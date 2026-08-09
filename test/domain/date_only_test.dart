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
}
