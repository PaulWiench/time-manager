/// The jump-to-date dialog (handoff §4.3.7).
///
/// Hand-built rather than a themed `showDatePicker`: Material's header layout
/// cannot be reshaped into this one, and what is actually needed is small — a
/// month to step through, a grid of days, and a button that says where you are
/// about to land.
library;

import 'package:flutter/material.dart' show Material, MaterialType, showDialog;
import 'package:flutter/widgets.dart';

import '../core/format.dart';
import '../core/icons/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text_styles.dart';
import '../domain/date_only.dart';
import 'buttons.dart';
import 'press_scale.dart';

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initial,
  DateTime? last,
  DateTime? now,
}) {
  final colors = context.colors;
  final today = now ?? DateTime.now();

  return showDialog<DateTime>(
    context: context,
    barrierColor: colors.scrim,
    builder: (context) => _dialogSurface(
      AppDatePicker(initial: initial, last: last ?? today, now: today),
    ),
  );
}

/// A dialog's own Material.
///
/// `showModalBottomSheet` supplies one, which is why the sheets never needed
/// this; `showDialog` does not, and without it every `Text` inside renders with
/// Flutter's yellow "no Material ancestor" underlines. The render harness wraps
/// its children in a transparent Material for its own reasons — Switch and
/// InkWell assert without one — so the goldens looked right and only the phone
/// showed it.
Widget _dialogSurface(Widget child) =>
    Material(type: MaterialType.transparency, child: child);

class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    super.key,
    required this.initial,
    required this.last,
    this.now,
  });

  final DateTime initial;

  /// Days after this are shown but muted — there is nothing logged there yet.
  final DateTime last;

  /// Which day gets the "today" outline. Injectable because a widget that
  /// reads the clock itself cannot be rendered to a stable golden — this one
  /// used to, and its render drifted by a day every day.
  final DateTime? now;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  late DateTime _selected = dateOnly(widget.initial);
  late DateTime _month = DateTime(widget.initial.year, widget.initial.month);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: colors.shadowFloat,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JUMP TO DATE',
                  style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpace.s3),
              Row(
                children: [
                  Expanded(
                    child: Text(AppFormat.monthYear(_month),
                        style: AppTextStyles.headline.copyWith(color: colors.text)),
                  ),
                  AppIconButton(
                    icon: AppIcons.caretLeft,
                    semanticLabel: 'Previous month',
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1)),
                  ),
                  AppIconButton(
                    icon: AppIcons.caretRight,
                    semanticLabel: 'Next month',
                    onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s3),
              _MonthGrid(
                month: _month,
                today: dateOnly(widget.now ?? DateTime.now()),
                stateFor: (date) {
                  if (date == _selected) return _CellState.selected;
                  // Days past `last` are shown and still tappable — there is
                  // simply nothing logged there yet.
                  return date.isAfter(dateOnly(widget.last))
                      ? _CellState.muted
                      : _CellState.plain;
                },
                onSelect: (date) => setState(() => _selected = date),
              ),
              const SizedBox(height: AppSpace.s3),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTextButton(
                    label: 'Cancel',
                    emphasis: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  PrimaryPill(
                    label: 'Go to ${AppFormat.dayAndMonth(_selected)}',
                    expand: false,
                    height: AppSize.touch,
                    onPressed: () => Navigator.of(context).pop(_selected),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picks the days of a vacation: tap the first, tap the last, then tap any day
/// between to drop it or put it back.
///
/// Returns the days actually chosen, already filtered — never a start/end pair.
/// Callers book what they are handed and do not repeat the workday rules.
Future<Set<DateTime>?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime initialMonth,
  required bool Function(DateTime) bookable,
  DateTime? now,
}) {
  final colors = context.colors;

  return showDialog<Set<DateTime>>(
    context: context,
    barrierColor: colors.scrim,
    builder: (context) => _dialogSurface(
      AppDateRangePicker(
        initialMonth: initialMonth,
        bookable: bookable,
        now: now ?? DateTime.now(),
      ),
    ),
  );
}

class AppDateRangePicker extends StatefulWidget {
  const AppDateRangePicker({
    super.key,
    required this.initialMonth,
    required this.bookable,
    required this.now,
  });

  final DateTime initialMonth;

  /// Whether a day can hold leave at all. In practice
  /// `computeTargetHours(...) > 0`, which folds rest days and full public
  /// holidays into one question and still lets a half-day holiday through.
  final bool Function(DateTime) bookable;

  final DateTime now;

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  late DateTime _month = DateTime(widget.initialMonth.year, widget.initialMonth.month);

  DateTime? _start;
  DateTime? _end;

  /// Days inside the range that were tapped off. Kept apart from the range
  /// itself so that dragging the range wider brings them back into play
  /// without remembering a decision made about a different span.
  final _excluded = <DateTime>{};

  bool get _complete => _start != null && _end != null;

  void _tap(DateTime date) {
    setState(() {
      if (!_complete) {
        if (_start == null) {
          _start = date;
          return;
        }
        // Tapping backwards is a perfectly ordinary way to pick a range.
        if (date.isBefore(_start!)) {
          _end = _start;
          _start = date;
        } else {
          _end = date;
        }
        return;
      }

      // With both ends fixed, a tap inside the span adjusts it and a tap
      // outside starts over. Anything else would make the second range
      // impossible to draw without a reset button.
      if (!date.isBefore(_start!) && !date.isAfter(_end!)) {
        if (!_excluded.remove(date)) _excluded.add(date);
        return;
      }
      _start = date;
      _end = null;
      _excluded.clear();
    });
  }

  /// Every day in the span, split by why it is or is not being booked.
  ({List<DateTime> booked, int skipped, int dropped}) get _tally {
    final start = _start;
    if (start == null) return (booked: const [], skipped: 0, dropped: 0);
    final end = _end ?? start;

    final booked = <DateTime>[];
    var skipped = 0;
    var dropped = 0;
    for (var d = start; !d.isAfter(end); d = shiftDays(d, 1)) {
      if (!widget.bookable(d)) {
        skipped++;
      } else if (_excluded.contains(d)) {
        dropped++;
      } else {
        booked.add(d);
      }
    }
    return (booked: booked, skipped: skipped, dropped: dropped);
  }

  _CellState _stateFor(DateTime date) {
    if (!widget.bookable(date)) return _CellState.disabled;

    final start = _start;
    if (start == null) return _CellState.plain;
    final end = _end ?? start;

    if (date.isBefore(start) || date.isAfter(end)) return _CellState.plain;
    return _excluded.contains(date) ? _CellState.excluded : _CellState.selected;
  }

  String get _summary {
    final tally = _tally;
    if (_start == null) return 'Tap the first day';
    if (_end == null) return 'Now tap the last day';

    final days = tally.booked.length;
    return [
      '$days day${days == 1 ? '' : 's'}',
      if (tally.skipped > 0) '${tally.skipped} not workdays',
      if (tally.dropped > 0) '${tally.dropped} dropped',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final booked = _tally.booked;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.s5),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s5),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: colors.shadowFloat,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PICK THE DAYS',
                  style: AppTextStyles.kicker.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpace.s3),
              Row(
                children: [
                  Expanded(
                    child: Text(AppFormat.monthYear(_month),
                        style: AppTextStyles.headline.copyWith(color: colors.text)),
                  ),
                  AppIconButton(
                    icon: AppIcons.caretLeft,
                    semanticLabel: 'Previous month',
                    onPressed: () => setState(() => _month = shiftMonths(_month, -1)),
                  ),
                  AppIconButton(
                    icon: AppIcons.caretRight,
                    semanticLabel: 'Next month',
                    onPressed: () => setState(() => _month = shiftMonths(_month, 1)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s3),
              _MonthGrid(
                month: _month,
                today: dateOnly(widget.now),
                stateFor: _stateFor,
                onSelect: _tap,
              ),
              const SizedBox(height: AppSpace.s3),
              // The count is the whole point of the range: it is what tells
              // you whether "the 12th to the 23rd" is the eight days you
              // meant to book.
              Text(_summary,
                  style: AppTextStyles.caption.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpace.s3),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppTextButton(
                    label: 'Cancel',
                    emphasis: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  PrimaryPill(
                    label: booked.isEmpty
                        ? 'Continue'
                        : 'Continue with ${booked.length}',
                    expand: false,
                    height: AppSize.touch,
                    onPressed: booked.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(booked.toSet()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How one day in the grid is drawn, and whether it can be tapped at all.
enum _CellState {
  /// Tappable, nothing special about it.
  plain,

  /// In the selection.
  selected,

  /// Inside the chosen range, but tapped off.
  excluded,

  /// Dimmed but still tappable — a date with nothing logged on it yet.
  muted,

  /// Nothing can be booked here: a rest day, or a full public holiday.
  disabled,
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.stateFor,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final _CellState Function(DateTime) stateFor;
  final ValueChanged<DateTime> onSelect;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first, so the leading blanks are however far into the week the
    // first of the month falls.
    final lead = first.weekday - 1;
    final cells = <Widget>[];

    for (var i = 0; i < lead; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final state = stateFor(date);
      cells.add(_DayCell(
        date: date,
        state: state,
        isToday: date == today,
        onTap: state == _CellState.disabled ? null : () => onSelect(date),
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return SizedBox(
      width: 7 * 44,
      child: Column(
        children: [
          Row(
            children: [
              for (final letter in _letters)
                Expanded(
                  child: Center(
                    child: Text(letter,
                        style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.s1),
          for (var row = 0; row < cells.length / 7; row++)
            Row(
              children: [
                // The 2 dp gutter between cells belongs to the cell, not to
                // this grid: it is what lets a 40 dp square fill a 44 dp tap
                // target without growing.
                for (var col = 0; col < 7; col++)
                  Expanded(child: cells[row * 7 + col]),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.state,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final _CellState state;

  /// Decided by the grid from an injectable `now`, never read from the clock
  /// here — see [AppDatePicker.now].
  final bool isToday;

  /// Null on a day that cannot be chosen.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = state == _CellState.selected;

    final fill = selected ? colors.selected : null;
    // An excluded day keeps the range's outline so it still reads as part of
    // the span you picked — it is a hole in the booking, not a day outside it.
    final border = switch (state) {
      _CellState.excluded =>
        Border.all(color: colors.selected, width: AppStroke.focus),
      _ when isToday && !selected =>
        Border.all(color: colors.focus, width: AppStroke.focus),
      _ => null,
    };

    // The tap target is the full 44 dp slot; the 40 dp square inside it is
    // only what gets painted. A day cell you can miss is worse than a day
    // cell that looks slightly loose.
    final cell = SizedBox(
      height: AppSize.touch,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: border,
          ),
          child: Text(
            '${date.day}',
            style: (selected ? AppTextStyles.bodyStrong : AppTextStyles.body).copyWith(
              color: switch (state) {
                _CellState.selected => colors.onSelected,
                _CellState.muted || _CellState.disabled => colors.textMuted,
                _ => colors.text,
              },
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      // Still announced, so a screen reader can tell a rest day from the end
      // of the month rather than finding a silent gap in the grid.
      return Semantics(enabled: false, label: '${date.day}, not a workday', child: cell);
    }
    return PressScale(onTap: onTap, child: cell);
  }
}
