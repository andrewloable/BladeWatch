package net.bladewatch.app.monitor

import kotlin.math.max

/**
 * Data class for driving range information, carrying both the electric and the fuel range for
 * hybrid vehicles.
 *
 * @param elecRangeKmIn electric driving range in km
 * @param fuelRangeKmIn fuel driving range in km (0 if not available / pure EV)
 * @param fuelPercentIn fuel tank level % (NaN if not a PHEV or unavailable)
 */
class DrivingRangeData @JvmOverloads constructor(
    elecRangeKmIn: Int,
    fuelRangeKmIn: Int = 0,
    fuelPercentIn: Double = Double.NaN
) {

    /** Electric driving range in km. */
    @JvmField
    val elecRangeKm: Int = max(0, elecRangeKmIn)

    /** Fuel driving range in km (0 for a pure EV). */
    @JvmField
    val fuelRangeKm: Int = max(0, fuelRangeKmIn)

    /** Combined range. */
    @JvmField
    val totalRangeKm: Int = elecRangeKm + fuelRangeKm

    /** True if the total range is below [CRITICAL_RANGE_THRESHOLD]. */
    @JvmField
    val isCritical: Boolean = totalRangeKm < CRITICAL_RANGE_THRESHOLD

    /** True if the total range is below [LOW_RANGE_THRESHOLD]. */
    @JvmField
    val isLow: Boolean = totalRangeKm < LOW_RANGE_THRESHOLD

    /**
     * Fuel tank level % (PHEV only), NaN for BEVs or unknown. Only realistic percentages are
     * accepted; sentinel values (e.g. 255) are filtered upstream in BydDataCollector, but this
     * defends in depth.
     */
    @JvmField
    val fuelPercent: Double =
        if (fuelPercentIn >= 0 && fuelPercentIn <= 100) fuelPercentIn else Double.NaN

    @JvmField
    val timestamp: Long = System.currentTimeMillis()

    fun hasFuelPercent(): Boolean = !fuelPercent.isNaN()

    /** Whether the range is within valid bounds. */
    fun isValidRange(): Boolean =
        elecRangeKm in MIN_RANGE..MAX_RANGE && fuelRangeKm in MIN_RANGE..MAX_RANGE

    /** Status string for display. */
    fun getStatus(): String = when {
        isCritical -> "CRITICAL"
        isLow -> "LOW"
        else -> "OK"
    }

    /** Whether this is a pure EV (no fuel range). */
    fun isPureEV(): Boolean = fuelRangeKm == 0

    override fun toString(): String =
        "DrivingRangeData{" +
            "elecRangeKm=" + elecRangeKm +
            ", fuelRangeKm=" + fuelRangeKm +
            ", totalRangeKm=" + totalRangeKm +
            ", isLow=" + isLow +
            ", isCritical=" + isCritical +
            ", timestamp=" + timestamp +
            '}'

    companion object {
        const val MIN_RANGE = 0
        const val MAX_RANGE = 999

        /** km. */
        const val LOW_RANGE_THRESHOLD = 50

        /** km. */
        const val CRITICAL_RANGE_THRESHOLD = 20
    }
}
