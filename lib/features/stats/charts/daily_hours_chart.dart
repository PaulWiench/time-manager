import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_empty_state.dart';

/// Patterns § 2 — one bar per day, net worked hours. Ranges longer than a
/// month produce more bars than fit on screen, so the chart scrolls
/// horizontally with a fixed per-bar width rather than squashing bars
/// illegibly thin; `reverse: true` starts scrolled to the most recent days.
class DailyHoursChart extends StatelessWidget {
  final List<DayStat> days;

  const DailyHoursChart({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (days.length < 2) return const ChartEmptyState();

    var maxY = 0.5;
    for (final d in days) {
      if (d.netWorkedHours > maxY) maxY = d.netWorkedHours;
    }
    const barWidth = 6.0;
    const gap = 3.0;
    final chartWidth = days.length * (barWidth + gap);

    return SizedBox(
      height: 110,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: SizedBox(
          width: chartWidth < 280 ? 280 : chartWidth,
          child: BarChart(
            BarChartData(
              maxY: maxY * 1.15,
              alignment: BarChartAlignment.start,
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
              barGroups: [
                for (var i = 0; i < days.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: days[i].netWorkedHours, color: colors.accentFill, width: barWidth, borderRadius: BorderRadius.circular(1.5)),
                  ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
