package net.bladewatch.app.trips

import android.hardware.bydauto.instrument.BYDAutoInstrumentDevice
import java.io.File
import java.util.regex.Pattern
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToLong
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.GpsMonitor
import net.bladewatch.app.monitor.VehicleDataMonitor
import net.bladewatch.app.storage.StorageManager
import org.json.JSONArray
import org.json.JSONObject

/**
 * Standalone handler for `/api/trips` HTTP requests (including the sub-paths below).
 *
 * Processes trip analytics API endpoints and returns [JSONObject] responses. Called from
 * HttpServer's serve() method when the URI starts with "/api/trips".
 */
class TripApiHandler(private val manager: TripAnalyticsManager) {

    /**
     * Handle an `/api/trips` request, including every sub-path.
     *
     * @param uri the full request URI (e.g. "/api/trips?days=7", "/api/trips/123/telemetry")
     * @param method HTTP method (GET, POST, DELETE)
     * @param params query parameters parsed from the URI (may be empty or null)
     * @param body request body for POST requests, may be null
     * @return a response with a "success" field; error responses include "_status"
     */
    fun handleRequest(
        uri: String,
        method: String?,
        params: Map<String, String>?,
        body: String?,
    ): JSONObject {
        return try {
            // Strip the query string from the URI for path matching.
            val path = if (uri.contains("?")) uri.substringBefore("?") else uri

            val q = HashMap<String, String>()
            if (params != null) q.putAll(params)
            if (uri.contains("?")) {
                parseQueryParams(uri.substringAfter("?"), q)
            }

            when {
                path == "/api/trips/summary" && method == "GET" -> handleGetSummary(q)
                path == "/api/trips/dna" && method == "GET" -> handleGetDna(q)
                path == "/api/trips/range" && method == "GET" -> handleGetRange()

                path == "/api/trips/config" && method == "GET" -> handleGetConfig()
                path == "/api/trips/config" && method == "POST" -> handlePostConfig(body)

                path == "/api/trips/storage" && method == "GET" -> handleGetStorage()
                path == "/api/trips/storage" && method == "POST" -> handlePostStorage(body)

                // Reconcile the trips DB with telemetry files on disk (prune missing,
                // re-index orphans; no recompute).
                path == "/api/trips/sync" && method == "POST" -> manager.reconcileTrips()

                else -> routeById(path, method) ?: run {
                    if ((path == "/api/trips" || path == "/api/trips/") && method == "GET") {
                        handleListTrips(q)
                    } else {
                        errorResponse("Not found", 404)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Error handling request: $uri", e)
            errorResponse("Internal error: " + e.message, 500)
        }
    }

    /** Routes that carry a numeric trip id, or null when the path matches none of them. */
    private fun routeById(path: String, method: String?): JSONObject? {
        TRIP_TELEMETRY_PATTERN.matcher(path).let {
            if (it.matches() && method == "GET") return handleGetTelemetry(it.group(1)!!.toLong())
        }
        TRIP_SIMILAR_PATTERN.matcher(path).let {
            if (it.matches() && method == "GET") {
                return handleGetSimilarTrips(it.group(1)!!.toLong())
            }
        }
        TRIP_GPS_PATTERN.matcher(path).let {
            if (it.matches() && method == "GET") return handleGetGpsTrace(it.group(1)!!.toLong())
        }
        TRIP_ID_PATTERN.matcher(path).let {
            if (it.matches()) {
                val tripId = it.group(1)!!.toLong()
                if (method == "GET") return handleGetTrip(tripId)
                if (method == "DELETE") return handleDeleteTrip(tripId)
            }
        }
        return null
    }

    // ==================== ENDPOINT HANDLERS ====================

    /**
     * GET /api/trips — list trips. Query: days (default 7), limit (default 50), offset
     * (default 0).
     *
     * Pagination is via offset: a client doing Load More keeps the same `days` and increments
     * `offset` by the size of the previous response. A short page (length < limit) signals
     * end-of-data.
     */
    private fun handleListTrips(params: Map<String, String>): JSONObject {
        val days = getIntParam(params, "days", 7)
        val limit = getIntParam(params, "limit", 50)
        val offset = getIntParam(params, "offset", 0)

        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)

        val tripsArray = JSONArray()
        for (trip in db.getTrips(days, limit, offset)) {
            enrichTripEnergy(trip)
            tripsArray.put(trip.toSummaryJson())
        }

        return successResponse("trips", tripsArray, "trips list")
    }

    /** GET /api/trips/{id} — single trip with micro-moments. */
    private fun handleGetTrip(tripId: Long): JSONObject {
        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)
        val trip = db.getTrip(tripId) ?: return errorResponse("Trip not found", 404)

        enrichTripEnergy(trip)
        return successResponse("trip", trip.toJson(), "trip detail")
    }

    /** GET /api/trips/{id}/telemetry — decompress and return the telemetry array. */
    private fun handleGetTelemetry(tripId: Long): JSONObject {
        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)
        val trip = db.getTrip(tripId) ?: return errorResponse("Trip not found", 404)

        val telemetryFile = existingTelemetryFile(trip)
            ?: return errorResponse("Telemetry data unavailable", 410)

        val telemetryArray = JSONArray()
        for (sample in TelemetryStore.readFromFile(telemetryFile)) {
            telemetryArray.put(sample.toJson())
        }

        return successResponse("telemetry", telemetryArray, "telemetry")
    }

    /** DELETE /api/trips/{id} — delete the trip record and its telemetry file. */
    private fun handleDeleteTrip(tripId: Long): JSONObject {
        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)
        val trip = db.getTrip(tripId) ?: return errorResponse("Trip not found", 404)

        trip.telemetryFilePath?.takeIf { it.isNotEmpty() }?.let { path ->
            val telemetryFile = File(path)
            if (telemetryFile.exists()) {
                if (telemetryFile.delete()) {
                    logger.info("Deleted telemetry file: ${telemetryFile.name}")
                } else {
                    logger.warn("Failed to delete telemetry file: ${telemetryFile.name}")
                }
            }
        }

        if (!db.deleteTrip(tripId)) {
            return errorResponse("Failed to delete trip", 500)
        }

        val response = JSONObject()
        try {
            response.put("success", true)
        } catch (e: Exception) {
            logger.error("Error building delete response", e)
        }
        return response
    }

    /** GET /api/trips/summary — weekly rollup. Query: days (default 7). */
    private fun handleGetSummary(params: Map<String, String>): JSONObject {
        val days = getIntParam(params, "days", 7)
        // Convert days to approximate weeks, rounding up.
        val weeks = max(1, (days + 6) / 7)

        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)

        val rollupsArray = JSONArray()
        for (rollup in db.getRecentWeeklyRollups(weeks)) {
            rollupsArray.put(rollup.toJson())
        }

        return successResponse("summary", rollupsArray, "summary")
    }

    /** GET /api/trips/dna — average DNA scores. Query: days (default 30). */
    private fun handleGetDna(params: Map<String, String>): JSONObject {
        val days = getIntParam(params, "days", 30)
        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)

        val scores = db.getAverageDna(days)
        return successResponse("dna", scores?.toJson() ?: JSONObject.NULL, "DNA")
    }

    /**
     * GET /api/trips/range — personalized range estimate. Reads current SoC and temperature
     * from VehicleDataMonitor, speed from GpsMonitor, and DNA from the database.
     */
    private fun handleGetRange(): JSONObject {
        val estimator = manager.getRangeEstimator()
        val db = manager.getDatabase()

        if (estimator == null || db == null) return notEnoughDataResponse()

        return try {
            var currentSoc = 0.0
            try {
                VehicleDataMonitor.getInstance().getBatterySoc()?.let {
                    currentSoc = it.socPercent
                }
            } catch (e: Exception) {
                logger.debug("Could not read SoC: " + e.message)
            }

            var currentSpeed = 0.0
            try {
                currentSpeed = GpsMonitor.getInstance().getSpeed() * 3.6 // m/s to km/h
            } catch (e: Exception) {
                logger.debug("Could not read speed: " + e.message)
            }

            var extTemp = 20 // Default mild temperature
            try {
                BYDAutoInstrumentDevice.getInstance(null)?.let {
                    extTemp = it.getOutCarTemperature()
                }
            } catch (e: Exception) {
                logger.debug("Could not read external temp: " + e.message)
            }

            var dnaOverall = 50 // Default mid-range
            try {
                db.getAverageDna(30)?.let { dnaOverall = it.getOverall() }
            } catch (e: Exception) {
                logger.debug("Could not read DNA scores: " + e.message)
            }

            val estimate = estimator.estimate(currentSoc, currentSpeed, extTemp, dnaOverall)
                ?: return notEnoughDataResponse()

            // Add the car's built-in range for comparison.
            try {
                VehicleDataMonitor.getInstance().getDrivingRange()?.let {
                    estimate.builtInRangeKm = it.elecRangeKm
                }
            } catch (e: Exception) {
                logger.debug("Could not read built-in range: " + e.message)
            }

            val response = JSONObject()
            response.put("success", true)
            response.put("range", estimate.toJson())
            response
        } catch (e: Exception) {
            logger.error("Error computing range estimate", e)
            notEnoughDataResponse()
        }
    }

    private fun notEnoughDataResponse(): JSONObject {
        val response = JSONObject()
        try {
            response.put("success", true)
            response.put("range", JSONObject.NULL)
            response.put("message", "Not enough data")
        } catch (e: Exception) {
            logger.warn("Failed to build the not-enough-data response: " + e.message)
        }
        return response
    }

    /** GET /api/trips/config — current config state. */
    private fun handleGetConfig(): JSONObject {
        val config = manager.getConfig()
        val payload = config?.toJson() ?: JSONObject().apply { put("enabled", false) }
        // Live drivetrain, not a stored setting: the settings screen uses it to decide whether
        // the fuel fields are meaningful at all. Best-effort — a probe failure yields false,
        // which the clients treat as "hide, unless a value is already configured" rather than
        // as proof the car is a BEV.
        payload.put("isPhev", isPhevVehicle())
        return successResponse("config", payload, "config")
    }

    /** Drivetrain, best-effort. Never lets a HAL failure break the config response. */
    private fun isPhevVehicle(): Boolean = try {
        BydDataCollector.getInstance().isPhevVehicle()
    } catch (t: Throwable) {
        logger.debug("config drivetrain probe unavailable: " + t.message)
        false
    }

    /** POST /api/trips/config — set config. */
    private fun handlePostConfig(body: String?): JSONObject {
        return try {
            val bodyJson = JSONObject(body ?: "{}")

            // Connect/proto clients OMIT default scalars (enabled=false, electricityRate=0.0)
            // but set the proto presence companions hasEnabled/hasElectricityRate so a
            // false/zero can still be saved. The legacy web UI sends the value keys directly,
            // with no presence flag.
            if (bodyJson.optBoolean("hasEnabled", false) || bodyJson.has("enabled")) {
                manager.onConfigChanged(bodyJson.optBoolean("enabled", false))
            }

            manager.getConfig()?.let { config ->
                if (bodyJson.optBoolean("hasElectricityRate", false) ||
                    bodyJson.has("electricityRate")
                ) {
                    config.setElectricityRate(bodyJson.optDouble("electricityRate", 0.0))
                }
                if (bodyJson.optBoolean("hasFuelPricePerL", false) ||
                    bodyJson.has("fuelPricePerL")
                ) {
                    config.setFuelPricePerL(bodyJson.optDouble("fuelPricePerL", 0.0))
                }
                if (bodyJson.optBoolean("hasFuelTankCapacityL", false) ||
                    bodyJson.has("fuelTankCapacityL")
                ) {
                    config.setFuelTankCapacityL(bodyJson.optDouble("fuelTankCapacityL", 0.0))
                }
                if (bodyJson.has("currency")) {
                    config.setCurrency(bodyJson.getString("currency"))
                }
                if (bodyJson.has("distanceUnit")) {
                    val unit = bodyJson.getString("distanceUnit")
                    config.setDistanceUnit(unit)
                    // Propagate to BydDataCollector so the conversion factor updates at once.
                    try {
                        BydDataCollector.getInstance()
                            ?.setDistanceUnitOverride(if (unit == "mi") "mi" else "km")
                    } catch (e2: Exception) {
                        logger.warn("Failed to set distanceUnit override: " + e2.message)
                    }
                }
                config.save()
            }

            JSONObject().apply { put("success", true) }
        } catch (e: Exception) {
            logger.error("Error setting config: " + e.message)
            errorResponse("Invalid request body: " + e.message, 400)
        }
    }

    /** GET /api/trips/storage — storage settings and usage. */
    private fun handleGetStorage(): JSONObject {
        val sm = StorageManager.getInstance()
        val db = manager.getDatabase()

        val storage = JSONObject()
        try {
            storage.put("storageType", sm.getTripsStorageType().name)
            storage.put("limitMb", sm.getTripsLimitMb())
            val usedBytes = sm.getTripsSize().toDouble()
            val usedMb = usedBytes / (1024.0 * 1024.0)
            if (usedMb < 0.1 && usedBytes > 0) {
                // Show small sizes in KB.
                storage.put("usedMb", (usedBytes / 1024.0 * 10.0).roundToLong() / 10.0)
                storage.put("usedUnit", "KB")
            } else {
                storage.put("usedMb", (usedMb * 10.0).roundToLong() / 10.0)
                storage.put("usedUnit", "MB")
            }
            storage.put("sdCardAvailable", sm.isSdCardAvailable())
            storage.put("tripsCount", db?.getTripCount() ?: 0)
            storage.put("storagePath", sm.getTripsPath())
        } catch (e: Exception) {
            logger.error("Error reading storage settings", e)
        }

        return successResponse("storage", storage, "storage")
    }

    /** POST /api/trips/storage — set storage settings. */
    private fun handlePostStorage(body: String?): JSONObject {
        return try {
            val bodyJson = JSONObject(body ?: "{}")
            val sm = StorageManager.getInstance()

            if (bodyJson.has("storageType")) {
                val typeStr = bodyJson.getString("storageType")
                val type = if (typeStr.equals("SD_CARD", ignoreCase = true)) {
                    StorageManager.StorageType.SD_CARD
                } else {
                    StorageManager.StorageType.INTERNAL
                }
                sm.setTripsStorageType(type)
            }

            var limitChanged = false
            if (bodyJson.has("storageLimitMb")) {
                sm.setTripsLimitMb(bodyJson.getLong("storageLimitMb"))
                limitChanged = true
            }

            // Mirror the recordings/surveillance handler: enforce the new limit immediately so
            // the user sees usage drop within seconds instead of waiting for the 30s periodic
            // sweep. Async, to keep the HTTP response fast.
            if (limitChanged) {
                Thread({
                    try {
                        sm.ensureTripsSpace(0)
                    } catch (ex: Exception) {
                        logger.warn(
                            "Async trips cleanup after limit change failed: " + ex.message
                        )
                    }
                }, "TripsLimitCleanup").start()
            }

            JSONObject().apply { put("success", true) }
        } catch (e: Exception) {
            logger.error("Error setting storage: " + e.message)
            errorResponse("Invalid request body: " + e.message, 400)
        }
    }

    // ==================== ROUTE COMPARISON ENDPOINTS ====================

    /**
     * GET /api/trips/{id}/similar — find trips on the same route. Matches start/end within
     * about 1.1 km (0.01 degrees) and distance within 25%.
     */
    private fun handleGetSimilarTrips(tripId: Long): JSONObject {
        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)
        val trip = db.getTrip(tripId) ?: return errorResponse("Trip not found", 404)

        val startLat = trip.startLat
        val startLon = trip.startLon
        val endLat = trip.endLat
        val endLon = trip.endLon

        if (startLat == 0.0 && startLon == 0.0) {
            return errorResponse("Trip has no GPS data", 400)
        }

        // Fast path: use the route_id index when it is populated and useful.
        var candidates: List<TripRecord>
        var usingRouteFastPath = false
        if (trip.routeId > 0) {
            candidates = db.getTripsByRoute(trip.routeId, 100)
            // If the route holds only this trip, fall back to a full scan — backfill may have
            // split similar trips across different routes.
            if (candidates.size <= 1) {
                candidates = db.getTrips(365, 500)
            } else {
                usingRouteFastPath = true
            }
        } else {
            candidates = db.getTrips(365, 500)
        }

        val similar = JSONArray()
        var bestEff = Double.MAX_VALUE
        var worstEff = 0.0
        var bestId = -1L
        var worstId = -1L
        var sumEff = 0.0
        var sumScore = 0
        var sumDuration = 0
        var sumSpeed = 0.0
        var sumCost = 0.0
        var count = 0

        for (t in candidates) {
            if (t.id == tripId) continue

            // Apply the geofence filter when doing a full scan (not the route fast path).
            if (!usingRouteFastPath) {
                if (abs(t.startLat - startLat) > 0.01 || abs(t.startLon - startLon) > 0.01) {
                    continue
                }
                if (abs(t.endLat - endLat) > 0.01 || abs(t.endLon - endLon) > 0.01) continue
            }

            val eff = t.efficiencySocPerKm
            similar.put(t.toSummaryJson())
            sumEff += eff
            sumScore += t.getOverallScore()
            sumDuration += t.durationSeconds
            sumSpeed += t.avgSpeedKmh
            sumCost += t.tripCost
            count++
            if (eff > 0 && eff < bestEff) {
                bestEff = eff
                bestId = t.id
            }
            if (eff > worstEff) {
                worstEff = eff
                worstId = t.id
            }
        }

        val response = JSONObject()
        try {
            response.put("success", true)
            response.put("similar", similar)
            response.put("count", count)
            // Debug info
            response.put("_debug_routeId", trip.routeId)
            response.put("_debug_startLat", startLat)
            response.put("_debug_endLat", endLat)
            response.put("_debug_candidatesScanned", candidates.size)
            if (count > 0) {
                val stats = JSONObject()
                stats.put("avgEfficiency", sumEff / count)
                stats.put("avgScore", sumScore / count)
                stats.put("avgDurationSeconds", sumDuration / count)
                stats.put("avgSpeedKmh", sumSpeed / count)
                stats.put("avgCost", sumCost / count)
                stats.put("bestTripId", bestId)
                stats.put("bestEfficiency", if (bestEff == Double.MAX_VALUE) 0.0 else bestEff)
                stats.put("worstTripId", worstId)
                stats.put("worstEfficiency", worstEff)
                response.put("stats", stats)
            }
        } catch (e: Exception) {
            logger.error("Error building similar trips response", e)
        }
        return response
    }

    /**
     * GET /api/trips/{id}/gps — lightweight GPS-only trace for a map overlay. Returns
     * `[[lat,lon], ...]`, much smaller than the full telemetry.
     */
    private fun handleGetGpsTrace(tripId: Long): JSONObject {
        val db = manager.getDatabase() ?: return errorResponse("Trip database not available", 500)
        val trip = db.getTrip(tripId) ?: return errorResponse("Trip not found", 404)

        val telemetryFile = existingTelemetryFile(trip)
            ?: return errorResponse("Telemetry data unavailable", 410)

        val gps = JSONArray()
        for (s in TelemetryStore.readFromFile(telemetryFile)) {
            if (s.lat != 0.0 && s.lon != 0.0) {
                try {
                    gps.put(JSONArray().put(s.lat).put(s.lon))
                } catch (e: Exception) {
                    logger.warn("Failed to build GPS point: " + e.message)
                }
            }
        }

        return successResponse("gps", gps, "GPS trace")
    }

    // ==================== UTILITY METHODS ====================

    /** The trip's telemetry file if it is set and present on disk, else null. */
    private fun existingTelemetryFile(trip: TripRecord): File? {
        val path = trip.telemetryFilePath
        if (path.isNullOrEmpty()) return null
        val f = File(path)
        return if (f.exists()) f else null
    }

    /** Parse query parameters from a query string, e.g. "days=7&limit=50". */
    private fun parseQueryParams(queryString: String?, params: MutableMap<String, String>) {
        if (queryString.isNullOrEmpty()) return
        for (pair in queryString.split("&")) {
            val eq = pair.indexOf('=')
            if (eq > 0) {
                val key = pair.substring(0, eq)
                val value = if (eq < pair.length - 1) pair.substring(eq + 1) else ""
                params[key] = value
            }
        }
    }

    /**
     * Enrich a trip with estimated energy when BMS kWh data was never recorded, so old trips
     * still show a cost in the UI.
     *
     * Uses the BYD-local nominal pack capacity (the same source as VehicleDataMonitor). There
     * is no SoH degradation source, so the pack is treated as healthy. The enrichment is
     * in-memory only — it is never persisted.
     */
    private fun enrichTripEnergy(trip: TripRecord) {
        if (!shouldEnrichEnergy(trip)) return

        try {
            val nominal = VehicleDataMonitor.getInstance().getNominalCapacityKwh()
            if (nominal <= 0) return

            val socDelta = trip.socStart - trip.socEnd
            val estimatedEnergy = (socDelta / 100.0) * nominal

            trip.kwhStart = (trip.socStart / 100.0) * nominal
            trip.kwhEnd = (trip.socEnd / 100.0) * nominal

            val config = manager.getConfig()
            if (config != null && config.getElectricityRate() > 0 && trip.tripCost <= 0) {
                trip.electricityRate = config.getElectricityRate()
                trip.currency = config.getCurrency()
                // Set BOTH legs, not just the total. tripCost is now electricCost + fuelCost,
                // so filling only the total would show a trip that cost something with a zero
                // electric leg — the response would contradict itself. A trip old enough to
                // need this enrichment has no fuel data, so the fuel leg stays 0.
                trip.electricCost = estimatedEnergy * trip.electricityRate
                trip.tripCost = trip.electricCost + trip.fuelCost
            }

            if (trip.distanceKm > 0) {
                trip.energyPerKm = estimatedEnergy / trip.distanceKm
            }
        } catch (e: Exception) {
            logger.warn("enrichTripEnergy: failed to read nominal capacity: " + e.message)
        }
    }

    /** An integer query parameter, or [defaultValue] when absent or unparseable. */
    private fun getIntParam(params: Map<String, String>, key: String, defaultValue: Int): Int {
        val value = params[key]
        if (value.isNullOrEmpty()) return defaultValue
        return value.toIntOrNull() ?: defaultValue
    }

    /** A `{success:true, <key>:<payload>}` response. */
    private fun successResponse(key: String, payload: Any, what: String): JSONObject {
        val response = JSONObject()
        try {
            response.put("success", true)
            response.put(key, payload)
        } catch (e: Exception) {
            logger.error("Error building $what response", e)
        }
        return response
    }

    /** An error response with the given message and HTTP status code. */
    private fun errorResponse(message: String, status: Int): JSONObject {
        val response = JSONObject()
        try {
            response.put("success", false)
            response.put("error", message)
            response.put("_status", status)
        } catch (e: Exception) {
            logger.error("Error building error response", e)
        }
        return response
    }

    internal companion object {
        /**
         * Whether [trip] should have its energy back-filled from the SoC delta on read.
         *
         * Pure, and split out so the RULES can be tested without a HAL: [enrichTripEnergy] itself
         * reaches `VehicleDataMonitor.getInstance()` for the pack capacity, which does not exist
         * off-device.
         *
         * Three things disqualify a trip:
         *  - it already has a positive energy figure, so there is nothing to fill;
         *  - it has no usable SoC drop, so there is nothing to estimate from;
         *  - it carries BOTH energy-meter readings, which means a zero is a MEASUREMENT (a PHEV
         *    leg driven entirely on the engine) rather than a missing value.
         *
         * That last rule mirrors `TripAnalyticsManager.resolveTripEnergyKwh` deliberately. The
         * write path declines to estimate over a metered zero, so estimating here would fabricate
         * consumption the vehicle says never happened AND make the detail view contradict both the
         * list view and what is stored. The same margin is used for the same reason: SoC is
         * integer-resolution, so one step is indistinguishable from quantisation noise or
         * parasitic draw, and only an unmistakable drop may override the meter.
         */
        internal fun shouldEnrichEnergy(trip: TripRecord): Boolean {
            if (trip.getEnergyUsedKwh() > 0) return false
            if (trip.socStart <= 0 || trip.socEnd <= 0 || trip.socStart <= trip.socEnd) return false
            if (trip.hasMeteredEnergy() &&
                trip.socStart - trip.socEnd <= TripAnalyticsManager.SOC_OVERRIDE_MIN_DROP_PCT
            ) {
                return false
            }
            return true
        }

        private val logger = DaemonLogger.getInstance("TripApiHandler")

        // URI patterns for extracting trip IDs
        private val TRIP_ID_PATTERN: Pattern = Pattern.compile("^/api/trips/(\\d+)$")
        private val TRIP_TELEMETRY_PATTERN: Pattern =
            Pattern.compile("^/api/trips/(\\d+)/telemetry$")
        private val TRIP_SIMILAR_PATTERN: Pattern = Pattern.compile("^/api/trips/(\\d+)/similar$")
        private val TRIP_GPS_PATTERN: Pattern = Pattern.compile("^/api/trips/(\\d+)/gps$")
    }
}
