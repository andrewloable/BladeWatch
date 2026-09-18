package net.bladewatch.app.storage;

import net.bladewatch.app.logging.DaemonLogger;

import org.json.JSONObject;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Persists which recorded clips the owner has bookmarked via {@code MarkRecording}
 * (BladeWatch-nmao.4). A mark is metadata only -- it never starts a new file, splits, or
 * copies a clip -- and marked files must be skipped by {@code StorageManager}'s automatic
 * cleanup sweep (see {@code ensureSpace}).
 */
public final class MarkedRecordingsStore {

    private static final DaemonLogger logger = DaemonLogger.getInstance("MarkedRecordingsStore");
    private static final String DEFAULT_PATH = "/data/local/tmp/marked_recordings.json";

    private static volatile MarkedRecordingsStore instance;

    public static MarkedRecordingsStore getInstance() {
        if (instance == null) {
            synchronized (MarkedRecordingsStore.class) {
                if (instance == null) {
                    instance = new MarkedRecordingsStore(new File(DEFAULT_PATH));
                }
            }
        }
        return instance;
    }

    private final File file;
    private final Map<String, Long> marks = new ConcurrentHashMap<>();

    /** Visible for testing an isolated store; production code always uses {@link #getInstance()}. */
    public MarkedRecordingsStore(File file) {
        this.file = file;
        load();
    }

    /**
     * Marks a filename. Idempotent: a filename already marked keeps its ORIGINAL timestamp --
     * a mark records "when the thing worth keeping happened", not "when the button was last
     * tapped", so a double-tap on the same clip must not move it.
     *
     * @return the mark timestamp: the new one, or the pre-existing one if already marked.
     */
    public synchronized long mark(String filename) {
        Long existing = marks.get(filename);
        if (existing != null) return existing;
        long now = System.currentTimeMillis();
        marks.put(filename, now);
        save();
        return now;
    }

    public boolean isMarked(String filename) {
        return marks.containsKey(filename);
    }

    /** Epoch ms the filename was marked at, or 0 if it was never marked. */
    public long getMarkTimestamp(String filename) {
        Long t = marks.get(filename);
        return t != null ? t : 0L;
    }

    private synchronized void load() {
        if (!file.exists()) return;
        try (FileReader r = new FileReader(file)) {
            StringBuilder sb = new StringBuilder();
            char[] buf = new char[4096];
            int n;
            while ((n = r.read(buf)) > 0) sb.append(buf, 0, n);
            JSONObject root = new JSONObject(sb.toString());
            java.util.Iterator<String> keys = root.keys();
            while (keys.hasNext()) {
                String name = keys.next();
                marks.put(name, root.optLong(name, 0L));
            }
        } catch (Exception e) {
            logger.warn("Failed to load marked recordings: " + e.getMessage());
        }
    }

    private synchronized void save() {
        try {
            JSONObject root = new JSONObject();
            for (Map.Entry<String, Long> e : marks.entrySet()) {
                root.put(e.getKey(), e.getValue());
            }
            File parent = file.getParentFile();
            if (parent != null && !parent.exists()) parent.mkdirs();
            File tmp = new File(file.getAbsolutePath() + ".tmp");
            try (FileWriter w = new FileWriter(tmp)) {
                w.write(root.toString());
            }
            if (!tmp.renameTo(file)) {
                try (FileWriter w = new FileWriter(file)) {
                    w.write(root.toString());
                }
                tmp.delete();
            }
            file.setReadable(true, false);
            file.setWritable(true, false);
        } catch (Exception e) {
            logger.warn("Failed to save marked recordings: " + e.getMessage());
        }
    }
}
