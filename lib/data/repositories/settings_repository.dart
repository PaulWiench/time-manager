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

  Future<AppSetting?> effectiveFor(DateTime date) =>
      db.settingsDao.effectiveFor(date);

  Stream<AppSetting?> watchLatest() => db.settingsDao.watchLatest();

  /// True once onboarding has written the first Settings row.
  Future<bool> hasCompletedOnboarding() async =>
      (await db.settingsDao.effectiveFor(DateTime.now())) != null;

  Future<void> save({
    required DateTime effectiveFrom,
    required double weeklyHours,
    required List<int> workDays,
    required int minSessionMinutes,
    required bool autoBreakEnabled,
    required bool restrictCheckin,
  }) async {
    final day = dateOnly(effectiveFrom);

    await db.transaction(() async {
      await db.settingsDao.insertSettings(AppSettingsCompanion.insert(
        effectiveFrom: Value(day),
        weeklyHours: Value(weeklyHours),
        workDays: Value(workDays),
        minSessionMinutes: Value(minSessionMinutes),
        autoBreakEnabled: Value(autoBreakEnabled),
        restrictCheckin: Value(restrictCheckin),
      ));
      await db.auditLogDao.record(AuditLogEntriesCompanion.insert(
        action: 'update',
        entityType: 'AppSettings',
        newValue: Value(jsonEncode({
          'effectiveFrom': day.toIso8601String(),
          'weeklyHours': weeklyHours,
          'workDays': workDays,
          'minSessionMinutes': minSessionMinutes,
          'autoBreakEnabled': autoBreakEnabled,
          'restrictCheckin': restrictCheckin,
        })),
      ));
    });

    // A settings change can shift target_hours (and so balance_delta) for
    // every day already on record from effectiveFrom forward, not just one.
    await recalc.recalculateRangeFrom(day);
  }

  /// Onboarding's "starting balance" isn't a Settings field — it's the
  /// carried-over balance from before tracking began, so it's seeded as a
  /// BalanceSnapshot dated the day before [effectiveFrom]. The balance
  /// cascade (`RecalculationService._cascadeBalanceFrom`) always looks up
  /// the latest snapshot strictly before the date it's cascading from, so
  /// this becomes every later day's base without needing its own column.
  Future<void> seedStartingBalance({required double balance, required DateTime effectiveFrom}) async {
    final seedDate = dateOnly(effectiveFrom).subtract(const Duration(days: 1));
    await db.balanceSnapshotDao.upsert(BalanceSnapshotsCompanion.insert(
      date: seedDate,
      balance: balance,
    ));
  }
}
