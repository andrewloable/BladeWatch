package net.bladewatch.app.server

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.monitor.AccMonitor
import net.bladewatch.app.storage.StorageManager
import org.json.JSONArray
import net.bladewatch.app.auth.CompanionPairing
import net.bladewatch.app.daemon.PearStatus
import net.bladewatch.app.daemon.PearTopic
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.FileReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.io.PrintWriter
import java.io.RandomAccessFile
import java.net.BindException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.nio.charset.StandardCharsets
import java.util.Collections
import java.util.Locale
import java.util.regex.Pattern
import kotlin.math.max
import kotlin.math.min

/**
 * TCP command server — handles JSON commands from DaemonClient. Listens on localhost:19876 for
 * security.
 *
 * Several members below are public only so the Java tests in this package can reach them: Kotlin
 * mangles `internal` names on the JVM, so an internal test seam would be unreachable from Java.
 */
class TcpCommandServer(private val port: Int) {

    @Volatile
    private var serverSocket: ServerSocket? = null

    /**
     * The port actually bound, -1 until then. Tests construct with port 0 and read this: picking
     * a "free" port first and binding it later races any other process, and the debug and release
     * test JVMs run these classes at the same time.
     */
    val boundPort: Int get() = serverSocket?.takeUnless { it.isClosed }?.localPort ?: -1

    @Volatile
    private var running = true

    private fun store(): SecretConfigStore = secretStoreForTest ?: SECRET_STORE

    /**
     * Secret-store sections only byd_cam_daemon itself uses -- it reads them from the store
     * directly, never over IPC. Refused to every secret_* command in both directions
     * (BladeWatch-rdtj.16): the app UID is trusted, but it is the widest target on the head unit,
     * and without this it could read the LAN TLS private key, the Pear topic seed and the discovery
     * probe key, or plant a companion credential. Case-insensitive, as the auth guard is.
     */
    internal fun isDaemonOnlySecretSection(section: String): Boolean =
        DAEMON_ONLY_SECRET_SECTIONS.any { it.equals(section, ignoreCase = true) }

    private val DAEMON_ONLY_SECRET_SECTIONS = setOf(
        LanTls.SECTION, PearTopic.SECTION, LanDiscoveryResponder.SECTION, CompanionPairing.SECTION,
    )

    fun start() {
        CameraDaemon.log("TCP server starting on port $port")

        while (running && CameraDaemon.isRunning()) {
            try {
                serverSocket?.let { existing ->
                    if (!existing.isClosed) {
                        try {
                            existing.close()
                        } catch (e: Exception) {
                            CameraDaemon.log(
                                "WARN: TCP serverSocket.close() failed: " + e.message
                            )
                        }
                    }
                }

                val socket = ServerSocket(port, 5, InetAddress.getByName("127.0.0.1"))
                socket.reuseAddress = true
                serverSocket = socket
                CameraDaemon.log("TCP server listening on 127.0.0.1:$port")

                while (running && CameraDaemon.isRunning() && !socket.isClosed) {
                    try {
                        val client = socket.accept()
                        CameraDaemon.log("TCP client connected: " + client.remoteSocketAddress)
                        Thread(
                            { handleClient(client) },
                            "TcpClient-" + System.currentTimeMillis()
                        ).start()
                    } catch (e: SocketException) {
                        if (running) {
                            CameraDaemon.log("WARN: TCP socket error: " + e.message)
                        }
                        break
                    }
                }

                if (running) {
                    CameraDaemon.log("TCP server restarting...")
                    Thread.sleep(2000)
                }
            } catch (e: BindException) {
                CameraDaemon.log("ERROR: TCP port $port in use, retrying...")
                try {
                    Thread.sleep(5000)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    break
                }
            } catch (e: Exception) {
                CameraDaemon.log("ERROR: TCP server error: " + e.message)
                if (running) {
                    try {
                        Thread.sleep(3000)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                        break
                    }
                }
            }
        }

        CameraDaemon.log("TCP server stopped")
    }

    fun stop() {
        running = false
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            CameraDaemon.log("WARN: TCP serverSocket.close() in stop() failed: " + e.message)
        }
    }

    private fun handleClient(client: Socket) {
        try {
            // Defence in depth: the IPC token is world-readable (644) by design, so verify the
            // connecting process's UID before doing anything. Only root/system/shell-daemon and
            // the BladeWatch app may drive commands (notably 'secret_*'). Reject everything else.
            val peerUid = PeerCredentials.resolvePeerUid(client)
            if (!PeerCredentials.isTrusted(peerUid)) {
                CameraDaemon.log(
                    "WARN: TCP IPC rejected untrusted peer uid=" + peerUid +
                        " from " + client.remoteSocketAddress
                )
                try {
                    client.close()
                } catch (e: Exception) {
                    CameraDaemon.log("WARN: TCP client.close() failed: " + e.message)
                }
                return
            }

            val reader = BufferedReader(InputStreamReader(client.getInputStream()))
            val writer = PrintWriter(OutputStreamWriter(client.getOutputStream()), true)

            // Require auth as the first message: {"token": "<value>"}
            val authLine = reader.readLine() ?: return
            val authMsg = JSONObject(authLine)
            if (!IpcTokenManager.isValid(authMsg.optString("token", ""))) {
                val err = JSONObject()
                err.put("status", "error")
                err.put("message", "Unauthorized")
                writer.println(err.toString())
                return
            }

            while (true) {
                val line = reader.readLine() ?: break
                try {
                    val cmd = JSONObject(line)
                    CameraDaemon.log("TCP received command: " + cmd.optString("cmd", ""))
                    writer.println(processCommand(cmd).toString())
                } catch (e: Exception) {
                    val error = JSONObject()
                    error.put("status", "error")
                    error.put("message", e.message)
                    writer.println(error.toString())
                }
            }
        } catch (e: Exception) {
            CameraDaemon.log("TCP client disconnected: " + e.message)
        } finally {
            try {
                client.close()
            } catch (e: Exception) {
                CameraDaemon.log("WARN: TCP client.close() in finally failed: " + e.message)
            }
        }
    }

    @Throws(Exception::class)
    fun processCommand(cmd: JSONObject): JSONObject {
        val action = cmd.optString("cmd", "")
        val response = JSONObject()

        CameraDaemon.log("Processing command: $action")

        if (action.startsWith("secret_") && isDaemonOnlySecretSection(cmd.optString("section", ""))) {
            response.put("status", "error")
            response.put("message", "Secret section not available over IPC")
            return response
        }

        when (action) {
            "start" -> {
                // Start recording — streaming is independent and NOT started by default
                val camsToStart = cmd.optJSONArray("cameras")
                val enableStream = cmd.optBoolean("stream", false)
                if (camsToStart != null) {
                    for (i in 0 until camsToStart.length()) {
                        CameraDaemon.startCamera(camsToStart.getInt(i), enableStream, false)
                    }
                }
                response.put("status", "ok")
                response.put("recording", getRecordingCameras())
            }

            "stop" -> {
                // A user-requested stop forces even while recording
                val forceStop = cmd.optBoolean("force", true)
                val camsToStop = cmd.optJSONArray("cameras")
                if (camsToStop != null) {
                    for (i in 0 until camsToStop.length()) {
                        CameraDaemon.stopCamera(camsToStop.getInt(i), forceStop)
                    }
                } else {
                    CameraDaemon.stopAllCameras(forceStop)
                }
                response.put("status", "ok")
                response.put("recording", getRecordingCameras())
            }

            "status" -> {
                response.put("status", "ok")
                response.put("recording", getRecordingCameras())
                response.put("viewing", getViewOnlyCameras())
                response.put("active", getActiveCameras())
                response.put("available", getAvailableCameras())
            }

            "ping" -> {
                response.put("status", "ok")
                response.put("message", "pong")
            }

            "setOutput" -> {
                response.put("status", "ok")
                response.put("outputDir", CameraDaemon.getOutputDir())
            }

            "shutdown" -> {
                response.put("status", "ok")
                Thread({
                    try {
                        Thread.sleep(300)
                    } catch (e: InterruptedException) {
                        Thread.currentThread().interrupt()
                        return@Thread
                    }
                    CameraDaemon.shutdown()
                }, "ShutdownThread").start()
            }

            "setStreamMode" -> {
                val mode = cmd.optString("mode", "")
                if (mode == "private" || mode == "public") {
                    CameraDaemon.setStreamMode(mode)
                    response.put("status", "ok")
                    response.put("mode", CameraDaemon.getStreamMode())
                    response.put(
                        "message",
                        "Stream mode set to $mode (both use tunnel URLs now)"
                    )
                } else {
                    response.put("status", "error")
                    response.put("message", "Invalid mode. Use 'private' or 'public'")
                }
            }

            "getStreamMode" -> {
                response.put("status", "ok")
                response.put("mode", CameraDaemon.getStreamMode())
                response.put("isPublic", CameraDaemon.isPublicMode())
            }

            // ==================== SURVEILLANCE COMMANDS ====================

            "enableSurveillance" -> {
                UnifiedConfigManager.setSurveillanceEnabled(true)
                if (!AccMonitor.isAccOn()) {
                    CameraDaemon.enableSurveillance()
                }
                response.put("status", "ok")
                response.put("surveillance", CameraDaemon.getSurveillanceStatus())
            }

            "disableSurveillance" -> {
                CameraDaemon.disableSurveillance()
                UnifiedConfigManager.setSurveillanceEnabled(false)
                response.put("status", "ok")
                response.put("surveillance", CameraDaemon.getSurveillanceStatus())
            }

            "surveillanceStatus" -> {
                response.put("status", "ok")
                response.put("surveillance", CameraDaemon.getSurveillanceStatus())
            }

            "setAccState" -> {
                val accOff = cmd.optBoolean("accOff", false)
                CameraDaemon.onAccStateChanged(accOff)
                response.put("status", "ok")
                response.put("accOff", accOff)
                response.put("surveillance", CameraDaemon.getSurveillanceStatus())
            }

            // ==================== RECORDING MODE COMMANDS ====================

            "setRecordingMode" -> {
                val recordingMode = cmd.optString("mode", "")
                if (recordingMode.isNotEmpty()) {
                    CameraDaemon.setRecordingMode(recordingMode)
                    response.put("status", "ok")
                    response.put("mode", CameraDaemon.getRecordingMode())
                } else {
                    response.put("status", "error")
                    response.put("message", "No mode specified")
                }
            }

            "getRecordingMode" -> {
                response.put("status", "ok")
                response.put("mode", CameraDaemon.getRecordingMode())
            }

            // ==================== QUALITY SETTINGS COMMANDS ====================

            "setBitrate" -> {
                // Legacy bitrate labels: LOW (2Mbps), MEDIUM (3Mbps), HIGH (6Mbps)
                val bitrateValue = cmd.optString("value", "").uppercase(Locale.ROOT)
                if (bitrateValue == "LOW" || bitrateValue == "MEDIUM" || bitrateValue == "HIGH") {
                    // TCP clients still send the legacy bitrate labels; convert them at the IPC
                    // boundary so the daemon uses the canonical ECONOMY/STANDARD/HIGH
                    // recording-quality path.
                    val qualityValue = when (bitrateValue) {
                        "LOW" -> "ECONOMY"
                        "HIGH" -> "HIGH"
                        else -> "STANDARD"
                    }
                    CameraDaemon.setRecordingQuality(qualityValue)
                    HttpServer.setRecordingQuality(qualityValue)
                    response.put("status", "ok")
                    response.put("bitrate", bitrateValue)
                    response.put("quality", qualityValue)
                    response.put(
                        "message",
                        "Bitrate set to " + bitrateValue + " (" + qualityValue +
                            ") - applied immediately"
                    )
                } else {
                    response.put("status", "error")
                    response.put("message", "Invalid bitrate. Use LOW, MEDIUM, or HIGH")
                }
            }

            "setCodec" -> {
                // Recording codec is H264-only — HEVC playback isn't supported by the player.
                val codecValue = cmd.optString("value", "").uppercase(Locale.ROOT)
                if (codecValue == "H264") {
                    CameraDaemon.setRecordingCodec(codecValue)
                    HttpServer.setRecordingCodec(codecValue)
                    response.put("status", "ok")
                    response.put("codec", codecValue)
                    response.put(
                        "message",
                        "Codec set to $codecValue - restart recording to apply"
                    )
                } else {
                    response.put("status", "error")
                    response.put("message", "Invalid codec. Only H264 is supported")
                }
            }

            "setRecordingsStorageType" -> {
                val recStorageTypeValue = cmd.optString("value", "").uppercase(Locale.ROOT)
                if (recStorageTypeValue == "INTERNAL" || recStorageTypeValue == "SD_CARD") {
                    val storageManager = StorageManager.getInstance()
                    val recType = if ("SD_CARD" == recStorageTypeValue) {
                        StorageManager.StorageType.SD_CARD
                    } else {
                        StorageManager.StorageType.INTERNAL
                    }
                    if (storageManager.setRecordingsStorageType(recType)) {
                        response.put("status", "ok")
                        response.put("storageType", recStorageTypeValue)
                        response.put("path", storageManager.recordingsPath)
                        response.put("message", "Recordings storage set to $recStorageTypeValue")
                        CameraDaemon.log(
                            "Recordings storage type set to $recStorageTypeValue via TCP IPC"
                        )
                    } else {
                        response.put("status", "error")
                        response.put("message", "SD card not available")
                    }
                } else {
                    response.put("status", "error")
                    response.put("message", "Invalid storage type. Use INTERNAL or SD_CARD")
                }
            }

            "setRecordingsLimitMb" -> {
                val recLimitMb = cmd.optLong("value", -1)
                if (recLimitMb > 0) {
                    val recLimitStorage = StorageManager.getInstance()
                    recLimitStorage.recordingsLimitMb = recLimitMb
                    response.put("status", "ok")
                    response.put("limitMb", recLimitStorage.recordingsLimitMb)
                    response.put(
                        "message",
                        "Recordings limit set to " + recLimitStorage.recordingsLimitMb + " MB"
                    )
                    CameraDaemon.log(
                        "Recordings limit set to " + recLimitStorage.recordingsLimitMb +
                            " MB via TCP IPC"
                    )
                    // Trigger async cleanup
                    Thread(
                        { recLimitStorage.ensureRecordingsSpace(0) }, "RecLimitCleanup"
                    ).start()
                } else {
                    response.put("status", "error")
                    response.put("message", "Invalid limit value")
                }
            }

            "getQualitySettings" -> {
                // Read directly from the unified config for cross-UID sync
                response.put("status", "ok")

                var bitrate = "MEDIUM"
                var codec = "H264"
                try {
                    val unifiedFile = File("/data/local/tmp/bladewatch_config.json")
                    if (unifiedFile.exists()) {
                        val sb = StringBuilder()
                        BufferedReader(FileReader(unifiedFile)).use { reader ->
                            while (true) {
                                val l = reader.readLine() ?: break
                                sb.append(l)
                            }
                        }
                        val recording = JSONObject(sb.toString()).optJSONObject("recording")
                        if (recording != null) {
                            bitrate = recording.optString("bitrate", "MEDIUM")
                            codec = recording.optString("codec", "H264")
                        }
                    }
                } catch (e: Exception) {
                    CameraDaemon.log(
                        "getQualitySettings: Could not read unified config: " + e.message
                    )
                    // Fall back to the HttpServer statics
                    bitrate = HttpServer.getRecordingBitrate()
                    codec = HttpServer.getRecordingCodec()
                }

                response.put("bitrate", bitrate)
                response.put("codec", codec)
                response.put(
                    "bitrateOptions",
                    JSONObject().put("LOW", "2 Mbps").put("MEDIUM", "3 Mbps").put("HIGH", "6 Mbps")
                )
                response.put(
                    "codecOptions", JSONObject().put("H264", "H.264/AVC (Compatible)")
                )
            }

            "auth_invalidate" -> {
                // Invalidate the cached auth state — called when the app regenerates its token,
                // which forces the daemon to reload auth state from file on the next validation.
                AuthManager.invalidateCache()
                CameraDaemon.log("Auth cache invalidated via IPC")
                response.put("status", "ok")
                response.put("message", "Auth cache invalidated")
            }

            "secret_get" -> {
                val value = store().getString(
                    cmd.optString("section", ""), cmd.optString("key", "")
                )
                response.put("status", "ok")
                response.put("value", value ?: "")
            }

            "secret_get_section" -> {
                response.put("status", "ok")
                response.put("section", store().loadSection(cmd.optString("section", "")))
            }

            "secret_put" -> {
                val section = cmd.optString("section", "")
                val key = cmd.optString("key", "")
                val value = if (cmd.has("value")) cmd.get("value") else null
                val ok = when {
                    value == null || value === JSONObject.NULL -> store().delete(section, key)
                    value is Boolean -> store().putBoolean(section, key, value)
                    value is Number -> store().putLong(section, key, value.toLong())
                    else -> store().putString(section, key, value.toString())
                }
                response.put("status", if (ok) "ok" else "error")
                if (!ok) {
                    response.put("message", "Failed to write secret")
                }
            }

            "secret_delete" -> {
                val ok = store().delete(cmd.optString("section", ""), cmd.optString("key", ""))
                response.put("status", if (ok) "ok" else "error")
                if (!ok) {
                    response.put("message", "Failed to delete secret")
                }
            }

            // BladeWatch-hygs: PUBLIC (non-secret) config sections over IPC. Deliberately NOT a
            // generic "write anything to bladewatch_config.json" primitive: only the sections a
            // Settings screen actually owns are reachable (PUBLIC_CONFIG_SECTIONS), so this
            // command cannot be used to reconfigure recording, surveillance or the network
            // binding. The secret store is unreachable from here — that stays on the secret_*
            // family.
            "config_get_section" -> {
                val section = cmd.optString("section", "")
                if (!isPublicConfigSectionReadable(section)) {
                    response.put("status", "error")
                    response.put("message", "Section not exposed over IPC: $section")
                } else {
                    response.put("status", "ok")
                    response.put("section", publicConfigSection(section))
                }
            }

            "config_put" -> {
                val section = cmd.optString("section", "")
                val key = cmd.optString("key", "")
                if (!isPublicConfigSectionAllowed(section)) {
                    response.put("status", "error")
                    response.put("message", "Section not exposed over IPC: $section")
                } else {
                    val value = if (cmd.has("value")) cmd.get("value") else null
                    if (key.isEmpty() || value == null || value === JSONObject.NULL) {
                        response.put("status", "error")
                        response.put(
                            "message", "config_put needs a non-empty key and a value"
                        )
                    } else {
                        val ok = UnifiedConfigManager.updateValues(
                            section, Collections.singletonMap(key, value)
                        )
                        response.put("status", if (ok) "ok" else "error")
                        if (!ok) {
                            response.put("message", "Failed to write $section.$key")
                        }
                    }
                }
            }

            // BladeWatch-m1po / BladeWatch-3lbz.2: the current Tor onion URL, for the Dashboard's
            // remote-access tile / QR code in the Flutter APK, which has no path to
            // TorController's in-memory LiveData or to the app-private SharedPreferences copy.
            //
            // TWO gates, and both are load-bearing:
            //
            // 1. The process must be running. tor's hs/hostname file is written once and then
            //    persists forever, reboots included, so on its own it says nothing about
            //    liveness.
            // 2. tor must have BOOTSTRAPPED. The tunnel this replaces only printed its URL once
            //    the tunnel was live. tor writes hs/hostname about a second after first launch
            //    and then takes ~82 s (cold) or ~6 s (warm) to reach the network — measured on
            //    the head unit 2026-09-14. Publishing the address in that window puts an "online"
            //    QR code on screen for a service nothing can reach yet.
            // BladeWatch-rdtj.4: what a companion needs to reach this car over the LAN -- the TLS
            // listener's port and the SHA-256 pin of its certificate, for the pairing QR
            // (BladeWatch-rdtj.7). A certificate fingerprint is not secret, but it is served over
            // IPC only on purpose: a companion must learn what to trust out of band, never from the
            // very connection it is deciding whether to trust.
            //
            // Creates the identity if none exists yet, so pairing can happen before LAN access is
            // ever switched on; LanTls.loadOrCreate is synchronized against the listener doing the
            // same, so both always agree on one certificate.
            // BladeWatch-rdtj.7: pairing the companion app. In-car only BY CONSTRUCTION, not by
            // accident: this server binds 127.0.0.1 and admits only the app UID (PeerCredentials),
            // so pairing and un-pairing need someone at the car -- a stolen phone can neither
            // un-pair the owner's other devices nor pair itself further. A remote companion reaches
            // HttpServer, never this port. Remote revocation would need its own endpoint and its
            // own threat analysis; it is deliberately absent.
            "pairingMint" -> {
                val deviceId = AuthManager.getState()?.deviceId
                    ?: throw IllegalStateException("auth not initialised")
                val identity = LanTls.loadOrCreate(store()) { e ->
                    CameraDaemon.log(
                        "ERROR: stored LAN TLS identity unreadable (" + e.message +
                            "); minting a new one -- paired companions must re-pair"
                    )
                }
                val payload = CompanionPairing.shared.mint(
                    CompanionPairing.Identity(
                        deviceId = deviceId,
                        pearTopic = PearTopic.topicHex(store()),
                        tlsPort = LanTls.PORT,
                        tlsFingerprint = identity.fingerprintSha256,
                        probeKey = LanDiscoveryResponder.probeKey(store()).joinToString("") { "%02x".format(it) },
                    )
                )
                // Pairing is what switches remote access on: the Pear peer is opt-in, and a
                // companion that is not on the car's Wi-Fi can only redeem its code over Pear.
                recordDaemonEnabled("PEAR_PEER", true)
                response.put("status", "ok")
                response.put("payload", payload.encode())
                response.put("expiresAt", payload.expiresAt)
                response.put("lanEnabled", readLanEnabled())
            }

            "pairingList" -> {
                val companions = JSONArray()
                CompanionPairing.shared.list().forEach {
                    companions.put(JSONObject().put("id", it.id).put("name", it.name).put("pairedAt", it.pairedAt))
                }
                response.put("status", "ok")
                response.put("companions", companions)
            }

            "pairingRevoke" -> {
                if (CompanionPairing.shared.revoke(cmd.optString("id", ""))) {
                    response.put("status", "ok")
                } else {
                    response.put("status", "error")
                    response.put("message", "no such companion")
                }
            }

            // The owner's LAN-access opt-in (network.lanHttpEnabled), switched from the pairing
            // flow. The TLS listener and the discovery responder follow it within 5 s.
            "lanAccessSet" -> {
                val enabled = cmd.optBoolean("enabled", false)
                if (recordLanEnabled(enabled)) {
                    response.put("status", "ok")
                    response.put("enabled", enabled)
                } else {
                    response.put("status", "error")
                    response.put("message", "could not write the LAN access setting")
                }
            }

            "lanTlsInfo" -> {
                val identity = LanTls.loadOrCreate(store()) { e ->
                    CameraDaemon.log(
                        "ERROR: stored LAN TLS identity unreadable (" + e.message +
                            "); minting a new one -- paired companions must re-pair"
                    )
                }
                response.put("status", "ok")
                response.put("fingerprintSha256", identity.fingerprintSha256)
                response.put("port", LanTls.PORT)
                response.put("enabled", readLanEnabled())
            }

            "tunnelStatus" -> {
                val tunnelRunning = isProcessRunning(DAEMON_PROCESS_NAMES["TOR_TUNNEL"])
                val tunnelUrl =
                    if (tunnelRunning && isTorBootstrapped()) readTorOnionUrl() else null
                response.put("status", "ok")
                response.put("running", tunnelRunning)
                // running && url == null is a real, distinct state — tor is up but not yet
                // reachable. The client renders that as "connecting", not "offline".
                response.put("url", tunnelUrl ?: JSONObject.NULL)
                // BladeWatch-y7x2: the owner's INTENT, so the Dashboard can hide its connect card
                // entirely when the tunnel is switched off. Distinct from running: an enabled
                // tunnel is also not running for the first minute while tor bootstraps, and
                // hiding the card during THAT window would make the Dashboard look broken exactly
                // while the user is waiting for it.
                response.put("enabled", readDaemonEnabled("TOR_TUNNEL"))
            }

            // BladeWatch-rdtj.17: the Pear peer for the in-car UI -- running, the owner's switch, and
            // whether the car can actually be found (DHT online, from pear_daemon's status file),
            // plus connected companions and when one last connected. Never the topic or a peer key.
            "pearStatus" -> {
                val report = PearStatus.report(
                    pearStatusFileForTest ?: File(PearStatus.PATH),
                    isProcessRunning(DAEMON_PROCESS_NAMES["PEAR_PEER"]),
                    readDaemonEnabled("PEAR_PEER"),
                    System.currentTimeMillis(),
                )
                report.keys().forEach { key -> response.put(key, report.get(key)) }
            }

            // BladeWatch-abcx: enable/disable an OPTIONAL daemon from a UI that has no ADB.
            // Deliberately NOT a generic "run this daemon command" primitive: `type` is checked
            // against a fixed allow-list before anything happens, and no part of it ever reaches a
            // shell.
            //
            // Scope is TOR_TUNNEL and PEAR_PEER only, on purpose:
            //
            //  - CAMERA_DAEMON hosts THIS server. Stopping it kills the socket answering the
            //    request, and the Flutter APK has no ADB, so nothing could start it again — a
            //    one-way door out of that UI's reach.
            //  - SENTRY_DAEMON / ACC_SENTRY_DAEMON are CORE daemons. DaemonStartupManager's
            //    health check relaunches every core daemon within 30 s unless it is in an
            //    in-memory, app-process-only `userStoppedDaemons` set that this process cannot
            //    reach, so a stop here would silently undo itself.
            //
            // TOR_TUNNEL and PEAR_PEER have none of those problems: each is an OPTIONAL daemon
            // whose enabled state already persists, and the health check both starts it (through
            // TorLauncher / PearLauncher) and leaves it alone when disabled. So enabling is just recording the intent and letting
            // the existing launcher do the work; only disabling additionally has to kill the
            // running process, because the health check never kills, it only relaunches.
            "daemon_set_enabled" -> {
                val daemonType = cmd.optString("type", "")
                if (!TOGGLEABLE_DAEMONS.contains(daemonType)) {
                    response.put("status", "error")
                    response.put("message", "Daemon not toggleable over IPC: $daemonType")
                } else {
                    val enable = cmd.optBoolean("enabled", false)
                    val recorded = recordDaemonEnabled(daemonType, enable)
                    var killed = 0
                    if (!enable) {
                        // The health check only ever relaunches; without this the tunnel would
                        // keep serving until the next reboot despite the switch reading "off".
                        killed = killDaemonProcesses(DAEMON_PROCESS_NAMES[daemonType])
                    }
                    response.put("status", if (recorded) "ok" else "error")
                    response.put("enabled", enable)
                    response.put("killed", killed)
                    if (!recorded) {
                        response.put(
                            "message", "Failed to record daemon state for $daemonType"
                        )
                    }
                }
            }

            // uy93.2: "shell" (free-form sh -c over IPC) removed — RCE as UID 2000. No live
            // caller was found; SentryDaemon runs its own shell commands directly.

            "daemonStatus" -> {
                // BladeWatch-1xt9: process-liveness only (no ADB — this process already runs as
                // shell UID, same as the daemons it's checking). A boolean is all an external
                // check can honestly report; STARTING/STOPPING/ERROR are tracked client-side
                // during an in-flight start/stop call.
                val daemons = JSONObject()
                for ((key, procName) in DAEMON_PROCESS_NAMES) {
                    daemons.put(key, isProcessRunning(procName))
                }
                response.put("status", "ok")
                response.put("daemons", daemons)

                // BladeWatch-dh1r: the user's INTENT, reported separately from liveness.
                //
                // Liveness alone cannot drive a settings switch. Enabling a daemon only records
                // the intent — the health check launches it on its next cycle and tor then needs
                // up to a minute to bootstrap (61 s measured on the head unit). A switch bound to
                // liveness springs straight back to off, and the user's natural second tap
                // DISABLES the tunnel they just enabled, because the disable path also kills the
                // process.
                //
                // Only toggleable daemons appear here. The other three are started by the service
                // host and have no user-facing enabled state; inventing one would imply a switch
                // that does nothing.
                val enabled = JSONObject()
                for (type in TOGGLEABLE_DAEMONS) {
                    enabled.put(type, readDaemonEnabled(type))
                }
                response.put("enabled", enabled)
            }

            else -> {
                response.put("status", "error")
                response.put("message", "Unknown command: $action")
            }
        }

        return response
    }

    /**
     * True if a daemon process named exactly [processName] is currently running.
     *
     * Matches on **argv[0] only**, compared by basename and by exact equality — never a substring
     * of the whole command line. BladeWatch-xzhv: the previous implementation shelled out to
     * `pgrep -f`, and -f matches the FULL command line, so *any* process that merely mentioned a
     * daemon name reported that daemon as running. Observed on the head unit: an `adb shell`
     * one-liner that only wrote to the tunnel's log made `tunnelStatus` answer running=true with
     * no tunnel anywhere — which defeats the whole point of that command's liveness gate (it
     * exists so a URL left in the log by a dead session is never republished as a live tunnel).
     *
     * argv[0] is the right discriminator because of how these processes are launched, verified by
     * reading `/proc/<pid>/cmdline` on the device:
     *  - `app_process --nice-name=byd_cam_daemon …` overwrites argv[0] with the nice-name, so the
     *    live daemon's cmdline is literally "byd_cam_daemon" (NUL/space padded) — while the `sh
     *    -c` that launched it keeps its own argv[0] of "sh". Exactly the distinction the old
     *    pattern could not draw.
     *  - tor is exec'd by path, so its argv[0] is /data/local/tmp/bladewatch_tor — hence the
     *    basename comparison rather than raw equality.
     *
     * Exact equality also preserves the property the old leading-boundary group existed for:
     * sentry_daemon does not match acc_sentry_daemon.
     *
     * Reading procfs directly replaces a ProcessBuilder fork per daemon per poll, which removes
     * the file-descriptor leak the previous implementation had to guard against by hand. This
     * process runs as shell UID and can read other processes' cmdline.
     */
    fun isProcessRunning(processName: String?): Boolean =
        findPidsByProcessName(processName).isNotEmpty()

    companion object {

        private val SECRET_STORE = SecretConfigStore()

        /** ponytail: test seam — null = live SECRET_STORE; non-null = injected store. */
        @JvmField
        var secretStoreForTest: SecretConfigStore? = null

        /** Test seam for `pearStatus`: where pear_daemon's status file is read from. */
        @JvmStatic
        @Volatile
        var pearStatusFileForTest: File? = null

        /**
         * BladeWatch-1xt9: mirrors DaemonType.processName in
         * `app/src/main/java/com/loabletech/bladewatch/ui/model/DaemonType.kt` — kept as a local
         * copy rather than an import so this low-level server package doesn't take a dependency on
         * the ui.model layer. Update both if a process name ever changes.
         *
         * The "Map.of is API 30" hazard the Java version documented does not apply to a Kotlin
         * linkedMapOf, which compiles to a LinkedHashMap constructor.
         */
        private val DAEMON_PROCESS_NAMES: Map<String, String> = Collections.unmodifiableMap(
            linkedMapOf(
                "CAMERA_DAEMON" to "byd_cam_daemon",
                "SENTRY_DAEMON" to "sentry_daemon",
                "ACC_SENTRY_DAEMON" to "acc_sentry_daemon",
                // Renamed, not just re-pathed: argv[0] basename is the discriminator (see
                // isProcessRunning), and a bare "tor" is generic enough to collide. 14 chars,
                // under the kernel's 15-char cap on /proc/<pid>/comm so killall still matches.
                "TOR_TUNNEL" to "bladewatch_tor",
                // PearLauncher.PEAR_PROCESS -- the --nice-name, i.e. argv[0]; 11 chars.
                "PEAR_PEER" to "pear_daemon"
            )
        )

        /**
         * The only [UnifiedConfigManager] sections the `config_get_section`/`config_put` commands
         * will touch.
         *
         * BladeWatch-hygs: the Flutter APK needs the two sections its Settings screens own —
         * `statusOverlay` (the floating pill's per-segment visibility) and `developerOptions` (the
         * two logging toggles). Everything else in that file — recording, surveillance, streaming,
         * network — is set through a purpose-built command or an RPC that validates its input, and
         * must stay that way: a generic section write would let any IPC caller flip
         * `network.lanHttpEnabled` or disable surveillance with no validation at all.
         */
        private val PUBLIC_CONFIG_SECTIONS: Set<String> =
            Collections.unmodifiableSet(linkedSetOf("statusOverlay", "developerOptions"))

        /**
         * Sections readable over IPC but NOT writable — a strict superset of
         * [PUBLIC_CONFIG_SECTIONS].
         *
         * BladeWatch-i2wv: the Flutter Diagnostics screen's Camera health tile needs
         * `camera.probedCameraId` / `camera.manualOverride`. It needs to READ it and nothing more.
         *
         * The obvious move was to add `camera` to the set above, and that would have been wrong:
         * that set gates `config_put` as well, so it would have handed every IPC caller
         * unvalidated WRITE access to the camera configuration in order to satisfy a read-only
         * tile. Splitting read from write grants the tile exactly the privilege it needs and no
         * more.
         */
        private val PUBLIC_CONFIG_READABLE_SECTIONS: Set<String> =
            Collections.unmodifiableSet(LinkedHashSet(PUBLIC_CONFIG_SECTIONS).apply {
                add("camera")
            })

        /**
         * The WRITE gate. Reads use [isPublicConfigSectionReadable]. Public so
         * PublicConfigCommandTest, which is Java, can pin the allowlist.
         */
        @JvmStatic
        fun isPublicConfigSectionAllowed(section: String?): Boolean =
            PUBLIC_CONFIG_SECTIONS.contains(section)

        /** The READ gate — see [PUBLIC_CONFIG_READABLE_SECTIONS]. */
        @JvmStatic
        fun isPublicConfigSectionReadable(section: String?): Boolean =
            PUBLIC_CONFIG_READABLE_SECTIONS.contains(section)

        /**
         * The daemons `daemon_set_enabled` will act on. See that command's comment for why the
         * other three are excluded; this is the enforcement, not the documentation.
         */
        private val TOGGLEABLE_DAEMONS: Set<String> =
            Collections.unmodifiableSet(linkedSetOf("TOR_TUNNEL", "PEAR_PEER"))

        /**
         * ponytail: test seam — non-null stands in for the real `camera` config section.
         * `UnifiedConfigManager.loadConfig()` calls `android.util.Log`, which is not mocked in a
         * JVM unit test.
         */
        @JvmField
        var cameraConfigForTest: JSONObject? = null

        /**
         * ponytail: test seam — non-null records the intent instead of writing the real config,
         * which needs `android.util.Log` and a file under /storage.
         */
        @JvmField
        var daemonEnabledWritesForTest: MutableMap<String, Boolean>? = null

        /** ponytail: test seam -- non-null stands in for `network.lanHttpEnabled`. */
        @JvmField
        var lanEnabledForTest: Boolean? = null

        /** Writes the LAN opt-in; with [lanEnabledForTest] set, records it there instead. */
        private fun recordLanEnabled(enabled: Boolean): Boolean {
            if (lanEnabledForTest != null) {
                lanEnabledForTest = enabled
                return true
            }
            return UnifiedConfigManager.setLanHttpEnabled(enabled)
        }

        private fun readLanEnabled(): Boolean = lanEnabledForTest ?: try {
            UnifiedConfigManager.isLanHttpEnabled()
        } catch (t: Throwable) {
            false // unreadable config: report LAN access off rather than claim it is on
        }

        /** Test seam mirroring [daemonEnabledWritesForTest]; null = read the real config. */
        @JvmField
        var daemonEnabledReadsForTest: Map<String, Boolean>? = null

        /**
         * Whether the user has enabled an optional daemon. Absent means never enabled — a car
         * whose owner has never touched the tunnel must not be reported as having asked for one.
         */
        private fun readDaemonEnabled(daemonType: String): Boolean {
            daemonEnabledReadsForTest?.let { return it[daemonType] == true }
            return try {
                UnifiedConfigManager.isDaemonEnabled(daemonType) == true
            } catch (t: Throwable) {
                // An unreadable config must not take down daemonStatus, which the Startup and
                // Settings screens both poll. "Not enabled" is the safe answer: it understates
                // rather than claiming the owner asked for a tunnel they never enabled. The
                // liveness map is unaffected and still reports the truth.
                CameraDaemon.log(
                    "daemonStatus: could not read enabled state for " + daemonType + ": " +
                        t.message
                )
                false
            }
        }

        private fun recordDaemonEnabled(daemonType: String, enabled: Boolean): Boolean {
            daemonEnabledWritesForTest?.let {
                it[daemonType] = enabled
                return true
            }
            return UnifiedConfigManager.setDaemonEnabled(daemonType, enabled)
        }

        /**
         * ponytail: test seam — non-null diverts kills into this list instead of signalling
         * anything, so the allow-list and the kill decision are testable off-device.
         */
        @JvmField
        var killedPidsForTest: MutableList<Int>? = null

        /**
         * SIGKILLs every process whose argv[0] basename is [processName], returning how many were
         * signalled.
         *
         * The PIDs come from this class's own procfs scan, never from the request — the caller
         * supplies an enum-constrained daemon TYPE, which is mapped through DAEMON_PROCESS_NAMES
         * to a fixed process name. Nothing from the wire reaches this method.
         *
         * `android.os.Process.killProcess` is a direct syscall wrapper, not a shell invocation —
         * signalling a same-UID process is permitted, and this daemon runs as the same shell UID
         * the tunnel was launched under.
         */
        private fun killDaemonProcesses(processName: String?): Int {
            if (processName == null) return 0
            var killed = 0
            for (pid in findPidsByProcessName(processName)) {
                try {
                    val sink = killedPidsForTest
                    if (sink != null) {
                        sink.add(pid)
                    } else {
                        android.os.Process.killProcess(pid)
                    }
                    killed++
                } catch (e: Exception) {
                    CameraDaemon.log(
                        "daemon_set_enabled: could not kill pid " + pid + ": " + e.message
                    )
                }
            }
            return killed
        }

        /**
         * Where `TorLauncher` points tor's notice log — mirrors its TOR_LOG constant. Kept as a
         * local copy rather than an import so this low-level server package takes no dependency on
         * the launcher layer; update both if it ever moves.
         */
        @JvmField
        var torLogPathForTest: String? = null

        private fun torLogPath(): String = torLogPathForTest ?: "/data/local/tmp/tor.log"

        /**
         * Where tor writes the onion address, inside the hidden-service directory.
         *
         * Mode 600 and shell-owned, which is exactly why this command exists: the app UID cannot
         * read it, but this process already runs as shell UID — the same UID tor is launched under
         * — so it can, with no shell and no ADB.
         *
         * The sibling `hs_ed25519_secret_key` in that directory is the car's permanent
         * remote-access identity. Nothing may ever read, log or return it.
         */
        @JvmField
        var torHostnamePathForTest: String? = null

        private fun torHostnamePath(): String =
            torHostnamePathForTest ?: "/data/local/tmp/tor/hs/hostname"

        /**
         * A v3 onion address: 56 base32 characters (a-z and 2-7, so no 0/1/8/9) plus ".onion".
         * Validated rather than trusted because the Dashboard turns whatever comes back into a QR
         * code, and a half-written or truncated file would become a link that silently goes
         * nowhere.
         */
        private val ONION_V3: Pattern = Pattern.compile("^[a-z2-7]{56}\\.onion$")

        /** Only ever read this much of the tail of a large log — see [isTorBootstrapped]. */
        private const val TOR_LOG_TAIL_BYTES = 256 * 1024

        /**
         * The onion service URL, or null if tor has not written a usable address.
         *
         * Plain `http://` on purpose. The onion protocol already encrypts end to end and
         * authenticates the service by its key, so there is no TLS to add and no certificate to
         * check — the address IS the public key. This is not a downgrade from an https tunnel URL.
         *
         * Says nothing about reachability: the file persists across reboots, so callers must gate
         * on [isTorBootstrapped] as well. Public for TunnelStatusCommandTest, which is Java.
         */
        @JvmStatic
        fun readTorOnionUrl(): String? {
            val hostname = File(torHostnamePath())
            if (!hostname.isFile || hostname.length() == 0L) return null
            return try {
                // One short line; no streaming needed, unlike the log below.
                val raw = ByteArray(min(hostname.length(), 256L).toInt())
                FileInputStream(hostname).use { input ->
                    val read = input.read(raw)
                    if (read <= 0) return null
                    val addr = String(raw, 0, read, StandardCharsets.UTF_8).trim()
                    if (!ONION_V3.matcher(addr).matches()) null else "http://$addr"
                }
            } catch (e: Exception) {
                CameraDaemon.log("tunnelStatus: could not read tor hostname: " + e.message)
                null
            }
        }

        /**
         * Whether tor's CURRENT run has reached "Bootstrapped 100%".
         *
         * tor appends to one log across launches, so a success line from an earlier run sits above
         * the current run's "Bootstrapped 0% (starting)". Tracking the latest of the two rather
         * than merely searching for 100% is what stops a restart republishing the address during
         * the window when the service is not reachable.
         *
         * Never loads the whole log into memory: the previous implementation's comment records the
         * 85 MB+ allocations that caused. On a log larger than [TOR_LOG_TAIL_BYTES] it reads only
         * the tail, skipping the partial line the seek lands inside. tor logs at notice level and
         * is quiet once up, so the tail is where the current run is.
         *
         * Public for TunnelStatusCommandTest, which is Java.
         */
        @JvmStatic
        fun isTorBootstrapped(): Boolean {
            val log = File(torLogPath())
            if (!log.isFile || log.length() == 0L) return false
            return try {
                RandomAccessFile(log, "r").use { raf ->
                    val start = max(0L, raf.length() - TOR_LOG_TAIL_BYTES)
                    raf.seek(start)
                    if (start > 0) raf.readLine() // drop the partial line the seek landed inside
                    var bootstrapped = false
                    while (true) {
                        val line = raf.readLine() ?: break
                        // Order matters: a run that restarts resets the verdict, and a run that
                        // completes sets it. The last one wins.
                        if (line.contains("Bootstrapped 0%")) {
                            bootstrapped = false
                        } else if (line.contains("Bootstrapped 100%")) {
                            bootstrapped = true
                        }
                    }
                    bootstrapped
                }
            } catch (e: Exception) {
                CameraDaemon.log("tunnelStatus: could not read tor log: " + e.message)
                false
            }
        }

        /**
         * The section's current values, read through the same typed accessors the native UI uses
         * so the DEFAULTS for an absent key match exactly (`cameraVisible`/`tripVisible` default
         * true, `timingLogsEnabled` true, `debugLogsEnabled` false). Reading the raw JSON object
         * instead would hand the caller an empty object on a fresh install and make every client
         * re-derive those defaults.
         */
        @Throws(Exception::class)
        private fun publicConfigSection(section: String): JSONObject = when (section) {
            "statusOverlay" -> {
                val cfg = UnifiedConfigManager.getStatusOverlay()
                JSONObject()
                    .put("cameraVisible", cfg.optBoolean("cameraVisible", true))
                    .put("tripVisible", cfg.optBoolean("tripVisible", true))
            }
            "developerOptions" -> JSONObject()
                .put("timingLogsEnabled", UnifiedConfigManager.isTimingLogsEnabled())
                .put("debugLogsEnabled", UnifiedConfigManager.isDebugLogsEnabled())
            "camera" -> {
                // BladeWatch-i2wv: read-only, and only the two fields the Diagnostics camera tile
                // actually renders.
                //
                // Projected key by key rather than returned wholesale ON PURPOSE. The real
                // `camera` section also carries firmwareFingerprint, buildDisplay,
                // buildIncremental and productDevice — device-identifying strings that have no
                // business crossing this boundary to satisfy a status tile.
                val cfg = cameraConfigForTest
                    ?: UnifiedConfigManager.loadConfig().optJSONObject("camera")
                    ?: JSONObject()
                JSONObject()
                    .put("probedCameraId", cfg.optInt("probedCameraId", -1))
                    .put("manualOverride", cfg.optBoolean("manualOverride", false))
            }
            // Unreachable: every caller checks the relevant gate first.
            else -> JSONObject()
        }

        /**
         * Every PID whose argv[0] basename is exactly [processName] — see
         * [isProcessRunning] for why argv[0] and not the whole command line. A daemon can
         * legitimately have more than one PID (a forked child keeps the parent's argv), so this
         * returns all of them rather than the first.
         *
         * Public because AuthMiddleware and several Java tests call it.
         */
        @JvmStatic
        fun findPidsByProcessName(processName: String?): List<Int> {
            val pids = ArrayList<Int>()
            if (processName.isNullOrEmpty()) return pids
            val entries = procRoot().listFiles() ?: return pids
            for (entry in entries) {
                if (!isPid(entry.name)) continue
                val argv0 = readArgv0(File(entry, "cmdline")) ?: continue
                if (processName == basename(argv0)) {
                    val pid = entry.name.toIntOrNull()
                    // isPid() already screened this; belt and braces.
                    if (pid != null) pids.add(pid)
                }
            }
            return pids
        }

        /**
         * ponytail: test seam — null = the real /proc; non-null = a fake tree a unit test can
         * populate, which is what makes the matching rules above testable off-device.
         */
        @JvmField
        var procRootForTest: File? = null

        private fun procRoot(): File = procRootForTest ?: File("/proc")

        private fun isPid(name: String): Boolean {
            if (name.isEmpty()) return false
            for (c in name) {
                if (c < '0' || c > '9') return false
            }
            return true
        }

        /**
         * The first NUL-separated element of `/proc/<pid>/cmdline`, or null when the process is
         * gone or unreadable (both routine: PIDs vanish mid-scan, and kernel threads have an empty
         * cmdline).
         *
         * Trailing spaces are stripped because `app_process` pads the argv[0] region — the live
         * daemon's cmdline is the nice-name followed by filler, not a bare string.
         */
        private fun readArgv0(cmdline: File): String? = try {
            FileInputStream(cmdline).use { input ->
                // argv[0] alone; no need to read a whole command line to compare one token.
                val buf = ByteArray(256)
                val n = input.read(buf)
                if (n <= 0) {
                    null
                } else {
                    var end = 0
                    while (end < n && buf[end].toInt() != 0) end++
                    val first = String(buf, 0, end, StandardCharsets.UTF_8)
                    var trimEnd = first.length
                    while (trimEnd > 0 && first[trimEnd - 1] == ' ') trimEnd--
                    val trimmed = first.substring(0, trimEnd)
                    if (trimmed.isEmpty()) null else trimmed
                }
            }
        } catch (e: Exception) {
            // A PID that exited between listFiles() and the open is the common case.
            null
        }

        private fun basename(path: String): String {
            val slash = path.lastIndexOf('/')
            return if (slash < 0) path else path.substring(slash + 1)
        }

        // ==================== STATUS HELPERS ====================

        @JvmStatic
        fun getRecordingCameras(): JSONArray {
            val arr = JSONArray()
            // GPU pipeline: only show as recording if in recording mode AND actually recording.
            // Mosaic recording = all 4 cameras.
            val pipeline = CameraDaemon.getGpuPipeline()
            if (pipeline != null && pipeline.isRecordingMode && pipeline.isRecording) {
                arr.put(1)
                arr.put(2)
                arr.put(3)
                arr.put(4)
            }
            return arr
        }

        @JvmStatic
        fun getViewOnlyCameras(): JSONArray {
            val arr = JSONArray()
            // GPU pipeline: show as viewing if running but not in recording mode.
            val pipeline = CameraDaemon.getGpuPipeline()
            if (pipeline != null && pipeline.isRunning && !pipeline.isRecordingMode) {
                arr.put(1)
                arr.put(2)
                arr.put(3)
                arr.put(4)
            }
            return arr
        }

        @JvmStatic
        fun getActiveCameras(): JSONArray {
            val arr = JSONArray()
            // GPU pipeline: all 4 cameras active together.
            if (CameraDaemon.isSurveillanceActive()) {
                arr.put(1)
                arr.put(2)
                arr.put(3)
                arr.put(4)
            }
            return arr
        }

        @JvmStatic
        fun getAvailableCameras(): JSONArray {
            val arr = JSONArray()
            for (i in 1..4) {
                arr.put(i)
            }
            return arr
        }
    }
}
