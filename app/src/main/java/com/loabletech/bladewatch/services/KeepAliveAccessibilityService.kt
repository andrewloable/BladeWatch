package net.bladewatch.app.services

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import net.bladewatch.app.ui.daemon.DaemonStartupManager

/**
 * Minimal AccessibilityService that keeps the app process alive indefinitely.
 *
 * Android's OOM killer and OEM process killers (including BYD's DiLink firmware) are hardcoded
 * never to kill a process hosting an active AccessibilityService. This gives the app the highest
 * possible process priority — the same tier as the keyboard or a phone call — preventing the
 * 24-hour kill cycle on newer BYD firmware.
 *
 * The service itself is a no-op for accessibility events; its sole purpose is process keep-alive.
 *
 * Enable via ADB (one-time):
 * ```
 *   settings put secure enabled_accessibility_services net.bladewatch.app/net.bladewatch.app.services.KeepAliveAccessibilityService
 *   settings put secure accessibility_enabled 1
 * ```
 */
class KeepAliveAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this

        Log.i(TAG, "AccessibilityService connected — process is now protected")

        // Minimal config — we don't need to observe any events
        val info = serviceInfo ?: AccessibilityServiceInfo()
        info.eventTypes = 0 // No events
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.notificationTimeout = 5000
        info.flags = 0
        serviceInfo = info

        // No foreground notification needed — DaemonKeepaliveService already has one. The
        // AccessibilityService binding alone is enough to protect the process.

        // Ensure the daemons are running (respawn if killed)
        try {
            DaemonStartupManager.startOnBoot(applicationContext)
        } catch (e: Exception) {
            Log.w(TAG, "Daemon startup from A11y service: " + e.message)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // No-op — we don't process accessibility events
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onDestroy() {
        Log.w(TAG, "AccessibilityService destroyed — attempting restart")
        instance = null

        // Self-restart: send a broadcast to trigger re-enable
        try {
            sendBroadcast(Intent("net.bladewatch.app.RESTART_ACCESSIBILITY"))
        } catch (e: Exception) {
            Log.e(TAG, "Restart broadcast failed: " + e.message)
        }

        super.onDestroy()
    }

    companion object {
        private const val TAG = "KeepAliveA11y"

        private var instance: KeepAliveAccessibilityService? = null

        @JvmStatic
        fun isRunning(): Boolean = instance != null
    }
}
