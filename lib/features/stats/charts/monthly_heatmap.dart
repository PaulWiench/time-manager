/// A calendar month, shaded by how much was worked (handoff §5.6.4).
///
/// Deliberately scoped to one calendar month with its own stepper, independent
/// of the range chips: a flattened six-month window does not lay out as a
/// legible calendar, and the point of this chart is the shape of a month.
///
/// Leave cells are punched rather than shaded — a day off is not a light day.
library;

import 'package:flutter/widgets.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_palette.dart';

class MonthlyHeatmap extends StatelessWidget {
  const MonthlyHeatmap({
    super.key,
    required this.month,
    required this.days,
    required this.leaveDays,
    required this.today,
  });

  final DateTime month;
  final List<DayStat> days;
  final Set<DateTime> leaveDays;
  final DateTime today;

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final colors = context.colors;

    final byDate = {for (final day in days) day.date: day};
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = DateTime(month.year, month.month).weekday - 1;

    final cells = <Widget?>[
      for (var i = 0; i < lead; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        _Cell(
          date: DateTime(month.year, month.month, day),
          stat: byDate[DateTime(month.year, month.month, day)],
          isLeave: leaveDays.contains(DateTime(month.year, month.month, day)),
          isToday: DateTime(month.year, month.month, day) == today,
          isFuture: DateTime(month.year, month.month, day).isAfter(today),
          palette: palette,
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final letter in _weekdayLetters)
              Expanded(
                child: Center(
                  child: Text(letter,
                      style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.s2),
        for (var row = 0; row * 7 < cells.length; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.s2),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++) ...[
                  if (col > 0) const SizedBox(width: AppSpace.s2),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: cells[row * 7 + col] ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpace.s1),
        _Legend(palette: palette),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.date,
    required this.stat,
    required this.isLeave,
    required this.isToday,
    required this.isFuture,
    required this.palette,
  });

  final DateTime date;
  final DayStat? stat;
  final bool isLeave;
  final bool isToday;
  final bool isFuture;
  final ChartPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.cellLg);

    // A day that has not happened is outlined, not shaded: nothing is known
    // about it yet, and shading it grey would claim it was a nil day.
    if (isFuture) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.divider, width: AppStroke.hair),
        ),
      );
    }

    if (isLeave) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: palette.ground,
          borderRadius: radius,
          border: Border.all(color: palette.leave, width: AppStroke.focus),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: palette.leave, shape: BoxShape.circle),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.heatFor(stat?.netWorkedHours ?? 0, stat?.targetHours ?? 0),
        borderRadius: radius,
        border: isToday
            ? Border.all(color: palette.highlight, width: AppStroke.focus)
            : null,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.palette});

  final ChartPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Text('Less', style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
        const SizedBox(width: AppSpace.s2),
        for (final step in palette.heat)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: step,
                borderRadius: BorderRadius.circular(AppRadius.cell),
              ),
            ),
          ),
        const SizedBox(width: AppSpace.s1),
        Text('More', style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
        const Spacer(),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: palette.ground,
            borderRadius: BorderRadius.circular(AppRadius.cell),
            border: Border.all(color: palette.leave, width: AppStroke.focus),
          ),
        ),
        const SizedBox(width: AppSpace.s1),
        Text('Leave', style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
      ],
    );
  }
}
