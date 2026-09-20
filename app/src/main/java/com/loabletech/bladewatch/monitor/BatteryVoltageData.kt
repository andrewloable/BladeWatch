package net.bladewatch.app.monitor

/**
 * Data model for the 12V battery voltage LEVEL status.
 *
 * Represents the level as reported by BYDAutoBodyworkDevice. This is a status indicator
 * (LOW/NORMAL/INVALID), not the actual voltage in volts — see [BatteryPowerData] for that.
 *
 * @param level the level code from BYDAutoBodyworkDevice (0=LOW, 1=NORMAL, 255=INVALID)
 */
class BatteryVoltageData(@JvmField val level: Int) {

    /** "LOW", "NORMAL" or "INVALID". */
    @JvmField
    val levelName: String = interpretLevel(level)

    /** True if the level is LOW. */
    @JvmField
    val isWarning: Boolean = level == BODYWORK_BATTERY_VOLTAGE_LEVEL_LOW

    @JvmField
    val timestamp: Long = System.currentTimeMillis()

    override fun toString(): String =
        "BatteryVoltageData{" +
            "level=" + level +
            ", levelName='" + levelName + '\'' +
            ", isWarning=" + isWarning +
            ", timestamp=" + timestamp +
            '}'

    companion object {
        // Constants from BYDAutoBodyworkDevice
        const val BODYWORK_BATTERY_VOLTAGE_LEVEL_LOW = 0
        const val BODYWORK_BATTERY_VOLTAGE_LEVEL_NORMAL = 1
        const val BODYWORK_BATTERY_VOLTAGE_LEVEL_INVALID = 255

        /** Interpret a level code as a human-readable name. */
        private fun interpretLevel(level: Int): String = when (level) {
            BODYWORK_BATTERY_VOLTAGE_LEVEL_LOW -> "LOW"
            BODYWORK_BATTERY_VOLTAGE_LEVEL_NORMAL -> "NORMAL"
            BODYWORK_BATTERY_VOLTAGE_LEVEL_INVALID -> "INVALID"
            // Unknown codes default to INVALID
            else -> "INVALID"
        }
    }
}
