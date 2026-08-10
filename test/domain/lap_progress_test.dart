import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/lap_progress.dart';

void main() {
  group('lapProgressFor', () {
    test('zero or negative ratio is an empty lap 0', () {
      expect(lapProgressFor(0.0).lapIndex, 0);
      expect(lapProgressFor(0.0).fraction, 0.0);
      expect(lapProgressFor(-1.0).lapIndex, 0);
      expect(lapProgressFor(-1.0).fraction, 0.0);
    });

    test('mid-lap ratio stays on lap 0', () {
      final p = lapProgressFor(0.5);
      expect(p.lapIndex, 0);
      expect(p.fraction, closeTo(0.5, 1e-9));
    });

    test('exactly hitting the target reads as a full lap 0, not empty lap 1', () {
      final p = lapProgressFor(1.0);
      expect(p.lapIndex, 0);
      expect(p.fraction, closeTo(1.0, 1e-9));
    });

    test('just past the target starts lap 1 near-empty', () {
      final p = lapProgressFor(1.01);
      expect(p.lapIndex, 1);
      expect(p.fraction, closeTo(0.01, 1e-9));
    });

    test('double overtime is a full lap 1', () {
      final p = lapProgressFor(2.0);
      expect(p.lapIndex, 1);
      expect(p.fraction, closeTo(1.0, 1e-9));
    });

    test('keeps lapping indefinitely', () {
      final p = lapProgressFor(2.5);
      expect(p.lapIndex, 2);
      expect(p.fraction, closeTo(0.5, 1e-9));
    });
  });
}
