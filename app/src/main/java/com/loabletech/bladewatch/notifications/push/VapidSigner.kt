package net.bladewatch.app.notifications.push

import org.json.JSONObject
import java.math.BigInteger
import java.net.URI
import java.security.Signature
import java.util.Arrays

/**
 * VAPID JWT signer. Builds an ES256 JWT for one push request, with the audience set to the origin
 * of the subscription endpoint (RFC 8292 §2).
 *
 * Push services require this signature to authorise the request and cap unauthenticated abuse.
 * The same signing key is used across every subscription served by this device.
 *
 * Java's `Signature.getInstance("SHA256withECDSA")` returns an ASN.1 DER-encoded signature; JWT
 * requires the raw 64-byte (r||s) form, so we transcode.
 *
 * @param contact optional contact email/URL (RFC 8292 §2.1). Empty string is acceptable.
 */
class VapidSigner(private val keyStore: VapidKeyStore, contact: String?) {

    private val contact: String = contact ?: ""

    /** Build a JWT valid for ~12 hours, scoped to the audience derived from the push endpoint. */
    @Throws(Exception::class)
    fun signFor(endpoint: String): String {
        val uri = URI.create(endpoint)
        val audience = uri.scheme + "://" + uri.authority

        val nowSec = System.currentTimeMillis() / 1000L
        val expSec = nowSec + 12 * 3600L

        // Header
        val header = JSONObject()
        header.put("typ", "JWT")
        header.put("alg", "ES256")

        // Claims
        val claims = JSONObject()
        claims.put("aud", audience)
        claims.put("exp", expSec)
        if (contact.isNotEmpty()) {
            // Per RFC 8292 the sub claim should be a contact URI (mailto: or https:)
            claims.put(
                "sub",
                if (contact.startsWith("mailto:") || contact.startsWith("http")) {
                    contact
                } else {
                    "mailto:$contact"
                }
            )
        }

        val headerB64 = B64Url.enc(header.toString().toByteArray(Charsets.UTF_8))
        val claimsB64 = B64Url.enc(claims.toString().toByteArray(Charsets.UTF_8))
        val signingInput = "$headerB64.$claimsB64"

        val priv = keyStore.privateKey()
        val sig = Signature.getInstance("SHA256withECDSA")
        sig.initSign(priv)
        sig.update(signingInput.toByteArray(Charsets.UTF_8))
        val derSig = sig.sign()

        val rawSig = derToRawP1363(derSig, 32)
        return signingInput + "." + B64Url.enc(rawSig)
    }

    companion object {
        /**
         * Convert a JCA ECDSA signature (ASN.1 DER `SEQUENCE(r,s)`) into the raw IEEE P1363 form
         * (`r || s`) required by JWT/JOSE. Each component is left-padded to [partLen] bytes.
         */
        @JvmStatic
        fun derToRawP1363(der: ByteArray, partLen: Int): ByteArray {
            // DER:  30 [len] 02 [rLen] r 02 [sLen] s
            // len, rLen, sLen each may be short-form (single byte 0x00..0x7F) or long-form
            // (0x81 LL, 0x82 LL LL ...). For ES256 the sequence is always short-form (≤ 72
            // bytes), but parse generally to be safe.
            require(der[0].toInt() == 0x30) { "not a DER sequence" }

            val idx = 1 + lengthFieldSize(der, 1)

            require(der[idx].toInt() == 0x02) { "expected INTEGER (r)" }
            val rLenSize = lengthFieldSize(der, idx + 1)
            val rLen = readLength(der, idx + 1)
            val rStart = idx + 1 + rLenSize
            val rEnd = rStart + rLen

            require(der[rEnd].toInt() == 0x02) { "expected INTEGER (s)" }
            val sLenSize = lengthFieldSize(der, rEnd + 1)
            val sLen = readLength(der, rEnd + 1)
            val sStart = rEnd + 1 + sLenSize
            val sEnd = sStart + sLen

            val r = BigInteger(1, Arrays.copyOfRange(der, rStart, rEnd))
            val s = BigInteger(1, Arrays.copyOfRange(der, sStart, sEnd))

            val out = ByteArray(partLen * 2)
            val rb = VapidKeyStore.unsignedBytes(r, partLen)
            val sb = VapidKeyStore.unsignedBytes(s, partLen)
            System.arraycopy(rb, 0, out, 0, partLen)
            System.arraycopy(sb, 0, out, partLen, partLen)
            return out
        }

        /** Number of bytes occupied by an ASN.1 BER/DER length field starting at [off]. */
        private fun lengthFieldSize(buf: ByteArray, off: Int): Int {
            val b = buf[off].toInt() and 0xFF
            return if ((b and 0x80) == 0) 1 else 1 + (b and 0x7F)
        }

        /** Decode the length value written at [off]. */
        private fun readLength(buf: ByteArray, off: Int): Int {
            val b = buf[off].toInt() and 0xFF
            if ((b and 0x80) == 0) return b
            val n = b and 0x7F
            var len = 0
            for (i in 1..n) {
                len = (len shl 8) or (buf[off + i].toInt() and 0xFF)
            }
            return len
        }
    }
}
