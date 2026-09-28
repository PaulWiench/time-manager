package dev.paulwiench.time_manager.widget

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * The Kotlin half of the shared day-settlement fixture. Its Dart twin is
 * `test/domain/day_settlement_fixture_test.dart`; both read the same file,
 * which is the only thing stopping the widget's balance from drifting away
 * from the one on screen.
 */
class DaySettlementTest {
    private fun fixture(): JSONObject {
        val json = javaClass.classLoader!!
            .getResourceAsStream("day_settlement.json")!!
            .bufferedReader()
            .use { it.readText() }
        return JSONObject(json)
    }

    @Test
    fun `matches the shared fixture for when the day is over`() {
        val root = fixture()
        val windowStart = root.getInt("windowStartMinutes")
        val windowEnd = root.getInt("windowEndMinutes")

        val cases = root.getJSONArray("cases")
        require(cases.length() > 0) { "fixture is empty" }

        for (i in 0 until cases.length()) {
            val case = cases.getJSONObject(i)
            val idle =
                if (case.isNull("secondsSinceLastCheckOut")) null
                else case.getLong("secondsSinceLastCheckOut")

            assertEquals(
                case.getString("name"),
                case.getBoolean("expectedFinished"),
                DaySettlement.todayIsFinished(
                    nowMinutesOfDay = case.getInt("nowMinutesOfDay"),
                    hasActiveSession = case.getBoolean("hasActiveSession"),
                    secondsSinceLastCheckOut = idle,
                    windowStartMinutes = windowStart,
                    windowEndMinutes = windowEnd,
                ),
            )
        }
    }

    @Test
    fun `matches the shared fixture for what today contributes`() {
        val cases = fixture().getJSONArray("contributionCases")
        require(cases.length() > 0) { "fixture is empty" }

        for (i in 0 until cases.length()) {
            val case = cases.getJSONObject(i)
            assertEquals(
                case.getString("name"),
                case.getDouble("expected"),
                DaySettlement.todayContribution(
                    delta = case.getDouble("delta"),
                    finished = case.getBoolean("finished"),
                ),
                1e-9,
            )
        }
    }
}
