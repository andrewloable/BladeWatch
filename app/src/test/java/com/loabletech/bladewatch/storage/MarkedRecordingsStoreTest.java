package net.bladewatch.app.storage;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

import java.io.File;
import java.nio.file.Files;

/**
 * BladeWatch-nmao.4: {@link MarkedRecordingsStore} persistence and de-dupe rule, using the
 * package-private file-path constructor so tests never touch the real
 * {@code /data/local/tmp/marked_recordings.json} (which does not exist on a dev machine).
 */
public class MarkedRecordingsStoreTest {

    private File newTempFile() throws Exception {
        File f = Files.createTempFile("marked-recordings-test", ".json").toFile();
        f.delete(); // exercise the "file does not exist yet" load path, like a fresh install
        f.deleteOnExit();
        return f;
    }

    @Test
    public void mark_thenIsMarked_true() throws Exception {
        MarkedRecordingsStore store = new MarkedRecordingsStore(newTempFile());

        store.mark("clip1.mp4");

        assertTrue(store.isMarked("clip1.mp4"));
    }

    @Test
    public void unmarkedFile_isNotMarked() throws Exception {
        MarkedRecordingsStore store = new MarkedRecordingsStore(newTempFile());

        assertFalse(store.isMarked("never-marked.mp4"));
    }

    @Test
    public void mark_persistsAcrossANewInstanceOverTheSameFile() throws Exception {
        File f = newTempFile();
        MarkedRecordingsStore first = new MarkedRecordingsStore(f);
        long ts = first.mark("clip1.mp4");

        MarkedRecordingsStore second = new MarkedRecordingsStore(f);

        assertTrue("mark did not survive reload from the same file", second.isMarked("clip1.mp4"));
        assertEquals(ts, second.getMarkTimestamp("clip1.mp4"));
    }

    @Test
    public void twoMarksOnSameClip_areDeduplicated_keepingTheFirstTimestamp() throws Exception {
        // De-duplicated, not two entries: a mark records "when the thing worth keeping
        // happened", not "when the button was last tapped" -- a double-tap must not move it.
        // The sleep matters: without it, two calls microseconds apart can land in the same
        // System.currentTimeMillis() tick and this assertion passes even if de-dupe is
        // broken -- caught for real via the mutation check (see close reason).
        MarkedRecordingsStore store = new MarkedRecordingsStore(newTempFile());

        long first = store.mark("clip1.mp4");
        Thread.sleep(5);
        long second = store.mark("clip1.mp4");

        assertEquals(first, second);
    }

    @Test
    public void unmarkedFile_hasZeroTimestamp() throws Exception {
        MarkedRecordingsStore store = new MarkedRecordingsStore(newTempFile());

        assertEquals(0L, store.getMarkTimestamp("never-marked.mp4"));
    }
}
