package dev.paulwiench.time_manager.widget

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File
import java.util.Calendar
import java.util.UUID

enum class TrackingState { TRACKING, BREAK, CHECKED_OUT }

/** Everything the widget needs to render, computed fresh on every update. */
data class WidgetState(
    val trackingState: TrackingState,
    val workedHours: Double,
    val targetHours: Double,
)

/**
 * Reads/writes the same SQLite file the Flutter app's Drift database uses
 * (`<dataDir>/app_flutter/time_manager.sqlite`, confirmed by inspecting the
 * on-device file — `path_provider`'s `getApplicationDocumentsDirectory()` on
 * Android resolves to `context.dataDir/app_flutter`, one level up from
 * `context.filesDir`). Drift's `DateTime` columns are unix epoch *seconds*,
 * and date-only columns (`date` on WorkSessions/DayEntries) store local
 * midnight — verified against a live onboarding run rather than assumed.
 *
 * The widget deliberately never calls into the app's recalculation engine
 * (break-law deduction, balance cascade) — that's Dart-only domain logic
 * (`recalculation_engine.dart`, `break_engine.dart`) not worth porting for
 * a glance-only surface. So it shows *gross* tracked time toward today's
 * target (raw session time, no legal-break deduction) rather than the
 * break-deducted net figure the full app shows. This is a documented scope
 * simplification, matching the precedent set by other Milestone 6/7
 * interpretation calls: opening the app always reconciles to the
 * authoritative net number; the widget is for a glance, not the ledger.
 */
object WidgetRepository {
    // path_provider's getApplicationDocumentsDirectory() on Android resolves to
    // context.dataDir/app_flutter, NOT context.filesDir/app_flutter (filesDir
    // is a level too deep, at .../files) — confirmed by inspecting the actual
    // on-device path rather than assumed; verify again if this ever moves.
    private fun dbFile(context: Context): File = File(context.dataDir, "app_flutter/time_manager.sqlite")

    private fun todayMidnightSeconds(): Long {
        val cal = Calendar.getInstance()
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis / 1000
    }

    private fun nowSeconds(): Long = System.currentTimeMillis() / 1000

    fun loadState(context: Context): WidgetState {
        val file = dbFile(context)
        if (!file.exists()) return WidgetState(TrackingState.CHECKED_OUT, 0.0, 0.0)

        val db = SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READONLY)
        try {
            val today = todayMidnightSeconds()

            var activeStart: Long? = null
            db.rawQuery(
                "SELECT start_time FROM work_sessions WHERE status = 'active' ORDER BY start_time DESC LIMIT 1",
                null,
            ).use { c -> if (c.moveToFirst()) activeStart = c.getLong(0) }

            var grossSeconds = 0L
            var hasCompletedToday = false
            db.rawQuery(
                "SELECT start_time, end_time FROM work_sessions WHERE date = ? AND status = 'completed'",
                arrayOf(today.toString()),
            ).use { c ->
                while (c.moveToNext()) {
                    grossSeconds += c.getLong(1) - c.getLong(0)
                    hasCompletedToday = true
                }
            }
            val start = activeStart
            if (start != null) grossSeconds += nowSeconds() - start
            val workedHours = grossSeconds / 3600.0

            var targetHours = 0.0
            var hasTargetRow = false
            db.rawQuery("SELECT target_hours FROM day_entries WHERE date = ?", arrayOf(today.toString())).use { c ->
                if (c.moveToFirst()) {
                    targetHours = c.getDouble(0)
                    hasTargetRow = true
                }
            }
            if (!hasTargetRow || targetHours <= 0.0) {
                targetHours = fallbackTargetHours(db, today)
            }

            val state = when {
                start != null -> TrackingState.TRACKING
                hasCompletedToday && workedHours < targetHours -> TrackingState.BREAK
                else -> TrackingState.CHECKED_OUT
            }
            return WidgetState(state, workedHours, targetHours)
        } finally {
            db.close()
        }
    }

    private fun fallbackTargetHours(db: SQLiteDatabase, today: Long): Double {
        var weeklyHours = 40.0
        var workDays = "1,2,3,4,5"
        db.rawQuery(
            "SELECT weekly_hours, work_days FROM app_settings WHERE effective_from <= ? ORDER BY effective_from DESC, created_at DESC LIMIT 1",
            arrayOf(today.toString()),
        ).use { c ->
            if (c.moveToFirst()) {
                weeklyHours = c.getDouble(0)
                workDays = c.getString(1) ?: workDays
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
     * `WorkSessionRepository.checkIn`/`checkOut` (Dart) minus the
     * recalculation step, which only Dart can perform (see class doc).
     * Still enforces the single-active-session invariant and the
     * too-short-session discard rule, so the DB stays internally
     * consistent for the next time the app itself opens and recalculates.
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
                "SELECT id, start_time FROM work_sessions WHERE status = 'active' ORDER BY start_time DESC LIMIT 1",
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
                // DayEntry rows are created lazily and WorkSessions.date FKs
                // to them (FK enforcement is on) — must exist first.
                db.execSQL("INSERT OR IGNORE INTO day_entries (date, updated_at) VALUES (?, ?)", arrayOf<Any>(today, now))
                db.execSQL(
                    "INSERT INTO work_sessions (id, date, start_time, end_time, status, created_at, updated_at) " +
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
            "SELECT min_session_minutes FROM app_settings WHERE effective_from <= ? ORDER BY effective_from DESC, created_at DESC LIMIT 1",
            arrayOf(today.toString()),
        ).use { c -> if (c.moveToFirst()) minutes = c.getInt(0) }
        return minutes
    }
}
