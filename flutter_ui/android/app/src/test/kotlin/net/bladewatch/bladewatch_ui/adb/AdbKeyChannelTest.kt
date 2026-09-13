package net.bladewatch.bladewatch_ui.adb

import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.io.File
import java.security.KeyFactory
import java.security.PublicKey
import java.security.Signature
import java.security.interfaces.RSAPrivateCrtKey
import java.security.spec.PKCS8EncodedKeySpec
import java.security.spec.RSAPublicKeySpec
import java.util.Base64

// RFC 3447 / PKCS#1 DigestInfo prefix for SHA-1 — see AdbKeyChannel's own
// copy of this constant for the full explanation. Duplicated here (rather
// than making AdbKeyChannel expose it) so the test independently encodes
// what a correct verifier expects, instead of trivially agreeing with
// whatever the production constant happens to say.
private val SHA1_DIGEST_INFO_PREFIX = byteArrayOf(
    0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14,
)

class AdbKeyChannelTest {

    private lateinit var dir: File
    private lateinit var privateKeyFile: File
    private lateinit var publicKeyFile: File
    private lateinit var channel: AdbKeyChannel

    @Before
    fun setUp() {
        dir = File.createTempFile("adb_key_channel_test", "").apply { delete(); mkdirs() }
        privateKeyFile = File(dir, "adbkey")
        publicKeyFile = File(dir, "adbkey.pub")
        channel = AdbKeyChannel(privateKeyFile, publicKeyFile)
    }

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    @Test
    fun `getPublicKey generates a key pair on first call when none exists`() {
        assertFalse(privateKeyFile.exists())

        val publicKey = channel.getPublicKey()

        assertTrue(privateKeyFile.exists())
        assertTrue(publicKeyFile.exists())
        assertTrue(publicKey.isNotBlank())
    }

    @Test
    fun `getPublicKey is stable across calls instead of regenerating`() {
        val first = channel.getPublicKey()
        val second = channel.getPublicKey()

        assertEquals(first, second)
    }

    @Test
    fun `getPublicKey reuses an already-generated key pair on a new channel instance`() {
        val first = channel.getPublicKey()

        val secondChannel = AdbKeyChannel(privateKeyFile, publicKeyFile)
        val second = secondChannel.getPublicKey()

        assertEquals(first, second)
    }

    @Test
    fun `sign generates a key pair when none exists yet`() {
        assertFalse(privateKeyFile.exists())

        channel.sign(ByteArray(20) { it.toByte() })

        assertTrue(privateKeyFile.exists())
    }

    @Test
    fun `sign produces a PKCS#1 v1_5 signature over the SHA1 DigestInfo-wrapped token, unhashed`() {
        // adbd's own verification mirrors OpenSSL's RSA_sign(NID_sha1, token, 20, ...): the
        // 20-byte token is treated as an ALREADY-COMPUTED digest, wrapped in the SHA-1
        // DigestInfo ASN.1 prefix, PKCS#1 v1.5-padded, and raw-RSA-signed — it is NOT hashed
        // again first. A JCE "SHA1withRSA" Signature would be the wrong verifier here: it
        // hashes whatever you feed it before wrapping, so verifying the raw token against it
        // would check SHA1(SHA1(token)) instead — "NONEwithRSA" over the pre-built DigestInfo
        // is the correct Java equivalent of adbd's own check (confirmed against a manual
        // BigInteger modPow round-trip and a Cipher-based RSA public-key decrypt of the
        // signature, both recovering the exact DigestInfo+token bytes, before this test was
        // written this way).
        val token = ByteArray(20) { (it * 7).toByte() }

        val signature = channel.sign(token)

        val publicKey = derivePublicKeyFromPrivateKeyFile()
        val verifier = Signature.getInstance("NONEwithRSA")
        verifier.initVerify(publicKey)
        verifier.update(SHA1_DIGEST_INFO_PREFIX + token)
        assertTrue(
            "signature must verify as a raw PKCS#1 v1.5 signature over the SHA1 DigestInfo-wrapped " +
                "token (this is the exact scheme adbd's RSA_sign(NID_sha1, ...) expects)",
            verifier.verify(signature),
        )
    }

    @Test
    fun `sign produces a different signature for a different token`() {
        val signatureA = channel.sign(ByteArray(20) { 1 })
        val signatureB = channel.sign(ByteArray(20) { 2 })

        assertFalse(signatureA.contentEquals(signatureB))
    }

    @Test
    fun `sign is deterministic for the same token and key pair`() {
        val token = ByteArray(20) { 9 }

        val signatureA = channel.sign(token)
        val signatureB = channel.sign(token)

        assertArrayEquals(signatureA, signatureB)
    }

    /**
     * Reconstructs the RSA public key from the private key file's own CRT
     * parameters (modulus + public exponent) — proves [AdbKeyChannel.sign]'s
     * output cryptographically without needing to parse the ADB-specific
     * mincrypt public-key wire format [AdbKeyChannel.getPublicKey] returns.
     */
    private fun derivePublicKeyFromPrivateKeyFile(): PublicKey {
        val text = privateKeyFile.readText(Charsets.UTF_8)
        val der = Base64.getDecoder().decode(
            text.replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replace("\n", "")
                .trim(),
        )
        val factory = KeyFactory.getInstance("RSA")
        val privateKey = factory.generatePrivate(PKCS8EncodedKeySpec(der)) as RSAPrivateCrtKey
        return factory.generatePublic(RSAPublicKeySpec(privateKey.modulus, privateKey.publicExponent))
    }
}
