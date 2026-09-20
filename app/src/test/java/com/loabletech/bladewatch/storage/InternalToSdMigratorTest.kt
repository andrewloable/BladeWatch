package net.bladewatch.app.storage

import net.bladewatch.app.trips.TripDatabase
import net.bladewatch.app.trips.TripRecord
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File
import java.nio.file.Files
import java.util.UUID

/**
 * [InternalToSdMigrator] sweeps files stranded on internal storage over to the SD card once it
 * becomes available (boot success or a watchdog remount) -- see
 * [StorageManager.resolveSdCardAutoPriority]'s doc comment for the incident this whole feature
 * exists to fix. `moveCategory`/`migrateTrips` are pure functions over plain [File]/[TripDatabase]
 * so they're testable without a live Android environment, the same reasoning behind
 * `StorageManagerCleanupSelectionTest`'s extraction of `selectFilesToDelete`.
 *
 * An "old" test file is backdated past [InternalToSdMigrator]'s MIN_AGE_MS guard (60s) so it
 * reads as eligible for migration; a fresh file (default mtime = now) is used to prove the
 * still-may-be-open guard actually holds files back.
 */
class InternalToSdMigratorTest {

    private lateinit var internalDir: File
    private lateinit var sdDir: File

    @Before
    fun setUp() {
        internalDir = Files.createTempDirectory("migrator-internal").toFile()
        sdDir = Files.createTempDirectory("migrator-sd").toFile()
    }

    private fun oldFile(dir: File, name: String, content: String = "x"): File {
        val f = File(dir, name)
        f.writeText(content)
        assertTrue("could not backdate mtime for $name", f.setLastModified(System.currentTimeMillis() - 120_000))
        return f
    }

    private fun freshFile(dir: File, name: String, content: String = "x"): File {
        val f = File(dir, name)
        f.writeText(content)
        return f
    }

    @Test
    fun `an old eligible file is moved from internal to sd`() {
        val f = oldFile(internalDir, "rec_1.mp4")

        val moved = InternalToSdMigrator.moveCategory(internalDir, sdDir, /* categoryActive= */ false)

        assertEquals(1, moved)
        assertFalse("must no longer exist at the internal path", f.exists())
        assertTrue("must now exist at the sd path", File(sdDir, "rec_1.mp4").exists())
    }

    @Test
    fun `a file too fresh to be safely moved is left alone`() {
        val f = freshFile(internalDir, "rec_recent.mp4")

        val moved = InternalToSdMigrator.moveCategory(internalDir, sdDir, false)

        assertEquals("a possibly-still-open file must never be moved", 0, moved)
        assertTrue(f.exists())
        assertFalse(File(sdDir, "rec_recent.mp4").exists())
    }

    @Test
    fun `an already-present destination file is left alone on both sides, never overwritten`() {
        oldFile(internalDir, "rec_dup.mp4", content = "internal-version")
        File(sdDir, "rec_dup.mp4").writeText("sd-version")

        val moved = InternalToSdMigrator.moveCategory(internalDir, sdDir, false)

        assertEquals(0, moved)
        assertEquals("internal-version", File(internalDir, "rec_dup.mp4").readText())
        assertEquals("sd-version must never be clobbered", "sd-version", File(sdDir, "rec_dup.mp4").readText())
    }

    @Test
    fun `an active category is skipped entirely, even with an old eligible file present`() {
        oldFile(internalDir, "rec_1.mp4")

        val moved = InternalToSdMigrator.moveCategory(internalDir, sdDir, /* categoryActive= */ true)

        assertEquals("must never touch files while this category is actively recording", 0, moved)
        assertTrue(File(internalDir, "rec_1.mp4").exists())
    }

    @Test
    fun `null or identical directories are a no-op, never throw`() {
        assertEquals(0, InternalToSdMigrator.moveCategory(null, sdDir, false))
        assertEquals(0, InternalToSdMigrator.moveCategory(internalDir, null, false))
        assertEquals(0, InternalToSdMigrator.moveCategory(internalDir, internalDir, false))
    }

    @Test
    fun `multiple eligible files in the same category all move`() {
        oldFile(internalDir, "rec_1.mp4")
        oldFile(internalDir, "rec_2.mp4")
        oldFile(internalDir, "rec_3.mp4")

        val moved = InternalToSdMigrator.moveCategory(internalDir, sdDir, false)

        assertEquals(3, moved)
        assertEquals(3, sdDir.listFiles()?.size)
    }

    // ==================== Trip telemetry (DB path rewrite) ====================

    private lateinit var db: TripDatabase
    private var dbUrl: String? = null

    @After
    fun tearDown() {
        if (dbUrl != null) {
            try { db.close() } catch (ignored: Exception) { }
        }
    }

    private fun openDb(): TripDatabase {
        val url = "jdbc:h2:mem:migrator_${UUID.randomUUID().toString().replace("-", "")};DB_CLOSE_DELAY=-1"
        dbUrl = url
        val d = TripDatabase()
        d.setJdbcUrlForTest(url)
        d.init()
        db = d
        return d
    }

    @Test
    fun `migrating a trip telemetry file rewrites its DB row to the new path`() {
        val tripDb = openDb()
        val f = oldFile(internalDir, "trip_42.jsonl.gz")
        val trip = TripRecord().apply {
            startTime = 1_700_000_000_000L
            endTime = 1_700_000_600_000L
            distanceKm = 5.0
            durationSeconds = 300
            telemetryFilePath = f.absolutePath
        }
        val id = tripDb.insertTrip(trip)

        val moved = InternalToSdMigrator.migrateTrips(internalDir, sdDir, tripDb)

        assertEquals(1, moved)
        val newPath = File(sdDir, "trip_42.jsonl.gz").absolutePath
        assertEquals(newPath, tripDb.getTrip(id)!!.telemetryFilePath)
    }

    @Test
    fun `a stray telemetry file with no matching DB row still moves, DB is simply untouched`() {
        val tripDb = openDb()
        oldFile(internalDir, "trip_orphan.jsonl.gz")

        val moved = InternalToSdMigrator.migrateTrips(internalDir, sdDir, tripDb)

        assertEquals(1, moved)
        assertTrue(File(sdDir, "trip_orphan.jsonl.gz").exists())
    }

    @Test
    fun `a null trip database is a no-op, never throws`() {
        oldFile(internalDir, "trip_1.jsonl.gz")

        val moved = InternalToSdMigrator.migrateTrips(internalDir, sdDir, null)

        assertEquals(0, moved)
        assertTrue("with no database to update, the file must be left where it is",
            File(internalDir, "trip_1.jsonl.gz").exists())
    }
}
