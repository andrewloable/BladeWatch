package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * The five Driving DNA axis scores. Each is an integer in [0, 100] where 100 is optimal.
 */
class DnaScores {

    @JvmField var anticipation: Int = 0
    @JvmField var smoothness: Int = 0
    @JvmField var speedDiscipline: Int = 0
    @JvmField var efficiency: Int = 0
    @JvmField var consistency: Int = 0

    /** The overall score: the mean of all five axes. */
    fun getOverall(): Int =
        (anticipation + smoothness + speedDiscipline + efficiency + consistency) / 5

    /** Serialise for API responses. */
    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("anticipation", anticipation)
            json.put("smoothness", smoothness)
            json.put("speedDiscipline", speedDiscipline)
            json.put("efficiency", efficiency)
            json.put("consistency", consistency)
            json.put("overall", getOverall())
        } catch (e: Exception) {
            logger.warn("DnaScores.toJson: failed to serialize: " + e.message)
        }
        return json
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("DnaScores")
    }
}
