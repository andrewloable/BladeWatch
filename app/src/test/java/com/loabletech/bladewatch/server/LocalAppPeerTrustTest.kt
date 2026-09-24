package net.bladewatch.app.server

import java.io.ByteArrayOutputStream
import java.io.File
import java.net.InetAddress
import java.net.InetSocketAddress
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-g5u7: on the in-car listener, local trust -- the debug-build Tier 2 bypass and the
 * vehicle-action second-factor exemption -- belongs to BladeWatch's own UIDs, not to every app that
 * can reach 127.0.0.1:8080. Measured before the fix on a debug build: any caller there got
 * GetStatus, SetChargeCap, recordings and live view with an invalid JWT.
 */
class LocalAppPeerTrustTest {

    @Before
    fun setUp() {
        // Every other Tier 2 condition forced open: debug bypass on, no tunnel running.
        AuthMiddleware.setLoopbackBypassOverride(true)
        AuthMiddleware.setTunnelActiveOverride(false)
    }

    @After
    fun tearDown() {
        AuthMiddleware.setLoopbackBypassOverride(null)
        AuthMiddleware.setTunnelActiveOverride(null)
    }

    private fun allowed(trust: ListenerTrust): Pair<Boolean, String> {
        val out = ByteArrayOutputStream()
        val ok = AuthMiddleware.checkAuth(
            "/bladewatch.v1.VehicleService/SetChargeCap", null, null, out,
            InetSocketAddress("127.0.0.1", 40123), false, trust,
        )
        return ok to out.toString("UTF-8")
    }

    @Test
    fun `an untrusted app on the in-car listener is served like a remote caller`() {
        val trust = AuthMiddleware.effectiveTrust(ListenerTrust.LOCAL_APPS) { false }
        assertEquals(ListenerTrust.REMOTE, trust)
        val (ok, response) = allowed(trust)
        assertFalse("no credential, no bypass", ok)
        assertTrue(response, response.contains("401 Unauthorized"))
        assertFalse(
            "and no exemption from the vehicle second factor",
            AuthMiddleware.isLocalAppCaller(trust, InetAddress.getByName("127.0.0.1")),
        )
    }

    @Test
    fun `BladeWatch itself keeps the in-car listener's trust`() {
        val trust = AuthMiddleware.effectiveTrust(ListenerTrust.LOCAL_APPS) { true }
        assertEquals(ListenerTrust.LOCAL_APPS, trust)
        assertTrue(allowed(trust).first)
        assertTrue(AuthMiddleware.isLocalAppCaller(trust, InetAddress.getByName("127.0.0.1")))
    }

    @Test
    fun `remote listeners stay remote, and never pay for a UID lookup`() {
        var looked = false
        val trust = AuthMiddleware.effectiveTrust(ListenerTrust.REMOTE) { looked = true; true }
        assertEquals(ListenerTrust.REMOTE, trust)
        assertFalse(looked)
    }

    @Test
    fun `HttpServer applies it to every connection before anything else reads the trust`() {
        val path = "src/main/java/com/loabletech/bladewatch/server/HttpServer.kt"
        val src = listOf(File(path), File("app/$path")).first { it.isFile }.readText()
        val body = src.substringAfter("private fun handleClient(client: Socket, listenerTrust: ListenerTrust) {")
        val firstStatement = body.lines().map { it.trim() }.first { it.isNotEmpty() && !it.startsWith("//") }
        assertEquals(
            "val trust = AuthMiddleware.effectiveTrust(listenerTrust) { PeerCredentials.isTrustedPeer(client) }",
            firstStatement,
        )
        assertEquals("listenerTrust is read only there", 1, Regex("""\blistenerTrust\b""").findAll(body.substringBefore("\n    private fun ")).count())
    }
}
