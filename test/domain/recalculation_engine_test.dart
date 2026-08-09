import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/break_engine.dart';
import 'package:time_manager/domain/recalculation_engine.dart';

void main() {
  group('computeTargetHours', () {
    const workDays = [1, 2, 3, 4, 5];

    test('spreads the weekly target evenly across work days', () {
      final target = computeTargetHours(
        date: DateTime(2026, 8, 10), // Monday
        workDays: workDays,
        weeklyHours: 40,
      );
      expect(target, 8.0);
    });

    test('non-work day always targets 0, holiday or not', () {
      final target = computeTargetHours(
        date: DateTime(2026, 8, 8), // Saturday
        workDays: workDays,
        weeklyHours: 40,
        holidayFraction: 1.0,
      );
      expect(target, 0);
    });

    test('full-day holiday zeroes the target on a work day', () {
      final target = computeTargetHours(
        date: DateTime(2026, 12, 25),
        workDays: workDays,
        weeklyHours: 40,
        holidayFraction: 1.0,
      );
      expect(target, 0);
    });

    test('half-day holiday halves the target on a work day', () {
      final target = computeTargetHours(
        date: DateTime(2026, 8, 10),
        workDays: workDays,
        weeklyHours: 40,
        holidayFraction: 0.5,
      );
      expect(target, 4.0);
    });
  });

  group('recalculateDayEntry', () {
    test('a pure leave day has no worked hours and delta = leave - target', () {
      final result = recalculateDayEntry(
        completedSessions: const [],
        autoBreakEnabled: true,
        autoBreakOverridden: false,
        leaveHours: 8,
        targetHours: 8,
      );
      expect(result.netWorkedHours, 0);
      expect(result.balanceDelta, 0);
      expect(result.syntheticBreak, isNull);
    });

    test('runs the break engine when auto-break is enabled and not overridden', () {
      final result = recalculateDayEntry(
        completedSessions: [
          WorkPeriod(
            start: DateTime(2026, 8, 10, 8),
            end: DateTime(2026, 8, 10, 12),
          ),
          WorkPeriod(
            start: DateTime(2026, 8, 10, 12, 20),
            end: DateTime(2026, 8, 10, 14, 30),
          ),
        ],
        autoBreakEnabled: true,
        autoBreakOverridden: false,
        leaveHours: 0,
        targetHours: 8,
      );
      expect(result.netWorkedHours, 6.0);
      expect(result.balanceDelta, 6.0 - 8);
      expect(result.syntheticBreak, isNotNull);
    });

    test('skips the break engine when overridden, even with a real deficit', () {
      final result = recalculateDayEntry(
        completedSessions: [
          WorkPeriod(
            start: DateTime(2026, 8, 10, 8),
            end: DateTime(2026, 8, 10, 12),
          ),
          WorkPeriod(
            start: DateTime(2026, 8, 10, 12, 20),
            end: DateTime(2026, 8, 10, 14, 30),
          ),
        ],
        autoBreakEnabled: true,
        autoBreakOverridden: true,
        leaveHours: 0,
        targetHours: 8,
      );
      // Gross session time (4h + 2h10m), no deficit subtracted.
      expect(result.netWorkedHours, 6 + 10 / 60.0);
      expect(result.syntheticBreak, isNull);
    });

    test('skips the break engine when auto-break is disabled in settings', () {
      final result = recalculateDayEntry(
        completedSessions: [
          WorkPeriod(
            start: DateTime(2026, 8, 10, 8),
            end: DateTime(2026, 8, 10, 18),
          ),
        ],
        autoBreakEnabled: false,
        autoBreakOverridden: false,
        leaveHours: 0,
        targetHours: 8,
      );
      expect(result.netWorkedHours, 10.0);
      expect(result.syntheticBreak, isNull);
    });
  });

  test('missedWorkdayDelta is the negative of the target', () {
    expect(missedWorkdayDelta(8), -8);
  });

  test('cascadeBalance accumulates deltas in order from the starting balance', () {
    final snapshots = cascadeBalance(
      startingBalance: 0,
      dailyDeltas: [
        MapEntry(DateTime(2026, 8, 10), -8.0),
        MapEntry(DateTime(2026, 8, 11), 2.0),
        MapEntry(DateTime(2026, 8, 12), 0.0),
      ],
    );

    expect(snapshots.map((s) => s.balance), [-8.0, -6.0, -6.0]);
    expect(snapshots.last.date, DateTime(2026, 8, 12));
  });
}
