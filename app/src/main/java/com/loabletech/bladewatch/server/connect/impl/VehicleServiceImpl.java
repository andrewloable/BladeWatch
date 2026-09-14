package net.bladewatch.app.server.connect.impl;

import net.bladewatch.app.server.GpsApiHandler;
import net.bladewatch.app.server.VehicleControlApiHandler;
import net.bladewatch.app.server.connect.ConnectDispatcher;
import net.bladewatch.app.server.connect.ConnectException;
import net.bladewatch.app.server.connect.ConnectHandlerUtil;
import net.bladewatch.app.server.connect.ConnectResponse;

/**
 * Connect protocol handler for bladewatch.v1.VehicleService.
 *
 * VehicleControlApiHandler routes (GET/POST /api/vehicle/*):
 *   GetState, GetAcDiagnostics, GetSeatDiagnostics, Lock, Unlock, Trunk,
 *   MoveWindow, Flash, FindCar, SetClimate, SetSeat, SetLights, SetAdas,
 *   SetBatteryHeat, GetChargingSchedule, SetChargingSchedule,
 *   GetChargeCap, SetChargeCap
 *
 * GpsApiHandler routes:
 *   GetGpsLocation → GET  /api/gps
 *   StartGps       → POST /api/gps/start
 *   StopGps        → POST /api/gps/stop
 */
public class VehicleServiceImpl {

    public void register(ConnectDispatcher dispatcher) {
        dispatcher.register("bladewatch.v1.VehicleService", "GetState",
                this::handleGetState);
        dispatcher.register("bladewatch.v1.VehicleService", "GetAcDiagnostics",
                this::handleGetAcDiagnostics);
        dispatcher.register("bladewatch.v1.VehicleService", "GetSeatDiagnostics",
                this::handleGetSeatDiagnostics);
        // NOT REGISTERED (BladeWatch-c2h1): Lock, Unlock, Flash, FindCar,
        // SetBatteryHeat, Get/SetChargingSchedule. The proto still declares them so
        // the wire contract is unchanged for existing clients, but none had a local
        // SDK primitive once 61b4d7f removed the BYD cloud, so they could only ever
        // answer NOT_SUPPORTED. No first-party client calls them: web/ dropped the
        // Lock/Unlock/Flash controls by decision (see web/src/app/pages/vehicle/
        // vehicle.component.ts) and the Flutter UI never had them.
        dispatcher.register("bladewatch.v1.VehicleService", "Trunk", this::handleTrunk);
        dispatcher.register("bladewatch.v1.VehicleService", "MoveWindow",
                this::handleMoveWindow);
        dispatcher.register("bladewatch.v1.VehicleService", "SetClimate",
                this::handleSetClimate);
        dispatcher.register("bladewatch.v1.VehicleService", "SetSeat", this::handleSetSeat);
        dispatcher.register("bladewatch.v1.VehicleService", "SetLights",
                this::handleSetLights);
        dispatcher.register("bladewatch.v1.VehicleService", "SetAdas", this::handleSetAdas);
        dispatcher.register("bladewatch.v1.VehicleService", "GetChargeCap",
                this::handleGetChargeCap);
        dispatcher.register("bladewatch.v1.VehicleService", "SetChargeCap",
                this::handleSetChargeCap);
        dispatcher.register("bladewatch.v1.VehicleService", "GetGpsLocation",
                this::handleGetGpsLocation);
        dispatcher.register("bladewatch.v1.VehicleService", "StartGps",
                this::handleStartGps);
        dispatcher.register("bladewatch.v1.VehicleService", "StopGps",
                this::handleStopGps);
    }

    private ConnectResponse handleGetState(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("GET", "/api/vehicle/state", null, out));
    }

    private ConnectResponse handleGetAcDiagnostics(String req, String clientIdentity) throws ConnectException {
        // REST emits {success, ac:{...}}; proto GetAcDiagnosticsResponse has a
        // string raw_json (json rawJson). Stringify the ac object into rawJson.
        org.json.JSONObject body = ConnectHandlerUtil.capture(out ->
                VehicleControlApiHandler.handle("GET", "/api/vehicle/ac-diagnostics", null, out));
        return reshapeObjectToJsonString(body, "ac", "rawJson");
    }

    private ConnectResponse handleGetSeatDiagnostics(String req, String clientIdentity) throws ConnectException {
        // REST emits {success, seats:{...}}; proto GetSeatDiagnosticsResponse has
        // a string raw_json (json rawJson). Stringify the seats object into rawJson.
        org.json.JSONObject body = ConnectHandlerUtil.capture(out ->
                VehicleControlApiHandler.handle("GET", "/api/vehicle/seat-diagnostics", null, out));
        return reshapeObjectToJsonString(body, "seats", "rawJson");
    }

    private ConnectResponse handleTrunk(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("POST", "/api/vehicle/trunk", req, out));
    }

    private ConnectResponse handleMoveWindow(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("POST", "/api/vehicle/window", req, out));
    }

    private ConnectResponse handleSetClimate(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("POST", "/api/vehicle/climate", req, out));
    }

    private ConnectResponse handleSetSeat(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("POST", "/api/vehicle/seat", req, out));
    }

    private ConnectResponse handleSetLights(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("POST", "/api/vehicle/lights", req, out));
    }

    private ConnectResponse handleSetAdas(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("POST", "/api/vehicle/adas", req, out));
    }

    private ConnectResponse handleGetChargeCap(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("GET", "/api/vehicle/charge-cap", null, out));
    }

    private ConnectResponse handleSetChargeCap(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                VehicleControlApiHandler.handle("POST", "/api/vehicle/charge-cap", req, out));
    }

    private ConnectResponse handleGetGpsLocation(String req, String clientIdentity) throws ConnectException {
        // REST emits {success, location:{...}, googleMapsUrl}; proto
        // GetGpsLocationResponse has a string location_json (json locationJson).
        // Stringify the location object into locationJson.
        org.json.JSONObject body = ConnectHandlerUtil.capture(out ->
                GpsApiHandler.handle("GET", "/api/gps", null, out));
        return reshapeObjectToJsonString(body, "location", "locationJson");
    }

    private ConnectResponse handleStartGps(String req, String clientIdentity) throws ConnectException {
        // REST emits {success, message, location:{...}}; proto StartGpsResponse
        // has a string location_json (json locationJson).
        org.json.JSONObject body = ConnectHandlerUtil.capture(out ->
                GpsApiHandler.handle("POST", "/api/gps/start", req, out));
        return reshapeObjectToJsonString(body, "location", "locationJson");
    }

    private ConnectResponse handleStopGps(String req, String clientIdentity) throws ConnectException {
        return ConnectHandlerUtil.captureString(out ->
                GpsApiHandler.handle("POST", "/api/gps/stop", req, out));
    }

    /**
     * Reshape a captured REST response whose {@code fromKey} holds a nested JSON
     * object into the proto's flat string field {@code toKey} (the object
     * stringified). Other top-level keys (success, googleMapsUrl, message) are
     * preserved. If {@code fromKey} is absent or null, it is simply dropped.
     */
    private static ConnectResponse reshapeObjectToJsonString(
            org.json.JSONObject body, String fromKey, String toKey) throws ConnectException {
        try {
            Object v = body.opt(fromKey);
            body.remove(fromKey);
            if (v != null && v != org.json.JSONObject.NULL) {
                body.put(toKey, v.toString());
            }
            return ConnectResponse.of(body.toString());
        } catch (Exception e) {
            throw new ConnectException("internal", "An internal error occurred");
        }
    }
}
