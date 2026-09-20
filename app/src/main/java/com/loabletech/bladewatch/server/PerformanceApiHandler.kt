package net.bladewatch.app.server

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.NominalCapacityResolver
import net.bladewatch.app.monitor.PerformanceMonitor
import net.bladewatch.app.monitor.SocHistoryDatabase
import net.bladewatch.app.monitor.VehicleDataMonitor
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.storage.StorageManager
import org.json.JSONObject

/**
 * The performance-monitoring operations behind `SystemService`.
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/performance paths and writing JSON into
 * an OutputStream that the Connect layer captured straight back out. The operations still
 * reachable over ConnectRPC now RETURN their JSON.
 *
 * Deleted with the dispatch: history, full, connect, disconnect, heartbeat, start, stop, status,
 * discover, soc-history and battery-health. None had an RPC, so unrouting /api/ left them
 * unreachable. connect/heartbeat/disconnect were additionally SUPERSEDED in BladeWatch-qwqq by
 * SystemService methods that call PerformanceMonitor directly.
 */
object PerformanceApiHandler {

    private val logger: DaemonLogger = DaemonLogger.getInstance("PerformanceApiHandler")

    @JvmStatic
    @Throws(Exception::class)
    fun getCurrent(): JSONObject = try {
        val monitor = PerformanceMonitor.getInstance()
        val data = monitor.getLatestAsJson()
        if (data.length() == 0) {
            // No data yet — return empty with a status
            val response = JSONObject()
            response.put("status", "no_data")
            response.put("message", Messages.get("errors.performance_no_data"))
            response.put("monitoring", monitor.isRunning)
            response
        } else {
            data
        }
    } catch (e: Exception) {
        logger.error("Failed to get current performance data", e)
        JSONObject("{\"error\": \"" + e.message + "\"}")
    }

    /**
     * Proxies `SocHistoryDatabase.getLastParkingDelta()` to UI-process callers
     * (DashboardInsightProvider) which can't open the H2 file themselves — the daemon's
     * FILE_LOCK=SOCKET excludes other JVMs, and the UI-side singleton is never init()'d anyway
     * because init() only runs in CameraDaemon.main().
     *
     * @param maxAgeHours 0 or less keeps the old query-string default of 72.
     * @return the JSON object returned by getLastParkingDelta(), or `{"available": false}` when
     *   the DB is offline or there is no qualifying cycle.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun parkingDelta(maxAgeHours: Int): JSONObject = try {
        val hours = if (maxAgeHours <= 0) 72 else maxAgeHours
        SocHistoryDatabase.getInstance().getLastParkingDelta(hours)
            ?: JSONObject("{\"available\": false}")
    } catch (e: Exception) {
        logger.error("Failed to get parking delta", e)
        JSONObject("{\"available\": false, \"error\": \"" + e.message + "\"}")
    }

    /**
     * Proxies `SocHistoryDatabase.getMostRecentCompletedChargingSession()` for the same
     * cross-process reason as [parkingDelta].
     *
     * @param hoursBack 0 or less keeps the old query-string default of 24.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun lastCharge(hoursBack: Int): JSONObject = try {
        val hours = if (hoursBack <= 0) 24 else hoursBack
        SocHistoryDatabase.getInstance().getMostRecentCompletedChargingSession(hours)
            ?: JSONObject("{\"available\": false}")
    } catch (e: Exception) {
        logger.error("Failed to get last charge", e)
        JSONObject("{\"available\": false, \"error\": \"" + e.message + "\"}")
    }

    // ==================== SOH STATUS & RESET ====================

    /** Detailed SOH status with source, confidence and capacity info. */
    @JvmStatic
    @Throws(Exception::class)
    fun sohStatus(): JSONObject = try {
        // SoH ESTIMATION is still gone — there is no BYD-local degradation source, so the pack is
        // treated as healthy. What this reports is the nominal CAPACITY, which is resolvable and
        // is what the dashboard's read-outs actually consume (BladeWatch-b9vl). Reporting
        // success:false while capacity was demonstrably known is what left the panel showing "—"
        // beside correctly-costed trips.
        val response = JSONObject()
        val kwh = VehicleDataMonitor.getInstance().getNominalCapacityKwh()
        response.put("success", kwh > 0)
        response.put("nominalCapacityKwh", kwh)
        response.put("nominalSource", VehicleDataMonitor.getInstance().getNominalCapacitySource())
        // No degradation source exists, so no SoH percentage is invented here.
        response.put("displaySoh", 0.0)
        response.put("displaySource", "unavailable")
        if (kwh <= 0) response.put("error", Messages.get("errors.soh_not_initialized"))
        response
    } catch (e: Exception) {
        logger.error("Failed to get SOH status", e)
        JSONObject("{\"success\":false,\"error\":\"" + e.message + "\"}")
    }

    /** Battery State-of-Health estimation has been removed; there is nothing to reset. */
    @JvmStatic
    @Throws(Exception::class)
    fun sohReset(): JSONObject = try {
        val response = JSONObject()
        response.put("success", false)
        response.put("error", Messages.get("errors.soh_not_initialized"))
        response
    } catch (e: Exception) {
        logger.error("Failed to reset SOH", e)
        JSONObject("{\"success\":false,\"error\":\"" + e.message + "\"}")
    }

    /**
     * Bulk reset of user-selected data categories.
     *
     * Body: `{"categories": ["trips","socHistory","soh","mediaRecordings","mediaSurveillance",
     * "mediaProximity","mediaTrips"]}`
     *
     * Each requested category runs independently — a partial failure on one does not abort the
     * others. The response includes a per-category result so the UI can show which wipes
     * succeeded.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun resetCategories(requestBody: String?): JSONObject {
        val response = JSONObject()
        val results = JSONObject()
        try {
            val req = if (requestBody.isNullOrEmpty()) JSONObject() else JSONObject(requestBody)
            val cats = req.optJSONArray("categories")
            if (cats == null || cats.length() == 0) {
                response.put("success", false)
                response.put("error", Messages.get("errors.reset_no_categories"))
                return response
            }

            for (i in 0 until cats.length()) {
                val cat = cats.optString(i, "")
                val r = JSONObject()
                try {
                    when (cat) {
                        "trips" -> {
                            val mgr = CameraDaemon.getTripAnalyticsManager()
                            // Refuse if a trip is being recorded right now — wiping mid-trip
                            // would leave the in-memory TripBuilder writing to a freshly-empty
                            // DB and create a phantom one-row history. The user can turn the car
                            // off and try again.
                            if (mgr != null && mgr.isTripActive()) {
                                r.put("success", false)
                                r.put("error", Messages.get("errors.reset_trip_in_progress"))
                            } else {
                                val db = mgr?.getDatabase()
                                val n = db?.resetAll() ?: -1L
                                r.put("success", n >= 0)
                                r.put("rowsDeleted", n)
                            }
                        }
                        "socHistory" -> {
                            val n = SocHistoryDatabase.getInstance().resetAll()
                            r.put("success", n >= 0)
                            r.put("rowsDeleted", n)
                        }
                        "soh" -> {
                            // Battery State-of-Health estimation has been removed; nothing to
                            // reset.
                            r.put("success", true)
                        }
                        "mediaRecordings" -> {
                            val sm = StorageManager.getInstance()
                            // Don't wipe the dir while the encoder is writing to it — at best
                            // you'd delete the still-open file descriptor; at worst, corrupt the
                            // active MP4.
                            if (sm.isRecordingActive) {
                                r.put("success", false)
                                r.put("error", Messages.get("errors.reset_recording_in_progress"))
                            } else {
                                val n = sm.wipeMediaCategory("recordings")
                                r.put("success", n >= 0)
                                r.put("filesDeleted", n)
                            }
                        }
                        "mediaSurveillance" -> {
                            val sm = StorageManager.getInstance()
                            if (sm.isSurveillanceActive) {
                                r.put("success", false)
                                r.put(
                                    "error",
                                    Messages.get("errors.reset_surveillance_in_progress")
                                )
                            } else {
                                val n = sm.wipeMediaCategory("surveillance")
                                r.put("success", n >= 0)
                                r.put("filesDeleted", n)
                            }
                        }
                        "mediaProximity" -> {
                            val n = StorageManager.getInstance().wipeMediaCategory("proximity")
                            r.put("success", n >= 0)
                            r.put("filesDeleted", n)
                        }
                        "mediaTrips" -> {
                            val n = StorageManager.getInstance().wipeMediaCategory("trips")
                            r.put("success", n >= 0)
                            r.put("filesDeleted", n)
                        }
                        else -> {
                            r.put("success", false)
                            r.put("error", Messages.get("errors.reset_unknown_category"))
                        }
                    }
                } catch (inner: Exception) {
                    r.put("success", false)
                    r.put("error", inner.message)
                    logger.warn("Reset category " + cat + " failed: " + inner.message)
                }
                results.put(cat, r)
            }

            response.put("success", true)
            response.put("results", results)
            return response
        } catch (e: Exception) {
            logger.error("Reset request failed", e)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /** Current nominal kWh and its source. */
    @JvmStatic
    @Throws(Exception::class)
    fun sohGetNominal(): JSONObject = try {
        // BladeWatch-b9vl: this used to return a hardcoded null/"unset" even though the capacity
        // IS resolvable — NominalCapacityResolver answers 18.3 kWh on this car — so the dashboard
        // showed "—" while trips were being costed from a real number.
        val response = JSONObject()
        val kwh = VehicleDataMonitor.getInstance().getNominalCapacityKwh()
        val source = VehicleDataMonitor.getInstance().getNominalCapacitySource()
        // 0 means genuinely unknown and must stay JSON null, not a fake zero capacity.
        response.put("nominalKwh", if (kwh > 0) kwh as Any else JSONObject.NULL)
        response.put("nominalSource", source)
        response
    } catch (e: Exception) {
        logger.error("Failed to get SOH nominal", e)
        JSONObject("{\"error\":\"" + e.message + "\"}")
    }

    /**
     * Set or clear the user-set nominal kWh.
     *
     * Body: `{"nominalKwh": 82.5}` sets the user override; `{"nominalKwh": null}` clears it and
     * re-runs auto-detect. Validates the 8-120 kWh range.
     *
     * Note that the outer catch swallows the typed [ConnectException] into a `success:false`
     * body. That is pre-existing behaviour, kept deliberately rather than changed in passing.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun sohSetNominal(requestBody: String?): JSONObject = try {
        // BladeWatch-b9vl. The owner knows their own car, and every automatic source is
        // inference: the SDK field is a charging-session figure (phim), the catalogue is
        // per-trim, and the derivation reads a channel that mirrors SoC on this car (x4lf). An
        // explicit value outranks all of them.
        val req = if (requestBody.isNullOrEmpty()) JSONObject() else JSONObject(requestBody)
        val response = JSONObject()

        if (req.isNull("nominalKwh")) {
            UnifiedConfigManager.setNominalCapacityOverrideKwh(0.0)
            response.put("success", true)
            response.put("nominalKwh", JSONObject.NULL)
            response.put(
                "nominalSource", VehicleDataMonitor.getInstance().getNominalCapacitySource()
            )
            response
        } else {
            val kwh = req.optDouble("nominalKwh", Double.NaN)
            if (!NominalCapacityResolver.isUsableOverride(kwh)) {
                // Refused rather than stored: a typo must not be able to redefine the pack and
                // silently corrupt every trip from then on.
                throw ConnectException(
                    "invalid_argument", Messages.get("errors.soh_nominal_range")
                )
            }
            if (!UnifiedConfigManager.setNominalCapacityOverrideKwh(kwh)) {
                throw ConnectException("internal", Messages.get("errors.models_persist_failed"))
            }
            response.put("success", true)
            response.put("nominalKwh", kwh)
            response.put("nominalSource", "user")
            response
        }
    } catch (e: Exception) {
        logger.error("Failed to set SOH nominal", e)
        JSONObject("{\"success\":false,\"error\":\"" + e.message + "\"}")
    }
}
