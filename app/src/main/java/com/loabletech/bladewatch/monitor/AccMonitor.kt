package net.bladewatch.app.monitor

import android.content.Context
import net.bladewatch.app.daemon.CameraDaemon

/**
 * State holder for ACC status, with a direct hardware query.
 *
 * ACC state detection is handled by AccSentryDaemon, which uses the BYDAutoBodyworkDevice listener
 * for real ACC events, falls back to polling sys.accanim.status, and sends IPC commands to the
 * surveillance engine on port 19877.
 *
 * On a CameraDaemon restart (e.g. after an EGL crash), the ACC state is read directly from
 * BYDAutoBodyworkDevice.getPowerLevel() so the daemon can re-enter sentry mode without depending on
 * AccSentryDaemon IPC.
 */
class AccMonitor {

    /** No-op, for backward compatibility with CameraDaemon. */
    fun start() {
        CameraDaemon.log("AccMonitor: passive mode (ACC detection by AccSentryDaemon)")
    }

    /** No-op, for backward compatibility. */
    fun stop() {
        // Nothing to stop
    }

    companion object {

        // Power levels from BYDAutoBodyworkDevice (same as AccSentryDaemon)
        private const val POWER_LEVEL_OFF = 0
        private const val POWER_LEVEL_ACC = 1
        private const val POWER_LEVEL_ON = 2

        @Volatile
        private var inSentryMode = false

        /**
         * Defaults to false (ACC off) — the safer assumption until AccSentryDaemon confirms the
         * state. This prevents a false "acc: true" in status when the daemon restarts.
         */
        @Volatile
        private var accOn = false

        @JvmStatic
        fun isAccOn(): Boolean = accOn

        @JvmStatic
        fun isInSentryMode(): Boolean = inSentryMode

        /** Called by the surveillance IPC when AccSentryDaemon sends the ACC state. */
        @JvmStatic
        fun setAccState(isAccOn: Boolean) {
            accOn = isAccOn
            inSentryMode = !isAccOn
            CameraDaemon.log(
                "ACC state updated via IPC: accOn=$isAccOn, sentryMode=$inSentryMode"
            )
        }

        /**
         * Reads the ACC state directly from BYDAutoBodyworkDevice hardware, with no dependency on
         * AccSentryDaemon or file persistence.
         *
         * @param context Android context for the BYD device API
         * @return true if ACC is OFF (sentry mode should be active), false if ACC is ON or unknown
         */
        @JvmStatic
        fun probeAccState(context: Context): Boolean {
            return try {
                val deviceClass =
                    Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice")
                val getInstance = deviceClass.getMethod("getInstance", Context::class.java)
                val device = getInstance.invoke(null, context)

                if (device == null) {
                    CameraDaemon.log(
                        "AccMonitor: BYDAutoBodyworkDevice.getInstance returned null"
                    )
                    return false
                }

                val level = deviceClass.getMethod("getPowerLevel").invoke(device) as Int

                val isAccOn = level >= POWER_LEVEL_ON
                accOn = isAccOn
                inSentryMode = !isAccOn

                val levelStr = when (level) {
                    0 -> "OFF"
                    1 -> "ACC"
                    2 -> "ON"
                    3 -> "OK"
                    else -> "UNKNOWN($level)"
                }
                CameraDaemon.log(
                    "AccMonitor: hardware probe powerLevel=" + levelStr +
                        " → accOn=" + isAccOn + ", sentryMode=" + inSentryMode
                )

                !isAccOn // true if ACC is OFF
            } catch (e: Exception) {
                CameraDaemon.log("AccMonitor: hardware probe failed: " + e.message)
                // Assume ACC ON — the safe default; don't enter sentry on an error.
                false
            }
        }
    }
}
