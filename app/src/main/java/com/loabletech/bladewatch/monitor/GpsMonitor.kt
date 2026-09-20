package net.bladewatch.app.monitor

import android.content.Context

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.surveillance.SafeLocationManager

import org.json.JSONObject

import java.io.File

/**
 * GPS Monitor - Receives location updates from LocationSidecarService via IPC.
 *
 * Flow: LocationSidecarService → IPC (port 19877) → SurveillanceIpcServer → GpsMonitor.updateFromIpc()
 *
 * Cache locations (daemon UID 2000 writes to these):
 * 1. /data/local/tmp/gps_cache.json (primary - daemon can write here)
 *
 * Note: App data directory (/data/data/net.bladewatch.app/) is NOT writable by daemon (UID 2000).
 * The LocationSidecarService (app UID) handles its own cache in app data directory.
 *
 * On startup, loads cached GPS for immediate availability.
 */
class GpsMonitor private constructor() {

    @Volatile
    var latitude: Double = 0.0
        private set

    @Volatile
    var longitude: Double = 0.0
        private set

    @Volatile
    var speed: Float = 0.0f
        private set

    @Volatile
    var heading: Float = 0.0f
        private set

    @Volatile
    var accuracy: Float = 0.0f
        private set

    @Volatile
    var altitude: Double = 0.0
        private set

    @Volatile
    var lastUpdate: Long = 0
        private set

    @Volatile
    var isRunning: Boolean = false
        private set

    @Volatile
    private var loadedFromCache = false

    @Volatile
    private var lastLoggedAt: Long = 0

    fun init(ctx: Context?) {
        // Load cached GPS on init - try multiple locations
        loadFromCache()
        CameraDaemon.log(
            TAG + ": Initialized (IPC mode)" +
                if (hasLocation()) {
                    " - cached: $latitude, $longitude (loadedFromCache=$loadedFromCache)"
                } else {
                    " - no cached location"
                }
        )
    }

    fun start() {
        if (isRunning) return
        isRunning = true

        // Start the sidecar service
        try {
            Runtime.getRuntime().exec(START_CMD)
            CameraDaemon.log("$TAG: Sidecar service started")
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": Failed to start sidecar: " + e.message)
        }
    }

    /** Called by SurveillanceIpcServer when GPS update arrives via IPC. */
    fun updateFromIpc(
        lat: Double,
        lng: Double,
        speed: Float,
        heading: Float,
        accuracy: Float,
        time: Long,
        altitude: Double
    ) {
        // Reject invalid coordinates (0,0 is in the ocean, not a real location)
        if (lat == 0.0 && lng == 0.0) {
            return
        }

        latitude = lat
        longitude = lng
        this.speed = speed
        this.heading = heading
        this.accuracy = accuracy
        this.altitude = altitude
        lastUpdate = time
        loadedFromCache = false // We have live data now

        // Persist to cache file
        saveToCache()

        // SOTA: Notify SafeLocationManager for geofence checks
        try {
            SafeLocationManager.getInstance().onLocationUpdate(lat, lng)
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": SafeLocationManager update failed: " + e.message)
        }

        // Log periodically — once every LOG_INTERVAL_MS at most.
        // The previous `currentTimeMillis() % 10000 < 2000` trick fired
        // whenever a 2-second IPC update happened to land inside a fixed
        // 2s window, which produced bursts of identical log lines.
        val now = System.currentTimeMillis()
        if (hasLocation() && now - lastLoggedAt >= LOG_INTERVAL_MS) {
            lastLoggedAt = now
            CameraDaemon.log("$TAG: GPS: $lat, $lng (speed=$speed" + "m/s)")
        }
    }

    private fun saveToCache() {
        // Only save if we have a valid location
        if (!hasLocation()) return

        try {
            val json = JSONObject()
            json.put("lat", latitude)
            json.put("lng", longitude)
            json.put("speed", speed)
            json.put("heading", heading)
            json.put("accuracy", accuracy)
            json.put("altitude", altitude)
            json.put("time", lastUpdate)

            // Save to primary cache (daemon tmp) - daemon UID 2000 can write here
            //
            // Note: Cannot write to app data directory from daemon (different UID)
            // LocationSidecarService handles its own cache in app data directory
            saveToCacheFile(CACHE_FILE, json.toString())
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": Failed to save GPS cache: " + e.message)
        }
    }

    private fun saveToCacheFile(path: String, content: String) {
        try {
            // Ensure parent directory exists
            val file = File(path)
            val parent = file.parentFile
            if (parent != null && !parent.exists()) {
                parent.mkdirs()
            }

            // Atomic write
            val tmp = File("$path.tmp")
            tmp.writeText(content)
            if (!tmp.renameTo(file)) {
                // Fallback: direct write if rename fails
                file.writeText(content)
                tmp.delete()
            }
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": Cache file write failed: " + e.message)
        }
    }

    private fun loadFromCache() {
        // Try primary cache first (daemon tmp)
        if (loadFromCacheFile(CACHE_FILE)) {
            CameraDaemon.log("$TAG: Loaded GPS from primary cache: $latitude, $longitude")
            loadedFromCache = true
            return
        }

        // Try secondary cache (app data directory - written by LocationSidecarService)
        if (loadFromCacheFile(CACHE_FILE_APP)) {
            CameraDaemon.log("$TAG: Loaded GPS from app cache: $latitude, $longitude")
            loadedFromCache = true
            return
        }

        CameraDaemon.log("$TAG: No GPS cache found at $CACHE_FILE or $CACHE_FILE_APP")
    }

    private fun loadFromCacheFile(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) {
                return false
            }

            val json = JSONObject(file.readText())
            val lat = json.optDouble("lat", 0.0)
            val lng = json.optDouble("lng", 0.0)

            // Always use cached location if valid — better than nothing
            // Fresh IPC updates from sidecar will overwrite this
            if (lat != 0.0 || lng != 0.0) {
                latitude = lat
                longitude = lng
                speed = json.optDouble("speed", 0.0).toFloat()
                heading = json.optDouble("heading", 0.0).toFloat()
                accuracy = json.optDouble("accuracy", 0.0).toFloat()
                altitude = json.optDouble("altitude", 0.0)
                lastUpdate = json.optLong("time", 0)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": Failed to load GPS cache: " + e.message)
            false
        }
    }

    fun stop() {
        isRunning = false
        CameraDaemon.log("$TAG: Stopped")
    }

    // ==================== PUBLIC GETTERS ====================

    fun getProvider(): String = "sidecar"

    fun isMoving(): Boolean = speed > 1.0f

    fun hasLocation(): Boolean = latitude != 0.0 || longitude != 0.0

    fun getLocationJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("lat", latitude)
            json.put("lng", longitude)
            json.put("speed", speed)
            json.put("heading", heading)
            json.put("accuracy", accuracy)
            json.put("altitude", altitude)
            json.put("lastUpdate", lastUpdate)
            json.put("provider", "sidecar")
            json.put("isMoving", isMoving())
            json.put("hasLocation", hasLocation())

            // Add staleness indicator - location is stale if no update in 30 seconds
            val ageMs = System.currentTimeMillis() - lastUpdate
            json.put("ageMs", ageMs)
            json.put("isStale", ageMs > 30000)
            // Cached = no update in 60s OR loaded from cache file
            json.put("isCached", ageMs > 60000 || loadedFromCache)
            // Explicitly indicate if loaded from persistent cache
            json.put("loadedFromCache", loadedFromCache)
        } catch (e: Exception) {
            CameraDaemon.log(TAG + ": Failed to create location JSON: " + e.message)
        }
        return json
    }

    fun getGoogleMapsUrl(): String? {
        if (!hasLocation()) return null
        return "https://www.google.com/maps/dir/?api=1&destination=" +
            latitude + "," + longitude + "&travelmode=driving"
    }

    companion object {
        private const val TAG = "GpsMonitor"

        // Primary cache file (daemon uid 2000 can write to /data/local/tmp)
        private const val CACHE_FILE = "/data/local/tmp/gps_cache.json"

        // Secondary cache file (app data directory - read-only for daemon,
        // written by LocationSidecarService)
        private const val CACHE_FILE_APP =
            "/data/data/net.bladewatch.app/files/gps_cache.json"

        // Command to start the sidecar service
        private const val START_CMD =
            "am start-foreground-service -n net.bladewatch.app/.services.LocationSidecarService"

        private const val LOG_INTERVAL_MS = 30_000L

        @Volatile
        private var instance: GpsMonitor? = null

        @JvmStatic
        fun getInstance(): GpsMonitor =
            instance ?: synchronized(this) {
                instance ?: GpsMonitor().also { instance = it }
            }
    }
}
