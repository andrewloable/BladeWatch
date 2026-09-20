package net.bladewatch.app.storage

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-g8ee: [StorageManager.sweepableDirsFrom] — which directories an orphan sweeper
 * is allowed to look at.
 *
 * This guard is security-relevant, not housekeeping. `getReapableDirs("recordings")` includes
 * the flat legacy base `/storage/emulated/0/Android/data/net.bladewatch.app/files`, which is
 * not a media directory: it holds `bladewatch_secrets.json`, `bladewatch_config.json` and
 * `.bladewatch_device_id`. `cleanupOrphanedSidecars` deletes any `.json` with no matching
 * `.mp4`, so a sweeper pointed at that directory destroys the device's legacy secrets and
 * config. `ensureSpace` is safe there only because it passes a category name prefix, and a
 * sweeper cannot copy that trick — per-actor thumbnails are `thumb_<base>_a*.jpg` and carry
 * no category prefix.
 *
 * The literal path is spelled out here on purpose. If someone edits
 * `StorageManager.LEGACY_APP_FILES_DIR`, this test fails and makes them come and think about
 * what it is protecting.
 */
class SweepableDirsTest {

    private val flatLegacyBase = File("/storage/emulated/0/Android/data/net.bladewatch.app/files")
    private val active = File("/storage/emulated/0/BladeWatch/surveillance")
    private val sdMirror = File("/storage/E000-0000/BladeWatch/surveillance")
    private val legacySubdir = File("/storage/emulated/0/Android/data/net.bladewatch.app/files/sentry_events")

    @Test
    fun dropsTheSharedFlatLegacyBase() {
        for (category in listOf("recordings", "surveillance", "proximity")) {
            val out = StorageManager.sweepableDirsFrom(
                category, listOf(active, sdMirror, legacySubdir, flatLegacyBase)
            )
            assertFalse(
                "$category exposed the flat legacy base to the sweeper — that deletes " +
                    "bladewatch_secrets.json and bladewatch_config.json",
                out.any { it.absolutePath == flatLegacyBase.absolutePath }
            )
        }
    }

    /** Dropping the base must not drop the mirror or the legacy *subdirectory*. */
    @Test
    fun keepsEveryRealMediaDirectory() {
        val out = StorageManager.sweepableDirsFrom(
            "surveillance", listOf(active, sdMirror, legacySubdir, flatLegacyBase)
        )
        assertEquals(listOf(active, sdMirror, legacySubdir), out)
    }

    /**
     * Trip telemetry is `<tripId>.jsonl.gz` with no `.mp4` anywhere, so nothing in the trips
     * directory is a sidecar and the sweeper has no business there.
     */
    @Test
    fun refusesTrips() {
        assertTrue(StorageManager.sweepableDirsFrom("trips", listOf(active, sdMirror)).isEmpty())
    }

    @Test
    fun refusesAnUnknownCategory() {
        assertTrue(StorageManager.sweepableDirsFrom("nope", listOf(active)).isEmpty())
    }
}
