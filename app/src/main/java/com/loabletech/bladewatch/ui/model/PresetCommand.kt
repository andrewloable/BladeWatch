package net.bladewatch.app.ui.model

import net.bladewatch.app.launcher.DaemonKillCommands

/**
 * A preset ADB command for quick execution.
 */
data class PresetCommand(
    val label: String,
    val command: String,
    val category: String
)

/**
 * Convenience constant for all preset commands.
 */
val PRESET_COMMANDS = PresetCommands.ALL

/**
 * List of preset ADB commands organized by category.
 */
object PresetCommands {
    val ALL = listOf(
        // Status commands
        PresetCommand("Process Status", "ps -ef | grep -E 'daemon|bladewatch_tor'", "Status"),
        PresetCommand("Port Status", "netstat -tlnp | grep -E '8080|8554'", "Status"),

        // Log commands
        PresetCommand("Tor Logs", "cat /data/local/tmp/tor.log | tail -50", "Logs"),
        PresetCommand("Camera Logs", "cat /data/local/tmp/byd_cam_daemon.log | tail -50", "Logs"),
        PresetCommand("Sentry Logs", "cat /data/local/tmp/sentry_daemon.log | tail -50", "Logs"),

        // Control commands
        // BladeWatch-6jj1: these run in the Diagnostics ADB console, so the old
        // `pkill -f` forms killed the USER'S OWN CONSOLE SESSION instead of the daemon —
        // the pattern appears in the console shell's own cmdline. Built through
        // DaemonKillCommands so the console and the controllers cannot drift apart.
        PresetCommand(
            "Kill Camera",
            // Kill the watchdog script FIRST so it can't respawn the daemon,
            // then sleep briefly, then kill the daemon and clear its lock file.
            // The rm globs start_cam_*.sh: naming the script would put the literal back
            // in this cmdline, where the bracketed regex above would match it.
            DaemonKillCommands.killMatchingCmdline("start_cam_daemon") + "; " +
                "rm -f /data/local/tmp/start_cam_*.sh; " +
                "sleep 1; " +
                DaemonKillCommands.killByName("byd_cam_daemon") + "; " +
                "rm -f /data/local/tmp/camera_daemon.lock",
            "Control"
        ),
        PresetCommand("Kill Sentry", DaemonKillCommands.killByName("sentry_daemon"), "Control"),
        
        // System commands
        PresetCommand("Storage", "df -h /data", "System"),
        PresetCommand("Battery", "dumpsys battery", "System"),
        PresetCommand("Network", "ip addr", "System"),
        PresetCommand("Ping Test", "ping -c 3 8.8.8.8", "System"),
        PresetCommand("Proxy Settings", "settings get global http_proxy", "System"),
        PresetCommand("Reset Proxy", "settings put global http_proxy :0", "Control"),
        PresetCommand("ACC Props", "getprop | grep -i acc", "System")
    )
    
    val CATEGORIES = ALL.map { it.category }.distinct()
}
