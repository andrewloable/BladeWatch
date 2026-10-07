package net.bladewatch.bladewatch_companion

import android.media.MediaCodecList
import android.media.MediaFormat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * BladeWatch-rdtj.73: reports this device's own hardware video decode ceiling, so the car knows
 * whether a saved clip needs transcoding before it can play here. Saved recordings only -- Live
 * view has no decode problem to solve (refreshed JPEG stills, no video codec involved).
 *
 * Extends FlutterFragmentActivity, not FlutterActivity (BladeWatch-hr6r.6): local_auth's Android
 * implementation requires a FragmentActivity to host its biometric prompt.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "maxDecodeSize") {
                result.success(maxDecodeSize())
            } else {
                result.notImplemented()
            }
        }
    }

    /**
     * The smaller of this device's H.264 and H.265 hardware decoder size ceilings, as
     * `[width, height]`, or null if neither codec is found at all. The car's own recordings may be
     * encoded as either MIME type (HardwareEventRecorderGpu.codecMimeType), so both are checked
     * and the tighter one wins -- the same conservative-approximation stance as
     * ClipCapability.nativeFits on the car.
     */
    private fun maxDecodeSize(): List<Int>? {
        val avc = decoderCeiling(MediaFormat.MIMETYPE_VIDEO_AVC)
        val hevc = decoderCeiling(MediaFormat.MIMETYPE_VIDEO_HEVC)
        val width = tighter(avc?.first, hevc?.first) ?: return null
        val height = tighter(avc?.second, hevc?.second) ?: return null
        return listOf(width, height)
    }

    private fun tighter(a: Int?, b: Int?): Int? = when {
        a == null -> b
        b == null -> a
        else -> minOf(a, b)
    }

    /**
     * This device's decode ceiling for [mime]: the first HARDWARE-accelerated decoder's own
     * supported width/height upper bound, since that is what real playback actually uses. Only
     * falls back to a software decoder's (tighter) ceiling when no hardware decoder exists for
     * this MIME at all -- matching what was measured on a real phone (BladeWatch-rdtj.73): a
     * hardware ceiling of 1920px either dimension, a software ceiling of 1280x720.
     */
    private fun decoderCeiling(mime: String): Pair<Int, Int>? {
        var softwareFallback: Pair<Int, Int>? = null
        for (info in MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos) {
            if (info.isEncoder || !info.supportedTypes.any { it.equals(mime, ignoreCase = true) }) continue
            val caps = try {
                info.getCapabilitiesForType(mime).videoCapabilities
            } catch (e: Exception) {
                null
            } ?: continue
            val ceiling = caps.supportedWidths.upper to caps.supportedHeights.upper
            if (info.isHardwareAccelerated) return ceiling
            if (softwareFallback == null) softwareFallback = ceiling
        }
        return softwareFallback
    }

    companion object {
        private const val CHANNEL = "net.bladewatch.companionapp/video_capability"
    }
}
