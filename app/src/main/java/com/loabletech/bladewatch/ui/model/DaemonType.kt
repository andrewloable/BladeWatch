package net.bladewatch.app.ui.model

/**
 * Types of background daemons managed by the app.
 * Note: Location Sidecar is not included here as it auto-starts silently
 * and is managed by SentryDaemon, not shown in the UI.
 */
/*
 * TOR_TUNNEL was removed with tor (BladeWatch-rdtj.12). An existing config or preference that still
 * names it is harmless: every string-to-type lookup (PreferencesManager) tolerates an unknown name,
 * and the cross-process `daemons` section is read by key, never enumerated into this type.
 */
enum class DaemonType(val displayName: String, val processName: String) {
    CAMERA_DAEMON("Camera Daemon", "byd_cam_daemon"),
    SENTRY_DAEMON("Sentry Daemon", "sentry_daemon"),
    ACC_SENTRY_DAEMON("ACC Sentry", "acc_sentry_daemon"),
    // The --nice-name pear_daemon is launched with — see PearLauncher.PEAR_PROCESS.
    PEAR_PEER("Pear Peer", "pear_daemon")
}
