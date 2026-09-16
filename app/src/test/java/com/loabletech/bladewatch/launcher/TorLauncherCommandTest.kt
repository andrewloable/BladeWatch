package net.bladewatch.app.launcher

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-3lbz.2: the torrc and the shell commands TorLauncher builds.
 *
 * Everything here is a pure string, deliberately: the launcher's interesting decisions are all
 * "what exactly gets written to disk and handed to a shell", and those are the parts that fail
 * silently on a head unit at 3am. The ADB plumbing around them is not worth a mock.
 *
 * Every constant asserted here was verified against a real tor 0.4.8.14 running on the BYD head
 * unit on 2026-09-14 — it bootstrapped, published the onion service, and served the web app.
 */
class TorLauncherCommandTest {

    @Test
    fun `torrc points the onion service at the daemon's local http server`() {
        val torrc = TorLauncher.torrcContents()

        // The whole point of the tunnel: expose 127.0.0.1:8080 as an onion service on port 80.
        assertTrue(
            "torrc must forward onion port 80 to the local HTTP server:\n$torrc",
            torrc.lineSequence().any { it.trim() == "HiddenServicePort 80 127.0.0.1:8080" }
        )
        assertTrue(
            "torrc must declare the hidden-service directory:\n$torrc",
            torrc.lineSequence().any { it.trim() == "HiddenServiceDir ${TorLauncher.HS_DIR}" }
        )
    }

    @Test
    fun `torrc opens no socks listener`() {
        val torrc = TorLauncher.torrcContents()

        // BladeWatch runs tor purely as an onion SERVICE. A SOCKS listener would be an
        // open proxy on the head unit that nothing in the app ever uses. (The 2026-09-14
        // feasibility test set SocksPort 9050 only because the test itself needed a
        // client to fetch through.)
        assertTrue(
            "torrc must disable the SOCKS port:\n$torrc",
            torrc.lineSequence().any { it.trim() == "SocksPort 0" }
        )
    }

    @Test
    fun `torrc logs where the daemon looks for bootstrap state`() {
        val torrc = TorLauncher.torrcContents()

        // TcpCommandServer.isTorBootstrapped() reads this exact path to decide whether the
        // tunnel may publish its address. If the two drift, the Dashboard never leaves
        // "connecting".
        assertTrue(
            "torrc must log to the path the IPC bootstrap gate reads:\n$torrc",
            torrc.lineSequence().any { it.trim() == "Log notice file ${TorLauncher.TOR_LOG}" }
        )
        assertEquals("/data/local/tmp/tor.log", TorLauncher.TOR_LOG)
        assertEquals("/data/local/tmp/tor/hs", TorLauncher.HS_DIR)
    }

    @Test
    fun `torrc configures no bridges or pluggable transports`() {
        val torrc = TorLauncher.torrcContents()

        // The head unit reached guards on 443/9001 with no interference (verified
        // 2026-09-14), so bridges would be unused complexity — and obfs4proxy is another
        // binary to ship, verify and keep current.
        for (banned in listOf("Bridge ", "UseBridges", "ClientTransportPlugin")) {
            assertFalse("torrc must not configure $banned:\n$torrc", torrc.contains(banned))
        }
    }

    @Test
    fun `setup command creates the tor directories mode 700`() {
        val cmd = TorLauncher.setupCommand("/data/app/x/lib/arm64/libtor.so")

        // tor REFUSES TO START if DataDirectory or HiddenServiceDir is group- or
        // world-accessible. Getting this wrong means a tunnel that never comes up, with
        // the reason buried in a log nobody reads.
        assertTrue("must create the data directory: $cmd", cmd.contains("mkdir -p ${TorLauncher.DATA_DIR}"))
        assertTrue("must create the hidden-service directory: $cmd", cmd.contains("mkdir -p ${TorLauncher.HS_DIR}"))
        assertTrue("data directory must be 700: $cmd", cmd.contains("chmod 700 ${TorLauncher.DATA_DIR}"))
        assertTrue("hidden-service directory must be 700: $cmd", cmd.contains("chmod 700 ${TorLauncher.HS_DIR}"))
    }

    @Test
    fun `setup command installs the binary under its own process name`() {
        val src = "/data/app/x/lib/arm64/libtor.so"
        val cmd = TorLauncher.setupCommand(src)

        // The binary is copied to a path whose BASENAME is the process name, because
        // TcpCommandServer.isProcessRunning matches on basename(argv[0]) and tor is exec'd
        // by path. Copy it to any other name and the tunnel reads as permanently offline.
        assertTrue("must copy from the extracted native library: $cmd", cmd.contains(src))
        assertTrue("must install as the process name: $cmd", cmd.contains(TorLauncher.TOR_BIN))
        assertTrue("must be made executable: $cmd", cmd.contains("chmod +x ${TorLauncher.TOR_BIN}"))
        assertEquals("bladewatch_tor", TorLauncher.TOR_BIN.substringAfterLast('/'))
        assertEquals(TorLauncher.TOR_PROCESS, TorLauncher.TOR_BIN.substringAfterLast('/'))
    }

    @Test
    fun `the process name fits the kernel's fifteen character comm cap`() {
        // /proc/<pid>/comm is truncated at 15 chars by the kernel, so a longer name makes
        // killall silently do nothing — the exact trap CLAUDE.md records for
        // acc_sentry_daemon.
        assertTrue(
            "process name '${TorLauncher.TOR_PROCESS}' would be truncated in /proc/<pid>/comm",
            TorLauncher.TOR_PROCESS.length <= 15
        )
    }

    @Test
    fun `launch command detaches tor and points it at the torrc`() {
        val cmd = TorLauncher.launchCommand()

        assertTrue("must exec the installed binary: $cmd", cmd.contains(TorLauncher.TOR_BIN))
        assertTrue("must pass the torrc: $cmd", cmd.contains("-f ${TorLauncher.TORRC}"))
        // Detached, or it dies with the ADB shell that started it.
        assertTrue("must survive the launching shell: $cmd", cmd.contains("nohup"))
        // Backgrounded. Asserted as "nohup ... &" rather than "the string ends with &",
        // because the launch is now wrapped in an if/fi guard against double-starting
        // (see `launch command does nothing when tor is already running`).
        assertTrue("must run in the background: $cmd", Regex("nohup[^&]*&").containsMatchIn(cmd))
    }

    @Test
    fun `stop command never touches the hidden service directory`() {
        val cmd = TorLauncher.stopCommand()

        assertTrue("must kill the tor process: $cmd", cmd.contains(TorLauncher.TOR_PROCESS))
        // Same guard as the hard reset: hs/ holds hs_ed25519_secret_key, which IS the
        // permanent onion address. Deleting it silently breaks every QR code ever scanned.
        assertFalse(
            "stopping the tunnel must never delete the onion identity: $cmd",
            cmd.contains(TorLauncher.HS_DIR)
        )
        assertFalse(
            "a glob over the tor directory would take hs/ with it: $cmd",
            cmd.contains("rm -rf ${TorLauncher.TOR_DIR}") || cmd.contains("${TorLauncher.TOR_DIR}/*")
        )
    }

    /**
     * Verified on the head unit 2026-09-15, and the reason this test exists.
     *
     * toybox `pkill -f` matches the pattern as a literal SUBSTRING of every process's
     * /proc/<pid>/cmdline — and the cmdline of the ADB shell running this command IS the
     * command, pattern included. So `pkill -9 -f bladewatch_tor` kills the shell that
     * issued it. Measured with a marker string matching no process on the device:
     *
     *     $ adb shell "echo start; pkill -9 -f 'bwprobe_marker_xyz'; echo SHOULD PRINT"
     *     start
     *     (exit 137 — SIGKILL; the second echo never ran)
     *
     * Everything after the pkill is therefore dead code on a real device: the killall
     * below it, and the `echo done` the callback waits for. The bracket trick does not
     * save you either — substring matching finds the literal "[b]ladewatch_tor" in the
     * script text too. Only `comm`/argv[0] matching can tell the two apart, and the
     * shell's is "sh". CLAUDE.md records the same trap.
     */
    @Test
    fun `stop command matches by process name, never by full command line`() {
        val cmd = TorLauncher.stopCommand()

        assertFalse(
            "pkill -f matches this command's OWN shell and kills it (exit 137, verified " +
                "on device) — everything after it never runs. Match by name: $cmd",
            cmd.contains("pkill") && cmd.contains("-f")
        )
        assertTrue("must still kill tor: $cmd", cmd.contains("killall"))
    }

    /**
     * Same trap, opposite symptom. `pgrep -f bladewatch_tor` matches the ADB shell that
     * runs it, so the liveness probe answers "running" whether or not tor exists.
     * Measured on the head unit 2026-09-15 with NO tor process anywhere:
     *
     *     pgrep -f bladewatch_tor  -> 5187   (which is the shell's own pid)
     *     pgrep    bladewatch_tor  -> (nothing — correct)
     *
     * A probe stuck at "yes" is worse than one stuck at "no": DaemonStartupManager skips
     * the start because the tunnel is "already running", so it never comes up at all.
     */
    @Test
    fun `liveness probe matches by process name, never by full command line`() {
        val cmd = TorLauncher.isRunningCommand()

        assertFalse(
            "pgrep -f matches this command's own shell, so the probe answers 'running' " +
                "with no tor on the device (verified) — and the tunnel then never " +
                "starts, because the caller thinks it already has: $cmd",
            cmd.contains("-f")
        )
        assertTrue("must still probe for tor: $cmd", cmd.contains(TorLauncher.TOR_PROCESS))
    }

    /**
     * Verified on the head unit 2026-09-15, from tor's own log:
     *
     * ```
     * 09:26:31 [notice] Tor 0.4.8.14
     * 09:26:31 [notice] Tor 0.4.8.14          <- TWO starts, same second
     * 09:26:31 [warn]  It looks like another Tor process is running with the same
     *                  data directory. Waiting 5 seconds to see if it goes away.
     * 09:26:36 [err]   No, it's still there. Exiting.
     * ```
     *
     * The second instance dies on the DataDirectory lock, so nothing breaks — but it burns
     * five seconds of a startup path, writes errors into a log the bootstrap gate reads,
     * and means two callers each believe they started the tunnel.
     *
     * The root cause was DaemonStartupManager scheduling its work twice (onCreate, then
     * again from the ADB-auth-granted callback). That is fixed separately. This guard is
     * the belt-and-braces half: even with two callers racing, the LAUNCH ITSELF is a no-op
     * when tor is already up, decided inside the one shell invocation so there is no
     * check-then-act window for a caller to lose.
     */
    @Test
    fun `launch command does nothing when tor is already running`() {
        val cmd = TorLauncher.launchCommand()

        assertTrue(
            "the launch must check for a live tor first, in the SAME shell invocation — a " +
                "separate check would leave a window for a second launch: $cmd",
            cmd.contains("pidof ${TorLauncher.TOR_PROCESS}")
        )
        assertTrue("must still be able to launch: $cmd", cmd.contains("nohup"))
        assertFalse(
            "pgrep matches comm only, which is not reliable across daemons here — pidof " +
                "matches comm OR argv[0]: $cmd",
            cmd.contains("pgrep")
        )
    }
}
