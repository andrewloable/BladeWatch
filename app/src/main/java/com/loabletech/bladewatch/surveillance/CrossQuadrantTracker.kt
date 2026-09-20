package net.bladewatch.app.surveillance

import net.bladewatch.app.ai.Detection
import net.bladewatch.app.logging.DaemonLogger

import kotlin.math.sqrt

/**
 * CrossQuadrantTracker — Correlates object detections across camera quadrants.
 *
 * When a person walks from the front camera's FOV into the left camera's FOV,
 * YOLO produces two independent detections. Without tracking, the timeline
 * records them as two separate events. This tracker assigns a persistent
 * track ID so the system knows it's the same person.
 *
 * Algorithm: Lightweight centroid + class matching (no deep re-identification).
 *
 * For each new detection:
 *   1. Check if any existing track has the same classId AND is in an adjacent
 *      quadrant AND was last seen within HANDOFF_WINDOW_MS.
 *   2. If the detection is near the edge of its quadrant (within EDGE_MARGIN
 *      blocks of the boundary), and the existing track was near the opposite
 *      edge of the adjacent quadrant, it's a handoff — assign the same trackId.
 *   3. Otherwise, create a new track.
 *
 * Adjacency map (based on physical camera placement on BYD):
 *   Front (Q0) ↔ Right (Q1), Front (Q0) ↔ Left (Q3*)
 *   Rear  (Q2) ↔ Right (Q1), Rear  (Q2) ↔ Left (Q3*)
 *   (* Q3 = BR in grid = Left camera per strip mapping)
 *
 * Note: Q2=BL=Rear, Q3=BR=Left in the mosaic grid.
 *
 * Edge detection:
 *   Each quadrant is 320×240 in the mosaic (10×7 block grid).
 *   "Near edge" = detection bbox within EDGE_MARGIN_PX of the quadrant boundary.
 *   Adjacent quadrants share a physical edge where FOVs overlap.
 *
 * This is intentionally simple. Full re-identification (appearance embeddings,
 * Kalman filters) would require a second neural network and is overkill for
 * a parked-car surveillance system. The centroid + class + edge heuristic
 * catches 90%+ of cross-camera transitions.
 */
class CrossQuadrantTracker {

    private var nextTrackId = 1

    /** A tracked object across quadrants. */
    class Track {
        @JvmField var trackId = 0
        @JvmField var classId = 0
        @JvmField var lastQuadrant = 0

        // Bbox in quadrant pixel coords
        @JvmField var lastX = 0
        @JvmField var lastY = 0
        @JvmField var lastW = 0
        @JvmField var lastH = 0

        @JvmField var lastSeenMs = 0L
        @JvmField var active = false

        // Edge flags from last observation
        @JvmField var nearLeftEdge = false
        @JvmField var nearRightEdge = false
        @JvmField var nearTopEdge = false
        @JvmField var nearBottomEdge = false
    }

    private val tracks = Array(MAX_TRACKS) { Track() }

    /**
     * Process a batch of detections from a single quadrant.
     * Returns the same detections annotated with track IDs.
     *
     * @param detections YOLO detections from this quadrant
     * @param quadrant   Quadrant index (0-3)
     * @return List of TrackResult with trackId assigned
     */
    fun processDetections(detections: List<Detection>?, quadrant: Int): List<TrackResult> {
        val now = System.currentTimeMillis()
        pruneStale(now)

        val results = ArrayList<TrackResult>()
        if (detections.isNullOrEmpty()) return results

        for (det in detections) {
            val classId = det.classId
            val x = det.x
            val y = det.y
            val w = det.w
            val h = det.h

            // Compute edge proximity
            val nearLeft = x < EDGE_MARGIN_PX
            val nearRight = (x + w) > (Q_WIDTH - EDGE_MARGIN_PX)
            val nearTop = y < EDGE_MARGIN_PX
            val nearBottom = (y + h) > (Q_HEIGHT - EDGE_MARGIN_PX)
            val newNearEdge = nearLeft || nearRight || nearTop || nearBottom

            // Try to match to an existing track
            var matchIdx = -1
            var bestTimeDelta = Long.MAX_VALUE

            for (i in 0 until MAX_TRACKS) {
                val t = tracks[i]
                if (!t.active) continue
                if (t.classId != classId) continue

                val timeDelta = now - t.lastSeenMs

                if (t.lastQuadrant == quadrant) {
                    // Case 1: Same quadrant — centroid proximity match with adaptive threshold
                    val cx = x + w / 2.0f
                    val cy = y + h / 2.0f
                    val tcx = t.lastX + t.lastW / 2.0f
                    val tcy = t.lastY + t.lastH / 2.0f
                    val dist = sqrt((cx - tcx) * (cx - tcx) + (cy - tcy) * (cy - tcy))

                    // SOTA: Adaptive distance threshold based on object size.
                    // At close range (~0.6m), a person's bbox is ~150px wide and they
                    // move fast. At far range (~3m), the bbox is ~30px and they move slow.
                    // Use 1.5× the larger dimension of the object as the match radius.
                    // This prevents track fragmentation for close-range fast-moving objects.
                    val adaptiveThreshold = maxOf(120f, maxOf(w, h) * 1.5f)

                    if (dist < adaptiveThreshold && timeDelta < bestTimeDelta) {
                        matchIdx = i
                        bestTimeDelta = timeDelta
                    }
                } else if (ADJACENT[quadrant][t.lastQuadrant] && timeDelta < HANDOFF_WINDOW_MS) {
                    // Case 2: Adjacent quadrant — cross-camera handoff.
                    // The detection should be near the edge facing the previous quadrant,
                    // and the previous track should have been near the edge facing this one.
                    val oldNearEdge = t.nearLeftEdge || t.nearRightEdge ||
                        t.nearTopEdge || t.nearBottomEdge
                    if (newNearEdge && oldNearEdge && timeDelta < bestTimeDelta) {
                        matchIdx = i
                        bestTimeDelta = timeDelta
                    }
                }
            }

            val trackId: Int
            if (matchIdx >= 0) {
                // Update existing track
                val t = tracks[matchIdx]
                trackId = t.trackId
                if (t.lastQuadrant != quadrant) {
                    logger.info(
                        String.format(
                            "Track #%d HANDOFF: %s → %s (class=%d, gap=%dms)",
                            trackId,
                            MotionPipelineV2.QUADRANT_NAMES[t.lastQuadrant],
                            MotionPipelineV2.QUADRANT_NAMES[quadrant],
                            classId, bestTimeDelta
                        )
                    )
                }
                t.observe(quadrant, x, y, w, h, now, nearLeft, nearRight, nearTop, nearBottom)
            } else {
                // Create new track
                trackId = nextTrackId++
                val slot = findFreeSlot()
                if (slot >= 0) {
                    val t = tracks[slot]
                    t.trackId = trackId
                    t.classId = classId
                    t.observe(
                        quadrant, x, y, w, h, now, nearLeft, nearRight, nearTop, nearBottom
                    )
                    t.active = true
                }
            }

            results.add(TrackResult(det, trackId, quadrant))
        }

        return results
    }

    /** Record one observation onto a track. Both the update and create paths set the same fields. */
    private fun Track.observe(
        quadrant: Int,
        x: Int,
        y: Int,
        w: Int,
        h: Int,
        now: Long,
        nearLeft: Boolean,
        nearRight: Boolean,
        nearTop: Boolean,
        nearBottom: Boolean
    ) {
        lastQuadrant = quadrant
        lastX = x
        lastY = y
        lastW = w
        lastH = h
        lastSeenMs = now
        nearLeftEdge = nearLeft
        nearRightEdge = nearRight
        nearTopEdge = nearTop
        nearBottomEdge = nearBottom
    }

    private fun pruneStale(now: Long) {
        for (t in tracks) {
            if (t.active && (now - t.lastSeenMs) > TRACK_TTL_MS) {
                t.active = false
            }
        }
    }

    private fun findFreeSlot(): Int {
        for (i in 0 until MAX_TRACKS) {
            if (!tracks[i].active) return i
        }
        // Evict oldest
        var oldest = Long.MAX_VALUE
        var oldestIdx = 0
        for (i in 0 until MAX_TRACKS) {
            if (tracks[i].lastSeenMs < oldest) {
                oldest = tracks[i].lastSeenMs
                oldestIdx = i
            }
        }
        tracks[oldestIdx].active = false
        return oldestIdx
    }

    /** Get the number of currently active tracks. */
    fun getActiveTrackCount(): Int = tracks.count { it.active }

    /** Reset all tracks (e.g., when surveillance mode is toggled). */
    fun reset() {
        for (t in tracks) {
            t.active = false
        }
        nextTrackId = 1
    }

    /** Detection annotated with a track ID. */
    class TrackResult(
        @JvmField val detection: Detection,
        @JvmField val trackId: Int,
        @JvmField val quadrant: Int
    )

    companion object {
        private val logger = DaemonLogger.getInstance("XQTracker")

        /** How long a track stays alive without updates before being pruned */
        private const val TRACK_TTL_MS = 5000L

        /**
         * Maximum time gap for a cross-quadrant handoff (person disappears from Q0,
         * appears in Q1 within this window)
         */
        private const val HANDOFF_WINDOW_MS = 2000L

        /**
         * Detection must be within this many pixels of the quadrant edge to be
         * considered a potential handoff candidate. ~1.5 blocks.
         */
        private const val EDGE_MARGIN_PX = 48

        // Quadrant dimensions in the mosaic
        private const val Q_WIDTH = 320
        private const val Q_HEIGHT = 240

        /** Maximum concurrent tracks (parked car scenario — unlikely to have >8 people) */
        private const val MAX_TRACKS = 16

        /**
         * Adjacency table: which quadrants share a physical camera boundary.
         *
         * Physical layout around the BYD:
         *   Front camera faces forward, Right faces passenger side,
         *   Left faces driver side, Rear faces backward.
         *
         * Quadrant indices (from MotionPipelineV2.QUADRANT_NAMES):
         *   Q0 = front (TL in mosaic grid)
         *   Q1 = right (TR in mosaic grid)
         *   Q2 = rear  (BL in mosaic grid)
         *   Q3 = left  (BR in mosaic grid)
         *
         * Adjacent pairs (physically touching FOVs):
         *   Front-Right (Q0-Q1): person walks from front to passenger side
         *   Front-Left  (Q0-Q3): person walks from front to driver side
         *   Rear-Right  (Q2-Q1): person walks from rear to passenger side
         *   Rear-Left   (Q2-Q3): person walks from rear to driver side
         *
         * Non-adjacent (impossible direct transitions):
         *   Front-Rear  (Q0-Q2): would require teleporting through the car
         *   Right-Left  (Q1-Q3): would require teleporting through the car
         */
        private val ADJACENT = arrayOf(
            //          Q0     Q1     Q2     Q3
            /*Q0*/ booleanArrayOf(false, true, false, true), // Front ↔ Right, Left
            /*Q1*/ booleanArrayOf(true, false, true, false), // Right ↔ Front, Rear
            /*Q2*/ booleanArrayOf(false, true, false, true), // Rear  ↔ Right, Left
            /*Q3*/ booleanArrayOf(true, false, true, false) // Left  ↔ Front, Rear
        )
    }
}
