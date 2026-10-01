import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/vacation_proration.dart';

void main() {
  ProratedVacation days(DateTime start, {DateTime? end, int year = 2026, double quota = 30}) =>
      proratedVacationDays(yearlyQuota: quota, jobStart: start, jobEnd: end, year: year);

  test('Paul\'s 2026: from 15 March is nine full months, 22.5, rounded up to 23', () {
    final result = days(DateTime(2026, 3, 15));
    expect(result.fullMonths, 9);
    expect(result.exact, 22.5);
    expect(result.days, 23);
    expect(result.isProrated, isTrue);
  });

  test('the following year is the full quota', () {
    final result = days(DateTime(2026, 3, 15), year: 2027);
    expect(result.days, 30);
    expect(result.isProrated, isFalse);
  });

  test('ending mid-year counts the months up to the last working day', () {
    // 15 Mar – 31 Jul: four full months (15 Mar – 14 Jul), the rest partial.
    final result = days(DateTime(2026, 3, 15), end: DateTime(2026, 7, 31));
    expect(result.fullMonths, 4);
    expect(result.days, 10);
  });

  test('a job ending on a month boundary earns that last month', () {
    // 1 Jan – 30 Jun is exactly six months.
    final result = days(DateTime(2025, 6, 1), end: DateTime(2026, 6, 30));
    expect(result.fullMonths, 6);
    expect(result.days, 15);
  });

  test('below half a day rounds down', () {
    // 25 days × 5 / 12 = 10.42
    final result = days(DateTime(2026, 8, 1), quota: 25);
    expect(result.fullMonths, 5);
    expect(result.days, 10);
  });

  test('a job outside the year earns nothing in it', () {
    expect(days(DateTime(2027, 2, 1)).days, 0);
    expect(days(DateTime(2024, 2, 1), end: DateTime(2025, 12, 31)).days, 0);
  });

  test('months are counted on the calendar across the spring DST change', () {
    // 29 March 2026 is when Germany springs forward; counting by Duration
    // would land a month at 01:00 and drop it.
    final result = days(DateTime(2026, 3, 29), end: DateTime(2026, 4, 28));
    expect(result.fullMonths, 1);
  });
}
