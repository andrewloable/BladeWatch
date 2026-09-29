package net.bladewatch.app.byd

import org.json.JSONObject

/**
 * The dashboard's drive state (BladeWatch-7zp9): gear, drive mode and Auto Hold as labels, plus
 * the raw SDK values they came from.
 *
 * A label is only what was MEASURED on a head unit, because the SDK does not settle it:
 * BYDAutoEnergyDevice carries two constant families for getOperationMode
 * (ENERGY_OPERATION_MODE_NORMAL=1 / _ECO=2 / _SPORT=3, and ENERGY_OPERATION_ECONOMY=1 / _SPORT=2 /
 * _NORMAL=3), and BYDAutoADASDevice.getAVHState's AUTO_HOLD_STATE1..4 (0..3) are unnamed. A guess
 * would be shown as fact, so an unmeasured value maps to [UNKNOWN] and the dashboard shows "–".
 * The raw values go on the wire so the measurement needs nothing but a status query.
 *
 * Measured on the owner's DM-i head unit 2026-09-25/26 with the owner switching each control:
 * getOperationMode reads 1 in BOTH ECO and NORMAL and 2 in SPORT -- neither constant family fits,
 * and no other getter differs between ECO and NORMAL (a full getter dump in each), so 1 is
 * "ECO/NORMAL", never a guessed one of the two; getAVHState off=0, on=1 (the value while
 * actually holding is not yet measured); getEnergyMode EV=1, HEV=3 (BladeWatch-os88).
 */
object DriveState {
    const val UNKNOWN = "UNKNOWN"

    /** Raw getOperationMode -> label. The car reads 1 for ECO and NORMAL alike. */
    private val DRIVE_MODES: Map<Int, String> = mapOf(1 to "ECO/NORMAL", 2 to "SPORT")

    /** Raw getAVHState -> DISABLED / ENABLED / ACTIVE. ponytail: ACTIVE awaits a measured hold. */
    private val AUTO_HOLD: Map<Int, String> = mapOf(0 to "DISABLED", 1 to "ENABLED")

    /** Raw getEnergyMode -> EV / HEV. */
    private val ENERGY_MODES: Map<Int, String> = mapOf(1 to "EV", 3 to "HEV")

    private val GEARS = setOf("P", "R", "N", "D", "M", "S")

    fun driveMode(raw: Int): String = DRIVE_MODES[raw] ?: UNKNOWN

    fun autoHold(raw: Int): String = AUTO_HOLD[raw] ?: UNKNOWN

    fun energyMode(raw: Int): String = ENERGY_MODES[raw] ?: UNKNOWN

    /** [gear] as RecordingModeManager.gearToString gives it; anything but a gear letter is UNKNOWN. */
    fun toJson(gear: String?, operationModeRaw: Int, autoHoldRaw: Int, energyModeRaw: Int): JSONObject = JSONObject()
        .put("gear", if (gear in GEARS) gear else UNKNOWN)
        .put("driveMode", driveMode(operationModeRaw))
        .put("driveModeRaw", if (operationModeRaw < 0) -1 else operationModeRaw)
        .put("autoHold", autoHold(autoHoldRaw))
        .put("autoHoldRaw", if (autoHoldRaw < 0) -1 else autoHoldRaw)
        .put("energyMode", energyMode(energyModeRaw))
        .put("energyModeRaw", if (energyModeRaw < 0) -1 else energyModeRaw)
}
