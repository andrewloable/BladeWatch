package net.bladewatch.app.server

import java.io.File
import net.bladewatch.app.launcher.TorLauncher
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.6 / BladeWatch-ur11: the tunnels' ways in are REMOTE listeners on loopback.
 *
 * The Pear pump and the tor onion service both open TCP connections to 127.0.0.1, which at the
 * socket level look exactly like an app on the head unit. What keeps a remote peer from the
 * in-car UI's privileges -- the Tier 2 loopback bypass, the vehicle second-factor exemption -- is
 * that they land on listeners whose connections are ListenerTrust.REMOTE: tor on
 * [HttpServer.REMOTE_LOOPBACK_PORT], the Pear pump on [HttpServer.PEAR_TLS_PORT].
 * HttpServer cannot run in a JVM test, so its listener wiring is read as source (a declared test
 * input). The trust decisions themselves are AuthMiddlewareTest's: aRemoteListenerNeverGetsTheLoopbackBypass
 * (bypass forced on, no tunnel, REMOTE on port 8081 still refused) and
 * onlyTheLocalListenerOnLoopbackIsExemptFromTheVehicleSecondFactor.
 */
class RemoteLoopbackListenerTest {

    private val src: String by lazy {
        val path = "src/main/java/com/loabletech/bladewatch/server/HttpServer.kt"
        listOf(File(path), File("app/$path")).first { it.isFile }.readText()
    }

    @Test
    fun `the remote loopback listener binds loopback only and serves every connection as REMOTE`() {
        val body = src.substringAfter("private fun runRemoteLoopbackListener()").substringBefore("\n    }\n")
        assertTrue(body, body.contains("ServerSocket(REMOTE_LOOPBACK_PORT, 10, InetAddress.getByName(\"127.0.0.1\"))"))
        assertTrue(body, body.contains("handleClient(client, ListenerTrust.REMOTE)"))
        assertFalse(body, body.contains("LOCAL_APPS"))
    }

    @Test
    fun `only the in-car UI's listener is LOCAL_APPS`() {
        assertEquals(1, Regex("""handleClient\(client, ListenerTrust\.LOCAL_APPS\)""").findAll(src).count())
        assertEquals(8081, HttpServer.REMOTE_LOOPBACK_PORT)
    }

    @Test
    fun `the Pear TLS listener binds loopback only, serves the pinned LAN certificate, and is REMOTE`() {
        val body = src.substringAfter("private fun runPearTlsListener()").substringBefore("\n    }\n")
        assertTrue(body, body.contains("createServerSocket(PEAR_TLS_PORT, 10, InetAddress.getByName(\"127.0.0.1\"))"))
        assertTrue(body, body.contains("LanTls.loadOrCreate(") && body.contains("LanTls.serverSocketFactory(identity)"))
        assertTrue(body, body.contains("handleClient(client, ListenerTrust.REMOTE)"))
        assertFalse(body, body.contains("LOCAL_APPS"))
    }

    @Test
    fun `login rate limits key on the peer IP, never the socket address with its port`() {
        // "/127.0.0.1:54321" is a fresh bucket on every reconnect, which made the per-caller limit
        // a no-op (BladeWatch-rdtj.16).
        assertFalse(src.contains("remoteSocketAddress.toString()"))
        assertTrue(src.contains("private fun rateLimitIdentity(client: Socket): String = client.inetAddress?.hostAddress"))
        assertEquals(2, Regex("""rateLimitIdentity\(client\)""").findAll(src).count())
    }

    @Test
    fun `tor forwards to the remote loopback listener`() {
        assertTrue(TorLauncher.torrcContents().contains("127.0.0.1:${HttpServer.REMOTE_LOOPBACK_PORT}"))
    }
}
