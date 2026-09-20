package net.bladewatch.app.server

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.media.RecordingsDatabase
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.storage.MarkedRecordingsStore
import net.bladewatch.app.storage.StorageManager
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.FileReader
import java.io.OutputStream
import java.nio.charset.StandardCharsets
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Collections
import java.util.Date
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.regex.Pattern
import kotlin.math.ceil
import kotlin.math.min
import kotlin.math.roundToLong

/**
 * Serves the recording list, metadata and video/thumbnail files.
 *
 * Uses StorageManager for the dedicated BladeWatch directories with size limits.
 *
 * BladeWatch-6mnq: the JSON dispatch lived here — it matched /api/recordings, /api/events/ and
 * also /thumb/ and /video/ (which [handleWithRange] already covers properly, with Range and ETag
 * support), then wrote JSON into an OutputStream the Connect layer captured back out. Every JSON
 * operation RETURNS its JSON now, and its filters are arguments rather than query-string
 * fragments.
 *
 * [handleWithRange] is DELIBERATELY still HTTP: /video/ and /thumb/ are byte ranges for a player
 * and an `<img src>`, which a browser fetches directly and which ConnectRPC cannot serve.
 */
object RecordingsApiHandler {

    // Thumbnail cache directory — the parent of the recordings dir
    private fun getThumbnailCacheDir(): String {
        val recordingsDir = File(StorageManager.getInstance().recordingsPath)
        return File(recordingsDir.parentFile, "thumbs").absolutePath
    }

    private fun getRecordingsDir(): String = StorageManager.getInstance().recordingsPath

    private fun getSentryDir(): String = StorageManager.getInstance().surveillancePath

    // Legacy paths for backward compatibility (migration)
    private const val LEGACY_RECORDINGS_DIR =
        "/storage/emulated/0/Android/data/net.bladewatch.app/files"
    private const val LEGACY_SENTRY_DIR = "$LEGACY_RECORDINGS_DIR/sentry_events"

    // Filename patterns (support an optional _N segment suffix for multi-segment recordings)
    private val CAM_PATTERN: Pattern =
        Pattern.compile("cam(\\d+)?_(\\d{8})_(\\d{6})(?:_\\d+)?\\.mp4")
    private val EVENT_PATTERN: Pattern =
        Pattern.compile("event_(\\d{8})_(\\d{6})(?:_\\d+)?\\.mp4")
    private val PROXIMITY_PATTERN: Pattern =
        Pattern.compile("proximity_(\\d{8})_(\\d{6})(?:_\\d+)?\\.mp4")
    private val DATE_FORMAT = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US)

    /**
     * Per-recording cache keyed by absolute mp4 path. Validated against (mp4 length + mp4 mtime +
     * sidecar mtime); any change invalidates.
     *
     * Without this, every list call (the UI auto-refresh polls it) re-scans and re-parses every
     * JSON sidecar from disk — a directory of 1000 recordings means 1000 sidecar reads per poll.
     * The cache turns the steady-state cost into one File.exists() plus two lastModified() calls
     * per recording.
     */
    private val RECORDING_CACHE = ConcurrentHashMap<String, CachedRecording>()

    /**
     * Drop a cache entry for the given mp4 absolute path. Callers outside this class (loop
     * rotation in HardwareEventRecorderGpu, the Kotlin RecordingScanner, manual SD-card
     * maintenance) should call this when they delete an .mp4 so the list doesn't return phantom
     * entries. No-op when the key isn't present.
     */
    @JvmStatic
    fun invalidateRecordingCache(absMp4Path: String?) {
        if (absMp4Path == null) return
        RECORDING_CACHE.remove(absMp4Path)
    }

    /**
     * Periodic prune. Removes entries whose underlying .mp4 no longer exists. Call from a
     * long-running daemon's hourly maintenance pass to keep the cache from growing unbounded
     * across months of uptime.
     */
    @JvmStatic
    fun pruneRecordingCache() {
        val it = RECORDING_CACHE.entries.iterator()
        var removed = 0
        while (it.hasNext()) {
            val e = it.next()
            if (!File(e.key).exists()) {
                it.remove()
                removed++
            }
        }
        if (removed > 0) {
            CameraDaemon.log("RECORDING_CACHE pruned $removed stale entries")
        }
    }

    private class CachedRecording(
        val mp4Length: Long,
        val mp4Mtime: Long,
        /** 0 if absent. */
        val sidecarMtime: Long,
        /** Serialised JSONObject — cheaper to clone than to rebuild. */
        val json: String
    )

    /**
     * Handle the two byte-serving routes with Range support for video seeking and conditional GET
     * (If-None-Match) for ETag-based 304 responses on cached recordings.
     *
     * BladeWatch-qrcj: the /thumb/ branch below is load-bearing. HttpServer sends BOTH prefixes
     * here, and when the JSON dispatch was removed in BladeWatch-6mnq the thumbnail branch went
     * with it — leaving every `<img src="/thumb/...">` and every Web Push hero image 404ing while
     * serveThumbnail sat unreachable. RecordingsRouteCoverageTest pins that both prefixes are
     * still handled.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun handleWithRange(
        method: String,
        path: String,
        body: String?,
        rangeHeader: String?,
        ifNoneMatchHeader: String?,
        out: OutputStream
    ): Boolean {
        if (path.startsWith("/video/")) {
            streamVideo(out, path.substring(7), rangeHeader, ifNoneMatchHeader)
            return true
        }
        if (path.startsWith("/thumb/")) {
            serveThumbnail(out, path.substring(7))
            return true
        }
        // Only /video/ and /thumb/ reach here — HttpServer routes nothing else to this method
        // since the JSON dispatch was removed (BladeWatch-6mnq).
        return false
    }

    // Background thumbnail generator
    private val thumbExecutor = Executors.newSingleThreadExecutor()
    private val pendingThumbs: MutableSet<String> =
        Collections.synchronizedSet(HashSet<String>())

    /**
     * Serve a cached thumbnail for a video file. Returns a 202 immediately if not cached, and
     * generates it in the background.
     *
     * The 202 header block is built from CONCATENATED string literals on purpose:
     * ResponseFramingTest reads it as source text.
     */
    @Throws(Exception::class)
    private fun serveThumbnail(out: OutputStream, filename: String) {
        // Security: prevent path traversal
        if (filename.contains("..") || filename.contains("/")) {
            HttpResponse.sendError(out, 400, Messages.get("errors.recordings_invalid_filename"))
            return
        }

        // Direct sidecar JPEG hits — heroes ("event_xxx.jpg") or per-actor
        // ("thumb_event_xxx_a17_9300.jpg") written by ThumbnailBuffer next to the MP4. Looking
        // these up here means the events page can use a single URL shape (/thumb/<filename>) for
        // both video-frame and AI thumbnails.
        if (filename.lowercase(Locale.US).endsWith(".jpg")) {
            val jpegFile = findSiblingJpeg(filename)
            if (jpegFile != null && jpegFile.exists() && jpegFile.length() > 0) {
                HttpResponse.sendImage(out, jpegFile, "image/jpeg")
                return
            }
            HttpResponse.sendError(
                out, 404,
                Messages.get("errors.recordings_thumbnail_not_found_with_filename", filename)
            )
            return
        }

        // Check the cache first
        val cacheDir = File(getThumbnailCacheDir())
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }

        val thumbName = filename.replace(".mp4", ".jpg")
        val thumbFile = File(cacheDir, thumbName)

        // If a v3 hero JPEG exists alongside the MP4, prefer it: it's the peak-severity moment
        // captured during the recording rather than a generic frame at +1s. Backwards-compatible —
        // legacy clips without a hero file fall through to the cache + MediaMetadataRetriever path.
        val heroSibling = findSiblingJpeg(thumbName)
        if (heroSibling != null && heroSibling.exists() && heroSibling.length() > 0) {
            HttpResponse.sendImage(out, heroSibling, "image/jpeg")
            return
        }

        // If a cached thumbnail exists and is valid, serve it immediately
        if (thumbFile.exists() && thumbFile.length() > 0) {
            HttpResponse.sendImage(out, thumbFile, "image/jpeg")
            return
        }

        // Find the source video file. allowInFlightTmp=true so a notification tapped within
        // seconds of motion still gets a hero image: MediaMetadataRetriever can read sync frames
        // from <name>.mp4.tmp before the muxer finalises the moov atom on close.
        val videoFile = findVideoFile(filename, true)
        if (videoFile == null) {
            HttpResponse.sendError(
                out, 404,
                Messages.get("errors.recordings_video_not_found_with_filename", filename)
            )
            return
        }

        // Queue background generation if not already pending. add() returns false when the element
        // was already present, so a single atomic call avoids the check-then-act race where two
        // concurrent requests both pass contains() and submit overlapping FileOutputStreams to the
        // same thumb file.
        if (pendingThumbs.add(filename)) {
            thumbExecutor.submit {
                try {
                    val data = generateThumbnail(videoFile)
                    if (data != null) {
                        FileOutputStream(thumbFile).use { fos -> fos.write(data) }
                    }
                } catch (e: Exception) {
                    CameraDaemon.log("Background thumb gen failed: " + e.message)
                } finally {
                    pendingThumbs.remove(filename)
                }
            }
        }

        // Return 202 Accepted with a retry hint — the client should retry
        val body = "{\"status\":\"generating\"}".toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 202 Accepted\r\n" +
            "Content-Type: application/json\r\n" +
            "Retry-After: 1\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            HttpResponse.connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray(StandardCharsets.UTF_8))
        out.write(body)
        out.flush()
    }

    /**
     * Generate a thumbnail from a video file using MediaMetadataRetriever. Extracts the frame at
     * the 1 second mark and scales it to 320x180.
     */
    private fun generateThumbnail(videoFile: File): ByteArray? {
        val retriever = MediaMetadataRetriever()
        // setDataSource(String) calls ActivityThread.currentApplication().getPackageManager() for
        // the MIME lookup. The daemon has no registered Application, so that NPEs on DiLink5. The
        // FileDescriptor overload skips the package-manager probe entirely.
        return try {
            FileInputStream(videoFile).use { fis ->
                retriever.setDataSource(fis.fd)

                // Frame at 1 second (1,000,000 microseconds), falling back to 0
                var frame = retriever.getFrameAtTime(
                    1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                )
                if (frame == null) {
                    frame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                }

                if (frame == null) {
                    null
                } else {
                    // Scale down to thumbnail size (320x180 for 16:9)
                    val scaled = Bitmap.createScaledBitmap(frame, 320, 180, true)

                    val baos = ByteArrayOutputStream()
                    scaled.compress(Bitmap.CompressFormat.JPEG, 75, baos)

                    if (scaled !== frame) {
                        scaled.recycle()
                    }
                    frame.recycle()

                    baos.toByteArray()
                }
            }
        } catch (e: Exception) {
            CameraDaemon.log("Thumbnail generation failed: " + e.message)
            null
        } finally {
            try {
                retriever.release()
            } catch (e: Exception) {
                CameraDaemon.log("retriever.release() failed: " + e.message)
            }
        }
    }

    /**
     * Reports whether a given filename is currently being written by the encoder as
     * `<filename>.tmp`. Used by the events page to display a pinned "Recording in progress"
     * placeholder when the user taps a notification before the post-record window finalises the
     * file.
     *
     * `inflight=false` can mean either "the file finished and was renamed" (success) or "no such
     * recording exists" — the caller already reloads the recordings list when the probe flips, so
     * the success and not-found branches converge in the UI.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun inflightStatus(filename: String?): JSONObject {
        // Security: prevent path traversal
        if (filename.isNullOrEmpty() || filename.contains("..") || filename.contains("/")) {
            throw ConnectException(
                "invalid_argument", Messages.get("errors.recordings_invalid_filename")
            )
        }
        val tmp = findInflightTmp(filename)
        val json = JSONObject()
        try {
            json.put("filename", filename)
            json.put("inflight", tmp != null)
            if (tmp != null) {
                json.put("sizeBytes", tmp.length())
            }
        } catch (ignored: Exception) {
            CameraDaemon.log("Failed to build inflight status JSON: " + ignored.message)
        }
        return json
    }

    /**
     * Locate `<filename>.tmp` across all recording storage roots. Returns null when no in-flight
     * write is happening.
     */
    private fun findInflightTmp(filename: String): File? =
        firstReadableIn(allMediaDirs(), "$filename.tmp")

    /** The active + alternate directories for all three media types, in search order. */
    private fun allMediaDirs(): List<File> {
        val sm = StorageManager.getInstance()
        val dirs = ArrayList<File>()
        dirs.addAll(sm.allRecordingsDirs)
        dirs.addAll(sm.allSurveillanceDirs)
        dirs.addAll(sm.allProximityDirs)
        return dirs
    }

    /** The first directory in [dirs] holding a readable, non-empty [name], or null. */
    private fun firstReadableIn(dirs: List<File>, name: String): File? {
        for (dir in dirs) {
            val f = File(dir, name)
            if (f.exists() && f.canRead() && f.length() > 0) return f
        }
        return null
    }

    /**
     * Bookmarks the recording currently being written. Read-only with respect to the recording
     * pipeline itself — this only resolves which file is live and hands it to
     * [MarkedRecordingsStore] (BladeWatch-nmao.4).
     */
    @JvmStatic
    @Throws(Exception::class)
    fun markRecording(): JSONObject =
        buildMarkResponse(currentRecordingFilename(), MarkedRecordingsStore.getInstance())

    /** The base filename currently being written by the shared encoder, or null if none. */
    private fun currentRecordingFilename(): String? = try {
        CameraDaemon.getGpuPipeline()?.encoder?.currentRecordingFilename
    } catch (e: Exception) {
        CameraDaemon.log("currentRecordingFilename failed: " + e.message)
        null
    }

    /**
     * Pure decision: given the currently-recording filename (or null if nothing is recording),
     * mark it and build the response JSON. Extracted from [markRecording] so the
     * in-flight/not-recording branches and the mark-persists behaviour are testable without a real
     * CameraDaemon.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun buildMarkResponse(
        currentFilename: String?,
        store: MarkedRecordingsStore
    ): JSONObject {
        val json = JSONObject()
        if (currentFilename == null) {
            json.put("success", false)
            json.put("reason", "not_recording")
            return json
        }
        json.put("success", true)
        json.put("filename", currentFilename)
        json.put("markTimestampMs", store.mark(currentFilename))
        return json
    }

    /** Adds `marked`/`markedAtMs` to a recording's JSON from the marked-recordings store. */
    @JvmStatic
    @Throws(Exception::class)
    fun applyMarkedStatus(
        recording: JSONObject,
        filename: String,
        store: MarkedRecordingsStore
    ) {
        val marked = store.isMarked(filename)
        recording.put("marked", marked)
        if (marked) {
            recording.put("markedAtMs", store.getMarkTimestamp(filename))
        }
    }

    /**
     * Find a video file across all storage locations, using StorageManager to get every possible
     * directory rather than hardcoding paths.
     *
     * @param allowInFlightTmp when true, fall through to `<filename>.tmp` for files still being
     *   written by HardwareEventRecorderGpu. Useful for thumbnail generation
     *   (MediaMetadataRetriever reads frames without needing the moov atom). NOT safe for video
     *   streaming — a .tmp lacks the moov atom and the `<video>` element will fail to load it, so
     *   streaming MUST use the default false.
     */
    @JvmOverloads
    private fun findVideoFile(filename: String, allowInFlightTmp: Boolean = false): File? {
        val dirs = allMediaDirs() + File(LEGACY_RECORDINGS_DIR) + File(LEGACY_SENTRY_DIR)
        firstReadableIn(dirs, filename)?.let { return it }

        // In-flight fallback (thumbnails only): a notification fires the moment startRecording()
        // returns, but the file on disk is still <name>.mp4.tmp until closeEventRecording()
        // finishes (10-15s post-record). Without this fallback, a tap within that window fetches
        // /thumb/<name> and gets 404, so the push notification banner shows no hero image. NOT
        // enabled for video streaming, because a .tmp lacks the moov atom.
        if (allowInFlightTmp) {
            return firstReadableIn(allMediaDirs(), "$filename.tmp")
        }

        return null
    }

    /**
     * Locate a JPEG sibling next to a recording. Used to serve hero / per-actor thumbnails that
     * ThumbnailBuffer writes alongside the MP4. Same security and directory-search rules as
     * [findVideoFile].
     */
    private fun findSiblingJpeg(jpegName: String?): File? {
        if (jpegName.isNullOrEmpty()) return null
        if (jpegName.contains("..") || jpegName.contains("/")) return null
        val dirs = allMediaDirs() + File(LEGACY_RECORDINGS_DIR) + File(LEGACY_SENTRY_DIR)
        return firstReadableIn(dirs, jpegName)
    }

    private fun splitCsvLower(csv: String?): Set<String> {
        if (csv.isNullOrEmpty()) return emptySet()
        return csv.split(",")
            .map { it.trim().lowercase(Locale.US) }
            .filter { it.isNotEmpty() }
            .toSet()
    }

    private fun splitCsvUpper(csv: String?): Set<String> {
        if (csv.isNullOrEmpty()) return emptySet()
        return csv.split(",")
            .map { it.trim().uppercase(Locale.US) }
            .filter { it.isNotEmpty() }
            .toSet()
    }

    /** List all recordings with optional filters and pagination. */
    @JvmStatic
    @Throws(Exception::class)
    fun listRecordings(
        typeFilter: String?,
        dateFilter: String?,
        page: Int,
        pageSize: Int,
        classFilter: String?,
        severityFilter: String?,
        proximityFilter: String?
    ): JSONObject {
        // DB-first: serve from the media catalog when available, falling back to a live filesystem
        // scan (which is also the catalog's rebuild source). The remaining post-processing (sort,
        // dedup, filter, paginate) is identical regardless of source.
        val recordings = gatherRecordings(typeFilter, dateFilter).toMutableList()

        // Sort by timestamp descending (newest first)
        recordings.sortWith { a, b ->
            b.optLong("timestamp", 0).compareTo(a.optLong("timestamp", 0))
        }

        // Deduplicate by filename — the same file may appear from multiple scan locations (e.g. SD
        // card + internal storage fallback). Keep the first occurrence (largest/newest).
        val seenFilenames = HashSet<String>()
        recordings.removeIf { !seenFilenames.add(it.optString("filename", "")) }

        // v3 filters: each filter is comma-separated; a recording must match at least one value in
        // each non-empty filter. Static actors (parked cars, idle people) are intentionally
        // excluded — chips surface threats, not scenery.
        val classSet = splitCsvLower(classFilter)
        val sevSet = splitCsvUpper(severityFilter)
        val proxSet = splitCsvUpper(proximityFilter)
        if (classSet.isNotEmpty() || sevSet.isNotEmpty() || proxSet.isNotEmpty()) {
            recordings.removeIf { rec ->
                if (sevSet.isNotEmpty()) {
                    val sev = rec.optString("peakSeverity", "")
                    if (sev.isEmpty() || !sevSet.contains(sev)) return@removeIf true
                }
                if (proxSet.isNotEmpty()) {
                    val prox = rec.optString("peakProximity", "")
                    if (prox.isEmpty() || !proxSet.contains(prox)) return@removeIf true
                }
                if (classSet.isNotEmpty()) {
                    val actors = rec.optJSONArray("actors")
                    if (actors == null || actors.length() == 0) return@removeIf true
                    var any = false
                    for (i in 0 until actors.length()) {
                        val a = actors.optJSONObject(i) ?: continue
                        if (classSet.contains(a.optString("class", "").lowercase(Locale.US))) {
                            any = true
                            break
                        }
                    }
                    if (!any) return@removeIf true
                }
                false
            }
        }

        // Pagination
        val totalCount = recordings.size
        var totalPages = ceil(totalCount.toDouble() / pageSize).toInt()
        if (totalPages == 0) totalPages = 1

        // Clamp the page to the valid range
        val clampedPage = page.coerceAtLeast(1).coerceAtMost(totalPages)

        val startIndex = (clampedPage - 1) * pageSize
        val endIndex = min(startIndex + pageSize, totalCount)

        val pageRecordings = if (startIndex < totalCount) {
            recordings.subList(startIndex, endIndex)
        } else {
            emptyList()
        }

        val response = JSONObject()
        response.put("success", true)
        response.put("recordings", JSONArray(pageRecordings))
        response.put("totalCount", totalCount)
        response.put("totalPages", totalPages)
        response.put("page", clampedPage)
        response.put("pageSize", pageSize)

        return response
    }

    // ==================== MEDIA CATALOG (H2) INTEGRATION ====================

    /** The media catalog DB, or null when the daemon/manager isn't up yet. */
    private fun mediaDb(): RecordingsDatabase? = CameraDaemon.getMediaCatalogManager()?.getDatabase()

    /**
     * Parse one recording (mp4 + optional sidecar) into the API JSON shape, bypassing the
     * in-memory list cache. Used by MediaCatalogManager to index a clip into the H2 catalog — one
     * parser keeps live indexing and the filesystem rebuild in lockstep (no schema drift).
     */
    @JvmStatic
    fun parseForIndex(file: File, type: String): JSONObject? = parseRecordingUncached(file, type)

    /**
     * Scan every recording storage root (active + alternate + legacy) and return absolute-path to
     * type for each readable, non-empty .mp4. The single source of truth for "what files exist",
     * shared by the reconcile/sync and the filesystem fallback so they always agree.
     */
    @JvmStatic
    fun scanAllMp4s(): Map<String, String> {
        val present = HashMap<String, String>()
        val sm = StorageManager.getInstance()
        for (dir in sm.allRecordingsDirs) collectMp4s(dir, "normal", present)
        collectMp4s(File(LEGACY_RECORDINGS_DIR), "normal", present)
        for (dir in sm.allSurveillanceDirs) collectMp4s(dir, "sentry", present)
        collectMp4s(File(LEGACY_SENTRY_DIR), "sentry", present)
        for (dir in sm.allProximityDirs) collectMp4s(dir, "proximity", present)
        return present
    }

    private fun collectMp4s(dir: File?, type: String, present: MutableMap<String, String>) {
        if (dir == null || !dir.exists() || !dir.isDirectory || !dir.canRead()) return
        val files = dir.listFiles { _, name -> name.endsWith(".mp4") } ?: return
        for (f in files) {
            if (!f.canRead() || f.length() <= 0) continue
            // First writer wins per absolute path; the type derives from the dir.
            present.putIfAbsent(f.absolutePath, type)
        }
    }

    /**
     * Inclusive-exclusive [start, end) epoch-ms window for a YYYY-MM-DD filter, or the full range
     * when no filter is supplied.
     *
     * Returns {0L, 0L} (an empty range, so zero results) for a malformed filter, so the caller
     * receives an empty list rather than the entire recording library. That makes the bad-input
     * case visible to the client.
     */
    private fun dateRangeMs(dateFilter: String?): LongArray {
        if (dateFilter.isNullOrBlank()) {
            return longArrayOf(0L, Long.MAX_VALUE)
        }
        return try {
            val parts = dateFilter.trim().split("-")
            if (parts.size != 3) {
                CameraDaemon.log("Invalid date filter (expected YYYY-MM-DD): $dateFilter")
                longArrayOf(0L, 0L)
            } else {
                val cal = Calendar.getInstance()
                cal.set(
                    parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt(), 0, 0, 0
                )
                cal.set(Calendar.MILLISECOND, 0)
                val start = cal.timeInMillis
                cal.add(Calendar.DAY_OF_MONTH, 1)
                longArrayOf(start, cal.timeInMillis)
            }
        } catch (e: Exception) {
            CameraDaemon.log("Invalid date filter: $dateFilter")
            longArrayOf(0L, 0L)
        }
    }

    /**
     * Gather recordings DB-first (with a lazy auto-rebuild when empty), falling back to a live
     * filesystem scan.
     */
    private fun gatherRecordings(typeFilter: String?, dateFilter: String?): List<JSONObject> {
        val db = mediaDb()
        if (db != null && db.isAvailable()) {
            // Trigger a background reconcile on the first call (a no-op after that). Handles both
            // the fully-empty DB and the partial-index case.
            CameraDaemon.getMediaCatalogManager()?.ensureIndexedOnce()
            if (db.getCount() > 0) {
                val range = dateRangeMs(dateFilter)
                val result = db.getRecordings(typeFilter, range[0], range[1]).toMutableList()
                // Remove phantom entries whose physical file has been deleted but whose DB row
                // wasn't pruned (e.g. deleteByPath threw after file.delete()).
                result.removeIf {
                    val p = it.optString("path", "")
                    p.isNotEmpty() && !File(p).exists()
                }
                return result
            }
        }
        return gatherFromFilesystem(typeFilter, dateFilter)
    }

    /** Live filesystem scan (the catalog rebuild source and the ultimate fallback). */
    private fun gatherFromFilesystem(
        typeFilter: String?,
        dateFilter: String?
    ): List<JSONObject> {
        val recordings = ArrayList<JSONObject>()
        val sm = StorageManager.getInstance()

        // Normal recordings from ALL locations (active + alternate + legacy)
        if (typeFilter == null || typeFilter == "normal") {
            for (dir in sm.allRecordingsDirs) {
                scanDirectory(dir, "normal", recordings, dateFilter)
            }
            val legacyDir = File(LEGACY_RECORDINGS_DIR)
            if (legacyDir.exists()) {
                scanDirectory(legacyDir, "normal", recordings, dateFilter)
            }
        }

        // Sentry events from ALL locations (active + alternate + legacy)
        if (typeFilter == null || typeFilter == "sentry") {
            for (dir in sm.allSurveillanceDirs) {
                scanDirectory(dir, "sentry", recordings, dateFilter)
            }
            val legacySentryDir = File(LEGACY_SENTRY_DIR)
            if (legacySentryDir.exists()) {
                scanDirectory(legacySentryDir, "sentry", recordings, dateFilter)
            }
        }

        // Proximity events from ALL locations (active + alternate)
        if (typeFilter == null || typeFilter == "proximity") {
            for (dir in sm.allProximityDirs) {
                scanDirectory(dir, "proximity", recordings, dateFilter)
            }
        }
        return recordings
    }

    /**
     * Reconcile the media catalog DB with the files on disk (add/update/remove) so the DB is
     * exactly 1:1 with storage.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun syncCatalog(): JSONObject {
        val mcm = CameraDaemon.getMediaCatalogManager()
        return if (mcm == null || !mcm.isAvailable) {
            val response = JSONObject()
            response.put("success", false)
            response.put("error", "catalog_unavailable")
            response
        } else {
            mcm.reconcile()
        }
    }

    private fun scanDirectory(
        dir: File,
        type: String,
        recordings: MutableList<JSONObject>,
        dateFilter: String?
    ) {
        if (!dir.exists() || !dir.isDirectory) return

        // Verify the directory is actually readable (catches unmounted SD card ghost paths)
        if (!dir.canRead()) return

        val files = dir.listFiles { _, name -> name.endsWith(".mp4") } ?: return

        var filterStart = 0L
        var filterEnd = 0L
        if (!dateFilter.isNullOrEmpty()) {
            val range = dateRangeMs(dateFilter)
            filterStart = range[0]
            filterEnd = range[1]
        }

        for (file in files) {
            // Skip ghost files: they must be readable and have actual content. On BYD, an
            // unmounted SD card can leave stale directory entries with 0-byte ghosts.
            if (!file.canRead() || file.length() <= 0) continue

            val recording = parseRecording(file, type) ?: continue
            // Apply the date filter if specified
            if (filterStart > 0) {
                val ts = recording.optLong("timestamp", 0)
                if (ts < filterStart || ts >= filterEnd) continue
            }
            recordings.add(recording)
        }
    }

    private fun parseRecording(file: File, type: String): JSONObject? {
        // Cache lookup: the hot path skips regex + DateFormat + sidecar I/O when nothing has
        // changed. Keyed by absolute path; the type only affects which regex matches but a given
        // file matches at most one regex, so cached entries are stable across `type` values.
        val cacheKey = file.absolutePath
        val mp4Length = file.length()
        val mp4Mtime = file.lastModified()
        val sidecar = File(file.parentFile, file.name.replace(".mp4", ".json"))
        val sidecarMtime = if (sidecar.exists()) sidecar.lastModified() else 0L

        val cached = RECORDING_CACHE[cacheKey]
        if (cached != null &&
            cached.mp4Length == mp4Length &&
            cached.mp4Mtime == mp4Mtime &&
            cached.sidecarMtime == sidecarMtime
        ) {
            try {
                return JSONObject(cached.json)
            } catch (ignored: Exception) {
                CameraDaemon.log(
                    "Failed to deserialize cached recording: " + ignored.message
                )
                // fall through to re-parse
            }
        }

        val parsed = parseRecordingUncached(file, type)
        if (parsed != null) {
            try {
                RECORDING_CACHE[cacheKey] =
                    CachedRecording(mp4Length, mp4Mtime, sidecarMtime, parsed.toString())
            } catch (ignored: Exception) {
                CameraDaemon.log("Failed to cache recording parse result: " + ignored.message)
            }
        }
        return parsed
    }

    private fun parseRecordingUncached(file: File, type: String): JSONObject? {
        return try {
            val name = file.name
            val timestamp: Long
            var cameraId = 0

            when (type) {
                "sentry" -> {
                    val m = EVENT_PATTERN.matcher(name)
                    if (!m.matches()) return null
                    timestamp = DATE_FORMAT.parse(m.group(1) + "_" + m.group(2))!!.time
                }
                "proximity" -> {
                    val m = PROXIMITY_PATTERN.matcher(name)
                    if (!m.matches()) return null
                    timestamp = DATE_FORMAT.parse(m.group(1) + "_" + m.group(2))!!.time
                }
                else -> {
                    val m = CAM_PATTERN.matcher(name)
                    if (!m.matches()) return null
                    cameraId = m.group(1)?.toInt() ?: 0
                    timestamp = DATE_FORMAT.parse(m.group(2) + "_" + m.group(3))!!.time
                }
            }

            val rec = JSONObject()
            rec.put("filename", name)
            rec.put("path", file.absolutePath)
            rec.put("type", type)
            rec.put("cameraId", cameraId)
            rec.put("timestamp", timestamp)
            rec.put("size", file.length())
            rec.put("sizeFormatted", formatSize(file.length()))

            // Format date/time for display
            val date = Date(timestamp)
            rec.put("date", SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date))
            rec.put("time", SimpleDateFormat("HH:mm:ss", Locale.US).format(date))
            rec.put("dateFormatted", SimpleDateFormat("MMM dd, yyyy", Locale.US).format(date))
            rec.put("timeFormatted", SimpleDateFormat("h:mm a", Locale.US).format(date))

            // Video URL for playback
            rec.put("videoUrl", "/video/$name")

            // Thumbnail URL — the server generates the thumbnail from the video
            rec.put("thumbnailUrl", "/thumb/$name")

            applyMarkedStatus(rec, name, MarkedRecordingsStore.getInstance())

            // ---- v3 sidecar enrichment ----
            // If a JSON sidecar accompanies this MP4, attach the high-level stats so the events
            // list can render badges and filter without opening every file. Backwards-compatible:
            // with no sidecar, a v2 sidecar, or a parse error, the recording entry simply lacks
            // the new fields and the UI degrades.
            try {
                val side = File(file.parentFile, name.replace(".mp4", ".json"))
                if (side.exists() && side.canRead()) {
                    val sb = StringBuilder(min(side.length(), 65536L).toInt())
                    BufferedReader(FileReader(side)).use { br ->
                        while (true) {
                            val line = br.readLine() ?: break
                            sb.append(line)
                        }
                    }
                    val sidecarJson = JSONObject(sb.toString())
                    rec.put("schemaVersion", sidecarJson.optInt("version", 2))
                    // Clip duration from the sidecar (v3) — avoids a MediaMetadataRetriever probe.
                    val sideDurationMs = sidecarJson.optLong("durationMs", 0)
                    if (sideDurationMs > 0) rec.put("durationSeconds", sideDurationMs / 1000)
                    val stats = sidecarJson.optJSONObject("stats")
                    if (stats != null) {
                        // v2 fields (always present)
                        rec.put("personSpans", stats.optInt("person", 0))
                        rec.put("vehicleSpans", stats.optInt("car", 0))
                        rec.put("bikeSpans", stats.optInt("bike", 0))
                        // v3 fields (may be absent on legacy clips)
                        if (stats.has("personCount")) {
                            rec.put("personCount", stats.optInt("personCount"))
                        }
                        if (stats.has("vehicleCount")) {
                            rec.put("vehicleCount", stats.optInt("vehicleCount"))
                        }
                        if (stats.has("bikeCount")) {
                            rec.put("bikeCount", stats.optInt("bikeCount"))
                        }
                        if (stats.has("animalCount")) {
                            rec.put("animalCount", stats.optInt("animalCount"))
                        }
                        if (stats.has("peakSeverity")) {
                            rec.put("peakSeverity", stats.optString("peakSeverity"))
                        }
                        if (stats.has("peakProximity")) {
                            rec.put("peakProximity", stats.optString("peakProximity"))
                        }
                        if (stats.has("peakSeverityMs")) {
                            rec.put("peakSeverityMs", stats.optLong("peakSeverityMs"))
                        }
                    }
                    // Hero thumbnail filename (v3 only)
                    if (sidecarJson.has("heroThumbnail")) {
                        val heroName = sidecarJson.optString("heroThumbnail")
                        if (!heroName.isNullOrEmpty() &&
                            File(file.parentFile, heroName).exists()
                        ) {
                            rec.put("heroThumbnailUrl", "/thumb/$heroName")
                        }
                    }
                    // Compact actors[] for the filter chips. Strip the heavy fields, but KEEP
                    // static actors with their isStatic flag intact.
                    //
                    // The Class chip ("does this clip contain a vehicle?") only makes sense if it
                    // counts every vehicle that physically appeared. The tracker's isStatic flag
                    // is a frame-by-frame bbox-stability heuristic
                    // (STATIC_FRAMES_NEEDED_VEHICLE=2, ~200ms) that flips true on a vehicle
                    // passing laterally through a quadrant — exactly the kind of clip a user
                    // filtering on Vehicle wants to see.
                    //
                    // The Severity / Proximity filters key off rec.peakSeverity and
                    // rec.peakProximity (which EventTimelineCollector aggregates from non-static
                    // actors only), so the "scenery doesn't escalate" rule still holds for those.
                    val actors = sidecarJson.optJSONArray("actors")
                    if (actors != null && actors.length() > 0) {
                        val slim = JSONArray()
                        for (i in 0 until actors.length()) {
                            val a = actors.optJSONObject(i) ?: continue
                            slim.put(
                                JSONObject()
                                    .put("class", a.optString("class", "object"))
                                    .put("peakSeverity", a.optString("peakSeverity", "NOTICE"))
                                    .put("peakProximity", a.optString("peakProximity", "UNKNOWN"))
                                    .put("isStatic", a.optBoolean("isStatic", false))
                            )
                        }
                        rec.put("actors", slim)
                    }
                }
            } catch (se: Exception) {
                CameraDaemon.log(
                    "Sidecar parse failed (recording still shown): " + se.message
                )
                // A sidecar parse failure is non-fatal; the recording still appears in the list.
            }

            // Duration: fall back to a one-time MediaMetadataRetriever probe when the sidecar did
            // not supply it (e.g. normal dashcam clips). parseRecording is cached per file, so
            // this runs at most once per recording.
            if (!rec.has("durationSeconds")) {
                val durSec = probeDurationSeconds(file)
                if (durSec > 0) rec.put("durationSeconds", durSec)
            }

            rec
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Probe a recording's duration (seconds) via MediaMetadataRetriever. Returns 0 on failure.
     * Heavier than a file-stat, so callers should cache the result ([parseRecording] does).
     */
    private fun probeDurationSeconds(file: File): Long {
        var retriever: MediaMetadataRetriever? = null
        try {
            retriever = MediaMetadataRetriever()
            retriever.setDataSource(file.absolutePath)
            val d = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            if (d != null) {
                return d.trim().toLong() / 1000L
            }
        } catch (ignored: Exception) {
            CameraDaemon.log("Duration probe failed: " + ignored.message)
            // Unreadable/partial mp4 (e.g. in-flight) — the duration just stays 0.
        } finally {
            if (retriever != null) {
                try {
                    retriever.release()
                } catch (e: Exception) {
                    CameraDaemon.log(
                        "retriever.release() failed in probeDurationSeconds: " + e.message
                    )
                }
            }
        }
        return 0L
    }

    /** Dates that have recordings, for calendar highlighting. */
    @JvmStatic
    @Throws(Exception::class)
    fun datesWithRecordings(): JSONObject {
        val dates = HashSet<String>()
        val countByDate = HashMap<String, Int>()
        val hasSentryByDate = HashMap<String, Boolean>()

        if (!datesFromDb(dates, countByDate, hasSentryByDate)) {
            datesFromFilesystem(dates, countByDate, hasSentryByDate)
        }

        val datesArray = JSONArray()
        for (date in dates) {
            val dateObj = JSONObject()
            dateObj.put("date", date)
            dateObj.put("count", countByDate[date] ?: 0)
            dateObj.put("hasSentry", hasSentryByDate[date] ?: false)
            datesArray.put(dateObj)
        }

        val response = JSONObject()
        response.put("success", true)
        response.put("dates", datesArray)

        return response
    }

    /**
     * Populate the calendar maps from the media catalog DB. Returns false when the DB is
     * unavailable or empty (after a lazy auto-rebuild attempt).
     */
    private fun datesFromDb(
        dates: MutableSet<String>,
        countByDate: MutableMap<String, Int>,
        hasSentryByDate: MutableMap<String, Boolean>
    ): Boolean {
        val db = mediaDb()
        if (db == null || !db.isAvailable()) return false
        CameraDaemon.getMediaCatalogManager()?.ensureIndexedOnce() // no-op after the first call
        if (db.getCount() == 0) return false

        val ymd = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        // getDateRows() returns [timestamp_ms, isSentry] — no json CLOB, no JSONObject allocation.
        for (row in db.getDateRows()) {
            val formattedDate = ymd.format(Date(row[0]))
            dates.add(formattedDate)
            countByDate.merge(formattedDate, 1, Int::plus)
            if (row[1] == 1L) hasSentryByDate[formattedDate] = true
        }
        return true
    }

    /** Filesystem scan of recording dates (the catalog rebuild source and the fallback). */
    private fun datesFromFilesystem(
        dates: MutableSet<String>,
        countByDate: MutableMap<String, Int>,
        hasSentryByDate: MutableMap<String, Boolean>
    ) {
        val sm = StorageManager.getInstance()

        for (dir in sm.allRecordingsDirs) {
            scanDatesInDirectory(dir, false, dates, countByDate, hasSentryByDate)
        }
        val legacyDir = File(LEGACY_RECORDINGS_DIR)
        if (legacyDir.exists()) {
            scanDatesInDirectory(legacyDir, false, dates, countByDate, hasSentryByDate)
        }

        for (dir in sm.allSurveillanceDirs) {
            scanDatesInDirectory(dir, true, dates, countByDate, hasSentryByDate)
        }
        val legacySentryDir = File(LEGACY_SENTRY_DIR)
        if (legacySentryDir.exists()) {
            scanDatesInDirectory(legacySentryDir, true, dates, countByDate, hasSentryByDate)
        }

        for (dir in sm.allProximityDirs) {
            scanDatesInDirectory(dir, false, dates, countByDate, hasSentryByDate)
        }
    }

    private fun scanDatesInDirectory(
        dir: File,
        isSentry: Boolean,
        dates: MutableSet<String>,
        countByDate: MutableMap<String, Int>,
        hasSentryByDate: MutableMap<String, Boolean>
    ) {
        if (!dir.exists() || !dir.isDirectory || !dir.canRead()) return

        val files = dir.listFiles { _, name -> name.endsWith(".mp4") } ?: return

        for (file in files) {
            // Skip ghost files from an unmounted SD card
            if (!file.canRead() || file.length() <= 0) continue

            val name = file.name
            var dateStr: String? = null
            var isSentryFile = false

            // Try all patterns to extract the date — handles mixed directories
            val eventMatcher = EVENT_PATTERN.matcher(name)
            val camMatcher = CAM_PATTERN.matcher(name)
            val proxMatcher = PROXIMITY_PATTERN.matcher(name)

            if (eventMatcher.matches()) {
                dateStr = eventMatcher.group(1)
                isSentryFile = true
            } else if (camMatcher.matches()) {
                dateStr = camMatcher.group(2)
            } else if (proxMatcher.matches()) {
                dateStr = proxMatcher.group(1)
            }

            if (dateStr != null && dateStr.length == 8) {
                val formattedDate = dateStr.substring(0, 4) + "-" +
                    dateStr.substring(4, 6) + "-" + dateStr.substring(6, 8)
                dates.add(formattedDate)
                countByDate.merge(formattedDate, 1, Int::plus)
                if (isSentryFile) {
                    hasSentryByDate[formattedDate] = true
                }
            }
        }
    }

    /**
     * Storage statistics. Scans ALL locations (active + alternate) via StorageManager,
     * deduplicating by filename.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun storageStats(): JSONObject {
        val storage = StorageManager.getInstance()

        val todayStr = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date())

        // [normalSize, normalCount, sentrySize, sentryCount, proximitySize, proximityCount,
        //  normalToday, sentryToday, proximityToday]
        val agg = LongArray(9)
        if (!aggregateStatsFromDb(agg, todayStr)) {
            aggregateStatsFromFilesystem(storage, agg, todayStr)
        }
        val normalSize = agg[0]
        val normalCount = agg[1]
        val sentrySize = agg[2]
        val sentryCount = agg[3]
        val proximitySize = agg[4]
        val proximityCount = agg[5]
        val normalTodayCount = agg[6]
        val sentryTodayCount = agg[7]
        val proximityTodayCount = agg[8]

        // Available space from the active recordings directory
        val activeRecDir = storage.recordingsDir
        val availableSpace = if (activeRecDir.exists()) activeRecDir.freeSpace else 0
        val totalSpace = if (activeRecDir.exists()) activeRecDir.totalSpace else 0

        val response = JSONObject()
        response.put("success", true)
        response.put("normalCount", normalCount)
        response.put("normalSize", normalSize)
        response.put("normalSizeFormatted", formatSize(normalSize))
        response.put("sentryCount", sentryCount)
        response.put("sentrySize", sentrySize)
        response.put("sentrySizeFormatted", formatSize(sentrySize))
        response.put("proximityCount", proximityCount)
        response.put("proximitySize", proximitySize)
        response.put("proximitySizeFormatted", formatSize(proximitySize))
        response.put("totalCount", normalCount + sentryCount + proximityCount)
        response.put("totalSize", normalSize + sentrySize + proximitySize)
        response.put(
            "totalSizeFormatted", formatSize(normalSize + sentrySize + proximitySize)
        )
        response.put("availableSpace", availableSpace)
        response.put("availableSpaceFormatted", formatSize(availableSpace))
        response.put("totalSpace", totalSpace)
        response.put("totalSpaceFormatted", formatSize(totalSpace))

        // Today's counts
        response.put("normalTodayCount", normalTodayCount)
        response.put("sentryTodayCount", sentryTodayCount)
        response.put("proximityTodayCount", proximityTodayCount)
        response.put(
            "totalTodayCount", normalTodayCount + sentryTodayCount + proximityTodayCount
        )

        // Storage limit info
        response.put("recordingsLimitMb", storage.recordingsLimitMb)
        response.put("surveillanceLimitMb", storage.surveillanceLimitMb)
        response.put("recordingsLimitBytes", storage.recordingsLimitMb * 1024 * 1024)
        response.put("surveillanceLimitBytes", storage.surveillanceLimitMb * 1024 * 1024)
        response.put(
            "recordingsUsagePercent",
            if (storage.recordingsLimitMb > 0) {
                (normalSize * 100.0 / (storage.recordingsLimitMb * 1024 * 1024)).roundToLong()
            } else {
                0L
            }
        )
        response.put(
            "surveillanceUsagePercent",
            if (storage.surveillanceLimitMb > 0) {
                (sentrySize * 100.0 / (storage.surveillanceLimitMb * 1024 * 1024)).roundToLong()
            } else {
                0L
            }
        )

        // Storage paths
        response.put("recordingsPath", getRecordingsDir())
        response.put("surveillancePath", getSentryDir())

        return response
    }

    /**
     * Aggregate per-type counts/sizes/today-counts from the media catalog DB. Dedups by filename
     * per type (a clip on SD + internal counts once), exactly like the filesystem aggregation.
     * Returns false when the DB is unavailable or empty (after a lazy auto-rebuild attempt) so the
     * caller falls back.
     */
    private fun aggregateStatsFromDb(agg: LongArray, todayStr: String): Boolean {
        val db = mediaDb()
        if (db == null || !db.isAvailable()) return false
        CameraDaemon.getMediaCatalogManager()?.ensureIndexedOnce() // no-op after the first call
        if (db.getCount() == 0) return false

        // Convert "yyyyMMdd" todayStr to an inclusive-exclusive epoch range.
        val dateFmt = todayStr.substring(0, 4) + "-" + todayStr.substring(4, 6) + "-" +
            todayStr.substring(6, 8)
        val todayRange = dateRangeMs(dateFmt)
        // aggregateForStats uses a live File.length() for sizes; no json CLOB scanned.
        db.aggregateForStats(agg, todayRange[0], todayRange[1])
        return agg[1] > 0 || agg[3] > 0 || agg[5] > 0
    }

    /**
     * Filesystem aggregation (the catalog rebuild source and the fallback). Scans ALL locations
     * via StorageManager, deduplicating by filename per type.
     */
    private fun aggregateStatsFromFilesystem(
        storage: StorageManager,
        agg: LongArray,
        todayStr: String
    ) {
        val seenNormal = HashSet<String>()
        val seenSentry = HashSet<String>()
        val seenProximity = HashSet<String>()

        // Normal recordings from ALL locations
        for (dir in storage.allRecordingsDirs + File(LEGACY_RECORDINGS_DIR)) {
            accumulate(dir, seenNormal, agg, 0, 1, 6, todayStr, CAM_PATTERN, 2)
        }

        // Sentry events from ALL locations
        for (dir in storage.allSurveillanceDirs + File(LEGACY_SENTRY_DIR)) {
            accumulate(dir, seenSentry, agg, 2, 3, 7, todayStr, EVENT_PATTERN, 1)
        }

        // Proximity events from ALL locations
        for (dir in storage.allProximityDirs) {
            accumulate(dir, seenProximity, agg, 4, 5, 8, todayStr, PROXIMITY_PATTERN, 1)
        }
    }

    /** One directory's contribution to the size/count/today triple at the given agg indices. */
    private fun accumulate(
        dir: File,
        seen: MutableSet<String>,
        agg: LongArray,
        sizeIdx: Int,
        countIdx: Int,
        todayIdx: Int,
        todayStr: String,
        pattern: Pattern,
        dateGroup: Int
    ) {
        if (!dir.exists() || !dir.canRead()) return
        val files = dir.listFiles { _, name -> name.endsWith(".mp4") } ?: return
        for (f in files) {
            if (!f.canRead() || f.length() <= 0) continue
            if (!seen.add(f.name)) continue
            agg[sizeIdx] += f.length()
            agg[countIdx]++
            if (isFileFromToday(f.name, todayStr, pattern, dateGroup)) agg[todayIdx]++
        }
    }

    /**
     * Whether a filename matches today's date based on the pattern.
     *
     * @param filename the filename to check
     * @param todayStr today's date in YYYYMMDD format
     * @param pattern the regex pattern to match
     * @param dateGroup the group index containing the date in the pattern
     */
    private fun isFileFromToday(
        filename: String,
        todayStr: String,
        pattern: Pattern,
        dateGroup: Int
    ): Boolean {
        val m = pattern.matcher(filename)
        return m.matches() && todayStr == m.group(dateGroup)
    }

    /**
     * Stream a video file with optional Range support and ETag-based caching.
     *
     * Finalized event recordings are immutable (the daemon writes to `<name>.mp4.tmp` and
     * atomically renames once the file is closed), so we emit a strong ETag derived from
     * length+mtime and a 24h max-age so the client's HTTP cache can serve repeat playback locally
     * instead of re-streaming from the daemon. The cache headers are added in
     * HttpResponse.sendVideo / sendVideoRange.
     */
    @Throws(Exception::class)
    private fun streamVideo(
        out: OutputStream,
        filename: String,
        rangeHeader: String?,
        ifNoneMatchHeader: String?
    ) {
        // Security: prevent path traversal
        if (filename.contains("..") || filename.contains("/")) {
            HttpResponse.sendError(out, 400, Messages.get("errors.recordings_invalid_filename"))
            return
        }

        // findVideoFile checks ALL storage locations
        val file = findVideoFile(filename)

        if (file == null) {
            HttpResponse.sendError(
                out, 404, Messages.get("errors.recordings_not_found_with_filename", filename)
            )
            return
        }

        // Conditional GET: if the client's cached copy matches our ETag, skip re-streaming. The
        // tag is "<length>-<mtime>" so any append/replace invalidates without needing a content
        // hash.
        val etag = buildVideoEtag(file)
        if (ifNoneMatchHeader != null && etagMatches(ifNoneMatchHeader, etag)) {
            HttpResponse.sendNotModified(out, etag)
            return
        }

        // Handle a Range request for video seeking
        try {
            if (rangeHeader != null && rangeHeader.startsWith("bytes=")) {
                val parts = rangeHeader.substring(6).split("-")
                val start = if (parts[0].isEmpty()) 0L else parts[0].toLong()
                val end = if (parts.size > 1 && parts[1].isNotEmpty()) parts[1].toLong() else -1L

                // Validate the range
                val fileLength = file.length()
                if (start < 0 || start >= fileLength) {
                    HttpResponse.sendError(
                        out, 416, Messages.get("errors.recordings_range_not_satisfiable")
                    )
                    return
                }

                HttpResponse.sendVideoRange(out, file, start, end, etag)
            } else {
                HttpResponse.sendVideo(out, file, etag)
            }
        } catch (e: NumberFormatException) {
            HttpResponse.sendError(
                out, 400, Messages.get("errors.recordings_invalid_range_header")
            )
        } catch (e: FileNotFoundException) {
            // The file disappeared between the check and the read (SD card unmount)
            HttpResponse.sendError(
                out, 410, Messages.get("errors.recordings_file_no_longer_accessible")
            )
        }
    }

    /**
     * Build a strong ETag for a video file from its size and mtime. Anything that mutates the file
     * (replacement, append, ext-storage rotation) changes at least one of these, invalidating the
     * client's cache.
     */
    private fun buildVideoEtag(file: File): String =
        "\"" + file.length() + "-" + file.lastModified() + "\""

    /**
     * Whether the client's If-None-Match header matches our ETag. Tolerates the wildcard form, the
     * weak prefix ("W/"), and comma-separated lists per RFC 7232 §3.2.
     */
    private fun etagMatches(ifNoneMatch: String?, etag: String?): Boolean {
        if (ifNoneMatch == null || etag == null) return false
        if ("*" == ifNoneMatch.trim()) return true
        for (token in ifNoneMatch.split(",")) {
            var t = token.trim()
            if (t.startsWith("W/")) t = t.substring(2)
            if (t == etag) return true
        }
        return false
    }

    /** Delete a recording. */
    @JvmStatic
    @Throws(Exception::class)
    fun deleteRecording(filename: String): JSONObject {
        // Security: prevent path traversal
        if (filename.contains("..") || filename.contains("/")) {
            throw ConnectException(
                "internal", Messages.get("errors.recordings_invalid_filename")
            )
        }

        // findVideoFile checks ALL storage locations
        val file = findVideoFile(filename)
            ?: throw ConnectException("internal", Messages.get("errors.recordings_not_found"))

        val deleted = file.delete()
        if (deleted) {
            deleteSidecars(file, filename)
        }

        val response = JSONObject()
        response.put("success", deleted)
        if (!deleted) {
            response.put("error", Messages.get("errors.recordings_delete_failed"))
        }

        return response
    }

    /**
     * Sweep the .mp4's sidecar files: the JSON event timeline, the cached thumb, the v3 hero JPEG
     * and the per-actor thumbs (`thumb_<base>_a*.jpg`).
     *
     * Mirrors RecordingScanner.deleteRecording on the Android side — without this sweep, web-UI
     * deletes leak hero/per-actor JPEGs into the storage directory until the disk fills (the
     * loop-rotation cleanup also doesn't see them because it only iterates .mp4 files).
     */
    private fun deleteSidecars(mp4File: File, filename: String) {
        // Invalidate the in-memory parse cache so the next list call doesn't return a phantom
        // entry for the just-deleted file.
        RECORDING_CACHE.remove(mp4File.absolutePath)

        // Prune the media catalog row too, otherwise the DB-first list keeps a phantom entry until
        // the next sync.
        try {
            val db = CameraDaemon.getMediaCatalogManager()?.getDatabase()
            if (db != null && !db.deleteByPath(mp4File.absolutePath)) {
                CameraDaemon.log(
                    "WARN: deleteByPath returned false for " + mp4File.name +
                        " — phantom entry may persist until next Sync"
                )
            }
        } catch (e: Exception) {
            CameraDaemon.log(
                "WARN: deleteByPath threw for " + mp4File.name + ": " + e.message +
                    " — phantom entry may persist until next Sync"
            )
        }

        // JSON event timeline
        val jsonFile = File(mp4File.parentFile, filename.replace(".mp4", ".json"))
        if (jsonFile.exists()) jsonFile.delete()

        // Cached thumbnail
        val thumbFile = File(getThumbnailCacheDir(), filename.replace(".mp4", ".jpg"))
        if (thumbFile.exists()) thumbFile.delete()

        // v3 hero JPEG sibling: <base>.jpg next to the mp4
        val parent = mp4File.parentFile
        if (parent == null || !parent.canRead()) return
        val base = if (filename.endsWith(".mp4")) filename.dropLast(4) else filename
        val heroSibling = File(parent, "$base.jpg")
        if (heroSibling.exists()) heroSibling.delete()

        // Per-actor thumbs: thumb_<base>_a<id>(_<rel>).jpg
        //
        // Anchored with "_a" so a sibling segment named "<base>_2.mp4" with its own thumbs at
        // "thumb_<base>_2_a*.jpg" is NOT swept when we delete <base>.mp4.
        val perActorPrefix = "thumb_${base}_a"
        val perActor = parent.listFiles { _, name ->
            name.startsWith(perActorPrefix) && name.endsWith(".jpg")
        }
        perActor?.forEach { it.delete() }
    }

    /**
     * Batch delete multiple recordings at once.
     *
     * Body: `{ "filenames": ["file1.mp4", "file2.mp4", ...] }`.
     * Returns `{ "success": true, "deleted": N, "failed": N, "errors": [...] }`.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun batchDeleteRecordings(body: String?): JSONObject {
        val response = JSONObject()

        if (body.isNullOrEmpty()) {
            response.put("success", false)
            response.put("error", Messages.get("errors.recordings_body_required"))
            return response
        }

        try {
            val filenames = JSONObject(body).optJSONArray("filenames")

            if (filenames == null || filenames.length() == 0) {
                response.put("success", false)
                response.put("error", Messages.get("errors.recordings_no_filenames"))
                return response
            }

            // Limit the batch size to prevent abuse
            val maxBatch = 100
            if (filenames.length() > maxBatch) {
                response.put("success", false)
                response.put(
                    "error",
                    Messages.get("errors.recordings_max_batch_with_count", maxBatch)
                )
                return response
            }

            var deleted = 0
            var failed = 0
            val errors = JSONArray()

            for (i in 0 until filenames.length()) {
                val filename = filenames.getString(i)

                // Security: prevent path traversal
                if (filename.contains("..") || filename.contains("/")) {
                    failed++
                    errors.put("$filename: invalid filename")
                    continue
                }

                val file = findVideoFile(filename)
                if (file == null) {
                    failed++
                    errors.put("$filename: not found")
                    continue
                }

                if (file.delete()) {
                    deleted++
                    deleteSidecars(file, filename)
                } else {
                    failed++
                    errors.put("$filename: delete failed")
                }
            }

            response.put("success", true)
            response.put("deleted", deleted)
            response.put("failed", failed)
            if (errors.length() > 0) {
                response.put("errors", errors)
            }
        } catch (e: Exception) {
            response.put("success", false)
            response.put(
                "error", Messages.get("errors.invalid_request_with_detail", e.message)
            )
        }

        return response
    }

    /**
     * The event timeline JSON for a recording: the JSON sidecar if it exists, or an empty events
     * array for backward compatibility.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun eventTimeline(filename: String): JSONObject {
        // Security: prevent path traversal
        if (filename.contains("..") || filename.contains("/")) {
            throw ConnectException(
                "invalid_argument", Messages.get("errors.recordings_invalid_filename")
            )
        }

        // Search for the JSON sidecar in all storage locations
        val jsonFile = findJsonSidecar(filename.replace(".mp4", ".json"))

        if (jsonFile != null && jsonFile.exists()) {
            // Serve the actual event data
            return try {
                val sb = StringBuilder()
                BufferedReader(FileReader(jsonFile)).use { reader ->
                    while (true) {
                        val line = reader.readLine() ?: break
                        sb.append(line)
                    }
                }
                JSONObject(sb.toString())
            } catch (e: Exception) {
                // The file exists but cannot be read or parsed — an empty timeline, not an error:
                // a video without usable events still plays.
                emptyTimeline()
            }
        }
        // Backward compatible: no sidecar = empty events array
        return emptyTimeline()
    }

    /** An empty timeline response (backward compatibility for videos without sidecars). */
    @Throws(Exception::class)
    private fun emptyTimeline(): JSONObject {
        val response = JSONObject()
        response.put("version", 1)
        response.put("events", JSONArray())
        response.put("durationMs", 0)
        return response
    }

    /**
     * Find a JSON sidecar file across all storage locations, using StorageManager to get every
     * possible directory rather than hardcoding paths.
     */
    private fun findJsonSidecar(jsonFilename: String): File? {
        val sm = StorageManager.getInstance()
        // Surveillance first, then recordings, then proximity — the original search order.
        val dirs = ArrayList<File>()
        dirs.addAll(sm.allSurveillanceDirs)
        dirs.addAll(sm.allRecordingsDirs)
        dirs.addAll(sm.allProximityDirs)
        for (dir in dirs) {
            val f = File(dir, jsonFilename)
            if (f.exists()) return f
        }
        return null
    }

    private fun formatSize(bytes: Long): String = when {
        bytes >= 1_000_000_000 -> String.format(Locale.US, "%.1f GB", bytes / 1_000_000_000.0)
        bytes >= 1_000_000 -> String.format(Locale.US, "%.1f MB", bytes / 1_000_000.0)
        bytes >= 1_000 -> String.format(Locale.US, "%.1f KB", bytes / 1_000.0)
        else -> "$bytes B"
    }
}
