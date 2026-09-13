package net.bladewatch.bladewatch_ui.adb

import dadb.AdbKeyPair
import java.io.File
import java.security.KeyFactory
import java.security.PrivateKey
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Base64
import javax.crypto.Cipher

/**
 * Holds the RSA key pair the hand-rolled Dart ADB client
 * (`flutter_ui/lib/adb/adb_client.dart`) authenticates with — BladeWatch-yz1e.4's
 * ADB Console. Mirrors `app/src/main/java/com/loabletech/bladewatch/launcher/AdbShellExecutor.kt`'s
 * `getOrCreateAdbKeyPair()`, but deliberately keeps a SEPARATE key pair under
 * this APK's own [privateKeyFile]/[publicKeyFile] rather than reading the main
 * app's `net.bladewatch.app` key: both APKs share a UID (see
 * `flutter_ui/android/app/build.gradle.kts`'s signing comment) so the files
 * are technically reachable, but the main app's private key file format is an
 * internal implementation detail of the `dadb` library, not a documented
 * contract — safer to generate this APK's own pair than to depend on an
 * unverified byte-for-byte format match. Practical consequence: adbd treats
 * this as a separate, not-yet-authorized client the first time it connects on
 * a given head unit, even when the native app's own ADB console is already
 * authorized. See BladeWatch-yz1e.4's task notes for Phase 3 to verify.
 *
 * [dev.mobile:dadb](https://github.com/mobile-dev-inc/dadb) is used ONLY for
 * key-pair generation ([AdbKeyPair.generate]) — specifically the ADB/mincrypt
 * public-key wire format ([getPublicKey]'s Montgomery-precomputed struct),
 * which is exotic enough that hand-rolling it from scratch would risk a wrong
 * result with no on-device way for this CODE-ONLY task to catch it. Reading
 * the generated files back, and signing, use plain `java.security` —
 * confirmed against `dadb-1.2.8.jar`'s own bytecode (`dadb.PKCS8.parse`):
 * the private key file is PEM text (`-----BEGIN/END PRIVATE KEY-----`
 * wrapping base64 PKCS#8 DER), not raw DER.
 */
class AdbKeyChannel(private val privateKeyFile: File, private val publicKeyFile: File) {

    companion object {
        // RFC 3447 / PKCS#1 DigestInfo prefix for SHA-1 with no parameters —
        // the fixed 15-byte ASN.1 header OpenSSL's RSA_sign(NID_sha1, ...)
        // prepends to a digest before PKCS#1 v1.5-padding and raw-RSA-signing
        // it. adbd's AUTH_SIGNATURE verification (and every ADB client,
        // including AOSP's own) expects exactly this — NOT a JCE
        // "SHA1withRSA" Signature, which would SHA-1-hash the token again
        // instead of treating it as an already-final 20-byte digest.
        private val SHA1_DIGEST_INFO_PREFIX = byteArrayOf(
            0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14,
        )
    }

    /** The ADB-formatted public key blob ("<base64> <label>"), generating a key pair first if needed. */
    fun getPublicKey(): String {
        ensureKeyPair()
        return publicKeyFile.readText(Charsets.UTF_8).trim()
    }

    /** Signs a 20-byte ADB AUTH token, generating a key pair first if needed. */
    fun sign(token: ByteArray): ByteArray {
        ensureKeyPair()
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.ENCRYPT_MODE, readPrivateKey())
        return cipher.doFinal(SHA1_DIGEST_INFO_PREFIX + token)
    }

    private fun ensureKeyPair() {
        if (!privateKeyFile.exists() || !publicKeyFile.exists()) {
            AdbKeyPair.generate(privateKeyFile, publicKeyFile)
        }
    }

    private fun readPrivateKey(): PrivateKey {
        val text = privateKeyFile.readText(Charsets.UTF_8)
        val der = Base64.getDecoder().decode(
            text.replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replace("\n", "")
                .trim(),
        )
        return KeyFactory.getInstance("RSA").generatePrivate(PKCS8EncodedKeySpec(der))
    }
}
