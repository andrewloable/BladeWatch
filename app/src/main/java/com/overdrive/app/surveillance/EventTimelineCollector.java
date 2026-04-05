package com.overdrive.app.surveillance;

import com.overdrive.app.ai.Detection;
import com.overdrive.app.logging.DaemonLogger;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileWriter;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * SOTA Event Timeline Collector — Production Ready
 *
 * Architecture: Inline Coalescing (Span-based)
 * 
 * Instead of storing every raw frame event and coalescing later (which overflows
 * at ~9 minutes at 15 FPS), we coalesce ON THE HOT PATH. The buffer stores
 * FINISHED SPANS, not raw events.
 *
 * Write rate to buffer: ~0.5/sec (one span commit per 2s coalesce window)
 * Buffer capacity: 16384 spans = ~9.1 hours of continuous motion
 * Memory: 16384 * (8+8+1+4+1) bytes = ~360 KB
 *
 * Thread safety:
 * - All mutable state access (ingestEvent, startCollecting, stopAndWrite) is synchronized
 * - stopAndWrite commits the final in-flight span and snapshots arrays under the lock
 * - File I/O runs async on a dedicated MIN_PRIORITY thread, never blocks recording
 *
 * Persistence:
 * - Atomic write via .tmp + renameTo to prevent corrupt JSON on power loss
 *
 * Backward compatible: videos without .json sidecars just show no markers in the UI.
 */
public class EventTimelineCollector {

    private static final DaemonLogger logger = DaemonLogger.getInstance("EventTimeline");

    private static final long COALESCE_MS = 2000;

    // Type constants (byte values for compact storage)
    private static final byte TYPE_MOTION = 0;
    private static final byte TYPE_BIKE   = 1;
    private static final byte TYPE_CAR    = 2;
    private static final byte TYPE_PERSON = 3;
    private static final String[] TYPE_NAMES = {"motion", "bike", "car", "person"};

    // ========================================================================
    // COMMITTED SPAN BUFFER
    // ========================================================================
    // 16384 spans at 0.5 commits/sec = 9.1 hours before overflow.
    private static final int SPAN_CAPACITY = 16384;

    private final long[]  spanStarts      = new long[SPAN_CAPACITY];
    private final long[]  spanEnds        = new long[SPAN_CAPACITY];
    private final byte[]  spanTypes       = new byte[SPAN_CAPACITY];
    private final float[] spanConfidences = new float[SPAN_CAPACITY];
    private final byte[]  spanCounts      = new byte[SPAN_CAPACITY];
    private int spanCount = 0;

    // ========================================================================
    // IN-FLIGHT SPAN (currently being built on the hot path)
    // ========================================================================
    private long   inflightStart = -1;  // -1 = no active span
    private long   inflightEnd   = 0;
    private byte   inflightType  = TYPE_MOTION;
    private float  inflightConf  = 0;
    private byte   inflightCount = 0;

    // State
    private long recordingStartTimeMs = 0;
    private volatile boolean collecting = false;

    // Async writer — daemon thread at MIN_PRIORITY so it never competes with encoder
    private final ExecutorService writeExecutor = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "TimelineWriter");
        t.setDaemon(true);
        t.setPriority(Thread.MIN_PRIORITY);
        return t;
    });

    // ========================================================================
    // LIFECYCLE (all synchronized)
    // ========================================================================

    public synchronized void startCollecting() {
        spanCount = 0;
        inflightStart = -1;
        recordingStartTimeMs = System.currentTimeMillis();
        collecting = true;
        logger.info("Timeline collection started");
    }

    /**
     * Stop collecting and write the JSON sidecar ASYNCHRONOUSLY.
     * 
     * CRITICAL: This method is synchronized to prevent a race with ingestEvent.
     * It commits the final in-flight span and snapshots the arrays under the lock,
     * then releases the lock before async file I/O.
     */
    public synchronized void stopAndWrite(File mp4File) {
        if (!collecting) return;
        collecting = false;

        // Commit any in-flight span while holding the lock
        commitInflight();

        final int count = spanCount;
        if (count == 0) {
            logger.info("No events collected, skipping sidecar write");
            return;
        }

        // Snapshot arrays under the lock (fast arraycopy)
        final long[]  starts = new long[count];
        final long[]  ends   = new long[count];
        final byte[]  types  = new byte[count];
        final float[] confs  = new float[count];
        final byte[]  counts = new byte[count];

        System.arraycopy(spanStarts,      0, starts, 0, count);
        System.arraycopy(spanEnds,        0, ends,   0, count);
        System.arraycopy(spanTypes,       0, types,  0, count);
        System.arraycopy(spanConfidences, 0, confs,  0, count);
        System.arraycopy(spanCounts,      0, counts, 0, count);

        final long durationMs = System.currentTimeMillis() - recordingStartTimeMs;

        // Release lock — file I/O on background thread
        writeExecutor.execute(() -> {
            writeJsonSidecar(mp4File, starts, ends, types, confs, counts, count, durationMs);
        });
    }

    public boolean isCollecting() {
        return collecting;
    }

    // ========================================================================
    // HOT PATH (synchronized — ~30-50ns uncontended on ARM64)
    // ========================================================================

    public void onMotionDetected(int activeBlocks) {
        if (!collecting) return;
        ingestEvent(System.currentTimeMillis() - recordingStartTimeMs,
                TYPE_MOTION, 0f, (byte) 0);
    }

    public void onAiDetection(List<Detection> detections, boolean hasActiveMotion) {
        if (!collecting || !hasActiveMotion || detections == null || detections.isEmpty()) return;

        byte bestType = TYPE_MOTION;
        float bestConf = 0;
        int totalCount = 0;

        for (int i = 0, size = detections.size(); i < size; i++) {
            Detection det = detections.get(i);
            int classId = det.getClassId();
            byte type;

            if (classId == 0)                                    type = TYPE_PERSON;
            else if (classId == 2 || classId == 5 || classId == 7) type = TYPE_CAR;
            else if (classId == 1 || classId == 3)               type = TYPE_BIKE;
            else continue;

            totalCount++;
            if (type > bestType || (type == bestType && det.getConfidence() > bestConf)) {
                bestType = type;
                bestConf = det.getConfidence();
            }
        }

        if (totalCount > 0) {
            ingestEvent(System.currentTimeMillis() - recordingStartTimeMs,
                    bestType, bestConf, (byte) Math.min(totalCount, 127));
        }
    }

    // ========================================================================
    // INLINE COALESCING ENGINE
    // ========================================================================

    /**
     * Core ingest: extends the in-flight span or commits it and starts a new one.
     * In steady state (continuous motion), just updates inflightEnd (~30ns).
     */
    private synchronized void ingestEvent(long relativeMs, byte type, float conf, byte count) {
        if (inflightStart < 0) {
            // No active span — start new
            inflightStart = relativeMs;
            inflightEnd   = relativeMs;
            inflightType  = type;
            inflightConf  = conf;
            inflightCount = count;
            return;
        }

        if (relativeMs - inflightEnd <= COALESCE_MS) {
            // Within coalesce window — extend
            inflightEnd = relativeMs;
            if (type > inflightType) {
                inflightType = type;
                inflightConf = conf;
            } else if (type == inflightType && conf > inflightConf) {
                inflightConf = conf;
            }
            if (count > inflightCount) {
                inflightCount = count;
            }
        } else {
            // Gap > 2s — commit current span, start new
            commitInflight();
            inflightStart = relativeMs;
            inflightEnd   = relativeMs;
            inflightType  = type;
            inflightConf  = conf;
            inflightCount = count;
        }
    }

    /**
     * Commit in-flight span to buffer. MUST be called from synchronized context.
     */
    private void commitInflight() {
        if (inflightStart < 0) return;
        if (spanCount >= SPAN_CAPACITY) {
            // 9+ hours of continuous motion — log once and drop
            if (spanCount == SPAN_CAPACITY) {
                logger.warn("Timeline buffer full (" + SPAN_CAPACITY + " spans). Dropping.");
            }
            inflightStart = -1;
            return;
        }

        int idx = spanCount;
        spanStarts[idx]      = inflightStart;
        spanEnds[idx]        = inflightEnd;
        spanTypes[idx]       = inflightType;
        spanConfidences[idx] = inflightConf;
        spanCounts[idx]      = inflightCount;
        spanCount = idx + 1;
        inflightStart = -1;
    }

    // ========================================================================
    // COLD PATH — Async file I/O, never blocks recording
    // ========================================================================

    /**
     * Write JSON sidecar. Atomic via .tmp + renameTo to survive power loss.
     */
    private void writeJsonSidecar(File mp4File, long[] starts, long[] ends,
                                   byte[] types, float[] confs, byte[] counts,
                                   int count, long durationMs) {
        try {
            JSONObject root = new JSONObject();
            root.put("version", 1);
            root.put("durationMs", durationMs);

            JSONArray eventsArray = new JSONArray();
            int motionN = 0, personN = 0, carN = 0, bikeN = 0;

            for (int i = 0; i < count; i++) {
                JSONObject ev = new JSONObject();
                ev.put("start", starts[i]);
                ev.put("end", ends[i]);

                String typeName = TYPE_NAMES[types[i]];
                ev.put("type", typeName);

                if (confs[i] > 0) {
                    ev.put("maxConf", Math.round(confs[i] * 100) / 100.0);
                }
                int cnt = counts[i] & 0xFF;
                if (cnt > 1) {
                    ev.put("maxCount", cnt);
                }
                eventsArray.put(ev);

                switch (typeName) {
                    case "person": personN++; break;
                    case "car":    carN++;    break;
                    case "bike":   bikeN++;   break;
                    default:       motionN++; break;
                }
            }

            root.put("events", eventsArray);

            JSONObject stats = new JSONObject();
            stats.put("motion", motionN);
            stats.put("person", personN);
            stats.put("car", carN);
            stats.put("bike", bikeN);
            root.put("stats", stats);

            // Atomic write: .tmp -> rename
            String jsonName = mp4File.getName().replace(".mp4", ".json");
            File jsonFile = new File(mp4File.getParentFile(), jsonName);
            File tmpFile = new File(jsonFile.getAbsolutePath() + ".tmp");

            try (FileWriter fw = new FileWriter(tmpFile)) {
                fw.write(root.toString());
            }

            if (!tmpFile.renameTo(jsonFile)) {
                // renameTo can fail on some Android filesystems — fallback to direct write
                try (FileWriter fw = new FileWriter(jsonFile)) {
                    fw.write(root.toString());
                }
                tmpFile.delete();
            }

            jsonFile.setReadable(true, false);

            logger.info(String.format("Timeline saved: %s (%d spans, duration=%ds)",
                    jsonFile.getName(), count, durationMs / 1000));

        } catch (Exception e) {
            logger.error("Failed to write timeline JSON: " + e.getMessage(), e);
        }
    }
}
