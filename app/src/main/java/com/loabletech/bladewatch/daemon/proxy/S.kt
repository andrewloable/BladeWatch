package net.bladewatch.app.daemon.proxy

/**
 * Short alias for string decryption: `S.d("encrypted_base64")` -> plaintext.
 *
 * Exists purely for brevity in obfuscated code. The decryption itself lives in `Safe`.
 */
object S {
    /**
     * Decrypt an encrypted string.
     *
     * @param e Base64-encoded AES-encrypted string
     * @return decrypted plaintext
     */
    @JvmStatic
    fun d(e: String): String = Safe.s(e)
}
