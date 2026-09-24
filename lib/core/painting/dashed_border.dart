/// A dashed outline as a [ShapeBorder].
///
/// Flutter has no dashed [Border], and the design leans on dashes as a
/// meaning, not a decoration: dashed means "not a real thing you logged" —
/// a synthetic break the app inferred, a workday that never happened, the raw
/// audit log. Because it is a [ShapeBorder] rather than a bespoke painter it
/// composes with [ShapeDecoration], so a dashed container can still carry a
/// fill, a shadow and a clip without any of them knowing about the dashes.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/app_dimens.dart';

class DashedRoundedBorder extends ShapeBorder {
  const DashedRoundedBorder({
    required this.color,
    required this.radius,
    this.strokeWidth = AppStroke.dash,
    this.dashLength = AppStroke.dashOn,
    this.gapLength = AppStroke.dashOff,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(rect.deflate(strokeWidth), Radius.circular(radius)),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Stroke centred on the path, so inset by half the width or the outer
    // half of every dash is clipped away by the container's own bounds.
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect.deflate(strokeWidth / 2),
        Radius.circular(math.max(0, radius - strokeWidth / 2)),
      ));

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  ShapeBorder scale(double t) => DashedRoundedBorder(
        color: color,
        radius: radius * t,
        strokeWidth: strokeWidth * t,
        dashLength: dashLength * t,
        gapLength: gapLength * t,
      );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is DashedRoundedBorder) {
      return DashedRoundedBorder(
        color: Color.lerp(a.color, color, t)!,
        radius: _lerp(a.radius, radius, t),
        strokeWidth: _lerp(a.strokeWidth, strokeWidth, t),
        dashLength: _lerp(a.dashLength, dashLength, t),
        gapLength: _lerp(a.gapLength, gapLength, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is DashedRoundedBorder) return b.lerpFrom(this, 1 - t);
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is DashedRoundedBorder &&
      other.color == color &&
      other.radius == radius &&
      other.strokeWidth == strokeWidth &&
      other.dashLength == dashLength &&
      other.gapLength == gapLength;

  @override
  int get hashCode => Object.hash(color, radius, strokeWidth, dashLength, gapLength);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
