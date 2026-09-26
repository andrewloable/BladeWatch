package net.bladewatch.app.auth

import android.os.Build

import net.bladewatch.app.config.SecretConfigBridge
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon

import org.json.JSONObject

import java.io.File
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Base64
import java.util.Locale

import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Authentication Manager for BYD Champ.
 *
 * Simple device token authentication - no external OAuth needed.
 * Works over any transport (Pear, or a LAN address) since no origin
 * validation is required.
 *
 * Auth Flow:
 * 1. User enters device token (displayed in app)
 * 2. Token validated → JWT session created
 * 3. JWT used for subsequent requests (24 hour expiry)
 *
 * Security:
 * - Device token = deviceId + secret (e.g., byd-a1b2c3d4-x7k9m2p5)
 * - JWT signed with HMAC-SHA256 using device secret
 *
 * Persistence:
 * Public auth state (device ID, last access, token epoch) stays in the
 * unified config, while the device secret moves to the daemon-owned secret
 * store. App-side callers fall back to localhost IPC when the secret file
 * is not directly readable in-process.
 *
 * Existing devices: on first run after this change, if the unified
 * config has no auth section but the legacy `/data/local/tmp/.byd_auth.json`
 * exists, its contents are migrated in-place — so a device that was
 * already logged in keeps its secret and existing JWTs.
 *
 * The device ID file at `/data/local/tmp/.bladewatch_device_id` is
 * still consulted (it's written by ADB shell during MainActivity startup),
 * so the deviceId remains stable across uninstalls even though the
 * unified config is wiped on factory reset.
 */
object AuthManager {

    // Section name inside the unified config.
    private const val CONFIG_SECTION = "auth"
    private const val KEY_DEVICE_ID = "deviceId"
    private const val KEY_DEVICE_SECRET = "deviceSecret"
    private const val KEY_LAST_ACCESS = "lastAccess"

    // Legacy single-purpose auth file. Read-only at this point — kept
    // around purely so existing installs can be migrated forward into
    // the unified config without forcing the user to re-pair.
    private const val LEGACY_AUTH_FILE = "/data/local/tmp/.byd_auth.json"

    // Device ID file — written via ADB shell from MainActivity, survives
    // app reinstall. Consulted only when the unified config has no
    // deviceId yet (cold-start before MainActivity has synced).
    private const val DEVICE_ID_FILE =
        "/storage/emulated/0/Android/data/net.bladewatch.app/files/.bladewatch_device_id"
    private const val LEGACY_DEVICE_ID_FILE = "/data/local/tmp/.bladewatch_device_id"
    private const val LEGACY_CAMERA_DEVICE_ID_FILE = "/data/local/tmp/.byd_device_id"

    // JWT settings
    /** 24 hours */
    private const val JWT_EXPIRY_MS = 24 * 60 * 60 * 1000L
    private const val JWT_ALGORITHM = "HS256"
    private const val KEY_TOKEN_EPOCH = "tokenEpoch"

    // In-memory cache. UnifiedConfigManager already mtime-invalidates its
    // own cache, but a tiny per-instance cache lets us hand out the same
    // AuthState reference for repeated calls within a single request and
    // skips a JSON parse on the JWT validation hot path.
    @Volatile
    private var cachedState: AuthState? = null

    @Volatile
    private var cachedConfigMtime = 0L

    @Volatile
    private var testStateOverride: AuthState? = null

    // Monotonic counter incremented every time cachedState is replaced.
    // Lets downstream JWT consumers (DaemonHttpClient, WebViewFragment cookie)
    // detect a swap and invalidate their own per-secret caches without
    // having to compare opaque secret material.
    @Volatile
    private var stateVersion = 0L

    // Backoff for init retries. When initialize() fails to persist (daemon not
    // ready yet), we record the timestamp and refuse to retry within this window.
    // Without this, callers that poll getState()/generateJwt() at 1 Hz will
    // hammer the daemon's IPC server with rejected connections.
    @Volatile
    private var lastInitAttemptMs = 0L
    private const val INIT_RETRY_INTERVAL_MS = 3000L

    /** Auth state persisted to the unified config. */
    class AuthState {
        @JvmField
        var deviceId: String? = null

        /** Random secret for token generation */
        @JvmField
        var deviceSecret: String? = null

        /** Last successful auth timestamp */
        @JvmField
        var lastAccess: Long = 0

        /** Session rotation counter */
        @JvmField
        var tokenEpoch: Long = 0

        fun getDeviceToken(): String = "$deviceId-$deviceSecret"

        /**
         * Get just the secret part (for display in app UI).
         * User combines with device ID shown on login page.
         */
        fun getSecret(): String? = deviceSecret

        fun toJson(): JSONObject = try {
            JSONObject().apply {
                put(KEY_DEVICE_ID, deviceId)
                put(KEY_LAST_ACCESS, lastAccess)
                put(KEY_TOKEN_EPOCH, tokenEpoch)
            }
        } catch (e: Exception) {
            log("toJson failed: " + e.message)
            JSONObject()
        }

        companion object {
            @JvmStatic
            fun fromJson(json: JSONObject): AuthState = AuthState().apply {
                deviceId = json.optString(KEY_DEVICE_ID, "")
                deviceSecret = ""
                lastAccess = json.optLong(KEY_LAST_ACCESS, 0)
                tokenEpoch = json.optLong(KEY_TOKEN_EPOCH, 0)
            }
        }
    }

    /** JWT validation result. */
    class JwtValidation {
        @JvmField
        var valid = false

        @JvmField
        var deviceId: String? = null

        @JvmField
        var error: String? = null

        companion object {
            @JvmStatic
            fun success(deviceId: String?): JwtValidation = JwtValidation().apply {
                valid = true
                this.deviceId = deviceId
            }

            @JvmStatic
            fun failure(error: String?): JwtValidation = JwtValidation().apply {
                valid = false
                this.error = error
            }
        }
    }

    // ==================== INITIALIZATION ====================

    /**
     * Initialize auth state. Creates device secret if not exists.
     * Call this on app/daemon startup.
     */
    @JvmStatic
    @Synchronized
    fun initialize(): AuthState? {
        testStateOverride?.let {
            cachedState = it
            cachedConfigMtime = 0
            stateVersion++
            return it
        }

        // Backoff: if we recently failed to persist (daemon not ready), don't
        // hammer the IPC server. Callers that poll getState()/generateJwt() will
        // keep getting null until the daemon has created the config file.
        val now = System.currentTimeMillis()
        if (lastInitAttemptMs > 0 && (now - lastInitAttemptMs) < INIT_RETRY_INTERVAL_MS) {
            log("Throttling init retry — last attempt was " + (now - lastInitAttemptMs) + "ms ago")
            return null
        }

        var state = loadFromConfig()

        // Migration: if unified config has no auth yet but the legacy
        // .byd_auth.json exists from a previous version, lift it forward
        // so existing devices don't lose their secret. We only attempt
        // the write when the unified config file is already there and
        // world-rw — which it is on any device that has run the daemon
        // at least once. On a brand-new install where the daemon hasn't
        // run yet, the write will silently fail; the daemon will perform
        // the migration on its first boot.
        if (state == null) {
            val legacy = loadLegacyAuthFile()
            if (legacy != null && !legacy.deviceSecret.isNullOrEmpty()) {
                state = legacy
                if (state.deviceId.isNullOrEmpty()) {
                    state.deviceId = loadDeviceId()
                }
                if (writeToConfig(state)) {
                    log("Migrated auth state from legacy file $LEGACY_AUTH_FILE")
                } else {
                    log(
                        "Legacy auth state held in-memory; will be migrated when unified " +
                            "config becomes writable"
                    )
                }
            }
        }

        // Still nothing? Mint a fresh state. Critical: only persist if
        // the write actually succeeds. On app-UID processes the unified
        // config file is unwritable until the daemon (UID 2000) creates
        // it with chmod 666. If the write fails we DO NOT cache the
        // generated secret — that would make the app sign JWTs with
        // a secret the daemon will never accept. Instead we return null
        // so callers (e.g. WebViewFragment) retry once the daemon has
        // booted and getState() can pull the canonical value.
        if (state == null || state.deviceSecret.isNullOrEmpty()) {
            // BladeWatch-w7by: "not found" is only true when the daemon itself read the store and it
            // was not there. From the app process it can just mean the daemon has not answered yet
            // (an install restarts the app before the daemons): minting here then persisted a NEW
            // secret once the daemon came up, and every companion token died with the old one.
            if (!SecretConfigBridge.canMintSecrets()) {
                log("Auth secret not readable from this process yet -- leaving it to the daemon")
                cachedState = null
                cachedConfigMtime = 0
                lastInitAttemptMs = System.currentTimeMillis()
                return null
            }
            if (state == null) state = AuthState()
            if (state.deviceId.isNullOrEmpty()) {
                state.deviceId = loadDeviceId()
            }
            state.deviceSecret = generateSecret(20)
            if (!writeToConfig(state)) {
                log(
                    "WARN: cannot persist auth secret (likely app UID before daemon boot) " +
                        "— will defer to daemon"
                )
                // Do NOT cache. Returning null keeps callers in a
                // "retry later" loop instead of locking in a secret
                // that won't agree with whatever the daemon writes.
                cachedState = null
                cachedConfigMtime = 0
                lastInitAttemptMs = System.currentTimeMillis()
                return null
            }
            log("Generated new device secret")
        }

        cachedState = state
        cachedConfigMtime = UnifiedConfigManager.getLastModified()
        stateVersion++
        log("Auth initialized. Device: " + state.deviceId)
        return state
    }

    /**
     * Get current auth state.
     *
     * Reads from the unified config when its mtime has advanced beyond
     * the cached snapshot. UnifiedConfigManager already throttles its
     * own disk reads via the cached-config + mtime check, so this is
     * cheap to call on every JWT validation.
     */
    @JvmStatic
    fun getState(): AuthState? {
        testStateOverride?.let { return it }
        var cur = cachedState
        var fileMtime = UnifiedConfigManager.getLastModified()
        if (cur != null && fileMtime != 0L && fileMtime == cachedConfigMtime) {
            return cur
        }
        // Cache stale or unset — pull from config.
        synchronized(this) {
            // Re-check inside the lock.
            cur = cachedState
            fileMtime = UnifiedConfigManager.getLastModified()
            if (cur != null && fileMtime != 0L && fileMtime == cachedConfigMtime) {
                return cur
            }
            val fresh = loadFromConfig()
            if (fresh != null && !fresh.deviceSecret.isNullOrEmpty()) {
                val prev = cur
                if (prev == null ||
                    prev.deviceSecret != fresh.deviceSecret ||
                    prev.deviceId != fresh.deviceId
                ) {
                    cachedState = fresh
                    stateVersion++
                    log("Auth state refreshed from unified config (mtime=$fileMtime)")
                }
                cachedConfigMtime = fileMtime
                return cachedState
            }
            // Config has no auth yet — initialize (handles migration too).
            return initialize()
        }
    }

    /**
     * Force the next [getState] to re-read the device secret from the
     * daemon (via the secret-store IPC) instead of returning the in-memory
     * cache.
     *
     * Why this exists: the cache is invalidated on the unified-config file's
     * mtime, but the device secret lives in the shell-owned secrets store and
     * is fetched over IPC — so a daemon restart that hands out the canonical
     * secret won't change config.json's mtime and the app keeps signing JWTs
     * with a stale secret ("Invalid signature" → "Camera unavailable"), which
     * previously only cleared after a manual app restart. Call this when the
     * app returns to the foreground (and before opening the live stream) so a
     * fresh install / daemon restart re-syncs the secret automatically.
     */
    @JvmStatic
    fun refresh() {
        // Intentionally NOT synchronized. refresh() only writes the volatile
        // cache fields below, so it needs no monitor — and acquiring one would
        // be actively harmful: getState()/initialize() hold the AuthManager
        // monitor across a blocking daemon IPC (up to ~30s while the
        // daemon is still booting on a fresh install). refresh() is called from
        // MainActivity.onResume() on the MAIN thread; if it had to wait for that
        // monitor it would block the UI thread past the 5s input-dispatch
        // threshold and ANR. Lock-free keeps onResume() instant. The
        // volatile cachedState=null write is the real cache invalidation
        // (getState() re-checks it); the stateVersion bump is an advisory
        // "changed" hint for JWT-caching consumers (DaemonHttpClient's /status
        // poller, WebView cookie) so they re-mint instead of reusing a JWT
        // signed with the now-discarded secret. A rare lost increment from
        // racing a monitored writer is harmless because cachedState=null already
        // forces a reload.
        if (testStateOverride != null) return
        cachedState = null
        cachedConfigMtime = 0
        stateVersion++
    }

    // ==================== TOKEN VALIDATION ====================

    /**
     * Validate device token.
     * Token format: {deviceId}-{secret}
     */
    @JvmStatic
    fun validateDeviceToken(token: String?): Boolean {
        if (token.isNullOrEmpty()) {
            return false
        }
        val state = getState() ?: return false
        // Guard the SECRET, not the composed token. getDeviceToken() is deviceId + "-" +
        // deviceSecret, so a blank secret yields "byd-xxxx-" — non-empty, and guessable by
        // anyone who has seen the device id, which the login page displays.
        //
        // getState() will not hand out a blank-secret state today (it re-initialises instead),
        // so this is defence in depth rather than a live hole. It is worth stating here anyway
        // because AuthState.fromJson deliberately sets deviceSecret = "" — the secret lives in
        // the secret store, not the config — so blank-secret states are constructed by design
        // and only one caller stands between them and this check.
        if (state.getSecret().isNullOrEmpty()) {
            return false
        }
        val expected = state.getDeviceToken()
        if (expected.isEmpty()) {
            return false
        }
        // Constant-time, like every other secret comparison in this class (see the JWT
        // signature checks below) and in IpcTokenManager / VehicleActionToken. This one was
        // the outlier, and it is the most exposed of the set: it backs POST /auth/token, the
        // UNAUTHENTICATED login endpoint, so the compared value is supplied by whoever can
        // reach the tunnel. String.equals returns at the first differing byte, which leaks how
        // much of the secret a guess got right.
        //
        // The attempt limiter in AuthApiHandler already caps guesses, so this is defence in
        // depth rather than a fix for a demonstrated break — but it costs one line and removes
        // an inconsistency that reads like an oversight.
        return MessageDigest.isEqual(
            token.toByteArray(StandardCharsets.UTF_8),
            expected.toByteArray(StandardCharsets.UTF_8)
        )
    }

    /**
     * Regenerate device token (invalidates all sessions).
     *
     * Returns the new token on success, or `null` if persistence
     * failed (e.g. the unified config file disappeared between read and
     * write, or a cross-UID write race). On failure we deliberately
     * leave the previous cachedState in place — caching a phantom secret
     * here would re-introduce the exact divergence the unified-store
     * refactor was meant to eliminate, this time triggered by the user
     * pressing "Regenerate".
     */
    @JvmStatic
    @Synchronized
    fun regenerateToken(): String? = rotateSecret(generateSecret(20), "Token regenerated")

    /** Minimum length for a user-supplied custom secret. */
    const val CUSTOM_SECRET_MIN_LENGTH = 12

    /**
     * Set a user-provided custom secret (password). Caller must validate
     * minimum length before calling. Returns the new full device token, or
     * null if persistence failed.
     */
    @JvmStatic
    @Synchronized
    fun setCustomSecret(customSecret: String?): String? {
        if (customSecret == null || customSecret.length < CUSTOM_SECRET_MIN_LENGTH) return null
        return rotateSecret(customSecret, "Custom secret set by user")
    }

    /**
     * Install [newSecret] as the device secret and bump the token epoch, persisting first
     * and only caching on success. regenerateToken() and setCustomSecret() differ only in
     * where the secret comes from and what they log.
     */
    private fun rotateSecret(newSecret: String, successLog: String): String? {
        val current = getState()
        val state: AuthState
        if (current == null) {
            state = AuthState()
            state.deviceId = loadDeviceId()
        } else {
            // Don't mutate the cached AuthState in place — if the write
            // fails, callers reading cachedState concurrently would see
            // a half-applied secret. Snapshot fields onto a new object.
            state = AuthState()
            state.deviceId = current.deviceId
            state.lastAccess = current.lastAccess
            state.tokenEpoch = current.tokenEpoch
        }

        state.deviceSecret = newSecret
        state.tokenEpoch = state.tokenEpoch + 1

        if (testStateOverride != null) {
            testStateOverride = state
            cachedState = state
            stateVersion++
            log("$successLog (test override)")
            return state.getDeviceToken()
        }

        if (!writeToConfig(state)) {
            log("ERROR: $successLog failed to persist new secret — keeping previous state")
            return null
        }

        cachedState = state
        cachedConfigMtime = UnifiedConfigManager.getLastModified()
        stateVersion++

        log(successLog)
        return state.getDeviceToken()
    }

    // ==================== JWT MANAGEMENT ====================

    /** Generate a JWT session token. */
    @JvmStatic
    fun generateJwt(): String? = generateJwt(null)

    /**
     * A JWT session token; [companionId] non-null mints one for a paired companion app
     * (BladeWatch-rdtj.7), carrying it as `cid` so [validateJwt] can refuse it the moment that
     * companion is un-paired, without disturbing any other session.
     */
    @JvmStatic
    fun generateJwt(companionId: String?): String? {
        val state = getState() ?: return null

        return try {
            val now = System.currentTimeMillis() / 1000
            val exp = now + (JWT_EXPIRY_MS / 1000)
            val headerJson = "{\"alg\":\"" + JWT_ALGORITHM + "\",\"typ\":\"JWT\"}"
            val payloadJson = "{\"sub\":\"" + escapeJson(state.deviceId) + "\"," +
                "\"iat\":" + now + "," +
                "\"exp\":" + exp + "," +
                (if (companionId != null) "\"cid\":\"" + escapeJson(companionId) + "\"," else "") +
                "\"ver\":" + state.tokenEpoch + "}"

            val content = base64UrlEncode(headerJson.toByteArray(StandardCharsets.UTF_8)) +
                "." + base64UrlEncode(payloadJson.toByteArray(StandardCharsets.UTF_8))

            // We deliberately do NOT bump lastAccess on every JWT mint:
            // the previous implementation rewrote the auth file on every
            // call (~1Hz from /status polling) which thrashed the unified
            // config and bumped its mtime, defeating the mtime-based
            // cache. lastAccess wasn't read by anything load-bearing.
            content + "." + hmacSha256(content, state.deviceSecret)
        } catch (e: Exception) {
            log("JWT generation error: " + e.message)
            null
        }
    }

    /**
     * Mint a single-purpose thumb token for a given filename. Compact HS256
     * over the existing device secret with claims `sub=filename` and
     * `exp=now+ttlSec`. The token can be carried as a `?t=`
     * query param so browsers fetching the thumbnail (Web Push notification
     * service worker, FCM image fetch, iOS WebKit notification body) don't
     * need to send Authorization headers — useful when the URL ends up in
     * the OS-level notification banner where headers are not configurable.
     */
    @JvmStatic
    fun signThumbToken(filename: String?, ttlSec: Long): String? {
        val state = getState()
        if (state == null || filename == null) return null
        return try {
            val now = System.currentTimeMillis() / 1000
            val headerJson = "{\"alg\":\"" + JWT_ALGORITHM + "\",\"typ\":\"THM\"}"
            val payloadJson = "{\"sub\":\"" + escapeJson(filename) + "\"," +
                "\"iat\":" + now + "," +
                "\"exp\":" + (now + ttlSec) + "}"
            val content = base64UrlEncode(headerJson.toByteArray(StandardCharsets.UTF_8)) +
                "." + base64UrlEncode(payloadJson.toByteArray(StandardCharsets.UTF_8))
            content + "." + hmacSha256(content, state.deviceSecret)
        } catch (e: Exception) {
            log("Thumb token sign error: " + e.message)
            null
        }
    }

    /**
     * Validate a thumb token against an expected filename. Returns true iff
     * signature matches the device secret, `typ=="THM"`,
     * `sub==filename`, and `exp` is in the future.
     */
    @JvmStatic
    fun validateThumbToken(filename: String?, token: String?): Boolean {
        if (filename == null || token.isNullOrEmpty()) return false
        val state = getState() ?: return false
        val parts = token.split(".")
        if (parts.size != 3) return false
        return try {
            val content = parts[0] + "." + parts[1]
            val expectedSig = hmacSha256(content, state.deviceSecret)
            if (!MessageDigest.isEqual(
                    expectedSig.toByteArray(StandardCharsets.UTF_8),
                    parts[2].toByteArray(StandardCharsets.UTF_8)
                )
            ) {
                return false
            }
            val headerJson = String(base64UrlDecode(parts[0]), StandardCharsets.UTF_8)
            if ("THM" != extractJsonString(headerJson, "typ")) return false
            val payloadJson = String(base64UrlDecode(parts[1]), StandardCharsets.UTF_8)
            if (filename != extractJsonString(payloadJson, "sub")) return false
            val exp = extractJsonLong(payloadJson, "exp", 0)
            System.currentTimeMillis() / 1000 <= exp
        } catch (e: Exception) {
            log("validateThumbToken failed: " + e.message)
            false
        }
    }

    /**
     * Invalidate cached auth state.
     * Called via IPC when app regenerates token.
     * Next JWT validation will reload from the unified config.
     */
    @JvmStatic
    @Synchronized
    fun invalidateCache() {
        cachedState = null
        cachedConfigMtime = 0
        stateVersion++
        log("Auth cache invalidated - will reload on next validation")
    }

    /**
     * Monotonic counter that bumps every time the cached auth state is
     * replaced. Callers that cache JWTs derived from the state (so they
     * don't pay HMAC cost per request) can pin their cache entry to a
     * specific stateVersion and invalidate when this number moves on.
     */
    @JvmStatic
    fun getStateVersion(): Long = stateVersion

    /** Validate a JWT and extract claims. */
    @JvmStatic
    fun validateJwt(jwt: String?): JwtValidation {
        if (jwt.isNullOrEmpty()) {
            return JwtValidation.failure("No token provided")
        }

        val raw = if (jwt.startsWith("Bearer ")) jwt.substring(7) else jwt

        val parts = raw.split(".")
        if (parts.size != 3) {
            return JwtValidation.failure("Invalid token format")
        }

        val state = getState() ?: return JwtValidation.failure("Auth not initialized")

        return try {
            val content = parts[0] + "." + parts[1]
            val expectedSig = hmacSha256(content, state.deviceSecret)

            if (!MessageDigest.isEqual(
                    expectedSig.toByteArray(StandardCharsets.UTF_8),
                    parts[2].toByteArray(StandardCharsets.UTF_8)
                )
            ) {
                log("JWT signature mismatch - token may have been regenerated")
                return JwtValidation.failure("Invalid signature")
            }

            val payloadJson = String(base64UrlDecode(parts[1]), StandardCharsets.UTF_8)
            val exp = extractJsonLong(payloadJson, "exp", Long.MIN_VALUE)
            if (exp == Long.MIN_VALUE) {
                return JwtValidation.failure("Token validation error: missing exp")
            }
            if (System.currentTimeMillis() / 1000 > exp) {
                return JwtValidation.failure("Token expired")
            }

            val tokenEpoch = extractJsonLong(payloadJson, "ver", 0)
            if (tokenEpoch != state.tokenEpoch) {
                return JwtValidation.failure("Session rotated")
            }

            val tokenDeviceId = extractJsonString(payloadJson, "sub")
            if (tokenDeviceId.isNullOrEmpty()) {
                return JwtValidation.failure("Token validation error: missing sub")
            }
            if (tokenDeviceId != state.deviceId) {
                return JwtValidation.failure("Device mismatch")
            }

            // A companion's session dies with its pairing (BladeWatch-rdtj.7).
            val companionId = extractJsonString(payloadJson, "cid")
            if (companionId != null && !CompanionPairing.shared.isPaired(companionId)) {
                return JwtValidation.failure("Companion un-paired")
            }

            JwtValidation.success(tokenDeviceId)
        } catch (e: Exception) {
            JwtValidation.failure("Token validation error: " + e.message)
        }
    }

    // ==================== UNIFIED CONFIG I/O ====================

    /**
     * Load auth state from the unified config. Returns null if the auth
     * section is absent or has no secret (treat as "not initialized").
     */
    private fun loadFromConfig(): AuthState? {
        return try {
            val section = UnifiedConfigManager.loadConfig().optJSONObject(CONFIG_SECTION)
            val secret = SecretConfigBridge.getString(CONFIG_SECTION, KEY_DEVICE_SECRET)
            if (secret.isNullOrEmpty()) return null
            if (section == null) {
                return AuthState().apply {
                    deviceId = loadDeviceId()
                    deviceSecret = secret
                }
            }
            AuthState.fromJson(section).apply {
                deviceSecret = secret
                if (tokenEpoch < 0) tokenEpoch = 0
            }
        } catch (e: Exception) {
            log("Failed to load auth from unified config: " + e.message)
            null
        }
    }

    /**
     * Persist auth state to the unified config. UnifiedConfigManager
     * handles the world-rw chmod and atomic-rename write, so both the
     * daemon (UID 2000) and the app process (UID 10xxx) see the new
     * value once the file has been created.
     *
     * Important caveat: UnifiedConfigManager.updateSection mutates its
     * in-memory cache in-place BEFORE the disk write, so when the disk
     * write fails (cross-UID, before the daemon has created the file)
     * the in-memory cache can retain a stale auth section. We force a
     * reload on failure so the next reader does not keep a phantom state.
     *
     * deviceId/tokenEpoch are ALSO mirrored into the secret store's "auth"
     * section (alongside deviceSecret, which lives there exclusively) —
     * BladeWatch-b195: the Flutter APK's JwtMinter can only reach this
     * config over the secret_get_section IPC command, which reads
     * exclusively from SecretConfigStore. Before this, secret_get_section
     * could only ever return deviceSecret, so JwtMinter's deviceId check
     * always failed and every Flutter-side RPC call went out unauthenticated.
     * These two fields are not secret; storing them in the 600 secrets file
     * alongside the real secret is no worse for confidentiality than the
     * status quo, and keeps JwtMinter.kt's single IPC call unchanged. See
     * [writeSecretStoreMirror] for that half, tested in isolation.
     */
    private fun writeToConfig(state: AuthState): Boolean {
        return try {
            // Captured once, up front, and reused for both rollback points below so a
            // failure at either step restores the same pre-write state.
            val prior = SecretStoreSnapshot.capture()

            if (!writeSecretStoreMirror(state, prior)) {
                return false
            }

            if (UnifiedConfigManager.updateSection(CONFIG_SECTION, state.toJson())) {
                cachedConfigMtime = UnifiedConfigManager.getLastModified()
                return true
            }

            log("Failed to persist public auth state; rolling back secret write")
            prior.restore()
            UnifiedConfigManager.forceReload()
            false
        } catch (e: Exception) {
            log("Failed to write auth to unified config: " + e.message)
            try {
                UnifiedConfigManager.forceReload()
            } catch (ignored: Exception) {
                log("forceReload after write failure also failed: " + ignored.message)
            }
            false
        }
    }

    /**
     * Writes deviceSecret (exclusively) and mirrors deviceId/tokenEpoch into
     * the secret store's "auth" section — see [writeToConfig]'s doc
     * comment for why the mirror exists (BladeWatch-b195). Factored out of
     * writeToConfig so it can be exercised directly in a JVM test via
     * `SecretConfigBridge.directStoreForTest` without also touching
     * UnifiedConfigManager (a separate, real-file-path-hardcoded class with its own
     * untested I/O boundary).
     *
     * Public rather than package-private because AuthManagerTest is a Java test and
     * Kotlin mangles `internal` member names, which Java cannot spell.
     *
     * Rolls back the secret write on its own if the mirror fails, so callers
     * that get `false` back can treat the secret store as untouched.
     */
    @JvmStatic
    fun writeSecretStoreMirror(state: AuthState): Boolean {
        // Snapshot what is in the store BEFORE touching it. A rollback has to put these
        // back; deleting deviceId/tokenEpoch instead (as this used to do) destroys the
        // values an already-paired device was relying on, so a failed re-pair left the
        // store worse off than if the write had never been attempted — and JwtMinter,
        // which reads exactly these keys over secret_get_section, would then mint
        // unauthenticated calls forever.
        return writeSecretStoreMirror(state, SecretStoreSnapshot.capture())
    }

    private fun writeSecretStoreMirror(state: AuthState, prior: SecretStoreSnapshot): Boolean {
        val clearing = state.deviceSecret.isNullOrEmpty()

        val secretOk = if (clearing) {
            SecretConfigBridge.delete(CONFIG_SECTION, KEY_DEVICE_SECRET)
        } else {
            SecretConfigBridge.putString(CONFIG_SECTION, KEY_DEVICE_SECRET, state.deviceSecret)
        }
        if (!secretOk) {
            return false
        }

        val mirrorOk = if (clearing) {
            SecretConfigBridge.delete(CONFIG_SECTION, KEY_DEVICE_ID) &&
                SecretConfigBridge.delete(CONFIG_SECTION, KEY_TOKEN_EPOCH)
        } else {
            SecretConfigBridge.putString(CONFIG_SECTION, KEY_DEVICE_ID, state.deviceId) &&
                SecretConfigBridge.putLong(CONFIG_SECTION, KEY_TOKEN_EPOCH, state.tokenEpoch)
        }
        if (!mirrorOk) {
            log(
                "Failed to mirror deviceId/tokenEpoch into the secret store; " +
                    "rolling back secret write"
            )
            prior.restore()
            return false
        }
        return true
    }

    /**
     * The three secret-store fields [writeSecretStoreMirror] touches, captured
     * before the write so a failure can put them back exactly as they were rather than
     * deleting them. A null field means "was absent", which restores as a delete.
     */
    private class SecretStoreSnapshot private constructor(
        private val deviceSecret: String?,
        private val deviceId: String?,
        private val tokenEpoch: String?
    ) {
        fun restore() {
            restoreKey(KEY_DEVICE_SECRET, deviceSecret)
            restoreKey(KEY_DEVICE_ID, deviceId)
            restoreKey(KEY_TOKEN_EPOCH, tokenEpoch)
        }

        companion object {
            fun capture(): SecretStoreSnapshot = SecretStoreSnapshot(
                SecretConfigBridge.getString(CONFIG_SECTION, KEY_DEVICE_SECRET),
                SecretConfigBridge.getString(CONFIG_SECTION, KEY_DEVICE_ID),
                SecretConfigBridge.getString(CONFIG_SECTION, KEY_TOKEN_EPOCH)
            )

            private fun restoreKey(key: String, value: String?) {
                if (value == null) {
                    SecretConfigBridge.delete(CONFIG_SECTION, key)
                } else {
                    SecretConfigBridge.putString(CONFIG_SECTION, key, value)
                }
            }
        }
    }

    /**
     * Read the legacy single-purpose auth file. Used exactly once during
     * migration so devices that were paired before this change keep
     * their secret.
     */
    private fun loadLegacyAuthFile(): AuthState? {
        return try {
            val file = File(LEGACY_AUTH_FILE)
            if (!file.exists() || !file.canRead()) return null

            val content = file.readText().trim()
            if (content.isEmpty()) return null

            AuthState.fromJson(JSONObject(content))
        } catch (e: Exception) {
            log("Failed to read legacy auth file: " + e.message)
            null
        }
    }

    private fun loadDeviceId(): String {
        readDeviceIdFile(DEVICE_ID_FILE)?.let { return it }
        readDeviceIdFile(LEGACY_DEVICE_ID_FILE)?.let { return it }
        readDeviceIdFile(LEGACY_CAMERA_DEVICE_ID_FILE)?.let { return it }

        try {
            val serial = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Build.getSerial()
            } else {
                @Suppress("DEPRECATION")
                Build.SERIAL
            }
            if (serial != null && serial != "unknown") {
                return stableDeviceId(serial)
            }
        } catch (e: Exception) {
            log("Error reading device serial: " + e.message)
        }

        try {
            val fingerprint = Build.FINGERPRINT
            if (!fingerprint.isNullOrEmpty()) {
                return stableDeviceId(fingerprint)
            }
        } catch (e: Exception) {
            log("Error reading build fingerprint: " + e.message)
        }

        // File doesn't exist yet and hardware IDs were unavailable — temp ID.
        // MainActivity writes the real persistent file via ADB shell on app
        // launch; the next reconcile in getState() picks up the canonical ID
        // from the unified config.
        val tempId = "byd-" + generateSecret(8)
        log("Device ID file not found, using temporary ID: $tempId")
        return tempId
    }

    private fun readDeviceIdFile(path: String): String? {
        try {
            val file = File(path)
            if (file.exists()) {
                file.bufferedReader().use { reader ->
                    val id = reader.readLine()
                    if (id != null && id.startsWith("byd-")) {
                        return id.trim()
                    }
                }
            }
        } catch (e: Exception) {
            log("Error reading device ID file: " + e.message)
        }
        return null
    }

    private fun stableDeviceId(source: String): String =
        "byd-" + String.format(Locale.US, "%08x", source.hashCode())

    // ==================== CRYPTO UTILS ====================

    private fun generateSecret(length: Int): String {
        val chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        val random = SecureRandom()
        val sb = StringBuilder(length)
        repeat(length) {
            sb.append(chars[random.nextInt(chars.length)])
        }
        return sb.toString()
    }

    @Throws(Exception::class)
    private fun hmacSha256(data: String, secret: String?): String {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(
            SecretKeySpec((secret ?: "").toByteArray(StandardCharsets.UTF_8), "HmacSHA256")
        )
        return base64UrlEncode(mac.doFinal(data.toByteArray(StandardCharsets.UTF_8)))
    }

    private fun base64UrlEncode(data: ByteArray): String =
        Base64.getUrlEncoder().withoutPadding().encodeToString(data)

    private fun base64UrlDecode(data: String): ByteArray = Base64.getUrlDecoder().decode(data)

    private fun escapeJson(value: String?): String {
        if (value == null) return ""
        return value.replace("\\", "\\\\").replace("\"", "\\\"")
    }

    private fun extractJsonString(json: String?, key: String?): String? {
        if (json == null || key == null) return null
        val needle = "\"$key\""
        val keyIndex = json.indexOf(needle)
        if (keyIndex < 0) return null
        val colon = json.indexOf(':', keyIndex + needle.length)
        if (colon < 0) return null
        var start = colon + 1
        while (start < json.length && json[start].isWhitespace()) start++
        if (start >= json.length || json[start] != '"') return null
        val out = StringBuilder()
        var escape = false
        for (i in start + 1 until json.length) {
            val c = json[i]
            if (escape) {
                out.append(c)
                escape = false
                continue
            }
            if (c == '\\') {
                escape = true
                continue
            }
            if (c == '"') {
                return out.toString()
            }
            out.append(c)
        }
        return null
    }

    private fun extractJsonLong(json: String?, key: String?, defaultValue: Long): Long {
        if (json == null || key == null) return defaultValue
        val needle = "\"$key\""
        val keyIndex = json.indexOf(needle)
        if (keyIndex < 0) return defaultValue
        val colon = json.indexOf(':', keyIndex + needle.length)
        if (colon < 0) return defaultValue
        var start = colon + 1
        while (start < json.length && json[start].isWhitespace()) start++
        var end = start
        while (end < json.length) {
            val c = json[end]
            if ((c in '0'..'9') || c == '-' || c == '+') {
                end++
                continue
            }
            break
        }
        if (end == start) return defaultValue
        return try {
            json.substring(start, end).toLong()
        } catch (e: NumberFormatException) {
            defaultValue
        }
    }

    private fun log(message: String) {
        CameraDaemon.log("AUTH: $message")
    }

    @JvmStatic
    fun setTestState(state: AuthState?) {
        testStateOverride = state
    }

    @JvmStatic
    fun clearTestState() {
        testStateOverride = null
        cachedState = null
        cachedConfigMtime = 0
        lastInitAttemptMs = 0
    }

    @JvmStatic
    fun getJwtExpirySeconds(): Long = JWT_EXPIRY_MS / 1000L
}
