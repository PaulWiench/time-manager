import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_empty_state.dart';

/// Overview § 2 — how many weeks in range hit the weekly-hour target. Bars
/// are colored by hit/miss rather than paired with a per-week target line,
/// since the target itself varies week to week (holidays, partial weeks).
class WeeklyHitRateChart extends StatelessWidget {
  final List<WeekStat> weeks;

  const WeeklyHitRateChart({super.key, required this.weeks});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (weeks.isEmpty) return const ChartEmptyState();

    final hit = weeks.where((w) => w.hitTarget).length;
    var maxY = 0.5;
    for (final w in weeks) {
      if (w.netHours > maxY) maxY = w.netHours;
      if (w.targetHours > maxY) maxY = w.targetHours;
    }
    final barWidth = (240 / weeks.length).clamp(4.0, 18.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$hit of ${weeks.length} weeks hit target', style: AppTextStyles.body.copyWith(color: colors.text)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.15,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              barGroups: [
                for (var i = 0; i < weeks.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: weeks[i].netHours,
                      color: weeks[i].hitTarget ? colors.accentFill : colors.idle,
                      width: barWidth,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
