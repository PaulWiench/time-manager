/// One bar per day against the target line (handoff §5.6.5). Long ranges
/// pass one bar per week or month instead, each the average worked day in it
/// (additions handoff §6).
///
/// Weekends get a stub rather than nothing, so the week's rhythm is visible in
/// the gaps — a run of five bars and two stubs reads as a working week without
/// anything having to say so. A week or month with no worked day gets the
/// same stub.
library;

import 'dart:math' as math;

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
const double _axisLine = 12;

/// The y axis runs from zero to at least this, so an average is drawn against
/// a whole day rather than against a baseline cut off at 6 h.
const double _minTopHours = 10;

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

    var maxY = math.max(targetHours, _minTopHours);
    for (final day in days) {
      if (day.netWorkedHours > maxY) maxY = day.netWorkedHours;
    }
    final targetFraction = maxY > 0 ? targetHours / maxY : 0.0;

    final labels = _axisLabels();
    final axisLines = labels.any((l) => l.year != null) ? 2 : (labels.isEmpty ? 0 : 1);
    final axisHeight = axisLines == 0 ? 16.0 : 4 + axisLines * _axisLine;

    final gap = switch (bucket) {
      HoursBucket.month => AppSpace.s2,
      HoursBucket.week => AppSpace.s1,
      // Fixed gaps alone outgrow the row once there are a few dozen bars.
      HoursBucket.day => days.length > 40 ? 1.0 : AppSpace.s1,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _plotHeight + axisHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final n = days.length;
              final barWidth = n == 0 ? 0.0 : (constraints.maxWidth - gap * (n - 1)) / n;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: _plotHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final (i, day) in days.indexed) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            child: _Bar(
                              day: day,
                              maxY: maxY,
                              isCurrent: _contains(day.date, today),
                              isRest: bucket == HoursBucket.day
                                  ? day.targetHours <= 0 && day.netWorkedHours <= 0
                                  : day.netWorkedHours <= 0,
                              palette: palette,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // The target is a line across the whole plot rather than a
                  // tick on an axis: every bar is being compared to it.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _plotHeight * (1 - targetFraction),
                    child: DashedLine(color: palette.baseline),
                  ),
                  Positioned(
                    left: 0,
                    top: _plotHeight * (1 - targetFraction) - 16,
                    child: Text('${AppFormat.hm(targetHours)} target',
                        style: AppTextStyles.micro.copyWith(color: colors.textMuted)),
                  ),
                  for (final label in labels)
                    Positioned(
                      left: label.index * (barWidth + gap),
                      top: _plotHeight + 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label.month,
                              style: AppTextStyles.micro.copyWith(color: palette.axisLabel)),
                          if (label.year != null)
                            Text(label.year!,
                                style: AppTextStyles.micro.copyWith(color: palette.axisLabel)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (bucket != HoursBucket.day) ...[
          const SizedBox(height: AppSpace.s2),
          Wrap(
            spacing: AppSpace.s4,
            runSpacing: AppSpace.s1,
            children: [
              _LegendItem(
                swatch: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: palette.highlight, shape: BoxShape.circle),
                ),
                label: bucket == HoursBucket.week ? 'This week so far' : 'This month so far',
              ),
              _LegendItem(
                swatch: Container(width: 10, height: 2, color: palette.inactive),
                label: 'No worked day',
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// 6M: the month under the first week whose Monday falls in it. 1Y: every
  /// month, with the year under the first bar and under January.
  List<_AxisLabel> _axisLabels() {
    switch (bucket) {
      case HoursBucket.day:
        return const [];
      case HoursBucket.week:
        final labels = <_AxisLabel>[];
        int? lastMonth;
        for (final (i, day) in days.indexed) {
          if (day.date.month != lastMonth) {
            // A range starting late in a month puts two labels a bar apart;
            // the later one is the month the bars below it belong to.
            if (labels.isNotEmpty && i - labels.last.index < 3) labels.removeLast();
            labels.add(_AxisLabel(i, AppFormat.monthAbbrev(day.date)));
            lastMonth = day.date.month;
          }
        }
        return labels;
      case HoursBucket.month:
        return [
          for (final (i, day) in days.indexed)
            _AxisLabel(
              i,
              AppFormat.monthAbbrev(day.date),
              year: i == 0 || day.date.month == 1 ? '${day.date.year}' : null,
            ),
        ];
    }
  }

  bool _contains(DateTime start, DateTime day) {
    final date = dateOnly(day);
    return !date.isBefore(start) && date.isBefore(bucketEnd(start, bucket));
  }
}

class _AxisLabel {
  const _AxisLabel(this.index, this.month, {this.year});
  final int index;
  final String month;
  final String? year;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: AppSpace.s1 + 2),
        Text(label, style: AppTextStyles.caption.copyWith(color: context.colors.textMuted)),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.maxY,
    required this.isCurrent,
    required this.isRest,
    required this.palette,
  });

  final DayStat day;
  final double maxY;
  final bool isCurrent;

  /// Nothing to draw a bar for: a weekend, or a week or month never worked.
  final bool isRest;
  final ChartPalette palette;

  @override
  Widget build(BuildContext context) {
    final height = isRest
        ? 2.0
        : (maxY > 0 ? (day.netWorkedHours / maxY) * _plotHeight : 0.0).clamp(2.0, _plotHeight);

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isRest ? palette.inactive : (isCurrent ? palette.highlight : palette.mark),
            borderRadius: BorderRadius.circular(math.min(4, constraints.maxWidth / 2)),
          ),
        ),
      ),
    );
  }
}
