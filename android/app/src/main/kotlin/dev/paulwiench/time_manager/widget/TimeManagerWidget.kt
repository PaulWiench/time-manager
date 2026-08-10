package dev.paulwiench.time_manager.widget

import android.content.Context
import android.content.res.Configuration
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

/**
 * Design handoff (Milestone 5/6) color tokens — kept in sync with
 * lib/core/theme/app_colors.dart's `light`/`dark` palettes by hand, since
 * Glance can't share Dart's ThemeExtension. Glance 1.1.1 has no public
 * day/night [ColorProvider] (only the internal one used by its own
 * checkbox/switch translators) and no determinate circular progress
 * composable, so the ring stays a canvas-rendered bitmap — meaning, unlike
 * a resource-id-backed color, its theme can't be deferred to the launcher's
 * own re-inflation. The whole palette (ring included) is instead resolved
 * once per [TimeManagerWidget.provideGlance] call from the *system's*
 * current uiMode (app.dart uses `ThemeMode.system`, so this mirrors it) —
 * every check-in/out tap already calls `updateAll` (see
 * [ToggleTrackingAction]), so in practice the palette catches up within
 * that tap or the existing 30-minute periodic refresh, whichever is
 * sooner. A bare system theme flip with no other widget interaction can
 * lag up to that same window; there's no shorter, reliable "theme changed"
 * signal a manifest-declared widget receiver can subscribe to
 * (`ACTION_CONFIGURATION_CHANGED` is runtime-registration-only).
 */
private data class WidgetPalette(
    val background: Int,
    val text: Int,
    val track: Int,
    val accentFill: Int,
    val breakFill: Int,
    val idle: Int,
)

private val LightPalette = WidgetPalette(
    background = AndroidColor.parseColor("#F3F5FE"),
    text = AndroidColor.parseColor("#292B31"),
    track = AndroidColor.parseColor("#DFE1EC"),
    accentFill = AndroidColor.parseColor("#9184D9"),
    breakFill = AndroidColor.parseColor("#44A080"), // oklch(64% 0.10 168)
    idle = AndroidColor.parseColor("#B2B6CA"),
)

private val DarkPalette = WidgetPalette(
    background = AndroidColor.parseColor("#161826"),
    text = AndroidColor.parseColor("#E9E9ED"),
    track = AndroidColor.parseColor("#383946"),
    accentFill = AndroidColor.parseColor("#9184D9"),
    breakFill = AndroidColor.parseColor("#44A080"), // oklch(64% 0.10 168), same value both themes
    idle = AndroidColor.parseColor("#595D6C"),
)

private fun paletteFor(context: Context): WidgetPalette {
    val nightMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
    return if (nightMode == Configuration.UI_MODE_NIGHT_YES) DarkPalette else LightPalette
}

private enum class WidgetTier { TINY, COMPACT, EXPANDED }

private val tinySize = DpSize(40.dp, 40.dp)
private val compactSize = DpSize(90.dp, 90.dp)
private val expandedSize = DpSize(250.dp, 140.dp)

class TimeManagerWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Responsive(setOf(tinySize, compactSize, expandedSize))

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val state = WidgetRepository.loadState(context)
        val palette = paletteFor(context)
        provideContent {
            val size = LocalSize.current
            val tier = when {
                size.width < 70.dp -> WidgetTier.TINY
                size.width < 180.dp -> WidgetTier.COMPACT
                else -> WidgetTier.EXPANDED
            }
            WidgetContent(context = context, state = state, palette = palette, tier = tier)
        }
    }
}

@Composable
private fun WidgetContent(context: Context, state: WidgetState, palette: WidgetPalette, tier: WidgetTier) {
    val ringColorInt = when (state.trackingState) {
        TrackingState.TRACKING -> palette.accentFill
        TrackingState.BREAK -> palette.breakFill
        TrackingState.CHECKED_OUT -> palette.idle
    }
    val progress = if (state.targetHours > 0) {
        (state.workedHours / state.targetHours).toFloat().coerceIn(0f, 1f)
    } else {
        0f
    }
    val ringSizeDp = when (tier) {
        WidgetTier.TINY -> 34
        WidgetTier.COMPACT -> 68
        WidgetTier.EXPANDED -> 84
    }
    val ringSizePx = (ringSizeDp * context.resources.displayMetrics.density).roundToInt()
    val ringBitmap = renderProgressRing(
        sizePx = ringSizePx,
        strokeWidthPx = ringSizePx * 0.11f,
        progress = progress,
        colorArgb = ringColorInt,
        trackColorArgb = palette.track,
    )

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(Color(palette.background)))
            .clickable(actionRunCallback<ToggleTrackingAction>())
            .padding(if (tier == WidgetTier.TINY) 2.dp else if (tier == WidgetTier.COMPACT) 4.dp else 12.dp),
        contentAlignment = Alignment.Center,
    ) {
        if (tier == WidgetTier.EXPANDED) {
            Row(
                modifier = GlanceModifier.fillMaxSize(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                RingWithLabel(ringBitmap, ringSizeDp, state, textSize = 16, textColorInt = palette.text)
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
                        style = TextStyle(fontSize = 12.sp, color = ColorProvider(Color(palette.text))),
                    )
                }
            }
        } else {
            val textSize = if (tier == WidgetTier.TINY) 9 else 12
            RingWithLabel(ringBitmap, ringSizeDp, state, textSize = textSize, textColorInt = palette.text)
        }
    }
}

@Composable
private fun RingWithLabel(ringBitmap: android.graphics.Bitmap, ringSizeDp: Int, state: WidgetState, textSize: Int, textColorInt: Int) {
    Box(contentAlignment = Alignment.Center) {
        Image(
            provider = ImageProvider(ringBitmap),
            contentDescription = stateLabel(state.trackingState),
            modifier = GlanceModifier.size(ringSizeDp.dp),
        )
        Text(
            text = formatHours(state.workedHours),
            style = TextStyle(fontSize = textSize.sp, fontWeight = FontWeight.Bold, color = ColorProvider(Color(textColorInt))),
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
