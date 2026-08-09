import 'package:drift/drift.dart';

import '../../domain/vacation_rollover.dart';
import '../database/database.dart';
import '../database/enums.dart';

/// Vacation quota per calendar year, plus year-end rollover (Requirements &
/// Scope § 4 — Vacation Quota).
class VacationQuotaRepository {
  final AppDatabase db;

  VacationQuotaRepository(this.db);

  Future<VacationQuota?> forYear(int year) => db.vacationQuotaDao.forYear(year);

  Future<double> usedDaysForYear(int year) async {
    final leave = await db.leaveEntryDao.forYear(year);
    var hours = 0.0;
    for (final l in leave) {
      if (l.type == LeaveType.vacation) hours += l.hours;
    }
    // A "day" in the quota is a full daily target; callers needing an exact
    // conversion should pass a settings-aware hours-per-day, but for the
    // common Mon-Fri/8h case dividing by 8 is the practical default.
    return hours / 8.0;
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
