/// Stats' data half: resolves the range, gathers the aggregates, hands them to
/// [StatsBody].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';
import '../../data/database/enums.dart';
import '../../domain/date_only.dart';
import '../../domain/leave_days.dart';
import '../../domain/recalculation_engine.dart';
import '../../domain/stats_aggregation.dart';
import '../../providers/balance_providers.dart';
import '../../providers/day_providers.dart';
import '../../providers/holiday_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stats_providers.dart';
import 'stats_body.dart';
import 'stats_view.dart';
import '../../providers/job_providers.dart';
import '../../providers/vacation_providers.dart';
import '../../widgets/edit_vacation_sheet.dart';
import '../jobs/job_pill.dart';

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
      jobPill: ref.watch(hasSeveralJobsProvider) ? const JobPill() : null,
      tab: _tab,
      range: _range,
      customRangeLabel: _customRange == null ? null : _customLabel(_customRange!),
      overview: _tab == StatsTab.overview ? _overview(range, today) : null,
      patterns: _tab == StatsTab.patterns ? _patterns(range, today) : null,
      leave: _tab == StatsTab.leave ? _leave(today) : null,
      onOpenVacation: (booking) => showEditVacationSheet(context, booking),
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

    // Today's stored snapshot is a full-day shortfall until the day has been
    // worked, so plotting it made the trend dip every afternoon and recover
    // overnight. The settled days are plotted as recorded and today is
    // appended under the same rule Home prints.
    final displayed = ref.watch(displayedBalanceProvider(DateTime.now()));

    return OverviewData(
      balance: [
        for (final snapshot in snapshots)
          if (snapshot.date.isBefore(today))
            BalancePoint(date: snapshot.date, balance: snapshot.balance),
        if (!range.endExclusive.isBefore(today))
          BalancePoint(date: today, balance: displayed.hours),
      ],
      // Future day entries — a vacation booked for next month — are excluded
      // from the balance cascade but would otherwise land in a weekly bar,
      // crediting hours nobody has taken yet.
      weeks: weeklyAggregates(
        _dayStats([for (final e in entries) if (!e.date.isAfter(today)) e]),
      ),
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
      // Public holidays count too: they carry no leave hours, so they used to
      // be drawn as an ordinary blank cell, indistinguishable from a day that
      // was simply not worked.
      leaveDays: {
        for (final entry in monthEntries)
          if (entry.leaveHours > 0 && entry.netWorkedHours <= 0) entry.date,
        for (final holiday in ref
                .watch(publicHolidaysForYearProvider(_month.year))
                .valueOrNull ??
            const <PublicHoliday>[])
          if (holiday.date.month == _month.month && holiday.date.year == _month.year)
            holiday.date,
      },
      days: _dayStats(entries),
      dailyBars: bucketDailyHours(
        // A year of months is twelve bars, this month included: the trailing
        // 365 days would also catch a sliver of the same month a year ago.
        _dayStats([
          for (final e in entries)
            if (hoursBucketFor(range) != HoursBucket.month ||
                !e.date.isBefore(DateTime(today.year, today.month - 11)))
              e,
        ]),
        hoursBucketFor(range),
      ),
      hoursBucket: hoursBucketFor(range),
      // A vacation booked for next month is not a short day yet.
      weekdayAverages: averageHoursByWeekday(
        _dayStats([for (final e in entries) if (!e.date.isAfter(today)) e]),
      ),
      checkinHistogram: checkinHourHistogram(firstCheckIns),
      checkins: summariseCheckins(firstCheckIns),
      today: today,
    );
  }

  LeaveData _leave(DateTime today) {
    final entitlement = ref.watch(vacationEntitlementProvider(_leaveYear));
    final entries = ref.watch(leaveForYearProvider(_leaveYear)).valueOrNull ?? const [];

    // Each entry against its own date's target, not against a flat 8 hours: a
    // full day here is weeklyHours / workDays.length, 7.9 for a 39.5 h week, so
    // sixteen whole vacation days used to come out as 15.8 and no whole number
    // was reachable at all.
    final dayEntries = ref
            .watch(dayEntriesInRangeProvider(
                DateTime(_leaveYear), DateTime(_leaveYear + 1)))
            .valueOrNull ??
        const <DayEntry>[];
    final targets = {for (final day in dayEntries) day.date: day.targetHours};
    final settings = ref.watch(latestSettingsProvider).valueOrNull;

    double daysFor(LeaveEntry entry) {
      final target = targets[dateOnly(entry.date)] ??
          (settings == null
              ? 0
              : computeTargetHours(
                  date: entry.date,
                  workDays: settings.workDays,
                  weeklyHours: settings.weeklyHours,
                ));
      return leaveDaysFor(hours: entry.hours, targetHours: target);
    }

    var used = 0.0;
    var planned = 0.0;
    var sick = 0.0;
    var flex = 0.0;
    for (final entry in entries) {
      final days = daysFor(entry);
      switch (entry.type) {
        case LeaveType.vacation:
          // Booked for a date still ahead is planned, not taken.
          if (entry.date.isAfter(today)) {
            planned += days;
          } else {
            used += days;
          }
        case LeaveType.sick:
          sick += days;
        // Flex days used to fall through a bare `break` and vanish from Stats
        // entirely, while still counting in the balance.
        case LeaveType.flexDay:
          flex += days;
      }
    }

    return LeaveData(
      year: _leaveYear,
      totalDays: entitlement?.totalDays ?? 30,
      usedDays: used,
      plannedDays: planned,
      sickDays: sick,
      flexDays: flex,
      vacations: ref.watch(vacationBookingsProvider(_leaveYear)),
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
