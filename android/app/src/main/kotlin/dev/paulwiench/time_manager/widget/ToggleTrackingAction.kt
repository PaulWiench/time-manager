package dev.paulwiench.time_manager.widget

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.updateAll

/** Single tap toggles check-in/out at any widget size — no separate "open
 * app" zone, per the design handoff's compact-widget spec. */
class ToggleTrackingAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        WidgetRepository.toggleTracking(context)
        TimeManagerWidget().updateAll(context)
    }
}
