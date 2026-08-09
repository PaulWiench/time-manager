/// Pure aggregation helpers for the Stats screen (Milestone 8). Kept
/// Flutter/Drift-free like the rest of `domain/` — callers map DB rows
/// (`DayEntry`, `WorkSession`) into the plain value types here before
/// calling in.
library;

import 'date_only.dart';

/// One day's already-computed aggregate, as stored on `DayEntry` — net
/// worked hours, target, and balance delta are read straight off that row
/// rather than recomputed here, since `DayEntry` already holds the
/// historically-accurate values the recalculation engine produced.
class DayStat {
  final DateTime date;
  final double netWorkedHours;
  final double targetHours;
  final double balanceDelta;

  const DayStat({
    required this.date,
    required this.netWorkedHours,
    required this.targetHours,
    required this.balanceDelta,
  });
}

/// A trailing (not calendar-aligned) date window ending "today" — matches
/// the UX doc's plain-language "last week / month / 6 months / year"
/// phrasing for the Stats global range selector.
class DateRange {
  final DateTime start; // inclusive, date-only
  final DateTime endExclusive; // date-only

  const DateRange({required this.start, required this.endExclusive});
}

DateRange trailingRange(int days, {required DateTime today}) {
  final start = shiftDays(dateOnly(today), -(days - 1));
  final endExclusive = shiftDays(dateOnly(today), 1);
  return DateRange(start: start, endExclusive: endExclusive);
}

/// The Monday (ISO week start) of the week containing [date].
DateTime mondayOfWeek(DateTime date) => shiftDays(date, -(date.weekday - 1));

class WeekStat {
  final DateTime weekStart;
  final double netHours;
  final double targetHours;
  final double balanceDelta;

  const WeekStat({
    required this.weekStart,
    required this.netHours,
    required this.targetHours,
    required this.balanceDelta,
  });

  /// A week with no scheduled work (targetHours == 0, e.g. all-holiday or
  /// out-of-range padding) counts as trivially hit rather than missed.
  bool get hitTarget => targetHours <= 0 || netHours >= targetHours;
}

/// Groups [days] into ISO weeks (Monday start), ordered ascending. Only
/// weeks with at least one [DayStat] in range appear — a week isn't padded
/// in from outside the requested range.
List<WeekStat> weeklyAggregates(List<DayStat> days) {
  final byWeek = <DateTime, List<DayStat>>{};
  for (final d in days) {
    byWeek.putIfAbsent(mondayOfWeek(d.date), () => []).add(d);
  }
  final weeks = byWeek.keys.toList()..sort();
  return [
    for (final wk in weeks)
      WeekStat(
        weekStart: wk,
        netHours: byWeek[wk]!.fold(0.0, (s, d) => s + d.netWorkedHours),
        targetHours: byWeek[wk]!.fold(0.0, (s, d) => s + d.targetHours),
        balanceDelta: byWeek[wk]!.fold(0.0, (s, d) => s + d.balanceDelta),
      ),
  ];
}

/// Average net worked hours per ISO weekday (index 0 = Monday .. 6 =
/// Sunday) across [days]. A weekday with no entries at all averages to 0.
List<double> averageHoursByWeekday(List<DayStat> days) {
  final sums = List<double>.filled(7, 0);
  final counts = List<int>.filled(7, 0);
  for (final d in days) {
    final idx = d.date.weekday - 1;
    sums[idx] += d.netWorkedHours;
    counts[idx] += 1;
  }
  return [for (var i = 0; i < 7; i++) counts[i] == 0 ? 0.0 : sums[i] / counts[i]];
}

/// Count of check-ins per hour-of-day (index 0..23), for the "earliest /
/// latest check-in patterns" distribution.
List<int> checkinHourHistogram(List<DateTime> checkInTimes) {
  final buckets = List<int>.filled(24, 0);
  for (final t in checkInTimes) {
    buckets[t.hour]++;
  }
  return buckets;
}
