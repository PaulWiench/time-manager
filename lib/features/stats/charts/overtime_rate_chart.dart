/// How fast the balance moved each week (handoff §5.6.3).
///
/// Distinct from the trend line above it: that one shows where the balance is,
/// this one shows what is pushing it there. Bars straddle a zero line so a run
/// of small losses reads differently from one bad week.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../domain/date_only.dart';
import '../../../domain/stats_aggregation.dart';
import 'chart_palette.dart';

class OvertimeRateChart extends StatelessWidget {
  const OvertimeRateChart({super.key, required this.weeks, required this.today});

  final List<WeekStat> weeks;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final currentWeek = startOfWeek(today);

    var maxAbs = 0.5;
    for (final week in weeks) {
      if (week.balanceDelta.abs() > maxAbs) maxAbs = week.balanceDelta.abs();
    }
    final barWidth = (260 / weeks.length).clamp(4.0, 18.0);

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          // The zero line sits at 40 % of the height: losses are the common
          // case here, and they need the room.
          minY: -maxAbs * 1.5,
          maxY: maxAbs * 1.1,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: palette.baseline,
                strokeWidth: AppStroke.chartGrid,
              ),
            ],
          ),
          barGroups: [
            for (final (i, week) in weeks.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: week.balanceDelta,
                    color: week.weekStart == currentWeek ? palette.highlight : palette.mark,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
