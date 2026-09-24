package dev.paulwiench.time_manager.widget

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * The Kotlin half of the shared break-law fixture. Its Dart twin is
 * `test/domain/break_law_fixture_test.dart`; both read the same file, which
 * is the only thing stopping the widget's arithmetic from drifting away from
 * the app's.
 */
class BreakLawTest {
    @Test
    fun `matches the shared fixture`() {
        val json = javaClass.classLoader!!
            .getResourceAsStream("break_law.json")!!
            .bufferedReader()
            .use { it.readText() }

        val cases = JSONObject(json).getJSONArray("cases")
        require(cases.length() > 0) { "fixture is empty" }

        for (i in 0 until cases.length()) {
            val case = cases.getJSONObject(i)
            val gross = case.getLong("grossMinutes")
            val realBreaks = case.getLong("realBreakMinutes")

            assertEquals(
                case.getString("name"),
                case.getLong("expectedRequiredMinutes"),
                BreakLaw.requiredBreakMinutes(gross),
            )
            assertEquals(
                case.getString("name"),
                case.getLong("expectedNetMinutes"),
                BreakLaw.netMinutes(gross, realBreaks),
            )
        }
    }
}
