package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Immutable single telemetry reading. Thread-safe by design — every field is read-only.
 *
 * Serialised with COMPACT one- and two-letter keys, because these are written per sample into
 * `.jsonl.gz` trip files where the key names would otherwise dominate the payload.
 */
class TelemetrySample(
    @JvmField val timestampMs: Long,
    @JvmField val speedKmh: Int,
    /** 0-100 */
    @JvmField val accelPedalPercent: Int,
    /** 0-100 */
    @JvmField val brakePedalPercent: Int,
    @JvmField val brakePedalPressed: Boolean,
    /** 1=P, 2=R, 3=N, 4=D, 5=M, 6=S */
    @JvmField val gearMode: Int,
    @JvmField val lat: Double,
    @JvmField val lon: Double,
    @JvmField val altitude: Double,
) {

    /** Serialise with the compact storage keys: t, s, a, b, bp, g, la, lo, al. */
    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("t", timestampMs)
            json.put("s", speedKmh)
            json.put("a", accelPedalPercent)
            json.put("b", brakePedalPercent)
            json.put("bp", brakePedalPressed)
            json.put("g", gearMode)
            json.put("la", lat)
            json.put("lo", lon)
            json.put("al", altitude)
        } catch (e: Exception) {
            logger.warn("TelemetrySample.toJson: failed to serialize: " + e.message)
        }
        return json
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("TelemetrySample")

        /** Deserialise from the compact form. Defaults match a stationary sample in Park. */
        @JvmStatic
        fun fromJson(json: JSONObject): TelemetrySample = TelemetrySample(
            json.optLong("t", 0),
            json.optInt("s", 0),
            json.optInt("a", 0),
            json.optInt("b", 0),
            json.optBoolean("bp", false),
            json.optInt("g", 1),
            json.optDouble("la", 0.0),
            json.optDouble("lo", 0.0),
            json.optDouble("al", 0.0)
        )
    }
}
