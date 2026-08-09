/// Midnight auto-stop for sessions left running overnight. See Requirements
/// & Scope § Midnight Cutoff.
library;

import 'date_only.dart';

/// A same-day time-of-day range (minutes since midnight), used for the
/// optional "restrict check-in to work window" setting. Kept Flutter-free
/// on purpose — this is not `package:flutter`'s TimeOfDay.
class TimeOfDayWindow {
  final int startMinutes;
  final int endMinutes;

  const TimeOfDayWindow({required this.startMinutes, required this.endMinutes});

  /// True if [dt]'s time-of-day falls inside the window. Handles windows
  /// that wrap past midnight (start > end).
  bool contains(DateTime dt) {
    final minutes = dt.hour * 60 + dt.minute;
    if (startMinutes <= endMinutes) {
      return minutes >= startMinutes && minutes <= endMinutes;
    }
    return minutes >= startMinutes || minutes <= endMinutes;
  }
}

class MidnightCutoffResult {
  final DateTime effectiveEnd;
  final bool cutoffApplied;

  const MidnightCutoffResult({
    required this.effectiveEnd,
    required this.cutoffApplied,
  });
}

/// Whether a still-running session should be auto-stopped at 23:59 of its
/// start day. Applies once the session has crossed into the next calendar
/// day, unless [workWindow] is configured and [now] falls inside it —
/// [workWindow] is null whenever the user hasn't opted into restricting
/// check-ins to a defined window (Requirements § 3, opt-in), in which case
/// there's no window to be "outside" of and the cutoff always applies.
MidnightCutoffResult evaluateMidnightCutoff({
  required DateTime sessionStart,
  required DateTime now,
  TimeOfDayWindow? workWindow,
}) {
  final startDay =
      DateTime(sessionStart.year, sessionStart.month, sessionStart.day);
  final nextDay = shiftDays(startDay, 1);

  final crossedMidnight = !now.isBefore(nextDay);
  if (!crossedMidnight) {
    return MidnightCutoffResult(effectiveEnd: now, cutoffApplied: false);
  }

  if (workWindow != null && workWindow.contains(now)) {
    return MidnightCutoffResult(effectiveEnd: now, cutoffApplied: false);
  }

  final cutoff =
      DateTime(startDay.year, startDay.month, startDay.day, 23, 59, 59);
  return MidnightCutoffResult(effectiveEnd: cutoff, cutoffApplied: true);
}
