package net.bladewatch.app.storage

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject
import java.io.File
import java.io.FileReader
import java.io.FileWriter
import java.util.concurrent.ConcurrentHashMap

/**
 * Persists which recorded clips the owner has bookmarked via `MarkRecording` (BladeWatch-nmao.4).
 *
 * A mark is metadata only — it never starts a new file, splits, or copies a clip — and marked
 * files must be skipped by StorageManager's automatic cleanup sweep (see `ensureSpace`).
 *
 * @param file visible for testing an isolated store; production code always uses [getInstance].
 */
class MarkedRecordingsStore(private val file: File) {

    private val marks: MutableMap<String, Long> = ConcurrentHashMap()

    init {
        load()
    }

    /**
     * Mark a filename. Idempotent: a filename already marked keeps its ORIGINAL timestamp — a mark
     * records "when the thing worth keeping happened", not "when the button was last tapped", so a
     * double-tap on the same clip must not move it.
     *
     * @return the mark timestamp: the new one, or the pre-existing one if already marked.
     */
    @Synchronized
    fun mark(filename: String): Long {
        marks[filename]?.let { return it }
        val now = System.currentTimeMillis()
        marks[filename] = now
        save()
        return now
    }

    fun isMarked(filename: String): Boolean = marks.containsKey(filename)

    /** Epoch ms the filename was marked at, or 0 if it was never marked. */
    fun getMarkTimestamp(filename: String): Long = marks[filename] ?: 0L

    @Synchronized
    private fun load() {
        if (!file.exists()) return
        try {
            FileReader(file).use { r ->
                val sb = StringBuilder()
                val buf = CharArray(4096)
                while (true) {
                    val n = r.read(buf)
                    if (n <= 0) break
                    sb.append(buf, 0, n)
                }
                val root = JSONObject(sb.toString())
                val keys = root.keys()
                while (keys.hasNext()) {
                    val name = keys.next()
                    marks[name] = root.optLong(name, 0L)
                }
            }
        } catch (e: Exception) {
            logger.warn("Failed to load marked recordings: " + e.message)
        }
    }

    @Synchronized
    private fun save() {
        try {
            val root = JSONObject()
            for ((key, value) in marks) {
                root.put(key, value)
            }
            val parent = file.parentFile
            if (parent != null && !parent.exists()) parent.mkdirs()
            val tmp = File(file.absolutePath + ".tmp")
            FileWriter(tmp).use { w -> w.write(root.toString()) }
            if (!tmp.renameTo(file)) {
                FileWriter(file).use { w -> w.write(root.toString()) }
                tmp.delete()
            }
            file.setReadable(true, false)
            file.setWritable(true, false)
        } catch (e: Exception) {
            logger.warn("Failed to save marked recordings: " + e.message)
        }
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("MarkedRecordingsStore")
        private const val DEFAULT_PATH = "/data/local/tmp/marked_recordings.json"

        @Volatile
        private var instance: MarkedRecordingsStore? = null

        @JvmStatic
        fun getInstance(): MarkedRecordingsStore {
            instance?.let { return it }
            return synchronized(MarkedRecordingsStore::class.java) {
                instance ?: MarkedRecordingsStore(File(DEFAULT_PATH)).also { instance = it }
            }
        }
    }
}
