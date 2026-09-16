package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Trip energy resolution — the fix for "efficiency shows 0".
 *
 * **The bug.** `energyPerKm` is the number the UI shows as efficiency, and it had exactly two
 * writers: the detector at finalize time (only when a kWh delta already existed) and the SoC
 * fallback buried inside cost computation. Cost ran AFTER scoring, so on any trip where the
 * kWh channel could not answer — a short hop where integer-resolution SoC never moved, or a
 * car whose BMS goes flaky with ACC off — `energyPerKm` stayed 0 through scoring and was
 * stored as 0.
 *
 * It got worse downstream: `computeConsistency` receives that 0, measures its deviation from
 * the fleet average as a full 100%, and clamps the consistency score to 0 too. One flat-SoC
 * trip therefore reported zero efficiency AND zero consistency.
 *
 * The fix mirrors Overdrive: resolve energy ONCE, BEFORE scoring, and assign `energyPerKm`
 * from it unconditionally so every consumer sees the same figure on the same unit axis.
 */
class TripEnergyResolutionTest {

    private companion object {
        const val EPS = 1e-9
        const val NO_COUNTER = -1.0
        const val NOMINAL_KWH = 60.0
    }

    private fun trip(block: TripRecord.() -> Unit) = TripRecord().apply(block)

    private fun resolve(t: TripRecord, nominalKwh: Double = NOMINAL_KWH) =
        TripAnalyticsManager.resolveTripEnergyKwh(t, nominalKwh)

    // ── tier 1: metered ──────────────────────────────────────────────────────────

    /** The only tier with the resolution to measure a short trip. */
    @Test
    fun `the metered counter answers a short trip that soc cannot`() {
        val t = trip {
            distanceKm = 2.0
            socStart = 80.0
            socEnd = 80.0      // integer SoC never moved
            kwhStart = 40.0
            kwhEnd = 40.0      // remaining-energy delta is flat too
            elecConStart = 1000.0
            elecConEnd = 1000.35
        }
        assertEquals("the accumulator DID move", 0.35, resolve(t), 1e-6)
    }

    /**
     * A counter reset or a unit change between the two reads would otherwise be booked as a
     * huge, confidently-wrong measurement. The ceiling is generous — 100 kWh/100 km plus 1 kWh
     * of slack for very short trips — so it only rejects the physically impossible.
     */
    @Test
    fun `an implausible metered delta is discarded rather than trusted`() {
        val t = trip {
            distanceKm = 5.0
            socStart = 80.0
            socEnd = 70.0
            elecConStart = 1000.0
            elecConEnd = 1900.0   // 900 kWh over 5 km — a counter reset
        }
        val energy = resolve(t)
        assertTrue("900 kWh over 5 km must not be believed", energy < 100)
        assertEquals("falls through to the SoC estimate: 10% of 60 kWh",
            6.0, energy, 1e-6)
        assertEquals("and the poisoned snapshots are cleared so every tier agrees",
            NO_COUNTER, t.elecConStart, EPS)
    }

    @Test
    fun `a metered delta at the plausibility ceiling is still accepted`() {
        val t = trip {
            distanceKm = 5.0
            elecConStart = 1000.0
            elecConEnd = 1006.0   // exactly 1.0 + distanceKm
        }
        assertEquals(6.0, resolve(t), 1e-6)
    }

    // ── a measured zero is a measurement ─────────────────────────────────────────

    /**
     * When the meter reports a true zero AND the remaining-energy delta agrees, 0 is a
     * measurement, not a gap. Estimating from SoC there would manufacture consumption the
     * vehicle says never happened — the normal reading for a PHEV leg driven on the engine.
     */
    @Test
    fun `a true metered zero is not overridden by soc noise`() {
        val t = trip {
            distanceKm = 30.0
            socStart = 80.0
            socEnd = 79.0          // exactly one integer step — indistinguishable from noise
            elecConStart = 1000.0
            elecConEnd = 1000.0    // meter says nothing was drawn
        }
        assertEquals("a single SoC step must not invent 0.6 kWh of propulsion energy",
            0.0, resolve(t), EPS)
    }

    /**
     * But a counter stuck at a fixed value is not tracking on this trim, and if SoC really
     * fell then energy really was used. Only an unmistakable drop overrides the meter.
     */
    @Test
    fun `a clear soc drop overrides a stuck meter`() {
        val t = trip {
            distanceKm = 50.0
            socStart = 80.0
            socEnd = 70.0          // 10% — far above the noise floor
            elecConStart = 1000.0
            elecConEnd = 1000.0    // stuck
        }
        assertEquals("10% of a 60 kWh pack", 6.0, resolve(t), 1e-6)
    }

    // ── tier 3: SoC estimate ─────────────────────────────────────────────────────

    @Test
    fun `soc estimate is used when no counter exists at all`() {
        val t = trip {
            distanceKm = 50.0
            socStart = 80.0
            socEnd = 60.0
            elecConStart = NO_COUNTER
            elecConEnd = NO_COUNTER
        }
        assertEquals("20% of 60 kWh", 12.0, resolve(t), 1e-6)
    }

    @Test
    fun `no nominal capacity means no estimate rather than a guess`() {
        val t = trip {
            distanceKm = 50.0
            socStart = 80.0
            socEnd = 60.0
        }
        assertEquals(0.0, resolve(t, nominalKwh = 0.0), EPS)
    }

    @Test
    fun `a rising soc with no counter yields zero not a negative`() {
        val t = trip {
            distanceKm = 50.0
            socStart = 60.0
            socEnd = 80.0
        }
        assertEquals(0.0, resolve(t), EPS)
    }

    // ── the reported bug ─────────────────────────────────────────────────────────

    /**
     * THE regression. Reproduces the user-visible report: a trip whose efficiency showed 0.
     *
     * Before the fix, this trip reached scoring with `energyPerKm` still 0 because the only
     * SoC fallback lived in cost computation, which ran afterwards.
     */
    @Test
    fun `a trip with a real soc drop resolves a non-zero efficiency`() {
        val t = trip {
            distanceKm = 40.0
            socStart = 75.0
            socEnd = 60.0     // 15% of 60 kWh = 9 kWh
            kwhStart = 0.0    // BMS kWh channel silent — common with ACC off
            kwhEnd = 0.0
            elecConStart = NO_COUNTER
            elecConEnd = NO_COUNTER
        }
        val energy = resolve(t)
        assertEquals(9.0, energy, 1e-6)

        val energyPerKm = energy / t.distanceKm
        assertTrue("efficiency must not be 0 for a trip that clearly used energy",
            energyPerKm > 0)
        assertEquals(0.225, energyPerKm, 1e-6)
    }

    /** Nothing usable anywhere is still an honest 0 rather than an invention. */
    @Test
    fun `a trip with no usable signal resolves to zero`() {
        val t = trip { distanceKm = 10.0 }
        assertEquals(0.0, resolve(t), EPS)
    }
}
