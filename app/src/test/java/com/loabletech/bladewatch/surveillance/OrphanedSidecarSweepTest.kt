package net.bladewatch.app.surveillance

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * BladeWatch-g8ee: [HardwareEventRecorderGpu.cleanupOrphanedSidecars].
 *
 * Both failure directions are silent and expensive, which is why this is worth a test at all:
 *
 *  - Sweeping too little is how 823 orphans (111 MB) accumulated on the head unit over nine
 *    days. They are not inert — the retention reaper measures the whole directory against the
 *    category limit, so dead thumbnails consume quota and it deletes real footage to compensate.
 *  - Sweeping too much destroys the owner's evidence. A segment mid-write has no `.mp4` yet
 *    (it is `<base>.mp4.tmp`), so a naive "no matching mp4" rule would eat the sidecars of the
 *    event currently being recorded.
 */
class OrphanedSidecarSweepTest {

    @get:Rule
    val tmp = TemporaryFolder()

    /** Writes [name] and back-dates it well past the sweeper's 5-minute grace window. */
    private fun aged(name: String): File = tmp.newFile(name).apply {
        writeText("x")
        assertTrue("could not back-date $name", setLastModified(System.currentTimeMillis() - 60 * 60 * 1000L))
    }

    @Test
    fun reapsSidecarsWhoseSegmentIsGone() {
        val hero = aged("event_20260101_010101.jpg")
        val srt = aged("event_20260101_010101.srt")
        val json = aged("event_20260101_010101.json")
        val thumb = aged("thumb_event_20260101_010101_a17_9300.jpg")

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(tmp.root))

        assertFalse("hero JPEG survived", hero.exists())
        assertFalse("SRT survived", srt.exists())
        assertFalse("timeline JSON survived", json.exists())
        assertFalse("per-actor thumbnail survived", thumb.exists())
    }

    @Test
    fun keepsSidecarsOfALiveSegment() {
        val mp4 = aged("event_20260101_010101.mp4")
        val hero = aged("event_20260101_010101.jpg")
        val srt = aged("event_20260101_010101.srt")
        val json = aged("event_20260101_010101.json")
        val thumb = aged("thumb_event_20260101_010101_a17_9300.jpg")

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(tmp.root))

        for (f in listOf(mp4, hero, srt, json, thumb)) {
            assertTrue("deleted a live segment's " + f.name, f.exists())
        }
    }

    /** A segment being written right now is `<base>.mp4.tmp` — its sidecars land first. */
    @Test
    fun keepsSidecarsOfASegmentStillBeingWritten() {
        val inFlight = aged("event_20260101_010101.mp4.tmp")
        val hero = aged("event_20260101_010101.jpg")
        val thumb = aged("thumb_event_20260101_010101_a3.jpg")

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(tmp.root))

        assertTrue("deleted the in-flight segment", inFlight.exists())
        assertTrue("deleted a mid-write segment's hero JPEG", hero.exists())
        assertTrue("deleted a mid-write segment's thumbnail", thumb.exists())
    }

    /** The grace window covers the gap between the sidecar write and the .mp4 rename. */
    @Test
    fun keepsOrphansYoungerThanTheGraceWindow() {
        val fresh = tmp.newFile("event_20260101_010101.jpg").apply { writeText("x") }

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(tmp.root))

        assertTrue("reaped a sidecar inside the grace window", fresh.exists())
    }

    /** .tmp and .broken belong to cleanupOrphanedTmpFiles; .mp4 belongs to the reaper. */
    @Test
    fun leavesSegmentsAndTmpQuarantineAlone() {
        val orphanMp4 = aged("event_20260101_010101.mp4")
        val strayTmp = aged("event_20260102_020202.mp4.tmp")
        val broken = aged("event_20260103_030303.mp4.broken")

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(tmp.root))

        for (f in listOf(orphanMp4, strayTmp, broken)) {
            assertTrue("swept " + f.name + ", which is not a sidecar", f.exists())
        }
    }

    /**
     * A live segment must not shelter a dead sibling's thumbnails.
     *
     * `thumb_<base>_2_a17.jpg` also starts with `thumb_<base>`, so matching on the bare base
     * attributes it to the live `<base>` and keeps it forever — under-sweeping, which is
     * precisely the leak this sweeper exists to stop. The `_a` anchor is what separates them,
     * and it is the same anchor the forward paths in deleteSegmentSidecars, StorageManager
     * and RecordingsApiHandler all use.
     */
    @Test
    fun reapsADeadSiblingsThumbnailEvenWhenTheBaseSegmentIsLive() {
        val liveMp4 = aged("event_20260101_010101.mp4")
        val liveThumb = aged("thumb_event_20260101_010101_a17_9300.jpg")
        val deadSiblingThumb = aged("thumb_event_20260101_010101_2_a17_9300.jpg")

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(tmp.root))

        assertTrue("swept a live segment", liveMp4.exists())
        assertTrue("swept a live segment's own thumbnail", liveThumb.exists())
        assertFalse("kept a thumbnail whose segment was reaped", deadSiblingThumb.exists())
    }

    /** ...and the mirror image: reaping `<base>` must not take `<base>_2`'s thumbnails with it. */
    @Test
    fun doesNotSweepALiveSiblingsThumbnails() {
        val siblingMp4 = aged("event_20260101_010101_2.mp4")
        val siblingThumb = aged("thumb_event_20260101_010101_2_a17_9300.jpg")
        val orphanThumb = aged("thumb_event_20260101_010101_a17_9300.jpg")

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(tmp.root))

        assertTrue("swept a live sibling segment", siblingMp4.exists())
        assertTrue("swept the sibling segment's thumbnail", siblingThumb.exists())
        assertFalse("kept a genuinely orphaned thumbnail", orphanThumb.exists())
    }

    @Test
    fun toleratesAMissingDirectory() {
        val gone = File(tmp.root, "never-created")
        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(gone))
        assertEquals(0, tmp.root.listFiles()?.size ?: 0)
    }

    /**
     * The mirror case, and the reason this takes a list rather than one directory.
     *
     * InternalToSdMigrator.moveIfEligible moves files individually and skips anything younger
     * than its age gate, so a partial migration legitimately leaves "<base>.mp4" on the SD
     * card while "<base>.jpg" is still on internal. Sweeping either directory on its own reads
     * that as an orphan and deletes a live segment's sidecars.
     */
    @Test
    fun poolsLiveSegmentsAcrossEveryDirectoryOfTheCategory() {
        val sdMirror = tmp.newFolder("sd")
        val internal = tmp.newFolder("internal")

        fun agedIn(dir: File, name: String) = File(dir, name).apply {
            writeText("x")
            assertTrue(setLastModified(System.currentTimeMillis() - 60 * 60 * 1000L))
        }

        // Migration moved the segment to SD but has not moved its sidecars yet.
        val migratedMp4 = agedIn(sdMirror, "event_20260101_010101.mp4")
        val strandedHero = agedIn(internal, "event_20260101_010101.jpg")
        val strandedThumb = agedIn(internal, "thumb_event_20260101_010101_a4_120.jpg")
        // A genuine orphan on internal: nothing owns it in either directory.
        val realOrphan = agedIn(internal, "event_20251231_235959.srt")

        HardwareEventRecorderGpu.cleanupOrphanedSidecars(listOf(internal, sdMirror))

        assertTrue("deleted the migrated segment", migratedMp4.exists())
        assertTrue("deleted a live segment's hero JPEG stranded by a partial migration", strandedHero.exists())
        assertTrue("deleted a live segment's thumbnail stranded by a partial migration", strandedThumb.exists())
        assertFalse("kept a genuine orphan", realOrphan.exists())
    }
}
