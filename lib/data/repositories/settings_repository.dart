import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/date_only.dart';
import '../database/database.dart';
import 'recalculation_service.dart';

/// Wraps SettingsDao's versioned rows (Data Model § Settings: a new row per
/// change, active row = highest `effectiveFrom` <= the queried date).
class SettingsRepository {
  final AppDatabase db;
  final RecalculationService recalc;

  SettingsRepository(this.db, this.recalc);

  Future<AppSetting?> effectiveFor(int jobId, DateTime date) =>
      db.settingsDao.effectiveFor(jobId, date);

  Stream<AppSetting?> watchLatest(int jobId) => db.settingsDao.watchLatest(jobId);

  Stream<AppSetting?> watchEffectiveFor(int jobId, DateTime date) =>
      db.settingsDao.watchEffectiveFor(jobId, date);

  /// True once onboarding has written the first Settings row.
  Future<bool> hasCompletedOnboarding() => db.settingsDao.any();

  /// Settings are versioned — every change writes a new row — so every field
  /// has to be passed on every save. A field left out here would silently
  /// reset itself the next time any unrelated setting changed.
  Future<void> save({
    required int jobId,
    required DateTime effectiveFrom,
    required double weeklyHours,
    required List<int> workDays,
    required int minSessionMinutes,
    required bool autoBreakEnabled,
    required bool restrictCheckin,
    int workWindowStartMinutes = 8 * 60,
    int workWindowEndMinutes = 18 * 60,
    double? balanceFloorHours,
    double? balanceCapHours,
    bool balanceAnnualReset = false,
  }) async {
    final day = dateOnly(effectiveFrom);

    await db.transaction(() async {
      await db.settingsDao.insertSettings(AppSettingsCompanion.insert(
        jobId: Value(jobId),
        effectiveFrom: Value(day),
        weeklyHours: Value(weeklyHours),
        workDays: Value(workDays),
        minSessionMinutes: Value(minSessionMinutes),
        autoBreakEnabled: Value(autoBreakEnabled),
        restrictCheckin: Value(restrictCheckin),
        workWindowStartMinutes: Value(workWindowStartMinutes),
        workWindowEndMinutes: Value(workWindowEndMinutes),
        balanceFloorHours: Value(balanceFloorHours),
        balanceCapHours: Value(balanceCapHours),
        balanceAnnualReset: Value(balanceAnnualReset),
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'AppSettings',
        newValue: Value(jsonEncode({
          'jobId': jobId,
          'effectiveFrom': day.toIso8601String(),
          'weeklyHours': weeklyHours,
          'workDays': workDays,
          'minSessionMinutes': minSessionMinutes,
          'autoBreakEnabled': autoBreakEnabled,
          'restrictCheckin': restrictCheckin,
          'workWindowStartMinutes': workWindowStartMinutes,
          'workWindowEndMinutes': workWindowEndMinutes,
          'balanceFloorHours': balanceFloorHours,
          'balanceCapHours': balanceCapHours,
          'balanceAnnualReset': balanceAnnualReset,
        })),
      ));
    });

    // A settings change can shift target_hours (and so balance_delta) for
    // every day already on record from effectiveFrom forward, not just one.
    await recalc.recalculateRangeFrom(jobId, day);
  }

  /// A schedule change that counts from [from] — possibly a date already
  /// past, e.g. a contract that changed on 1 September.
  ///
  /// Settings are versioned, so a plain new row at [from] is not enough: a
  /// version saved later (say on 28 September, for the work window) still
  /// carries the old weekly hours and would put them back from its own date
  /// on. So the change is written as a new version at [from] and carried
  /// into every later version of this job's settings, for the changed fields
  /// only; everything else each version says is left alone. Then every day
  /// from [from] is recalculated.
  Future<void> saveScheduleFrom({
    required int jobId,
    required DateTime from,
    double? weeklyHours,
    List<int>? workDays,
    int? workWindowStartMinutes,
    int? workWindowEndMinutes,
  }) async {
    final day = dateOnly(from);
    await db.transaction(() async {
      final rows = await (db.select(db.appSettings)
            ..where((t) => t.jobId.equals(jobId))
            ..orderBy([
              (t) => OrderingTerm.asc(t.effectiveFrom),
              (t) => OrderingTerm.asc(t.createdAt),
            ]))
          .get();
      if (rows.isEmpty) return;
      final base = await db.settingsDao.effectiveFor(jobId, day) ?? rows.first;

      await db.settingsDao.insertSettings(AppSettingsCompanion.insert(
        jobId: Value(jobId),
        effectiveFrom: Value(day),
        weeklyHours: Value(weeklyHours ?? base.weeklyHours),
        workDays: Value(workDays ?? base.workDays),
        minSessionMinutes: Value(base.minSessionMinutes),
        autoBreakEnabled: Value(base.autoBreakEnabled),
        restrictCheckin: Value(base.restrictCheckin),
        workWindowStartMinutes: Value(workWindowStartMinutes ?? base.workWindowStartMinutes),
        workWindowEndMinutes: Value(workWindowEndMinutes ?? base.workWindowEndMinutes),
        balanceFloorHours: Value(base.balanceFloorHours),
        balanceCapHours: Value(base.balanceCapHours),
        balanceAnnualReset: Value(base.balanceAnnualReset),
      ));

      var carried = 0;
      for (final later in rows.where((r) => dateOnly(r.effectiveFrom).isAfter(day))) {
        await (db.update(db.appSettings)..where((t) => t.id.equals(later.id))).write(
          AppSettingsCompanion(
            weeklyHours: weeklyHours == null ? const Value.absent() : Value(weeklyHours),
            workDays: workDays == null ? const Value.absent() : Value(workDays),
            workWindowStartMinutes: workWindowStartMinutes == null
                ? const Value.absent()
                : Value(workWindowStartMinutes),
            workWindowEndMinutes:
                workWindowEndMinutes == null ? const Value.absent() : Value(workWindowEndMinutes),
          ),
        );
        carried++;
      }

      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'AppSettings',
        newValue: Value(jsonEncode({
          'jobId': jobId,
          'appliesFrom': day.toIso8601String(),
          'weeklyHours': weeklyHours,
          'workDays': workDays,
          'workWindowStartMinutes': workWindowStartMinutes,
          'workWindowEndMinutes': workWindowEndMinutes,
          'carriedIntoLaterVersions': carried,
        })),
      ));
    });
    await recalc.recalculateRangeFrom(jobId, day);
  }

  /// The settings that apply to every job — auto-break, minimum session
  /// length, restrict check-in. Each job's history gets its own next row
  /// carrying the change, so every job's settings stay complete on their own.
  Future<void> saveForAllJobs({
    required DateTime effectiveFrom,
    int? minSessionMinutes,
    bool? autoBreakEnabled,
    bool? restrictCheckin,
  }) async {
    for (final job in await db.jobDao.all()) {
      final current = await db.settingsDao.latest(job.id);
      if (current == null) continue;
      await save(
        jobId: job.id,
        effectiveFrom: effectiveFrom,
        weeklyHours: current.weeklyHours,
        workDays: current.workDays,
        minSessionMinutes: minSessionMinutes ?? current.minSessionMinutes,
        autoBreakEnabled: autoBreakEnabled ?? current.autoBreakEnabled,
        restrictCheckin: restrictCheckin ?? current.restrictCheckin,
        workWindowStartMinutes: current.workWindowStartMinutes,
        workWindowEndMinutes: current.workWindowEndMinutes,
        balanceFloorHours: current.balanceFloorHours,
        balanceCapHours: current.balanceCapHours,
        balanceAnnualReset: current.balanceAnnualReset,
      );
    }
  }
}
