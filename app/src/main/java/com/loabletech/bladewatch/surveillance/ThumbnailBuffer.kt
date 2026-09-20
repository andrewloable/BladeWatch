package net.bladewatch.app.surveillance

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect

import net.bladewatch.app.logging.DaemonLogger

import java.io.File
import java.io.FileOutputStream
import java.io.IOException

import kotlin.math.roundToInt

/**
 * ThumbnailBuffer — Captures the highest-severity frame per Actor over the life
 * of a recording, then writes JPEG thumbnails next to the MP4 when the recording
 * closes.
 *
 * Score tuple per slot: (severity ordinal, confidence, proximity rank).
 * Higher tuple wins; new observations only overwrite the slot when their tuple
 * beats the existing one. This guarantees the saved JPEG is the peak-threat
 * moment, not the first or last detection.
 *
 * Memory bound: one slot per active actorId, one 640×640 RGB byte[] each
 * (~1.2 MB). Worst case at MAX_TRACKS=32 ≈ 38 MB; in practice 1–4 actors so
 * ~5 MB during a recording. All slots are dropped when the recording closes.
 */
class ThumbnailBuffer {

    private class Slot {
        var rgb: ByteArray? = null
        var srcW = 0
        var srcH = 0
        var bboxX = 0
        var bboxY = 0
        var bboxW = 0
        var bboxH = 0
        // Non-null with sane defaults: a Slot is only ever read after observe() has
        // copied a real Actor's peak values into it, and Actor declares all three
        // non-null. Defaults keep Actor.severityLabel/groupLabel/proximityLabel
        // callable without a null check.
        var severity: Actor.Severity = Actor.Severity.NOTICE
        var confidence = 0f
        var proximity: Actor.Proximity = Actor.Proximity.UNKNOWN
        var wallMs = 0L
        var classGroup: Actor.ClassGroup = Actor.ClassGroup.UNKNOWN
        var actorId = 0L
        var camera = 0
    }

    private val slots = HashMap<Long, Slot>()

    // Pooled scratch buffer for ARGB conversion in writeJpeg. Hero JPEGs are
    // written sequentially during stopRecording, all from foveated crops of
    // identical dimension. Without pooling, each writeJpeg allocates a fresh
    // int[srcW*srcH] (~1.6 MB per 640×640 thumb) and discards it, churning
    // 6-16 MB per recording-stop and triggering GC pauses on the main thread.
    // Held by class because flushToDisk is single-threaded (synchronized).
    private var argbScratch: IntArray? = null

    /**
     * Observe a frame: examine each Actor in the snapshot and update its slot
     * iff the new tuple beats the existing one.
     *
     * The [rgb] buffer is COPIED into the slot — the caller is free to
     * recycle their own buffer immediately.
     *
     * @param actors  Snapshot from [ActorTracker.update]
     * @param rgb     RGB byte[] (length = w*h*3) of the YOLO crop the actors were detected in
     * @param w       Width of the rgb buffer (e.g. 320 for mosaic, 640 for foveated)
     * @param h       Height of the rgb buffer
     * @param camera  Quadrant index
     */
    @Synchronized
    fun observe(actors: List<Actor>?, rgb: ByteArray?, w: Int, h: Int, camera: Int) {
        if (actors.isNullOrEmpty() || rgb == null || w <= 0 || h <= 0) return
        val now = System.currentTimeMillis()
        for (a in actors) {
            // Only consider actors that hit at least NOTICE in this frame's quadrant
            if (a.peakCamera != camera) continue
            // Skip background scenery: a static non-person actor that never
            // escalated past NOTICE is almost always a parked car or a tree
            // briefly uncovered by motion. Including them in the slot pool
            // means a far parked vehicle wins the hero score on otherwise-empty
            // events — the user sees a thumbnail with a green bbox over a
            // static car in the distance and assumes the system flagged it as
            // a threat. EventTimelineCollector's peakProximity aggregation
            // already excludes these (RecordingsApiHandler honours the result
            // for the distance chip filter). Mirror the same gate here so the
            // hero / per-actor JPEGs agree with the recording-level summary.
            if (a.isStatic &&
                a.classGroup != Actor.ClassGroup.PERSON &&
                a.peakSeverity == Actor.Severity.NOTICE
            ) {
                continue
            }
            val incoming = score(a.peakSeverity, a.peakConfidence, a.peakProximity, a.classGroup)
            val existing = slots[a.actorId]
            val existingScore = if (existing != null) {
                score(
                    existing.severity, existing.confidence, existing.proximity,
                    existing.classGroup
                )
            } else {
                -1L
            }
            if (incoming <= existingScore) continue

            // CRITICAL: bbox alignment guard. The actor's peakBbox lives in
            // peakBboxQuadW × peakBboxQuadH coords (the crop space at the
            // frame peak severity was hit). The rgb we'd store is in THIS
            // frame's w × h. The pipeline alternates between mosaic (320×240,
            // full quadrant downscaled) and foveated (640×640, a high-res
            // window centered on motion centroid) — these are NOT
            // proportionally related geometries. Naive rescaling would draw
            // the bbox on the wrong physical region.
            //
            // Skip the update unless this frame's crop matches the peak's
            // crop. The score gate above already returned for non-improving
            // observations, so the only path that lands here is a real
            // improvement — but if it lands during an incompatible crop
            // mode, we'd rather keep the prior matching (rgb, bbox) pair
            // than overwrite with mismatched ones. The peak frame itself
            // (when peakSeverityWallMs == this frame's wallMs) is always
            // compatible because peakBboxQuad{W,H} were just set to (w, h).
            //
            // Defensive fallback: if peakBboxQuadW/H are zero (Actor
            // produced before this field existed in storage / very early
            // frames), trust the current crop dims.
            val bboxQuadW = if (a.peakBboxQuadW > 0) a.peakBboxQuadW else w
            val bboxQuadH = if (a.peakBboxQuadH > 0) a.peakBboxQuadH else h
            if (bboxQuadW != w || bboxQuadH != h) {
                // Wait for a frame whose crop matches the peak's crop. The
                // existing slot (if any) already has a coherent (rgb, bbox)
                // pair captured when the dims did match — better than
                // overwriting with a mismatched pair.
                continue
            }

            val s = existing ?: Slot()
            // Re-allocate only if size changed (or first capture) — avoids per-frame churn
            val needBytes = w * h * 3
            var dst = s.rgb
            if (dst == null || dst.size != needBytes) {
                dst = ByteArray(needBytes)
                s.rgb = dst
            }
            System.arraycopy(rgb, 0, dst, 0, needBytes)
            s.srcW = w
            s.srcH = h
            s.bboxX = a.peakBboxX
            s.bboxY = a.peakBboxY
            s.bboxW = a.peakBboxW
            s.bboxH = a.peakBboxH
            s.severity = a.peakSeverity
            s.confidence = a.peakConfidence
            s.proximity = a.peakProximity
            s.wallMs = now
            s.classGroup = a.classGroup
            s.actorId = a.actorId
            s.camera = a.peakCamera
            slots[a.actorId] = s
        }
    }

    /**
     * Flush captured thumbnails to disk and pick the hero image (highest-score
     * across all actors). Called on recording close.
     *
     * @param mp4File         The recording file the thumbs accompany
     * @param relRecordingMsByActorId  Map of actorId → recording-relative timestamp,
     *                                 used to name the per-actor JPEG and as a hint
     *                                 for the JSON sidecar. May be null.
     * @return Hero thumbnail file (or null if no thumbnails captured).
     */
    @Synchronized
    fun flushToDisk(mp4File: File?, relRecordingMsByActorId: Map<Long, Long>?): File? {
        if (slots.isEmpty() || mp4File == null) return null
        val parent = mp4File.parentFile ?: return null

        val base = mp4File.name.removeSuffix(".mp4")

        var hero: Slot? = null
        var heroScore = -1L

        for (s in slots.values) {
            val sc = score(s.severity, s.confidence, s.proximity, s.classGroup)
            if (sc > heroScore) {
                heroScore = sc
                hero = s
            }
            try {
                val rel = relRecordingMsByActorId?.get(s.actorId) ?: -1L
                val jpegName = "thumb_" + base + "_a" + s.actorId +
                    (if (rel >= 0) "_$rel" else "") + ".jpg"
                writeJpeg(s, File(parent, jpegName))
            } catch (e: Exception) {
                logger.warn("Per-actor thumb write failed: " + e.message)
            }
        }

        var heroFile: File? = null
        if (hero != null) {
            try {
                heroFile = File(parent, "$base.jpg")
                writeJpeg(hero, heroFile)
            } catch (e: Exception) {
                logger.warn("Hero thumb write failed: " + e.message)
                heroFile = null
            }
        }

        // Free buffers; slots will be re-populated on the next recording.
        slots.clear()
        return heroFile
    }

    /**
     * @return list of actorIds for which a thumbnail has been captured during
     *         the current recording.
     */
    @Synchronized
    fun capturedActorIds(): List<Long> = ArrayList(slots.keys)

    /**
     * Returns the recording-relative time (wall-ms) the slot was last updated,
     * for slot's owning actorId, or -1 if no slot exists.
     */
    @Synchronized
    fun lastUpdateWallMs(actorId: Long): Long = slots[actorId]?.wallMs ?: -1L

    /** Drop everything (e.g. when recording aborted). */
    @Synchronized
    fun clear() {
        slots.clear()
    }

    // ---------- writer ------------------------------------------------------

    private fun writeJpeg(s: Slot, outFile: File) {
        val srcRgb = s.rgb ?: return
        var bmp: Bitmap? = null
        var out: Bitmap? = null
        try {
            bmp = Bitmap.createBitmap(s.srcW, s.srcH, Bitmap.Config.ARGB_8888)
            // Convert RGB byte[] → ARGB pixel array, reusing a pooled scratch
            // buffer when possible. Realloc only when the size grows.
            val needPixels = s.srcW * s.srcH
            var pixels = argbScratch
            if (pixels == null || pixels.size < needPixels) {
                pixels = IntArray(needPixels)
                argbScratch = pixels
            }
            var i = 0
            var p = 0
            while (i < srcRgb.size) {
                val r = srcRgb[i].toInt() and 0xFF
                val g = srcRgb[i + 1].toInt() and 0xFF
                val b = srcRgb[i + 2].toInt() and 0xFF
                pixels[p] = (0xFF000000.toInt()) or (r shl 16) or (g shl 8) or b
                i += 3
                p++
            }
            bmp.setPixels(pixels, 0, s.srcW, 0, 0, s.srcW, s.srcH)

            // Resize to OUT_SIDE if needed
            if (s.srcW != OUT_SIDE || s.srcH != OUT_SIDE) {
                out = Bitmap.createScaledBitmap(bmp, OUT_SIDE, OUT_SIDE, true)
                // bmp is now redundant — recycle eagerly (and null it so the
                // finally block doesn't double-recycle). createScaledBitmap
                // can also return the same bitmap if dims happened to match;
                // guard by identity.
                if (out !== bmp) {
                    bmp.recycle()
                    bmp = null
                }
            } else {
                out = bmp
                bmp = null // ownership transferred to `out`
            }

            // Draw bbox + label
            val canvas = Canvas(out!!)
            val stroke = Paint(Paint.ANTI_ALIAS_FLAG)
            stroke.style = Paint.Style.STROKE
            stroke.strokeWidth = 4f
            stroke.color = severityColor(s.severity)

            val scaleX = OUT_SIDE.toFloat() / s.srcW
            val scaleY = OUT_SIDE.toFloat() / s.srcH
            val r = Rect(
                (s.bboxX * scaleX).roundToInt(),
                (s.bboxY * scaleY).roundToInt(),
                ((s.bboxX + s.bboxW) * scaleX).roundToInt(),
                ((s.bboxY + s.bboxH) * scaleY).roundToInt()
            )
            canvas.drawRect(r, stroke)

            val label = Paint(Paint.ANTI_ALIAS_FLAG)
            label.color = Color.WHITE
            label.textSize = 28f
            label.setShadowLayer(3f, 0f, 0f, Color.BLACK)
            val text = Actor.severityLabel(s.severity) + " · " +
                Actor.groupLabel(s.classGroup) + " · " +
                Actor.proximityLabel(s.proximity)
            canvas.drawText(
                text, maxOf(8, r.left).toFloat(), maxOf(32, r.top - 8).toFloat(), label
            )

            // Atomic write: compress to <name>.tmp, fsync, rename to <name>.
            // A process kill mid-compress would otherwise leave a truncated
            // .jpg at the final filename — and the hero JPEG is now
            // load-bearing for PWA push, with no regeneration path once
            // the sidecar names it as heroThumbnail.
            // Same discipline EventTimelineCollector uses for the JSON sidecar.
            val tmpFile = File(outFile.absolutePath + ".tmp")
            FileOutputStream(tmpFile).use { fos ->
                out.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, fos)
                try {
                    fos.fd.sync()
                } catch (ignored: Throwable) {
                    logger.warn(
                        "JPEG fsync failed for " + outFile.name + ": " + ignored.message
                    )
                }
            }
            // World-readable so the PWA push sender (separate process, shell UID)
            // can read the JPEG. Set on tmp BEFORE rename so the readable bit
            // lands atomically with the file move.
            try {
                tmpFile.setReadable(true, /* ownerOnly = */ false)
            } catch (ignored: Throwable) {
                logger.warn(
                    "setReadable failed for thumbnail " + outFile.name + ": " + ignored.message
                )
            }
            if (!tmpFile.renameTo(outFile)) {
                // Rename failed (e.g. cross-volume on weird mounts). Best-effort
                // direct copy as a fallback so we don't lose the hero entirely.
                outFile.delete()
                if (!tmpFile.renameTo(outFile)) {
                    tmpFile.delete()
                    throw IOException("Failed to atomically rename $tmpFile → $outFile")
                }
            }
        } finally {
            // Recycle whichever Bitmaps are still live. setPixels / createScaledBitmap /
            // FileOutputStream can all throw, and previously these paths leaked
            // 1.6 MB of native pixels per failure. Identity-guard against
            // double-recycle when out==bmp.
            out?.recycle()
            if (bmp != null && bmp !== out) bmp.recycle()
        }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("ThumbBuf")

        /**
         * Output JPEG side-length. The crop is resized to this from whatever the
         * source dimensions were (typically 640×640 foveated or 320×240 mosaic).
         */
        private const val OUT_SIDE = 640
        private const val JPEG_QUALITY = 85

        /**
         * Score tuple for ranking observations. Higher wins.
         *
         * Order of importance:
         *  1. Severity ordinal (NOTICE < ALERT < CRITICAL).
         *  2. Class group rank — person > bike > vehicle > animal > unknown.
         *     Reason: when two actors hit the same severity tier (e.g. an approaching
         *     car and a walking person both reach ALERT), the *person* is what the
         *     user actually wants the thumbnail to depict. Without this, a high-
         *     confidence vehicle bbox can mask the lower-confidence but more
         *     relevant person.
         *  3. Proximity (closer wins).
         *  4. Confidence — high-resolution tie-breaker only.
         */
        private fun score(
            sev: Actor.Severity,
            conf: Float,
            p: Actor.Proximity,
            g: Actor.ClassGroup
        ): Long {
            val sevOrd = sev.ordinal
            val classRank = classRank(g) // 0..4
            val proxRank = Actor.Proximity.values().size - 1 - p.ordinal
            val confMilli = Math.round(conf * 1000f).coerceIn(0, 1000)
            // Pack: [sev:4][class:4][prox:4][confMilli:14]
            return (sevOrd.toLong() shl 32) or
                (classRank.toLong() shl 28) or
                (proxRank.toLong() shl 24) or
                confMilli.toLong()
        }

        private fun classRank(g: Actor.ClassGroup): Int = when (g) {
            Actor.ClassGroup.PERSON -> 4
            Actor.ClassGroup.BIKE -> 3
            Actor.ClassGroup.VEHICLE -> 2
            Actor.ClassGroup.ANIMAL -> 1
            else -> 0
        }

        private fun severityColor(sev: Actor.Severity): Int = when (sev) {
            Actor.Severity.CRITICAL -> Color.RED
            Actor.Severity.ALERT -> 0xFFFF8800.toInt() // orange
            else -> 0xFFAAAAAA.toInt() // grey for NOTICE
        }
    }
}
