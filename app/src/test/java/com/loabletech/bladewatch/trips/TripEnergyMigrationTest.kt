package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-aa3i: repair trips stored while nominal pack capacity resolved to ~100 kWh.
 *
 * Every row below is VERBATIM from the head unit's own trip database (10 trips, pulled
 * 2026-09-19). They are not invented: the whole point is that the stored `kwhStart`/`kwhEnd`
 * mirror `socStart`/`socEnd` 1:1, which is what makes the damage detectable and the repair
 * idempotent.
 *
 * The correction is cross-validated against a channel the bug never touched. Trip 193 drove
 * 8.88 km for a 6-point SoC drop, and its lifetime electricity counter moved 80.2 -> 81.3 kWh,
 * a GROSS draw of 1.1 kWh. Recomputing the net delta as 6% of 18.3 kWh gives 1.098 kWh — 0.2%
 * apart. That agreement is the evidence that 18.3 is the right capacity and that this repair
 * produces real numbers rather than merely smaller ones.
 */
class TripEnergyMigrationTest {

    // ── detection ────────────────────────────────────────────────────────

    @Test
    fun `the real damaged rows are detected`() {
        // id, socStart, socEnd, kwhStart, kwhEnd — verbatim from TRIPS.
        val damaged = listOf(
            Triple(54.0, 53.7, 47.0) to 46.6,
            Triple(77.0, 77.0, 71.0) to 71.3,
            Triple(85.0, 84.8, 79.0) to 78.8,
        )
        for ((head, kwhEnd) in damaged) {
            val (socStart, kwhStart, socEnd) = head
            assertTrue(
                "soc $socStart/$socEnd with kwh $kwhStart/$kwhEnd is the mirrored channel",
                TripEnergyMigration.needsCorrection(socStart, socEnd, kwhStart, kwhEnd)
            )
        }
    }

    @Test
    fun `an already-repaired row is not touched again`() {
        // After repair, trip 193 holds 77% x 18.3 = 14.09 and 71% x 18.3 = 12.99. Nothing like
        // 77 and 71, so the repair is idempotent by DATA rather than by a marker file — it
        // survives a database restore, which a marker does not.
        assertFalse(TripEnergyMigration.needsCorrection(77.0, 71.0, 14.09, 12.99))
    }

    @Test
    fun `a trip with no stored energy at all is left alone`() {
        assertFalse(TripEnergyMigration.needsCorrection(77.0, 71.0, 0.0, 0.0))
    }

    // ── repair ───────────────────────────────────────────────────────────

    @Test
    fun `trip 193 is repaired to the figure its own meter corroborates`() {
        val fixed = TripEnergyMigration.correct(
            socStart = 77.0, socEnd = 71.0, distanceKm = 8.88,
            electricityRate = 13.0, fuelCost = 0.0,
            meteredEnergyKwh = 1.1, nominalKwh = 18.3,
        )
        assertEquals(14.091, fixed.kwhStart, 0.001)
        assertEquals(12.993, fixed.kwhEnd, 0.001)
        // 1.098 kWh over 8.88 km = 0.1236 kWh/km, against the stored 0.6417.
        assertEquals(0.1236, fixed.energyPerKm, 0.0001)
        assertEquals(1.098 * 13.0, fixed.electricCost, 0.01)
        assertEquals(fixed.electricCost, fixed.tripCost, 0.001)
    }

    @Test
    fun `a fuel leg is preserved rather than recomputed`() {
        // Only the electric leg was wrong. tripCost = electricCost + fuelCost, and litres came
        // from a counter this bug never touched.
        val fixed = TripEnergyMigration.correct(
            socStart = 77.0, socEnd = 71.0, distanceKm = 8.88,
            electricityRate = 13.0, fuelCost = 25.0,
            meteredEnergyKwh = 0.0, nominalKwh = 18.3,
        )
        assertEquals(fixed.electricCost + 25.0, fixed.tripCost, 0.001)
    }

    @Test
    fun `a regen-positive trip consumes nothing rather than going negative`() {
        // Trip 34 on the device: soc 59 -> 59 with kwh 59.1 -> 59.4. A pack that ended fuller
        // drew nothing on balance; billing energy that was put back would charge for a trip
        // that cost nothing.
        val fixed = TripEnergyMigration.correct(
            socStart = 59.0, socEnd = 60.0, distanceKm = 10.0,
            electricityRate = 13.0, fuelCost = 0.0,
            meteredEnergyKwh = 0.0, nominalKwh = 18.3,
        )
        assertEquals(0.0, fixed.energyPerKm, 0.0001)
        assertEquals(0.0, fixed.electricCost, 0.0001)
    }

    @Test
    fun `a short hop below SoC resolution falls back to the meter`() {
        // Trip 97: 1 km, soc 53 -> 53, so the net delta cannot answer. Its lifetime counter
        // moved 76.8 -> 76.9. Without this tier the repair would silently zero a trip that did
        // draw energy -- mirroring TripRecord.getEnergyUsedKwh, which exists for exactly this.
        val fixed = TripEnergyMigration.correct(
            socStart = 53.0, socEnd = 53.0, distanceKm = 1.0,
            electricityRate = 13.0, fuelCost = 0.0,
            meteredEnergyKwh = 0.1, nominalKwh = 18.3,
        )
        assertEquals(0.1, fixed.energyPerKm, 0.0001)
        assertEquals(1.3, fixed.electricCost, 0.001)
    }

    @Test
    fun `a zero distance trip yields no efficiency figure rather than a division by zero`() {
        val fixed = TripEnergyMigration.correct(
            socStart = 77.0, socEnd = 71.0, distanceKm = 0.0,
            electricityRate = 13.0, fuelCost = 0.0,
            meteredEnergyKwh = 0.0, nominalKwh = 18.3,
        )
        assertEquals(0.0, fixed.energyPerKm, 0.0001)
        // The energy itself is still known, so the cost is still recomputed.
        assertEquals(1.098 * 13.0, fixed.electricCost, 0.01)
    }

    @Test
    fun `an unconfigured electricity rate leaves the cost at zero`() {
        val fixed = TripEnergyMigration.correct(
            socStart = 77.0, socEnd = 71.0, distanceKm = 8.88,
            electricityRate = 0.0, fuelCost = 0.0,
            meteredEnergyKwh = 0.0, nominalKwh = 18.3,
        )
        assertEquals(0.0, fixed.electricCost, 0.0001)
        assertEquals(0.1236, fixed.energyPerKm, 0.0001)
    }
}
