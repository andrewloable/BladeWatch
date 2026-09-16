package net.bladewatch.app.trips

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Persistent configuration for Trip Analytics.
 *
 * Uses `UnifiedConfigManager` to store config in the "tripAnalytics" section of
 * `/data/local/tmp/bladewatch_config.json`. Storage settings (storageType, storageLimitMb)
 * are delegated to `StorageManager` — this class only manages the enabled toggle and the
 * pricing the trip cost is computed from.
 *
 * **Java interop.** The accessors are spelled as explicit `isEnabled()` / `getX()` / `setX()`
 * rather than Kotlin properties, because `TripAnalyticsManager` and `TripApiHandler` are Java
 * and call them by those exact names.
 */
class TripConfig {

    private var enabledFlag: Boolean = true

    /** Cost per kWh. 0 means not configured, so the electric leg is not costed. */
    private var electricityRateValue: Double = 0.0

    /**
     * Cost per litre for the PHEV fuel leg (BladeWatch-fpdz). 0 means NOT CONFIGURED, not
     * free — exactly as a 0 electricity rate means the electric leg is not costed. The
     * currency is shared with the electric rate: one car, one wallet.
     */
    private var fuelPriceValue: Double = 0.0

    /**
     * Fuel tank capacity in litres, owner-set. 0 means NOT CONFIGURED, and that is the
     * default on purpose: BYD local data does not expose a tank size, so without this the
     * fuel range simply cannot be computed. A guessed default would put a wrong range number
     * on the dashboard, which is worse than no number because the driver acts on it.
     */
    private var fuelTankCapacityValue: Double = 0.0

    private var currencyValue: String = ""

    /**
     * Distance unit preference: "km" (default) or "mi". When "mi", the backend applies
     * MILES_TO_KM conversion on BYD SDK values and the frontend converts km to miles for
     * display. Overrides the auto-detected getMileageUnit() from the instrument cluster.
     */
    private var distanceUnitValue: String = "km"

    /**
     * Load configuration from UnifiedConfigManager.
     *
     * @return true if the section was read successfully, false otherwise
     */
    fun load(): Boolean {
        return try {
            val section = UnifiedConfigManager.loadConfig().optJSONObject(SECTION)
            if (section != null) {
                // Trip analytics is always on — there is no user-facing off switch. A stored
                // enabled=false (from a legacy build or a stale SetConfig) would otherwise make
                // TripAnalyticsManager.init() skip initComponents(), leaving the TripDatabase
                // unopened so every read endpoint returns "Trip database not available" and the
                // dashboard / Trips screen show nothing. Force it true and self-heal the
                // persisted config so the file stops contradicting runtime state.
                val stored = section.optBoolean("enabled", true)
                applySection(section)
                logger.info(
                    "Config loaded: enabled=$enabledFlag rate=$electricityRateValue " +
                        "fuel=$fuelPriceValue $currencyValue unit=$distanceUnitValue"
                )
                if (!stored) {
                    logger.info(
                        "Stored enabled=false ignored — trip analytics is always on; " +
                            "self-healing config"
                    )
                    save()
                }
                true
            } else {
                logger.info("No tripAnalytics section in UnifiedConfigManager, using defaults")
                false
            }
        } catch (e: Exception) {
            logger.error("Config load error: " + e.message)
            enabledFlag = true
            false
        }
    }

    /**
     * Save current configuration to UnifiedConfigManager.
     *
     * @return true if the config was written successfully, false otherwise
     */
    fun save(): Boolean {
        return try {
            val success = UnifiedConfigManager.updateSection(SECTION, toSection())
            if (success) {
                logger.info("Config saved to UnifiedConfigManager: enabled=$enabledFlag")
            }
            success
        } catch (e: Exception) {
            logger.error("Config save error: " + e.message)
            false
        }
    }

    /**
     * Serialise this config to its persisted section.
     *
     * Paired with [applySection], and split out so the round trip is testable without a
     * filesystem. The failure this guards is a KEY MISMATCH: writing "currency" while reading
     * "currencyCode" loses the setting silently on the next daemon restart, with no error
     * anywhere — the owner just finds their choice reverted.
     */
    internal fun toSection(): JSONObject {
        val section = JSONObject()
        section.put("enabled", enabledFlag)
        section.put("electricityRate", electricityRateValue)
        section.put("fuelPricePerL", fuelPriceValue)
        section.put("fuelTankCapacityL", fuelTankCapacityValue)
        section.put("currency", currencyValue)
        section.put("distanceUnit", distanceUnitValue)
        return section
    }

    /**
     * Populate this config from a persisted section. Paired with [toSection].
     *
     * Every default here must match the field initialiser, so a section written by an older
     * build (missing the newer keys) loads as "not configured" rather than as a surprise.
     */
    internal fun applySection(section: JSONObject) {
        // enabled is deliberately NOT read back into enabledFlag — trip analytics is always
        // on. load() inspects the stored value only to self-heal the file.
        enabledFlag = true
        electricityRateValue = section.optDouble("electricityRate", 0.0)
        fuelPriceValue = section.optDouble("fuelPricePerL", 0.0)
        fuelTankCapacityValue = section.optDouble("fuelTankCapacityL", 0.0)
        currencyValue = section.optString("currency", "")
        distanceUnitValue = section.optString("distanceUnit", "km")
    }

    // ==================== GETTERS ====================

    fun isEnabled(): Boolean = enabledFlag

    fun getElectricityRate(): Double = electricityRateValue

    /** Cost per litre for the fuel leg; 0 means not configured, so the leg is not costed. */
    fun getFuelPricePerL(): Double = fuelPriceValue

    /** Tank capacity in litres; 0 means not configured, so no fuel range can be predicted. */
    fun getFuelTankCapacityL(): Double = fuelTankCapacityValue

    fun getCurrency(): String = currencyValue

    fun getDistanceUnit(): String = distanceUnitValue

    // ==================== SETTERS ====================

    /** Trip analytics is always on; attempts to disable it are ignored. */
    fun setEnabled(@Suppress("UNUSED_PARAMETER") enabled: Boolean) {
        enabledFlag = true
    }

    /**
     * A settings figure that is safe to store, or 0 meaning "not configured".
     *
     * Rejects negatives — a negative price or capacity turns a cost or a range negative
     * downstream — and, less obviously, **non-finite values**.
     *
     * Infinity is the one that bites: `Infinity > 0` is TRUE, so a plain positivity check
     * stores it happily. JSON has no way to represent it, and `JSONObject.put` throws
     * "JSON does not allow non-finite numbers" the moment a derived cost is serialised. Because
     * `TripRecord.toJson` catches, the result is not a clean error but a PARTIAL trip object
     * missing every key after the failure — and it persists, because the config is saved.
     *
     * It is reachable without touching the UI: `optDouble` parses the perfectly legal JSON
     * literal `1e400` as Infinity, so a single config POST would degrade the whole trips API
     * until someone noticed and reset the value.
     */
    private fun sanitizeSetting(value: Double): Double =
        if (value.isFinite() && value > 0) value else 0.0

    fun setElectricityRate(rate: Double) {
        electricityRateValue = sanitizeSetting(rate)
    }

    fun setFuelPricePerL(pricePerLitre: Double) {
        fuelPriceValue = sanitizeSetting(pricePerLitre)
    }

    fun setFuelTankCapacityL(litres: Double) {
        fuelTankCapacityValue = sanitizeSetting(litres)
    }

    /**
     * Store the display currency.
     *
     * Both UIs now pick an ISO 4217 code, so anything code-SHAPED (exactly three letters) is
     * normalised to upper case — otherwise "php" and "PHP" become two different stored values
     * for the same currency.
     *
     * **The daemon deliberately does not carry the 162-code list.** Its job here is to reject
     * garbage, not to be the ISO authority: the picker is what constrains the choice, and
     * "exactly three letters" is a complete structural rule for ISO 4217 without a table to
     * keep in sync with the generated catalogue. A well-formed code this build has never heard
     * of is stored as-is and costs nothing, because the render path falls back to prefix
     * display for anything ICU cannot format.
     *
     * **Legacy values are preserved unchanged.** A config predating the picker holds a bare
     * symbol like "$" and belongs to an owner with trips priced in it; rewriting or clearing it
     * would make their existing costs render blank.
     */
    fun setCurrency(currency: String?) {
        if (currency.isNullOrEmpty()) {
            currencyValue = ""
            return
        }
        // Reject HTML-injection chars; cap at 8 chars (enough for any symbol or code). This
        // value is interpolated into UI strings and log lines.
        if (currency.contains("<") || currency.contains(">") || currency.length > 8) {
            currencyValue = ""
            return
        }
        currencyValue = if (isIsoCodeShaped(currency)) currency.uppercase() else currency
    }

    /** Whether [value] has the shape of an ISO 4217 code: exactly three ASCII letters. */
    private fun isIsoCodeShaped(value: String): Boolean =
        value.length == 3 && value.all { it in 'a'..'z' || it in 'A'..'Z' }

    fun setDistanceUnit(unit: String?) {
        distanceUnitValue = if (unit == "mi") "mi" else "km"
    }

    // ==================== UTILITY ====================

    /** Serialize configuration to a JSONObject for API responses. */
    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("enabled", enabledFlag)
            json.put("electricityRate", electricityRateValue)
            json.put("fuelPricePerL", fuelPriceValue)
            json.put("fuelTankCapacityL", fuelTankCapacityValue)
            json.put("currency", currencyValue)
            json.put("distanceUnit", distanceUnitValue)
        } catch (e: Exception) {
            logger.error("toJson error: " + e.message)
        }
        return json
    }

    override fun toString(): String = "TripConfig{enabled=$enabledFlag}"

    private companion object {
        private const val TAG = "TripConfig"
        private const val SECTION = "tripAnalytics"
        private val logger = DaemonLogger.getInstance(TAG)
    }
}
