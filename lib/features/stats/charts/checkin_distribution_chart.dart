import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'chart_empty_state.dart';

/// Patterns § 4 — earliest/latest check-in patterns as an hour-of-day
/// histogram. No off-the-shelf `fl_chart` shape fits a bucketed
/// distribution well, so this is hand-rolled per the design spec's call-out
/// that this chart type needs its own `CustomPainter`.
class CheckinDistributionChart extends StatelessWidget {
  final List<int> histogram; // length 24, index = hour of day

  const CheckinDistributionChart({super.key, required this.histogram});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = histogram.fold<int>(0, (a, b) => a + b);
    if (total < 2) return const ChartEmptyState();

    // Restrict the drawn axis to the hour range that actually has data
    // (padded by an hour either side) rather than a mostly-empty 24h axis.
    var lo = 23, hi = 0;
    for (var h = 0; h < 24; h++) {
      if (histogram[h] > 0) {
        if (h < lo) lo = h;
        if (h > hi) hi = h;
      }
    }
    lo = (lo - 1).clamp(0, 23);
    hi = (hi + 1).clamp(0, 23);

    return SizedBox(
      height: 100,
      width: double.infinity,
      child: CustomPaint(
        painter: _HistogramPainter(
          histogram: histogram,
          startHour: lo,
          endHourInclusive: hi,
          barColor: colors.accentFill,
          labelColor: colors.textMuted,
        ),
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  final List<int> histogram;
  final int startHour;
  final int endHourInclusive;
  final Color barColor;
  final Color labelColor;

  _HistogramPainter({
    required this.histogram,
    required this.startHour,
    required this.endHourInclusive,
    required this.barColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hours = [for (var h = startHour; h <= endHourInclusive; h++) h];
    var maxCount = 1;
    for (final h in hours) {
      if (histogram[h] > maxCount) maxCount = histogram[h];
    }

    const labelSpace = 16.0;
    final chartHeight = size.height - labelSpace;
    final barWidth = size.width / hours.length;
    final paint = Paint()..color = barColor;

    for (var i = 0; i < hours.length; i++) {
      final h = hours[i];
      final count = histogram[h];
      if (count == 0) continue;
      final barHeight = (count / maxCount) * chartHeight;
      final rect = Rect.fromLTWH(
        i * barWidth + barWidth * 0.15,
        chartHeight - barHeight,
        barWidth * 0.7,
        barHeight,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), paint);
    }

    for (var i = 0; i < hours.length; i++) {
      final h = hours[i];
      if (h % 3 != 0) continue;
      final tp = TextPainter(
        text: TextSpan(text: '$h', style: TextStyle(fontSize: 9, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * barWidth + barWidth / 2 - tp.width / 2, chartHeight + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter oldDelegate) {
    return oldDelegate.histogram != histogram ||
        oldDelegate.startHour != startHour ||
        oldDelegate.endHourInclusive != endHourInclusive ||
        oldDelegate.barColor != barColor;
  }
}
