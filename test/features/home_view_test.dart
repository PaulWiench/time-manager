/// The decisions Home makes about what to say, without drawing anything.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/data/database/enums.dart';
import 'package:time_manager/domain/tracking_state.dart';
import 'package:time_manager/features/home/home_view.dart';
import 'package:time_manager/widgets/day_rail.dart';

import '../fixtures/rows.dart';

void main() {
  final today = DateTime(2026, 9, 22);
  DateTime at(int hour, int minute) => DateTime(2026, 9, 22, hour, minute);

  HomeView view({
    required DateTime now,
    double committedNet = 0,
    double target = 7.9,
    List<dynamic> sessions = const [],
    double? floor,
    double balance = -15.9667,
    double leaveHours = 0,
  }) =>
      buildHomeView(
        now: now,
        settings: settingsRow(balanceFloorHours: floor),
        dayEntry: dayEntryRow(
          date: today,
          netWorkedHours: committedNet,
          leaveHours: leaveHours,
          targetHours: target,
        ),
        sessions: sessions.cast(),
        breaks: const [],
        leave: leaveHours == 0 ? const [] : [leaveRow(date: today, hours: leaveHours)],
        // The settled balance, carried in from yesterday — buildHomeView adds
        // today itself.
        balance: balanceRow(date: DateTime(2026, 9, 21), balance: balance),
      );

  group('the balance holds today back until the day is over', () {
    // Every case starts from the same settled figure: −15:58 carried in from
    // yesterday, on a 7:54 day.
    test('checking in does not cost a whole day', () {
      // The old behaviour: checking in wrote today as 0 + 0 − 7.9 and the
      // headline fell to −23:52 before any work had been done.
      final v = view(
        now: at(8, 43),
        sessions: [sessionRow(start: at(8, 43), status: SessionStatus.active)],
      );

      expect(v.balanceHours, closeTo(-15.9667, 0.001));
      expect(v.balanceProvisional, isTrue);
    });

    test('a morning short of target still costs nothing', () {
      final v = view(
        now: at(11, 30),
        committedNet: 2.5,
        sessions: [sessionRow(start: at(9, 0), end: at(11, 30))],
      );

      expect(v.balanceHours, closeTo(-15.9667, 0.001));
      expect(v.balanceProvisional, isTrue);
    });

    test('passing the target moves the balance that minute', () {
      final v = view(
        now: at(17, 30),
        committedNet: 8.5,
        sessions: [sessionRow(start: at(9, 0), end: at(17, 30))],
      );

      // −15:58 + 0:36 = −15:22, and nothing is being withheld.
      expect(v.balanceHours, closeTo(-15.3667, 0.001));
      expect(v.balanceProvisional, isFalse);
    });

    test('the shortfall lands once the working day is over', () {
      final v = view(
        now: at(19, 30),
        committedNet: 6.9,
        sessions: [sessionRow(start: at(9, 0), end: at(16, 54))],
      );

      // Outside 08:00–18:00 and idle for over an hour: −15:58 + −1:00.
      expect(v.balanceHours, closeTo(-16.9667, 0.001));
      expect(v.balanceProvisional, isFalse);
    });

    test('a long lunch inside working hours does not settle the day', () {
      final v = view(
        now: at(14, 0),
        committedNet: 2.5,
        sessions: [sessionRow(start: at(9, 0), end: at(11, 30))],
      );

      expect(v.balanceHours, closeTo(-15.9667, 0.001));
      expect(v.balanceProvisional, isTrue);
    });

    test('a full vacation day is settled, not provisional', () {
      // Nothing worked, but leave covers the target exactly, so the day comes
      // out level and there is no shortfall to withhold.
      final v = view(now: at(11, 0), leaveHours: 7.9);

      expect(v.balanceHours, closeTo(-15.9667, 0.001));
      expect(v.balanceProvisional, isFalse);
    });
  });

  test('the ring counts the running session, not just what was committed', () {
    final v = view(
      now: at(16, 37),
      committedNet: 3.9,
      sessions: [sessionRow(start: at(14, 51), status: SessionStatus.active)],
    );

    expect(v.state, TrackingState.tracking);
    expect(v.timerText, '1:46:00');
    expect(v.sinceText, 'since 14:51');
    // 3:54 committed + 1:46 running = 5:40 of 7:54.
    expect(v.netHours, closeTo(5.6667, 0.001));
    expect(v.ringProgress, closeTo(0.717, 0.001));
  });

  test('during a break the ring times the break, not the finished session', () {
    final v = view(
      now: at(13, 5),
      committedNet: 3.9,
      sessions: [sessionRow(start: at(8, 43), end: at(12, 37))],
    );

    expect(v.state, TrackingState.onBreak);
    expect(v.timerText, '0:28:00');
    expect(v.sinceText, 'since 12:37');
    // The break in progress has no row, but the rail still has to show it.
    expect(v.rail.last.type, RailSegmentType.realBreak);
    expect(v.rail.last.hours, closeTo(28 / 60, 1e-6));
  });

  test('over the target, the surplus is reported instead of a clamped zero', () {
    final v = view(
      now: at(20, 9),
      committedNet: 3.9,
      sessions: [sessionRow(start: at(14, 51), status: SessionStatus.active)],
    );

    expect(v.isOverTarget, isTrue);
    expect(v.remainingHours, closeTo(-1.3, 0.001)); // 1:18 over
    expect(v.ringProgress, greaterThan(1));
  });

  test('a balance only warns past a bound that was configured', () {
    expect(view(now: at(19, 20), balance: -20.68).balanceWarning, isFalse);
    expect(view(now: at(19, 20), balance: -20.68, floor: -20).balanceWarning, isTrue);
    expect(view(now: at(19, 20), balance: -15.96, floor: -20).balanceWarning, isFalse);
  });

  test('a day with nothing on it gets the empty state, not an empty timeline', () {
    final v = view(now: at(7, 58));

    expect(v.hasActivity, isFalse);
    expect(v.state, TrackingState.notStarted);
    expect(v.timerText, '0:00');
    expect(v.sinceText, 'today');
    expect(v.rail, isEmpty);
  });

  group('leave', () {
    test('a whole vacation day is a finished day, not one with 7:54 left', () {
      final v = view(now: at(19, 20), leaveHours: 7.9);

      expect(v.netHours, 0);
      expect(v.remainingHours, closeTo(0, 0.001));
      expect(v.isOverTarget, isFalse);
      expect(v.leaveConflict, isNull);
      // On the rail it is one hatched block filling the bar.
      expect(v.rail.single.type, RailSegmentType.vacation);
      expect(v.rail.single.hours, 7.9);
    });

    test('half off and half worked lands on the target and says nothing', () {
      final v = view(
        now: at(17, 30),
        committedNet: 3.95,
        leaveHours: 3.95,
        sessions: [sessionRow(start: at(8, 30), end: at(12, 27))],
      );

      expect(v.remainingHours, closeTo(0, 0.001));
      expect(v.leaveConflict, isNull);
    });

    test('a vacation day that was worked anyway names the double credit', () {
      final v = view(
        now: at(20, 7),
        committedNet: 5.8167,
        leaveHours: 7.9,
        sessions: [sessionRow(start: at(9, 22), end: at(16, 0))],
      );

      expect(v.leaveConflict, isNotNull);
      expect(v.leaveConflict!.headline, 'Worked 5:49 on a vacation day');
      expect(v.leaveConflict!.detail, contains('5:49'));
      // The day is 5:49 past its target once the leave is counted, which is
      // exactly the swing the balance took.
      expect(v.remainingHours, closeTo(-5.8167, 0.001));
      expect(v.isOverTarget, isTrue);
    });
  });
}
