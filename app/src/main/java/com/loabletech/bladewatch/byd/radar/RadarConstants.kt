package net.bladewatch.app.byd.radar

/** Constants for the BYD Radar SDK. */
object RadarConstants {

    // Radar probe states
    const val STATE_SAFE = 0
    const val STATE_ABNORMAL = 1
    const val STATE_GREEN = 2
    const val STATE_YELLOW = 3
    const val STATE_RED = 4

    // Radar areas (8 sensors)
    const val AREA_LEFT_FRONT = 0
    const val AREA_RIGHT_FRONT = 1
    const val AREA_LEFT_REAR = 2
    const val AREA_RIGHT_REAR = 3
    const val AREA_LEFT = 4
    const val AREA_RIGHT = 5
    const val AREA_FRONT_LEFT_MID = 6
    const val AREA_FRONT_RIGHT_MID = 7

    const val SENSOR_COUNT = 8

    @JvmField
    val AREA_NAMES = arrayOf(
        "leftFront", "rightFront", "leftRear", "rightRear",
        "left", "right", "frontLeftMid", "frontRightMid"
    )

    @JvmStatic
    fun stateToString(state: Int): String = when (state) {
        STATE_SAFE -> "SAFE"
        STATE_ABNORMAL -> "ABNORMAL"
        STATE_GREEN -> "GREEN"
        STATE_YELLOW -> "YELLOW"
        STATE_RED -> "RED"
        -1 -> "UNKNOWN"
        else -> "STATE($state)"
    }

    @JvmStatic
    fun areaToString(area: Int): String = when (area) {
        AREA_LEFT_FRONT -> "LEFT_FRONT"
        AREA_RIGHT_FRONT -> "RIGHT_FRONT"
        AREA_LEFT_REAR -> "LEFT_REAR"
        AREA_RIGHT_REAR -> "RIGHT_REAR"
        AREA_LEFT -> "LEFT"
        AREA_RIGHT -> "RIGHT"
        AREA_FRONT_LEFT_MID -> "FRONT_LEFT_MID"
        AREA_FRONT_RIGHT_MID -> "FRONT_RIGHT_MID"
        else -> "AREA($area)"
    }
}
