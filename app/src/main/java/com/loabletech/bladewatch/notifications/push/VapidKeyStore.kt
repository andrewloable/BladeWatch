package net.bladewatch.app.notifications.push

import android.util.Base64
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.math.BigInteger
import java.security.KeyFactory
import java.security.KeyPair
import java.security.KeyPairGenerator
import java.security.interfaces.ECPrivateKey
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.X509EncodedKeySpec
import java.util.concurrent.atomic.AtomicReference

/**
 * Persistent VAPID keypair (ECDSA secp256r1 / P-256).
 *
 * Generated once on first read, stored as a JSON file at the configured path. Subsequent loads
 * return the same keypair so the public key stays stable for the life of the install — Web Push
 * subscriptions are bound to the public key, so rotating it would invalidate every existing
 * subscription on every phone.
 */
class VapidKeyStore(private val keyFile: File) {

    private val cached = AtomicReference<KeyPair>()

    /** Uncompressed P-256 public key, 65 bytes (0x04 || X || Y), base64url-encoded. */
    @Volatile
    private var publicKeyB64Url: String? = null

    @Synchronized
    @Throws(Exception::class)
    fun load(): KeyPair {
        cached.get()?.let { return it }

        var kp: KeyPair? = null
        if (keyFile.exists() && keyFile.length() > 0) {
            kp = readFromDisk()
        }
        if (kp == null) {
            kp = generateAndPersist()
        }
        cached.set(kp)
        publicKeyB64Url = encodeUncompressedPublicKey(kp.public as ECPublicKey)
        return kp
    }

    /**
     * Public key in the form Web Push clients expect for `applicationServerKey` — uncompressed
     * P-256, base64url, no padding.
     */
    @Throws(Exception::class)
    fun publicKeyB64Url(): String {
        if (publicKeyB64Url == null) load()
        return publicKeyB64Url!!
    }

    @Throws(Exception::class)
    fun privateKey(): ECPrivateKey = load().private as ECPrivateKey

    @Throws(Exception::class)
    fun publicKey(): ECPublicKey = load().public as ECPublicKey

    // ==================== INTERNAL ====================

    private fun readFromDisk(): KeyPair? = try {
        FileInputStream(keyFile).use { fis ->
            val json = String(readAll(fis), Charsets.UTF_8)
            val j = JSONObject(json)
            val privDer = Base64.decode(j.getString("privPkcs8"), Base64.NO_WRAP)
            val pubDer = Base64.decode(j.getString("pubX509"), Base64.NO_WRAP)

            val kf = KeyFactory.getInstance("EC")
            val priv = kf.generatePrivate(PKCS8EncodedKeySpec(privDer))
            val pub = kf.generatePublic(X509EncodedKeySpec(pubDer))
            KeyPair(pub, priv)
        }
    } catch (e: Exception) {
        logger.warn("Failed to read VAPID key file, will generate new key: " + e.message)
        null
    }

    @Throws(Exception::class)
    private fun generateAndPersist(): KeyPair {
        val kpg = KeyPairGenerator.getInstance("EC")
        kpg.initialize(ECGenParameterSpec("secp256r1"))
        val kp = kpg.generateKeyPair()

        val parent = keyFile.parentFile
        if (parent != null && !parent.exists()) {
            parent.mkdirs()
        }

        val j = JSONObject()
        j.put("privPkcs8", Base64.encodeToString(kp.private.encoded, Base64.NO_WRAP))
        j.put("pubX509", Base64.encodeToString(kp.public.encoded, Base64.NO_WRAP))
        j.put("createdAt", System.currentTimeMillis())

        val tmp = File(keyFile.absolutePath + ".tmp")
        FileOutputStream(tmp).use { fos ->
            fos.write(j.toString().toByteArray(Charsets.UTF_8))
            fos.fd.sync()
        }
        if (!tmp.renameTo(keyFile)) {
            // renameTo fails silently on some filesystems if dest exists
            keyFile.delete()
            if (!tmp.renameTo(keyFile)) {
                throw IOException("Failed to persist VAPID key file")
            }
        }
        return kp
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("VapidKeyStore")

        @Throws(Exception::class)
        private fun readAll(fis: FileInputStream): ByteArray {
            val out = ByteArrayOutputStream()
            val buf = ByteArray(4096)
            while (true) {
                val n = fis.read(buf)
                if (n <= 0) break
                out.write(buf, 0, n)
            }
            return out.toByteArray()
        }

        /**
         * Encode a P-256 public key as an uncompressed point (0x04 || X || Y), 65 bytes,
         * base64url-encoded with no padding (Web Push spec).
         */
        private fun encodeUncompressedPublicKey(pub: ECPublicKey): String {
            val xBytes = unsignedBytes(pub.w.affineX, 32)
            val yBytes = unsignedBytes(pub.w.affineY, 32)
            val raw = ByteArray(65)
            raw[0] = 0x04
            System.arraycopy(xBytes, 0, raw, 1, 32)
            System.arraycopy(yBytes, 0, raw, 33, 32)
            return Base64.encodeToString(
                raw, Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            )
        }

        /** Big-endian unsigned bytes, left-padded to [length]. */
        @JvmStatic
        fun unsignedBytes(bi: BigInteger, length: Int): ByteArray {
            val signed = bi.toByteArray()
            if (signed.size == length) return signed
            val out = ByteArray(length)
            if (signed.size < length) {
                System.arraycopy(signed, 0, out, length - signed.size, signed.size)
            } else {
                // strip leading sign byte
                System.arraycopy(signed, signed.size - length, out, 0, length)
            }
            return out
        }
    }
}
