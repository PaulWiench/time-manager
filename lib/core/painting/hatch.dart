/// Diagonal hatching as a [Decoration], for leave.
///
/// Leave is the one block on the Day Rail and the heatmap that did not happen
/// at a desk, and the design distinguishes it by texture rather than by hue
/// alone — so it survives greyscale, and so a colourblind reading of "blue
/// block" still says "not worked". Written as a [Decoration] so it composes
/// with a radius and a fill instead of being a one-off painter per call site.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class HatchDecoration extends Decoration {
  const HatchDecoration({
    required this.background,
    required this.stripe,
    this.borderRadius = BorderRadius.zero,
    this.stripeWidth = 3,
    this.gapWidth = 3,
    this.angle = math.pi * 3 / 4, // 135 degrees
  });

  /// The wash behind the stripes — a Tint role.
  final Color background;

  /// The stripes themselves — the matching Fill role.
  final Color stripe;

  final BorderRadius borderRadius;
  final double stripeWidth;
  final double gapWidth;
  final double angle;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _HatchPainter(this);

  @override
  Decoration? lerpFrom(Decoration? a, double t) =>
      a is HatchDecoration ? _lerpHatch(a, this, t) : super.lerpFrom(a, t);

  @override
  Decoration? lerpTo(Decoration? b, double t) =>
      b is HatchDecoration ? _lerpHatch(this, b, t) : super.lerpTo(b, t);

  static HatchDecoration _lerpHatch(HatchDecoration a, HatchDecoration b, double t) =>
      HatchDecoration(
        background: Color.lerp(a.background, b.background, t)!,
        stripe: Color.lerp(a.stripe, b.stripe, t)!,
        borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
        stripeWidth: a.stripeWidth + (b.stripeWidth - a.stripeWidth) * t,
        gapWidth: a.gapWidth + (b.gapWidth - a.gapWidth) * t,
        angle: a.angle + (b.angle - a.angle) * t,
      );

  @override
  bool operator ==(Object other) =>
      other is HatchDecoration &&
      other.background == background &&
      other.stripe == stripe &&
      other.borderRadius == borderRadius &&
      other.stripeWidth == stripeWidth &&
      other.gapWidth == gapWidth &&
      other.angle == angle;

  @override
  int get hashCode =>
      Object.hash(background, stripe, borderRadius, stripeWidth, gapWidth, angle);
}

class _HatchPainter extends BoxPainter {
  _HatchPainter(this.decoration);

  final HatchDecoration decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size ?? Size.zero;
    if (size.isEmpty) return;
    final rect = offset & size;
    final rrect = decoration.borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect, Paint()..color = decoration.background);

    // Rotate about the rect's centre and draw vertical bars across a square
    // big enough to cover the rect at any angle, so no corner is left bare.
    final centre = rect.center;
    final span = rect.longestSide * 1.5;
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(decoration.angle);

    final paint = Paint()..color = decoration.stripe;
    final step = decoration.stripeWidth + decoration.gapWidth;
    for (var x = -span; x < span; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, -span, decoration.stripeWidth, span * 2), paint);
    }

    canvas.restore();
  }
}
