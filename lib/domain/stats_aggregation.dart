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
/// Sunday) across the days that were actually worked. A full leave day, a
/// holiday or an untracked day is not a short Tuesday, so counting it as 0 h
/// only dragged its weekday down; a half day of leave still counts with the
/// hours that were worked. A weekday never worked averages to 0.
List<double> averageHoursByWeekday(List<DayStat> days) {
  final sums = List<double>.filled(7, 0);
  final counts = List<int>.filled(7, 0);
  for (final d in days) {
    if (d.netWorkedHours <= 0) continue;
    final idx = d.date.weekday - 1;
    sums[idx] += d.netWorkedHours;
    counts[idx] += 1;
  }
  return [for (var i = 0; i < 7; i++) counts[i] == 0 ? 0.0 : sums[i] / counts[i]];
}

/// How many days one bar of the Daily Hours chart stands for.
enum HoursBucket { day, week, month }

/// One bar per day stops fitting on a phone somewhere past a month, so
/// longer ranges are grouped: weeks up to about nine months, months beyond.
HoursBucket hoursBucketFor(DateRange range) {
  var days = 0;
  for (var d = range.start; d.isBefore(range.endExclusive); d = shiftDays(d, 1)) {
    days++;
  }
  // Additions handoff §6.1: 1W/1M daily, 6M weekly, 1Y monthly; a custom
  // range by its length.
  if (days <= 45) return HoursBucket.day;
  if (days <= 270) return HoursBucket.week;
  return HoursBucket.month;
}

/// The first day of the [bucket] containing [date].
DateTime bucketStart(DateTime date, HoursBucket bucket) => switch (bucket) {
      HoursBucket.day => dateOnly(date),
      HoursBucket.week => mondayOfWeek(dateOnly(date)),
      HoursBucket.month => DateTime(date.year, date.month),
    };

/// The first day after the [bucket] starting at [start].
DateTime bucketEnd(DateTime start, HoursBucket bucket) => switch (bucket) {
      HoursBucket.day => shiftDays(start, 1),
      HoursBucket.week => shiftDays(start, 7),
      HoursBucket.month => DateTime(start.year, start.month + 1),
    };

/// Groups [days] into one [DayStat] per [bucket], ordered ascending. Each
/// bucket's hours are the average per *worked* day, so a week with a holiday
/// reads the same as the days around it rather than a fifth shorter. The
/// target is likewise the average over scheduled days; a bucket with no work
/// and no schedule comes out as a rest bucket (both 0). Days are passed
/// through unchanged for [HoursBucket.day].
List<DayStat> bucketDailyHours(List<DayStat> days, HoursBucket bucket) {
  if (bucket == HoursBucket.day) return days;
  final byBucket = <DateTime, List<DayStat>>{};
  for (final d in days) {
    byBucket.putIfAbsent(bucketStart(d.date, bucket), () => []).add(d);
  }
  double averageOf(Iterable<double> values) {
    final list = values.toList();
    return list.isEmpty ? 0 : list.fold<double>(0, (s, v) => s + v) / list.length;
  }

  final starts = byBucket.keys.toList()..sort();
  return [
    for (final start in starts)
      DayStat(
        date: start,
        netWorkedHours: averageOf(
            byBucket[start]!.map((d) => d.netWorkedHours).where((h) => h > 0)),
        targetHours: averageOf(
            byBucket[start]!.map((d) => d.targetHours).where((h) => h > 0)),
        balanceDelta: byBucket[start]!.fold(0.0, (s, d) => s + d.balanceDelta),
      ),
  ];
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

/// The first check-in of each day, which is the one "when do you start"
/// is actually asking about. Counting every session start would let one day
/// with four short sessions outvote four days that each started once.
List<DateTime> firstCheckInPerDay(List<DateTime> checkInTimes) {
  final earliest = <DateTime, DateTime>{};
  for (final time in checkInTimes) {
    final day = dateOnly(time);
    final current = earliest[day];
    if (current == null || time.isBefore(current)) earliest[day] = time;
  }
  final days = earliest.keys.toList()..sort();
  return [for (final day in days) earliest[day]!];
}

/// What the check-in histogram has to say: the busiest hour, how many days
/// fall in it, and the two extremes.
class CheckinSummary {
  const CheckinSummary({
    required this.modalHour,
    required this.modalCount,
    required this.dayCount,
    required this.earliest,
    required this.latest,
  });

  /// -1 when there is nothing to summarise.
  final int modalHour;

  final int modalCount;
  final int dayCount;
  final DateTime? earliest;
  final DateTime? latest;
}

CheckinSummary summariseCheckins(List<DateTime> firstCheckIns) {
  if (firstCheckIns.isEmpty) {
    return const CheckinSummary(
      modalHour: -1,
      modalCount: 0,
      dayCount: 0,
      earliest: null,
      latest: null,
    );
  }

  final histogram = checkinHourHistogram(firstCheckIns);
  var modalHour = 0;
  for (var hour = 1; hour < 24; hour++) {
    if (histogram[hour] > histogram[modalHour]) modalHour = hour;
  }

  // Earliest and latest mean time of day, not first and last in the range:
  // the question is how early the day has ever started, not whether that
  // happened in March.
  var earliest = firstCheckIns.first;
  var latest = firstCheckIns.first;
  int minutesOfDay(DateTime t) => t.hour * 60 + t.minute;
  for (final time in firstCheckIns) {
    if (minutesOfDay(time) < minutesOfDay(earliest)) earliest = time;
    if (minutesOfDay(time) > minutesOfDay(latest)) latest = time;
  }

  return CheckinSummary(
    modalHour: modalHour,
    modalCount: histogram[modalHour],
    dayCount: firstCheckIns.length,
    earliest: earliest,
    latest: latest,
  );
}
