package net.bladewatch.app.monitor

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-x4lf: every trip's energy, cost and efficiency was inflated ~5.2x because the
 * nominal pack capacity resolved to ~100 kWh on a Seal 5 DM-i, whose traction battery is
 * 18.3 kWh.
 *
 * Root cause, measured off the device's own SoC history (963 rows, 2026-09-19): the BYD
 * "remaining kWh" channel is not energy at all, it mirrors SoC percent 1:1 --
 * soc=73/remain=72.9, soc=77/remain=77.0, soc=79/remain=78.8. Dividing that by soc/100
 * yields ~100 for ANY pack, a number that looks like a plausible BEV capacity, so nothing
 * downstream noticed. The efficiency scorer then saw 0.64 kWh/km, off the bottom of any sane
 * scale, and pinned every trip at 0 -- which is the "trips show 0% efficiency" symptom.
 *
 * These are pure functions with the inputs injected precisely because `VehicleDataMonitor`
 * is a private-constructor singleton over live BYD data and cannot be built on the JVM --
 * the same constraint that shaped `StorageManager.selectFilesToDelete`.
 */
class NominalCapacityResolverTest {

    // ── the mirror detector ──────────────────────────────────────────────

    @Test
    fun `real measured pairs from the car are recognised as a SoC mirror`() {
        // Verbatim from SOC_HISTORY on the head unit.
        val measured = listOf(
            73.0 to 72.9, 72.0 to 72.3, 72.0 to 71.6, 71.0 to 71.3,
            71.0 to 71.4, 73.0 to 73.3, 77.0 to 77.0, 79.0 to 78.8,
        )
        for ((soc, remain) in measured) {
            assertTrue(
                "soc=$soc remain=$remain is a 1:1 mirror and must not be read as energy",
                NominalCapacityResolver.looksLikeSocMirror(remain, soc)
            )
        }
    }

    @Test
    fun `a genuine PHEV energy reading is not mistaken for a mirror`() {
        // 18.3 kWh pack at 73% -> 13.4 kWh remaining. Nothing like 73.
        assertFalse(NominalCapacityResolver.looksLikeSocMirror(13.4, 73.0))
        // 82.5 kWh Seal at 40% -> 33 kWh. Nothing like 40.
        assertFalse(NominalCapacityResolver.looksLikeSocMirror(33.0, 40.0))
    }

    // ── the user override ────────────────────────────────────────────────

    @Test
    fun `a user-set override outranks every detected source`() {
        // BladeWatch-b9vl. The owner knows their own car. Every other source here is inference:
        // the SDK field is a charging-session figure (phim), the catalogue is per-trim, and the
        // derivation reads a channel that mirrors SoC on this car. An explicit value is not.
        assertEquals(21.5, NominalCapacityResolver.resolve(
            overrideKwh = 21.5, chargingCapacityKwh = 60.0, catalogueKwh = 18.3,
            remainKwh = 33.0, socPercent = 40.0,
        ), 0.001)
    }

    @Test
    fun `an unset override changes nothing`() {
        // 0 and NaN both mean "not set" — clearing the override must fall straight back to
        // auto-detection rather than pinning the pack at zero.
        assertEquals(18.3, NominalCapacityResolver.resolve(
            overrideKwh = 0.0, chargingCapacityKwh = Double.NaN, catalogueKwh = 18.3,
            remainKwh = 72.9, socPercent = 73.0,
        ), 0.001)
        assertEquals(18.3, NominalCapacityResolver.resolve(
            overrideKwh = Double.NaN, chargingCapacityKwh = Double.NaN, catalogueKwh = 18.3,
            remainKwh = 72.9, socPercent = 73.0,
        ), 0.001)
    }

    @Test
    fun `an out-of-range override is refused rather than trusted`() {
        // The old REST contract specified 8-120 kWh. A typo must not be able to redefine the
        // pack as 1.83 or 1830 kWh and silently corrupt every trip from then on.
        for (bad in listOf(7.9, 120.1, -5.0, 0.5)) {
            assertEquals("an override of $bad is outside any real BYD pack and must be ignored",
                18.3, NominalCapacityResolver.resolve(
                    overrideKwh = bad, chargingCapacityKwh = Double.NaN, catalogueKwh = 18.3,
                    remainKwh = 72.9, socPercent = 73.0,
                ), 0.001)
        }
        for (ok in listOf(8.0, 120.0, 18.3)) {
            assertTrue("an override of $ok is a real pack size and must be honoured",
                NominalCapacityResolver.isUsableOverride(ok))
        }
    }

    // ── which source answered ────────────────────────────────────────────

    @Test
    fun `the resolver reports which source answered`() {
        // GetSohNominal reported a hardcoded "unset" even when a capacity was demonstrably
        // known. The source has to come from the same decision that picked the value, or the
        // two drift apart again.
        assertEquals("user", NominalCapacityResolver.sourceOf(18.3, Double.NaN, 18.3, 72.9, 73.0))
        assertEquals("sdk", NominalCapacityResolver.sourceOf(0.0, 19.5, 18.3, 72.9, 73.0))
        assertEquals("catalogue", NominalCapacityResolver.sourceOf(0.0, Double.NaN, 18.3, 72.9, 73.0))
        assertEquals("derived", NominalCapacityResolver.sourceOf(0.0, Double.NaN, 0.0, 33.0, 40.0))
        assertEquals("unset", NominalCapacityResolver.sourceOf(0.0, Double.NaN, 0.0, 72.9, 73.0))
    }

    @Test
    fun `the reported source always matches the value actually returned`() {
        // Pins the two together so a future edit cannot change one without the other.
        val cases = listOf(
            listOf(18.3, Double.NaN, 18.3, 72.9, 73.0),
            listOf(0.0, 19.5, 18.3, 72.9, 73.0),
            listOf(0.0, Double.NaN, 18.3, 72.9, 73.0),
            listOf(0.0, Double.NaN, 0.0, 33.0, 40.0),
            listOf(0.0, Double.NaN, 0.0, 72.9, 73.0),
        )
        for (c in cases) {
            val value = NominalCapacityResolver.resolve(c[0], c[1], c[2], c[3], c[4])
            val source = NominalCapacityResolver.sourceOf(c[0], c[1], c[2], c[3], c[4])
            assertEquals("a source of 'unset' must mean no value, and vice versa",
                source == "unset", value == 0.0)
        }
    }

    // ── the no-nominal fallback ──────────────────────────────────────────

    @Test
    fun `without a nominal capacity a mirrored reading is not passed off as energy`() {
        // BladeWatch-ofe9. getBatteryRemainPowerKwh ends with "no nominal capacity: use the raw
        // BMS value if available", and nominal == 0.0 is exactly the honest "unknown" that
        // resolve() now returns. Without this guard the unknown is converted straight back into
        // the ~5.4x-wrong mirrored number the x4lf fix exists to eliminate.
        assertEquals("a mirrored reading with no nominal to check it against is unknown, not energy",
            0.0, NominalCapacityResolver.trustworthyRemainKwh(72.9, 73.0), 0.001)
        assertEquals(0.0, NominalCapacityResolver.trustworthyRemainKwh(77.0, 77.0), 0.001)
    }

    @Test
    fun `without a nominal capacity an honest reading is still returned`() {
        // Cars where the channel really does report energy must not regress: 33 kWh at 40% is
        // nothing like 40, so it is believed even with no capacity to cross-check it.
        assertEquals(33.0, NominalCapacityResolver.trustworthyRemainKwh(33.0, 40.0), 0.001)
        // No reading at all stays unknown rather than becoming a fake zero reading.
        assertEquals(0.0, NominalCapacityResolver.trustworthyRemainKwh(0.0, 40.0), 0.001)
        assertEquals(0.0, NominalCapacityResolver.trustworthyRemainKwh(Double.NaN, 40.0), 0.001)
    }

    // ── the resolver ─────────────────────────────────────────────────────

    @Test
    fun `the model catalogue answers when the SDK capacity is absent`() {
        val kwh = NominalCapacityResolver.resolve(
            overrideKwh = 0.0,
            chargingCapacityKwh = Double.NaN,   // what this car actually reports
            catalogueKwh = 18.3,                 // seal5-dmi-premium, from models/manifest.json
            remainKwh = 72.9, socPercent = 73.0, // the mirrored channel
        )
        assertEquals(18.3, kwh, 0.001)
    }

    @Test
    fun `the mirrored channel is rejected rather than divided into a fake 100 kWh`() {
        // No catalogue entry either: the honest answer is "unknown", not ~100.
        val kwh = NominalCapacityResolver.resolve(
            overrideKwh = 0.0,
            chargingCapacityKwh = Double.NaN, catalogueKwh = 0.0,
            remainKwh = 72.9, socPercent = 73.0,
        )
        assertEquals("a SoC mirror must yield unknown, never an invented capacity",
            0.0, kwh, 0.001)
    }

    @Test
    fun `a real kWh channel is still used when there is no catalogue entry`() {
        // Unlisted trim, but the BMS reports genuine energy: 33 kWh at 40% -> 82.5 kWh.
        val kwh = NominalCapacityResolver.resolve(
            overrideKwh = 0.0,
            chargingCapacityKwh = Double.NaN, catalogueKwh = 0.0,
            remainKwh = 33.0, socPercent = 40.0,
        )
        assertEquals(82.5, kwh, 0.01)
    }

    @Test
    fun `the SDK capacity still wins when it agrees with the catalogue`() {
        // This test used to pass chargingCapacityKwh = 60.0 against a catalogue of 18.3 and
        // assert that 60.0 won. That pair is not a battery option, it is a contradiction --
        // the test was pinning the BladeWatch-phim defect as if it were the requirement. The
        // intent it was written for, per-vehicle outranking per-trim, is real and is kept here
        // with a pair that could actually describe the same car.
        val kwh = NominalCapacityResolver.resolve(
            overrideKwh = 0.0,
            chargingCapacityKwh = 19.5, catalogueKwh = 18.3,
            remainKwh = 30.0, socPercent = 50.0,
        )
        assertEquals("a per-vehicle SDK value outranks a per-trim constant",
            19.5, kwh, 0.001)
        assertEquals(82.5, NominalCapacityResolver.resolve(0.0, 82.5, 80.0, Double.NaN, Double.NaN), 0.001)
    }

    @Test
    fun `an SDK capacity that contradicts the catalogue loses to the catalogue`() {
        // BladeWatch-phim. chargingCapacityKwh is NOT a verified pack-spec field: its two
        // writers in BydDataCollector accept it on `> 0` and `0 < cap < 200` respectively, and
        // the callback's own comment calls the event "purely diagnostic for charging session
        // size". A part-charged session on this 18.3 kWh car reads about 6.5.
        assertEquals("a charging-session figure must not redefine the pack",
            18.3, NominalCapacityResolver.resolve(0.0, 6.5, 18.3, Double.NaN, Double.NaN), 0.001)

        // And a percentage, which the 0..200 window admits whole.
        assertEquals("a percentage must not redefine the pack",
            18.3, NominalCapacityResolver.resolve(0.0, 73.0, 18.3, 72.9, 73.0), 0.001)
    }

    @Test
    fun `with no catalogue entry the SDK value is taken as before`() {
        // Unlisted trim: there is nothing to cross-check against, so refusing the only figure
        // available would be a regression, not a safeguard.
        assertEquals(6.5, NominalCapacityResolver.resolve(0.0, 6.5, 0.0, Double.NaN, Double.NaN), 0.001)
    }

    @Test
    fun `low or absent SoC yields unknown rather than a wild extrapolation`() {
        // Dividing by a near-zero SoC is how you get a nonsense capacity.
        assertEquals(0.0, NominalCapacityResolver.resolve(0.0, Double.NaN, 0.0, 2.0, 3.0), 0.001)
        assertEquals(0.0, NominalCapacityResolver.resolve(0.0, Double.NaN, 0.0, 0.0, 50.0), 0.001)
        assertEquals(0.0, NominalCapacityResolver.resolve(0.0, Double.NaN, 0.0, Double.NaN, Double.NaN), 0.001)
    }
}
