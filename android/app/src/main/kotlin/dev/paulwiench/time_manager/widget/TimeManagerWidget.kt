package dev.paulwiench.time_manager.widget

import android.content.Context
import android.graphics.Color as AndroidColor
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import kotlin.math.roundToInt

// Design handoff (Milestone 5/6) color tokens — kept in sync with
// lib/core/theme/app_colors.dart's `light` palette by hand, since Glance
// can't share Dart's ThemeExtension. The widget always renders in the
// light palette regardless of system theme: it's a small, low-chrome
// surface where one consistent look reads better than a day/night swap
// most launchers don't reliably signal to widgets anyway.
private val BackgroundColor = AndroidColor.parseColor("#F3F5FE")
private val TextColorInt = AndroidColor.parseColor("#292B31")
private val TrackColorInt = AndroidColor.parseColor("#DFE1EC")
private val AccentFillInt = AndroidColor.parseColor("#9184D9")
private val BreakFillInt = AndroidColor.parseColor("#44A080") // oklch(64% 0.10 168)
private val IdleFillInt = AndroidColor.parseColor("#B2B6CA")

private val compactSize = DpSize(90.dp, 90.dp)
private val expandedSize = DpSize(250.dp, 140.dp)

class TimeManagerWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Responsive(setOf(compactSize, expandedSize))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val state = WidgetRepository.loadState(context)
        provideContent {
            val size = LocalSize.current
            WidgetContent(context = context, state = state, compact = size.width < 180.dp)
        }
    }
}

@Composable
private fun WidgetContent(context: Context, state: WidgetState, compact: Boolean) {
    val ringColorInt = when (state.trackingState) {
        TrackingState.TRACKING -> AccentFillInt
        TrackingState.BREAK -> BreakFillInt
        TrackingState.CHECKED_OUT -> IdleFillInt
    }
    val progress = if (state.targetHours > 0) {
        (state.workedHours / state.targetHours).toFloat().coerceIn(0f, 1f)
    } else {
        0f
    }
    val ringSizeDp = if (compact) 68 else 84
    val ringSizePx = (ringSizeDp * context.resources.displayMetrics.density).roundToInt()
    val ringBitmap = renderProgressRing(
        sizePx = ringSizePx,
        strokeWidthPx = ringSizePx * 0.11f,
        progress = progress,
        colorArgb = ringColorInt,
        trackColorArgb = TrackColorInt,
    )

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(Color(BackgroundColor)))
            .clickable(actionRunCallback<ToggleTrackingAction>())
            .padding(if (compact) 4.dp else 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        if (compact) {
            RingWithLabel(ringBitmap, ringSizeDp, state, textSize = 12)
        } else {
            Row(
                modifier = GlanceModifier.fillMaxSize(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                RingWithLabel(ringBitmap, ringSizeDp, state, textSize = 16)
                Column(
                    modifier = GlanceModifier.padding(start = 14.dp),
                    horizontalAlignment = Alignment.Start,
                ) {
                    Text(
                        text = stateLabel(state.trackingState),
                        style = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Bold, color = ColorProvider(Color(ringColorInt))),
                    )
                    Text(
                        text = "${formatHours(state.workedHours)} of ${formatHours(state.targetHours)}",
                        style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color(TextColorInt))),
                    )
                }
            }
        }
    }
}

@Composable
private fun RingWithLabel(ringBitmap: android.graphics.Bitmap, ringSizeDp: Int, state: WidgetState, textSize: Int) {
    Box(contentAlignment = Alignment.Center) {
        Image(
            provider = ImageProvider(ringBitmap),
            contentDescription = stateLabel(state.trackingState),
            modifier = GlanceModifier.size(ringSizeDp.dp),
        )
        Text(
            text = formatHours(state.workedHours),
            style = TextStyle(fontSize = textSize.sp, fontWeight = FontWeight.Bold, color = ColorProvider(Color(TextColorInt))),
        )
    }
}

private fun stateLabel(state: TrackingState): String = when (state) {
    TrackingState.TRACKING -> "TRACKING"
    TrackingState.BREAK -> "ON BREAK"
    TrackingState.CHECKED_OUT -> "CHECKED OUT"
}

private fun formatHours(hours: Double): String {
    val totalMinutes = (hours * 60).roundToInt().coerceAtLeast(0)
    return "${totalMinutes / 60}:${(totalMinutes % 60).toString().padStart(2, '0')}"
}
