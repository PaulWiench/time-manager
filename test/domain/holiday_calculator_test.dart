import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/holiday_calculator.dart';

void main() {
  group('gaussEasterSunday', () {
    test('matches well-known reference dates', () {
      expect(gaussEasterSunday(2024), DateTime(2024, 3, 31));
      expect(gaussEasterSunday(2025), DateTime(2025, 4, 20));
      expect(gaussEasterSunday(2026), DateTime(2026, 4, 5));
      expect(gaussEasterSunday(2027), DateTime(2027, 3, 28));
    });

    test('handles the classic correction-term exception years', () {
      // 1954 and 1981 are the standard regression cases for the Gauss
      // algorithm's exception-day correction terms.
      expect(gaussEasterSunday(1954), DateTime(1954, 4, 18));
      expect(gaussEasterSunday(1981), DateTime(1981, 4, 19));
    });
  });

  group('germanNationalHolidays', () {
    test('includes all 9 nationwide holidays with correct dates for 2026', () {
      final holidays = germanNationalHolidays(2026);
      final byName = {for (final h in holidays) h.name: h.date};

      expect(holidays, hasLength(9));
      expect(byName['Neujahr'], DateTime(2026, 1, 1));
      expect(byName['Tag der Arbeit'], DateTime(2026, 5, 1));
      expect(byName['Tag der Deutschen Einheit'], DateTime(2026, 10, 3));
      expect(byName['1. Weihnachtstag'], DateTime(2026, 12, 25));
      expect(byName['2. Weihnachtstag'], DateTime(2026, 12, 26));

      final easter = gaussEasterSunday(2026);
      expect(byName['Karfreitag'], easter.subtract(const Duration(days: 2)));
      expect(byName['Ostermontag'], easter.add(const Duration(days: 1)));
      expect(byName['Christi Himmelfahrt'], easter.add(const Duration(days: 39)));
      expect(byName['Pfingstmontag'], easter.add(const Duration(days: 50)));
    });
  });
}
