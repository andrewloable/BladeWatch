package net.bladewatch.app.server;

import net.bladewatch.app.daemon.CameraDaemon;
import net.bladewatch.app.config.SecretConfigStore;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * TCP Command Server - handles JSON commands from DaemonClient.
 * Listens on localhost:19876 for security.
 */
public class TcpCommandServer {

    private final int port;
    private ServerSocket serverSocket;
    private volatile boolean running = true;
    private static final SecretConfigStore SECRET_STORE = new SecretConfigStore();

    // ponytail: test seam — null = live SECRET_STORE; non-null = injected store (test-only)
    static SecretConfigStore secretStoreForTest = null;

    private SecretConfigStore store() {
        return secretStoreForTest != null ? secretStoreForTest : SECRET_STORE;
    }

    // BladeWatch-1xt9: mirrors DaemonType.processName in
    // app/src/main/java/com/loabletech/bladewatch/ui/model/DaemonType.kt — kept as a
    // local copy rather than an import so this low-level server package doesn't take
    // a dependency on the ui.model layer. Update both if a process name ever changes.
    //
    // NOTE: built with LinkedHashMap, NOT Map.of(). java.util.Map.of is a Java 9 API
    // that Android only provides from API 30; this module is minSdk 25 and the target
    // head unit is API 29, and core library desugaring is not enabled. Because this is
    // a static final field, Map.of() would throw NoSuchMethodError from the static
    // initializer — i.e. ExceptionInInitializerError for the whole class, taking the
    // IPC command server down with it. Lint's NewApi check cannot catch this here
    // because the module sets lint { abortOnError = false }.
    private static final Map<String, String> DAEMON_PROCESS_NAMES;
    static {
        Map<String, String> names = new LinkedHashMap<>();
        names.put("CAMERA_DAEMON", "byd_cam_daemon");
        names.put("SENTRY_DAEMON", "sentry_daemon");
        names.put("ACC_SENTRY_DAEMON", "acc_sentry_daemon");
        // Renamed, not just re-pathed: argv[0] basename is the discriminator (see
        // isProcessRunning), and a bare "tor" is generic enough to collide. 14 chars,
        // under the kernel's 15-char cap on /proc/<pid>/comm so killall still matches.
        names.put("TOR_TUNNEL", "bladewatch_tor");
        DAEMON_PROCESS_NAMES = Collections.unmodifiableMap(names);
    }

    public TcpCommandServer(int port) {
        this.port = port;
    }

    public void start() {
        CameraDaemon.log("TCP server starting on port " + port);
        
        while (running && CameraDaemon.isRunning()) {
            try {
                if (serverSocket != null && !serverSocket.isClosed()) {
                    try { serverSocket.close(); } catch (Exception e) { CameraDaemon.log("WARN: TCP serverSocket.close() failed: " + e.getMessage()); }
                }
                
                serverSocket = new ServerSocket(port, 5, InetAddress.getByName("127.0.0.1"));
                serverSocket.setReuseAddress(true);
                CameraDaemon.log("TCP server listening on 127.0.0.1:" + port);

                while (running && CameraDaemon.isRunning() && !serverSocket.isClosed()) {
                    try {
                        Socket client = serverSocket.accept();
                        CameraDaemon.log("TCP client connected: " + client.getRemoteSocketAddress());
                        new Thread(() -> handleClient(client), "TcpClient-" + System.currentTimeMillis()).start();
                    } catch (java.net.SocketException e) {
                        if (running) {
                            CameraDaemon.log("WARN: TCP socket error: " + e.getMessage());
                        }
                        break;
                    }
                }
                
                if (running) {
                    CameraDaemon.log("TCP server restarting...");
                    Thread.sleep(2000);
                }
                
            } catch (java.net.BindException e) {
                CameraDaemon.log("ERROR: TCP port " + port + " in use, retrying...");
                try { Thread.sleep(5000); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); break; }
            } catch (Exception e) {
                CameraDaemon.log("ERROR: TCP server error: " + e.getMessage());
                if (running) {
                    try { Thread.sleep(3000); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); break; }
                }
            }
        }
        
        CameraDaemon.log("TCP server stopped");
    }

    public void stop() {
        running = false;
        try {
            if (serverSocket != null) serverSocket.close();
        } catch (Exception e) {
            CameraDaemon.log("WARN: TCP serverSocket.close() in stop() failed: " + e.getMessage());
        }
    }

    private void handleClient(Socket client) {
        try {
            // Defence in depth: the IPC token is world-readable (644) by design,
            // so verify the connecting process's UID before doing anything. Only
            // root/system/shell-daemon and the BladeWatch app may drive commands
            // (notably 'shell' and 'secret_*'). Reject everything else.
            int peerUid = PeerCredentials.resolvePeerUid(client);
            if (!PeerCredentials.isTrusted(peerUid)) {
                CameraDaemon.log("WARN: TCP IPC rejected untrusted peer uid=" + peerUid
                        + " from " + client.getRemoteSocketAddress());
                try { client.close(); } catch (Exception e) { CameraDaemon.log("WARN: TCP client.close() failed: " + e.getMessage()); }
                return;
            }

            BufferedReader reader = new BufferedReader(new InputStreamReader(client.getInputStream()));
            PrintWriter writer = new PrintWriter(new OutputStreamWriter(client.getOutputStream()), true);

            // Require auth as the first message: {"token": "<value>"}
            String authLine = reader.readLine();
            if (authLine == null) return;
            JSONObject authMsg = new JSONObject(authLine);
            if (!IpcTokenManager.isValid(authMsg.optString("token", ""))) {
                JSONObject err = new JSONObject();
                err.put("status", "error");
                err.put("message", "Unauthorized");
                writer.println(err.toString());
                return;
            }

            String line;
            while ((line = reader.readLine()) != null) {
                try {
                    JSONObject cmd = new JSONObject(line);
                    CameraDaemon.log("TCP received command: " + cmd.optString("cmd", ""));
                    JSONObject response = processCommand(cmd);
                    writer.println(response.toString());
                } catch (Exception e) {
                    JSONObject error = new JSONObject();
                    error.put("status", "error");
                    error.put("message", e.getMessage());
                    writer.println(error.toString());
                }
            }
        } catch (Exception e) {
            CameraDaemon.log("TCP client disconnected: " + e.getMessage());
        } finally {
            try { client.close(); } catch (Exception e) { CameraDaemon.log("WARN: TCP client.close() in finally failed: " + e.getMessage()); }
        }
    }

    JSONObject processCommand(JSONObject cmd) throws Exception {
        String action = cmd.optString("cmd", "");
        JSONObject response = new JSONObject();
        
        CameraDaemon.log("Processing command: " + action);

        switch (action) {
            case "start":
                // Start recording - streaming is now independent and NOT started by default
                JSONArray camsToStart = cmd.optJSONArray("cameras");
                boolean enableStream = cmd.optBoolean("stream", false);  // Default to false - streaming is separate
                if (camsToStart != null) {
                    for (int i = 0; i < camsToStart.length(); i++) {
                        int camId = camsToStart.getInt(i);
                        CameraDaemon.startCamera(camId, enableStream, false);
                    }
                }
                response.put("status", "ok");
                response.put("recording", getRecordingCameras());
                break;

            case "stop":
                // User explicitly requested stop - force stop even if recording
                boolean forceStop = cmd.optBoolean("force", true);  // Default to force for backward compat
                JSONArray camsToStop = cmd.optJSONArray("cameras");
                if (camsToStop != null) {
                    for (int i = 0; i < camsToStop.length(); i++) {
                        CameraDaemon.stopCamera(camsToStop.getInt(i), forceStop);
                    }
                } else {
                    CameraDaemon.stopAllCameras(forceStop);
                }
                response.put("status", "ok");
                response.put("recording", getRecordingCameras());
                break;

            case "status":
                response.put("status", "ok");
                response.put("recording", getRecordingCameras());
                response.put("viewing", getViewOnlyCameras());
                response.put("active", getActiveCameras());
                response.put("available", getAvailableCameras());
                break;

            case "ping":
                response.put("status", "ok");
                response.put("message", "pong");
                break;

            case "getFrame":
                int frameViewId = cmd.optInt("camera", 1);
                // GPU pipeline: get frame from GPU camera extractor
                net.bladewatch.app.surveillance.GpuSurveillancePipeline gpuPipeline = CameraDaemon.getGpuPipeline();
                if (gpuPipeline != null && gpuPipeline.getCamera() != null) {
                    byte[] jpegFrame = gpuPipeline.getCamera().getLatestJpegFrame(frameViewId);
                    if (jpegFrame != null) {
                        String base64Frame = android.util.Base64.encodeToString(jpegFrame, android.util.Base64.NO_WRAP);
                        response.put("status", "ok");
                        response.put("frame", base64Frame);
                        response.put("timestamp", System.currentTimeMillis());
                    } else {
                        response.put("status", "error");
                        response.put("message", "No frame available for view " + frameViewId);
                    }
                } else {
                    response.put("status", "error");
                    response.put("message", "GPU pipeline not available");
                }
                break;

            case "setOutput":
                response.put("status", "ok");
                response.put("outputDir", CameraDaemon.getOutputDir());
                break;

            case "shutdown":
                response.put("status", "ok");
                new Thread(() -> {
                    try { Thread.sleep(300); } catch (InterruptedException e) { Thread.currentThread().interrupt(); return; }
                    CameraDaemon.shutdown();
                }, "ShutdownThread").start();
                break;

            case "setStreamMode":
                String mode = cmd.optString("mode", "");
                if (mode.equals("private") || mode.equals("public")) {
                    CameraDaemon.setStreamMode(mode);
                    response.put("status", "ok");
                    response.put("mode", CameraDaemon.getStreamMode());
                    response.put("message", "Stream mode set to " + mode + " (both use tunnel URLs now)");
                } else {
                    response.put("status", "error");
                    response.put("message", "Invalid mode. Use 'private' or 'public'");
                }
                break;

            case "getStreamMode":
                response.put("status", "ok");
                response.put("mode", CameraDaemon.getStreamMode());
                response.put("isPublic", CameraDaemon.isPublicMode());
                break;

            // ==================== SURVEILLANCE COMMANDS ====================
            
            case "enableSurveillance":
                net.bladewatch.app.config.UnifiedConfigManager.setSurveillanceEnabled(true);
                if (!net.bladewatch.app.monitor.AccMonitor.isAccOn()) {
                    CameraDaemon.enableSurveillance();
                }
                response.put("status", "ok");
                response.put("surveillance", CameraDaemon.getSurveillanceStatus());
                break;

            case "disableSurveillance":
                CameraDaemon.disableSurveillance();
                net.bladewatch.app.config.UnifiedConfigManager.setSurveillanceEnabled(false);
                response.put("status", "ok");
                response.put("surveillance", CameraDaemon.getSurveillanceStatus());
                break;

            case "surveillanceStatus":
                response.put("status", "ok");
                response.put("surveillance", CameraDaemon.getSurveillanceStatus());
                break;

            case "setAccState":
                boolean accOff = cmd.optBoolean("accOff", false);
                CameraDaemon.onAccStateChanged(accOff);
                response.put("status", "ok");
                response.put("accOff", accOff);
                response.put("surveillance", CameraDaemon.getSurveillanceStatus());
                break;
            
            // ==================== RECORDING MODE COMMANDS ====================
            
            case "setRecordingMode":
                String recordingMode = cmd.optString("mode", "");
                if (!recordingMode.isEmpty()) {
                    CameraDaemon.setRecordingMode(recordingMode);
                    response.put("status", "ok");
                    response.put("mode", CameraDaemon.getRecordingMode());
                } else {
                    response.put("status", "error");
                    response.put("message", "No mode specified");
                }
                break;
            
            case "getRecordingMode":
                response.put("status", "ok");
                response.put("mode", CameraDaemon.getRecordingMode());
                break;

            // ==================== QUALITY SETTINGS COMMANDS ====================
            
            case "setBitrate":
                // Set recording bitrate: LOW (2Mbps), MEDIUM (3Mbps), HIGH (6Mbps)
                String bitrateValue = cmd.optString("value", "").toUpperCase();
                if (bitrateValue.equals("LOW") || bitrateValue.equals("MEDIUM") || bitrateValue.equals("HIGH")) {
                    // TCP clients still send the legacy bitrate labels; convert
                    // them at the IPC boundary so the daemon uses the canonical
                    // ECONOMY/STANDARD/HIGH recording-quality path.
                    String qualityValue;
                    switch (bitrateValue) {
                        case "LOW": qualityValue = "ECONOMY"; break;
                        case "HIGH": qualityValue = "HIGH"; break;
                        case "MEDIUM":
                        default: qualityValue = "STANDARD"; break;
                    }
                    CameraDaemon.setRecordingQuality(qualityValue);
                    HttpServer.setRecordingQuality(qualityValue);
                    response.put("status", "ok");
                    response.put("bitrate", bitrateValue);
                    response.put("quality", qualityValue);
                    response.put("message", "Bitrate set to " + bitrateValue + " (" + qualityValue + ") - applied immediately");
                } else {
                    response.put("status", "error");
                    response.put("message", "Invalid bitrate. Use LOW, MEDIUM, or HIGH");
                }
                break;

            case "setCodec":
                // Recording codec is H264-only — HEVC playback isn't supported by the WebView video player.
                String codecValue = cmd.optString("value", "").toUpperCase();
                if (codecValue.equals("H264")) {
                    CameraDaemon.setRecordingCodec(codecValue);
                    HttpServer.setRecordingCodec(codecValue);
                    response.put("status", "ok");
                    response.put("codec", codecValue);
                    response.put("message", "Codec set to " + codecValue + " - restart recording to apply");
                } else {
                    response.put("status", "error");
                    response.put("message", "Invalid codec. Only H264 is supported");
                }
                break;

            case "setRecordingsStorageType":
                // Set recordings storage type: INTERNAL or SD_CARD
                String recStorageTypeValue = cmd.optString("value", "").toUpperCase();
                if (recStorageTypeValue.equals("INTERNAL") || recStorageTypeValue.equals("SD_CARD")) {
                    net.bladewatch.app.storage.StorageManager storageManager =
                        net.bladewatch.app.storage.StorageManager.getInstance();
                    net.bladewatch.app.storage.StorageManager.StorageType recType =
                        "SD_CARD".equals(recStorageTypeValue) ?
                            net.bladewatch.app.storage.StorageManager.StorageType.SD_CARD :
                            net.bladewatch.app.storage.StorageManager.StorageType.INTERNAL;
                    boolean recSuccess = storageManager.setRecordingsStorageType(recType);
                    if (recSuccess) {
                        response.put("status", "ok");
                        response.put("storageType", recStorageTypeValue);
                        response.put("path", storageManager.getRecordingsPath());
                        response.put("message", "Recordings storage set to " + recStorageTypeValue);
                        CameraDaemon.log("Recordings storage type set to " + recStorageTypeValue + " via TCP IPC");
                    } else {
                        response.put("status", "error");
                        response.put("message", "SD card not available");
                    }
                } else {
                    response.put("status", "error");
                    response.put("message", "Invalid storage type. Use INTERNAL or SD_CARD");
                }
                break;

            case "setRecordingsLimitMb":
                // Set recordings storage limit in MB
                long recLimitMb = cmd.optLong("value", -1);
                if (recLimitMb > 0) {
                    net.bladewatch.app.storage.StorageManager recLimitStorage =
                        net.bladewatch.app.storage.StorageManager.getInstance();
                    recLimitStorage.setRecordingsLimitMb(recLimitMb);
                    response.put("status", "ok");
                    response.put("limitMb", recLimitStorage.getRecordingsLimitMb());
                    response.put("message", "Recordings limit set to " + recLimitStorage.getRecordingsLimitMb() + " MB");
                    CameraDaemon.log("Recordings limit set to " + recLimitStorage.getRecordingsLimitMb() + " MB via TCP IPC");
                    // Trigger async cleanup
                    new Thread(() -> recLimitStorage.ensureRecordingsSpace(0), "RecLimitCleanup").start();
                } else {
                    response.put("status", "error");
                    response.put("message", "Invalid limit value");
                }
                break;

            case "getQualitySettings":
                // Get current quality settings - read directly from unified config for cross-UID sync
                response.put("status", "ok");
                
                // Read from unified config file (source of truth for cross-UID access)
                String bitrate = "MEDIUM";
                String codec = "H264";
                try {
                    java.io.File unifiedFile = new java.io.File("/data/local/tmp/bladewatch_config.json");
                    if (unifiedFile.exists()) {
                        java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.FileReader(unifiedFile));
                        StringBuilder sb = new StringBuilder();
                        String line;
                        while ((line = reader.readLine()) != null) {
                            sb.append(line);
                        }
                        reader.close();
                        
                        JSONObject unified = new JSONObject(sb.toString());
                        JSONObject recording = unified.optJSONObject("recording");
                        if (recording != null) {
                            bitrate = recording.optString("bitrate", "MEDIUM");
                            codec = recording.optString("codec", "H264");
                        }
                    }
                } catch (Exception e) {
                    CameraDaemon.log("getQualitySettings: Could not read unified config: " + e.getMessage());
                    // Fall back to HttpServer static vars
                    bitrate = HttpServer.getRecordingBitrate();
                    codec = HttpServer.getRecordingCodec();
                }
                
                response.put("bitrate", bitrate);
                response.put("codec", codec);
                response.put("bitrateOptions", new JSONObject()
                    .put("LOW", "2 Mbps")
                    .put("MEDIUM", "3 Mbps")
                    .put("HIGH", "6 Mbps"));
                response.put("codecOptions", new JSONObject()
                    .put("H264", "H.264/AVC (Compatible)"));
                break;

            case "auth_invalidate":
                // Invalidate cached auth state - called when app regenerates token
                // This forces daemon to reload auth state from file on next JWT validation
                net.bladewatch.app.auth.AuthManager.invalidateCache();
                CameraDaemon.log("Auth cache invalidated via IPC");
                response.put("status", "ok");
                response.put("message", "Auth cache invalidated");
                break;

            case "secret_get": {
                String section = cmd.optString("section", "");
                String key = cmd.optString("key", "");
                String value = store().getString(section, key);
                response.put("status", "ok");
                response.put("value", value == null ? "" : value);
                break;
            }

            case "secret_get_section": {
                String section = cmd.optString("section", "");
                JSONObject data = store().loadSection(section);
                response.put("status", "ok");
                response.put("section", data);
                break;
            }

            case "secret_put": {
                String section = cmd.optString("section", "");
                String key = cmd.optString("key", "");
                Object value = cmd.has("value") ? cmd.get("value") : null;
                boolean ok;
                if (value == null || value == JSONObject.NULL) {
                    ok = store().delete(section, key);
                } else if (value instanceof Boolean) {
                    ok = store().putBoolean(section, key, (Boolean) value);
                } else if (value instanceof Number) {
                    ok = store().putLong(section, key, ((Number) value).longValue());
                } else {
                    ok = store().putString(section, key, String.valueOf(value));
                }
                response.put("status", ok ? "ok" : "error");
                if (!ok) {
                    response.put("message", "Failed to write secret");
                }
                break;
            }

            case "secret_delete": {
                String section = cmd.optString("section", "");
                String key = cmd.optString("key", "");
                boolean ok = store().delete(section, key);
                response.put("status", ok ? "ok" : "error");
                if (!ok) {
                    response.put("message", "Failed to delete secret");
                }
                break;
            }

            // BladeWatch-hygs: PUBLIC (non-secret) config sections over IPC.
            // Deliberately NOT a generic "write anything to bladewatch_config.json"
            // primitive: only the sections a Settings screen actually owns are
            // reachable (PUBLIC_CONFIG_SECTIONS), so this command cannot be used to
            // reconfigure recording, surveillance or the network binding. The secret
            // store is unreachable from here — that stays on the secret_* family.
            case "config_get_section": {
                String section = cmd.optString("section", "");
                if (!isPublicConfigSectionReadable(section)) {
                    response.put("status", "error");
                    response.put("message", "Section not exposed over IPC: " + section);
                    break;
                }
                response.put("status", "ok");
                response.put("section", publicConfigSection(section));
                break;
            }

            case "config_put": {
                String section = cmd.optString("section", "");
                String key = cmd.optString("key", "");
                if (!isPublicConfigSectionAllowed(section)) {
                    response.put("status", "error");
                    response.put("message", "Section not exposed over IPC: " + section);
                    break;
                }
                Object value = cmd.has("value") ? cmd.get("value") : null;
                if (key.isEmpty() || value == null || value == JSONObject.NULL) {
                    response.put("status", "error");
                    response.put("message", "config_put needs a non-empty key and a value");
                    break;
                }
                boolean ok = net.bladewatch.app.config.UnifiedConfigManager.updateValues(
                        section, Collections.singletonMap(key, value));
                response.put("status", ok ? "ok" : "error");
                if (!ok) {
                    response.put("message", "Failed to write " + section + "." + key);
                }
                break;
            }

            // BladeWatch-m1po / BladeWatch-3lbz.2: the current Tor onion URL, for the
            // Dashboard's remote-access tile / QR code in the Flutter APK, which has no
            // path to TorController's in-memory LiveData or to the app-private
            // SharedPreferences copy.
            //
            // TWO gates, and both are load-bearing:
            //
            // 1. The process must be running. tor's hs/hostname file is written once and
            //    then persists forever, reboots included, so on its own it says nothing
            //    about liveness.
            // 2. tor must have BOOTSTRAPPED. The tunnel this replaces only
            //    printed its URL once the tunnel was live. tor writes hs/hostname about a
            //    second after first launch and then takes ~82 s (cold) or ~6 s (warm) to
            //    reach the network — measured on the head unit 2026-09-14. Publishing the
            //    address in that window puts an "online" QR code on screen for a service
            //    nothing can reach yet.
            case "tunnelStatus": {
                boolean tunnelRunning = isProcessRunning(DAEMON_PROCESS_NAMES.get("TOR_TUNNEL"));
                String tunnelUrl =
                        (tunnelRunning && isTorBootstrapped()) ? readTorOnionUrl() : null;
                response.put("status", "ok");
                response.put("running", tunnelRunning);
                // running && url == null is a real, distinct state — tor is up but not yet
                // reachable. The client renders that as "connecting", not "offline".
                response.put("url", tunnelUrl == null ? JSONObject.NULL : tunnelUrl);
                // BladeWatch-y7x2: the owner's INTENT, so the Dashboard can hide its connect
                // card entirely when the tunnel is switched off. Distinct from running: an
                // enabled tunnel is also not running for the first minute while tor
                // bootstraps, and hiding the card during THAT window would make the
                // Dashboard look broken exactly while the user is waiting for it.
                response.put("enabled", readDaemonEnabled("TOR_TUNNEL"));
                break;
            }

            // BladeWatch-abcx: enable/disable an OPTIONAL daemon from a UI that has no
            // ADB. Deliberately NOT a generic "run this daemon command" primitive:
            // `type` is checked against a fixed allow-list before anything happens, and
            // no part of it ever reaches a shell.
            //
            // Scope is TOR_TUNNEL only, on purpose (decided on this issue):
            //
            //  - CAMERA_DAEMON hosts THIS server. Stopping it kills the socket answering
            //    the request, and the Flutter APK has no ADB, so nothing could start it
            //    again — a one-way door out of that UI's reach.
            //  - SENTRY_DAEMON / ACC_SENTRY_DAEMON are CORE daemons. DaemonStartupManager's
            //    health check relaunches every core daemon within 30 s unless it is in an
            //    in-memory, app-process-only `userStoppedDaemons` set that this process
            //    cannot reach, so a stop here would silently undo itself. Making those
            //    stoppable needs a cross-process decision about whether a stopped DASHCAM
            //    should stay stopped across a reboot — see this issue.
            //
            // TOR_TUNNEL has none of those problems: it is an OPTIONAL daemon whose
            // enabled state native ALREADY persists, and the health check both starts it
            // (through TorLauncher) and leaves it alone
            // when disabled. So enabling is just recording the intent and letting the
            // existing launcher do the work; only disabling additionally has to kill the
            // running process, because the health check never kills, it only relaunches.
            case "daemon_set_enabled": {
                String daemonType = cmd.optString("type", "");
                if (!TOGGLEABLE_DAEMONS.contains(daemonType)) {
                    response.put("status", "error");
                    response.put("message", "Daemon not toggleable over IPC: " + daemonType);
                    break;
                }
                boolean enable = cmd.optBoolean("enabled", false);
                boolean recorded = recordDaemonEnabled(daemonType, enable);
                int killed = 0;
                if (!enable) {
                    // The health check only ever relaunches; without this the tunnel would
                    // keep serving until the next reboot despite the switch reading "off".
                    killed = killDaemonProcesses(DAEMON_PROCESS_NAMES.get(daemonType));
                }
                response.put("status", recorded ? "ok" : "error");
                response.put("enabled", enable);
                response.put("killed", killed);
                if (!recorded) {
                    response.put("message", "Failed to record daemon state for " + daemonType);
                }
                break;
            }

            // uy93.2: "shell" (free-form sh -c over IPC) removed — RCE as UID 2000.
            // No live caller found; SentryDaemon runs its own shell commands directly.

            case "daemonStatus": {
                // BladeWatch-1xt9: process-liveness only (no ADB — this process already
                // runs as shell UID, same as the daemons it's checking). A boolean is
                // all an external check can honestly report; STARTING/STOPPING/ERROR
                // are tracked client-side during an in-flight start/stop call, same as
                // the native AdbDaemonLauncher-based check already does.
                JSONObject daemons = new JSONObject();
                for (Map.Entry<String, String> entry : DAEMON_PROCESS_NAMES.entrySet()) {
                    daemons.put(entry.getKey(), isProcessRunning(entry.getValue()));
                }
                response.put("status", "ok");
                response.put("daemons", daemons);

                // BladeWatch-dh1r: the user's INTENT, reported separately from liveness.
                //
                // Liveness alone cannot drive a settings switch. Enabling a daemon only
                // records the intent — the health check launches it on its next cycle and
                // tor then needs up to a minute to bootstrap (61 s measured on the head
                // unit). A switch bound to liveness springs straight back to off, and the
                // user's natural second tap DISABLES the tunnel they just enabled, because
                // the disable path also kills the process.
                //
                // Only toggleable daemons appear here. The other three are started by the
                // service host and have no user-facing enabled state; inventing one would
                // imply a switch that does nothing.
                JSONObject enabled = new JSONObject();
                for (String type : TOGGLEABLE_DAEMONS) {
                    enabled.put(type, readDaemonEnabled(type));
                }
                response.put("enabled", enabled);
                break;
            }

            default:
                response.put("status", "error");
                response.put("message", "Unknown command: " + action);
        }
        
        return response;
    }

    /**
     * The only {@link net.bladewatch.app.config.UnifiedConfigManager} sections the
     * {@code config_get_section}/{@code config_put} commands will touch.
     *
     * <p>BladeWatch-hygs: the Flutter APK needs the two sections its Settings screens
     * own — {@code statusOverlay} (the floating pill's per-segment visibility, read by
     * {@link net.bladewatch.app.overlay.StatusOverlayService#updateUI}) and
     * {@code developerOptions} (the two logging toggles). Everything else in that file
     * — recording, surveillance, streaming, network — is set through a purpose-built
     * command or an RPC that validates its input, and must stay that way: a generic
     * section write would let any IPC caller flip {@code network.lanHttpEnabled} or
     * disable surveillance with no validation at all.
     *
     * <p>Built with LinkedHashSet, not {@code Set.of} — same API-29 reason as
     * {@link #DAEMON_PROCESS_NAMES} above.
     */
    private static final java.util.Set<String> PUBLIC_CONFIG_SECTIONS;
    static {
        java.util.Set<String> sections = new java.util.LinkedHashSet<>();
        sections.add("statusOverlay");
        sections.add("developerOptions");
        PUBLIC_CONFIG_SECTIONS = Collections.unmodifiableSet(sections);
    }

    /**
     * Sections readable over IPC but NOT writable — a strict superset of
     * {@link #PUBLIC_CONFIG_SECTIONS}.
     *
     * <p>BladeWatch-i2wv: the Flutter Diagnostics screen's Camera health tile needs
     * {@code camera.probedCameraId} / {@code camera.manualOverride}, which is exactly
     * what native's {@code DiagnosticsFragment.updateCameraTile()} reads. It needs to
     * READ it and nothing more.
     *
     * <p>The obvious move was to add {@code camera} to the set above, and that would
     * have been wrong: that set gates {@code config_put} as well, so it would have
     * handed every IPC caller unvalidated WRITE access to the camera configuration in
     * order to satisfy a read-only tile. Splitting read from write grants the tile
     * exactly the privilege it needs and no more.
     *
     * <p>Write access still goes through {@link #PUBLIC_CONFIG_SECTIONS} alone, so
     * {@code camera} remains unwritable over IPC. Anything that genuinely needs to
     * change camera config keeps using its purpose-built command, which validates.
     */
    private static final java.util.Set<String> PUBLIC_CONFIG_READABLE_SECTIONS;
    static {
        java.util.Set<String> sections = new java.util.LinkedHashSet<>(PUBLIC_CONFIG_SECTIONS);
        sections.add("camera");
        PUBLIC_CONFIG_READABLE_SECTIONS = Collections.unmodifiableSet(sections);
    }

    /**
     * Package-private so {@code PublicConfigCommandTest} can pin the allowlist.
     *
     * <p>This is the WRITE gate. Reads use {@link #isPublicConfigSectionReadable}.
     */
    static boolean isPublicConfigSectionAllowed(String section) {
        return PUBLIC_CONFIG_SECTIONS.contains(section);
    }

    /** The READ gate — see {@link #PUBLIC_CONFIG_READABLE_SECTIONS}. */
    static boolean isPublicConfigSectionReadable(String section) {
        return PUBLIC_CONFIG_READABLE_SECTIONS.contains(section);
    }

    /**
     * The daemons {@code daemon_set_enabled} will act on. See that command's comment for
     * why the other three are excluded; this is the enforcement, not the documentation.
     */
    private static final java.util.Set<String> TOGGLEABLE_DAEMONS;
    static {
        java.util.Set<String> toggleable = new java.util.LinkedHashSet<>();
        toggleable.add("TOR_TUNNEL");
        TOGGLEABLE_DAEMONS = Collections.unmodifiableSet(toggleable);
    }

    /**
     * ponytail: test seam — non-null stands in for the real `camera` config section.
     * {@code UnifiedConfigManager.loadConfig()} calls {@code android.util.Log}, which
     * is not mocked in a JVM unit test.
     */
    static JSONObject cameraConfigForTest = null;

    /**
     * ponytail: test seam — non-null records the intent instead of writing the real
     * config, which needs {@code android.util.Log} and a file under /storage.
     */
    static java.util.Map<String, Boolean> daemonEnabledWritesForTest = null;

    /** Test seam mirroring {@link #daemonEnabledWritesForTest}; null = read the real config. */
    static java.util.Map<String, Boolean> daemonEnabledReadsForTest = null;

    /**
     * Whether the user has enabled an optional daemon. Absent means never enabled — a car
     * whose owner has never touched the tunnel must not be reported as having asked for one.
     */
    private static boolean readDaemonEnabled(String daemonType) {
        if (daemonEnabledReadsForTest != null) {
            return Boolean.TRUE.equals(daemonEnabledReadsForTest.get(daemonType));
        }
        try {
            Boolean recorded =
                    net.bladewatch.app.config.UnifiedConfigManager.isDaemonEnabled(daemonType);
            return Boolean.TRUE.equals(recorded);
        } catch (Throwable t) {
            // An unreadable config must not take down daemonStatus, which the Startup and
            // Settings screens both poll. "Not enabled" is the safe answer: it understates
            // rather than claiming the owner asked for a tunnel they never enabled. The
            // liveness map above is unaffected and still reports the truth.
            CameraDaemon.log("daemonStatus: could not read enabled state for "
                    + daemonType + ": " + t.getMessage());
            return false;
        }
    }

    private static boolean recordDaemonEnabled(String daemonType, boolean enabled) {
        if (daemonEnabledWritesForTest != null) {
            daemonEnabledWritesForTest.put(daemonType, enabled);
            return true;
        }
        return net.bladewatch.app.config.UnifiedConfigManager.setDaemonEnabled(daemonType, enabled);
    }

    /**
     * ponytail: test seam — non-null diverts kills into this list instead of signalling
     * anything, so the allow-list and the kill decision are testable off-device.
     */
    static java.util.List<Integer> killedPidsForTest = null;

    /**
     * SIGKILLs every process whose argv[0] basename is {@code processName}, returning how
     * many were signalled.
     *
     * <p>The PIDs come from this class's own procfs scan, never from the request — the
     * caller supplies an enum-constrained daemon TYPE, which is mapped through
     * {@link #DAEMON_PROCESS_NAMES} to a fixed process name. Nothing from the wire reaches
     * this method.
     *
     * <p>{@code android.os.Process.killProcess} is a direct syscall wrapper, not a shell
     * invocation — signalling a same-UID process is permitted, and this daemon runs as the
     * same shell UID the tunnel was launched under.
     */
    private static int killDaemonProcesses(String processName) {
        if (processName == null) return 0;
        int killed = 0;
        for (Integer pid : findPidsByProcessName(processName)) {
            try {
                if (killedPidsForTest != null) {
                    killedPidsForTest.add(pid);
                } else {
                    android.os.Process.killProcess(pid);
                }
                killed++;
            } catch (Exception e) {
                CameraDaemon.log("daemon_set_enabled: could not kill pid " + pid + ": " + e.getMessage());
            }
        }
        return killed;
    }

    /**
     * Where {@code TorLauncher} points tor's notice log — mirrors its {@code TOR_LOG}
     * constant ({@code app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt}).
     * Kept as a local copy rather than an import so this low-level server package takes no
     * dependency on the launcher layer; update both if it ever moves.
     */
    static String torLogPathForTest = null;

    private static String torLogPath() {
        return torLogPathForTest != null ? torLogPathForTest : "/data/local/tmp/tor.log";
    }

    /**
     * Where tor writes the onion address, inside the hidden-service directory.
     *
     * <p>Mode 600 and shell-owned, which is exactly why this command exists: the app UID
     * cannot read it, but this process already runs as shell UID — the same UID tor is
     * launched under — so it can, with no shell and no ADB.
     *
     * <p>The sibling {@code hs_ed25519_secret_key} in that directory is the car's permanent
     * remote-access identity. Nothing may ever read, log or return it.
     */
    static String torHostnamePathForTest = null;

    private static String torHostnamePath() {
        return torHostnamePathForTest != null
                ? torHostnamePathForTest
                : "/data/local/tmp/tor/hs/hostname";
    }

    /**
     * A v3 onion address: 56 base32 characters (a-z and 2-7, so no 0/1/8/9) plus ".onion".
     * Validated rather than trusted because the Dashboard turns whatever comes back into a
     * QR code, and a half-written or truncated file would become a link that silently goes
     * nowhere.
     */
    private static final java.util.regex.Pattern ONION_V3 =
            java.util.regex.Pattern.compile("^[a-z2-7]{56}\\.onion$");

    /**
     * Only ever read this much of the tail of a large log — see {@link #isTorBootstrapped}.
     */
    private static final int TOR_LOG_TAIL_BYTES = 256 * 1024;

    /**
     * The onion service URL, or null if tor has not written a usable address.
     *
     * <p>Plain {@code http://} on purpose. The onion protocol already encrypts end to end and
     * authenticates the service by its key, so there is no TLS to add and no certificate to
     * check — the address IS the public key. This is not a downgrade from an https tunnel URL.
     *
     * <p>Says nothing about reachability: the file persists across reboots, so callers must
     * gate on {@link #isTorBootstrapped} as well. Package-private for
     * {@code TunnelStatusCommandTest}.
     */
    static String readTorOnionUrl() {
        java.io.File hostname = new java.io.File(torHostnamePath());
        if (!hostname.isFile() || hostname.length() == 0) return null;
        try {
            // One short line; no streaming needed, unlike the log below.
            byte[] raw = new byte[(int) Math.min(hostname.length(), 256)];
            try (java.io.FileInputStream in = new java.io.FileInputStream(hostname)) {
                int read = in.read(raw);
                if (read <= 0) return null;
                String addr = new String(raw, 0, read,
                        java.nio.charset.StandardCharsets.UTF_8).trim();
                if (!ONION_V3.matcher(addr).matches()) return null;
                return "http://" + addr;
            }
        } catch (Exception e) {
            CameraDaemon.log("tunnelStatus: could not read tor hostname: " + e.getMessage());
            return null;
        }
    }

    /**
     * Whether tor's CURRENT run has reached "Bootstrapped 100%".
     *
     * <p>tor appends to one log across launches, so a success line from an earlier run sits
     * above the current run's "Bootstrapped 0% (starting)". Tracking the latest of the two
     * rather than merely searching for 100% is what stops a restart republishing the address
     * during the window when the service is not reachable — the exact class of cross-launch
     * log drift the tunnel implementation this replaces had to handle too.
     *
     * <p>Never loads the whole log into memory: the previous implementation's comment records
     * the 85 MB+ allocations that caused. On a log larger than {@link #TOR_LOG_TAIL_BYTES} it
     * reads only the tail, skipping the partial line the seek lands inside. tor logs at notice
     * level and is quiet once up, so the tail is where the current run is.
     *
     * <p>Package-private for {@code TunnelStatusCommandTest}.
     */
    static boolean isTorBootstrapped() {
        java.io.File log = new java.io.File(torLogPath());
        if (!log.isFile() || log.length() == 0) return false;
        try (java.io.RandomAccessFile raf = new java.io.RandomAccessFile(log, "r")) {
            long start = Math.max(0, raf.length() - TOR_LOG_TAIL_BYTES);
            raf.seek(start);
            if (start > 0) raf.readLine(); // drop the partial line the seek landed inside
            boolean bootstrapped = false;
            String line;
            while ((line = raf.readLine()) != null) {
                // Order matters: a run that restarts resets the verdict, and a run that
                // completes sets it. The last one wins.
                if (line.contains("Bootstrapped 0%")) {
                    bootstrapped = false;
                } else if (line.contains("Bootstrapped 100%")) {
                    bootstrapped = true;
                }
            }
            return bootstrapped;
        } catch (Exception e) {
            CameraDaemon.log("tunnelStatus: could not read tor log: " + e.getMessage());
            return false;
        }
    }

    /**
     * The section's current values, read through the same typed accessors the native
     * UI uses so the DEFAULTS for an absent key match exactly ({@code cameraVisible}/
     * {@code tripVisible} default true, {@code timingLogsEnabled} true,
     * {@code debugLogsEnabled} false). Reading the raw JSON object instead would hand
     * the caller an empty object on a fresh install and make every client re-derive
     * those defaults.
     */
    private static JSONObject publicConfigSection(String section) throws Exception {
        switch (section) {
            case "statusOverlay": {
                JSONObject cfg = net.bladewatch.app.config.UnifiedConfigManager.getStatusOverlay();
                return new JSONObject()
                        .put("cameraVisible", cfg.optBoolean("cameraVisible", true))
                        .put("tripVisible", cfg.optBoolean("tripVisible", true));
            }
            case "developerOptions":
                return new JSONObject()
                        .put("timingLogsEnabled",
                                net.bladewatch.app.config.UnifiedConfigManager.isTimingLogsEnabled())
                        .put("debugLogsEnabled",
                                net.bladewatch.app.config.UnifiedConfigManager.isDebugLogsEnabled());
            case "camera": {
                // BladeWatch-i2wv: read-only, and only the two fields the Diagnostics
                // camera tile actually renders — the same pair native's
                // DiagnosticsFragment.updateCameraTile() reads.
                //
                // Projected key by key rather than returned wholesale ON PURPOSE. The
                // real `camera` section also carries firmwareFingerprint, buildDisplay,
                // buildIncremental and productDevice — device-identifying strings that
                // have no business crossing this boundary to satisfy a status tile.
                JSONObject cfg = cameraConfigForTest != null
                        ? cameraConfigForTest
                        : net.bladewatch.app.config.UnifiedConfigManager.loadConfig()
                                .optJSONObject("camera");
                if (cfg == null) cfg = new JSONObject();
                return new JSONObject()
                        .put("probedCameraId", cfg.optInt("probedCameraId", -1))
                        .put("manualOverride", cfg.optBoolean("manualOverride", false));
            }
            default:
                // Unreachable: every caller checks the relevant gate first.
                return new JSONObject();
        }
    }

    /**
     * True if a daemon process named exactly {@code processName} is currently running.
     *
     * <p>Matches on <b>argv[0] only</b>, compared by basename and by exact equality —
     * never a substring of the whole command line. BladeWatch-xzhv: the previous
     * implementation shelled out to {@code pgrep -f "(^|[^_[:alnum:]])<name>"}, and
     * {@code -f} matches the FULL command line, so <i>any</i> process that merely
     * mentioned a daemon name reported that daemon as running. Observed on the head
     * unit: an {@code adb shell} one-liner that only wrote to
     * the tunnel's log made {@code tunnelStatus} answer
     * {@code running=true} with no tunnel anywhere — which defeats the whole point of
     * that command's liveness gate (it exists so a URL left in the log by a dead
     * session is never republished as a live tunnel).
     *
     * <p>argv[0] is the right discriminator because of how these processes are
     * launched, verified by reading {@code /proc/<pid>/cmdline} on the device:
     * <ul>
     *   <li>{@code app_process --nice-name=byd_cam_daemon …} overwrites argv[0] with
     *       the nice-name, so the live daemon's cmdline is literally
     *       {@code "byd_cam_daemon"} (NUL/space padded) — while the {@code sh -c}
     *       that launched it keeps its own argv[0] of {@code "sh"}. Exactly the
     *       distinction the old pattern could not draw.</li>
     *   <li>tor is exec'd by path, so its argv[0] is
     *       {@code /data/local/tmp/bladewatch_tor} —
     *       hence the basename comparison rather than raw equality.</li>
     * </ul>
     *
     * <p>Exact equality also preserves the property the old leading-boundary group
     * existed for: {@code sentry_daemon} does not match {@code acc_sentry_daemon}.
     *
     * <p>Reading procfs directly replaces a {@code ProcessBuilder} fork per daemon per
     * poll, which removes the file-descriptor leak the previous implementation had to
     * guard against by hand. This process runs as shell UID and can read other
     * processes' {@code cmdline} (confirmed on device, same UID the daemons run as).
     */
    boolean isProcessRunning(String processName) {
        return !findPidsByProcessName(processName).isEmpty();
    }

    /**
     * Every PID whose argv[0] basename is exactly {@code processName} — see
     * {@link #isProcessRunning} for why argv[0] and not the whole command line.
     * A daemon can legitimately have more than one PID (a forked child keeps the
     * parent's argv), so this returns all of them rather than the first.
     */
    static java.util.List<Integer> findPidsByProcessName(String processName) {
        java.util.List<Integer> pids = new java.util.ArrayList<>();
        if (processName == null || processName.isEmpty()) return pids;
        java.io.File[] entries = procRoot().listFiles();
        if (entries == null) return pids;
        for (java.io.File entry : entries) {
            if (!isPid(entry.getName())) continue;
            String argv0 = readArgv0(new java.io.File(entry, "cmdline"));
            if (argv0 == null) continue;
            if (processName.equals(basename(argv0))) {
                try {
                    pids.add(Integer.parseInt(entry.getName()));
                } catch (NumberFormatException ignored) {
                    // isPid() already screened this; belt and braces.
                }
            }
        }
        return pids;
    }

    // ponytail: test seam — null = the real /proc; non-null = a fake tree a unit test
    // can populate, which is what makes the matching rules above testable off-device.
    static java.io.File procRootForTest = null;

    private static java.io.File procRoot() {
        return procRootForTest != null ? procRootForTest : new java.io.File("/proc");
    }

    private static boolean isPid(String name) {
        if (name.isEmpty()) return false;
        for (int i = 0; i < name.length(); i++) {
            if (name.charAt(i) < '0' || name.charAt(i) > '9') return false;
        }
        return true;
    }

    /**
     * The first NUL-separated element of {@code /proc/<pid>/cmdline}, or null when the
     * process is gone or unreadable (both routine: PIDs vanish mid-scan, and kernel
     * threads have an empty cmdline).
     *
     * <p>Trailing spaces are stripped because {@code app_process} pads the argv[0]
     * region — the live daemon's cmdline is the nice-name followed by filler, not a
     * bare string.
     */
    private static String readArgv0(java.io.File cmdline) {
        try (java.io.InputStream in = new java.io.FileInputStream(cmdline)) {
            // argv[0] alone; no need to read a whole command line to compare one token.
            byte[] buf = new byte[256];
            int n = in.read(buf);
            if (n <= 0) return null;
            int end = 0;
            while (end < n && buf[end] != 0) end++;
            String first = new String(buf, 0, end, java.nio.charset.StandardCharsets.UTF_8);
            int trimEnd = first.length();
            while (trimEnd > 0 && first.charAt(trimEnd - 1) == ' ') trimEnd--;
            String trimmed = first.substring(0, trimEnd);
            return trimmed.isEmpty() ? null : trimmed;
        } catch (Exception e) {
            // A PID that exited between listFiles() and the open is the common case.
            return null;
        }
    }

    private static String basename(String path) {
        int slash = path.lastIndexOf('/');
        return slash < 0 ? path : path.substring(slash + 1);
    }

    // ==================== STATUS HELPERS ====================
    
    public static JSONArray getRecordingCameras() {
        JSONArray arr = new JSONArray();
        // GPU pipeline: Only show as recording if in recording mode AND actually recording
        net.bladewatch.app.surveillance.GpuSurveillancePipeline pipeline = CameraDaemon.getGpuPipeline();
        if (pipeline != null && pipeline.isRecordingMode() && pipeline.isRecording()) {
            // Mosaic recording = all 4 cameras
            arr.put(1);
            arr.put(2);
            arr.put(3);
            arr.put(4);
        }
        return arr;
    }

    public static JSONArray getViewOnlyCameras() {
        JSONArray arr = new JSONArray();
        // GPU pipeline: Show as viewing if running but not in recording mode
        net.bladewatch.app.surveillance.GpuSurveillancePipeline pipeline = CameraDaemon.getGpuPipeline();
        if (pipeline != null && pipeline.isRunning() && !pipeline.isRecordingMode()) {
            // Viewing all 4 cameras
            arr.put(1);
            arr.put(2);
            arr.put(3);
            arr.put(4);
        }
        return arr;
    }

    public static JSONArray getActiveCameras() {
        JSONArray arr = new JSONArray();
        // GPU pipeline: all 4 cameras active together
        if (CameraDaemon.isSurveillanceActive()) {
            arr.put(1);
            arr.put(2);
            arr.put(3);
            arr.put(4);
        }
        return arr;
    }

    public static JSONArray getAvailableCameras() {
        JSONArray arr = new JSONArray();
        for (int i = 1; i <= 4; i++) {
            arr.put(i);
        }
        return arr;
    }
}
