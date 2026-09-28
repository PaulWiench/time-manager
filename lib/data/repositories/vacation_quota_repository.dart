import 'package:drift/drift.dart';

import '../../domain/date_only.dart';
import '../../domain/leave_days.dart';
import '../../domain/vacation_rollover.dart';
import '../database/database.dart';
import '../database/enums.dart';

/// Vacation quota per calendar year, plus year-end rollover (Requirements &
/// Scope § 4 — Vacation Quota).
class VacationQuotaRepository {
  final AppDatabase db;

  VacationQuotaRepository(this.db);

  Future<VacationQuota?> forYear(int year) => db.vacationQuotaDao.forYear(year);

  Stream<VacationQuota?> watchForYear(int year) => db.vacationQuotaDao.watchForYear(year);

  Future<void> setQuota({required int year, required double totalDays}) {
    return db.vacationQuotaDao.upsert(VacationQuotasCompanion(
      year: Value(year),
      totalDays: Value(totalDays),
    ));
  }

  /// Vacation days used in [year], each entry measured against the target its
  /// own date carried.
  ///
  /// This used to divide the year's hours by a flat 8, with a comment admitting
  /// it was a stand-in for a settings-aware conversion. A full day here is
  /// `weeklyHours / workDays.length` — 7.9 for a 39.5 h week — so sixteen whole
  /// vacation days came out as 15.8, and on a half-day public holiday it was
  /// wrong in the other direction.
  Future<double> usedDaysForYear(int year) async {
    final leave = await db.leaveEntryDao.forYear(year);
    final days = await db.dayEntryDao.forRange(DateTime(year), DateTime(year + 1));
    final targets = {for (final day in days) day.date: day.targetHours};

    var total = 0.0;
    for (final entry in leave) {
      if (entry.type != LeaveType.vacation) continue;
      total += leaveDaysFor(
        hours: entry.hours,
        targetHours: targets[dateOnly(entry.date)] ?? 0,
      );
    }
    return total;
  }

  Future<void> rollIntoNextYear({
    required int fromYear,
    required RolloverPolicy policy,
    required double nextYearTotalDays,
    DateTime? useByDeadline,
  }) async {
    final current = await db.vacationQuotaDao.forYear(fromYear);
    final currentValues = VacationQuotaValues(
      totalDays: current?.totalDays ?? 30,
      rolloverDays: current?.rolloverDays ?? 0,
    );
    final used = await usedDaysForYear(fromYear);

    final next = computeNextYearRollover(
      currentYear: currentValues,
      usedDays: used,
      policy: policy,
      nextYearTotalDays: nextYearTotalDays,
      useByDeadline: useByDeadline,
    );

    await db.vacationQuotaDao.upsert(VacationQuotasCompanion.insert(
      year: Value(fromYear + 1),
      totalDays: Value(next.totalDays),
      rolloverDays: Value(next.rolloverDays),
      rolloverDeadline: Value(next.rolloverDeadline),
    ));
  }
}
