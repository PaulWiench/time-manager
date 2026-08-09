/// Turns a day's raw entities into the DayEntry aggregate, and cascades
/// balance changes forward. See Data Model § Design Principles, § DayEntry,
/// § BalanceSnapshot, and § Recalculation Trigger Rules.
library;

import 'break_engine.dart';

class DayEntryComputation {
  final double netWorkedHours;
  final double leaveHours;
  final double targetHours;
  final double balanceDelta;

  /// Set only when auto-break logic ran and found a deficit — null when
  /// there were no sessions, break requirements were already met, or
  /// `autoBreakOverridden`/`!autoBreakEnabled` skipped the logic entirely.
  final SyntheticBreakPlan? syntheticBreak;

  const DayEntryComputation({
    required this.netWorkedHours,
    required this.leaveHours,
    required this.targetHours,
    required this.balanceDelta,
    required this.syntheticBreak,
  });
}

/// The daily target, from the weekly target spread evenly across the
/// configured work days, adjusted for a public holiday's fraction (1.0 = full
/// day off -> 0 target, 0.5 -> half the normal target). Non-work days
/// (including a holiday landing on one) always target 0 — Requirements § 4:
/// "If a public holiday falls on a non-working day... it has no effect on
/// the balance."
double computeTargetHours({
  required DateTime date,
  required List<int> workDays,
  required double weeklyHours,
  double? holidayFraction,
}) {
  final isWorkDay = workDays.contains(date.weekday);
  if (!isWorkDay || workDays.isEmpty) return 0;

  final normalDailyTarget = weeklyHours / workDays.length;
  if (holidayFraction == null) return normalDailyTarget;
  return normalDailyTarget * (1 - holidayFraction);
}

/// Computes net worked hours (and, if applicable, where a synthetic break
/// belongs) for one day, then the resulting balance_delta.
///
/// When `autoBreakOverridden` is true (the user deleted/edited a synthetic
/// break on this date) or auto-break deduction is disabled entirely, the
/// legal break logic is skipped per Data Model § DayEntry.
/// auto_break_overridden — net worked hours is then just the raw sum of
/// session durations. Manual BreakEntry rows the user records within that
/// span are treated as their own annotation, not a further deduction here;
/// this is a deliberate simplification where the Requirements doc doesn't
/// fully specify the interaction, flagged for revisit if it causes issues.
DayEntryComputation recalculateDayEntry({
  required List<WorkPeriod> completedSessions,
  required bool autoBreakEnabled,
  required bool autoBreakOverridden,
  required double leaveHours,
  required double targetHours,
}) {
  if (completedSessions.isEmpty) {
    return DayEntryComputation(
      netWorkedHours: 0,
      leaveHours: leaveHours,
      targetHours: targetHours,
      balanceDelta: leaveHours - targetHours,
      syntheticBreak: null,
    );
  }

  final runAutoBreak = autoBreakEnabled && !autoBreakOverridden;
  if (!runAutoBreak) {
    var gross = Duration.zero;
    for (final s in completedSessions) {
      gross += s.duration;
    }
    final netHours = gross.inMinutes / 60.0;
    return DayEntryComputation(
      netWorkedHours: netHours,
      leaveHours: leaveHours,
      targetHours: targetHours,
      balanceDelta: netHours + leaveHours - targetHours,
      syntheticBreak: null,
    );
  }

  final calc = calculateBreaks(completedSessions);
  final netHours = calc.netWorkedTime.inMinutes / 60.0;
  return DayEntryComputation(
    netWorkedHours: netHours,
    leaveHours: leaveHours,
    targetHours: targetHours,
    balanceDelta: netHours + leaveHours - targetHours,
    syntheticBreak: calc.syntheticBreak,
  );
}

/// The implicit balance_delta for a scheduled workday that has no DayEntry
/// at all — Data Model § Design Principles: "Workdays with no DayEntry are
/// treated as missed days (balance_delta = -target_hours)."
double missedWorkdayDelta(double targetHours) => -targetHours;

class BalanceSnapshotValue {
  final DateTime date;
  final double balance;

  const BalanceSnapshotValue({required this.date, required this.balance});
}

/// Cascades a starting balance forward through [dailyDeltas] (one entry per
/// consecutive calendar date in ascending order), producing one cumulative
/// BalanceSnapshot per day. The caller is responsible for resolving each
/// date's delta first — an existing DayEntry's balance_delta, or
/// [missedWorkdayDelta] for a scheduled workday with none, or 0 for a
/// non-work day — since that resolution needs DB/settings access this
/// pure engine doesn't have.
List<BalanceSnapshotValue> cascadeBalance({
  required double startingBalance,
  required List<MapEntry<DateTime, double>> dailyDeltas,
}) {
  final result = <BalanceSnapshotValue>[];
  var running = startingBalance;
  for (final entry in dailyDeltas) {
    running += entry.value;
    result.add(BalanceSnapshotValue(date: entry.key, balance: running));
  }
  return result;
}
