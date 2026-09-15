/*
 * Ported from Overdrive (https://github.com/yash-srivastava/Overdrive-release),
 * surveillance/FisheyeDewarp.java.
 *
 * MIT License. Copyright (c) 2026 Yash Srivastava.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to
 * the above copyright notice and this permission notice being included in all copies or
 * substantial portions of the Software.
 */
package net.bladewatch.app.surveillance

import net.bladewatch.app.ai.Detection
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Fixed-constant fisheye dewarp for the YOLO inference crop (side mirror cameras).
 *
 * **Why.** The BYD side mirror cameras are ultra-wide fisheye. Barrel curvature warps a
 * close subject's geometry away from anything a COCO-trained detector has seen, so YOLO
 * misses real people standing beside the car — the exact case sentry mode exists for.
 * Straightening only the bytes handed to the detector recovers those detections with no
 * effect on any other pipeline stage.
 *
 * **What it does NOT touch.** Not the recording, not the stream, not the thumbnail, not the
 * crop the tracker consumes. Only the detector's input buffer. Boxes come back in dewarped
 * space and [mapDetectionsToSource] returns them to original crop space immediately after
 * inference, so every downstream consumer sees the coordinate space it always has.
 *
 * **Not user-configurable, by design.** The constants describe the LENS, not a preference.
 * Detection accuracy must not change because someone adjusted a display slider, and a
 * slider defaulting to 0 would keep the fix permanently off. See
 * `docs/evaluations/overdrive-camera-ux.md`, which distinguishes this from the separate
 * 0–100 DISPLAY dewarp implemented in the GPU shaders.
 *
 * **The maths.** Division-model dewarp. For each OUTPUT pixel at centred, aspect-corrected
 * coordinate n, sample the source at `n * zoom / (1 + k1*r^2 + k2*r^4)`, where
 * `zoom = 1 + k1*a^2 + k2*a^4` (a = tile aspect h/w, derived per call) keeps the
 * corners at the tile edge.
 * Strength 0 gives k1 = k2 = 0 and zoom = 1, i.e. exact identity.
 *
 * **Scope.** Full-tile mosaic crops only. Foveated crops are re-centred sub-windows of the
 * panorama, so their centre is not the lens axis and a tile-centred radial model would be
 * geometrically wrong there. The caller enforces this (BladeWatch-4pic).
 *
 * **Failure policy.** Any error returns null (or, for the mapping, the original list). This
 * object can only ADD detector signal, never remove it.
 *
 * **Threading.** Called on the AI executor only, matching `YoloDetector`'s single-lane
 * discipline. The LUT cache is built once under a lock and read-only afterwards; the output
 * scratch buffer is safe to share only because of that single-lane contract.
 *
 * **Java interop.** Declared as an `object` with [JvmStatic] members because the caller,
 * `SurveillanceEngineGpu`, is Java. Kotlin cannot express package-private, so unlike the
 * Java original this is public within the module — it is not API, and nothing outside the
 * surveillance package should call it.
 */
object FisheyeDewarp {

    /**
     * Per-quadrant dewarp strength, indexed Q0..Q3 by `MotionPipelineV2.QUADRANT_NAMES`,
     * which is `{"front", "right", "rear", "left"}`. So Q1 and Q3 are the two MIRROR
     * cameras and are the only ones dewarped; front and rear stay at 0, which is
     * byte-identical to no dewarp at all.
     *
     * 0.5 comes from Overdrive's offline sweep over 30 real recorded frames: on the left
     * mirror camera it gave 12 relevant detections / 3.37 summed confidence against 7 /
     * 2.19 undewarped (+71% detections, +54% confidence), while 0.75 and above collapsed to
     * 4 then 2 — the constant is a peak, not a floor. Front and rear had no subjects in
     * that footage so they were left at 0 on a fail-open basis, and the right camera
     * inherits the left's value because it is the same mirror hardware.
     *
     * **These are Overdrive's numbers, and they were never verified on this car.**
     * BladeWatch-3dg8 was closed with that measurement WAIVED, so nothing here is evidence
     * about this vehicle's lenses. What WAS established on this car (196 surveillance
     * events): a motion event seen only by a mirror camera classifies nothing 82% of the
     * time, against 0% for front and rear — so the PROBLEM is real here even though the
     * chosen strength is not yet justified here. Treat 0.5 as a reasonable inherited
     * default, not a tuned value.
     *
     * To disable entirely, set every entry to 0 — that is byte-identical to no dewarp and
     * the wiring guard still passes.
     */
    private val QUADRANT_STRENGTH = floatArrayOf(0f, 0.5f, 0f, 0.5f)

    /**
     * Tile aspect (h/w), used to make the radial metric isotropic: x spans [-1,1] and y
     * spans [-aspect, aspect], so r is a true radius rather than an ellipse.
     *
     * DERIVED from the crop, not a constant. Every path that reaches the dewarp today is
     * 4:3 (the 320x240 mosaic tile) so this evaluates to exactly 0.75f and is byte-identical
     * to the constant it replaced. It is derived anyway because the one other crop in this
     * package, FoveatedCropper.CROP_SIZE, is 640 SQUARE: a hardcoded 0.75 would stretch such
     * a crop on top of mis-centring it if the fromMosaicTile guard ever regressed. Deriving
     * it keeps that failure to the one mistake instead of two.
     */
    private fun aspectOf(w: Int, h: Int): Float = h.toFloat() / w.toFloat()

    /** Dewarp strength for a quadrant; 0 means this quadrant is never dewarped. */
    @JvmStatic
    fun strengthFor(quadrant: Int): Float =
        if (quadrant in QUADRANT_STRENGTH.indices) QUADRANT_STRENGTH[quadrant] else 0f

    // Cached LUT for the single (strength, w, h) combination in live use (0.5 @ 320x240),
    // rebuilt only if any of the three changes. lut[outIdx] = srcIdx, both in PIXEL units.
    private var cachedLut: IntArray? = null
    private var cachedStrength = -1f
    private var cachedW = -1
    private var cachedH = -1
    private val lutLock = Any()

    /**
     * Reusable output buffer. Allocating a fresh ~230 KB array per side-camera inference is
     * roughly 0.92 MB/s of large-object GC churn at the close-subject cadence — firing
     * precisely while recording, which is the pattern `YoloDetector`'s own reusable buffers
     * exist to avoid. Safe to share because of the single-lane contract in the class doc:
     * the returned buffer is consumed synchronously by `detect()` on the same thread and
     * never retained.
     */
    private var dewarpScratch: ByteArray? = null

    private fun lutFor(strength: Float, w: Int, h: Int): IntArray = synchronized(lutLock) {
        cachedLut?.let {
            if (cachedStrength == strength && cachedW == w && cachedH == h) return it
        }
        val k1 = 0.30f * strength
        val k2 = 0.10f * strength
        val aspect = aspectOf(w, h)
        val a2 = aspect * aspect
        val zoom = 1f + k1 * a2 + k2 * a2 * a2

        val lut = IntArray(w * h)
        for (y in 0 until h) {
            val ny = ((y + 0.5f) / h) * 2f - 1f
            val nya = ny * aspect
            for (x in 0 until w) {
                val nx = ((x + 0.5f) / w) * 2f - 1f
                val r2 = nx * nx + nya * nya
                val inv = 1f / (1f + k1 * r2 + k2 * r2 * r2)
                val sx = nx * inv * zoom
                val sy = (nya * inv * zoom) / aspect
                val px = ((sx * 0.5f + 0.5f) * w).toInt().coerceIn(0, w - 1)
                val py = ((sy * 0.5f + 0.5f) * h).toInt().coerceIn(0, h - 1)
                lut[y * w + x] = py * w + px
            }
        }
        cachedLut = lut
        cachedStrength = strength
        cachedW = w
        cachedH = h
        return lut
    }

    /**
     * Dewarp an RGB888 crop for detector input.
     *
     * @param rgb packed RGB888, length at least `w * h * 3`
     * @param quadrant Q0..Q3 per `MotionPipelineV2.QUADRANT_NAMES`
     * @return the dewarped buffer, or `null` when this quadrant is not dewarped or the input
     *   is unusable. Null rather than a copy is deliberate: it makes "no change" impossible
     *   to confuse with "changed", and the caller then feeds the original.
     */
    @JvmStatic
    fun dewarpForDetector(rgb: ByteArray?, w: Int, h: Int, quadrant: Int): ByteArray? {
        return try {
            val strength = strengthFor(quadrant)
            if (strength <= 0f || rgb == null || w <= 0 || h <= 0 || rgb.size < w * h * 3) {
                return null
            }
            val lut = lutFor(strength, w, h)
            var out = dewarpScratch
            if (out == null || out.size != w * h * 3) {
                out = ByteArray(w * h * 3)
                dewarpScratch = out
            }
            for (i in lut.indices) {
                val s = lut[i] * 3
                val d = i * 3
                out[d] = rgb[s]
                out[d + 1] = rgb[s + 1]
                out[d + 2] = rgb[s + 2]
            }
            out
        } catch (t: Throwable) {
            null  // fail open — the caller uses the original crop
        }
    }

    /**
     * Map detections from DEWARPED crop space back to the ORIGINAL warped crop space,
     * preserving order and every non-geometric field.
     *
     * Uses the same forward sampling transform the pixels used, evaluated at the box's four
     * corners PLUS its four edge midpoints, then takes the bounding box of the mapped
     * points. Eight points rather than four because the transform is radial: a straight edge
     * bows, so a box's extreme can sit at an edge midpoint and a corners-only mapping would
     * clip the subject out of its own box.
     *
     * @return the mapped list, or the original list unchanged when this quadrant is not
     *   dewarped or anything goes wrong — better an unmapped box than a dropped one.
     */
    @JvmStatic
    fun mapDetectionsToSource(
        dets: List<Detection>?,
        w: Int,
        h: Int,
        quadrant: Int
    ): List<Detection>? {
        return try {
            val strength = strengthFor(quadrant)
            if (strength <= 0f || dets.isNullOrEmpty()) return dets
            // Same degenerate-size guard as dewarpForDetector. Without it a zero width
            // divides by zero and every box silently collapses to 0x0 at the origin
            // instead of being left alone -- a dropped detection, which is the one
            // outcome this object's failure policy forbids.
            if (w <= 0 || h <= 0) return dets

            val k1 = 0.30f * strength
            val k2 = 0.10f * strength
            val aspect = aspectOf(w, h)
            val a2 = aspect * aspect
            val zoom = 1f + k1 * a2 + k2 * a2 * a2

            dets.map { d ->
                val x1 = d.x.toFloat()
                val y1 = d.y.toFloat()
                val x2 = x1 + d.w
                val y2 = y1 + d.h
                val mx = (x1 + x2) * 0.5f
                val my = (y1 + y2) * 0.5f

                // corners, then edge midpoints — the radial bow lives on the edges
                val px = floatArrayOf(x1, x2, x1, x2, mx, mx, x1, x2)
                val py = floatArrayOf(y1, y1, y2, y2, y1, y2, my, my)

                var minX = Float.MAX_VALUE
                var minY = Float.MAX_VALUE
                var maxX = -Float.MAX_VALUE
                var maxY = -Float.MAX_VALUE
                for (i in 0 until 8) {
                    val nx = (px[i] / w) * 2f - 1f
                    val nya = ((py[i] / h) * 2f - 1f) * aspect
                    val r2 = nx * nx + nya * nya
                    val inv = 1f / (1f + k1 * r2 + k2 * r2 * r2)
                    val sxp = ((nx * inv * zoom) * 0.5f + 0.5f) * w
                    val syp = (((nya * inv * zoom) / aspect) * 0.5f + 0.5f) * h
                    minX = min(minX, sxp)
                    maxX = max(maxX, sxp)
                    minY = min(minY, syp)
                    maxY = max(maxY, syp)
                }

                val bx = minX.roundToInt().coerceIn(0, w - 1)
                val by = minY.roundToInt().coerceIn(0, h - 1)
                val bw = (maxX.roundToInt() - bx).coerceIn(0, w - bx)
                val bh = (maxY.roundToInt() - by).coerceIn(0, h - by)
                Detection(d.classId, d.confidence, bx, by, bw, bh)
            }
        } catch (t: Throwable) {
            dets  // fail open — better an unmapped box than a dropped one
        }
    }
}
