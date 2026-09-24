/// Stats' data half: resolves the range, gathers the aggregates, hands them to
/// [StatsBody].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../domain/stats_aggregation.dart';
import '../../providers/day_providers.dart';
import '../../providers/stats_providers.dart';
import 'stats_body.dart';
import 'stats_view.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  StatsTab _tab = StatsTab.overview;
  StatsRange _range = StatsRange.month;
  DateRange? _customRange;

  /// The heatmap steps through months on its own; Leave steps through years.
  /// Both deliberately ignore the range chips.
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _leaveYear = DateTime.now().year;

  DateRange _resolveRange(DateTime today) {
    final days = _range.trailingDays;
    if (days != null) return trailingRange(days, today: today);
    return _customRange ?? trailingRange(30, today: today);
  }

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final range = _resolveRange(today);

    return StatsBody(
      tab: _tab,
      range: _range,
      customRangeLabel: _customRange == null ? null : _customLabel(_customRange!),
      overview: _tab == StatsTab.overview ? _overview(range, today) : null,
      patterns: _tab == StatsTab.patterns ? _patterns(range, today) : null,
      leave: _tab == StatsTab.leave ? _leave() : null,
      onTabChanged: (tab) => setState(() => _tab = tab),
      onRangeChanged: (value) {
        if (value == StatsRange.custom) {
          _pickCustomRange();
        } else {
          setState(() => _range = value);
        }
      },
      onStepMonth: (direction) =>
          setState(() => _month = DateTime(_month.year, _month.month + direction)),
      onStepYear: (direction) => setState(() => _leaveYear += direction),
    );
  }

  // ---------------------------------------------------------------------
  // Aggregates.
  // ---------------------------------------------------------------------

  List<DayStat> _dayStats(List<DayEntry> entries) => [
        for (final entry in entries)
          DayStat(
            date: entry.date,
            netWorkedHours: entry.netWorkedHours,
            targetHours: entry.targetHours,
            balanceDelta: entry.balanceDelta,
          ),
      ];

  OverviewData _overview(DateRange range, DateTime today) {
    final snapshots =
        ref.watch(balanceSnapshotsInRangeProvider(range.start, range.endExclusive)).valueOrNull ??
            const <BalanceSnapshot>[];
    final entries =
        ref.watch(dayEntriesInRangeProvider(range.start, range.endExclusive)).valueOrNull ??
            const <DayEntry>[];

    return OverviewData(
      balance: [
        for (final snapshot in snapshots)
          BalancePoint(date: snapshot.date, balance: snapshot.balance),
      ],
      weeks: weeklyAggregates(_dayStats(entries)),
      today: today,
    );
  }

  PatternsData _patterns(DateRange range, DateTime today) {
    final entries =
        ref.watch(dayEntriesInRangeProvider(range.start, range.endExclusive)).valueOrNull ??
            const <DayEntry>[];
    final sessions =
        ref.watch(workSessionsInRangeProvider(range.start, range.endExclusive)).valueOrNull ??
            const <WorkSession>[];

    final monthEnd = DateTime(_month.year, _month.month + 1);
    final monthEntries =
        ref.watch(dayEntriesInRangeProvider(_month, monthEnd)).valueOrNull ?? const <DayEntry>[];

    final firstCheckIns = firstCheckInPerDay([
      for (final session in sessions)
        if (session.status != SessionStatus.discarded) session.startTime,
    ]);

    return PatternsData(
      month: _month,
      monthDays: _dayStats(monthEntries),
      // A day is "leave" for the heatmap when it logged leave hours and no
      // work — a half day of each is still a day that was partly worked.
      leaveDays: {
        for (final entry in monthEntries)
          if (entry.leaveHours > 0 && entry.netWorkedHours <= 0) entry.date,
      },
      days: _dayStats(entries),
      weekdayAverages: averageHoursByWeekday(_dayStats(entries)),
      checkinHistogram: checkinHourHistogram(firstCheckIns),
      checkins: summariseCheckins(firstCheckIns),
      today: today,
    );
  }

  LeaveData _leave() {
    final quota = ref.watch(vacationQuotaForYearProvider(_leaveYear)).valueOrNull;
    final entries = ref.watch(leaveForYearProvider(_leaveYear)).valueOrNull ?? const [];

    var vacationHours = 0.0;
    var sickHours = 0.0;
    for (final entry in entries) {
      switch (entry.type) {
        case LeaveType.vacation:
          vacationHours += entry.hours;
        case LeaveType.sick:
          sickHours += entry.hours;
        case LeaveType.flexDay:
          break;
      }
    }

    return LeaveData(
      year: _leaveYear,
      totalDays: (quota?.totalDays ?? 30) + (quota?.rolloverDays ?? 0),
      usedDays: vacationHours / kLeaveHoursPerDay,
      sickDays: sickHours / kLeaveHoursPerDay,
    );
  }

  // ---------------------------------------------------------------------
  // Custom range.
  // ---------------------------------------------------------------------

  static final _dayMonth = DateFormat('d MMM');
  static final _dayMonthYear = DateFormat('d MMM yyyy');

  String _customLabel(DateRange range) {
    final last = shiftDays(range.endExclusive, -1);
    return '${_dayMonth.format(range.start)} – ${_dayMonthYear.format(last)}';
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final current = _customRange;
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: current?.start ?? shiftDays(now, -29),
        end: current != null ? shiftDays(current.endExclusive, -1) : now,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _range = StatsRange.custom;
      _customRange = DateRange(
        start: dateOnly(result.start),
        endExclusive: shiftDays(dateOnly(result.end), 1),
      );
    });
  }
}
