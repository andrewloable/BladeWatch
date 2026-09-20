package net.bladewatch.app.server

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.surveillance.GpuPipelineConfig
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStream
import java.util.Locale

/**
 * Manages WebSocket streaming configuration and control, behind `StreamService`.
 *
 * PARTIALLY exempt from the REST inversion (BladeWatch-6mnq): the only HTTP route left is
 * `GET /api/stream/still`, a JPEG the Angular live view consumes as an image URL, so it cannot
 * speak ConnectRPC. Every other stream operation is JSON, is reached through `StreamService`, and
 * returns its value rather than writing it into a stream.
 *
 * The header block in [sendStillFrame] is built from CONCATENATED string literals on purpose:
 * ResponseFramingTest reads it as source text.
 */
object StreamingApiHandler {

    private var streamingQuality = "LOW" // Default to LOW for better performance

    private val MODE_NAMES = arrayOf("Mosaic", "Front", "Right", "Rear", "Left", "Raw")

    /** The ONLY HTTP entry point left here. */
    @JvmStatic
    @Throws(Exception::class)
    fun handle(method: String, path: String, body: String?, out: OutputStream): Boolean {
        if (path == "/api/stream/still" && method == "GET") {
            handleStillFrame(out)
            return true
        }
        return false
    }

    /**
     * BladeWatch-y78o.1: serves the still-frame fallback JPEG. Thin — all it does is fetch the
     * retained bytes and hand them to [sendStillFrame], which is the actually-tested part (this
     * method itself needs a running pipeline, like every other handler in this class, so it is
     * exercised on-device rather than in a JVM unit test).
     */
    @Throws(Exception::class)
    private fun handleStillFrame(out: OutputStream) {
        val pipeline = CameraDaemon.getGpuPipeline()
        sendStillFrame(out, pipeline?.latestStillFrame)
    }

    /**
     * Writes the still-frame HTTP response. A present, non-empty frame is 200 image/jpeg; an
     * absent or empty one is an explicit 503 — never a 200 with a zero-length body, which would
     * read to a client as a valid-but-corrupt image rather than "not ready yet".
     */
    @JvmStatic
    @Throws(Exception::class)
    internal fun sendStillFrame(out: OutputStream, jpeg: ByteArray?) {
        if (jpeg == null || jpeg.isEmpty()) {
            HttpResponse.sendError(out, 503, "No still frame available yet")
            return
        }
        val header = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: image/jpeg\r\n" +
            "Content-Length: " + jpeg.size + "\r\n" +
            "Cache-Control: no-cache\r\n" +
            "\r\n"
        out.write(header.toByteArray())
        out.write(jpeg)
        out.flush()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun enableStreaming(): JSONObject {
        val pipeline = CameraDaemon.getGpuPipeline()

        CameraDaemon.log(
            "handleEnableStreaming: pipeline=" + (pipeline != null) +
                ", running=" + (pipeline != null && pipeline.isRunning)
        )

        if (pipeline == null) {
            throw ConnectException(
                "internal", Messages.get("errors.streaming_pipeline_not_initialized")
            )
        }

        // Auto-start the pipeline if it is not running. Warm com.byd.avc first so a cold camera
        // HAL doesn't deliver black frames — see setStreamViewMode for the same rationale.
        if (!pipeline.isRunning) {
            try {
                CameraDaemon.log(
                    "handleEnableStreaming: warming up AVC HAL before pipeline cold start"
                )
                check(
                    CameraDaemon.ensureAvcWarmupStarted(
                        "StreamingApiHandler.handleEnableStreaming"
                    )
                ) { "AVC warmup failed" }
                CameraDaemon.log("handleEnableStreaming: auto-starting pipeline for streaming")
                pipeline.start()
                Thread.sleep(500)
            } catch (e: Exception) {
                CameraDaemon.log(
                    "handleEnableStreaming: failed to start pipeline - " + e.message
                )
                throw ConnectException(
                    "internal",
                    Messages.get("errors.streaming_start_failed_with_detail", e.message)
                )
            }
        }

        if (pipeline.isStreamingEnabled) {
            CameraDaemon.log("handleEnableStreaming: already enabled")
            val response = JSONObject()
            response.put("success", true)
            response.put("message", Messages.get("messages.streaming_already_enabled"))
            response.put("wsPort", 8887)
            return response
        }

        try {
            val q = GpuPipelineConfig.StreamingQuality.fromString(streamingQuality)
            CameraDaemon.log("handleEnableStreaming: quality=" + q.displayName)
            pipeline.enableStreaming(q.width, q.height, q.fps, q.bitrate)

            CameraDaemon.log("handleEnableStreaming: success")
            val response = JSONObject()
            response.put("success", true)
            response.put("message", Messages.get("messages.streaming_enabled"))
            response.put("wsPort", 8887)
            response.put("quality", q.name)
            response.put("resolution", q.width.toString() + "x" + q.height)
            response.put("fps", q.fps)
            response.put("bitrate", q.bitrate)
            return response
        } catch (e: Exception) {
            CameraDaemon.log("handleEnableStreaming: error - " + e.message)
            throw ConnectException("internal", e.message ?: "An internal error occurred")
        }
    }

    @JvmStatic
    @Throws(Exception::class)
    fun disableStreaming(): JSONObject {
        val pipeline = CameraDaemon.getGpuPipeline()
            ?: throw ConnectException(
                "internal", Messages.get("errors.streaming_pipeline_not_available")
            )

        pipeline.disableStreaming()

        val response = JSONObject()
        response.put("success", true)
        response.put("message", Messages.get("messages.streaming_disabled"))
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun streamStatus(): JSONObject {
        val pipeline = CameraDaemon.getGpuPipeline()

        val response = JSONObject()
        response.put("pipelineRunning", pipeline != null && pipeline.isRunning)
        response.put("streamingEnabled", pipeline != null && pipeline.isStreamingEnabled)
        response.put("wsPort", 8887)

        if (pipeline != null && pipeline.isStreamingEnabled) {
            val vm = pipeline.streamViewMode
            response.put("viewMode", vm)
            response.put("viewName", if (vm in 0..4) MODE_NAMES[vm] else "Unknown")
        }

        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun streamQualityOptions(): JSONObject {
        CameraDaemon.log("sendStreamQualityOptions: current=$streamingQuality")
        val response = JSONObject()
        response.put("success", true)
        response.put("current", streamingQuality)

        val options = JSONArray()
        for (q in GpuPipelineConfig.StreamingQuality.values()) {
            val opt = JSONObject()
            opt.put("id", q.name)
            opt.put("name", q.displayName)
            opt.put("width", q.width)
            opt.put("height", q.height)
            opt.put("fps", q.fps)
            opt.put("bitrate", q.bitrate)
            opt.put("bitrateKbps", q.bitrate / 1000)
            options.put(opt)
        }
        response.put("options", options)

        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun setStreamQuality(quality: String): JSONObject {
        val newQuality = GpuPipelineConfig.StreamingQuality.fromString(quality)

        streamingQuality = newQuality.name
        CameraDaemon.setStreamingQuality(quality)

        // Persist to UnifiedConfigManager (streaming.quality) so the choice survives a daemon
        // restart. Mirrors the recording-side flow where QualitySettingsApiHandler.persistSettings
        // is the single canonical writer for both recording and streaming sections — without this
        // call the in-memory streamingQuality field is the only record of the user's pick, and a
        // kill/restart silently reverts to whatever the on-disk default seeded (MEDIUM).
        QualitySettingsApiHandler.persistSettings()

        // The preference is applied on the next stream start. The active stream is deliberately
        // NOT restarted, to avoid disrupting the live view; the /ws handler applies the quality
        // when the client reconnects.
        CameraDaemon.log(
            "Streaming quality set to: " + newQuality.displayName + " (persisted)"
        )

        val response = JSONObject()
        response.put("success", true)
        response.put("quality", newQuality.name)
        response.put("displayName", newQuality.displayName)
        response.put("width", newQuality.width)
        response.put("height", newQuality.height)
        response.put("fps", newQuality.fps)
        response.put("bitrate", newQuality.bitrate)
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun setStreamViewMode(viewMode: Int): JSONObject {
        val pipeline = CameraDaemon.getGpuPipeline()
            ?: throw ConnectException(
                "internal", Messages.get("errors.streaming_pipeline_not_available")
            )

        if (viewMode < 0 || viewMode > 5) {
            throw ConnectException(
                "internal", Messages.get("errors.streaming_invalid_view_mode")
            )
        }

        // Auto-start the pipeline if it is not running.
        //
        // CRITICAL: warm up com.byd.avc BEFORE opening the camera. On DiLink5 a cold camera HAL
        // (e.g. the user opens the stream while ACC is OFF and surveillance is disabled, so
        // com.byd.avc was never launched this session) returns valid handles but delivers black
        // frames. The warmup launches com.byd.avc/.MainActivity silently, which initialises the
        // multi-consumer HAL. Same fix used by RecordingModeManager during cold start. Skipped
        // when the pipeline is already running — the camera is open and com.byd.avc must already
        // be alive.
        if (!pipeline.isRunning) {
            try {
                CameraDaemon.log(
                    "handleStreamViewMode: warming up AVC HAL before pipeline cold start"
                )
                // Blocks ~4s; safe — runs on the HTTP worker thread.
                check(
                    CameraDaemon.ensureAvcWarmupStarted(
                        "StreamingApiHandler.handleStreamViewMode"
                    )
                ) { "AVC warmup failed" }
                CameraDaemon.log("handleStreamViewMode: auto-starting pipeline")
                pipeline.start()
                Thread.sleep(500)
            } catch (e: Exception) {
                throw ConnectException(
                    "internal",
                    Messages.get("errors.streaming_start_failed_with_detail", e.message)
                )
            }
        }

        // Enable streaming first if it is not enabled
        if (!pipeline.isStreamingEnabled) {
            try {
                CameraDaemon.log("Enabling streaming before setting view mode")
                val q = GpuPipelineConfig.StreamingQuality.fromString(streamingQuality)
                pipeline.enableStreaming(q.width, q.height, q.fps, q.bitrate)
                Thread.sleep(500)
            } catch (e: Exception) {
                throw ConnectException(
                    "internal",
                    Messages.get("errors.streaming_enable_failed_with_detail", e.message)
                )
            }
        }

        pipeline.streamViewMode = viewMode

        CameraDaemon.log(
            "Stream view mode set to: " +
                (if (viewMode < MODE_NAMES.size) MODE_NAMES[viewMode] else "Unknown")
        )

        val response = JSONObject()
        response.put("success", true)
        response.put("viewMode", viewMode)
        response.put(
            "viewName", if (viewMode < MODE_NAMES.size) MODE_NAMES[viewMode] else "Unknown"
        )
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun streamViewMode(): JSONObject {
        val pipeline = CameraDaemon.getGpuPipeline()

        val viewMode = pipeline?.streamViewMode ?: -1

        val response = JSONObject()
        response.put("success", true)
        response.put("viewMode", viewMode)
        response.put(
            "viewName",
            if (viewMode >= 0 && viewMode < MODE_NAMES.size) MODE_NAMES[viewMode] else "Unknown"
        )
        return response
    }

    // Static getters/setters for cross-component access
    @JvmStatic
    fun getStreamingQuality(): String = streamingQuality

    @JvmStatic
    fun setStreamingQuality(quality: String?) {
        if (quality == null) return
        val q = quality.uppercase(Locale.ROOT)
        // Mirror the StreamingQuality enum (GpuPipelineConfig). SMOOTH and MAX are recent
        // additions; the cold-start loader (QualitySettingsApiHandler.loadPersistedSettings)
        // calls this with whatever tag is on disk, so if we silently reject MAX here the
        // persisted user pick decays to the hard-coded default after every daemon restart.
        when (q) {
            "ULTRA_LOW", "LOW", "MEDIUM", "HIGH", "ULTRA_HIGH", "SMOOTH", "MAX", "LQ", "HQ" ->
                streamingQuality = q
            // Unknown tag — leave the previous value intact.
        }
    }
}
