package dev.paulwiench.time_manager.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Keeps the widget's ring visibly advancing on its own while a session is
 * active, instead of only changing on a check-in/out tap or the OS's
 * 30-minute `updatePeriodMillis` floor (a manifest-declared widget can't go
 * below that — this self-rescheduling chain is the standard workaround).
 * Ticks once a minute, re-enqueuing itself only for as long as tracking is
 * still active; it stops naturally on checkout rather than needing an
 * explicit cancel. Best-effort timing — WorkManager can delay a tick under
 * Doze/battery optimization, same honest caveat as the 30-minute periodic
 * floor this replaces while tracking; it always catches up on the next
 * wake rather than drifting forever.
 */
class WidgetRefreshWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        TimeManagerWidget().updateAll(applicationContext)
        if (WidgetRepository.loadState(applicationContext).trackingState == TrackingState.TRACKING) {
            scheduleNext(applicationContext, ExistingWorkPolicy.REPLACE)
        }
        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "widget_refresh_tick"

        /**
         * [ExistingWorkPolicy.KEEP] (the default) is for opportunistic
         * resumption — e.g. from `provideGlance`, which can't tell whether
         * a chain is already in flight — so it never disrupts an
         * in-progress countdown. The worker's own self-reschedule uses
         * [ExistingWorkPolicy.REPLACE] explicitly, since at that point the
         * prior request (itself) has already finished.
         */
        fun scheduleNext(context: Context, policy: ExistingWorkPolicy = ExistingWorkPolicy.KEEP) {
            val request = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
                .setInitialDelay(1, TimeUnit.MINUTES)
                .build()
            WorkManager.getInstance(context).enqueueUniqueWork(WORK_NAME, policy, request)
        }
    }
}
