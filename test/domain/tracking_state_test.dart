import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/tracking_state.dart';

void main() {
  final now = DateTime(2026, 9, 24, 16, 30);

  TrackingState state({
    bool active = false,
    DateTime? lastOut,
    int completed = 0,
  }) =>
      trackingStateFor(
        now: now,
        hasActiveSession: active,
        lastCheckOut: lastOut,
        completedSessionsToday: completed,
      );

  test('an open session is tracking, whatever else happened today', () {
    expect(state(active: true), TrackingState.tracking);
    expect(
      state(active: true, lastOut: now.subtract(const Duration(hours: 5)), completed: 2),
      TrackingState.tracking,
    );
  });

  test('a day with nothing logged has not started', () {
    expect(state(), TrackingState.notStarted);
    // A completed count without a check-out timestamp would be inconsistent
    // data; it must not fall through to "on break".
    expect(state(completed: 1), TrackingState.notStarted);
  });

  test('a recent check-out reads as a break, an old one as the end of the day', () {
    expect(
      state(lastOut: now.subtract(const Duration(minutes: 20)), completed: 1),
      TrackingState.onBreak,
    );
    expect(
      state(lastOut: now.subtract(const Duration(hours: 4)), completed: 2),
      TrackingState.checkedOut,
    );
  });

  test('the break window boundary belongs to the break', () {
    expect(
      state(lastOut: now.subtract(kBreakWindow), completed: 1),
      TrackingState.onBreak,
    );
    expect(
      state(lastOut: now.subtract(kBreakWindow + const Duration(minutes: 1)), completed: 1),
      TrackingState.checkedOut,
    );
  });

  test('a check-out in the future does not read as an endless break', () {
    // Happens if the clock moves backwards mid-day; "just checked out" is the
    // honest answer, and it resolves itself as the clock catches up.
    expect(
      state(lastOut: now.add(const Duration(minutes: 5)), completed: 1),
      TrackingState.onBreak,
    );
  });

  group('balance bounds', () {
    test('unset bounds never warn', () {
      expect(balanceBeyondBounds(-400), isFalse);
      expect(balanceBeyondBounds(400), isFalse);
    });

    test('warns only past a bound that was actually configured', () {
      expect(balanceBeyondBounds(-19.9, floorHours: -20), isFalse);
      expect(balanceBeyondBounds(-20, floorHours: -20), isFalse);
      expect(balanceBeyondBounds(-20.1, floorHours: -20), isTrue);

      expect(balanceBeyondBounds(41, capHours: 40), isTrue);
      expect(balanceBeyondBounds(41, floorHours: -20), isFalse);
    });
  });
}
