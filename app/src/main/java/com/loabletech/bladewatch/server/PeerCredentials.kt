package net.bladewatch.app.server

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.Socket

/**
 * Resolves and authorizes the peer UID of an accepted loopback IPC connection.
 *
 * The loopback IPC servers — [TcpCommandServer] (19876) and [SurveillanceIpcServer] (19877) —
 * authenticate callers with a shared bearer token. That token lives in
 * `/data/local/tmp/bladewatch_ipc_token` and is intentionally world-readable (mode 644) so the app
 * UID can bootstrap its IPC calls (see [IpcTokenManager]). World-readable means the token alone is
 * NOT a trust boundary: any local process that can read it could drive privileged commands (e.g.
 * `shell`, `secret_*`, `UPDATE_GPS`).
 *
 * This class adds a second, defence-in-depth gate: the daemon resolves the connecting socket's
 * owning UID and rejects any peer that is not an allow-listed trusted identity (root, system,
 * shell/daemon, or the BladeWatch app itself).
 *
 * **Transport note:** a Java TCP [Socket] cannot read `SO_PEERCRED` directly. Because both
 * endpoints are on loopback, both appear in `/proc/net/tcp` and `/proc/net/tcp6`. We locate the
 * client's socket row by its `(localPort, remotePort)` pair — unique for an established loopback
 * connection — and read the owning UID from that row. The daemon runs as shell (UID 2000), which
 * retains read access to these procfs entries on Android 10+.
 */
object PeerCredentials {

    private val logger: DaemonLogger = DaemonLogger.getInstance("PeerCredentials")

    // Resolved lazily from the app's package context and cached. -1 = unresolved.
    @Volatile
    private var cachedAppUid = -1

    /** ponytail: test seam — null = live resolveAppUid(); non-null = injected result (test-only) */
    @JvmField
    @Volatile
    var appUidOverrideForTest: Int? = null

    /** ponytail: test seam — null = real /proc scan; non-null = injected peer UID (test-only) */
    @JvmField
    @Volatile
    var peerUidForTest: Int? = null

    private const val ROOT_UID = 0
    private const val SYSTEM_UID = 1000
    private const val SHELL_UID = 2000

    /**
     * Resolve the owning UID of the remote end of an accepted loopback socket.
     *
     * @return the peer UID, or -1 if it could not be determined.
     */
    @JvmStatic
    fun resolvePeerUid(client: Socket?): Int {
        peerUidForTest?.let { return it }
        if (client == null) return -1
        val clientPort = client.port // remote (client ephemeral) port
        val serverPort = client.localPort // our listening port
        if (clientPort <= 0 || serverPort <= 0) return -1
        // The procfs row for an established connection is normally present the instant accept()
        // returns, but retry a few times to absorb any race.
        for (attempt in 0 until 5) {
            val uid = lookupUid(clientPort, serverPort)
            if (uid >= 0) return uid
            try {
                Thread.sleep(5)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                break
            }
        }
        return -1
    }

    /**
     * Returns true if the given UID is an allow-listed trusted identity: root (0), system (1000),
     * shell/daemon (2000), or the BladeWatch app UID. An unresolved UID (-1) is never trusted.
     */
    @JvmStatic
    fun isTrusted(uid: Int): Boolean {
        if (uid == ROOT_UID || uid == SYSTEM_UID || uid == SHELL_UID) return true
        if (uid < 0) return false
        val appUid = appUidOverrideForTest ?: resolveAppUid()
        if (appUid > 0) {
            // Compare on the per-user base app-id so a non-zero Android user still matches
            // (uid = userId * 100000 + appId).
            return uid == appUid || (uid % 100000) == (appUid % 100000)
        }
        // uy93.1: App-context UID resolution failed. Without a confirmed app UID we cannot
        // distinguish the legitimate BladeWatch app from any co-resident app that also holds the
        // world-readable IPC token. The fail-open path that previously trusted uid>=10000 is
        // removed: an unverified peer is rejected.
        //
        // Impact on BYD firmware: when ActivityThread/createAppContext times out, the app will be
        // denied at this gate until its UID resolves. The correct long-term fix is a positive
        // identity factor (signature attestation or a per-install non-world-readable secret);
        // this change removes the security hole as the immediate priority.
        return false
    }

    /** Convenience: resolve the peer UID of [client] and check the allow-list. */
    @JvmStatic
    fun isTrustedPeer(client: Socket?): Boolean = isTrusted(resolvePeerUid(client))

    // ==================== internals ====================

    private fun resolveAppUid(): Int {
        val cached = cachedAppUid
        if (cached > 0) return cached
        try {
            val ctx = CameraDaemon.getAppContext()
            if (ctx != null) {
                val ai = ctx.applicationInfo
                if (ai != null && ai.uid > 0) {
                    cachedAppUid = ai.uid
                    return ai.uid
                }
                val u = ctx.packageManager.getPackageUid(ctx.packageName, 0)
                if (u > 0) {
                    cachedAppUid = u
                    return u
                }
            }
        } catch (ignored: Exception) {
            // App context not ready yet — the caller treats an unresolved app UID as "no app
            // match"; shell/system/root peers still pass.
            logger.warn("Failed to resolve app UID (context not ready): " + ignored.message)
        }
        return -1
    }

    /** Scan both procfs tables for the client socket row and return its UID. */
    private fun lookupUid(clientPort: Int, serverPort: Int): Int {
        var uid = scan("/proc/net/tcp", clientPort, serverPort)
        if (uid < 0) uid = scan("/proc/net/tcp6", clientPort, serverPort)
        return uid
    }

    /**
     * Parse a /proc/net/tcp or /proc/net/tcp6 table. Each data row is
     * `sl local_address rem_address st tx:rx tr:tm retr uid timeout inode ...`. We match the row
     * whose local port is the client's ephemeral port AND whose remote port is our server port,
     * then return field[7] (uid).
     */
    private fun scan(path: String, clientPort: Int, serverPort: Int): Int {
        val f = File(path)
        if (!f.exists()) return -1
        try {
            BufferedReader(FileReader(f)).use { r ->
                r.readLine() // skip header
                while (true) {
                    val line = r.readLine() ?: break
                    val t = line.trim().split(Regex("\\s+"))
                    if (t.size < 8) continue
                    val localPort = parseHexPort(t[1])
                    val remPort = parseHexPort(t[2])
                    if (localPort == clientPort && remPort == serverPort) {
                        return try {
                            t[7].toInt()
                        } catch (e: NumberFormatException) {
                            -1
                        }
                    }
                }
            }
        } catch (ignored: Exception) {
            // procfs unreadable / unexpected format — treat as unresolved.
            logger.warn("Failed to scan procfs $path for peer UID: " + ignored.message)
        }
        return -1
    }

    /** Extract the hex port from an "ADDRESS:PORT" procfs field. */
    private fun parseHexPort(addrPort: String): Int {
        val colon = addrPort.lastIndexOf(':')
        if (colon < 0 || colon + 1 >= addrPort.length) return -1
        return try {
            addrPort.substring(colon + 1).toInt(16)
        } catch (e: NumberFormatException) {
            logger.warn("Failed to parse hex port from '$addrPort': " + e.message)
            -1
        }
    }
}
