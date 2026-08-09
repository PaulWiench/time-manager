import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'chart_empty_state.dart';

/// Patterns § 3 — average net hours per weekday (Mon..Sun) across the
/// selected range.
class WeekdayHoursChart extends StatelessWidget {
  final List<double> averages; // length 7, Mon..Sun

  const WeekdayHoursChart({super.key, required this.averages});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (averages.every((v) => v == 0)) return const ChartEmptyState();

    var maxY = 0.5;
    for (final v in averages) {
      if (v > maxY) maxY = v;
    }

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_labels[value.toInt()], style: AppTextStyles.metaMedium.copyWith(color: colors.textMuted)),
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < 7; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: averages[i], color: colors.accentFill, width: 16, borderRadius: BorderRadius.circular(2)),
              ]),
          ],
        ),
      ),
    );
  }
}
