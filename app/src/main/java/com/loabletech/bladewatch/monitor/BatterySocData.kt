package net.bladewatch.app.monitor

/**
 * Data model for the battery State of Charge (SOC): the remaining battery power as a percentage
 * (0-100%). Source: BYDAutoStatisticDevice.getElecPercentageValue().
 *
 * @param socPercent the SOC percentage (0-100)
 */
class BatterySocData(@JvmField val socPercent: Double) {

    /** True if below [CRITICAL_SOC_THRESHOLD]. */
    @JvmField
    val isCritical: Boolean = socPercent < CRITICAL_SOC_THRESHOLD

    /** True if below [LOW_SOC_THRESHOLD]. */
    @JvmField
    val isLow: Boolean = socPercent < LOW_SOC_THRESHOLD

    @JvmField
    val timestamp: Long = System.currentTimeMillis()

    /** Whether the SOC is within the valid range. */
    fun isValidRange(): Boolean = socPercent in MIN_SOC..MAX_SOC

    /** Battery status description. */
    fun getStatus(): String = when {
        isCritical -> "CRITICAL"
        isLow -> "LOW"
        else -> "NORMAL"
    }

    override fun toString(): String =
        "BatterySocData{" +
            "socPercent=" + socPercent +
            ", isLow=" + isLow +
            ", isCritical=" + isCritical +
            ", timestamp=" + timestamp +
            '}'

    companion object {
        const val MIN_SOC = 0.0
        const val MAX_SOC = 100.0
        const val LOW_SOC_THRESHOLD = 20.0
        const val CRITICAL_SOC_THRESHOLD = 10.0
    }
}
