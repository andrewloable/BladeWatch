package net.bladewatch.app.surveillance

import net.bladewatch.app.ai.Detection
import net.bladewatch.app.surveillance.Actor.ClassGroup
import net.bladewatch.app.surveillance.Actor.Proximity
import net.bladewatch.app.surveillance.Actor.Severity
import net.bladewatch.app.surveillance.Actor.Trend

import kotlin.math.abs

/**
 * ActorTracker — Persistent tracker that turns per-frame YOLO detections into
 * lifetime-aware [Actor] records.
 *
 * Design notes:
 *  - Sits on top of the existing motion+YOLO pipeline; does NOT replace it.
 *  - One tracker instance per surveillance engine; tracks across cameras.
 *  - Association: greedy IoU within the same quadrant; class-group must match.
 *    Cross-quadrant handoff is deferred to [CrossQuadrantTracker] which
 *    keeps doing what it does today — this tracker assigns its own actorIds and
 *    is independent.
 *  - Proximity is pixel-relative (no extrinsics). Calibrated thresholds on
 *    bbox-dim/quadrant-dim ratio.
 *  - Trend = sign of bbox-area change over the last [TREND_WINDOW] updates.
 *  - Static = bbox area + position stable for [STATIC_FRAMES_NEEDED]+ updates.
 *  - All inputs are in QUADRANT pixel coordinates (the same coordinate space
 *    SurveillanceEngineGpu uses today after foveated→quadrant scaling at lines
 *    1597–1598). The caller is responsible for any coordinate normalisation.
 */
class ActorTracker {

    private var nextActorId = 1L
    private val tracks = ArrayList<Track>()

    /**
     * Process a batch of detections from one quadrant for one frame and return
     * the updated actor view (snapshot). Caller may pass an empty list to age
     * tracks without adding new observations.
     *
     * [xqTrackIdHints] is a parallel array of cross-quadrant track ID hints (one per
     * detection, or `0` for no hint); pass null for none. (The old no-hints convenience
     * overload is gone — nothing called it.)
     *
     * When a hint is present, the matching pass first tries to find an
     * existing Track with the same `xqTrackId` regardless of quadrant.
     * This fixes the "same physical person crosses front→right and gets two
     * actorIds" bug: the cross-quadrant tracker has already assigned a
     * persistent ID; we just bind the Actor to it.
     *
     * If no hinted match is found, falls back to the original per-quadrant +
     * IoU + class-group match. Detections without a hint use the legacy path.
     *
     * @param detections    YOLO detections, in QUADRANT pixel coords (top-left origin)
     * @param quadrant      Quadrant index 0..3 (front/right/rear/left)
     * @param quadrantW     Width of the coord space the bboxes live in (e.g. 320)
     * @param quadrantH     Height of the coord space the bboxes live in (e.g. 240)
     * @param recordingStartWallMs  Recording start wall-clock; pass 0 if not recording
     * @param wallNowMs     Wall-clock for this frame
     * @return Immutable list of all currently-active Actors (across all quadrants)
     */
    @Synchronized
    fun update(
        detections: List<Detection>?,
        xqTrackIdHints: IntArray?,
        quadrant: Int,
        quadrantW: Int,
        quadrantH: Int,
        recordingStartWallMs: Long,
        wallNowMs: Long
    ): List<Actor> {
        pruneStale(wallNowMs)

        if (detections != null && detections.isNotEmpty()) {
            for (i in detections.indices) {
                val d = detections[i]
                val group = Actor.groupOf(d.classId)
                if (group == ClassGroup.UNKNOWN) continue

                val hint = if (xqTrackIdHints != null && i < xqTrackIdHints.size) {
                    xqTrackIdHints[i]
                } else {
                    0
                }

                var best: Track? = null

                // Path A: cross-quadrant trackId match (any quadrant). This is
                // the primary identity signal — same xqTrackId means the
                // CrossQuadrantTracker says it's the same physical thing.
                if (hint != 0) {
                    best = tracks.firstOrNull { it.classGroup == group && it.xqTrackId == hint }
                }

                // Path B: per-quadrant IoU fallback (legacy behaviour). Only
                // runs when there's no hinted Track. We also gracefully bind
                // the cross-quadrant trackId to a same-quadrant IoU match if
                // both end up describing the same Track — keeps subsequent
                // frames stable.
                if (best == null) {
                    var bestIou = MATCH_IOU_MIN
                    for (t in tracks) {
                        if (t.quadrant != quadrant) continue
                        if (t.classGroup != group) continue
                        val iou = iou(
                            t.lastX, t.lastY, t.lastW, t.lastH,
                            d.x, d.y, d.w, d.h
                        )
                        if (iou > bestIou) {
                            bestIou = iou
                            best = t
                        }
                    }
                }

                if (best == null) {
                    if (tracks.size >= MAX_TRACKS) {
                        evictOldest()
                    }
                    best = Track(nextActorId++, group, quadrant)
                    tracks.add(best)
                }
                if (hint != 0 && best.xqTrackId == 0) {
                    best.xqTrackId = hint
                }
                best.observe(d, quadrant, quadrantW, quadrantH, recordingStartWallMs, wallNowMs)
            }
        }

        // Build snapshot for callers
        return tracks.map { it.toActor() }
    }

    /**
     * Reset tracker state (e.g. when a recording finishes or the user toggles
     * surveillance off).
     */
    @Synchronized
    fun reset() {
        tracks.clear()
        nextActorId = 1
    }

    /** Read-only count of currently-active tracks. */
    @Synchronized
    fun activeTrackCount(): Int = tracks.size

    // ---------- internal -----------------------------------------------------

    private fun pruneStale(now: Long) {
        tracks.removeAll { now - it.lastSeenWallMs > TRACK_TTL_MS }
    }

    private fun evictOldest() {
        tracks.minByOrNull { it.lastSeenWallMs }?.let { tracks.remove(it) }
    }

    /** Per-Actor mutable state. */
    private class Track(
        val actorId: Long,
        val classGroup: ClassGroup,
        var quadrant: Int
    ) {
        // Cross-quadrant track ID (from CrossQuadrantTracker). When non-zero,
        // this Actor is bound to a cross-camera identity that survives quadrant
        // boundaries. The merge hint in update() lets us look up an existing
        // Actor by xqTrackId regardless of which quadrant it currently lives
        // in — fixes the "person walks front→right gets two actorIds" bug.
        var xqTrackId = 0

        var firstSeenWallMs = 0L
        var lastSeenWallMs = 0L
        var firstSeenRelMs = -1L
        var lastSeenRelMs = -1L

        var lastX = 0
        var lastY = 0
        var lastW = 0
        var lastH = 0
        var lastQuadW = 0
        var lastQuadH = 0
        var cameraMask = 0

        // History for trend / static
        val areaHistory = FloatArray(TREND_WINDOW)
        val cxHistory = IntArray(TREND_WINDOW)
        val cyHistory = IntArray(TREND_WINDOW)
        var historyCount = 0
        var stableFrames = 0

        // Peak severity bookkeeping
        var peakSeverity = Severity.NOTICE
        var peakSeverityWallMs = 0L
        var peakSeverityRelMs = -1L
        var peakProximity = Proximity.UNKNOWN
        var peakConfidence = 0f
        var peakBboxX = 0
        var peakBboxY = 0
        var peakBboxW = 0
        var peakBboxH = 0

        // Crop dimensions peakBbox was measured against — see Actor.peakBboxQuadW/H.
        var peakBboxQuadW = 0
        var peakBboxQuadH = 0
        var peakCamera = quadrant

        // Dwell at current peak proximity
        var peakProxStartWallMs = 0L

        fun observe(
            d: Detection,
            newQuadrant: Int,
            quadW: Int,
            quadH: Int,
            recordingStartWallMs: Long,
            wallNowMs: Long
        ) {
            if (firstSeenWallMs == 0L) {
                firstSeenWallMs = wallNowMs
                if (recordingStartWallMs > 0) {
                    firstSeenRelMs = wallNowMs - recordingStartWallMs
                }
            }
            lastSeenWallMs = wallNowMs
            lastSeenRelMs =
                if (recordingStartWallMs > 0) wallNowMs - recordingStartWallMs else -1

            quadrant = newQuadrant
            cameraMask = cameraMask or (1 shl (newQuadrant and 0x03))
            lastQuadW = quadW
            lastQuadH = quadH

            val x = d.x
            val y = d.y
            val w = d.w
            val h = d.h

            val prevArea = if (lastW > 0) (lastW * lastH).toFloat() else 0f
            val curArea = (w * h).toFloat()

            val cx = x + w / 2
            val cy = y + h / 2

            // Stability check (against previous observation, not full history)
            if (lastW > 0) {
                val drift = if (prevArea > 0) abs(curArea - prevArea) / prevArea else 1f
                val dCx = abs(cx - (lastX + lastW / 2))
                val dCy = abs(cy - (lastY + lastH / 2))
                if (drift < STATIC_AREA_DRIFT_FRAC &&
                    dCx < STATIC_CENTROID_DRIFT_PX &&
                    dCy < STATIC_CENTROID_DRIFT_PX
                ) {
                    if (stableFrames < Int.MAX_VALUE - 1) stableFrames++
                } else {
                    stableFrames = 0
                }
            }

            lastX = x
            lastY = y
            lastW = w
            lastH = h

            // Roll history
            val slot = historyCount % TREND_WINDOW
            areaHistory[slot] = curArea
            cxHistory[slot] = cx
            cyHistory[slot] = cy
            historyCount++

            // Compute proximity from bbox dimension relative to quadrant dim.
            // For people use height (taller-than-wide); for vehicles use width.
            val ratio = if (classGroup == ClassGroup.VEHICLE) {
                if (quadW > 0) w.toFloat() / quadW else 0f
            } else {
                if (quadH > 0) h.toFloat() / quadH else 0f
            }
            val prox = ratioToProximity(ratio)

            // Update peak proximity (smaller ordinal = closer)
            if (peakProximity == Proximity.UNKNOWN || prox.ordinal < peakProximity.ordinal) {
                peakProximity = prox
                peakProxStartWallMs = wallNowMs
                // Refresh peakBbox + its crop space whenever proximity
                // upgrades (got closer). The thumbnail capture rule is
                // "the moment threat was highest", and a closer actor
                // is more threatening even if the severity tier hasn't
                // changed. Without this, ThumbnailBuffer would see a
                // score increase (proximity bumped) but the actor's
                // peakBbox would still be in the OLD frame's crop space
                // — and the bbox-vs-rgb alignment guard would refuse
                // to update the slot, leaving a stale crop on disk.
                //
                // peakCamera moves with it: without that, a person crossing
                // front → right quadrant whose proximity bumped but severity
                // stayed at ALERT would have peakBbox set to right-camera
                // coords but peakCamera stuck on front. ThumbnailBuffer.observe
                // gates on `a.peakCamera != camera` and would reject the
                // right-frame, leaving the hero stuck on the older,
                // less-close moment from the front camera.
                setPeakBbox(x, y, w, h, quadW, quadH, newQuadrant)
            } else if (prox != peakProximity) {
                // moved further; reset dwell
                peakProxStartWallMs = wallNowMs
            }
            // prox == peakProximity: continue dwell, nothing to do.

            val dwellMs = wallNowMs - peakProxStartWallMs
            val staticThreshold = staticThresholdFor(classGroup)
            val sev = SeverityClassifier.classify(
                classGroup, prox, peakProximity,
                computeTrend(), stableFrames >= staticThreshold, dwellMs
            )

            // Track peak severity moment for thumbnail capture
            val upgradeSev = sev.ordinal > peakSeverity.ordinal
            val tieBetterConf = sev == peakSeverity && d.confidence > peakConfidence
            if (upgradeSev || tieBetterConf) {
                peakSeverity = sev
                peakSeverityWallMs = wallNowMs
                peakSeverityRelMs =
                    if (recordingStartWallMs > 0) wallNowMs - recordingStartWallMs else -1
                peakConfidence = d.confidence
                // Snapshot the crop dims THIS frame's bbox is in. Without
                // these, downstream consumers (ThumbnailBuffer, baseline
                // promotion) can't tell whether to interpret the bbox in
                // 320×240 mosaic or 640×640 foveated coords.
                setPeakBbox(x, y, w, h, quadW, quadH, newQuadrant)
            }
        }

        private fun setPeakBbox(
            x: Int,
            y: Int,
            w: Int,
            h: Int,
            quadW: Int,
            quadH: Int,
            camera: Int
        ) {
            peakBboxX = x
            peakBboxY = y
            peakBboxW = w
            peakBboxH = h
            peakBboxQuadW = quadW
            peakBboxQuadH = quadH
            peakCamera = camera
        }

        private fun computeTrend(): Trend {
            if (historyCount < 2) return Trend.UNKNOWN
            // newest is at slot (historyCount-1) % TREND_WINDOW,
            // oldest at historyCount % TREND_WINDOW
            val newest = (historyCount - 1) % TREND_WINDOW
            val oldest = if (historyCount >= TREND_WINDOW) historyCount % TREND_WINDOW else 0
            val a0 = areaHistory[oldest]
            val a1 = areaHistory[newest]
            if (a0 <= 0) return Trend.UNKNOWN
            val change = (a1 - a0) / a0
            // Direction sanity check — avoids false APPROACHING when a stationary
            // object's bbox is repeatedly reshaped by an occluder (e.g. a person
            // walking past a parked car). Real approach: bbox grows AND its
            // bottom edge drifts down (or its centroid drifts down for ground
            // objects). Occlusion noise: bbox grows but centroid jitters with
            // no net direction. We require coherent vertical motion >= 5 px.
            val dCy = cyHistory[newest] - cyHistory[oldest]
            if (change > 0.10f && dCy >= 5) return Trend.APPROACHING
            if (change < -0.10f && dCy <= -5) return Trend.RECEDING
            return Trend.STABLE
        }

        fun toActor(): Actor {
            // current proximity = recompute from last frame so toActor is
            // internally consistent
            val ratio = if (classGroup == ClassGroup.VEHICLE) {
                if (lastQuadW > 0) lastW.toFloat() / lastQuadW else 0f
            } else {
                if (lastQuadH > 0) lastH.toFloat() / lastQuadH else 0f
            }
            val lastProx = ratioToProximity(ratio)
            val staticThreshold = staticThresholdFor(classGroup)
            return Actor(
                actorId, classGroup,
                firstSeenWallMs, lastSeenWallMs,
                firstSeenRelMs, lastSeenRelMs,
                cameraMask,
                peakProximity, lastProx,
                computeTrend(), stableFrames >= staticThreshold,
                peakSeverity, peakSeverityWallMs, peakSeverityRelMs,
                peakConfidence,
                peakBboxX, peakBboxY, peakBboxW, peakBboxH,
                peakBboxQuadW, peakBboxQuadH, peakCamera,
                lastX, lastY, lastW, lastH
            )
        }
    }

    companion object {
        /** Active tracks live this long without an update before being pruned. */
        private const val TRACK_TTL_MS = 5000L

        /** Hard upper bound on simultaneous tracks. */
        private const val MAX_TRACKS = 32

        /** IoU below this is not a match. */
        private const val MATCH_IOU_MIN = 0.20f

        /** History window for trend + static decision. */
        private const val TREND_WINDOW = 6

        /** How many consecutive stable observations classify "static" (persons + bikes). */
        private const val STATIC_FRAMES_NEEDED = 8

        /**
         * Vehicles get a much shorter static window. The classic failure to prevent:
         * a parked car that DetectionBaseline missed (e.g. arrived between event-end
         * baseline updates) reaches the Actor layer with a fresh track. With
         * STATIC_FRAMES_NEEDED=8 the Actor would be non-static for ~800ms and the
         * SeverityClassifier could escalate it to ALERT. 2 frames (~200ms at 10 fps)
         * means the second consecutive frame already classifies it as static and
         * caps severity at NOTICE — mirroring the intuition that a vehicle is only
         * a threat when it's *moving toward us*.
         */
        private const val STATIC_FRAMES_NEEDED_VEHICLE = 2

        /** Bbox-area drift below this counts as "stable" for static detection. */
        private const val STATIC_AREA_DRIFT_FRAC = 0.10f

        /** Bbox-centroid drift (pixels) below this counts as "stable" for static detection. */
        private const val STATIC_CENTROID_DRIFT_PX = 10

        // Proximity thresholds — pixel-relative ratios of bbox dim to quadrant dim
        // (quadrant = 320×240 in mosaic mode; foveated path is rescaled to quadrant first).
        private const val PROX_VERY_CLOSE = 0.60f
        private const val PROX_CLOSE = 0.35f
        private const val PROX_MID = 0.15f

        private fun staticThresholdFor(group: ClassGroup): Int =
            if (group == ClassGroup.VEHICLE) STATIC_FRAMES_NEEDED_VEHICLE
            else STATIC_FRAMES_NEEDED

        private fun ratioToProximity(ratio: Float): Proximity = when {
            ratio <= 0f -> Proximity.UNKNOWN
            ratio >= PROX_VERY_CLOSE -> Proximity.VERY_CLOSE
            ratio >= PROX_CLOSE -> Proximity.CLOSE
            ratio >= PROX_MID -> Proximity.MID
            else -> Proximity.FAR
        }

        private fun iou(
            ax: Int,
            ay: Int,
            aw: Int,
            ah: Int,
            bx: Int,
            by: Int,
            bw: Int,
            bh: Int
        ): Float {
            val x1 = maxOf(ax, bx)
            val y1 = maxOf(ay, by)
            val x2 = minOf(ax + aw, bx + bw)
            val y2 = minOf(ay + ah, by + bh)
            val interW = maxOf(0, x2 - x1)
            val interH = maxOf(0, y2 - y1)
            val inter = interW * interH
            val union = aw * ah + bw * bh - inter
            return if (union > 0) inter.toFloat() / union else 0f
        }
    }
}
