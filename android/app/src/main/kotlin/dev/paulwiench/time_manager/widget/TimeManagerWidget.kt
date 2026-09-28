package dev.paulwiench.time_manager.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import dev.paulwiench.time_manager.MainActivity
import dev.paulwiench.time_manager.R
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * The home-screen widget: the Dusk Slab, shrunk.
 *
 * Its colours come from `res/values/tm_tokens.xml`, generated from
 * `lib/core/theme/app_colors.dart` — see `widget_tokens.dart`. That matters
 * twice over: the two palettes can no longer drift apart silently, and a
 * resource-backed colour is re-resolved by the launcher when the system theme
 * flips, which is what used to leave this widget in yesterday's palette for up
 * to half an hour.
 *
 * The ring is still a bitmap, because Glance has no canvas, so its colours are
 * looked up at render time instead. That one surface still lags a theme flip
 * until the next update, and there is no way around it short of Glance growing
 * a drawing primitive.
 *
 * The slab's rounded corners come from a shape drawable rather than
 * `cornerRadius`, which is an API 31 feature and silently does nothing below.
 */
private val tinySize = DpSize(40.dp, 40.dp)
private val compactSize = DpSize(90.dp, 90.dp)
private val expandedSize = DpSize(250.dp, 110.dp)

class TimeManagerWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Responsive(setOf(tinySize, compactSize, expandedSize))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val state = WidgetRepository.loadState(context)
        // Opportunistically resumes the per-minute refresh chain whenever a
        // render observes a live session — covers a check-in started in the
        // app, which has no direct hook into the widget, and recovery after a
        // reboot. KEEP means it never disrupts a chain already ticking.
        if (state.trackingState == TrackingState.TRACKING ||
            state.trackingState == TrackingState.BREAK
        ) {
            WidgetRefreshWorker.scheduleNext(context)
        }

        provideContent {
            val size = LocalSize.current
            if (size.width < 180.dp) CompactWidget(context, state) else ExpandedWidget(context, state)
        }
    }
}

/** 1x1: a slab disc with the ring on it. The whole thing is the button. */
@Composable
private fun CompactWidget(context: Context, state: WidgetState) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(R.drawable.tm_slab_circle))
            .clickable(actionRunCallback<ToggleTrackingAction>())
            .padding(6.dp),
        contentAlignment = Alignment.Center,
    ) {
        Ring(context, state, sizeDp = 60, strokeDp = 7f)
    }
}

/**
 * 4x2: the ring, today against target, and the balance.
 *
 * Two tap zones rather than one — the ring toggles, everything else opens the
 * app. At this size a single target would mean reaching for the widget to read
 * the balance and accidentally checking out.
 */
@Composable
private fun ExpandedWidget(context: Context, state: WidgetState) {
    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(R.drawable.tm_slab_card))
            .padding(top = 16.dp, start = 20.dp, end = 16.dp, bottom = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = GlanceModifier.clickable(actionRunCallback<ToggleTrackingAction>()),
            contentAlignment = Alignment.Center,
        ) {
            Ring(context, state, sizeDp = 112, strokeDp = 12f)
        }

        Column(
            modifier = GlanceModifier
                .defaultWeight()
                .fillMaxSize()
                .padding(start = 16.dp)
                .clickable(actionStartActivity(Intent(context, MainActivity::class.java))),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = stateLabel(state.trackingState),
                style = TextStyle(
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = ColorProvider(stateColorRes(state.trackingState)),
                ),
                maxLines = 1,
            )
            // Every line is capped at one: a launcher cell is whatever width
            // the launcher feels like, and a wrapped "of 7:54" reads as two
            // unrelated numbers.
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    text = formatHours(state.netHours),
                    style = TextStyle(
                        fontSize = 28.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(R.color.tm_on_slab),
                    ),
                    maxLines = 1,
                )
                Text(
                    text = " of ${formatHours(state.targetHours)}",
                    style = TextStyle(
                        fontSize = 12.sp,
                        color = ColorProvider(R.color.tm_on_slab_muted),
                    ),
                    maxLines = 1,
                )
            }
            Spacer(GlanceModifier.height(8.dp))
            Box(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(ColorProvider(R.color.tm_slab_track)),
                content = {},
            )
            Spacer(GlanceModifier.height(8.dp))
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "BALANCE",
                    modifier = GlanceModifier.defaultWeight(),
                    style = TextStyle(
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(R.color.tm_on_slab_muted),
                    ),
                    maxLines = 1,
                )
                Text(
                    text = formatHours(state.balanceHours, signed = true),
                    style = TextStyle(
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(R.color.tm_on_slab),
                    ),
                    maxLines = 1,
                )
            }
        }
    }
}

@Composable
private fun Ring(context: Context, state: WidgetState, sizeDp: Int, strokeDp: Float) {
    val density = context.resources.displayMetrics.density
    val sizePx = (sizeDp * density).roundToInt()
    val ratio = if (state.targetHours > 0) state.netHours / state.targetHours else 0.0
    val lap = lapProgressFor(ratio)

    val bitmap = renderProgressRing(
        sizePx = sizePx,
        strokeWidthPx = strokeDp * density,
        progress = lap.fraction,
        lapIndex = lap.lapIndex,
        state = state.trackingState,
        colorArgb = ContextCompat.getColor(context, stateColorRes(state.trackingState)),
        lapColorArgb = ContextCompat.getColor(context, R.color.tm_ring_lap),
        trackColorArgb = ContextCompat.getColor(context, R.color.tm_slab_track),
    )

    Image(
        provider = ImageProvider(bitmap),
        contentDescription = stateLabel(state.trackingState),
        modifier = GlanceModifier.size(sizeDp.dp),
    )
}

private fun stateColorRes(state: TrackingState): Int = when (state) {
    TrackingState.TRACKING -> R.color.tm_accent_fill
    TrackingState.BREAK -> R.color.tm_break_fill
    TrackingState.CHECKED_OUT -> R.color.tm_idle
    TrackingState.NOT_STARTED -> R.color.tm_on_slab_muted
}

private fun stateLabel(state: TrackingState): String = when (state) {
    TrackingState.TRACKING -> "TRACKING"
    TrackingState.BREAK -> "ON BREAK"
    TrackingState.CHECKED_OUT -> "CHECKED OUT"
    TrackingState.NOT_STARTED -> "NOT STARTED"
}

private fun formatHours(hours: Double, signed: Boolean = false): String {
    val totalMinutes = (abs(hours) * 60).roundToInt()
    val sign = if (hours < 0) "−" else if (signed) "+" else ""
    return "$sign${totalMinutes / 60}:${(totalMinutes % 60).toString().padStart(2, '0')}"
}
