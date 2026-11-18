package net.bladewatch.app.trips

import java.io.File
import java.nio.file.Files
import java.sql.DriverManager
import java.util.UUID
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-reml.3: the one-time wipe of all trip history, on the first start of the version that
 * costs by EV/HEV mode. Old trips were costed on both legs and carry no per-mode figures.
 */
class TripHistoryWipeTest {

    private lateinit var url: String
    private lateinit var db: TripDatabase
    private lateinit var dir: File
    private lateinit var dir2: File

    @Before
    fun setUp() {
        url = "jdbc:h2:mem:wipe_${UUID.randomUUID().toString().replace("-", "")};DB_CLOSE_DELAY=-1"
        db = TripDatabase()
        db.setJdbcUrlForTest(url)
        db.init()
        dir = Files.createTempDirectory("trips1").toFile()
        dir2 = Files.createTempDirectory("trips2").toFile()
    }

    @After
    fun tearDown() {
        try { db.close() } catch (ignored: Exception) { }
        dir.deleteRecursively()
        dir2.deleteRecursively()
    }

    private fun count(table: String): Int = DriverManager.getConnection(url, "sa", "").use { c ->
        c.createStatement().use { st -> st.executeQuery("SELECT COUNT(*) FROM $table").use { it.next(); it.getInt(1) } }
    }

    private fun trip(startMs: Long) = TripRecord().apply {
        startTime = startMs
        endTime = startMs + 900_000
        distanceKm = 12.5
        durationSeconds = 900
        startLat = 14.5; startLon = 121.0; endLat = 14.6; endLon = 121.1
        tripCost = 3.0
    }

    /** Three old trips with their rollups, a route, a learned bucket and a telemetry file each. */
    private fun seedOldHistory() {
        for (i in 1..3) {
            val t = trip(1_700_000_000_000L + i * 86_400_000L)
            db.insertTrip(t)
            db.updateWeeklyRollup(t)
            db.updateMonthlyRollup(t)
            db.findOrCreateRoute(t.startLat, t.startLon, t.endLat, t.endLon, t.distanceKm)
            File(dir, "$i.jsonl.gz").writeBytes(byteArrayOf(1, 2, 3))
        }
        File(dir2, "9.jsonl.gz").writeBytes(byteArrayOf(1))
        db.updateConsumptionBucket("urban_50_70", 0.16)
        db.updateConsumptionBucket("fuel_urban_50_70", 0.07)
    }

    @Test
    fun `the first run wipes every table and every telemetry file`() {
        seedOldHistory()
        assertEquals(3, count("trips"))

        val deleted = db.wipeTripHistoryOnce(listOf(dir, dir2), emptySet())

        assertEquals(3, deleted)
        for (t in listOf("trips", "routes", "weekly_rollups", "monthly_rollups", "consumption_buckets")) {
            assertEquals("$t must be empty", 0, count(t))
        }
        assertEquals(0, dir.listFiles()!!.size)
        assertEquals(0, dir2.listFiles()!!.size)
        assertEquals(1, count("schema_flags"))
    }

    /** Regression: a second start must not erase the trips recorded since the first. */
    @Test
    fun `the second run keeps new data`() {
        seedOldHistory()
        db.wipeTripHistoryOnce(listOf(dir), emptySet())
        db.insertTrip(trip(1_800_000_000_000L).apply { isManual = true })
        File(dir, "100.jsonl.gz").writeBytes(byteArrayOf(9))

        val deleted = db.wipeTripHistoryOnce(listOf(dir), emptySet())

        assertEquals(0, deleted)
        assertEquals(1, count("trips"))
        assertTrue(File(dir, "100.jsonl.gz").exists())
    }

    @Test
    fun `the telemetry file of the open manual trip survives`() {
        seedOldHistory()
        File(dir, "1700000555000.jsonl.gz").writeBytes(byteArrayOf(7))

        db.wipeTripHistoryOnce(listOf(dir), setOf("1700000555000.jsonl.gz"))

        assertEquals(listOf("1700000555000.jsonl.gz"), dir.listFiles()!!.map { it.name })
    }

    @Test
    fun `nothing outside the named tables and telemetry files is touched`() {
        seedOldHistory()
        DriverManager.getConnection(url, "sa", "").use { c ->
            c.createStatement().use {
                it.execute("CREATE TABLE unrelated (id INT)")
                it.execute("INSERT INTO unrelated VALUES (1)")
            }
        }
        File(dir, "notes.txt").writeText("keep me")
        File(dir, "trip.json").writeText("{}")

        db.wipeTripHistoryOnce(listOf(dir), emptySet())

        assertEquals(1, count("unrelated"))
        assertEquals(setOf("notes.txt", "trip.json"), dir.listFiles()!!.map { it.name }.toSet())
    }

    @Test
    fun `a missing telemetry directory does not stop the wipe`() {
        seedOldHistory()

        val deleted = db.wipeTripHistoryOnce(listOf(File(dir, "does-not-exist"), dir), emptySet())

        assertEquals(3, deleted)
        assertEquals(0, count("trips"))
    }

    @Test
    fun `an empty database records the flag so the wipe never runs later`() {
        assertEquals(0, db.wipeTripHistoryOnce(listOf(dir), emptySet()))
        assertEquals(1, count("schema_flags"))

        // History recorded afterwards (the new, per-mode kind) must never be wiped.
        db.insertTrip(trip(1_800_000_000_000L))
        assertEquals(0, db.wipeTripHistoryOnce(listOf(dir), emptySet()))
        assertEquals(1, count("trips"))
    }

    @Test
    fun `the flag lives in the database not in a marker file`() {
        db.wipeTripHistoryOnce(listOf(dir), emptySet())

        assertTrue(dir.listFiles()!!.isEmpty())
        assertFalse(File("trips_wipe_energy_mode_v1").exists())
    }
}
