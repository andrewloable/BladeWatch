package net.bladewatch.bladewatch_ui.ipc

import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.IOException
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.InetSocketAddress
import java.net.Socket
import java.net.SocketTimeoutException

/**
 * Blocking TCP client for the daemon's loopback command IPC —
 * `app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java`,
 * port 19876 by default. Ported from
 * `app/src/main/java/com/loabletech/bladewatch/client/CameraDaemonClient.java`
 * (the wire protocol) and
 * `app/src/main/java/com/loabletech/bladewatch/server/IpcTokenManager.java`
 * (the token file contract, read-only side): connect, send `{"token":
 * "<value>"}` as the first line (the server never acknowledges this line —
 * it only replies to what follows), then one JSON command per line, one JSON
 * response per line.
 *
 * Unlike `CameraDaemonClient`, this opens one fresh connection per
 * [sendCommand] call rather than keeping one open across calls — simpler,
 * and appropriate for a Flutter platform-channel call site, which is
 * inherently one request/response per invocation rather than a persistent
 * session.
 *
 * The shared UID with `net.bladewatch.app` (BladeWatch-7965.1) is what lets
 * this connection past the daemon's peer-UID gate
 * (`app/src/main/java/com/loabletech/bladewatch/server/PeerCredentials.java`)
 * — never widen that gate to work around a connection problem here.
 *
 * [host]/[port]/[tokenFile]/timeouts are constructor parameters (not
 * hardcoded) purely so JVM tests can point this at a local test server and a
 * temp token file instead of the real daemon and `/data/local/tmp` —
 * production call sites use the defaults.
 */
class IpcClient(
    private val host: String = "127.0.0.1",
    private val port: Int = 19876,
    private val tokenFile: File = File("/data/local/tmp/bladewatch_ipc_token"),
    private val connectTimeoutMs: Int = 5_000,
    private val readTimeoutMs: Int = 10_000,
) : IpcCommandSender {
    /**
     * Sends [command] and returns the daemon's parsed JSON response.
     *
     * @throws IpcException.TokenUnreadable the token file is missing, empty, or unreadable
     * @throws IpcException.DaemonNotListening nothing accepted the connection, or it closed with no response
     * @throws IpcException.Timeout connected, but no response arrived in time
     * @throws IpcException.CommandRejected the daemon replied with an error status, or a malformed response
     */
    override fun sendCommand(command: JSONObject): JSONObject {
        val token = readToken()
        val socket = connect()

        try {
            val line = writeAndReadLine(socket, token, command)
            if (line == null) {
                throw IpcException.DaemonNotListening("$host:$port closed the connection with no response")
            }

            val response = try {
                JSONObject(line)
            } catch (e: Exception) {
                // Deliberately does NOT include the response body. This message travels
                // out to Dart as a PlatformException and from there into logs, and the
                // responses to secret_get / secret_get_section carry the device secret
                // and tunnel tokens in their payload. CLAUDE.md's Security Notes forbid
                // those values reaching a log, so report only the length.
                throw IpcException.CommandRejected(
                    "malformed response from $host:$port (${line.length} bytes, not valid JSON)"
                )
            }

            if ("error".equals(response.optString("status"), ignoreCase = true)) {
                throw IpcException.CommandRejected(response.optString("message", "command rejected"))
            }
            return response
        } finally {
            try {
                socket.close()
            } catch (_: Exception) {
                // Best-effort cleanup — the command's own outcome is already decided.
            }
        }
    }

    /**
     * Writes the auth handshake + [command], then reads one response line.
     * Any I/O failure here means the connection died mid-exchange (e.g. the
     * daemon closed it right after accept, before this client's write even
     * landed) — that is exactly the "not listening" case from the caller's
     * point of view, so it is not a distinct error category. A read timeout
     * specifically (the daemon accepted but is simply slow) stays distinct.
     */
    private fun writeAndReadLine(socket: Socket, token: String, command: JSONObject): String? {
        try {
            val writer = PrintWriter(socket.getOutputStream(), true)
            val reader = BufferedReader(InputStreamReader(socket.getInputStream()))

            writer.println(JSONObject().put("token", token).toString())
            writer.println(command.toString())
            writer.flush()

            return reader.readLine()
        } catch (e: SocketTimeoutException) {
            throw IpcException.Timeout("$host:$port did not respond within ${readTimeoutMs}ms: ${e.message}")
        } catch (e: IOException) {
            throw IpcException.DaemonNotListening("$host:$port closed the connection: ${e.message}")
        }
    }

    private fun connect(): Socket {
        val socket = Socket()
        try {
            socket.connect(InetSocketAddress(host, port), connectTimeoutMs)
            socket.soTimeout = readTimeoutMs
        } catch (e: Exception) {
            throw IpcException.DaemonNotListening("connect to $host:$port failed: ${e.message}")
        }
        return socket
    }

    private fun readToken(): String {
        if (!tokenFile.exists()) {
            throw IpcException.TokenUnreadable("$tokenFile does not exist")
        }
        val text = try {
            tokenFile.readText().trim()
        } catch (e: Exception) {
            throw IpcException.TokenUnreadable("failed to read $tokenFile: ${e.message}")
        }
        if (text.isEmpty()) {
            throw IpcException.TokenUnreadable("$tokenFile is empty")
        }
        return text
    }
}
