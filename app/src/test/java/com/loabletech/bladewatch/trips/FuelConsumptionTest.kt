package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-fpdz.9: fuel consumption learning and range prediction.
 *
 * Two properties carry the weight here. The first is that a zero-litre leg teaches nothing
 * (as opposed to teaching "0 L/km"), because that is the difference between a range estimate
 * that degrades gracefully on a plug-in hybrid and one that quietly inflates every time the
 * driver completes a commute on battery. The second is that with no tank capacity configured
 * the estimator declines to answer rather than guessing — a wrong range number on a dashboard
 * is worse than no number, because the driver acts on it.
 */
class FuelConsumptionTest {

    private companion object { const val EPS = 1e-9 }

    // ── learning ──

    @Test
    fun `a normal trip yields its litres per km`() {
        val rate = FuelConsumption.litresPerKm(3.5, 50.0)
        assertNotNull(rate)
        assertEquals(0.07, rate!!, EPS)
    }

    /**
     * THE poisoning case. A PHEV leg driven entirely on electricity burned 0 litres. That is a
     * correct, real trip — but its fuel rate is undefined, not 0 L/km. Learning 0 would drag
     * the bucket average down and inflate every later range prediction.
     */
    @Test
    fun `an electric only leg teaches nothing rather than teaching zero`() {
        assertNull("0 litres over a real distance must not become a 0 L/km sample",
            FuelConsumption.litresPerKm(0.0, 50.0))
    }

    @Test
    fun `a zero distance trip teaches nothing`() {
        assertNull(FuelConsumption.litresPerKm(3.5, 0.0))
        assertNull(FuelConsumption.litresPerKm(0.0, 0.0))
    }

    @Test
    fun `negative inputs teach nothing`() {
        assertNull(FuelConsumption.litresPerKm(-3.5, 50.0))
        assertNull(FuelConsumption.litresPerKm(3.5, -50.0))
    }

    /**
     * The sanity band is tested at BOTH boundaries, not just in the middle. An inclusive
     * bound written as exclusive silently discards legitimate samples, and the symptom — a
     * bucket that fills more slowly than it should — is invisible.
     */
    @Test
    fun `the sanity band is inclusive at both boundaries`() {
        // 0.02 L/km exactly: 1.0 L over 50 km.
        assertNotNull("the lower bound must be inclusive",
            FuelConsumption.litresPerKm(1.0, 50.0))
        // 0.20 L/km exactly: 10.0 L over 50 km.
        assertNotNull("the upper bound must be inclusive",
            FuelConsumption.litresPerKm(10.0, 50.0))
    }

    @Test
    fun `samples outside the sanity band are rejected`() {
        assertNull("0.01 L/km is implausibly frugal",
            FuelConsumption.litresPerKm(0.5, 50.0))
        assertNull("0.25 L/km is implausibly thirsty",
            FuelConsumption.litresPerKm(12.5, 50.0))
    }

    /** Fuel samples must never land in the kWh/km buckets. */
    @Test
    fun `fuel buckets are namespaced away from the electric ones`() {
        val electric = "60_20_75"
        val fuel = FuelConsumption.fuelBucketKey(electric)
        assertTrue("must be namespaced", fuel.startsWith(FuelConsumption.FUEL_PREFIX))
        assertTrue("must preserve the electric key so the two stay comparable",
            fuel.endsWith(electric))
        assertTrue("and must not collide with it", fuel != electric)
    }

    // ── prediction ──

    @Test
    fun `range is remaining litres divided by the learned rate`() {
        // A 50 L tank at 40% is 20 L; at 0.07 L/km that is 285.7 km.
        val km = FuelConsumption.predictRangeKm(50.0, 40.0, 0.07)
        assertEquals(20.0 / 0.07, km, 1e-6)
    }

    /**
     * No tank capacity means no prediction. This is the constraint the task set explicitly:
     * BYD local data does not expose a tank size and one must not be invented.
     */
    @Test
    fun `without a configured tank capacity it declines to predict`() {
        assertEquals("0 means not configured",
            FuelConsumption.CANNOT_PREDICT, FuelConsumption.predictRangeKm(0.0, 40.0, 0.07), EPS)
        assertEquals(FuelConsumption.CANNOT_PREDICT,
            FuelConsumption.predictRangeKm(-10.0, 40.0, 0.07), EPS)
    }

    @Test
    fun `an unusable fuel level declines to predict`() {
        for (pct in listOf(-1.0, 101.0, Double.NaN)) {
            assertEquals("fuelPercent=$pct must not produce a range",
                FuelConsumption.CANNOT_PREDICT,
                FuelConsumption.predictRangeKm(50.0, pct, 0.07), EPS)
        }
    }

    @Test
    fun `an out of band rate declines to predict`() {
        assertEquals(FuelConsumption.CANNOT_PREDICT,
            FuelConsumption.predictRangeKm(50.0, 40.0, 0.001), EPS)
        assertEquals(FuelConsumption.CANNOT_PREDICT,
            FuelConsumption.predictRangeKm(50.0, 40.0, 5.0), EPS)
    }

    /** An empty tank is a real reading and predicts zero range, not "unknown". */
    @Test
    fun `an empty tank predicts zero range rather than declining`() {
        assertEquals(0.0, FuelConsumption.predictRangeKm(50.0, 0.0, 0.07), EPS)
    }
}
