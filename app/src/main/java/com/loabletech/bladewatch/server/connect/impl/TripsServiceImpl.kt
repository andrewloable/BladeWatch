package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectHandlerUtil
import net.bladewatch.app.server.connect.ConnectResponse
import net.bladewatch.app.trips.TripApiHandler
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * Connect protocol handler for bladewatch.v1.TripsService.
 *
 * TripApiHandler is an instance method (not static), so this impl gets the TripAnalyticsManager
 * from CameraDaemon at call time (same pattern as HttpServer).
 *
 * Routes (TripApiHandler.handleRequest):
 *   ListTrips       → GET    /api/trips
 *   GetTrip         → GET    /api/trips/{id}
 *   DeleteTrip      → DELETE /api/trips/{id}
 *   GetSummary      → GET    /api/trips/summary
 *   GetDna          → GET    /api/trips/dna
 *   GetRange        → GET    /api/trips/range
 *   GetConfig       → GET    /api/trips/config
 *   SetConfig       → POST   /api/trips/config
 *   GetStorage      → GET    /api/trips/storage
 *   SetStorage      → POST   /api/trips/storage
 *   SyncTrips       → POST   /api/trips/sync
 *   GetTelemetry    → GET    /api/trips/{id}/telemetry
 *   GetSimilarTrips → GET    /api/trips/{id}/similar
 *   GetGpsTrace     → GET    /api/trips/{id}/gps
 */
class TripsServiceImpl {

    @Volatile
    private var cachedHandler: TripApiHandler? = null

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register("bladewatch.v1.TripsService", "ListTrips", this::handleListTrips)
        dispatcher.register("bladewatch.v1.TripsService", "GetTrip", this::handleGetTrip)
        dispatcher.register("bladewatch.v1.TripsService", "DeleteTrip", this::handleDeleteTrip)
        dispatcher.register("bladewatch.v1.TripsService", "GetSummary", this::handleGetSummary)
        dispatcher.register("bladewatch.v1.TripsService", "GetDna", this::handleGetDna)
        dispatcher.register("bladewatch.v1.TripsService", "GetRange", this::handleGetRange)
        dispatcher.register("bladewatch.v1.TripsService", "GetConfig", this::handleGetConfig)
        dispatcher.register("bladewatch.v1.TripsService", "SetConfig", this::handleSetConfig)
        dispatcher.register("bladewatch.v1.TripsService", "GetStorage", this::handleGetStorage)
        dispatcher.register("bladewatch.v1.TripsService", "SetStorage", this::handleSetStorage)
        dispatcher.register("bladewatch.v1.TripsService", "SyncTrips", this::handleSyncTrips)
        dispatcher.register("bladewatch.v1.TripsService", "GetTelemetry", this::handleGetTelemetry)
        dispatcher.register(
            "bladewatch.v1.TripsService", "GetSimilarTrips", this::handleGetSimilarTrips
        )
        dispatcher.register("bladewatch.v1.TripsService", "GetGpsTrace", this::handleGetGpsTrace)
    }

    /**
     * Run the REST handler and return its JSON body (after the HTTP status check), so callers can
     * reshape the payload to match the proto wire shape before serialising.
     */
    @Throws(ConnectException::class)
    private fun invokeJson(method: String, uri: String, requestBody: String?): JSONObject {
        val tam = CameraDaemon.getTripAnalyticsManager()
            ?: throw ConnectException("unavailable", "Trip analytics not initialized")
        val handler = cachedHandler ?: TripApiHandler(tam).also { cachedHandler = it }
        val result = handler.handleRequest(uri, method, null, requestBody)
            ?: throw ConnectException("internal", "No response from TripApiHandler")
        // Check the HTTP-level status before removing the field — _status >= 400 is an error.
        val status = result.optInt("_status", 200)
        result.remove("_status")
        if (status >= 400) {
            val error = result.optString("error", result.optString("message", "Request failed"))
            val code = when {
                status == 404 || status == 410 -> "not_found"
                status == 400 -> "invalid_argument"
                else -> "internal"
            }
            throw ConnectException(code, error)
        }
        return result
    }

    @Throws(ConnectException::class)
    private fun invoke(method: String, uri: String, requestBody: String?): ConnectResponse =
        ConnectResponse.of(invokeJson(method, uri, requestBody).toString())

    @Throws(ConnectException::class)
    private fun handleListTrips(req: String?, clientIdentity: String?): ConnectResponse =
        invoke("GET", "/api/trips" + buildTripsQuery(req, true), req)

    @Throws(ConnectException::class)
    private fun handleGetTrip(req: String?, clientIdentity: String?): ConnectResponse {
        val id = ConnectHandlerUtil.requireLong(req, "id")
        val result = invokeJson("GET", "/api/trips/$id", req)
        // TripApiHandler emits a FLAT trip object; the proto TripDetail expects a nested `summary`
        // (TripSummary) plus the DNA/elevation/micro_moments fields at the top level. Nest a copy
        // of the flat trip under `summary` — TripSummary parsing ignores the extra keys, and the
        // top-level TripDetail fields still parse from the flat trip.
        try {
            val trip = result.optJSONObject("trip")
            if (trip != null && !trip.has("summary")) {
                trip.put("summary", JSONObject(trip.toString()))
            }
        } catch (e: JSONException) {
            throw ConnectException("internal", "An internal error occurred")
        }
        return ConnectResponse.of(result.toString())
    }

    @Throws(ConnectException::class)
    private fun handleDeleteTrip(req: String?, clientIdentity: String?): ConnectResponse {
        val id = ConnectHandlerUtil.requireLong(req, "id")
        return invoke("DELETE", "/api/trips/$id", req)
    }

    @Throws(ConnectException::class)
    private fun handleGetSummary(req: String?, clientIdentity: String?): ConnectResponse {
        val result = invokeJson("GET", "/api/trips/summary" + buildTripsQuery(req, false), req)
        // proto WeeklyRollupEntry models each entry as a single string rollup_json blob.
        try {
            wrapArrayAsJsonBlob(result, "summary", "rollupJson")
        } catch (e: JSONException) {
            throw ConnectException("internal", "An internal error occurred")
        }
        return ConnectResponse.of(result.toString())
    }

    @Throws(ConnectException::class)
    private fun handleGetDna(req: String?, clientIdentity: String?): ConnectResponse =
        invoke("GET", "/api/trips/dna" + buildTripsQuery(req, false), req)

    @Throws(ConnectException::class)
    private fun handleGetRange(req: String?, clientIdentity: String?): ConnectResponse {
        val result = invokeJson("GET", "/api/trips/range", req)
        // proto GetRangeResponse models the estimate as a single string range_json blob; the
        // handler emits it as a nested `range` object.
        try {
            val range = result.optJSONObject("range")
            if (range != null) {
                result.put("rangeJson", range.toString())
                result.remove("range")
            }
        } catch (e: JSONException) {
            throw ConnectException("internal", "An internal error occurred")
        }
        return ConnectResponse.of(result.toString())
    }

    @Throws(ConnectException::class)
    private fun handleGetConfig(req: String?, clientIdentity: String?): ConnectResponse =
        invoke("GET", "/api/trips/config", null)

    @Throws(ConnectException::class)
    private fun handleSetConfig(req: String?, clientIdentity: String?): ConnectResponse =
        invoke("POST", "/api/trips/config", req)

    @Throws(ConnectException::class)
    private fun handleGetStorage(req: String?, clientIdentity: String?): ConnectResponse =
        invoke("GET", "/api/trips/storage", null)

    @Throws(ConnectException::class)
    private fun handleSetStorage(req: String?, clientIdentity: String?): ConnectResponse =
        invoke("POST", "/api/trips/storage", req)

    @Throws(ConnectException::class)
    private fun handleSyncTrips(req: String?, clientIdentity: String?): ConnectResponse =
        invoke("POST", "/api/trips/sync", req)

    @Throws(ConnectException::class)
    private fun handleGetTelemetry(req: String?, clientIdentity: String?): ConnectResponse {
        // proto GetTelemetryRequest.trip_id → json "tripId" (not "id").
        val id = ConnectHandlerUtil.requireLong(req, "tripId")
        val result = invokeJson("GET", "/api/trips/$id/telemetry", req)
        // proto TelemetrySample models each sample as a single string sample_json blob.
        try {
            wrapArrayAsJsonBlob(result, "telemetry", "sampleJson")
        } catch (e: JSONException) {
            throw ConnectException("internal", "An internal error occurred")
        }
        return ConnectResponse.of(result.toString())
    }

    @Throws(ConnectException::class)
    private fun handleGetSimilarTrips(req: String?, clientIdentity: String?): ConnectResponse {
        // proto GetSimilarTripsRequest.trip_id → json "tripId" (not "id").
        val id = ConnectHandlerUtil.requireLong(req, "tripId")
        return invoke("GET", "/api/trips/$id/similar", req)
    }

    @Throws(ConnectException::class)
    private fun handleGetGpsTrace(req: String?, clientIdentity: String?): ConnectResponse {
        // proto GetGpsTraceRequest.trip_id → json "tripId" (not "id").
        val id = ConnectHandlerUtil.requireLong(req, "tripId")
        val result = invokeJson("GET", "/api/trips/$id/gps", req)
        // Handler emits gps as positional arrays [[lat,lon],...]; proto GpsPoint expects
        // {lat,lon}.
        try {
            val gps = result.optJSONArray("gps")
            if (gps != null) {
                val pts = JSONArray()
                for (i in 0 until gps.length()) {
                    val p = gps.optJSONArray(i)
                    if (p == null || p.length() < 2) continue
                    pts.put(JSONObject().put("lat", p.optDouble(0)).put("lon", p.optDouble(1)))
                }
                result.put("gps", pts)
            }
        } catch (e: JSONException) {
            throw ConnectException("internal", "An internal error occurred")
        }
        return ConnectResponse.of(result.toString())
    }

    private companion object {
        /**
         * Wrap each element of a JSON array under [arrayKey] as a stringified-JSON blob, matching
         * proto messages that model the element as a single opaque `string <field>_json`, e.g.
         * telemetry [{t,s,..}] → [{"sampleJson":"{...}"}] so the Kotlin/TS client parses the blob.
         */
        @Throws(JSONException::class)
        fun wrapArrayAsJsonBlob(root: JSONObject, arrayKey: String, blobField: String) {
            val arr = root.optJSONArray(arrayKey) ?: return
            val wrapped = JSONArray()
            for (i in 0 until arr.length()) {
                val el = arr.optJSONObject(i) ?: continue
                wrapped.put(JSONObject().put(blobField, el.toString()))
            }
            root.put(arrayKey, wrapped)
        }

        /**
         * Build a REST query string (?days=&limit=&offset=) from a request body, so Connect
         * clients can forward ListTrips/GetSummary/GetDna filters. TripApiHandler reads these only
         * from the URI query string (params==null path), never the body, so a path-only URI would
         * always use the defaults (days=7, limit=50, offset=0). Only fields the client actually
         * set (non-zero) are appended.
         */
        fun buildTripsQuery(req: String?, withLimitOffset: Boolean): String {
            if (req.isNullOrEmpty()) return ""
            val r = try {
                JSONObject(req)
            } catch (e: JSONException) {
                return ""
            }
            val q = StringBuilder()
            val days = r.optInt("days", 0)
            if (days > 0) appendParam(q, "days", days.toString())
            if (withLimitOffset) {
                val limit = r.optInt("limit", 0)
                if (limit > 0) appendParam(q, "limit", limit.toString())
                val offset = r.optInt("offset", 0)
                if (offset > 0) appendParam(q, "offset", offset.toString())
            }
            return if (q.isEmpty()) "" else "?$q"
        }

        fun appendParam(q: StringBuilder, key: String, value: String?) {
            if (value.isNullOrEmpty()) return
            if (q.isNotEmpty()) q.append('&')
            q.append(key).append('=').append(value)
        }
    }
}
