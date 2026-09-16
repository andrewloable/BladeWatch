package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-fpdz.7: the dual-leg trip cost.
 *
 * This is the change in the epic most able to do harm, because `tripCost` is the user's stored
 * cost history. The single most important test here is [a bev trip costs exactly what it always
 * did] — everything else is new behaviour, but that one pins old behaviour that must not move.
 *
 * `computeCosts` is deliberately given the ALREADY-RESOLVED energy rather than deriving its
 * own. Energy resolution moved to [TripAnalyticsManager.resolveTripEnergyKwh] and runs before
 * scoring, so the efficiency figure and the cost figure can never disagree about how much was
 * consumed. That resolution is tested in [TripEnergyResolutionTest]; this file tests pricing.
 *
 * Litres come from the lifetime COUNTER delta and never from tank percent: percent has no litre
 * scale without a tank capacity, and BYD local data does not expose one.
 */
class TripCostTest {

    private companion object {
        const val EPS = 1e-9
        const val UNAVAILABLE = -1.0
    }

    private fun trip(block: TripRecord.() -> Unit) = TripRecord().apply(block)

    /** The old single-leg formula, reproduced independently, to compare against. */
    private fun legacyCost(energyUsed: Double, rate: Double) =
        if (energyUsed > 0 && rate > 0) energyUsed * rate else 0.0

    // ── the regression that matters ──

    /**
     * A BEV has no fuel counters, so it must cost exactly what the single-leg implementation
     * charged. Checked across a spread of inputs rather than one, because a formula change can
     * agree at one point by luck.
     */
    @Test
    fun `a bev trip costs exactly what it always did`() {
        val cases = listOf(
            5.0 to 0.15,
            17.5 to 0.22,
            0.0 to 0.15,    // nothing resolved
            5.0 to 0.0,     // rate not configured
        )
        for ((energyUsed, rate) in cases) {
            val t = trip { distanceKm = 25.0 }
            TripAnalyticsManager.computeCosts(t, rate, "$", 0.0, energyUsed)

            assertEquals("tripCost moved for energy $energyUsed @ $rate",
                legacyCost(energyUsed, rate), t.tripCost, EPS)
            assertEquals("a BEV must have no fuel cost", 0.0, t.fuelCost, EPS)
            assertEquals("a BEV must burn no litres", 0.0, t.litresUsed, EPS)
        }
    }

    // ── the fuel leg ──

    @Test
    fun `a phev trip costs both legs and tripCost is their sum`() {
        val t = trip {
            distanceKm = 50.0
            fuelConStart = 1200.0
            fuelConEnd = 1203.5  // 3.5 L
        }
        TripAnalyticsManager.computeCosts(t, 0.15, "$", 1.80, 2.0)

        assertEquals("litres from the counter delta", 3.5, t.litresUsed, EPS)
        assertEquals("fuel leg", 6.30, t.fuelCost, EPS)
        assertEquals("electric leg", 0.30, t.electricCost, EPS)
        assertEquals("tripCost must be the sum of both legs", 6.60, t.tripCost, EPS)
    }

    /**
     * A PHEV leg driven entirely on electricity burned 0 litres. That is a real result and must
     * be stored as 0 — not skipped as if the reading were missing — while the electric leg is
     * still costed normally.
     */
    @Test
    fun `an electric only phev leg records zero litres and still costs the electric leg`() {
        val t = trip {
            distanceKm = 50.0
            fuelConStart = 1200.0
            fuelConEnd = 1200.0
        }
        TripAnalyticsManager.computeCosts(t, 0.15, "$", 1.80, 2.0)

        assertEquals("0 litres is a result, not a gap", 0.0, t.litresUsed, EPS)
        assertEquals(0.0, t.fuelCost, EPS)
        assertEquals("the electric leg still costs", 0.30, t.electricCost, EPS)
        assertEquals(0.30, t.tripCost, EPS)
    }

    /** The litres were burned whether or not the owner told us the price. */
    @Test
    fun `litres are recorded even when no fuel price is configured`() {
        val t = trip {
            distanceKm = 50.0
            fuelConStart = 1200.0
            fuelConEnd = 1203.5
        }
        TripAnalyticsManager.computeCosts(t, 0.15, "$", 0.0, 2.0)

        assertEquals("litres must still be recorded", 3.5, t.litresUsed, EPS)
        assertEquals("but they cannot be costed", 0.0, t.fuelCost, EPS)
    }

    /** A HAL reset or counter overflow must not produce negative litres. */
    @Test
    fun `a backwards counter yields zero litres never a negative`() {
        val t = trip {
            distanceKm = 50.0
            fuelConStart = 1203.0
            fuelConEnd = 1200.0
        }
        TripAnalyticsManager.computeCosts(t, 0.15, "$", 1.80, 2.0)

        assertEquals(0.0, t.litresUsed, EPS)
        assertEquals(0.0, t.fuelCost, EPS)
        assertTrue("cost must never go negative", t.tripCost >= 0)
    }

    /**
     * ONE end unavailable is not half a measurement — it is no measurement.
     *
     * This is reachable, not hypothetical: `TripDetector` probes the drivetrain separately at
     * each trip boundary and a probe can fail at one of them, leaving the sentinel on that side
     * only. Treating -1 as a number rather than as "absent" turns a 500 L lifetime reading into
     * 501 litres burned on a single trip, and prices it.
     *
     * Both orientations are covered because the guard has two halves and a mutation can break
     * either one alone.
     */
    @Test
    fun `one unavailable end produces no fuel leg`() {
        val missingStart = trip {
            distanceKm = 50.0
            fuelConStart = UNAVAILABLE
            fuelConEnd = 500.0
        }
        TripAnalyticsManager.computeCosts(missingStart, 0.15, "$", 1.80, 2.0)
        assertEquals("a lifetime reading is not a delta", 0.0, missingStart.litresUsed, EPS)
        assertEquals(0.0, missingStart.fuelCost, EPS)

        val missingEnd = trip {
            distanceKm = 50.0
            fuelConStart = 500.0
            fuelConEnd = UNAVAILABLE
        }
        TripAnalyticsManager.computeCosts(missingEnd, 0.15, "$", 1.80, 2.0)
        assertEquals(0.0, missingEnd.litresUsed, EPS)
        assertEquals(0.0, missingEnd.fuelCost, EPS)

        // And neither counts as having fuel data, so no UI shows a fuel row for them.
        assertTrue(!missingStart.hasFuelData() && !missingEnd.hasFuelData())
    }

    /** Unavailable counters mean no fuel leg at all, on any drivetrain. */
    @Test
    fun `unavailable fuel counters produce no fuel leg`() {
        val t = trip {
            distanceKm = 50.0
            fuelConStart = UNAVAILABLE
            fuelConEnd = UNAVAILABLE
        }
        TripAnalyticsManager.computeCosts(t, 0.15, "$", 1.80, 2.0)

        assertEquals(0.0, t.litresUsed, EPS)
        assertEquals(0.0, t.fuelCost, EPS)
        assertEquals(0.30, t.tripCost, EPS)
    }

    /** Half a pair is not a measurement. */
    @Test
    fun `a single fuel counter reading is not enough for a leg`() {
        val t = trip {
            distanceKm = 50.0
            fuelConStart = 1200.0
            fuelConEnd = UNAVAILABLE
        }
        TripAnalyticsManager.computeCosts(t, 0.15, "$", 1.80, 2.0)
        assertEquals(0.0, t.litresUsed, EPS)
    }

    // ── energyPerKm must stay electric-only, and must not be touched here ──

    /**
     * `energyPerKm` is kWh per km and is owned by the caller, set from the same resolved figure
     * passed in here. Costing must not touch it — least of all folding litres in, which would
     * silently change what every stored efficiency figure means.
     */
    @Test
    fun `costing never writes energyPerKm`() {
        val t = trip {
            distanceKm = 50.0
            energyPerKm = 0.04   // set by the caller from the resolved energy
            fuelConStart = 1200.0
            fuelConEnd = 1210.0  // a large fuel leg
        }
        TripAnalyticsManager.computeCosts(t, 0.15, "$", 1.80, 2.0)

        assertEquals("a large fuel leg must not move kWh/km", 0.04, t.energyPerKm, EPS)
    }

    // ── snapshotting ──

    /** The rates and currency are snapshotted onto the trip alongside the costs. */
    @Test
    fun `rates and currency are snapshotted onto the trip`() {
        val t = trip { distanceKm = 10.0 }
        TripAnalyticsManager.computeCosts(t, 0.15, "€", 1.80, 0.0)
        assertEquals(0.15, t.electricityRate, EPS)
        assertEquals(1.80, t.fuelPricePerL, EPS)
        assertEquals("€", t.currency)
    }

    /** Zero resolved energy costs nothing, however generous the rate. */
    @Test
    fun `zero resolved energy costs nothing`() {
        val t = trip { distanceKm = 50.0 }
        TripAnalyticsManager.computeCosts(t, 0.99, "$", 0.0, 0.0)
        assertEquals(0.0, t.electricCost, EPS)
        assertEquals(0.0, t.tripCost, EPS)
    }
}
