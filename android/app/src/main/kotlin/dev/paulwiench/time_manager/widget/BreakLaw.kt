package dev.paulwiench.time_manager.widget

/**
 * The German statutory break deduction (ArbZG), ported from
 * `lib/domain/break_engine.dart`.
 *
 * This is the one piece of domain logic the widget genuinely cannot borrow:
 * it runs in the launcher's process, and the number it shows has to include
 * the session running right now, which no committed row knows about yet.
 * Everything else the widget displays — the balance, today's committed net —
 * is read from rows Dart already computed.
 *
 * Only the deduction is ported, not where the synthetic break is placed. The
 * widget draws a number, not a timeline, and the anchor rule is the
 * complicated half.
 *
 * Both copies are tested against `src/test/resources/break_law.json`.
 */
object BreakLaw {
    private const val SIX_HOURS = 6 * 60
    private const val NINE_HOURS = 9 * 60

    /** Minutes of break owed for [grossMinutes] of work. */
    fun requiredBreakMinutes(grossMinutes: Long): Long = when {
        grossMinutes > NINE_HOURS -> 45
        grossMinutes > SIX_HOURS -> 30
        else -> 0
    }

    /**
     * Gross work minus whatever break is still owed. Time already spent
     * between sessions is not subtracted again — it was never counted as work
     * in the first place.
     */
    fun netMinutes(grossMinutes: Long, realBreakMinutes: Long): Long {
        val required = requiredBreakMinutes(grossMinutes)
        val deficit = (required - realBreakMinutes).coerceAtLeast(0)
        return grossMinutes - deficit
    }
}
