/// Six months of plausible history, so the Stats charts have something real
/// to draw (handoff §4.4).
///
/// Generated rather than typed out, but deterministically: the same seedless
/// pseudo-random walk every run, because a render that changes shape between
/// runs is worth nothing as a reference.
library;

import 'package:time_manager/domain/date_only.dart';
import 'package:time_manager/domain/stats_aggregation.dart';
import 'package:time_manager/domain/vacation_bookings.dart';
import 'package:time_manager/features/stats/stats_view.dart';

final today = DateTime(2026, 9, 22);

const _target = 7.9; // 7:54

/// A repeatable sequence in [0, 1) — `Math.random` is unavailable in these
/// tests by design, and a fixed walk is what makes the renders comparable.
class _Wobble {
  int _state = 0x2f6e2b1;

  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return (_state >> 8) / 0x7fffff;
  }
}

/// One entry per calendar day over the trailing [days], with weekends empty
/// and workdays scattered around the target.
List<DayStat> _history(int days, {required DateTime end}) {
  final wobble = _Wobble();
  final start = shiftDays(end, -(days - 1));
  final stats = <DayStat>[];

  for (var i = 0; i < days; i++) {
    final date = shiftDays(start, i);
    final isWorkday = date.weekday <= 5;
    if (!isWorkday) {
      stats.add(DayStat(date: date, netWorkedHours: 0, targetHours: 0, balanceDelta: 0));
      continue;
    }
    // A handful of missed days, and otherwise somewhere between six and nine
    // and a half hours.
    final missed = wobble.next() < 0.06;
    final worked = missed ? 0.0 : 6.0 + wobble.next() * 3.5;
    stats.add(DayStat(
      date: date,
      netWorkedHours: worked,
      targetHours: _target,
      balanceDelta: worked - _target,
    ));
  }
  return stats;
}

List<BalancePoint> _balanceFrom(List<DayStat> days, {required double startingBalance}) {
  var running = startingBalance;
  return [
    for (final day in days)
      BalancePoint(date: day.date, balance: running += day.balanceDelta),
  ];
}

OverviewData overview({int days = 182}) {
  final history = _history(days, end: today);
  return OverviewData(
    balance: _balanceFrom(history, startingBalance: 4.75),
    weeks: weeklyAggregates(history),
    today: today,
  );
}

/// A single week: enough to draw, not enough to say anything, which is the
/// point of the not-enough-data state.
OverviewData sparseOverview() {
  final history = _history(7, end: today);
  return OverviewData(
    balance: [_balanceFrom(history, startingBalance: -15.9).first],
    weeks: const [],
    today: today,
  );
}

PatternsData patterns({int days = 30, HoursBucket bucket = HoursBucket.day}) {
  final history = _history(days, end: today);
  final month = DateTime(2026, 9);
  final monthDays = [
    for (final day in history)
      if (day.date.year == month.year && day.date.month == month.month) day,
  ];

  final checkIns = <DateTime>[
    for (final day in history)
      if (day.netWorkedHours > 0)
        DateTime(day.date.year, day.date.month, day.date.day, 7 + (day.date.day % 3),
            (day.date.day * 7) % 60),
  ];

  return PatternsData(
    month: month,
    monthDays: monthDays,
    leaveDays: {DateTime(2026, 9, 4)},
    days: history,
    dailyBars: bucketDailyHours(history, bucket),
    hoursBucket: bucket,
    weekdayAverages: averageHoursByWeekday(history),
    checkinHistogram: checkinHourHistogram(checkIns),
    checkins: summariseCheckins(checkIns),
    today: today,
  );
}

/// Paul's own 2026: thirteen vacation days taken, three more booked for the
/// end of September, one sick day and a half-day of flex.
LeaveData leave() => LeaveData(
      year: 2026,
      totalDays: 30,
      usedDays: 13,
      plannedDays: 3,
      sickDays: 1,
      flexDays: 0.5,
      vacations: groupVacations(
        [
          for (final d in [26, 27, 28, 29, 30])
            VacationDay(date: DateTime(2026, 10, d), vacationId: 'autumn', days: 1),
          for (final d in [31])
            VacationDay(date: DateTime(2026, 8, d), vacationId: 'sea', days: 1),
          for (final d in [1, 2, 3, 4, 7, 8, 9, 10, 11])
            VacationDay(date: DateTime(2026, 9, d), vacationId: 'sea', days: 1),
          VacationDay(date: DateTime(2026, 7, 17), vacationId: 'bridge', days: 1),
          VacationDay(date: DateTime(2026, 7, 20), vacationId: 'bridge', days: 1),
          VacationDay(date: DateTime(2026, 6, 5), vacationId: 'june', days: 1),
        ],
        names: {'autumn': 'Herbstferien', 'sea': 'Sommer an der Ostsee', 'june': 'Brückentag'},
        today: DateTime(2026, 10, 1),
      ),
    );
