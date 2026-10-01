import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/date_only.dart';
import '../database/database.dart';
import 'recalculation_service.dart';
import 'work_session_repository.dart';

/// Jobs: create, edit, end, reopen — and which one the app is showing.
///
/// A job's schedule is its versioned settings rows, its balance its own
/// snapshots, its quota its own quota rows; this is where a new job gets all
/// three, and where moving a job's dates re-settles the days that changes.
class JobRepository {
  JobRepository(this.db, this.recalc, this.sessions);

  final AppDatabase db;
  final RecalculationService recalc;
  final WorkSessionRepository sessions;

  static const _selectedKey = 'selectedJobId';

  Stream<List<Job>> watchAll() => db.jobDao.watchAll();

  Future<List<Job>> all() => db.jobDao.all();

  Stream<Job?> watchById(int id) => db.jobDao.watchById(id);

  /// The job Home, History and Stats show. Falls back to the first active
  /// job when nothing was chosen yet or the chosen one no longer exists.
  Stream<int?> watchSelectedId() => db.jobDao.watchPreference(_selectedKey).asyncMap((value) async {
        final chosen = int.tryParse(value ?? '');
        final jobs = await db.jobDao.all();
        if (chosen != null && jobs.any((j) => j.id == chosen)) return chosen;
        final active = jobs.where((j) => j.endDate == null).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        if (active.isNotEmpty) return active.first.id;
        return jobs.isEmpty ? null : jobs.first.id;
      });

  Future<void> select(int jobId) => db.jobDao.setPreference(_selectedKey, '$jobId');

  /// Creates a job with its first settings row, quota and starting balance,
  /// and settles its days from the start up to today.
  Future<int> createJob({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    required double weeklyHours,
    required List<int> workDays,
    required int workWindowStartMinutes,
    required int workWindowEndMinutes,
    double startingBalanceHours = 0,
    double? balanceFloorHours,
    double? balanceCapHours,
    bool balanceAnnualReset = false,
    required double vacationDaysPerYear,
    bool? autoBreakEnabled,
  }) async {
    final start = dateOnly(startDate);
    late int id;
    await db.transaction(() async {
      // The settings every job shares come from whichever job exists, so a
      // second job does not quietly switch auto-break back on.
      final jobs = await db.jobDao.all();
      final shared = jobs.isEmpty ? null : await db.settingsDao.latest(jobs.first.id);

      id = await db.jobDao.insertJob(JobsCompanion.insert(
        name: name.trim(),
        startDate: start,
        endDate: Value(endDate == null ? null : dateOnly(endDate)),
        startingBalanceHours: Value(startingBalanceHours),
      ));
      await db.settingsDao.insertSettings(AppSettingsCompanion.insert(
        jobId: Value(id),
        effectiveFrom: Value(start),
        weeklyHours: Value(weeklyHours),
        workDays: Value(workDays),
        minSessionMinutes: Value(shared?.minSessionMinutes ?? 5),
        autoBreakEnabled: Value(autoBreakEnabled ?? shared?.autoBreakEnabled ?? true),
        restrictCheckin: Value(shared?.restrictCheckin ?? false),
        workWindowStartMinutes: Value(workWindowStartMinutes),
        workWindowEndMinutes: Value(workWindowEndMinutes),
        balanceFloorHours: Value(balanceFloorHours),
        balanceCapHours: Value(balanceCapHours),
        balanceAnnualReset: Value(balanceAnnualReset),
      ));
      await db.vacationQuotaDao.upsert(VacationQuotasCompanion.insert(
        jobId: Value(id),
        year: start.year,
        totalDays: Value(vacationDaysPerYear),
      ));
      await _audit('create', id, {
        'name': name.trim(),
        'startDate': start.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'startingBalanceHours': startingBalanceHours,
      });
    });
    await recalc.recalculateRangeFrom(id, start);
    return id;
  }

  /// Renames a job and moves its dates or starting balance. Every day between
  /// the old and the new dates is re-settled.
  ///
  /// Throws [JobDatesError] for dates that would orphan tracked time: a start
  /// after the first session, an end before the last one, or an end before
  /// the start.
  Future<void> updateJob(
    int id, {
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    required double startingBalanceHours,
  }) async {
    final job = await db.jobDao.byId(id);
    if (job == null) return;
    final start = dateOnly(startDate);
    final end = endDate == null ? null : dateOnly(endDate);
    await validateDates(id, start: start, end: end);

    await db.transaction(() async {
      await db.jobDao.updateJob(
        id,
        JobsCompanion(
          name: Value(name.trim()),
          startDate: Value(start),
          endDate: Value(end),
          startingBalanceHours: Value(startingBalanceHours),
          updatedAt: Value(DateTime.now()),
        ),
      );
      // Moving the start earlier than any settings row would leave the new
      // days with no schedule at all; the first row is carried back to it.
      final first = await (db.select(db.appSettings)
            ..where((t) => t.jobId.equals(id))
            ..orderBy([(t) => OrderingTerm.asc(t.effectiveFrom)])
            ..limit(1))
          .getSingleOrNull();
      if (first != null && start.isBefore(dateOnly(first.effectiveFrom))) {
        await (db.update(db.appSettings)..where((t) => t.id.equals(first.id)))
            .write(AppSettingsCompanion(effectiveFrom: Value(start)));
      }
      await _audit('update', id, {
        'name': name.trim(),
        'startDate': start.toIso8601String(),
        'endDate': end?.toIso8601String(),
        'startingBalanceHours': startingBalanceHours,
      }, old: {
        'name': job.name,
        'startDate': job.startDate.toIso8601String(),
        'endDate': job.endDate?.toIso8601String(),
        'startingBalanceHours': job.startingBalanceHours,
      });
    });

    final oldStart = dateOnly(job.startDate);
    final from = [
      oldStart,
      start,
      if (job.endDate != null) dateOnly(job.endDate!),
      if (end != null) end,
    ].reduce((a, b) => a.isBefore(b) ? a : b);
    await recalc.recalculateRangeFrom(id, from);
  }

  /// Ends a job on [lastDay]. A session of this job still running is checked
  /// out first — at [now] if the job ends today or later, otherwise at the end
  /// of the last day.
  Future<void> endJob(int id, DateTime lastDay, {DateTime? now}) async {
    final job = await db.jobDao.byId(id);
    if (job == null) return;
    final end = dateOnly(lastDay);
    final clock = now ?? DateTime.now();
    await validateDates(id, start: dateOnly(job.startDate), end: end, ignoreRunning: true);

    final running = await db.workSessionDao.activeSessions(id);
    for (final session in running) {
      final at = end.isBefore(dateOnly(clock)) ? DateTime(end.year, end.month, end.day, 23, 59) : clock;
      await sessions.checkOut(sessionId: session.id, at: at.isBefore(session.startTime) ? clock : at);
    }
    await updateJob(
      id,
      name: job.name,
      startDate: job.startDate,
      endDate: end,
      startingBalanceHours: job.startingBalanceHours,
    );
  }

  Future<void> reopenJob(int id) async {
    final job = await db.jobDao.byId(id);
    if (job == null) return;
    await updateJob(
      id,
      name: job.name,
      startDate: job.startDate,
      endDate: null,
      startingBalanceHours: job.startingBalanceHours,
    );
  }

  /// The first and last day this job has tracked time on, if any.
  Future<({DateTime? first, DateTime? last})> trackedSpan(int id) async {
    final row = await db
        .customSelect(
          "SELECT MIN(date) AS first, MAX(date) AS last FROM work_sessions "
          "WHERE job_id = ? AND status != 'discarded'",
          variables: [Variable<int>(id)],
          readsFrom: {db.workSessions},
        )
        .getSingle();
    return (first: row.read<DateTime?>('first'), last: row.read<DateTime?>('last'));
  }

  Future<void> validateDates(
    int id, {
    required DateTime start,
    DateTime? end,
    bool ignoreRunning = false,
  }) async {
    if (end != null && end.isBefore(start)) throw const JobDatesError.endsBeforeStart();
    final span = await trackedSpan(id);
    if (span.first != null && start.isAfter(span.first!)) {
      throw JobDatesError.startAfterSessions(span.first!);
    }
    if (end != null && span.last != null && end.isBefore(span.last!)) {
      throw JobDatesError.endBeforeSessions(span.last!);
    }
    if (!ignoreRunning && end != null && (await db.workSessionDao.activeSessions(id)).isNotEmpty) {
      throw const JobDatesError.running();
    }
  }

  Future<void> _audit(String action, int id, Map<String, Object?> value,
          {Map<String, Object?>? old}) =>
      db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: action,
        entityType: 'Job',
        entityId: Value('$id'),
        oldValue: Value(old == null ? null : jsonEncode(old)),
        newValue: Value(jsonEncode(value)),
      ));
}

/// Why a job's dates were refused, phrased for the person moving them.
class JobDatesError implements Exception {
  const JobDatesError.endsBeforeStart()
      : message = 'Ends before it starts',
        date = null;
  JobDatesError.startAfterSessions(DateTime this.date)
      : message = 'Sessions exist from that day on. Start on or before it.';
  JobDatesError.endBeforeSessions(DateTime this.date)
      : message = 'Sessions exist until that day. End on or after it.';
  const JobDatesError.running()
      : message = 'A session is running. End the job from the End job sheet.',
        date = null;

  final String message;

  /// The session date the message refers to, for the screen to print.
  final DateTime? date;

  @override
  String toString() => message;
}
