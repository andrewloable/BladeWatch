package net.bladewatch.app.monitor

/**
 * Immutable data class for HV battery thermal readings.
 *
 * Values are in degrees Celsius, derived from BYD's CAN bus encoding: `actualTempC = rawValue - 40`.
 *
 * Three sensors from BYDAutoStatisticDevice: the highest battery cell temperature, the lowest
 * battery cell temperature, and the average pack / coolant temperature.
 */
class BatteryThermalData(
    /** Max cell temperature in °C (NaN if unavailable). */
    @JvmField val highestTempC: Double,
    /** Min cell temperature in °C (NaN if unavailable). */
    @JvmField val lowestTempC: Double,
    /** Average pack temperature in °C (NaN if unavailable). */
    @JvmField val averageTempC: Double,
    /** Timestamp of this reading. */
    @JvmField val timestamp: Long
) {

    /** Temperature delta between the max and min cells (a thermal imbalance indicator). */
    @JvmField
    val deltaC: Double =
        if (!highestTempC.isNaN() && !lowestTempC.isNaN()) highestTempC - lowestTempC
        else Double.NaN

    /** True if any temperature exceeds 45°C (BYD's thermal warning threshold). */
    @JvmField
    val isWarning: Boolean

    /** True if any temperature exceeds 55°C (critical — the BMS will derate). */
    @JvmField
    val isCritical: Boolean

    init {
        var maxTemp = Double.NaN
        if (!highestTempC.isNaN()) {
            maxTemp = highestTempC
        } else if (!averageTempC.isNaN()) {
            maxTemp = averageTempC
        }

        isWarning = !maxTemp.isNaN() && maxTemp > 45.0
        isCritical = !maxTemp.isNaN() && maxTemp > 55.0
    }

    /**
     * The best available temperature reading for thermal monitoring: prefers the average, falls
     * back to the highest, then the lowest.
     */
    fun getBestTemperature(): Double {
        if (!averageTempC.isNaN()) return averageTempC
        if (!highestTempC.isNaN()) return highestTempC
        return lowestTempC
    }

    /** True if at least one temperature reading is available. */
    fun hasData(): Boolean =
        !highestTempC.isNaN() || !lowestTempC.isNaN() || !averageTempC.isNaN()

    fun getStatus(): String = when {
        isCritical -> "CRITICAL"
        isWarning -> "WARNING"
        hasData() -> "NORMAL"
        else -> "UNAVAILABLE"
    }

    override fun toString(): String {
        if (!hasData()) return "BatteryThermal[unavailable]"
        return String.format(
            "BatteryThermal[hi=%.1f°C lo=%.1f°C avg=%.1f°C Δ=%.1f°C %s]",
            highestTempC, lowestTempC, averageTempC, deltaC, getStatus()
        )
    }
}
