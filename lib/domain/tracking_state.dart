/// What today looks like right now, as the ring, the day rail, the timeline
/// and the home-screen widget all need to say it.
///
/// Pure Dart with no Flutter or database imports so it can be unit-tested,
/// and so the Kotlin widget can mirror the same rule without guessing.
enum TrackingState {
  /// Nothing logged today yet.
  notStarted,

  /// A session is open.
  tracking,

  /// Checked out, but recently enough that this reads as a break rather than
  /// the end of the day.
  onBreak,

  /// Checked out for the day.
  checkedOut,
}

/// The default window after a check-out that still counts as a break.
///
/// The app has no explicit "start break" action and deliberately doesn't want
/// one — a break is just the gap between two sessions. That leaves exactly one
/// judgement call: how long a gap can be before it stops being a break. Two
/// hours covers a long lunch plus errands without ever describing an evening
/// as "on break".
const kBreakWindow = Duration(hours: 2);

/// Derives the current state from today's sessions.
///
/// [lastCheckOut] is the end of the most recent completed session today, and
/// [completedSessionsToday] counts only sessions that actually closed — a
/// discarded one must not make the day look started.
TrackingState trackingStateFor({
  required DateTime now,
  required bool hasActiveSession,
  required DateTime? lastCheckOut,
  required int completedSessionsToday,
  Duration breakWindow = kBreakWindow,
}) {
  if (hasActiveSession) return TrackingState.tracking;
  if (completedSessionsToday == 0 || lastCheckOut == null) {
    return TrackingState.notStarted;
  }
  // A check-out timestamp in the future would mean a clock change mid-day;
  // treat it as "just now" rather than letting a negative gap read as a break
  // that never ends.
  final sinceCheckOut = now.difference(lastCheckOut);
  if (sinceCheckOut.isNegative || sinceCheckOut <= breakWindow) {
    return TrackingState.onBreak;
  }
  return TrackingState.checkedOut;
}

/// Whether a running balance has crossed a configured bound.
///
/// Both bounds are optional and unset by default, and an unset bound never
/// warns — the design has exactly one warning treatment, and it has to mean
/// something specific when it appears.
bool balanceBeyondBounds(double balance, {double? floorHours, double? capHours}) {
  if (floorHours != null && balance < floorHours) return true;
  if (capHours != null && balance > capHours) return true;
  return false;
}
