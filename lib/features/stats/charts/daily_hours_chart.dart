/// One bar per day against the target line (handoff §5.6.5). Long ranges
/// pass one bar per week or month instead, each the average worked day in it.
///
/// Weekends get a stub rather than nothing, so the week's rhythm is visible in
/// the gaps — a run of five bars and two stubs reads as a working week without
/// anything having to say so.
library;

import 'package:flutter/widgets.dart';

import '../../../core/format.dart';
import '../../../core/painting/dashed_border.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/date_only.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_palette.dart';

const double _plotHeight = 130;

class DailyHoursChart extends StatelessWidget {
  const DailyHoursChart({
    super.key,
    required this.days,
    this.bucket = HoursBucket.day,
    required this.today,
    required this.targetHours,
  });

  final List<DayStat> days;

  /// What one entry of [days] stands for; each bar starts at its `date`.
  final HoursBucket bucket;
  final DateTime today;

  /// The scheduled hours for a normal workday, drawn as the dashed line.
  final double targetHours;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final colors = context.colors;

    var maxY = targetHours;
    for (final day in days) {
      if (day.netWorkedHours > maxY) maxY = day.netWorkedHours;
    }
    maxY = maxY * 1.15;
    final targetFraction = maxY > 0 ? targetHours / maxY : 0.0;

    return SizedBox(
      height: _plotHeight + 16,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, day) in days.indexed) ...[
                  // Fixed gaps alone outgrow the row once there are a few
                  // dozen bars, so they thin out as the bars do.
                  if (i > 0) SizedBox(width: days.length > 40 ? 1 : AppSpace.s1),
                  Expanded(
                    child: _Bar(
                      day: day,
                      maxY: maxY,
                      isToday: _contains(day.date, today),
                      palette: palette,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // The target is a line across the whole plot rather than a tick on
          // an axis: every bar is being compared to it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 16 + _plotHeight * targetFraction,
            child: DashedLine(color: palette.baseline),
          ),
          Positioned(
            left: 0,
            bottom: 16 + _plotHeight * targetFraction + 4,
            child: Text('${AppFormat.hm(targetHours)} target',
                style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
          ),
        ],
      ),
    );
  }

  bool _contains(DateTime start, DateTime day) {
    final date = dateOnly(day);
    return !date.isBefore(start) && date.isBefore(bucketEnd(start, bucket));
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.maxY,
    required this.isToday,
    required this.palette,
  });

  final DayStat day;
  final double maxY;
  final bool isToday;
  final ChartPalette palette;

  @override
  Widget build(BuildContext context) {
    // A day with no scheduled hours and nothing logged is a weekend: it gets a
    // stub, not a missing column.
    final isRestDay = day.targetHours <= 0 && day.netWorkedHours <= 0;
    final height = isRestDay
        ? 2.0
        : (maxY > 0 ? (day.netWorkedHours / maxY) * _plotHeight : 0.0).clamp(2.0, _plotHeight);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isRestDay
              ? palette.inactive
              : (isToday ? palette.highlight : palette.mark),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
