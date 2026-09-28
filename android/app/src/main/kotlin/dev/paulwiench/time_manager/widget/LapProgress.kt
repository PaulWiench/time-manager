package dev.paulwiench.time_manager.widget

import kotlin.math.ceil

/**
 * Kotlin mirror of `lib/domain/lap_progress.dart` — which lap of the ring a
 * raw worked/target ratio falls on, and how far through that lap it is. A
 * ratio of exactly 1.0 reads as a full (not empty) ring at lap 0; the lap
 * only advances once the *next* fraction of work begins, so the ring never
 * flickers back to empty right at the target, and keeps lapping
 * indefinitely into overtime rather than stopping at 100%.
 */
data class LapProgress(val lapIndex: Int, val fraction: Float)

fun lapProgressFor(ratio: Double): LapProgress {
    if (ratio <= 0) return LapProgress(0, 0f)
    val lapIndex = ceil(ratio).toInt() - 1
    val fraction = (ratio - lapIndex).coerceIn(0.0, 1.0).toFloat()
    return LapProgress(lapIndex, fraction)
}
