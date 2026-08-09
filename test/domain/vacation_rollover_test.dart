import 'package:flutter_test/flutter_test.dart';
import 'package:time_manager/domain/vacation_rollover.dart';

void main() {
  group('computeNextYearRollover', () {
    const currentYear = VacationQuotaValues(totalDays: 30, rolloverDays: 2);

    test('indefinite policy carries the full unused balance forward', () {
      final next = computeNextYearRollover(
        currentYear: currentYear,
        usedDays: 25,
        policy: RolloverPolicy.indefinite,
        nextYearTotalDays: 30,
      );
      expect(next.rolloverDays, 7);
      expect(next.rolloverDeadline, isNull);
    });

    test('expireAtYearEnd policy discards unused days', () {
      final next = computeNextYearRollover(
        currentYear: currentYear,
        usedDays: 25,
        policy: RolloverPolicy.expireAtYearEnd,
        nextYearTotalDays: 30,
      );
      expect(next.rolloverDays, 0);
    });

    test('useByDeadline policy carries unused days with a deadline', () {
      final deadline = DateTime(2027, 10, 1);
      final next = computeNextYearRollover(
        currentYear: currentYear,
        usedDays: 25,
        policy: RolloverPolicy.useByDeadline,
        nextYearTotalDays: 30,
        useByDeadline: deadline,
      );
      expect(next.rolloverDays, 7);
      expect(next.rolloverDeadline, deadline);
    });

    test('unused days never go negative when more was used than available', () {
      final next = computeNextYearRollover(
        currentYear: currentYear,
        usedDays: 40,
        policy: RolloverPolicy.indefinite,
        nextYearTotalDays: 30,
      );
      expect(next.rolloverDays, 0);
    });
  });

  group('isApproachingRolloverExpiry', () {
    test('true within the warning window before the deadline', () {
      final quota = VacationQuotaValues(
        totalDays: 30,
        rolloverDays: 5,
        rolloverDeadline: DateTime(2026, 10, 1),
      );
      expect(
        isApproachingRolloverExpiry(quota, DateTime(2026, 9, 15), warnDaysBefore: 30),
        isTrue,
      );
    });

    test('false when still well before the deadline', () {
      final quota = VacationQuotaValues(
        totalDays: 30,
        rolloverDays: 5,
        rolloverDeadline: DateTime(2026, 10, 1),
      );
      expect(
        isApproachingRolloverExpiry(quota, DateTime(2026, 6, 1), warnDaysBefore: 30),
        isFalse,
      );
    });

    test('false once the deadline has passed', () {
      final quota = VacationQuotaValues(
        totalDays: 30,
        rolloverDays: 5,
        rolloverDeadline: DateTime(2026, 10, 1),
      );
      expect(
        isApproachingRolloverExpiry(quota, DateTime(2026, 10, 2), warnDaysBefore: 30),
        isFalse,
      );
    });

    test('false when there is no rollover deadline configured', () {
      const quota = VacationQuotaValues(totalDays: 30, rolloverDays: 5);
      expect(isApproachingRolloverExpiry(quota, DateTime(2026, 9, 15)), isFalse);
    });
  });
}
