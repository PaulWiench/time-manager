package dev.paulwiench.time_manager.widget

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
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
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
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
class TimeManagerWidget : GlanceAppWidget() {
    // Exact, not Responsive: Responsive hands the layout the nearest *declared*
    // size rather than the cell's real one, so a one-row-tall widget always
    // came out as the 90x90 compact layout — the "wide widget does nothing"
    // bug. Widget v2's layouts are formulas of the real width and height.
    override val sizeMode = SizeMode.Exact

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
            // Widget v2 §2.1: under 100 dp tall is one row; twice as wide as
            // tall is the 4x2; anything else is the tall layout, 1x1 included.
            when {
                size.height < 100.dp -> WideWidget(context, state, compact = size.width < 260.dp)
                size.width >= size.height * 2 -> ExpandedWidget(context, state)
                else -> TallWidget(context, state)
            }
        }
    }
}

/**
 * 1x1, 2x2, 3x3 (widget v2 §2.2): the ring in the upper third, today's hours
 * in the lower third. A launcher's 1x1 is about twice as tall as it is wide,
 * which is the room the hours sit in.
 *
 * At 1x1 the whole widget toggles check-in; from 2x2 up the ring does and the
 * rest opens the app.
 */
@Composable
private fun TallWidget(context: Context, state: WidgetState) {
    val size = LocalSize.current
    val w = size.width.value
    val h = size.height.value
    val tiny = w < 100f
    val pad = when {
        tiny -> 6f
        w < 180f -> 12f
        else -> 16f
    }
    val ring = minOf(w - 2 * pad, 0.6f * (h - 2 * pad)).toInt().coerceAtLeast(24)
    val stroke = maxOf(5f, (0.11f * ring).roundToInt().toFloat())
    val numberSp = when {
        tiny -> 18f
        w < 180f -> 28f
        else -> 40f
    }
    val showCaption = !tiny

    // Ring centred at a third of the height, never closer than the padding
    // to the top; the text block centred at five sixths.
    val ringTop = maxOf(pad, h / 3f - ring / 2f)
    val blockHeight = numberSp * 1.15f + if (showCaption) 16f else 0f
    val blockCentre = 5f * h / 6f - if (showCaption) 4f else 0f
    val gap = maxOf(0f, blockCentre - blockHeight / 2f - (ringTop + ring))

    val toggle = actionRunCallback<ToggleTrackingAction>()
    val open = actionStartActivity(Intent(context, MainActivity::class.java))

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(if (tiny) R.drawable.tm_slab_card_small else R.drawable.tm_slab_card))
            .clickable(if (tiny) toggle else open),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(GlanceModifier.height(ringTop.dp))
        Box(
            modifier = if (tiny) GlanceModifier else GlanceModifier.clickable(toggle),
            contentAlignment = Alignment.Center,
        ) {
            Ring(context, state, sizeDp = ring, strokeDp = stroke)
        }
        Spacer(GlanceModifier.height(gap.dp))
        Text(
            text = formatHours(state.netHours),
            style = TextStyle(
                fontSize = numberSp.sp,
                fontWeight = FontWeight.Bold,
                color = ColorProvider(R.color.tm_on_slab),
            ),
            maxLines = 1,
        )
        if (showCaption) {
            Text(
                text = "of ${formatHours(state.targetHours)}",
                style = TextStyle(
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium,
                    color = ColorProvider(R.color.tm_on_slab_muted),
                ),
                maxLines = 1,
            )
        }
    }
}

/**
 * 3x1 and 4x1 (widget v2 §2.3): the 4x2's content on one line — ring, state
 * and today, a divider, the balance. Under 260 dp wide the state label gives
 * way to TODAY and "of 7:54" drops, and the ring's colour and glyph carry the
 * state on their own, as on the 1x1.
 */
@Composable
private fun WideWidget(context: Context, state: WidgetState, compact: Boolean) {
    val h = LocalSize.current.height.value
    val ring = (h - 24f).toInt().coerceIn(24, 64)

    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(R.drawable.tm_slab_card_small))
            .padding(start = 12.dp, end = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = GlanceModifier.clickable(actionRunCallback<ToggleTrackingAction>()),
            contentAlignment = Alignment.Center,
        ) {
            Ring(context, state, sizeDp = ring, strokeDp = 6f)
        }
        Row(
            modifier = GlanceModifier
                .defaultWeight()
                .fillMaxHeight()
                .padding(start = 12.dp)
                .clickable(actionStartActivity(Intent(context, MainActivity::class.java))),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = if (compact) "TODAY" else stateLabel(state.trackingState),
                    style = TextStyle(
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(
                            if (compact) R.color.tm_on_slab_muted else stateColorRes(state.trackingState),
                        ),
                    ),
                    maxLines = 1,
                )
                Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = formatHours(state.netHours),
                        style = TextStyle(
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold,
                            color = ColorProvider(R.color.tm_on_slab),
                        ),
                        maxLines = 1,
                    )
                    if (!compact) {
                        Text(
                            text = " of ${formatHours(state.targetHours)}",
                            style = TextStyle(
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Medium,
                                color = ColorProvider(R.color.tm_on_slab_muted),
                            ),
                            maxLines = 1,
                        )
                    }
                }
            }
            Box(
                modifier = GlanceModifier
                    .width(1.dp)
                    .fillMaxHeight()
                    .padding(vertical = 16.dp),
                content = {
                    Box(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .background(ColorProvider(R.color.tm_slab_track)),
                        content = {},
                    )
                },
            )
            Column(
                modifier = GlanceModifier.padding(start = 12.dp),
                horizontalAlignment = Alignment.End,
            ) {
                Text(
                    text = "BALANCE",
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

/**
 * 4x2: the ring, today against target, and the balance.
 *
 * Two tap zones rather than one — the ring toggles, everything else opens the
 * app. At this size a single target would mean reaching for the widget to read
 * the balance and accidentally checking out. Widget v2 §2.4: vertical padding
 * 18 so the 112 ring is centred in 148; the ring shrinks with a shorter cell.
 */
@Composable
private fun ExpandedWidget(context: Context, state: WidgetState) {
    val h = LocalSize.current.height.value
    val ring = (h - 36f).toInt().coerceIn(48, 112)
    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ImageProvider(R.drawable.tm_slab_card))
            .padding(top = 18.dp, start = 20.dp, end = 18.dp, bottom = 18.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = GlanceModifier.clickable(actionRunCallback<ToggleTrackingAction>()),
            contentAlignment = Alignment.Center,
        ) {
            Ring(context, state, sizeDp = ring, strokeDp = if (ring >= 100) 12f else 0.11f * ring)
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
