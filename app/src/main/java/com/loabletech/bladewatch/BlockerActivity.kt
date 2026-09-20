package net.bladewatch.app

import android.app.Activity
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager

/**
 * BlockerActivity - "Blackout Shield" for Sentry Mode.
 *
 * This activity creates a fake "screen off" state:
 * - Screen is BLACK (solid black view)
 * - Backlight is 0 (minimum power, looks off)
 * - Touch is BLOCKED (consumed by the overlay)
 * - Screen stays ON (FLAG_KEEP_SCREEN_ON prevents sleep logic)
 *
 * This achieves 99% of the same result as actually turning off the screen,
 * but keeps the system awake for surveillance recording.
 *
 * Works with UID 1000/2000 privileges - system won't kill this activity.
 */
@Suppress("DEPRECATION") // TargetSdk 25 Android Auto builds still need the legacy immersive/lockscreen flags.
class BlockerActivity : Activity() {

    // Save original brightness to restore on exit
    private var originalBrightness = 128
    private var originalBrightnessMode = Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. VISUAL: Fullscreen Solid Black View
        val blocker = View(this)
        blocker.setBackgroundColor(0xFF000000.toInt()) // Solid Black - looks like screen is off
        blocker.isClickable = true
        blocker.isFocusable = true
        blocker.isFocusableInTouchMode = true

        // 2. INPUT: Consume ALL Touches - stops touches from passing through
        blocker.setOnTouchListener { _, _ -> true }

        setContentView(blocker)

        // 3. FLAGS: Keep Screen On + Fullscreen + Show on Lockscreen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or // Prevent sleep logic
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or // Show over lockscreen
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or // Dismiss keyguard
                WindowManager.LayoutParams.FLAG_FULLSCREEN or // Hide status bar
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS // Extend beyond screen
        )

        // 4. Immersive sticky mode - hide all system UI
        applyImmersiveMode()

        // 5. HARDWARE: Kill Backlight (The "Fake Sleep")
        killBacklight()
    }

    /** Immersive sticky mode - hide all system UI. Re-applied on every resume and focus gain. */
    private fun applyImmersiveMode() {
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
    }

    /** Set backlight to 0 - makes screen appear completely off. */
    private fun killBacklight() {
        try {
            // Save original brightness settings
            originalBrightness = Settings.System.getInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                128
            )
            originalBrightnessMode = Settings.System.getInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
            )

            // Set to manual mode and minimum brightness
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
            )
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                0 // Total Darkness
            )

            // Also set window brightness to minimum
            setWindowBrightnessToMinimum()
        } catch (e: Exception) {
            Log.w(
                TAG,
                "Failed to set system brightness settings, falling back to window brightness: " +
                    e.message
            )
            try {
                setWindowBrightnessToMinimum()
            } catch (e2: Exception) {
                Log.w(TAG, "Failed to set window brightness as fallback: " + e2.message)
            }
        }
    }

    private fun setWindowBrightnessToMinimum() {
        val params = window.attributes
        params.screenBrightness = 0.0f // 0 = minimum
        window.attributes = params
    }

    /** Restore original brightness settings. */
    private fun restoreBacklight() {
        try {
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS_MODE,
                originalBrightnessMode
            )
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                originalBrightness
            )
        } catch (e: Exception) {
            Log.w(TAG, "Failed to restore brightness settings: " + e.message)
        }
    }

    override fun onResume() {
        super.onResume()
        // Re-apply immersive mode and kill backlight when resuming
        applyImmersiveMode()
        killBacklight()
    }

    override fun onBackPressed() {
        // Block back button - do nothing
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Block all key events
        return true
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        // Block all key events
        return true
    }

    override fun dispatchTouchEvent(ev: MotionEvent?): Boolean {
        // Consume all touch events
        return true
    }

    override fun dispatchKeyEvent(event: KeyEvent?): Boolean {
        // Consume all key events
        return true
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Re-apply immersive mode when gaining focus
            applyImmersiveMode()
            killBacklight()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Restore brightness when shield is removed
        restoreBacklight()
    }

    companion object {
        private const val TAG = "BlockerActivity"
    }
}
