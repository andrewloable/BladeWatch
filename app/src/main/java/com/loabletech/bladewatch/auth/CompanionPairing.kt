package net.bladewatch.app.auth

import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject

/**
 * Pairing the companion app (BladeWatch-rdtj.7).
 *
 * The owner, in the car, asks for a pairing QR. It carries everything the companion needs to FIND
 * and TRUST the car -- the Pear topic, the LAN TLS pin and port, the discovery probe key, the
 * device id -- plus a single-use CODE that is good for [CODE_TTL_MS]. It carries no credential: the
 * companion redeems the code once, over any path to the car, for its own companion id and token,
 * and from then on exchanges that token for session JWTs. A QR photographed over the owner's
 * shoulder is therefore worthless once redeemed or expired.
 *
 * The companion token is derived, not stored: HMAC-SHA256(device secret, domain || id). Revoking a
 * companion is deleting its id from the [SECTION] of the 600 secret store -- its token stops
 * verifying and every JWT minted for it (they carry its id as `cid`) stops validating, while every
 * other companion keeps working. Rotating the device secret still revokes them all.
 *
 * Mint, list and revoke are IPC commands on 127.0.0.1:19876, reachable only by the in-car UI (peer
 * UID + IPC token): pairing and un-pairing need someone at the car. Codes live in memory in
 * CameraDaemon, which serves both the IPC commands and the redeem endpoint; a restart cancels the
 * outstanding QR, which is the right outcome for something meant to be short-lived.
 */
class CompanionPairing(
    private val store: SecretConfigStore,
    private val deviceSecret: () -> String?,
    private val now: () -> Long = System::currentTimeMillis,
    private val random: SecureRandom = SecureRandom(),
) {
    /** Everything the QR carries. [encode] is what goes into it. */
    class Payload(
        val deviceId: String,
        val pearTopic: String,
        val tlsPort: Int,
        val tlsFingerprint: String,
        val probeKey: String,
        val code: String,
        val expiresAt: Long,
    ) {
        fun toJson(): JSONObject = JSONObject()
            .put("v", PAYLOAD_VERSION)
            .put("deviceId", deviceId)
            .put("pearTopic", pearTopic)
            .put("tlsPort", tlsPort)
            .put("tlsFp", tlsFingerprint)
            .put("probeKey", probeKey)
            .put("code", code)
            .put("exp", expiresAt)

        /** base64url (no padding) of the JSON: QR-alphanumeric-friendly and URL-safe. */
        fun encode(): String =
            Base64.getUrlEncoder().withoutPadding().encodeToString(toJson().toString().toByteArray(StandardCharsets.UTF_8))
    }

    /** What the car tells a companion that redeemed a code. Never logged, never shown again. */
    class Credential(val companionId: String, val token: String)

    class PairedCompanion(val id: String, val name: String, val pairedAt: Long)

    /** Identity facts the caller gathers from the daemon's own stores; see TcpCommandServer. */
    class Identity(
        val deviceId: String,
        val pearTopic: String,
        val tlsPort: Int,
        val tlsFingerprint: String,
        val probeKey: String,
    )

    private val pending = LinkedHashMap<String, Long>() // code -> expiry; guarded by this

    @Synchronized
    fun mint(identity: Identity): Payload {
        purgeExpired()
        while (pending.size >= MAX_PENDING) pending.remove(pending.keys.first()) // newest QR wins
        val code = Base64.getUrlEncoder().withoutPadding().encodeToString(ByteArray(16).also(random::nextBytes))
        val expiresAt = now() + CODE_TTL_MS
        pending[code] = expiresAt
        return Payload(identity.deviceId, identity.pearTopic, identity.tlsPort, identity.tlsFingerprint, identity.probeKey, code, expiresAt)
    }

    /**
     * Trades a pairing code for a new companion's credential, exactly once: the code is consumed on
     * the first attempt that names it, valid or not, and an expired one is refused. null = refused.
     */
    @Synchronized
    fun redeem(code: String, name: String): Credential? {
        val expiresAt = pending.remove(code) ?: return null
        if (expiresAt < now()) return null
        val secret = deviceSecret()?.takeIf { it.isNotEmpty() } ?: return null
        val id = hex(ByteArray(16).also(random::nextBytes))
        val record = JSONObject().put("name", name.trim().take(MAX_NAME).ifEmpty { "Companion" }).put("pairedAt", now())
        if (!store.putString(SECTION, id, record.toString())) return null
        return Credential(id, token(secret, id))
    }

    /** True when [companionId] is paired and [token] is its token. Constant-time on the token. */
    fun verify(companionId: String, token: String): Boolean {
        if (!isPaired(companionId)) return false
        val secret = deviceSecret()?.takeIf { it.isNotEmpty() } ?: return false
        return MessageDigest.isEqual(
            token(secret, companionId).toByteArray(StandardCharsets.UTF_8),
            token.toByteArray(StandardCharsets.UTF_8)
        )
    }

    fun isPaired(companionId: String): Boolean =
        companionId.length == ID_HEX_CHARS && store.getString(SECTION, companionId) != null

    fun list(): List<PairedCompanion> {
        val section = store.loadSection(SECTION)
        return section.keys().asSequence().mapNotNull { id ->
            val record = try { JSONObject(section.getString(id)) } catch (e: Exception) { return@mapNotNull null }
            PairedCompanion(id, record.optString("name", "Companion"), record.optLong("pairedAt"))
        }.sortedBy { it.pairedAt }.toList()
    }

    /** Un-pairs one companion. Its token and every JWT minted for it stop working immediately. */
    fun revoke(companionId: String): Boolean =
        isPaired(companionId) && store.delete(SECTION, companionId)

    private fun purgeExpired() {
        val t = now()
        pending.entries.removeAll { it.value < t }
    }

    companion object {
        const val PAYLOAD_VERSION = 1
        const val SECTION = "companions"

        /** How long a pairing QR is good for. Minutes, not days: it is shown on a screen. */
        const val CODE_TTL_MS = 5 * 60_000L

        private const val MAX_PENDING = 4
        private const val MAX_NAME = 64
        private const val ID_HEX_CHARS = 32
        private val TOKEN_DOMAIN = "bladewatch/companion/v1".toByteArray(StandardCharsets.UTF_8)

        /** The companion's token: base64url(HMAC-SHA256(device secret, domain || 0x00 || id)). */
        fun token(deviceSecret: String, companionId: String): String {
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(SecretKeySpec(deviceSecret.toByteArray(StandardCharsets.UTF_8), "HmacSHA256"))
            mac.update(TOKEN_DOMAIN)
            mac.update(0)
            return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(mac.doFinal(companionId.toByteArray(StandardCharsets.UTF_8)))
        }

        private fun hex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }

        private val daemonInstance by lazy {
            CompanionPairing(SecretConfigStore(), { AuthManager.getState()?.deviceSecret })
        }

        // ponytail: test seam -- non-null replaces the daemon's instance everywhere it is used.
        @JvmField
        @Volatile
        var sharedForTest: CompanionPairing? = null

        /** The daemon's instance: codes are in memory, so there must be exactly one per process. */
        @JvmStatic
        val shared: CompanionPairing
            get() = sharedForTest ?: daemonInstance
    }
}
