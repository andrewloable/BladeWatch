package net.bladewatch.app.trips

import java.util.UUID
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

/**
 * `TripDatabase.getOverallAverage` must average the ELECTRIC buckets only.
 *
 * `FuelConsumption` stores litres/km in the same `consumption_buckets` table as the electric
 * kWh/km samples, namespaced by a `fuel_` key prefix so no schema change was needed. That
 * sharing is only safe while every aggregate query excludes the fuel namespace.
 *
 * The danger is that the two bands OVERLAP numerically — roughly 0.02-0.20 L/km against
 * 0.10-0.30 kWh/km — so a contaminated average still looks like a believable consumption
 * figure. Nothing would look broken; the electric range prediction would just quietly be
 * wrong, and only on PHEVs, which is the hardest possible case to notice.
 *
 * Runs the real H2 schema and the real SQL rather than asserting on query strings, because the
 * bug being guarded against is a missing WHERE clause, which executes perfectly.
 */
class ConsumptionBucketNamespaceTest {

    private lateinit var db: TripDatabase

    @Before
    fun setUp() {
        val url = "jdbc:h2:mem:buckets_${UUID.randomUUID().toString().replace("-", "")};" +
            "DB_CLOSE_DELAY=-1"
        db = TripDatabase()
        db.setJdbcUrlForTest(url)
        db.init()
    }

    @After
    fun tearDown() {
        try { db.close() } catch (ignored: Exception) { }
    }

    private companion object {
        /**
         * `consumption_buckets` stores its sums as H2 `REAL` (32-bit), so 0.2 comes back as
         * 0.20000000298. That is pre-existing and not what these tests are about — asserting
         * at 1e-9 would be asserting something that was never true. Same rationale as
         * `TripDatabaseFuelColumnsTest.EPS_FLOAT32`.
         */
        const val EPS_FLOAT32 = 1e-6
    }

    /** A realistic electric key: speed band, temperature band, driving style. */
    private val electricKey = "60_20_smooth"

    @Test
    fun `the overall average ignores fuel buckets entirely`() {
        // Two electric samples at 0.20 kWh/km.
        db.updateConsumptionBucket(electricKey, 0.20)
        db.updateConsumptionBucket(electricKey, 0.20)
        // A fuel sample at 0.06 L/km, which would drag the mean down if it were counted.
        db.updateConsumptionBucket(FuelConsumption.fuelBucketKey(electricKey), 0.06)

        val overall = db.getOverallAverage()
        assertNotNull("electric buckets exist, so there must be an average", overall)
        assertEquals(
            "sample count must exclude the fuel row",
            2,
            overall!!.sampleCount,
        )
        assertEquals(
            "a fuel sample must not be averaged into kWh/km",
            0.20,
            overall.getMean(),
            EPS_FLOAT32,
        )
    }

    /**
     * The other half, and the one that breaks `RangeEstimator.backfillBucketsIfNeeded`: with
     * ONLY fuel buckets present there is no electric average at all. If this returned a
     * non-null bucket, the backfill would conclude the electric buckets were already populated
     * and skip rebuilding them from trip history.
     */
    @Test
    fun `fuel buckets alone do not constitute an electric average`() {
        db.updateConsumptionBucket(FuelConsumption.fuelBucketKey(electricKey), 0.06)
        db.updateConsumptionBucket(FuelConsumption.fuelBucketKey("90_5_aggressive"), 0.09)

        assertNull(
            "only fuel samples exist, so there is no electric average to report",
            db.getOverallAverage(),
        )
    }

    /**
     * The prefix contains `_`, which is a single-character wildcard in SQL LIKE. If the
     * pattern were not escaped, this key — `fuel` plus one character — would be excluded too,
     * silently dropping a legitimate electric bucket.
     *
     * Contrived as a key, deliberately: the point is that the exclusion is anchored to the
     * literal prefix rather than to a pattern that happens to work for today's key format.
     */
    @Test
    fun `the underscore in the prefix is matched literally, not as a wildcard`() {
        db.updateConsumptionBucket("fuelX_20_smooth", 0.30)

        val overall = db.getOverallAverage()
        assertNotNull("a key merely starting with 'fuel' is still electric", overall)
        assertEquals(1, overall!!.sampleCount)
        assertEquals(0.30, overall.getMean(), EPS_FLOAT32)
    }

    /**
     * `clearConsumptionBuckets` purges ELECTRIC buckets only.
     *
     * Its single caller is the one-time PHEV migration in `CameraDaemon`, which fires when the
     * pack turns out to be PHEV-sized and throws away kWh/km rates computed against a wrong,
     * BEV-sized capacity. A fuel rate is `litresUsed / distanceKm` and contains no capacity
     * term, so it cannot be poisoned that way.
     *
     * Wiping it would destroy the fuel learning of the very vehicle the migration just
     * identified as a PHEV — and would do so silently, since the only symptom is a fuel range
     * that has gone blank and slowly comes back over the following weeks.
     */
    @Test
    fun `clearing buckets on a capacity change spares the fuel namespace`() {
        db.updateConsumptionBucket(electricKey, 0.20)
        db.updateConsumptionBucket("90_5_aggressive", 0.26)
        db.updateConsumptionBucket(FuelConsumption.fuelBucketKey(electricKey), 0.06)

        db.clearConsumptionBuckets()

        assertNull("electric rates were computed against the wrong capacity", db.getOverallAverage())
        assertNull(db.getBucket(electricKey))
        val fuel = db.getBucket(FuelConsumption.fuelBucketKey(electricKey))
        assertNotNull("litres/km has no capacity term and must survive", fuel)
        assertEquals(0.06, fuel!!.getMean(), EPS_FLOAT32)
    }

    /** Both kinds present, keyed lookups must still reach each namespace independently. */
    @Test
    fun `keyed lookups still reach both namespaces`() {
        db.updateConsumptionBucket(electricKey, 0.22)
        db.updateConsumptionBucket(FuelConsumption.fuelBucketKey(electricKey), 0.07)

        assertEquals(0.22, db.getBucket(electricKey)!!.getMean(), EPS_FLOAT32)
        assertEquals(
            0.07,
            db.getBucket(FuelConsumption.fuelBucketKey(electricKey))!!.getMean(),
            EPS_FLOAT32,
        )
    }
}
