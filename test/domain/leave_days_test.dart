/// Turning leave hours back into leave days.
///
/// The number these replace was `hours / 8`, hardcoded in two places. Paul's
/// sixteen whole vacation days rendered as 15.8, and no whole number was
/// reachable at all for a 39.5 h week.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/leave_days.dart';

void main() {
  // 39.5 hours over five days.
  const target = 7.9;

  test('a whole day is one day, not 0.9875 of one', () {
    expect(leaveDaysFor(hours: target, targetHours: target), 1);
    expect(sumLeaveDays([for (var i = 0; i < 16; i++) (hours: target, targetHours: target)]), 16);
  });

  test('the fractions the editor can write come back exactly', () {
    expect(leaveDaysFor(hours: target * 0.75, targetHours: target), 0.75);
    expect(leaveDaysFor(hours: target * 0.5, targetHours: target), 0.5);
    expect(leaveDaysFor(hours: target * 0.25, targetHours: target), 0.25);
  });

  test('a full day on a half public holiday is still a full day', () {
    // A half holiday halves that date's target, and a "full day" of leave on it
    // is only 3.95 hours. Measuring against a flat 8 would have called it a
    // half day.
    expect(leaveDaysFor(hours: 3.95, targetHours: 3.95), 1);
  });

  test('an entry written before the weekly hours changed still rounds home', () {
    // 8.0 recorded against a 7.9 target, or vice versa: the editor only ever
    // writes quarters, so anything within an eighth of one is that quarter.
    expect(leaveDaysFor(hours: 8, targetHours: 7.9), 1);
    expect(leaveDaysFor(hours: 7.9, targetHours: 8), 1);
  });

  test('a date with no target contributes nothing rather than dividing by zero',
      () {
    expect(leaveDaysFor(hours: 7.9, targetHours: 0), 0);
    expect(leaveDaysFor(hours: 7.9, targetHours: -1), 0);
  });

  test('a four-day week has longer days, and they still count as one', () {
    // 39.5 over four days is 9.875 — the case where dividing by 8 overcounted.
    expect(leaveDaysFor(hours: 9.875, targetHours: 9.875), 1);
  });
}
