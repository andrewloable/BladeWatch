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

    fun putBoolean(section: String, key: String, value: Boolean): Boolean {
        val command = JSONObject()
            .put("cmd", "config_put")
            .put("section", section)
            .put("key", key)
            .put("value", value)
        return "ok".equals(ipc.sendCommand(command).optString("status"), ignoreCase = true)
    }
}
