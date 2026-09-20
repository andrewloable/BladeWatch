package net.bladewatch.app.surveillance

/**
 * A persistent moving subject around the vehicle.
 *
 * One Actor represents one tracked entity (person, vehicle, bike, animal) across multiple frames
 * and possibly multiple cameras. Actors are produced by ActorTracker from raw YOLO detections and
 * consumed by EventTimelineCollector (the per-recording JSON sidecar), ThumbnailBuffer (picking
 * the peak-severity frame), [SeverityClassifier] (NOTICE/ALERT/CRITICAL gating), and the
 * notification and UI layers.
 *
 * No metric distance: everything that quantifies "how close" is a [Proximity] band derived from
 * bbox size in the camera frame, NOT calibrated extrinsics. If extrinsics ever become available,
 * swap the proximity classifier without breaking any consumer.
 */
class Actor(
    @JvmField val actorId: Long,
    @JvmField val classGroup: ClassGroup,
    @JvmField val firstSeenWallMs: Long,
    @JvmField val lastSeenWallMs: Long,
    /** Relative to the recording start, or -1 if pre-trigger. */
    @JvmField val firstSeenRelMs: Long,
    @JvmField val lastSeenRelMs: Long,
    /** One bit per quadrant (0=front, 1=right, 2=rear, 3=left). */
    @JvmField val cameraMask: Int,
    /** Closest approach across the actor's lifetime. */
    @JvmField val peakProximity: Proximity,
    /** Most recent proximity. */
    @JvmField val lastProximity: Proximity,
    @JvmField val trend: Trend,
    /** bbox area + position stable for at least STATIC_DWELL_FRAMES. */
    @JvmField val isStatic: Boolean,
    @JvmField val peakSeverity: Severity,
    @JvmField val peakSeverityWallMs: Long,
    @JvmField val peakSeverityRelMs: Long,
    @JvmField val peakConfidence: Float,
    /** bbox at the peak-severity moment, in crop pixel coords. */
    @JvmField val peakBboxX: Int,
    @JvmField val peakBboxY: Int,
    @JvmField val peakBboxW: Int,
    @JvmField val peakBboxH: Int,
    /**
     * Crop dimensions the peakBbox is measured against.
     *
     * The pipeline alternates between mosaic (320x240) and foveated (640x640) crops depending on
     * whether the foveated cropper is wired up and whether motion blocks are confirmed in the
     * current frame. peakBbox alone is meaningless without knowing which crop space it is in —
     * readers (ThumbnailBuffer, baseline promotion) MUST use these dims to scale bboxes onto
     * whatever frame they are drawing on. Without this the hero JPEG draws the bbox over a
     * different camera region than the actor actually occupied.
     */
    @JvmField val peakBboxQuadW: Int,
    @JvmField val peakBboxQuadH: Int,
    /** The quadrant where peak severity hit. */
    @JvmField val peakCamera: Int,
    /**
     * Most recent observation — for "what does this actor look like NOW" queries (mid-event
     * baseline promotion, future distance estimation). peakBbox describes the forensic/thumbnail
     * moment; lastBbox the freshest.
     */
    @JvmField val lastBboxX: Int,
    @JvmField val lastBboxY: Int,
    @JvmField val lastBboxW: Int,
    @JvmField val lastBboxH: Int
) {

    /** Coarse class taxonomy collapsed from COCO so trackers/UIs deal with 5 things, not 80. */
    enum class ClassGroup {
        PERSON,

        /** car / bus / truck */
        VEHICLE,

        /** bicycle / motorcycle */
        BIKE,
        ANIMAL,
        UNKNOWN
    }

    /**
     * Proximity band — pure pixel-relative classification, derived from bbox height for persons
     * and bbox width for vehicles. No reliance on camera mounting intrinsics or extrinsics.
     */
    enum class Proximity {
        /** bbox at least 60% of the crop dimension. */
        VERY_CLOSE,

        /** bbox 35-60%. */
        CLOSE,

        /** bbox 15-35%. */
        MID,

        /** bbox below 15%. */
        FAR,
        UNKNOWN
    }

    /** Trajectory trend over the last few frames (purely pixel-relative). */
    enum class Trend {
        /** bbox area growing. */
        APPROACHING,

        /** bbox area shrinking. */
        RECEDING,

        /** change within noise. */
        STABLE,
        UNKNOWN
    }

    /** Severity emitted by [SeverityClassifier]; mirrors the three-tier gating. */
    enum class Severity {
        /** background / passing-by / static parked car. */
        NOTICE,

        /** person near the vehicle, vehicle approaching, etc. */
        ALERT,

        /** person at very-close, prolonged dwell at very-close, etc. */
        CRITICAL
    }

    companion object {
        /** Map a COCO class ID to a coarse group. */
        @JvmStatic
        fun groupOf(cocoClassId: Int): ClassGroup = when {
            cocoClassId == 0 -> ClassGroup.PERSON
            cocoClassId == 2 || cocoClassId == 5 || cocoClassId == 7 -> ClassGroup.VEHICLE
            cocoClassId == 1 || cocoClassId == 3 -> ClassGroup.BIKE
            cocoClassId in 14..23 -> ClassGroup.ANIMAL
            else -> ClassGroup.UNKNOWN
        }

        @JvmStatic
        fun groupLabel(g: ClassGroup): String = when (g) {
            ClassGroup.PERSON -> "person"
            ClassGroup.VEHICLE -> "vehicle"
            ClassGroup.BIKE -> "bike"
            ClassGroup.ANIMAL -> "animal"
            else -> "object"
        }

        @JvmStatic
        fun proximityLabel(p: Proximity): String = when (p) {
            Proximity.VERY_CLOSE -> "very close"
            Proximity.CLOSE -> "close"
            Proximity.MID -> "mid"
            Proximity.FAR -> "far"
            else -> "unknown"
        }

        @JvmStatic
        fun severityLabel(s: Severity): String = when (s) {
            Severity.CRITICAL -> "CRITICAL"
            Severity.ALERT -> "ALERT"
            else -> "NOTICE"
        }
    }
}
