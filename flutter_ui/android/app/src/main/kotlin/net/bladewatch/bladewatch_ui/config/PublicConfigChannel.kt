package net.bladewatch.bladewatch_ui.config

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import org.json.JSONObject

/**
 * `config_get_section`/`config_put` over loopback IPC (BladeWatch-hygs) — the
 * PUBLIC, non-secret half of the daemon's config store
 * (`UnifiedConfigManager`), which backs the Status-overlay and Privacy
 * settings screens.
 *
 * Deliberately separate from [SecretConfigChannel] rather than another method
 * on it: the two wrap different stores with different threat models, and the
 * one thing that must never happen here is a caller reaching the secret store
 * through a method that does not say "secret". The daemon enforces the same
 * split — `config_put` refuses any section outside its own allowlist
 * (`statusOverlay`, `developerOptions`), so a bug on this side cannot widen
 * what is writable.
 *
 * Only booleans are exposed because both screens are switch-only. Add a typed
 * method if a non-boolean setting ever moves here; do not add a generic
 * `Any`-valued put.
 */
class PublicConfigChannel(private val ipc: IpcCommandSender) {

    /**
     * Every key in the section, as booleans. The daemon fills in native's own
     * defaults for absent keys, so an empty map means the call failed — not
     * "everything is off". Callers keep their own fallbacks for that case.
     */
    fun getSection(section: String): Map<String, Boolean> {
        val response = ipc.sendCommand(
            JSONObject().put("cmd", "config_get_section").put("section", section),
        )
        val data = response.optJSONObject("section") ?: return emptyMap()
        return data.keys().asSequence().associateWith { data.optBoolean(it) }
    }

    /**
     * The Diagnostics Camera health tile's two fields (BladeWatch-i2wv), typed,
     * because `probedCameraId` is an Int and [getSection] coerces everything to
     * Boolean. This is the "add a typed method" the class comment calls for, not a
     * generic `Any`-valued read.
     *
     * Mirrors what native's `DiagnosticsFragment.updateCameraTile()` reads straight
     * off `UnifiedConfigManager`: `camera.probedCameraId` and `camera.manualOverride`.
     *
     * Returns null when the read fails, which the caller must NOT confuse with
     * "probe returned -1" — the first means unknown, the second means genuinely not
     * probed yet.
     *
     * READ ONLY. `camera` is on the daemon's readable allowlist but deliberately not
     * its writable one, so there is no matching setter here and there must not be.
     */
    fun getCameraProbe(): CameraProbe? {
        val response = ipc.sendCommand(
            JSONObject().put("cmd", "config_get_section").put("section", "camera"),
        )
        val data = response.optJSONObject("section") ?: return null
        return CameraProbe(
            probedCameraId = data.optInt("probedCameraId", -1),
            manualOverride = data.optBoolean("manualOverride", false),
        )
    }

    data class CameraProbe(val probedCameraId: Int, val manualOverride: Boolean)

    fun putBoolean(section: String, key: String, value: Boolean): Boolean {
        val command = JSONObject()
            .put("cmd", "config_put")
            .put("section", section)
            .put("key", key)
            .put("value", value)
        return "ok".equals(ipc.sendCommand(command).optString("status"), ignoreCase = true)
    }
}
