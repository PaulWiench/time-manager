package dev.paulwiench.time_manager.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF

/**
 * The widget's ring, drawn to a [Bitmap].
 *
 * Glance has no canvas composable — its `CircularProgressIndicator` is
 * indeterminate-only — so the ring is rendered here and shown with an `Image`.
 *
 * It is deliberately the flat twin of the in-app Sun Dial rather than a copy
 * of it: no ticks, no knob, no glow. At 60 dp on a launcher those read as
 * dirt, and the widget's job is to be legible at arm's length. The state is
 * carried by a glyph in the middle instead — a disc while tracking, two bars
 * on a break, a hollow circle once the day is done — so the ring says what it
 * means without any text.
 */
fun renderProgressRing(
    sizePx: Int,
    strokeWidthPx: Float,
    progress: Float,
    lapIndex: Int,
    state: TrackingState,
    colorArgb: Int,
    lapColorArgb: Int,
    trackColorArgb: Int,
): Bitmap {
    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val radius = (sizePx - strokeWidthPx) / 2f
    val centre = sizePx / 2f
    val rect = RectF(centre - radius, centre - radius, centre + radius, centre + radius)

    fun stroke(color: Int, round: Boolean) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        this.color = color
        style = Paint.Style.STROKE
        strokeWidth = strokeWidthPx
        if (round) strokeCap = Paint.Cap.ROUND
    }

    canvas.drawArc(rect, 0f, 360f, false, stroke(trackColorArgb, round = false))

    val sweep = progress.coerceIn(0f, 1f)
    if (lapIndex > 0) {
        // A lapped ring is a full circle of the state colour with the overtime
        // arc laid over it, so "past the target" is one glance, not a count.
        canvas.drawArc(rect, 0f, 360f, false, stroke(colorArgb, round = false))
        if (sweep > 0f) {
            canvas.drawArc(rect, -90f, 360f * sweep, false, stroke(lapColorArgb, round = true))
        }
    } else if (sweep > 0f) {
        // A closed ring should meet itself rather than overlap two round caps
        // at twelve o'clock.
        canvas.drawArc(rect, -90f, 360f * sweep, false, stroke(colorArgb, round = sweep < 1f))
    }

    drawStateGlyph(canvas, sizePx, state, colorArgb)
    return bitmap
}

private fun drawStateGlyph(canvas: Canvas, sizePx: Int, state: TrackingState, colorArgb: Int) {
    val centre = sizePx / 2f
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = colorArgb }

    when (state) {
        TrackingState.TRACKING -> canvas.drawCircle(centre, centre, sizePx * 0.13f, paint)

        TrackingState.BREAK -> {
            val barWidth = sizePx * 0.078f
            val barHeight = sizePx * 0.26f
            val gap = sizePx * 0.062f
            paint.style = Paint.Style.FILL
            for (dx in listOf(-(gap / 2f + barWidth), gap / 2f)) {
                canvas.drawRoundRect(
                    RectF(
                        centre + dx,
                        centre - barHeight / 2f,
                        centre + dx + barWidth,
                        centre + barHeight / 2f,
                    ),
                    barWidth / 2f,
                    barWidth / 2f,
                    paint,
                )
            }
        }

        TrackingState.CHECKED_OUT, TrackingState.NOT_STARTED -> {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = sizePx * 0.03f
            canvas.drawCircle(centre, centre, sizePx * 0.1f, paint)
        }
    }
}
