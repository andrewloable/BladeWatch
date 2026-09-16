package net.bladewatch.app.trips

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * `TripApiHandler.shouldEnrichEnergy` — the read-path back-fill gate.
 *
 * The enrichment exists so trips recorded before the energy meter was captured still show a
 * cost instead of a blank. The risk is the opposite case: enriching a trip whose meter DID
 * report, where a zero is a real measurement rather than a missing value.
 *
 * That matters because the write path already decided. `resolveTripEnergyKwh` refuses to
 * estimate over a metered zero unless SoC fell by more than one quantisation step, so a read
 * path without the same rule would hand the UI a different answer than the one stored — the
 * detail view contradicting the list view for the same trip.
 */
class EnrichTripEnergyTest {

    /** A trip with no meter readings at all — the historical shape this feature is for. */
    private fun legacyTrip(socStart: Double, socEnd: Double) = TripRecord().apply {
        this.socStart = socStart
        this.socEnd = socEnd
        distanceKm = 10.0
        elecConStart = -1.0
        elecConEnd = -1.0
    }

    /** A trip that DID record both meter readings, with the given kWh delta. */
    private fun meteredTrip(socStart: Double, socEnd: Double, kwh: Double) = TripRecord().apply {
        this.socStart = socStart
        this.socEnd = socEnd
        distanceKm = 10.0
        elecConStart = 1000.0
        elecConEnd = 1000.0 + kwh
    }

    @Test
    fun `a legacy trip with a SoC drop is enriched`() {
        assertTrue(TripApiHandler.shouldEnrichEnergy(legacyTrip(80.0, 70.0)))
    }

    @Test
    fun `a trip that already has energy is left alone`() {
        val t = legacyTrip(80.0, 70.0)
        t.kwhStart = 50.0
        t.kwhEnd = 45.0
        assertFalse("5 kWh already measured", TripApiHandler.shouldEnrichEnergy(t))
    }

    @Test
    fun `no usable SoC delta means nothing to estimate from`() {
        assertFalse("SoC rose", TripApiHandler.shouldEnrichEnergy(legacyTrip(70.0, 80.0)))
        assertFalse("SoC flat", TripApiHandler.shouldEnrichEnergy(legacyTrip(70.0, 70.0)))
        assertFalse("no start reading", TripApiHandler.shouldEnrichEnergy(legacyTrip(0.0, 70.0)))
        assertFalse("no end reading", TripApiHandler.shouldEnrichEnergy(legacyTrip(80.0, 0.0)))
    }

    /**
     * THE regression this gate exists for: a PHEV leg driven entirely on the engine. The meter
     * correctly reports zero kWh drawn, while SoC ticks down a single step from parasitic and
     * HVAC draw. Estimating here would invent roughly half a kWh of propulsion energy — and a
     * cost for it — that the vehicle says was never drawn.
     */
    @Test
    fun `a metered zero is not overridden by one step of SoC noise`() {
        assertFalse(
            "1% is one quantisation step, not evidence",
            TripApiHandler.shouldEnrichEnergy(meteredTrip(80.0, 79.0, 0.0)),
        )
        assertFalse(
            "below one step is certainly noise",
            TripApiHandler.shouldEnrichEnergy(meteredTrip(80.0, 79.5, 0.0)),
        )
    }

    /**
     * The margin applies ONLY when there is a meter reading to protect. A legacy trip has no
     * meter at all, so a small SoC drop is not "noise contradicting a measurement" — it is the
     * only evidence that exists, and refusing it would leave the trip blank forever.
     *
     * This is what makes the `hasMeteredEnergy()` half of the guard load-bearing: without it
     * the margin would silently swallow every short legacy trip too.
     */
    @Test
    fun `a legacy trip is enriched even from a sub-margin SoC drop`() {
        assertTrue(
            "no meter means SoC is the only evidence there is",
            TripApiHandler.shouldEnrichEnergy(legacyTrip(80.0, 79.5)),
        )
        assertTrue(TripApiHandler.shouldEnrichEnergy(legacyTrip(80.0, 79.0)))
    }

    /**
     * The counterpart: a genuinely stuck meter over a real drive must still be corrected, or a
     * dead counter would permanently zero every trip.
     */
    @Test
    fun `a metered zero IS overridden by an unmistakable SoC drop`() {
        assertTrue(
            "a 10% drop cannot be quantisation noise",
            TripApiHandler.shouldEnrichEnergy(meteredTrip(80.0, 70.0, 0.0)),
        )
    }

    /** Exactly at the margin is still noise — the rule is strictly greater than. */
    @Test
    fun `the override margin is exclusive`() {
        val atMargin = 80.0 - TripAnalyticsManager.SOC_OVERRIDE_MIN_DROP_PCT
        assertFalse(TripApiHandler.shouldEnrichEnergy(meteredTrip(80.0, atMargin, 0.0)))
        assertTrue(TripApiHandler.shouldEnrichEnergy(meteredTrip(80.0, atMargin - 0.01, 0.0)))
    }
}
