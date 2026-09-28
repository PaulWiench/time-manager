/// The jump-to-date dialog (handoff §4.3.7).
///
/// Hand-built rather than a themed `showDatePicker`: Material's header layout
/// cannot be reshaped into this one, and what is actually needed is small — a
/// month to step through, a grid of days, and a button that says where you are
/// about to land.
library;

import 'package:flutter/material.dart' show showDialog;
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
    builder: (context) =>
        AppDatePicker(initial: initial, last: last ?? today, now: today),
  );
}

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
                selected: _selected,
                last: dateOnly(widget.last),
                today: dateOnly(widget.now ?? DateTime.now()),
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

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.last,
    required this.today,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime last;
  final DateTime today;
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
      cells.add(_DayCell(
        date: date,
        isSelected: date == selected,
        isToday: date == today,
        isFuture: date.isAfter(last),
        onTap: () => onSelect(date),
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
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;

  /// Decided by the grid from an injectable `now`, never read from the clock
  /// here — see [AppDatePicker.now].
  final bool isToday;

  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // The tap target is the full 44 dp slot; the 40 dp square inside it is
    // only what gets painted. A day cell you can miss is worse than a day
    // cell that looks slightly loose.
    return PressScale(
      onTap: onTap,
      child: SizedBox(
        height: AppSize.touch,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? colors.selected : null,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: isToday && !isSelected
                  ? Border.all(color: colors.focus, width: AppStroke.focus)
                  : null,
            ),
            child: Text(
              '${date.day}',
              style: (isSelected ? AppTextStyles.bodyStrong : AppTextStyles.body)
                  .copyWith(
                color: isSelected
                    ? colors.onSelected
                    : (isFuture ? colors.textMuted : colors.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
