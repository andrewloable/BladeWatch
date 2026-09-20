package net.bladewatch.app.telemetry

/**
 * Immutable point-in-time telemetry reading. Thread-safe by design — every field is read-only,
 * and the seatbelt array is defensively copied on the way in.
 */
class TelemetrySnapshot @JvmOverloads constructor(
    @JvmField val speedKmh: Int,
    /** 0-100 */
    @JvmField val accelPedalPercent: Int,
    /** 0-100 */
    @JvmField val brakePedalPercent: Int,
    @JvmField val brakePedalPressed: Boolean,
    /** 1-6, matching BYDAutoGearboxDevice constants. */
    @JvmField val gearMode: Int,
    @JvmField val leftTurnSignal: Boolean,
    @JvmField val rightTurnSignal: Boolean,
    seatbeltBuckled: BooleanArray?,
    @JvmField val timestampMs: Long,
    /**
     * False means no GPS fix yet — the overlay omits the coordinate line rather than burning
     * 0,0 into the recording.
     */
    @JvmField val hasGps: Boolean = false,
    @JvmField val latitude: Double = 0.0,
    @JvmField val longitude: Double = 0.0,
) {

    /** Indexed by seat position. Copied on construction to preserve immutability. */
    @JvmField
    val seatbeltBuckled: BooleanArray = seatbeltBuckled?.clone() ?: BooleanArray(0)

    /** Gear mode as a display character: 1→P, 2→R, 3→N, 4→D, 5→M, 6→S, otherwise '?'. */
    fun getGearChar(): Char = when (gearMode) {
        1 -> 'P'
        2 -> 'R'
        3 -> 'N'
        4 -> 'D'
        5 -> 'M'
        6 -> 'S'
        else -> '?'
    }

    /** Colour for the current gear mode. Dark values, because the overlay is on white. */
    fun getGearColor(): Int = when (gearMode) {
        1 -> 0xFF666666.toInt() // P -> dark gray
        2 -> 0xFFCC0000.toInt() // R -> dark red
        3 -> 0xFF0066CC.toInt() // N -> blue
        4 -> 0xFF008800.toInt() // D -> dark green
        5 -> 0xFF8800CC.toInt() // M -> purple
        6 -> 0xFFCC6600.toInt() // S -> orange
        else -> 0xFF000000.toInt() // unknown -> black
    }

    companion object {
        /** A safe default: stationary, in Park, signals off, both belts buckled. */
        @JvmStatic
        fun createDefault(): TelemetrySnapshot = TelemetrySnapshot(
            speedKmh = 0,
            accelPedalPercent = 0,
            brakePedalPercent = 0,
            brakePedalPressed = false,
            gearMode = 1, // P
            leftTurnSignal = false,
            rightTurnSignal = false,
            seatbeltBuckled = booleanArrayOf(true, true), // driver + passenger
            timestampMs = System.currentTimeMillis(),
        )
    }
}
