import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_empty_state.dart';

/// Overview § 3 — the *rate* the balance is growing/shrinking per week
/// (sum of `balanceDelta`), distinct from the raw cumulative trend line.
/// Bars straddle a zero line: accent for weeks that grew the balance,
/// warning for weeks that shrank it.
class OvertimeRateChart extends StatelessWidget {
  final List<WeekStat> weeks;

  const OvertimeRateChart({super.key, required this.weeks});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (weeks.isEmpty) return const ChartEmptyState();

    var maxAbs = 0.5;
    for (final w in weeks) {
      if (w.balanceDelta.abs() > maxAbs) maxAbs = w.balanceDelta.abs();
    }
    final barWidth = (240 / weeks.length).clamp(4.0, 18.0);

    return SizedBox(
      height: 110,
      child: BarChart(
        BarChartData(
          minY: -maxAbs * 1.15,
          maxY: maxAbs * 1.15,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: 0, color: colors.divider, strokeWidth: 1)]),
          barGroups: [
            for (var i = 0; i < weeks.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: weeks[i].balanceDelta,
                  color: weeks[i].balanceDelta >= 0 ? colors.accentFill : colors.warningFill,
                  width: barWidth,
                  borderRadius: BorderRadius.circular(2),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
