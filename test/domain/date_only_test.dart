import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/date_only.dart';

void main() {
  group('shiftDays', () {
    test('always lands on local midnight, even across a DST transition', () {
      // Germany's 2026 spring-forward is 29 March — Duration(days: 1)
      // arithmetic on a local DateTime silently drifts off midnight there,
      // which is exactly what froze RecalculationService's cascade for
      // months of real user data (every date.equals(...) lookup downstream
      // started missing). shiftDays must stay exact through it.
      var d = DateTime(2026, 3, 27);
      for (var i = 0; i < 10; i++) {
        d = shiftDays(d, 1);
        expect(d.hour, 0, reason: 'drifted off midnight at $d');
        expect(d.minute, 0);
        expect(d.second, 0);
      }
      expect(d, DateTime(2026, 4, 6));
    });

    test('steps backward correctly too', () {
      expect(shiftDays(DateTime(2026, 4, 6), -10), DateTime(2026, 3, 27));
    });

    test('zero days is a no-op', () {
      final d = DateTime(2026, 6, 15);
      expect(shiftDays(d, 0), d);
    });
  });

  group('dateOnly', () {
    test('truncates time-of-day components', () {
      expect(dateOnly(DateTime(2026, 6, 15, 13, 45, 30)), DateTime(2026, 6, 15));
    });
  });

  group('startOfWeek', () {
    test('is the Monday of that week, and a no-op on a Monday', () {
      expect(startOfWeek(DateTime(2026, 9, 24)), DateTime(2026, 9, 21));
      expect(startOfWeek(DateTime(2026, 9, 21)), DateTime(2026, 9, 21));
      expect(startOfWeek(DateTime(2026, 9, 27)), DateTime(2026, 9, 21));
    });
  });

  group('isoWeekNumber', () {
    test('numbers ordinary weeks from the first Thursday', () {
      expect(isoWeekNumber(DateTime(2026, 9, 21)), 39);
      expect(isoWeekNumber(DateTime(2026, 9, 27)), 39);
      expect(isoWeekNumber(DateTime(2026, 9, 28)), 40);
    });

    test('a week belongs to the year that owns its Thursday', () {
      // 1 Jan 2027 is a Friday, so its week's Thursday is 31 Dec 2026 —
      // week 53 of 2026, not week 1 of 2027.
      expect(isoWeekNumber(DateTime(2027, 1, 1)), 53);
      // 1 Jan 2026 is a Thursday, so that week is week 1 of 2026.
      expect(isoWeekNumber(DateTime(2025, 12, 29)), 1);
    });

    test('stays exact across a DST boundary', () {
      // A Duration-based ordinal count would lose an hour here and could
      // drop a day, which is a whole week number at the wrong end of March.
      expect(isoWeekNumber(DateTime(2026, 3, 30)), 14);
    });
  });
}
