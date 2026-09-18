package net.bladewatch.app.telemetry

import org.json.JSONArray
import org.json.JSONObject

/**
 * BladeWatch-y78o.5: every field OverlayBitmapRenderer's burned-in telemetry overlay can draw
 * today, and nothing else -- no new fields were added in this issue.
 *
 * GPS latitude/longitude is deliberately NOT a member. OverlayBitmapRenderer.renderFrame()
 * burns it in through a separate, unconditional code path (drawn whenever TelemetrySnapshot
 * .hasGps is true) that this enum and [OverlayFieldSelectionResolver] do not touch, gate, or
 * expose as a toggle -- an explicit product decision (existing installs already ship with GPS
 * coordinates burned into every recording with a fix, and removing or exposing a checklist
 * toggle for that is a separate decision with different tradeoffs than this issue's stated
 * scope, which is field SELECTION for the other telemetry, not a change to what location
 * behaviour ships). The vehicle identification number is not drawn anywhere in this codebase
 * and stays that way.
 */
enum class OverlayField {
    SPEED,
    GEAR,
    TURN_SIGNAL_LEFT,
    TURN_SIGNAL_RIGHT,
    BRAKE_PEDAL,
    ACCEL_PEDAL,
    SEATBELT_DRIVER,
    SEATBELT_PASSENGER,
    TIMESTAMP;

    companion object {
        /** Every field the renderer draws today -- the default for every recording type, so an
         *  existing install with no persisted selection sees no change. */
        @JvmField
        val ALL: Set<OverlayField> = entries.toSet()
    }
}

/**
 * Recording types the overlay field checklist applies to independently. Derived from
 * RecordingModeManager.Mode (CONTINUOUS/DRIVE_MODE) and GpuSurveillancePipeline's recording
 * paths, both read in full: CONTINUOUS and DRIVE_MODE, and proximity-triggered recording
 * (ProximityRecordingHandler.startRecording -> GpuSurveillancePipeline.startRecording(dir,
 * "proximity")), all currently route through the SAME Mode.NORMAL_RECORDING overlay-enabled
 * path in GpuSurveillancePipeline -- confirmed by reading every
 * recorder.setOverlayRecordingModeAllowed(...) call site. Surveillance/sentry recording calls
 * setOverlayRecordingModeAllowed(false) and shows no overlay at all today, independent of any
 * field selection. [CONTINUOUS] and [PROXIMITY] are kept as separate, independently
 * configurable types here anyway (matching the issue's own instruction to enumerate types
 * "plus the surveillance and proximity paths") because a driver may reasonably want a
 * different overlay on ordinary drive footage than on a proximity-triggered clip even though
 * today's renderer does not yet distinguish them at the call site -- see this issue's close
 * reason for the live-wiring scope boundary.
 */
enum class RecordingOverlayType(val configKey: String) {
    CONTINUOUS("continuous"),
    SURVEILLANCE("surveillance"),
    PROXIMITY("proximity"),
}

/**
 * Resolves and updates a recording type's enabled overlay fields, persisted inside
 * UnifiedConfigManager's existing "telemetryOverlay" config section (as a new "fields" child
 * object) rather than a second config section.
 */
object OverlayFieldSelectionResolver {
    /**
     * Reads telemetryOverlay.fields.<type> from a persisted config JSONObject (the section
     * UnifiedConfigManager.getTelemetryOverlay() returns). A null config, a missing "fields"
     * section, or a missing entry for this specific [type] all resolve to [OverlayField.ALL] --
     * exactly today's unconditional behaviour, so an existing install with no "fields" key at
     * all sees no change until it explicitly customises a selection.
     *
     * A name in the array that does not match any [OverlayField] (hand-edited config, a config
     * written by a newer or rolled-back release) is silently dropped rather than thrown on.
     */
    @JvmStatic
    fun resolve(telemetryOverlayConfig: JSONObject?, type: RecordingOverlayType): Set<OverlayField> {
        val fieldsSection = telemetryOverlayConfig?.optJSONObject("fields") ?: return OverlayField.ALL
        if (!fieldsSection.has(type.configKey)) return OverlayField.ALL
        val array = fieldsSection.optJSONArray(type.configKey) ?: return OverlayField.ALL
        val result = mutableSetOf<OverlayField>()
        for (i in 0 until array.length()) {
            val name = array.optString(i, "")
            val field = OverlayField.entries.firstOrNull { it.name.equals(name, ignoreCase = true) }
            if (field != null) result.add(field)
        }
        return result
    }

    /**
     * Returns a copy of [telemetryOverlayConfig] (or a new object if null) with [type]'s
     * selection set to exactly [selection] -- including the empty set, a legal, representable
     * "no fields" state, distinct from "not yet customised".
     */
    @JvmStatic
    fun withSelection(
        telemetryOverlayConfig: JSONObject?,
        type: RecordingOverlayType,
        selection: Set<OverlayField>,
    ): JSONObject {
        val config = telemetryOverlayConfig ?: JSONObject()
        val fieldsSection = config.optJSONObject("fields") ?: JSONObject().also { config.put("fields", it) }
        val array = JSONArray()
        for (field in selection) array.put(field.name)
        fieldsSection.put(type.configKey, array)
        return config
    }
}
