package net.bladewatch.app.server

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.auth.CompanionPairing
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

    /** Companion pairing (BladeWatch-rdtj.7). Public, rate-limited; listed in AuthMiddleware. */
    const val PAIR_PATH = "/auth/pair"
    const val COMPANION_LOGIN_PATH = "/auth/companion"

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

        // BladeWatch-rdtj.7: the companion app's two public calls.
        //
        // No rate limits here, deliberately (BladeWatch-rlgv). What they check cannot be guessed --
        // a pairing code is 128 random bits, single-use and 5 minutes long; a companion id is 128
        // random bits and its token an HMAC-SHA256 -- so a limit adds nothing against guessing and
        // only hands anyone who can reach these (the LAN when it is on, anyone with the Pear topic)
        // a way to lock every companion out: the global lockout blocked them all for 5 minutes per
        // 30 bad tries, and every remote peer shares ONE 127.0.0.1 bucket. /auth/token keeps its
        // limits -- an owner-set access code can be short -- until it goes with the web app.
        if (method == "POST" && (path == PAIR_PATH || path == COMPANION_LOGIN_PATH)) {
            val identity = if (!rateLimitIdentity.isNullOrEmpty()) rateLimitIdentity else "unknown"
            return if (path == PAIR_PATH) handlePairRedeem(body, out, identity) else handleCompanionLogin(body, out, identity)
        }

        return false
    }

    /**
     * Trades the single-use code from an in-car pairing QR for a companion credential
     * (BladeWatch-rdtj.7). The credential is returned once, here, and never again. Errors are
     * stable codes, not localized text: the companion shows its own message.
     */
    private fun handlePairRedeem(body: String?, out: OutputStream, rateLimitIdentity: String): Boolean {
        val request = try { JSONObject(body ?: "") } catch (e: Exception) { JSONObject() }
        val credential = CompanionPairing.shared.redeem(request.optString("code", ""), request.optString("name", ""))
        val response = JSONObject()
        if (credential == null) {
            response.put("success", false).put("error", "pairing_code_refused")
        } else {
            clearRateLimit(rateLimitIdentity)
            response.put("success", true).put("companionId", credential.companionId).put("token", credential.token)
            log("Companion paired")
        }
        HttpResponse.sendJson(out, response.toString())
        return true
    }

    /** A paired companion trades its token for a session JWT, carried in the body, not a cookie. */
    private fun handleCompanionLogin(body: String?, out: OutputStream, rateLimitIdentity: String): Boolean {
        val request = try { JSONObject(body ?: "") } catch (e: Exception) { JSONObject() }
        val companionId = request.optString("companionId", "")
        val verdict = CompanionPairing.shared.check(companionId, request.optString("token", ""))
        val jwt = if (verdict == CompanionPairing.Verdict.OK) AuthManager.generateJwt(companionId) else null
        val response = JSONObject()
        if (verdict == CompanionPairing.Verdict.REFUSED) {
            // The ONLY answer that tells a companion it was removed; it stops and asks to pair again.
            response.put("success", false).put("error", "companion_refused")
        } else if (jwt == null) {
            // BladeWatch-w7by: the car could not tell (store unreadable, auth not loaded yet) or
            // could not mint. Retryable -- never "refused", and no failed-guess count against anyone.
            response.put("success", false).put("error", "auth_unavailable")
        } else {
            clearRateLimit(rateLimitIdentity)
            response.put("success", true).put("jwt", jwt).put("expiresIn", AuthManager.getJwtExpirySeconds())
        }
        HttpResponse.sendJson(out, response.toString())
        return true
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

    /** Test seam: forget every bucket and the global lockout. */
    @JvmStatic
    fun resetRateLimitsForTest() {
        rateLimits.clear()
        globalFailCount.set(0)
        globalWindowStart.set(System.currentTimeMillis())
        globalLockoutUntil = 0L
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
