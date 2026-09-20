package net.bladewatch.app.proximity

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.notifications.NotificationBus
import net.bladewatch.app.notifications.NotificationEvent
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.surveillance.GpuSurveillancePipeline

import org.json.JSONObject

import java.io.File
import java.net.URLEncoder

/**
 * Proximity Recording Handler
 *
 * Manages the recording lifecycle for Proximity Guard events:
 * - Pre-buffer capture
 * - Recording start/stop
 * - File naming with proximity_ prefix
 * - Storage management
 * - Push notifications
 */
class ProximityRecordingHandler(private val pipeline: GpuSurveillancePipeline?) {

    private val storageManager: StorageManager = StorageManager.getInstance()

    private var outputDir: File = storageManager.proximityDir

    /** Get current trigger level. */
    var currentTriggerLevel: String? = null
        private set

    /** Check if currently recording. */
    var isRecording: Boolean = false
        private set

    // Filename captured when the start-stage push was published. Reused on
    // stop so the matching final-stage push uses the same tag (Web Push
    // tag-replace semantics: a later push with the same tag swaps the
    // banner) and points at the now-finalised .mp4 + sibling hero JPEG.
    private var activeRecordingFile: String? = null

    /**
     * Start proximity recording.
     *
     * @param triggerLevel The trigger level that caused recording ("YELLOW" or "RED")
     */
    fun startRecording(triggerLevel: String) {
        if (isRecording) {
            logger.warn("Already recording, ignoring start request")
            return
        }

        currentTriggerLevel = triggerLevel

        try {
            // Ensure space available (reserve 50MB)
            if (!storageManager.ensureProximitySpace(50L * 1024 * 1024)) {
                logger.error("Insufficient space for proximity recording")
                return
            }

            // Get proximity output directory
            outputDir = storageManager.proximityDir

            // Start recording with proximity directory and prefix
            pipeline?.startRecording(outputDir, "proximity")
            isRecording = true

            logger.info(
                "Proximity recording started: trigger=" + triggerLevel +
                    " dir=" + outputDir.absolutePath
            )

            // Publish to NotificationBus → push notifications
            publishProximityNotification(triggerLevel)
        } catch (e: Exception) {
            logger.error("Failed to start proximity recording: " + e.message)
            e.printStackTrace()
        }
    }

    /**
     * Publish a proximity notification onto the cross-cutting NotificationBus.
     *
     * RED trigger (`<0.5m`) is treated as critical so it overrides
     * the user's quiet hours. YELLOW (`0.5–0.8m`) is warn.
     */
    private fun publishProximityNotification(triggerLevel: String) {
        try {
            val data = JSONObject()
            data.put("triggerLevel", triggerLevel)

            // The pipeline's encoder was started above with the proximity_
            // prefix. Pull the active output path so the push deep-links to
            // the exact clip being recorded and renders its thumbnail.
            val filename = activeRecordingFilename()
            activeRecordingFile = filename
            val url: String
            if (filename != null) {
                data.put("filename", filename)
                // Mark as the start-stage event. The hero JPEG is only
                // written when the segment finalises in stopRecording, so
                // pointing the SW at a still-live .mp4 right now would only
                // hit MMR's 202-while-generating window. Carrying stage so
                // the SW skips the snapshot fetch on this event. The
                // matching final-stage push fires from stopRecording with
                // the same tag and a real signed snapshot URL.
                data.put("stage", "start")
                url = "/events?filter=proximity&file=" + URLEncoder.encode(filename, "UTF-8")
            } else {
                url = "/events?filter=proximity"
            }

            publish(triggerLevel, url, data)
        } catch (t: Throwable) {
            logger.debug("publishProximityNotification failed: " + t.message)
        }
    }

    private fun activeRecordingFilename(): String? = try {
        val path = pipeline?.encoder?.getCurrentOutputPath()
        if (path.isNullOrEmpty()) {
            null
        } else {
            val slash = path.lastIndexOf('/')
            if (slash >= 0) path.substring(slash + 1) else path
        }
    } catch (t: Throwable) {
        logger.warn("Failed to get active recording filename: " + t.message)
        null
    }

    /** Stop proximity recording. */
    fun stopRecording() {
        if (!isRecording) {
            return
        }

        val triggerLevelAtStop = currentTriggerLevel
        val videoFile = activeRecordingFile

        try {
            // Stop recording
            pipeline?.stopRecording()
            isRecording = false

            logger.info("Proximity recording stopped")

            // Trigger cleanup
            storageManager.onProximityFileSaved()

            // Final-stage push with the now-finalised hero JPEG. The start
            // push deliberately skipped the snapshot URL because the hero
            // JPEG is only written when stopRecording finalises the segment.
            // Reusing the same notification tag ("proximity-<level>") so
            // Web Push tag-replace semantics swap the banner image in
            // place rather than stacking a second card.
            publishProximityFinal(triggerLevelAtStop, videoFile)
        } catch (e: Exception) {
            logger.error("Failed to stop proximity recording: " + e.message)
            e.printStackTrace()
        } finally {
            activeRecordingFile = null
        }
    }

    /**
     * Publish the final-stage push for a proximity recording. Carries a
     * signed snapshot URL pointing at the sibling hero JPEG (`base.jpg`
     * written by HardwareEventRecorderGpu on segment finalisation). When
     * the JPEG is missing (rare — encoder error), falls back to the .mp4
     * which the server resolves via MMR.
     */
    private fun publishProximityFinal(triggerLevel: String?, videoFile: String?) {
        if (videoFile.isNullOrEmpty()) return
        try {
            val data = JSONObject()
            data.put("triggerLevel", triggerLevel)
            data.put("filename", videoFile)
            data.put("stage", "final")

            val heroName = if (videoFile.endsWith(".mp4")) {
                videoFile.substring(0, videoFile.length - 4) + ".jpg"
            } else {
                "$videoFile.jpg"
            }
            val snapshotName = if (File(outputDir, heroName).exists()) heroName else videoFile
            val thumbTok = AuthManager.signThumbToken(snapshotName, 600L)
            var snapUrl = "/thumb/" + URLEncoder.encode(snapshotName, "UTF-8")
            if (thumbTok != null) snapUrl += "?t=$thumbTok"
            data.put("snapshot", snapUrl)

            val url = "/events?filter=proximity&file=" + URLEncoder.encode(videoFile, "UTF-8")

            publish(triggerLevel, url, data)
        } catch (t: Throwable) {
            logger.debug("publishProximityFinal failed: " + t.message)
        }
    }

    /**
     * The one NotificationEvent shape both stages publish. Only the url and data differ
     * between them; severity, titles and the tag are a pure function of the trigger level,
     * and the tag is what gives the final-stage push its banner-replace behaviour.
     */
    private fun publish(triggerLevel: String?, url: String, data: JSONObject) {
        val red = "RED" == triggerLevel
        NotificationBus.get().publish(
            NotificationEvent(
                "surveillance.proximity",
                if (red) NotificationEvent.Severity.CRITICAL else NotificationEvent.Severity.WARN,
                if (red) "Object very close" else "Object nearby",
                if (red) "Within 0.5 m" else "Within 0.8 m",
                "proximity-$triggerLevel",
                url,
                data
            )
        )
    }

    /**
     * Extend current recording (new trigger while already recording).
     * Does not create a new file - just logs the extension.
     * The 2-minute segment handling is done by the encoder.
     *
     * @param triggerLevel The new trigger level
     */
    fun extendRecording(triggerLevel: String) {
        if (!isRecording) {
            logger.warn("Cannot extend - not recording")
            return
        }

        logger.info(
            "Extending proximity recording: new trigger=" + triggerLevel +
                " (previous=" + currentTriggerLevel + ")"
        )

        // Update trigger level if higher priority
        if (triggerLevel == "RED" && currentTriggerLevel != "RED") {
            currentTriggerLevel = triggerLevel
            logger.info("Upgraded trigger level to RED")
        }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("ProximityRecordingHandler")
    }
}
