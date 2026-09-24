package dev.paulwiench.time_manager.widget

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.util.Calendar
import java.util.UUID

enum class TrackingState { TRACKING, BREAK, CHECKED_OUT, NOT_STARTED }

/** Everything the widget needs to render, computed fresh on every update. */
data class WidgetState(
    val trackingState: TrackingState,
    val netHours: Double,
    val targetHours: Double,
    val balanceHours: Double,
)

/**
 * Reads and writes the same SQLite file the app's Drift database uses
 * (`<dataDir>/app_flutter/time_manager.sqlite` — `path_provider`'s
 * `getApplicationDocumentsDirectory()` resolves to `context.dataDir/app_flutter`,
 * one level up from `context.filesDir`, confirmed on device rather than
 * assumed). Drift stores `DateTime` columns as unix epoch *seconds*, and
 * date-only columns as local midnight.
 *
 * The widget used to show gross tracked time, because the break deduction and
 * the balance cascade are Dart-only. It now shows the same net figure and the
 * same balance the app does, without porting either:
 *
 *   - The **balance** is read straight from `balance_snapshots`, which Dart
 *     has already cascaded. Nothing is recomputed.
 *   - **Today's net** is derived from today's sessions with the one rule that
 *     cannot be read from a row — the statutory break deduction — because the
 *     session running right now is not in any committed row yet. That rule is
 *     [BreakLaw], ten lines, checked against the same fixture as the Dart
 *     original.
 *
 * A cached table written by Flutter was the obvious alternative and the wrong
 * one: [toggleTracking] writes to SQLite while the app is not running, so the
 * cache would be stale exactly when the widget was being used.
 */
object WidgetRepository {
    private fun dbFile(context: Context): File =
        File(context.dataDir, "app_flutter/time_manager.sqlite")

    private fun todayMidnightSeconds(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis / 1000
    }

    private fun nowSeconds(): Long = System.currentTimeMillis() / 1000

    /** Mirrors `kBreakWindow` in lib/domain/tracking_state.dart. */
    private const val BREAK_WINDOW_SECONDS = 2 * 60 * 60

    fun loadState(context: Context): WidgetState {
        val file = dbFile(context)
        if (!file.exists()) return WidgetState(TrackingState.NOT_STARTED, 0.0, 0.0, 0.0)

        val db = SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY)
        try {
            val today = todayMidnightSeconds()
            val now = nowSeconds()

            var activeStart: Long? = null
            db.rawQuery(
                "SELECT start_time FROM work_sessions WHERE status = 'active' " +
                    "ORDER BY start_time DESC LIMIT 1",
                null,
            ).use { c -> if (c.moveToFirst()) activeStart = c.getLong(0) }

            // Completed sessions in order, so the gaps between them can be
            // counted as breaks already taken.
            val completed = mutableListOf<Pair<Long, Long>>()
            db.rawQuery(
                "SELECT start_time, end_time FROM work_sessions " +
                    "WHERE date = ? AND status = 'completed' ORDER BY start_time",
                arrayOf(today.toString()),
            ).use { c ->
                while (c.moveToNext()) completed.add(c.getLong(0) to c.getLong(1))
            }

            val periods = completed.toMutableList()
            activeStart?.let { periods.add(it to now) }

            var grossSeconds = 0L
            var realBreakSeconds = 0L
            for ((i, period) in periods.withIndex()) {
                grossSeconds += period.second - period.first
                if (i > 0) realBreakSeconds += period.first - periods[i - 1].second
            }

            val netHours = if (periods.isEmpty()) {
                0.0
            } else {
                BreakLaw.netMinutes(grossSeconds / 60, realBreakSeconds / 60) / 60.0
            }

            var targetHours = 0.0
            var hasTargetRow = false
            db.rawQuery(
                "SELECT target_hours FROM day_entries WHERE date = ?",
                arrayOf(today.toString()),
            ).use { c ->
                if (c.moveToFirst()) {
                    targetHours = c.getDouble(0)
                    hasTargetRow = true
                }
            }
            if (!hasTargetRow || targetHours <= 0.0) targetHours = fallbackTargetHours(db, today)

            var balanceHours = 0.0
            db.rawQuery(
                "SELECT balance FROM balance_snapshots ORDER BY date DESC LIMIT 1",
                null,
            ).use { c -> if (c.moveToFirst()) balanceHours = c.getDouble(0) }

            val lastCheckOut = completed.maxOfOrNull { it.second }
            return WidgetState(
                trackingState = trackingStateFor(
                    now = now,
                    activeStart = activeStart,
                    lastCheckOut = lastCheckOut,
                    targetMet = targetHours > 0 && netHours >= targetHours,
                ),
                netHours = netHours,
                targetHours = targetHours,
                balanceHours = balanceHours,
            )
        } finally {
            db.close()
        }
    }

    /**
     * Mirrors `trackingStateFor` in lib/domain/tracking_state.dart, including
     * the rule that once the day's hours are in, walking away is going home
     * rather than taking a break.
     */
    internal fun trackingStateFor(
        now: Long,
        activeStart: Long?,
        lastCheckOut: Long?,
        targetMet: Boolean,
    ): TrackingState {
        if (activeStart != null) return TrackingState.TRACKING
        if (lastCheckOut == null) return TrackingState.NOT_STARTED
        if (targetMet) return TrackingState.CHECKED_OUT
        val since = now - lastCheckOut
        return if (since <= BREAK_WINDOW_SECONDS) TrackingState.BREAK else TrackingState.CHECKED_OUT
    }

    private fun fallbackTargetHours(db: SQLiteDatabase, today: Long): Double {
        var weeklyHours = 40.0
        var workDays = "1,2,3,4,5"
        db.rawQuery(
            "SELECT weekly_hours, work_days FROM app_settings WHERE effective_from <= ? " +
                "ORDER BY effective_from DESC, created_at DESC LIMIT 1",
            arrayOf(today.toString()),
        ).use { c ->
            if (c.moveToFirst()) {
                weeklyHours = c.getDouble(0)
                workDays = c.getString(1)
            }
        }

        val days = workDays.split(",").mapNotNull { it.trim().toIntOrNull() }
        if (days.isEmpty()) return 0.0

        val cal = Calendar.getInstance()
        cal.timeInMillis = today * 1000
        // Calendar.DAY_OF_WEEK is Sunday=1..Saturday=7; the app stores ISO
        // weekdays Monday=1..Sunday=7 (see AppSettings.workDays).
        val isoWeekday = ((cal.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1
        return if (days.contains(isoWeekday)) weeklyHours / days.size else 0.0
    }

    /**
     * Toggles check-in/out with a direct, schema-consistent write — mirrors
     * `WorkSessionRepository.checkIn`/`checkOut` minus the recalculation step,
     * which only Dart can perform. It still enforces the single-active-session
     * invariant and the too-short-session discard rule, so the database stays
     * consistent for the next time the app opens and recalculates.
     */
    fun toggleTracking(context: Context) {
        val file = dbFile(context)
        if (!file.exists()) return

        val db = SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE)
        try {
            val now = nowSeconds()
            var activeId: String? = null
            var activeStart: Long? = null
            db.rawQuery(
                "SELECT id, start_time FROM work_sessions WHERE status = 'active' " +
                    "ORDER BY start_time DESC LIMIT 1",
                null,
            ).use { c ->
                if (c.moveToFirst()) {
                    activeId = c.getString(0)
                    activeStart = c.getLong(1)
                }
            }

            val id = activeId
            val start = activeStart
            if (id != null && start != null) {
                val minMinutes = minSessionMinutes(db, todayMidnightSeconds())
                val durationMinutes = (now - start) / 60.0
                val status = if (durationMinutes < minMinutes) "discarded" else "completed"
                db.execSQL(
                    "UPDATE work_sessions SET end_time = ?, status = ?, updated_at = ? WHERE id = ?",
                    arrayOf<Any>(now, status, now, id),
                )
            } else {
                val today = todayMidnightSeconds()
                // DayEntry rows are created lazily and WorkSessions.date FKs to
                // them (FK enforcement is on) — it must exist first.
                db.execSQL(
                    "INSERT OR IGNORE INTO day_entries (date, updated_at) VALUES (?, ?)",
                    arrayOf<Any>(today, now),
                )
                db.execSQL(
                    "INSERT INTO work_sessions " +
                        "(id, date, start_time, end_time, status, created_at, updated_at) " +
                        "VALUES (?, ?, ?, NULL, 'active', ?, ?)",
                    arrayOf<Any>(UUID.randomUUID().toString(), today, now, now, now),
                )
            }
        } finally {
            db.close()
        }
    }

    private fun minSessionMinutes(db: SQLiteDatabase, today: Long): Int {
        var minutes = 5
        db.rawQuery(
            "SELECT min_session_minutes FROM app_settings WHERE effective_from <= ? " +
                "ORDER BY effective_from DESC, created_at DESC LIMIT 1",
            arrayOf(today.toString()),
        ).use { c -> if (c.moveToFirst()) minutes = c.getInt(0) }
        return minutes
    }
}
