package net.bladewatch.app.daemon

import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.io.FileWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Report-only Frida/hook detection for uy93.9.
 *
 * SCOPE: Frida agent library presence in /proc/self/maps ONLY. NOT CHECKED: root, ADB, ptrace or
 * debugger presence — all of which fire on normal BYD DiLink v3 operation (ADB-connected,
 * dev-unlocked, shell UID daemons).
 *
 * ENFORCEMENT: NEVER. A detection triggers a log entry only; the daemon continues to run
 * regardless of what is found.
 *
 * KILL-SWITCH: create /data/local/tmp/bladewatch_rasp_disabled to skip the checks:
 * `adb shell touch /data/local/tmp/bladewatch_rasp_disabled`.
 *
 * REPORT: appended to /data/local/tmp/bladewatch_security.log. That log survives R8/ProGuard
 * stripping because it writes directly via FileWriter, not via DaemonLogger, which is stripped in
 * release builds.
 */
object RaspDetector {

    private const val SECURITY_LOG = "/data/local/tmp/bladewatch_security.log"
    private const val KILL_SWITCH = "/data/local/tmp/bladewatch_rasp_disabled"

    // Frida patterns: agent lib names and gadget names as they appear in /proc/self/maps
    private val FRIDA_MARKERS = arrayOf(
        "frida-agent",
        "frida-gadget",
        "re.frida.agent"
    )

    /** Called once at CameraDaemon startup. Never throws. */
    @JvmStatic
    fun checkAndReport() {
        try {
            if (File(KILL_SWITCH).exists()) return
            scanProcMaps()
        } catch (ignored: Exception) {
            // Never propagate — RASP must not affect daemon availability
        }
    }

    private fun scanProcMaps() {
        try {
            BufferedReader(FileReader("/proc/self/maps")).use { r ->
                while (true) {
                    val line = r.readLine() ?: break
                    for (marker in FRIDA_MARKERS) {
                        if (line.contains(marker)) {
                            reportEvent("FRIDA_DETECTED", line.trim())
                            return // one report per scan is enough
                        }
                    }
                }
            }
        } catch (ignored: Exception) {
            // An unreadable /proc/self/maps is not something to escalate.
        }
    }

    private fun reportEvent(type: String, detail: String) {
        try {
            val ts = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
            // ponytail: append-only, no rotation; this file is low-volume (one entry per detect)
            FileWriter(SECURITY_LOG, true).use { fw ->
                fw.write("$ts [RASP:$type] $detail\n")
            }
        } catch (ignored: Exception) {
            // The report is best-effort; losing it must not affect the daemon.
        }
    }
}
