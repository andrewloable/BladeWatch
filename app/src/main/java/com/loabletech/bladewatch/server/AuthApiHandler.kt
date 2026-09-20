package net.bladewatch.app.server

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.daemon.CameraDaemon
import org.json.JSONObject
import java.io.OutputStream
import java.util.ArrayDeque
import java.util.Deque
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * HTTP handler for the authentication endpoints.
 *
 *  - `GET  /auth/status` — check auth status; surfaces deviceId to loopback callers only
 *  - `POST /auth/token`  — validate a device token and get a JWT (rate-limited)
 *  - `POST /auth/logout` — clear the session
 *
 * This is the PRE-AUTH bootstrap and deliberately keeps its HTTP entry point: login.html is plain
 * HTML served before any Connect client exists, and it is the one page that has to work when
 * everything else is broken. `AuthService.Login` exists for the SPA.
 *
 * Rate limiting on /auth/token: 10 attempts per minute per TCP peer, then a 30s per-identity
 * lockout; plus a global cap (30 failures / 2 min → 5 min lockout) that is immune to identity
 * rotation. Identity is always the real TCP socket address — never X-Forwarded-For, which is
 * attacker-controlled.
 */
object AuthApiHandler {

    // Per-identity rate-limit constants
    private const val RATE_LIMIT_WINDOW_MS = 60_000 // 1 minute window
    private const val RATE_LIMIT_MAX_ATTEMPTS = 10 // attempts per identity per window
    private const val RATE_LIMIT_LOCKOUT_MS = 30_000L // per-identity lockout duration

    // Global rate-limit: caps total failed attempts regardless of identity rotation
    private const val GLOBAL_FAIL_THRESHOLD = 30 // failed attempts across all IPs
    private const val GLOBAL_LOCKOUT_MS = 300_000L // 5-minute global lockout
    private const val GLOBAL_WINDOW_MS = 120_000L // 2-minute counting window

    // Bounded map size: prevents OOM from identity rotation (an attacker flooding new IPs)
    private const val MAX_IDENTITY_BUCKETS = 256

    private val rateLimits = ConcurrentHashMap<String, RateLimitBucket>()

    // Global failure tracking (not per-identity — immune to rotation)
    private val globalWindowStart = AtomicLong(System.currentTimeMillis())
    private val globalFailCount = AtomicInteger(0)

    @Volatile
    private var globalLockoutUntil = 0L

    private class RateLimitBucket {
        val attempts: Deque<Long> = ArrayDeque()
        var lockedUntil = 0L
    }

    /** Handle an auth request. */
    @JvmStatic
    @Throws(Exception::class)
    fun handle(method: String, path: String, body: String?, out: OutputStream): Boolean =
        handle(method, path, body, out, null, false)

    /** Handle an auth request with the rate-limit identity (the real socket address). */
    @JvmStatic
    @Throws(Exception::class)
    fun handle(
        method: String,
        path: String,
        body: String?,
        out: OutputStream,
        rateLimitIdentity: String?,
        secureCookie: Boolean
    ): Boolean {
        if (path == "/auth/status" && method == "GET") {
            return handleStatus(out, rateLimitIdentity)
        }

        if (path == "/auth/token" && method == "POST") {
            // Rate-limit token validation to slow down brute-force attempts. Identity is always
            // the real TCP peer socket (set by HttpServer) — never X-Forwarded-For, which is
            // client-controlled.
            val idForLimit =
                if (!rateLimitIdentity.isNullOrEmpty()) rateLimitIdentity else "unknown"
            val rateError = checkRateLimit(idForLimit)
            if (rateError != null) {
                val resp = JSONObject()
                resp.put("success", false)
                resp.put("error", rateError)
                HttpResponse.sendJson(out, resp.toString())
                return true
            }
            return handleTokenValidation(body, out, idForLimit, secureCookie)
        }

        if (path == "/auth/logout" && method == "POST") {
            return handleLogout(out, secureCookie)
        }

        return false
    }

    /** @return null if the request may proceed, an error string if it is rate limited. */
    private fun checkRateLimit(identity: String): String? {
        val now = System.currentTimeMillis()

        // Global lockout check — immune to identity rotation
        if (globalLockoutUntil > now) {
            val secs = (globalLockoutUntil - now) / 1000 + 1
            return Messages.get("errors.rate_limited_locked_for_seconds", secs)
        }

        // Per-identity bucket (bounded map — evict the oldest if full)
        if (rateLimits.size >= MAX_IDENTITY_BUCKETS && !rateLimits.containsKey(identity)) {
            val oldest = rateLimits.keys().nextElement()
            rateLimits.remove(oldest)
        }
        val bucket = rateLimits.computeIfAbsent(identity) { RateLimitBucket() }
        synchronized(bucket) {
            if (bucket.lockedUntil > now) {
                val secs = (bucket.lockedUntil - now) / 1000 + 1
                return Messages.get("errors.rate_limited_locked_for_seconds", secs)
            }
            // Drop attempts outside the per-identity window
            val windowStart = now - RATE_LIMIT_WINDOW_MS
            while (!bucket.attempts.isEmpty() && bucket.attempts.peekFirst() < windowStart) {
                bucket.attempts.pollFirst()
            }
            if (bucket.attempts.size >= RATE_LIMIT_MAX_ATTEMPTS) {
                bucket.lockedUntil = now + RATE_LIMIT_LOCKOUT_MS
                bucket.attempts.clear()
                log(
                    "Rate limit exceeded for " + identity + " — locked for " +
                        (RATE_LIMIT_LOCKOUT_MS / 1000) + "s"
                )
                return Messages.get(
                    "errors.rate_limited_locked_for_seconds", RATE_LIMIT_LOCKOUT_MS / 1000
                )
            }
            bucket.attempts.addLast(now)
        }
        return null
    }

    /**
     * Record a failed login attempt toward the global cap. Called after a validation failure, not
     * for rate-limit rejections.
     */
    private fun recordGlobalFailure() {
        val now = System.currentTimeMillis()
        // Reset the window if it has expired
        if (now - globalWindowStart.get() > GLOBAL_WINDOW_MS) {
            globalWindowStart.set(now)
            globalFailCount.set(0)
        }
        val fails = globalFailCount.incrementAndGet()
        if (fails >= GLOBAL_FAIL_THRESHOLD && globalLockoutUntil <= now) {
            globalLockoutUntil = now + GLOBAL_LOCKOUT_MS
            log(
                "Global brute-force threshold reached (" + fails +
                    " failures) — global lockout for " + (GLOBAL_LOCKOUT_MS / 1000) + "s"
            )
        }
    }

    /** Reset the rate-limit bucket for an identity after a successful login. */
    private fun clearRateLimit(identity: String?) {
        if (identity != null) rateLimits.remove(identity)
    }

    /**
     * Device status. deviceId is only included for loopback callers (the in-car UI on the same
     * device) — tunnel/LAN callers get status:ok only, because exposing it halves the brute-force
     * search space.
     */
    @Throws(Exception::class)
    private fun handleStatus(out: OutputStream, identity: String?): Boolean {
        val state = AuthManager.getState()

        val response = JSONObject()
        response.put("status", "ok")

        val isLoopback = identity != null && identity.contains("127.0.0.1")
        if (isLoopback && state != null) {
            response.put("deviceId", state.deviceId)
        }

        HttpResponse.sendJson(out, response.toString())
        return true
    }

    /** Validate the device token and return a JWT session. */
    @Throws(Exception::class)
    private fun handleTokenValidation(
        body: String?,
        out: OutputStream,
        rateLimitIdentity: String?,
        secureCookie: Boolean
    ): Boolean {
        val response = JSONObject()

        try {
            val token = JSONObject(body).optString("token", "")

            if (AuthManager.validateDeviceToken(token)) {
                // Successful login — wipe the attempt counter so the user gets a fresh
                // 10-attempt budget on their next session.
                clearRateLimit(rateLimitIdentity)

                val jwt = AuthManager.generateJwt()
                val state = AuthManager.getState()
                if (jwt == null || state == null) {
                    // Auth state was invalidated between validateDeviceToken and here (e.g. a
                    // concurrent regenerateToken). Treat it as a transient failure rather than
                    // NPEing on state.deviceId.
                    response.put("success", false)
                    response.put("error", Messages.get("errors.invalid_device_token"))
                    log("Auth state vanished mid-login — asking client to retry")
                } else {
                    response.put("success", true)
                    response.put("deviceId", state.deviceId)
                    response.put("expiresIn", AuthManager.getJwtExpirySeconds())

                    log("Token validated for device: " + state.deviceId)
                    val sessionCookie = buildCookie(
                        "byd_session", jwt, AuthManager.getJwtExpirySeconds().toLong(),
                        true, secureCookie
                    )
                    val hintCookie = buildCookie(
                        "byd_auth", "1", AuthManager.getJwtExpirySeconds().toLong(),
                        false, secureCookie
                    )
                    HttpResponse.sendJsonWithCookies(
                        out, response.toString(), arrayOf(sessionCookie, hintCookie)
                    )
                    return true
                }
            } else {
                response.put("success", false)
                response.put("error", Messages.get("errors.invalid_device_token"))
                log("Invalid token attempt from $rateLimitIdentity")
                recordGlobalFailure()
            }
        } catch (e: Exception) {
            response.put("success", false)
            response.put(
                "error", Messages.get("errors.invalid_request_with_detail", e.message)
            )
        }

        HttpResponse.sendJson(out, response.toString())
        return true
    }

    /** Log the user out. The client should clear its stored JWT. */
    @Throws(Exception::class)
    private fun handleLogout(out: OutputStream, secureCookie: Boolean): Boolean {
        val response = JSONObject()
        response.put("success", true)
        response.put("message", Messages.get("messages.logged_out"))

        val expiredSession = buildCookie("byd_session", "", 0, true, secureCookie)
        val expiredHint = buildCookie("byd_auth", "", 0, false, secureCookie)
        HttpResponse.sendJsonWithCookies(
            out, response.toString(), arrayOf(expiredSession, expiredHint)
        )
        return true
    }

    private fun buildCookie(
        name: String,
        value: String,
        maxAgeSeconds: Long,
        httpOnly: Boolean,
        secure: Boolean
    ): String {
        val cookie = StringBuilder()
        cookie.append(name).append("=").append(value)
            .append("; Path=/; Max-Age=").append(maxAgeSeconds)
            .append("; SameSite=Lax")
        if (httpOnly) cookie.append("; HttpOnly")
        if (secure) cookie.append("; Secure")
        return cookie.toString()
    }

    private fun log(message: String) {
        CameraDaemon.log("AUTH: $message")
    }
}
