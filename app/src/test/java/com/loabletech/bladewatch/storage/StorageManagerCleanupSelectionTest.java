package net.bladewatch.app.storage;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.Collections;
import java.util.List;

import org.junit.Test;

/**
 * BladeWatch-gyg1.4: {@link StorageManager#selectFilesToDelete} is the selection algorithm
 * shared, unmodified, by the real cleanup in {@code ensureSpace} and the new
 * {@code previewRecordingsLimitChange}/{@code previewSurveillanceLimitChange}. Extracted as a
 * static, dependency-injected method specifically so it is testable without constructing a
 * {@code StorageManager}, which needs a live Android environment for other members (real
 * on-disk paths under {@code /storage/emulated/0/...}, {@code StatFs}, etc.) — see
 * {@code MarkedRecordingsExcludedFromCleanupTest}'s doc comment for the same constraint
 * against the pre-refactor {@code ensureSpace}.
 *
 * <p>A JVM temp directory (not {@code /storage/emulated/0}) is a perfectly real filesystem for
 * {@link File} I/O, so this drives the actual algorithm against actual files, not a structural
 * source-text guard.
 */
public class StorageManagerCleanupSelectionTest {

    private File dir;
    private MarkedRecordingsStore markedStore;

    private void setUp() throws IOException {
        dir = Files.createTempDirectory("cleanup-selection-test").toFile();
        markedStore = new MarkedRecordingsStore(Files.createTempFile("marked-recordings", ".json").toFile());
    }

    /** {@code rec_<epochMs>.mp4}, sized and dated so oldest-first sorting is unambiguous. */
    private File file(String name, long sizeBytes, long mtimeMs) throws IOException {
        File f = new File(dir, name);
        Files.write(f.toPath(), new byte[(int) sizeBytes]);
        assertTrue("could not set mtime for " + name, f.setLastModified(mtimeMs));
        return f;
    }

    @Test
    public void alreadyWithinTarget_selectsNothing() throws Exception {
        setUp();
        file("rec_1.mp4", 100, 1_000);

        StorageManager.CleanupSelection selection = StorageManager.selectFilesToDelete(
                Collections.singletonList(dir), null, 1_000, markedStore, d -> d.listFiles());

        assertTrue("expected no files selected when already under target", selection.files.isEmpty());
        assertEquals(100, selection.poolSizeAtStart);
    }

    @Test
    public void overTarget_selectsOldestFirst_stoppingAsSoonAsUnderTarget() throws Exception {
        setUp();
        File oldest = file("rec_1.mp4", 100, 1_000);
        File middle = file("rec_2.mp4", 100, 2_000);
        file("rec_3.mp4", 100, 3_000); // newest -- pool is 300, target 250 needs only the oldest gone

        StorageManager.CleanupSelection selection = StorageManager.selectFilesToDelete(
                Collections.singletonList(dir), null, 250, markedStore, d -> d.listFiles());

        assertEquals(List.of(oldest), selection.files);
        assertEquals(300, selection.poolSizeAtStart);
        assertTrue("middle file must survive a selection that only needed the oldest",
                !selection.files.contains(middle));
    }

    @Test
    public void markedFileIsSkipped_nextOldestUnmarkedIsSelectedInstead() throws Exception {
        setUp();
        File oldest = file("rec_1.mp4", 100, 1_000);
        File nextOldest = file("rec_2.mp4", 100, 2_000);
        file("rec_3.mp4", 100, 3_000);
        markedStore.mark("rec_1.mp4");

        StorageManager.CleanupSelection selection = StorageManager.selectFilesToDelete(
                Collections.singletonList(dir), null, 250, markedStore, d -> d.listFiles());

        assertTrue("marked file must never be selected", !selection.files.contains(oldest));
        assertTrue("the next-oldest unmarked file must be selected in its place",
                selection.files.contains(nextOldest));
    }

    @Test
    public void namePrefixFiltersToOnlyMatchingFiles() throws Exception {
        setUp();
        file("rec_1.mp4", 100, 1_000);
        file("sentry_1.mp4", 100, 1_500);

        StorageManager.CleanupSelection selection = StorageManager.selectFilesToDelete(
                Collections.singletonList(dir), "sentry_", 0, markedStore, d -> d.listFiles());

        assertEquals("only the sentry_-prefixed file should count toward the pool", 100, selection.poolSizeAtStart);
        assertEquals(1, selection.files.size());
        assertEquals("sentry_1.mp4", selection.files.get(0).getName());
    }

    /**
     * The required-tests list (BladeWatch-gyg1.4) asks for "a preview with a hypothetical
     * limit lower than current returns a larger candidate set than the same call without it" —
     * written against a design where the daemon added an optional hypothetical-limit field to
     * an existing endpoint. This codebase's actual design has no "without a hypothetical
     * limit" mode (every call names an explicit target), so the equivalent, meaningful
     * assertion is monotonicity: a lower target can never select fewer files than a higher one
     * against the same file set.
     */
    @Test
    public void aLowerTarget_selectsAtLeastAsManyFilesAsAHigherTarget() throws Exception {
        setUp();
        file("rec_1.mp4", 100, 1_000);
        file("rec_2.mp4", 100, 2_000);
        file("rec_3.mp4", 100, 3_000);

        StorageManager.CleanupSelection higherTarget = StorageManager.selectFilesToDelete(
                Collections.singletonList(dir), null, 250, markedStore, d -> d.listFiles());
        StorageManager.CleanupSelection lowerTarget = StorageManager.selectFilesToDelete(
                Collections.singletonList(dir), null, 50, markedStore, d -> d.listFiles());

        assertTrue("a lower target must select at least as many files as a higher target",
                lowerTarget.files.size() >= higherTarget.files.size());
        assertEquals(1, higherTarget.files.size());
        assertEquals(3, lowerTarget.files.size());
    }

    // ── BladeWatch-xa3s: preview must describe the limit that would actually be applied ──

    /**
     * Why the clamp below matters, stated as behaviour rather than as a claim: a negative target
     * makes the selection loop's {@code remaining <= targetSizeBytes} break condition
     * unreachable, so every unmarked file is selected. A preview fed an unclamped negative or
     * overflowing value therefore tells the owner their entire library is about to be deleted —
     * while applying the same request clamps it and deletes almost nothing.
     */
    @Test
    public void aNegativeTarget_selectsEverything_whichIsWhyTheLimitMustBeClampedFirst() throws Exception {
        setUp();
        file("rec_1.mp4", 100, 1_000);
        file("rec_2.mp4", 100, 2_000);
        file("rec_3.mp4", 100, 3_000);

        StorageManager.CleanupSelection selection = StorageManager.selectFilesToDelete(
                Collections.singletonList(dir), null, -1_048_576L, markedStore, d -> d.listFiles());

        assertEquals("a negative target can never be satisfied, so nothing stops the loop",
                3, selection.files.size());
    }

    @Test
    public void clampLimitMb_bringsAnOutOfRangeRequestToWhatWouldActuallyBePersisted() {
        long diskMaxMb = 64_000;

        assertEquals("a negative request must clamp up to the floor, not stay negative",
                100, StorageManager.clampLimitMb(-1, diskMaxMb));
        assertEquals("zero is below the floor too",
                100, StorageManager.clampLimitMb(0, diskMaxMb));
        assertEquals("a request larger than the disk clamps to the disk",
                diskMaxMb, StorageManager.clampLimitMb(Long.MAX_VALUE, diskMaxMb));
        assertEquals("an in-range request is passed through untouched",
                20_000, StorageManager.clampLimitMb(20_000, diskMaxMb));
    }

    /**
     * The clamp is also what keeps {@code limitMb * 1024 * 1024} from overflowing: an unclamped
     * Long.MAX_VALUE wraps to a negative target, i.e. straight into the
     * selects-everything case above.
     */
    @Test
    public void clampLimitMb_makesTheByteConversionOverflowProof() {
        long diskMaxMb = 64_000;

        long rawBytes = Long.MAX_VALUE * 1024L * 1024L;
        assertTrue("precondition: the unclamped multiply really does overflow negative", rawBytes < 0);

        long clampedBytes = StorageManager.clampLimitMb(Long.MAX_VALUE, diskMaxMb) * 1024L * 1024L;
        assertTrue("clamping first keeps the byte target positive", clampedBytes > 0);
    }
}
