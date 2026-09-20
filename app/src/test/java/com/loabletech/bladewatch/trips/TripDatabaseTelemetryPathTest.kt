package net.bladewatch.app.trips

import java.util.UUID
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * [TripDatabase.updateTelemetryFilePath], used by [net.bladewatch.app.storage.InternalToSdMigrator]
 * after physically moving a trip's telemetry file from internal storage to the SD card. Tested
 * directly against a real in-memory H2 database, same approach as
 * [TripDatabaseFuelColumnsTest] — the real schema and real bindings, not a mocked connection.
 */
class TripDatabaseTelemetryPathTest {

    private lateinit var db: TripDatabase

    @Before
    fun setUp() {
        val url = "jdbc:h2:mem:telemetry_path_${UUID.randomUUID().toString().replace("-", "")};DB_CLOSE_DELAY=-1"
        db = TripDatabase()
        db.setJdbcUrlForTest(url)
        db.init()
    }

    @After
    fun tearDown() {
        try { db.close() } catch (ignored: Exception) { }
    }

    private fun tripWithTelemetryPath(path: String) = TripRecord().apply {
        startTime = 1_700_000_000_000L
        endTime = 1_700_000_600_000L
        distanceKm = 5.0
        durationSeconds = 300
        telemetryFilePath = path
    }

    @Test
    fun `rewrites the matching row and returns true`() {
        val id = db.insertTrip(tripWithTelemetryPath("/internal/trips/trip_1.jsonl.gz"))

        val updated = db.updateTelemetryFilePath(
            "/internal/trips/trip_1.jsonl.gz", "/sdcard/trips/trip_1.jsonl.gz"
        )

        assertTrue(updated)
        assertEquals("/sdcard/trips/trip_1.jsonl.gz", db.getTrip(id)!!.telemetryFilePath)
    }

    @Test
    fun `no matching row returns false and touches nothing`() {
        val id = db.insertTrip(tripWithTelemetryPath("/internal/trips/trip_1.jsonl.gz"))

        val updated = db.updateTelemetryFilePath(
            "/internal/trips/does_not_exist.jsonl.gz", "/sdcard/trips/does_not_exist.jsonl.gz"
        )

        assertFalse(updated)
        assertEquals("the unrelated row must be untouched",
            "/internal/trips/trip_1.jsonl.gz", db.getTrip(id)!!.telemetryFilePath)
    }

    @Test
    fun `every row sharing the same old path is updated, not just the first`() {
        val id1 = db.insertTrip(tripWithTelemetryPath("/internal/trips/shared.jsonl.gz"))
        val id2 = db.insertTrip(tripWithTelemetryPath("/internal/trips/shared.jsonl.gz"))

        val updated = db.updateTelemetryFilePath(
            "/internal/trips/shared.jsonl.gz", "/sdcard/trips/shared.jsonl.gz"
        )

        assertTrue(updated)
        assertEquals("/sdcard/trips/shared.jsonl.gz", db.getTrip(id1)!!.telemetryFilePath)
        assertEquals("/sdcard/trips/shared.jsonl.gz", db.getTrip(id2)!!.telemetryFilePath)
    }

    @Test
    fun `a trip with no telemetry path at all is unaffected`() {
        val id = db.insertTrip(TripRecord().apply {
            startTime = 1_700_000_000_000L
            endTime = 1_700_000_600_000L
            distanceKm = 5.0
            durationSeconds = 300
        })

        val updated = db.updateTelemetryFilePath("/internal/trips/anything.jsonl.gz", "/sdcard/trips/anything.jsonl.gz")

        assertFalse(updated)
        assertEquals(null, db.getTrip(id)!!.telemetryFilePath)
    }
}
