package net.bladewatch.app.surveillance

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.GpsMonitor

import org.json.JSONArray
import org.json.JSONObject

import java.io.File
import java.util.concurrent.CopyOnWriteArrayList

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToLong
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * SafeLocationManager — Singleton geofence manager.
 *
 * Responsibilities:
 * 1. CRUD for safe location zones (max 10)
 * 2. Haversine distance check against current GPS
 * 3. Zone transition detection (enter/leave) with camera lifecycle control
 * 4. Persistence to config file (cross-UID accessible)
 *
 * GPS Integration:
 * - Called by GpsMonitor.updateFromIpc() on every location update (~2s)
 * - Caches result to avoid redundant Haversine math
 * - On zone transition: enables/disables surveillance via CameraDaemon
 *
 * Thread Safety:
 * - CopyOnWriteArrayList for zone list (reads >> writes)
 * - volatile for cached state
 */
class SafeLocationManager private constructor() {

    private val zones = CopyOnWriteArrayList<SafeLocation>()

    @Volatile
    var isFeatureEnabled = true
        private set

    @Volatile
    private var cachedInSafeZone = false

    @Volatile
    private var cachedZoneName: String? = null

    @Volatile
    private var cachedDistanceM = Double.MAX_VALUE

    /** Load zones from config file. Call once at daemon startup. */
    fun init() {
        loadFromFile()
        CameraDaemon.log(
            TAG + ": Initialized with " + zones.size + " zones, feature=" + isFeatureEnabled
        )
    }

    // ========================================================================
    // ZONE CRUD
    // ========================================================================

    fun addZone(name: String, lat: Double, lng: Double, radiusM: Int): SafeLocation? {
        if (zones.size >= MAX_ZONES) {
            CameraDaemon.log("$TAG: Max zones reached ($MAX_ZONES)")
            return null
        }
        val zone = SafeLocation(name, lat, lng, radiusM)
        zones.add(zone)
        saveToFile()
        // Re-evaluate immediately — maybe we just added a zone we're inside
        reevaluateZone()
        CameraDaemon.log("$TAG: Added zone '$name' at $lat,$lng r=$radiusM" + "m")
        return zone
    }

    fun updateZone(id: String, updates: JSONObject): Boolean {
        for (zone in zones) {
            if (zone.id == id) {
                if (updates.has("name")) zone.name = updates.optString("name")
                if (updates.has("lat")) zone.latitude = updates.optDouble("lat")
                if (updates.has("lng")) zone.longitude = updates.optDouble("lng")
                if (updates.has("radiusM")) zone.radiusMeters = updates.optInt("radiusM")
                if (updates.has("enabled")) zone.isEnabled = updates.optBoolean("enabled")
                saveToFile()
                reevaluateZone()
                return true
            }
        }
        return false
    }

    fun removeZone(id: String): Boolean {
        for (zone in zones) {
            if (zone.id == id) {
                zones.remove(zone)
                saveToFile()
                reevaluateZone()
                CameraDaemon.log(TAG + ": Removed zone '" + zone.name + "'")
                return true
            }
        }
        return false
    }

    fun getZones(): List<SafeLocation> = ArrayList(zones)

    fun setFeatureEnabled(enabled: Boolean) {
        isFeatureEnabled = enabled
        saveToFile()
        reevaluateZone()
        CameraDaemon.log(TAG + ": Feature " + (if (enabled) "enabled" else "disabled"))
    }

    // ========================================================================
    // GEOFENCE CHECK — Haversine
    // ========================================================================

    /**
     * Check if current GPS position is inside any enabled safe zone.
     * Uses cached result — updated on every GPS tick via [onLocationUpdate].
     */
    val isInSafeZone: Boolean get() = isFeatureEnabled && cachedInSafeZone

    val currentZoneName: String? get() = cachedZoneName

    val distanceToNearestZone: Double get() = cachedDistanceM

    /**
     * Called by GpsMonitor on every IPC location update (~2s).
     * Performs Haversine check and triggers zone transitions.
     */
    fun onLocationUpdate(lat: Double, lng: Double) {
        if (!isFeatureEnabled || zones.isEmpty()) {
            if (cachedInSafeZone) {
                // Feature was disabled or all zones removed while in zone
                cachedInSafeZone = false
                cachedZoneName = null
                cachedDistanceM = Double.MAX_VALUE
                onLeftSafeZone()
            }
            return
        }

        val wasInZone = cachedInSafeZone
        var nowInZone = false
        var zoneName: String? = null
        var nearestDist = Double.MAX_VALUE

        for (zone in zones) {
            if (!zone.isEnabled) continue

            val dist = haversine(lat, lng, zone.latitude, zone.longitude)
            if (dist < nearestDist) {
                nearestDist = dist
            }
            if (dist <= zone.radiusMeters) {
                nowInZone = true
                zoneName = zone.name
                nearestDist = dist
                break // Inside at least one zone — that's enough
            }
        }

        cachedInSafeZone = nowInZone
        cachedZoneName = zoneName
        cachedDistanceM = nearestDist

        // Zone transitions
        if (!wasInZone && nowInZone) {
            onEnteredSafeZone(zoneName)
        } else if (wasInZone && !nowInZone) {
            onLeftSafeZone()
        }
    }

    /** Force re-evaluation with current GPS (after zone add/remove/toggle). */
    private fun reevaluateZone() {
        val gps = GpsMonitor.getInstance()
        if (gps.hasLocation()) {
            onLocationUpdate(gps.latitude, gps.longitude)
        }
    }

    // ========================================================================
    // ZONE TRANSITIONS — Camera Lifecycle Control
    // ========================================================================

    private fun onEnteredSafeZone(zoneName: String?) {
        CameraDaemon.log("$TAG: ENTERED safe zone '$zoneName' — suppressing surveillance")
        // Only act when the pipeline is actually in SURVEILLANCE mode. The
        // pipeline is shared with CONTINUOUS / DRIVE_MODE / PROXIMITY_GUARD
        // recording — driving home with ACC ON + CONTINUOUS recording would
        // otherwise have its recording torn down here.
        val pipeline = CameraDaemon.getGpuPipeline()
        if (pipeline != null && pipeline.isSurveillanceMode) {
            // Don't call disableSurveillance() through CameraDaemon — that clears
            // the user's preference. Just disable the sentry component and stop
            // the pipeline. The preference stays enabled so surveillance
            // auto-restarts when leaving the zone or on the next ACC OFF.
            pipeline.disableSurveillance()
            pipeline.stop()
        }
        // Either way, mark the suppression flag: when ACC eventually turns off and
        // would have armed sentry, CameraDaemon's ACC-OFF handler skips it.
        CameraDaemon.setSafeZoneSuppressed(true)
    }

    private fun onLeftSafeZone() {
        CameraDaemon.log("$TAG: LEFT safe zone — resuming surveillance")
        if (CameraDaemon.isSafeZoneSuppressed()) {
            CameraDaemon.setSafeZoneSuppressed(false)
            // Check persisted config — only restart if user actually wants surveillance
            if (UnifiedConfigManager.isSurveillanceEnabled()) {
                CameraDaemon.enableSurveillance()
            }
        }
    }

    // ========================================================================
    // PERSISTENCE
    // ========================================================================

    private fun saveToFile() {
        try {
            val root = JSONObject()
            root.put("enabled", isFeatureEnabled)
            val arr = JSONArray()
            for (z in zones) {
                arr.put(z.toJson())
            }
            root.put("zones", arr)
            val content = root.toString(2)

            val tmp = File("$CONFIG_FILE.tmp")
            tmp.writeText(content)
            val target = File(CONFIG_FILE)
            if (!tmp.renameTo(target)) {
                // Fallback: direct write
                target.writeText(content)
                tmp.delete()
            }
            target.setReadable(true, false)
            target.setWritable(true, false)
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": Failed to save: " + e.message)
        }
    }

    private fun loadFromFile() {
        try {
            val file = File(CONFIG_FILE)
            if (!file.exists()) return

            val root = JSONObject(file.readText())
            isFeatureEnabled = root.optBoolean("enabled", true)
            val arr = root.optJSONArray("zones")
            if (arr != null) {
                zones.clear()
                var i = 0
                while (i < arr.length() && i < MAX_ZONES) {
                    zones.add(SafeLocation(arr.getJSONObject(i)))
                    i++
                }
            }
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": Failed to load: " + e.message)
        }
    }

    // ========================================================================
    // STATUS (for API responses)
    // ========================================================================

    val statusJson: JSONObject get() {
        val json = JSONObject()
        try {
            json.put("featureEnabled", isFeatureEnabled)
            json.put("inSafeZone", cachedInSafeZone)
            json.put("currentZone", cachedZoneName)
            json.put("nearestDistanceM", cachedDistanceM.roundToLong())
            json.put("zoneCount", zones.size)

            val gps = GpsMonitor.getInstance()
            json.put("hasGps", gps.hasLocation())
            if (gps.hasLocation()) {
                json.put("lat", gps.latitude)
                json.put("lng", gps.longitude)
                json.put("accuracy", gps.accuracy)
            }

            val arr = JSONArray()
            for (z in zones) arr.put(z.toJson())
            json.put("zones", arr)
        } catch (ignored: Exception) {
            logger.warn("SafeLocationManager.getStatusJson failed: " + ignored.message)
        }
        return json
    }

    companion object {
        private const val TAG = "SafeLocation"
        private val logger = DaemonLogger.getInstance(TAG)
        private const val CONFIG_FILE = "/data/local/tmp/safe_locations.json"
        private const val MAX_ZONES = 10
        private const val EARTH_RADIUS_M = 6_371_000.0

        @Volatile
        private var instance: SafeLocationManager? = null

        @JvmStatic
        fun getInstance(): SafeLocationManager =
            instance ?: synchronized(SafeLocationManager::class.java) {
                instance ?: SafeLocationManager().also { instance = it }
            }

        /**
         * Calculate great-circle distance between two GPS coordinates.
         * @return distance in meters
         */
        @JvmStatic
        fun haversine(lat1: Double, lng1: Double, lat2: Double, lng2: Double): Double {
            val dLat = Math.toRadians(lat2 - lat1)
            val dLng = Math.toRadians(lng2 - lng1)
            val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLng / 2) * sin(dLng / 2)
            val c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return EARTH_RADIUS_M * c
        }
    }
}
