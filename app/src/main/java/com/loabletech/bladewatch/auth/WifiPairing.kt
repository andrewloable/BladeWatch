package net.bladewatch.app.auth

import java.nio.ByteBuffer
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.security.SecureRandom

/**
 * Pairing a device that has no camera -- a TV, a desktop -- over the car's Wi-Fi with a matching
 * number instead of a QR (BladeWatch 1.4.1.2). It ends where QR pairing starts: the device receives
 * the same single-use pairing payload ([CompanionPairing.Payload]) and redeems it as usual. What
 * this adds is a safe way to hand that payload over without a camera.
 *
 * ## The protocol (the companion's `wifi_pairing.dart` must reproduce it exactly)
 *
 * 1. The owner opens "Pair a device" in the car. That opens the pairing [window]; while it is open
 *    the LAN discovery responder answers an unsigned pairing probe, and the endpoints below work.
 * 2. The device connects to the LAN TLS listener, accepting whatever certificate it is shown and
 *    remembering its fingerprint (lowercase hex SHA-256 over the DER).
 * 3. `start`: the device sends its name and a COMMITMENT, SHA-256 of a 32-byte secret nonce. The car
 *    answers with a request id and its own 32-byte nonce.
 * 4. `reveal`: the device sends its nonce; the car checks it against the commitment.
 * 5. Both sides compute [number] from the car's certificate fingerprint and both nonces. The car
 *    shows it with the device's name; the device shows it too. The owner confirms in the car only if
 *    they match.
 * 6. `result`: once confirmed, the car hands over a freshly minted pairing payload, once. The device
 *    checks the payload names the certificate it connected to, and redeems its code as usual.
 *
 * ## Why the number means something
 *
 * A device in the middle would hold two TLS sessions, presenting ITS certificate to the device, so
 * the device's number and the car's number are computed from different fingerprints. To make them
 * agree anyway it would have to choose a nonce after seeing the other side's -- and the commitment
 * stops that on both legs: the device commits before it sees the car's nonce, and a middle device
 * must commit to the car before it sees the car's. One forged number in a million per attempt, and
 * [MAX_ATTEMPTS] attempts per window. This is Bluetooth's numeric comparison.
 *
 * ## Exposure
 *
 * Nothing here works unless the owner is in the car with the dialog open, and nothing pairs without
 * them tapping Confirm. One request at a time, a few per window, the window shuts when the dialog
 * does (or [WINDOW_MS] after its last refresh), and the endpoints answer only on the LAN listener.
 * State lives in memory: a daemon restart cancels everything, like an outstanding QR.
 */
class WifiPairing(
    /** A monotonic clock: a wall-clock jump must not reopen or stretch the window. */
    private val now: () -> Long = { System.nanoTime() / 1_000_000 },
    private val random: SecureRandom = SecureRandom(),
) {
    class Started(val id: String, val carNonce: ByteArray)

    /** A request the owner has to confirm or refuse in the car. */
    class Pending(val id: String, val name: String, val number: String)

    sealed class Result {
        object Waiting : Result()
        object Refused : Result()
        class Accepted(val payload: CompanionPairing.Payload) : Result()
    }

    private class Request(val id: String, val name: String, val commitment: ByteArray, val carNonce: ByteArray, val createdAt: Long) {
        var number: String? = null
        var decision: Boolean? = null
    }

    private var windowUntil = 0L // guarded by this
    private var attempts = 0
    private var request: Request? = null

    /**
     * The in-car dialog opens the window when it opens, refreshes it while it stays open, and shuts
     * it when it closes. Shutting it forgets everything, an undecided request included.
     */
    @Synchronized
    fun window(open: Boolean) {
        if (open) {
            windowUntil = now() + WINDOW_MS
        } else {
            windowUntil = 0
            attempts = 0
            request = null
        }
    }

    @Synchronized
    fun isOpen(): Boolean = now() < windowUntil

    /** Step 3. null = refused: window shut, another request in progress, or too many attempts. */
    @Synchronized
    fun start(name: String, commitment: ByteArray): Started? {
        if (!isOpen() || commitment.size != NONCE_BYTES) return null
        val current = request
        if (current != null && current.decision == null && now() - current.createdAt < REQUEST_TTL_MS) return null
        if (attempts >= MAX_ATTEMPTS) return null
        attempts++
        val started = Started(hex(bytes(16)), bytes(NONCE_BYTES))
        request = Request(started.id, cleanName(name), commitment, started.carNonce, now())
        return started
    }

    /**
     * Step 4: the device's nonce must hash to its commitment; [carFingerprint] is this car's own TLS
     * certificate. false = refused, and a nonce that does not match ends the request.
     */
    @Synchronized
    fun reveal(id: String, deviceNonce: ByteArray, carFingerprint: String): Boolean {
        val r = request?.takeIf { it.id == id && it.number == null && isOpen() } ?: return false
        if (deviceNonce.size != NONCE_BYTES || !MessageDigest.isEqual(sha256(deviceNonce), r.commitment)) {
            request = null
            return false
        }
        r.number = number(carFingerprint, deviceNonce, r.carNonce)
        return true
    }

    /** For the in-car dialog: the request waiting for the owner, with the number to compare. */
    @Synchronized
    fun pending(): Pending? = request?.takeIf { it.number != null && it.decision == null && isOpen() }
        ?.let { Pending(it.id, it.name, it.number!!) }

    /** The owner's answer, in the car. false = no such request waiting. */
    @Synchronized
    fun decide(id: String, accept: Boolean): Boolean {
        val r = request?.takeIf { it.id == id && it.number != null && it.decision == null } ?: return false
        r.decision = accept
        return true
    }

    /**
     * Step 6, polled by the device. An accepted request is handed its payload once, minted by [mint]
     * at that moment; a refused or unknown one is told so.
     */
    @Synchronized
    fun result(id: String, mint: () -> CompanionPairing.Payload): Result {
        val r = request?.takeIf { it.id == id } ?: return Result.Refused
        return when (r.decision) {
            null -> if (isOpen()) Result.Waiting else Result.Refused.also { request = null }
            false -> Result.Refused.also { request = null }
            true -> Result.Accepted(mint()).also { request = null }
        }
    }

    private fun bytes(n: Int) = ByteArray(n).also(random::nextBytes)

    companion object {
        const val NONCE_BYTES = 32

        /** The dialog refreshes it every few seconds; this is how long it outlives the last refresh. */
        const val WINDOW_MS = 15_000L

        /** How long an undecided request blocks another. */
        const val REQUEST_TTL_MS = 120_000L

        /** Attempts per window: each is a one-in-a-million shot at a forged number. */
        const val MAX_ATTEMPTS = 5

        private const val MAX_NAME = 64
        private val DOMAIN = "bladewatch/wifi-pair/v1".toByteArray(StandardCharsets.UTF_8)

        /**
         * The six digits both screens show: the first four bytes of
         * SHA-256(domain | 0x00 | fingerprint (UTF-8 hex) | 0x00 | device nonce | car nonce),
         * big-endian and unsigned, modulo 1 000 000, zero-padded.
         */
        @JvmStatic
        fun number(fingerprint: String, deviceNonce: ByteArray, carNonce: ByteArray): String {
            val digest = MessageDigest.getInstance("SHA-256").run {
                update(DOMAIN)
                update(0)
                update(fingerprint.toByteArray(StandardCharsets.UTF_8))
                update(0)
                update(deviceNonce)
                update(carNonce)
                digest()
            }
            val value = ByteBuffer.wrap(digest, 0, 4).int.toLong() and 0xffffffffL
            return "%06d".format(value % 1_000_000)
        }

        internal fun sha256(data: ByteArray): ByteArray = MessageDigest.getInstance("SHA-256").digest(data)

        private fun cleanName(name: String): String =
            name.filter { !it.isISOControl() }.trim().take(MAX_NAME).ifEmpty { "Device" }

        private fun hex(bytes: ByteArray): String = bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }

        private val daemonInstance by lazy { WifiPairing() }

        // ponytail: test seam -- non-null replaces the daemon's instance everywhere it is used.
        @JvmField
        @Volatile
        var sharedForTest: WifiPairing? = null

        /** The daemon's instance: the window and the request live in memory, one per process. */
        @JvmStatic
        val shared: WifiPairing
            get() = sharedForTest ?: daemonInstance
    }
}
