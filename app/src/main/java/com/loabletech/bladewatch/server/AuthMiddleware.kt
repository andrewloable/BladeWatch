package net.bladewatch.app.server

import net.bladewatch.app.BuildConfig
import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.daemon.CameraDaemon
import java.io.OutputStream
import java.net.SocketAddress
import java.net.URLDecoder
import java.net.URLEncoder

/**
 * Authentication middleware for HttpServer.
 *
 * Two-tier authentication:
 *  - Tier 1 — JWT (cookie or `Authorization: Bearer`): primary, all callers should use this.
 *  - Tier 2 — loopback safety net: requests originating from 127.0.0.1 are trusted only in debug
 *    builds, and only when the request carries no tunnel-fingerprint headers (X-Forwarded-*, Cf-*,
 *    X-Real-Ip, Forwarded). Release builds require a JWT for every protected route because Android
 *    loopback is shared by all apps.
 *
 * Public paths (no auth required at all): /auth/token, /auth/logout, /login.html, /login,
 * /shared/ assets, /favicon.ico.
 *
 * Notably NOT public: /status, which leaks ACC/charging/recording state.
 *
 * /auth/status is still public but only returns deviceId for loopback callers. Tunnel/LAN callers
 * receive status:ok with no deviceId, to prevent brute-force aid.
 */
/**
 * Which HttpServer listener a request arrived on -- and therefore whether a loopback source address
 * means anything (BladeWatch-rdtj.4).
 *
 * Loopback is not a trustworthy signal on its own. The Pear stream pump delivers remote traffic from
 * 127.0.0.1 (as the removed tor onion service did): at the socket level that is indistinguishable
 * from an app on the head unit. So trust is a property of the LISTENER, declared where it is created,
 * rather than something inferred from the peer address -- and anything not explicitly declared
 * local is [REMOTE]. A new listener, or a new caller of [AuthMiddleware.checkAuth], fails closed.
 */
enum class ListenerTrust {
    /**
     * `127.0.0.1:8080`, where the in-car UI and the service host connect. The only listener eligible
     * for the Tier 2 loopback safety net or the vehicle-action second-factor exemption. Nothing that
     * relays remote traffic may ever connect here; the Pear pump targets [HttpServer.PEAR_TLS_PORT]
     * (pinned by RemoteLoopbackListenerTest).
     */
    LOCAL_APPS,

    /** Every other listener -- LAN TLS on 8443, the Pear pump's TLS on 8444. Loopback proves nothing. */
    REMOTE,
}

object AuthMiddleware {

    // Paths that don't require authentication
    private val PUBLIC_PATHS: Set<String> = hashSetOf(
        "/auth/status", // Login page polls this; deviceId returned only to loopback callers
        "/auth/token",
        "/auth/logout",
        AuthApiHandler.PAIR_PATH, // companion pairing (rdtj.7): a single-use code is the credential
        AuthApiHandler.COMPANION_LOGIN_PATH, // companion token -> JWT; rate-limited like /auth/token
        "/login.html",
        "/login",
        "/favicon.ico",
        // Favicon variants — browsers and iOS fetch these without auth cookies.
        "/favicon.png",
        "/favicon-32x32.png",
        "/favicon-16x16.png",
        "/apple-touch-icon.png",
        // PWA install assets — the browser fetches these as part of service-worker registration
        // and manifest discovery, with no Bearer header (browser-internal fetch, not
        // auth.js-wrapped).
        "/manifest.json",
        "/sw.js",
        // Connect protocol: the login endpoint must be reachable before a session exists.
        "/bladewatch.v1.AuthService/Login"
    )

    // Path prefixes that don't require authentication
    private val PUBLIC_PREFIXES = arrayOf(
        "/shared/", // Static assets (CSS, JS, fonts, models)
        "/i18n/" // Language files
    )

    // Cookie name for JWT
    private const val JWT_COOKIE_NAME = "byd_session"

    @Volatile
    private var loopbackBypassOverride: Boolean? = null

    /** Check whether a request is authenticated. */
    @JvmStatic
    @Throws(Exception::class)
    fun checkAuth(
        path: String,
        cookieHeader: String?,
        authHeader: String?,
        out: OutputStream
    ): Boolean = checkAuth(path, cookieHeader, authHeader, out, null, false)

    /**
     * Check whether a request is authenticated, with the client address only. Backwards-compat
     * overload — assumes no tunnel headers, because the caller did not pass them.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun checkAuth(
        path: String,
        cookieHeader: String?,
        authHeader: String?,
        out: OutputStream,
        clientAddress: SocketAddress?
    ): Boolean = checkAuth(path, cookieHeader, authHeader, out, clientAddress, false)

    /**
     * Full check, with tunnel-header awareness.
     *
     * @param path request path.
     * @param cookieHeader Cookie header value.
     * @param authHeader Authorization header value.
     * @param out output stream, for sending 401/redirect.
     * @param clientAddress client socket address, for the loopback Tier-2 net.
     * @param hasTunnelHeaders true if the request carries reverse-proxy fingerprints
     *   (X-Forwarded-*, Cf-*, X-Real-Ip, Forwarded). When true, the loopback safety net is
     *   disabled.
     * @return true if authenticated or a public path, false if the request should be blocked.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun checkAuth(
        path: String,
        cookieHeader: String?,
        authHeader: String?,
        out: OutputStream,
        clientAddress: SocketAddress?,
        hasTunnelHeaders: Boolean
    ): Boolean = checkAuth(
        path, cookieHeader, authHeader, out, clientAddress, hasTunnelHeaders, ListenerTrust.REMOTE
    )

    /**
     * The full check. [trust] is the listener the request arrived on: only [ListenerTrust.LOCAL_APPS]
     * can ever reach the Tier 2 loopback safety net, and every shorter overload passes
     * [ListenerTrust.REMOTE], so a caller that does not say otherwise fails closed.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun checkAuth(
        path: String,
        cookieHeader: String?,
        authHeader: String?,
        out: OutputStream,
        clientAddress: SocketAddress?,
        hasTunnelHeaders: Boolean,
        trust: ListenerTrust
    ): Boolean {
        // Tier 0 — public paths (login UI, static assets, login submission)
        if (isPublicPath(path)) {
            return true
        }

        // Tier 0.5 — signed thumb token. Browsers and Web Push service workers fetch
        // /thumb/<file>?t=<jws> as a plain HTTPS GET (no Authorization header is available,
        // because the fetch happens inside the OS notification banner, the FCM image fetch, or
        // the iOS notification service). Accept the request iff the token's `sub` claim matches
        // the requested filename and it is not expired.
        if (path.startsWith("/thumb/")) {
            val split = splitPathAndQuery(path)
            val token = queryParam(split[1], "t")
            if (token != null) {
                val filename = split[0].substring("/thumb/".length)
                val decoded = urlDecode(filename)
                if (AuthManager.validateThumbToken(decoded, token) ||
                    AuthManager.validateThumbToken(filename, token)
                ) {
                    return true
                }
            }
        }

        // Tier 1 — JWT validation. This is the primary path: WebView (cookie), frontend pages
        // (Authorization header via auth.js), native callers (cookie via DaemonHttpClient).
        var jwt: String? = null
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            jwt = authHeader.substring(7)
        }
        if (jwt == null && cookieHeader != null) {
            jwt = extractJwtFromCookie(cookieHeader)
        }
        if (!jwt.isNullOrEmpty()) {
            val validation = AuthManager.validateJwt(jwt)
            if (validation.valid) {
                return true
            }
            // A JWT was provided but is invalid — log and fall through to Tier 2 (a stale cached
            // JWT shouldn't lock out a legitimate same-device caller).
            log("JWT invalid for " + path + ": " + validation.error)
        }

        // Tier 2 — loopback safety net. Trust 127.0.0.1 / ::1 ONLY on the in-car listener and only
        // when no proxy-fingerprint headers are present. In release builds this bypass is disabled
        // entirely because Android loopback is shared by every app on the device.
        //
        // What keeps REMOTE traffic out of it is the listener, never the address (BladeWatch-rdtj.4):
        // every way in from outside -- the Pear pump on 8444, LAN TLS on 8443 -- is a REMOTE
        // listener, and 8080 is LOCAL_APPS only for a peer UID PeerCredentials trusts
        // (effectiveTrust in HttpServer). BladeWatch-3lbz.2 once added a second condition here,
        // "no tunnel process running", because the tor onion service connected to 127.0.0.1:8080
        // as the shell UID, which that check trusts. Since BladeWatch-ur11 tor used its own REMOTE
        // listener, and with tor removed (BladeWatch-rdtj.12) that process check could never be
        // true again, so it was deleted rather than kept as protection that protects nothing. The
        // rule that replaces it: nothing may relay remote traffic into 8080 -- RemoteLoopbackListenerTest
        // pins the Pear pump to 8444, and AuthMiddlewareTest pins that a REMOTE request is refused
        // with the bypass forced on.
        if (trust == ListenerTrust.LOCAL_APPS && isLoopbackBypassAllowed() && !hasTunnelHeaders &&
            clientAddress != null
        ) {
            val addrStr = clientAddress.toString()
            if (addrStr.contains("127.0.0.1") || addrStr.contains("/0:0:0:0:0:0:0:1")) {
                return true
            }
        }

        return handleUnauthorized(
            path, out,
            if (jwt.isNullOrEmpty()) "No session token" else "Invalid session token"
        )
    }

    /**
     * Test seam. Public rather than module-internal only so AuthMiddlewareTest and
     * VehicleApiAuthTest, which are Java, can still call it: Kotlin mangles `internal` names.
     */
    @JvmStatic
    fun setLoopbackBypassOverride(override: Boolean?) {
        loopbackBypassOverride = override
    }

    private fun isLoopbackBypassAllowed(): Boolean = loopbackBypassOverride ?: BuildConfig.DEBUG

    /**
     * Whether a request comes from an app on the head unit itself, for the vehicle-action
     * second-factor exemption in HttpServer. That exemption used to be `isLoopbackAddress` alone,
     * which the Pear pump would have satisfied from 127.0.0.1 -- letting a remote peer actuate the
     * car on a session JWT alone. Requires the in-car listener as well (BladeWatch-rdtj.4).
     */
    @JvmStatic
    fun isLocalAppCaller(trust: ListenerTrust, address: java.net.InetAddress): Boolean =
        trust == ListenerTrust.LOCAL_APPS && address.isLoopbackAddress

    /**
     * The trust a connection actually gets. The in-car listener's local trust is for BladeWatch, not
     * for every app on the head unit: Android loopback is shared, and LOCAL_APPS both opens the
     * debug-build Tier 2 bypass and skips the vehicle-action second factor -- so any installed app
     * used to get the whole API, vehicle control included, with no credential (BladeWatch-g5u7).
     * A connection keeps LOCAL_APPS only when its peer UID is one the IPC server trusts too
     * ([PeerCredentials]: the BladeWatch app UID, shell, system, root). Any other peer -- or one
     * whose UID cannot be resolved -- is served exactly like a remote caller. [peerTrusted] is only
     * evaluated on the in-car listener; the lookup reads /proc/net.
     */
    @JvmStatic
    fun effectiveTrust(listener: ListenerTrust, peerTrusted: () -> Boolean): ListenerTrust =
        if (listener == ListenerTrust.LOCAL_APPS && !peerTrusted()) ListenerTrust.REMOTE else listener

    /** Whether a path is public (no auth required). */
    @JvmStatic
    fun isPublicPath(path: String): Boolean {
        // Exact match
        if (PUBLIC_PATHS.contains(path)) {
            return true
        }

        // Strip the query string for matching
        val pathOnly = if (path.contains("?")) path.substring(0, path.indexOf("?")) else path
        if (PUBLIC_PATHS.contains(pathOnly)) {
            return true
        }

        // Prefix match
        for (prefix in PUBLIC_PREFIXES) {
            if (path.startsWith(prefix)) {
                return true
            }
        }

        return false
    }

    /** Extract the JWT from a cookie header. */
    private fun extractJwtFromCookie(cookieHeader: String?): String? {
        if (cookieHeader == null) return null

        // Parse cookies: "name1=value1; name2=value2"
        for (cookie in cookieHeader.split(";")) {
            val parts = cookie.trim().split("=", limit = 2)
            if (parts.size == 2 && parts[0].trim() == JWT_COOKIE_NAME) {
                return parts[1].trim()
            }
        }

        return null
    }

    /**
     * Handle an unauthorized request: API requests get 401 JSON, page requests get redirected to
     * the login page.
     */
    @Throws(Exception::class)
    private fun handleUnauthorized(path: String, out: OutputStream, reason: String): Boolean {
        log("Unauthorized: " + path + " - " + reason)

        // API requests get 401 JSON
        if (path.startsWith("/api/") || path.startsWith("/ws") ||
            path.startsWith("/video/") ||
            path.startsWith("/thumb/") || path.startsWith("/h264/") ||
            path == "/status" || path.startsWith("/bladewatch.v1.")
        ) {
            val json = "{\"error\":\"Unauthorized\",\"reason\":\"" + reason +
                "\",\"login\":\"/login.html\"}"
            HttpResponse.sendUnauthorized(out, json)
            return false
        }

        // Page requests get redirected to login
        HttpResponse.sendRedirect(out, "/login.html?redirect=" + urlEncode(path))
        return false
    }

    /** Simple URL encoding for the redirect parameter. */
    private fun urlEncode(s: String): String = try {
        URLEncoder.encode(s, "UTF-8")
    } catch (e: Exception) {
        log("urlEncode failed: " + e.message)
        s
    }

    private fun urlDecode(s: String): String = try {
        URLDecoder.decode(s, "UTF-8")
    } catch (e: Exception) {
        log("urlDecode failed: " + e.message)
        s
    }

    private fun splitPathAndQuery(path: String): Array<String> {
        val q = path.indexOf('?')
        return if (q < 0) arrayOf(path, "") else arrayOf(path.substring(0, q), path.substring(q + 1))
    }

    private fun queryParam(query: String?, name: String): String? {
        if (query.isNullOrEmpty()) return null
        for (pair in query.split("&")) {
            val eq = pair.indexOf('=')
            if (eq < 0) continue
            if (name == pair.substring(0, eq)) {
                return urlDecode(pair.substring(eq + 1))
            }
        }
        return null
    }

    private fun log(message: String) {
        CameraDaemon.log("AUTH: $message")
    }
}
