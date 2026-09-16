package net.bladewatch.app.trips

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-9uu6: settings survive a daemon restart.
 *
 * The failure this guards is silent and unpleasant: a KEY MISMATCH between what `save()` writes
 * and what `load()` reads loses the setting on the next restart with no error anywhere. The
 * owner simply finds their currency reverted to USD and has no way to tell why.
 *
 * The file I/O itself belongs to `UnifiedConfigManager` and is shared by every config section,
 * so these exercise the serialisation round trip — the part unique to trips, and the part where
 * a new field is easy to add on one side only.
 */
class TripConfigPersistenceTest {

    private companion object { const val EPS = 1e-9 }

    /** Save this config and load it into a fresh instance, as a restart would. */
    private fun restart(configure: TripConfig.() -> Unit): TripConfig {
        val before = TripConfig().apply(configure)
        val section = before.toSection()
        return TripConfig().apply { applySection(section) }
    }

    // ── the reported requirement ──

    @Test
    fun `a selected currency survives a restart`() {
        val after = restart { setCurrency("PHP") }
        assertEquals("PHP", after.getCurrency())
    }

    @Test
    fun `every currency in the catalogue survives a restart`() {
        for (code in listOf("USD", "EUR", "GBP", "JPY", "PHP", "AUD", "INR", "ZAR")) {
            val after = restart { setCurrency(code) }
            assertEquals("$code must survive a restart", code, after.getCurrency())
        }
    }

    /** Normalisation happens on the way in, so what is stored is what comes back. */
    @Test
    fun `a lower case selection survives normalised`() {
        assertEquals("PHP", restart { setCurrency("php") }.getCurrency())
    }

    /**
     * An owner whose config predates the picker must not have their symbol rewritten or
     * dropped by a save/load cycle — every trip they have is priced in it.
     */
    @Test
    fun `a legacy symbol survives a restart unchanged`() {
        for (legacy in listOf("$", "€", "kr", "Rp")) {
            val after = restart { setCurrency(legacy) }
            assertEquals("legacy $legacy must survive", legacy, after.getCurrency())
        }
    }

    // ── the rest of the settings ──

    @Test
    fun `phev pricing survives a restart`() {
        val after = restart {
            setFuelPricePerL(1.80)
            setFuelTankCapacityL(50.0)
        }
        assertEquals(1.80, after.getFuelPricePerL(), EPS)
        assertEquals(50.0, after.getFuelTankCapacityL(), EPS)
    }

    @Test
    fun `every setting survives together`() {
        val after = restart {
            setElectricityRate(0.1234)
            setFuelPricePerL(1.85)
            setFuelTankCapacityL(47.5)
            setCurrency("SGD")
            setDistanceUnit("mi")
        }
        assertEquals(0.1234, after.getElectricityRate(), EPS)
        assertEquals(1.85, after.getFuelPricePerL(), EPS)
        assertEquals(47.5, after.getFuelTankCapacityL(), EPS)
        assertEquals("SGD", after.getCurrency())
        assertEquals("mi", after.getDistanceUnit())
    }

    /**
     * A deliberate 0 means "not configured" and must persist as 0 — not silently revert to a
     * previous non-zero value, which is what happens if a writer skips defaults.
     */
    @Test
    fun `a deliberate zero persists as zero`() {
        val after = restart {
            setFuelPricePerL(1.80)
            setFuelPricePerL(0.0)   // owner clears it
        }
        assertEquals(0.0, after.getFuelPricePerL(), EPS)
    }

    // ── what the settings UIs read back ──

    /**
     * Persisting correctly is only half of "the selection persists" — both settings screens
     * seed their fields from this projection, so a value that saves fine but is missing here
     * still LOOKS reverted to the owner.
     */
    @Test
    fun `the api projection carries everything the settings screens seed from`() {
        val json = TripConfig().apply {
            setElectricityRate(0.15)
            setFuelPricePerL(1.80)
            setFuelTankCapacityL(50.0)
            setCurrency("PHP")
            setDistanceUnit("mi")
        }.toJson()

        assertEquals("PHP", json.getString("currency"))
        assertEquals(0.15, json.getDouble("electricityRate"), EPS)
        assertEquals(1.80, json.getDouble("fuelPricePerL"), EPS)
        assertEquals(50.0, json.getDouble("fuelTankCapacityL"), EPS)
        assertEquals("mi", json.getString("distanceUnit"))
    }

    /**
     * The full journey: an owner picks a currency, the daemon restarts, and the settings
     * screen shows what they chose rather than the default.
     */
    @Test
    fun `a chosen currency comes back through the projection after a restart`() {
        val afterRestart = restart { setCurrency("SGD") }
        assertEquals("the settings screen seeds from this",
            "SGD", afterRestart.toJson().getString("currency"))
    }

    // ── key contract ──

    /**
     * Every key `applySection` reads must be one `toSection` writes. A field added to only one
     * side is the exact bug this class exists for, and it is invisible until a restart.
     */
    @Test
    fun `written keys cover everything the loader reads`() {
        val written = TripConfig().toSection().keys().asSequence().toSet()
        for (key in listOf(
            "enabled", "electricityRate", "fuelPricePerL",
            "fuelTankCapacityL", "currency", "distanceUnit",
        )) {
            assertTrue("save() must write '$key' or load() silently loses it",
                key in written)
        }
    }

    /**
     * A section written by an older build has none of the newer keys. It must load as "not
     * configured" rather than throwing or inventing a value.
     */
    @Test
    fun `a section from an older build loads with safe defaults`() {
        val legacySection = JSONObject()
            .put("enabled", true)
            .put("electricityRate", 0.15)
            .put("currency", "$")

        val cfg = TripConfig().apply { applySection(legacySection) }

        assertEquals("the old settings still load", 0.15, cfg.getElectricityRate(), EPS)
        assertEquals("$", cfg.getCurrency())
        assertEquals("a missing fuel price is not configured", 0.0, cfg.getFuelPricePerL(), EPS)
        assertEquals("a missing tank size is not configured",
            0.0, cfg.getFuelTankCapacityL(), EPS)
        assertEquals("distance unit falls back to km", "km", cfg.getDistanceUnit())
    }
}
