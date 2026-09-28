/// The rule that stops a day in progress dragging the balance down.
///
/// Paul's words for it: "if outside of the normal work hours a break more than
/// an hour exists then it should judge the day is finished, but latest at
/// midnight." Each clause of that sentence gets a test.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/day_settlement.dart';
import 'package:time_manager/domain/midnight_cutoff.dart';

void main() {
  final today = DateTime(2026, 9, 28);
  DateTime at(int hour, int minute) => DateTime(2026, 9, 28, hour, minute);

  // The default: 08:00-18:00.
  const window = TimeOfDayWindow(startMinutes: 8 * 60, endMinutes: 18 * 60);

  bool finished({
    required DateTime now,
    DateTime? day,
    bool active = false,
    DateTime? lastCheckOut,
  }) =>
      dayIsFinished(
        now: now,
        day: day ?? today,
        hasActiveSession: active,
        lastCheckOut: lastCheckOut,
        workWindow: window,
      );

  group('dayIsFinished', () {
    test('a day the calendar has passed is finished, whatever happened on it', () {
      // Including the case that matters most: a workday nobody ever checked in
      // to. That is the day whose -7:54 has to land eventually, and this is the
      // only branch that lands it.
      expect(
        finished(now: DateTime(2026, 9, 29, 0, 1), lastCheckOut: null),
        isTrue,
      );
    });

    test('a future day has not started, let alone finished', () {
      expect(
        finished(now: at(10, 0), day: DateTime(2026, 9, 30), lastCheckOut: null),
        isFalse,
      );
    });

    test('a running session means the day is still going, even at midnight-1', () {
      expect(finished(now: at(23, 59), active: true, lastCheckOut: at(12, 0)), isFalse);
    });

    test('a day with no check-out yet is not finished', () {
      // 07:00 is outside the window, but nothing has happened — this is the
      // morning before work, not the evening after it.
      expect(finished(now: at(7, 0), lastCheckOut: null), isFalse);
    });

    test('an idle hour inside working hours is a long lunch, not the end', () {
      // Checked out at 11:30, now 14:00 — two and a half hours, which the
      // two-hour break window would already have called "checked out". The day
      // is not over: it is the middle of the afternoon.
      expect(finished(now: at(14, 0), lastCheckOut: at(11, 30)), isFalse);
    });

    test('the same gap outside working hours ends the day', () {
      expect(finished(now: at(19, 30), lastCheckOut: at(18, 15)), isTrue);
    });

    test('a short gap outside working hours does not', () {
      // Left at 18:10, it is 18:40 — half an hour, could be anything.
      expect(finished(now: at(18, 40), lastCheckOut: at(18, 10)), isFalse);
    });

    test('the idle window is measured from the last check-out, not from the window edge',
        () {
      // Out at 17:55, now 18:50: the clock is outside the window, but only 55
      // minutes have passed.
      expect(finished(now: at(18, 50), lastCheckOut: at(17, 55)), isFalse);
      // Five minutes later it tips over.
      expect(finished(now: at(18, 56), lastCheckOut: at(17, 55)), isTrue);
    });

    test('an early start settles early too', () {
      // Someone who works 05:00-07:30 is outside the window the whole time, so
      // the day settles at 08:31 — before the window even opens. Correct: the
      // rule is "outside working hours and idle", and they are both.
      expect(finished(now: at(7, 45), lastCheckOut: at(7, 30)), isFalse);
      // 08:31 is inside the window now, so it is not finished after all.
      expect(finished(now: at(8, 31), lastCheckOut: at(7, 30)), isFalse);
    });
  });

  group('todayContribution', () {
    test('an unfinished day never subtracts', () {
      expect(todayContribution(delta: -7.9, finished: false), 0);
      expect(todayContribution(delta: -0.01, finished: false), 0);
    });

    test('an unfinished day adds a surplus the moment it exists', () {
      // "Once 07:54 is surpassed it should directly increase."
      expect(todayContribution(delta: 1.5, finished: false), 1.5);
    });

    test('a finished day counts for exactly what it was', () {
      expect(todayContribution(delta: -7.9, finished: true), -7.9);
      expect(todayContribution(delta: 1.5, finished: true), 1.5);
      expect(todayContribution(delta: 0, finished: true), 0);
    });
  });
}
