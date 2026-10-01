import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/session_fix.dart';

void main() {
  DateTime t(int h, int m, [int s = 0]) => DateTime(2026, 9, 22, h, m, s);

  group('Started earlier?', () {
    test('the work window is the earliest when check-in is restricted', () {
      final fix = SessionFix.startEarlier(currentStart: t(8, 12), workWindowStartMinutes: 7 * 60);
      expect(fix.earliest, t(7, 0));
      expect(fix.earliestReason, FixLimitReason.workWindow);
      expect(fix.latest, t(8, 12));
      expect(fix.initial, t(8, 12));
      expect(fix.validity(fix.initial), FixValidity.unchanged);
      expect(fix.canSave(fix.initial), isFalse);
    });

    test('without a restriction, the day start', () {
      final fix = SessionFix.startEarlier(currentStart: t(8, 12));
      expect(fix.earliest, DateTime(2026, 9, 22));
      expect(fix.earliestReason, FixLimitReason.dayStart);
    });

    test('the previous session today wins over the window', () {
      final fix = SessionFix.startEarlier(
        currentStart: t(13, 10),
        previousEnd: t(12, 30, 20),
        workWindowStartMinutes: 7 * 60,
      );
      expect(fix.earliest, t(12, 30));
      expect(fix.earliestReason, FixLimitReason.previousSession);
      // Choosing the limit saves the exact end, not 20 s inside that session.
      expect(fix.resolve(fix.earliest), t(12, 30, 20));
      expect(fix.resolve(t(12, 45)), t(12, 45));
    });

    test('steps snap to the 5-minute grid and clamp to the limits exactly', () {
      final fix = SessionFix.startEarlier(currentStart: t(8, 12), workWindowStartMinutes: 7 * 60 + 3);
      expect(fix.stepDown(t(8, 12)), t(8, 10));
      expect(fix.stepDown(t(8, 10)), t(8, 5));
      expect(fix.stepDown(t(7, 5)), t(7, 3));
      expect(fix.canStepDown(t(7, 3)), isFalse);
      expect(fix.stepUp(t(8, 5)), t(8, 10));
      expect(fix.stepUp(t(8, 10)), t(8, 12));
      expect(fix.canStepUp(t(8, 12)), isFalse);
    });

    test('validity across the range', () {
      final fix = SessionFix.startEarlier(currentStart: t(8, 12), workWindowStartMinutes: 7 * 60);
      expect(fix.validity(t(7, 45)), FixValidity.valid);
      expect(fix.validity(t(7, 0)), FixValidity.atEarliest);
      expect(fix.validity(t(6, 40)), FixValidity.beforeEarliest);
      expect(fix.validity(t(8, 30)), FixValidity.afterLatest);
      expect(fix.canSave(t(7, 0)), isTrue);
      expect(fix.canSave(t(6, 40)), isFalse);
    });
  });

  group('Check in at…', () {
    test('between the check-out and now, starting at now, 1-minute steps', () {
      final fix = SessionFix.checkInAt(lastCheckOut: t(12, 30), now: t(13, 5, 40));
      expect(fix.earliest, t(12, 30));
      expect(fix.latest, t(13, 5));
      expect(fix.initial, t(13, 5));
      expect(fix.validity(t(12, 58)), FixValidity.valid);
      expect(fix.validity(t(13, 5)), FixValidity.valid, reason: 'now is a valid check-in');
      expect(fix.validity(t(13, 20)), FixValidity.afterLatest);
      expect(fix.validity(t(12, 20)), FixValidity.beforeEarliest);
      expect(fix.stepDown(t(12, 58)), t(12, 57));
    });

    test('the check-out itself resolves to the exact second, which merges', () {
      final fix = SessionFix.checkInAt(lastCheckOut: t(12, 30, 20), now: t(13, 5));
      expect(fix.earliest, t(12, 30));
      expect(fix.resolve(t(12, 30)), t(12, 30, 20));
    });
  });
}
