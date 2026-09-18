package net.bladewatch.app.storage;

import static org.junit.Assert.assertEquals;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.Test;

/**
 * {@link StorageManager#resolveSdCardAutoPriority} is the retry-then-decide logic behind a real
 * incident: a boot-time race where the SD card wasn't mounted yet by the time
 * {@code applyAutoStoragePriority()} ran used to silently downgrade an already-configured
 * SD_CARD preference to INTERNAL and persist that, requiring a full device restart (sometimes
 * more than one) to recover. Extracted static + dependency-injected so it is testable without a
 * live Android environment — {@code StorageManager} itself needs one (real on-disk paths under
 * {@code /storage/emulated/0/...}, {@code StatFs}, shell probes), the same constraint that
 * motivated extracting {@link StorageManager#selectFilesToDelete} (see
 * {@code StorageManagerCleanupSelectionTest}'s doc comment).
 */
public class StorageManagerAutoPriorityTest {

    private static StorageManager.Sleeper noopSleeper(List<Long> sleptFor) {
        return ms -> sleptFor.add(ms);
    }

    @Test
    public void firstAttemptSucceeds_returnsMounted_noSleep() {
        List<Long> sleptFor = new ArrayList<>();
        AtomicInteger calls = new AtomicInteger(0);

        StorageManager.AutoPriorityResult result = StorageManager.resolveSdCardAutoPriority(
                5, 2000, /* previouslyOnSdCard= */ true,
                () -> { calls.incrementAndGet(); return true; },
                noopSleeper(sleptFor));

        assertEquals(StorageManager.AutoPriorityResult.MOUNTED, result);
        assertEquals(1, calls.get());
        assertEquals("a first-try success must not sleep at all", 0, sleptFor.size());
    }

    @Test
    public void succeedsOnALaterAttempt_returnsMounted_sleepsBetweenEachFailure() {
        List<Long> sleptFor = new ArrayList<>();
        AtomicInteger calls = new AtomicInteger(0);

        StorageManager.AutoPriorityResult result = StorageManager.resolveSdCardAutoPriority(
                5, 2000, true,
                () -> calls.incrementAndGet() >= 3, // fails attempts 1-2, succeeds on 3
                noopSleeper(sleptFor));

        assertEquals(StorageManager.AutoPriorityResult.MOUNTED, result);
        assertEquals(3, calls.get());
        assertEquals("must sleep once between each failed attempt, stopping once mounted",
                2, sleptFor.size());
    }

    @Test
    public void exhaustsRetries_previouslyOnSdCard_keepsPreferenceAndFlagsError() {
        List<Long> sleptFor = new ArrayList<>();
        AtomicInteger calls = new AtomicInteger(0);

        StorageManager.AutoPriorityResult result = StorageManager.resolveSdCardAutoPriority(
                5, 2000, true,
                () -> { calls.incrementAndGet(); return false; },
                noopSleeper(sleptFor));

        assertEquals("must never silently fall back to internal when the user already had SD_CARD configured",
                StorageManager.AutoPriorityResult.KEEP_SD_CARD_AND_FLAG_ERROR, result);
        assertEquals("must try the full attempt budget before giving up", 5, calls.get());
        assertEquals("must sleep between each attempt but never after the last one",
                4, sleptFor.size());
    }

    @Test
    public void exhaustsRetries_noPriorSdCardPreference_fallsBackToInternal() {
        List<Long> sleptFor = new ArrayList<>();

        StorageManager.AutoPriorityResult result = StorageManager.resolveSdCardAutoPriority(
                5, 2000, /* previouslyOnSdCard= */ false,
                () -> false,
                noopSleeper(sleptFor));

        assertEquals("no existing SD_CARD preference to protect -- this is the ordinary "
                        + "'no SD card ever configured' auto-detect outcome, not an error",
                StorageManager.AutoPriorityResult.FALL_BACK_TO_INTERNAL, result);
    }

    @Test
    public void sleepsTheExactRequestedDuration() {
        List<Long> sleptFor = new ArrayList<>();

        StorageManager.resolveSdCardAutoPriority(3, 2500, false, () -> false, noopSleeper(sleptFor));

        for (long ms : sleptFor) {
            assertEquals(2500L, ms);
        }
    }

    @Test
    public void singleAttemptBudget_failsImmediately_noSleepAtAll() {
        List<Long> sleptFor = new ArrayList<>();

        StorageManager.AutoPriorityResult result = StorageManager.resolveSdCardAutoPriority(
                1, 2000, true, () -> false, noopSleeper(sleptFor));

        assertEquals(StorageManager.AutoPriorityResult.KEEP_SD_CARD_AND_FLAG_ERROR, result);
        assertEquals("a 1-attempt budget must never sleep -- there is no 'between attempts' to wait for",
                0, sleptFor.size());
    }
}
