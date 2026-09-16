package net.bladewatch.app.trips

import java.sql.DriverManager
import java.util.UUID
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-fpdz.3: persistence of the PHEV fuel leg and the metered-energy counters.
 *
 * H2 is a plain JVM library, so this runs the REAL schema, the REAL bindings and the REAL row
 * mapping against an in-memory database rather than asserting on SQL strings. That matters
 * here more than usual: the failure this guards against is a column/parameter misalignment,
 * which executes perfectly and silently writes every value into the wrong field — exactly the
 * kind of bug a string assertion would wave through.
 *
 * Each test gets its own database name so they cannot leak into one another.
 */
class TripDatabaseFuelColumnsTest {

    private lateinit var db: TripDatabase
    private lateinit var url: String

    private companion object {
        /**
         * Exact-ish tolerance for the columns this task added. They are DOUBLE PRECISION, so
         * a value must come back bit-for-bit; anything looser would hide a real rounding bug.
         */
        const val EPS = 1e-9

        /**
         * Tolerance for the PRE-EXISTING columns, which are H2 `REAL` (32-bit). They have
         * always lost precision — 0.2 stores as 0.20000000298 — and this task does not change
         * that. Asserting them at [EPS] would be asserting something that was never true.
         */
        const val EPS_FLOAT32 = 1e-6

        const val UNAVAILABLE = -1.0
    }

    @Before
    fun setUp() {
        // DB_CLOSE_DELAY=-1 keeps the in-memory DB alive for the whole test, not just the
        // first connection.
        url = "jdbc:h2:mem:trips_${UUID.randomUUID().toString().replace("-", "")};DB_CLOSE_DELAY=-1"
        db = TripDatabase()
        db.setJdbcUrlForTest(url)
        db.init()
    }

    @After
    fun tearDown() {
        try { db.close() } catch (ignored: Exception) { }
    }

    private fun phevTrip() = TripRecord().apply {
        startTime = 1_700_000_000_000L
        endTime = 1_700_000_900_000L
        distanceKm = 42.5
        durationSeconds = 900
        fuelPctStart = 80.0
        fuelPctEnd = 74.5
        fuelConStart = 1200.25
        fuelConEnd = 1203.75
        elecConStart = 5000.0
        elecConEnd = 5008.4
        litresUsed = 3.5
        fuelPricePerL = 1.80
        fuelCost = 6.30
        electricCost = 2.10
    }

    /**
     * The alignment test. Ten distinct values go in; all ten must come back in their own
     * fields. Every value differs, so a shifted binding cannot pass by coincidence.
     */
    @Test
    fun `all ten fields survive an insert and read back`() {
        val id = db.insertTrip(phevTrip())
        assertTrue("insert should return a generated id", id > 0)

        val read = db.getTrip(id)
        assertNotNull("the trip must be readable back", read)
        requireNotNull(read)

        assertEquals("fuelPctStart", 80.0, read.fuelPctStart, EPS)
        assertEquals("fuelPctEnd", 74.5, read.fuelPctEnd, EPS)
        assertEquals("fuelConStart", 1200.25, read.fuelConStart, EPS)
        assertEquals("fuelConEnd", 1203.75, read.fuelConEnd, EPS)
        assertEquals("elecConStart", 5000.0, read.elecConStart, EPS)
        assertEquals("elecConEnd", 5008.4, read.elecConEnd, EPS)
        assertEquals("litresUsed", 3.5, read.litresUsed, EPS)
        assertEquals("fuelPricePerL", 1.80, read.fuelPricePerL, EPS)
        assertEquals("fuelCost", 6.30, read.fuelCost, EPS)
        assertEquals("electricCost", 2.10, read.electricCost, EPS)
    }

    /** Adding parameters must not have shifted any pre-existing binding. */
    @Test
    fun `pre existing fields are unshifted by the new parameters`() {
        val t = phevTrip().apply {
            distanceKm = 42.5
            kwhStart = 40.0
            kwhEnd = 35.0
            energyPerKm = 0.2
            electricityRate = 0.15
            currency = "$"
            tripCost = 8.40
            maxSpeedKmh = 97
            extTempC = 21
            anticipationScore = 71
            consistencyScore = 64
            routeId = 5
        }
        val read = db.getTrip(db.insertTrip(t))
        requireNotNull(read)

        // These are the older REAL columns — see EPS_FLOAT32.
        assertEquals(42.5, read.distanceKm, EPS_FLOAT32)
        assertEquals(40.0, read.kwhStart, EPS_FLOAT32)
        assertEquals(35.0, read.kwhEnd, EPS_FLOAT32)
        assertEquals(0.2, read.energyPerKm, EPS_FLOAT32)
        assertEquals(0.15, read.electricityRate, EPS_FLOAT32)
        assertEquals("$", read.currency)
        assertEquals(8.40, read.tripCost, EPS_FLOAT32)
        assertEquals(97, read.maxSpeedKmh)
        assertEquals(21, read.extTempC)
        assertEquals(71, read.anticipationScore)
        assertEquals(64, read.consistencyScore)
        assertEquals(5L, read.routeId)
    }

    /** updateTrip binds the same ten at the same offsets, with the id last. */
    @Test
    fun `update rewrites the fuel fields without corrupting the id`() {
        val id = db.insertTrip(phevTrip())
        val updated = db.getTrip(id)
        requireNotNull(updated)
        updated.litresUsed = 9.25
        updated.fuelCost = 16.65
        updated.fuelConEnd = 1209.5
        db.updateTrip(updated)

        val read = db.getTrip(id)
        requireNotNull(read)
        assertEquals("the row must still be the same row", id, read.id)
        assertEquals(9.25, read.litresUsed, EPS)
        assertEquals(16.65, read.fuelCost, EPS)
        assertEquals(1209.5, read.fuelConEnd, EPS)
        assertEquals("untouched field must survive the update", 80.0, read.fuelPctStart, EPS)
    }

    /**
     * A BEV trip never sets a fuel reading. Those columns must read back as -1, NOT 0 —
     * otherwise a car with no fuel system looks like one that burned nothing.
     */
    @Test
    fun `a bev trip reads back unavailable rather than zero`() {
        val bev = TripRecord().apply {
            startTime = 1_700_000_000_000L
            endTime = 1_700_000_600_000L
            distanceKm = 10.0
            elecConStart = 5000.0
            elecConEnd = 5002.0
        }
        val read = db.getTrip(db.insertTrip(bev))
        requireNotNull(read)

        assertEquals("fuelPctStart", UNAVAILABLE, read.fuelPctStart, EPS)
        assertEquals("fuelPctEnd", UNAVAILABLE, read.fuelPctEnd, EPS)
        assertEquals("fuelConStart", UNAVAILABLE, read.fuelConStart, EPS)
        assertEquals("fuelConEnd", UNAVAILABLE, read.fuelConEnd, EPS)
        assertEquals("a BEV still meters electricity", 5000.0, read.elecConStart, EPS)
        assertEquals("a BEV still meters electricity", 5002.0, read.elecConEnd, EPS)
    }

    /**
     * A real 0 must round-trip as 0 and stay distinguishable from the unavailable sentinel.
     * This is the PHEV leg driven entirely on electricity: it burned nothing, and that is a
     * measurement.
     */
    @Test
    fun `a measured zero round trips as zero not as unavailable`() {
        val electricOnlyLeg = phevTrip().apply {
            fuelConStart = 1200.0
            fuelConEnd = 1200.0
            litresUsed = 0.0
            fuelCost = 0.0
            fuelPctStart = 0.0
        }
        val read = db.getTrip(db.insertTrip(electricOnlyLeg))
        requireNotNull(read)

        assertEquals("an empty tank is a reading", 0.0, read.fuelPctStart, EPS)
        assertEquals("0 litres burned is a reading", 0.0, read.litresUsed, EPS)
        assertTrue("and it must not be confused with unavailable", read.fuelConStart >= 0)
        assertEquals(1200.0, read.fuelConStart, EPS)
    }

    /**
     * BACKWARD COMPATIBILITY — the case that would corrupt real user history.
     *
     * An existing database has none of these columns. Opening it must add them via
     * ADD COLUMN IF NOT EXISTS and leave the rows already there readable, with the observed
     * counters reading -1 rather than a fabricated 0.
     */
    @Test
    fun `a database predating these columns still opens and reads`() {
        val legacyUrl =
            "jdbc:h2:mem:legacy_${UUID.randomUUID().toString().replace("-", "")};DB_CLOSE_DELAY=-1"

        // Build a trips table with the pre-fpdz shape and put a row in it.
        DriverManager.getConnection(legacyUrl, "sa", "").use { c ->
            c.createStatement().use { st ->
                st.execute(
                    "CREATE TABLE trips (" +
                        "id BIGINT AUTO_INCREMENT PRIMARY KEY, start_time BIGINT, end_time BIGINT, " +
                        "distance_km REAL, duration_seconds INT, avg_speed_kmh REAL, max_speed_kmh INT, " +
                        "soc_start REAL, soc_end REAL, efficiency_soc_per_km REAL, " +
                        "start_lat REAL, start_lon REAL, end_lat REAL, end_lon REAL, ext_temp_c INT, " +
                        "anticipation_score INT, smoothness_score INT, speed_discipline_score INT, " +
                        "efficiency_score INT, consistency_score INT, " +
                        "micro_moments_json VARCHAR, telemetry_file_path VARCHAR)"
                )
                st.execute(
                    "INSERT INTO trips (start_time, end_time, distance_km, duration_seconds) " +
                        "VALUES (1700000000000, 1700000600000, 12.5, 600)"
                )
            }
        }

        val legacyDb = TripDatabase()
        legacyDb.setJdbcUrlForTest(legacyUrl)
        legacyDb.init()   // must migrate, not throw
        try {
            val trips = legacyDb.getTrips(3650, 10)
            assertEquals("the pre-existing row must survive the migration", 1, trips.size)
            val t = trips[0]
            assertEquals("its real data must be intact", 12.5, t.distanceKm, EPS_FLOAT32)
            assertEquals("never-read counter must be unavailable, not 0",
                UNAVAILABLE, t.fuelConStart, EPS)
            assertEquals("never-read counter must be unavailable, not 0",
                UNAVAILABLE, t.elecConStart, EPS)
            assertEquals("a computed sum with nothing to sum is 0", 0.0, t.litresUsed, EPS)
        } finally {
            try { legacyDb.close() } catch (ignored: Exception) { }
        }
    }
}
