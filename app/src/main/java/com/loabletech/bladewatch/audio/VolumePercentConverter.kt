package net.bladewatch.app.audio

import kotlin.math.roundToInt

/**
 * Converts between the owner-facing 0-100% volume scale and a stream's raw Android volume
 * index, whose range differs per stream and per device (BladeWatch-2000.2). No Android
 * imports -- pure arithmetic, so the conversion is unit-tested without a device.
 *
 * The raw index is never exposed to callers outside `MediaVolumeController`: a caller-visible
 * index on a 0-15 stream would mean something different on a device whose stream maxes at 7,
 * making the API meaningless across devices.
 */
object VolumePercentConverter {

    /** Clamps [percent] to [0, 100] first, so out-of-range input is absorbed rather than
     * thrown on or passed through to the device untouched. */
    @JvmStatic
    fun percentToIndex(percent: Int, maxIndex: Int): Int {
        if (maxIndex <= 0) return 0
        val clampedPercent = percent.coerceIn(0, 100)
        return (clampedPercent / 100.0f * maxIndex).roundToInt()
    }

    /** Clamps [index] to `[0, maxIndex]` first, for the same reason as above. */
    @JvmStatic
    fun indexToPercent(index: Int, maxIndex: Int): Int {
        if (maxIndex <= 0) return 0
        val clampedIndex = index.coerceIn(0, maxIndex)
        return (clampedIndex / maxIndex.toFloat() * 100).roundToInt()
    }
}
