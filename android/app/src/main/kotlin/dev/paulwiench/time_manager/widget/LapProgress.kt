package dev.paulwiench.time_manager.widget

import android.graphics.Color as AndroidColor
import kotlin.math.ceil
import kotlin.math.pow

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

/**
 * Darkens [colorArgb] by a fixed step per completed [lapIndex], mirroring
 * the intent of `core/theme/color_space.dart`'s `darkenForLap` (same
 * 0.82-per-lap factor and 0.12 floor) so overtime laps read as
 * progressively deeper shades on the widget too. Scales HSV *value*
 * rather than Dart's HSL *lightness* — `android.graphics.Color`'s
 * `colorToHSV`/`HSVToColor` are built into the platform SDK with no extra
 * dependency, and the two aren't pixel-identical, but both read as "darker
 * each lap," which is all this cue needs.
 */
fun darkenForLap(colorArgb: Int, lapIndex: Int): Int {
    if (lapIndex <= 0) return colorArgb
    val hsv = FloatArray(3)
    AndroidColor.colorToHSV(colorArgb, hsv)
    val factor = 0.82.pow(lapIndex).toFloat()
    hsv[2] = (hsv[2] * factor).coerceIn(0.12f, 1f)
    return AndroidColor.HSVToColor(AndroidColor.alpha(colorArgb), hsv)
}
