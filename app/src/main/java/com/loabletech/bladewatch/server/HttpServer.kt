package net.bladewatch.app.server

import android.content.res.AssetManager
import android.media.MediaCodec
import android.util.Base64
import net.bladewatch.app.BuildConfig
import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.monitor.AccMonitor
import net.bladewatch.app.monitor.BatteryMonitor
import net.bladewatch.app.monitor.GpsMonitor
import net.bladewatch.app.monitor.NetworkMonitor
import net.bladewatch.app.monitor.VehicleDataMonitor
import net.bladewatch.app.recording.RecordingModeManager
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.surveillance.GpuPipelineConfig
import net.bladewatch.app.surveillance.HardwareEventRecorderGpu
import net.bladewatch.app.surveillance.SafeLocationManager
import org.json.JSONObject
import java.io.BufferedOutputStream
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.BindException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.net.SocketTimeoutException
import java.net.URLDecoder
import javax.net.ssl.SSLServerSocket
import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.util.Locale
import java.util.Properties
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.math.min
import kotlin.math.roundToLong

/**
 * HTTP server — serves the web UI and the WebSocket H.264 stream.
 *
 * Plain HTTP listens on 127.0.0.1:8080 ONLY, under every configuration: plaintext never leaves the
 * device (BladeWatch-rdtj.4). LAN access, when the owner opts in (`network.lanHttpEnabled`), is a
 * SECOND listener -- TLS on 0.0.0.0:[LanTls.PORT] with a pinned self-signed certificate. Every
 * listener declares its [ListenerTrust]; only 8080 is [ListenerTrust.LOCAL_APPS].
 *
 * Single-port WebSocket: the /ws endpoint upgrades to WebSocket for H.264 streaming, so the tunnel
 * can expose both HTTP and WebSocket through one onion port.
 *
 * The header blocks below are built from CONCATENATED string literals on purpose:
 * ResponseFramingTest reads them as source text and would not recognise an interpolated status
 * line.
 */
class HttpServer(private val port: Int) {

    private var serverSocket: ServerSocket? = null

    @Volatile
    private var running = true

    /**
     * Request-serving pool, capped at 32 concurrent connections. Every worker here is bounded by
     * the 15 s socket timeout set in [handleClient], so no single request can hold one
     * indefinitely.
     */
    private val threadPool = Executors.newFixedThreadPool(32)

    /**
     * Long-lived H.264 WebSocket streams, deliberately SEPARATE from [threadPool]
     * (BladeWatch-sxzg).
     *
     * The in-car Flutter UI speaks ConnectRPC to this very server on 127.0.0.1:8080, so it queues
     * on the same pool as every remote client arriving through the onion service.
     * [streamH264ToWebSocket] sets setSoTimeout(0) and then blocks for the whole viewing session —
     * so on the request pool, each viewer permanently removed a worker that the driver's own
     * screen needed. Ordinary requests are bounded by their timeout; a stream is bounded by
     * nothing.
     *
     * Measured on the head unit 2026-09-15, with the tunnel up and a remote viewer: the Flutter
     * app rendered ZERO frames in ten seconds while 44% of frames were janky at a 600 ms 99th
     * percentile, on a machine that was 497% of 800% idle. Not a render loop and not a CPU
     * shortage — a UI thread waiting on RPCs stuck behind remote traffic.
     *
     * Cached rather than fixed: viewers are few and sporadic, threads are reclaimed after 60 s
     * idle, and a hard cap here would mean refusing a legitimate viewer rather than merely slowing
     * one. The cap that matters is on the REQUEST pool, which this protects.
     */
    private val streamPool = Executors.newCachedThreadPool { r ->
        Thread(r, "http-stream").apply { isDaemon = true }
    }

    /** Exposed so service impls can register themselves. */
    val connectDispatcher = ConnectDispatcher()

    fun start() {
        CameraDaemon.log("HTTP server starting on port $port")

        // Initialize the auth system
        AuthManager.initialize()
        CameraDaemon.log("Auth system initialized")

        Thread({ runLanTlsListener() }, "http-lan-tls").apply { isDaemon = true; start() }
        Thread({ runRemoteLoopbackListener() }, "http-remote-loopback").apply { isDaemon = true; start() }
        Thread({ runPearTlsListener() }, "http-pear-tls").apply { isDaemon = true; start() }

        while (running && CameraDaemon.isRunning()) {
            try {
                serverSocket?.let { existing ->
                    if (!existing.isClosed) {
                        try {
                            existing.close()
                        } catch (e: Exception) {
                            CameraDaemon.log(
                                "WARN: HTTP serverSocket.close() failed: " + e.message
                            )
                        }
                    }
                }

                // Loopback, always. LAN access is the TLS listener's job (runLanTlsListener).
                val socket = ServerSocket(port, 10, InetAddress.getByName("127.0.0.1"))
                socket.reuseAddress = true
                serverSocket = socket
                CameraDaemon.log("HTTP server listening on 127.0.0.1:$port")

                while (running && CameraDaemon.isRunning() && !socket.isClosed) {
                    try {
                        val client = socket.accept()
                        CameraDaemon.log("HTTP client: " + client.remoteSocketAddress)
                        threadPool.execute { handleClient(client, ListenerTrust.LOCAL_APPS) }
                    } catch (e: SocketException) {
                        if (running) {
                            CameraDaemon.log("WARN: HTTP socket error: " + e.message)
                        }
                        break
                    }
                }

                if (running) {
                    CameraDaemon.log("HTTP server restarting...")
                    Thread.sleep(2000)
                }
            } catch (e: BindException) {
                CameraDaemon.log("ERROR: HTTP port $port in use, retrying...")
                try {
                    Thread.sleep(5000)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    break
                }
            } catch (e: Exception) {
                CameraDaemon.log("ERROR: HTTP server error: " + e.message)
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

        CameraDaemon.log("HTTP server stopped")
    }

    fun stop() {
        running = false
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            CameraDaemon.log("WARN: HTTP stop() serverSocket.close() failed: " + e.message)
        }
        try {
            lanTlsSocket?.close()
        } catch (e: Exception) {
            CameraDaemon.log("WARN: HTTP stop() LAN TLS socket close() failed: " + e.message)
        }
        try {
            remoteLoopbackSocket?.close()
        } catch (e: Exception) {
            CameraDaemon.log("WARN: HTTP stop() remote loopback socket close() failed: " + e.message)
        }
        try {
            pearTlsSocket?.close()
        } catch (e: Exception) {
            CameraDaemon.log("WARN: HTTP stop() Pear TLS socket close() failed: " + e.message)
        }
        threadPool.shutdownNow()
        streamPool.shutdownNow()
    }

    @Volatile
    private var lanTlsSocket: ServerSocket? = null

    @Volatile
    private var remoteLoopbackSocket: ServerSocket? = null

    @Volatile
    private var pearTlsSocket: ServerSocket? = null

    /**
     * 127.0.0.1:[PEAR_TLS_PORT] -- TLS, with the SAME pinned certificate as the LAN listener, and
     * every connection [ListenerTrust.REMOTE]. PearStreamPump connects here; the companion runs TLS
     * end to end through the Pear stream to this listener.
     *
     * Why TLS on top of Pear's own encryption: pear-end's Hyperswarm key pair is random per worklet
     * start and never exposed, so nothing pins the car's Pear identity. Without this, anyone who
     * knows the topic -- a revoked phone, a photographed QR -- could answer as the car, or relay
     * between a companion and the real car, and read the companion's token, JWT and video. The
     * certificate pin from pairing authenticates the car end to end through any relay (owner's
     * decision, BladeWatch-rdtj.8). Loopback only, and independent of the LAN opt-in.
     */
    /**
     * Who a login attempt counts against: the peer's IP alone. Remote transports all arrive from
     * 127.0.0.1, so tor and Pear clients share one bucket -- accepted: every credential behind these
     * endpoints is at least 128 bits, and the global lockout bounds guessing regardless.
     */
    private fun rateLimitIdentity(client: Socket): String = client.inetAddress?.hostAddress ?: "unknown"

    private fun runPearTlsListener() {
        while (running && CameraDaemon.isRunning()) {
            try {
                val identity = LanTls.loadOrCreate(SecretConfigStore()) { e ->
                    CameraDaemon.log("ERROR: stored LAN TLS identity unreadable (${e.message}); " +
                        "minting a new one -- paired companions must re-pair")
                }
                val socket = LanTls.serverSocketFactory(identity)
                    .createServerSocket(PEAR_TLS_PORT, 10, InetAddress.getByName("127.0.0.1")) as SSLServerSocket
                socket.enabledProtocols = LanTls.enabledProtocols(socket.supportedProtocols)
                socket.use {
                    pearTlsSocket = it
                    CameraDaemon.log("Pear TLS listener on 127.0.0.1:$PEAR_TLS_PORT")
                    while (running && CameraDaemon.isRunning() && !it.isClosed) {
                        val client = it.accept()
                        threadPool.execute { handleClient(client, ListenerTrust.REMOTE) }
                    }
                }
            } catch (e: Exception) {
                if (!running) return
                CameraDaemon.log("ERROR: Pear TLS listener: ${e.message}")
                try {
                    Thread.sleep(3000)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return
                }
            }
        }
    }

    /**
     * 127.0.0.1:[REMOTE_LOOPBACK_PORT] -- where the tor onion service hands its connections in
     * (BladeWatch-ur11). pear_daemon's stream pump has its own TLS listener, [runPearTlsListener].
     *
     * Loopback like 8080, but every connection is [ListenerTrust.REMOTE]. A tunnel opens a plain
     * TCP connection to loopback, which at the socket level is indistinguishable from an app on the
     * head unit; landing it on its own listener is what denies the far end the loopback bypass and
     * the vehicle second-factor exemption -- by construction, not by remembering to mark a tunnel
     * as active. Always on: loopback-only, and REMOTE is the strictest trust there is.
     */
    private fun runRemoteLoopbackListener() {
        while (running && CameraDaemon.isRunning()) {
            try {
                ServerSocket(REMOTE_LOOPBACK_PORT, 10, InetAddress.getByName("127.0.0.1")).use { socket ->
                    remoteLoopbackSocket = socket
                    CameraDaemon.log("Remote loopback listener on 127.0.0.1:$REMOTE_LOOPBACK_PORT")
                    while (running && CameraDaemon.isRunning() && !socket.isClosed) {
                        val client = socket.accept()
                        threadPool.execute { handleClient(client, ListenerTrust.REMOTE) }
                    }
                }
            } catch (e: Exception) {
                if (!running) return
                CameraDaemon.log("ERROR: remote loopback listener: ${e.message}")
                try {
                    Thread.sleep(3000)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return
                }
            }
        }
    }

    /**
     * The LAN listener: TLS on 0.0.0.0:[LanTls.PORT], only while the owner has LAN access switched
     * on (BladeWatch-rdtj.4). Every connection it accepts is [ListenerTrust.REMOTE].
     *
     * The flag is re-read every [LAN_TLS_RECHECK_MS] -- the accept times out to do it -- so turning
     * LAN access off closes the port within seconds rather than at the next daemon restart, and
     * turning it on during pairing works without one.
     */
    private fun runLanTlsListener() {
        while (running && CameraDaemon.isRunning()) {
            try {
                if (!UnifiedConfigManager.isLanHttpEnabled()) {
                    Thread.sleep(LAN_TLS_RECHECK_MS.toLong())
                    continue
                }
                val identity = LanTls.loadOrCreate(SecretConfigStore()) { e ->
                    CameraDaemon.log("ERROR: stored LAN TLS identity unreadable (${e.message}); " +
                        "minting a new one -- paired companions must re-pair")
                }
                val socket = LanTls.serverSocketFactory(identity)
                    .createServerSocket(LanTls.PORT, 10, InetAddress.getByName("0.0.0.0")) as SSLServerSocket
                socket.enabledProtocols = LanTls.enabledProtocols(socket.supportedProtocols)
                socket.soTimeout = LAN_TLS_RECHECK_MS
                lanTlsSocket = socket
                CameraDaemon.log("LAN TLS listener on 0.0.0.0:${LanTls.PORT}")
                try {
                    while (running && CameraDaemon.isRunning() && UnifiedConfigManager.isLanHttpEnabled()) {
                        try {
                            val client = socket.accept()
                            threadPool.execute { handleClient(client, ListenerTrust.REMOTE) }
                        } catch (e: SocketTimeoutException) {
                            // Deliberate: the loop condition re-reads the opt-in flag.
                        }
                    }
                } finally {
                    socket.close()
                    lanTlsSocket = null
                    CameraDaemon.log("LAN TLS listener closed")
                }
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                return
            } catch (e: Exception) {
                CameraDaemon.log("ERROR: LAN TLS listener: ${e.message}")
                try {
                    Thread.sleep(5000)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return
                }
            }
        }
    }

    private fun handleClient(client: Socket, trust: ListenerTrust) {
        // BladeWatch-sxzg: set when the socket's ownership passes to the streaming pool. The
        // finally below MUST NOT close it then — the stream is still using it, and closing here
        // would tear down every live view the moment it started.
        var socketHandedOff = false
        // True while waiting for a request line, false once one is being served. Lets the
        // SocketTimeoutException handler tell a normal keep-alive idle expiry (the peer stopped
        // asking) from a read that timed out MID-REQUEST, which is a real fault and must not be
        // swallowed.
        var betweenRequests = true
        try {
            client.soTimeout = SOCKET_TIMEOUT_MS
            // BladeWatch-ou7y: ISO-8859-1, deliberately, NOT the platform default. Content-Length
            // counts BYTES but reader.read(char[]) returns CHARACTERS, and under a UTF-8 decoder
            // those differ for any non-ASCII body — the body loop then waits for characters that
            // will never arrive and the request times out. Latin-1 maps bytes 0-255 bijectively
            // onto chars 0-255, so one char IS one byte and the count is exact. decodeRequestBody
            // converts back to real text. Safe for the rest of the request: request lines and the
            // header values parsed below are ASCII (a non-ASCII path arrives percent-encoded,
            // which is ASCII).
            val reader = BufferedReader(
                InputStreamReader(client.getInputStream(), StandardCharsets.ISO_8859_1)
            )
            val out = KeepAliveStream(BufferedOutputStream(client.getOutputStream()))

            // BladeWatch-67h8: one socket may now carry several requests. Every existing
            // "client.close(); return" below still means "close and stop", which is still correct
            // — they are the error paths. Only the SUCCESS path loops.
            while (true) {
                // Re-arm per iteration. A previous request on this connection may have raised the
                // timeout (the vehicle-control path below sets 60s), and under keep-alive that
                // would otherwise persist for every later request and hold an idle socket four
                // times longer than intended.
                client.soTimeout = SOCKET_TIMEOUT_MS
                betweenRequests = true

                val requestLine = reader.readLine()
                if (requestLine == null) {
                    client.close()
                    return
                }

                betweenRequests = false
                CameraDaemon.log("HTTP: $requestLine")

                // Parse headers
                var contentLength = 0
                var websocketKey: String? = null
                var upgradeHeader: String? = null
                var rangeHeader: String? = null
                // Conditional GET — if the client's HTTP cache sends If-None-Match matching our
                // ETag, we return 304 instead of re-streaming the whole file. Used for cached
                // event recordings.
                var ifNoneMatchHeader: String? = null
                var cookieHeader: String? = null
                var authHeader: String? = null
                var contentTypeHeader: String? = null
                var connectVersionHeader: String? = null
                // uy93.5: the second factor for actuating vehicle calls from non-loopback.
                var vehicleActionTokenHeader: String? = null
                // Reverse-proxy fingerprints — used by AuthMiddleware to disable the loopback
                // safety net when a tunnel relayed the request. A reverse proxy injects
                // X-Forwarded-*. NOTE: the Tor onion service does NOT — it opens a plain TCP
                // connection to 127.0.0.1:8080 — so these headers are no longer how remote traffic
                // is recognised. AuthMiddleware also checks whether the tunnel process is up; see
                // its Tier 2 comment.
                var hasTunnelHeaders = false

                // BladeWatch-67h8: the client's own keep-alive intent.
                var connectionRequestHeader: String? = null

                while (true) {
                    val line = reader.readLine() ?: break
                    if (line.isEmpty()) break
                    val lower = line.lowercase()
                    if (lower.startsWith("connection:")) {
                        connectionRequestHeader = line.substring(11).trim().lowercase()
                    }
                    if (lower.startsWith("content-length:")) {
                        contentLength = line.substring(15).trim().toInt()
                    } else if (lower.startsWith("sec-websocket-key:")) {
                        websocketKey = line.substring(18).trim()
                    } else if (lower.startsWith("upgrade:")) {
                        upgradeHeader = line.substring(8).trim()
                    } else if (lower.startsWith("range:")) {
                        rangeHeader = line.substring(6).trim()
                    } else if (lower.startsWith("if-none-match:")) {
                        ifNoneMatchHeader = line.substring(14).trim()
                    } else if (lower.startsWith("cookie:")) {
                        cookieHeader = line.substring(7).trim()
                    } else if (lower.startsWith("authorization:")) {
                        authHeader = line.substring(14).trim()
                    } else if (lower.startsWith("content-type:")) {
                        contentTypeHeader = line.substring(13).trim()
                    } else if (lower.startsWith("connect-protocol-version:")) {
                        connectVersionHeader = line.substring(25).trim()
                    } else if (lower.startsWith("x-vehicle-action-token:")) {
                        vehicleActionTokenHeader = line.substring(23).trim()
                    } else if (lower.startsWith("accept-language:")) {
                        // First-touch locale hint. Only used if the user has never explicitly
                        // chosen via the picker (LocaleManager file empty). We don't auto-persist
                        // Accept-Language; the picker is the only thing that writes the state
                        // file.
                        val al = line.substring(16).trim()
                        if (al.isNotEmpty()) {
                            try {
                                LocaleManager.fromAcceptLanguage(al)
                            } catch (e: Exception) {
                                CameraDaemon.log(
                                    "DEBUG: Accept-Language probe failed: " + e.message
                                )
                            }
                        }
                    } else if (lower.startsWith("x-forwarded-for:") ||
                        lower.startsWith("x-forwarded-host:") ||
                        lower.startsWith("x-forwarded-proto:") ||
                        lower.startsWith("x-real-ip:") ||
                        lower.startsWith("forwarded:") ||
                        lower.startsWith("cf-connecting-ip:") ||
                        lower.startsWith("cf-ray:") ||
                        lower.startsWith("cf-visitor:")
                    ) {
                        hasTunnelHeaders = true
                    }
                }

                // Read the POST body if present. Loop-read for large payloads (e.g. base64 image
                // uploads): BufferedReader.read() may return fewer chars than requested in a
                // single call.
                var body: String? = null
                if (contentLength > 0) {
                    val bodyChars = CharArray(contentLength)
                    var totalRead = 0
                    while (totalRead < contentLength) {
                        val read = reader.read(bodyChars, totalRead, contentLength - totalRead)
                        if (read == -1) break // EOF
                        totalRead += read
                    }
                    body = decodeRequestBody(bodyChars, totalRead)
                }

                val parts = requestLine.split(" ")
                if (parts.size < 2) {
                    // This runs BEFORE the keep-alive decision below, so on a REUSED connection
                    // `out` still carries the previous request's "keep-alive". We are about to
                    // close, so say so.
                    out.isKeepAlive = false
                    HttpResponse.sendError(out, 400, "Bad Request")
                    client.close()
                    return
                }

                val method = parts[0]
                val path = parts[1]

                // BladeWatch-67h8: decide BEFORE dispatch, because the response writers read this
                // back through HttpResponse.connectionHeader(out) as they emit headers. HTTP/1.1
                // defaults to persistent; HTTP/1.0 requires an explicit opt-in.
                val httpVersion = if (parts.size > 2) parts[2].trim() else "HTTP/1.0"
                val clientWantsClose = connectionRequestHeader?.contains("close") == true
                val clientWantsKeepAlive = connectionRequestHeader?.contains("keep-alive") == true
                val keepAlive = !clientWantsClose &&
                    ("HTTP/1.1".equals(httpVersion, ignoreCase = true) || clientWantsKeepAlive)
                out.isKeepAlive = keepAlive

                // Extend the timeout for slow vehicle control calls. Keyed on the Connect path now
                // that the REST routes are gone (BladeWatch-6mnq). Lock/Unlock/Flash were the slow
                // ones and are cloud-only commands that now resolve to NOT_SUPPORTED, but the SDK
                // path can still block, so the allowance is kept for the service as a whole.
                if (path.startsWith("/bladewatch.v1.VehicleService/")) {
                    client.soTimeout = 60000
                }

                // WebSocket upgrade on the /ws path (auth first for non-public paths). Match /ws
                // and /ws?... — the query param allows a JWT as ?token= because browser WebSocket
                // clients cannot set arbitrary headers, and cookies may be dropped through a
                // tunnel's SameSite policy.
                val wsPathOnly =
                    if (path.contains("?")) path.substring(0, path.indexOf("?")) else path
                if (wsPathOnly == "/ws" && websocketKey != null &&
                    "websocket".equals(upgradeHeader, ignoreCase = true)
                ) {
                    // Promote a ?token= query param into a synthetic Authorization header so
                    // AuthMiddleware's existing Bearer-token path handles it.
                    var wsAuthHeader = authHeader
                    if (wsAuthHeader == null && path.contains("?")) {
                        for (param in path.substring(path.indexOf("?") + 1).split("&")) {
                            val eq = param.indexOf('=')
                            if (eq > 0 && "token" == param.substring(0, eq)) {
                                wsAuthHeader = "Bearer " +
                                    URLDecoder.decode(param.substring(eq + 1), "UTF-8")
                                break
                            }
                        }
                    }
                    out.isKeepAlive = false // see the auth gate below
                    val wsAuthorized = AuthMiddleware.checkAuth(
                        wsPathOnly, cookieHeader, wsAuthHeader, out,
                        client.remoteSocketAddress, hasTunnelHeaders, trust
                    )
                    out.isKeepAlive = keepAlive
                    if (!wsAuthorized) {
                        client.close()
                        return
                    }
                    socketHandedOff = handleWebSocketUpgrade(client, websocketKey)
                    return
                }

                // Route auth endpoints (all public). The login endpoints are rate-limited by the
                // peer's IP -- never X-Forwarded-For, which is client-controlled, and never the
                // socket address with its port, which is a new bucket on every reconnect and made
                // the per-caller limit a no-op (BladeWatch-rdtj.16).
                if (path.startsWith("/auth/")) {
                    AuthApiHandler.handle(
                        method, path, body, out,
                        rateLimitIdentity(client), hasTunnelHeaders
                    )
                    out.flush()
                    if (!keepAlive) break
                    continue
                }

                // Serve the login page (public) — strip the query string for matching
                val pathOnly =
                    if (path.contains("?")) path.substring(0, path.indexOf("?")) else path
                if (pathOnly == "/login" || pathOnly == "/login.html") {
                    if (!serveStaticFile(out, "local/login.html")) {
                        HttpResponse.sendError(out, 404, "login.html not found")
                    }
                    out.flush()
                    if (!keepAlive) break
                    continue
                }

                // Handle CORS preflight (OPTIONS) requests for cross-origin webapp access.
                // Browsers send OPTIONS before POST/PUT/DELETE with Content-Type:
                // application/json. The in-car UI is same-origin so it skips this, but the
                // external webapp needs it. Must be handled BEFORE the auth check — preflight
                // requests don't carry cookies or tokens.
                if (method == "OPTIONS") {
                    HttpResponse.sendCorsPreflightResponse(out)
                    out.flush()
                    if (!keepAlive) break
                    continue
                }

                // Check authentication for all other paths.
                //
                // BladeWatch-67h8: checkAuth writes its own 401/redirect when it fails, and that
                // response is followed by a close — so it must not claim keep-alive. Announce
                // close first, then restore the request's intent if auth passed.
                out.isKeepAlive = false
                val authorized = AuthMiddleware.checkAuth(
                    path, cookieHeader, authHeader, out,
                    client.remoteSocketAddress, hasTunnelHeaders, trust
                )
                out.isKeepAlive = keepAlive
                if (!authorized) {
                    client.close()
                    return
                }

                // uy93.5 / BladeWatch-jwko: vehicle actuation from a NON-LOOPBACK caller needs a
                // short-lived action token (X-Vehicle-Action-Token) on top of the session JWT. The
                // in-car UI always connects from loopback and is exempt.
                //
                // This gate used to be keyed on path.startsWith("/api/vehicle/"), which no real
                // client ever matched after the Connect migration — so the second factor was inert
                // and a session JWT alone actuated the car over the tunnel. It is keyed on the
                // Connect path now. VehicleActionGate owns which methods actuate, and its test
                // fails when a VehicleService RPC is registered without being classified, so this
                // cannot decay by omission the way it did before.
                //
                // BladeWatch-rdtj.4: "loopback" alone is no longer the test -- the Pear pump reaches
                // this server from 127.0.0.1, and a remote peer must not skip the second factor.
                if (VehicleActionGate.requiresActionToken(path) &&
                    !AuthMiddleware.isLocalAppCaller(trust, client.inetAddress)
                ) {
                    val actionState = AuthManager.getState()
                    if (actionState == null ||
                        !VehicleActionToken.validate(
                            vehicleActionTokenHeader, actionState.deviceSecret
                        )
                    ) {
                        // Rejected and closing — do not advertise keep-alive.
                        out.isKeepAlive = false
                        HttpResponse.sendJsonForbidden(
                            out,
                            "Vehicle action token required — call " +
                                "VehicleService/IssueActionToken first"
                        )
                        client.close()
                        return
                    }
                }

                // The client identity for Connect's rate limiting (AuthService's login): the real
                // TCP peer's IP, as for /auth/ above.
                val connectClientIdentity = rateLimitIdentity(client)

                // Route to the modular handlers first
                if (routeToHandlers(
                        method, path, body, rangeHeader, ifNoneMatchHeader,
                        contentTypeHeader, connectVersionHeader, connectClientIdentity, out
                    )
                ) {
                    // Handled by a modular handler
                } else if (path.startsWith("/assets/") || path.startsWith("/vendor/")) {
                    // Angular SPA static assets (JS/CSS chunks produced by the Vite build).
                    var filePath = path.substring(1) // strip the leading slash
                    val q = filePath.indexOf('?')
                    if (q >= 0) filePath = filePath.substring(0, q)
                    if (!serveStaticFile(out, "angular/$filePath")) {
                        HttpResponse.sendError(out, 404, "Not Found: $path")
                    }
                } else if (path.startsWith("/manifest.json")) {
                    // PWA manifest + service worker (still used by installed PWA instances).
                    if (!serveStaticFile(out, "local/manifest.json")) {
                        HttpResponse.sendError(out, 404, "manifest.json not found")
                    }
                } else if (path.startsWith("/sw.js")) {
                    if (!serveStaticFile(out, "local/sw.js")) {
                        HttpResponse.sendError(out, 404, "sw.js not found")
                    }
                } else if (path == "/credits.json") {
                    if (!serveStaticFile(out, "local/credits.json")) {
                        HttpResponse.sendError(out, 404, "credits.json not found")
                    }
                } else if (path.startsWith("/i18n/")) {
                    // Catalog JSON: /i18n/en.json, /i18n/zh-CN.json, … 404s on unsupported tags so
                    // the runtime falls back to en. Strip ?query / #fragment so a cache-busting
                    // suffix like ?v=<build> still resolves to the file on disk.
                    var tag = path.substring(6)
                    val q = tag.indexOf('?')
                    if (q >= 0) tag = tag.substring(0, q)
                    val hsh = tag.indexOf('#')
                    if (hsh >= 0) tag = tag.substring(0, hsh)
                    val dot = tag.lastIndexOf('.')
                    val base = if (dot > 0) tag.substring(0, dot) else tag
                    if (!LocaleManager.isSupported(base)) {
                        HttpResponse.sendError(out, 404, "Unknown locale")
                    } else if (!serveStaticFile(out, "i18n/$tag")) {
                        HttpResponse.sendError(out, 404, "Catalog missing: $tag")
                    }
                } else if (path.startsWith("/shared/") || path.startsWith("/local/")) {
                    // Strip ?query and #fragment so cache-busting versions like ?v=12 resolve to
                    // the same file on disk.
                    var filePath = path.substring(1)
                    val q = filePath.indexOf('?')
                    if (q >= 0) filePath = filePath.substring(0, q)
                    val h = filePath.indexOf('#')
                    if (h >= 0) filePath = filePath.substring(0, h)
                    if (!serveStaticFile(out, filePath)) {
                        HttpResponse.sendError(out, 404, "Not Found: $path")
                    }
                }
                // BladeWatch-6mnq: /status, /api/start/{id}, /api/view/{id}, /api/stop/{id},
                // /api/stopall and /api/recording/mode were all handled inline here.
                // SystemService.GetStatus reads statusJson() directly now instead of capturing
                // this stream; recording mode is SettingsService.SetRecordingMode; and the camera
                // start/stop verbs had no first-party caller left — both UIs drive the camera
                // through StreamService.Enable/Disable and the daemon's own lifecycle.
                else if (path.startsWith("/h264/")) {
                    // Deprecated HTTP streaming
                    val response = JSONObject()
                    response.put(
                        "error", "HTTP streaming deprecated. Use WebSocket on port 8887"
                    )
                    response.put(
                        "wsUrl", "ws://" + client.localAddress.hostAddress + ":8887"
                    )
                    HttpResponse.sendJson(out, response.toString())
                } else if (path.startsWith("/view/")) {
                    // Legacy view page — redirect
                    HttpResponse.sendHtml(
                        out,
                        "<html><head><meta http-equiv='refresh' content='0;url=/'></head></html>"
                    )
                } else if (path.startsWith("/hero/")) {
                    // Three.js vehicle hero page — served directly, NOT caught by the SPA
                    // fallback. hero.html references ../shared/vendor/ (already served at
                    // /shared/).
                    var filePath = path.substring(1)
                    val q = filePath.indexOf('?')
                    if (q >= 0) filePath = filePath.substring(0, q)
                    if (!serveStaticFile(out, filePath)) {
                        HttpResponse.sendError(out, 404, "Not Found: $path")
                    }
                } else if (path == "/favicon.ico" || path == "/favicon.png" ||
                    path == "/favicon-32x32.png" || path == "/favicon-16x16.png" ||
                    path == "/apple-touch-icon.png"
                ) {
                    // Favicon / PWA icon files — must be served as files, not caught by the SPA
                    // fallback below. iOS fetches apple-touch-icon without cookies, so these paths
                    // are also whitelisted in AuthMiddleware's public set.
                    if (!serveStaticFile(out, "angular/" + path.substring(1))) {
                        HttpResponse.sendError(out, 404, "Not Found: $path")
                    }
                } else {
                    // Angular SPA fallback — serve index.html for all unrecognised paths so the
                    // Angular router can handle the route client-side.
                    if (!serveStaticFile(out, "angular/index.html")) {
                        HttpResponse.sendError(out, 404, "Not Found")
                    }
                }

                // ---- BladeWatch-67h8: one request served; decide whether to read another ----
                // The flush is load-bearing. Previously the close in `finally` flushed the
                // BufferedOutputStream for any handler that forgot to; holding the socket open
                // removes that safety net, and an unflushed response is a client that hangs.
                out.flush()
                if (!keepAlive) break
            } // end of the per-request loop
        } catch (e: SocketTimeoutException) {
            // Between requests this is ordinary keep-alive idle expiry — the peer simply stopped
            // asking — and logging it would make every reused connection an error. MID-REQUEST it
            // is a genuine fault (a truncated body, a client that stalled) and swallowing it would
            // hide the one case worth seeing. Note that reading a body whose Content-Length counts
            // BYTES with a char-oriented BufferedReader times out here on any non-ASCII body; that
            // predates keep-alive, but this is where it now surfaces, so it must stay visible.
            if (!betweenRequests) {
                CameraDaemon.log("HTTP error: read timed out mid-request: " + e.message)
            }
        } catch (e: Exception) {
            CameraDaemon.log("HTTP error: " + e.message)
        } finally {
            if (!socketHandedOff) {
                try {
                    client.close()
                } catch (e: Exception) {
                    CameraDaemon.log("WARN: HTTP client.close() failed: " + e.message)
                }
            }
        }
    }

    /**
     * Routes requests to the modular API handlers.
     *
     * @return true if handled by a handler
     */
    @Throws(Exception::class)
    private fun routeToHandlers(
        method: String,
        path: String,
        body: String?,
        rangeHeader: String?,
        ifNoneMatchHeader: String?,
        contentTypeHeader: String?,
        connectVersionHeader: String?,
        clientIdentity: String?,
        out: OutputStream
    ): Boolean {
        // Connect protocol — routes /bladewatch.v1.ServiceName/Method to the registered service
        // impls. Auth middleware already ran before this call, so no extra JWT check is needed.
        if (path.startsWith("/bladewatch.v1.")) {
            connectDispatcher.dispatch(
                method, path, body, contentTypeHeader, connectVersionHeader, clientIdentity, out
            )
            return true
        }

        // BladeWatch-6mnq: ConnectRPC is the only JSON API surface. Every /api/ JSON route that
        // used to be matched here is now a method under /bladewatch.v1., dispatched above. What
        // remains is deliberately NOT a JSON API — a browser fetches these by URL and cannot speak
        // Connect:
        //
        //   /video/        a player's byte-range requests (Range header, 206 responses)
        //   /thumb/        <img src>, additionally auth'd by a signed ?t= token
        //   /api/stream    MJPEG and still frames, also consumed as image URLs
        //
        // Do not reintroduce a JSON route here. Two surfaces over one implementation is how they
        // drift: GetSohNominal reported a hardcoded "unset" while the capacity was demonstrably
        // known, and a hand-rolled shell-failure check survived in ServiceLauncher long after
        // BladeWatch-boat replaced it elsewhere.
        if (path.startsWith("/video/") || path.startsWith("/thumb/")) {
            return RecordingsApiHandler.handleWithRange(
                method, path, body, rangeHeader, ifNoneMatchHeader, out
            )
        }

        if (path.startsWith("/api/stream")) {
            return StreamingApiHandler.handle(method, path, body, out)
        }

        return false
    }

    /**
     * The daemon status object, for `SystemService.GetStatus` (BladeWatch-6mnq).
     *
     * This used to write itself into an OutputStream that the Connect layer captured back out; it
     * returns the object now. There is no longer an HTTP /status route — the SPA and the Flutter
     * UI both call the RPC.
     */
    @Throws(Exception::class)
    fun statusJson(): JSONObject {
        val status = JSONObject()
        status.put("status", "ok")
        status.put("deviceId", CameraDaemon.getDeviceId())

        // Vehicle-data readiness, surfaced explicitly so the web UI can render a "waiting for
        // vehicle…" state instead of silently leaving every field blank when the BYD binders
        // haven't bound yet (cold-boot race — HTTP comes up well before BydDataCollector finishes
        // ~15 binder lookups). On first hit, give the collector a short window to come online;
        // this resolves the most common "tunnel loads, no data" report without forcing the client
        // to retry.
        status.put("vehicleDataReady", waitForVehicleDataReady(1500))

        // App version straight from the build. The in-app updater that used to write a release
        // string to /data/local/tmp/bladewatch_version has been removed, so the APK's own
        // versionName is now the only truth there is.
        status.put("appVersion", BuildConfig.VERSION_NAME)
        status.put("recording", TcpCommandServer.getRecordingCameras())
        status.put("viewing", TcpCommandServer.getViewOnlyCameras())
        status.put("active", TcpCommandServer.getActiveCameras())
        status.put("available", TcpCommandServer.getAvailableCameras())
        status.put("battery", BatteryMonitor.getBatteryInfo())
        status.put("acc", AccMonitor.isAccOn())

        // Safe zone status (so the UI can show the suppressed state)
        val safeMgr = SafeLocationManager.getInstance()
        status.put("safeZoneSuppressed", CameraDaemon.isSafeZoneSuppressed())
        status.put("inSafeZone", safeMgr.isInSafeZone)
        if (safeMgr.currentZoneName != null) {
            status.put("safeZoneName", safeMgr.currentZoneName)
        }

        // Vehicle data (charging state and power). Each subsection is wrapped individually — one
        // BYD HAL throwing RemoteException must not zero out unrelated fields. Any failure here is
        // logged so customers reporting "blank data" produce evidence we can act on, instead of
        // silent emptiness.
        try {
            val vehicleMonitor = VehicleDataMonitor.getInstance()

            val chargingState = vehicleMonitor.getChargingState()
            if (chargingState != null) {
                val charging = JSONObject()
                charging.put("stateName", chargingState.stateName)
                charging.put("status", chargingState.status.name)
                charging.put("chargingPowerKW", chargingState.chargingPowerKW)
                charging.put("isDischarging", chargingState.isDischarging)
                charging.put("isError", chargingState.isError)
                // Surface the "estimated from SOC rate" flag so the UI can show a "~" prefix on
                // the kW value.
                charging.put("isEstimated", chargingState.isEstimated)
                status.put("charging", charging)
            }

            val socData = vehicleMonitor.getBatterySoc()
            if (socData != null) {
                val soc = JSONObject()
                soc.put("percent", socData.socPercent)
                soc.put("isLow", socData.isLow)
                soc.put("isCritical", socData.isCritical)
                soc.put("status", socData.getStatus())
                status.put("soc", soc)
            }

            val rangeData = vehicleMonitor.getDrivingRange()
            if (rangeData != null) {
                val range = JSONObject()
                range.put("elecRangeKm", rangeData.elecRangeKm)
                range.put("fuelRangeKm", rangeData.fuelRangeKm)
                range.put("totalRangeKm", rangeData.totalRangeKm)
                range.put("isLow", rangeData.isLow)
                range.put("isCritical", rangeData.isCritical)
                range.put("status", rangeData.getStatus())
                // Only emit fuelPercent for PHEVs — BEVs leave fuelPercent NaN upstream
                // (BydDataCollector gates on nominal capacity < 30 kWh), so the web UI's
                // `if (fuelPct > 0)` guard hides the fuel card.
                if (rangeData.hasFuelPercent()) {
                    range.put("fuelPercent", rangeData.fuelPercent)
                }
                status.put("range", range)
            }

            // Distance unit preference — "km" or "mi". Derived from the user setting
            // (TripConfig.distanceUnit), which overrides auto-detection. The web UI uses this to
            // convert km values for display and pick the right label.
            try {
                val collector = BydDataCollector.getInstance()
                status.put("distanceUnit", if (collector?.isMilesMode == true) "mi" else "km")
            } catch (e: Exception) {
                CameraDaemon.log("DEBUG: distanceUnit probe failed: " + e.message)
                status.put("distanceUnit", "km")
            }

            // Active UI locale — exposed so a client can sync its i18n state with changes made
            // elsewhere (the Android settings drawer, another logged-in client). Always one of
            // LocaleManager.SUPPORTED.
            try {
                status.put("locale", LocaleManager.get())
            } catch (e: Exception) {
                CameraDaemon.log("DEBUG: locale probe failed: " + e.message)
                status.put("locale", "en")
            }
        } catch (e: Exception) {
            // Vehicle data not available — surface the cause so a customer report includes the
            // proximate failure (binder gone, SDK class missing, etc.) rather than just "page is
            // blank".
            CameraDaemon.log("status: vehicle data block failed: $e")
            status.put("vehicleDataError", e.javaClass.simpleName + ": " + e.message)
        }
        try {
            val soh = JSONObject()
            var hasSoh = false

            // Read the SOH percent from the persisted battery-health estimate file.
            val sohFile = File("/data/local/tmp/abrp_soh_estimate.properties")
            if (sohFile.exists()) {
                val props = Properties()
                FileInputStream(sohFile).use { fis -> props.load(fis) }
                val sohStr = props.getProperty("soh_percent")
                if (sohStr != null) {
                    val sohVal = sohStr.toDouble()
                    // Reject out-of-range values (e.g. 101 from bogus BMS sentinels)
                    if (sohVal > 0 && sohVal <= 100) {
                        soh.put("percent", (sohVal * 10).roundToLong() / 10.0)
                        hasSoh = true
                    }
                }
            }

            if (hasSoh) status.put("soh", soh)
        } catch (e: Exception) {
            CameraDaemon.log("DEBUG: SOH read failed: " + e.message)
        }

        // GPU surveillance status — only true when actually in sentry/surveillance mode, not when
        // the pipeline is running for normal recording (CONTINUOUS, PROXIMITY_GUARD)
        val pipeline = CameraDaemon.getGpuPipeline()
        status.put("gpuSurveillance", pipeline != null && pipeline.isSurveillanceMode)

        // Recording mode details (for the status overlay)
        try {
            val recordingStatus = JSONObject()
            val rmm = CameraDaemon.getRecordingModeManager()
            if (rmm != null) {
                recordingStatus.put("configuredMode", rmm.currentMode.name)
                recordingStatus.put("isRecording", pipeline != null && pipeline.isRecording)
                recordingStatus.put("pipelineRunning", pipeline != null && pipeline.isRunning)
                recordingStatus.put(
                    "gear", RecordingModeManager.gearToString(rmm.currentGear)
                )
                recordingStatus.put("accOn", rmm.isAccOn)
            } else {
                recordingStatus.put("configuredMode", "UNKNOWN")
                recordingStatus.put("isRecording", false)
                recordingStatus.put("pipelineRunning", false)
            }
            status.put("recordingStatus", recordingStatus)
        } catch (e: Exception) {
            // Recording status not available
        }

        // Trip analytics status (for the status overlay)
        try {
            val tripStatus = JSONObject()
            val tam = CameraDaemon.getTripAnalyticsManager()
            if (tam != null) {
                tripStatus.put("enabled", tam.isEnabled())
                tripStatus.put("tripActive", tam.isTripActive())
                val activeTrip = tam.getActiveTrip()
                if (activeTrip != null) {
                    tripStatus.put("tripStartTime", activeTrip.startTime)
                    tripStatus.put(
                        "tripDurationSec",
                        (System.currentTimeMillis() - activeTrip.startTime) / 1000
                    )
                }
            } else {
                tripStatus.put("enabled", false)
                tripStatus.put("tripActive", false)
            }
            status.put("tripStatus", tripStatus)
        } catch (e: Exception) {
            // Trip status not available
        }

        // GPS location
        status.put("gps", GpsMonitor.getInstance().getLocationJson())

        // Network info (WiFi SSID + IP or mobile data)
        val network = NetworkMonitor.getNetworkInfo()
        val dataUsage = NetworkMonitor.getDataUsageInfo()
        network.put("thisMonthBytes", dataUsage.optLong("thisMonthBytes", 0L))
        network.put("lastMonthBytes", dataUsage.optLong("lastMonthBytes", 0L))
        // The owner's opt-in for LAN access, which is now TLS on its own port; plain HTTP never
        // binds beyond loopback (BladeWatch-rdtj.4), so the old "LAN HTTP is unsafe" warning and
        // a 0.0.0.0 httpBind no longer exist.
        val lanEnabled = UnifiedConfigManager.isLanHttpEnabled()
        network.put("lanHttpEnabled", lanEnabled)
        network.put("httpBind", "127.0.0.1")
        network.put(
            "lanTls",
            JSONObject().put("enabled", lanEnabled).put("port", LanTls.PORT)
                .put("listening", lanTlsSocket?.isClosed == false)
        )
        status.put("network", network)

        return status
    }

    /**
     * Block briefly until BydDataCollector reports initialized, so the very first status request
     * after boot doesn't return a shell with every vehicle field omitted. The collector typically
     * finishes inside ~600 ms but cold-boot binders can stretch beyond a second; we cap the wait so
     * a permanently-broken collector still returns a response.
     *
     * @return true if the collector is initialized when this returns, false if the wait timed out
     *   (the caller still emits status, just with the vehicle fields absent and
     *   vehicleDataReady=false).
     */
    private fun waitForVehicleDataReady(maxWaitMs: Long): Boolean {
        return try {
            val collector = BydDataCollector.getInstance()
            if (collector.isInitialized) {
                return true
            }
            val deadline = System.currentTimeMillis() + maxWaitMs
            while (System.currentTimeMillis() < deadline) {
                Thread.sleep(50)
                if (collector.isInitialized) {
                    return true
                }
            }
            false
        } catch (ie: InterruptedException) {
            Thread.currentThread().interrupt()
            false
        } catch (e: Exception) {
            false
        }
    }

    /** Serves static files from WEB_ROOT, streaming large files in 16KB chunks. */
    private fun serveStaticFile(out: OutputStream, relativePath: String): Boolean {
        if (relativePath.contains("..")) {
            return false
        }

        var file = File(WEB_ROOT, relativePath)
        if (!file.exists() || !file.isFile) {
            // Fall back to the persistent models cache for GLBs that were downloaded at runtime.
            // All shipped models live in WEB_ROOT (bundled in the APK assets); any future
            // downloadable models are fetched on demand into ModelsApiHandler.MODELS_DIR.
            if (relativePath.startsWith("shared/models/") && relativePath.endsWith(".glb")) {
                val cached = ModelsApiHandler.cachedModelFile(
                    relativePath.substring("shared/models/".length)
                ) ?: return false
                file = cached
            } else {
                return false
            }
        }

        return try {
            FileInputStream(file).use { fis ->
                val contentType = getContentType(relativePath)

                // HTML pages must always revalidate so the user gets the latest UI logic. The
                // service worker and PWA manifest also need to bypass cache — a stuck-cached SW
                // means the user can't pick up notification fixes without a manual unregister.
                //
                // i18n catalogs (/i18n/<lang>.json) MUST also bypass cache: unlike the Angular
                // JS/CSS bundle — whose filenames are content-hashed and so cache-bust
                // automatically on every build — the catalog URLs are static and unhashed. A new
                // app build ships new template keys, but a browser holding a day-old cached
                // catalog won't have them, so the UI renders raw keys ("dashboard.this_week")
                // until the cache expires. Revalidating guarantees catalogs refresh immediately on
                // every reinstall/update.
                //
                // Other shared static assets (JS/CSS/fonts/images) ship inside the APK and never
                // change without an app update, so we let the browser cache them to avoid
                // re-downloading ~360KB on every page load.
                val fileName = File(relativePath).name
                val isCatalog = relativePath.startsWith("i18n/") ||
                    relativePath.startsWith("server-i18n/")
                val cacheControl = if (relativePath.endsWith(".html") ||
                    fileName == "sw.js" || fileName == "manifest.json" || isCatalog
                ) {
                    "no-store, no-cache, must-revalidate, max-age=0"
                } else {
                    "public, max-age=86400"
                }

                val headers = StringBuilder()
                headers.append("HTTP/1.1 200 OK\r\n")
                    .append("Content-Type: ").append(contentType).append("\r\n")
                    .append("Content-Length: ").append(file.length()).append("\r\n")
                    .append("Cache-Control: ").append(cacheControl).append("\r\n")
                if (relativePath.endsWith(".html")) {
                    headers.append("Pragma: no-cache\r\n").append("Expires: 0\r\n")
                }
                headers.append(HttpResponse.connectionHeader(out)).append("\r\n")
                out.write(headers.toString().toByteArray())

                // Stream in 16KB chunks
                val buffer = ByteArray(16384)
                while (true) {
                    val count = fis.read(buffer)
                    if (count == -1) break
                    out.write(buffer, 0, count)
                }
                out.flush()

                CameraDaemon.log(
                    "Served static: " + relativePath + " (" + file.length() + " bytes)"
                )
                true
            }
        } catch (e: Exception) {
            CameraDaemon.log("Static file error: " + relativePath + " - " + e.message)
            false
        }
    }

    private fun getContentType(path: String): String = when {
        path.endsWith(".html") -> "text/html; charset=utf-8"
        path.endsWith(".css") -> "text/css; charset=utf-8"
        path.endsWith(".js") -> "application/javascript; charset=utf-8"
        path.endsWith(".json") -> "application/json"
        path.endsWith(".wasm") -> "application/wasm"
        path.endsWith(".png") -> "image/png"
        path.endsWith(".jpg") || path.endsWith(".jpeg") -> "image/jpeg"
        path.endsWith(".webp") -> "image/webp"
        path.endsWith(".svg") -> "image/svg+xml"
        path.endsWith(".ico") -> "image/x-icon"
        path.endsWith(".glb") -> "model/gltf-binary"
        path.endsWith(".gltf") -> "model/gltf+json"
        else -> "application/octet-stream"
    }

    // ==================== WEBSOCKET STREAMING ====================

    /**
     * Complete the WebSocket handshake and hand the socket to the streaming pool.
     *
     * @return true if ownership of [client] passed to [streamPool], meaning the caller must NOT
     *   close it. False if the handshake failed and the socket is still the caller's to close.
     */
    private fun handleWebSocketUpgrade(client: Socket, websocketKey: String): Boolean {
        try {
            CameraDaemon.log("WebSocket upgrade requested")

            val acceptKey = computeWebSocketAccept(websocketKey)

            val out = client.getOutputStream()
            val response = "HTTP/1.1 101 Switching Protocols\r\n" +
                "Upgrade: websocket\r\n" +
                "Connection: Upgrade\r\n" +
                "Sec-WebSocket-Accept: " + acceptKey + "\r\n\r\n"
            out.write(response.toByteArray())
            out.flush()

            CameraDaemon.log("WebSocket handshake complete")
            // Hand off to the streaming pool and let this REQUEST thread go. The handshake is
            // done, so nothing above needs the socket any more, and streaming it here would hold a
            // request worker for the entire session (BladeWatch-sxzg).
            //
            // The socket is deliberately NOT closed on the way out: it now belongs to the stream,
            // which closes it when the viewer goes away.
            streamPool.execute { streamH264ToWebSocket(client) }
            return true
        } catch (e: Exception) {
            CameraDaemon.log("WebSocket upgrade error: " + e.message)
        }
        // Handshake failed: the socket never reached the stream, so the caller still owns it.
        return false
    }

    @Throws(Exception::class)
    private fun computeWebSocketAccept(key: String): String {
        val sha1 = MessageDigest.getInstance("SHA-1")
        val hash = sha1.digest((key + WS_MAGIC).toByteArray(StandardCharsets.UTF_8))
        return Base64.encodeToString(hash, Base64.NO_WRAP)
    }

    /**
     * Streams H.264 frames over WebSocket with a zero-restart attach.
     *
     * Instead of force-restarting the encoder on every client connect (which causes a 700ms gap
     * and corrupt first frames), we:
     *  1. reuse the existing encoder if streaming is already enabled,
     *  2. request an IDR keyframe via MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME,
     *  3. send the cached SPS/PPS immediately so the decoder can initialise,
     *  4. wait for the IDR to arrive before sending P-frames.
     *
     * That gives an instant stream start with no encoder restart, no frame corruption, and no
     * broken pipe from the client timing out during a restart.
     */
    private fun streamH264ToWebSocket(client: Socket) {
        CameraDaemon.log("Starting H.264 WebSocket stream")

        val frameQueue = ArrayBlockingQueue<ByteArray>(60)
        val running = booleanArrayOf(true)

        try {
            client.soTimeout = 0
            client.tcpNoDelay = true
            client.sendBufferSize = 256 * 1024
            val out = BufferedOutputStream(client.getOutputStream(), 128 * 1024)

            val pipeline = CameraDaemon.getGpuPipeline()
            if (pipeline == null) {
                CameraDaemon.log("WS: Pipeline not available")
                sendWebSocketClose(out, 1011, "Pipeline not available")
                return
            }

            // Auto-start the pipeline if needed
            if (!pipeline.isRunning) {
                CameraDaemon.log("WS: Auto-starting pipeline")
                pipeline.start()
                Thread.sleep(500)
            }

            val q = GpuPipelineConfig.StreamingQuality.fromString(
                StreamingApiHandler.getStreamingQuality()
            )

            var savedViewMode = pipeline.streamViewMode
            if (savedViewMode < 0) savedViewMode = 0

            // Reuse the existing encoder if streaming is already enabled at the same quality.
            // Only restart if not enabled or the quality changed.
            var needsRestart = !pipeline.isStreamingEnabled

            // A quality change needs a restart for the new resolution
            if (!needsRestart && pipeline.isStreamingEnabled) {
                if (pipeline.streamEncoder != null) {
                    val scaler = pipeline.streamScaler
                    if (scaler != null) {
                        val currentWidth = scaler.width
                        val currentHeight = scaler.height
                        if (currentWidth != q.width || currentHeight != q.height) {
                            CameraDaemon.log(
                                "WS: Quality changed (" + currentWidth + "x" + currentHeight +
                                    " → " + q.width + "x" + q.height + ") — restarting encoder"
                            )
                            needsRestart = true
                            pipeline.disableStreaming()
                            Thread.sleep(200)
                        }
                    }
                }
            }

            if (needsRestart) {
                CameraDaemon.log("WS: Enabling streaming - " + q.displayName)
                pipeline.enableStreaming(q.width, q.height, q.fps, q.bitrate)
                Thread.sleep(500)
            } else {
                CameraDaemon.log("WS: Reusing existing stream encoder (no restart)")
            }

            if (savedViewMode > 0) {
                pipeline.streamViewMode = savedViewMode
                CameraDaemon.log("WS: View mode $savedViewMode")
            }

            val encoder = pipeline.streamEncoder
            if (encoder == null) {
                CameraDaemon.log("WS: Stream encoder not available")
                sendWebSocketClose(out, 1011, "Encoder not available")
                return
            }

            // Send the cached SPS/PPS immediately from WebSocketStreamServer so the client decoder
            // can initialise before the first frame arrives.
            val wsServer = pipeline.webSocketServer
            var spsPpsSent = false
            if (wsServer != null) {
                val cachedSpsPps = wsServer.cachedSpsPps
                if (cachedSpsPps != null && cachedSpsPps.isNotEmpty()) {
                    try {
                        sendWebSocketBinaryFrame(out, cachedSpsPps)
                        spsPpsSent = true
                        CameraDaemon.log(
                            "WS: Sent cached SPS/PPS (" + cachedSpsPps.size + " bytes)"
                        )
                    } catch (e: Exception) {
                        CameraDaemon.log("WS: Failed to send cached SPS/PPS: " + e.message)
                    }
                }
            }

            // Request an IDR keyframe so the client gets a clean decode start. This is instant —
            // no encoder restart needed.
            encoder.requestSyncFrame()
            CameraDaemon.log("WS: IDR keyframe requested")

            // Also request an SPS/PPS re-send if we didn't have cached ones
            if (!spsPpsSent) {
                // The encoder will send SPS/PPS before the next IDR via the callback
                CameraDaemon.log("WS: Waiting for SPS/PPS from encoder")
            }

            // Stream callback with congestion control
            val gotKeyframe = booleanArrayOf(spsPpsSent) // skip waiting if SPS/PPS already sent
            val callback = object : HardwareEventRecorderGpu.StreamCallback {
                override fun onSpsPps(sps: ByteBuffer, pps: ByteBuffer) {
                    val spsSize = sps.remaining()
                    val ppsSize = pps.remaining()
                    val combined = ByteArray(spsSize + ppsSize)
                    sps.get(combined, 0, spsSize)
                    pps.get(combined, spsSize, ppsSize)
                    frameQueue.offer(combined)
                    gotKeyframe[0] = true
                    CameraDaemon.log("WS: Queued SPS/PPS (" + combined.size + " bytes)")
                }

                override fun onH264Packet(data: ByteBuffer, info: MediaCodec.BufferInfo) {
                    // Drop P-frames until we've sent SPS/PPS + IDR: sending P-frames before the
                    // decoder has SPS/PPS causes a decode failure.
                    if (!gotKeyframe[0]) {
                        val isKeyframe =
                            (info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0
                        if (!isKeyframe) return // drop P-frames before the first keyframe
                        gotKeyframe[0] = true
                    }

                    if (frameQueue.remainingCapacity() > 0) {
                        val frame = ByteArray(info.size)
                        data.position(info.offset)
                        data.get(frame)
                        frameQueue.offer(frame)
                    }
                    // If the queue is full, drop the frame (congestion control)
                }
            }

            encoder.setStreamCallback(callback)
            CameraDaemon.log("WS: Stream callback registered")

            wsServer?.registerExternalClient()

            var lastFrameTime = System.currentTimeMillis()
            var frameCount = 0

            try {
                while (running[0] && !client.isClosed) {
                    val frame = frameQueue.poll(5, TimeUnit.SECONDS)

                    if (frame != null) {
                        try {
                            // Log the first few frames for debugging
                            if (frameCount < 5) {
                                CameraDaemon.log(
                                    "WS: Frame " + frameCount + " size=" + frame.size + " bytes"
                                )
                            }
                            sendWebSocketBinaryFrame(out, frame)
                            lastFrameTime = System.currentTimeMillis()
                            frameCount++

                            if (frameCount % 300 == 0) {
                                CameraDaemon.log("WS: Sent $frameCount frames")
                            }
                        } catch (e: SocketException) {
                            CameraDaemon.log("WS: Client disconnected (" + e.message + ")")
                            break
                        } catch (e: IOException) {
                            CameraDaemon.log("WS: Write error (" + e.message + ")")
                            break
                        }
                    } else {
                        // No frame for 5 seconds — send a ping to keep alive
                        try {
                            out.write(byteArrayOf(0x89.toByte(), 0x00))
                            out.flush()
                        } catch (e: Exception) {
                            CameraDaemon.log("WS: Ping failed, client gone")
                            break
                        }

                        if (System.currentTimeMillis() - lastFrameTime > 60000) {
                            CameraDaemon.log("WS: Idle timeout (60s) - closing")
                            break
                        }
                    }
                }
            } finally {
                wsServer?.unregisterExternalClient()
            }

            encoder.clearStreamCallback()
            CameraDaemon.log("WS: Stream ended ($frameCount frames sent)")
        } catch (e: Exception) {
            CameraDaemon.log("WS stream error: " + e.message)
        } finally {
            try {
                client.close()
            } catch (e: Exception) {
                // The viewer is gone; nothing useful to do.
            }
        }
    }

    /**
     * Send binary data as WebSocket frame(s), fragmenting large frames. Frames larger than
     * [MAX_WS_FRAME_SIZE] are split into continuation frames to prevent TCP buffer overflow on
     * constrained networks (the BYD WiFi AP).
     */
    @Throws(Exception::class)
    private fun sendWebSocketBinaryFrame(out: OutputStream, data: ByteArray) {
        if (data.size <= MAX_WS_FRAME_SIZE) {
            // Small frame — send as a single message
            sendWebSocketRawFrame(out, data, 0, data.size, 0x82, true)
        } else {
            // Large frame — fragment into continuation frames
            var offset = 0
            var first = true
            while (offset < data.size) {
                val chunkSize = min(MAX_WS_FRAME_SIZE, data.size - offset)
                val last = offset + chunkSize >= data.size
                // binary for the first, continuation for the rest
                val opcode = if (first) 0x02 else 0x00
                sendWebSocketRawFrame(out, data, offset, chunkSize, opcode, last)
                offset += chunkSize
                first = false
            }
        }
        out.flush()
    }

    @Throws(Exception::class)
    private fun sendWebSocketRawFrame(
        out: OutputStream,
        data: ByteArray,
        offset: Int,
        len: Int,
        opcode: Int,
        fin: Boolean
    ) {
        out.write((if (fin) 0x80 else 0x00) or opcode)

        if (len <= 125) {
            out.write(len)
        } else if (len <= 65535) {
            out.write(126)
            out.write((len shr 8) and 0xFF)
            out.write(len and 0xFF)
        } else {
            out.write(127)
            for (i in 7 downTo 0) {
                out.write((len shr (8 * i)) and 0xFF)
            }
        }

        out.write(data, offset, len)
    }

    private fun sendWebSocketClose(out: OutputStream, code: Int, reason: String) {
        try {
            val reasonBytes = reason.toByteArray(StandardCharsets.UTF_8)

            out.write(0x88) // FIN + close opcode
            out.write(2 + reasonBytes.size)
            out.write((code shr 8) and 0xFF)
            out.write(code and 0xFF)
            out.write(reasonBytes)
            out.flush()
        } catch (e: Exception) {
            // The peer is already gone; nothing to report.
        }
    }

    companion object {

        private const val WEB_ROOT = "/data/local/tmp/web"

        /**
         * Read timeout, applied to the first request and to the idle wait between keep-alive
         * requests (BladeWatch-67h8). Long enough not to punish a slow Tor round trip, short
         * enough that an abandoned socket is reclaimed rather than held by a daemon that runs for
         * weeks.
         */
        private const val SOCKET_TIMEOUT_MS = 15000

        /** How often the LAN TLS listener re-reads the owner's opt-in (see runLanTlsListener). */
        private const val LAN_TLS_RECHECK_MS = 5000

        /** See [runRemoteLoopbackListener]. TorLauncher points here, never at 8080. */
        const val REMOTE_LOOPBACK_PORT = 8081

        /** See [runPearTlsListener]. PearStreamPump points here. */
        const val PEAR_TLS_PORT = 8444

        private const val WS_MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

        /** 32KB per WebSocket frame. */
        private const val MAX_WS_FRAME_SIZE = 32768

        /**
         * Turn a Latin-1-read request body back into text (BladeWatch-ou7y).
         *
         * The request reader decodes as ISO-8859-1 so that one char is exactly one byte and
         * Content-Length — which counts bytes — can be satisfied exactly. That makes [chars] a byte
         * buffer wearing a CharArray costume: each element holds one byte in its low 8 bits.
         * Narrowing them back to bytes and decoding as UTF-8 recovers the text the client actually
         * sent.
         *
         * Public rather than module-internal so RequestBodyDecodingTest, which is Java, can
         * exercise it directly; the surrounding socket plumbing is not unit-testable.
         */
        @JvmStatic
        fun decodeRequestBody(chars: CharArray, length: Int): String {
            val bytes = ByteArray(length)
            for (i in 0 until length) {
                bytes[i] = chars[i].code.toByte()
            }
            return String(bytes, StandardCharsets.UTF_8)
        }

        /** Extracts the web assets from the APK to the filesystem. */
        @JvmStatic
        fun extractWebAssets(assetManager: AssetManager?) {
            if (assetManager == null) {
                CameraDaemon.log("AssetManager is null, skipping web asset extraction")
                return
            }

            try {
                val webRoot = File(WEB_ROOT)

                // Always delete and recreate to ensure fresh files on app update
                if (webRoot.exists()) {
                    deleteRecursive(webRoot)
                    CameraDaemon.log("Deleted existing web assets for fresh extraction")
                }
                webRoot.mkdirs()

                // Extract web/local and web/shared directories
                extractAssetDir(assetManager, "web/local", File(WEB_ROOT, "local"))
                extractAssetDir(assetManager, "web/shared", File(WEB_ROOT, "shared"))
                // Angular SPA build output.
                extractAssetDir(assetManager, "web/angular", File(WEB_ROOT, "angular"))
                // three.js hero page (vehicle 3D hero, served at /hero/).
                extractAssetDir(assetManager, "web/hero", File(WEB_ROOT, "hero"))
                // i18n catalogs (one JSON per supported locale). The web/i18n directory is created
                // by the NLLB translation pipeline — at minimum web/i18n/en.json must exist for
                // the runtime to load.
                extractAssetDir(assetManager, "web/i18n", File(WEB_ROOT, "i18n"))
                // Server-side i18n catalogs (the Messages lookup source). Kept distinct from
                // web/i18n so the HTTP /i18n/ route doesn't accidentally expose internal error
                // keys, and the two catalogs can diverge if needed.
                extractAssetDir(assetManager, "server-i18n", File(WEB_ROOT, "server-i18n"))

                // Overlay icons for the telemetry overlay
                extractAssetDir(assetManager, "overlay", File("/data/local/tmp/overlay"))

                CameraDaemon.log("Web assets extracted to $WEB_ROOT")
            } catch (e: Exception) {
                CameraDaemon.log("Failed to extract web assets: " + e.message)
            }
        }

        private fun deleteRecursive(file: File) {
            if (file.isDirectory) {
                file.listFiles()?.forEach { deleteRecursive(it) }
            }
            file.delete()
        }

        @Throws(Exception::class)
        private fun extractAssetDir(
            assetManager: AssetManager,
            assetPath: String,
            destDir: File
        ) {
            if (!destDir.exists()) {
                destDir.mkdirs()
            }

            val files = assetManager.list(assetPath)
            if (files == null || files.isEmpty()) {
                CameraDaemon.log("No files found in assets/$assetPath")
                return
            }

            for (fileName in files) {
                val assetFilePath = "$assetPath/$fileName"
                val destFile = File(destDir, fileName)

                val subFiles = assetManager.list(assetFilePath)
                if (subFiles != null && subFiles.isNotEmpty()) {
                    extractAssetDir(assetManager, assetFilePath, destFile)
                } else {
                    assetManager.open(assetFilePath).use { input ->
                        FileOutputStream(destFile).use { output ->
                            val buffer = ByteArray(4096)
                            while (true) {
                                val read = input.read(buffer)
                                if (read == -1) break
                                output.write(buffer, 0, read)
                            }
                        }
                    }
                    CameraDaemon.log(
                        "Extracted: " + assetFilePath + " -> " + destFile.absolutePath
                    )
                }
            }
        }

        // ============ STATIC ACCESSORS (for backward compatibility) ============

        /** Loads persisted settings. Delegates to QualitySettingsApiHandler. */
        @JvmStatic
        fun loadPersistedSettings() {
            QualitySettingsApiHandler.loadPersistedSettings()
        }

        // Getters delegate to the handlers
        @JvmStatic
        fun getRecordingQuality(): String = QualitySettingsApiHandler.getRecordingQuality()

        @JvmStatic
        fun getStreamingQuality(): String = StreamingApiHandler.getStreamingQuality()

        @JvmStatic
        fun getRecordingBitrate(): String = QualitySettingsApiHandler.getRecordingBitrate()

        @JvmStatic
        fun getRecordingCodec(): String = QualitySettingsApiHandler.getRecordingCodec()

        // Setters delegate to the handlers
        @JvmStatic
        fun setRecordingQuality(quality: String?) {
            QualitySettingsApiHandler.setRecordingQuality(quality)
        }

        @JvmStatic
        fun setStreamingQuality(quality: String?) {
            StreamingApiHandler.setStreamingQuality(quality)
        }

        /**
         * Legacy API surface kept for old web/IPC clients. Converts here so callers land on the
         * canonical recording-quality implementation.
         */
        @JvmStatic
        fun setRecordingBitrate(bitrate: String?) {
            QualitySettingsApiHandler.setRecordingQuality(legacyBitrateToQuality(bitrate))
        }

        @JvmStatic
        fun setRecordingCodec(codec: String) {
            QualitySettingsApiHandler.setRecordingCodec(codec)
        }

        // Static setters for the IPC server
        @JvmStatic
        fun setRecordingBitrateStatic(bitrate: String?) {
            QualitySettingsApiHandler.setRecordingBitrateStatic(bitrate)
        }

        @JvmStatic
        fun setRecordingCodecStatic(codec: String) {
            QualitySettingsApiHandler.setRecordingCodecStatic(codec)
        }

        @JvmStatic
        fun persistSettingsStatic() {
            QualitySettingsApiHandler.persistSettings()
        }

        private fun legacyBitrateToQuality(bitrate: String?): String = when (
            bitrate?.uppercase(Locale.ROOT)
        ) {
            "LOW" -> "ECONOMY"
            "HIGH" -> "HIGH"
            else -> "STANDARD"
        }
    }
}
