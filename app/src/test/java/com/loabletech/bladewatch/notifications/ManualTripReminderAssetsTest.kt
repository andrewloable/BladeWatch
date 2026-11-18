package net.bladewatch.app.notifications

import java.io.File
import net.bladewatch.app.trips.ManualTripReminder
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-gklt.4: the manual trip reminder reaches the companion through the notification
 * bus, so it needs a registered category and a translated message in every server language.
 */
class ManualTripReminderAssetsTest {

    private fun assets(): File {
        var d = File("src/main/assets")
        if (!d.isDirectory) d = File("app/src/main/assets")
        assertTrue("could not locate the assets directory", d.isDirectory)
        return d
    }

    @Test
    fun `category is registered, on by default and a warning`() {
        val cats = JSONObject(File(assets(), "notifications-categories.json").readText())
            .getJSONArray("categories")
        val found = (0 until cats.length()).map { cats.getJSONObject(it) }
            .single { it.getString("id") == "trips.manual_reminder" }

        assertTrue(found.getBoolean("defaultEnabled"))
        assertEquals("warn", found.getString("severity"))
        assertEquals("Trips", found.getString("group"))
    }

    @Test
    fun `every server language carries the three reminder messages translated`() {
        val keys = listOf(
            "manual_trip_reminder_title", "manual_trip_reminder_acc_off", "manual_trip_reminder_parked",
        )
        val dir = File(assets(), "server-i18n")
        val files = dir.listFiles { f -> f.name.endsWith(".json") }!!.sortedBy { it.name }
        assertEquals(17, files.size)
        val english = JSONObject(File(dir, "en.json").readText()).getJSONObject("notifications")

        for (f in files) {
            val n = JSONObject(f.readText()).getJSONObject("notifications")
            for (k in keys) {
                assertTrue("${f.name} is missing $k", n.has(k) && n.getString(k).isNotBlank())
                if (f.name != "en.json") {
                    assertFalse("${f.name} $k is still English", n.getString(k) == english.getString(k))
                }
            }
        }
    }

    @Test
    fun `reason constants are the strings the clients match on`() {
        assertEquals("acc_off", ManualTripReminder.REASON_ACC_OFF)
        assertEquals("parked_30m", ManualTripReminder.REASON_PARKED)
    }
}
