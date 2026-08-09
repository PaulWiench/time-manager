package dev.paulwiench.time_manager.widget

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF

/**
 * Native re-implementation of `lib/widgets/progress_ring.dart`'s CustomPainter —
 * Glance has no canvas-drawing composable (`CircularProgressIndicator` in
 * androidx.glance.appwidget is indeterminate-only), so the ring is
 * pre-rendered to a [Bitmap] here and displayed via Glance's `Image`. Same
 * round-capped stroke starting at 12 o'clock as the Flutter version, so the
 * widget ring reads identically to the in-app one.
 */
fun renderProgressRing(
    sizePx: Int,
    strokeWidthPx: Float,
    progress: Float,
    colorArgb: Int,
    trackColorArgb: Int,
): Bitmap {
    val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)

    val radius = (sizePx - strokeWidthPx) / 2f
    val rect = RectF(
        sizePx / 2f - radius,
        sizePx / 2f - radius,
        sizePx / 2f + radius,
        sizePx / 2f + radius,
    )

    val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = trackColorArgb
        style = Paint.Style.STROKE
        strokeWidth = strokeWidthPx
    }
    canvas.drawArc(rect, 0f, 360f, false, trackPaint)

    val clamped = progress.coerceIn(0f, 1f)
    if (clamped > 0f) {
        val fgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colorArgb
            style = Paint.Style.STROKE
            strokeWidth = strokeWidthPx
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawArc(rect, -90f, 360f * clamped, false, fgPaint)
    }

    return bitmap
}
