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
 * BladeWatch-reml.2: costing, efficiency, scoring, range learning and rollups by EV/HEV mode.
 *
 * The owner's rule: EV driving is costed from kWh only, HEV driving from fuel only, and a trip that
 * switches is the sum of its segments. The guard that matters most is BEV parity: a trip with no
 * HEV driving must come out EXACTLY as it did before, because the stored costs are the user's
 * history.
 */
class TripModeCostTest {

    private companion object {
        const val EPS = 1e-9
        const val SPLIT = "[]"   // any non-null timeline: "the split was recorded"
    }

    private fun trip(block: TripRecord.() -> Unit) = TripRecord().apply(block)

    /** A trip that drove [evKm] in EV mode and [hevKm] in HEV mode. */
    private fun split(evKm: Double, evKwh: Double, hevKm: Double, hevLitres: Double) = trip {
        distanceKm = evKm + hevKm
        this.evKm = evKm; this.evKwh = evKwh; this.hevKm = hevKm; this.hevLitres = hevLitres
        energySegmentsJson = SPLIT
    }

    private fun cost(t: TripRecord, rate: Double = 0.2, price: Double = 1.8) {
        val leg = TripAnalyticsManager.electricLeg(t, 0.0)
        t.energyPerKm = if (leg.km > 0) leg.kwh / leg.km else 0.0
        TripAnalyticsManager.computeCosts(t, rate, "USD", price, leg.kwh)
    }

    // ── the three modes ──

    @Test
    fun `an EV trip is costed from kWh only`() {
        val t = split(evKm = 20.0, evKwh = 2.0, hevKm = 0.0, hevLitres = 0.0)
        // The engine's lifetime counter moved too: EV driving must still burn nothing.
        t.fuelConStart = 100.0; t.fuelConEnd = 101.0
        t.kwhStart = 20.0; t.kwhEnd = 18.0

        cost(t)

        assertEquals(0.4, t.electricCost, EPS)
        assertEquals(0.0, t.fuelCost, EPS)
        assertEquals(0.0, t.litresUsed, EPS)
        assertEquals(0.4, t.tripCost, EPS)
    }

    /** Regression: the whole-trip energy used to be costed on top of the fuel for a pure HEV trip. */
    @Test
    fun `an HEV trip is costed from fuel only`() {
        val t = split(evKm = 0.0, evKwh = 0.0, hevKm = 30.0, hevLitres = 1.5)
        // The battery moved (HVAC) and the meter counted it: HEV driving reports no electricity.
        t.kwhStart = 20.0; t.kwhEnd = 19.0
        t.elecConStart = 100.0; t.elecConEnd = 101.0
        t.socStart = 80.0; t.socEnd = 78.0

        cost(t)

        assertEquals(0.0, t.electricCost, EPS)
        assertEquals(2.7, t.fuelCost, EPS)
        assertEquals(1.5, t.litresUsed, EPS)
        assertEquals(2.7, t.tripCost, EPS)
        assertEquals("no kWh/km for a trip with no electric leg", 0.0, t.energyPerKm, EPS)
    }

    @Test
    fun `a mixed trip is the sum of its segments, each costed by its own mode`() {
        val t = split(evKm = 10.0, evKwh = 1.5, hevKm = 20.0, hevLitres = 1.2)

        cost(t)

        assertEquals(0.3, t.electricCost, EPS)
        assertEquals(2.16, t.fuelCost, EPS)
        assertEquals(2.46, t.tripCost, EPS)
        assertEquals("kWh/km over the EV kilometres only", 0.15, t.energyPerKm, EPS)
    }

    @Test
    fun `litres are recorded for an HEV trip even with no fuel price set`() {
        val t = split(evKm = 0.0, evKwh = 0.0, hevKm = 30.0, hevLitres = 1.5)

        cost(t, price = 0.0)

        assertEquals(1.5, t.litresUsed, EPS)
        assertEquals(0.0, t.fuelCost, EPS)
    }

    // ── BEV parity: nothing that has no HEV driving may move ──

    @Test
    fun `a trip with no HEV driving keeps its whole-trip electric leg and cost exactly`() {
        // (distance, kwhStart, kwhEnd, elecStart, elecEnd, socStart, socEnd, nominal)
        val cases = listOf(
            doubleArrayOf(25.0, 20.0, 15.0, 100.0, 105.4, 80.0, 60.0, 18.3),   // net drop
            doubleArrayOf(25.0, 20.0, 20.4, 100.0, 100.6, 80.0, 80.0, 18.3),   // regen: nothing
            doubleArrayOf(25.0, -1.0, -1.0, 100.0, 104.0, 80.0, 60.0, 18.3),   // metered only
            doubleArrayOf(3.0, 0.0, 0.0, -1.0, -1.0, 80.0, 70.0, 18.3),       // SoC estimate tier
            doubleArrayOf(40.0, 0.0, 0.0, -1.0, -1.0, 50.0, 50.0, 18.3),      // no source at all
            doubleArrayOf(25.0, 20.0, 15.0, 100.0, 400.0, 80.0, 60.0, 18.3),   // implausible meter
        )
        for (c in cases) {
            fun build(withSplit: Boolean) = trip {
                distanceKm = c[0]; kwhStart = c[1]; kwhEnd = c[2]
                elecConStart = c[3]; elecConEnd = c[4]; socStart = c[5]; socEnd = c[6]
                if (withSplit) {
                    evKm = c[0]; hevKm = 0.0; hevLitres = 0.0; energySegmentsJson = SPLIT
                }
            }
            val old = build(false)    // exactly what the pre-split code saw
            val new = build(true)     // the same trip, with the split recorded as all-EV

            val oldKwh = TripAnalyticsManager.resolveTripEnergyKwh(old, c[7])
            val leg = TripAnalyticsManager.electricLeg(new, c[7])
            assertEquals("electric kWh moved for ${c.toList()}", oldKwh, leg.kwh, EPS)
            assertEquals("electric km moved for ${c.toList()}", c[0], leg.km, EPS)

            TripAnalyticsManager.computeCosts(old, 0.22, "USD", 0.0, oldKwh)
            TripAnalyticsManager.computeCosts(new, 0.22, "USD", 0.0, leg.kwh)
            assertEquals(old.electricCost, new.electricCost, EPS)
            assertEquals(old.tripCost, new.tripCost, EPS)
            assertEquals(0.0, new.fuelCost, EPS)
            assertEquals(old.litresUsed, new.litresUsed, EPS)
        }
    }

    @Test
    fun `a trip recorded before the split keeps the old whole-trip legs`() {
        val t = trip {
            distanceKm = 50.0
            fuelConStart = 1000.0; fuelConEnd = 1003.0
        }

        TripAnalyticsManager.computeCosts(t, 0.2, "USD", 1.8, 5.0)

        assertEquals(1.0, t.electricCost, EPS)
        assertEquals(5.4, t.fuelCost, EPS)
        assertEquals(6.4, t.tripCost, EPS)
    }

    @Test
    fun `the electric leg accessors fall back to the whole trip without HEV driving`() {
        val bev = trip { distanceKm = 12.0; kwhStart = 10.0; kwhEnd = 8.0 }
        assertEquals(2.0, bev.getElectricLegKwh(), EPS)
        assertEquals(12.0, bev.getElectricLegKm(), EPS)
        assertEquals(12.0, bev.getFuelLegKm(), EPS)

        val mixed = split(evKm = 4.0, evKwh = 0.5, hevKm = 8.0, hevLitres = 0.6)
        assertEquals(0.5, mixed.getElectricLegKwh(), EPS)
        assertEquals(4.0, mixed.getElectricLegKm(), EPS)
        assertEquals(8.0, mixed.getFuelLegKm(), EPS)
    }

    @Test
    fun `energy used in the trip json is the electric leg`() {
        val mixed = split(evKm = 10.0, evKwh = 1.5, hevKm = 20.0, hevLitres = 1.2)
        mixed.kwhStart = 20.0; mixed.kwhEnd = 15.0   // whole-trip drop would be 5.0

        assertEquals(1.5, mixed.toSummaryJson().getDouble("energyUsedKwh"), EPS)
    }

    @Test
    fun `a trip with a split is never enriched from its SoC`() {
        val hev = split(evKm = 0.0, evKwh = 0.0, hevKm = 30.0, hevLitres = 1.5)
        hev.socStart = 80.0; hev.socEnd = 60.0

        assertTrue(!TripApiHandler.shouldEnrichEnergy(hev))
        assertTrue("an old trip with the same SoC drop still is", TripApiHandler.shouldEnrichEnergy(trip {
            socStart = 80.0; socEnd = 60.0
        }))
    }

    // ── scoring ──

    private fun samples(n: Int = 600) = (0 until n).map {
        TelemetrySample(1_000L * it, 60, 20, 0, false, 4, 14.0 + it * 1e-5, 121.0, 10.0)
    }

    private fun score(t: TripRecord): Int {
        TripScoreEngine().computeSummary(t, samples())
        return t.efficiencyScore
    }

    @Test
    fun `an HEV only trip scores neutral on efficiency instead of being judged on the battery`() {
        val t = split(evKm = 0.0, evKwh = 0.0, hevKm = 30.0, hevLitres = 1.5)
        t.socStart = 80.0; t.socEnd = 70.0   // would score on SoC drain if it counted

        assertEquals(50, score(t))
    }

    @Test
    fun `a mixed trip is scored on its electric leg only`() {
        val ev = split(evKm = 10.0, evKwh = 1.5, hevKm = 20.0, hevLitres = 1.2)   // 0.15 kWh/km
        val bev = trip { distanceKm = 10.0; kwhStart = 20.0; kwhEnd = 18.5 }       // 0.15 kWh/km
        val diluted = trip { distanceKm = 30.0; kwhStart = 20.0; kwhEnd = 18.5 }   // 0.05 kWh/km

        assertEquals(score(bev), score(ev))
        assertTrue(score(ev) != score(diluted))
    }

    @Test
    fun `a BEV trip scores exactly as it did`() {
        val plain = trip { distanceKm = 25.0; kwhStart = 20.0; kwhEnd = 16.0 }
        val withSplit = trip {
            distanceKm = 25.0; kwhStart = 20.0; kwhEnd = 16.0
            evKm = 25.0; energySegmentsJson = SPLIT
        }

        assertEquals(score(plain), score(withSplit))
    }

    // ── rollups ──

    @Test
    fun `a weekly rollup adds the electric leg and leaves HEV only trips out of the kWh per km mean`() {
        val a = split(10.0, 1.5, 20.0, 1.2).apply { energyPerKm = 0.15; tripCost = 2.46 }
        val b = split(0.0, 0.0, 30.0, 1.5).apply { energyPerKm = 0.0; tripCost = 2.7 }
        val c = trip {
            distanceKm = 10.0; kwhStart = 10.0; kwhEnd = 8.0; energyPerKm = 0.2; tripCost = 0.4
        }

        val r = WeeklyRollup.ofTrips(listOf(a, b, c))

        assertEquals(1.5 + 0.0 + 2.0, r.totalEnergyKwh, EPS)
        assertEquals("(0.15 + 0.2) / 2, the HEV only trip not counted", 0.175, r.avgEnergyPerKm, EPS)
        assertEquals(2.46 + 2.7 + 0.4, r.totalCost, EPS)
    }

    // ── range learning ──

    private lateinit var db: TripDatabase
    private lateinit var url: String

    @Before
    fun setUp() {
        url = "jdbc:h2:mem:modecost_${UUID.randomUUID().toString().replace("-", "")};DB_CLOSE_DELAY=-1"
        db = TripDatabase()
        db.setJdbcUrlForTest(url)
        db.init()
    }

    @After
    fun tearDown() {
        try { db.close() } catch (ignored: Exception) { }
    }

    private fun bucketKey(t: TripRecord) = RangeEstimator.computeBucketKey(t.avgSpeedKmh, t.extTempC, t.getOverallScore())

    @Test
    fun `range learning takes kWh per km from the EV segments and litres per km from the HEV segments`() {
        val t = split(evKm = 10.0, evKwh = 1.5, hevKm = 20.0, hevLitres = 1.2).apply {
            avgSpeedKmh = 60.0; extTempC = 20; litresUsed = 1.2
        }

        RangeEstimator(db, null).onTripCompleted(t)

        val electric = db.getBucket(bucketKey(t))
        val fuel = db.getBucket(FuelConsumption.fuelBucketKey(bucketKey(t)))
        assertNotNull(electric)
        assertNotNull(fuel)
        assertEquals("0.15 kWh/km, not 1.5 over the whole 30 km", 0.15, electric!!.getMean(), 1e-5)
        assertEquals("0.06 L/km over the 20 HEV km, not 1.2 over 30", 0.06, fuel!!.getMean(), 1e-5)
    }

    @Test
    fun `an HEV only trip teaches the fuel bucket and no electric one`() {
        val t = split(evKm = 0.0, evKwh = 0.0, hevKm = 30.0, hevLitres = 1.5).apply {
            avgSpeedKmh = 60.0; extTempC = 20; litresUsed = 1.5; socStart = 80.0; socEnd = 70.0
        }

        RangeEstimator(db, null).onTripCompleted(t)

        assertTrue("no electric sample from a trip with no electric leg", db.getBucket(bucketKey(t)) == null)
        assertEquals(0.05, db.getBucket(FuelConsumption.fuelBucketKey(bucketKey(t)))!!.getMean(), 1e-5)
    }

    @Test
    fun `an EV only trip teaches the electric bucket and no fuel one`() {
        val t = split(evKm = 20.0, evKwh = 3.0, hevKm = 0.0, hevLitres = 0.0).apply {
            avgSpeedKmh = 60.0; extTempC = 20
            kwhStart = 20.0; kwhEnd = 17.0
        }

        RangeEstimator(db, null).onTripCompleted(t)

        assertEquals(0.15, db.getBucket(bucketKey(t))!!.getMean(), 1e-5)
        assertTrue(db.getBucket(FuelConsumption.fuelBucketKey(bucketKey(t))) == null)
    }

    // ── database rollups ──

    private fun weeklyEnergy(): Double = DriverManager.getConnection(url, "sa", "").use { c ->
        c.createStatement().use { st ->
            st.executeQuery("SELECT SUM(total_energy_kwh) FROM weekly_rollups").use { it.next(); it.getDouble(1) }
        }
    }

    @Test
    fun `the stored weekly rollup adds the electric leg only`() {
        val t = split(evKm = 10.0, evKwh = 1.5, hevKm = 20.0, hevLitres = 1.2).apply {
            startTime = 1_700_000_000_000L; endTime = startTime + 900_000
            kwhStart = 20.0; kwhEnd = 15.0   // whole-trip drop 5.0 must NOT be what is stored
            energyPerKm = 0.15; tripCost = 2.46
        }

        db.updateWeeklyRollup(t)

        assertEquals(1.5, weeklyEnergy(), 1e-5)
    }
}
