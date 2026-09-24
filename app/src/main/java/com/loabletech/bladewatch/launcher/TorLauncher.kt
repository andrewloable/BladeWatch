package net.bladewatch.app.launcher

import android.content.Context
import net.bladewatch.app.logging.LogManager

/**
 * Launches the Tor onion service that fronts the daemon's local web server.
 *
 * Replaces the previous tunnel's launcher, which was ~1360 lines almost entirely because the previous tunnel
 * needed an account: an enable token, a one-time registration per device against a five-device
 * free-tier limit, a reserved-share dance to keep a stable URL, and a 401 re-registration repair
 * loop when the environment was revoked server-side. Tor needs none of it. There is no account, no token, no registration
 * and no device limit, and the address is permanent because it is derived from a key file on disk.
 * What is left is: write a config file, run a binary, read one line back.
 *
 * ## How the binary gets here
 *
 * `downloadTor` in `app/build.gradle.kts` fetches tor 0.4.8.14 from Maven Central, verifies its
 * SHA-256 and drops it in `jniLibs/arm64-v8a/libtor.so`. Android extracts anything in jniLibs to
 * the app's nativeLibraryDir with the execute bit set, which is the only way to ship a runnable
 * binary to a non-rooted head unit. This class copies it to [TOR_BIN] and runs it as shell UID
 * over ADB, the same way every other BladeWatch daemon is launched.
 *
 * ## Measured on the real head unit, 2026-09-14
 *
 * Cold bootstrap ~82 s to "Bootstrapped 100%"; warm restart ~6 s with a populated DataDirectory.
 * The onion address survived restarts unchanged. Throughput 62-75 KB/s, warm request TTFB
 * 2.1-6.5 s, ~65 MB RSS and ~5% CPU. The H.264 WebSocket on /ws upgraded and held 216 kbit/s.
 * Guards were reachable on 443/9001 with no interference, so no bridges are configured.
 *
 * ## The onion key is a secret
 *
 * `$HS_DIR/hs_ed25519_secret_key` IS the car's permanent remote-access identity. It is never read,
 * logged, copied to shared storage or returned over IPC. Delete it and tor mints a new address on
 * the next start, silently invalidating every QR code the owner ever scanned — which is why both
 * [stopCommand] and `DaemonHardReset.hardResetCommand` are careful never to remove that directory,
 * and why both have tests asserting they do not.
 *
 * ## The address is not authentication
 *
 * An onion address is a capability URL. The daemon's password / JWT auth stays mandatory in front
 * of the web server; this class does not touch it.
 */
class TorLauncher(
    private val context: Context,
    private val adbShellExecutor: AdbShellExecutor,
    private val logManager: LogManager
) {
    companion object {
        private const val TAG = "TorLauncher"

        /**
         * Process name, and therefore the basename the binary is installed under.
         *
         * `TcpCommandServer.isProcessRunning` matches on `basename(argv[0])` and tor is exec'd by
         * path, so the two are the same string by construction. A bare "tor" would be generic
         * enough to collide with something else on the head unit; 14 characters keeps it inside
         * the kernel's 15-char cap on `/proc/<pid>/comm`, so `killall` still matches it in full.
         */
        const val TOR_PROCESS = "bladewatch_tor"

        const val TOR_BIN = "/data/local/tmp/$TOR_PROCESS"
        const val TOR_DIR = "/data/local/tmp/tor"
        const val TORRC = "$TOR_DIR/torrc"
        const val DATA_DIR = "$TOR_DIR/data"
        const val HS_DIR = "$TOR_DIR/hs"

        /** Mirrored by `TcpCommandServer.torLogPath()`; update both if it moves. */
        const val TOR_LOG = "/data/local/tmp/tor.log"

        /** Where tor writes the onion address, mode 600 and shell-owned. */
        const val HOSTNAME_FILE = "$HS_DIR/hostname"

        /**
         * The local web server the onion service fronts: its REMOTE loopback listener, never 8080
         * (BladeWatch-ur11). tor delivers every remote request from 127.0.0.1, so on 8080 -- the
         * in-car UI's listener -- a remote visitor was treated as a head-unit app and skipped the
         * vehicle-control second factor. 8081 carries the same routes with REMOTE trust.
         */
        private val LOCAL_HTTP = "127.0.0.1:${net.bladewatch.app.server.HttpServer.REMOTE_LOOPBACK_PORT}"

        /**
         * The whole configuration. Five lines, and every one of them earns its place:
         *
         * - `SocksPort 0` — BladeWatch runs tor as a SERVICE, never as a client. A listener here
         *   would be an open proxy on the head unit that nothing in the app ever uses.
         * - `DataDirectory` — the consensus cache. Keeping it is what turns an 82 s cold start
         *   into a 6 s warm one. Safe to delete; it costs only a slow bootstrap.
         * - `HiddenServiceDir` — holds the permanent identity key. NOT safe to delete, ever.
         * - `HiddenServicePort 80 -> 127.0.0.1:8081` — plain HTTP inside the tunnel is correct:
         *   the onion protocol already encrypts end to end and authenticates the service by its
         *   key, so there is no TLS to add and no certificate to pin.
         * - `Log notice file` — the bootstrap gate in `TcpCommandServer.isTorBootstrapped()`
         *   reads this file to decide when the address may be published.
         */
        @JvmStatic
        fun torrcContents(): String = buildString {
            appendLine("# Generated by BladeWatch TorLauncher — edits here are overwritten.")
            appendLine("SocksPort 0")
            appendLine("DataDirectory $DATA_DIR")
            appendLine("HiddenServiceDir $HS_DIR")
            appendLine("HiddenServicePort 80 $LOCAL_HTTP")
            appendLine("Log notice file $TOR_LOG")
        }

        /**
         * Install the binary and prepare the directories.
         *
         * The `chmod 700` calls are not decoration: tor REFUSES TO START if DataDirectory or
         * HiddenServiceDir is group- or world-accessible, and reports it only in a log nobody is
         * watching yet. `/data/local/tmp` is 0771 shell:shell, so the defaults would be wrong.
         *
         * The torrc is written with a quoted heredoc so nothing in it is expanded by the shell.
         */
        @JvmStatic
        fun setupCommand(nativeTorPath: String): String = buildString {
            append("cp $nativeTorPath $TOR_BIN && chmod +x $TOR_BIN && ")
            append("mkdir -p $DATA_DIR && mkdir -p $HS_DIR && ")
            append("chmod 700 $DATA_DIR && chmod 700 $HS_DIR && ")
            append("cat > $TORRC <<'TORRC_EOF'\n")
            append(torrcContents())
            append("TORRC_EOF\n")
            append("echo ok")
        }

        /**
         * Start tor detached, but only if it is not already running.
         *
         * `nohup … &` because the launching ADB shell goes away immediately and would otherwise
         * take tor with it. Output goes to /dev/null rather than a second file — tor writes its
         * own notice log via the torrc, and that is the file the bootstrap gate reads.
         *
         * ## Why the guard is inside the command
         *
         * Two callers once raced and started tor twice in the same second (measured on the head
         * unit 2026-09-15). The second instance found the DataDirectory lock held, waited five
         * seconds, and exited:
         *
         * ```
         * 09:26:31 [notice] Tor 0.4.8.14
         * 09:26:31 [notice] Tor 0.4.8.14          <- two starts, same second
         * 09:26:31 [warn]  It looks like another Tor process is running with the same
         *                  data directory. Waiting 5 seconds to see if it goes away.
         * 09:26:36 [err]   No, it's still there. Exiting.
         * ```
         *
         * Nothing broke — the first instance kept serving — but it wasted five seconds of a
         * startup path and wrote `[err]` lines into the log the bootstrap gate reads.
         *
         * Checking from Kotlin first would not fix it: that is check-then-act across two ADB
         * round trips, and the loser of the race still launches. Deciding inside the single
         * shell invocation closes the window. `pidof`, not `pgrep`, because pgrep consults
         * `comm` only — see [isRunningCommand].
         */
        @JvmStatic
        fun launchCommand(): String =
            "if pidof $TOR_PROCESS > /dev/null 2>&1; then echo already_running; " +
                "else nohup $TOR_BIN -f $TORRC > /dev/null 2>&1 & echo launched; fi"

        /**
         * Stop tor.
         *
         * `killall`, NOT `pkill -f`, and this is verified-on-device important. toybox
         * `pkill -f` matches the pattern as a literal SUBSTRING of every process's
         * `/proc/<pid>/cmdline` — and the cmdline of the ADB shell running this command IS
         * this command, pattern included. So `pkill -9 -f bladewatch_tor` kills the shell
         * that issued it: measured on the head unit 2026-09-15 with a marker matching no
         * process at all, the shell died with exit 137 and the next statement never ran.
         * The bracket trick does not help either, because substring matching finds the
         * literal `[b]ladewatch_tor` in the script text too.
         *
         * `killall` matches `comm` / `basename(argv[0])`, which is "sh" for this shell and
         * "bladewatch_tor" for the tunnel, so it cannot match itself. [TOR_PROCESS] is 14
         * characters precisely so it survives the kernel's 15-char cap on `comm`.
         *
         * Deliberately only kills. It does NOT clean up [TOR_DIR]: that directory holds the
         * permanent onion identity, and a stop must be reversible. See the class docs.
         */
        @JvmStatic
        fun stopCommand(): String =
            "killall -9 $TOR_PROCESS 2>/dev/null; echo done"

        /**
         * Probe whether tor is alive.
         *
         * Plain `pgrep`, never `pgrep -f`, for the same reason [stopCommand] avoids
         * `pkill -f` — except that here the failure is silent rather than fatal. Measured on
         * the head unit 2026-09-15 with NO tor process anywhere:
         *
         * ```
         * pgrep -f bladewatch_tor  -> 5187   (the probing shell's own pid)
         * pgrep    bladewatch_tor  -> (nothing — correct)
         * ```
         *
         * A probe wedged at "running" is worse than one wedged at "stopped":
         * `DaemonStartupManager.startTunnelFromPreferences` skips the launch when the tunnel
         * is "already running", so the tunnel would never come up at all.
         */
        @JvmStatic
        fun isRunningCommand(): String =
            "pgrep $TOR_PROCESS > /dev/null && echo yes || echo no"

        /** True once the current run has reached 100%, mirroring the IPC gate's rule. */
        @JvmStatic
        fun isBootstrapped(logTail: String): Boolean {
            var up = false
            for (line in logTail.lineSequence()) {
                // Order matters: a restart resets the verdict, a completion sets it, last wins.
                // tor appends across launches, so an old success line sits above the new start.
                if (line.contains("Bootstrapped 0%")) up = false
                else if (line.contains("Bootstrapped 100%")) up = true
            }
            return up
        }
    }

    interface TorCallback {
        fun onLog(message: String)
        fun onTunnelUrl(url: String)
        fun onError(error: String)
    }

    /**
     * Install if needed, start tor, then wait for it to reach the network and report the address.
     *
     * Reports [TorCallback.onTunnelUrl] only once tor is BOOTSTRAPPED, never merely once the
     * hostname file exists — it is written about a second after the very first launch and then
     * persists across reboots, so on its own it says nothing about reachability.
     */
    fun launchTor(callback: TorCallback) {
        val src = "${context.applicationInfo.nativeLibraryDir}/libtor.so"
        logManager.info(TAG, "Launching Tor onion service")
        callback.onLog("Preparing Tor…")

        adbShellExecutor.execute(
            command = setupCommand(src),
            callback = object : AdbShellExecutor.ShellCallback {
                override fun onSuccess(output: String) {
                    if (!output.contains("ok")) {
                        // Most likely cause by far: libtor.so absent because the build skipped
                        // downloadTor. Say so rather than making someone read a shell trace.
                        val msg = "Tor setup failed (is libtor.so packaged?): ${output.trim()}"
                        logManager.error(TAG, msg)
                        callback.onError(msg)
                        return
                    }
                    startProcess(callback)
                }

                override fun onError(error: String) {
                    logManager.error(TAG, "Tor setup failed: $error")
                    callback.onError("Tor setup failed: $error")
                }
            }
        )
    }

    private fun startProcess(callback: TorCallback) {
        callback.onLog("Starting Tor…")
        adbShellExecutor.execute(
            command = launchCommand(),
            callback = object : AdbShellExecutor.ShellCallback {
                override fun onSuccess(output: String) {
                    logManager.info(TAG, "Tor started; waiting for bootstrap")
                    callback.onLog("Connecting to the Tor network…")
                    awaitBootstrap(callback, attempt = 1)
                }

                override fun onError(error: String) {
                    logManager.error(TAG, "Tor launch failed: $error")
                    callback.onError("Tor launch failed: $error")
                }
            }
        )
    }

    /**
     * Poll until tor reports 100%, then read the address.
     *
     * The budget is generous on purpose. A cold start measured ~82 s on the head unit and a warm
     * one ~6 s, but bootstrap time depends on the car's connection, which on a parked vehicle can
     * be poor. 40 attempts at 5 s is a little over three minutes; giving up earlier would report
     * a failure for a tunnel that was about to come up.
     */
    private fun awaitBootstrap(callback: TorCallback, attempt: Int) {
        if (attempt > 40) {
            val msg = "Tor did not finish bootstrapping — see $TOR_LOG"
            logManager.error(TAG, msg)
            callback.onError(msg)
            return
        }
        adbShellExecutor.execute(
            // Only the tail: the log is appended to across launches and can grow.
            command = "tail -c 65536 $TOR_LOG 2>/dev/null; echo '---'; cat $HOSTNAME_FILE 2>/dev/null",
            callback = object : AdbShellExecutor.ShellCallback {
                override fun onSuccess(output: String) {
                    val parts = output.split("---")
                    val logTail = parts.getOrElse(0) { "" }
                    val hostname = parts.getOrElse(1) { "" }.trim()

                    if (isBootstrapped(logTail) && hostname.endsWith(".onion")) {
                        val url = "http://$hostname"
                        // Never log the address itself: it is a capability granting network
                        // access to this car, and daemon logs get shared in bug reports.
                        logManager.info(TAG, "Tor onion service is live")
                        callback.onLog("Tor tunnel online")
                        callback.onTunnelUrl(url)
                        return
                    }
                    retry(callback, attempt)
                }

                override fun onError(error: String) = retry(callback, attempt)
            }
        )
    }

    private fun retry(callback: TorCallback, attempt: Int) {
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            awaitBootstrap(callback, attempt + 1)
        }, 5_000)
    }

    /** Whether tor is running right now. */
    fun isTunnelRunning(callback: (Boolean) -> Unit) {
        adbShellExecutor.execute(
            command = isRunningCommand(),
            callback = object : AdbShellExecutor.ShellCallback {
                override fun onSuccess(output: String) = callback(output.contains("yes"))
                override fun onError(error: String) = callback(false)
            }
        )
    }

    /** Stop tor. The onion identity is left on disk, so restarting keeps the same address. */
    fun stopTor(callback: TorCallback) {
        adbShellExecutor.execute(
            command = stopCommand(),
            callback = object : AdbShellExecutor.ShellCallback {
                override fun onSuccess(output: String) {
                    logManager.info(TAG, "Tor stopped")
                    callback.onLog("Tor tunnel stopped")
                }

                override fun onError(error: String) {
                    logManager.error(TAG, "Failed to stop Tor: $error")
                    callback.onError("Failed to stop Tor: $error")
                }
            }
        )
    }
}
