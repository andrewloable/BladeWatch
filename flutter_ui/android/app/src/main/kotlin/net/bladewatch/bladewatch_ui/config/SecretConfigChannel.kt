package net.bladewatch.bladewatch_ui.config

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import org.json.JSONObject

/**
 * `secret_get`/`secret_put`/`secret_delete` over loopback IPC
 * (BladeWatch-ncbb.2) — for the Zrok token dialog and similar settings that
 * store a value in the daemon-owned secret store. Ports the relevant
 * commands from
 * `app/src/main/java/com/loabletech/bladewatch/client/CameraDaemonClient.java`
 * (`getSecret`/`putSecret`/`deleteSecret`); unlike that reference, this
 * never retries internally — a platform-channel call site can retry itself
 * if it wants to, and baking retry into every layer just compounds latency.
 *
 * **Never add a method that reads the whole `auth` section or its
 * `deviceSecret` key** — `net.bladewatch.bladewatch_ui.auth.JwtMinter` is the
 * only caller allowed to touch that value, and it never returns the raw
 * secret to Dart either (see the Security Notes in CLAUDE.md).
 */
class SecretConfigChannel(private val ipc: IpcCommandSender) {

    companion object {
        private const val AUTH_SECTION = "auth"
        private const val DEVICE_SECRET_KEY = "deviceSecret"

        /**
         * Enforces the class-level rule above instead of only documenting it. Dart
         * reaches [get] through a generic `(section, key)` platform-channel call, so
         * without this check `config.get("auth", "deviceSecret")` would hand the raw
         * device secret to Dart — the exact thing the doc forbids, via a method that
         * never mentions auth. No caller does this today; the guard is here so none
         * can start by accident. [net.bladewatch.bladewatch_ui.auth.JwtMinter] is the
         * only sanctioned path to that value.
         */
        private fun rejectAuthSecret(section: String, key: String) {
            if (section.equals(AUTH_SECTION, ignoreCase = true) &&
                key.equals(DEVICE_SECRET_KEY, ignoreCase = true)
            ) {
                throw IllegalArgumentException(
                    "refusing to read auth/deviceSecret through the generic secret channel — use JwtMinter"
                )
            }
        }
    }

    /** Returns the stored value, or null if the key isn't set (an empty or
     *  absent `value` in an otherwise-`ok` response) — distinct from an
     *  [net.bladewatch.bladewatch_ui.ipc.IpcException], which propagates. */
    fun get(section: String, key: String): String? {
        rejectAuthSecret(section, key)
        val response = ipc.sendCommand(
            JSONObject().put("cmd", "secret_get").put("section", section).put("key", key),
        )
        val value = response.optString("value", "")
        return value.ifEmpty { null }
    }

    fun put(section: String, key: String, value: String): Boolean {
        val command = JSONObject()
            .put("cmd", "secret_put")
            .put("section", section)
            .put("key", key)
            .put("value", value)
        return "ok".equals(ipc.sendCommand(command).optString("status"), ignoreCase = true)
    }

    fun delete(section: String, key: String): Boolean {
        val command = JSONObject().put("cmd", "secret_delete").put("section", section).put("key", key)
        return "ok".equals(ipc.sendCommand(command).optString("status"), ignoreCase = true)
    }
}
