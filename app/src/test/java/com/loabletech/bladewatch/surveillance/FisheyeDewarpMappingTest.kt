package net.bladewatch.app.surveillance

import net.bladewatch.app.ai.Detection
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-3mzl: mapping detections from dewarped space back to source space.
 *
 * YOLO runs on a dewarped crop, so the boxes it returns are in dewarped coordinates. Every
 * downstream consumer in BladeWatch — the motion-overlap filter, DetectionBaseline,
 * ActorTracker, CrossQuadrantTracker, ThumbnailBuffer — expects the ORIGINAL warped crop
 * space. If this mapping is wrong, boxes land on the wrong part of the frame: the visible
 * symptom is a hero thumbnail with the box drawn in the wrong place, or motion-overlap
 * silently rejecting every real detection.
 *
 * Written before the implementation.
 */
class FisheyeDewarpMappingTest {

    private companion object {
        /** Byte-decodable tile with the same 0.75 aspect as the live 320x240 mosaic tile. */
        const val W = 200
        const val H = 150

        const val MIRROR_Q = 3      // left mirror — dewarped
        const val IDENTITY_Q = 0    // front — never dewarped
    }

    private fun det(x: Int, y: Int, w: Int, h: Int) = Detection(0, 0.9f, x, y, w, h)
    private fun one(x: Int, y: Int, w: Int, h: Int) = listOf(det(x, y, w, h))

    // ── identity and failure behaviour ──

    /** A quadrant that is not dewarped must not have its boxes moved. */
    @Test
    fun `identity quadrant leaves boxes untouched`() {
        val out = FisheyeDewarp.mapDetectionsToSource(one(10, 20, 30, 40), W, H, IDENTITY_Q)!!
        assertEquals(1, out.size)
        assertEquals(10, out[0].x)
        assertEquals(20, out[0].y)
        assertEquals(30, out[0].w)
        assertEquals(40, out[0].h)
    }

    @Test
    fun `null and empty are handled without throwing`() {
        assertNull(FisheyeDewarp.mapDetectionsToSource(null, W, H, MIRROR_Q))
        assertTrue(FisheyeDewarp.mapDetectionsToSource(emptyList(), W, H, MIRROR_Q)!!.isEmpty())
    }

    /**
     * A degenerate crop size must leave the boxes ALONE.
     *
     * This pins the OUTCOME, not the mechanism, and deliberately so. Two things deliver it:
     * the explicit `w <= 0 || h <= 0` guard, and — if that guard were removed — the
     * fail-open `catch`, because a zero width drives the arithmetic to NaN and
     * `coerceIn(0, w - 1)` then throws on an inverted range. Mutation-tested: deleting the
     * guard still passes, which is the correct result for an outcome test and is why the
     * guard is not load-bearing.
     *
     * The guard is kept regardless, so the safe behaviour comes from a stated precondition
     * rather than from an exception thrown four lines deep in float maths — the sort of
     * accident that survives exactly until someone narrows the catch.
     */
    @Test
    fun `degenerate crop size leaves boxes untouched rather than collapsing them`() {
        listOf(0 to H, W to 0, 0 to 0, -1 to H).forEach { (w, h) ->
            val out = FisheyeDewarp.mapDetectionsToSource(one(10, 20, 30, 40), w, h, MIRROR_Q)!!
            assertEquals("size at ${w}x$h", 1, out.size)
            assertEquals("x must be untouched at ${w}x$h", 10, out[0].x)
            assertEquals("y must be untouched at ${w}x$h", 20, out[0].y)
            assertEquals("w must not collapse at ${w}x$h", 30, out[0].w)
            assertEquals("h must not collapse at ${w}x$h", 40, out[0].h)
        }
    }

    // ── everything non-geometric must survive ──

    /**
     * Only the box moves. classId and confidence decide what the event IS and whether it
     * passes the threat gate, so corrupting them would change behaviour far beyond geometry.
     * The list is also indexed positionally downstream, so order and size must hold.
     */
    @Test
    fun `classId confidence and order are preserved`() {
        val input = listOf(
            Detection(0, 0.91f, 20, 20, 10, 10),
            Detection(2, 0.42f, 120, 40, 30, 25),
            Detection(7, 0.77f, 60, 100, 15, 40))

        val out = FisheyeDewarp.mapDetectionsToSource(input, W, H, MIRROR_Q)!!

        assertEquals("list size must not change", input.size, out.size)
        input.forEachIndexed { i, expected ->
            assertEquals("classId at $i", expected.classId, out[i].classId)
            assertEquals("confidence at $i", expected.confidence, out[i].confidence, 0f)
        }
    }

    // ── geometry ──

    /** Radial transforms are identity at r = 0, so a centred box barely moves. */
    @Test
    fun `a centred box stays approximately put`() {
        val bw = 20
        val bh = 16
        val bx = W / 2 - bw / 2
        val by = H / 2 - bh / 2
        val d = FisheyeDewarp.mapDetectionsToSource(one(bx, by, bw, bh), W, H, MIRROR_Q)!![0]
        assertEquals("centre box x", bx.toDouble(), d.x.toDouble(), 4.0)
        assertEquals("centre box y", by.toDouble(), d.y.toDouble(), 4.0)
    }

    /** A mapped box must stay inside the crop, with non-negative extents. */
    @Test
    fun `mapped boxes stay in bounds with non negative extents`() {
        val input = listOf(
            det(0, 0, 10, 10),                  // top-left corner
            det(W - 10, H - 10, 10, 10),        // bottom-right corner
            det(0, H / 2, W, 4),                // full-width sliver
            det(W / 2, 0, 4, H))                // full-height sliver

        FisheyeDewarp.mapDetectionsToSource(input, W, H, MIRROR_Q)!!.forEach { d ->
            assertTrue("x >= 0", d.x >= 0)
            assertTrue("y >= 0", d.y >= 0)
            assertTrue("w >= 0", d.w >= 0)
            assertTrue("h >= 0", d.h >= 0)
            assertTrue("x+w within crop", d.x + d.w <= W)
            assertTrue("y+h within crop", d.y + d.h <= H)
        }
    }

    /**
     * THE point of sampling 8 points rather than 4.
     *
     * The transform is radial, so a straight edge bows: a wide box's extreme in y can sit at
     * the MIDPOINT of its top or bottom edge, not at a corner. Mapping only the corners
     * under-covers the object, and an under-sized box then fails motion-overlap or clips the
     * subject out of the hero thumbnail.
     */
    @Test
    fun `wide box keeps the bowed edge that corners would miss`() {
        val bx = 10
        val by = 20
        val bw = W - 20
        val bh = 12

        val eight = FisheyeDewarp.mapDetectionsToSource(one(bx, by, bw, bh), W, H, MIRROR_Q)!![0]
        val fourCornerHeight = mapUsingCornersOnly(bx, by, bw, bh)

        assertTrue(
            "8-point mapping must cover at least as much height as a 4-corner mapping " +
                "(8-point h=${eight.h}, 4-corner h=$fourCornerHeight). If it does not, the " +
                "edge midpoints are not being sampled and a bowed edge is being clipped off.",
            eight.h >= fourCornerHeight)
        assertTrue(
            "for a wide box the bow must be strictly visible, otherwise this test is not " +
                "exercising the property it claims to",
            eight.h > fourCornerHeight)
    }

    /**
     * Reference implementation of the WRONG approach, used only to prove the real one does
     * better. Mirrors the production forward map but samples corners alone.
     */
    private fun mapUsingCornersOnly(bx: Int, by: Int, bw: Int, bh: Int): Int {
        val strength = FisheyeDewarp.strengthFor(MIRROR_Q)
        val k1 = 0.30f * strength
        val k2 = 0.10f * strength
        val aspect = H.toFloat() / W   // derived, exactly as production does
        val a2 = aspect * aspect
        val zoom = 1f + k1 * a2 + k2 * a2 * a2

        val px = floatArrayOf(bx.toFloat(), (bx + bw).toFloat(), bx.toFloat(), (bx + bw).toFloat())
        val py = floatArrayOf(by.toFloat(), by.toFloat(), (by + bh).toFloat(), (by + bh).toFloat())
        var minY = Float.MAX_VALUE
        var maxY = -Float.MAX_VALUE
        for (i in 0 until 4) {
            val nx = (px[i] / W) * 2f - 1f
            val nya = ((py[i] / H) * 2f - 1f) * aspect
            val r2 = nx * nx + nya * nya
            val inv = 1f / (1f + k1 * r2 + k2 * r2 * r2)
            val syp = (((nya * inv * zoom) / aspect) * 0.5f + 0.5f) * H
            minY = minOf(minY, syp)
            maxY = maxOf(maxY, syp)
        }
        val y = Math.round(minY).coerceIn(0, H - 1)
        return (Math.round(maxY) - y).coerceIn(0, H - y)
    }

    /**
     * The mapping and the pixel transform must be the SAME function, or boxes will not land
     * on the thing that was detected.
     *
     * Round trip: paint a marker block at a known SOURCE position, dewarp the image, find
     * where the marker ended up in dewarped space, hand that position back as a detection,
     * and require it to map home. This is the only test here that checks the two halves of
     * the feature against each other rather than each against the formula — a consistent
     * sign error in both would pass everything else and still put boxes in the wrong place.
     */
    @Test
    fun `mapping is the inverse of where the dewarp moved the pixels`() {
        val markerX = 140
        val markerY = 45
        val markerSize = 12

        val src = ByteArray(W * H * 3)  // black
        for (y in markerY until markerY + markerSize) {
            for (x in markerX until markerX + markerSize) {
                val i = (y * W + x) * 3
                src[i] = 0xFF.toByte(); src[i + 1] = 0xFF.toByte(); src[i + 2] = 0xFF.toByte()
            }
        }

        val dewarped = FisheyeDewarp.dewarpForDetector(src, W, H, MIRROR_Q)
        assertNotNull("Q3 must be dewarped for this test to mean anything", dewarped)

        var minX = Int.MAX_VALUE
        var minY = Int.MAX_VALUE
        var maxX = -1
        var maxY = -1
        for (y in 0 until H) {
            for (x in 0 until W) {
                if ((dewarped!![(y * W + x) * 3].toInt() and 0xFF) > 127) {
                    minX = minOf(minX, x); maxX = maxOf(maxX, x)
                    minY = minOf(minY, y); maxY = maxOf(maxY, y)
                }
            }
        }
        assertTrue("the marker vanished from the dewarped image", maxX >= 0)

        val mapped = FisheyeDewarp.mapDetectionsToSource(
            one(minX, minY, maxX - minX + 1, maxY - minY + 1), W, H, MIRROR_Q)!![0]

        assertEquals("round-tripped x", markerX.toDouble(), mapped.x.toDouble(), 3.0)
        assertEquals("round-tripped y", markerY.toDouble(), mapped.y.toDouble(), 3.0)
        assertEquals("round-tripped width", markerSize.toDouble(), mapped.w.toDouble(), 4.0)
        assertEquals("round-tripped height", markerSize.toDouble(), mapped.h.toDouble(), 4.0)
    }
}
