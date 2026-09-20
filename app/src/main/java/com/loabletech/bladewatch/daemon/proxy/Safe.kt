package net.bladewatch.app.daemon.proxy

import android.util.Base64
import net.bladewatch.app.logging.DaemonLogger
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * String de-obfuscation, in pure Kotlin/Java rather than JNI.
 *
 * This replaces a native (JNI) approach that was unstable in app_process daemons.
 *
 * Approach: the key is split into 4 parts stored as byte arrays (which defeats the `strings`
 * command), reconstructed at runtime on the stack (invisible to static analysis), and used for
 * AES-256-CBC. A decompiler sees scattered byte arrays rather than a "KEY" variable.
 *
 * **This is obfuscation, not confidentiality.** The AES key ships inside the APK and can be
 * recovered by decompiling. Use it for internal paths, service names, shell commands and package
 * names only. Secrets — credentials, tokens, API keys — belong in bladewatch_secrets.json via
 * SecretConfigStore, written at runtime by the daemon process (UID 2000).
 *
 * Trade-off: less secure than native code, but 100% stable across Android versions. For a
 * persistence daemon, stability matters more than theoretical security.
 *
 * Usage: `Safe.s("base64_encrypted_string")` returns the plaintext.
 */
object Safe {

    private val logger: DaemonLogger = DaemonLogger.getInstance("Safe")

    // Key split into 4 parts — looks like random data in decompiled code. The real key is 32 bytes
    // for AES-256; these byte values are ASCII codes that form it when concatenated.
    private val K_PART_1 = byteArrayOf(0x38, 0x39, 0x33, 0x38, 0x34, 0x37, 0x32, 0x38)
    private val K_PART_2 = byteArrayOf(0x33, 0x37, 0x34, 0x38, 0x32, 0x39, 0x33, 0x30)
    private val K_PART_3 = byteArrayOf(0x31, 0x38, 0x32, 0x37, 0x33, 0x38, 0x34, 0x39)
    private val K_PART_4 = byteArrayOf(0x31, 0x30, 0x32, 0x39, 0x33, 0x38, 0x34, 0x37)

    // IV: 16 bytes for AES-CBC
    private val I_RAW = byteArrayOf(
        0x31, 0x30, 0x32, 0x39, 0x33, 0x38, 0x34, 0x37,
        0x35, 0x36, 0x31, 0x30, 0x32, 0x39, 0x33, 0x38
    )

    /**
     * Decrypt an AES-256-CBC encrypted, Base64-encoded string.
     *
     * @param encrypted Base64-encoded ciphertext
     * @return the plaintext, "ERR" on failure, or an empty string if the input is null or empty
     */
    @JvmStatic
    fun s(encrypted: String?): String {
        return try {
            if (encrypted.isNullOrEmpty()) {
                return ""
            }

            // Reconstruct the key at runtime on the stack: this happens in CPU registers and
            // stack, invisible to static file analysis.
            val keyBytes = ByteArray(32)
            System.arraycopy(K_PART_1, 0, keyBytes, 0, 8)
            System.arraycopy(K_PART_2, 0, keyBytes, 8, 8)
            System.arraycopy(K_PART_3, 0, keyBytes, 16, 8)
            System.arraycopy(K_PART_4, 0, keyBytes, 24, 8)

            // Standard AES-256-CBC decryption
            val cipher = Cipher.getInstance("AES/CBC/PKCS5PADDING")
            cipher.init(
                Cipher.DECRYPT_MODE,
                SecretKeySpec(keyBytes, "AES"),
                IvParameterSpec(I_RAW)
            )

            val decrypted = cipher.doFinal(Base64.decode(encrypted, Base64.NO_WRAP))

            String(decrypted, Charsets.UTF_8)
        } catch (e: Exception) {
            logger.error("Safe.s() decryption failed: " + e.message)
            // An error marker — helps debugging without exposing details.
            "ERR"
        }
    }
}
