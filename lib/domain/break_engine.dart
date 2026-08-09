/// German legal break deduction (Arbeitszeitgesetz). See Requirements &
/// Scope § 2 for the full rule set and the worked example this
/// implementation is built against.
library;

/// A completed work interval. Only sessions with a known [end] participate
/// in break calculation — an active (not yet checked out) session isn't
/// part of a day's committed recalculation.
class WorkPeriod {
  final DateTime start;
  final DateTime end;

  const WorkPeriod({required this.start, required this.end});

  Duration get duration => end.difference(start);
}

/// Where a synthetic (law-mandated) break should be recorded. Stored as its
/// own BreakEntry row (type=synthetic), distinct from the "real" BreakEntry
/// that already represents the natural gap between sessions — the UX
/// deliberately shows these as separate, visually distinct blocks.
class SyntheticBreakPlan {
  final DateTime start;
  final DateTime end;

  const SyntheticBreakPlan({required this.start, required this.end});

  Duration get duration => end.difference(start);
}

class BreakCalculation {
  final Duration grossWorkTime;
  final Duration realBreakTime;
  final Duration requiredBreakTime;
  final Duration deficit;

  /// Gross work time minus the deficit — the number the UI displays. Real
  /// break gaps are never counted as work in the first place (they're the
  /// literal space between sessions), so only the deficit needs subtracting.
  final Duration netWorkedTime;

  /// Null when the real breaks already meet or exceed the legal minimum.
  final SyntheticBreakPlan? syntheticBreak;

  const BreakCalculation({
    required this.grossWorkTime,
    required this.realBreakTime,
    required this.requiredBreakTime,
    required this.deficit,
    required this.netWorkedTime,
    required this.syntheticBreak,
  });
}

/// Required break for a given amount of gross work time, per the ArbZG
/// thresholds in Requirements § 2: >6h -> 30min, >9h -> 45min.
Duration requiredBreakFor(Duration grossWorkTime) {
  if (grossWorkTime > const Duration(hours: 9)) return const Duration(minutes: 45);
  if (grossWorkTime > const Duration(hours: 6)) return const Duration(minutes: 30);
  return Duration.zero;
}

/// Computes the full break picture for one day's sessions: gross/net work
/// time and, if the real breaks fall short of the legal minimum, where to
/// place a synthetic break to make up the difference.
///
/// [sessions] must be non-empty and have no overlapping periods; the caller
/// (the recalculation engine) is responsible for filtering out
/// too-short/discarded sessions before calling this.
BreakCalculation calculateBreaks(List<WorkPeriod> sessions) {
  assert(sessions.isNotEmpty, 'calculateBreaks requires at least one session');

  final sorted = [...sessions]..sort((a, b) => a.start.compareTo(b.start));

  var grossWorkTime = Duration.zero;
  for (final s in sorted) {
    grossWorkTime += s.duration;
  }

  final gaps = <WorkPeriod>[];
  for (var i = 0; i < sorted.length - 1; i++) {
    gaps.add(WorkPeriod(start: sorted[i].end, end: sorted[i + 1].start));
  }
  var realBreakTime = Duration.zero;
  for (final g in gaps) {
    realBreakTime += g.duration;
  }

  final requiredBreakTime = requiredBreakFor(grossWorkTime);
  final deficit = requiredBreakTime > realBreakTime
      ? requiredBreakTime - realBreakTime
      : Duration.zero;
  final netWorkedTime = grossWorkTime - deficit;

  SyntheticBreakPlan? synthetic;
  if (deficit > Duration.zero) {
    final anchor = _determineAnchor(sorted);

    WorkPeriod? containingGap;
    for (final g in gaps) {
      if (!anchor.isBefore(g.start) && !anchor.isAfter(g.end)) {
        containingGap = g;
        break;
      }
    }

    synthetic = containingGap != null
        // Extends the existing real gap: the synthetic break sits right
        // after it, so together they cover the required duration.
        ? SyntheticBreakPlan(
            start: containingGap.end,
            end: containingGap.end.add(deficit),
          )
        // No gap at the anchor (a session is actively running through it):
        // insert the synthetic break directly at the anchor.
        : SyntheticBreakPlan(start: anchor, end: anchor.add(deficit));
  }

  return BreakCalculation(
    grossWorkTime: grossWorkTime,
    realBreakTime: realBreakTime,
    requiredBreakTime: requiredBreakTime,
    deficit: deficit,
    netWorkedTime: netWorkedTime,
    syntheticBreak: synthetic,
  );
}

/// Default anchor is 12:00. If noon falls outside the session window
/// (before the first check-in or after the last check-out), the anchor
/// shifts to 4 hours into the first session instead. Requirements § 2 —
/// Break anchor placement.
DateTime _determineAnchor(List<WorkPeriod> sortedSessions) {
  final first = sortedSessions.first;
  final last = sortedSessions.last;
  final noon = DateTime(first.start.year, first.start.month, first.start.day, 12);

  if (noon.isBefore(first.start) || noon.isAfter(last.end)) {
    return first.start.add(const Duration(hours: 4));
  }
  return noon;
}
