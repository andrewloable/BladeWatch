package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Non-finite numbers must never reach stored state or the wire.
 *
 * JSON cannot represent Infinity or NaN, and org.json enforces that: `JSONObject.put` throws
 * "JSON does not allow non-finite numbers". Because `TripRecord.toJson` and `TripConfig.toJson`
 * both catch, the symptom is not a clean error — it is a PARTIAL object missing every key after
 * the failure point, which clients render as missing data rather than as a fault.
 *
 * Infinity is the dangerous one precisely because it passes the obvious guards: `Infinity > 0`
 * is true and `Infinity < 0` is false, so a positivity check or a bare NaN check both admit it.
 *
 * It is reachable without touching the UI. `1e400` is a legal JSON number literal and
 * `JSONObject.optDouble` parses it to Infinity, so one config POST would persist it — and the
 * config is saved to disk, so it survives a restart.
 */
class NonFiniteInputTest {

    private companion object { const val EPS = 1e-9 }

    // ── config setters ──

    @Test
    fun `config setters reject infinity as not-configured`() {
        val c = TripConfig()
        c.setFuelPricePerL(Double.POSITIVE_INFINITY)
        c.setFuelTankCapacityL(Double.POSITIVE_INFINITY)
        c.setElectricityRate(Double.POSITIVE_INFINITY)

        assertEquals(0.0, c.getFuelPricePerL(), EPS)
        assertEquals(0.0, c.getFuelTankCapacityL(), EPS)
        assertEquals(0.0, c.getElectricityRate(), EPS)
    }

    @Test
    fun `config setters reject NaN and negatives`() {
        val c = TripConfig()
        for (bad in listOf(Double.NaN, Double.NEGATIVE_INFINITY, -1.0)) {
            c.setFuelPricePerL(bad)
            c.setFuelTankCapacityL(bad)
            c.setElectricityRate(bad)
            assertEquals("fuel price rejected $bad", 0.0, c.getFuelPricePerL(), EPS)
            assertEquals("tank rejected $bad", 0.0, c.getFuelTankCapacityL(), EPS)
            assertEquals("rate rejected $bad", 0.0, c.getElectricityRate(), EPS)
        }
    }

    @Test
    fun `ordinary values still round-trip`() {
        val c = TripConfig()
        c.setFuelPricePerL(1.85)
        c.setFuelTankCapacityL(47.5)
        c.setElectricityRate(0.15)
        assertEquals(1.85, c.getFuelPricePerL(), EPS)
        assertEquals(47.5, c.getFuelTankCapacityL(), EPS)
        assertEquals(0.15, c.getElectricityRate(), EPS)
    }

    /** The end of the chain: whatever was stored, the config must still serialise. */
    @Test
    fun `a config that survived a hostile write still serialises`() {
        val c = TripConfig()
        c.setFuelPricePerL(Double.POSITIVE_INFINITY)
        c.setElectricityRate(Double.POSITIVE_INFINITY)

        val j = c.toJson()
        assertTrue("every key must be present, not truncated at the first bad value",
            j.has("fuelPricePerL") && j.has("electricityRate") &&
                j.has("currency") && j.has("distanceUnit"))
    }

    // ── HAL readings ──

    /**
     * `TripDetector.sanitizeReading` guards the HAL boundary. An Infinity counter would become
     * an Infinity DELTA and then an Infinity cost, so it must read as unavailable.
     */
    @Test
    fun `an infinite HAL reading is recorded as unavailable`() {
        val t = TripRecord()
        TripDetector.captureStart(t, true, Double.POSITIVE_INFINITY, Double.POSITIVE_INFINITY,
            Double.POSITIVE_INFINITY)
        TripDetector.captureEnd(t, true, Double.NaN, Double.NEGATIVE_INFINITY, Double.NaN)

        for (v in listOf(t.fuelPctStart, t.fuelConStart, t.elecConStart,
                t.fuelPctEnd, t.fuelConEnd, t.elecConEnd)) {
            assertEquals(-1.0, v, EPS)
        }
        assertTrue("no usable counter pair, so no fuel leg", !t.hasFuelData())
    }

    // ── derived figures ──

    @Test
    fun `an infinite tank capacity cannot predict a range`() {
        assertEquals(FuelConsumption.CANNOT_PREDICT,
            FuelConsumption.predictRangeKm(Double.POSITIVE_INFINITY, 50.0, 0.06), EPS)
    }

    @Test
    fun `non-finite trip inputs teach no fuel rate`() {
        assertEquals(null, FuelConsumption.litresPerKm(Double.POSITIVE_INFINITY, 100.0))
        assertEquals(null, FuelConsumption.litresPerKm(6.0, Double.POSITIVE_INFINITY))
        assertEquals(null, FuelConsumption.litresPerKm(Double.NaN, 100.0))
    }

    /** The whole point: a trip built from sanitised inputs always serialises in full. */
    @Test
    fun `a trip from sanitised inputs serialises completely`() {
        val t = TripRecord().apply { distanceKm = 50.0 }
        TripDetector.captureStart(t, true, Double.POSITIVE_INFINITY, Double.POSITIVE_INFINITY, 1000.0)
        TripDetector.captureEnd(t, true, Double.POSITIVE_INFINITY, Double.POSITIVE_INFINITY, 1008.0)
        TripAnalyticsManager.computeCosts(t, 0.15, "USD", Double.POSITIVE_INFINITY, 8.0)

        val j = t.toJson()
        // fuelPricePerL is written LATE in toJson, after putCommon. Listing only the early
        // keys would pass while serialisation was truncating at the first bad value — which is
        // precisely the failure mode being guarded against.
        for (k in listOf("litresUsed", "fuelCost", "electricCost", "tripCost", "hasFuelData",
                "currency", "distanceKm", "fuelPricePerL", "elecConStart", "elecConEnd")) {
            assertTrue("toJson truncated before $k", j.has(k))
        }
        assertTrue("cost must be finite", j.getDouble("tripCost").isFinite())
    }
}
