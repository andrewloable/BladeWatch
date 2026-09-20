package net.bladewatch.app.media

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.RecordingsApiHandler
import org.json.JSONObject
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Owns the [RecordingsDatabase] lifecycle and the live-indexing + reconcile logic for
 * recordings / surveillance / proximity clips.
 *
 * Mirrors the `TripAnalyticsManager` ownership model: created, initialised and closed by
 * `CameraDaemon`, reached from recorder/HTTP code via `CameraDaemon.getMediaCatalogManager()`.
 *
 * Live indexing: the recorder finalize paths and the sidecar writer call [indexRecording] so a
 * freshly recorded clip appears in the DB (and thus the UI) without waiting for a sync. Manual
 * sync and the lazy auto-rebuild both call [reconcile] to make the DB exactly match the files
 * on disk.
 */
class MediaCatalogManager {

    private var database: RecordingsDatabase? = null

    private val reconcileInProgress = AtomicBoolean(false)

    // AtomicBoolean so the CAS in ensureIndexedOnce() is lock-free and safe to call from any
    // thread (HTTP workers, background threads).
    private val autoRebuildAttempted = AtomicBoolean(false)

    // ==================== LIFECYCLE ====================

    fun init() {
        database = RecordingsDatabase().also { it.init() }
        logger.info("MediaCatalogManager initialized (available=" + isAvailable + ")")
    }

    fun shutdown() {
        database?.close()
    }

    val isAvailable: Boolean
        get() = database?.isAvailable() == true

    fun getDatabase(): RecordingsDatabase? = database

    // ==================== LIVE INDEXING ====================

    /**
     * Index (insert/update) a single recording. Derives the type from the filename, parses it
     * via the shared `RecordingsApiHandler` parser, and upserts. Best-effort and `synchronized`
     * so the two-phase finalize-then-sidecar upserts for the same path cannot interleave.
     *
     * No-op when the catalog DB is unavailable, the file is missing/empty, or the filename does
     * not match a known recording pattern.
     */
    @Synchronized
    fun indexRecording(mp4File: File?) {
        val db = database
        if (!isAvailable || db == null || mp4File == null) return
        try {
            if (!mp4File.exists() || !mp4File.name.endsWith(".mp4") || mp4File.length() <= 0) {
                return
            }
            val type = classifyType(mp4File.name)
            val parsed = RecordingsApiHandler.parseForIndex(mp4File, type)
                ?: return // not a recognised recording filename
            db.upsert(
                mp4File.absolutePath,
                mp4File.name,
                type,
                parsed.optLong("timestamp", 0L),
                mp4File.length(),
                mp4File.lastModified(),
                sidecarMtime(mp4File),
                parsed.toString()
            )
        } catch (e: Exception) {
            logger.warn("indexRecording failed for " + mp4File.name + ": " + e.message)
        }
    }

    // ==================== RECONCILE ====================

    /**
     * Schedules a one-time background reconcile so the DB mirrors the files on disk. Idempotent
     * — only the first caller ever spawns the thread; subsequent callers return immediately
     * (AtomicBoolean CAS gate).
     *
     * Runs on a daemon background thread so HTTP workers are never blocked by the filesystem
     * scan. Uses [reconcile], NOT `reconcileInternal` directly, so `reconcileInProgress` is
     * always set *before* any snapshot is taken — otherwise a concurrent manual-sync could enter
     * the scan simultaneously.
     */
    fun ensureIndexedOnce() {
        if (!autoRebuildAttempted.compareAndSet(false, true)) return
        if (!isAvailable) return
        logger.info("Media catalog: scheduling background auto-reconcile")
        Thread({ reconcile() }, "media-auto-reconcile").apply {
            isDaemon = true
            start()
        }
    }

    /**
     * Reconcile the DB against the files on disk: add new, update changed (size/mtime/
     * sidecar-mtime), remove rows whose files are gone.
     *
     * Single-flight — a concurrent caller gets a busy result rather than blocking the HTTP
     * worker for the full scan.
     *
     * @return `{success, added, updated, removed, total}`, or `{success:false,
     *         error:"sync_in_progress"}`.
     */
    fun reconcile(): JSONObject {
        if (!isAvailable) return failure("catalog_unavailable")
        if (!reconcileInProgress.compareAndSet(false, true)) return failure("sync_in_progress")
        return try {
            reconcileInternal()
        } finally {
            reconcileInProgress.set(false)
        }
    }

    private fun reconcileInternal(): JSONObject {
        val db = database ?: return failure("catalog_unavailable")
        val m = HashMap<String, Any>()
        var added = 0
        var updated = 0
        var removed = 0
        try {
            // present: absolute path -> type, for every readable, non-empty .mp4
            val present: Map<String, String> = RecordingsApiHandler.scanAllMp4s()
            val dbState: Map<String, LongArray> = db.getAllPathState()

            for ((path, _) in present) {
                val f = File(path)
                val prev = dbState[path]
                if (prev == null) {
                    indexRecording(f)
                    added++
                } else if (prev[0] != f.length() || prev[1] != f.lastModified() ||
                    prev[2] != sidecarMtime(f)
                ) {
                    indexRecording(f)
                    updated++
                }
            }
            for (path in dbState.keys) {
                if (!present.containsKey(path)) {
                    db.deleteByPath(path)
                    removed++
                }
            }
            m["success"] = true
            m["added"] = added
            m["updated"] = updated
            m["removed"] = removed
            m["total"] = present.size
            logger.info(
                "Media reconcile: +" + added + " ~" + updated + " -" + removed +
                    " (total=" + present.size + ")"
            )
        } catch (ex: Exception) {
            logger.error("Media reconcile failed", ex)
            m["success"] = false
            m["error"] = ex.message ?: "unknown"
        }
        return JSONObject(m as Map<*, *>)
    }

    private fun failure(reason: String): JSONObject =
        JSONObject(mapOf<String, Any>("success" to false, "error" to reason) as Map<*, *>)

    companion object {
        private val logger = DaemonLogger.getInstance("MediaCatalogManager")

        /**
         * Classify a recording file by its filename prefix. Matches the type strings used by
         * `RecordingsApiHandler` — "sentry" / "proximity" / "normal".
         */
        @JvmStatic
        fun classifyType(filename: String?): String = when {
            filename == null -> "normal"
            filename.startsWith("event_") -> "sentry"
            filename.startsWith("proximity_") -> "proximity"
            else -> "normal"
        }

        private fun sidecarMtime(mp4File: File): Long {
            val sidecar = File(mp4File.parentFile, mp4File.name.replace(".mp4", ".json"))
            return if (sidecar.exists()) sidecar.lastModified() else 0L
        }
    }
}
