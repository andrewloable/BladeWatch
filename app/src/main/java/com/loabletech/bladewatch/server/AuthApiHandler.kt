package net.bladewatch.app.server

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.auth.CompanionPairing
import net.bladewatch.app.daemon.CameraDaemon
import org.json.JSONObject
import java.io.OutputStream

/**
 * HTTP handler for the companion app's two public calls (BladeWatch-rdtj.7):
 *
 *  - `POST /auth/pair`      -- trade the single-use code from an in-car pairing QR for a credential
 *  - `POST /auth/companion` -- a paired companion trades its token for a session JWT
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

    /** Handle an auth request; false when [path] is not one of the companion's. */
    @JvmStatic
    @Throws(Exception::class)
    fun handle(method: String, path: String, body: String?, out: OutputStream): Boolean {
        if (method == "POST" && path == PAIR_PATH) return handlePairRedeem(body, out)
        if (method == "POST" && path == COMPANION_LOGIN_PATH) return handleCompanionLogin(body, out)
        return false
    }

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
