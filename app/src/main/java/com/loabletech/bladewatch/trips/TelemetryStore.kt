package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.zip.GZIPInputStream
import java.util.zip.GZIPOutputStream

/**
 * Reads and writes gzipped JSON-lines telemetry files, for `TripTelemetryRecorder` (chunked
 * writes) and the Trip API (reads).
 *
 * The recorder appends a NEW gzip stream to the same file on every flush. A plain
 * [GZIPInputStream] reads only the first one, so [readFromFile] loops over concatenated streams
 * until EOF — without that, every trip would appear to contain only its first 60 seconds.
 */
object TelemetryStore {

    private val logger: DaemonLogger = DaemonLogger.getInstance("TelemetryStore")

    /**
     * Read a gzipped JSON-lines telemetry file, handling concatenated gzip streams.
     *
     * @param file the `.jsonl.gz` file
     * @return every sample across all streams in the file
     */
    @JvmStatic
    fun readFromFile(file: File?): List<TelemetrySample> {
        if (file == null || !file.exists() || file.length() == 0L) return ArrayList()
        return try {
            // Read the whole file into memory — telemetry files are bounded by storage limits.
            parseJsonLines(decompressConcatenatedGzip(readAllBytes(file)))
        } catch (e: Exception) {
            logger.error("Failed to read telemetry file: " + file.name, e)
            ArrayList()
        }
    }

    /**
     * Write samples as a SINGLE gzipped JSON-lines file. Utility/testing path — the recorder
     * uses chunked appends instead.
     */
    @JvmStatic
    @Throws(IOException::class)
    fun writeToFile(file: File?, samples: List<TelemetrySample>?) {
        if (file == null) throw IOException("Output file is null")
        if (samples.isNullOrEmpty()) throw IOException("No samples to write")

        val jsonBytes = serializeToJsonLines(samples).toByteArray(Charsets.UTF_8)
        BufferedOutputStream(FileOutputStream(file, false)).use { fos ->
            GZIPOutputStream(fos).use { it.write(jsonBytes) }
        }
        logger.info("Wrote " + samples.size + " samples to " + file.name)
    }

    /**
     * One compact JSON object per line, with no trailing newline on the last line.
     */
    @JvmStatic
    fun serializeToJsonLines(samples: List<TelemetrySample>?): String {
        if (samples.isNullOrEmpty()) return ""
        return samples.joinToString("\n") { it.toJson().toString() }
    }

    /**
     * Parse JSON-lines back into samples. A malformed line is SKIPPED rather than failing the
     * whole file: one corrupt line at the end of an interrupted flush should not lose the trip.
     */
    @JvmStatic
    fun parseJsonLines(jsonLines: String?): List<TelemetrySample> {
        val samples = ArrayList<TelemetrySample>()
        if (jsonLines.isNullOrBlank()) return samples

        for (line in jsonLines.split("\n")) {
            val trimmed = line.trim()
            if (trimmed.isEmpty()) continue
            try {
                samples.add(TelemetrySample.fromJson(JSONObject(trimmed)))
            } catch (e: Exception) {
                logger.warn("Skipping malformed telemetry line: " + e.message)
            }
        }
        return samples
    }

    // ==================== INTERNAL HELPERS ====================

    /**
     * Decompress CONCATENATED gzip streams.
     *
     * The gzip format permits streams to be concatenated, each with its own header. Each
     * [GZIPInputStream] consumes exactly one, leaving the underlying stream positioned at the
     * next, so the loop picks up where the last left off. An IOException means trailing garbage
     * or EOF — stop and return what was recovered rather than discarding the whole file.
     */
    private fun decompressConcatenatedGzip(data: ByteArray?): String {
        if (data == null || data.isEmpty()) return ""

        val result = ByteArrayOutputStream()
        val bais = ByteArrayInputStream(data)
        val buffer = ByteArray(4096)

        while (bais.available() > 0) {
            bais.mark(data.size)
            try {
                val gzis = GZIPInputStream(bais)
                var bytesRead: Int
                while (gzis.read(buffer).also { bytesRead = it } != -1) {
                    result.write(buffer, 0, bytesRead)
                }
                gzis.close()
            } catch (e: IOException) {
                break
            }
        }

        return result.toString("UTF-8")
    }

    private fun readAllBytes(file: File): ByteArray {
        val baos = ByteArrayOutputStream(file.length().toInt())
        BufferedInputStream(FileInputStream(file)).use { bis ->
            val buffer = ByteArray(8192)
            var bytesRead: Int
            while (bis.read(buffer).also { bytesRead = it } != -1) {
                baos.write(buffer, 0, bytesRead)
            }
        }
        return baos.toByteArray()
    }
}
