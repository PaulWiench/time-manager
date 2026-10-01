/// The two corrections for a day still in progress (additions handoff §5):
///
/// - **Started earlier?** — the running session began before the tap that
///   started it. Its start moves back, never forward, and never into the
///   session before it.
/// - **Check in at…** — the user is on a break and resumed work without
///   checking back in. A new session starts at a past time, between the last
///   check-out and now.
///
/// Pure: limits, stepping and what the sheet should say about a value. The
/// sheet draws it; the repository enforces the same limits again on save.
library;

import 'date_only.dart';

enum SessionFixKind { startEarlier, checkInAt }

/// Which rule set a limit, so the sheet can say why it is there.
enum FixLimitReason { workWindow, previousSession, dayStart, currentStart, checkOut, now }

/// How a value stands against the limits.
enum FixValidity {
  valid,

  /// Valid and sitting exactly on the earliest limit.
  atEarliest,

  /// The value the session already has — nothing to save.
  unchanged,

  /// Before the earliest limit (only reachable by typing).
  beforeEarliest,

  /// After the latest limit (only reachable by typing).
  afterLatest,
}

class SessionFix {
  SessionFix._({
    required this.kind,
    required this.earliest,
    required this.earliestReason,
    required this.latest,
    required this.latestReason,
    required this.initial,
    required this.stepMinutes,
    required DateTime exactEarliest,
  }) : _exactEarliest = exactEarliest;

  /// [currentStart] is the running session's start; [previousEnd] the end of
  /// the same job's last completed session that day, if any.
  /// [workWindowStartMinutes] applies only when check-in is restricted to the
  /// work window — otherwise any time of day is a valid start.
  factory SessionFix.startEarlier({
    required DateTime currentStart,
    DateTime? previousEnd,
    int? workWindowStartMinutes,
  }) {
    final day = dateOnly(currentStart);
    var earliest = day;
    var reason = FixLimitReason.dayStart;
    if (workWindowStartMinutes != null) {
      final window = day.add(Duration(minutes: workWindowStartMinutes));
      if (window.isAfter(earliest)) {
        earliest = window;
        reason = FixLimitReason.workWindow;
      }
    }
    if (previousEnd != null && previousEnd.isAfter(earliest)) {
      earliest = previousEnd;
      reason = FixLimitReason.previousSession;
    }
    final start = _toMinute(currentStart);
    if (earliest.isAfter(start)) earliest = start;
    return SessionFix._(
      kind: SessionFixKind.startEarlier,
      exactEarliest: earliest,
      earliest: _toMinute(earliest),
      earliestReason: reason,
      latest: start,
      latestReason: FixLimitReason.currentStart,
      initial: start,
      stepMinutes: 5,
    );
  }

  factory SessionFix.checkInAt({required DateTime lastCheckOut, required DateTime now}) {
    final latest = _toMinute(now);
    final earliest = _toMinute(lastCheckOut);
    return SessionFix._(
      kind: SessionFixKind.checkInAt,
      exactEarliest: lastCheckOut,
      earliest: earliest.isAfter(latest) ? latest : earliest,
      earliestReason: FixLimitReason.checkOut,
      latest: latest,
      latestReason: FixLimitReason.now,
      initial: latest,
      stepMinutes: 1,
    );
  }

  final SessionFixKind kind;
  final DateTime earliest;
  final FixLimitReason earliestReason;
  final DateTime latest;
  final FixLimitReason latestReason;
  final DateTime initial;
  final int stepMinutes;

  /// The earliest limit to the second. The sheet works in whole minutes, so
  /// [earliest] is this rounded down; choosing it saves this instead, so a
  /// check-out at 12:30:20 is resumed exactly rather than overlapped by 20 s.
  final DateTime _exactEarliest;

  /// What to save for the [value] the sheet shows.
  DateTime resolve(DateTime value) => value == earliest ? _exactEarliest : value;

  /// One step earlier, onto the step grid, never past the earliest limit —
  /// which stays reachable exactly even when it is off the grid.
  DateTime stepDown(DateTime value) {
    final minutes = value.hour * 60 + value.minute;
    final onGrid = minutes % stepMinutes == 0;
    final down = value.subtract(Duration(minutes: onGrid ? stepMinutes : minutes % stepMinutes));
    return down.isBefore(earliest) ? earliest : down;
  }

  DateTime stepUp(DateTime value) {
    final minutes = value.hour * 60 + value.minute;
    final up = value.add(Duration(minutes: stepMinutes - minutes % stepMinutes));
    return up.isAfter(latest) ? latest : up;
  }

  bool canStepDown(DateTime value) => value.isAfter(earliest);
  bool canStepUp(DateTime value) => value.isBefore(latest);

  /// [value] at hour:minute on the fix's day — what typing a time gives.
  DateTime atTimeOfDay(int hour, int minute) =>
      DateTime(latest.year, latest.month, latest.day, hour, minute);

  FixValidity validity(DateTime value) {
    if (value.isBefore(earliest)) return FixValidity.beforeEarliest;
    if (value.isAfter(latest)) return FixValidity.afterLatest;
    if (kind == SessionFixKind.startEarlier && value == latest) return FixValidity.unchanged;
    if (value == earliest) return FixValidity.atEarliest;
    return FixValidity.valid;
  }

  bool canSave(DateTime value) {
    final v = validity(value);
    return v == FixValidity.valid || v == FixValidity.atEarliest;
  }

  static DateTime _toMinute(DateTime t) => DateTime(t.year, t.month, t.day, t.hour, t.minute);

}

/// A break shorter than this does not count toward the legal break (ArbZG
/// § 4 counts breaks in blocks of at least 15 minutes).
const Duration kMinimumCountingBreak = Duration(minutes: 15);
