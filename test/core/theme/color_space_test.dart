import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/core/theme/color_space.dart';

void main() {
  group('darkenForLap', () {
    const base = Color(0xFF9184D9);

    test('lap 0 leaves the color unchanged', () {
      expect(darkenForLap(base, 0), base);
    });

    test('each further lap gets strictly darker, and monotonically so', () {
      final lightness0 = HSLColor.fromColor(darkenForLap(base, 0)).lightness;
      final lightness1 = HSLColor.fromColor(darkenForLap(base, 1)).lightness;
      final lightness2 = HSLColor.fromColor(darkenForLap(base, 2)).lightness;
      expect(lightness1, lessThan(lightness0));
      expect(lightness2, lessThan(lightness1));
    });

    test('never darkens below the readability floor', () {
      // The floor is enforced in HSL float space, but converting the
      // result back through 8-bit RGB and re-reading its HSL lightness
      // (as this test does) loses a little precision at the boundary.
      final lightness = HSLColor.fromColor(darkenForLap(base, 50)).lightness;
      expect(lightness, greaterThanOrEqualTo(0.12 - 0.01));
    });
  });
}
