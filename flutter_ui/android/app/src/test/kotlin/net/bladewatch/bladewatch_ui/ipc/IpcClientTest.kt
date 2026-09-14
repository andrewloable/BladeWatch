package net.bladewatch.bladewatch_ui.ipc

import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket

/** Binds to loopback explicitly. `ServerSocket(0)` alone binds the wildcard
 *  address, which this sandboxed test environment refuses to connect a
 *  client to ("Can't assign requested address"); an explicit loopback bind
 *  works, matching how the daemon's own IPC servers bind. */
private fun loopbackServerSocket(): ServerSocket =
    ServerSocket().apply { bind(InetSocketAddress(InetAddress.getByName("127.0.0.1"), 0)) }

/**
 * Exercises the real TCP client against a real local [ServerSocket] — this is
 * genuinely testable on the dev machine with no daemon and no device, so it
 * is, not stubbed behind a fake transport.
 */
class IpcClientTest {

    private var server: ServerSocket? = null
    private var tokenFile: File? = null

    @After
    fun tearDown() {
        server?.close()
        tokenFile?.delete()
    }

    private fun tokenFile(content: String = "test-token-value"): File {
        val f = File.createTempFile("ipc_token_test", ".tmp")
        f.writeText(content)
        tokenFile = f
        return f
    }

    private fun startServer(handle: (auth: JSONObject, command: JSONObject, writer: PrintWriter) -> Unit): ServerSocket {
        val s = loopbackServerSocket()
        server = s
        Thread {
            try {
                val client = s.accept()
                val reader = BufferedReader(InputStreamReader(client.getInputStream()))
                val writer = PrintWriter(client.getOutputStream(), true)
                val authLine = reader.readLine() ?: return@Thread
                val auth = JSONObject(authLine)
                val cmdLine = reader.readLine() ?: return@Thread
                val command = JSONObject(cmdLine)
                handle(auth, command, writer)
                client.close()
            } catch (_: Exception) {
                // Test server thread — failures surface as assertion failures in the
                // test body itself (no response arrives, or it doesn't match).
            }
        }.start()
        Thread.sleep(200)
        return s
    }

    @Test
    fun `zzz diagnostic print jvm info`() {
        println("java.home=" + System.getProperty("java.home"))
        println("os.arch=" + System.getProperty("os.arch"))
        println("java.version=" + System.getProperty("java.version"))
    }

    @Test
    fun `sends the token then the command, and returns a successful response`() {
        var capturedToken: String? = null
        var capturedCommand: String? = null
        val server = startServer { auth, command, writer ->
            capturedToken = auth.optString("token")
            capturedCommand = command.optString("cmd")
            writer.println(JSONObject().put("status", "ok").put("value", "42").toString())
        }
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile("secret-abc"))

        val response = client.sendCommand(JSONObject().put("cmd", "ping"))

        assertEquals("secret-abc", capturedToken)
        assertEquals("ping", capturedCommand)
        assertEquals("ok", response.optString("status"))
        assertEquals("42", response.optString("value"))
    }

    @Test
    fun `trims whitespace from the token file`() {
        val server = startServer { auth, _, writer ->
            assertEquals("trimmed-token", auth.optString("token"))
            writer.println(JSONObject().put("status", "ok").toString())
        }
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile("  trimmed-token  \n"))

        client.sendCommand(JSONObject().put("cmd", "ping"))
    }

    @Test
    fun `throws TokenUnreadable when the token file does not exist`() {
        val missing = File.createTempFile("ipc_token_missing", ".tmp")
        missing.delete() // exists() is now false
        val client = IpcClient(port = 1, tokenFile = missing)

        assertThrows(IpcException.TokenUnreadable::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws TokenUnreadable when the token file is empty`() {
        val client = IpcClient(port = 1, tokenFile = tokenFile(""))

        assertThrows(IpcException.TokenUnreadable::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws TokenUnreadable when the token file exists but cannot be read as text`() {
        // A directory exists() but readText() on it always throws — a
        // portable way to hit a real read failure without relying on POSIX
        // permission bits, which behave inconsistently when tests run as root.
        val dir = File.createTempFile("ipc_token_dir", "").apply { delete(); mkdir() }
        tokenFile = dir
        val client = IpcClient(port = 1, tokenFile = dir)

        assertThrows(IpcException.TokenUnreadable::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws DaemonNotListening when nothing is listening on the port`() {
        // Bind then immediately close, so the port is (almost certainly) free
        // but guaranteed to refuse — much faster and more deterministic than
        // relying on a hard-coded unused port number.
        val probe = loopbackServerSocket()
        val freePort = probe.localPort
        probe.close()
        val client = IpcClient(port = freePort, tokenFile = tokenFile(), connectTimeoutMs = 2_000)

        assertThrows(IpcException.DaemonNotListening::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws Timeout when the server accepts but never responds`() {
        val server = startServer { _, _, _ ->
            Thread.sleep(2_000) // outlives the client's short read timeout below
        }
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile(), readTimeoutMs = 200)

        assertThrows(IpcException.Timeout::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws DaemonNotListening when the server closes immediately (write itself fails)`() {
        val server = loopbackServerSocket()
        this.server = server
        Thread {
            val client = server.accept()
            client.close() // closes before reading anything — the client's own write fails
        }.start()
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile())

        assertThrows(IpcException.DaemonNotListening::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws DaemonNotListening when the peer resets the connection mid-exchange`() {
        // The two close-based tests around this one do NOT reach the
        // IOException branch in writeAndReadLine: PrintWriter never throws
        // (it swallows IOException into an internal error flag), so a plain
        // close surfaces as readLine() returning null — the clean-EOF path.
        // Only an ABORTIVE close (SO_LINGER 0, with unread data in the
        // server's receive buffer) sends a RST, which makes the client's read
        // throw "Connection reset" and exercises the IOException mapping.
        //
        // This is a real daemon failure mode, not a contrivance: it is what a
        // crashing or killed CameraDaemon looks like to the app mid-command.
        val server = loopbackServerSocket()
        this.server = server
        Thread {
            val client = server.accept()
            // Let the client's two writes land unread, so closing forces RST
            // rather than an orderly FIN.
            Thread.sleep(150)
            client.setSoLinger(true, 0)
            client.close()
        }.start()
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile(), readTimeoutMs = 5_000)

        assertThrows(IpcException.DaemonNotListening::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws DaemonNotListening when the server reads the command then closes with no response`() {
        // Distinct from the immediate-close case above: here the write
        // succeeds (the server reads both lines) and readLine() cleanly
        // returns null (EOF) rather than throwing mid-write.
        val server = loopbackServerSocket()
        this.server = server
        Thread {
            val client = server.accept()
            val reader = BufferedReader(InputStreamReader(client.getInputStream()))
            reader.readLine() // auth
            reader.readLine() // command
            client.close() // ...then nothing
        }.start()
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile())

        assertThrows(IpcException.DaemonNotListening::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `throws CommandRejected when the response status is error, e_g_ a bad token`() {
        val server = startServer { _, _, writer ->
            writer.println(JSONObject().put("status", "error").put("message", "Unauthorized").toString())
        }
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile())

        val thrown = assertThrows(IpcException.CommandRejected::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
        assertTrue(thrown.message!!.contains("Unauthorized"))
    }

    @Test
    fun `throws CommandRejected when the response is not valid JSON`() {
        val server = startServer { _, _, writer ->
            writer.println("not json at all")
        }
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile())

        assertThrows(IpcException.CommandRejected::class.java) {
            client.sendCommand(JSONObject().put("cmd", "ping"))
        }
    }

    @Test
    fun `a fresh connection is used per call — two calls do not interfere`() {
        val commands = mutableListOf<String>()
        val server = loopbackServerSocket()
        this.server = server
        Thread {
            repeat(2) {
                val client = server.accept()
                val reader = BufferedReader(InputStreamReader(client.getInputStream()))
                val writer = PrintWriter(client.getOutputStream(), true)
                reader.readLine() // auth
                val cmd = JSONObject(reader.readLine())
                commands.add(cmd.optString("cmd"))
                writer.println(JSONObject().put("status", "ok").put("echo", cmd.optString("cmd")).toString())
                client.close()
            }
        }.start()
        val client = IpcClient(port = server.localPort, tokenFile = tokenFile())

        val r1 = client.sendCommand(JSONObject().put("cmd", "start"))
        val r2 = client.sendCommand(JSONObject().put("cmd", "stop"))

        assertEquals("start", r1.optString("echo"))
        assertEquals("stop", r2.optString("echo"))
        assertEquals(listOf("start", "stop"), commands)
    }
}
