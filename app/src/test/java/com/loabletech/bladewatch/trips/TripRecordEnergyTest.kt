package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-fpdz.5: the two-tier energy cascade on [TripRecord].
 *
 * The single-tier version this replaces returned 0 for any trip that did not move the
 * remaining-energy reading. Remaining energy is derived from a 1%-resolution SoC — roughly
 * 0.6 kWh, several km of driving — so every short trip was recorded as having consumed
 * nothing and cost nothing, while the lifetime electricity counter had advanced the whole
 * time. That is a BEV bug as much as a PHEV one.
 *
 * The tier ORDER is the design, not an implementation detail, so it is pinned here directly.
 * Tier 1 is the net remaining-energy delta and wins whenever it can answer, because it is net
 * of regeneration — the quantity a cost must be based on, since you only buy back the energy
 * the pack actually ended up short. The metered counter is gross draw, so preferring it would
 * inflate a regen-heavy trip and put stored history on two different axes depending on which
 * channels a trim happens to expose.
 */
class TripRecordEnergyTest {

    private companion object {
        const val EPS = 1e-9
        const val NO_COUNTER = -1.0
    }

    private fun trip(kwhStart: Double, kwhEnd: Double, elecStart: Double, elecEnd: Double) =
        TripRecord().apply {
            this.kwhStart = kwhStart
            this.kwhEnd = kwhEnd
            this.elecConStart = elecStart
            this.elecConEnd = elecEnd
        }

    // ── tier 1 ──

    @Test
    fun `tier 1 answers from the remaining energy delta`() {
        assertEquals(5.0, trip(40.0, 35.0, NO_COUNTER, NO_COUNTER).getEnergyUsedKwh(), EPS)
    }

    /**
     * THE regen property. Both tiers can answer; tier 1 must win. The metered counter says 8
     * kWh of gross draw, but the pack only ended 5 kWh short because regeneration put 3 back
     * — and 5 is what the trip cost.
     */
    @Test
    fun `tier 1 is preferred even when tier 2 could also answer`() {
        assertEquals("gross draw must not override the net delta",
            5.0, trip(40.0, 35.0, 100.0, 108.0).getEnergyUsedKwh(), EPS)
    }

    // ── tier 2: the short-trip bug ──

    /**
     * The bug this task exists for. Equal remaining-energy readings do not mean "consumed
     * nothing" — they mean "below this channel's resolution". The accumulator still moved.
     */
    @Test
    fun `equal remaining energy falls through to the metered counter`() {
        assertEquals("a short trip must report the metered figure, not 0",
            0.4, trip(40.0, 40.0, 100.0, 100.4).getEnergyUsedKwh(), EPS)
    }

    @Test
    fun `metered tier answers when there is no remaining energy channel`() {
        assertEquals(2.5, trip(0.0, 0.0, 100.0, 102.5).getEnergyUsedKwh(), EPS)
    }

    // ── sign discipline ──

    /**
     * A pack that ended fuller than it started regenerated more than it drew. Report 0, never
     * a negative: billing energy that was put back would charge for a trip that cost nothing,
     * and it would leave this trip's cost and its efficiency score on opposite signs.
     */
    @Test
    fun `a fuller pack consumes nothing rather than a negative`() {
        assertEquals(0.0, trip(35.0, 40.0, NO_COUNTER, NO_COUNTER).getEnergyUsedKwh(), EPS)
        // And it must stay 0 even when the gross counter has a number to offer. This is the
        // whole point of the guard: the pack ended FULLER, so on balance nothing was consumed,
        // however much was drawn and pushed back along the way. Asserting merely ">= 0" here
        // let the guard be deleted without a single test failing (measured).
        assertEquals("a fuller pack must not fall through to gross draw",
            0.0, trip(35.0, 40.0, 100.0, 108.0).getEnergyUsedKwh(), EPS)
    }

    @Test
    fun `never negative across awkward inputs`() {
        val cases = listOf(
            doubleArrayOf(35.0, 40.0, 108.0, 100.0),
            doubleArrayOf(0.0, 0.0, 108.0, 100.0),
            doubleArrayOf(-1.0, -1.0, -1.0, -1.0),
            doubleArrayOf(40.0, 40.0, 100.0, 99.0),
        )
        for (c in cases) {
            val v = trip(c[0], c[1], c[2], c[3]).getEnergyUsedKwh()
            assertTrue("negative energy from ${c.toList()}", v >= 0)
        }
    }

    // ── a true zero is not missing data ──

    /**
     * A PHEV leg driven entirely on the engine genuinely drew 0 kWh. That is a measurement,
     * and it must be distinguishable from having no counter at all — otherwise a caller falls
     * through to a coarser tier and invents consumption that did not happen.
     */
    @Test
    fun `a true metered zero is a measurement not missing data`() {
        val t = trip(40.0, 40.0, 100.0, 100.0)
        assertEquals(0.0, t.getEnergyUsedKwh(), EPS)
        assertTrue("the counter was read; 0 is its answer", t.hasMeteredEnergy())
        assertEquals(0.0, t.getMeteredEnergyKwh(), EPS)
    }

    @Test
    fun `absent counters are not a measurement`() {
        assertFalse(trip(40.0, 35.0, NO_COUNTER, NO_COUNTER).hasMeteredEnergy())
        assertFalse("half a pair is not a measurement",
            trip(40.0, 35.0, 100.0, NO_COUNTER).hasMeteredEnergy())
        assertFalse("a counter that went backwards is not usable",
            trip(40.0, 35.0, 108.0, 100.0).hasMeteredEnergy())
    }

    // ── regression against the implementation this replaces ──

    /**
     * Cost history is computed from this method. Any trip with no metered counter — every trip
     * ever recorded before this change — must produce exactly what the one-tier version
     * produced, or the change silently rewrites what the user was charged.
     */
    @Test
    fun `legacy trips are unaffected`() {
        val cases = listOf(
            40.0 to 35.0, 40.0 to 40.0, 35.0 to 40.0,
            0.0 to 0.0, 40.0 to 0.0, 0.0 to 35.0,
        )
        for ((start, end) in cases) {
            val legacy = if (start > 0 && end > 0 && start > end) start - end else 0.0
            assertEquals("legacy behaviour changed for kwh $start->$end",
                legacy, trip(start, end, NO_COUNTER, NO_COUNTER).getEnergyUsedKwh(), EPS)
        }
    }

    // ── rollup accessor ──

    @Test
    fun `resolved energy falls back to the stored rate`() {
        val t = trip(0.0, 0.0, NO_COUNTER, NO_COUNTER).apply {
            energyPerKm = 0.18
            distanceKm = 50.0
        }
        assertEquals("rollups must stay consistent with the per-trip figure",
            9.0, t.getResolvedEnergyKwh(), EPS)
    }

    @Test
    fun `resolved energy prefers the measurement and is never negative`() {
        val measured = trip(40.0, 35.0, NO_COUNTER, NO_COUNTER).apply {
            energyPerKm = 0.18
            distanceKm = 50.0
        }
        assertEquals("a real measurement wins over the estimate",
            5.0, measured.getResolvedEnergyKwh(), EPS)

        val negative = trip(0.0, 0.0, NO_COUNTER, NO_COUNTER).apply {
            energyPerKm = -0.5
            distanceKm = 10.0
        }
        assertTrue(negative.getResolvedEnergyKwh() >= 0)
    }
}
