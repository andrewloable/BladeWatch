package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-fpdz.2: the fuel and metered-energy fields on [TripRecord].
 *
 * These fields are pure data, so the only things worth pinning are the two conventions a later
 * reader can silently get wrong, and the additive-ness of the change:
 *
 *  - **-1 means unavailable; 0 is a real measurement.** A PHEV leg driven entirely on the
 *    engine genuinely consumed 0 kWh from the pack, and a PHEV leg driven entirely on
 *    electricity genuinely burned 0 litres. Collapsing those into "no data" is what makes a
 *    cost silently wrong rather than visibly missing.
 *  - **The summary carries derived values only.** Raw lifetime counters are meaningless to a
 *    list view and would be a standing invitation to compute a delta client-side.
 */
class TripRecordTest {

    private companion object {
        const val EPS = 1e-9
        const val UNAVAILABLE = -1.0
    }

    /** Every field a trip did not observe must start at the unavailable sentinel, not 0. */
    @Test
    fun `counters default to unavailable not zero`() {
        val t = TripRecord()
        assertEquals("fuelPctStart", UNAVAILABLE, t.fuelPctStart, EPS)
        assertEquals("fuelPctEnd", UNAVAILABLE, t.fuelPctEnd, EPS)
        assertEquals("fuelConStart", UNAVAILABLE, t.fuelConStart, EPS)
        assertEquals("fuelConEnd", UNAVAILABLE, t.fuelConEnd, EPS)
        assertEquals("elecConStart", UNAVAILABLE, t.elecConStart, EPS)
        assertEquals("elecConEnd", UNAVAILABLE, t.elecConEnd, EPS)
    }

    /** Computed values start at 0 — they are sums, not observations. */
    @Test
    fun `computed fields default to zero`() {
        val t = TripRecord()
        assertEquals("litresUsed", 0.0, t.litresUsed, EPS)
        assertEquals("fuelPricePerL", 0.0, t.fuelPricePerL, EPS)
        assertEquals("fuelCost", 0.0, t.fuelCost, EPS)
        assertEquals("electricCost", 0.0, t.electricCost, EPS)
    }

    private fun populated() = TripRecord().apply {
        fuelPctStart = 80.0
        fuelPctEnd = 74.5
        fuelConStart = 1200.25
        fuelConEnd = 1203.75
        litresUsed = 3.5
        fuelPricePerL = 1.80
        fuelCost = 6.30
        electricCost = 2.10
        elecConStart = 5000.0
        elecConEnd = 5008.4
    }

    @Test
    fun `full json carries every new field`() {
        val j = populated().toJson()
        assertEquals(80.0, j.getDouble("fuelPctStart"), EPS)
        assertEquals(74.5, j.getDouble("fuelPctEnd"), EPS)
        assertEquals(1200.25, j.getDouble("fuelConStart"), EPS)
        assertEquals(1203.75, j.getDouble("fuelConEnd"), EPS)
        assertEquals(3.5, j.getDouble("litresUsed"), EPS)
        assertEquals(1.80, j.getDouble("fuelPricePerL"), EPS)
        assertEquals(6.30, j.getDouble("fuelCost"), EPS)
        assertEquals(2.10, j.getDouble("electricCost"), EPS)
        assertEquals(5000.0, j.getDouble("elecConStart"), EPS)
        assertEquals(5008.4, j.getDouble("elecConEnd"), EPS)
    }

    /**
     * The summary feeds a list view: derived values only. Raw counters in a list response
     * invite a client to compute its own delta, which would then disagree with the daemon's
     * the moment a counter resets.
     */
    @Test
    fun `summary carries derived values but not raw counters`() {
        val j = populated().toSummaryJson()
        assertTrue("litresUsed belongs in the summary", j.has("litresUsed"))
        assertTrue("fuelCost belongs in the summary", j.has("fuelCost"))
        assertTrue("electricCost belongs in the summary", j.has("electricCost"))

        assertFalse("raw fuel counter must not reach a list view", j.has("fuelConStart"))
        assertFalse("raw fuel counter must not reach a list view", j.has("fuelConEnd"))
        assertFalse("raw elec counter must not reach a list view", j.has("elecConStart"))
        assertFalse("raw elec counter must not reach a list view", j.has("elecConEnd"))
        assertFalse("tank percent is not a list-view concern", j.has("fuelPctStart"))
    }

    /**
     * The whole change is additive. A record that never saw a fuel reading must serialise its
     * pre-existing keys exactly as before, or a shipped client breaks on an unrelated field.
     */
    @Test
    fun `existing keys are unchanged for a bev trip`() {
        val t = TripRecord().apply {
            id = 7
            distanceKm = 12.5
            kwhStart = 40.0
            kwhEnd = 37.5
            energyPerKm = 0.2
            electricityRate = 0.15
            currency = "$"
            tripCost = 0.375
        }

        val j = t.toJson()
        assertEquals(7L, j.getLong("id"))
        assertEquals(12.5, j.getDouble("distanceKm"), EPS)
        assertEquals(40.0, j.getDouble("kwhStart"), EPS)
        assertEquals(37.5, j.getDouble("kwhEnd"), EPS)
        assertEquals("energyUsedKwh must still be the tier-1 delta",
            2.5, j.getDouble("energyUsedKwh"), EPS)
        assertEquals(0.2, j.getDouble("energyPerKm"), EPS)
        assertEquals(0.15, j.getDouble("electricityRate"), EPS)
        assertEquals("$", j.getString("currency"))
        assertEquals(0.375, j.getDouble("tripCost"), EPS)
    }

    /**
     * Both projections must stay in step. The Java original carried two near-identical 30-line
     * blocks and a field added to one but not the other would drift silently; the Kotlin
     * version shares one [TripRecord.toSummaryJson] core, and this pins that they agree on
     * everything the summary is supposed to carry.
     */
    @Test
    fun `summary keys are a strict subset of the full projection`() {
        val full = populated().toJson().keys().asSequence().toSet()
        val summary = populated().toSummaryJson().keys().asSequence().toSet()
        val orphans = summary - full
        assertTrue("summary exposes keys the full projection does not: $orphans", orphans.isEmpty())
        assertTrue("the full projection must be strictly richer", full.size > summary.size)
    }
}
