package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONArray
import org.json.JSONObject

/**
 * Micro-moment analysis extracted from trip telemetry: launch profiles, coast-before-brake
 * events, and pedal-smoothness windows.
 */
class MicroMoments {

    @JvmField val launches: MutableList<LaunchProfile> = ArrayList()
    @JvmField val coastBrakeEvents: MutableList<CoastBrakeEvent> = ArrayList()
    @JvmField val smoothnessWindows: MutableList<PedalSmoothnessWindow> = ArrayList()

    // ==================== Aggregate metrics ====================

    /** Mean peak accel pedal % across all launches. */
    fun getAvgLaunchAggressiveness(): Double =
        if (launches.isEmpty()) 0.0
        else launches.sumOf { it.peakAccelPercent.toDouble() } / launches.size

    /** Mean coast gap in SECONDS across all coast-brake events. */
    fun getAvgCoastGapSeconds(): Double =
        if (coastBrakeEvents.isEmpty()) 0.0
        else (coastBrakeEvents.sumOf { it.coastGapMs.toDouble() } / coastBrakeEvents.size) / 1000.0

    /** Mean pedal smoothness (standard deviation) across all windows. */
    fun getAvgPedalSmoothness(): Double =
        if (smoothnessWindows.isEmpty()) 0.0
        else smoothnessWindows.sumOf { it.stdDev } / smoothnessWindows.size

    // ==================== Serialization ====================

    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("launches", JSONArray().also { a -> launches.forEach { a.put(it.toJson()) } })
            json.put(
                "coastBrakeEvents",
                JSONArray().also { a -> coastBrakeEvents.forEach { a.put(it.toJson()) } }
            )
            json.put(
                "smoothnessWindows",
                JSONArray().also { a -> smoothnessWindows.forEach { a.put(it.toJson()) } }
            )
        } catch (e: Exception) {
            logger.warn("MicroMoments.toJson: failed to serialize: " + e.message)
        }
        return json
    }

    /**
     * A launch: speed going from 0 to above 5 km/h, with the accel pedal curve for the first 10s.
     */
    class LaunchProfile {
        @JvmField var startTime: Long = 0
        @JvmField var peakAccelPercent: Int = 0

        /** Accel pedal % samples over the first 10 seconds. */
        @JvmField var accelCurve: IntArray = IntArray(0)

        fun toJson(): JSONObject {
            val json = JSONObject()
            try {
                json.put("startTime", startTime)
                json.put("peakAccelPercent", peakAccelPercent)
                json.put("accelCurve", JSONArray().also { a -> accelCurve.forEach { a.put(it) } })
            } catch (e: Exception) {
                logger.warn("MicroMoments.LaunchProfile.toJson: failed to serialize: " + e.message)
            }
            return json
        }

        companion object {
            @JvmStatic
            fun fromJson(json: JSONObject): LaunchProfile = LaunchProfile().apply {
                startTime = json.optLong("startTime", 0)
                peakAccelPercent = json.optInt("peakAccelPercent", 0)
                json.optJSONArray("accelCurve")?.let { curve ->
                    accelCurve = IntArray(curve.length()) { curve.optInt(it, 0) }
                }
            }
        }
    }

    /**
     * A coast-before-brake event: the accel pedal drops to 0, then the brake rises above 0.
     * Records how long the coast lasted and the speed when the brake was applied.
     */
    class CoastBrakeEvent {
        @JvmField var coastGapMs: Long = 0
        @JvmField var speedAtBrake: Int = 0

        fun toJson(): JSONObject {
            val json = JSONObject()
            try {
                json.put("coastGapMs", coastGapMs)
                json.put("speedAtBrake", speedAtBrake)
            } catch (e: Exception) {
                logger.warn("MicroMoments.CoastBrakeEvent.toJson: failed to serialize: " + e.message)
            }
            return json
        }

        companion object {
            @JvmStatic
            fun fromJson(json: JSONObject): CoastBrakeEvent = CoastBrakeEvent().apply {
                coastGapMs = json.optLong("coastGapMs", 0)
                speedAtBrake = json.optInt("speedAtBrake", 0)
            }
        }
    }

    /** The standard deviation of accel pedal % over one 10-second window. */
    class PedalSmoothnessWindow {
        @JvmField var startTime: Long = 0
        @JvmField var stdDev: Double = 0.0

        fun toJson(): JSONObject {
            val json = JSONObject()
            try {
                json.put("startTime", startTime)
                json.put("stdDev", stdDev)
            } catch (e: Exception) {
                logger.warn(
                    "MicroMoments.PedalSmoothnessWindow.toJson: failed to serialize: " + e.message
                )
            }
            return json
        }

        companion object {
            @JvmStatic
            fun fromJson(json: JSONObject): PedalSmoothnessWindow = PedalSmoothnessWindow().apply {
                startTime = json.optLong("startTime", 0)
                stdDev = json.optDouble("stdDev", 0.0)
            }
        }
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("MicroMoments")

        /** Parse from a JSON string. A malformed blob yields an EMPTY object, never null. */
        @JvmStatic
        fun fromJson(jsonStr: String?): MicroMoments {
            val mm = MicroMoments()
            if (jsonStr.isNullOrEmpty()) return mm
            try {
                val json = JSONObject(jsonStr)
                json.optJSONArray("launches")?.let { arr ->
                    for (i in 0 until arr.length()) {
                        mm.launches.add(LaunchProfile.fromJson(arr.getJSONObject(i)))
                    }
                }
                json.optJSONArray("coastBrakeEvents")?.let { arr ->
                    for (i in 0 until arr.length()) {
                        mm.coastBrakeEvents.add(CoastBrakeEvent.fromJson(arr.getJSONObject(i)))
                    }
                }
                json.optJSONArray("smoothnessWindows")?.let { arr ->
                    for (i in 0 until arr.length()) {
                        mm.smoothnessWindows.add(PedalSmoothnessWindow.fromJson(arr.getJSONObject(i)))
                    }
                }
            } catch (e: Exception) {
                logger.warn("MicroMoments.fromJson: failed to parse: " + e.message)
            }
            return mm
        }
    }
}
