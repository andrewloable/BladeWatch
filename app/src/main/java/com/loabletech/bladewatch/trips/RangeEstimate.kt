package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Result of a personalized range prediction. Contains the predicted range with confidence
 * interval bounds, the matched consumption bucket info, and the car's built-in range for
 * comparison.
 *
 * **Java interop.** Fields carry [JvmField] because `RangeEstimator` is Java and assigns them
 * directly; without it Kotlin would emit private fields behind getters and those assignments
 * would stop compiling.
 */
class RangeEstimate {

    @JvmField var predictedRangeKm: Double = 0.0
    @JvmField var lowerBoundKm: Double = 0.0
    @JvmField var upperBoundKm: Double = 0.0
    @JvmField var bucketKey: String? = null
    @JvmField var sampleCount: Int = 0
    @JvmField var builtInRangeKm: Int = 0

    // PHEV fuel leg (BladeWatch-fpdz.9). Reported SEPARATELY from the electric range and never
    // summed into it: they are drawn from different tanks and have different confidence, and a
    // combined number would hide which one is about to run out.
    // CANNOT_PREDICT (-1) when there is no learned fuel rate or no configured tank capacity.
    @JvmField var fuelRangeKm: Double = FuelConsumption.CANNOT_PREDICT
    @JvmField var fuelLitresPerKm: Double = FuelConsumption.CANNOT_PREDICT

    /** The car's own fuel range from the HAL, for comparison. 0 when unavailable. */
    @JvmField var builtInFuelRangeKm: Int = 0

    /** Serialize to JSON for API responses. */
    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("predictedRangeKm", predictedRangeKm)
            json.put("lowerBoundKm", lowerBoundKm)
            json.put("upperBoundKm", upperBoundKm)
            json.put("bucketKey", bucketKey ?: "")
            json.put("sampleCount", sampleCount)
            json.put("builtInRangeKm", builtInRangeKm)
            json.put("fuelRangeKm", fuelRangeKm)
            json.put("fuelLitresPerKm", fuelLitresPerKm)
            json.put("builtInFuelRangeKm", builtInFuelRangeKm)
        } catch (e: Exception) {
            logger.warn("RangeEstimate.toJson: failed to serialize: " + e.message)
        }
        return json
    }

    private companion object {
        private const val TAG = "RangeEstimate"
        private val logger = DaemonLogger.getInstance(TAG)
    }
}
