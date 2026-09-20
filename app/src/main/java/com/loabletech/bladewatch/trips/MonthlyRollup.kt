package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/** Pre-aggregated monthly trip summary, keyed by year and month (1-12). */
class MonthlyRollup {

    @JvmField var year: Int = 0

    /** 1-12. */
    @JvmField var month: Int = 0
    @JvmField var tripCount: Int = 0
    @JvmField var totalDistanceKm: Double = 0.0
    @JvmField var totalDurationSeconds: Int = 0
    @JvmField var avgEfficiency: Double = 0.0
    @JvmField var totalEnergyKwh: Double = 0.0
    @JvmField var totalCost: Double = 0.0
    @JvmField var avgEnergyPerKm: Double = 0.0
    @JvmField var avgAnticipation: Int = 0
    @JvmField var avgSmoothness: Int = 0
    @JvmField var avgSpeedDiscipline: Int = 0
    @JvmField var avgEfficiencyScore: Int = 0
    @JvmField var avgConsistency: Int = 0

    /** Serialise for API responses. */
    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("year", year)
            json.put("month", month)
            json.put("tripCount", tripCount)
            json.put("totalDistanceKm", totalDistanceKm)
            json.put("totalDurationSeconds", totalDurationSeconds)
            json.put("avgEfficiency", avgEfficiency)
            json.put("totalEnergyKwh", totalEnergyKwh)
            json.put("totalCost", totalCost)
            json.put("avgEnergyPerKm", avgEnergyPerKm)
            json.put("avgAnticipation", avgAnticipation)
            json.put("avgSmoothness", avgSmoothness)
            json.put("avgSpeedDiscipline", avgSpeedDiscipline)
            json.put("avgEfficiencyScore", avgEfficiencyScore)
            json.put("avgConsistency", avgConsistency)
        } catch (e: Exception) {
            logger.warn("MonthlyRollup.toJson: failed to serialize: " + e.message)
        }
        return json
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("MonthlyRollup")
    }
}
