package com.overdrive.app.surveillance;

import android.media.MediaFormat;

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
public class GpuPipelineConfig {
    
    // Video codec selection
    public enum VideoCodec {
        H264(MediaFormat.MIMETYPE_VIDEO_AVC, "H.264"),
        H265(MediaFormat.MIMETYPE_VIDEO_HEVC, "H.265/HEVC");
        
        public final String mimeType;
        public final String displayName;
        
        VideoCodec(String mimeType, String displayName) {
            this.mimeType = mimeType;
            this.displayName = displayName;
        }
    }
    
    // Bitrate presets (optimized for surveillance)
    // H.265 achieves same quality at ~65% of H.264 bitrate
    public enum BitratePreset {
        LOW(2_000_000, 1_300_000, "Low"),        // H.264: 2 Mbps, H.265: 1.3 Mbps
        MEDIUM(3_000_000, 2_000_000, "Medium"),  // H.264: 3 Mbps, H.265: 2 Mbps
        HIGH(6_000_000, 4_000_000, "High");      // H.264: 6 Mbps, H.265: 4 Mbps
        
        public final int bitrateH264;
        public final int bitrateH265;
        public final String displayName;
        
        // Legacy field for backward compatibility
        public final int bitrate;
        
        BitratePreset(int bitrateH264, int bitrateH265, String displayName) {
            this.bitrateH264 = bitrateH264;
            this.bitrateH265 = bitrateH265;
            this.displayName = displayName;
            this.bitrate = bitrateH264;  // Default to H.264 for legacy code
        }
        
        /**
         * Gets the appropriate bitrate for the given codec.
         * H.265 uses ~65% of H.264 bitrate for equivalent quality.
         */
        public int getBitrateForCodec(VideoCodec codec) {
            return codec == VideoCodec.H265 ? bitrateH265 : bitrateH264;
        }
        
        /**
         * Gets display string showing both bitrates.
         */
        public String getDisplayString(VideoCodec codec) {
            int br = getBitrateForCodec(codec);
            return displayName + " (" + (br / 1_000_000.0) + " Mbps)";
        }
        
        public static BitratePreset fromBitrate(int bitrate) {
            if (bitrate <= 2_500_000) return LOW;
            if (bitrate <= 4_500_000) return MEDIUM;
            return HIGH;
        }
    }
    
    // Recording modes (legacy - now uses BitratePreset)
    public enum RecordingMode {
        NORMAL(15, 6_000_000),      // 15 FPS, 6 Mbps
        SENTRY(10, 2_000_000),      // 10 FPS, 2 Mbps (idle)
        SENTRY_EVENT(10, 5_000_000); // 10 FPS, 5 Mbps (event)
        
        public final int fps;
        public final int bitrate;
        
        RecordingMode(int fps, int bitrate) {
            this.fps = fps;
            this.bitrate = bitrate;
        }
    }
    
    // Streaming quality presets (optimized for various network conditions)
    public enum StreamingQuality {
        // Ultra Low: 400 kbps - prioritize resolution over FPS for surveillance
        // Higher resolution at lower FPS looks better than low-res at higher FPS
        ULTRA_LOW(480, 360, 5, 400_000, "Ultra Low (400k)"),
        
        // Low: 600 kbps - for slow connections
        LOW(640, 480, 8, 600_000, "Low (600k)"),
        
        // Medium: 1 Mbps - balanced quality/bandwidth (default)
        MEDIUM(800, 600, 10, 1_000_000, "Medium (1M)"),
        
        // High: 1.5 Mbps - good quality
        HIGH(960, 720, 12, 1_500_000, "High (1.5M)"),
        
        // Ultra High: 2.5 Mbps - best quality (LAN/WiFi only)
        ULTRA_HIGH(1280, 960, 15, 2_500_000, "Ultra (2.5M)");
        
        // Legacy aliases
        public static final StreamingQuality LQ = LOW;
        public static final StreamingQuality HQ = HIGH;
        
        public final int width;
        public final int height;
        public final int fps;
        public final int bitrate;
        public final String displayName;
        
        StreamingQuality(int width, int height, int fps, int bitrate, String displayName) {
            this.width = width;
            this.height = height;
            this.fps = fps;
            this.bitrate = bitrate;
            this.displayName = displayName;
        }
        
        public static StreamingQuality fromString(String name) {
            if (name == null) return MEDIUM;
            switch (name.toUpperCase()) {
                case "ULTRA_LOW": return ULTRA_LOW;
                case "LOW":
                case "LQ": return LOW;
                case "MEDIUM": return MEDIUM;
                case "HIGH":
                case "HQ": return HIGH;
                case "ULTRA_HIGH": return ULTRA_HIGH;
                default: return MEDIUM;
            }
        }
    }
    
    // Current configuration
    private RecordingMode recordingMode = RecordingMode.NORMAL;
    private StreamingQuality streamingQuality = StreamingQuality.HQ;
    
    // New configurable settings
    private VideoCodec videoCodec = VideoCodec.H264;  // Default H.264 for compatibility
    private BitratePreset bitratePreset = BitratePreset.MEDIUM;  // Default 3 Mbps for balance
    private int customBitrate = 3_000_000;  // Custom bitrate in bps
    
    // AI configuration
    private boolean aiEnabled = true;
    private float sadThreshold = 0.05f;
    private boolean grayscaleAi = false;
    
    /**
     * Gets the current recording mode.
     */
    public RecordingMode getRecordingMode() {
        return recordingMode;
    }
    
    /**
     * Sets the recording mode.
     */
    public void setRecordingMode(RecordingMode mode) {
        this.recordingMode = mode;
    }
    
    /**
     * Gets the current streaming quality.
     */
    public StreamingQuality getStreamingQuality() {
        return streamingQuality;
    }
    
    /**
     * Sets the streaming quality.
     */
    public void setStreamingQuality(StreamingQuality quality) {
        this.streamingQuality = quality;
    }
    
    /**
     * Checks if AI is enabled.
     */
    public boolean isAiEnabled() {
        return aiEnabled;
    }
    
    /**
     * Sets AI enabled state.
     */
    public void setAiEnabled(boolean enabled) {
        this.aiEnabled = enabled;
    }
    
    /**
     * Gets the SAD threshold.
     */
    public float getSadThreshold() {
        return sadThreshold;
    }
    
    /**
     * Sets the SAD threshold.
     */
    public void setSadThreshold(float threshold) {
        this.sadThreshold = threshold;
    }
    
    /**
     * Checks if grayscale AI mode is enabled.
     */
    public boolean isGrayscaleAi() {
        return grayscaleAi;
    }
    
    /**
     * Sets grayscale AI mode.
     */
    public void setGrayscaleAi(boolean enabled) {
        this.grayscaleAi = enabled;
    }
    
    // ==================== NEW CODEC/BITRATE SETTINGS ====================
    
    /**
     * Gets the current video codec.
     */
    public VideoCodec getVideoCodec() {
        return videoCodec;
    }
    
    /**
     * Sets the video codec (H.264 or H.265).
     * H.265 provides ~50% better compression but requires hardware support.
     * Bitrate is automatically adjusted to maintain equivalent quality.
     */
    public void setVideoCodec(VideoCodec codec) {
        this.videoCodec = codec;
        // Recalculate bitrate for new codec
        this.customBitrate = bitratePreset.getBitrateForCodec(codec);
    }
    
    /**
     * Gets the current bitrate preset.
     */
    public BitratePreset getBitratePreset() {
        return bitratePreset;
    }
    
    /**
     * Sets the bitrate preset.
     * The actual bitrate will be adjusted based on the selected codec.
     * Clears any custom bitrate so the preset takes effect.
     */
    public void setBitratePreset(BitratePreset preset) {
        this.bitratePreset = preset;
        // Set custom bitrate to the codec-aware value from the preset
        this.customBitrate = preset.getBitrateForCodec(videoCodec);
    }
    
    /**
     * Gets the effective bitrate in bps.
     * Returns the custom bitrate if set, otherwise the preset bitrate for current codec.
     */
    public int getEffectiveBitrate() {
        // If custom bitrate was explicitly set, use it
        if (customBitrate > 0) {
            return customBitrate;
        }
        return bitratePreset.getBitrateForCodec(videoCodec);
    }
    
    /**
     * Sets a custom bitrate in bps directly (bypasses preset).
     * Used when applying bitrate changes at runtime.
     */
    public void setCustomBitrate(int bitrate) {
        this.customBitrate = bitrate;
        // Don't change the preset - just store the custom value
    }
    
    /**
     * Gets the MIME type for the current codec.
     */
    public String getCodecMimeType() {
        return videoCodec.mimeType;
    }
}
