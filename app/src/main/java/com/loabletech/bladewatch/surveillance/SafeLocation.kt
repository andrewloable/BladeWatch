package net.bladewatch.app.surveillance

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject
import java.util.UUID

/**
 * A circular geofence zone where surveillance is suppressed. When the car is parked inside any
 * enabled safe zone, the camera pipeline never starts, saving 100% of the camera/GPU/encoder
 * resources.
 */
class SafeLocation {

    var id: String
        private set

    // Initialised here because Kotlin requires a backing field to have an initializer at the
    // declaration; both constructors assign through the setter, which is what sanitises.
    var name: String = "Unnamed"
        set(value) {
            field = sanitizeName(value)
        }

    var latitude: Double

    var longitude: Double

    /** 50-500m. The setter clamps, so both constructors get the clamp for free. */
    var radiusMeters: Int = 150
        set(value) {
            field = value.coerceIn(50, 500)
        }

    var isEnabled: Boolean

    var createdAt: Long
        private set

    constructor(name: String?, latitude: Double, longitude: Double, radiusMeters: Int) {
        this.id = UUID.randomUUID().toString().substring(0, 8)
        this.name = sanitizeName(name)
        this.latitude = latitude
        this.longitude = longitude
        this.radiusMeters = radiusMeters
        this.isEnabled = true
        this.createdAt = System.currentTimeMillis()
    }

    /** Deserialize from JSON. */
    constructor(json: JSONObject) {
        this.id = json.optString("id", UUID.randomUUID().toString().substring(0, 8))
        this.name = sanitizeName(json.optString("name", "Unnamed"))
        this.latitude = json.optDouble("lat", 0.0)
        this.longitude = json.optDouble("lng", 0.0)
        this.radiusMeters = json.optInt("radiusM", 150)
        this.isEnabled = json.optBoolean("enabled", true)
        this.createdAt = json.optLong("createdAt", System.currentTimeMillis())
    }

    /** Serialize to JSON. */
    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("id", id)
            json.put("name", name)
            json.put("lat", latitude)
            json.put("lng", longitude)
            json.put("radiusM", radiusMeters)
            json.put("enabled", isEnabled)
            json.put("createdAt", createdAt)
        } catch (ignored: Exception) {
            logger.warn("SafeLocation.toJson failed: " + ignored.message)
        }
        return json
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("SafeLocation")

        /** Strip HTML-injection chars and cap the length. */
        fun sanitizeName(name: String?): String {
            if (name == null || name.trim().isEmpty()) return "Unnamed"
            val cleaned = name.replace("<", "").replace(">", "").trim()
            if (cleaned.isEmpty()) return "Unnamed"
            return if (cleaned.length > 64) cleaned.substring(0, 64) else cleaned
        }
    }
}
