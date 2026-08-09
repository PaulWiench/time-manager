import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The circular progress indicator used on Home (daily target) and Stats
/// Leave (vacation used/quota). Round-capped stroke starting at 12 o'clock,
/// matching the design handoff's SVG rings pixel-for-pixel.
class ProgressRing extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double progress; // 0..1
  final Color color;
  final Color trackColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              strokeWidth: strokeWidth,
              progress: progress.clamp(0.0, 1.0),
              color: color,
              trackColor: trackColor,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double strokeWidth;
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.strokeWidth,
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (progress <= 0) return;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
