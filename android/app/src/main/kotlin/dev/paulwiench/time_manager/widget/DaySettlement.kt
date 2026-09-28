package dev.paulwiench.time_manager.widget

/**
 * When today stops being provisional, ported from
 * `lib/domain/day_settlement.dart`.
 *
 * The widget reads the balance from `balance_snapshots`, which Dart has
 * already cascaded — but today's snapshot carries a full-day shortfall until
 * the day has actually been worked. The app stopped printing that figure, so
 * the widget has to stop too: a launcher tile and the screen behind it
 * disagreeing about the balance is worse than either being wrong alone.
 *
 * Only the judgement is ported, not the cascade. The widget reads settled days
 * straight from the table and composes today itself, exactly as Home does.
 *
 * Both copies are tested against `src/test/resources/day_settlement.json`.
 */
object DaySettlement {
    /** Mirrors `kEndOfDayIdle`. */
    const val END_OF_DAY_IDLE_SECONDS = 60 * 60L

    /** Mirrors `TimeOfDayWindow.contains`, including a window that wraps midnight. */
    fun windowContains(minutesOfDay: Int, startMinutes: Int, endMinutes: Int): Boolean =
        if (startMinutes <= endMinutes) {
            minutesOfDay in startMinutes..endMinutes
        } else {
            minutesOfDay >= startMinutes || minutesOfDay <= endMinutes
        }

    /**
     * Whether today can be counted for what it actually was.
     *
     * The Dart original also settles any day the calendar has moved past. That
     * branch is absent here on purpose: the widget derives both "today" and
     * "now" from the same clock in the same call, so the day it is judging is
     * always the current one.
     */
    fun todayIsFinished(
        nowMinutesOfDay: Int,
        hasActiveSession: Boolean,
        secondsSinceLastCheckOut: Long?,
        windowStartMinutes: Int,
        windowEndMinutes: Int,
        idleSeconds: Long = END_OF_DAY_IDLE_SECONDS,
    ): Boolean {
        if (hasActiveSession) return false
        if (secondsSinceLastCheckOut == null) return false
        if (windowContains(nowMinutesOfDay, windowStartMinutes, windowEndMinutes)) return false
        return secondsSinceLastCheckOut > idleSeconds
    }

    /** Mirrors `todayContribution`: an unfinished day can help, never hurt. */
    fun todayContribution(delta: Double, finished: Boolean): Double =
        if (finished) delta else if (delta > 0) delta else 0.0
}
