package net.bladewatch.app.server

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.auth.CompanionPairing
import net.bladewatch.app.auth.WifiPairing
import net.bladewatch.app.daemon.CameraDaemon
import org.json.JSONObject
import java.io.OutputStream

/**
 * HTTP handler for the companion app's public calls (BladeWatch-rdtj.7):
 *
 *  - `POST /auth/pair`      -- trade the single-use code from an in-car pairing QR for a credential
 *  - `POST /auth/companion` -- a paired companion trades its token for a session JWT
 *  - `POST /auth/wifi-pair/{start,reveal,result}` -- pairing a device with no camera over the car's
 *    Wi-Fi with a matching number (BladeWatch 1.4.1.2, [WifiPairing]); on the LAN listener only
 *
 * The web app's login (`/auth/token`, `/auth/logout`, `/auth/status`) and its cookie session were
 * removed with the web app (BladeWatch-rdtj.22).
 *
 * No rate limits here, deliberately (BladeWatch-rlgv). What they check cannot be guessed -- a
 * pairing code is 128 random bits, single-use and 5 minutes long; a companion id is 128 random bits
 * and its token an HMAC-SHA256 -- so a limit adds nothing against guessing and only hands anyone who
 * can reach these (the LAN when it is on, anyone with the Pear topic) a way to lock every companion
 * out: every remote peer shares ONE 127.0.0.1 address.
 */
object AuthApiHandler {

    /** Companion pairing (BladeWatch-rdtj.7). Public; listed in AuthMiddleware. */
    const val PAIR_PATH = "/auth/pair"
    const val COMPANION_LOGIN_PATH = "/auth/companion"
    const val WIFI_PAIR_START_PATH = "/auth/wifi-pair/start"
    const val WIFI_PAIR_REVEAL_PATH = "/auth/wifi-pair/reveal"
    const val WIFI_PAIR_RESULT_PATH = "/auth/wifi-pair/result"

    /**
     * Handle an auth request; false when [path] is not one of the companion's. [viaLan] is true
     * when it arrived on the LAN TLS listener: Wi-Fi pairing answers there only, never over Pear --
     * it is for a device in the house, on the car's own network.
     */
    @JvmStatic
    @JvmOverloads
    @Throws(Exception::class)
    fun handle(method: String, path: String, body: String?, out: OutputStream, viaLan: Boolean = false): Boolean {
        if (method == "POST" && path == PAIR_PATH) return handlePairRedeem(body, out)
        if (method == "POST" && path == COMPANION_LOGIN_PATH) return handleCompanionLogin(body, out)
        if (method == "POST" && viaLan && path in WIFI_PAIR_PATHS) return handleWifiPair(path, body, out)
        return false
    }

    private val WIFI_PAIR_PATHS = setOf(WIFI_PAIR_START_PATH, WIFI_PAIR_REVEAL_PATH, WIFI_PAIR_RESULT_PATH)

    /**
     * The device's half of [WifiPairing]. Errors are stable codes: `wifi_pairing_closed` (no window
     * open, another request in progress, or too many attempts) and `wifi_pairing_refused` (the owner
     * said no, the nonce did not match, or the request is gone).
     */
    private fun handleWifiPair(path: String, body: String?, out: OutputStream): Boolean {
        val request = try { JSONObject(body ?: "") } catch (e: Exception) { JSONObject() }
        val pairing = WifiPairing.shared
        val id = request.optString("id", "")
        val response = JSONObject()
        when (path) {
            WIFI_PAIR_START_PATH -> {
                val started = unhex(request.optString("commitment", ""))?.let { pairing.start(request.optString("name", ""), it) }
                if (started == null) {
                    response.put("success", false).put("error", "wifi_pairing_closed")
                } else {
                    response.put("success", true).put("id", started.id).put("carNonce", hex(started.carNonce))
                }
            }
            WIFI_PAIR_REVEAL_PATH -> {
                // A malformed nonce is a wrong one: it ends the request, so it cannot block the next.
                val nonce = unhex(request.optString("deviceNonce", "")) ?: ByteArray(0)
                if (pairing.reveal(id, nonce, TcpCommandServer.lanTlsFingerprint())) {
                    response.put("success", true)
                } else {
                    response.put("success", false).put("error", "wifi_pairing_refused")
                }
            }
            else -> when (val result = pairing.result(id) { TcpCommandServer.mintPairing() }) {
                WifiPairing.Result.Waiting -> response.put("success", true).put("state", "waiting")
                WifiPairing.Result.Refused -> response.put("success", false).put("error", "wifi_pairing_refused")
                is WifiPairing.Result.Accepted -> {
                    response.put("success", true).put("state", "accepted").put("payload", result.payload.encode())
                    log("Wi-Fi pairing confirmed in the car")
                }
            }
        }
        HttpResponse.sendJson(out, response.toString())
        return true
    }

    /** 32 bytes from 64 hex characters, else null. */
    private fun unhex(text: String): ByteArray? {
        if (text.length != WifiPairing.NONCE_BYTES * 2 || !text.all { it in "0123456789abcdef" }) return null
        return text.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    }

    private fun hex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }

    /**
     * Trades the single-use code from an in-car pairing QR for a companion credential
     * (BladeWatch-rdtj.7). The credential is returned once, here, and never again. Errors are
     * stable codes, not localized text: the companion shows its own message.
     */
    private fun handlePairRedeem(body: String?, out: OutputStream): Boolean {
        val request = try { JSONObject(body ?: "") } catch (e: Exception) { JSONObject() }
        val credential = CompanionPairing.shared.redeem(request.optString("code", ""), request.optString("name", ""))
        val response = JSONObject()
        if (credential == null) {
            response.put("success", false).put("error", "pairing_code_refused")
        } else {
            response.put("success", true).put("companionId", credential.companionId).put("token", credential.token)
            log("Companion paired")
        }
        HttpResponse.sendJson(out, response.toString())
        return true
    }

    /** A paired companion trades its token for a session JWT, carried in the body, not a cookie. */
    private fun handleCompanionLogin(body: String?, out: OutputStream): Boolean {
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
            response.put("success", true).put("jwt", jwt).put("expiresIn", AuthManager.getJwtExpirySeconds())
        }
        HttpResponse.sendJson(out, response.toString())
        return true
    }

    private fun log(message: String) {
        CameraDaemon.log("AUTH: $message")
    }
}
