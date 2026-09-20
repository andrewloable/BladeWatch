package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.GearMonitor
import net.bladewatch.app.monitor.GpsMonitor
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.telemetry.TelemetryDataCollector
import java.io.BufferedOutputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.zip.GZIPOutputStream
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.roundToLong
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Captures 5Hz telemetry by reading from existing singleton monitors. Buffers samples in memory,
 * flushes 1Hz-downsampled gzipped JSON-lines to disk.
 *
 * Does NOT create its own BYD device handles — reads from [TelemetryDataCollector], [GpsMonitor],
 * VehicleDataMonitor and [GearMonitor], which are already running.
 *
 * @param telemetryDataCollector injected from TripAnalyticsManager. May be null if the collector
 *   has not been initialised yet (GPU init delay); set it later through the same property.
 */
class TripTelemetryRecorder(@Volatile var telemetryDataCollector: TelemetryDataCollector?) {

    // Executor for 5Hz sampling
    private var executor: ScheduledExecutorService? = null
    private var sampleFuture: ScheduledFuture<*>? = null
    private var flushFuture: ScheduledFuture<*>? = null

    // Buffer (guarded by bufferLock)
    private val bufferLock = Any()
    private val buffer = ArrayList<TelemetrySample>()
    private var estimatedBufferBytes = 0L

    // All captured 5Hz samples for scoring (not cleared on flush)
    private val allSamplesLock = Any()
    private val allSamples = ArrayList<TelemetrySample>()

    // Trip state
    @Volatile
    private var recording = false
    private var currentTripId = -1L
    private var outputFile: File? = null

    // Stats tracking
    /** Maximum speed recorded during this trip. */
    var maxSpeedKmh = 0
        private set
    private var speedSumKmh = 0L
    private var speedSampleCount = 0L

    // GPS distance tracking (running haversine sum)
    /** Total GPS distance recorded during this trip, in km. */
    var totalDistanceKm = 0.0
        private set
    private var lastLat = 0.0
    private var lastLon = 0.0
    private var hasLastGps = false

    // GPS coverage tracking — how many samples landed valid lat/lon. Logged at trip end so the
    // daemon log alone tells us why a trip's map is blank (no GPS during recording vs. file write
    // failure vs. UI bug).
    private var sampleCountTotal = 0L
    private var sampleCountWithGps = 0L

    /** Average speed recorded during this trip. */
    val avgSpeedKmh: Double
        get() = if (speedSampleCount > 0) speedSumKmh.toDouble() / speedSampleCount else 0.0

    /** All captured 5Hz samples, for score computation (before downsampling). */
    val samplesForScoring: List<TelemetrySample>
        get() = synchronized(allSamplesLock) { ArrayList(allSamples) }

    /**
     * Start recording telemetry for the given trip. Starts the 5Hz sampling timer and the periodic
     * flush timer.
     */
    fun startRecording(tripId: Long) {
        if (recording) {
            logger.warn("Already recording trip $currentTripId, ignoring start for $tripId")
            return
        }

        currentTripId = tripId
        outputFile = File(StorageManager.getInstance().tripsDir, "$tripId.jsonl.gz")
        maxSpeedKmh = 0
        speedSumKmh = 0
        speedSampleCount = 0
        totalDistanceKm = 0.0
        lastLat = 0.0
        lastLon = 0.0
        hasLastGps = false
        sampleCountTotal = 0
        sampleCountWithGps = 0

        synchronized(bufferLock) {
            buffer.clear()
            estimatedBufferBytes = 0
        }
        synchronized(allSamplesLock) {
            allSamples.clear()
        }

        recording = true

        val exec = Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "TripTelemetry-$tripId").apply { isDaemon = true }
        }
        executor = exec

        // 5Hz sampling
        sampleFuture = exec.scheduleAtFixedRate(
            ::sample, 0, SAMPLE_INTERVAL_MS, TimeUnit.MILLISECONDS
        )

        // Periodic flush every 60s
        flushFuture = exec.scheduleAtFixedRate(
            ::flushBuffer, FLUSH_INTERVAL_MS, FLUSH_INTERVAL_MS, TimeUnit.MILLISECONDS
        )

        logger.info("Started recording trip $tripId → " + outputFile!!.absolutePath)
    }

    /**
     * Stop recording. Flushes the remaining buffer and closes the file.
     *
     * @return the telemetry file path, or null if not recording
     */
    fun stopRecording(): String? {
        if (!recording) {
            logger.warn("Not recording, ignoring stop")
            return null
        }

        recording = false
        logger.info("Stopping recording for trip $currentTripId")

        // Cancel scheduled tasks
        sampleFuture?.cancel(false)
        flushFuture?.cancel(false)

        // Final flush of remaining buffer
        flushBuffer()

        // Shutdown executor
        executor?.let { exec ->
            exec.shutdown()
            try {
                exec.awaitTermination(5, TimeUnit.SECONDS)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
            }
            executor = null
        }

        // Notify StorageManager
        try {
            StorageManager.getInstance().onTripFileSaved()
        } catch (e: Exception) {
            logger.warn("Failed to notify StorageManager: " + e.message)
        }

        val file = outputFile
        val path = file?.absolutePath
        val fileBytes = if (file != null && file.exists()) file.length() else -1L
        val gpsPct = if (sampleCountTotal == 0L) {
            0L
        } else {
            (100.0 * sampleCountWithGps / sampleCountTotal).roundToLong()
        }
        logger.info(
            "Stopped recording trip " + currentTripId +
                " (samples=" + speedSampleCount +
                ", maxSpeed=" + maxSpeedKmh +
                ", gps=" + sampleCountWithGps + "/" + sampleCountTotal + " (" + gpsPct + "%)" +
                ", fileBytes=" + (if (fileBytes < 0) "missing" else fileBytes.toString()) +
                ", file=" + path + ")"
        )

        return path
    }

    /** The file path for a given trip ID. */
    fun getTelemetryFilePath(tripId: Long): String =
        File(StorageManager.getInstance().tripsDir, "$tripId.jsonl.gz").absolutePath

    // ==================== PRIVATE: Sampling ====================

    /** Called at 5Hz. Reads from the existing singleton monitors and buffers a sample. */
    private fun sample() {
        if (!recording) return

        try {
            val now = System.currentTimeMillis()

            // Read speed/accel/brake/brakePedalPressed from TelemetryDataCollector
            val snapshot = telemetryDataCollector?.getLatestSnapshot()
            var speedKmh = 0
            var accelPedal = 0
            var brakePedal = 0
            var brakePedalPressed = false
            if (snapshot != null) {
                // A snapshot older than 2 seconds means the poller may have died.
                val snapshotAge = now - snapshot.timestampMs
                if (snapshotAge < 2000) {
                    speedKmh = snapshot.speedKmh
                    accelPedal = snapshot.accelPedalPercent
                    brakePedal = snapshot.brakePedalPercent
                    brakePedalPressed = snapshot.brakePedalPressed
                } else if (snapshotAge < 5000) {
                    // Stale snapshot — record zeros instead of frozen values, and log only once
                    // per staleness episode (within the first 5s).
                    logger.warn("Telemetry snapshot stale (" + snapshotAge + "ms old), recording zeros")
                }
            }

            // Read GPS from GpsMonitor
            val gps = GpsMonitor.getInstance()
            val lat = gps.latitude
            val lon = gps.longitude
            val altitude = gps.altitude

            // Read gear from GearMonitor
            val gearMode = GearMonitor.getInstance().currentGear

            val sample = TelemetrySample(
                now, speedKmh, accelPedal, brakePedal,
                brakePedalPressed, gearMode, lat, lon, altitude
            )

            // Track GPS distance (haversine) and coverage stats.
            sampleCountTotal++
            if (lat != 0.0 && lon != 0.0) {
                sampleCountWithGps++
                if (hasLastGps && lastLat != 0.0 && lastLon != 0.0) {
                    val dist = haversineKm(lastLat, lastLon, lat, lon)
                    // Filter out GPS jumps (>500m in 200ms is impossible at any speed)
                    if (dist < 0.5) {
                        totalDistanceKm += dist
                    }
                }
                lastLat = lat
                lastLon = lon
                hasLastGps = true
            }

            // Track stats
            if (speedKmh > maxSpeedKmh) {
                maxSpeedKmh = speedKmh
            }
            speedSumKmh += speedKmh
            speedSampleCount++

            // Add to scoring buffer (all 5Hz samples)
            synchronized(allSamplesLock) {
                allSamples.add(sample)
            }

            // Add to flush buffer
            synchronized(bufferLock) {
                buffer.add(sample)
                // Rough estimate: ~100 bytes per sample
                estimatedBufferBytes += 100

                // Force flush if the buffer exceeds the 10MB threshold
                if (estimatedBufferBytes >= MAX_BUFFER_BYTES) {
                    logger.info("Buffer exceeded 10MB threshold, force-flushing")
                    executor?.execute(::flushBuffer)
                }
            }
        } catch (e: Throwable) {
            // Catch Throwable to prevent ScheduledExecutorService from silently stopping
            logger.warn("Sample error: " + e.message)
        }
    }

    // ==================== PRIVATE: Flush Pipeline ====================

    /**
     * Flush pipeline:
     *  1. Copy the buffer to a local list, clear the buffer
     *  2. Downsample 5Hz to 1Hz: group by second, pick the sample closest to each whole-second
     *     boundary
     *  3. Serialise each 1Hz sample as a JSON line using `TelemetrySample.toJson()`
     *  4. Write a gzipped chunk and append it to the output file
     */
    private fun flushBuffer() {
        val toFlush: List<TelemetrySample>
        synchronized(bufferLock) {
            if (buffer.isEmpty()) return
            toFlush = ArrayList(buffer)
            buffer.clear()
            estimatedBufferBytes = 0
        }

        // Downsample 5Hz → 1Hz
        val downsampled = downsampleTo1Hz(toFlush)

        if (downsampled.isEmpty()) return

        // Serialize and write gzipped chunk
        try {
            writeGzippedChunk(downsampled)
        } catch (e: IOException) {
            logger.error("Failed to write telemetry chunk: " + e.message)
            // Per requirement 2.7: log the error and continue, do not crash
        }
    }

    /**
     * Write a list of 1Hz samples as a gzipped JSON-lines chunk appended to the output file. Each
     * flush builds a temp buffer, gzips it and appends it to the file.
     *
     * Re-resolves the output directory against `StorageManager.getTripsDir()` on each flush. The
     * directory pointer can flip mid-trip when the SD card unmounts/remounts (the watchdog rebinds
     * tripsDir to internal storage and back). Without re-resolution we would keep appending to a
     * path under a now-absent volume, every flush would IOException, and the trip would end with
     * an empty file even though the recorder logs "ok".
     */
    @Throws(IOException::class)
    private fun writeGzippedChunk(samples: List<TelemetrySample>) {
        if (outputFile == null) return

        // Build JSON-lines content
        val sb = StringBuilder()
        for (sample in samples) {
            sb.append(sample.toJson().toString()).append('\n')
        }

        // Gzip the content
        val baos = ByteArrayOutputStream()
        GZIPOutputStream(baos).use { gzos ->
            gzos.write(sb.toString().toByteArray(Charsets.UTF_8))
        }

        // Re-resolve the target file if its directory has gone away mid-trip. Any partial bytes
        // are migrated from the stale path to the live one so a chunk-by-chunk flush stays as one
        // continuous file post-trip.
        val target = resolveOutputFileForFlush() ?: return

        // Append gzipped bytes to the (possibly relocated) output file.
        BufferedOutputStream(FileOutputStream(target, true)).use { fos ->
            fos.write(baos.toByteArray())
        }

        logger.info(
            "Flushed " + samples.size + " 1Hz samples to " + target.name +
                " (" + baos.size() + " bytes gzipped)"
        )
    }

    /**
     * If the output file's parent directory has become unavailable (typical cause: SD card
     * unmounted mid-trip), re-resolve against the live `StorageManager.getTripsDir()`. If the live
     * dir differs, copy any bytes already written at the stale path to the new path before
     * continuing.
     *
     * Returns the file the caller should open. [outputFile] is also updated to the new path so
     * subsequent flushes — and [stopRecording]'s path report — see the live location.
     */
    private fun resolveOutputFileForFlush(): File? {
        val current = outputFile ?: return null
        val parent = current.parentFile
        if (parent != null && parent.exists() && parent.canWrite()) {
            return current
        }
        val liveDir = StorageManager.getInstance().tripsDir
        if (liveDir == null || liveDir == parent) {
            return current
        }
        val newPath = File(liveDir, current.name)
        if (newPath != current) {
            // Best-effort migration of any prior chunk bytes. If migration fails (e.g. the stale
            // file truly went with the volume) we still proceed — the new flush creates a fresh
            // file at the live path.
            try {
                if (current.exists() && current.length() > 0 &&
                    (parent == null || parent.exists())
                ) {
                    Files.copy(
                        current.toPath(),
                        newPath.toPath(),
                        StandardCopyOption.REPLACE_EXISTING
                    )
                    logger.info(
                        "Trip telemetry migrated: " + current.absolutePath +
                            " -> " + newPath.absolutePath
                    )
                }
            } catch (e: Exception) {
                logger.warn(
                    "Trip telemetry migration failed: " + e.message +
                        " — continuing at " + newPath.absolutePath
                )
            }
            outputFile = newPath
        }
        return outputFile
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("TripTelemetryRecorder")

        /** 5Hz. */
        private const val SAMPLE_INTERVAL_MS = 200L

        /** 60s. */
        private const val FLUSH_INTERVAL_MS = 60_000L
        private const val MAX_BUFFER_BYTES = (10 * 1024 * 1024).toLong()

        /** Haversine formula: distance between two GPS coordinates, in km. */
        private fun haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
            val r = 6371.0 // Earth radius in km
            val dLat = Math.toRadians(lat2 - lat1)
            val dLon = Math.toRadians(lon2 - lon1)
            val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
            val c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return r * c
        }

        /**
         * 1Hz downsampling: for each whole-second boundary present in the data, select the sample
         * with the timestamp closest to that boundary.
         */
        internal fun downsampleTo1Hz(samples: List<TelemetrySample>?): List<TelemetrySample> {
            if (samples == null || samples.isEmpty()) return ArrayList()

            // Group samples by their whole second (floored)
            val bySecond = HashMap<Long, MutableList<TelemetrySample>>()
            for (s in samples) {
                val secondBoundary = (s.timestampMs / 1000) * 1000
                bySecond.getOrPut(secondBoundary) { ArrayList() }.add(s)
            }

            // For each second boundary, pick the sample closest to that boundary
            val sortedSeconds = ArrayList(bySecond.keys).apply { sort() }

            val result = ArrayList<TelemetrySample>(sortedSeconds.size)
            for (boundary in sortedSeconds) {
                val group = bySecond[boundary]!!
                var closest: TelemetrySample? = null
                var closestDist = Long.MAX_VALUE
                for (s in group) {
                    val dist = abs(s.timestampMs - boundary)
                    if (dist < closestDist) {
                        closestDist = dist
                        closest = s
                    }
                }
                if (closest != null) {
                    result.add(closest)
                }
            }

            return result
        }
    }
}
