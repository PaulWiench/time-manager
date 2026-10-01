/// Turning leave hours back into leave days.
///
/// `LeaveEntries.hours` is stored in hours and `VacationQuotas.totalDays` in
/// days, and for a long time the seam between them was a hardcoded
/// `hours / 8` — in two places, one of which said in its own comment that it
/// was a guess. A full day here is `weeklyHours / workDays.length`, which for
/// a 39.5 h week over five days is 7.9, so sixteen whole vacation days used to
/// render as 15.8 and no whole number was reachable at all.
///
/// A day's worth of leave is a fraction of *that date's* target, which also
/// makes a half-day public holiday (target 3.95) come out right. Since the
/// editor only ever writes a full, three-quarter, half or quarter day, the
/// result is snapped to the nearest quarter: that absorbs both float noise and
/// an entry written before the weekly hours were changed.
library;

double leaveDaysFor({required double hours, required double targetHours}) {
  if (targetHours <= 0) return 0;
  return (hours / targetHours * 4).round() / 4;
}

double sumLeaveDays(Iterable<({double hours, double targetHours})> entries) {
  var total = 0.0;
  for (final entry in entries) {
    total += leaveDaysFor(hours: entry.hours, targetHours: entry.targetHours);
  }
  return total;
}

/// Days, as a number someone would say out loud: `13` rather than `13.0`, and
/// `2.5` when it really is a half.
String formatLeaveDays(double days) {
  final rounded = (days * 4).round() / 4;
  if (rounded == rounded.roundToDouble()) return '${rounded.round()}';
  return rounded.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
}
