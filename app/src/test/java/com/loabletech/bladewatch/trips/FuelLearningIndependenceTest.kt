package net.bladewatch.app.trips

import java.util.UUID
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

/**
 * Fuel-rate learning must NOT depend on the electric rate being usable.
 *
 * `RangeEstimator.onTripCompleted` has two bail-outs on the electric path — a non-positive
 * SoC delta, and a rate outside the kWh/km sanity band. Both describe the SAME kind of trip:
 * one driven on the ENGINE, where the battery barely moved.
 *
 * That is exactly the trip carrying the best fuel sample there is. While `learnFuelRate` ran
 * only after the electric path succeeded, a pure-petrol leg taught the fuel bucket nothing, so
 * litres/km was learned solely from battery-heavy mixed trips — biasing it LOW and
 * over-predicting fuel range on the trips where range matters most.
 *
 * Driven through a real H2 database rather than a mock, because what is being asserted is that
 * a row actually lands in the fuel bucket.
 */
class FuelLearningIndependenceTest {

    private lateinit var db: TripDatabase

    private companion object {
        /** `consumption_buckets` sums are H2 REAL (32-bit); see TripDatabaseFuelColumnsTest. */
        const val EPS_FLOAT32 = 1e-6
    }

    @Before
    fun setUp() {
        val url = "jdbc:h2:mem:fuellearn_${UUID.randomUUID().toString().replace("-", "")};" +
            "DB_CLOSE_DELAY=-1"
        db = TripDatabase()
        db.setJdbcUrlForTest(url)
        db.init()
    }

    @After
    fun tearDown() {
        try { db.close() } catch (ignored: Exception) { }
    }

    /**
     * A leg driven entirely on the engine: 100 km, 6 litres burned (0.06 L/km), and the
     * battery did not move — so the electric path finds no SoC delta and gives up.
     */
    private fun engineOnlyTrip() = TripRecord().apply {
        distanceKm = 100.0
        avgSpeedKmh = 80.0
        extTempC = 20
        socStart = 30.0
        socEnd = 30.0          // flat: the electric path bails here
        kwhStart = -1.0
        kwhEnd = -1.0
        elecConStart = -1.0
        elecConEnd = -1.0
        fuelConStart = 1000.0
        fuelConEnd = 1006.0    // 6 L over 100 km
        litresUsed = 6.0
    }

    private fun fuelBucketFor(trip: TripRecord) = db.getBucket(
        FuelConsumption.fuelBucketKey(
            RangeEstimator.computeBucketKey(
                trip.avgSpeedKmh, trip.extTempC, trip.getOverallScore()
            )
        )
    )

    @Test
    fun `an engine-only leg still teaches the fuel bucket`() {
        val trip = engineOnlyTrip()
        RangeEstimator(db).onTripCompleted(trip)

        val bucket = fuelBucketFor(trip)
        assertNotNull(
            "a pure-petrol leg is the best fuel sample there is; it must not be discarded " +
                "just because the electric path had nothing to learn",
            bucket,
        )
        assertEquals(1, bucket!!.sampleCount)
        assertEquals(0.06, bucket.getMean(), EPS_FLOAT32)
    }

    /** The electric bucket must stay empty for that trip — it genuinely learned nothing. */
    @Test
    fun `an engine-only leg teaches the electric bucket nothing`() {
        val trip = engineOnlyTrip()
        RangeEstimator(db).onTripCompleted(trip)

        assertNull(
            "no usable electric rate, so no electric sample",
            db.getOverallAverage(),
        )
    }

    /**
     * The converse, already documented on `learnFuelRate`: a leg driven entirely on battery is
     * a perfectly good kWh/km sample and no fuel sample at all. Burning zero litres must not
     * enter the fuel bucket, or the learned rate is dragged toward zero and fuel range
     * inflates without limit.
     */
    @Test
    fun `a battery-only leg teaches the fuel bucket nothing`() {
        val trip = engineOnlyTrip().apply {
            socStart = 80.0
            socEnd = 60.0        // a real electric sample
            fuelConEnd = 1000.0  // counter read, zero litres burned
            litresUsed = 0.0
        }
        RangeEstimator(db).onTripCompleted(trip)

        assertNull("0 L/km is undefined, not a rate", fuelBucketFor(trip))
    }

    /**
     * A BEV must never create fuel state of any kind.
     *
     * `learnFuelRate` now runs on every trip past the distance guard, so the invariant is not
     * enforced by "we don't call it" — it rests on a BEV's fuel counters staying at the -1
     * unavailable sentinel (`TripDetector.captureStart` gates the fuel pair on the drivetrain),
     * which leaves `litresUsed` at 0, which `FuelConsumption.litresPerKm` rejects.
     *
     * That is three links in a chain, in three different files. This pins the END of it, so a
     * change to any link that lets a BEV grow a fuel bucket fails here rather than shipping.
     */
    @Test
    fun `a bev trip creates no fuel bucket`() {
        val trip = TripRecord().apply {
            distanceKm = 50.0
            avgSpeedKmh = 70.0
            extTempC = 18
            socStart = 80.0
            socEnd = 60.0
            // The direct BMS reading, not the SoC fallback: that fallback multiplies by
            // nominal pack capacity, which comes from the HAL and reads 0 off-device, so it
            // would yield a 0 kWh/km rate and be rejected as an outlier here for reasons
            // having nothing to do with the drivetrain. 8 kWh over 50 km = 0.16 kWh/km.
            kwhStart = 50.0
            kwhEnd = 42.0
            // Every fuel field at the unavailable sentinel, exactly as a BEV records them.
            fuelPctStart = -1.0
            fuelPctEnd = -1.0
            fuelConStart = -1.0
            fuelConEnd = -1.0
            litresUsed = 0.0
        }
        RangeEstimator(db).onTripCompleted(trip)

        assertNull("a car with no tank must not grow a fuel bucket", fuelBucketFor(trip))
        // ...while the electric side learned normally.
        assertNotNull("the electric trip is still a good kWh/km sample", db.getOverallAverage())
    }

    /**
     * Too short to learn anything from either tank — the one guard that legitimately gates
     * both paths.
     *
     * The litres are scaled to keep the RATE inside the plausible band (0.04 L over 0.4 km is
     * 0.10 L/km, a perfectly ordinary figure). That matters: with the trip's usual 6 L the
     * rate would be 15 L/km and `FuelConsumption.litresPerKm` would reject it on the sanity
     * band alone, so the test would pass whether or not the distance guard existed at all.
     */
    @Test
    fun `a very short trip teaches neither bucket`() {
        val trip = engineOnlyTrip().apply {
            distanceKm = 0.4
            fuelConEnd = fuelConStart + 0.04
            litresUsed = 0.04
        }
        RangeEstimator(db).onTripCompleted(trip)

        assertNull("below the minimum learnable distance", fuelBucketFor(trip))
        assertNull(db.getOverallAverage())
    }
}
