package net.bladewatch.app.surveillance

import java.io.File
import java.nio.charset.StandardCharsets
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-4pic: the wiring contract for fisheye dewarp in `SurveillanceEngineGpu`.
 *
 * The dewarp itself is covered by [FisheyeDewarpTest] and [FisheyeDewarpMappingTest]. What
 * those cannot reach is how the engine CALLS it, and the two ways of getting that wrong are
 * both silent:
 *
 *  1. Dewarping a foveated crop. Foveated crops are re-centred sub-windows of the panorama,
 *     so their centre is not the lens axis and a tile-centred radial model moves their boxes
 *     the wrong way. Nothing throws; detections just land in the wrong place.
 *  2. Handing the dewarped buffer to anything other than the detector, or forgetting to map
 *     the boxes back, which puts every downstream consumer in the wrong coordinate space.
 *
 * `SurveillanceEngineGpu` is ~4,000 lines and instantiating it needs a GL context, a camera
 * and a TFLite interpreter, so this reads the source as DATA — the property under test is
 * what the call site is wired to do. `app/build.gradle.kts` declares `src/main/java` as an
 * explicit test input, so this re-runs when that file changes.
 */
class FisheyeDewarpWiringTest {

    private fun engineSource(): String {
        var f = File("src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.java")
        if (!f.isFile) {
            f = File("app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.java")
        }
        assertTrue("could not locate SurveillanceEngineGpu.java from ${File(".").absolutePath}",
            f.isFile)
        return String(f.readBytes(), StandardCharsets.UTF_8)
    }

    /**
     * The mosaic-vs-foveated decision must be an explicit flag, not inferred from the crop
     * dimensions. Inferring it from `qW == FoveatedCropper.CROP_SIZE` would work today and
     * break silently the day CROP_SIZE changes or a third crop path appears.
     */
    @Test
    fun `the crop path is distinguished by an explicit flag`() {
        val src = engineSource()
        assertTrue(
            "SurveillanceEngineGpu must declare a boolean marking a full mosaic tile. " +
                "Do not infer it from qW or CROP_SIZE — that is exactly the inference this " +
                "guard exists to prevent.",
            src.contains("boolean fromMosaicTile"))
    }

    /** All three crop branches must set it: foveated, the foveated fallback, and legacy. */
    @Test
    fun `every crop branch assigns the flag`() {
        val src = engineSource()
        val falseAssignments = Regex("fromMosaicTile\\s*=\\s*false").findAll(src).count()
        val trueAssignments = Regex("fromMosaicTile\\s*=\\s*true").findAll(src).count()

        assertTrue(
            "the foveated branch must set the flag false (found $falseAssignments)",
            falseAssignments >= 1)
        assertTrue(
            "both mosaic branches — the foveated FALLBACK and the legacy path — must set it " +
                "true (found $trueAssignments). The fallback is easy to miss: it sits inside " +
                "the foveated branch but produces a real mosaic tile.",
            trueAssignments >= 2)
    }

    /** Dewarp must be gated on that flag, so a foveated crop is never dewarped. */
    @Test
    fun `dewarp is applied only to mosaic tiles`() {
        val src = engineSource()
        assertTrue(
            "the dewarp call must be guarded by fromMosaicTile",
            Regex("fromMosaicTile\\s*\\n?\\s*\\?\\s*FisheyeDewarp\\.dewarpForDetector")
                .containsMatchIn(src.replace("\r\n", "\n")))
    }

    /**
     * The detector gets the dewarped bytes; everything else keeps the original crop. If
     * `cropData` were reassigned, the thumbnail and the tracker would silently move to
     * dewarped space and every stored box would be wrong.
     */
    @Test
    fun `the original crop is never replaced by the dewarped one`() {
        val src = engineSource()
        assertTrue(
            "the detector must be fed a separate buffer, not a reassigned cropData",
            src.contains("detectorInput"))
        assertTrue(
            "cropData is declared final so it cannot be reassigned — keep it that way",
            src.contains("final byte[] cropData"))
    }

    /**
     * Boxes must come home before anything reads them. Checked by ORDER in the file, because
     * a mapping call that sits after the motion-overlap filter is worse than none: the
     * filter would compare dewarped boxes against warped motion blocks and reject everything.
     */
    @Test
    fun `detections are mapped back before any downstream consumer`() {
        val src = engineSource()

        val detectAt = src.indexOf("detectorInput, qW, qH, aiConfidence")
        assertTrue("could not find the detector call", detectAt > 0)

        val mapAt = src.indexOf("FisheyeDewarp.mapDetectionsToSource", detectAt)
        assertTrue("the detections are never mapped back to source space", mapAt > detectAt)

        // The first thing that consumes the list after inference is the motion-overlap filter.
        val firstConsumerAt = src.indexOf("motionFiltered", detectAt)
        assertTrue("could not find the motion-overlap filter after the detector call",
            firstConsumerAt > detectAt)

        assertTrue(
            "mapDetectionsToSource must run BEFORE the motion-overlap filter (map at " +
                "$mapAt, first consumer at $firstConsumerAt). Downstream stages compare " +
                "these boxes against warped motion blocks, the baseline and tracker state.",
            mapAt < firstConsumerAt)
    }
}
