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
