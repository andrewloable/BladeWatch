package net.bladewatch.app.server

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.6 / -ur11 / -rdtj.12: remote traffic's way in is a REMOTE listener on loopback.
 *
 * The Pear pump opens TCP connections to 127.0.0.1, which at the socket level look exactly like an
 * app on the head unit. What keeps a remote peer from the in-car UI's privileges -- the Tier 2
 * loopback bypass, the vehicle second-factor exemption -- is that it lands on
 * [HttpServer.PEAR_TLS_PORT], a listener whose connections are ListenerTrust.REMOTE, and NEVER on
 * 8080. With tor removed that is the whole defence (AuthMiddleware no longer looks for a tunnel
 * process), so the pump's target is pinned here.
 * HttpServer cannot run in a JVM test, so its listener wiring is read as source (a declared test
 * input). The trust decisions themselves are AuthMiddlewareTest's: aRemoteListenerNeverGetsTheLoopbackBypass
 * (bypass forced on, REMOTE on 8444 still refused), vehicleControlOverThePearPumpWithoutAJwtIsA401
 * and onlyTheLocalListenerOnLoopbackIsExemptFromTheVehicleSecondFactor.
 */
class RemoteLoopbackListenerTest {

    private val src: String by lazy {
        val path = "src/main/java/com/loabletech/bladewatch/server/HttpServer.kt"
        listOf(File(path), File("app/$path")).first { it.isFile }.readText()
    }

    @Test
    fun `the Pear pump connects to the REMOTE Pear TLS listener, never to the in-car one`() {
        val pump = listOf(File("src/main/java/com/loabletech/bladewatch/daemon/PearStreamPump.kt"),
            File("app/src/main/java/com/loabletech/bladewatch/daemon/PearStreamPump.kt")).first { it.isFile }.readText()
        assertTrue(pump.contains("Socket(InetAddress.getByName(\"127.0.0.1\"), HttpServer.PEAR_TLS_PORT)"))
        assertFalse("the pump must never target 8080", pump.contains("8080"))
        assertEquals(8444, HttpServer.PEAR_TLS_PORT)
    }

    @Test
    fun `only the in-car UI's listener is LOCAL_APPS`() {
        assertEquals(1, Regex("""handleClient\(client, ListenerTrust\.LOCAL_APPS\)""").findAll(src).count())
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
}
