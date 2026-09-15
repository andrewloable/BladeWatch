package net.bladewatch.app.server;

import android.content.res.AssetManager;
import android.util.Base64;

import net.bladewatch.app.auth.AuthManager;
import net.bladewatch.app.config.UnifiedConfigManager;
import net.bladewatch.app.daemon.CameraDaemon;
import net.bladewatch.app.monitor.AccMonitor;
import net.bladewatch.app.monitor.BatteryMonitor;
import net.bladewatch.app.server.connect.ConnectDispatcher;
import net.bladewatch.app.surveillance.GpuPipelineConfig;
import net.bladewatch.app.surveillance.HardwareEventRecorderGpu;

import org.json.JSONObject;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * HTTP Server - serves web UI and WebSocket H.264 streaming.
 * Listens on 127.0.0.1:8080 by default; LAN binding is an explicit unsafe mode.
 * 
 * Single-port WebSocket: /ws endpoint upgrades to WebSocket for H.264 streaming
 * (single port lets the tunnel expose both HTTP and WebSocket through one onion port).
 * 
 * API handlers are modularized into separate classes:
 * - RecordingsApiHandler: /api/recordings, /video/*
 * - SurveillanceApiHandler: /api/surveillance/*
 * - StreamingApiHandler: /api/stream/*
 * - GpsApiHandler: /api/gps/*
 * - QualitySettingsApiHandler: /api/settings/quality
 */
public class HttpServer {

    private static final String WEB_ROOT = "/data/local/tmp/web";
    private final int port;
    private ServerSocket serverSocket;
    private volatile boolean running = true;

    // Thread Pool to prevent server clogging (max 32 concurrent connections)
    /**
     * Request-serving pool. Every worker here is bounded by the 15 s socket timeout set in
     * {@code handleClient}, so no single request can hold one indefinitely.
     */
    private final ExecutorService threadPool = Executors.newFixedThreadPool(32);

    /**
     * Long-lived H.264 WebSocket streams, deliberately SEPARATE from {@link #threadPool}
     * (BladeWatch-sxzg).
     *
     * <p>The in-car Flutter UI speaks ConnectRPC to this very server on 127.0.0.1:8080, so
     * it queues on the same pool as every remote client arriving through the onion service.
     * {@code streamH264ToWebSocket} sets {@code setSoTimeout(0)} and then blocks for the
     * whole viewing session — so on the request pool, each viewer permanently removed a
     * worker that the driver's own screen needed. Ordinary requests are bounded by their
     * timeout; a stream is bounded by nothing.
     *
     * <p>Measured on the head unit 2026-09-15, with the tunnel up and a remote viewer: the
     * Flutter app rendered ZERO frames in ten seconds while 44% of frames were janky at a
     * 600 ms 99th percentile, on a machine that was 497% of 800% idle. Not a render loop and
     * not a CPU shortage — a UI thread waiting on RPCs stuck behind remote traffic.
     *
     * <p>Cached rather than fixed: viewers are few and sporadic, threads are reclaimed after
     * 60 s idle, and a hard cap here would mean refusing a legitimate viewer rather than
     * merely slowing one. The cap that matters is on the REQUEST pool, which this protects.
     */
    private final ExecutorService streamPool = Executors.newCachedThreadPool(r -> {
        Thread t = new Thread(r, "http-stream");
        t.setDaemon(true);
        return t;
    });

    private final ConnectDispatcher connectDispatcher = new ConnectDispatcher();

    public HttpServer(int port) {
        this.port = port;
    }

    /** Expose the ConnectDispatcher so service impls can register themselves. */
    public ConnectDispatcher getConnectDispatcher() {
        return connectDispatcher;
    }

    /**
     * Extracts web assets from APK to filesystem.
     * Call this during initialization with a valid AssetManager.
     */
    public static void extractWebAssets(AssetManager assetManager) {
        if (assetManager == null) {
            CameraDaemon.log("AssetManager is null, skipping web asset extraction");
            return;
        }
        
        try {
            File webRoot = new File(WEB_ROOT);
            
            // Always delete and recreate to ensure fresh files on app update
            if (webRoot.exists()) {
                deleteRecursive(webRoot);
                CameraDaemon.log("Deleted existing web assets for fresh extraction");
            }
            webRoot.mkdirs();
            
            // Extract web/local and web/shared directories
            extractAssetDir(assetManager, "web/local", new File(WEB_ROOT, "local"));
            extractAssetDir(assetManager, "web/shared", new File(WEB_ROOT, "shared"));
            // Extract Angular SPA build output.
            extractAssetDir(assetManager, "web/angular", new File(WEB_ROOT, "angular"));
            // Extract three.js hero page (vehicle 3D hero, served at /hero/).
            extractAssetDir(assetManager, "web/hero", new File(WEB_ROOT, "hero"));
            // Extract i18n catalogs (one JSON per supported locale).
            // The web/i18n directory is created by the NLLB translation pipeline
            // — at minimum web/i18n/en.json must exist for the runtime to load.
            extractAssetDir(assetManager, "web/i18n", new File(WEB_ROOT, "i18n"));
            // Extract server-side i18n catalogs (Messages.java lookup source).
            // Kept distinct from web/i18n so the HTTP /i18n/ route doesn't accidentally
            // expose internal error keys, and the two catalogs can diverge if needed.
            extractAssetDir(assetManager, "server-i18n", new File(WEB_ROOT, "server-i18n"));

            // Extract overlay icons for telemetry overlay
            extractAssetDir(assetManager, "overlay", new File("/data/local/tmp/overlay"));

            CameraDaemon.log("Web assets extracted to " + WEB_ROOT);
        } catch (Exception e) {
            CameraDaemon.log("Failed to extract web assets: " + e.getMessage());
        }
    }
    
    private static void deleteRecursive(File file) {
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursive(child);
                }
            }
        }
        file.delete();
    }
    
    private static void extractAssetDir(AssetManager assetManager, String assetPath, File destDir) throws Exception {
        if (!destDir.exists()) {
            destDir.mkdirs();
        }
        
        String[] files = assetManager.list(assetPath);
        if (files == null || files.length == 0) {
            CameraDaemon.log("No files found in assets/" + assetPath);
            return;
        }
        
        for (String fileName : files) {
            String assetFilePath = assetPath + "/" + fileName;
            File destFile = new File(destDir, fileName);
            
            String[] subFiles = assetManager.list(assetFilePath);
            if (subFiles != null && subFiles.length > 0) {
                extractAssetDir(assetManager, assetFilePath, destFile);
            } else {
                try (InputStream in = assetManager.open(assetFilePath);
                     FileOutputStream out = new FileOutputStream(destFile)) {
                    byte[] buffer = new byte[4096];
                    int read;
                    while ((read = in.read(buffer)) != -1) {
                        out.write(buffer, 0, read);
                    }
                }
                CameraDaemon.log("Extracted: " + assetFilePath + " -> " + destFile.getAbsolutePath());
            }
        }
    }

    public void start() {
        CameraDaemon.log("HTTP server starting on port " + port);
        
        // Initialize auth system
        AuthManager.initialize();
        CameraDaemon.log("Auth system initialized");
        
        while (running && CameraDaemon.isRunning()) {
            try {
                if (serverSocket != null && !serverSocket.isClosed()) {
                    try { serverSocket.close(); } catch (Exception e) { CameraDaemon.log("WARN: HTTP serverSocket.close() failed: " + e.getMessage()); }
                }
                
                String bindHost = UnifiedConfigManager.isLanHttpEnabled() ? "0.0.0.0" : "127.0.0.1";
                serverSocket = new ServerSocket(port, 10, InetAddress.getByName(bindHost));
                serverSocket.setReuseAddress(true);
                CameraDaemon.log("HTTP server listening on " + bindHost + ":" + port);

                while (running && CameraDaemon.isRunning() && !serverSocket.isClosed()) {
                    try {
                        Socket client = serverSocket.accept();
                        CameraDaemon.log("HTTP client: " + client.getRemoteSocketAddress());
                        threadPool.execute(() -> handleClient(client));
                    } catch (java.net.SocketException e) {
                        if (running) {
                            CameraDaemon.log("WARN: HTTP socket error: " + e.getMessage());
                        }
                        break;
                    }
                }
                
                if (running) {
                    CameraDaemon.log("HTTP server restarting...");
                    Thread.sleep(2000);
                }
                
            } catch (java.net.BindException e) {
                CameraDaemon.log("ERROR: HTTP port " + port + " in use, retrying...");
                try { Thread.sleep(5000); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); break; }
            } catch (Exception e) {
                CameraDaemon.log("ERROR: HTTP server error: " + e.getMessage());
                if (running) {
                    try { Thread.sleep(3000); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); break; }
                }
            }
        }
        
        CameraDaemon.log("HTTP server stopped");
    }

    public void stop() {
        running = false;
        try {
            if (serverSocket != null) serverSocket.close();
        } catch (Exception e) { CameraDaemon.log("WARN: HTTP stop() serverSocket.close() failed: " + e.getMessage()); }
        threadPool.shutdownNow();
        streamPool.shutdownNow();
    }

    /**
     * Read timeout, applied to the first request and to the idle wait between keep-alive
     * requests (BladeWatch-67h8). Long enough not to punish a slow Tor round trip, short
     * enough that an abandoned socket is reclaimed rather than held by a daemon that runs
     * for weeks.
     */
    private static final int SOCKET_TIMEOUT_MS = 15000;

    /**
     * Turn a Latin-1-read request body back into text (BladeWatch-ou7y).
     *
     * <p>The request reader decodes as ISO-8859-1 so that one char is exactly one byte and
     * {@code Content-Length} — which counts bytes — can be satisfied exactly. That makes
     * {@code chars} a byte buffer wearing a char[] costume: each element holds one byte in
     * its low 8 bits. Narrowing them back to bytes and decoding as UTF-8 recovers the text
     * the client actually sent.
     *
     * <p>Package-private so {@code RequestBodyDecodingTest} can exercise it directly; the
     * surrounding socket plumbing is not unit-testable.
     */
    static String decodeRequestBody(char[] chars, int length) {
        byte[] bytes = new byte[length];
        for (int i = 0; i < length; i++) {
            bytes[i] = (byte) chars[i];
        }
        return new String(bytes, java.nio.charset.StandardCharsets.UTF_8);
    }

    private void handleClient(Socket client) {
        // BladeWatch-sxzg: set when the socket's ownership passes to the streaming pool.
        // The finally below MUST NOT close it then — the stream is still using it, and
        // closing here would tear down every live view the moment it started.
        boolean socketHandedOff = false;
        // True while waiting for a request line, false once one is being served. Lets the
        // SocketTimeoutException handler tell a normal keep-alive idle expiry (the peer
        // stopped asking) from a read that timed out MID-REQUEST, which is a real fault and
        // must not be swallowed.
        boolean betweenRequests = true;
        try {
            client.setSoTimeout(SOCKET_TIMEOUT_MS);
            // BladeWatch-ou7y: ISO-8859-1, deliberately, NOT the platform default.
            // Content-Length counts BYTES but reader.read(char[]) returns CHARACTERS, and
            // under a UTF-8 decoder those differ for any non-ASCII body — the body loop
            // then waits for characters that will never arrive and the request times out.
            // Latin-1 maps bytes 0-255 bijectively onto chars 0-255, so one char IS one
            // byte and the count is exact. decodeRequestBody() converts back to real text.
            // Safe for the rest of the request: request lines and the header values parsed
            // below are ASCII (a non-ASCII path arrives percent-encoded, which is ASCII).
            BufferedReader reader = new BufferedReader(new InputStreamReader(
                    client.getInputStream(), java.nio.charset.StandardCharsets.ISO_8859_1));
            KeepAliveStream out = new KeepAliveStream(new BufferedOutputStream(client.getOutputStream()));

            // BladeWatch-67h8: one socket may now carry several requests. Every existing
            // "client.close(); return;" below still means "close and stop", which is
            // still correct — they are the error paths. Only the SUCCESS path loops.
            while (true) {

            // Re-arm per iteration. A previous request on this connection may have raised
            // the timeout (the vehicle-control path below sets 60s), and under keep-alive
            // that would otherwise persist for every later request and hold an idle socket
            // four times longer than intended.
            client.setSoTimeout(SOCKET_TIMEOUT_MS);
            betweenRequests = true;

            String requestLine = reader.readLine();
            if (requestLine == null) {
                client.close();
                return;
            }
            
            betweenRequests = false;
            CameraDaemon.log("HTTP: " + requestLine);
            
            // Parse headers
            String line;
            int contentLength = 0;
            String websocketKey = null;
            String upgradeHeader = null;
            String rangeHeader = null;
            // Conditional GET — if the client (Chrome WebView's HTTP cache)
            // sends If-None-Match matching our ETag, we return 304 instead of
            // re-streaming the whole file. Used for cached event recordings.
            String ifNoneMatchHeader = null;
            String cookieHeader = null;
            String authHeader = null;
            String contentTypeHeader = null;
            String connectVersionHeader = null;
            // uy93.5: second factor for /api/vehicle/* POST from non-loopback.
            String vehicleActionTokenHeader = null;
            // Reverse-proxy fingerprints — used by AuthMiddleware to disable
            // the loopback safety net when a tunnel relayed the request.
            // A reverse proxy injects X-Forwarded-*. NOTE: the Tor onion service does
            // NOT — it opens a plain TCP connection to 127.0.0.1:8080 — so these headers
            // are no longer how remote traffic is recognised. AuthMiddleware also checks
            // whether the tunnel process is up; see its Tier 2 comment.
            boolean hasTunnelHeaders = false;
            String forwardedFor = null;
            String hostHeader = null;
            // Kept for any reverse proxy that rewrites Host: to the backend URL
            // (localhost:8080) and stashes the original public hostname in
            // X-Forwarded-Host. Captured here so isPwaOrigin can match it. Tor sends
            // neither header — an onion client's Host: is already the .onion address.
            String forwardedHostHeader = null;

            // BladeWatch-67h8: the client's own keep-alive intent.
            String connectionRequestHeader = null;

            while ((line = reader.readLine()) != null && !line.isEmpty()) {
                String lower = line.toLowerCase();
                if (lower.startsWith("connection:")) {
                    connectionRequestHeader = line.substring(11).trim().toLowerCase();
                }
                if (lower.startsWith("content-length:")) {
                    contentLength = Integer.parseInt(line.substring(15).trim());
                } else if (lower.startsWith("sec-websocket-key:")) {
                    websocketKey = line.substring(18).trim();
                } else if (lower.startsWith("upgrade:")) {
                    upgradeHeader = line.substring(8).trim();
                } else if (lower.startsWith("range:")) {
                    rangeHeader = line.substring(6).trim();
                } else if (lower.startsWith("if-none-match:")) {
                    ifNoneMatchHeader = line.substring(14).trim();
                } else if (lower.startsWith("cookie:")) {
                    cookieHeader = line.substring(7).trim();
                } else if (lower.startsWith("authorization:")) {
                    authHeader = line.substring(14).trim();
                } else if (lower.startsWith("content-type:")) {
                    contentTypeHeader = line.substring(13).trim();
                } else if (lower.startsWith("connect-protocol-version:")) {
                    connectVersionHeader = line.substring(25).trim();
                } else if (lower.startsWith("x-vehicle-action-token:")) {
                    vehicleActionTokenHeader = line.substring(23).trim();
                } else if (lower.startsWith("accept-language:")) {
                    // First-touch locale hint. Only used if the user has never
                    // explicitly chosen via the picker (LocaleManager file empty).
                    String al = line.substring(16).trim();
                    if (!al.isEmpty()) {
                        try { LocaleManager.fromAcceptLanguage(al); } catch (Exception e) { CameraDaemon.log("DEBUG: Accept-Language probe failed: " + e.getMessage()); }
                        // Note: we don't auto-persist Accept-Language; the picker
                        // is the only thing that writes the state file. JS-side
                        // navigator.language detection feeds the picker.
                    }
                } else if (lower.startsWith("host:")) {
                    hostHeader = line.substring(5).trim();
                } else if (lower.startsWith("x-forwarded-for:")) {
                    hasTunnelHeaders = true;
                    forwardedFor = line.substring(16).trim();
                } else if (lower.startsWith("x-forwarded-host:")) {
                    hasTunnelHeaders = true;
                    // Header value can be a comma list ("a.example, b.example")
                    // when chained through multiple proxies. The leftmost entry
                    // is the original client-facing host.
                    String v = line.substring(17).trim();
                    int comma = v.indexOf(',');
                    forwardedHostHeader = (comma > 0 ? v.substring(0, comma) : v).trim();
                } else if (lower.startsWith("x-forwarded-proto:")
                        || lower.startsWith("x-real-ip:")
                        || lower.startsWith("forwarded:")
                        || lower.startsWith("cf-connecting-ip:")
                        || lower.startsWith("cf-ray:")
                        || lower.startsWith("cf-visitor:")) {
                    hasTunnelHeaders = true;
                }
            }
            
            // Read POST body if present
            // SOTA: Loop read for large payloads (e.g., base64 image uploads)
            // BufferedReader.read() may return fewer chars than requested in a single call
            String body = null;
            if (contentLength > 0) {
                char[] bodyChars = new char[contentLength];
                int totalRead = 0;
                while (totalRead < contentLength) {
                    int read = reader.read(bodyChars, totalRead, contentLength - totalRead);
                    if (read == -1) break;  // EOF
                    totalRead += read;
                }
                body = decodeRequestBody(bodyChars, totalRead);
            }

            String[] parts = requestLine.split(" ");
            if (parts.length < 2) {
                // This runs BEFORE the keep-alive decision below, so on a REUSED connection
                // `out` still carries the previous request's "keep-alive". We are about to
                // close, so say so.
                out.setKeepAlive(false);
                HttpResponse.sendError(out, 400, "Bad Request");
                client.close();
                return;
            }

            String method = parts[0];
            String path = parts[1];

            // BladeWatch-67h8: decide BEFORE dispatch, because the response writers read
            // this back through HttpResponse.connectionHeader(out) as they emit headers.
            // HTTP/1.1 defaults to persistent; HTTP/1.0 requires an explicit opt-in.
            String httpVersion = parts.length > 2 ? parts[2].trim() : "HTTP/1.0";
            boolean clientWantsClose = connectionRequestHeader != null
                    && connectionRequestHeader.contains("close");
            boolean clientWantsKeepAlive = connectionRequestHeader != null
                    && connectionRequestHeader.contains("keep-alive");
            boolean keepAlive = !clientWantsClose
                    && ("HTTP/1.1".equalsIgnoreCase(httpVersion) || clientWantsKeepAlive);
            out.setKeepAlive(keepAlive);
            
            // Extend timeout for slow vehicle control API calls.
            if (path.startsWith("/api/vehicle/lock") ||
                path.startsWith("/api/vehicle/unlock") || path.startsWith("/api/vehicle/flash")) {
                client.setSoTimeout(60000);
            }
            
            // WebSocket upgrade on /ws path (check auth first for non-public paths).
            // Match /ws and /ws?... (query params allow JWT-as-?token= since browser
            // WebSocket clients can't set arbitrary headers — cookies may be dropped
            // through tunnels' SameSite policies).
            String wsPathOnly = path.contains("?") ? path.substring(0, path.indexOf("?")) : path;
            if (wsPathOnly.equals("/ws") && websocketKey != null && "websocket".equalsIgnoreCase(upgradeHeader)) {
                // Promote ?token= query param into a synthetic Authorization header
                // so AuthMiddleware's existing Bearer-token path handles it.
                String wsAuthHeader = authHeader;
                if (wsAuthHeader == null && path.contains("?")) {
                    String query = path.substring(path.indexOf("?") + 1);
                    for (String param : query.split("&")) {
                        int eq = param.indexOf('=');
                        if (eq > 0 && "token".equals(param.substring(0, eq))) {
                            wsAuthHeader = "Bearer " + java.net.URLDecoder.decode(
                                param.substring(eq + 1), "UTF-8");
                            break;
                        }
                    }
                }
                out.setKeepAlive(false);   // see the auth gate below
                boolean wsAuthorized = AuthMiddleware.checkAuth(wsPathOnly, cookieHeader,
                        wsAuthHeader, out, client.getRemoteSocketAddress(), hasTunnelHeaders);
                out.setKeepAlive(keepAlive);
                if (!wsAuthorized) {
                    client.close();
                    return;
                }
                socketHandedOff = handleWebSocketUpgrade(client, websocketKey);
                return;
            }

            // Route auth endpoints (all public). The /auth/token endpoint is
            // rate-limited by socket address. We never key on X-Forwarded-For
            // because it is client-controlled — rotating it defeats per-IP limits.
            if (path.startsWith("/auth/")) {
                String identity = String.valueOf(client.getRemoteSocketAddress());
                AuthApiHandler.handle(method, path, body, out, identity, hasTunnelHeaders);
                out.flush();
                if (!keepAlive) break;
                continue;
            }
            
            // Serve login page (public) - strip query string for matching
            String pathOnly = path.contains("?") ? path.substring(0, path.indexOf("?")) : path;
            if (pathOnly.equals("/login") || pathOnly.equals("/login.html")) {
                if (!serveStaticFile(out, "local/login.html")) {
                    HttpResponse.sendError(out, 404, "login.html not found");
                }
                out.flush();
                if (!keepAlive) break;
                continue;
            }
            
            // Handle CORS preflight (OPTIONS) requests for cross-origin webapp access.
            // Browsers send OPTIONS before POST/PUT/DELETE with Content-Type: application/json.
            // The in-app WebView is same-origin so it skips this, but the external webapp needs it.
            // Must be handled BEFORE auth check — preflight requests don't carry cookies/tokens.
            if (method.equals("OPTIONS")) {
                HttpResponse.sendCorsPreflightResponse(out);
                out.flush();
                if (!keepAlive) break;
                continue;
            }
            
            // Check authentication for all other paths.
            // BladeWatch-67h8: checkAuth writes its own 401/redirect when it fails, and
            // that response is followed by a close — so it must not claim keep-alive.
            // Announce close first, restore the request's intent if auth passed.
            out.setKeepAlive(false);
            boolean authorized = AuthMiddleware.checkAuth(path, cookieHeader, authHeader, out,
                    client.getRemoteSocketAddress(), hasTunnelHeaders);
            out.setKeepAlive(keepAlive);
            if (!authorized) {
                client.close();
                return;
            }

            // uy93.5: vehicle actuation POST from non-loopback requires a short-lived
            // action token (X-Vehicle-Action-Token) in addition to the session JWT.
            // The WebView always connects from loopback (127.0.0.1 / ::1) and is exempt.
            // The /api/vehicle/action-token issue endpoint itself is also exempt.
            String vehicleActionPathOnly = path.contains("?") ? path.substring(0, path.indexOf("?")) : path;
            if (method.equals("POST")
                    && vehicleActionPathOnly.startsWith("/api/vehicle/")
                    && !vehicleActionPathOnly.equals("/api/vehicle/action-token")
                    && !client.getInetAddress().isLoopbackAddress()) {
                net.bladewatch.app.auth.AuthManager.AuthState actionState = net.bladewatch.app.auth.AuthManager.getState();
                if (actionState == null || !VehicleActionToken.validate(vehicleActionTokenHeader, actionState.deviceSecret)) {
                    out.setKeepAlive(false);   // rejected and closing — do not advertise keep-alive
                    HttpResponse.sendJsonForbidden(out, "Vehicle action token required — use GET /api/vehicle/action-token first");
                    client.close();
                    return;
                }
            }

            // Derive client identity for Connect rate limiting. Always use the
            // real TCP peer — X-Forwarded-For is client-controlled and must not
            // be trusted for rate-limit keying.
            String connectClientIdentity = String.valueOf(client.getRemoteSocketAddress());

            // Route to modular handlers first
            if (routeToHandlers(method, path, body, rangeHeader, ifNoneMatchHeader,
                    contentTypeHeader, connectVersionHeader, connectClientIdentity, out)) {
                // Handled by a modular handler
            }
            // Angular SPA static assets (JS/CSS chunks produced by Vite build).
            else if (path.startsWith("/assets/") || path.startsWith("/vendor/")) {
                String filePath = path.substring(1); // strip leading slash
                int q = filePath.indexOf('?');
                if (q >= 0) filePath = filePath.substring(0, q);
                if (!serveStaticFile(out, "angular/" + filePath)) {
                    HttpResponse.sendError(out, 404, "Not Found: " + path);
                }
            // PWA manifest + service worker (still used by installed PWA instances).
            } else if (path.startsWith("/manifest.json")) {
                if (!serveStaticFile(out, "local/manifest.json")) {
                    HttpResponse.sendError(out, 404, "manifest.json not found");
                }
            } else if (path.startsWith("/sw.js")) {
                if (!serveStaticFile(out, "local/sw.js")) {
                    HttpResponse.sendError(out, 404, "sw.js not found");
                }
            } else if (path.equals("/credits.json")) {
                if (!serveStaticFile(out, "local/credits.json")) {
                    HttpResponse.sendError(out, 404, "credits.json not found");
                }
            } else if (path.equals("/api/i18n/lang")) {
                // GET → current locale; POST {"lang":"zh-CN"} → persist + echo
                if (method.equals("GET")) {
                    JSONObject resp = new JSONObject();
                    resp.put("lang", LocaleManager.get());
                    JSONObject supported = new JSONObject();
                    for (String s : LocaleManager.SUPPORTED) supported.put(s, true);
                    resp.put("supported", supported);
                    HttpResponse.sendJson(out, resp.toString());
                } else if (method.equals("POST")) {
                    String want;
                    try {
                        want = new JSONObject(body).optString("lang", "");
                    } catch (Exception e) { CameraDaemon.log("DEBUG: locale POST body parse failed: " + e.getMessage()); want = ""; }
                    String resolved = LocaleManager.set(want);
                    HttpResponse.sendJson(out, "{\"lang\":\"" + resolved + "\"}");
                } else {
                    HttpResponse.sendError(out, 405, "Method Not Allowed");
                }
            } else if (path.startsWith("/i18n/")) {
                // Catalog JSON: /i18n/en.json, /i18n/zh-CN.json, …
                // 404s on unsupported tags so the runtime falls back to en.
                // Strip ?query / #fragment so a cache-busting suffix like
                // ?v=<build> still resolves to the file on disk.
                String tag = path.substring(6);
                int q = tag.indexOf('?');
                if (q >= 0) tag = tag.substring(0, q);
                int hsh = tag.indexOf('#');
                if (hsh >= 0) tag = tag.substring(0, hsh);
                int dot = tag.lastIndexOf('.');
                String base = dot > 0 ? tag.substring(0, dot) : tag;
                if (!LocaleManager.isSupported(base)) {
                    HttpResponse.sendError(out, 404, "Unknown locale");
                } else if (!serveStaticFile(out, "i18n/" + tag)) {
                    HttpResponse.sendError(out, 404, "Catalog missing: " + tag);
                }
            } else if (path.startsWith("/shared/") || path.startsWith("/local/")) {
                // Strip ?query and #fragment so cache-busting versions like
                // ?v=12 resolve to the same file on disk.
                String filePath = path.substring(1);
                int q = filePath.indexOf('?');
                if (q >= 0) filePath = filePath.substring(0, q);
                int h = filePath.indexOf('#');
                if (h >= 0) filePath = filePath.substring(0, h);
                if (!serveStaticFile(out, filePath)) {
                    HttpResponse.sendError(out, 404, "Not Found: " + path);
                }
            }
            // Core camera APIs (kept inline for simplicity)
            else if (path.equals("/status")) {
                sendStatus(out);
            } else if (path.startsWith("/api/start/")) {
                int camId = Integer.parseInt(path.substring(11));
                CameraDaemon.startCamera(camId, true, false);
                HttpResponse.sendJson(out, "{\"status\":\"ok\",\"action\":\"start\",\"camera\":" + camId + "}");
            } else if (path.startsWith("/api/view/")) {
                int camId = Integer.parseInt(path.substring(10));
                CameraDaemon.startCamera(camId, true, true);
                HttpResponse.sendJson(out, "{\"status\":\"ok\",\"action\":\"view\",\"camera\":" + camId + "}");
            } else if (path.startsWith("/api/stop/")) {
                int camId = Integer.parseInt(path.substring(10));
                CameraDaemon.stopCamera(camId);
                HttpResponse.sendJson(out, "{\"status\":\"ok\",\"action\":\"stop\",\"camera\":" + camId + "}");
            } else if (path.equals("/api/stopall")) {
                CameraDaemon.stopAllCameras();
                HttpResponse.sendJson(out, "{\"status\":\"ok\",\"action\":\"stopall\"}");
            } else if (path.equals("/api/recording/mode")) {
                // Get/Set recording mode
                if (method.equals("GET")) {
                    String currentMode = CameraDaemon.getRecordingMode();
                    HttpResponse.sendJson(out, "{\"status\":\"ok\",\"mode\":\"" + currentMode + "\"}");
                } else if (method.equals("POST")) {
                    JSONObject json = new JSONObject(body);
                    String mode = json.optString("mode", "");
                    if (!mode.isEmpty()) {
                        CameraDaemon.setRecordingMode(mode);
                        HttpResponse.sendJson(out, "{\"status\":\"ok\",\"mode\":\"" + mode + "\"}");
                    } else {
                        HttpResponse.sendJson(out, "{\"status\":\"error\",\"message\":\"No mode specified\"}");
                    }
                } else {
                    HttpResponse.sendError(out, 405, "Method Not Allowed");
                }
            } else if (path.startsWith("/h264/")) {
                // Deprecated HTTP streaming
                JSONObject response = new JSONObject();
                response.put("error", "HTTP streaming deprecated. Use WebSocket on port 8887");
                response.put("wsUrl", "ws://" + client.getLocalAddress().getHostAddress() + ":8887");
                HttpResponse.sendJson(out, response.toString());
            } else if (path.startsWith("/view/")) {
                // Legacy view page - redirect
                HttpResponse.sendHtml(out, "<html><head><meta http-equiv='refresh' content='0;url=/'></head></html>");
            } else if (path.startsWith("/hero/")) {
                // Three.js vehicle hero page — served directly, NOT caught by the SPA
                // fallback. hero.html references ../shared/vendor/ (already served at /shared/).
                String filePath = path.substring(1);
                int q = filePath.indexOf('?');
                if (q >= 0) filePath = filePath.substring(0, q);
                if (!serveStaticFile(out, filePath)) {
                    HttpResponse.sendError(out, 404, "Not Found: " + path);
                }
            } else if (path.equals("/favicon.ico") || path.equals("/favicon.png")
                    || path.equals("/favicon-32x32.png") || path.equals("/favicon-16x16.png")
                    || path.equals("/apple-touch-icon.png")) {
                // Favicon / PWA icon files — must be served as files, not caught by the
                // SPA fallback below. iOS fetches apple-touch-icon without cookies so
                // these paths are also whitelisted in AuthMiddleware.PUBLIC_PATHS.
                String filename = path.substring(1);
                if (!serveStaticFile(out, "angular/" + filename)) {
                    HttpResponse.sendError(out, 404, "Not Found: " + path);
                }
            } else {
                // Angular SPA fallback — serve index.html for all unrecognised paths so
                // the Angular router can handle the route client-side.
                if (!serveStaticFile(out, "angular/index.html")) {
                    HttpResponse.sendError(out, 404, "Not Found");
                }
            }

            // ---- BladeWatch-67h8: one request served; decide whether to read another ----
            // The flush is load-bearing. Previously the close in `finally` flushed the
            // BufferedOutputStream for any handler that forgot to; holding the socket open
            // removes that safety net, and an unflushed response is a client that hangs.
            out.flush();
            if (!keepAlive) break;
            }  // end of the per-request loop

        } catch (java.net.SocketTimeoutException e) {
            // Between requests this is ordinary keep-alive idle expiry — the peer simply
            // stopped asking — and logging it would make every reused connection an error.
            // MID-REQUEST it is a genuine fault (a truncated body, a client that stalled)
            // and swallowing it would hide the one case worth seeing. Note that reading a
            // body whose Content-Length counts BYTES with a char-oriented BufferedReader
            // times out here on any non-ASCII body; that predates keep-alive, but this is
            // where it now surfaces, so it must stay visible.
            if (!betweenRequests) {
                CameraDaemon.log("HTTP error: read timed out mid-request: " + e.getMessage());
            }
        } catch (Exception e) {
            CameraDaemon.log("HTTP error: " + e.getMessage());
        } finally {
            if (!socketHandedOff) {
                try { client.close(); } catch (Exception e) { CameraDaemon.log("WARN: HTTP client.close() failed: " + e.getMessage()); }
            }
        }
    }

    /**
     * Routes requests to modular API handlers.
     * @return true if handled by a handler
     */
    private boolean routeToHandlers(String method, String path, String body, String rangeHeader,
                                     String ifNoneMatchHeader, String contentTypeHeader,
                                     String connectVersionHeader, String clientIdentity,
                                     OutputStream out) throws Exception {
        // Connect protocol — routes /bladewatch.v1.ServiceName/Method to registered service impls.
        // Auth middleware already ran before this call, so no extra JWT check needed here.
        if (path.startsWith("/bladewatch.v1.")) {
            connectDispatcher.dispatch(method, path, body,
                    contentTypeHeader, connectVersionHeader, clientIdentity, out);
            return true;
        }

        // Recordings API (with Range header support for video seeking) + thumbnails + event timelines
        if (path.startsWith("/api/recordings") || path.startsWith("/video/") ||
            path.startsWith("/thumb/") || path.startsWith("/api/events/")) {
            return RecordingsApiHandler.handleWithRange(method, path, body, rangeHeader, ifNoneMatchHeader, out);
        }
        
        // Surveillance API
        if (path.startsWith("/api/surveillance/safe-locations")) {
            return SafeLocationApiHandler.handle(method, path, body, out);
        }
        if (path.startsWith("/api/surveillance")) {
            return SurveillanceApiHandler.handle(method, path, body, out);
        }
        
        // Streaming API
        if (path.startsWith("/api/stream")) {
            return StreamingApiHandler.handle(method, path, body, out);
        }
        
        // GPS API
        if (path.startsWith("/api/gps")) {
            return GpsApiHandler.handle(method, path, body, out);
        }
        
        // Quality Settings API (includes storage settings)
        if (path.startsWith("/api/settings/")) {
            return QualitySettingsApiHandler.handle(method, path, body, out);
        }
        
        // Trip Analytics API
        if (path.startsWith("/api/trips")) {
            net.bladewatch.app.trips.TripAnalyticsManager tam = CameraDaemon.getTripAnalyticsManager();
            if (tam != null) {
                net.bladewatch.app.trips.TripApiHandler handler = new net.bladewatch.app.trips.TripApiHandler(tam);
                org.json.JSONObject result = handler.handleRequest(path, method, null, body);
                if (result != null) {
                    int status = result.optInt("_status", 200);
                    result.remove("_status");
                    if (status == 200) {
                        HttpResponse.sendJson(out, result.toString());
                    } else {
                        HttpResponse.sendError(out, status, result.toString());
                    }
                    return true;
                }
            } else {
                HttpResponse.sendJsonError(out, "Trip analytics not initialized");
                return true;
            }
        }
        
        // Audio Test API (AVAS speaker test)
        if (path.startsWith("/api/audio/")) {
            return AudioTestApiHandler.handle(method, path, body, out);
        }

        // Vehicle Control API
        if (path.startsWith("/api/vehicle")) {
            return VehicleControlApiHandler.handle(method, path, body, out);
        }
        
        // Performance API
        if (path.startsWith("/api/performance")) {
            return PerformanceApiHandler.handle(method, path, body, out);
        }
        
        // Format Storage API (reformat SD card / USB drive)
        if (path.equals("/api/storage/format")) {
            return FormatStorageApiHandler.handle(path, method, body, out);
        }

        // External Storage API (SD card and CDR cleanup)
        if (path.startsWith("/api/storage/external")) {
            return ExternalStorageApiHandler.handle(path, method, body, out);
        }

        // 3D Vehicle Models API (download/persist user-selectable GLB models)
        if (path.startsWith("/api/models/")) {
            return ModelsApiHandler.handle(method, path, body, out);
        }

        // Notification API — web push notifications
        if (path.startsWith("/api/notifications") || path.startsWith("/api/push")) {
            return NotificationApiHandler.handle(method, path, body, out);
        }

        return false;
    }
    
    /** Expose sendStatus for Connect service impls (ConnectHandlerUtil capture pattern). */
    public void serveStatus(OutputStream out) throws Exception {
        sendStatus(out);
    }

    private void sendStatus(OutputStream out) throws Exception {
        JSONObject status = new JSONObject();
        status.put("status", "ok");
        status.put("deviceId", CameraDaemon.getDeviceId());

        // Vehicle-data readiness, surfaced explicitly so the web UI can render
        // a "waiting for vehicle…" state instead of silently leaving every
        // field blank when the BYD binders haven't bound yet (cold-boot race
        // — HTTP comes up well before BydDataCollector finishes ~15 binder
        // lookups). On first hit, give the collector a short window to come
        // online; this resolves the most common "tunnel loads, no data"
        // report without forcing the client to retry.
        boolean vehicleReady = waitForVehicleDataReady(1500);
        status.put("vehicleDataReady", vehicleReady);

        // App version straight from the build. The in-app updater that used to
        // write a release string to /data/local/tmp/bladewatch_version has been
        // removed, so the APK's own versionName is now the only truth there is.
        status.put("appVersion", net.bladewatch.app.BuildConfig.VERSION_NAME);
        status.put("recording", TcpCommandServer.getRecordingCameras());
        status.put("viewing", TcpCommandServer.getViewOnlyCameras());
        status.put("active", TcpCommandServer.getActiveCameras());
        status.put("available", TcpCommandServer.getAvailableCameras());
        status.put("battery", BatteryMonitor.getBatteryInfo());
        status.put("acc", AccMonitor.isAccOn());
        
        // Safe zone status (so UI can show suppressed state)
        net.bladewatch.app.surveillance.SafeLocationManager safeMgr =
            net.bladewatch.app.surveillance.SafeLocationManager.getInstance();
        status.put("safeZoneSuppressed", CameraDaemon.isSafeZoneSuppressed());
        status.put("inSafeZone", safeMgr.isInSafeZone());
        if (safeMgr.getCurrentZoneName() != null) {
            status.put("safeZoneName", safeMgr.getCurrentZoneName());
        }
        
        // Vehicle data (charging state and power).
        // Each subsection is wrapped individually — one BYD HAL throwing
        // RemoteException must not zero out unrelated fields. Any failure
        // here is logged so customers reporting "blank data" produce evidence
        // we can act on, instead of silent emptiness.
        try {
            net.bladewatch.app.monitor.VehicleDataMonitor vehicleMonitor =
                net.bladewatch.app.monitor.VehicleDataMonitor.getInstance();

            net.bladewatch.app.monitor.ChargingStateData chargingState = vehicleMonitor.getChargingState();
            if (chargingState != null) {
                JSONObject charging = new JSONObject();
                charging.put("stateName", chargingState.stateName);
                charging.put("status", chargingState.status.name());
                charging.put("chargingPowerKW", chargingState.chargingPowerKW);
                charging.put("isDischarging", chargingState.isDischarging);
                charging.put("isError", chargingState.isError);
                // Surface the "estimated from SOC rate" flag so the UI can show
                // a "~" prefix on the kW value (core.js already reads this).
                charging.put("isEstimated", chargingState.isEstimated);
                status.put("charging", charging);
            }
            
            net.bladewatch.app.monitor.BatterySocData socData = vehicleMonitor.getBatterySoc();
            if (socData != null) {
                JSONObject soc = new JSONObject();
                soc.put("percent", socData.socPercent);
                soc.put("isLow", socData.isLow);
                soc.put("isCritical", socData.isCritical);
                soc.put("status", socData.getStatus());
                status.put("soc", soc);
            }
            
            net.bladewatch.app.monitor.DrivingRangeData rangeData = vehicleMonitor.getDrivingRange();
            if (rangeData != null) {
                JSONObject range = new JSONObject();
                range.put("elecRangeKm", rangeData.elecRangeKm);
                range.put("fuelRangeKm", rangeData.fuelRangeKm);
                range.put("totalRangeKm", rangeData.totalRangeKm);
                range.put("isLow", rangeData.isLow);
                range.put("isCritical", rangeData.isCritical);
                range.put("status", rangeData.getStatus());
                // Only emit fuelPercent for PHEVs — BEVs leave fuelPercent NaN
                // upstream (BydDataCollector gates on nominal capacity < 30 kWh),
                // so the web UI's `if (fuelPct > 0)` guard hides the fuel card.
                if (rangeData.hasFuelPercent()) {
                    range.put("fuelPercent", rangeData.fuelPercent);
                }
                status.put("range", range);
            }

            // Distance unit preference — "km" or "mi". Derived from user setting
            // (TripConfig.distanceUnit) which overrides auto-detection. The web UI
            // uses this to convert km values for display and pick the right label.
            try {
                net.bladewatch.app.byd.BydDataCollector collector =
                        net.bladewatch.app.byd.BydDataCollector.getInstance();
                status.put("distanceUnit", (collector != null && collector.isMilesMode()) ? "mi" : "km");
            } catch (Exception e) {
                CameraDaemon.log("DEBUG: distanceUnit probe failed: " + e.getMessage());
                status.put("distanceUnit", "km");
            }

            // Active UI locale — exposed so the WebView can sync its i18n
            // state with changes made elsewhere (Android settings drawer,
            // another logged-in client). Always one of LocaleManager.SUPPORTED.
            try {
                status.put("locale", LocaleManager.get());
            } catch (Exception e) {
                CameraDaemon.log("DEBUG: locale probe failed: " + e.getMessage());
                status.put("locale", "en");
            }
        } catch (Exception e) {
            // Vehicle data not available — surface the cause so a customer
            // report includes the proximate failure (binder gone, SDK class
            // missing, etc.) rather than just "page is blank".
            CameraDaemon.log("status: vehicle data block failed: " + e);
            status.put("vehicleDataError", e.getClass().getSimpleName() + ": " + e.getMessage());
        }
        try {
            JSONObject soh = new JSONObject();
            boolean hasSoh = false;

            // Read SOH percent from the persisted battery-health estimate file.
            java.io.File sohFile = new java.io.File("/data/local/tmp/abrp_soh_estimate.properties");
            if (sohFile.exists()) {
                java.util.Properties props = new java.util.Properties();
                try (java.io.FileInputStream fis = new java.io.FileInputStream(sohFile)) {
                    props.load(fis);
                }
                String sohStr = props.getProperty("soh_percent");
                if (sohStr != null) {
                    double sohVal = Double.parseDouble(sohStr);
                    // Reject out-of-range values (e.g. 101 from bogus BMS sentinels)
                    if (sohVal > 0 && sohVal <= 100) {
                        soh.put("percent", Math.round(sohVal * 10) / 10.0);
                        hasSoh = true;
                    }
                }
            }

            if (hasSoh) status.put("soh", soh);
        } catch (Exception e) {
            CameraDaemon.log("DEBUG: SOH read failed: " + e.getMessage());
        }
        
        // GPU surveillance status — only true when actually in sentry/surveillance mode,
        // not when pipeline is running for normal recording (CONTINUOUS, PROXIMITY_GUARD)
        net.bladewatch.app.surveillance.GpuSurveillancePipeline pipeline = CameraDaemon.getGpuPipeline();
        status.put("gpuSurveillance", pipeline != null && pipeline.isSurveillanceMode());
        
        // Recording mode details (for status overlay)
        try {
            JSONObject recordingStatus = new JSONObject();
            net.bladewatch.app.recording.RecordingModeManager rmm = CameraDaemon.getRecordingModeManager();
            if (rmm != null) {
                recordingStatus.put("configuredMode", rmm.getCurrentMode().name());
                recordingStatus.put("isRecording", pipeline != null && pipeline.isRecording());
                recordingStatus.put("pipelineRunning", pipeline != null && pipeline.isRunning());
                recordingStatus.put("gear", net.bladewatch.app.recording.RecordingModeManager.gearToString(rmm.getCurrentGear()));
                recordingStatus.put("accOn", rmm.isAccOn());
            } else {
                recordingStatus.put("configuredMode", "UNKNOWN");
                recordingStatus.put("isRecording", false);
                recordingStatus.put("pipelineRunning", false);
            }
            status.put("recordingStatus", recordingStatus);
        } catch (Exception e) {
            // Recording status not available
        }
        
        // Trip analytics status (for status overlay)
        try {
            JSONObject tripStatus = new JSONObject();
            net.bladewatch.app.trips.TripAnalyticsManager tam = CameraDaemon.getTripAnalyticsManager();
            if (tam != null) {
                tripStatus.put("enabled", tam.isEnabled());
                tripStatus.put("tripActive", tam.isTripActive());
                net.bladewatch.app.trips.TripRecord activeTrip = tam.getActiveTrip();
                if (activeTrip != null) {
                    tripStatus.put("tripStartTime", activeTrip.startTime);
                    tripStatus.put("tripDurationSec", (System.currentTimeMillis() - activeTrip.startTime) / 1000);
                }
            } else {
                tripStatus.put("enabled", false);
                tripStatus.put("tripActive", false);
            }
            status.put("tripStatus", tripStatus);
        } catch (Exception e) {
            // Trip status not available
        }
        
        // GPS location
        net.bladewatch.app.monitor.GpsMonitor gps = net.bladewatch.app.monitor.GpsMonitor.getInstance();
        status.put("gps", gps.getLocationJson());
        
        // Network info (WiFi SSID + IP or Mobile Data)
        JSONObject network = net.bladewatch.app.monitor.NetworkMonitor.getNetworkInfo();
        if (UnifiedConfigManager.isLanHttpEnabled()) {
            network.put("lanHttpEnabled", true);
            network.put("httpBind", "0.0.0.0");
            network.put("httpModeWarning", "LAN HTTP is unsafe on shared networks");
        } else {
            network.put("lanHttpEnabled", false);
            network.put("httpBind", "127.0.0.1");
        }
        status.put("network", network);
        
        HttpResponse.sendJson(out, status.toString());
    }

    /**
     * Block briefly until BydDataCollector reports initialized, so the very
     * first /status request after boot doesn't return a shell with every
     * vehicle field omitted. The collector typically finishes inside ~600 ms
     * but cold-boot binders can stretch beyond a second; we cap the wait so
     * a permanently-broken collector still returns a response.
     *
     * @return true if the collector is initialized when this returns,
     *         false if the wait timed out (caller still emits status, just
     *         with vehicle fields absent and vehicleDataReady=false).
     */
    private boolean waitForVehicleDataReady(long maxWaitMs) {
        try {
            net.bladewatch.app.byd.BydDataCollector collector =
                net.bladewatch.app.byd.BydDataCollector.getInstance();
            if (collector.isInitialized()) {
                return true;
            }
            long deadline = System.currentTimeMillis() + maxWaitMs;
            while (System.currentTimeMillis() < deadline) {
                Thread.sleep(50);
                if (collector.isInitialized()) {
                    return true;
                }
            }
            return false;
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            return false;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Serves static files from WEB_ROOT with streaming for large files.
     */
    private boolean serveStaticFile(OutputStream out, String relativePath) {
        if (relativePath.contains("..")) {
            return false;
        }

        File file = new File(WEB_ROOT, relativePath);
        if (!file.exists() || !file.isFile()) {
            // Fall back to the persistent models cache for GLBs that were downloaded
            // at runtime. All shipped models live in WEB_ROOT (bundled in APK assets);
            // any future downloadable models are fetched on demand into ModelsApiHandler.MODELS_DIR.
            if (relativePath.startsWith("shared/models/") && relativePath.endsWith(".glb")) {
                String fileName = relativePath.substring("shared/models/".length());
                File cached = ModelsApiHandler.cachedModelFile(fileName);
                if (cached != null) {
                    file = cached;
                } else {
                    return false;
                }
            } else {
                return false;
            }
        }
        
        try (FileInputStream fis = new FileInputStream(file)) {
            String contentType = getContentType(relativePath);
            
            // HTML pages must always revalidate so the user gets the latest UI logic.
            // The service worker and PWA manifest also need to bypass cache —
            // a stuck-cached SW means the user can't pick up notification fixes
            // without a manual unregister.
            //
            // i18n catalogs (/i18n/<lang>.json) MUST also bypass cache: unlike the
            // Angular JS/CSS bundle — whose filenames are content-hashed and so
            // cache-bust automatically on every build — the catalog URLs are static
            // and unhashed. A new app build ships new template keys, but a browser
            // holding a day-old cached catalog won't have them, so the UI renders
            // raw keys ("dashboard.this_week") until the cache expires. Revalidating
            // guarantees catalogs refresh immediately on every reinstall/update.
            //
            // Other shared static assets (JS/CSS/fonts/images) ship inside the APK
            // and never change without an app update, so we let the browser cache
            // them to avoid re-downloading ~360KB on every page load.
            String cacheControl;
            String fileName = new File(relativePath).getName();
            boolean isCatalog = relativePath.startsWith("i18n/")
                    || relativePath.startsWith("server-i18n/");
            if (relativePath.endsWith(".html")
                    || fileName.equals("sw.js")
                    || fileName.equals("manifest.json")
                    || isCatalog) {
                cacheControl = "no-store, no-cache, must-revalidate, max-age=0";
            } else {
                cacheControl = "public, max-age=86400";
            }
            
            StringBuilder headers = new StringBuilder();
            headers.append("HTTP/1.1 200 OK\r\n")
                   .append("Content-Type: ").append(contentType).append("\r\n")
                   .append("Content-Length: ").append(file.length()).append("\r\n")
                   .append("Cache-Control: ").append(cacheControl).append("\r\n");
            if (relativePath.endsWith(".html")) {
                headers.append("Pragma: no-cache\r\n")
                       .append("Expires: 0\r\n");
            }
            headers.append(HttpResponse.connectionHeader(out)).append("\r\n");
            out.write(headers.toString().getBytes());
            
            // Stream in 16KB chunks
            byte[] buffer = new byte[16384];
            int count;
            while ((count = fis.read(buffer)) != -1) {
                out.write(buffer, 0, count);
            }
            out.flush();
            
            CameraDaemon.log("Served static: " + relativePath + " (" + file.length() + " bytes)");
            return true;
            
        } catch (Exception e) {
            CameraDaemon.log("Static file error: " + relativePath + " - " + e.getMessage());
            return false;
        }
    }
    
    private String getContentType(String path) {
        if (path.endsWith(".html")) return "text/html; charset=utf-8";
        if (path.endsWith(".css")) return "text/css; charset=utf-8";
        if (path.endsWith(".js")) return "application/javascript; charset=utf-8";
        if (path.endsWith(".json")) return "application/json";
        if (path.endsWith(".wasm")) return "application/wasm";
        if (path.endsWith(".png")) return "image/png";
        if (path.endsWith(".jpg") || path.endsWith(".jpeg")) return "image/jpeg";
        if (path.endsWith(".webp")) return "image/webp";
        if (path.endsWith(".svg")) return "image/svg+xml";
        if (path.endsWith(".ico")) return "image/x-icon";
        if (path.endsWith(".glb")) return "model/gltf-binary";
        if (path.endsWith(".gltf")) return "model/gltf+json";
        return "application/octet-stream";
    }

    // ==================== WEBSOCKET STREAMING ====================
    
    private static final String WS_MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    
    /**
     * Handles WebSocket upgrade on /ws path for single-port streaming.
     */
    /**
     * Complete the WebSocket handshake and hand the socket to the streaming pool.
     *
     * @return true if ownership of {@code client} passed to {@link #streamPool}, meaning the
     *         caller must NOT close it. False if the handshake failed and the socket is
     *         still the caller's to close.
     */
    private boolean handleWebSocketUpgrade(Socket client, String websocketKey) {
        try {
            CameraDaemon.log("WebSocket upgrade requested");
            
            String acceptKey = computeWebSocketAccept(websocketKey);
            
            OutputStream out = client.getOutputStream();
            String response = "HTTP/1.1 101 Switching Protocols\r\n" +
                            "Upgrade: websocket\r\n" +
                            "Connection: Upgrade\r\n" +
                            "Sec-WebSocket-Accept: " + acceptKey + "\r\n\r\n";
            out.write(response.getBytes());
            out.flush();
            
            CameraDaemon.log("WebSocket handshake complete");
            // Hand off to the streaming pool and let this REQUEST thread go. The handshake
            // is done, so nothing above needs the socket any more, and streaming it here
            // would hold a request worker for the entire session (BladeWatch-sxzg).
            //
            // The socket is deliberately NOT closed on the way out: it now belongs to the
            // stream, which closes it when the viewer goes away.
            streamPool.execute(() -> streamH264ToWebSocket(client));
            return true;
            
        } catch (Exception e) {
            CameraDaemon.log("WebSocket upgrade error: " + e.getMessage());
        }
        // Handshake failed: the socket never reached the stream, so the caller still owns it.
        return false;
    }
    
    private String computeWebSocketAccept(String key) throws Exception {
        String concat = key + WS_MAGIC;
        MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
        byte[] hash = sha1.digest(concat.getBytes("UTF-8"));
        return Base64.encodeToString(hash, Base64.NO_WRAP);
    }

    /**
     * SOTA: Streams H.264 frames over WebSocket with zero-restart attach.
     *
     * Instead of force-restarting the encoder on every client connect (which causes
     * a 700ms gap and corrupt first frames), we:
     * 1. Reuse the existing encoder if streaming is already enabled
     * 2. Request an IDR keyframe via MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME
     * 3. Send cached SPS/PPS immediately so the decoder can initialize
     * 4. Wait for the IDR to arrive before sending P-frames
     *
     * This gives instant stream start with no encoder restart, no frame corruption,
     * and no broken pipe from the client timing out during restart.
     */
    private void streamH264ToWebSocket(Socket client) {
        CameraDaemon.log("Starting H.264 WebSocket stream");
        
        final BlockingQueue<byte[]> frameQueue = new ArrayBlockingQueue<>(60);
        final boolean[] running = {true};
        
        try {
            client.setSoTimeout(0);
            client.setTcpNoDelay(true);
            client.setSendBufferSize(256 * 1024);
            final OutputStream out = new java.io.BufferedOutputStream(
                client.getOutputStream(), 128 * 1024);
            
            net.bladewatch.app.surveillance.GpuSurveillancePipeline pipeline = CameraDaemon.getGpuPipeline();
            if (pipeline == null) {
                CameraDaemon.log("WS: Pipeline not available");
                sendWebSocketClose(out, 1011, "Pipeline not available");
                return;
            }
            
            // Auto-start pipeline if needed
            if (!pipeline.isRunning()) {
                CameraDaemon.log("WS: Auto-starting pipeline");
                pipeline.start();
                Thread.sleep(500);
            }
            
            GpuPipelineConfig.StreamingQuality q = GpuPipelineConfig.StreamingQuality.fromString(
                StreamingApiHandler.getStreamingQuality());
            
            int savedViewMode = pipeline.getStreamViewMode();
            if (savedViewMode < 0) savedViewMode = 0;
            
            // SOTA: Reuse existing encoder if streaming is already enabled at same quality.
            // Only restart if not enabled or quality changed.
            boolean needsRestart = !pipeline.isStreamingEnabled();
            
            // Check if quality changed — need restart for new resolution
            if (!needsRestart && pipeline.isStreamingEnabled()) {
                HardwareEventRecorderGpu existingEncoder = pipeline.getStreamEncoder();
                if (existingEncoder != null) {
                    // Compare current encoder resolution with requested quality
                    net.bladewatch.app.streaming.GpuStreamScaler scaler = pipeline.getStreamScaler();
                    if (scaler != null) {
                        int currentWidth = scaler.getWidth();
                        int currentHeight = scaler.getHeight();
                        if (currentWidth != q.width || currentHeight != q.height) {
                            CameraDaemon.log("WS: Quality changed (" + currentWidth + "x" + currentHeight + 
                                " → " + q.width + "x" + q.height + ") — restarting encoder");
                            needsRestart = true;
                            pipeline.disableStreaming();
                            Thread.sleep(200);
                        }
                    }
                }
            }
            
            if (needsRestart) {
                CameraDaemon.log("WS: Enabling streaming - " + q.displayName);
                pipeline.enableStreaming(q.width, q.height, q.fps, q.bitrate);
                Thread.sleep(500);
            } else {
                CameraDaemon.log("WS: Reusing existing stream encoder (no restart)");
            }
            
            if (savedViewMode > 0) {
                pipeline.setStreamViewMode(savedViewMode);
                CameraDaemon.log("WS: View mode " + savedViewMode);
            }
            
            HardwareEventRecorderGpu encoder = pipeline.getStreamEncoder();
            if (encoder == null) {
                CameraDaemon.log("WS: Stream encoder not available");
                sendWebSocketClose(out, 1011, "Encoder not available");
                return;
            }
            
            // SOTA: Send cached SPS/PPS immediately from WebSocketStreamServer
            // so the client decoder can initialize before the first frame arrives.
            net.bladewatch.app.streaming.WebSocketStreamServer wsServer = pipeline.getWebSocketServer();
            boolean spsPpsSent = false;
            if (wsServer != null) {
                byte[] cachedSpsPps = wsServer.getCachedSpsPps();
                if (cachedSpsPps != null && cachedSpsPps.length > 0) {
                    try {
                        sendWebSocketBinaryFrame(out, cachedSpsPps);
                        spsPpsSent = true;
                        CameraDaemon.log("WS: Sent cached SPS/PPS (" + cachedSpsPps.length + " bytes)");
                    } catch (Exception e) {
                        CameraDaemon.log("WS: Failed to send cached SPS/PPS: " + e.getMessage());
                    }
                }
            }
            
            // SOTA: Request IDR keyframe so client gets a clean decode start.
            // This is instant — no encoder restart needed.
            encoder.requestSyncFrame();
            CameraDaemon.log("WS: IDR keyframe requested");
            
            // Also request SPS/PPS re-send if we didn't have cached ones
            if (!spsPpsSent) {
                // The encoder will send SPS/PPS before the next IDR via the callback
                CameraDaemon.log("WS: Waiting for SPS/PPS from encoder");
            }
            
            // Stream callback with congestion control
            final boolean[] gotKeyframe = {spsPpsSent};  // Skip waiting if we already sent SPS/PPS
            HardwareEventRecorderGpu.StreamCallback callback = new HardwareEventRecorderGpu.StreamCallback() {
                @Override
                public void onSpsPps(ByteBuffer sps, ByteBuffer pps) {
                    int spsSize = sps.remaining();
                    int ppsSize = pps.remaining();
                    byte[] combined = new byte[spsSize + ppsSize];
                    sps.get(combined, 0, spsSize);
                    pps.get(combined, spsSize, ppsSize);
                    frameQueue.offer(combined);
                    gotKeyframe[0] = true;
                    CameraDaemon.log("WS: Queued SPS/PPS (" + combined.length + " bytes)");
                }
                
                @Override
                public void onH264Packet(ByteBuffer data, android.media.MediaCodec.BufferInfo info) {
                    // SOTA: Drop P-frames until we've sent SPS/PPS + IDR
                    // Sending P-frames before the decoder has SPS/PPS causes decode failure
                    if (!gotKeyframe[0]) {
                        boolean isKeyframe = (info.flags & android.media.MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0;
                        if (!isKeyframe) return;  // Drop P-frames before first keyframe
                        gotKeyframe[0] = true;
                    }
                    
                    if (frameQueue.remainingCapacity() > 0) {
                        byte[] frame = new byte[info.size];
                        data.position(info.offset);
                        data.get(frame);
                        frameQueue.offer(frame);
                    }
                    // If queue is full, drop frame (congestion control)
                }
            };
            
            encoder.setStreamCallback(callback);
            CameraDaemon.log("WS: Stream callback registered");
            
            if (wsServer != null) {
                wsServer.registerExternalClient();
            }
            
            long lastFrameTime = System.currentTimeMillis();
            int frameCount = 0;
            
            try {
                while (running[0] && !client.isClosed()) {
                    byte[] frame = frameQueue.poll(5, TimeUnit.SECONDS);
                    
                    if (frame != null) {
                        try {
                            // Log first few frames for debugging
                            if (frameCount < 5) {
                                CameraDaemon.log("WS: Frame " + frameCount + " size=" + frame.length + " bytes");
                            }
                            sendWebSocketBinaryFrame(out, frame);
                            lastFrameTime = System.currentTimeMillis();
                            frameCount++;
                            
                            if (frameCount % 300 == 0) {
                                CameraDaemon.log("WS: Sent " + frameCount + " frames");
                            }
                        } catch (java.net.SocketException e) {
                            CameraDaemon.log("WS: Client disconnected (" + e.getMessage() + ")");
                            break;
                        } catch (java.io.IOException e) {
                            CameraDaemon.log("WS: Write error (" + e.getMessage() + ")");
                            break;
                        }
                    } else {
                        // No frame for 5 seconds — send ping to keep alive
                        try {
                            out.write(new byte[]{(byte)0x89, 0x00});
                            out.flush();
                        } catch (Exception e) {
                            CameraDaemon.log("WS: Ping failed, client gone");
                            break;
                        }
                        
                        if (System.currentTimeMillis() - lastFrameTime > 60000) {
                            CameraDaemon.log("WS: Idle timeout (60s) - closing");
                            break;
                        }
                    }
                }
            } finally {
                if (wsServer != null) {
                    wsServer.unregisterExternalClient();
                }
            }
            
            encoder.clearStreamCallback();
            CameraDaemon.log("WS: Stream ended (" + frameCount + " frames sent)");
            
        } catch (Exception e) {
            CameraDaemon.log("WS stream error: " + e.getMessage());
        } finally {
            try { client.close(); } catch (Exception e) {}
        }
    }

    /**
     * SOTA: Send binary data as WebSocket frame(s) with fragmentation for large frames.
     * Frames larger than MAX_WS_FRAME_SIZE are split into continuation frames
     * to prevent TCP buffer overflow on constrained networks (BYD WiFi AP).
     */
    private static final int MAX_WS_FRAME_SIZE = 32768;  // 32KB per WebSocket frame
    
    private void sendWebSocketBinaryFrame(OutputStream out, byte[] data) throws Exception {
        if (data.length <= MAX_WS_FRAME_SIZE) {
            // Small frame — send as single message
            sendWebSocketRawFrame(out, data, 0, data.length, 0x82, true);
        } else {
            // Large frame — fragment into continuation frames
            int offset = 0;
            boolean first = true;
            while (offset < data.length) {
                int chunkSize = Math.min(MAX_WS_FRAME_SIZE, data.length - offset);
                boolean last = (offset + chunkSize >= data.length);
                int opcode = first ? 0x02 : 0x00;  // binary for first, continuation for rest
                sendWebSocketRawFrame(out, data, offset, chunkSize, opcode, last);
                offset += chunkSize;
                first = false;
            }
        }
        out.flush();
    }
    
    private void sendWebSocketRawFrame(OutputStream out, byte[] data, int offset, int len, 
                                        int opcode, boolean fin) throws Exception {
        int firstByte = (fin ? 0x80 : 0x00) | opcode;
        out.write(firstByte);
        
        if (len <= 125) {
            out.write(len);
        } else if (len <= 65535) {
            out.write(126);
            out.write((len >> 8) & 0xFF);
            out.write(len & 0xFF);
        } else {
            out.write(127);
            for (int i = 7; i >= 0; i--) {
                out.write((int) ((len >> (8 * i)) & 0xFF));
            }
        }
        
        out.write(data, offset, len);
    }
    
    private void sendWebSocketClose(OutputStream out, int code, String reason) {
        try {
            byte[] reasonBytes = reason.getBytes("UTF-8");
            int len = 2 + reasonBytes.length;
            
            out.write(0x88);  // FIN + close opcode
            out.write(len);
            out.write((code >> 8) & 0xFF);
            out.write(code & 0xFF);
            out.write(reasonBytes);
            out.flush();
        } catch (Exception e) {
            // Ignore
        }
    }
    
    // ==================== STATIC ACCESSORS (for backward compatibility) ====================
    
    /**
     * Loads persisted settings. Delegates to QualitySettingsApiHandler.
     */
    public static void loadPersistedSettings() {
        QualitySettingsApiHandler.loadPersistedSettings();
    }
    
    // Getters delegate to handlers
    public static String getRecordingQuality() { return QualitySettingsApiHandler.getRecordingQuality(); }
    public static String getStreamingQuality() { return StreamingApiHandler.getStreamingQuality(); }
    public static String getRecordingBitrate() { return QualitySettingsApiHandler.getRecordingBitrate(); }
    public static String getRecordingCodec() { return QualitySettingsApiHandler.getRecordingCodec(); }
    
    // Setters delegate to handlers
    public static void setRecordingQuality(String quality) { QualitySettingsApiHandler.setRecordingQuality(quality); }
    public static void setStreamingQuality(String quality) { StreamingApiHandler.setStreamingQuality(quality); }
    public static void setRecordingBitrate(String bitrate) {
        // Legacy API surface kept for old web/IPC clients. Convert here so
        // callers land on the canonical recording-quality implementation.
        QualitySettingsApiHandler.setRecordingQuality(legacyBitrateToQuality(bitrate));
    }
    public static void setRecordingCodec(String codec) { QualitySettingsApiHandler.setRecordingCodec(codec); }
    
    // Static setters for IPC server
    public static void setRecordingBitrateStatic(String bitrate) { QualitySettingsApiHandler.setRecordingBitrateStatic(bitrate); }
    public static void setRecordingCodecStatic(String codec) { QualitySettingsApiHandler.setRecordingCodecStatic(codec); }
    public static void persistSettingsStatic() { QualitySettingsApiHandler.persistSettings(); }

    private static String legacyBitrateToQuality(String bitrate) {
        if (bitrate == null) return "STANDARD";
        switch (bitrate.toUpperCase()) {
            case "LOW": return "ECONOMY";
            case "HIGH": return "HIGH";
            case "MEDIUM":
            default: return "STANDARD";
        }
    }
}
