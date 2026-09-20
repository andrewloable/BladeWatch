package net.bladewatch.app.server

import net.bladewatch.app.audio.MediaVolumeController
import net.bladewatch.app.byd.AdasFieldInventory
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.byd.BydVehicleData
import net.bladewatch.app.byd.routing.VehicleCommandRouter
import net.bladewatch.app.byd.routing.VehicleCommandRouter.CommandResult
import net.bladewatch.app.byd.routing.VehicleCommandRouter.VehicleCommand
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale
import kotlin.math.roundToLong

/**
 * The Vehicle Control page's operations. Every write routes through [VehicleCommandRouter].
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/vehicle/ paths and writing JSON into an
 * OutputStream that the Connect layer captured straight back out. Every operation now RETURNS its
 * JSON.
 *
 * handleIssueActionToken went with the dispatch: BladeWatch-jwko put the issuer on
 * VehicleService.IssueActionToken, which mints the token directly. Keeping this copy would be a
 * second implementation of a security primitive, which is how the gate it belongs to drifted in
 * the first place.
 */
object VehicleControlApiHandler {

    private val logger: DaemonLogger = DaemonLogger.getInstance("VehicleControlApi")

    /**
     * Current vehicle state relevant to the control page: doors, windows, trunk, lock status, SOC,
     * range.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleGetState(): JSONObject {
        val response = JSONObject()
        val collector = BydDataCollector.getInstance()
        val data = collector.data

        if (data == null) {
            response.put("success", false)
            response.put("error", Messages.get("errors.vehicle_data_unavailable"))
            return response
        }

        response.put("success", true)

        // Door lock status: 1=locked, 2=unlocked, -1=unknown.
        // Index: 0=LF, 1=RF, 2=LR, 3=RR, 4=trunk, 5=unused, 6=overall(derived).
        //
        // BydDataCollector reads BYDAutoDoorLockDevice locally using the recovered legacy app's
        // getDoorLockStatus(area)/getDoorLockState path. Some firmwares return INVALID(0) for
        // every local area; values stay at -1 when the SDK reports no data.
        //
        // The BYD bodywork SDK area numbering swaps L to R on the FRONT axis vs the physical
        // doors: array index 0 (SDK "LEFT_FRONT") is physically right-front, index 1 is
        // left-front. The REAR axis on this car matches the SDK declaration as-is — see
        // DoorEventNotifier for the open/close-event side of this mapping. The rear pair below is
        // a pre-existing assumption from this code path and has not yet been field-verified for
        // lock state; if a single-door bench test on a real car shows rear lock state arriving
        // with the same asymmetric pattern, swap [2] and [3] back to SDK order.
        val doors = JSONObject()
        val lockStatus = data.doorLockStatus
        if (lockStatus != null && lockStatus.size >= 7) {
            doors.put("rf", lockStatus[0])
            doors.put("lf", lockStatus[1])
            doors.put("rr", lockStatus[2])
            doors.put("lr", lockStatus[3])
            doors.put("trunk", lockStatus[4])
            doors.put("hood", lockStatus[5])
            doors.put("overall", lockStatus[6])
        }
        response.put("doors", doors)

        // Window open percent: 0=closed, 100=fully open, -1=unknown. Some BYD firmwares return
        // 255 for absent/unsupported roof devices; never pass that through as a percentage or the
        // UI renders "255%". Index: 0=LF, 1=RF, 2=LR, 3=RR, 4=sunroof, 5=sunshade.
        val windows = JSONObject()
        val openPercent = data.windowOpenPercent
        if (openPercent != null && openPercent.size >= 4) {
            windows.put("lf", sanitizePercent(openPercent[0]))
            windows.put("rf", sanitizePercent(openPercent[1]))
            windows.put("lr", sanitizePercent(openPercent[2]))
            windows.put("rr", sanitizePercent(openPercent[3]))
            if (openPercent.size >= 5) {
                windows.put("sunroof", preferredPercent(data.sunroofPosition, openPercent[4]))
            }
            if (openPercent.size >= 6) {
                windows.put("sunshade", preferredPercent(data.sunshadePercent, openPercent[5]))
            }
        }
        response.put("windows", windows)

        val capabilities = JSONObject()
        val windowCaps = JSONObject()
        val sunroofWindowPercent =
            if (openPercent != null && openPercent.size >= 5) openPercent[4]
            else BydVehicleData.UNAVAILABLE
        val sunshadeWindowPercent =
            if (openPercent != null && openPercent.size >= 6) openPercent[5]
            else BydVehicleData.UNAVAILABLE
        val sunroofSupported =
            isValidPercent(preferredPercent(data.sunroofPosition, sunroofWindowPercent)) ||
                isValidPercent(data.sunroofPosition) ||
                isValidSunroofState(data.sunroofState)
        val sunshadeSupported =
            isValidPercent(preferredPercent(data.sunshadePercent, sunshadeWindowPercent)) ||
                isValidPercent(data.sunshadePercent)
        windowCaps.put("sunroof", sunroofSupported)
        windowCaps.put("sunshade", sunshadeSupported)
        capabilities.put("windows", windowCaps)
        val seatCaps = JSONObject()
        seatCaps.put("driverHeat", collector.isSeatHeatingSupported(1))
        seatCaps.put("passengerHeat", collector.isSeatHeatingSupported(2))
        seatCaps.put("driverCool", collector.isSeatVentilationSupported)
        seatCaps.put("passengerCool", collector.isSeatVentilationSupported)
        seatCaps.put("driverMemoryRecall", collector.isDriverSeatMemoryRecallSupported)
        capabilities.put("seats", seatCaps)
        response.put("capabilities", capabilities)

        // Trunk/tailgate status from extended bodywork. doorLockStatus[4] is the trunk lock.
        val trunk = JSONObject()
        if (lockStatus != null && lockStatus.size >= 5) {
            trunk.put("lockStatus", lockStatus[4])
        }
        response.put("trunk", trunk)

        // Sunroof
        val sunroof = JSONObject()
        if (data.sunroofState != BydVehicleData.UNAVAILABLE) {
            sunroof.put("state", data.sunroofState)
        }
        if (data.sunroofPosition != BydVehicleData.UNAVAILABLE) {
            sunroof.put("position", data.sunroofPosition)
        }
        response.put("sunroof", sunroof)

        // Battery info for display
        val battery = JSONObject()
        if (!data.socPercent.isNaN()) battery.put("soc", data.socPercent)
        if (data.elecRangeKm != BydVehicleData.UNAVAILABLE) {
            battery.put("rangeKm", data.elecRangeKm)
        }
        if (data.bodyworkRangeKm != BydVehicleData.UNAVAILABLE) {
            battery.put("bodyworkRangeKm", data.bodyworkRangeKm)
        }
        // PHEV fuel leg, omitted entirely on a BEV — see BatteryStatus in vehicle.proto.
        // fuelPercent is NaN when the HAL has no tank reading, and a negative value is the
        // collector's "unavailable", so both are excluded rather than sent as a 0 the UI would
        // render as a real empty tank.
        if (!data.fuelPercent.isNaN() && data.fuelPercent >= 0) {
            battery.put("fuelPercent", data.fuelPercent)
        }
        if (data.fuelRangeKm != BydVehicleData.UNAVAILABLE) {
            battery.put("fuelRangeKm", data.fuelRangeKm)
        }
        response.put("battery", battery)

        // Lights
        val lights = JSONObject()
        lights.put("lowBeam", data.lowBeam)
        lights.put("highBeam", data.highBeam)
        lights.put("hazard", data.hazard)
        lights.put("dayTimeLight", data.dayTimeLight)
        response.put("lights", lights)

        // ADAS
        val adas = JSONObject()
        adas.put("speedLimitWarning", data.speedLimitWarning)
        response.put("adas", adas)

        // Seats — heating/cooling levels for driver/passenger ([0-2], 0=off)
        val seats = JSONObject()
        val seatHeat = data.seatHeat
        if (seatHeat != null && seatHeat.isNotEmpty()) {
            val heat = JSONArray()
            for (v in seatHeat) heat.put(v)
            seats.put("heat", heat)
        }
        val seatCool = data.seatCool
        if (seatCool != null && seatCool.isNotEmpty()) {
            val cool = JSONArray()
            for (v in seatCool) cool.put(v)
            seats.put("cool", cool)
        }
        // ventilatedSupported: hardware capability. Cars without ventilated seats (Atto 3 base,
        // certain Seal trims) report hasFeature("SEAT_VENTILATING")=0; the UI greys out the cool
        // buttons on that.
        seats.put("ventilatedSupported", collector.isSeatVentilationSupported)
        response.put("seats", seats)

        // Climate — only report AC state if vehicle power is on (powerLevel >= 2), otherwise
        // stale cached data shows AC on when the car is actually off.
        val climate = JSONObject()
        val vehiclePoweredOn =
            data.powerLevel != BydVehicleData.UNAVAILABLE && data.powerLevel >= 2
        if (data.acStartState != BydVehicleData.UNAVAILABLE) {
            climate.put("acOn", vehiclePoweredOn && data.acStartState == 1)
        }
        // Setpoint and cabin temperature come from DIFFERENT positions of the same getter.
        // Both used to read position 1, so "inside temperature" was the driver's chosen
        // setpoint: it tracked the stepper exactly and never rose on a hot day. Measured on
        // the head unit with the cabin at 36C, position 1 read 24 — the setpoint —
        // and position 4 read 36. See BydDataCollector.AC_TEMP_POS_CABIN (BladeWatch-gkjl).
        val temps = selectClimateTemps(
            setpointRaw = collector.getAcTemperature(BydDataCollector.AC_TEMP_POS_SETPOINT),
            cabinRaw = collector.getAcTemperature(BydDataCollector.AC_TEMP_POS_CABIN),
            cachedInsideC = data.insideTempC,
        )
        temps.setpointC?.let { climate.put("setpointC", it) }
        temps.insideTempC?.let { climate.put("insideTempC", it) }
        if (data.acWindMode != BydVehicleData.UNAVAILABLE) {
            climate.put("windMode", data.acWindMode)
        }
        val acWindLevel = collector.acWindLevel
        if (acWindLevel in 0..7 && vehiclePoweredOn) {
            climate.put("fanLevel", acWindLevel)
        } else if (data.acFanLevel != BydVehicleData.UNAVAILABLE && vehiclePoweredOn) {
            climate.put("fanLevel", data.acFanLevel)
        }
        val acMaxCoolingState = collector.acMaxCoolingState
        if (acMaxCoolingState >= 0) climate.put("maxCooling", acMaxCoolingState == 1)
        response.put("climate", climate)

        // Tyres — per-corner pressure (kPa + PSI), temperature, and the three independent state
        // enums (pressure under/over, slow/fast leak, signal lost). Indexed [FL, FR, RL, RR]. The
        // web UI's tyre callouts read this block directly; if any required source is missing the
        // corner falls back to {available:false} so the UI shows a grey "no signal" state.
        val tyres = JSONObject()
        val anyTyreData = data.tyrePressure != null ||
            data.tyrePressureState != null ||
            data.tyreAirLeakState != null ||
            data.tyreSignalState != null ||
            data.tyreTemperature != null
        if (anyTyreData) {
            val keys = arrayOf("fl", "fr", "rl", "rr")
            for (i in keys.indices) {
                val t = JSONObject()
                val pressure = data.tyrePressure
                val kPa = if (pressure != null && i < pressure.size) {
                    pressure[i]
                } else {
                    BydVehicleData.UNAVAILABLE
                }
                if (kPa != BydVehicleData.UNAVAILABLE && kPa > 0) {
                    t.put("kPa", kPa)
                    // PSI = kPa * 0.1450377 (matches the AutoCommander UnitFormatter conversion).
                    // One decimal place is enough to distinguish the ±3 kPa steps the BYD TPMS
                    // actually reports — integer rounding collapses 247/250/253 kPa all to 36
                    // psi, hiding real change.
                    t.put("psi", (kPa * 0.1450377 * 10.0).roundToLong() / 10.0)
                }
                val temps = data.tyreTemperature
                if (temps != null && i < temps.size && temps[i] != BydVehicleData.UNAVAILABLE) {
                    t.put("temperatureC", temps[i])
                }
                val pressureState = data.tyrePressureState
                if (pressureState != null && i < pressureState.size) {
                    t.put("pressureState", pressureState[i])
                }
                val airLeakState = data.tyreAirLeakState
                if (airLeakState != null && i < airLeakState.size) {
                    t.put("airLeakState", airLeakState[i])
                }
                val signalState = data.tyreSignalState
                if (signalState != null && i < signalState.size) {
                    t.put("signalState", signalState[i])
                }
                // Available = we got at least one valid pressure reading.
                t.put("available", t.has("kPa"))
                tyres.put(keys[i], t)
            }
            tyres.put("available", true)
        } else {
            tyres.put("available", false)
        }
        response.put("tyres", tyres)

        // BladeWatch-2000.2: the real current value, not a local guess -- read straight from
        // MediaVolumeController rather than tracked separately here.
        try {
            val volume = MediaVolumeController.getInstance()
            response.put("mediaVolumePercent", volume.getVolumePercent())
            response.put("mediaMuted", volume.isMuted())
        } catch (e: Exception) {
            logger.warn("Failed to read media volume state: " + e.message)
        }

        // The engine telemetry block was removed: the BYD Auto SDK's engineCoolantLevel /
        // oilLevel / waterTempC / gearMode feeds were producing unreliable values on the test
        // PHEV (cold-engine sentinels, conflicting Engine vs Setting device readings, a raw
        // 28/254 oil dipstick that AutoCommander itself refuses to display). Don't reintroduce
        // without verifying each field against the cluster's own readout first.

        response.put("timestamp", data.timestamp)
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun handleSeatDiagnostics(): JSONObject {
        val response = JSONObject()
        response.put("success", true)
        response.put("seats", BydDataCollector.getInstance().diagnoseSeatCapabilities())
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun handleAcDiagnostics(): JSONObject {
        val response = JSONObject()
        response.put("success", true)
        response.put("ac", BydDataCollector.getInstance().diagnoseAc())
        return response
    }

    /**
     * Read-only: which of BladeWatch's declared ADAS_* feature ids actually resolve from the real
     * BYD SDK on this car, versus silently falling back to a hardcoded literal
     * (BladeWatch-2pnn.3). Never writes to the vehicle. Gated by the same JWT auth as every other
     * VehicleService call (AuthMiddleware.checkAuth, checked centrally in HttpServer before any
     * handler runs).
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleAdasInventory(): JSONObject {
        val response = JSONObject()
        response.put("success", true)
        response.put(
            "adas",
            AdasFieldInventory.probe(BydDataCollector.getInstance().adasDevice)
        )
        return response
    }

    /**
     * Trunk CLOSE and STOP, routed via the command router. Both are local SDK.
     *
     * **OPEN IS NOT SUPPORTED and must not be reintroduced without a real interlock.** Open used
     * to be cloud unlock then SDK tailgate, with the router firing the motor ONLY on unlock
     * SUCCESS. Commit 61b4d7f deleted the cloud unlock, which left `openTailgate()` being called
     * unconditionally: on a locked car the body controller may decline the motor or set off the
     * alarm, with nothing warning the driver. Removed in BladeWatch-c2h1.
     *
     * Close and stop are safe by construction: neither opens anything, and both map to real local
     * primitives (`closeTailgate` / `stopTailgate`).
     *
     * Body: `{ "action": "close" | "stop" }`. Anything else answers NOT_SUPPORTED.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleTrunk(body: String?): JSONObject {
        var action = ""
        if (!body.isNullOrEmpty()) {
            try {
                action = JSONObject(body).optString("action", "")
            } catch (ignored: Exception) {
                logger.warn("Failed to parse trunk body: " + ignored.message)
            }
        }
        val cmd: VehicleCommand = when (action) {
            "close" -> VehicleCommandRouter.TrunkCloseCommand()
            "stop" -> VehicleCommandRouter.TrunkStopCommand()
            else -> {
                // Includes "open" and the previous default of "open" on a missing action.
                logger.info("Trunk: action=$action not supported")
                return routedResponse(
                    CommandResult.notSupported(VehicleCommandRouter.notSupportedMessage()),
                    if (action.isEmpty()) "trunk" else action
                )
            }
        }

        val r = VehicleCommandRouter.getInstance().execute(cmd)
        logger.info("Trunk: action=" + action + " routed result=" + r.outcome + " path=" + r.path)
        return routedResponse(r, action)
    }

    /**
     * Window control routed through the command router.
     *
     * Body: one of
     *  - `{ "area": 1-4 (LF/RF/LR/RR) or 0 for all, "command": 1=open, 2=close, 3=stop }`
     *  - `{ "area": 0, "targetPercent": 0..100 }` (all side windows)
     *  - `{ "area": 1-4, "targetPercent": 0..100 }`
     *  - `{ "area": 5-6 (sunroof, sunshade), "targetPercent": 0..100 }`
     *
     * area=0 + command=2 routes through CloseAllWindowsCommand, which has its own local primitive
     * (setAllWindowsCommand(2)). Every path here is local SDK — the cloud CLOSEWINDOW strategy was
     * removed in 61b4d7f.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleWindow(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val req = JSONObject(body)
            // Connect/proto clients send windowIndex (the same 0=all/1=LF.. scheme the handler
            // uses for area) and a direction string ("open"/"close"). windowIndex==0 ("all") is a
            // proto default scalar and omitted on the wire, so its absence correctly maps to area
            // 0. The legacy web UI sends area + command (1=open, 2=close, 3=stop).
            val area = if (req.has("windowIndex")) {
                req.optInt("windowIndex", 0)
            } else {
                req.optInt("area", 0)
            }

            // targetPercent → SDK closed-loop positioning
            if (req.has("targetPercent")) {
                if (area < 0 || area > 6) {
                    response.put("success", false)
                    response.put(
                        "error", Messages.get("errors.vehicle_window_target_requires_area")
                    )
                    return response
                }
                val target = req.getInt("targetPercent")
                val r = VehicleCommandRouter.getInstance()
                    .execute(VehicleCommandRouter.WindowMoveCommand(area, 0, target))
                logger.info(
                    "Window: area=" + areaName(area) + " target=" + target + "% " + r.outcome
                )
                val resp = routedResponse(r, "window-target")
                resp.put("area", area)
                resp.put("targetPercent", target)
                return resp
            }

            // direction (proto) takes precedence over the legacy command int.
            val command: Int = if (req.has("direction")) {
                when (req.optString("direction", "close")) {
                    "open" -> 1
                    "stop" -> 3
                    else -> 2
                }
            } else {
                req.optInt("command", 2) // default close
            }
            // "Close all" has its own SDK primitive (setAllWindowsCommand) rather than looping the
            // four windows. It no longer works while the car is asleep — that came from the cloud
            // CLOSEWINDOW command, removed in 61b4d7f.
            val cmd: VehicleCommand = if (area == 0 && command == 2) {
                VehicleCommandRouter.CloseAllWindowsCommand()
            } else {
                VehicleCommandRouter.WindowMoveCommand(area, command, null)
            }
            val r = VehicleCommandRouter.getInstance().execute(cmd)
            logger.info(
                "Window: area=" + areaName(area) + " cmd=" + windowCmdName(command) + " " +
                    r.outcome
            )
            val resp = routedResponse(r, "window")
            resp.put("area", area)
            resp.put("command", command)
            return resp
        } catch (e: Exception) {
            logger.warn("Window command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * Climate control routed through the command router. Every action is local SDK. power_on /
     * power_off used to be cloud-first (OPENAIR / CLOSEAIR) with an SDK fallback; the cloud leg
     * was removed in 61b4d7f, leaving only what was the fallback.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleClimate(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val req = JSONObject(body)
            val action = req.optString("action", "")
            val cmd = buildClimateCommand(action, req)
            if (cmd == null) {
                logger.warn("Climate: unknown action '$action'")
                response.put("success", false)
                response.put(
                    "error",
                    Messages.get("errors.vehicle_unknown_action_with_action", action)
                )
                return response
            }
            val r = VehicleCommandRouter.getInstance().execute(cmd)
            logger.info("Climate: action=" + action + " " + r.outcome + " path=" + r.path)
            return routedResponse(r, action)
        } catch (e: Exception) {
            logger.warn("Climate command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * Pure parser: maps a climate `action` plus its JSON body to the [VehicleCommand] it should
     * dispatch, or null for an unrecognised action (it never throws on that — [handleClimate]
     * turns a null into the existing "unknown action" error response). Extracted so
     * BladeWatch-2000.1's four new actions, and the five pre-existing ones, are testable without
     * an HTTP round trip — mirrors [parseLightsRequest]'s shape.
     *
     * Connect/proto clients send camelCase json-names and OMIT default scalars (false/0); the
     * legacy web UI sends its own names and always sends booleans explicitly. Read the proto key
     * when present, else fall back to the legacy key — see the pre-existing cases below for the
     * established convention this follows.
     *
     * Public rather than module-internal because ClimateCommandParserTest reaches it from a
     * different package.
     */
    @JvmStatic
    fun buildClimateCommand(action: String, req: JSONObject): VehicleCommand? = when (action) {
        "power_on" -> {
            val t = if (req.has("setpointC")) {
                req.optDouble("setpointC", 22.0)
            } else {
                req.optDouble("temp", 22.0)
            }
            VehicleCommandRouter.ClimateOnCommand(t)
        }
        "power_off" -> VehicleCommandRouter.ClimateOffCommand()
        "set_temp" -> {
            val zone = req.optInt("zone", 1)
            val t = if (req.has("setpointC")) {
                req.optDouble("setpointC", 22.0)
            } else {
                req.optDouble("temp", 22.0)
            }
            VehicleCommandRouter.ClimateSetTempCommand(zone, t)
        }
        "set_fan" -> {
            val fan = if (req.has("fanLevel")) req.optInt("fanLevel", 3) else req.optInt("fan", 3)
            VehicleCommandRouter.ClimateSetFanCommand(fan)
        }
        "max_cooling" -> {
            val enabled = if (req.has("maxCooling")) {
                req.optBoolean("maxCooling", false)
            } else {
                req.optBoolean("enabled", false)
            }
            val hasRestore = req.optBoolean("hasRestore", true)
            val restoreTemp = if (req.has("restoreTempC")) {
                req.optDouble("restoreTempC", 22.0)
            } else {
                req.optDouble("restoreTemp", 22.0)
            }
            val restoreFan = if (req.has("restoreFanLevel")) {
                req.optInt("restoreFanLevel", 3)
            } else {
                req.optInt("restoreFan", 3)
            }
            val restorePowerOn = if (req.has("restoreAcOn")) {
                req.optBoolean("restoreAcOn", false)
            } else {
                req.optBoolean("restorePowerOn", false)
            }
            VehicleCommandRouter.ClimateMaxCoolingCommand(
                enabled, hasRestore, restoreTemp, restoreFan, restorePowerOn
            )
        }
        // BladeWatch-2000.1 below. "on" is already a plain (non-optional) proto bool on
        // SetClimateRequest, so a false request value arrives on the wire as an absent key —
        // optBoolean's false default already matches that, same as every other plain-bool field
        // on this same message.
        "front_defrost" -> VehicleCommandRouter.FrontDefrostCommand(req.optBoolean("on", false))
        "rear_defrost" -> VehicleCommandRouter.RearDefrostCommand(req.optBoolean("on", false))
        "set_wind_mode" -> VehicleCommandRouter.ClimateSetWindModeCommand(
            req.optInt("windMode", req.optInt("wind_mode", 0))
        )
        "set_cycle_mode" -> VehicleCommandRouter.ClimateSetCycleModeCommand(
            req.optInt("cycleMode", req.optInt("cycle_mode", 0))
        )
        else -> null
    }

    /**
     * Seat heating / ventilation / memory-recall — local SDK. This was cloud-first
     * (VENTILATIONHEATING) with an SDK fallback until 61b4d7f removed the cloud leg.
     *
     * The full-state payload is a leftover of that: the cloud command was stateful, so heat+vent
     * commands carried the FULL state of driver+passenger seats, and the client still sends it on
     * every seat command. Harmless, but do not mistake it for something the SDK path needs.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleSeat(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val req = JSONObject(body)
            val action = req.optString("action", "heating")
            // Connect/proto clients send seatIndex (1=driver, 2=passenger); the legacy web UI
            // sends position. Read the proto key when present.
            val position = if (req.has("seatIndex")) {
                req.optInt("seatIndex", 1)
            } else {
                req.optInt("position", 1)
            }
            val level = req.optInt("level", 0)
            val dh = req.optInt("driverHeat", 0)
            val dv = req.optInt("driverVent", 0)
            val ph = req.optInt("passengerHeat", 0)
            val pv = req.optInt("passengerVent", 0)
            val cmd: VehicleCommand = when (action) {
                "ventilation" -> VehicleCommandRouter.SeatVentCommand(position, level, dh, dv, ph, pv)
                "position" -> VehicleCommandRouter.SeatMemoryCommand(position)
                else -> VehicleCommandRouter.SeatHeatCommand(position, level, dh, dv, ph, pv)
            }
            val r = VehicleCommandRouter.getInstance().execute(cmd)
            logger.info(
                "Seat: action=" + action + " pos=" + seatPosName(position) +
                    " level=" + level + " " + r.outcome
            )
            val resp = routedResponse(r, action)
            resp.put("position", position)
            resp.put("level", level)
            return resp
        } catch (e: Exception) {
            logger.warn("Seat command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * Parsed result for lights/ADAS requests. A non-null [error] means a parse failure.
     *
     * Public rather than module-internal because LightsAdasParserTest is Java, and Kotlin mangles
     * `internal` names on the JVM.
     */
    class ToggleRequestParse private constructor(
        @JvmField val target: String?,
        @JvmField val enable: Boolean,
        @JvmField val error: String?
    ) {
        companion object {
            @JvmStatic
            fun ok(target: String?, enable: Boolean): ToggleRequestParse =
                ToggleRequestParse(target, enable, null)

            @JvmStatic
            fun err(error: String?): ToggleRequestParse =
                ToggleRequestParse(null, false, error)
        }
    }

    /**
     * Pure parser for lights requests. Accepts proto names first ("action"/"on"), falls back to
     * legacy names ("target"/"enable"). Errors if no boolean key is present.
     */
    @JvmStatic
    fun parseLightsRequest(req: JSONObject): ToggleRequestParse {
        // Accept proto "action" first, fall back to legacy "target"
        val target = if (req.has("action")) {
            req.optString("action", null)
        } else {
            req.optString("target", null)
        }
        if ("dayTimeLight" != target) {
            return ToggleRequestParse.err(
                Messages.get("errors.vehicle_unsupported_target_with_target", target)
            )
        }
        // Accept proto "on" first, fall back to legacy "enable"; an absent boolean is an error
        val enable = when {
            req.has("on") -> req.optBoolean("on", false)
            req.has("enable") -> req.optBoolean("enable", false)
            else -> return ToggleRequestParse.err("lights requires 'on'")
        }
        return ToggleRequestParse.ok(target, enable)
    }

    /**
     * Pure parser for ADAS requests. Accepts proto names first ("action"/"on"), falls back to
     * legacy names ("target"/"enable"). Errors if no boolean key is present.
     */
    @JvmStatic
    fun parseAdasRequest(req: JSONObject): ToggleRequestParse {
        // Accept proto "action" first, fall back to legacy "target"
        val target = if (req.has("action")) {
            req.optString("action", null)
        } else {
            req.optString("target", null)
        }
        if ("speedLimitWarning" != target) {
            return ToggleRequestParse.err(
                Messages.get("errors.vehicle_unsupported_target_with_target", target)
            )
        }
        // Accept proto "on" first, fall back to legacy "enable"; an absent boolean is an error
        val enable = when {
            req.has("on") -> req.optBoolean("on", false)
            req.has("enable") -> req.optBoolean("enable", false)
            else -> return ToggleRequestParse.err("adas requires 'on'")
        }
        return ToggleRequestParse.ok(target, enable)
    }

    /**
     * Light controls — SDK_ONLY routed.
     *
     * Body: `{ "action": "dayTimeLight", "on": true|false }` (ConnectRPC) or
     * `{ "target": "dayTimeLight", "enable": true|false }` (legacy REST).
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleLights(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val parsed = parseLightsRequest(JSONObject(body))
            if (parsed.error != null) {
                response.put("success", false)
                response.put("error", parsed.error)
                return response
            }
            val r = VehicleCommandRouter.getInstance()
                .execute(VehicleCommandRouter.LightsCommand(parsed.enable))
            logger.info(
                "Lights: target=dayTimeLight enable=" + parsed.enable + " " + r.outcome
            )
            val resp = routedResponse(r, "lights")
            resp.put("target", parsed.target)
            resp.put("enable", parsed.enable)
            return resp
        } catch (e: Exception) {
            logger.warn("Light command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * Screen on/off — SDK_ONLY routed (BladeWatch-2000.3).
     *
     * Body: `{ "on": true|false }`. A missing 'on' is a parse error, same as lights/ADAS. OFF is
     * gated by the normal motion interlock; ON is not (see
     * `VehicleCommandRouter.ScreenOnCommand#allowedWhileUnsafe`) — giving the driver their screen
     * back is never the unsafe direction.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleScreen(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val req = JSONObject(body)
            if (!req.has("on")) {
                response.put("success", false)
                response.put("error", "screen requires 'on'")
                return response
            }
            val on = req.optBoolean("on", false)
            val cmd: VehicleCommand = if (on) {
                VehicleCommandRouter.ScreenOnCommand()
            } else {
                VehicleCommandRouter.ScreenOffCommand()
            }
            val r = VehicleCommandRouter.getInstance().execute(cmd)
            logger.info("Screen: on=" + on + " " + r.outcome)
            val resp = routedResponse(r, "screen")
            resp.put("on", on)
            return resp
        } catch (e: Exception) {
            logger.warn("Screen command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * Media volume/mute (BladeWatch-2000.2). Android AudioManager only — no BYD SDK, deliberately
     * not routed through VehicleCommandRouter (adjusting volume is ordinary, safe-while-driving
     * behaviour, unlike the actuations that class gates).
     *
     * Body: `{ "action": "set"|"step_up"|"step_down"|"mute"|"unmute", "percent"?: 0-100 }`.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleMediaVolume(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val req = JSONObject(body)
            val action = req.optString("action", "")
            val volume = MediaVolumeController.getInstance()
            when (action) {
                "set" -> {
                    if (!req.has("percent")) {
                        response.put("success", false)
                        response.put("error", "media-volume 'set' requires 'percent'")
                        return response
                    }
                    volume.setVolumePercent(req.getInt("percent"))
                }
                "step_up" -> volume.stepUp()
                "step_down" -> volume.stepDown()
                "mute" -> volume.mute()
                "unmute" -> volume.unmute()
                else -> {
                    response.put("success", false)
                    response.put(
                        "error",
                        "media-volume requires 'action' to be one of: " +
                            "set, step_up, step_down, mute, unmute"
                    )
                    return response
                }
            }
            logger.info(
                "MediaVolume: action=" + action + " -> " + volume.getVolumePercent() +
                    "% muted=" + volume.isMuted()
            )
            response.put("success", true)
            response.put("outcome", "success")
            response.put("mediaVolumePercent", volume.getVolumePercent())
            response.put("mediaMuted", volume.isMuted())
            return response
        } catch (e: Exception) {
            logger.warn("Media volume command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * ADAS controls — SDK_ONLY routed.
     *
     * Body: `{ "action": "speedLimitWarning", "on": true|false }` (ConnectRPC) or
     * `{ "target": "speedLimitWarning", "enable": true|false }` (legacy REST).
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleAdas(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val parsed = parseAdasRequest(JSONObject(body))
            if (parsed.error != null) {
                response.put("success", false)
                response.put("error", parsed.error)
                return response
            }
            val r = VehicleCommandRouter.getInstance()
                .execute(VehicleCommandRouter.AdasSpeedLimitWarningCommand(parsed.enable))
            logger.info(
                "Adas: target=speedLimitWarning enable=" + parsed.enable + " " + r.outcome
            )
            val resp = routedResponse(r, "adas")
            resp.put("target", parsed.target)
            resp.put("enable", parsed.enable)
            return resp
        } catch (e: Exception) {
            logger.warn("Adas command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * BEV charge cap — SDK_ONLY via BYDAutoChargingDevice setChargeStopCapacityState +
     * setChargeStopSwitchState. The Seal HAL historically reports getChargeStopSupportConfig=0;
     * the collector probes via write-then-read-back on the first successful write, and the read
     * returns supported=false on no-op trims so the UI can hide the section.
     *
     * Body: `{ percent?: 50..100, enabled?: bool }`. When both are present the toggle runs first
     * so a freshly-enabled cap picks up the new percent.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleChargeCap(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val req = if (body.isNullOrEmpty()) JSONObject() else JSONObject(body)
            val hasPercent = req.has("percent")
            val hasEnabled = req.has("enabled")
            if (!hasPercent && !hasEnabled) {
                response.put("success", false)
                response.put(
                    "error",
                    Messages.get("errors.vehicle_unknown_action_with_action", "charge-cap")
                )
                return response
            }

            var last: CommandResult? = null
            var action: String? = null

            if (hasEnabled) {
                val enabled = req.getBoolean("enabled")
                val r = VehicleCommandRouter.getInstance()
                    .execute(VehicleCommandRouter.ChargeCapToggleCommand(enabled))
                logger.info("ChargeCap: toggle enabled=" + enabled + " " + r.outcome)
                last = r
                action = "charge-cap-toggle"
                if (r.outcome != VehicleCommandRouter.Outcome.SUCCESS && hasPercent) {
                    val resp = routedResponse(r, action)
                    resp.put("enabled", enabled)
                    return resp
                }
            }

            if (hasPercent) {
                val percent = req.getInt("percent")
                if (percent < 50 || percent > 100) {
                    response.put("success", false)
                    response.put("error", "percent must be 50..100 (got $percent)")
                    return response
                }
                val r = VehicleCommandRouter.getInstance()
                    .execute(VehicleCommandRouter.ChargeCapPercentCommand(percent))
                logger.info("ChargeCap: percent=" + percent + " " + r.outcome)
                last = r
                action = "charge-cap-percent"
            }

            val resp = routedResponse(last!!, action)
            if (hasPercent) resp.put("percent", req.getInt("percent"))
            if (hasEnabled) resp.put("enabled", req.getBoolean("enabled"))
            // Surface the probe result so the UI can hide on the next paint.
            BydDataCollector.getInstance().isChargeCapSupported?.let {
                resp.put("supported", it)
            }
            return resp
        } catch (e: Exception) {
            logger.warn("ChargeCap command failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            return response
        }
    }

    /**
     * BEV charge cap state — SDK reads. Returns the last-known target percent and on/off, plus a
     * `supported` flag derived from the write-read-back probe (null until the user has saved at
     * least once).
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleGetChargeCap(): JSONObject {
        val resp = JSONObject()
        try {
            val collector = BydDataCollector.getInstance()
            val percent = collector.chargeCapPercent
            val enabled = collector.chargeCapEnabled
            val supported = collector.isChargeCapSupported
            resp.put("success", true)
            resp.put("percent", if (percent >= 0) percent else JSONObject.NULL)
            when (enabled) {
                0 -> resp.put("enabled", false)
                1 -> resp.put("enabled", true)
                else -> resp.put("enabled", JSONObject.NULL)
            }
            // Tri-state: null = not yet probed (show optimistically), true/false = the probe
            // result from the last write.
            resp.put("supported", supported ?: JSONObject.NULL)
            logger.info(
                "ChargeCap GET → percent=" + percent + " enabled=" + enabled +
                    " supported=" + supported
            )
        } catch (e: Exception) {
            logger.warn("ChargeCap read failed: " + e.message)
            resp.put("success", false)
            resp.put("error", e.message)
        }
        return resp
    }

    // ==================== LOG HELPERS ====================

    private fun areaName(area: Int): String = when (area) {
        0 -> "all"
        1 -> "LF"
        2 -> "RF"
        3 -> "LR"
        4 -> "RR"
        5 -> "Sunroof"
        6 -> "Sunshade"
        else -> "?($area)"
    }

    private fun windowCmdName(cmd: Int): String = when (cmd) {
        1 -> "open"
        2 -> "close"
        3 -> "stop"
        else -> "?($cmd)"
    }

    private fun seatPosName(pos: Int): String = when (pos) {
        1 -> "driver"
        2 -> "passenger"
        3 -> "rear-left"
        4 -> "rear-right"
        else -> "?($pos)"
    }

    // ==================== HELPERS ====================

    private fun isValidPercent(value: Int): Boolean = value in 0..100

    private fun sanitizePercent(value: Int): Int = if (isValidPercent(value)) value else -1

    private fun preferredPercent(primary: Int, fallback: Int): Int =
        if (isValidPercent(primary)) primary else sanitizePercent(fallback)

    private fun isValidSunroofState(value: Int): Boolean =
        value != BydVehicleData.UNAVAILABLE && value >= 0 && value < 255

    /**
     * Build the response JSON shape the vehicle-control UI expects:
     * `{ success, path, latencyMs, message, action, outcome, commandSuccess }`.
     *
     *  - `success` is true on routed SUCCESS,
     *  - `path` is "local" or "none" (CommandResult.pathString maps Path.SDK to "local",
     *    everything else to "none"; the old "cloud" / "cloud-then-local" values went with the
     *    cloud path in 61b4d7f),
     *  - `message` is a localized user-facing string,
     *  - `commandSuccess` mirrors `success` so legacy UI branches still work.
     */
    private fun routedResponse(r: CommandResult, action: String?): JSONObject {
        val resp = JSONObject()
        try {
            val success = r.outcome == VehicleCommandRouter.Outcome.SUCCESS
            resp.put("success", success)
            resp.put("commandSuccess", success)
            resp.put("path", r.pathString())
            resp.put("latencyMs", r.latencyMs)
            resp.put("message", r.displayMessage)
            resp.put("outcome", r.outcome.name.lowercase(Locale.ROOT))
            resp.put("action", action)
            if (!success && r.error != null && r.error.message != null) {
                resp.put("error", r.error.message)
            } else if (!success) {
                resp.put("error", r.displayMessage)
            }
        } catch (ignored: Exception) {
            logger.warn("Failed to build routed response JSON: " + ignored.message)
        }
        return resp
    }

    /** What [handleVehicleStatus] should report for the two climate temperatures. */
    data class ClimateTemps(val setpointC: Int?, val insideTempC: Double?)

    /**
     * Picks the climate setpoint and the cabin temperature from the two raw
     * `getTemprature(position)` readings, plus the collector's cached cabin value as a
     * fallback. A null field means OMIT it from the response.
     *
     * Extracted as a pure `@JvmStatic` so the decision is testable without a live
     * [BydDataCollector], which needs a real BYD head unit — the same reason
     * `StorageManager.selectFilesToDelete` was extracted.
     *
     * The bug this encodes against (BladeWatch-gkjl): both values used to be read from
     * position 1, so the Vehicle screen showed the driver's chosen setpoint as the cabin
     * reading. It tracked the temperature stepper exactly and never rose on a hot day.
     * Measured on the head unit with the cabin at 36C, position 1 read 24 and position 4
     * read 36.
     *
     * When no reading passes its range check the field is omitted rather than defaulted: the
     * Flutter side maps absent/0.0 to null and hides the row, which is the honest degraded
     * state. Showing a plausible-but-wrong number is precisely what went wrong here.
     */
    @JvmStatic
    internal fun selectClimateTemps(setpointRaw: Int, cabinRaw: Int, cachedInsideC: Double): ClimateTemps {
        val setpoint = setpointRaw.takeIf { it in BydDataCollector.AC_SETPOINT_RANGE_C }
        val inside = when {
            cabinRaw in BydDataCollector.CABIN_TEMP_RANGE_C -> cabinRaw.toDouble()
            !cachedInsideC.isNaN() -> cachedInsideC
            else -> null
        }
        return ClimateTemps(setpoint, inside)
    }
}
