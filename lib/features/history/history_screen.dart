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
import '../../domain/recalculation_engine.dart';
import '../../providers/day_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stats_providers.dart';
import '../../widgets/app_date_picker.dart';
import '../../widgets/edit_session_sheet.dart';
import '../../widgets/leave_sheet.dart';
import 'history_body.dart';
import 'history_view.dart';
import '../../providers/job_providers.dart';

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

  /// The last fully-loaded row list, and the level it belongs to.
  ///
  /// Every provider here is read as `valueOrNull ?? const []`, so stepping to a
  /// new period — which instantiates fresh family providers — used to render
  /// one frame of zero-hour rows with no balance, and therefore no warning
  /// treatment, before the real data landed and the pale-yellow band snapped
  /// in. `BandedNumber` deliberately overhangs its own bounds unclipped, so it
  /// painted over its neighbours on the way. Holding the previous rows for that
  /// frame costs nothing and removes the flash.
  List<HistoryRow> _loaded = const [];
  HistoryMode? _loadedMode;

  /// Set by [_settled] while the rows are being built.
  bool _pending = false;

  T _settled<T>(AsyncValue<T> value, T fallback) {
    if (!value.hasValue) _pending = true;
    return value.valueOrNull ?? fallback;
  }

  void _step(int direction) {
    if (direction > 0 && !_canStepForward) return;
    setState(() {
      _anchor = stepAnchor(mode: _mode, anchor: _anchor, direction: direction);
    });
  }

  bool get _canStepForward => canStepForward(
        mode: _mode,
        anchor: _anchor,
        today: dateOnly(DateTime.now()),
      );

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());

    _pending = false;
    final built = switch (_mode) {
      HistoryMode.month => _monthRows(today),
      HistoryMode.week => _weekRows(today),
      HistoryMode.day => _dayRows(today),
    };
    if (!_pending) {
      _loaded = built;
      _loadedMode = _mode;
    }
    // A half-loaded list is worse than the one before it — but only if the one
    // before it was the same kind of list. Across a level change there is
    // nothing honest to hold, so it shows nothing for the frame.
    final rows = !_pending
        ? built
        : _loadedMode == _mode
            ? _loaded
            : const <HistoryRow>[];

    return HistoryBody(
      mode: _mode,
      stepperLabel: switch (_mode) {
        HistoryMode.month => '${_anchor.year}',
        HistoryMode.week => AppFormat.monthYear(_anchor),
        HistoryMode.day => AppFormat.weekRange(_weekStart, shiftDays(_weekStart, 6)),
      },
      rows: rows,
      expandedDay: _expandedDay,
      onModeChanged: (mode) => setState(() {
        _mode = mode;
        _expandedDay = null;
        _selectedBreakId = null;
      }),
      onStep: _step,
      canStepForward: _canStepForward,
      onOpenDatePicker: _jumpToDate,
      onTapRow: _tapRow,
      // Day mode only: a month or a week row stands for a range, so there is
      // no single date to mark as leave.
      onLongPressRow: _mode == HistoryMode.day ? (row) => _editLeave(row.date) : null,
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
        entries: _settled(
          ref.watch(dayEntriesInRangeProvider(start, endExclusive)),
          const <DayEntry>[],
        ),
        today: today,
      );

  List<HistoryRow> _dayRows(DateTime today) {
    final weekEnd = shiftDays(_weekStart, 7);
    final snapshots = _settled(
      ref.watch(balanceSnapshotsInRangeProvider(_weekStart, weekEnd)),
      const <BalanceSnapshot>[],
    );

    // The day before the week is needed too: whether Monday *crossed* a bound
    // depends on where the balance stood on Sunday.
    final previous = _settled(
      ref.watch(balanceSnapshotsInRangeProvider(shiftDays(_weekStart, -1), _weekStart)),
      const <BalanceSnapshot>[],
    );

    return [
      for (var i = 0; i < 7; i++)
        _dayRow(
          shiftDays(_weekStart, i),
          today,
          [...previous, ...snapshots],
        ),
    ];
  }

  HistoryRow _dayRow(DateTime date, DateTime today, List<BalanceSnapshot> snapshots) {
    final expanded = _expandedDay == date;
    final now = DateTime.now();
    final active = date == today ? ref.watch(activeSessionProvider).valueOrNull : null;

    final facts = DayFacts(
      date: date,
      settings: _settled(ref.watch(effectiveSettingsForProvider(date)), null),
      dayEntry: _settled(ref.watch(dayEntryForDateProvider(date)), null),
      holiday: _settled(ref.watch(publicHolidayForDateProvider(date)), null),
      leave: _settled(ref.watch(leaveForDateProvider(date)), const <LeaveEntry>[]),
      sessions: _settled(ref.watch(sessionsForDateProvider(date)), const <WorkSession>[]),
      breaks: _settled(ref.watch(breaksForDateProvider(date)), const <BreakEntry>[]),
      closingBalance: _closingBalance(date, snapshots),
      previousClosingBalance: _closingBalance(shiftDays(date, -1), snapshots),
      runningSince: active?.startTime,
      now: now,
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
        final jobId = ref.read(selectedJobIdProvider);
        if (jobId != null) {
          ref.read(workSessionRepositoryProvider).deleteSyntheticBreak(jobId, date);
        }
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

  /// Long-pressing a day opens the leave editor. Every provider read here is
  /// already being watched by the row that was pressed, so none of them is
  /// cold.
  Future<void> _editLeave(DateTime date) async {
    final settings = ref.read(effectiveSettingsForProvider(date)).valueOrNull;
    if (settings == null) return;

    final existing =
        ref.read(leaveForDateProvider(date)).valueOrNull ?? const <LeaveEntry>[];
    final targetHours = ref.read(dayEntryForDateProvider(date)).valueOrNull?.targetHours ??
        computeTargetHours(
          date: date,
          workDays: settings.workDays,
          weeklyHours: settings.weeklyHours,
          holidayFraction: ref.read(publicHolidayForDateProvider(date)).valueOrNull?.fraction,
        );

    final edit = await showLeaveSheet(
      context: context,
      dates: [date],
      targetFor: (_) => targetHours,
      existing: existing,
    );
    if (edit == null || !mounted) return;

    // Both paths replace rather than accumulate. A day has one kind of leave;
    // leaving the old row behind would double it against the quota and against
    // the day's balance.
    final repo = ref.read(leaveRepositoryProvider);
    final jobId = ref.read(selectedJobIdProvider);
    if (jobId == null) return;
    if (edit.cleared) {
      await repo.clearLeaveForDates(jobId, [date]);
    } else {
      await repo.setLeaveForDates(
        jobId: jobId,
        hoursByDate: {date: edit.hoursFor(targetHours)},
        type: edit.type!,
        vacationName: edit.name,
      );
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
