package net.bladewatch.app.audio

import android.content.Context
import android.media.AudioManager

/**
 * Wraps the real `android.media.AudioManager` (BladeWatch-2000.2), targeting
 * [AudioManager.STREAM_MUSIC] -- the stream every standard Android media app targets, which a
 * vendor head unit cannot remap without breaking every third-party media app on the device.
 * `AudioTestApiHandler` already uses `STREAM_MUSIC` elsewhere in this codebase (for the AVAS
 * exterior-speaker test path -- a different physical output, so not proof this stream reaches
 * the cabin speakers specifically, but consistent evidence that this is the stream BYD's
 * firmware honours). Not verified on a physical head unit in this environment; do that before
 * relying on this in the field (see this issue's close reason).
 *
 * `flags=0` on [setStreamVolume] -- no `FLAG_SHOW_UI`, no `FLAG_PLAY_SOUND` -- so a volume
 * change never triggers the on-screen volume toast or an audible click, honouring "do not
 * touch any audio route, focus request, or output device selection" and "do not add a remote
 * play-a-sound capability".
 */
class AudioManagerVolumeDevice(context: Context) : MediaVolumeDevice {

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    override fun getStreamMaxVolume(): Int = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)

    override fun getStreamVolume(): Int = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)

    override fun setStreamVolume(index: Int) {
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, index, 0)
    }
}
