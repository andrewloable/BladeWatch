package net.bladewatch.app.trips

import kotlin.math.sqrt

/**
 * Aggregated consumption for one condition combination, used by `RangeEstimator` for
 * personalised range prediction.
 *
 * Bucket key format: `{speedProfile}_{tempBand}_{styleBracket}`, e.g. `suburban_mild_high`.
 */
class ConsumptionBucket {

    @JvmField var bucketKey: String? = null
    @JvmField var sampleCount: Int = 0

    /** Running sum, for the mean. */
    @JvmField var sumKwhPerKm: Double = 0.0

    /** Running sum of squares, for the standard deviation. */
    @JvmField var sumSquaredKwhPerKm: Double = 0.0

    /** Mean consumption rate in kWh/km. */
    fun getMean(): Double = if (sampleCount == 0) 0.0 else sumKwhPerKm / sampleCount

    /**
     * Standard deviation of the consumption rate, via `sqrt(E[X^2] - (E[X])^2)`.
     *
     * The variance is clamped at zero: that formula can produce a tiny negative value through
     * floating-point rounding, and `sqrt` of it would be NaN.
     */
    fun getStdDev(): Double {
        if (sampleCount < 2) return 0.0
        val mean = getMean()
        var variance = (sumSquaredKwhPerKm / sampleCount) - (mean * mean)
        if (variance < 0) variance = 0.0
        return sqrt(variance)
    }
}
