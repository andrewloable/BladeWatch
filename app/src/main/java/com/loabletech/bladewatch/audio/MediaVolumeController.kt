package net.bladewatch.app.audio

import net.bladewatch.app.daemon.CameraDaemon

/**
 * Media volume and mute control (BladeWatch-2000.2). No BYD SDK, no motion interlock --
 * Android's own `AudioManager` covers this, and adjusting volume is ordinary,
 * universally-safe-while-driving behaviour (a physical volume knob is never gated on being
 * parked), unlike the actuations `VehicleCommandRouter` gates. See this issue's close reason
 * for the full reasoning behind keeping this a separate, dedicated controller instead of a
 * `VehicleCommandRouter` command.
 *
 * Percent, not the raw index, is this class's entire public surface -- see
 * [VolumePercentConverter].
 *
 * Public constructor for tests, which inject a fake [MediaVolumeDevice]; production uses
 * [getInstance].
 */
class MediaVolumeController(private val device: MediaVolumeDevice) {

    /** The raw index to restore on [unmute], or null when not currently muted by this
     * controller. Tracked explicitly rather than trusting the device's own mute state -- see
     * [MediaVolumeDevice]'s doc comment. */
    @Volatile
    private var levelBeforeMute: Int? = null

    fun getVolumePercent(): Int =
        VolumePercentConverter.indexToPercent(device.getStreamVolume(), device.getStreamMaxVolume())

    /** An explicit level change cancels any pending mute-restore -- setting a level is itself
     * an unambiguous statement of what the owner wants to hear next. */
    fun setVolumePercent(percent: Int) {
        levelBeforeMute = null
        val max = device.getStreamMaxVolume()
        device.setStreamVolume(VolumePercentConverter.percentToIndex(percent, max))
    }

    fun stepUp() = stepBy(1)

    fun stepDown() = stepBy(-1)

    /**
     * Steps in raw index units, floored at one index. Going through percent instead would make
     * the button a silent no-op on any stream whose max is under 20, because one index step is
     * then worth more than [STEP_PERCENT] and the adjustment rounds back to where it started
     * (max 7, index 3: 43% + 5% -> 48% -> index 3 again). Percent stays the only unit callers
     * ever see; this is internal arithmetic.
     */
    private fun stepBy(direction: Int) {
        val max = device.getStreamMaxVolume()
        if (max <= 0) return
        val delta = VolumePercentConverter.percentToIndex(STEP_PERCENT, max).coerceAtLeast(1)
        // Same as setVolumePercent: an explicit step states what the owner wants to hear next.
        levelBeforeMute = null
        device.setStreamVolume((device.getStreamVolume() + direction * delta).coerceIn(0, max))
    }

    /** No-op if already muted by this controller -- a second mute() must not overwrite the
     * remembered level with 0. */
    fun mute() {
        if (levelBeforeMute != null) return
        levelBeforeMute = device.getStreamVolume()
        device.setStreamVolume(0)
    }

    /** Restores the level captured by [mute], not a default. No-op if not currently muted by
     * this controller. */
    fun unmute() {
        val restore = levelBeforeMute ?: return
        levelBeforeMute = null
        device.setStreamVolume(restore)
    }

    fun isMuted(): Boolean = levelBeforeMute != null

    companion object {
        /** One step, in percent, for [stepUp] / [stepDown]. */
        private const val STEP_PERCENT = 5

        @Volatile
        private var instance: MediaVolumeController? = null

        /** Production singleton, wired to the real device via `CameraDaemon.getAppContext()`
         * -- the daemon's existing pattern for a Context outside the Activity lifecycle. Must
         * stay a singleton: [levelBeforeMute] has to persist between the HTTP request that
         * mutes and the later one that unmutes. */
        @JvmStatic
        fun getInstance(): MediaVolumeController {
            return instance ?: synchronized(this) {
                instance ?: MediaVolumeController(AudioManagerVolumeDevice(CameraDaemon.getAppContext())).also { instance = it }
            }
        }
    }
}
