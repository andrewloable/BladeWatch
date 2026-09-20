package net.bladewatch.app.surveillance

import java.util.Locale

import kotlin.math.atan
import kotlin.math.tan

/**
 * SOTA Surveillance Configuration
 *
 * Unified configuration for motion detection, flash filtering, and distance estimation.
 * Provides presets for common use cases and custom configuration for advanced users.
 */
class SurveillanceConfig {

    // ========================================================================
    // Distance Presets
    // ========================================================================

    enum class DistancePreset(
        @JvmField val blockSize: Int,
        @JvmField val requiredBlocks: Int,
        @JvmField val sensitivity: Float,
        @JvmField val minDistanceM: Float,
        @JvmField val maxDistanceM: Float
    ) {
        /** Strict: Large objects only (car/group). Ignores single walkers. */
        CLOSE(32, 4, 0.06f, 0.5f, 3.0f),

        /** Conservative: Solid objects. Good for windy trees. */
        NEAR(32, 3, 0.05f, 1.0f, 5.0f),

        /** Default: Balanced. Catches walking people reliably. */
        MEDIUM(32, 2, 0.04f, 2.0f, 8.0f),

        /** Sensitive: High gain. Catches motion immediately on block entry. */
        FAR(32, 2, 0.03f, 3.0f, 10.0f),

        /** Aggressive: Max sensitivity. Use only indoors/garages. */
        VERY_FAR(32, 1, 0.02f, 5.0f, 15.0f),

        /** Custom configuration - use setters to configure. */
        CUSTOM(32, 2, 0.04f, 0.5f, 15.0f);

        /**
         * Density thresholds for each preset (pixels per block that must change).
         * With 32x32 blocks and stride-2 sampling = ~256 pixels checked per block.
         */
        fun getDensityThreshold(): Int = when (this) {
            CLOSE -> 48 // ~19% - strict
            NEAR -> 40 // ~16% - conservative
            MEDIUM -> 32 // ~12% - balanced (default)
            FAR -> 16 // ~6%  - sensitive
            VERY_FAR -> 12 // ~4%  - aggressive
            else -> 32 // default to balanced
        }
    }

    // ========================================================================
    // Flash Filtering Mode (Now: Shadow Rejection for Grayscale Grid)
    // ========================================================================

    enum class FlashMode(
        @JvmField val flashImmunity: Int,
        @JvmField val temporalFrames: Int,
        @JvmField val useChroma: Boolean
    ) {
        /** No shadow filtering (very sensitive, may catch shadows). */
        OFF(0, 0, false),

        /** Normal shadow filtering - shadowThreshold=40. */
        LOW(1, 0, false),

        /** Strict shadow filtering - shadowThreshold=50. */
        MEDIUM(2, 0, false),

        /** Maximum shadow filtering - shadowThreshold=60. */
        HIGH(3, 0, false),

        /** Adaptive filtering with temporal consistency. */
        ADAPTIVE(2, 3, false),

        /** Maximum filtering - temporal + strict shadow. */
        MAXIMUM(3, 3, true)
    }

    // ========================================================================
    // Configuration Fields
    // ========================================================================

    // Distance filtering.
    //
    // distancePreset and flashMode keep a separate private backing field because several
    // setters below (setBlockSize, setFlashImmunity, ...) must reset them to CUSTOM/OFF
    // WITHOUT re-running the side effects their own setters have -- the Java original
    // assigned the field directly for exactly that reason.
    // Each of these keeps a private backing field because the preset setters
    // (distancePreset / flashMode) must write them WITHOUT tripping the
    // "switch to CUSTOM/OFF" side effect that the individual setters carry.
    private var distancePresetValue = DistancePreset.MEDIUM
    private var flashModeValue = FlashMode.ADAPTIVE
    private var blockSizeValue = 32
    private var requiredBlocksValue = 3
    private var sensitivityValue = 0.04f
    private var flashImmunityValue = 2
    private var temporalFramesValue = 3

    var blockSize: Int
        get() = blockSizeValue
        set(value) {
            blockSizeValue = value.coerceIn(8, 64)
            distancePresetValue = DistancePreset.CUSTOM
        }

    var requiredBlocks: Int
        get() = requiredBlocksValue
        set(value) {
            requiredBlocksValue = value.coerceIn(1, 10)
            distancePresetValue = DistancePreset.CUSTOM
        }

    var sensitivity: Float
        get() = sensitivityValue
        set(value) {
            sensitivityValue = value.coerceIn(0.01f, 0.20f)
            distancePresetValue = DistancePreset.CUSTOM
        }

    /** Allow close objects (was 2.0f) */
    var minDistanceM = 0.5f
        private set

    var maxDistanceM = 10.0f
        private set

    // Flash filtering
    var flashImmunity: Int
        get() = flashImmunityValue
        set(value) {
            flashImmunityValue = value.coerceIn(0, 3)
            flashModeValue = FlashMode.OFF // Custom
        }

    var temporalFrames: Int
        get() = temporalFramesValue
        set(value) { temporalFramesValue = value.coerceIn(0, 5) }

    var isUseChroma = false

    // Camera calibration (for accurate distance estimation)
    // NOTE: These are defaults - per-camera calibration is used in estimateDistance()

    /** Default (overridden per quadrant) */
    var cameraHeightM = 0.8f
        private set

    /** Zero tilt for 360 fish-eye cameras */
    var cameraTiltDeg = 0.0f
        private set

    /** Wide angle for 360 fish-eye cameras */
    var verticalFovDeg = 110.0f
        private set

    /** Frame width in pixels */
    var frameWidth = 640
        set(value) { field = value.coerceIn(160, 1920) }

    /** Frame height in pixels */
    var frameHeight = 480
        set(value) { field = value.coerceIn(120, 1080) }

    /** True for 2x2 camera grid */
    var isMosaic = true

    // Object detection
    var aiConfidence = 0.25f
        set(value) { field = value.coerceIn(0.1f, 0.9f) }

    /** Fraction of quadrant height */
    var minObjectSize = 0.12f
        set(value) { field = value.coerceIn(0.02f, 0.5f) }

    var isDetectPerson = true
    var isDetectCar = true
    var isDetectBike = false

    // Recording
    var preRecordSeconds = 5
        set(value) { field = value.coerceIn(1, 30) }

    var postRecordSeconds = 10
        set(value) { field = value.coerceIn(1, 60) }

    // ========================================================================
    // Notification severity gating (item 8)
    //
    // Per-tier mute is enforced device-side via PushSubscription.mutedCategories
    // against the new "surveillance.motion.{notice,alert,critical}" subcategories
    // (see notifications-categories.json). These config fields exist purely so
    // the legacy NotificationGate static helpers compile and so existing callers
    // that read the values keep working. They are NOT persisted any more.
    // ========================================================================
    var isPushNotices = false
    var isPushAlerts = true
    var isPushCritical = true

    // ========================================================================
    // UNIFIED SENSITIVITY (0-100%)
    // ========================================================================
    // Single slider that controls both density and alarm thresholds
    // Maps to technical parameters internally

    /** Default: 50% (Medium) */
    var unifiedSensitivity = 50
        set(value) { field = value.coerceIn(0, 100) }

    /** Night mode toggle (affects shadow threshold) */
    var isNightMode = false

    // ========================================================================
    // V2 Pipeline Settings
    // ========================================================================

    /** outdoor, garage, street */
    var environmentPreset = "outdoor"

    /** close, normal, extended */
    var detectionZone = "normal"

    /** 1-10 seconds */
    var loiteringTimeSeconds = 3
        set(value) { field = value.coerceIn(1, 10) }

    /** 1-5 */
    var sensitivityLevel = 3
        set(value) { field = value.coerceIn(1, 5) }

    /**
     * front, right, rear, left (matches quadrant order: Q0=front, Q1=right, Q2=rear,
     * Q3=left)
     */
    val cameraEnabled = booleanArrayOf(true, true, true, true)

    var isMotionHeatmapEnabled = false
    var isFilterDebugLogEnabled = false

    /** 0=OFF, 1=LIGHT, 2=NORMAL, 3=AGGRESSIVE */
    var shadowFilterMode = 2
        set(value) { field = value.coerceIn(0, 3) }

    // ========================================================================
    // Per-Quadrant Sensitivity / Zone Overrides
    // ========================================================================
    // null = inherit the global value. Indexed Q0=front, Q1=right, Q2=rear, Q3=left.
    // Side cams (Q1, Q3) often want stricter recall than front/rear because
    // a parking-lot neighbor pulls into the side stalls — these overrides let
    // the user crank just the sides without flooding front/rear with false
    // positives.

    /** 1-5, null = inherit */
    private val quadrantSensitivityOverride = arrayOfNulls<Int>(4)

    /** close|normal|extended, null = inherit */
    private val quadrantDetectionZoneOverride = arrayOfNulls<String>(4)

    /**
     * Resolved sensitivity level for a quadrant: per-quadrant override if set,
     * otherwise the global `sensitivityLevel`.
     */
    fun getEffectiveSensitivityLevel(quadrant: Int): Int {
        if (quadrant in 0..3) {
            quadrantSensitivityOverride[quadrant]?.let { return it }
        }
        return sensitivityLevel
    }

    /**
     * Resolved detection zone for a quadrant: per-quadrant override if set,
     * otherwise the global `detectionZone`.
     */
    fun getEffectiveDetectionZone(quadrant: Int): String {
        if (quadrant in 0..3) {
            quadrantDetectionZoneOverride[quadrant]?.let { return it }
        }
        return detectionZone
    }

    fun getQuadrantSensitivityOverride(quadrant: Int): Int? {
        if (quadrant < 0 || quadrant >= 4) return null
        return quadrantSensitivityOverride[quadrant]
    }

    fun setQuadrantSensitivityOverride(quadrant: Int, level: Int?) {
        if (quadrant < 0 || quadrant >= 4) return
        quadrantSensitivityOverride[quadrant] = level?.coerceIn(1, 5)
    }

    fun getQuadrantDetectionZoneOverride(quadrant: Int): String? {
        if (quadrant < 0 || quadrant >= 4) return null
        return quadrantDetectionZoneOverride[quadrant]
    }

    fun setQuadrantDetectionZoneOverride(quadrant: Int, zone: String?) {
        if (quadrant < 0 || quadrant >= 4) return
        if (zone == null) {
            quadrantDetectionZoneOverride[quadrant] = null
            return
        }
        if (zone == "close" || zone == "normal" || zone == "extended") {
            quadrantDetectionZoneOverride[quadrant] = zone
        }
    }

    fun isCameraEnabled(quadrant: Int): Boolean =
        quadrant in 0..3 && cameraEnabled[quadrant]

    fun setCameraEnabled(quadrant: Int, enabled: Boolean) {
        if (quadrant in 0..3) cameraEnabled[quadrant] = enabled
    }

    // ========================================================================
    // Surveillance Schedule
    // ========================================================================
    val schedule = SurveillanceSchedule()

    // ========================================================================
    // Constructors
    // ========================================================================

    constructor() {
        // Use defaults
    }

    constructor(distancePreset: DistancePreset, flashMode: FlashMode) {
        this.distancePreset = distancePreset
        this.flashMode = flashMode
    }

    // ========================================================================
    // Distance Preset Methods
    // ========================================================================

    var distancePreset: DistancePreset
        get() = distancePresetValue
        set(preset) {
            distancePresetValue = preset
            if (preset != DistancePreset.CUSTOM) {
                blockSizeValue = preset.blockSize
                requiredBlocksValue = preset.requiredBlocks
                sensitivityValue = preset.sensitivity
                minDistanceM = preset.minDistanceM
                maxDistanceM = preset.maxDistanceM
            }
        }

    // ========================================================================
    // Flash Mode Methods
    // ========================================================================

    var flashMode: FlashMode
        get() = flashModeValue
        set(mode) {
            flashModeValue = mode
            flashImmunityValue = mode.flashImmunity
            temporalFramesValue = mode.temporalFrames
            isUseChroma = mode.useChroma
        }

    // ========================================================================
    // Custom Configuration Setters
    // ========================================================================

    fun setDistanceRange(minM: Float, maxM: Float) {
        minDistanceM = maxOf(0.5f, minM)
        maxDistanceM = maxOf(minM + 1.0f, maxM)
        distancePresetValue = DistancePreset.CUSTOM
    }

    // ========================================================================
    // Camera Calibration
    // ========================================================================

    fun setCameraCalibration(heightM: Float, tiltDeg: Float, fovDeg: Float) {
        cameraHeightM = maxOf(0.1f, heightM)
        cameraTiltDeg = tiltDeg.coerceIn(-45.0f, 45.0f)
        verticalFovDeg = fovDeg.coerceIn(20.0f, 120.0f)
    }

    fun setResolution(width: Int, height: Int) {
        frameWidth = width
        frameHeight = height
    }

    // ========================================================================
    // Distance Estimation (360 Fish-Eye / Wide Angle - Mosaic Aware)
    // ========================================================================

    /**
     * Estimates real-world distance from pixel Y coordinate.
     * Optimized for 360° surround view systems with fish-eye (wide angle) cameras.
     *
     * Mosaic Layout (640x480):
     * ```
     * [ Front (0,0)    ][ Right (320,0)   ]   <- Top row: Y = 0 to 239
     * [ Rear  (0,240)  ][ Left  (320,240) ]   <- Bottom row: Y = 240 to 479
     * ```
     *
     * KEY INSIGHT: In each quadrant, Y=0 is the TOP (horizon/sky), Y=239 is BOTTOM
     * (ground/close). Objects with feet near the bottom of a quadrant are CLOSE.
     * Objects with feet near the middle of a quadrant are FAR.
     *
     * @param globalY Y coordinate in full mosaic frame (0 = top, frameHeight = bottom)
     * @return Estimated distance in meters
     */
    fun estimateDistance(globalY: Int): Float = estimateDistance(-1, globalY)

    /**
     * Quadrant-aware variant. When [quadrant] is in [0,3], picks the
     * camera-height calibration per camera (FRONT/SIDE/REAR/SIDE) instead of
     * inferring from mosaic row. Side cameras (Q1=right, Q3=left) are
     * mirror-mounted at HEIGHT_SIDE which is materially taller than the front
     * grille / rear plate; using the wrong height under-reports distance by
     * ~20-30%.
     */
    fun estimateDistanceForQuadrant(quadrant: Int, globalY: Int): Float =
        estimateDistance(quadrant, globalY)

    private fun estimateDistance(quadrant: Int, globalY: Int): Float {
        if (globalY <= 0) return 999.0f

        // Per-camera calibration
        val currentCamHeight: Float

        /** All 360 cameras: zero tilt */
        val currentCamTilt = TILT_ZERO

        /** All 360 cameras: wide angle */
        val currentFov = FOV_WIDE

        val localY: Double
        val quadrantHeight: Double

        if (isMosaic) {
            val halfH = frameHeight / 2 // 240 for 480p

            if (globalY < halfH) {
                localY = globalY.toDouble() // 0-239 within top quadrant
                quadrantHeight = halfH.toDouble() // 240
            } else {
                localY = (globalY - halfH).toDouble() // Convert to local: 240->0, 479->239
                quadrantHeight = halfH.toDouble() // 240
            }

            // Quadrant order: Q0=front, Q1=right, Q2=rear, Q3=left
            currentCamHeight = when (quadrant) {
                1, 3 -> HEIGHT_SIDE
                2 -> HEIGHT_REAR
                0 -> HEIGHT_FRONT
                // Legacy callers without a quadrant: fall back to
                // top-row=FRONT, bottom-row=REAR (the historic behavior).
                else -> if (globalY < halfH) HEIGHT_FRONT else HEIGHT_REAR
            }
        } else {
            // Single camera view
            currentCamHeight = HEIGHT_FRONT
            localY = globalY.toDouble()
            quadrantHeight = frameHeight.toDouble()
        }

        // EDGE CLAMPING: If feet touch bottom of quadrant, person is very close
        if (localY >= (quadrantHeight - EDGE_BUFFER_PX)) {
            return 0.5f // Very close - feet at edge of FOV
        }

        // OPTICAL MATH for Fish-Eye / Wide Angle Camera
        //
        // The optical center (horizon) is at the TOP of each quadrant (localY=0)
        // because 360° cameras point outward from the car, and the top of the
        // image shows the horizon while the bottom shows the ground near the car.
        //
        // With 110° vertical FOV:
        // - localY=0 (top) = horizon = infinite distance
        // - localY=120 (middle) = 55° down = ~1.5m for 0.9m camera height
        // - localY=239 (bottom) = 110° down = very close (~0.3m)

        // Focal length in pixels
        val fy = (quadrantHeight / 2.0) / tan(Math.toRadians(currentFov / 2.0))

        // Pixel deviation from horizon (top of quadrant)
        // localY=0 → v=0 (horizon), localY=239 → v=239 (max down angle)
        val v = localY

        // Calculate angle below horizon
        val angleFromHorizon = atan(v / fy)

        // Total angle from horizontal (tilt + pixel angle)
        val totalAngle = Math.toRadians(currentCamTilt.toDouble()) + angleFromHorizon

        // If looking at/above horizon, return far distance
        if (totalAngle <= 0.02) return 999.0f

        // Distance = Camera Height / tan(angle)
        // As angle increases (looking more downward), distance decreases
        val distance = (currentCamHeight / tan(totalAngle)).toFloat()

        // Clamp to reasonable range
        if (distance < 0.3f) return 0.3f
        if (distance > 50.0f) return 50.0f

        return distance
    }

    /**
     * Calculates expected pixel height for an object at given distance.
     *
     * @param realHeightM Real-world height of object (e.g., 1.7m for person)
     * @param distanceM Distance to object in meters
     * @return Expected height in pixels
     */
    fun expectedPixelHeight(realHeightM: Float, distanceM: Float): Int {
        if (distanceM <= 0) return frameHeight

        val cy = frameHeight / 2.0
        val fy = cy / tan(Math.toRadians(verticalFovDeg / 2.0))

        return ((fy * realHeightM) / distanceM).toInt()
    }

    /**
     * Validates if object size makes sense for the estimated distance.
     *
     * @param distanceM Estimated distance
     * @param heightPx Object height in pixels
     * @return true if size is valid for distance
     */
    fun isValidSizeForDistance(distanceM: Float, heightPx: Int): Boolean {
        // Expected height of a 1.7m human at this distance
        val expectedHumanHeight = expectedPixelHeight(1.7f, distanceM)

        // Allow 20% to 300% of human size (catches cars, bikes, etc.)
        return heightPx > (expectedHumanHeight * 0.2f) &&
            heightPx < (expectedHumanHeight * 3.0f)
    }

    // ========================================================================
    // Getters
    // ========================================================================

    // ========================================================================
    // UNIFIED SENSITIVITY API
    // ========================================================================

    /**
     * Sets the unified motion sensitivity (0-100%).
     *
     * This single slider controls both:
     * - Density Threshold: How many pixels must change per block
     * - Alarm Threshold: How many blocks must trigger to start recording
     *
     * Mapping:
     * - 0-30%:   LOW sensitivity (large/close objects only)
     * - 31-60%:  MEDIUM sensitivity (balanced, default)
     * - 61-80%:  HIGH sensitivity (detects distant objects)
     * - 81-100%: VERY HIGH sensitivity (any motion)
     *
     * @param sensitivity 0-100 percentage
     */
    /**
     * Gets the shadow threshold based on flash immunity level and night mode.
     *
     * Shadow threshold determines the minimum luma difference to count as motion.
     * Higher values = more aggressive shadow filtering (less sensitive).
     *
     * Flash immunity slider (0-3) maps to shadow threshold:
     * - 0 (OFF): 20 (very sensitive, catches faint changes)
     * - 1 (LOW): 30 (normal filtering)
     * - 2 (MEDIUM): 40 (moderate filtering)
     * - 3 (HIGH/MAX): 50 (aggressive filtering, ignores most shadows)
     *
     * Night mode adds +10 to the threshold for extra shadow rejection.
     *
     * @return Shadow threshold (20-60)
     */
    val shadowThreshold: Int get() {
        // Base threshold from flash immunity level (shadow rejection slider)
        val baseThreshold = when (flashImmunityValue) {
            0 -> 20 // OFF - very sensitive
            1 -> 30 // LOW - normal
            2 -> 40 // MEDIUM - moderate
            3 -> 50 // HIGH - aggressive
            else -> 40 // Default to medium
        }

        // Night mode adds extra filtering
        return if (isNightMode) baseThreshold + 10 else baseThreshold
    }

    /**
     * Gets the density threshold based on distance preset OR unified sensitivity.
     *
     * Density threshold = pixels per block that must change.
     * With 32x32 blocks and stride-2 sampling, we check ~256 pixels per block.
     *
     * If a distance preset is active, use its density.
     * Otherwise, map from unified sensitivity slider.
     *
     * @return Density threshold (8-48)
     */
    val densityThreshold: Int get() = when {
        // SOTA: Density is controlled by sensitivity slider, NOT distance
        // Distance only controls minObjectSize (AI detection range)
        // Map from unified sensitivity (0-100%)
        // Lower density = more sensitive (fewer pixels need to change per block)
        unifiedSensitivity >= 81 -> 8 // Very High: ~3% - very aggressive
        unifiedSensitivity >= 61 -> 12 // High: ~5% - sensitive
        unifiedSensitivity >= 41 -> 16 // Medium-High: ~6% - balanced-sensitive
        unifiedSensitivity >= 21 -> 24 // Medium: ~9% - balanced
        else -> 48 // Low: ~19% - strict
    }

    /**
     * Gets the alarm block threshold based on distance preset OR unified sensitivity.
     *
     * Alarm threshold = number of blocks that must be active to trigger.
     *
     * If a distance preset is active, use its required blocks.
     * Otherwise, map from unified sensitivity slider.
     *
     * @return Alarm block threshold (1-4)
     */
    val alarmBlockThreshold: Int get() {
        // SOTA: Alarm threshold is controlled by requiredBlocks (set by sensitivity slider)
        // Distance only controls minObjectSize (AI detection range)
        // Use the requiredBlocks field directly (set by sensitivity slider 1-5)
        return requiredBlocksValue
    }

    // ========================================================================
    // Utility Methods
    // ========================================================================

    /** Calculates total grid blocks for current configuration. */
    fun getTotalBlocks(frameWidth: Int, frameHeight: Int): Int =
        (frameWidth / blockSizeValue) * (frameHeight / blockSizeValue)

    override fun toString(): String = String.format(
        Locale.US,
        "SurveillanceConfig{distance=%s, flash=%s, block=%d, required=%d, " +
            "sensitivity=%.2f, temporal=%d, chroma=%b}",
        distancePresetValue, flashModeValue, blockSizeValue, requiredBlocksValue,
        sensitivityValue, temporalFramesValue, isUseChroma
    )

    companion object {
        /**
         * Edge Clamping: If motion is within this many pixels of quadrant bottom,
         * assume feet are cut off by FOV and force "Very Close" distance.
         */
        private const val EDGE_BUFFER_PX = 5

        // ====================================================================
        // Per-Camera Calibration (360 System / Fish-Eye Profile)
        // ====================================================================
        // 360 cameras are located lower on the car body

        /** Grille / Logo height */
        private const val HEIGHT_FRONT = 0.8f

        /** Trunk Handle / Plate */
        private const val HEIGHT_REAR = 0.9f

        /** Side Mirrors */
        private const val HEIGHT_SIDE = 1.1f

        // Fish-eye cameras look straight out (0 tilt) but have WIDE FOV to see ground
        // Standard 360 cameras have ~100-120 degree vertical FOV
        private const val TILT_ZERO = 0.0f

        /** KEY FIX for 360 systems */
        private const val FOV_WIDE = 110.0f
    }
}
