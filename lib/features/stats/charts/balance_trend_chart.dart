/// The balance over the selected range (handoff §5.6.1).
///
/// `BalanceSnapshot.balance` is already the running cumulative figure, so this
/// plots it directly rather than re-deriving a sum. The area is filled to the
/// zero line in both directions, which is the point of the chart: how much of
/// the range was spent below the line.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../stats_view.dart';
import 'chart_palette.dart';
import 'month_axis.dart';

const double _labelColumn = 44;

class BalanceTrendChart extends StatelessWidget {
  const BalanceTrendChart({super.key, required this.points});

  final List<BalancePoint> points;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final colors = context.colors;

    final spots = [
      for (final (i, point) in points.indexed) FlSpot(i.toDouble(), point.balance),
    ];
    var minY = 0.0, maxY = 0.0;
    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    // Gridlines every ten hours, or every five when the whole range fits in
    // fifteen — otherwise a quiet range gets one line and no sense of scale.
    final step = (maxY - minY) <= 15 ? 5.0 : 10.0;
    final gridMin = (minY / step).floorToDouble() * step;
    final gridMax = (maxY / step).ceilToDouble() * step;
    final gridLines = [for (var y = gridMin; y <= gridMax + 0.001; y += step) y];

    final plotMin = gridMin - step * 0.2;
    final plotMax = gridMax + step * 0.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: plotMin,
                    maxY: plotMax,
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        for (final y in gridLines)
                          HorizontalLine(
                            y: y,
                            // Zero is a statement; the rest is scaffolding.
                            color: y == 0 ? palette.baseline : palette.grid,
                            strokeWidth: AppStroke.chartGrid,
                            dashArray: y == 0 ? null : [4, 3],
                          ),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.2,
                        color: palette.mark,
                        barWidth: AppStroke.chartLine,
                        isStrokeJoinRound: true,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          // Only the last point is marked: it is where the
                          // number in the header comes from.
                          checkToShowDot: (spot, _) => spot.x == spots.last.x,
                          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 6,
                            color: palette.highlight,
                            strokeColor: palette.ground,
                            strokeWidth: 2,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: palette.wash,
                          cutOffY: 0,
                          applyCutOffY: true,
                        ),
                        aboveBarData: BarAreaData(
                          show: true,
                          color: palette.wash,
                          cutOffY: 0,
                          applyCutOffY: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s2),
              // The scale sits outside the plot so the line never runs under it.
              SizedBox(
                width: _labelColumn,
                child: Stack(
                  children: [
                    for (final y in gridLines)
                      Align(
                        alignment: Alignment(
                          -1,
                          -1 + 2 * (1 - (y - plotMin) / (plotMax - plotMin)),
                        ),
                        child: Text(
                          _hoursLabel(y),
                          style: AppTextStyles.micro.copyWith(color: colors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        Padding(
          padding: const EdgeInsets.only(right: _labelColumn + AppSpace.s2),
          child: MonthAxis(dates: [for (final point in points) point.date]),
        ),
      ],
    );
  }
}

String _hoursLabel(double hours) {
  final whole = hours.abs().round();
  if (hours < 0) return '−$whole h';
  return '${hours > 0 ? '+' : ''}$whole h';
}

