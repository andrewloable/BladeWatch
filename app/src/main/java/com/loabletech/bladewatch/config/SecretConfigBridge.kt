package net.bladewatch.app.config

import net.bladewatch.app.client.CameraDaemonClient
import net.bladewatch.app.client.DaemonReadinessChecker
import net.bladewatch.app.daemon.AppIntegrityCheck
import android.os.Looper
import android.util.Log
import org.json.JSONObject
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Accessor that prefers direct file access when the current process owns the
 * daemon secret store, and falls back to localhost IPC when it does not.
 */
object SecretConfigBridge {

    private val directStore = SecretConfigStore()
    private val lock = Any()

    // ponytail: test seam — null = real UID-gated directStore (canWriteDirectly()
    // requires shell UID 2000, meaningless off a real device); non-null = an
    // injected store used unconditionally by the write methods a JVM test
    // actually needs (putString/putLong/delete), skipping the UID check and the
    // IPC fallback entirely. Mirrors SecretConfigStore's own legacyPathForTest seam.
    @JvmField var directStoreForTest: SecretConfigStore? = null
    private val ipcExecutor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "secret-config-ipc").apply { isDaemon = true }
    }

    // The synchronized(lock) block guards only the directStore fast-path decision.
    // The IPC fallback runs OUTSIDE the lock: each IPC call creates its own CameraDaemonClient
    // (no shared mutable state), so concurrent callers are safe. Holding lock across a 30-180s
    // IPC call would serialize every config accessor process-wide.

    /**
     * Whether this process may CREATE a secret that others depend on (the device secret every
     * companion token derives from): only the daemon, which owns the store, and only while the
     * store is readable. Everyone else reads through IPC, and "could not read it" -- the app
     * process before the daemon answers, a store read failing -- must never pass for "it does not
     * exist": minting then replaces the real secret and un-pairs every companion (BladeWatch-w7by,
     * seen on the head unit when an install restarted the app before the daemon).
     */
    @JvmStatic
    fun canMintSecrets(): Boolean {
        directStoreForTest?.let { return it.isReadable() }
        return synchronized(lock) {
            try { directStore.canWriteDirectly() && directStore.isReadable() } catch (_: Exception) { false }
        }
    }

    @JvmStatic
    fun getString(section: String, key: String): String? {
        directStoreForTest?.let { return it.getString(section, key) }
        val direct = synchronized(lock) {
            try { if (directStore.canReadDirectly()) directStore.getString(section, key) else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as String?
        return readViaIpc(section, key)
    }

    @JvmStatic
    fun getLong(section: String, key: String, defaultValue: Long = 0L): Long {
        val direct = synchronized(lock) {
            try { if (directStore.canReadDirectly()) directStore.getLong(section, key, defaultValue) else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as Long
        return readLongViaIpc(section, key, defaultValue)
    }

    @JvmStatic
    fun getBoolean(section: String, key: String, defaultValue: Boolean = false): Boolean {
        val direct = synchronized(lock) {
            try { if (directStore.canReadDirectly()) directStore.getBoolean(section, key, defaultValue) else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as Boolean
        return readBooleanViaIpc(section, key, defaultValue)
    }

    @JvmStatic
    fun loadSection(section: String): JSONObject {
        val direct = synchronized(lock) {
            try { if (directStore.canReadDirectly()) directStore.loadSection(section) else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as JSONObject
        return readSectionViaIpc(section)
    }

    @JvmStatic
    fun putString(section: String, key: String, value: String?): Boolean {
        directStoreForTest?.let { return it.putString(section, key, value) }
        val direct = synchronized(lock) {
            try { if (directStore.canWriteDirectly() && directStore.putString(section, key, value)) true else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as Boolean
        return writeViaIpc(section, key, value, "put")
    }

    @JvmStatic
    fun putLong(section: String, key: String, value: Long): Boolean {
        directStoreForTest?.let { return it.putLong(section, key, value) }
        val direct = synchronized(lock) {
            try { if (directStore.canWriteDirectly() && directStore.putLong(section, key, value)) true else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as Boolean
        return writeViaIpc(section, key, value, "put")
    }

    @JvmStatic
    fun putBoolean(section: String, key: String, value: Boolean): Boolean {
        val direct = synchronized(lock) {
            try { if (directStore.canWriteDirectly() && directStore.putBoolean(section, key, value)) true else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as Boolean
        return writeViaIpc(section, key, value, "put")
    }

    @JvmStatic
    fun delete(section: String, key: String): Boolean {
        directStoreForTest?.let { return it.delete(section, key) }
        val direct = synchronized(lock) {
            try { if (directStore.canWriteDirectly() && directStore.delete(section, key)) true else Unit }
            catch (_: Exception) { Unit }
        }
        if (direct !== Unit) return direct as Boolean
        return writeViaIpc(section, key, null, "delete")
    }

    private fun readViaIpc(section: String, key: String): String? {
        return runIpcBlocking(null) {
            readViaIpcOnCurrentThread(section, key)
        }
    }

    private fun readViaIpcOnCurrentThread(section: String, key: String): String? {
        // Refuse privileged IPC if the APK signing cert doesn't match the expected
        // release cert (uy93.10). Dev/unsigned builds always pass (cert empty = no check).
        if (AppIntegrityCheck.isTamperedCached()) {
            Log.e("SecretConfigBridge", "IPC secret fetch blocked: APK integrity check failed")
            return null
        }
        if (!DaemonReadinessChecker.waitUntilReady(30_000)) {
            Log.w("SecretConfigBridge", "Daemon not ready for IPC read after 30s")
            return null
        }
        val cmd = JSONObject()
            .put("cmd", "secret_get")
            .put("section", section)
            .put("key", key)
        var lastError: String? = null
        for (attempt in 0 until 3) {
            val client = CameraDaemonClient()
            try {
                if (!client.connect()) {
                    lastError = "connect failed"
                } else {
                    val response = client.sendCommand(cmd)
                    if ("ok".equals(response.optString("status"), ignoreCase = true)) {
                        val value = response.optString("value", "")
                        return if (value.isEmpty()) null else value
                    }
                    lastError = response.optString("message", "daemon returned error")
                }
            } catch (e: Exception) {
                lastError = e.message ?: e.javaClass.simpleName
            } finally {
                client.disconnect()
            }
            if (attempt < 2) {
                try {
                    Thread.sleep(150L * (attempt + 1))
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    break
                }
            }
        }
        Log.w("SecretConfigBridge", "IPC read failed after 3 attempts for $section.$key: ${lastError ?: "unknown"}")
        return null
    }

    private fun readLongViaIpc(section: String, key: String, defaultValue: Long): Long {
        val value = readViaIpc(section, key) ?: return defaultValue
        return value.toLongOrNull() ?: defaultValue
    }

    private fun readBooleanViaIpc(section: String, key: String, defaultValue: Boolean): Boolean {
        val value = readViaIpc(section, key) ?: return defaultValue
        return when (value.lowercase()) {
            "true", "1", "yes", "on" -> true
            "false", "0", "no", "off" -> false
            else -> defaultValue
        }
    }

    private fun readSectionViaIpc(section: String): JSONObject {
        return runIpcBlocking(JSONObject()) {
            readSectionViaIpcOnCurrentThread(section)
        }
    }

    private fun readSectionViaIpcOnCurrentThread(section: String): JSONObject {
        val client = CameraDaemonClient()
        return try {
            if (!client.connect()) return JSONObject()
            val cmd = JSONObject()
                .put("cmd", "secret_get_section")
                .put("section", section)
            val response = client.sendCommand(cmd)
            if (!"ok".equals(response.optString("status"), ignoreCase = true)) return JSONObject()
            response.optJSONObject("section")?.let { JSONObject(it.toString()) } ?: JSONObject()
        } catch (_: Exception) {
            JSONObject()
        } finally {
            client.disconnect()
        }
    }

    private fun writeViaIpc(section: String, key: String, value: Any?, action: String): Boolean {
        return runIpcBlocking(false) {
            writeViaIpcOnCurrentThread(section, key, value, action)
        }
    }

    private fun writeViaIpcOnCurrentThread(section: String, key: String, value: Any?, action: String): Boolean {
        // Mirror the read path: bail early if the daemon is not ready, rather than letting
        // 3 connect() calls each stall 60s (worst case ~180s total on a background thread).
        if (!DaemonReadinessChecker.waitUntilReady(30_000)) {
            Log.w("SecretConfigBridge", "Daemon not ready for IPC write after 30s")
            return false
        }
        val command = JSONObject()
            .put("cmd", when (action) {
                "delete" -> "secret_delete"
                else -> "secret_put"
            })
            .put("section", section)
            .put("key", key)
        if (action != "delete" && value != null) {
            command.put("value", value)
        }

        var lastError: String? = null
        for (attempt in 0 until 3) {
            val client = CameraDaemonClient()
            try {
                if (!client.connect()) {
                    lastError = "connect failed"
                } else {
                    val response = client.sendCommand(command)
                    if ("ok".equals(response.optString("status"), ignoreCase = true)) {
                        return true
                    }
                    lastError = response.optString("message", "daemon returned error")
                }
            } catch (e: Exception) {
                lastError = e.message ?: e.javaClass.simpleName
            } finally {
                client.disconnect()
            }
            if (attempt < 2) {
                try {
                    Thread.sleep(150L * (attempt + 1))
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    break
                }
            }
        }
        Log.w("SecretConfigBridge", "IPC secret $action failed for $section.$key: ${lastError ?: "unknown"}")
        return false
    }

    private fun <T> runIpcBlocking(defaultValue: T, block: () -> T): T {
        if (Looper.myLooper() != Looper.getMainLooper()) {
            return block()
        }

        val future = ipcExecutor.submit<T> { block() }
        return try {
            // Cap BELOW Android's 5s input-dispatch ANR threshold. A main-thread
            // caller that hits a not-yet-ready daemon would otherwise park long
            // enough to ANR (a 6s cap guaranteed it). Callers should avoid IPC on
            // the main thread entirely; this is the defense-in-depth net.
            future.get(4, TimeUnit.SECONDS)
        } catch (e: java.util.concurrent.TimeoutException) {
            // cancel(true) interrupts the worker thread. Thread.sleep() in waitUntilReady and
            // retry backoff respond to interruption. Socket ops throw on interrupt. We prefer
            // cancel(true) over cancel(false) because the IPC calls here are atomic JSON
            // request/response; a write in flight will be abandoned (the daemon never sees a
            // partial message since we send whole JSON lines), so there is no partial-write
            // corruption risk. Without cancel, the single-thread executor stays occupied for
            // up to 30-180s, serializing all subsequent main-thread config reads behind it.
            future.cancel(true)
            Log.w("SecretConfigBridge", "IPC secret operation timed out after 4s, executor freed")
            defaultValue
        } catch (e: Exception) {
            future.cancel(true)
            Log.w("SecretConfigBridge", "IPC secret operation failed on worker: ${e.message ?: e.javaClass.simpleName}")
            defaultValue
        }
    }
}
