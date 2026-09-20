package net.bladewatch.app.surveillance

import net.bladewatch.app.ai.Detection
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONArray
import org.json.JSONObject

import java.io.File
import java.util.Locale
import java.util.concurrent.Executors

import kotlin.math.roundToLong

/**
 * SOTA Event Timeline Collector — With Semantic Pre-Record Ring Buffer
 *
 * Architecture: Dual-buffer inline coalescing.
 *
 * The collector maintains TWO buffers:
 *
 * 1. PRE-TRIGGER RING BUFFER (always active):
 *    A small circular buffer that continuously ingests motion and AI events,
 *    keeping the last ~15 seconds of semantic data. This mirrors the H.264
 *    circular buffer that keeps the last 15 seconds of video.
 *
 * 2. ACTIVE SPAN BUFFER (only during recording):
 *    The main span array that stores committed spans for the current event.
 *    When startCollecting(preRecordMs) is called, the pre-trigger ring buffer
 *    is flushed into this array with timestamps shifted to align with the
 *    video's pre-record window.
 *
 * This ensures the JSON sidecar captures YOLO detections and tracking data
 * that occurred during the approach phase BEFORE the recording trigger.
 *
 * Thread safety:
 * - All mutable state access is synchronized
 * - File I/O runs async on a dedicated MIN_PRIORITY thread
 *
 * Memory: ~360 KB (active) + ~22 KB (pre-trigger ring) = ~382 KB total
 */
class EventTimelineCollector {

    // ========================================================================
    // PRE-TRIGGER SEMANTIC RING BUFFER (always active)
    // ========================================================================
    // Keeps the last ~15 seconds of semantic events in a circular buffer.
    // At ~0.5 spans/sec coalescing rate, 64 slots = ~128 seconds capacity.
    // We only need ~15 seconds, so 64 is generous.

    private val preRingStarts = LongArray(PRE_RING_CAPACITY)
    private val preRingEnds = LongArray(PRE_RING_CAPACITY)
    private val preRingTypes = ByteArray(PRE_RING_CAPACITY)
    private val preRingConfs = FloatArray(PRE_RING_CAPACITY)
    private val preRingCounts = ByteArray(PRE_RING_CAPACITY)
    private val preRingCams = ByteArray(PRE_RING_CAPACITY)

    /** Next write position */
    private var preRingHead = 0

    /** Number of valid entries (max PRE_RING_CAPACITY) */
    private var preRingCount = 0

    // In-flight span for the pre-trigger path (separate from the active path).
    // Pre-trigger events use absolute wall-clock timestamps; they get shifted when flushed.
    private var preInflightStart = -1L
    private var preInflightEnd = 0L
    private var preInflightType = TYPE_MOTION
    private var preInflightConf = 0f
    private var preInflightCount: Byte = 0
    private var preInflightCams: Byte = 0

    // ========================================================================
    // ACTIVE SPAN BUFFER (only during recording)
    // ========================================================================

    private val spanStarts = LongArray(SPAN_CAPACITY)
    private val spanEnds = LongArray(SPAN_CAPACITY)
    private val spanTypes = ByteArray(SPAN_CAPACITY)
    private val spanConfidences = FloatArray(SPAN_CAPACITY)
    private val spanCounts = ByteArray(SPAN_CAPACITY)
    private val spanCameras = ByteArray(SPAN_CAPACITY)
    private var spanCount = 0

    // In-flight span for the active path
    private var inflightStart = -1L
    private var inflightEnd = 0L
    private var inflightType = TYPE_MOTION
    private var inflightConf = 0f
    private var inflightCount: Byte = 0
    private var inflightCameras: Byte = 0

    /**
     * Wall-clock timestamp (ms) of the start of the current recording (with
     * pre-record offset already applied). Returns 0 when not collecting.
     * Used by ActorTracker to compute Actor-relative timestamps.
     */
    var recordingStartTimeMs = 0L
        private set

    @Volatile
    var isCollecting = false
        private set

    /** Async writer */
    private val writeExecutor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "TimelineWriter").apply {
            isDaemon = true
            priority = Thread.MIN_PRIORITY
        }
    }

    // ========================================================================
    // LIFECYCLE
    // ========================================================================

    /**
     * Start collecting, optionally with a pre-record offset.
     * Flushes the pre-trigger ring buffer into the active span array,
     * shifting timestamps to align with the video's pre-record window.
     */
    @JvmOverloads
    @Synchronized
    fun startCollecting(preRecordMs: Long = 0) {
        startCollecting(preRecordMs, flushPreRing = true)
    }

    /**
     * Segment-rotation entry point: start collecting WITHOUT replaying the
     * pre-trigger ring buffer. The pre-ring captured spans from before the
     * original event began; replaying them at every rotation would seed
     * each subsequent segment with stale "marker at relMs=0" entries that
     * already appeared in segment 1's sidecar. Used by SurveillanceEngineGpu
     * when rotateSegment fires.
     */
    @Synchronized
    fun startCollectingNoPreRing() {
        startCollecting(0L, flushPreRing = false)
    }

    @Synchronized
    private fun startCollecting(preRecordMs: Long, flushPreRing: Boolean) {
        spanCount = 0
        inflightStart = -1

        // Timeline origin: the start of the video (preRecordMs before now)
        recordingStartTimeMs = System.currentTimeMillis() - preRecordMs

        var flushed = 0
        if (flushPreRing) {
            // Flush pre-trigger ring buffer: copy spans that fall within the
            // pre-record window into the active span array.
            // Pre-trigger spans use absolute wall-clock timestamps.
            // We need to convert them to relative timestamps (ms since recordingStartTimeMs).
            commitPreInflight() // Commit any in-flight pre-trigger span first

            val windowStart = recordingStartTimeMs // Earliest timestamp to include

            // Read ring buffer in chronological order
            val readStart = if (preRingCount < PRE_RING_CAPACITY) 0 else preRingHead
            for (i in 0 until preRingCount) {
                val idx = (readStart + i) % PRE_RING_CAPACITY

                // Only include spans that overlap with the pre-record window
                if (preRingEnds[idx] < windowStart) continue

                if (spanCount < SPAN_CAPACITY) {
                    spanStarts[spanCount] = maxOf(0, preRingStarts[idx] - recordingStartTimeMs)
                    spanEnds[spanCount] = preRingEnds[idx] - recordingStartTimeMs
                    spanTypes[spanCount] = preRingTypes[idx]
                    spanConfidences[spanCount] = preRingConfs[idx]
                    spanCounts[spanCount] = preRingCounts[idx]
                    spanCameras[spanCount] = preRingCams[idx]
                    spanCount++
                    flushed++
                }
            }
        } else {
            // Rotation path: drop any in-flight pre-ring span so it won't
            // spuriously appear in a future event's pre-roll.
            preInflightStart = -1
        }

        isCollecting = true
        logger.info(
            "Timeline collection started (preRecord=" + preRecordMs +
                "ms, origin shifted, flushed " + flushed + " pre-trigger spans" +
                (if (flushPreRing) "" else ", preRing skipped") + ")"
        )
    }

    /**
     * Stop collecting and write a v3 JSON sidecar with Actor records + hero
     * thumbnail reference. Backwards-compat: the v3 sidecar is a strict superset
     * of v2 (all v2 fields preserved), so old readers continue to work.
     *
     * @param mp4File          The recording file
     * @param actors           Final actor snapshot from ActorTracker (may be null/empty)
     * @param heroThumbnail    Filename of the hero JPEG, written by ThumbnailBuffer.
     *                         Just the basename (e.g. "event_xxx.jpg"), or null.
     */
    @JvmOverloads
    @Synchronized
    fun stopAndWrite(
        mp4File: File,
        actors: List<Actor>? = null,
        heroThumbnail: String? = null
    ) {
        if (!isCollecting) return
        isCollecting = false

        commitInflight()

        val count = spanCount
        if (count == 0 && actors.isNullOrEmpty()) {
            logger.info("No events collected, skipping sidecar write")
            return
        }

        val starts = spanStarts.copyOf(count)
        val ends = spanEnds.copyOf(count)
        val types = spanTypes.copyOf(count)
        val confs = spanConfidences.copyOf(count)
        val counts = spanCounts.copyOf(count)
        val cams = spanCameras.copyOf(count)

        val durationMs = System.currentTimeMillis() - recordingStartTimeMs
        // Snapshot actors so the writer thread sees an immutable copy
        val actorsCopy: List<Actor> = if (actors.isNullOrEmpty()) emptyList() else ArrayList(actors)

        writeExecutor.execute {
            writeJsonSidecar(
                mp4File, starts, ends, types, confs, counts, cams, count,
                durationMs, actorsCopy, heroThumbnail
            )
            // SRT subtitle sidecar — localized prose so VLC / video.js / ExoPlayer
            // can show "Person detected close range" / "Charging started · 4.3 kW"
            // without re-encoding the burned-in English overlay. Wrapped so an
            // SRT failure can never poison the JSON write above (which the
            // recordings UI depends on).
            try {
                writeSrtSidecar(mp4File, starts, ends, types, count, actorsCopy)
            } catch (t: Throwable) {
                logger.warn(
                    "SRT sidecar write failed for " + mp4File.name + ": " + t.message
                )
            }
        }
    }

    /**
     * Convert the snapshotted spans + actor list into a localized SRT
     * sidecar next to [mp4File]. Runs on the same low-priority
     * writer thread that emits the JSON sidecar, so it never blocks the
     * encoder drainer.
     *
     * Mapping rules (kept conservative — better to under-emit than to
     * spam every motion blip into a subtitle line):
     * - Each non-static actor produces ONE entry at its first-seen offset, keyed by
     *   class group (PERSON / VEHICLE) and tightened to `srt.person_close` when
     *   peakProximity is VERY_CLOSE or CLOSE.
     * - Spans of type `motion` that don't overlap any actor produce a single
     *   `srt.motion_started` entry at the span's start. Avoids duplicating
     *   actor-driven entries.
     * - Proximity-tier alerts are emitted from the actor's peakSeverityRelMs when
     *   severity is CRITICAL/ALERT.
     * - "Recording started" is always emitted at offset 0.
     */
    private fun writeSrtSidecar(
        mp4File: File,
        starts: LongArray,
        ends: LongArray,
        types: ByteArray,
        spanCount: Int,
        actors: List<Actor>?
    ) {
        val srt = SrtWriter()
        srt.addEvent(0L, SrtWriter.K_RECORDING_STARTED)

        // Actor-driven entries (preferred — they carry class + proximity)
        if (actors != null) {
            for (a in actors) {
                if (a.isStatic) continue
                val offset = if (a.firstSeenRelMs >= 0) a.firstSeenRelMs else 0L
                val key = when (a.classGroup) {
                    Actor.ClassGroup.PERSON ->
                        if (a.peakProximity == Actor.Proximity.VERY_CLOSE ||
                            a.peakProximity == Actor.Proximity.CLOSE
                        ) {
                            SrtWriter.K_PERSON_CLOSE
                        } else {
                            SrtWriter.K_PERSON_DETECTED
                        }

                    Actor.ClassGroup.VEHICLE -> SrtWriter.K_VEHICLE_DETECTED

                    // BIKE / ANIMAL / UNKNOWN: no key in the catalog yet;
                    // fall through to motion if applicable.
                    else -> null
                }
                if (key != null) {
                    srt.addEvent(offset, key)
                }

                // Severity → proximity-band alert. peakSeverityRelMs may be -1
                // when the peak fell outside this segment's window (renormalized
                // upstream by SurveillanceEngineGpu#flushSegmentMetadata).
                if (a.peakSeverityRelMs >= 0) {
                    if (a.peakSeverity == Actor.Severity.CRITICAL) {
                        srt.addEvent(a.peakSeverityRelMs, SrtWriter.K_PROXIMITY_RED)
                    } else if (a.peakSeverity == Actor.Severity.ALERT) {
                        srt.addEvent(a.peakSeverityRelMs, SrtWriter.K_PROXIMITY_YELLOW)
                    }
                }
            }
        }

        // Plain-motion spans (TYPE_MOTION) that have no actor to anchor on.
        // Without a class signal we fall back to the generic motion key.
        for (i in 0 until spanCount) {
            if (types[i] != TYPE_MOTION) continue
            // Skip motion spans that overlap a known actor — the actor entry
            // already covers them and we don't want double-up subtitles.
            if (overlapsAnyActor(starts[i], ends[i], actors)) continue
            srt.addEvent(starts[i], SrtWriter.K_MOTION_STARTED)
        }

        srt.write(mp4File)
    }

    // ========================================================================
    // HOT PATH — Motion events
    // ========================================================================

    @JvmOverloads
    fun onMotionDetected(activeBlocks: Int, cameraMask: Int = 0) {
        val now = System.currentTimeMillis()
        val cam = (cameraMask and 0x0F).toByte()
        if (isCollecting) {
            ingestEvent(now - recordingStartTimeMs, TYPE_MOTION, 0f, 0, cam)
        } else {
            // Pre-trigger: always ingest into the ring buffer
            ingestPreTrigger(now, TYPE_MOTION, 0f, 0, cam)
        }
    }

    // ========================================================================
    // HOT PATH — AI detection events
    // ========================================================================

    @JvmOverloads
    fun onAiDetection(
        detections: List<Detection>?,
        hasActiveMotion: Boolean,
        cameraMask: Int = 0
    ) {
        if (!hasActiveMotion || detections.isNullOrEmpty()) return

        var bestType = TYPE_MOTION
        var bestConf = 0f
        var totalCount = 0

        for (det in detections) {
            val type = when (det.classId) {
                0 -> TYPE_PERSON
                2, 5, 7 -> TYPE_CAR
                1, 3 -> TYPE_BIKE
                else -> continue
            }

            totalCount++
            if (type > bestType || (type == bestType && det.confidence > bestConf)) {
                bestType = type
                bestConf = det.confidence
            }
        }

        if (totalCount > 0) {
            val now = System.currentTimeMillis()
            val countByte = minOf(totalCount, 127).toByte()
            val camByte = (cameraMask and 0x0F).toByte()

            if (isCollecting) {
                ingestEvent(now - recordingStartTimeMs, bestType, bestConf, countByte, camByte)
            } else {
                // Pre-trigger: always ingest into the ring buffer
                ingestPreTrigger(now, bestType, bestConf, countByte, camByte)
            }
        }
    }

    // ========================================================================
    // PRE-TRIGGER RING BUFFER INGESTION (uses absolute wall-clock timestamps)
    // ========================================================================

    @Synchronized
    private fun ingestPreTrigger(
        absoluteMs: Long,
        type: Byte,
        conf: Float,
        count: Byte,
        cameras: Byte
    ) {
        if (preInflightStart < 0) {
            preInflightStart = absoluteMs
            preInflightEnd = absoluteMs
            preInflightType = type
            preInflightConf = conf
            preInflightCount = count
            preInflightCams = cameras
            return
        }

        if (absoluteMs - preInflightEnd <= COALESCE_MS) {
            preInflightEnd = absoluteMs
            preInflightCams = (preInflightCams.toInt() or cameras.toInt()).toByte()
            if (type > preInflightType) {
                preInflightType = type
                preInflightConf = conf
            } else if (type == preInflightType && conf > preInflightConf) {
                preInflightConf = conf
            }
            if (count > preInflightCount) {
                preInflightCount = count
            }
        } else {
            commitPreInflight()
            preInflightStart = absoluteMs
            preInflightEnd = absoluteMs
            preInflightType = type
            preInflightConf = conf
            preInflightCount = count
            preInflightCams = cameras
        }
    }

    private fun commitPreInflight() {
        if (preInflightStart < 0) return

        val idx = preRingHead
        preRingStarts[idx] = preInflightStart
        preRingEnds[idx] = preInflightEnd
        preRingTypes[idx] = preInflightType
        preRingConfs[idx] = preInflightConf
        preRingCounts[idx] = preInflightCount
        preRingCams[idx] = preInflightCams

        preRingHead = (preRingHead + 1) % PRE_RING_CAPACITY
        if (preRingCount < PRE_RING_CAPACITY) preRingCount++

        preInflightStart = -1
    }

    // ========================================================================
    // ACTIVE SPAN INGESTION (uses relative timestamps from recordingStartTimeMs)
    // ========================================================================

    @Synchronized
    private fun ingestEvent(
        relativeMs: Long,
        type: Byte,
        conf: Float,
        count: Byte,
        cameras: Byte
    ) {
        if (inflightStart < 0) {
            inflightStart = relativeMs
            inflightEnd = relativeMs
            inflightType = type
            inflightConf = conf
            inflightCount = count
            inflightCameras = cameras
            return
        }

        if (relativeMs - inflightEnd <= COALESCE_MS) {
            inflightEnd = relativeMs
            inflightCameras = (inflightCameras.toInt() or cameras.toInt()).toByte()
            if (type > inflightType) {
                inflightType = type
                inflightConf = conf
            } else if (type == inflightType && conf > inflightConf) {
                inflightConf = conf
            }
            if (count > inflightCount) {
                inflightCount = count
            }
        } else {
            commitInflight()
            inflightStart = relativeMs
            inflightEnd = relativeMs
            inflightType = type
            inflightConf = conf
            inflightCount = count
            inflightCameras = cameras
        }
    }

    private fun commitInflight() {
        if (inflightStart < 0) return
        if (spanCount >= SPAN_CAPACITY) {
            if (spanCount == SPAN_CAPACITY) {
                logger.warn("Timeline buffer full ($SPAN_CAPACITY spans). Dropping.")
            }
            inflightStart = -1
            return
        }

        val idx = spanCount
        spanStarts[idx] = inflightStart
        spanEnds[idx] = inflightEnd
        spanTypes[idx] = inflightType
        spanConfidences[idx] = inflightConf
        spanCounts[idx] = inflightCount
        spanCameras[idx] = inflightCameras
        spanCount = idx + 1
        inflightStart = -1
    }

    // ========================================================================
    // COLD PATH — Async JSON file I/O
    // ========================================================================

    /**
     * v3 sidecar writer — superset of v2. Old readers (which look for
     * `version=2`, `events[]`, `stats.{motion,person,car,bike}`)
     * keep working because every v2 field is still present. New readers may
     * additionally read:
     *   - `actors[]`        list of [Actor]-shaped records
     *   - `stats.peakSeverity` / `peakSeverityTMs`
     *   - `stats.{personCount,vehicleCount,bikeCount,animalCount}`
     *   - `stats.peakProximity`
     *   - `heroThumbnail`    basename of the JPEG sibling file
     */
    private fun writeJsonSidecar(
        mp4File: File,
        starts: LongArray,
        ends: LongArray,
        types: ByteArray,
        confs: FloatArray,
        counts: ByteArray,
        cameras: ByteArray,
        count: Int,
        durationMs: Long,
        actors: List<Actor>?,
        heroThumbnail: String?
    ) {
        try {
            // SOTA: Sort spans chronologically by start time.
            val sortIdx = (0 until count).sortedBy { starts[it] }

            val root = JSONObject()
            root.put("version", 3)
            root.put("durationMs", durationMs)

            val eventsArray = JSONArray()
            var motionN = 0
            var personN = 0
            var carN = 0
            var bikeN = 0

            for (i in sortIdx) {
                val ev = JSONObject()
                ev.put("start", starts[i])
                ev.put("end", ends[i])

                val typeName = TYPE_NAMES[types[i].toInt()]
                ev.put("type", typeName)

                if (confs[i] > 0) {
                    ev.put("maxConf", (confs[i] * 100).roundToLong() / 100.0)
                }
                val cnt = counts[i].toInt() and 0xFF
                if (cnt > 1) {
                    ev.put("maxCount", cnt)
                }

                val camMask = cameras[i].toInt() and 0x0F
                if (camMask > 0) {
                    ev.put("cameras", cameraMaskToJson(camMask))
                }

                eventsArray.put(ev)

                when (typeName) {
                    "person" -> personN++
                    "car" -> carN++
                    "bike" -> bikeN++
                    else -> motionN++
                }
            }

            root.put("events", eventsArray)

            // ---- Actors (v3) ----
            var personCount = 0
            var vehicleCount = 0
            var bikeCount = 0
            var animalCount = 0
            var peakSev: Actor.Severity? = null
            var peakProx: Actor.Proximity? = null
            var peakSevRel = -1L
            val actorsArr = JSONArray()
            if (actors != null) {
                for (a in actors) {
                    val ao = JSONObject()
                    ao.put("actorId", a.actorId)
                    ao.put("classGroup", a.classGroup.name)
                    ao.put("class", Actor.groupLabel(a.classGroup))
                    ao.put("firstSeenWallMs", a.firstSeenWallMs)
                    ao.put("lastSeenWallMs", a.lastSeenWallMs)
                    if (a.firstSeenRelMs >= 0) ao.put("firstSeenMs", a.firstSeenRelMs)
                    if (a.lastSeenRelMs >= 0) ao.put("lastSeenMs", a.lastSeenRelMs)
                    ao.put("peakProximity", a.peakProximity.name)
                    ao.put("lastProximity", a.lastProximity.name)
                    ao.put("trend", a.trend.name)
                    ao.put("isStatic", a.isStatic)
                    ao.put("peakSeverity", a.peakSeverity.name)
                    ao.put("peakSeverityWallMs", a.peakSeverityWallMs)
                    if (a.peakSeverityRelMs >= 0) ao.put("peakSeverityMs", a.peakSeverityRelMs)
                    ao.put("peakConfidence", (a.peakConfidence * 100).roundToLong() / 100.0)
                    ao.put(
                        "peakCamera",
                        if (a.peakCamera in 0..3) CAMERA_NAMES[a.peakCamera] else ""
                    )
                    ao.put("cameras", cameraMaskToJson(a.cameraMask))

                    actorsArr.put(ao)

                    // Counts + peak fields exclude static actors. The classic
                    // failure to prevent: a parked car next to ours dominates
                    // the stats and notification because YOLO sees it at high
                    // confidence. Static = not a threat = not a count.
                    if (!a.isStatic) {
                        when (a.classGroup) {
                            Actor.ClassGroup.PERSON -> personCount++
                            Actor.ClassGroup.VEHICLE -> vehicleCount++
                            Actor.ClassGroup.BIKE -> bikeCount++
                            Actor.ClassGroup.ANIMAL -> animalCount++
                            else -> {}
                        }
                        if (peakSev == null || a.peakSeverity.ordinal > peakSev.ordinal) {
                            peakSev = a.peakSeverity
                            peakSevRel = a.peakSeverityRelMs
                        }
                        if (peakProx == null || a.peakProximity.ordinal < peakProx.ordinal) {
                            peakProx = a.peakProximity
                        }
                    }
                }
            }
            root.put("actors", actorsArr)

            // ---- Stats (v2 fields preserved + v3 additions) ----
            val stats = JSONObject()
            // v2 fields: keep names exactly so existing readers keep working
            stats.put("motion", motionN)
            stats.put("person", personN)
            stats.put("car", carN)
            stats.put("bike", bikeN)
            // v3 additions
            stats.put("personCount", personCount)
            stats.put("vehicleCount", vehicleCount)
            stats.put("bikeCount", bikeCount)
            stats.put("animalCount", animalCount)
            peakSev?.let {
                stats.put("peakSeverity", it.name)
                if (peakSevRel >= 0) stats.put("peakSeverityMs", peakSevRel)
            }
            peakProx?.let { stats.put("peakProximity", it.name) }
            root.put("stats", stats)

            if (!heroThumbnail.isNullOrEmpty()) {
                root.put("heroThumbnail", heroThumbnail)
            }

            val jsonFile = File(mp4File.parentFile, mp4File.name.replace(".mp4", ".json"))
            val tmpFile = File(jsonFile.absolutePath + ".tmp")
            val content = root.toString()

            tmpFile.writeText(content)

            if (!tmpFile.renameTo(jsonFile)) {
                jsonFile.writeText(content)
                tmpFile.delete()
            }

            jsonFile.setReadable(true, false)

            logger.info(
                String.format(
                    Locale.US,
                    "Timeline saved (v3): %s (%d spans, %d actors, dur=%ds)",
                    jsonFile.name, count, actorsArr.length(), durationMs / 1000
                )
            )

            // Re-index the recording now that the enriched sidecar exists, so
            // the catalog row carries severity/actors. Idempotent (MERGE by
            // path) and runs on the writer executor, off the encoder thread.
            try {
                CameraDaemon.getMediaCatalogManager()?.indexRecording(mp4File)
            } catch (t: Throwable) {
                logger.warn("media index (sidecar) failed: " + t.message)
            }
        } catch (e: Exception) {
            logger.error("Failed to write timeline JSON: " + e.message, e)
        }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("EventTimeline")

        private const val COALESCE_MS = 2000

        // Type constants (byte values for compact storage)
        private const val TYPE_MOTION: Byte = 0
        private const val TYPE_BIKE: Byte = 1
        private const val TYPE_CAR: Byte = 2
        private const val TYPE_PERSON: Byte = 3
        private val TYPE_NAMES = arrayOf("motion", "bike", "car", "person")

        private val CAMERA_NAMES = arrayOf("front", "right", "rear", "left")

        private const val PRE_RING_CAPACITY = 64
        private const val SPAN_CAPACITY = 16384

        /** The 4-bit camera bitmask as a JSON array of names. */
        private fun cameraMaskToJson(mask: Int): JSONArray {
            val arr = JSONArray()
            for (bit in 0 until 4) {
                if ((mask and (1 shl bit)) != 0) arr.put(CAMERA_NAMES[bit])
            }
            return arr
        }

        private fun overlapsAnyActor(
            spanStart: Long,
            spanEnd: Long,
            actors: List<Actor>?
        ): Boolean {
            if (actors.isNullOrEmpty()) return false
            for (a in actors) {
                if (a.firstSeenRelMs < 0 || a.lastSeenRelMs < 0) continue
                if (spanStart <= a.lastSeenRelMs && spanEnd >= a.firstSeenRelMs) {
                    return true
                }
            }
            return false
        }
    }
}
