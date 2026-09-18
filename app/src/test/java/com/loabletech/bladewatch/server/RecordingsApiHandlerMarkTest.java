package net.bladewatch.app.server;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import net.bladewatch.app.storage.MarkedRecordingsStore;

import org.json.JSONObject;
import org.junit.Test;

import java.io.File;
import java.nio.file.Files;

/**
 * BladeWatch-nmao.4: the MarkRecording decision logic, extracted as
 * {@code RecordingsApiHandler.buildMarkResponse} so it is testable without a real
 * {@code CameraDaemon}/{@code HardwareEventRecorderGpu} (the caller resolves "current
 * filename" itself and passes it in -- see {@code null} meaning "nothing recording" below).
 */
public class RecordingsApiHandlerMarkTest {

    private MarkedRecordingsStore newStore() throws Exception {
        File f = Files.createTempFile("marked-recordings-handler-test", ".json").toFile();
        f.delete();
        f.deleteOnExit();
        return new MarkedRecordingsStore(f);
    }

    @Test
    public void recordingInFlight_succeedsAndPersistsTheMark() throws Exception {
        MarkedRecordingsStore store = newStore();

        JSONObject response = RecordingsApiHandler.buildMarkResponse("clip1.mp4", store);

        assertTrue(response.getBoolean("success"));
        assertEquals("clip1.mp4", response.getString("filename"));
        assertTrue(store.isMarked("clip1.mp4"));
    }

    @Test
    public void nothingRecording_failsWithReason_andDoesNotThrow() throws Exception {
        MarkedRecordingsStore store = newStore();

        JSONObject response = RecordingsApiHandler.buildMarkResponse(null, store);

        assertFalse(response.getBoolean("success"));
        assertEquals("not_recording", response.getString("reason"));
    }

    @Test
    public void twoMarksOnSameClip_returnTheSameTimestamp() throws Exception {
        MarkedRecordingsStore store = newStore();

        JSONObject first = RecordingsApiHandler.buildMarkResponse("clip1.mp4", store);
        JSONObject second = RecordingsApiHandler.buildMarkResponse("clip1.mp4", store);

        assertEquals(first.getLong("markTimestampMs"), second.getLong("markTimestampMs"));
    }

    @Test
    public void applyMarkedStatus_unmarkedFile_setsMarkedFalse() throws Exception {
        MarkedRecordingsStore store = newStore();
        JSONObject recording = new JSONObject();

        RecordingsApiHandler.applyMarkedStatus(recording, "clip1.mp4", store);

        assertFalse(recording.getBoolean("marked"));
    }

    @Test
    public void applyMarkedStatus_markedFile_setsMarkedTrueWithTimestamp() throws Exception {
        MarkedRecordingsStore store = newStore();
        long ts = store.mark("clip1.mp4");
        JSONObject recording = new JSONObject();

        RecordingsApiHandler.applyMarkedStatus(recording, "clip1.mp4", store);

        assertTrue(recording.getBoolean("marked"));
        assertEquals(ts, recording.getLong("markedAtMs"));
    }
}
