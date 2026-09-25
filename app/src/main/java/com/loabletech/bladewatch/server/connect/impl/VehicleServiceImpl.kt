package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.server.GpsApiHandler
import net.bladewatch.app.server.VehicleActionToken
import net.bladewatch.app.server.VehicleControlApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONObject

/**
 * Connect protocol handler for bladewatch.v1.VehicleService.
 *
 * VehicleControlApiHandler routes:
 *   GetState, GetAcDiagnostics, Trunk, MoveWindow, SetClimate,
 *   SetLights, SetAdas, SetScreen, SetMediaVolume, GetChargeCap, SetChargeCap
 *
 * GpsApiHandler routes:
 *   GetGpsLocation, StartGps, StopGps
 */
class VehicleServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register("bladewatch.v1.VehicleService", "GetState", this::handleGetState)
        dispatcher.register(
            "bladewatch.v1.VehicleService", "GetAcDiagnostics", this::handleGetAcDiagnostics
        )
        // NOT REGISTERED (BladeWatch-c2h1): Lock, Unlock, Flash, FindCar, SetBatteryHeat,
        // Get/SetChargingSchedule. The proto still declares them so the wire contract is unchanged
        // for existing clients, but none had a local SDK primitive once 61b4d7f removed the BYD
        // cloud, so they could only ever answer NOT_SUPPORTED. No first-party client calls them:
        // web/ dropped the Lock/Unlock/Flash controls by decision (see
        // web/src/app/pages/vehicle/vehicle.component.ts) and the Flutter UI never had them.
        dispatcher.register("bladewatch.v1.VehicleService", "Trunk", this::handleTrunk)
        dispatcher.register("bladewatch.v1.VehicleService", "MoveWindow", this::handleMoveWindow)
        dispatcher.register("bladewatch.v1.VehicleService", "SetClimate", this::handleSetClimate)
        dispatcher.register("bladewatch.v1.VehicleService", "SetLights", this::handleSetLights)
        dispatcher.register("bladewatch.v1.VehicleService", "SetAdas", this::handleSetAdas)
        dispatcher.register("bladewatch.v1.VehicleService", "SetScreen", this::handleSetScreen)
        dispatcher.register(
            "bladewatch.v1.VehicleService", "SetMediaVolume", this::handleSetMediaVolume
        )
        dispatcher.register(
            "bladewatch.v1.VehicleService", "GetChargeCap", this::handleGetChargeCap
        )
        dispatcher.register(
            "bladewatch.v1.VehicleService", "SetChargeCap", this::handleSetChargeCap
        )
        dispatcher.register(
            "bladewatch.v1.VehicleService", "GetGpsLocation", this::handleGetGpsLocation
        )
        dispatcher.register("bladewatch.v1.VehicleService", "StartGps", this::handleStartGps)
        dispatcher.register("bladewatch.v1.VehicleService", "StopGps", this::handleStopGps)
        // BladeWatch-jwko: the second factor's issuer. Never gated by VehicleActionGate.
        dispatcher.register(
            "bladewatch.v1.VehicleService", "IssueActionToken", this::handleIssueActionToken
        )
        dispatcher.register(
            "bladewatch.v1.VehicleService", "GetAdasInventory", this::handleGetAdasInventory
        )
    }

    @Throws(ConnectException::class)
    private fun handleGetState(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleGetState() }

    @Throws(ConnectException::class)
    private fun handleGetAdasInventory(req: String?, clientIdentity: String?): ConnectResponse =
        // Read-only probe; not gated by VehicleActionGate because it touches nothing.
        json {
            reshapeObjectToJsonString(
                VehicleControlApiHandler.handleAdasInventory(), "adas", "adasJson"
            )
        }

    @Throws(ConnectException::class)
    private fun handleGetAcDiagnostics(req: String?, clientIdentity: String?): ConnectResponse =
        // REST emits {success, ac:{...}}; proto GetAcDiagnosticsResponse has a string raw_json
        // (json rawJson). Stringify the ac object into rawJson.
        json {
            reshapeObjectToJsonString(
                VehicleControlApiHandler.handleAcDiagnostics(), "ac", "rawJson"
            )
        }

    @Throws(ConnectException::class)
    private fun handleTrunk(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleTrunk(req) }

    @Throws(ConnectException::class)
    private fun handleMoveWindow(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleWindow(req) }

    @Throws(ConnectException::class)
    private fun handleSetClimate(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleClimate(req) }

    @Throws(ConnectException::class)
    private fun handleSetLights(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleLights(req) }

    @Throws(ConnectException::class)
    private fun handleSetAdas(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleAdas(req) }

    @Throws(ConnectException::class)
    private fun handleSetScreen(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleScreen(req) }

    @Throws(ConnectException::class)
    private fun handleSetMediaVolume(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleMediaVolume(req) }

    @Throws(ConnectException::class)
    private fun handleGetChargeCap(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleGetChargeCap() }

    @Throws(ConnectException::class)
    private fun handleSetChargeCap(req: String?, clientIdentity: String?): ConnectResponse =
        json { VehicleControlApiHandler.handleChargeCap(req) }

    /**
     * Issues the short-lived vehicle action token (uy93.5, restored by BladeWatch-jwko).
     *
     * Actuating commands from a non-loopback caller must present it as `X-Vehicle-Action-Token`;
     * loopback callers — the in-car UI — are exempt and never need one. This method itself is
     * never gated, or the token would be unobtainable.
     */
    @Throws(ConnectException::class)
    private fun handleIssueActionToken(req: String?, clientIdentity: String?): ConnectResponse =
        try {
            val resp = JSONObject()
            // Read the secret into a local val before the null/blank check: it is a
            // mutable field on a shared AuthState, so Kotlin cannot smart-cast it
            // across the branch and a concurrent rotation could otherwise change it
            // between the check and the issue() call.
            val secret = AuthManager.getState()?.deviceSecret
            if (secret.isNullOrEmpty()) {
                resp.put("success", false)
                resp.put("error", "Device secret not available")
                ConnectResponse.of(resp.toString())
            } else {
                resp.put("success", true)
                resp.put("token", VehicleActionToken.issue(secret))
                resp.put("expiresInSeconds", VehicleActionToken.WINDOW_SECONDS)
                ConnectResponse.of(resp.toString())
            }
        } catch (e: Exception) {
            throw ConnectException("internal", "An internal error occurred")
        }

    @Throws(ConnectException::class)
    private fun handleGetGpsLocation(req: String?, clientIdentity: String?): ConnectResponse =
        // GpsApiHandler.location() returns {success, location:{...}, googleMapsUrl}; proto
        // GetGpsLocationResponse has a string location_json (json locationJson), so the nested
        // object is stringified into it.
        json { reshapeObjectToJsonString(GpsApiHandler.location(), "location", "locationJson") }

    @Throws(ConnectException::class)
    private fun handleStartGps(req: String?, clientIdentity: String?): ConnectResponse =
        // Same reshape as GetGpsLocation: {success, message, location:{...}} -> locationJson.
        json { reshapeObjectToJsonString(GpsApiHandler.start(), "location", "locationJson") }

    @Throws(ConnectException::class)
    private fun handleStopGps(req: String?, clientIdentity: String?): ConnectResponse =
        json { GpsApiHandler.stop() }

    private companion object {
        /**
         * Reshape a captured REST response whose [fromKey] holds a nested JSON object into the
         * proto's flat string field [toKey] (the object stringified). Other top-level keys
         * (success, googleMapsUrl, message) are preserved. If [fromKey] is absent or null, it is
         * simply dropped.
         */
        fun reshapeObjectToJsonString(
            payload: JSONObject,
            fromKey: String,
            toKey: String
        ): JSONObject {
            val v = payload.opt(fromKey)
            payload.remove(fromKey)
            if (v != null && v !== JSONObject.NULL) {
                payload.put(toKey, v.toString())
            }
            return payload
        }
    }
}
