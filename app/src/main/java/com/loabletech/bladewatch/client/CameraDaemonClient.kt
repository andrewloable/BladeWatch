package net.bladewatch.app.client

import android.util.Base64
import android.util.Log

import net.bladewatch.app.server.IpcTokenManager

import org.json.JSONArray
import org.json.JSONObject

import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.io.PrintWriter
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * TCP client for communicating with CameraDaemon.
 * Uses TCP on localhost to avoid SELinux cross-context restrictions.
 */
class CameraDaemonClient {

    private var socket: Socket? = null
    private var reader: BufferedReader? = null
    private var writer: PrintWriter? = null
    private val executor = Executors.newSingleThreadExecutor()

    @Volatile
    private var connected = false

    interface ResponseCallback {
        fun onResponse(response: JSONObject)

        /** [error] is the exception's message, which the JDK allows to be null. */
        fun onError(error: String?)
    }

    /**
     * Connect to CameraDaemon via TCP socket on localhost.
     *
     * With no argument, waits up to 60s for the daemon ready sentinel (appropriate for
     * cold-boot callers such as SecretConfigBridge). Use a short timeout (e.g. 2000ms) for
     * mid-session reconnects where the daemon was already known up.
     *
     * ConnectException and SocketTimeoutException are both retried up to 3x; other exceptions
     * (auth/protocol errors) fail immediately without retry.
     */
    @JvmOverloads
    fun connect(readinessTimeoutMs: Long = 60_000): Boolean {
        if (!DaemonReadinessChecker.waitUntilReady(readinessTimeoutMs)) {
            Log.w(TAG, "Daemon not ready after " + readinessTimeoutMs + "ms, aborting connect")
            return false
        }
        for (attempt in 0 until 3) {
            try {
                val s = Socket()
                socket = s
                s.connect(InetSocketAddress(HOST, PORT), CONNECT_TIMEOUT_MS)
                s.soTimeout = 30000 // 30 second read timeout

                reader = BufferedReader(InputStreamReader(s.getInputStream()))
                val w = PrintWriter(OutputStreamWriter(s.getOutputStream()), true)
                writer = w

                connected = true

                // Send auth token as the first message; server rejects without it.
                // refreshToken() (not getToken()) re-reads from disk so we never send a
                // token cached before the daemon (re)wrote it on its last startup, which
                // the daemon would reject as Unauthorized. We are past waitUntilReady()
                // here, so the daemon is up and its current token is on disk.
                val token = IpcTokenManager.refreshToken()
                if (token != null) {
                    val auth = JSONObject()
                    auth.put("token", token)
                    w.println(auth.toString())
                    w.flush()
                }

                Log.d(TAG, "Connected to CameraDaemon on $HOST:$PORT")
                return true
            } catch (e: IOException) {
                // ConnectException (connection refused) and SocketTimeoutException (slow accept
                // during startup) are both IOException subclasses — retry both.
                Log.w(TAG, "connect attempt " + (attempt + 1) + "/3 failed: " + e.message)
                connected = false
                try {
                    socket?.close()
                } catch (ignored: Exception) {
                    // Already broken; nothing useful to do with a close failure here.
                }
                socket = null
                reader = null
                writer = null
                if (attempt < 2) {
                    try {
                        Thread.sleep(2000)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                        return false
                    }
                }
            } catch (e: Exception) {
                // Non-IO exceptions (auth/protocol/JSON errors) fail fast without retry.
                Log.e(TAG, "Failed to connect to $HOST:$PORT: " + e.message)
                connected = false
                return false
            }
        }
        Log.e(TAG, "Failed to connect after 3 attempts")
        connected = false
        return false
    }

    /** Disconnect from daemon (daemon keeps running). */
    fun disconnect() {
        connected = false
        try {
            reader?.close()
            writer?.close()
            socket?.close()
        } catch (e: Exception) {
            Log.d(TAG, "Disconnect: " + e.message)
        }
        socket = null
        reader = null
        writer = null
        Log.d(TAG, "Disconnected from CameraDaemon (daemon still running)")
    }

    /** Check if connected. */
    fun isConnected(): Boolean {
        val s = socket
        return connected && s != null && s.isConnected && !s.isClosed
    }

    /** Send command and get response (blocking). */
    @Throws(Exception::class)
    fun sendCommand(command: JSONObject): JSONObject {
        if (!isConnected()) {
            // Mid-session reconnect: daemon was already known-up, so use a short readiness
            // timeout (2s) rather than the 60s cold-boot wait. This prevents one dropped
            // socket from stalling the executor for up to 60s.
            if (!connect(2_000)) {
                throw Exception("Not connected to CameraDaemon")
            }
        }

        synchronized(this) {
            try {
                val w = writer ?: throw Exception("Not connected to CameraDaemon")
                val r = reader ?: throw Exception("Not connected to CameraDaemon")
                w.println(command.toString())
                w.flush()

                val response = r.readLine()
                if (response == null) {
                    connected = false
                    throw Exception("CameraDaemon disconnected")
                }
                return JSONObject(response)
            } catch (e: Exception) {
                connected = false
                throw e
            }
        }
    }

    /** Send command string and get response (blocking). */
    fun sendCommand(commandJson: String): JSONObject? = try {
        sendCommand(JSONObject(commandJson))
    } catch (e: Exception) {
        Log.e(TAG, "sendCommand error: " + e.message)
        null
    }

    /** Send command async. */
    fun sendCommandAsync(command: JSONObject, callback: ResponseCallback?) {
        executor.submit {
            try {
                callback?.onResponse(sendCommand(command))
            } catch (e: Exception) {
                callback?.onError(e.message)
            }
        }
    }

    // ==================== COMMAND PLUMBING ====================
    //
    // Every convenience method below was the same three shapes spelled out by hand:
    // build a {"cmd": name, ...} object; either fire it async and route any build failure to
    // callback.onError, or send it blocking and report status=="ok". Stated once here.

    private inline fun cmd(name: String, build: JSONObject.() -> Unit = {}): JSONObject {
        val o = JSONObject()
        o.put("cmd", name)
        o.build()
        return o
    }

    private inline fun async(
        name: String,
        callback: ResponseCallback?,
        build: JSONObject.() -> Unit = {}
    ) {
        try {
            sendCommandAsync(cmd(name, build), callback)
        } catch (e: Exception) {
            callback?.onError(e.message)
        }
    }

    /** Blocking send; true when the daemon answered `status: "ok"`. */
    private inline fun sendOk(
        name: String,
        errLabel: String,
        build: JSONObject.() -> Unit = {}
    ): Boolean = try {
        "ok" == sendCommand(cmd(name, build)).optString("status")
    } catch (e: Exception) {
        Log.e(TAG, "$errLabel error: " + e.message)
        false
    }

    // ==================== CONVENIENCE METHODS ====================

    /** Ping daemon to check if it's alive. */
    fun ping(): Boolean = sendOk("ping", "Ping failed:")

    /** Start recording specified cameras. */
    fun startRecording(
        cameraIds: Set<Int>,
        enableStreaming: Boolean,
        callback: ResponseCallback?
    ) = async("start", callback) {
        put("cameras", JSONArray(cameraIds))
        put("stream", enableStreaming)
    }

    /** Stop recording specified cameras (or all if null). */
    fun stopRecording(cameraIds: Set<Int>?, callback: ResponseCallback?) =
        async("stop", callback) {
            if (cameraIds != null) {
                put("cameras", JSONArray(cameraIds))
            }
        }

    /** Get daemon status. */
    fun getStatus(callback: ResponseCallback?) = async("status", callback)

    /** Set output directory. */
    fun setOutputDir(path: String, callback: ResponseCallback?) =
        async("setOutput", callback) { put("path", path) }

    /** Enable/disable streaming for a camera. */
    fun setStreaming(cameraId: Int, enable: Boolean, callback: ResponseCallback?) =
        async("stream", callback) {
            put("camera", cameraId)
            put("enable", enable)
        }

    /**
     * Get latest frame from a camera (blocking).
     * Returns base64-encoded JPEG or null on error.
     */
    fun getFrame(cameraId: Int): ByteArray? {
        try {
            val response = sendCommand(cmd("getFrame") { put("camera", cameraId) })
            if ("ok" == response.optString("status")) {
                val base64 = response.optString("frame")
                if (base64.isNotEmpty()) {
                    return Base64.decode(base64, Base64.NO_WRAP)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "getFrame error: " + e.message)
        }
        return null
    }

    /** Get frame dimensions for a camera. */
    fun getFrameDimensions(cameraId: Int): IntArray? {
        try {
            val response = sendCommand(cmd("getFrame") { put("camera", cameraId) })
            if ("ok" == response.optString("status")) {
                return intArrayOf(
                    response.optInt("width", 0),
                    response.optInt("height", 0)
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "getFrameDimensions error: " + e.message)
        }
        return null
    }

    /** Shutdown the daemon. */
    fun shutdown(callback: ResponseCallback?) = async("shutdown", callback)

    // ==================== QUALITY SETTINGS ====================

    /**
     * Set recording bitrate.
     * @param bitrate LOW (2 Mbps), MEDIUM (3 Mbps), or HIGH (6 Mbps)
     */
    fun setRecordingBitrate(bitrate: String, callback: ResponseCallback?) =
        async("setBitrate", callback) { put("value", bitrate.uppercase()) }

    /**
     * Set recording codec.
     * @param codec H264 or H265
     */
    fun setRecordingCodec(codec: String, callback: ResponseCallback?) =
        async("setCodec", callback) { put("value", codec.uppercase()) }

    /** Get current quality settings from daemon. */
    fun getQualitySettings(callback: ResponseCallback?) = async("getQualitySettings", callback)

    /**
     * Set recording bitrate (blocking).
     * @param bitrate LOW, MEDIUM, or HIGH
     * @return true if successful
     */
    fun setRecordingBitrateSync(bitrate: String): Boolean =
        sendOk("setBitrate", "setRecordingBitrate") { put("value", bitrate.uppercase()) }

    /**
     * Set recording codec (blocking).
     * @param codec H264 or H265
     * @return true if successful
     */
    fun setRecordingCodecSync(codec: String): Boolean =
        sendOk("setCodec", "setRecordingCodec") { put("value", codec.uppercase()) }

    /**
     * Set recordings storage type (blocking).
     * @param type INTERNAL or SD_CARD
     * @return true if successful
     */
    fun setRecordingsStorageTypeSync(type: String): Boolean =
        sendOk("setRecordingsStorageType", "setRecordingsStorageType") {
            put("value", type.uppercase())
        }

    /**
     * Set recordings storage limit (blocking).
     * @param limitMb limit in megabytes
     * @return true if successful
     */
    fun setRecordingsLimitMbSync(limitMb: Long): Boolean =
        sendOk("setRecordingsLimitMb", "setRecordingsLimitMb") { put("value", limitMb) }

    /** Cleanup client resources (daemon keeps running). */
    fun destroy() {
        disconnect()
        executor.shutdown()
        try {
            executor.awaitTermination(1, TimeUnit.SECONDS)
        } catch (e: InterruptedException) {
            executor.shutdownNow()
        }
    }

    // ==================== AUTH COMMANDS ====================

    /**
     * Invalidate auth cache in daemon.
     * Call this after regenerating device token to force daemon to reload auth state.
     * This ensures old JWTs signed with the previous secret are rejected.
     */
    fun invalidateAuthCache(callback: ResponseCallback?) = async("auth_invalidate", callback)

    /**
     * Invalidate auth cache in daemon (blocking).
     * @return true if successful
     */
    fun invalidateAuthCacheSync(): Boolean = sendOk("auth_invalidate", "invalidateAuthCache")

    /** Read a secret value from the daemon-owned secret store. */
    fun getSecret(section: String, key: String): String? {
        return try {
            val response = sendCommand(
                cmd("secret_get") {
                    put("section", section)
                    put("key", key)
                }
            )
            if ("ok" != response.optString("status")) {
                return null
            }
            response.optString("value", "").ifEmpty { null }
        } catch (e: Exception) {
            Log.e(TAG, "getSecret error: " + e.message)
            null
        }
    }

    /** Read an entire secret section from the daemon-owned secret store. */
    fun getSecretSection(section: String): JSONObject {
        return try {
            val response = sendCommand(cmd("secret_get_section") { put("section", section) })
            if ("ok" != response.optString("status")) {
                return JSONObject()
            }
            response.optJSONObject("section") ?: JSONObject()
        } catch (e: Exception) {
            Log.e(TAG, "getSecretSection error: " + e.message)
            JSONObject()
        }
    }

    /** Store a secret value in the daemon-owned secret store. */
    fun putSecret(section: String, key: String, value: Any?): Boolean =
        sendOk("secret_put", "putSecret") {
            put("section", section)
            put("key", key)
            if (value != null) {
                put("value", value)
            }
        }

    /** Delete a secret value from the daemon-owned secret store. */
    fun deleteSecret(section: String, key: String): Boolean =
        sendOk("secret_delete", "deleteSecret") {
            put("section", section)
            put("key", key)
        }

    companion object {
        private const val TAG = "CameraDaemonClient"
        private const val HOST = "127.0.0.1"
        private const val PORT = 19876
        private const val CONNECT_TIMEOUT_MS = 5000

        /** Parse recording cameras from response. */
        @JvmStatic
        fun parseRecordingCameras(response: JSONObject): Set<Int> {
            val cameras = HashSet<Int>()
            try {
                val arr = response.optJSONArray("recording")
                if (arr != null) {
                    for (i in 0 until arr.length()) {
                        cameras.add(arr.getInt(i))
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Parse error: " + e.message)
            }
            return cameras
        }
    }
}
