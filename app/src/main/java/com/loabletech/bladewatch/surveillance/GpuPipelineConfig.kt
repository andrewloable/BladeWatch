package net.bladewatch.app.surveillance

import android.media.MediaFormat

import java.util.Locale

import kotlin.math.floor

/**
 * GpuPipelineConfig - Configuration for GPU surveillance pipeline.
 *
 * Supports:
 * - Recording quality (Normal/Sentry modes with different FPS/bitrate)
 * - Streaming quality (HQ/LQ with different resolutions/FPS)
 * - Configurable bitrate (2, 3, 6 Mbps)
 * - Codec selection (H.264/H.265)
 * - Dynamic reconfiguration
 */
class GpuPipelineConfig {

    /** Video codec selection */
    enum class VideoCodec(@JvmField val mimeType: String, @JvmField val displayName: String) {
        H264(MediaFormat.MIMETYPE_VIDEO_AVC, "H.264"),
        H265(MediaFormat.MIMETYPE_VIDEO_HEVC, "H.265/HEVC")
    }

    /**
     * Recording quality — single user-facing knob that bundles bitrate +
     * user-readable expectations. FPS is configured separately via
     * camera.targetFps so the user can pick e.g. PREMIUM @ 15 fps for
     * "archival without smoothness" or HIGH @ 30 fps for "smooth daily".
     *
     * Bitrate sizing rationale at 2560×1920 (4.9 megapixels per frame):
     *   - H.265 needs ~0.04 bpp for "good" quality, ~0.10 bpp for "evidence"
     *   - At 15 fps: 0.04 bpp × 5 MP × 15 = 3 Mbps minimum for "good"
     *   - At 30 fps: encoder spreads bits over 2× frames so per-frame detail
     *     drops at fixed bitrate — bump tier when going to higher fps
     *
     * H.265 / H.264 split: H.265 gets ~50% better compression at same
     * perceived quality, so H.264 columns are ~1.5× the H.265 column.
     */
    enum class RecordingQuality(
        @JvmField val bitrateH265: Int,
        @JvmField val bitrateH264: Int,
        @JvmField val displayName: String
    ) {
        /** ~7.5 MB/min @ H.265, archival multi-day SD lifespan */
        ECONOMY(1_000_000, 1_500_000, "Economy"),

        /** ~15 MB/min @ H.265, daily driver default */
        STANDARD(2_000_000, 3_000_000, "Standard"),

        /** ~30 MB/min @ H.265, fine textures readable */
        HIGH(4_000_000, 6_000_000, "High"),

        /** ~45 MB/min @ H.265, evidence-grade */
        PREMIUM(6_000_000, 9_000_000, "Premium"),

        /** ~75 MB/min @ H.265, hardware ceiling */
        MAX(10_000_000, 15_000_000, "Max");

        /** Resolved bitrate (bps) for the given codec. */
        fun getBitrateForCodec(codec: VideoCodec): Int =
            if (codec == VideoCodec.H265) bitrateH265 else bitrateH264

        /**
         * Effective bitrate (bps) — what the encoder typically produces,
         * not the KEY_BIT_RATE ceiling. Used for storage estimates.
         */
        fun effectiveBitrateForCodec(codec: VideoCodec): Double {
            val ceiling = getBitrateForCodec(codec)
            val factor =
                if (codec == VideoCodec.H265) H265_EFFECTIVE_FACTOR else H264_EFFECTIVE_FACTOR
            return ceiling * factor
        }

        /**
         * Estimated size per minute in MB for the given codec. Independent
         * of FPS — bitrate is bandwidth-per-second. Uses effective rate so
         * the user's storage forecast matches what they'll actually see.
         */
        fun estimateMbPerMinute(codec: VideoCodec): Double =
            (effectiveBitrateForCodec(codec) * 60.0) / 8.0 / 1024.0 / 1024.0

        /** Estimated size per hour in MB for the given codec. */
        fun estimateMbPerHour(codec: VideoCodec): Double = estimateMbPerMinute(codec) * 60.0

        /** Display string showing tier name + bitrate for the given codec. */
        fun getDisplayString(codec: VideoCodec): String =
            displayName + " (" + formatMbps(getBitrateForCodec(codec)) + " Mbps)"

        /**
         * Approximate perceptual equivalence to a familiar resolution at the
         * given codec + fps. Returns a human-readable label like "~1080p".
         *
         * Computed via bits-per-pixel-frame (bpp = bitrate / (frameW × frameH × fps))
         * and benchmarked against industry-standard "good quality" bitrates:
         *   480p ≈ 0.014 bpp at H.265
         *   720p ≈ 0.027 bpp
         *   1080p ≈ 0.054 bpp
         *   1440p ≈ 0.081 bpp
         *
         * Native frame is fixed at 2560×1920 (4.92 MP, 4:3). The label is
         * capped at "~1440p" — the mosaic is physically incapable of 4K
         * (3840×2160) detail because it's stitched from four 1280×960
         * camera feeds, so any "4K-equivalent" label would be misleading
         * marketing. Higher fps reduces bpp at fixed bitrate, so the
         * equivalent shifts down one tier when going from 15 → 30 fps.
         */
        fun getQualityEquivalent(codec: VideoCodec, fps: Int): String {
            val br = getBitrateForCodec(codec)
            // Frame size: mosaic is 2560×1920 = 4.92 MP per frame.
            val bpp = br.toDouble() / (2560.0 * 1920.0 * maxOf(1, fps))
            return when {
                bpp < 0.012 -> "~SD"
                bpp < 0.022 -> "~480p"
                bpp < 0.040 -> "~720p"
                bpp < 0.067 -> "~1080p"
                else -> "~1440p"
            }
        }

        companion object {
            /**
             * Effective-bitrate calibration. Measured on-device with MAX H.265
             * configured @ 10 Mbps ceiling:
             *   sample 1: 38.4 MB / 30 s = 10.24 Mbps
             *   sample 2: 21.9 MB / 17 s = 10.31 Mbps
             * Average ≈ 10.27 Mbps = 103% of ceiling — the encoder treats
             * KEY_BIT_RATE as a target, not a cap, and briefly overshoots on
             * keyframes. Use 1.0 so the storage forecast matches what users
             * actually see on disk; rounding the displayed values down (Math.round
             * in QualitySettingsApiHandler) keeps the headline conservative.
             * H.264 tracks its cap similarly closely.
             */
            private const val H265_EFFECTIVE_FACTOR = 1.0
            private const val H264_EFFECTIVE_FACTOR = 1.0

            private fun formatMbps(bps: Int): String {
                val m = bps / 1_000_000.0
                return if (m == floor(m)) m.toInt().toString()
                else String.format(Locale.US, "%.1f", m)
            }

            @JvmStatic
            fun fromString(name: String?): RecordingQuality = when (name?.uppercase()) {
                "ECONOMY" -> ECONOMY
                "STANDARD" -> STANDARD
                "HIGH" -> HIGH
                "PREMIUM" -> PREMIUM
                "MAX" -> MAX
                else -> STANDARD
            }
        }
    }

    /**
     * Thin alias for [RecordingQuality], kept so older call sites compile until they're
     * migrated.
     */
    @Deprecated("use RecordingQuality")
    enum class BitratePreset(@JvmField val quality: RecordingQuality) {
        LOW(RecordingQuality.ECONOMY),
        MEDIUM(RecordingQuality.STANDARD),
        HIGH(RecordingQuality.HIGH);

        @JvmField
        val bitrate: Int = quality.bitrateH264

        fun getBitrateForCodec(codec: VideoCodec): Int = quality.getBitrateForCodec(codec)

        fun getDisplayString(codec: VideoCodec): String = quality.getDisplayString(codec)

        companion object {
            @JvmStatic
            fun fromBitrate(bitrate: Int): BitratePreset = when {
                bitrate <= 2_500_000 -> LOW
                bitrate <= 4_500_000 -> MEDIUM
                else -> HIGH
            }
        }
    }

    /**
     * Recording modes (legacy - now uses BitratePreset).
     * FPS values are *defaults per mode*; user-configurable override is
     * honored via UnifiedConfig camera.targetFps and applyFpsChange().
     */
    enum class RecordingMode(@JvmField val fps: Int, @JvmField val bitrate: Int) {
        /** 15 FPS, 6 Mbps */
        NORMAL(15, 6_000_000),

        /** 10 FPS, 2 Mbps (idle) */
        SENTRY(10, 2_000_000),

        /** 10 FPS, 5 Mbps (event) */
        SENTRY_EVENT(10, 5_000_000),

        /** 25 FPS for high-motion capture */
        HIGH_FPS(25, 6_000_000),

        /** 30 FPS, HAL ceiling on this device */
        MAX_FPS(30, 8_000_000)
    }

    /** Streaming quality presets (optimized for various network conditions) */
    enum class StreamingQuality(
        @JvmField val width: Int,
        @JvmField val height: Int,
        @JvmField val fps: Int,
        @JvmField val bitrate: Int,
        @JvmField val displayName: String
    ) {
        /**
         * Ultra Low: 400 kbps - prioritize resolution over FPS for surveillance.
         * Higher resolution at lower FPS looks better than low-res at higher FPS.
         */
        ULTRA_LOW(480, 360, 5, 400_000, "Ultra Low (400k)"),

        /** Low: 600 kbps - for slow connections */
        LOW(640, 480, 8, 600_000, "Low (600k)"),

        /** Medium: 1 Mbps - balanced quality/bandwidth (default) */
        MEDIUM(800, 600, 10, 1_000_000, "Medium (1M)"),

        /** High: 1.5 Mbps - good quality */
        HIGH(960, 720, 12, 1_500_000, "High (1.5M)"),

        /** Ultra High: 2.5 Mbps - best quality */
        ULTRA_HIGH(1280, 960, 15, 2_500_000, "Ultra (2.5M)"),

        /** Smooth: 1280×960 @ 25 fps, 3.5 Mbps - high motion clarity */
        SMOOTH(1280, 960, 25, 3_500_000, "Smooth (3.5M)"),

        /** Max: 1280×960 @ 30 fps, 5 Mbps - HAL ceiling on this device, LAN only */
        MAX(1280, 960, 30, 5_000_000, "Max (5M)");

        companion object {
            // Legacy aliases
            @JvmField
            val LQ = LOW

            @JvmField
            val HQ = HIGH

            @JvmStatic
            fun fromString(name: String?): StreamingQuality = when (name?.uppercase()) {
                "ULTRA_LOW" -> ULTRA_LOW
                "LOW", "LQ" -> LOW
                "MEDIUM" -> MEDIUM
                "HIGH", "HQ" -> HIGH
                "ULTRA_HIGH" -> ULTRA_HIGH
                "SMOOTH" -> SMOOTH
                "MAX" -> MAX
                else -> MEDIUM
            }
        }
    }

    // Current configuration

    /** The current recording mode. */
    var recordingMode: RecordingMode = RecordingMode.NORMAL

    /** The current streaming quality. */
    var streamingQuality: StreamingQuality = StreamingQuality.HQ

    // New configurable settings

    /** Default H.264 for compatibility. */
    private var _videoCodec: VideoCodec = VideoCodec.H264

    // Single user-facing quality knob (replaces legacy bitratePreset string).
    // Resolved bitrate = recordingQuality.getBitrateForCodec(videoCodec).
    // Default STANDARD per the migration policy: existing settings reset to
    // STANDARD on first load after upgrade.
    private var _recordingQuality: RecordingQuality = RecordingQuality.STANDARD

    /** Mirrors recordingQuality, kept until call sites migrate. */
    @Suppress("DEPRECATION")
    private var _bitratePreset: BitratePreset = BitratePreset.MEDIUM

    /** 0 = derive from recordingQuality + codec */
    private var customBitrate = 0

    // AI configuration

    /** Whether AI is enabled. */
    var isAiEnabled: Boolean = true

    /** The SAD threshold. */
    var sadThreshold: Float = 0.05f

    /** Whether grayscale AI mode is enabled. */
    var isGrayscaleAi: Boolean = false

    // ==================== CODEC/BITRATE SETTINGS ====================

    /** Gets the current video codec. */
    fun getVideoCodec(): VideoCodec = _videoCodec

    /**
     * Sets the video codec (H.264 or H.265).
     * H.265 provides ~50% better compression but requires hardware support.
     * Bitrate is automatically adjusted to maintain equivalent quality.
     */
    fun setVideoCodec(codec: VideoCodec) {
        _videoCodec = codec
        // Codec change re-derives bitrate from the active quality tier.
        customBitrate = 0 // re-derive via getEffectiveBitrate
    }

    /** Gets the user-selected recording quality tier. */
    fun getRecordingQuality(): RecordingQuality = _recordingQuality

    /**
     * Sets the recording quality tier and clears any custom-bitrate override
     * so the new tier's bitrate (resolved against the current codec) takes
     * effect on the next encoder reinit.
     */
    @Suppress("DEPRECATION")
    fun setRecordingQuality(quality: RecordingQuality) {
        _recordingQuality = quality
        customBitrate = 0
        // Keep legacy bitratePreset alias roughly in sync for any code that
        // still reads it. Map ECONOMY/STANDARD → LOW/MEDIUM, the rest → HIGH.
        _bitratePreset = when (quality) {
            RecordingQuality.ECONOMY -> BitratePreset.LOW
            RecordingQuality.STANDARD -> BitratePreset.MEDIUM
            else -> BitratePreset.HIGH
        }
    }

    /** Gets the current bitrate preset. */
    @Suppress("DEPRECATION")
    fun getBitratePreset(): BitratePreset = _bitratePreset

    /**
     * Sets the bitrate preset.
     * The actual bitrate will be adjusted based on the selected codec.
     * Clears any custom bitrate so the preset takes effect.
     */
    @Suppress("DEPRECATION")
    fun setBitratePreset(preset: BitratePreset) {
        _bitratePreset = preset
        // Set custom bitrate to the codec-aware value from the preset
        customBitrate = preset.getBitrateForCodec(_videoCodec)
    }

    /**
     * Gets the effective bitrate in bps. Order of precedence:
     *   1. customBitrate if explicitly set (>0) — used by AdaptiveBitrate
     *      controller when scaling for thermals or network conditions.
     *   2. The current RecordingQuality tier resolved against the active codec.
     */
    fun getEffectiveBitrate(): Int {
        if (customBitrate > 0) {
            return customBitrate
        }
        return _recordingQuality.getBitrateForCodec(_videoCodec)
    }

    /**
     * Sets a custom bitrate in bps directly (bypasses preset).
     * Used when applying bitrate changes at runtime.
     */
    fun setCustomBitrate(bitrate: Int) {
        // Don't change the preset - just store the custom value
        customBitrate = bitrate
    }

    /** Gets the MIME type for the current codec. */
    fun getCodecMimeType(): String = _videoCodec.mimeType
}
