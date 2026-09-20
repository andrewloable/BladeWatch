package net.bladewatch.app.monitor

/**
 * Data model for the 12V battery power voltage: the actual voltage in volts as reported by
 * BYDAutoOtaDevice, with warning and critical thresholds for battery health monitoring.
 *
 * @param voltageVolts the voltage in volts from BYDAutoOtaDevice (9.0-16.0V typical)
 */
class BatteryPowerData(@JvmField val voltageVolts: Double) {

    /** True if below [CRITICAL_THRESHOLD_VOLTS]. */
    @JvmField
    val isCritical: Boolean = voltageVolts < CRITICAL_THRESHOLD_VOLTS

    /** True if below [WARNING_THRESHOLD_VOLTS]. */
    @JvmField
    val isWarning: Boolean = voltageVolts < WARNING_THRESHOLD_VOLTS

    @JvmField
    val timestamp: Long = System.currentTimeMillis()

    /** Whether the voltage is within the valid range. */
    fun isValidRange(): Boolean = voltageVolts in MIN_VALID_VOLTS..MAX_VALID_VOLTS

    /** Health status description. */
    fun getHealthStatus(): String = when {
        isCritical -> "CRITICAL"
        isWarning -> "WARNING"
        else -> "NORMAL"
    }

    override fun toString(): String =
        "BatteryPowerData{" +
            "voltageVolts=" + voltageVolts +
            ", isWarning=" + isWarning +
            ", isCritical=" + isCritical +
            ", timestamp=" + timestamp +
            '}'

    companion object {
        // Voltage thresholds
        const val WARNING_THRESHOLD_VOLTS = 11.5
        const val CRITICAL_THRESHOLD_VOLTS = 10.5
        const val MIN_VALID_VOLTS = 9.0
        const val MAX_VALID_VOLTS = 16.0
    }
}
