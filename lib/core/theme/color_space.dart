import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Converts a CSS `oklch(l% c h)` color to a Flutter [Color].
///
/// The design handoff (Claude Design, Milestone 5) specifies the break and
/// warning semantic hues in OKLCH — chosen at the same lightness/chroma as
/// the Nocturne accent so tracking/break/idle/warning stay distinguishable
/// without breaking the "one accent family, varied by ramp" system. Flutter
/// has no native OKLCH support, so rather than hand-picking approximate hex
/// values, this reimplements the OKLab -> linear-sRGB matrices (Björn
/// Ottosson's `oklch.com` reference) to get pixel-accurate colors straight
/// from the spec's own numbers.
Color oklch(double lightness, double chroma, double hueDegrees, [double alpha = 1.0]) {
  final hRad = hueDegrees * math.pi / 180.0;
  final a = chroma * math.cos(hRad);
  final b = chroma * math.sin(hRad);

  final l_ = lightness + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = lightness - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = lightness - 0.0894841775 * a - 1.2914855480 * b;

  final l3 = l_ * l_ * l_;
  final m3 = m_ * m_ * m_;
  final s3 = s_ * s_ * s_;

  final rLin = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  final gLin = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  final bLin = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  double toSrgb(double c) {
    c = c.clamp(0.0, 1.0);
    return c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
  }

  return Color.fromARGB(
    (alpha * 255).round(),
    (toSrgb(rLin) * 255).round().clamp(0, 255),
    (toSrgb(gLin) * 255).round().clamp(0, 255),
    (toSrgb(bLin) * 255).round().clamp(0, 255),
  );
}
