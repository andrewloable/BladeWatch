package net.bladewatch.app.config

import net.bladewatch.app.recording.RecordingPriority
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-l5w4: the one-time config migrations are the only thing standing between an
 * existing install and a silent behaviour change on upgrade, and they had no assertions at all.
 *
 * Every case here turns on a marker (`defaultOnMigrated`, `priorityMigrated`): the migration
 * must fire exactly once for a config that predates the key, and must never re-fire afterwards,
 * because re-firing would permanently override a setting the owner has since changed by hand.
 * That "never again" half is invisible in review and only surfaces on a real car after an
 * update, which is why it is pinned here rather than left to inspection.
 *
 * [ConfigMigrations] is a pure object taking a [JSONObject] precisely so this is testable
 * without a live Android environment -- the same constraint, and the same remedy, as
 * `StorageManager.selectFilesToDelete` and `DrivingSafetyGuard` (see their doc comments).
 */
class ConfigMigrationsTest {

    // ── recording.priority (2026-09) ──────────────────────────────────────

    @Test
    fun `a config predating the priority key is migrated to performance, not capped`() {
        // The pre-key world had no segment cap at all, so PERFORMANCE (the passthrough) IS
        // today's behaviour for this owner. RELIABILITY here would silently cut every
        // existing install's segment length to one minute.
        val config = JSONObject().put("recording", JSONObject().put("segmentMinutes", 10))

        val changed = ConfigMigrations.apply(config)

        assertTrue("migrating a pre-key config must report a change", changed)
        val recording = config.getJSONObject("recording")
        assertEquals(RecordingPriority.PERFORMANCE.name, recording.getString("priority"))
        assertTrue("the marker must be set, or this re-fires forever",
            recording.getBoolean("priorityMigrated"))
        assertEquals("an unrelated existing setting must survive untouched",
            10, recording.getInt("segmentMinutes"))
    }

    @Test
    fun `a deliberate reliability choice is never re-overridden`() {
        // The owner went into Settings and picked RELIABILITY after the migration already ran.
        val recording = JSONObject()
            .put("priority", RecordingPriority.RELIABILITY.name)
            .put("priorityMigrated", true)
        val config = JSONObject().put("recording", recording)
            .put("telemetryOverlay", JSONObject().put("defaultOnMigrated", true))

        val changed = ConfigMigrations.apply(config)

        assertFalse("nothing was pending, so nothing changed", changed)
        assertEquals("the owner's deliberate choice must survive",
            RecordingPriority.RELIABILITY.name,
            config.getJSONObject("recording").getString("priority"))
    }

    // ── telemetryOverlay.enabled (2026-06) ────────────────────────────────

    @Test
    fun `a config predating the overlay default flip is enabled exactly once`() {
        val config = JSONObject().put("telemetryOverlay", JSONObject().put("enabled", false))

        assertTrue(ConfigMigrations.apply(config))
        val overlay = config.getJSONObject("telemetryOverlay")
        assertTrue("the default flipped false->true; a pre-flip config is enabled once",
            overlay.getBoolean("enabled"))
        assertTrue(overlay.getBoolean("defaultOnMigrated"))
    }

    @Test
    fun `an overlay the owner switched off stays off`() {
        val config = JSONObject().put(
            "telemetryOverlay",
            JSONObject().put("enabled", false).put("defaultOnMigrated", true)
        ).put("recording", JSONObject().put("priorityMigrated", true))

        assertFalse(ConfigMigrations.apply(config))
        assertFalse("re-enabling an overlay the owner turned off is the bug the marker prevents",
            config.getJSONObject("telemetryOverlay").getBoolean("enabled"))
    }

    // ── both together ─────────────────────────────────────────────────────

    @Test
    fun `migration is idempotent - a second pass changes nothing`() {
        val config = JSONObject()

        assertTrue("first pass on an empty config migrates both sections",
            ConfigMigrations.apply(config))
        val afterFirst = config.toString()

        assertFalse("second pass must be a no-op", ConfigMigrations.apply(config))
        assertEquals("a no-op pass must not mutate the config", afterFirst, config.toString())
    }

    @Test
    fun `an empty config gets both sections created and marked`() {
        val config = JSONObject()

        ConfigMigrations.apply(config)

        assertEquals(RecordingPriority.PERFORMANCE.name,
            config.getJSONObject("recording").getString("priority"))
        assertTrue(config.getJSONObject("telemetryOverlay").getBoolean("enabled"))
    }
}
