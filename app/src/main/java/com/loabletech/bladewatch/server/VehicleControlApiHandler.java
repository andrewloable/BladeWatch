package net.bladewatch.app.server;

import net.bladewatch.app.auth.AuthManager;
import net.bladewatch.app.byd.BydDataCollector;
import net.bladewatch.app.byd.BydVehicleData;
import net.bladewatch.app.byd.routing.VehicleCommandRouter;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.CommandResult;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.VehicleCommand;
import net.bladewatch.app.logging.DaemonLogger;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.OutputStream;

/**
 * API handler for the Vehicle Control page. All write endpoints route
 * through {@link VehicleCommandRouter}.
 *
 * Endpoints:
 *   GET  /api/vehicle/state         — current door/window/trunk/lock state
 *   GET  /api/vehicle/ac-diagnostics — read-only AC SDK method/getter probe
 *   GET  /api/vehicle/seat-diagnostics — read-only seat hardware/capability probe
 *   GET  /api/vehicle/adas-inventory — read-only: which declared ADAS_* ids actually resolve from the SDK (BladeWatch-2pnn.3)
 *   POST /api/vehicle/lock          — lock
 *   POST /api/vehicle/unlock        — unlock
 *   POST /api/vehicle/trunk         — open/close/stop
 *   POST /api/vehicle/window        — window move
 *   POST /api/vehicle/flash         — flash lights
 *   POST /api/vehicle/find-car      — find car
 *   POST /api/vehicle/climate       — climate control
 *   POST /api/vehicle/seat          — SDK_ONLY
 *   POST /api/vehicle/lights        — SDK_ONLY
 *   POST /api/vehicle/screen        — { on: true|false } SDK_ONLY. ON bypasses the motion
 *                                      interlock (BladeWatch-2000.3); OFF is gated normally.
 *   POST /api/vehicle/media-volume  — { action: "set"|"step_up"|"step_down"|"mute"|"unmute",
 *                                      percent? } (BladeWatch-2000.2). Android AudioManager
 *                                      only -- no BYD SDK, not routed through
 *                                      VehicleCommandRouter, no motion interlock (adjusting
 *                                      volume is safe while driving).
 *   POST /api/vehicle/adas          — SDK_ONLY
 *   POST /api/vehicle/battery-heat  — battery preconditioning
 *   GET  /api/vehicle/charging-schedule  — { enabled, startChargeTime, endChargeTime, chargeWay }
 *   POST /api/vehicle/charging-schedule  — { startChargeTime, endChargeTime, chargeWay, enabled }
 *   GET  /api/vehicle/charge-cap         — { percent, enabled, supported } SDK_ONLY (BYDAutoChargingDevice.getChargeStopCapacityState)
 *   POST /api/vehicle/charge-cap         — { percent?, enabled? } SDK_ONLY
 */
public class VehicleControlApiHandler {

    private static final DaemonLogger logger = DaemonLogger.getInstance("VehicleControlApi");

    public static boolean handle(String method, String path, String body, OutputStream out) throws Exception {
        String cleanPath = path.contains("?") ? path.substring(0, path.indexOf("?")) : path;

        // GET /api/vehicle/action-token — issue a short-lived second-factor token (uy93.5).
        // Required by non-loopback callers for vehicle POST commands; loopback (WebView) is exempt.
        if (cleanPath.equals("/api/vehicle/action-token") && method.equals("GET")) {
            handleIssueActionToken(out);
            return true;
        }

        // GET /api/vehicle/state
        if (cleanPath.equals("/api/vehicle/state") && method.equals("GET")) {
            handleGetState(out);
            return true;
        }

        // GET /api/vehicle/ac-diagnostics
        if (cleanPath.equals("/api/vehicle/ac-diagnostics") && method.equals("GET")) {
            handleAcDiagnostics(out);
            return true;
        }

        // GET /api/vehicle/seat-diagnostics
        if (cleanPath.equals("/api/vehicle/seat-diagnostics") && method.equals("GET")) {
            handleSeatDiagnostics(out);
            return true;
        }

        // GET /api/vehicle/adas-inventory — read-only, on demand only (BladeWatch-2pnn.3)
        if (cleanPath.equals("/api/vehicle/adas-inventory") && method.equals("GET")) {
            handleAdasInventory(out);
            return true;
        }

        // REMOVED in BladeWatch-c2h1 with the rest of the cloud-only surface:
        //   /api/vehicle/{lock,unlock,flash,find-car,battery-heat,charging-schedule}
        // None had a local SDK primitive, so after 61b4d7f deleted the BYD cloud they
        // could only ever answer NOT_SUPPORTED. Trunk OPEN went too — see handleTrunk.

        // POST /api/vehicle/trunk
        if (cleanPath.equals("/api/vehicle/trunk") && method.equals("POST")) {
            handleTrunk(out, body);
            return true;
        }

        // POST /api/vehicle/window
        if (cleanPath.equals("/api/vehicle/window") && method.equals("POST")) {
            handleWindow(out, body);
            return true;
        }

        // POST /api/vehicle/climate
        if (cleanPath.equals("/api/vehicle/climate") && method.equals("POST")) {
            handleClimate(out, body);
            return true;
        }

        // POST /api/vehicle/seat
        if (cleanPath.equals("/api/vehicle/seat") && method.equals("POST")) {
            handleSeat(out, body);
            return true;
        }

        // POST /api/vehicle/lights
        if (cleanPath.equals("/api/vehicle/lights") && method.equals("POST")) {
            handleLights(out, body);
            return true;
        }

        // POST /api/vehicle/screen (BladeWatch-2000.3)
        if (cleanPath.equals("/api/vehicle/screen") && method.equals("POST")) {
            handleScreen(out, body);
            return true;
        }

        // POST /api/vehicle/media-volume (BladeWatch-2000.2)
        if (cleanPath.equals("/api/vehicle/media-volume") && method.equals("POST")) {
            handleMediaVolume(out, body);
            return true;
        }

        // POST /api/vehicle/adas
        if (cleanPath.equals("/api/vehicle/adas") && method.equals("POST")) {
            handleAdas(out, body);
            return true;
        }

        // GET /api/vehicle/charge-cap
        if (cleanPath.equals("/api/vehicle/charge-cap") && method.equals("GET")) {
            handleGetChargeCap(out);
            return true;
        }

        // POST /api/vehicle/charge-cap
        if (cleanPath.equals("/api/vehicle/charge-cap") && method.equals("POST")) {
            handleChargeCap(out, body);
            return true;
        }

        return false;
    }

    /**
     * Issue a short-lived vehicle action token (uy93.5). The token must be
     * presented as X-Vehicle-Action-Token on subsequent POST /api/vehicle/*
     * requests from non-loopback callers. Loopback (WebView) callers skip this.
     */
    private static void handleIssueActionToken(OutputStream out) throws Exception {
        JSONObject resp = new JSONObject();
        AuthManager.AuthState state = AuthManager.getState();
        if (state == null || state.deviceSecret == null || state.deviceSecret.isEmpty()) {
            resp.put("success", false);
            resp.put("error", "Device secret not available");
            HttpResponse.sendJson(out, resp.toString());
            return;
        }
        String token = VehicleActionToken.issue(state.deviceSecret);
        resp.put("success", true);
        resp.put("token", token);
        resp.put("expiresInSeconds", VehicleActionToken.WINDOW_SECONDS);
        HttpResponse.sendJson(out, resp.toString());
    }

    /**
     * Returns current vehicle state relevant to the control page:
     * doors, windows, trunk, lock status, SOC, range.
     */
    private static void handleGetState(OutputStream out) throws Exception {
        JSONObject response = new JSONObject();
        BydDataCollector collector = BydDataCollector.getInstance();
        BydVehicleData data = collector.getData();

        if (data == null) {
            response.put("success", false);
            response.put("error", Messages.get("errors.vehicle_data_unavailable"));
            HttpResponse.sendJson(out, response.toString());
            return;
        }

        response.put("success", true);

        // Door lock status: 1=locked, 2=unlocked, -1=unknown
        // Index: 0=LF, 1=RF, 2=LR, 3=RR, 4=trunk, 5=unused, 6=overall(derived)
        //
        // BydDataCollector reads BYDAutoDoorLockDevice locally using the
        // recovered legacy app's getDoorLockStatus(area)/getDoorLockState path.
        // Some firmwares return INVALID(0) for every local area; values stay
        // at -1 when the SDK reports no data.
        // BYD bodywork SDK area numbering swaps L↔R on the FRONT axis vs the
        // physical doors: array index 0 (SDK "LEFT_FRONT") is physically
        // right-front, index 1 is left-front. The REAR axis on this car
        // matches the SDK declaration as-is — see DoorEventNotifier for the
        // open/close-event side of this mapping. The rear pair below is a
        // pre-existing assumption from this code path and has not yet been
        // field-verified for lock state; if a single-door bench test on a
        // real car shows rear lock state arriving with the same asymmetric
        // pattern, swap [2]↔[3] back to SDK order ([2]=lr, [3]=rr).
        JSONObject doors = new JSONObject();
        if (data.doorLockStatus != null && data.doorLockStatus.length >= 7) {
            doors.put("rf", data.doorLockStatus[0]);
            doors.put("lf", data.doorLockStatus[1]);
            doors.put("rr", data.doorLockStatus[2]);
            doors.put("lr", data.doorLockStatus[3]);
            doors.put("trunk", data.doorLockStatus[4]);
            doors.put("hood", data.doorLockStatus[5]);
            doors.put("overall", data.doorLockStatus[6]);
        }
        response.put("doors", doors);

        // Window open percent [1-6]: 0=closed, 100=fully open, -1=unknown.
        // Some BYD firmwares return 255 for absent/unsupported roof devices;
        // never pass that through as a percentage or the UI renders "255%".
        // Index: 0=LF, 1=RF, 2=LR, 3=RR, 4=sunroof, 5=sunshade
        JSONObject windows = new JSONObject();
        if (data.windowOpenPercent != null && data.windowOpenPercent.length >= 4) {
            windows.put("lf", sanitizePercent(data.windowOpenPercent[0]));
            windows.put("rf", sanitizePercent(data.windowOpenPercent[1]));
            windows.put("lr", sanitizePercent(data.windowOpenPercent[2]));
            windows.put("rr", sanitizePercent(data.windowOpenPercent[3]));
            if (data.windowOpenPercent.length >= 5) {
                windows.put("sunroof", preferredPercent(data.sunroofPosition, data.windowOpenPercent[4]));
            }
            if (data.windowOpenPercent.length >= 6) {
                windows.put("sunshade", preferredPercent(data.sunshadePercent, data.windowOpenPercent[5]));
            }
        }
        response.put("windows", windows);

        JSONObject capabilities = new JSONObject();
        JSONObject windowCaps = new JSONObject();
        int sunroofWindowPercent = data.windowOpenPercent != null && data.windowOpenPercent.length >= 5
                ? data.windowOpenPercent[4] : BydVehicleData.UNAVAILABLE;
        int sunshadeWindowPercent = data.windowOpenPercent != null && data.windowOpenPercent.length >= 6
                ? data.windowOpenPercent[5] : BydVehicleData.UNAVAILABLE;
        boolean sunroofSupported =
                isValidPercent(preferredPercent(data.sunroofPosition, sunroofWindowPercent))
                        || isValidPercent(data.sunroofPosition)
                        || isValidSunroofState(data.sunroofState);
        boolean sunshadeSupported =
                isValidPercent(preferredPercent(data.sunshadePercent, sunshadeWindowPercent))
                        || isValidPercent(data.sunshadePercent);
        windowCaps.put("sunroof", sunroofSupported);
        windowCaps.put("sunshade", sunshadeSupported);
        capabilities.put("windows", windowCaps);
        JSONObject seatCaps = new JSONObject();
        seatCaps.put("driverHeat", collector.isSeatHeatingSupported(1));
        seatCaps.put("passengerHeat", collector.isSeatHeatingSupported(2));
        seatCaps.put("driverCool", collector.isSeatVentilationSupported());
        seatCaps.put("passengerCool", collector.isSeatVentilationSupported());
        seatCaps.put("driverMemoryRecall", collector.isDriverSeatMemoryRecallSupported());
        capabilities.put("seats", seatCaps);
        response.put("capabilities", capabilities);

        // Trunk/tailgate status from extended bodywork
        JSONObject trunk = new JSONObject();
        // Back door status from feature ID (if available in toJson)
        // We use doorLockStatus[4] for trunk lock, and check body door status flags
        if (data.doorLockStatus != null && data.doorLockStatus.length >= 5) {
            trunk.put("lockStatus", data.doorLockStatus[4]);
        }
        response.put("trunk", trunk);

        // Sunroof
        JSONObject sunroof = new JSONObject();
        if (data.sunroofState != BydVehicleData.UNAVAILABLE) {
            sunroof.put("state", data.sunroofState);
        }
        if (data.sunroofPosition != BydVehicleData.UNAVAILABLE) {
            sunroof.put("position", data.sunroofPosition);
        }
        response.put("sunroof", sunroof);

        // Battery info for display
        JSONObject battery = new JSONObject();
        if (!Double.isNaN(data.socPercent)) battery.put("soc", data.socPercent);
        if (data.elecRangeKm != BydVehicleData.UNAVAILABLE) battery.put("rangeKm", data.elecRangeKm);
        if (data.bodyworkRangeKm != BydVehicleData.UNAVAILABLE) battery.put("bodyworkRangeKm", data.bodyworkRangeKm);
        // PHEV fuel leg, omitted entirely on a BEV — see BatteryStatus in
        // vehicle.proto. fuelPercent is NaN when the HAL has no tank reading, and
        // a negative value is the collector's "unavailable", so both are excluded
        // rather than sent as a 0 the UI would render as a real empty tank.
        if (!Double.isNaN(data.fuelPercent) && data.fuelPercent >= 0) {
            battery.put("fuelPercent", data.fuelPercent);
        }
        if (data.fuelRangeKm != BydVehicleData.UNAVAILABLE) battery.put("fuelRangeKm", data.fuelRangeKm);
        response.put("battery", battery);

        // Lights
        JSONObject lights = new JSONObject();
        lights.put("lowBeam", data.lowBeam);
        lights.put("highBeam", data.highBeam);
        lights.put("hazard", data.hazard);
        lights.put("dayTimeLight", data.dayTimeLight);
        response.put("lights", lights);

        // ADAS
        JSONObject adas = new JSONObject();
        adas.put("speedLimitWarning", data.speedLimitWarning);
        response.put("adas", adas);

        // Seats — heating/cooling levels for driver/passenger ([0-2], 0=off)
        JSONObject seats = new JSONObject();
        if (data.seatHeat != null && data.seatHeat.length > 0) {
            JSONArray heat = new JSONArray();
            for (int v : data.seatHeat) heat.put(v);
            seats.put("heat", heat);
        }
        if (data.seatCool != null && data.seatCool.length > 0) {
            JSONArray cool = new JSONArray();
            for (int v : data.seatCool) cool.put(v);
            seats.put("cool", cool);
        }
        // ventilatedSeats: hardware capability. Cars without ventilated seats
        // (Atto 3 base, certain Seal trims) report hasFeature("SEAT_VENTILATING")=0.
        // JS uses this to grey out the cool buttons.
        seats.put("ventilatedSupported", collector.isSeatVentilationSupported());
        response.put("seats", seats);

        // Climate — only report AC state if vehicle power is on (powerLevel >= 2)
        // Otherwise stale cached data shows AC on when car is actually off
        JSONObject climate = new JSONObject();
        boolean vehiclePoweredOn = (data.powerLevel != BydVehicleData.UNAVAILABLE && data.powerLevel >= 2);
        if (data.acStartState != BydVehicleData.UNAVAILABLE) {
            climate.put("acOn", vehiclePoweredOn && data.acStartState == 1);
        }
        int acSetpointC = collector.getAcTemperature(1);
        if (acSetpointC >= 16 && acSetpointC <= 35) {
            climate.put("setpointC", acSetpointC);
            climate.put("insideTempC", acSetpointC);
        } else if (!Double.isNaN(data.insideTempC)) {
            climate.put("insideTempC", data.insideTempC);
        }
        if (data.acWindMode != BydVehicleData.UNAVAILABLE) climate.put("windMode", data.acWindMode);
        int acWindLevel = collector.getAcWindLevel();
        if (acWindLevel >= 0 && acWindLevel <= 7 && vehiclePoweredOn) {
            climate.put("fanLevel", acWindLevel);
        } else if (data.acFanLevel != BydVehicleData.UNAVAILABLE && vehiclePoweredOn) {
            climate.put("fanLevel", data.acFanLevel);
        }
        int acMaxCoolingState = collector.getAcMaxCoolingState();
        if (acMaxCoolingState >= 0) climate.put("maxCooling", acMaxCoolingState == 1);
        response.put("climate", climate);

        // Tyres — per-corner pressure (kPa + PSI), temperature, and the three
        // independent state enums (pressure under/over, slow/fast leak, signal
        // lost). Indexed [FL, FR, RL, RR]. The web UI's tyre callouts read this
        // block directly; if any required source is missing the corner falls
        // back to {available:false} so the UI shows a grey "no signal" state.
        JSONObject tyres = new JSONObject();
        boolean anyTyreData = data.tyrePressure != null
                || data.tyrePressureState != null
                || data.tyreAirLeakState != null
                || data.tyreSignalState != null
                || data.tyreTemperature != null;
        if (anyTyreData) {
            String[] keys = { "fl", "fr", "rl", "rr" };
            for (int i = 0; i < keys.length; i++) {
                JSONObject t = new JSONObject();
                int kPa = (data.tyrePressure != null && i < data.tyrePressure.length)
                        ? data.tyrePressure[i] : BydVehicleData.UNAVAILABLE;
                if (kPa != BydVehicleData.UNAVAILABLE && kPa > 0) {
                    t.put("kPa", kPa);
                    // PSI = kPa * 0.1450377 (matches the AutoCommander
                    // UnitFormatter conversion). One decimal place is
                    // enough to distinguish ±3 kPa steps the BYD TPMS
                    // actually reports — integer rounding collapses
                    // 247/250/253 kPa all to 36 psi, hiding real change.
                    double psi = kPa * 0.1450377;
                    t.put("psi", Math.round(psi * 10.0) / 10.0);
                }
                if (data.tyreTemperature != null && i < data.tyreTemperature.length
                        && data.tyreTemperature[i] != BydVehicleData.UNAVAILABLE) {
                    t.put("temperatureC", data.tyreTemperature[i]);
                }
                if (data.tyrePressureState != null && i < data.tyrePressureState.length) {
                    t.put("pressureState", data.tyrePressureState[i]);
                }
                if (data.tyreAirLeakState != null && i < data.tyreAirLeakState.length) {
                    t.put("airLeakState", data.tyreAirLeakState[i]);
                }
                if (data.tyreSignalState != null && i < data.tyreSignalState.length) {
                    t.put("signalState", data.tyreSignalState[i]);
                }
                // Available = we got at least one valid pressure reading.
                t.put("available", t.has("kPa"));
                tyres.put(keys[i], t);
            }
            tyres.put("available", true);
        } else {
            tyres.put("available", false);
        }
        response.put("tyres", tyres);

        // BladeWatch-2000.2: real current value, not a local guess -- read straight from
        // MediaVolumeController rather than tracked separately here.
        try {
            net.bladewatch.app.audio.MediaVolumeController volume =
                net.bladewatch.app.audio.MediaVolumeController.getInstance();
            response.put("mediaVolumePercent", volume.getVolumePercent());
            response.put("mediaMuted", volume.isMuted());
        } catch (Exception e) {
            logger.warn("Failed to read media volume state: " + e.getMessage());
        }

        // Engine telemetry block was removed: the BYD Auto SDK's
        // engineCoolantLevel / oilLevel / waterTempC / gearMode feeds
        // were producing unreliable values on the test PHEV
        // (cold-engine sentinels, conflicting Engine vs Setting device
        // readings, raw 28/254 oil dipstick that AutoCommander itself
        // refuses to display). Don't reintroduce without verifying each
        // field against the cluster's own readout first.

        response.put("timestamp", data.timestamp);
        HttpResponse.sendJson(out, response.toString());
    }

    private static void handleSeatDiagnostics(OutputStream out) throws Exception {
        JSONObject response = new JSONObject();
        response.put("success", true);
        response.put("seats", BydDataCollector.getInstance().diagnoseSeatCapabilities());
        HttpResponse.sendJson(out, response.toString());
    }

    private static void handleAcDiagnostics(OutputStream out) throws Exception {
        JSONObject response = new JSONObject();
        response.put("success", true);
        response.put("ac", BydDataCollector.getInstance().diagnoseAc());
        HttpResponse.sendJson(out, response.toString());
    }

    /**
     * Read-only: which of BladeWatch's declared ADAS_* feature ids actually resolve from the
     * real BYD SDK on this car, versus silently falling back to a hardcoded literal
     * (BladeWatch-2pnn.3). Never writes to the vehicle. Gated by the same JWT auth as every
     * other /api/vehicle/* route (AuthMiddleware.checkAuth, checked centrally in HttpServer
     * before any handler runs).
     */
    private static void handleAdasInventory(OutputStream out) throws Exception {
        JSONObject response = new JSONObject();
        response.put("success", true);
        response.put("adas", net.bladewatch.app.byd.AdasFieldInventory.probe(
                BydDataCollector.getInstance().getAdasDevice()));
        HttpResponse.sendJson(out, response.toString());
    }

    /**
     * Trunk CLOSE and STOP, routed via the command router. Both are local SDK.
     *
     * <p><b>OPEN IS NOT SUPPORTED and must not be reintroduced without a real
     * interlock.</b> Open used to be cloud unlock then SDK tailgate, with the
     * router firing the motor ONLY on unlock SUCCESS. Commit 61b4d7f deleted the
     * cloud unlock, which left {@code openTailgate()} being called unconditionally:
     * on a locked car the body controller may decline the motor or set off the
     * alarm, with nothing warning the driver. Removed in BladeWatch-c2h1.
     *
     * <p>Close and stop are safe by construction: neither opens anything, and both
     * map to real local primitives ({@code closeTailgate} / {@code stopTailgate}).
     *
     * Body: { "action": "close" | "stop" }. Anything else answers NOT_SUPPORTED.
     */
    private static void handleTrunk(OutputStream out, String body) throws Exception {
        String action = "";
        if (body != null && !body.isEmpty()) {
            try { action = new JSONObject(body).optString("action", ""); }
            catch (Exception ignored) {
                logger.warn("Failed to parse trunk body: " + ignored.getMessage());
            }
        }
        VehicleCommand cmd;
        if ("close".equals(action)) {
            cmd = new VehicleCommandRouter.TrunkCloseCommand();
        } else if ("stop".equals(action)) {
            cmd = new VehicleCommandRouter.TrunkStopCommand();
        } else {
            // Includes "open" and the previous default of "open" on a missing action.
            logger.info("Trunk: action=" + action + " not supported");
            HttpResponse.sendJson(out, routedResponse(
                    CommandResult.notSupported(
                            VehicleCommandRouter.notSupportedMessage()),
                    action.isEmpty() ? "trunk" : action).toString());
            return;
        }

        CommandResult r = VehicleCommandRouter.getInstance().execute(cmd);
        logger.info("Trunk: action=" + action + " routed result=" + r.outcome + " path=" + r.path);
        JSONObject resp = routedResponse(r, action);
        HttpResponse.sendJson(out, resp.toString());
    }

    /**
     * Window control routed through the command router.
     * Body: one of:
     *   { "area": 1-4 (LF/RF/LR/RR) or 0 for all, "command": 1=open, 2=close, 3=stop }
     *   { "area": 0,                                "targetPercent": 0..100 } // all side windows
     *   { "area": 1-4,                              "targetPercent": 0..100 }
     *   { "area": 5-6, (Sunroof and Sunshade),      "targetPercent": 0..100 }
     *
     * area=0 + command=2 routes through CloseAllWindowsCommand, which has its own
     * local primitive (setAllWindowsCommand(2)). Every path here is local SDK —
     * the cloud CLOSEWINDOW strategy was removed in 61b4d7f.
     */
    private static void handleWindow(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = new JSONObject(body);
            // Connect/proto clients send windowIndex (same 0=all/1=LF.. scheme
            // the handler uses for area) and a direction string ("open"/"close").
            // windowIndex==0 ("all") is a proto default scalar and omitted on the
            // wire, so its absence correctly maps to area 0. The legacy web UI
            // sends area + command (1=open, 2=close, 3=stop).
            int area = req.has("windowIndex") ? req.optInt("windowIndex", 0) : req.optInt("area", 0);

            // targetPercent → SDK closed-loop positioning
            if (req.has("targetPercent")) {
                if (area < 0 || area > 6) {
                    response.put("success", false);
                    response.put("error", Messages.get("errors.vehicle_window_target_requires_area"));
                    HttpResponse.sendJson(out, response.toString());
                    return;
                }
                int target = req.getInt("targetPercent");
                CommandResult r = VehicleCommandRouter.getInstance()
                        .execute(new VehicleCommandRouter.WindowMoveCommand(area, 0, target));
                logger.info("Window: area=" + areaName(area) + " target=" + target + "% " + r.outcome);
                JSONObject resp = routedResponse(r, "window-target");
                resp.put("area", area);
                resp.put("targetPercent", target);
                HttpResponse.sendJson(out, resp.toString());
                return;
            }

            // direction (proto) takes precedence over the legacy command int.
            int command;
            if (req.has("direction")) {
                String dir = req.optString("direction", "close");
                command = "open".equals(dir) ? 1 : "stop".equals(dir) ? 3 : 2;
            } else {
                command = req.optInt("command", 2); // default close
            }
            VehicleCommand cmd;
            // "Close all" has its own SDK primitive (setAllWindowsCommand) rather than
            // looping the four windows. It no longer works while the car is asleep —
            // that came from the cloud CLOSEWINDOW command, removed in 61b4d7f.
            if (area == 0 && command == 2) {
                cmd = new VehicleCommandRouter.CloseAllWindowsCommand();
            } else {
                cmd = new VehicleCommandRouter.WindowMoveCommand(area, command, null);
            }
            CommandResult r = VehicleCommandRouter.getInstance().execute(cmd);
            logger.info("Window: area=" + areaName(area) + " cmd=" + windowCmdName(command) + " " + r.outcome);
            JSONObject resp = routedResponse(r, "window");
            resp.put("area", area);
            resp.put("command", command);
            HttpResponse.sendJson(out, resp.toString());
        } catch (Exception e) {
            logger.warn("Window command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /**
     * Climate control routed through the command router.
     * Every action is local SDK. power_on / power_off used to be cloud-first
     * (OPENAIR / CLOSEAIR) with an SDK fallback; the cloud leg was removed in
     * 61b4d7f, leaving only what was the fallback.
     * Body: { "action": "power_on"|"power_off"|"set_temp"|"set_fan"|"max_cooling",
     *         "zone": 1|2, "temp": 17-33, "fan": 1-7,
     *         "enabled": true|false, "restoreTemp": 17-33, "restoreFan": 1-7, "restorePowerOn": true|false }
     */
    private static void handleClimate(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = new JSONObject(body);
            String action = req.optString("action", "");
            VehicleCommand cmd = buildClimateCommand(action, req);
            if (cmd == null) {
                logger.warn("Climate: unknown action '" + action + "'");
                response.put("success", false);
                response.put("error", Messages.get("errors.vehicle_unknown_action_with_action", action));
                HttpResponse.sendJson(out, response.toString());
                return;
            }
            CommandResult r = VehicleCommandRouter.getInstance().execute(cmd);
            logger.info("Climate: action=" + action + " " + r.outcome + " path=" + r.path);
            JSONObject resp = routedResponse(r, action);
            HttpResponse.sendJson(out, resp.toString());
        } catch (Exception e) {
            logger.warn("Climate command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /**
     * Pure parser: maps a climate {@code action} + its JSON body to the {@link VehicleCommand}
     * it should dispatch, or {@code null} for an unrecognised action (never throws on that --
     * {@link #handleClimate} turns a null into the existing "unknown action" error response).
     * Extracted so BladeWatch-2000.1's four new actions (and the five pre-existing ones) are
     * testable without an HTTP round trip -- mirrors {@link #parseLightsRequest}'s shape.
     *
     * <p>Connect/proto clients send camelCase json-names and OMIT default scalars (false/0);
     * the legacy web UI sends its own names and always sends booleans explicitly. Read the
     * proto key when present, else fall back to the legacy key -- see the pre-existing cases
     * below for the established convention this follows.
     */
    static VehicleCommand buildClimateCommand(String action, JSONObject req) {
        switch (action) {
            case "power_on": {
                double t = req.has("setpointC") ? req.optDouble("setpointC", 22) : req.optDouble("temp", 22);
                return new VehicleCommandRouter.ClimateOnCommand(t);
            }
            case "power_off":
                return new VehicleCommandRouter.ClimateOffCommand();
            case "set_temp": {
                int zone = req.optInt("zone", 1);
                double t = req.has("setpointC") ? req.optDouble("setpointC", 22) : req.optDouble("temp", 22);
                return new VehicleCommandRouter.ClimateSetTempCommand(zone, t);
            }
            case "set_fan": {
                int fan = req.has("fanLevel") ? req.optInt("fanLevel", 3) : req.optInt("fan", 3);
                return new VehicleCommandRouter.ClimateSetFanCommand(fan);
            }
            case "max_cooling": {
                boolean enabled = req.has("maxCooling")
                        ? req.optBoolean("maxCooling", false)
                        : req.optBoolean("enabled", false);
                boolean hasRestore = req.optBoolean("hasRestore", true);
                double restoreTemp = req.has("restoreTempC")
                        ? req.optDouble("restoreTempC", 22) : req.optDouble("restoreTemp", 22);
                int restoreFan = req.has("restoreFanLevel")
                        ? req.optInt("restoreFanLevel", 3) : req.optInt("restoreFan", 3);
                boolean restorePowerOn = req.has("restoreAcOn")
                        ? req.optBoolean("restoreAcOn", false)
                        : req.optBoolean("restorePowerOn", false);
                return new VehicleCommandRouter.ClimateMaxCoolingCommand(
                        enabled, hasRestore, restoreTemp, restoreFan, restorePowerOn);
            }
            // BladeWatch-2000.1 below. "on" is already a plain (non-optional) proto bool on
            // SetClimateRequest, so a false request value arrives on the wire as an absent
            // key -- optBoolean's false default already matches that, same as every other
            // plain-bool field on this same message.
            case "front_defrost":
                return new VehicleCommandRouter.FrontDefrostCommand(req.optBoolean("on", false));
            case "rear_defrost":
                return new VehicleCommandRouter.RearDefrostCommand(req.optBoolean("on", false));
            case "set_wind_mode":
                return new VehicleCommandRouter.ClimateSetWindModeCommand(req.optInt("windMode", req.optInt("wind_mode", 0)));
            case "set_cycle_mode":
                return new VehicleCommandRouter.ClimateSetCycleModeCommand(req.optInt("cycleMode", req.optInt("cycle_mode", 0)));
            default:
                return null;
        }
    }

    /**
     * Seat heating / ventilation / memory-recall — local SDK. This was cloud-first
     * (VENTILATIONHEATING) with an SDK fallback until 61b4d7f removed the cloud leg.
     *
     * <p>The full-state payload below is a leftover of that: the cloud command was
     * stateful, so heat+vent commands carried the FULL state of driver+passenger
     * seats, and the client still sends it on every seat command. Harmless, but do
     * not mistake it for something the SDK path needs.
     *
     * Body: { "action": "heating"|"ventilation"|"position",
     *         "position": 1-4, "level": 0-3,
     *         "driverHeat": 0-2, "driverVent": 0-2,
     *         "passengerHeat": 0-2, "passengerVent": 0-2 }
     */
    private static void handleSeat(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = new JSONObject(body);
            String action = req.optString("action", "heating");
            // Connect/proto clients send seatIndex (1=driver, 2=passenger); the
            // legacy web UI sends position. Read the proto key when present.
            int position = req.has("seatIndex") ? req.optInt("seatIndex", 1) : req.optInt("position", 1);
            int level = req.optInt("level", 0);
            int dh = req.optInt("driverHeat", 0);
            int dv = req.optInt("driverVent", 0);
            int ph = req.optInt("passengerHeat", 0);
            int pv = req.optInt("passengerVent", 0);
            VehicleCommand cmd;
            if ("ventilation".equals(action)) {
                cmd = new VehicleCommandRouter.SeatVentCommand(position, level, dh, dv, ph, pv);
            } else if ("position".equals(action)) {
                cmd = new VehicleCommandRouter.SeatMemoryCommand(position);
            } else {
                cmd = new VehicleCommandRouter.SeatHeatCommand(position, level, dh, dv, ph, pv);
            }
            CommandResult r = VehicleCommandRouter.getInstance().execute(cmd);
            logger.info("Seat: action=" + action + " pos=" + seatPosName(position)
                    + " level=" + level + " " + r.outcome);
            JSONObject resp = routedResponse(r, action);
            resp.put("position", position);
            resp.put("level", level);
            HttpResponse.sendJson(out, resp.toString());
        } catch (Exception e) {
            logger.warn("Seat command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /** Parsed result for lights/ADAS requests. {@code error != null} means parse failure. */
    static final class ToggleRequestParse {
        final String target;
        final boolean enable;
        final String error;
        private ToggleRequestParse(String target, boolean enable) {
            this.target = target; this.enable = enable; this.error = null;
        }
        private ToggleRequestParse(String error) {
            this.target = null; this.enable = false; this.error = error;
        }
        static ToggleRequestParse ok(String target, boolean enable) { return new ToggleRequestParse(target, enable); }
        static ToggleRequestParse err(String error) { return new ToggleRequestParse(error); }
    }

    /**
     * Pure parser for lights requests. Accepts proto names first ("action"/"on"),
     * falls back to legacy names ("target"/"enable"). Errors if no boolean key present.
     */
    static ToggleRequestParse parseLightsRequest(JSONObject req) {
        // Accept proto "action" first, fall back to legacy "target"
        String target = req.has("action") ? req.optString("action", null) : req.optString("target", null);
        if (!"dayTimeLight".equals(target)) {
            return ToggleRequestParse.err(Messages.get("errors.vehicle_unsupported_target_with_target", target));
        }
        // Accept proto "on" first, fall back to legacy "enable"; absent boolean is an error
        boolean enable;
        if (req.has("on")) {
            enable = req.optBoolean("on", false);
        } else if (req.has("enable")) {
            enable = req.optBoolean("enable", false);
        } else {
            return ToggleRequestParse.err("lights requires 'on'");
        }
        return ToggleRequestParse.ok(target, enable);
    }

    /**
     * Pure parser for ADAS requests. Accepts proto names first ("action"/"on"),
     * falls back to legacy names ("target"/"enable"). Errors if no boolean key present.
     */
    static ToggleRequestParse parseAdasRequest(JSONObject req) {
        // Accept proto "action" first, fall back to legacy "target"
        String target = req.has("action") ? req.optString("action", null) : req.optString("target", null);
        if (!"speedLimitWarning".equals(target)) {
            return ToggleRequestParse.err(Messages.get("errors.vehicle_unsupported_target_with_target", target));
        }
        // Accept proto "on" first, fall back to legacy "enable"; absent boolean is an error
        boolean enable;
        if (req.has("on")) {
            enable = req.optBoolean("on", false);
        } else if (req.has("enable")) {
            enable = req.optBoolean("enable", false);
        } else {
            return ToggleRequestParse.err("adas requires 'on'");
        }
        return ToggleRequestParse.ok(target, enable);
    }

    /**
     * Light controls — SDK_ONLY routed.
     * Body: { "action": "dayTimeLight", "on": true|false }  (ConnectRPC)
     *    or { "target": "dayTimeLight", "enable": true|false } (legacy REST)
     */
    private static void handleLights(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = new JSONObject(body);
            ToggleRequestParse parsed = parseLightsRequest(req);
            if (parsed.error != null) {
                response.put("success", false);
                response.put("error", parsed.error);
                HttpResponse.sendJson(out, response.toString());
                return;
            }
            CommandResult r = VehicleCommandRouter.getInstance()
                    .execute(new VehicleCommandRouter.LightsCommand(parsed.enable));
            logger.info("Lights: target=dayTimeLight enable=" + parsed.enable + " " + r.outcome);
            JSONObject resp = routedResponse(r, "lights");
            resp.put("target", parsed.target);
            resp.put("enable", parsed.enable);
            HttpResponse.sendJson(out, resp.toString());
        } catch (Exception e) {
            logger.warn("Light command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /**
     * Screen on/off — SDK_ONLY routed (BladeWatch-2000.3).
     * Body: { "on": true|false }. Missing 'on' is a parse error, same as lights/ADAS.
     * OFF is gated by the normal motion interlock; ON is not (VehicleCommandRouter.
     * ScreenOnCommand#allowedWhileUnsafe) -- giving the driver their screen back is never the
     * unsafe direction.
     */
    private static void handleScreen(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = new JSONObject(body);
            if (!req.has("on")) {
                response.put("success", false);
                response.put("error", "screen requires 'on'");
                HttpResponse.sendJson(out, response.toString());
                return;
            }
            boolean on = req.optBoolean("on", false);
            VehicleCommandRouter.VehicleCommand cmd = on
                    ? new VehicleCommandRouter.ScreenOnCommand()
                    : new VehicleCommandRouter.ScreenOffCommand();
            CommandResult r = VehicleCommandRouter.getInstance().execute(cmd);
            logger.info("Screen: on=" + on + " " + r.outcome);
            JSONObject resp = routedResponse(r, "screen");
            resp.put("on", on);
            HttpResponse.sendJson(out, resp.toString());
        } catch (Exception e) {
            logger.warn("Screen command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /**
     * Media volume/mute (BladeWatch-2000.2). Android AudioManager only -- no BYD SDK,
     * deliberately not routed through VehicleCommandRouter (see this issue's close reason:
     * adjusting volume is ordinary, safe-while-driving behaviour, unlike the actuations that
     * class gates).
     * Body: { "action": "set"|"step_up"|"step_down"|"mute"|"unmute", "percent"?: 0-100 }.
     */
    private static void handleMediaVolume(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = new JSONObject(body);
            String action = req.optString("action", "");
            net.bladewatch.app.audio.MediaVolumeController volume =
                net.bladewatch.app.audio.MediaVolumeController.getInstance();
            switch (action) {
                case "set":
                    if (!req.has("percent")) {
                        response.put("success", false);
                        response.put("error", "media-volume 'set' requires 'percent'");
                        HttpResponse.sendJson(out, response.toString());
                        return;
                    }
                    volume.setVolumePercent(req.getInt("percent"));
                    break;
                case "step_up":
                    volume.stepUp();
                    break;
                case "step_down":
                    volume.stepDown();
                    break;
                case "mute":
                    volume.mute();
                    break;
                case "unmute":
                    volume.unmute();
                    break;
                default:
                    response.put("success", false);
                    response.put("error", "media-volume requires 'action' to be one of: "
                        + "set, step_up, step_down, mute, unmute");
                    HttpResponse.sendJson(out, response.toString());
                    return;
            }
            logger.info("MediaVolume: action=" + action + " -> " + volume.getVolumePercent()
                + "% muted=" + volume.isMuted());
            response.put("success", true);
            response.put("outcome", "success");
            response.put("mediaVolumePercent", volume.getVolumePercent());
            response.put("mediaMuted", volume.isMuted());
            HttpResponse.sendJson(out, response.toString());
        } catch (Exception e) {
            logger.warn("Media volume command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /**
     * ADAS controls — SDK_ONLY routed.
     * Body: { "action": "speedLimitWarning", "on": true|false }  (ConnectRPC)
     *    or { "target": "speedLimitWarning", "enable": true|false } (legacy REST)
     */
    private static void handleAdas(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = new JSONObject(body);
            ToggleRequestParse parsed = parseAdasRequest(req);
            if (parsed.error != null) {
                response.put("success", false);
                response.put("error", parsed.error);
                HttpResponse.sendJson(out, response.toString());
                return;
            }
            CommandResult r = VehicleCommandRouter.getInstance()
                    .execute(new VehicleCommandRouter.AdasSpeedLimitWarningCommand(parsed.enable));
            logger.info("Adas: target=speedLimitWarning enable=" + parsed.enable + " " + r.outcome);
            JSONObject resp = routedResponse(r, "adas");
            resp.put("target", parsed.target);
            resp.put("enable", parsed.enable);
            HttpResponse.sendJson(out, resp.toString());
        } catch (Exception e) {
            logger.warn("Adas command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /**
     * BEV charge cap — SDK_ONLY via BYDAutoChargingDevice
     * setChargeStopCapacityState + setChargeStopSwitchState. The Seal HAL
     * historically reports getChargeStopSupportConfig=0; the collector probes
     * via write-then-read-back on the first successful POST and the GET
     * returns supported=false on no-op trims so the UI can hide the section.
     *
     * <p>Body: {@code { percent?: 50..100, enabled?: bool }}.
     * When both are present the toggle runs first so a freshly-enabled cap
     * picks up the new percent.
     */
    private static void handleChargeCap(OutputStream out, String body) throws Exception {
        JSONObject response = new JSONObject();
        try {
            JSONObject req = (body == null || body.isEmpty()) ? new JSONObject() : new JSONObject(body);
            boolean hasPercent = req.has("percent");
            boolean hasEnabled = req.has("enabled");
            if (!hasPercent && !hasEnabled) {
                response.put("success", false);
                response.put("error", Messages.get("errors.vehicle_unknown_action_with_action", "charge-cap"));
                HttpResponse.sendJson(out, response.toString());
                return;
            }

            CommandResult last = null;
            String action = null;

            if (hasEnabled) {
                boolean enabled = req.getBoolean("enabled");
                CommandResult r = VehicleCommandRouter.getInstance()
                        .execute(new VehicleCommandRouter.ChargeCapToggleCommand(enabled));
                logger.info("ChargeCap: toggle enabled=" + enabled + " " + r.outcome);
                last = r;
                action = "charge-cap-toggle";
                if (r.outcome != VehicleCommandRouter.Outcome.SUCCESS && hasPercent) {
                    JSONObject resp = routedResponse(r, action);
                    resp.put("enabled", enabled);
                    HttpResponse.sendJson(out, resp.toString());
                    return;
                }
            }

            if (hasPercent) {
                int percent = req.getInt("percent");
                if (percent < 50 || percent > 100) {
                    response.put("success", false);
                    response.put("error", "percent must be 50..100 (got " + percent + ")");
                    HttpResponse.sendJson(out, response.toString());
                    return;
                }
                CommandResult r = VehicleCommandRouter.getInstance()
                        .execute(new VehicleCommandRouter.ChargeCapPercentCommand(percent));
                logger.info("ChargeCap: percent=" + percent + " " + r.outcome);
                last = r;
                action = "charge-cap-percent";
            }

            JSONObject resp = routedResponse(last, action);
            if (hasPercent) resp.put("percent", req.getInt("percent"));
            if (hasEnabled) resp.put("enabled", req.getBoolean("enabled"));
            // Surface the probe result so the UI can hide on the next paint.
            Boolean supported = BydDataCollector.getInstance().isChargeCapSupported();
            if (supported != null) resp.put("supported", supported.booleanValue());
            HttpResponse.sendJson(out, resp.toString());
        } catch (Exception e) {
            logger.warn("ChargeCap command failed: " + e.getMessage());
            response.put("success", false);
            response.put("error", e.getMessage());
            HttpResponse.sendJson(out, response.toString());
        }
    }

    /**
     * BEV charge cap state — SDK reads. Returns last-known target percent and
     * on/off, plus a {@code supported} flag derived from the write-read-back
     * probe (null until the user has saved at least once).
     */
    private static void handleGetChargeCap(OutputStream out) throws Exception {
        JSONObject resp = new JSONObject();
        try {
            BydDataCollector collector = BydDataCollector.getInstance();
            int percent = collector.getChargeCapPercent();
            int enabled = collector.getChargeCapEnabled();
            Boolean supported = collector.isChargeCapSupported();
            resp.put("success", true);
            resp.put("percent", percent >= 0 ? percent : JSONObject.NULL);
            if (enabled == 0) resp.put("enabled", false);
            else if (enabled == 1) resp.put("enabled", true);
            else resp.put("enabled", JSONObject.NULL);
            // Tri-state: null = not yet probed (show optimistically),
            //           true/false = probe result from last write.
            if (supported == null) resp.put("supported", JSONObject.NULL);
            else resp.put("supported", supported.booleanValue());
            logger.info("ChargeCap GET → percent=" + percent + " enabled=" + enabled
                    + " supported=" + supported);
        } catch (Exception e) {
            logger.warn("ChargeCap read failed: " + e.getMessage());
            resp.put("success", false);
            resp.put("error", e.getMessage());
        }
        HttpResponse.sendJson(out, resp.toString());
    }

    // ==================== LOG HELPERS ====================

    private static String areaName(int area) {
        switch (area) {
            case 0: return "all";
            case 1: return "LF";
            case 2: return "RF";
            case 3: return "LR";
            case 4: return "RR";
            case 5: return "Sunroof";
            case 6: return "Sunshade";
            default: return "?(" + area + ")";
        }
    }

    private static String windowCmdName(int cmd) {
        switch (cmd) {
            case 1: return "open";
            case 2: return "close";
            case 3: return "stop";
            default: return "?(" + cmd + ")";
        }
    }

    private static String seatPosName(int pos) {
        switch (pos) {
            case 1: return "driver";
            case 2: return "passenger";
            case 3: return "rear-left";
            case 4: return "rear-right";
            default: return "?(" + pos + ")";
        }
    }

    // ==================== HELPERS ====================

    private static boolean isValidPercent(int value) {
        return value >= 0 && value <= 100;
    }

    private static int sanitizePercent(int value) {
        return isValidPercent(value) ? value : -1;
    }

    private static int preferredPercent(int primary, int fallback) {
        return isValidPercent(primary) ? primary : sanitizePercent(fallback);
    }

    private static boolean isValidSunroofState(int value) {
        return value != BydVehicleData.UNAVAILABLE
                && value >= 0
                && value < 255;
    }

    /**
     * Build the response JSON shape the new vehicle-control UI expects:
     *   { success, path, latencyMs, message, action, outcome, commandSuccess }
     * — `success` is true on routed SUCCESS,
     * — `path` is "local" or "none" (CommandResult.pathString maps Path.SDK to
     *   "local", everything else to "none"; the old "cloud" / "cloud-then-local"
     *   values went with the cloud path in 61b4d7f),
     * — `message` is a localized user-facing string,
     * — `commandSuccess` mirrors `success` so legacy UI branches still work.
     */
    private static JSONObject routedResponse(CommandResult r, String action) {
        JSONObject resp = new JSONObject();
        try {
            boolean success = r.outcome == VehicleCommandRouter.Outcome.SUCCESS;
            resp.put("success", success);
            resp.put("commandSuccess", success);
            resp.put("path", r.pathString());
            resp.put("latencyMs", r.latencyMs);
            resp.put("message", r.displayMessage);
            resp.put("outcome", r.outcome.name().toLowerCase());
            resp.put("action", action);
            if (!success && r.error != null && r.error.getMessage() != null) {
                resp.put("error", r.error.getMessage());
            } else if (!success) {
                resp.put("error", r.displayMessage);
            }
        } catch (Exception ignored) {
            logger.warn("Failed to build routed response JSON: " + ignored.getMessage());
        }
        return resp;
    }
}
