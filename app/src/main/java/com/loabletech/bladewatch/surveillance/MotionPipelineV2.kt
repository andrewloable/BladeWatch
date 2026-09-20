package net.bladewatch.app.surveillance

import net.bladewatch.app.logging.DaemonLogger

import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Wrapper for the native V2 per-quadrant motion detection pipeline.
 *
 * Handles config serialization, result deserialization, and provides
 * a clean API for SurveillanceEngineGpu to call.
 *
 * The `NativeMotion.*` entry points it calls are TOP-LEVEL functions in this package (see
 * NativeMotion.kt for why that form is required for JNI), so they are spelled unqualified
 * here. A Kotlin caller in another package imports them by name,
 * e.g. `import net.bladewatch.app.surveillance.initPipelineV2`; Java callers keep spelling
 * `NativeMotion.initPipelineV2()`.
 */
class MotionPipelineV2 {

    // Native struct sizes (queried at init)
    private var configStructSize = 0
    private var resultStructSize = 0

    // Expected sizes with shadow filter fields (for backward compatibility)
    // Old config: up to maxDistanceRow = 56 bytes (varies by alignment)
    // New config: + shadowFilterMode(4) + chromaRatioTolerance(4) + shadowPixelFraction(4)
    //             + oscillationThreshold(4) = +16 bytes
    // Old result: brightnessSuppressed(1) + 3 padding = ends at same offset
    // New result: brightnessSuppressed(1) + shadowFiltered(1) + 2 padding
    private var nativeHasShadowFilter = false

    // Pre-allocated direct ByteBuffers for JNI (zero GC)
    private var configBuffer: ByteBuffer? = null
    private var resultBuffer: ByteBuffer? = null

    /** Parsed results (reused across frames) */
    private val results = Array(NUM_QUADRANTS) { QuadrantResult() }

    private var initialized = false

    /** Per-quadrant detection result. */
    class QuadrantResult {
        @JvmField var motionDetected = false
        @JvmField var threatLevel = 0
        @JvmField var activeBlocks = 0
        @JvmField var confirmedBlocks = 0
        @JvmField var componentSize = 0
        @JvmField var centroidX = 0f
        @JvmField var centroidY = 0f
        @JvmField var meanLuma = 0f
        @JvmField var brightnessSuppressed = false
        @JvmField var shadowFiltered = false
        @JvmField val blockConfidence = FloatArray(TOTAL_BLOCKS)
    }

    /** Pipeline configuration. Set fields and call [applyConfig]. */
    class Config {
        // Stage 1: Brightness
        @JvmField var brightnessShiftThreshold = 0.15f
        @JvmField var brightnessSuppressionFrames = 5

        // Stage 2: Block thresholds
        @JvmField var shadowThreshold = 30
        @JvmField var lumaRatioThreshold = 1.3f
        @JvmField var edgeDiffThreshold = 15
        @JvmField var densityThreshold = 12

        // Stage 3: Temporal
        // With increment=0.3 and threshold=0.7, a block needs 3 consecutive active frames
        // (0.0 → 0.3 → 0.6 → 0.9 ≥ 0.7) to be confirmed. This filters out brief noise
        // events that only last 1-2 frames (100-200ms).
        @JvmField var confidenceIncrement = 0.3f
        @JvmField var confidenceDecay = 0.1f
        @JvmField var confidenceThreshold = 0.7f

        // Stage 4: Spatial
        @JvmField var minComponentSize = 1

        // Stage 5: Behavioral
        @JvmField var loiteringRadiusBlocks = 2.5f

        /** 3 seconds at 10 FPS */
        @JvmField var loiteringFrames = 30

        // Per-quadrant enable
        @JvmField var quadrantEnabled = booleanArrayOf(true, true, true, true)

        // Alarm threshold
        @JvmField var alarmBlockThreshold = 2

        /**
         * Detection zone: max centroid row for distance filtering.
         * 0 = no limit (extended), 2 = normal (~3m), 4 = close (~1.5m).
         */
        @JvmField var maxDistanceRow = 2

        /**
         * Shadow discrimination (tree shadow / cloud shadow filtering).
         * Mode: 0=OFF, 1=LIGHT, 2=NORMAL, 3=AGGRESSIVE.
         */
        @JvmField var shadowFilterMode = 2

        /** Chrominance ratio tolerance for shadow detection */
        @JvmField var chromaRatioTolerance = 0.10f

        /**
         * Fraction of changed pixels that must be shadow to suppress a block.
         * Raised from 0.5 to 0.6 to reduce risk of the "self-erasing person" bug
         * where a person's own shadow causes their block to be suppressed.
         */
        @JvmField var shadowPixelFraction = 0.6f

        /** Oscillation transitions threshold (in 10-frame window) */
        @JvmField var oscillationThreshold = 3

        /**
         * Java-side gate values for a sensitivity level. Used by per-quadrant
         * post-filtering: the native pipeline runs once with the most-permissive
         * config, and stricter quadrants demote results that don't clear these
         * values. Keep in sync with [applySensitivity].
         */
        class GateThresholds internal constructor(
            @JvmField val alarmBlockThreshold: Int,
            @JvmField val minComponentSize: Int,
            @JvmField val confidenceThreshold: Float
        )

        /** Apply a sensitivity preset (1-5). */
        fun applySensitivity(level: Int) {
            when (level) {
                1 -> { // Low
                    densityThreshold = 32
                    alarmBlockThreshold = 3
                    minComponentSize = 2
                    confidenceIncrement = 0.25f
                    confidenceThreshold = 0.8f
                }

                2 -> {
                    densityThreshold = 20
                    alarmBlockThreshold = 2
                    minComponentSize = 2
                    confidenceIncrement = 0.28f
                    confidenceThreshold = 0.75f
                }

                3 -> { // Default
                    densityThreshold = 12
                    alarmBlockThreshold = 2
                    minComponentSize = 1
                    confidenceIncrement = 0.3f
                    confidenceThreshold = 0.7f
                }

                4 -> {
                    densityThreshold = 8
                    alarmBlockThreshold = 1
                    minComponentSize = 1
                    confidenceIncrement = 0.35f
                    confidenceThreshold = 0.65f
                }

                5 -> { // Max
                    densityThreshold = 4
                    alarmBlockThreshold = 1
                    minComponentSize = 1
                    confidenceIncrement = 0.4f
                    confidenceThreshold = 0.6f
                }
            }
        }

        /**
         * Apply a detection zone preset.
         * Controls how far from the car motion is considered relevant:
         * - close: Only triggers within ~1.5m. Requires larger connected components.
         *          Rejects motion in the top 4 rows (far from car).
         * - normal: Standard ~3m detection range. Rejects top 2 rows.
         * - extended: Full quadrant, any motion triggers. No distance filtering.
         *
         * The grid is 7 rows tall (0=top/far, 6=bottom/close).
         * maxDistanceRow is the cutoff: centroids above this row are rejected.
         */
        fun applyDetectionZone(zone: String?) {
            when (zone) {
                "close" -> {
                    loiteringRadiusBlocks = 1.5f
                    minComponentSize = 2 // Require larger clusters for close-range
                    maxDistanceRow = 4 // Only bottom 3 rows (~43% of quadrant)
                }

                "normal" -> {
                    loiteringRadiusBlocks = 3.0f
                    minComponentSize = 1
                    maxDistanceRow = 2 // Bottom 5 rows (~71% of quadrant)
                }

                "extended" -> {
                    loiteringRadiusBlocks = 5.0f
                    minComponentSize = 1
                    maxDistanceRow = 0 // All rows (no distance filtering)
                }
            }
        }

        /** Apply an environment preset (sets multiple parameters). */
        fun applyEnvironmentPreset(preset: String?) {
            when (preset) {
                "outdoor" -> {
                    applySensitivity(3)
                    applyDetectionZone("normal")
                    loiteringFrames = 30 // 3 seconds
                    brightnessShiftThreshold = 0.15f
                    edgeDiffThreshold = 20
                    // FIX: Fast-motion ghosting — at 10 FPS a person crosses a 32px block
                    // in ~150-200ms (1-2 frames). With increment=0.3 and threshold=0.7,
                    // confirmation requires 3 frames (300ms) — they outrun the filter.
                    // Bump increment to 0.4 so confirmation triggers in 2 frames (200ms).
                    confidenceIncrement = 0.4f
                    confidenceThreshold = 0.7f
                    // Outdoor: tree shadows are the main problem — enable normal filtering.
                    // shadowPixelFraction raised to 0.6 to prevent the "self-erasing person"
                    // bug where a person's own shadow causes the block to be suppressed.
                    shadowFilterMode = 2 // NORMAL
                    chromaRatioTolerance = 0.10f
                    shadowPixelFraction = 0.6f
                    oscillationThreshold = 3
                }

                "garage" -> {
                    applySensitivity(4)
                    applyDetectionZone("close")
                    loiteringFrames = 20 // 2 seconds
                    brightnessShiftThreshold = 0.08f
                    edgeDiffThreshold = 15
                    // Garage: no tree shadows, but fluorescent flicker possible
                    // — light filtering
                    shadowFilterMode = 1 // LIGHT
                    chromaRatioTolerance = 0.15f
                    shadowPixelFraction = 0.7f
                    oscillationThreshold = 4
                }

                "street" -> {
                    applySensitivity(3)
                    applyDetectionZone("normal")
                    loiteringFrames = 50 // 5 seconds
                    brightnessShiftThreshold = 0.15f
                    edgeDiffThreshold = 20
                    // FIX: Fast-motion ghosting — street has even faster-moving objects
                    // (joggers, cyclists). Same 2-frame confirmation as outdoor.
                    confidenceIncrement = 0.4f
                    confidenceThreshold = 0.7f
                    // Street: tree shadows + passing car shadows.
                    // CHANGED from AGGRESSIVE(3) to NORMAL(2). Aggressive mode with
                    // shadowPixelFraction=0.3 was the worst case for the "self-erasing
                    // person" bug — a person's shadow only needs to be 30% of changed
                    // pixels to erase the entire block. The C++ fix now protects blocks
                    // with edge evidence, but NORMAL mode is safer for street scenes
                    // where people and their shadows coexist in the same blocks.
                    shadowFilterMode = 2 // NORMAL (was AGGRESSIVE)
                    chromaRatioTolerance = 0.10f
                    shadowPixelFraction = 0.6f
                    oscillationThreshold = 3
                }
            }
        }

        /**
         * Apply night mode preset.
         * Tuned for the BYD's camera ISP which boosts ISO heavily at night,
         * pushing mean luma to ~75-85 even in darkness. The heavy ISO boost
         * creates significant sensor noise that looks like motion to the
         * standard thresholds.
         */
        fun applyNightMode() {
            // Lower absolute thresholds for crushed, grainy blacks
            shadowThreshold = 14
            lumaRatioThreshold = 1.15f

            // ISO noise creates fake edges. Lower the edge threshold so real
            // objects pass, but keep densityThreshold normal to filter the static.
            edgeDiffThreshold = 8
            densityThreshold = 12 // Do NOT lower — ISO grain triggers false motion

            // Temporal: require 2 frames confirmation (same as outdoor fast-motion fix)
            confidenceIncrement = 0.4f
            confidenceThreshold = 0.7f

            // Headlight suppression: relax brightness shift threshold so passing
            // headlights trigger the brightness suppression stage instead of
            // being misclassified as motion.
            brightnessShiftThreshold = 0.35f
            brightnessSuppressionFrames = 8 // Longer suppression for headlight sweeps

            // Relax shadow filtering — color noise is too high at night for
            // chrominance-based shadow detection to work reliably.
            shadowFilterMode = 1 // LIGHT
            chromaRatioTolerance = 0.25f
            shadowPixelFraction = 0.7f
            oscillationThreshold = 4

            // Keep spatial and behavioral settings from current preset
            // (don't override minComponentSize, loiteringFrames, etc.)
        }

        /**
         * Apply glare mode preset.
         * When direct sunlight hits the lens, the BYD's ISP crushes exposure to
         * prevent blowout, compressing ground contrast from ~40 luma points to ~12.
         * The standard shadowThreshold of 30 makes people invisible.
         *
         * Uses relative multipliers on the user's current settings so their
         * sensitivity preference is respected (high sensitivity → aggressive glare
         * mode, low sensitivity → conservative glare mode).
         */
        fun applyGlareMode() {
            // Scale thresholds down to catch faint, contrast-crushed motion
            shadowThreshold = maxOf(10, (shadowThreshold * 0.5f).toInt())
            lumaRatioThreshold = maxOf(1.05f, lumaRatioThreshold * 0.85f)
            edgeDiffThreshold = maxOf(6, (edgeDiffThreshold * 0.6f).toInt())

            // Keep density threshold high — lens flares create massive sharp edges
            // that would trigger false alarms if density is too low
            densityThreshold = maxOf(14, densityThreshold)

            // Brightness suppression: relax slightly — the ISP is already fighting
            // the sun, so frame-to-frame brightness shifts are larger than normal
            brightnessShiftThreshold = maxOf(brightnessShiftThreshold, 0.20f)

            // Shadow filter: keep NORMAL — shadows are still real in direct sun,
            // they're just lower contrast. The lowered shadowThreshold handles this.
        }

        companion object {
            @JvmStatic
            fun gatesForSensitivity(level: Int): GateThresholds = when (level) {
                1 -> GateThresholds(3, 2, 0.8f)
                2 -> GateThresholds(2, 2, 0.75f)
                3 -> GateThresholds(2, 1, 0.7f)
                4 -> GateThresholds(1, 1, 0.65f)
                5 -> GateThresholds(1, 1, 0.6f)
                else -> GateThresholds(2, 1, 0.7f)
            }

            /**
             * Detection-zone row cutoff. Mirrors [applyDetectionZone]
             * for use in per-quadrant post-filtering. Returns the maxDistanceRow
             * (centroids strictly above this row are rejected).
             */
            @JvmStatic
            fun maxDistanceRowForZone(zone: String?): Int = when (zone) {
                "close" -> 4
                "normal" -> 2
                "extended" -> 0
                else -> 2
            }
        }
    }

    /** Initialize the pipeline. Must be called after native library is loaded. */
    fun init(): Boolean {
        return try {
            // Query native struct sizes
            configStructSize = getPipelineConfigSize()
            resultStructSize = getQuadrantResultSize()

            // Detect if native library includes shadow filter fields.
            //
            // Exact struct layout of PipelineConfigV2 (all fields are 4-byte aligned):
            //   float brightnessShiftThreshold     4 bytes  offset 0
            //   int   brightnessSuppressionFrames   4 bytes  offset 4
            //   int   shadowThreshold               4 bytes  offset 8
            //   float lumaRatioThreshold            4 bytes  offset 12
            //   int   edgeDiffThreshold             4 bytes  offset 16
            //   int   densityThreshold              4 bytes  offset 20
            //   float confidenceIncrement           4 bytes  offset 24
            //   float confidenceDecay               4 bytes  offset 28
            //   float confidenceThreshold           4 bytes  offset 32
            //   int   minComponentSize              4 bytes  offset 36
            //   float loiteringRadiusBlocks         4 bytes  offset 40
            //   int   loiteringFrames               4 bytes  offset 44
            //   bool  quadrantEnabled[4]            4 bytes  offset 48
            //   int   alarmBlockThreshold           4 bytes  offset 52
            //   int   maxDistanceRow                4 bytes  offset 56
            //   --- base total: 60 bytes ---
            //   int   shadowFilterMode              4 bytes  offset 60
            //   float chromaRatioTolerance          4 bytes  offset 64
            //   float shadowPixelFraction           4 bytes  offset 68
            //   int   oscillationThreshold          4 bytes  offset 72
            //   --- full total: 76 bytes ---
            //
            // The base struct (without shadow fields) is exactly 60 bytes.
            // With shadow fields it's exactly 76 bytes (60 + 16).
            // Use exact size check: if configStructSize == 76, shadow is supported.
            // Also accept >= 76 in case future fields are added after shadow fields.
            nativeHasShadowFilter = configStructSize >= BASE_CONFIG_SIZE + SHADOW_FIELDS_SIZE

            logger.info(
                String.format(
                    "V2 struct sizes: config=%d, result=%d (total result=%d), shadowFilter=%s",
                    configStructSize, resultStructSize, resultStructSize * NUM_QUADRANTS,
                    if (nativeHasShadowFilter) "supported" else "NOT supported (old native)"
                )
            )

            // Allocate direct ByteBuffers
            configBuffer = ByteBuffer.allocateDirect(configStructSize)
                .order(ByteOrder.nativeOrder())

            resultBuffer = ByteBuffer.allocateDirect(resultStructSize * NUM_QUADRANTS)
                .order(ByteOrder.nativeOrder())

            // Initialize native pipeline
            initPipelineV2()

            initialized = true
            logger.info("Motion Pipeline V2 initialized")
            true
        } catch (e: Exception) {
            logger.error("Failed to initialize V2 pipeline: " + e.message, e)
            false
        }
    }

    /** Serialize config to the native ByteBuffer. */
    fun applyConfig(config: Config) {
        if (!initialized) return
        val buf = configBuffer ?: return

        buf.clear()
        // Zero-fill the buffer before writing fields. ByteBuffer.clear() only
        // resets position/limit — not the underlying bytes. If the native
        // struct grows in a future build (e.g. partial shadow-fields support
        // between BASE_CONFIG_SIZE and BASE_CONFIG_SIZE+SHADOW_FIELDS_SIZE),
        // any bytes we don't explicitly write would carry stale values from
        // the previous applyConfig call. Costs ~60-76 byte writes — negligible.
        for (i in 0 until buf.capacity()) {
            buf.put(0.toByte())
        }
        buf.position(0)

        // Stage 1
        buf.putFloat(config.brightnessShiftThreshold)
        buf.putInt(config.brightnessSuppressionFrames)

        // Stage 2
        buf.putInt(config.shadowThreshold)
        buf.putFloat(config.lumaRatioThreshold)
        buf.putInt(config.edgeDiffThreshold)
        buf.putInt(config.densityThreshold)

        // Stage 3
        buf.putFloat(config.confidenceIncrement)
        buf.putFloat(config.confidenceDecay)
        buf.putFloat(config.confidenceThreshold)

        // Stage 4
        buf.putInt(config.minComponentSize)

        // Stage 5
        buf.putFloat(config.loiteringRadiusBlocks)
        buf.putInt(config.loiteringFrames)

        // Per-quadrant enable (4 bools → 4 bytes with padding)
        for (i in 0 until NUM_QUADRANTS) {
            buf.put(if (config.quadrantEnabled[i]) 1.toByte() else 0.toByte())
        }

        // Alarm threshold
        buf.putInt(config.alarmBlockThreshold)

        // Detection zone: max centroid row for distance filtering
        buf.putInt(config.maxDistanceRow)

        // Shadow discrimination parameters (only if native supports them)
        if (nativeHasShadowFilter) {
            buf.putInt(config.shadowFilterMode)
            buf.putFloat(config.chromaRatioTolerance)
            buf.putFloat(config.shadowPixelFraction)
            buf.putInt(config.oscillationThreshold)
        }

        buf.flip()
    }

    /**
     * Process a frame through the V2 pipeline.
     *
     * @param frameBuffer 640×480 RGB direct ByteBuffer
     * @param width Frame width
     * @param height Frame height
     * @return Array of 4 QuadrantResult (reused, do not hold references across calls)
     */
    fun processFrame(frameBuffer: ByteBuffer, width: Int, height: Int): Array<QuadrantResult> {
        if (!initialized) return results
        val cfg = configBuffer ?: return results
        val res = resultBuffer ?: return results

        res.clear()

        processFrameV2(frameBuffer, width, height, cfg, res)

        // Deserialize results
        res.rewind()
        for (q in 0 until NUM_QUADRANTS) {
            deserializeResult(res, results[q])
        }

        return results
    }

    /** Deserialize one QuadrantResultV2 from the ByteBuffer. */
    private fun deserializeResult(buf: ByteBuffer, result: QuadrantResult) {
        result.motionDetected = buf.get().toInt() != 0

        // Alignment padding (3 bytes after bool to align int)
        buf.get()
        buf.get()
        buf.get()

        result.threatLevel = buf.int
        result.activeBlocks = buf.int
        result.confirmedBlocks = buf.int
        result.componentSize = buf.int
        result.centroidX = buf.float
        result.centroidY = buf.float
        result.meanLuma = buf.float
        result.brightnessSuppressed = buf.get().toInt() != 0

        if (nativeHasShadowFilter) {
            // New layout: 2 bools + 2 padding bytes
            result.shadowFiltered = buf.get().toInt() != 0
            buf.get()
            buf.get() // 2 bytes padding to align float array
        } else {
            // Old layout: 1 bool + 3 padding bytes
            result.shadowFiltered = false
            buf.get()
            buf.get()
            buf.get() // 3 bytes padding
        }

        // Block confidence array (70 floats)
        for (i in 0 until TOTAL_BLOCKS) {
            result.blockConfidence[i] = buf.float
        }
    }

    /** Check if any quadrant detected motion above the given threat threshold. */
    fun hasMotion(minThreatLevel: Int): Boolean =
        results.any { it.motionDetected && it.threatLevel >= minThreatLevel }

    /** Get the highest threat level across all quadrants. */
    fun getMaxThreatLevel(): Int {
        var max = THREAT_NONE
        for (r in results) {
            if (r.threatLevel > max) {
                max = r.threatLevel
            }
        }
        return max
    }

    /** Get bitmask of quadrants with motion (bit 0 = Q0, bit 1 = Q1, etc.) */
    fun getActiveQuadrantMask(): Int {
        var mask = 0
        for (q in 0 until NUM_QUADRANTS) {
            if (results[q].motionDetected) {
                mask = mask or (1 shl q)
            }
        }
        return mask
    }

    /**
     * Get the quadrant with the highest threat level (for YOLO priority).
     * Returns -1 if no motion detected.
     */
    fun getHighestThreatQuadrant(): Int {
        var bestQ = -1
        var bestThreat = THREAT_NONE
        for (q in 0 until NUM_QUADRANTS) {
            if (results[q].threatLevel > bestThreat) {
                bestThreat = results[q].threatLevel
                bestQ = q
            }
        }
        return bestQ
    }

    fun isInitialized(): Boolean = initialized

    /**
     * Check if the loaded native library supports shadow filter fields.
     * Returns false if running against an older .so that doesn't have the shadow filter
     * struct fields.
     */
    fun isNativeShadowFilterSupported(): Boolean = nativeHasShadowFilter

    fun getResults(): Array<QuadrantResult> = results

    companion object {
        private val logger = DaemonLogger.getInstance("MotionV2")

        const val NUM_QUADRANTS = 4
        const val GRID_COLS = 10
        const val GRID_ROWS = 7

        /** 70 */
        const val TOTAL_BLOCKS = GRID_COLS * GRID_ROWS

        /**
         * Quadrant names for logging.
         * Grid layout (from GpuDownscaler shader): TL=Front, TR=Right, BL=Rear, BR=Left
         * Quadrant indices: Q0=TL, Q1=TR, Q2=BL, Q3=BR
         * FIX: Q2 and Q3 were swapped — Q2 is BL (Rear), Q3 is BR (Left).
         */
        @JvmField
        val QUADRANT_NAMES = arrayOf("front", "right", "rear", "left")

        // Threat levels (must match native THREAT_* constants)
        const val THREAT_NONE = 0

        /** Passing */
        const val THREAT_LOW = 1

        /** Approaching */
        const val THREAT_MEDIUM = 2

        /** Loitering */
        const val THREAT_HIGH = 3

        private const val BASE_CONFIG_SIZE = 60

        /** 4 fields × 4 bytes each */
        private const val SHADOW_FIELDS_SIZE = 16
    }
}
