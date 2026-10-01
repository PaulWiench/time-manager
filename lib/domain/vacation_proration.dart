/// Vacation entitlement in a year a job only partly covers.
///
/// A job that starts or ends mid-year earns its yearly quota pro rata: one
/// twelfth for every full month of employment that falls in the year. A
/// fraction of half a day or more rounds up to a whole day, anything less
/// rounds down — Paul's contract rule (TV-L § 26 style), so a 30-day quota
/// from 15 March is 30 × 9 / 12 = 22.5, which is 23.
///
/// Months are counted from the first day employed in the year, not on the
/// calendar: 15 March to 14 April is one month. Counting calendar months
/// gives the same answer for every start date this app has seen, but not for
/// all of them, and the contract speaks of months of employment.
library;

import 'date_only.dart';

class ProratedVacation {
  const ProratedVacation({
    required this.days,
    required this.fullMonths,
    required this.isProrated,
    required this.exact,
  });

  /// The entitlement, rounded.
  final double days;

  /// Full months of employment inside the year (12 for a whole year).
  final int fullMonths;

  /// False when the job covers the whole year and [days] is the quota as is.
  final bool isProrated;

  /// quota × months / 12 before rounding — what the explanation shows.
  final double exact;
}

ProratedVacation proratedVacationDays({
  required double yearlyQuota,
  required DateTime jobStart,
  DateTime? jobEnd,
  required int year,
}) {
  final yearStart = DateTime(year);
  final yearEnd = DateTime(year, 12, 31);
  final start = dateOnly(jobStart);
  final end = jobEnd == null ? null : dateOnly(jobEnd);

  final from = start.isAfter(yearStart) ? start : yearStart;
  final to = end == null || end.isAfter(yearEnd) ? yearEnd : end;
  if (to.isBefore(from)) {
    return const ProratedVacation(days: 0, fullMonths: 0, isProrated: true, exact: 0);
  }
  if (from == yearStart && to == yearEnd) {
    return ProratedVacation(
      days: yearlyQuota,
      fullMonths: 12,
      isProrated: false,
      exact: yearlyQuota,
    );
  }

  // A month counts once its last day is still employed.
  final dayAfter = shiftDays(to, 1);
  var months = 0;
  while (months < 12 && !shiftMonths(from, months + 1).isAfter(dayAfter)) {
    months++;
  }

  final exact = yearlyQuota * months / 12;
  final whole = exact.floorToDouble();
  final rounded = exact - whole >= 0.5 - 1e-9 ? whole + 1 : whole;
  return ProratedVacation(days: rounded, fullMonths: months, isProrated: true, exact: exact);
}
