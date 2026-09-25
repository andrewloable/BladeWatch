package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/** Pre-aggregated weekly trip summary, keyed by ISO year and week number. */
class WeeklyRollup {

    @JvmField var year: Int = 0

    /** ISO week. */
    @JvmField var weekNumber: Int = 0
    @JvmField var tripCount: Int = 0
    @JvmField var totalDistanceKm: Double = 0.0
    @JvmField var totalDurationSeconds: Int = 0
    @JvmField var avgEfficiency: Double = 0.0

    /** Sum of energyUsedKwh across trips. */
    @JvmField var totalEnergyKwh: Double = 0.0

    /** Sum of tripCost across trips. */
    @JvmField var totalCost: Double = 0.0

    /** Average kWh/km. */
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
            json.put("weekNumber", weekNumber)
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
            logger.warn("WeeklyRollup.toJson: failed to serialize: " + e.message)
        }
        return json
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("WeeklyRollup")

        /**
         * One rollup over exactly [trips] (BladeWatch-jkuz): the sums add up, the averages are
         * plain per-trip means -- the same weighting updateWeeklyRollup's running average uses.
         * Year and week are left 0: this covers a window of days, not a calendar week.
         */
        @JvmStatic
        fun ofTrips(trips: List<TripRecord>): WeeklyRollup {
            val r = WeeklyRollup()
            if (trips.isEmpty()) return r
            val n = trips.size
            fun mean(f: (TripRecord) -> Double) = trips.sumOf(f) / n
            r.tripCount = n
            r.totalDistanceKm = trips.sumOf { it.distanceKm }
            r.totalDurationSeconds = trips.sumOf { it.durationSeconds }
            r.totalEnergyKwh = trips.sumOf { it.getEnergyUsedKwh() }
            r.totalCost = trips.sumOf { it.tripCost }
            r.avgEfficiency = mean { it.efficiencySocPerKm }
            r.avgEnergyPerKm = mean { it.energyPerKm }
            r.avgAnticipation = mean { it.anticipationScore.toDouble() }.toInt()
            r.avgSmoothness = mean { it.smoothnessScore.toDouble() }.toInt()
            r.avgSpeedDiscipline = mean { it.speedDisciplineScore.toDouble() }.toInt()
            r.avgEfficiencyScore = mean { it.efficiencyScore.toDouble() }.toInt()
            r.avgConsistency = mean { it.consistencyScore.toDouble() }.toInt()
            return r
        }
    }
}
