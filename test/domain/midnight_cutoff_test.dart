import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/midnight_cutoff.dart';

void main() {
  group('evaluateMidnightCutoff', () {
    test('does nothing if the session has not crossed midnight yet', () {
      final result = evaluateMidnightCutoff(
        sessionStart: DateTime(2026, 8, 9, 22),
        now: DateTime(2026, 8, 9, 23, 30),
      );
      expect(result.cutoffApplied, isFalse);
    });

    test('auto-stops at 23:59:59 once past midnight with no work window', () {
      final result = evaluateMidnightCutoff(
        sessionStart: DateTime(2026, 8, 9, 22),
        now: DateTime(2026, 8, 10, 1),
      );
      expect(result.cutoffApplied, isTrue);
      expect(result.effectiveEnd, DateTime(2026, 8, 9, 23, 59, 59));
    });

    test('does not cut off if still inside a configured overnight work window', () {
      final overnightWindow = TimeOfDayWindow(
        startMinutes: 22 * 60, // 22:00
        endMinutes: 6 * 60, // 06:00, wraps past midnight
      );
      final result = evaluateMidnightCutoff(
        sessionStart: DateTime(2026, 8, 9, 22),
        now: DateTime(2026, 8, 10, 1),
        workWindow: overnightWindow,
      );
      expect(result.cutoffApplied, isFalse);
    });

    test('cuts off once past midnight and outside the work window', () {
      final dayWindow = TimeOfDayWindow(
        startMinutes: 8 * 60,
        endMinutes: 18 * 60,
      );
      final result = evaluateMidnightCutoff(
        sessionStart: DateTime(2026, 8, 9, 22),
        now: DateTime(2026, 8, 10, 1),
        workWindow: dayWindow,
      );
      expect(result.cutoffApplied, isTrue);
    });
  });
}
