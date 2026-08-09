import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/break_engine.dart';

WorkPeriod _p(String start, String end) =>
    WorkPeriod(start: DateTime.parse(start), end: DateTime.parse(end));

void main() {
  group('requiredBreakFor', () {
    test('no break required at or under 6h', () {
      expect(requiredBreakFor(const Duration(hours: 6)), Duration.zero);
      expect(requiredBreakFor(const Duration(hours: 5)), Duration.zero);
    });

    test('30 min required over 6h', () {
      expect(requiredBreakFor(const Duration(hours: 6, minutes: 1)),
          const Duration(minutes: 30));
    });

    test('45 min required over 9h', () {
      expect(requiredBreakFor(const Duration(hours: 9, minutes: 1)),
          const Duration(minutes: 45));
    });
  });

  group('calculateBreaks', () {
    test('Requirements worked example: 08-12, break 12:00-12:20, 12:20-14:30', () {
      final result = calculateBreaks([
        _p('2026-08-10 08:00:00', '2026-08-10 12:00:00'),
        _p('2026-08-10 12:20:00', '2026-08-10 14:30:00'),
      ]);

      expect(result.grossWorkTime, const Duration(hours: 6, minutes: 10));
      expect(result.requiredBreakTime, const Duration(minutes: 30));
      expect(result.realBreakTime, const Duration(minutes: 20));
      expect(result.deficit, const Duration(minutes: 10));
      expect(result.netWorkedTime, const Duration(hours: 6));

      final synthetic = result.syntheticBreak;
      expect(synthetic, isNotNull);
      expect(synthetic!.start, DateTime.parse('2026-08-10 12:20:00'));
      expect(synthetic.end, DateTime.parse('2026-08-10 12:30:00'));
    });

    test('sufficient real break needs no synthetic break', () {
      final result = calculateBreaks([
        _p('2026-08-10 08:00:00', '2026-08-10 12:00:00'),
        _p('2026-08-10 12:40:00', '2026-08-10 16:00:00'),
      ]);

      expect(result.grossWorkTime, const Duration(hours: 7, minutes: 20));
      expect(result.realBreakTime, const Duration(minutes: 40));
      expect(result.deficit, Duration.zero);
      expect(result.netWorkedTime, result.grossWorkTime);
      expect(result.syntheticBreak, isNull);
    });

    test('over 9h requires 45 min and inserts at noon when no gap exists', () {
      final result = calculateBreaks([
        _p('2026-08-10 08:00:00', '2026-08-10 18:00:00'),
      ]);

      expect(result.grossWorkTime, const Duration(hours: 10));
      expect(result.requiredBreakTime, const Duration(minutes: 45));
      expect(result.deficit, const Duration(minutes: 45));
      expect(result.netWorkedTime, const Duration(hours: 9, minutes: 15));

      final synthetic = result.syntheticBreak;
      expect(synthetic!.start, DateTime.parse('2026-08-10 12:00:00'));
      expect(synthetic.end, DateTime.parse('2026-08-10 12:45:00'));
    });

    test('anchor shifts to 4h into first session when noon is after the window', () {
      // Session window entirely before noon.
      final result = calculateBreaks([
        _p('2026-08-10 05:00:00', '2026-08-10 11:30:00'),
      ]);

      expect(result.deficit, const Duration(minutes: 30));
      final synthetic = result.syntheticBreak;
      expect(synthetic!.start, DateTime.parse('2026-08-10 09:00:00'));
      expect(synthetic.end, DateTime.parse('2026-08-10 09:30:00'));
    });

    test('anchor shifts to 4h into first session when noon is before the window', () {
      // Session window entirely after noon.
      final result = calculateBreaks([
        _p('2026-08-10 13:00:00', '2026-08-10 20:00:00'),
      ]);

      expect(result.deficit, const Duration(minutes: 30));
      final synthetic = result.syntheticBreak;
      expect(synthetic!.start, DateTime.parse('2026-08-10 17:00:00'));
      expect(synthetic.end, DateTime.parse('2026-08-10 17:30:00'));
    });
  });
}
