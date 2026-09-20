package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.recording.RecordingModeManager
import net.bladewatch.app.server.LocaleManager
import net.bladewatch.app.server.QualitySettingsApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import net.bladewatch.app.telemetry.OverlayField
import net.bladewatch.app.telemetry.OverlayFieldSelectionResolver
import net.bladewatch.app.telemetry.RecordingOverlayType
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * Connect protocol handler for bladewatch.v1.SettingsService.
 *
 * Routes:
 *   GetQuality       → QualitySettingsApiHandler.getQuality
 *   SetQuality       → QualitySettingsApiHandler.setQuality
 *   GetAppearance    → QualitySettingsApiHandler.getAppearance
 *   SetAppearance    → QualitySettingsApiHandler.setAppearance
 *   GetLocale        → LocaleManager directly
 *   SetLocale        → LocaleManager directly
 *   SetRecordingMode → CameraDaemon directly
 */
class SettingsServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register("bladewatch.v1.SettingsService", "GetQuality", this::handleGetQuality)
        dispatcher.register("bladewatch.v1.SettingsService", "SetQuality", this::handleSetQuality)
        dispatcher.register(
            "bladewatch.v1.SettingsService", "GetAppearance", this::handleGetAppearance
        )
        dispatcher.register(
            "bladewatch.v1.SettingsService", "SetAppearance", this::handleSetAppearance
        )
        dispatcher.register("bladewatch.v1.SettingsService", "GetLocale", this::handleGetLocale)
        dispatcher.register("bladewatch.v1.SettingsService", "SetLocale", this::handleSetLocale)
        dispatcher.register(
            "bladewatch.v1.SettingsService", "SetRecordingMode", this::handleSetRecordingMode
        )
        // BladeWatch-qwqq: the last /api/settings/* JSON calls any first-party client still made
        // over REST. These go straight to UnifiedConfigManager and the telemetry resolver rather
        // than wrapping a REST handler — the shape this class is converting to.
        dispatcher.register(
            "bladewatch.v1.SettingsService", "GetStatusOverlay", this::handleGetStatusOverlay
        )
        dispatcher.register(
            "bladewatch.v1.SettingsService", "SetStatusOverlay", this::handleSetStatusOverlay
        )
        dispatcher.register(
            "bladewatch.v1.SettingsService", "GetTelemetryOverlayFields",
            this::handleGetTelemetryOverlayFields
        )
        dispatcher.register(
            "bladewatch.v1.SettingsService", "SetTelemetryOverlayFields",
            this::handleSetTelemetryOverlayFields
        )
    }

    @Throws(ConnectException::class)
    private fun handleGetStatusOverlay(req: String?, clientIdentity: String?): ConnectResponse =
        try {
            val cfg = UnifiedConfigManager.getStatusOverlay()
            ConnectResponse.of(
                JSONObject()
                    .put("success", true)
                    .put("cameraVisible", cfg.optBoolean("cameraVisible", true))
                    .put("tripVisible", cfg.optBoolean("tripVisible", true))
                    .toString()
            )
        } catch (e: Exception) {
            logger.warn("GetStatusOverlay failed: " + e.message)
            throw ConnectException("internal", "An internal error occurred")
        }

    /**
     * Each toggle is optional: omitting one leaves it unchanged, matching the REST body this
     * replaces. Proto3 has no field presence for a bare bool, so the request carries an explicit
     * setCameraVisible/setTripVisible companion — without those, an absent toggle would arrive as
     * false and silently switch the pill OFF.
     */
    @Throws(ConnectException::class)
    private fun handleSetStatusOverlay(req: String?, clientIdentity: String?): ConnectResponse =
        try {
            val input = body(req)
            val patch = JSONObject()
            if (input.optBoolean("setCameraVisible", false)) {
                patch.put("cameraVisible", input.optBoolean("cameraVisible", true))
            }
            if (input.optBoolean("setTripVisible", false)) {
                patch.put("tripVisible", input.optBoolean("tripVisible", true))
            }
            val out = JSONObject()
            if (patch.length() == 0) {
                out.put("success", false)
                out.put("error", "nothing to update")
            } else {
                out.put("success", UnifiedConfigManager.setStatusOverlay(patch))
            }
            val cfg = UnifiedConfigManager.getStatusOverlay()
            out.put("cameraVisible", cfg.optBoolean("cameraVisible", true))
            out.put("tripVisible", cfg.optBoolean("tripVisible", true))
            ConnectResponse.of(out.toString())
        } catch (e: Exception) {
            logger.warn("SetStatusOverlay failed: " + e.message)
            throw ConnectException("internal", "An internal error occurred")
        }

    @Throws(ConnectException::class)
    private fun handleGetTelemetryOverlayFields(
        req: String?,
        clientIdentity: String?
    ): ConnectResponse = try {
        val overlayConfig = UnifiedConfigManager.getTelemetryOverlay()
        val available = JSONArray()
        for (f in OverlayField.values()) available.put(f.name)
        val selections = JSONObject()
        for (t in RecordingOverlayType.values()) {
            val arr = JSONArray()
            for (f in OverlayFieldSelectionResolver.resolve(overlayConfig, t)) arr.put(f.name)
            // The proto models this as map<string, FieldList>, so each entry is an object with a
            // "fields" array rather than a bare array.
            selections.put(t.configKey, JSONObject().put("fields", arr))
        }
        ConnectResponse.of(
            JSONObject()
                .put("success", true)
                .put("availableFields", available)
                .put("selections", selections)
                .toString()
        )
    } catch (e: Exception) {
        logger.warn("GetTelemetryOverlayFields failed: " + e.message)
        throw ConnectException("internal", "An internal error occurred")
    }

    @Throws(ConnectException::class)
    private fun handleSetTelemetryOverlayFields(
        req: String?,
        clientIdentity: String?
    ): ConnectResponse =
        // Kept in the handler rather than reimplemented here: its validation of the recording TYPE
        // is non-trivial, and a second copy of it is what BladeWatch-6mnq exists to avoid.
        json { QualitySettingsApiHandler.setTelemetryOverlayFields(req) }

    @Throws(ConnectException::class)
    private fun handleGetQuality(req: String?, clientIdentity: String?): ConnectResponse =
        json { QualitySettingsApiHandler.getQuality() }

    @Throws(ConnectException::class)
    private fun handleSetQuality(req: String?, clientIdentity: String?): ConnectResponse =
        // REST emits {success, recordingBitrate, recordingCodec, note}; the proto
        // SetQualityResponse expects recording_quality (json recordingQuality), codec (json
        // recordingCodec), message. recordingCodec already matches; map
        // recordingBitrate→recordingQuality (same applied tier) and note→message.
        json {
            val payload = QualitySettingsApiHandler.setQuality(req)
            if (payload.has("recordingBitrate") && !payload.has("recordingQuality")) {
                payload.put("recordingQuality", payload.optString("recordingBitrate", ""))
            }
            val note = payload.optString("note", "")
            if (note.isNotEmpty() && !payload.has("message")) {
                payload.put("message", note)
            }
            payload
        }

    @Throws(ConnectException::class)
    private fun handleGetAppearance(req: String?, clientIdentity: String?): ConnectResponse =
        json { QualitySettingsApiHandler.getAppearance() }

    @Throws(ConnectException::class)
    private fun handleSetAppearance(req: String?, clientIdentity: String?): ConnectResponse =
        json { QualitySettingsApiHandler.setAppearance(req) }

    @Throws(ConnectException::class)
    private fun handleGetLocale(req: String?, clientIdentity: String?): ConnectResponse = try {
        val supported = JSONObject()
        for (s in LocaleManager.SUPPORTED) supported.put(s, true)
        ConnectResponse.of(
            JSONObject()
                .put("lang", LocaleManager.get())
                .put("supported", supported)
                .toString()
        )
    } catch (e: Exception) {
        throw ConnectException("internal", "Failed to get locale: " + e.message)
    }

    @Throws(ConnectException::class)
    private fun handleSetLocale(req: String?, clientIdentity: String?): ConnectResponse = try {
        var want = ""
        try {
            want = JSONObject(req).optString("lang", "")
        } catch (ignored: Exception) {
            logger.warn("Failed to parse locale request body: " + ignored.message)
        }
        val resolved = LocaleManager.set(want)
        ConnectResponse.of("{\"lang\":\"" + resolved + "\"}")
    } catch (e: Exception) {
        throw ConnectException("internal", "Failed to set locale: " + e.message)
    }

    /**
     * Mirrors the inline POST /api/recording/mode route in HttpServer; calls CameraDaemon directly
     * (like Get/SetLocale) rather than shelling a REST handler, since the route has no standalone
     * handler class (BladeWatch-pg0s).
     */
    @Throws(ConnectException::class)
    private fun handleSetRecordingMode(req: String?, clientIdentity: String?): ConnectResponse {
        var mode = ""
        try {
            mode = JSONObject(req).optString("mode", "")
        } catch (ignored: Exception) {
            logger.warn("Failed to parse recording mode request body: " + ignored.message)
        }
        if (mode.isEmpty()) {
            throw ConnectException("invalid_argument", "Missing or invalid field: mode")
        }
        // Validate against the known enum values before passing to CameraDaemon.
        // CameraDaemon.setRecordingMode swallows IllegalArgumentException silently; we must check
        // here so the RPC can return a real error instead of success=true.
        try {
            RecordingModeManager.Mode.valueOf(mode.uppercase(Locale.ROOT))
        } catch (e: IllegalArgumentException) {
            throw ConnectException(
                "invalid_argument",
                "Unknown recording mode: " + mode +
                    ". Valid values: NONE, CONTINUOUS, DRIVE_MODE, PROXIMITY_GUARD"
            )
        }
        return try {
            CameraDaemon.setRecordingMode(mode)
            ConnectResponse.of(
                JSONObject()
                    .put("success", true)
                    .put("mode", mode.uppercase(Locale.ROOT))
                    .toString()
            )
        } catch (e: Exception) {
            throw ConnectException("internal", "Failed to set recording mode: " + e.message)
        }
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("SettingsServiceImpl")
    }
}
