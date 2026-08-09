import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/database/database.dart';
import 'chart_empty_state.dart';

/// Overview § 1 — cumulative hour balance across the selected range.
/// `BalanceSnapshot.balance` is already the running cumulative figure, so
/// this plots it directly rather than re-deriving a cumulative sum.
class BalanceTrendChart extends StatelessWidget {
  final List<BalanceSnapshot> snapshots;

  const BalanceTrendChart({super.key, required this.snapshots});

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (snapshots.length < 2) return const ChartEmptyState();

    final spots = [for (var i = 0; i < snapshots.length; i++) FlSpot(i.toDouble(), snapshots[i].balance)];
    var minY = spots.first.y, maxY = spots.first.y;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    final pad = (maxY - minY).abs() * 0.15 + 0.5;

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: minY - pad,
          maxY: maxY + pad,
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(horizontalLines: [HorizontalLine(y: 0, color: colors.divider, strokeWidth: 1)]),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colors.surface2,
              getTooltipItems: (touched) => [
                for (final t in touched)
                  LineTooltipItem(
                    '${_dateFmt.format(snapshots[t.x.toInt()].date)}: ${t.y.toStringAsFixed(1)}h',
                    AppTextStyles.metaMedium.copyWith(color: colors.text),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.2,
              color: colors.accentFill,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: colors.accentTint),
            ),
          ],
        ),
      ),
    );
  }
}
