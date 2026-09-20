package net.bladewatch.app.byd.bodywork

/** Constants for the BYD Bodywork SDK. */
object BodyworkConstants {

    // Power levels
    const val POWER_LEVEL_OFF = 0
    const val POWER_LEVEL_ACC = 1
    const val POWER_LEVEL_ON = 2

    // Door/Window states
    const val STATE_CLOSED = 0
    const val STATE_OPEN = 1

    // Alarm states
    const val ALARM_OFF = 0
    const val ALARM_ON = 1

    // Battery voltage levels
    const val BATTERY_LOW = 0
    const val BATTERY_NORMAL = 1
    const val BATTERY_INVALID = 2

    @JvmStatic
    fun powerLevelToString(level: Int): String = when (level) {
        POWER_LEVEL_OFF -> "OFF"
        POWER_LEVEL_ACC -> "ACC"
        POWER_LEVEL_ON -> "ON"
        else -> "UNKNOWN($level)"
    }

    @JvmStatic
    fun batteryLevelToString(level: Int): String = when (level) {
        BATTERY_LOW -> "LOW"
        BATTERY_NORMAL -> "NORMAL"
        BATTERY_INVALID -> "INVALID"
        else -> "UNKNOWN($level)"
    }
}
