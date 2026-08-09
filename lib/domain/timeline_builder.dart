/// Builds the alternating work/break sequence shown on Home's "Today" list
/// and History's expanded day row. Pure Dart (no Flutter, no Drift row
/// types) so it stays unit-testable like the other domain engines — the UI
/// layer converts WorkSession/BreakEntry rows into the plain intervals
/// this takes.
library;

enum TimelineBlockType { work, realBreak, syntheticBreak }

class TimelineBlock {
  final TimelineBlockType type;
  final DateTime start;
  final DateTime end;

  /// Set only for [TimelineBlockType.syntheticBreak] — the BreakEntry id,
  /// needed to resolve a delete tap back to a specific row.
  final String? id;

  const TimelineBlock({required this.type, required this.start, required this.end, this.id});

  Duration get duration => end.difference(start);
}

class TimelineInterval {
  final DateTime start;
  final DateTime end;
  const TimelineInterval({required this.start, required this.end});
}

class TimelineSyntheticBreak {
  final String id;
  final DateTime start;
  final DateTime end;
  const TimelineSyntheticBreak({required this.id, required this.start, required this.end});
}

/// Merges completed work sessions and synthetic breaks into one
/// chronological block list, filling any uncovered time between two
/// occupied intervals in with a "real break" block — the app never
/// persists real breaks as their own rows (Data Model: only synthetic
/// breaks are written back), they're always just the natural gap between
/// two sessions, computed here the same way `break_engine.calculateBreaks`
/// computes them for the balance math.
///
/// [sessions] and [syntheticBreaks] need not be pre-sorted or
/// non-overlapping-checked beyond what the recalculation engine already
/// guarantees (sessions never overlap; a synthetic break always falls
/// within or immediately after a real gap, or inside the active/anchor
/// session per `break_engine`'s anchor logic).
List<TimelineBlock> buildDayTimeline({
  required List<TimelineInterval> sessions,
  required List<TimelineSyntheticBreak> syntheticBreaks,
}) {
  final occupied = <TimelineBlock>[
    for (final s in sessions) TimelineBlock(type: TimelineBlockType.work, start: s.start, end: s.end),
    for (final b in syntheticBreaks)
      TimelineBlock(type: TimelineBlockType.syntheticBreak, start: b.start, end: b.end, id: b.id),
  ]..sort((a, b) => a.start.compareTo(b.start));

  if (occupied.isEmpty) return const [];

  final result = <TimelineBlock>[occupied.first];
  for (var i = 1; i < occupied.length; i++) {
    final prevEnd = occupied[i - 1].end;
    final next = occupied[i];
    if (next.start.isAfter(prevEnd)) {
      result.add(TimelineBlock(type: TimelineBlockType.realBreak, start: prevEnd, end: next.start));
    }
    result.add(next);
  }
  return result;
}
