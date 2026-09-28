package net.bladewatch.app.recording.transcode

/**
 * What resolution a clip should be served at, decided from what the requesting client's own
 * decoder can handle (BladeWatch-rdtj.73).
 *
 * Saved recordings ONLY -- RecordingsApiHandler's `/video/` route (owner, 2026-09-28). Live view
 * has no decode problem to solve: it is refreshed JPEG stills over `/api/stream`
 * (StreamingApiHandler), never a video codec, and this feature does not touch that path.
 *
 * Found on a real Android phone (Oppo CPH2333, Snapdragon-family SoC): its hardware AVC/HEVC
 * decoder caps at 1920px on EITHER dimension, and its software fallback caps lower still, at
 * 1280x720 -- neither can decode the car's native 2560x1920 mosaic at all, so playback failed
 * outright ("Failed to load"), not just slowly. Measured with a real MediaCodecList probe run on
 * that device; see the task notes for the full data.
 *
 * One fallback tier for v1, not a full ABR ladder: 1920x1080 is both within that phone's proven
 * decode set AND the single most universally hardware-decodable shape on real Android devices in
 * general (a near-guarantee, where the car's bespoke 4:3 mosaic is not validated by any decoder
 * profile tested). Add more tiers only if a real device is found that 1080p itself does not fit.
 *
 * A client that reports NOTHING (an older companion build, or a platform that never asked --
 * macOS/AVFoundation already plays the native format fine, so its companion build sends no
 * capability hint at all) gets the native file, unchanged: this is strictly additive, and the
 * previous behaviour -- always serve native -- is what an absent hint means.
 */
object ClipCapability {
    /** The one fallback tier this server can transcode to. */
    const val FALLBACK_WIDTH = 1920
    const val FALLBACK_HEIGHT = 1080

    /**
     * Parses `maxW`/`maxH` query parameters (both required together; either malformed or partial
     * is treated as "no hint", the safe default of serving native). Never throws: malformed input
     * comes from a client requesting a byte-range URL, not a trusted API caller.
     */
    fun parseHint(query: String?): Pair<Int, Int>? {
        if (query.isNullOrEmpty()) return null
        var w: Int? = null
        var h: Int? = null
        for (pair in query.split("&")) {
            val eq = pair.indexOf('=')
            if (eq < 0) continue
            val key = pair.substring(0, eq)
            val value = pair.substring(eq + 1)
            when (key) {
                "maxW" -> w = value.toIntOrNull()
                "maxH" -> h = value.toIntOrNull()
            }
        }
        val width = w
        val height = h
        if (width == null || height == null || width <= 0 || height <= 0) return null
        return width to height
    }

    /**
     * Whether a client whose decoder tops out at [hint] (width, height; either order -- a decoder
     * capability table is about the pair of dimensions, not which one is "width" for a given
     * clip's own orientation) can decode a [nativeWidth]x[nativeHeight] clip directly.
     *
     * Deliberately simple (both native dimensions must fit within the hint's larger and smaller
     * side): the real capability tables found on-device are not a clean formula either (a phone
     * that failed a smaller 4:3 frame while passing a larger 16:9 one, see the task notes), so no
     * simple check here can be exact. This is a conservative approximation -- it may transcode a
     * few clips a client could technically have decoded, never the reverse.
     */
    fun nativeFits(hint: Pair<Int, Int>, nativeWidth: Int, nativeHeight: Int): Boolean {
        val hintLong = maxOf(hint.first, hint.second)
        val hintShort = minOf(hint.first, hint.second)
        val clipLong = maxOf(nativeWidth, nativeHeight)
        val clipShort = minOf(nativeWidth, nativeHeight)
        return clipLong <= hintLong && clipShort <= hintShort
    }

    /** True when [hint] cannot even fit the one fallback tier -- there is nothing this server can offer yet. */
    fun fallbackFits(hint: Pair<Int, Int>): Boolean = nativeFits(hint, FALLBACK_WIDTH, FALLBACK_HEIGHT)
}
