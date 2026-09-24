/// History's data half: gathers the rows for the current zoom level and hands
/// them to [HistoryBody].
///
/// The per-date providers are watched here rather than inside each row, so the
/// body stays a pure function of a row list — which is what makes every zoom
/// level and every day status renderable without a database.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/database/database.dart';
import '../../domain/date_only.dart';
import '../../providers/day_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/edit_session_sheet.dart';
import 'history_body.dart';
import 'history_view.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryMode _mode = HistoryMode.day;

  /// Which period is on screen. Its year matters in Month mode, its month in
  /// Week mode, its week in Day mode.
  DateTime _anchor = dateOnly(DateTime.now());

  DateTime? _expandedDay;
  String? _selectedBreakId;

  DateTime get _weekStart => startOfWeek(_anchor);

  void _step(int direction) {
    setState(() {
      _anchor = switch (_mode) {
        HistoryMode.month => DateTime(_anchor.year + direction, 1, 1),
        HistoryMode.week => DateTime(_anchor.year, _anchor.month + direction, 1),
        HistoryMode.day => shiftDays(_anchor, 7 * direction),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());

    return HistoryBody(
      mode: _mode,
      stepperLabel: switch (_mode) {
        HistoryMode.month => '${_anchor.year}',
        HistoryMode.week => AppFormat.monthYear(_anchor),
        HistoryMode.day => AppFormat.weekRange(_weekStart, shiftDays(_weekStart, 6)),
      },
      rows: switch (_mode) {
        HistoryMode.month => _monthRows(today),
        HistoryMode.week => _weekRows(today),
        HistoryMode.day => _dayRows(today),
      },
      expandedDay: _expandedDay,
      onModeChanged: (mode) => setState(() {
        _mode = mode;
        _expandedDay = null;
        _selectedBreakId = null;
      }),
      onStep: _step,
      onOpenDatePicker: _jumpToDate,
      onTapRow: _tapRow,
    );
  }

  // ---------------------------------------------------------------------
  // Rows.
  // ---------------------------------------------------------------------

  List<HistoryRow> _monthRows(DateTime today) {
    final year = _anchor.year;
    if (year > today.year) return const [];
    final lastMonth = year == today.year ? today.month : 12;

    return [
      // Newest first: the month you are in is the one you came to look at.
      for (var month = lastMonth; month >= 1; month--)
        _summaryRow(
          start: DateTime(year, month),
          endExclusive: DateTime(year, month + 1),
          today: today,
        ),
    ];
  }

  List<HistoryRow> _weekRows(DateTime today) {
    final monthStart = DateTime(_anchor.year, _anchor.month);
    final monthEnd = DateTime(_anchor.year, _anchor.month + 1);

    final weeks = <DateTime>[];
    for (var week = startOfWeek(monthStart); week.isBefore(monthEnd); week = shiftDays(week, 7)) {
      if (!week.isAfter(today)) weeks.add(week);
    }

    return [
      for (final week in weeks.reversed)
        _summaryRow(start: week, endExclusive: shiftDays(week, 7), today: today),
    ];
  }

  HistoryRow _summaryRow({
    required DateTime start,
    required DateTime endExclusive,
    required DateTime today,
  }) =>
      historySummaryRow(
        mode: _mode,
        start: start,
        endExclusive: endExclusive,
        entries: ref.watch(dayEntriesInRangeProvider(start, endExclusive)).valueOrNull ??
            const [],
        today: today,
      );

  List<HistoryRow> _dayRows(DateTime today) {
    final weekEnd = shiftDays(_weekStart, 7);
    final snapshots =
        ref.watch(balanceSnapshotsInRangeProvider(_weekStart, weekEnd)).valueOrNull ??
            const <BalanceSnapshot>[];

    return [
      for (var i = 0; i < 7; i++) _dayRow(shiftDays(_weekStart, i), today, snapshots),
    ];
  }

  HistoryRow _dayRow(DateTime date, DateTime today, List<BalanceSnapshot> snapshots) {
    final expanded = _expandedDay == date;

    final facts = DayFacts(
      date: date,
      settings: ref.watch(effectiveSettingsForProvider(date)).valueOrNull,
      dayEntry: ref.watch(dayEntryForDateProvider(date)).valueOrNull,
      holiday: ref.watch(publicHolidayForDateProvider(date)).valueOrNull,
      leave: ref.watch(leaveForDateProvider(date)).valueOrNull ?? const [],
      sessions: ref.watch(sessionsForDateProvider(date)).valueOrNull ?? const [],
      breaks: ref.watch(breaksForDateProvider(date)).valueOrNull ?? const [],
      closingBalance: _closingBalance(date, snapshots),
    );

    return historyDayRow(
      facts: facts,
      today: today,
      expanded: expanded,
      selectedBreakId: expanded ? _selectedBreakId : null,
      onEditSession: (session) => EditSessionSheet.show(context, session),
      onSelectBreak: (id) => setState(
        () => _selectedBreakId = _selectedBreakId == id ? null : id,
      ),
      onDeleteBreak: () {
        ref.read(workSessionRepositoryProvider).deleteSyntheticBreak(date);
        setState(() => _selectedBreakId = null);
      },
    );
  }

  double? _closingBalance(DateTime date, List<BalanceSnapshot> snapshots) {
    for (final snapshot in snapshots) {
      if (snapshot.date == date) return snapshot.balance;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Navigation.
  // ---------------------------------------------------------------------

  void _tapRow(HistoryRow row) {
    switch (_mode) {
      case HistoryMode.month:
        setState(() {
          _mode = HistoryMode.week;
          _anchor = row.date;
        });
      case HistoryMode.week:
        setState(() {
          _mode = HistoryMode.day;
          _anchor = row.date;
        });
      case HistoryMode.day:
        setState(() {
          // Only one day is ever open: two expanded rows and the list stops
          // being scannable, which is the whole point of the zoom levels.
          _expandedDay = _expandedDay == row.date ? null : row.date;
          _selectedBreakId = null;
        });
    }
  }

  Future<void> _jumpToDate() async {
    final picked = await showAppDatePicker(context: context, initial: _anchor);
    if (picked == null || !mounted) return;
    setState(() {
      _mode = HistoryMode.day;
      _anchor = picked;
      _expandedDay = picked;
      _selectedBreakId = null;
    });
  }
}
