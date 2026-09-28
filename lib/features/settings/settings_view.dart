/// The strings Settings shows on the right of each row.
library;

import '../../core/format.dart';

class SettingsView {
  const SettingsView({
    required this.weeklyHours,
    required this.workDays,
    required this.startingBalance,
    required this.autoBreakEnabled,
    required this.minSessionLength,
    required this.restrictCheckin,
    required this.balanceBounds,
    required this.annualResetLabel,
    required this.leaveCount,
    required this.vacationQuota,
    required this.rolloverPolicy,
    required this.holidayRegion,
    required this.holidayCount,
    required this.notifications,
  });

  final String weeklyHours;
  final String workDays;
  final String startingBalance;
  final bool autoBreakEnabled;
  final String minSessionLength;
  final bool restrictCheckin;
  final String balanceBounds;
  final String annualResetLabel;
  /// `16 this year`, or `None yet`.
  final String leaveCount;

  final String vacationQuota;
  final String rolloverPolicy;
  final String holidayRegion;
  final String holidayCount;
  final String notifications;
}

/// `Mon–Fri` when the days run together, `Mon, Wed, Fri` when they do not.
String workDaysLabel(List<int> days) {
  const names = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
  final sorted = [...days]..sort();
  if (sorted.isEmpty) return 'None';
  final isContiguous = sorted.length > 1 && sorted.last - sorted.first == sorted.length - 1;
  if (isContiguous) return '${names[sorted.first]}–${names[sorted.last]}';
  return sorted.map((day) => names[day]).join(', ');
}

/// Either bound can stand alone — a floor without a cap is a perfectly normal
/// configuration, and neither being set is the default.
String balanceBoundsLabel(double? floor, double? cap) {
  if (floor == null && cap == null) return 'Not set';
  return [
    if (floor != null) AppFormat.hm(floor),
    if (cap != null) AppFormat.hm(cap, signed: true),
  ].join(' / ');
}
