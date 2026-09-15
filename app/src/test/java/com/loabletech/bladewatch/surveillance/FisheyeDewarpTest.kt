package net.bladewatch.app.surveillance

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-z3w4: the fisheye dewarp transform, tested as a pure function.
 *
 * Written before the implementation. The transform is applied only to the pixel buffer
 * handed to YOLO, so a defect here is invisible everywhere else in the pipeline — nothing
 * on screen changes, no recording changes, and the only symptom is that the detector
 * quietly does worse. That is precisely the kind of bug that needs a test rather than a
 * review.
 *
 * The properties pinned here follow from the maths regardless of the constants, so they
 * keep holding if the strengths are ever re-derived on a real car. They deliberately assert
 * "greater than zero" rather than "equals 0.5" for that reason — retuning a constant should
 * not break a geometry test.
 */
class FisheyeDewarpTest {

    private companion object {
        /** The live mosaic tile size. Used where only sizes and null-contracts matter. */
        const val W = 320
        const val H = 240

        /**
         * Coordinate-decoding size. The gradient fixture encodes source x and y into single
         * BYTES, so both dimensions must stay under 256 or the encoding aliases — at 320
         * wide, source x=306 reads back as 50 and a symmetry assertion compares nonsense.
         * 200x150 keeps the same 0.75 aspect as the live tile, which matters because the
         * transform derives its aspect from w/h — so a fixture with a different aspect would
         * be testing a different geometry from the one that ships.
         */
        const val DW = 200
        const val DH = 150

        /** Square tile, for the isotropy check. Under 256 so coordinates stay byte-decodable. */
        const val SQ = 128

        const val MIRROR_Q = 3      // left mirror — dewarped
    }

    /** RGB888 where R = x and G = y, so an output pixel reveals the source it sampled. */
    private fun gradient(w: Int, h: Int) = ByteArray(w * h * 3).also { rgb ->
        for (y in 0 until h) {
            for (x in 0 until w) {
                val i = (y * w + x) * 3
                rgb[i] = x.toByte()
                rgb[i + 1] = y.toByte()
                rgb[i + 2] = ((x + y) and 0xFF).toByte()
            }
        }
    }

    private fun ByteArray.sampledX(x: Int, y: Int, w: Int) = this[(y * w + x) * 3].toInt() and 0xFF
    private fun ByteArray.sampledY(x: Int, y: Int, w: Int) =
        this[(y * w + x) * 3 + 1].toInt() and 0xFF

    // ── strengthFor: the quadrant indexing, the easiest thing to get wrong ──

    /**
     * Q0..Q3 are front/right/rear/left per `MotionPipelineV2.QUADRANT_NAMES`. Only the two
     * MIRROR cameras are dewarped; front and rear stay at 0, which is byte-identical to
     * today, because there is no evidence for them.
     *
     * This is the assertion that catches what BladeWatch-7elj was filed for. A comment in
     * `FoveatedCropper` used to claim Q2 was left and Q3 rear; indexing the strengths that
     * way would dewarp the REAR camera while leaving the LEFT mirror — the one carrying all
     * the upstream evidence — untouched, and it would compile perfectly.
     */
    @Test
    fun `only the mirror cameras are dewarped`() {
        assertEquals("Q0 is front — no evidence, must stay identity",
            0f, FisheyeDewarp.strengthFor(0), 0f)
        assertTrue("Q1 is the right mirror — must be dewarped",
            FisheyeDewarp.strengthFor(1) > 0f)
        assertEquals("Q2 is REAR (not left) — no evidence, must stay identity",
            0f, FisheyeDewarp.strengthFor(2), 0f)
        assertTrue("Q3 is the LEFT mirror (not rear) — must be dewarped",
            FisheyeDewarp.strengthFor(3) > 0f)
    }

    @Test
    fun `out of range quadrants are identity`() {
        assertEquals(0f, FisheyeDewarp.strengthFor(-1), 0f)
        assertEquals(0f, FisheyeDewarp.strengthFor(4), 0f)
        assertEquals(0f, FisheyeDewarp.strengthFor(Int.MIN_VALUE), 0f)
        assertEquals(0f, FisheyeDewarp.strengthFor(Int.MAX_VALUE), 0f)
    }

    // ── the null contract ──

    /**
     * A non-dewarped quadrant returns null, NOT a copy. The caller then feeds the original
     * buffer. A copy would make "unchanged" indistinguishable from "changed" and would also
     * allocate ~230 KB per inference for nothing.
     */
    @Test
    fun `non dewarped quadrant returns null rather than a copy`() {
        val rgb = gradient(W, H)
        assertNull("front", FisheyeDewarp.dewarpForDetector(rgb, W, H, 0))
        assertNull("rear", FisheyeDewarp.dewarpForDetector(rgb, W, H, 2))
    }

    /** Fail open: any malformed input yields null, so the caller uses the original crop. */
    @Test
    fun `malformed input fails open rather than throwing`() {
        assertNull("null buffer", FisheyeDewarp.dewarpForDetector(null, W, H, MIRROR_Q))
        assertNull("buffer too small for w*h*3",
            FisheyeDewarp.dewarpForDetector(ByteArray(10), W, H, MIRROR_Q))
        assertNull("zero-sized crop",
            FisheyeDewarp.dewarpForDetector(ByteArray(0), 0, 0, MIRROR_Q))
    }

    // ── the transform itself ──

    @Test
    fun `a dewarped quadrant actually changes the pixels`() {
        val rgb = gradient(W, H)
        val out = FisheyeDewarp.dewarpForDetector(rgb, W, H, MIRROR_Q)
        assertNotNull("Q3 is dewarped, so this must not be null", out)
        assertEquals(W * H * 3, out!!.size)
        assertFalse("a dewarp that changes nothing is not a dewarp", rgb.contentEquals(out))
    }

    /**
     * Every sampled coordinate must land inside the source. The gradient encodes the source
     * x and y in the pixel, so an out-of-range read would surface as a coordinate no source
     * pixel could have produced.
     */
    @Test
    fun `every sampled pixel is inside the source`() {
        val out = FisheyeDewarp.dewarpForDetector(gradient(DW, DH), DW, DH, MIRROR_Q)
        assertNotNull(out)
        for (y in 0 until DH) {
            for (x in 0 until DW) {
                val sx = out!!.sampledX(x, y, DW)
                val sy = out.sampledY(x, y, DW)
                assertTrue("sampled x=$sx outside [0,${DW - 1}] at $x,$y", sx in 0 until DW)
                assertTrue("sampled y=$sy outside [0,${DH - 1}] at $x,$y", sy in 0 until DH)
            }
        }
    }

    /** Pure function of (strength, w, h): same inputs, same bytes, every time. */
    @Test
    fun `the transform is deterministic`() {
        val rgb = gradient(W, H)
        val first = FisheyeDewarp.dewarpForDetector(rgb, W, H, MIRROR_Q)!!.copyOf()
        val second = FisheyeDewarp.dewarpForDetector(rgb, W, H, MIRROR_Q)
        assertArrayEquals(first, second)
    }

    /**
     * The model is radial about the tile centre, so sampling must mirror about the vertical
     * axis. Checked on the centre row, where the vertical term is constant. An asymmetric
     * result means the centring — the half-pixel offset, or the aspect term — is wrong.
     */
    @Test
    fun `the transform is symmetric about the vertical axis`() {
        val out = FisheyeDewarp.dewarpForDetector(gradient(DW, DH), DW, DH, MIRROR_Q)
        assertNotNull(out)
        val y = DH / 2
        for (x in 0 until DW / 2) {
            val left = out!!.sampledX(x, y, DW)
            val right = out.sampledX(DW - 1 - x, y, DW)
            assertEquals("column $x is not mirror-symmetric",
                ((DW - 1) - left).toDouble(), right.toDouble(), 2.0)
        }
    }

    /** Radial transforms are identity at r = 0, so the centre barely moves. */
    @Test
    fun `the centre is approximately fixed`() {
        val out = FisheyeDewarp.dewarpForDetector(gradient(DW, DH), DW, DH, MIRROR_Q)
        assertNotNull(out)
        val cx = DW / 2
        val cy = DH / 2
        assertEquals("centre x should sample near itself",
            cx.toDouble(), out!!.sampledX(cx, cy, DW).toDouble(), 2.0)
        assertEquals("centre y should sample near itself",
            cy.toDouble(), out.sampledY(cx, cy, DW).toDouble(), 2.0)
    }

    /**
     * Dewarping magnifies the periphery, so an output pixel away from the centre samples a
     * source pixel further out than itself.
     */
    @Test
    fun `off centre pixels sample further from the centre`() {
        val out = FisheyeDewarp.dewarpForDetector(gradient(DW, DH), DW, DH, MIRROR_Q)
        assertNotNull(out)
        val cx = DW / 2
        val cy = DH / 2
        val probe = cx + DW / 4
        val sampled = out!!.sampledX(probe, cy, DW)
        assertTrue(
            "output x=$probe sampled source x=$sampled; dewarp must sample FURTHER from " +
                "the centre, not nearer", sampled > probe)
    }

    /**
     * The magnification must be STRONGEST at the centre and fall off with radius. This is
     * what distinguishes correcting a barrel distortion from deepening one, and it is the
     * only property here that pins the DIRECTION of the model.
     *
     * Added after mutation testing: replacing `inv = 1 / (1 + k1*r^2 + k2*r^4)` with
     * `inv = (1 + k1*r^2 + k2*r^4)` — inverting the correction entirely — passed every
     * other test in this class. Both models sample further from the centre than the output
     * pixel, so "samples outward" cannot tell them apart; only the way the ratio CHANGES
     * with radius can.
     *
     * Probes stay clear of the tile edge on purpose: there the source coordinate clamps,
     * and clamping flattens the ratio enough to hide the inversion.
     */
    @Test
    fun `magnification falls off with radius`() {
        val out = FisheyeDewarp.dewarpForDetector(gradient(DW, DH), DW, DH, MIRROR_Q)
        assertNotNull(out)
        val cx = DW / 2
        val cy = DH / 2
        val nearProbe = cx + DW / 8
        val farProbe = cx + (DW * 7) / 20

        val nearRatio = (out!!.sampledX(nearProbe, cy, DW) - cx).toDouble() / (nearProbe - cx)
        val farRatio = (out.sampledX(farProbe, cy, DW) - cx).toDouble() / (farProbe - cx)

        assertTrue(
            "magnification must DECREASE with radius (near=$nearRatio, far=$farRatio). " +
                "If far exceeds near the correction is inverted — it is deepening the " +
                "barrel distortion instead of removing it, and the detector will do worse.",
            nearRatio > farRatio)
    }

    /**
     * The aspect is DERIVED from w/h, not hardcoded, so a square tile is corrected
     * isotropically — equal radius in, equal magnification out, whichever axis you walk.
     *
     * This is the guard for the fix that replaced a hardcoded 0.75f. With the constant back
     * in, a square tile squashes the vertical term (nya = ny * 0.75) so the radius at a
     * vertical probe is smaller than at an equidistant horizontal one, the two get different
     * magnification, and the assertion below fails. Nothing else in this class notices,
     * because every other fixture here is 4:3 — where derived and hardcoded agree exactly.
     */
    @Test
    fun `a square tile is corrected isotropically`() {
        val out = FisheyeDewarp.dewarpForDetector(gradient(SQ, SQ), SQ, SQ, MIRROR_Q)
        assertNotNull(out)
        val c = SQ / 2
        // 3/8 of the tile, not 1/4. The radius matters: nearer the centre the two models
        // differ by well under a pixel and this test passes against the bug it exists to
        // catch (measured — at d = SQ/4 both give 34). Far enough out and the difference
        // opens to 2px and grows; much further and the source coordinate starts clamping
        // at the tile edge, which flattens it again.
        val d = SQ * 3 / 8

        val horizontal = out!!.sampledX(c + d, c, SQ) - c
        val vertical = out.sampledY(c, c + d, SQ) - c

        assertTrue("the probes must actually be magnified, or this proves nothing",
            horizontal > d)
        assertEquals(
            "a square tile must magnify equally along both axes (horizontal=$horizontal, " +
                "vertical=$vertical). A hardcoded 0.75 aspect makes these differ.",
            horizontal.toDouble(), vertical.toDouble(), 1.0)
    }

    /**
     * The LUT is cached per (strength, w, h). A stale cache reused across a size change
     * would index outside the new buffer, so prove the cache re-enters correctly in both
     * directions rather than only growing.
     */
    @Test
    fun `changing crop size rebuilds the transform`() {
        val big = gradient(W, H)
        val small = gradient(W / 2, H / 2)

        assertEquals(W * H * 3, FisheyeDewarp.dewarpForDetector(big, W, H, MIRROR_Q)!!.size)
        assertEquals((W / 2) * (H / 2) * 3,
            FisheyeDewarp.dewarpForDetector(small, W / 2, H / 2, MIRROR_Q)!!.size)
        assertEquals("cache must re-enter the original size correctly, not only grow",
            W * H * 3, FisheyeDewarp.dewarpForDetector(big, W, H, MIRROR_Q)!!.size)
    }
}
