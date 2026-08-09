import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/stats_aggregation.dart';

void main() {
  group('trailingRange', () {
    test('30-day window ends the day after today, inclusive of today', () {
      final range = trailingRange(30, today: DateTime(2026, 8, 9));
      expect(range.start, DateTime(2026, 7, 11));
      expect(range.endExclusive, DateTime(2026, 8, 10));
    });
  });

  group('mondayOfWeek', () {
    test('Sunday rolls back to the preceding Monday', () {
      expect(mondayOfWeek(DateTime(2026, 8, 9)), DateTime(2026, 8, 3));
    });

    test('Monday maps to itself', () {
      expect(mondayOfWeek(DateTime(2026, 8, 3)), DateTime(2026, 8, 3));
    });
  });

  group('weeklyAggregates', () {
    test('groups by ISO week and flags hit/miss target', () {
      final days = [
        DayStat(date: DateTime(2026, 8, 3), netWorkedHours: 8, targetHours: 8, balanceDelta: 0),
        DayStat(date: DateTime(2026, 8, 4), netWorkedHours: 6, targetHours: 8, balanceDelta: -2),
        DayStat(date: DateTime(2026, 8, 10), netWorkedHours: 9, targetHours: 8, balanceDelta: 1),
      ];
      final weeks = weeklyAggregates(days);
      expect(weeks.length, 2);
      expect(weeks[0].weekStart, DateTime(2026, 8, 3));
      expect(weeks[0].netHours, 14);
      expect(weeks[0].targetHours, 16);
      expect(weeks[0].hitTarget, isFalse);
      expect(weeks[1].hitTarget, isTrue);
    });

    test('a week with zero target hours counts as trivially hit', () {
      final weeks = weeklyAggregates([
        DayStat(date: DateTime(2026, 8, 3), netWorkedHours: 0, targetHours: 0, balanceDelta: 0),
      ]);
      expect(weeks.single.hitTarget, isTrue);
    });
  });

  group('averageHoursByWeekday', () {
    test('averages per weekday and zeroes out missing weekdays', () {
      final days = [
        DayStat(date: DateTime(2026, 8, 3), netWorkedHours: 8, targetHours: 8, balanceDelta: 0), // Mon
        DayStat(date: DateTime(2026, 8, 10), netWorkedHours: 4, targetHours: 8, balanceDelta: -4), // Mon
      ];
      final avgs = averageHoursByWeekday(days);
      expect(avgs[0], 6); // Monday average
      expect(avgs[1], 0); // Tuesday untouched
    });
  });

  group('checkinHourHistogram', () {
    test('buckets by hour of day', () {
      final histogram = checkinHourHistogram([
        DateTime(2026, 8, 3, 9, 15),
        DateTime(2026, 8, 4, 9, 45),
        DateTime(2026, 8, 5, 13, 0),
      ]);
      expect(histogram[9], 2);
      expect(histogram[13], 1);
      expect(histogram.reduce((a, b) => a + b), 3);
    });
  });
}
