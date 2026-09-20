package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.server.StreamingApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import java.util.Locale

/**
 * Connect protocol handler for bladewatch.v1.StreamService.
 *
 * Routes (StreamingApiHandler):
 *   Enable       → POST /api/stream/enable
 *   Disable      → POST /api/stream/disable
 *   GetStatus    → GET  /api/stream/status
 *   GetQuality   → GET  /api/stream/quality
 *   SetQuality   → POST /api/stream/quality/{tier}   (tier extracted from request JSON)
 *   SetViewMode  → POST /api/stream/view/{mode}      (mode extracted from request JSON)
 *   GetViewMode  → GET  /api/stream/view
 */
class StreamServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register("bladewatch.v1.StreamService", "Enable", this::handleEnable)
        dispatcher.register("bladewatch.v1.StreamService", "Disable", this::handleDisable)
        dispatcher.register("bladewatch.v1.StreamService", "GetStatus", this::handleGetStatus)
        dispatcher.register("bladewatch.v1.StreamService", "GetQuality", this::handleGetQuality)
        dispatcher.register("bladewatch.v1.StreamService", "SetQuality", this::handleSetQuality)
        dispatcher.register("bladewatch.v1.StreamService", "SetViewMode", this::handleSetViewMode)
        dispatcher.register("bladewatch.v1.StreamService", "GetViewMode", this::handleGetViewMode)
    }

    @Throws(ConnectException::class)
    private fun handleEnable(req: String?, clientIdentity: String?): ConnectResponse =
        json { StreamingApiHandler.enableStreaming() }

    @Throws(ConnectException::class)
    private fun handleDisable(req: String?, clientIdentity: String?): ConnectResponse =
        json { StreamingApiHandler.disableStreaming() }

    @Throws(ConnectException::class)
    private fun handleGetStatus(req: String?, clientIdentity: String?): ConnectResponse =
        json { StreamingApiHandler.streamStatus() }

    @Throws(ConnectException::class)
    private fun handleGetQuality(req: String?, clientIdentity: String?): ConnectResponse =
        json { StreamingApiHandler.streamQualityOptions() }

    @Throws(ConnectException::class)
    private fun handleSetQuality(req: String?, clientIdentity: String?): ConnectResponse {
        val tier = try {
            org.json.JSONObject(req).optString("quality", "STANDARD").uppercase(Locale.ROOT)
        } catch (ignored: Exception) {
            "STANDARD"
        }
        return json { StreamingApiHandler.setStreamQuality(tier) }
    }

    @Throws(ConnectException::class)
    private fun handleSetViewMode(req: String?, clientIdentity: String?): ConnectResponse {
        val viewMode = try {
            // Proto SetViewModeRequest.view_mode has no json_name, so the Connect client
            // serializes it to camelCase "viewMode". Accept "view_mode" as a legacy fallback.
            val j = org.json.JSONObject(req)
            if (j.has("viewMode")) j.optInt("viewMode", 0) else j.optInt("view_mode", 0)
        } catch (ignored: Exception) {
            0
        }
        return json { StreamingApiHandler.setStreamViewMode(viewMode) }
    }

    @Throws(ConnectException::class)
    private fun handleGetViewMode(req: String?, clientIdentity: String?): ConnectResponse =
        json { StreamingApiHandler.streamViewMode() }
}
