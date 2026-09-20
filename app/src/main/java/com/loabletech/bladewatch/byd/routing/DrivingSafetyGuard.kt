package net.bladewatch.app.byd.routing

/**
 * Pure motion-block decision function for vehicle-actuation commands.
 *
 * No Android, no singletons, no state — callers pass gear and speed in directly so this can be
 * unit-tested without a device. See BladeWatch-2pnn.2 for the caller that wires this into
 * [VehicleCommandRouter].
 */
object DrivingSafetyGuard {

    // Gear constants, duplicated by value from GearMonitor / RecordingModeManager.
    private const val GEAR_P = 1
    private const val GEAR_R = 2
    private const val GEAR_N = 3
    private const val GEAR_D = 4
    private const val GEAR_M = 5
    private const val GEAR_S = 6

    private const val SPEED_JITTER_FLOOR_KMH = 0.5

    enum class Decision {
        ALLOW,
        BLOCK_MOVING,
        BLOCK_UNKNOWN
    }

    @JvmStatic
    fun evaluate(gear: Int, speedKmh: Double, requireKnownState: Boolean): Decision {
        val speedKnown = !speedKmh.isNaN()

        if (speedKnown && speedKmh > SPEED_JITTER_FLOOR_KMH) {
            return Decision.BLOCK_MOVING
        }
        if (isDrivingGear(gear)) {
            return Decision.BLOCK_MOVING
        }
        if (gear == GEAR_P && speedKnown) {
            return Decision.ALLOW
        }
        return if (requireKnownState) Decision.BLOCK_UNKNOWN else Decision.ALLOW
    }

    private fun isDrivingGear(gear: Int): Boolean =
        gear == GEAR_R || gear == GEAR_N || gear == GEAR_D || gear == GEAR_M || gear == GEAR_S
}
