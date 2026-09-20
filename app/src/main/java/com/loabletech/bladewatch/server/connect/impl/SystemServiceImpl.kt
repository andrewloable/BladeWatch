package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.PerformanceMonitor
import net.bladewatch.app.server.AudioTestApiHandler
import net.bladewatch.app.server.HttpServer
import net.bladewatch.app.server.ModelsApiHandler
import net.bladewatch.app.server.PerformanceApiHandler
import net.bladewatch.app.server.PerformanceClientId
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONObject

/**
 * Connect protocol handler for bladewatch.v1.SystemService.
 *
 * GetStatus requires the HttpServer instance (statusJson is an instance method); the other
 * methods use static handler calls.
 */
class SystemServiceImpl(private val httpServer: HttpServer) {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register("bladewatch.v1.SystemService", "GetStatus", this::handleGetStatus)
        dispatcher.register(
            "bladewatch.v1.SystemService", "GetPerformance", this::handleGetPerformance
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "PlayAudioTest", this::handlePlayAudioTest
        )
        dispatcher.register("bladewatch.v1.SystemService", "ListModels", this::handleListModels)
        dispatcher.register(
            "bladewatch.v1.SystemService", "DownloadModel", this::handleDownloadModel
        )
        // BladeWatch-qwqq: the performance panel's session lifecycle, moved off REST. These call
        // PerformanceMonitor directly rather than wrapping a REST handler — the shape the rest of
        // this class is being converted to (BladeWatch-6mnq).
        dispatcher.register(
            "bladewatch.v1.SystemService", "PerformanceConnect", this::handlePerformanceConnect
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "PerformanceHeartbeat", this::handlePerformanceHeartbeat
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "PerformanceDisconnect",
            this::handlePerformanceDisconnect
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "GetSohNominal", this::handleGetSohNominal
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "SetSohNominal", this::handleSetSohNominal
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "GetSohStatus", this::handleGetSohStatus
        )
        dispatcher.register("bladewatch.v1.SystemService", "ResetSoh", this::handleResetSoh)
        dispatcher.register(
            "bladewatch.v1.SystemService", "ResetPerformance", this::handleResetPerformance
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "GetParkingDelta", this::handleGetParkingDelta
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "GetLastCharge", this::handleGetLastCharge
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "GetSelectedModel", this::handleGetSelectedModel
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "SetSelectedModel", this::handleSetSelectedModel
        )
        dispatcher.register(
            "bladewatch.v1.SystemService", "GetModelsManifest", this::handleGetModelsManifest
        )
    }

    @Throws(ConnectException::class)
    private fun handleGetStatus(req: String?, clientIdentity: String?): ConnectResponse = try {
        ConnectResponse.of(httpServer.statusJson().toString())
    } catch (e: Exception) {
        throw ConnectException("internal", "An internal error occurred")
    }

    @Throws(ConnectException::class)
    private fun handleGetPerformance(req: String?, clientIdentity: String?): ConnectResponse =
        // The REST handler returns the raw performance object; the proto + Angular consumer expect
        // GetPerformanceResponse{success, performance_json:"<stringified raw>"}. Wrap on the
        // Connect side only — the REST handler output is left untouched for the legacy web UI.
        json {
            JSONObject()
                .put("success", true)
                .put("performanceJson", PerformanceApiHandler.getCurrent().toString())
        }

    @Throws(ConnectException::class)
    private fun handlePlayAudioTest(req: String?, clientIdentity: String?): ConnectResponse =
        json { AudioTestApiHandler.testAvas(req) }

    @Throws(ConnectException::class)
    private fun handleListModels(req: String?, clientIdentity: String?): ConnectResponse =
        json { ModelsApiHandler.list() }

    @Throws(ConnectException::class)
    private fun handleDownloadModel(req: String?, clientIdentity: String?): ConnectResponse =
        json { ModelsApiHandler.download() }

    @Throws(ConnectException::class)
    private fun handlePerformanceConnect(req: String?, clientIdentity: String?): ConnectResponse =
        try {
            val requested = if (req.isNullOrEmpty()) null else JSONObject(req).optString("clientId", null)
            val clientId = PerformanceClientId.resolve(requested)
            PerformanceMonitor.getInstance().clientConnected(clientId)
            ConnectResponse.of(
                JSONObject()
                    .put("success", true)
                    // The id the server REGISTERED, which is the one heartbeats must carry.
                    .put("clientId", clientId)
                    .toString()
            )
        } catch (e: Exception) {
            logger.warn("PerformanceConnect failed: " + e.message)
            throw ConnectException("internal", "An internal error occurred")
        }

    @Throws(ConnectException::class)
    private fun handlePerformanceHeartbeat(req: String?, clientIdentity: String?): ConnectResponse =
        performanceSession(req, true)

    @Throws(ConnectException::class)
    private fun handlePerformanceDisconnect(
        req: String?,
        clientIdentity: String?
    ): ConnectResponse = performanceSession(req, false)

    /**
     * Heartbeat and disconnect differ only in which monitor call they make, and both are no-ops
     * without a client id — an unknown id must not be invented here, or a stray call would
     * register a session nobody ever disconnects and pin monitoring on forever.
     */
    @Throws(ConnectException::class)
    private fun performanceSession(req: String?, keepAlive: Boolean): ConnectResponse = try {
        val clientId = if (req.isNullOrEmpty()) null else JSONObject(req).optString("clientId", null)
        var handled = false
        if (!clientId.isNullOrBlank()) {
            val monitor = PerformanceMonitor.getInstance()
            if (keepAlive) {
                monitor.clientHeartbeat(clientId.trim())
            } else {
                monitor.clientDisconnected(clientId.trim())
            }
            handled = true
        }
        val out = JSONObject().put("success", handled)
        if (!handled) out.put("error", "clientId is required")
        ConnectResponse.of(out.toString())
    } catch (e: Exception) {
        logger.warn("Performance session call failed: " + e.message)
        throw ConnectException("internal", "An internal error occurred")
    }

    @Throws(ConnectException::class)
    private fun handleGetSohNominal(req: String?, clientIdentity: String?): ConnectResponse =
        json {
            val payload = PerformanceApiHandler.sohGetNominal()
            val wrapped = JSONObject()
            if (!payload.isNull("nominalKwh")) {
                wrapped.put("nominalKwh", payload.getDouble("nominalKwh"))
            }
            wrapped.put("nominalSource", payload.optString("nominalSource", "unset"))
        }

    @Throws(ConnectException::class)
    private fun handleSetSohNominal(req: String?, clientIdentity: String?): ConnectResponse {
        // Pass the request JSON through — the body may carry nominalKwh or null.
        var forwarded = req
        if (forwarded != null) {
            try {
                val reqJson = JSONObject(req)
                val restBody = JSONObject()
                if (reqJson.has("nominalKwh")) {
                    restBody.put(
                        "nominalKwh",
                        if (reqJson.isNull("nominalKwh")) JSONObject.NULL
                        else reqJson.getDouble("nominalKwh")
                    )
                } else {
                    restBody.put("nominalKwh", JSONObject.NULL)
                }
                forwarded = restBody.toString()
            } catch (e: Exception) {
                logger.warn(
                    "Failed to reformat SetSohNominal request body, forwarding raw: " + e.message
                )
            }
        }
        val payloadBody = forwarded
        return json {
            val payload = PerformanceApiHandler.sohSetNominal(payloadBody)
            val wrapped = JSONObject()
            wrapped.put("success", payload.optBoolean("success", false))
            if (!payload.isNull("nominalKwh")) {
                wrapped.put("nominalKwh", payload.getDouble("nominalKwh"))
            }
            wrapped.put("nominalSource", payload.optString("nominalSource", "unset"))
            if (payload.has("error")) wrapped.put("error", payload.optString("error", ""))
            wrapped
        }
    }

    @Throws(ConnectException::class)
    private fun handleGetSohStatus(req: String?, clientIdentity: String?): ConnectResponse =
        json {
            val payload = PerformanceApiHandler.sohStatus()
            val wrapped = JSONObject()
                .put("success", payload.optBoolean("success", false))
                .put("nominalCapacityKwh", payload.optDouble("nominalCapacityKwh", 0.0))
                .put("nominalSource", payload.optString("nominalSource", "unset"))
                .put("displaySoh", payload.optDouble("displaySoh", 0.0))
                .put("displaySource", payload.optString("displaySource", "unavailable"))
            if (payload.has("error")) wrapped.put("error", payload.optString("error", ""))
            wrapped
        }

    @Throws(ConnectException::class)
    private fun handleResetSoh(req: String?, clientIdentity: String?): ConnectResponse =
        json { PerformanceApiHandler.sohReset() }

    @Throws(ConnectException::class)
    private fun handleResetPerformance(req: String?, clientIdentity: String?): ConnectResponse =
        // req is a JSON object with a "categories" array field from the proto.
        json {
            val payload = PerformanceApiHandler.resetCategories(req)
            val wrapped = JSONObject().put("success", payload.optBoolean("success", false))
            if (payload.has("results")) {
                wrapped.put("resultsJson", payload.getJSONObject("results").toString())
            }
            if (payload.has("error")) wrapped.put("error", payload.optString("error", ""))
            wrapped
        }

    @Throws(ConnectException::class)
    private fun handleGetParkingDelta(req: String?, clientIdentity: String?): ConnectResponse {
        // Was round-tripped through a query string on a synthetic URL; it is an argument now
        // (BladeWatch-6mnq). 0 means "use the handler's default".
        var maxAgeHours = 72
        try {
            maxAgeHours = JSONObject(req ?: "{}").optInt("maxAgeHours", 72)
        } catch (e: Exception) {
            logger.warn("Failed to parse GetParkingDelta request: " + e.message)
        }
        return json { availabilityEnvelope(PerformanceApiHandler.parkingDelta(maxAgeHours)) }
    }

    @Throws(ConnectException::class)
    private fun handleGetLastCharge(req: String?, clientIdentity: String?): ConnectResponse {
        // Was round-tripped through a query string on a synthetic URL; it is an argument now
        // (BladeWatch-6mnq). 0 means "use the handler's default".
        var hoursBack = 24
        try {
            hoursBack = JSONObject(req ?: "{}").optInt("hoursBack", 24)
        } catch (e: Exception) {
            logger.warn("Failed to parse GetLastCharge request: " + e.message)
        }
        return json { availabilityEnvelope(PerformanceApiHandler.lastCharge(hoursBack)) }
    }

    @Throws(ConnectException::class)
    private fun handleGetSelectedModel(req: String?, clientIdentity: String?): ConnectResponse =
        json { ModelsApiHandler.getSelected() }

    @Throws(ConnectException::class)
    private fun handleSetSelectedModel(req: String?, clientIdentity: String?): ConnectResponse =
        // req proto fields: modelId, color — passed through as-is (the JSON keys match REST).
        json { ModelsApiHandler.setSelected(req) }

    @Throws(ConnectException::class)
    private fun handleGetModelsManifest(req: String?, clientIdentity: String?): ConnectResponse =
        // The proto carries the whole manifest as one opaque string field.
        json { JSONObject().put("manifestJson", ModelsApiHandler.getManifest().toString()) }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("SystemServiceImpl")

        /**
         * {available, rawJson?} for the two history probes. The handler signals "nothing to
         * report" either with an explicit available=false or by returning a payload with no
         * fields beyond that flag, so both are treated as unavailable.
         */
        fun availabilityEnvelope(payload: JSONObject): JSONObject {
            val available = payload.optBoolean("available", false) || payload.length() > 1
            val wrapped = JSONObject().put("available", available)
            if (available) wrapped.put("rawJson", payload.toString())
            return wrapped
        }
    }
}
