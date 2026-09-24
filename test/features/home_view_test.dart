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
  }) =>
      buildHomeView(
        now: now,
        settings: settingsRow(balanceFloorHours: floor),
        dayEntry: dayEntryRow(date: today, netWorkedHours: committedNet, targetHours: target),
        sessions: sessions.cast(),
        breaks: const [],
        leave: const [],
        balance: balanceRow(date: today, balance: balance),
      );

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
    expect(v.rail.last.end, at(13, 5));
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
}
