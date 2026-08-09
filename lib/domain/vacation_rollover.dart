/// Year-end vacation quota rollover. See Requirements & Scope § 4 —
/// Vacation Quota.
library;

enum RolloverPolicy {
  /// Unused days carry over indefinitely (default).
  indefinite,

  /// Unused days are forfeited at year end.
  expireAtYearEnd,

  /// Unused days carry over but must be used by a configured deadline.
  useByDeadline,
}

class VacationQuotaValues {
  final double totalDays;
  final double rolloverDays;
  final DateTime? rolloverDeadline;

  const VacationQuotaValues({
    required this.totalDays,
    required this.rolloverDays,
    this.rolloverDeadline,
  });
}

/// Computes the following year's quota (the `rolloverDays` component; the
/// caller is responsible for setting `totalDays` from the configured
/// yearly entitlement, since that's independent of rollover).
///
/// [usedDays] is this (ending) year's total vacation-type LeaveEntry hours
/// converted to days, [currentYear] is the quota row being closed out.
VacationQuotaValues computeNextYearRollover({
  required VacationQuotaValues currentYear,
  required double usedDays,
  required RolloverPolicy policy,
  required double nextYearTotalDays,
  DateTime? useByDeadline,
}) {
  final availableThisYear = currentYear.totalDays + currentYear.rolloverDays;
  final unused = (availableThisYear - usedDays).clamp(0, double.infinity);

  switch (policy) {
    case RolloverPolicy.expireAtYearEnd:
      return VacationQuotaValues(
        totalDays: nextYearTotalDays,
        rolloverDays: 0,
      );
    case RolloverPolicy.indefinite:
      return VacationQuotaValues(
        totalDays: nextYearTotalDays,
        rolloverDays: unused.toDouble(),
      );
    case RolloverPolicy.useByDeadline:
      assert(
        useByDeadline != null,
        'useByDeadline policy requires a deadline date',
      );
      return VacationQuotaValues(
        totalDays: nextYearTotalDays,
        rolloverDays: unused.toDouble(),
        rolloverDeadline: useByDeadline,
      );
  }
}

/// True if [now] is within [warnDaysBefore] of the rollover deadline (and
/// there's still unused rollover to lose) — drives the "vacation expiring"
/// notification and Stats warning state.
bool isApproachingRolloverExpiry(
  VacationQuotaValues quota,
  DateTime now, {
  int warnDaysBefore = 30,
}) {
  final deadline = quota.rolloverDeadline;
  if (deadline == null || quota.rolloverDays <= 0) return false;

  final warnFrom = deadline.subtract(Duration(days: warnDaysBefore));
  return !now.isBefore(warnFrom) && now.isBefore(deadline);
}
