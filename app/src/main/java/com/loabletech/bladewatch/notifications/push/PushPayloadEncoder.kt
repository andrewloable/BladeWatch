package net.bladewatch.app.notifications.push

import java.math.BigInteger
import java.nio.ByteBuffer
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.SecureRandom
import java.security.interfaces.ECPrivateKey
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec
import java.security.spec.ECParameterSpec
import java.security.spec.ECPoint
import java.security.spec.ECPublicKeySpec
import java.util.Arrays
import javax.crypto.Cipher
import javax.crypto.KeyAgreement
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * RFC 8291 (Web Push aes128gcm content encoding) payload encoder.
 *
 * This is the format that Chrome (FCM), Safari (web.push.apple.com) and Firefox all support. The
 * older aesgcm encoding is deprecated and not implemented here.
 *
 * Layout:
 * ```
 *   header := salt(16) || rs(4 BE) || idlen(1) || keyid(idlen)
 *   body   := AES-128-GCM(plaintext || 0x02, key, nonce)
 *   wire   := header || body
 * ```
 *
 * Each call generates a fresh ephemeral ECDH keypair and salt, so the same plaintext produces a
 * different wire payload every time — by design.
 *
 * BouncyCastle is not bundled (verified), so this uses only stock `java.security` /
 * `javax.crypto` primitives. HKDF is implemented by hand since Android's stock JCE doesn't
 * expose it.
 */
object PushPayloadEncoder {

    private const val RS = 4096
    private val RNG = SecureRandom()

    /** RFC 8291 terminates each info string with a NUL. Built, not escaped, on purpose. */
    private val NUL: String = 0.toChar().toString()

    class Encoded internal constructor(@JvmField val body: ByteArray)

    /**
     * Encode an opaque plaintext (UTF-8 JSON, etc.) for one subscription.
     *
     * @param plaintext payload bytes; must fit within `RS - 17` after adding the GCM tag and
     *   delimiter
     */
    @JvmStatic
    @Throws(Exception::class)
    fun encrypt(plaintext: ByteArray, subP256dh: ByteArray, subAuth: ByteArray): Encoded {
        require(plaintext.size + 17 <= RS) {
            "plaintext too large for single-record aes128gcm"
        }

        // Server ephemeral ECDH keypair — fresh per push
        val kpg = KeyPairGenerator.getInstance("EC")
        kpg.initialize(ECGenParameterSpec("secp256r1"))
        val serverEph = kpg.generateKeyPair()
        val serverPubRaw = uncompressedPoint(serverEph.public as ECPublicKey)

        val subPub = decodeP256(subP256dh)

        // ECDH shared secret
        val ka = KeyAgreement.getInstance("ECDH")
        ka.init(serverEph.private as ECPrivateKey)
        ka.doPhase(subPub, true)
        val sharedSecret = ka.generateSecret()

        // Step 1: HKDF(auth, sharedSecret, info = "WebPush: info" NUL || ua_pub || as_pub, 32)
        val keyInfo = concat(
            ("WebPush: info" + NUL).toByteArray(Charsets.UTF_8),
            subP256dh,
            serverPubRaw
        )
        val ikm = hkdf(subAuth, sharedSecret, keyInfo, 32)

        // Step 2: random salt(16), then derive CEK + nonce
        val salt = ByteArray(16)
        RNG.nextBytes(salt)

        val cek = hkdf(
            salt, ikm, ("Content-Encoding: aes128gcm" + NUL).toByteArray(Charsets.UTF_8), 16
        )
        val nonce = hkdf(
            salt, ikm, ("Content-Encoding: nonce" + NUL).toByteArray(Charsets.UTF_8), 12
        )

        // Step 3: padded plaintext: payload || 0x02 (last-record delimiter)
        val padded = ByteArray(plaintext.size + 1)
        System.arraycopy(plaintext, 0, padded, 0, plaintext.size)
        padded[plaintext.size] = 0x02

        // Step 4: AES-128-GCM
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.ENCRYPT_MODE, SecretKeySpec(cek, "AES"), GCMParameterSpec(128, nonce))
        val ciphertext = c.doFinal(padded)

        // Step 5: prepend header
        val buf = ByteBuffer.allocate(16 + 4 + 1 + serverPubRaw.size + ciphertext.size)
        buf.put(salt)
        buf.putInt(RS)
        buf.put(serverPubRaw.size.toByte())
        buf.put(serverPubRaw)
        buf.put(ciphertext)
        return Encoded(buf.array())
    }

    // ==================== HKDF (RFC 5869) ====================

    /**
     * HKDF-Extract-and-Expand with HMAC-SHA-256. Single-block expand only (length must be at most
     * 32 here).
     */
    @Throws(Exception::class)
    private fun hkdf(salt: ByteArray, ikm: ByteArray, info: ByteArray, length: Int): ByteArray {
        require(length <= 32) { "multi-block HKDF not implemented" }
        // Extract: PRK = HMAC(salt, ikm)
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(salt, "HmacSHA256"))
        val prk = mac.doFinal(ikm)

        // Expand: T(1) = HMAC(PRK, info || 0x01)
        mac.init(SecretKeySpec(prk, "HmacSHA256"))
        mac.update(info)
        mac.update(0x01.toByte())
        val full = mac.doFinal()
        if (full.size == length) return full
        val out = ByteArray(length)
        System.arraycopy(full, 0, out, 0, length)
        return out
    }

    // ==================== EC helpers ====================

    @JvmStatic
    fun uncompressedPoint(pub: ECPublicKey): ByteArray {
        val x = unsignedBytes(pub.w.affineX, 32)
        val y = unsignedBytes(pub.w.affineY, 32)
        val out = ByteArray(65)
        out[0] = 0x04
        System.arraycopy(x, 0, out, 1, 32)
        System.arraycopy(y, 0, out, 33, 32)
        return out
    }

    @JvmStatic
    @Throws(Exception::class)
    fun decodeP256(uncompressed: ByteArray): ECPublicKey {
        require(uncompressed.size == 65 && uncompressed[0].toInt() == 0x04) {
            "expected uncompressed P-256 point (65 bytes, 0x04 prefix)"
        }
        val x = BigInteger(1, Arrays.copyOfRange(uncompressed, 1, 33))
        val y = BigInteger(1, Arrays.copyOfRange(uncompressed, 33, 65))

        // Get the spec by generating a throwaway P-256 keypair — Android's KeyFactory doesn't
        // expose curve parameters directly via name.
        val kpg = KeyPairGenerator.getInstance("EC")
        kpg.initialize(ECGenParameterSpec("secp256r1"))
        val params: ECParameterSpec = (kpg.generateKeyPair().public as ECPublicKey).params

        val spec = ECPublicKeySpec(ECPoint(x, y), params)
        return KeyFactory.getInstance("EC").generatePublic(spec) as ECPublicKey
    }

    private fun unsignedBytes(bi: BigInteger, length: Int): ByteArray {
        val signed = bi.toByteArray()
        if (signed.size == length) return signed
        val out = ByteArray(length)
        if (signed.size < length) {
            System.arraycopy(signed, 0, out, length - signed.size, signed.size)
        } else {
            System.arraycopy(signed, signed.size - length, out, 0, length)
        }
        return out
    }

    private fun concat(vararg parts: ByteArray): ByteArray {
        var len = 0
        for (p in parts) len += p.size
        val out = ByteArray(len)
        var off = 0
        for (p in parts) {
            System.arraycopy(p, 0, out, off, p.size)
            off += p.size
        }
        return out
    }
}
