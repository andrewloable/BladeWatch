package net.bladewatch.app.server.connect.impl

import android.util.Base64
import com.google.protobuf.Descriptors
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.server.SurveillanceApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONException
import org.json.JSONObject
import java.util.Collections

/**
 * Connect protocol handler for bladewatch.v1.SurveillanceService.
 *
 * Routes (SurveillanceApiHandler):
 *   GetConfig    → getConfig
 *   SetConfig    → setConfig
 *   GetStatus    → getStatus
 *   Enable       → enable
 *   Disable      → disable
 *   GetHeatmap   → getHeatmap
 *   GetSnapshot  → getQuadrantSnapshotJpeg
 *   GetFilterLog → getFilterLog
 *   SyncCatalog  → reconcile
 */
class SurveillanceServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register(
            "bladewatch.v1.SurveillanceService", "GetConfig", this::handleGetConfig
        )
        dispatcher.register(
            "bladewatch.v1.SurveillanceService", "SetConfig", this::handleSetConfig
        )
        dispatcher.register(
            "bladewatch.v1.SurveillanceService", "GetStatus", this::handleGetStatus
        )
        dispatcher.register("bladewatch.v1.SurveillanceService", "Enable", this::handleEnable)
        dispatcher.register("bladewatch.v1.SurveillanceService", "Disable", this::handleDisable)
        dispatcher.register(
            "bladewatch.v1.SurveillanceService", "GetHeatmap", this::handleGetHeatmap
        )
        dispatcher.register(
            "bladewatch.v1.SurveillanceService", "GetSnapshot", this::handleGetSnapshot
        )
        dispatcher.register(
            "bladewatch.v1.SurveillanceService", "GetFilterLog", this::handleGetFilterLog
        )
        dispatcher.register(
            "bladewatch.v1.SurveillanceService", "SyncCatalog", this::handleSyncCatalog
        )
    }

    @Throws(ConnectException::class)
    private fun handleGetConfig(req: String?, clientIdentity: String?): ConnectResponse =
        json { SurveillanceApiHandler.getConfig() }

    @Throws(ConnectException::class)
    private fun handleSetConfig(req: String?, clientIdentity: String?): ConnectResponse {
        // The Connect client wraps the payload as SetSurveillanceConfigRequest.config → wire body
        // {"config":{...}}, but the REST handler parses a FLAT body. Unwrap the nested config,
        // re-add omitted false toggles, and merge the camera probe override fields
        // (manualCameraId, clearManualCameraId) from the top-level request before forwarding.
        val flatBody: String
        try {
            val r = JSONObject(req.orEmpty())
            val config = r.optJSONObject("config")
            if (config == null) {
                flatBody = req!! // already flat (defensive) — forward unchanged
            } else {
                for (key in CONFIG_BOOLEAN_TOGGLES) {
                    if (!config.has(key)) config.put(key, false)
                }
                // Merge camera probe override fields from the top-level request.
                if (r.has("manualCameraId") && !r.isNull("manualCameraId")) {
                    config.put("manualCameraId", r.getInt("manualCameraId"))
                }
                if (r.optBoolean("clearManualCameraId", false)) {
                    config.put("clearManualCameraId", true)
                }
                flatBody = config.toString()
            }
        } catch (e: JSONException) {
            throw ConnectException("invalid_argument", "Invalid surveillance config body")
        }
        return json { SurveillanceApiHandler.setConfig(flatBody) }
    }

    // Flat GetSurveillanceStatusResponse, reshaped from the nested REST {status:{...}} by
    // flatStatus (BladeWatch-nrwh). What each field means:
    //   pipelineRunning    = the camera pipeline runs. True during plain dashcam recording too.
    //   surveillanceActive = the persisted user preference (surveillance.surveillanceEnabled).
    //                        Not armed: it stays true while sentry is waiting or stopped.
    //   armed              = sentry is processing frames right now. The only "watching" signal.
    //   cameraYielded / nativeAppActive are copied from the REST status (BladeWatch-gyg1.2).
    @Throws(ConnectException::class)
    private fun handleGetStatus(req: String?, clientIdentity: String?): ConnectResponse =
        json {
            flatStatus(
                SurveillanceApiHandler.getStatus().optJSONObject("status"),
                UnifiedConfigManager.isSurveillanceEnabled()
            )
        }

    @Throws(ConnectException::class)
    private fun handleEnable(req: String?, clientIdentity: String?): ConnectResponse =
        json { SurveillanceApiHandler.enable() }

    @Throws(ConnectException::class)
    private fun handleDisable(req: String?, clientIdentity: String?): ConnectResponse =
        json { SurveillanceApiHandler.disable() }

    @Throws(ConnectException::class)
    private fun handleGetHeatmap(req: String?, clientIdentity: String?): ConnectResponse =
        json { SurveillanceApiHandler.getHeatmap() }

    @Throws(ConnectException::class)
    private fun handleGetSnapshot(req: String?, clientIdentity: String?): ConnectResponse {
        val quadrant = try {
            JSONObject(req.orEmpty()).optInt("quadrant", 0)
        } catch (ignored: Exception) {
            0
        }
        // The snapshot really is binary. It used to write an HTTP header + JPEG into a stream that
        // ConnectHandlerUtil then parsed back apart; the handler returns the bytes now and they
        // are base64'd straight into imageJpeg (BladeWatch-6mnq).
        return json {
            val jpeg = SurveillanceApiHandler.getQuadrantSnapshotJpeg(quadrant)
            JSONObject().put("imageJpeg", Base64.encodeToString(jpeg, Base64.NO_WRAP))
        }
    }

    @Throws(ConnectException::class)
    private fun handleGetFilterLog(req: String?, clientIdentity: String?): ConnectResponse =
        json { SurveillanceApiHandler.getFilterLog() }

    @Throws(ConnectException::class)
    private fun handleSyncCatalog(req: String?, clientIdentity: String?): ConnectResponse =
        json { SurveillanceApiHandler.reconcile() }

    companion object {
        /**
         * Builds the flat GetSurveillanceStatusResponse body. [status] is the REST "status"
         * object, or null when the daemon gave none. [userEnabled] is the persisted preference,
         * read from UnifiedConfigManager, never from status.enabled (the in-memory intent flag
         * that went stale in BladeWatch-l55j). With a null status only surveillanceActive is set;
         * the protobuf defaults cover the rest.
         */
        @JvmStatic
        internal fun flatStatus(status: JSONObject?, userEnabled: Boolean): JSONObject {
            val flat = JSONObject()
            flat.put("surveillanceActive", userEnabled)
            if (status != null) {
                flat.put("pipelineRunning", status.optBoolean("active", false))
                flat.put("armed", status.optBoolean("armed", false))
                // BladeWatch-gyg1.2: already computed by BydCameraCoordinator and already in the
                // REST status object -- these two field names match exactly, no reshaping.
                flat.put("cameraYielded", status.optBoolean("cameraYielded", false))
                flat.put("nativeAppActive", status.optBoolean("nativeAppActive", false))
            }
            return flat
        }

        /**
         * Boolean config toggles the REST handler reads with has()-gating. The Connect client
         * sends a FULL config snapshot, but JsonFormat omits any bool that is false, so the
         * handler would never see (and never persist) a toggle turned OFF. We re-add every
         * boolean field of SurveillanceConfig as false when absent so OFF sticks.
         *
         * Derived from the proto descriptor so a newly-added bool field is covered automatically
         * — no hand-maintained list to drift out of sync (BladeWatch-mvay). Re-adding a bool the
         * handler ignores (e.g. enabled/aiEnabled, which are owned by the Enable/Disable RPCs) is
         * inert, so deriving the full set is safe.
         */
        @JvmField
        val CONFIG_BOOLEAN_TOGGLES: List<String> = computeConfigBooleanToggles()

        private fun computeConfigBooleanToggles(): List<String> {
            val names = ArrayList<String>()
            for (f in net.bladewatch.app.grpc.v1.SurveillanceConfig.getDescriptor().fields) {
                if (f.type == Descriptors.FieldDescriptor.Type.BOOL) {
                    names.add(f.jsonName)
                }
            }
            return Collections.unmodifiableList(names)
        }
    }
}
