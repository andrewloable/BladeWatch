package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-fpdz.6: the fuel price per litre on [TripConfig].
 *
 * Deliberately mirrors the electricity rate in every respect, including that 0 means "not
 * configured" rather than "free". The currency is SHARED with the electric rate — one car,
 * one wallet — so there is no second currency field to get out of step.
 */
class TripConfigFuelPriceTest {

    private companion object { const val EPS = 1e-9 }

    @Test
    fun `defaults to zero meaning not configured`() {
        assertEquals(0.0, TripConfig().getFuelPricePerL(), EPS)
    }

    @Test
    fun `setter and getter round trip`() {
        val c = TripConfig()
        c.setFuelPricePerL(1.80)
        assertEquals(1.80, c.getFuelPricePerL(), EPS)
    }

    /**
     * A config written before this key existed must leave the price at 0 with no error, and
     * every other value untouched.
     */
    @Test
    fun `absent key stays zero without disturbing other values`() {
        val c = TripConfig()
        c.setElectricityRate(0.15)
        c.setCurrency("$")

        assertEquals("missing fuel price is 0, not a failure", 0.0, c.getFuelPricePerL(), EPS)
        assertEquals("electricity rate untouched", 0.15, c.getElectricityRate(), EPS)
        assertEquals("currency untouched", "$", c.getCurrency())
    }

    /** The API projection must carry it, or a client cannot show or edit the price. */
    @Test
    fun `json projection carries the fuel price`() {
        val c = TripConfig()
        c.setFuelPricePerL(1.80)
        c.setElectricityRate(0.15)
        c.setCurrency("$")

        val j = c.toJson()
        assertTrue("fuelPricePerL must be exposed", j.has("fuelPricePerL"))
        assertEquals(1.80, j.getDouble("fuelPricePerL"), EPS)
        assertEquals("the electric rate must still be there", 0.15, j.getDouble("electricityRate"), EPS)
        assertEquals("currency is shared, not duplicated", "$", j.getString("currency"))
        assertFalse("there must be no second fuel currency", j.has("fuelCurrency"))
    }

    // ── tank capacity ────────────────────────────────────────────────────────

    @Test
    fun `tank capacity defaults to zero meaning cannot predict range`() {
        assertEquals(0.0, TripConfig().getFuelTankCapacityL(), EPS)
    }

    @Test
    fun `tank capacity round trips and reaches the api projection`() {
        val c = TripConfig()
        c.setFuelTankCapacityL(50.0)
        assertEquals(50.0, c.getFuelTankCapacityL(), EPS)

        val j = c.toJson()
        assertTrue("the settings UI needs to read it back", j.has("fuelTankCapacityL"))
        assertEquals(50.0, j.getDouble("fuelTankCapacityL"), EPS)
    }

    /**
     * A negative capacity would produce a negative remaining-litres and therefore a negative
     * predicted range, so it is clamped to not-configured rather than stored.
     */
    @Test
    fun `negative tank capacity is rejected`() {
        val c = TripConfig()
        c.setFuelTankCapacityL(-50.0)
        assertEquals(0.0, c.getFuelTankCapacityL(), EPS)
    }

    /** A negative price is nonsense and must not be stored as one. */
    @Test
    fun `negative price is rejected`() {
        val c = TripConfig()
        c.setFuelPricePerL(-2.0)
        assertEquals("a negative price must fall back to not-configured",
            0.0, c.getFuelPricePerL(), EPS)
    }
}
