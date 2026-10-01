import 'package:drift/drift.dart';

import '../../domain/break_engine.dart';
import '../../domain/date_only.dart';
import '../../domain/recalculation_engine.dart';
import '../database/database.dart';
import '../database/enums.dart';

/// Ties the domain engines to the database: recomputes a day's DayEntry
/// (and its synthetic break, if any) and cascades the BalanceSnapshot
/// forward. This is the single place every mutation (session/leave/holiday/
/// settings change) routes through, per Data Model § Recalculation Trigger
/// Rules.
///
/// Every day and every balance belongs to a job, so every entry point takes
/// one. A change that is not one job's — a public holiday — goes through
/// [recalculateAllJobsFrom].
class RecalculationService {
  final AppDatabase db;
  final DateTime Function() _now;

  /// [now] is injectable so tests get deterministic "today" boundaries
  /// instead of depending on the real wall clock.
  RecalculationService(this.db, {DateTime Function() now = DateTime.now})
      : _now = now;

  /// Recalculates [date]'s DayEntry, then cascades the balance forward from
  /// [date] through today. A future [date] still gets its DayEntry
  /// recalculated (e.g. a newly-added upcoming holiday), but no balance
  /// snapshot is written for it — see [_cascadeBalanceFrom]. Use for a
  /// single-day change (a session/leave/holiday edit).
  Future<void> recalculateFrom(int jobId, DateTime date) async {
    final day = dateOnly(date);
    await db.transaction(() async {
      final job = await db.jobDao.byId(jobId);
      if (job == null) return;
      await _recalculateDay(job, day);
      await _cascadeBalanceFrom(job, day);
    });
  }

  /// [recalculateFrom] for every job — a holiday or another change that is
  /// not specific to one job.
  Future<void> recalculateAllJobsFrom(DateTime date) async {
    for (final job in await db.jobDao.all()) {
      await recalculateFrom(job.id, date);
    }
  }

  /// [recalculateRangeFrom] for every job.
  Future<void> recalculateAllJobsRangeFrom(DateTime date) async {
    for (final job in await db.jobDao.all()) {
      await recalculateRangeFrom(job.id, date);
    }
  }

  /// Recalculates every day from [date] through today, then cascades the
  /// balance once at the end. Use when a change can affect many days at
  /// once — a Settings change with a past `effectiveFrom` shifts
  /// target_hours (and so balance_delta) for every already-recorded day
  /// from that point forward, not just one. Data Model § Recalculation
  /// Trigger Rules: "Settings change with past effective_from -> All
  /// DayEntries and BalanceSnapshots from effective_from forward."
  ///
  /// [through] extends the range past today, for a change that reaches into
  /// the future (a vacation booked ahead). Without it a booking that lies
  /// entirely ahead was worked out on its first day only.
  Future<void> recalculateRangeFrom(int jobId, DateTime date, {DateTime? through}) async {
    final start = dateOnly(date);
    final today = dateOnly(_now());
    var end = start.isAfter(today) ? start : today;
    if (through != null && dateOnly(through).isAfter(end)) end = dateOnly(through);

    await db.transaction(() async {
      final job = await db.jobDao.byId(jobId);
      if (job == null) return;
      for (var d = start; !d.isAfter(end); d = shiftDays(d, 1)) {
        await _recalculateDay(job, d);
      }
      await _cascadeBalanceFrom(job, start);
    });
  }

  /// Updates the DayEntry for [day] from its current sessions/leave/holiday,
  /// but only writes a row if one already exists or something actually
  /// touches this date (a completed session, leave, or holiday) — DayEntry
  /// rows are created lazily, never speculatively, per Data Model §
  /// Design Principles.
  Future<void> _recalculateDay(Job job, DateTime day) async {
    final settings = await db.settingsDao.effectiveFor(job.id, day);
    // No settings yet means onboarding hasn't completed — nothing to
    // compute against.
    if (settings == null) return;

    final existing = await db.dayEntryDao.forDate(job.id, day);
    final holiday = await db.publicHolidayDao.forDate(day);
    final sessions = await db.workSessionDao.forDate(job.id, day);
    final completed = sessions
        .where((s) => s.status == SessionStatus.completed && s.endTime != null)
        .map((s) => WorkPeriod(start: s.startTime, end: s.endTime!))
        .toList();
    final leave = await db.leaveEntryDao.forDate(job.id, day);

    final hasActivity = completed.isNotEmpty || leave.isNotEmpty || holiday != null;
    if (existing == null && !hasActivity) return;

    var leaveHours = 0.0;
    for (final l in leave) {
      leaveHours += l.hours;
    }

    // Outside the job's own span a day owes nothing: before it started, or
    // after its last working day.
    final targetHours = _withinJob(job, day)
        ? computeTargetHours(
            date: day,
            workDays: settings.workDays,
            weeklyHours: settings.weeklyHours,
            holidayFraction: holiday?.fraction,
          )
        : 0.0;

    final autoBreakOverridden = existing?.autoBreakOverridden ?? false;

    final computation = recalculateDayEntry(
      completedSessions: completed,
      autoBreakEnabled: settings.autoBreakEnabled,
      autoBreakOverridden: autoBreakOverridden,
      leaveHours: leaveHours,
      targetHours: targetHours,
    );

    await db.dayEntryDao.upsert(DayEntriesCompanion(
      jobId: Value(job.id),
      date: Value(day),
      netWorkedHours: Value(computation.netWorkedHours),
      leaveHours: Value(computation.leaveHours),
      targetHours: Value(computation.targetHours),
      balanceDelta: Value(computation.balanceDelta),
      autoBreakOverridden: Value(autoBreakOverridden),
    ));

    // Synthetic breaks are fully re-derived every time — clear the old one
    // (if any) before writing the new plan, rather than trying to diff it.
    final existingBreaks = await db.breakEntryDao.forDate(job.id, day);
    for (final b in existingBreaks) {
      if (b.type == BreakType.synthetic) {
        await db.breakEntryDao.deleteBreak(b.id);
      }
    }
    final plan = computation.syntheticBreak;
    if (plan != null) {
      await db.breakEntryDao.insertBreak(BreakEntriesCompanion.insert(
        jobId: Value(job.id),
        date: day,
        startTime: plan.start,
        endTime: plan.end,
        type: BreakType.synthetic,
      ));
    }
  }

  /// No-op for a [day] beyond today — a future date (e.g. an upcoming
  /// holiday) has nothing "cumulative" to compute yet, and writing a
  /// speculative snapshot for it would corrupt `watchLatest()`: `ORDER BY
  /// date DESC` would then return that stale future row instead of today's
  /// real balance the next time something in the *past* changes without
  /// happening to also touch that same future date (e.g. a newly-seeded
  /// holiday only recalculates from its own date forward, not any
  /// already-existing future snapshots beyond it).
  ///
  /// The job's own starting balance is the floor every cascade rests on: a
  /// cascade that reaches back to the job's start (or finds no snapshot of
  /// the job's since) starts from [Job.startingBalanceHours] on the start
  /// date, never from a snapshot dated before the job existed.
  Future<void> _cascadeBalanceFrom(Job job, DateTime day) async {
    final today = dateOnly(_now());
    final jobStart = dateOnly(job.startDate);
    var from = day.isBefore(jobStart) ? jobStart : day;
    if (from.isAfter(today)) return;

    final previous = await db.balanceSnapshotDao.latestBefore(job.id, from);
    final double startingBalance;
    if (previous == null || previous.date.isBefore(jobStart) || from == jobStart) {
      from = jobStart;
      startingBalance = job.startingBalanceHours;
    } else {
      startingBalance = previous.balance;
    }

    final deltas = <MapEntry<DateTime, double>>[];
    for (var d = from; !d.isAfter(today); d = shiftDays(d, 1)) {
      deltas.add(MapEntry(d, await _deltaFor(job, d)));
    }

    final snapshots =
        cascadeBalance(startingBalance: startingBalance, dailyDeltas: deltas);
    for (final s in snapshots) {
      await db.balanceSnapshotDao.upsert(BalanceSnapshotsCompanion.insert(
        jobId: Value(job.id),
        date: s.date,
        balance: s.balance,
      ));
    }
  }

  /// Re-derives every day after today that already has a row — the repair
  /// for future bookings stored before [recalculateRangeFrom] took
  /// `through`. Future days carry no balance, so this touches day entries
  /// only. Runs at launch; cheap, a handful of rows.
  Future<void> refreshFutureDays() async {
    final today = dateOnly(_now());
    final rows = await (db.select(db.dayEntries)
          ..where((t) => t.date.isBiggerThanValue(today)))
        .get();
    final jobs = {for (final job in await db.jobDao.all()) job.id: job};
    await db.transaction(() async {
      for (final row in rows) {
        final job = jobs[row.jobId];
        if (job != null) await _recalculateDay(job, row.date);
      }
    });
  }

  /// One-time cleanup for a bug where earlier code wrote speculative
  /// BalanceSnapshots for future holiday dates (before [_cascadeBalanceFrom]
  /// was scoped to never do that) — those stale rows could outrank today's
  /// real balance in `watchLatest()`'s `ORDER BY date DESC`. Deletes every
  /// snapshot dated after today; a harmless no-op once none remain.
  Future<void> purgeFutureSnapshots() async {
    final today = dateOnly(_now());
    await db.balanceSnapshotDao.deleteFromDate(shiftDays(today, 1));
  }

  /// A date's balance_delta: its DayEntry's, if one exists; otherwise
  /// [missedWorkdayDelta] for a scheduled workday with no entry, or 0 for a
  /// non-work day. Data Model § Design Principles.
  Future<double> _deltaFor(Job job, DateTime date) async {
    final entry = await db.dayEntryDao.forDate(job.id, date);
    if (entry != null) return entry.balanceDelta;
    if (!_withinJob(job, date)) return 0;

    final settings = await db.settingsDao.effectiveFor(job.id, date);
    if (settings == null) return 0;
    if (!settings.workDays.contains(date.weekday)) return 0;

    final holiday = await db.publicHolidayDao.forDate(date);
    final target = computeTargetHours(
      date: date,
      workDays: settings.workDays,
      weeklyHours: settings.weeklyHours,
      holidayFraction: holiday?.fraction,
    );
    return missedWorkdayDelta(target);
  }

  static bool _withinJob(Job job, DateTime day) =>
      !day.isBefore(dateOnly(job.startDate)) &&
      (job.endDate == null || !day.isAfter(dateOnly(job.endDate!)));
}
