/// Which lap of the progress ring a raw worked/target ratio falls on, and
/// how far through that lap it is. A ratio of exactly 1.0 reads as a full
/// (not empty) ring at lap 0 — the lap only advances once the *next*
/// fraction of work begins, so the ring never flickers back to empty right
/// at the target.
class LapProgress {
  final int lapIndex;
  final double fraction;

  const LapProgress(this.lapIndex, this.fraction);
}

/// Converts worked/target (can exceed 1.0 during overtime) into which lap
/// is currently filling. Lap 0 is the day's regular target; each full lap
/// past that is one full extra "target's worth" of overtime, and the ring
/// keeps lapping indefinitely rather than stopping at 100%.
LapProgress lapProgressFor(double ratio) {
  if (ratio <= 0) return const LapProgress(0, 0.0);
  final lapIndex = ratio.ceil() - 1;
  final fraction = (ratio - lapIndex).clamp(0.0, 1.0);
  return LapProgress(lapIndex, fraction);
}
