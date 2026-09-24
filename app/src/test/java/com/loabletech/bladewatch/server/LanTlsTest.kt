package net.bladewatch.app.server

import java.io.File
import java.math.BigInteger
import java.net.InetAddress
import java.nio.file.Files
import java.security.KeyPairGenerator
import java.security.MessageDigest
import java.security.cert.X509Certificate
import java.security.spec.ECGenParameterSpec
import java.util.Calendar
import java.util.Date
import java.util.TimeZone
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext
import javax.net.ssl.SSLServerSocket
import javax.net.ssl.SSLSocket
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import net.bladewatch.app.config.SecretConfigStore
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.4: the LAN listener's TLS identity. What matters is that the certificate is a
 * real, parseable, self-signed certificate; that the fingerprint a companion pins is exactly the
 * one the listener serves; and that it never changes unless it has to.
 */
class LanTlsTest {

    private val dir = Files.createTempDirectory("lan-tls-test").toFile()
    private fun store(name: String = "secrets.json") = SecretConfigStore(File(dir, name))

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    @Test
    fun `the certificate is a valid self-signed v3 EC certificate`() {
        val cert = LanTls.loadOrCreate(store()).certificate
        cert.checkValidity()
        cert.verify(cert.publicKey) // self-signed: signed by its own key
        assertEquals(3, cert.version)
        assertEquals("EC", cert.publicKey.algorithm)
        assertEquals("SHA256withECDSA", cert.sigAlgName)
        assertEquals(cert.subjectX500Principal, cert.issuerX500Principal)
        // Generic on purpose: the subject is readable pre-auth by the whole LAN (BladeWatch-cjhz).
        assertEquals("CN=localhost", cert.subjectX500Principal.name)
    }

    @Test
    fun `it is valid for about ten years`() {
        val cert = LanTls.loadOrCreate(store()).certificate
        val days = TimeUnit.MILLISECONDS.toDays(cert.notAfter.time - cert.notBefore.time)
        assertTrue("validity was $days days", days in 3650L..3652L)
    }

    @Test
    fun `the pin is SHA-256 over the certificate DER, as openssl computes it`() {
        val identity = LanTls.loadOrCreate(store())
        val expected = MessageDigest.getInstance("SHA-256").digest(identity.certificate.encoded)
            .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        assertEquals(expected, identity.fingerprintSha256)
        assertEquals(64, identity.fingerprintSha256.length)
    }

    @Test
    fun `the identity survives a daemon restart unchanged`() {
        val first = LanTls.loadOrCreate(store()).fingerprintSha256
        // A fresh store object on the same file is what a restarted daemon sees.
        val afterRestart = LanTls.loadOrCreate(store()).fingerprintSha256
        assertEquals(first, afterRestart)
    }

    @Test
    fun `an expired certificate is still reused, never rotated`() {
        // Minted "today", then read back fifty years later: expiry must not trigger a new identity,
        // because a new identity is a new fingerprint and strands every paired companion.
        val first = LanTls.loadOrCreate(store(), now = Date()).fingerprintSha256
        val muchLater = Date(System.currentTimeMillis() + TimeUnit.DAYS.toMillis(365L * 50))
        assertEquals(first, LanTls.loadOrCreate(store(), now = muchLater).fingerprintSha256)
    }

    @Test
    fun `different cars get different certificates`() {
        assertNotEquals(
            LanTls.loadOrCreate(store("a.json")).fingerprintSha256,
            LanTls.loadOrCreate(store("b.json")).fingerprintSha256
        )
    }

    @Test
    fun `an unreadable stored identity is replaced and reported`() {
        val s = store()
        s.putString("lanTls", "privateKeyPkcs8", "not-base64-at-all")
        s.putString("lanTls", "certificateDer", "garbage")
        var reported: Exception? = null
        val identity = LanTls.loadOrCreate(s) { reported = it }
        assertTrue("replacement must be reported so it can be logged", reported != null)
        identity.certificate.verify(identity.certificate.publicKey)
        assertEquals(identity.fingerprintSha256, LanTls.loadOrCreate(store()).fingerprintSha256)
    }

    @Test
    fun `a key that does not match its certificate is caught`() {
        val a = LanTls.loadOrCreate(store("a.json"))
        val b = LanTls.loadOrCreate(store("b.json"))
        val mixed = store("mixed.json")
        val b64 = java.util.Base64.getEncoder()
        mixed.putString("lanTls", "privateKeyPkcs8", b64.encodeToString(a.privateKey.encoded))
        mixed.putString("lanTls", "certificateDer", b64.encodeToString(b.certificate.encoded))
        var reported: Exception? = null
        LanTls.loadOrCreate(mixed) { reported = it }
        assertTrue("a mismatched pair would fail every handshake; it must be detected", reported != null)
    }

    @Test
    fun `only TLS 1_2 and 1_3 are enabled`() {
        val offered = arrayOf("SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2", "TLSv1.3")
        assertArrayEquals(arrayOf("TLSv1.2", "TLSv1.3"), LanTls.enabledProtocols(offered))
    }

    @Test
    fun `a real handshake presents exactly the pinned certificate`() {
        val identity = LanTls.loadOrCreate(store())
        val server = LanTls.serverSocketFactory(identity)
            .createServerSocket(0, 1, InetAddress.getLoopbackAddress()) as SSLServerSocket
        server.enabledProtocols = LanTls.enabledProtocols(server.supportedProtocols)
        val pool = Executors.newSingleThreadExecutor()
        try {
            val accepted = pool.submit<Unit> {
                (server.accept() as SSLSocket).use { it.startHandshake(); it.outputStream.write(1) }
            }
            // A pinning client, the way the companion will be: trust nothing, then compare the pin.
            val trustAll = arrayOf<TrustManager>(object : X509TrustManager {
                override fun checkClientTrusted(chain: Array<out X509Certificate>, authType: String) {}
                override fun checkServerTrusted(chain: Array<out X509Certificate>, authType: String) {}
                override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
            })
            val client = SSLContext.getInstance("TLS").apply { init(null, trustAll, null) }
                .socketFactory.createSocket(InetAddress.getLoopbackAddress(), server.localPort) as SSLSocket
            client.use {
                it.startHandshake()
                val presented = it.session.peerCertificates[0].encoded
                val pin = MessageDigest.getInstance("SHA-256").digest(presented)
                    .joinToString("") { b -> "%02x".format(b.toInt() and 0xff) }
                assertEquals("the served certificate must be the one the pairing QR pins", identity.fingerprintSha256, pin)
                assertTrue(it.session.protocol, it.session.protocol in setOf("TLSv1.2", "TLSv1.3"))
                assertEquals(1, it.inputStream.read())
            }
            accepted.get(10, TimeUnit.SECONDS)
        } finally {
            server.close()
            pool.shutdownNow()
        }
    }

    @Test
    fun `dates from 2050 use GeneralizedTime and survive the round trip`() {
        // RFC 5280: UTCTime has a two-digit year and is only valid through 2049.
        val keyPair = KeyPairGenerator.getInstance("EC").apply { initialize(ECGenParameterSpec("secp256r1")) }
            .generateKeyPair()
        val notAfter = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear(); set(2061, Calendar.MARCH, 4, 5, 6, 7)
        }.time
        val cert = SelfSignedCert.build(keyPair, "t", Date(), notAfter, BigInteger.TEN)
        assertEquals(notAfter, cert.notAfter)
        cert.verify(keyPair.public)
    }

    @Test
    fun `plain HTTP binds loopback only -- 0_0_0_0 appears solely in the TLS listener`() {
        // Plaintext must never leave the device: the Bearer JWT would cross a shared Wi-Fi in the
        // clear. A source check, because the bind happens in a daemon loop no unit test can host.
        var root = File("src/main/java/com/loabletech/bladewatch")
        if (!root.isDirectory) root = File("app/src/main/java/com/loabletech/bladewatch")
        val src = File(root, "server/HttpServer.kt").readText()
        val listener = src.indexOf("private fun runLanTlsListener()")
        val listenerEnd = src.indexOf("\n    private fun ", listener + 1)
        assertTrue("runLanTlsListener not found", listener > 0 && listenerEnd > listener)

        var from = 0
        var codeHits = 0
        while (true) {
            val at = src.indexOf("\"0.0.0.0\"", from).takeIf { it >= 0 } ?: break
            val line = src.substring(src.lastIndexOf('\n', at) + 1, at)
            if (!line.trimStart().startsWith("//") && !line.trimStart().startsWith("*")) {
                codeHits++
                assertTrue("a \"0.0.0.0\" bind outside the TLS listener", at in listener until listenerEnd)
            }
            from = at + 1
        }
        assertEquals("the TLS listener must be the one LAN bind", 1, codeHits)
        assertTrue(
            "the plain listener must bind 127.0.0.1 literally",
            src.contains("ServerSocket(port, 10, InetAddress.getByName(\"127.0.0.1\"))")
        )
    }

    @Test
    fun `the pairing IPC command reports the pin the listener will serve`() {
        TcpCommandServer.secretStoreForTest = store()
        TcpCommandServer.lanEnabledForTest = false
        try {
            val server = TcpCommandServer(19876)
            val ask = { server.processCommand(org.json.JSONObject().put("cmd", "lanTlsInfo")) }
            val first = ask()
            assertEquals("ok", first.getString("status"))
            assertEquals(LanTls.PORT, first.getInt("port"))
            assertFalse(first.getBoolean("enabled"))
            // Created on first ask -- pairing can happen before LAN access is ever switched on --
            // and the same one every time after, which is what the listener will load.
            assertEquals(first.getString("fingerprintSha256"), ask().getString("fingerprintSha256"))
            assertEquals(LanTls.loadOrCreate(store()).fingerprintSha256, first.getString("fingerprintSha256"))
        } finally {
            TcpCommandServer.secretStoreForTest = null
            TcpCommandServer.lanEnabledForTest = null
        }
    }

    @Test
    fun `a non-positive serial is refused`() {
        val keyPair = KeyPairGenerator.getInstance("EC").apply { initialize(ECGenParameterSpec("secp256r1")) }
            .generateKeyPair()
        try {
            SelfSignedCert.build(keyPair, "t", Date(), Date(), BigInteger.ZERO)
            assertFalse("expected a rejection", true)
        } catch (e: IllegalArgumentException) {
            // expected
        }
    }
}
