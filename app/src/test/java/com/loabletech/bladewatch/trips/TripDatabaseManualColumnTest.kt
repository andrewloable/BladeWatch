package net.bladewatch.app.trips

import java.util.UUID
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** BladeWatch-gklt.1: the is_manual column survives insert, read and update. */
class TripDatabaseManualColumnTest {

    private lateinit var db: TripDatabase

    @Before
    fun setUp() {
        val url = "jdbc:h2:mem:trips_${UUID.randomUUID().toString().replace("-", "")};DB_CLOSE_DELAY=-1"
        db = TripDatabase()
        db.setJdbcUrlForTest(url)
        db.init()
    }

    @After
    fun tearDown() {
        try { db.close() } catch (ignored: Exception) { }
    }

    private fun trip(manual: Boolean) = TripRecord().apply {
        startTime = 1_700_000_000_000L
        endTime = 1_700_000_900_000L
        distanceKm = 12.5
        durationSeconds = 900
        fuelConStart = 100.0
        fuelConEnd = 101.5
        isManual = manual
    }

    @Test
    fun `manual flag round trips through insert and read`() {
        val manualId = db.insertTrip(trip(true))
        val autoId = db.insertTrip(trip(false))

        assertTrue(db.getTrip(manualId)!!.isManual)
        assertFalse(db.getTrip(autoId)!!.isManual)
    }

    /** updateTrip's WHERE id moved from index 44 to 45: a stale index would update nothing. */
    @Test
    fun `update keeps the flag and still targets its own row`() {
        val id = db.insertTrip(trip(true))
        val other = db.insertTrip(trip(false))
        val t = db.getTrip(id)!!
        t.distanceKm = 99.0
        db.updateTrip(t)

        val read = db.getTrip(id)!!
        assertEquals(99.0, read.distanceKm, 1e-3)
        assertTrue(read.isManual)
        assertEquals(12.5, db.getTrip(other)!!.distanceKm, 1e-3)
    }

    /** The orphan sweep deletes duration-0 rows; a manual trip stopped at once is not an orphan. */
    @Test
    fun `orphan sweep spares a manual trip with zero duration`() {
        val manualId = db.insertTrip(trip(true).apply { durationSeconds = 0 })
        val autoId = db.insertTrip(trip(false).apply { durationSeconds = 0 })

        val deleted = db.deleteOrphanedTrips(Long.MAX_VALUE)

        assertEquals(1, deleted)
        assertTrue(db.getTrip(manualId) != null)
        assertTrue(db.getTrip(autoId) == null)
    }

    /** BladeWatch-reml.1: the per-mode figures and the timeline survive insert, update and read. */
    @Test
    fun `per mode figures round trip through insert and update`() {
        val id = db.insertTrip(trip(false).apply {
            evKm = 8.25; evKwh = 0.75; hevKm = 12.5; hevLitres = 1.125
            energySegmentsJson = """[{"mode":"EV","km":8.25},{"mode":"HEV","km":12.5}]"""
        })

        val read = db.getTrip(id)!!
        assertEquals(8.25, read.evKm, 1e-9)
        assertEquals(0.75, read.evKwh, 1e-9)
        assertEquals(12.5, read.hevKm, 1e-9)
        assertEquals(1.125, read.hevLitres, 1e-9)
        assertEquals("""[{"mode":"EV","km":8.25},{"mode":"HEV","km":12.5}]""", read.energySegmentsJson)

        read.evKm = 1.0
        db.updateTrip(read)
        val again = db.getTrip(id)!!
        assertEquals(1.0, again.evKm, 1e-9)
        assertEquals(12.5, again.hevKm, 1e-9)
        assertEquals(read.energySegmentsJson, again.energySegmentsJson)
    }

    @Test
    fun `a trip without per mode data reads back zeros and no timeline`() {
        val id = db.insertTrip(trip(false))

        val read = db.getTrip(id)!!

        assertEquals(0.0, read.evKm, 1e-9)
        assertEquals(0.0, read.hevLitres, 1e-9)
        assertTrue(read.energySegmentsJson == null)
    }
}

