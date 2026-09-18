package net.bladewatch.app.audio

/**
 * Minimal seam over the volume-relevant slice of `android.media.AudioManager`
 * (BladeWatch-2000.2) -- just enough for [MediaVolumeController] to read and set the media
 * stream's level. Production wraps the real `AudioManager` ([AudioManagerVolumeDevice]);
 * tests use a hand-written fake, since this project has no Mockito/Robolectric.
 *
 * Deliberately has no mute-specific method. `AudioManager.setStreamMute` is deprecated, and
 * this project cannot assume a vendor head unit's built-in mute restores the exact prior
 * level (BladeWatch-2000.2's own "not a default" requirement). Mute/unmute is
 * [MediaVolumeController]'s own explicit remember-then-[setStreamVolume] logic, so this
 * interface only ever needs the three volume primitives.
 */
interface MediaVolumeDevice {
    fun getStreamMaxVolume(): Int

    fun getStreamVolume(): Int

    fun setStreamVolume(index: Int)
}
