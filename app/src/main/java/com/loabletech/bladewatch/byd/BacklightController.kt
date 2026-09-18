package net.bladewatch.app.byd

import android.content.Context
import android.os.PowerManager
import android.os.SystemClock
import net.bladewatch.app.logging.DaemonLogger

/**
 * BYD vendor backlight control (BladeWatch-2000.3), extracted from
 * `AccSentryDaemon.setBacklightState`'s reflection cascade so the stealth-panel path there and
 * the new explicit screen on/off vehicle command (`VehicleCommandRouter` via
 * [BydDataCollector.setScreenBacklight]) share one implementation instead of two copies that
 * could drift. `AccSentryDaemon` and the process `VehicleCommandRouter` runs in are separate
 * OS processes (see CLAUDE.md's daemon architecture) but the same APK/classpath, so this
 * class is called independently from each -- there is no shared instance, only shared code.
 *
 * Covers only the two reflection strategies the pre-extraction method tried first
 * (PowerManager, then the BYD hardware setting device). `AccSentryDaemon` keeps its own
 * settings-brightness/keyevent shell fallback for when both fail, unchanged and un-extracted,
 * since it is daemon-specific shell plumbing this object has no need of.
 */
object BacklightController {

    private val logger = DaemonLogger.getInstance("BacklightController")

    /**
     * Best-effort: tries each strategy in order, returning true as soon as one succeeds.
     * False means every strategy failed -- not necessarily that the screen is in the wrong
     * state, matching the pre-extraction method's contract exactly.
     */
    @JvmStatic
    fun setBacklight(context: Context?, on: Boolean): Boolean {
        if (context == null) return false
        return setViaPowerManager(context, on) || setViaBydHardwareService(context, on)
    }

    private fun setViaPowerManager(context: Context, on: Boolean): Boolean {
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val names = if (on) arrayOf("turnBacklightOn", "TurnBacklightOn") else arrayOf("turnBacklightOff", "TurnBacklightOff")
            for (methodName in names) {
                try {
                    val m = pm.javaClass.getMethod(methodName, Long::class.javaPrimitiveType)
                    m.invoke(pm, SystemClock.uptimeMillis())
                    logger.info("Backlight: PowerManager.$methodName SUCCESS")
                    return true
                } catch (ignored: NoSuchMethodException) {
                    // try the next name variant
                }
            }
        } catch (e: Exception) {
            logger.debug("Backlight via PowerManager failed: " + e.message)
        }
        return false
    }

    private fun setViaBydHardwareService(context: Context, on: Boolean): Boolean {
        try {
            val clazz = Class.forName("android.hardware.bydauto.setting.BYDAutoSettingDevice")
            val getInstance = clazz.getMethod("getInstance", Context::class.java)
            val device = getInstance.invoke(null, context)
            val methodName = if (on) "turnBacklightOn" else "turnBacklightOff"
            clazz.getMethod(methodName).invoke(device)
            logger.info("Backlight: BYDAutoSettingDevice.$methodName SUCCESS")
            return true
        } catch (e: Exception) {
            logger.debug("Backlight via BYDAutoSettingDevice failed: " + e.message)
            return false
        }
    }
}
