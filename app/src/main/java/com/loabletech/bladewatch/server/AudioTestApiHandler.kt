package net.bladewatch.app.server

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.min

/**
 * Test entry point for AVAS (exterior) speaker audio playback.
 *
 * Tests whether the AVAS speaker can play audio when the vehicle is off, using BydDataCollector's
 * multimedia device directly — the same pattern as all other BYD HAL access.
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/audio/ paths and writing JSON into an
 * OutputStream that the Connect layer captured straight back out. Both operations now RETURN their
 * JSON.
 */
object AudioTestApiHandler {

    private val logger: DaemonLogger = DaemonLogger.getInstance("AudioTestApi")

    /**
     * Read-only AVAS state query.
     *
     * No RPC exposes this — it was reachable only over `GET /api/audio/avas-state`, which had no
     * first-party caller. Kept rather than deleted because it is the diagnostic that tells you WHY
     * a speaker test did nothing (the IVI multimedia service returning null when the car is off
     * looks identical to a broken speaker from the test alone), and adding an RPC for it is a
     * smaller job than reconstructing the probe. See BladeWatch-6mnq.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun getState(): JSONObject {
        val response = JSONObject()
        try {
            val collector = BydDataCollector.getInstance()

            response.put("multimediaAvailable", collector.isMultimediaAvailable)
            response.put("collectorInitialized", collector.isInitialized)

            if (!collector.isMultimediaAvailable) {
                // The multimedia device returned null from getInstance() — the IVI audio service
                // isn't running (car off / multimedia subsystem powered down). We can still try
                // playing audio through Android's standard audio path.
                response.put("success", true)
                response.put(
                    "warning",
                    "Multimedia device unavailable (getInstance returned null). AVAS routing not " +
                        "possible, but standard audio output may still work."
                )
                response.put("canPlayStandardAudio", true)
                return response
            }

            val speakerState = collector.exteriorSpeakerState
            val avasSource = collector.avasSoundSource

            response.put("success", true)
            response.put("exteriorSpeakerState", speakerState ?: JSONObject.NULL)
            response.put(
                "exteriorSpeakerEnabled",
                if (speakerState != null) speakerState == 1 else JSONObject.NULL
            )
            response.put("avasSource", avasSource ?: JSONObject.NULL)

            // Probe the multimedia device for any related methods so we can see what the OEM build
            // actually exposes (method names vary across BYD models).
            val probeArr = JSONArray()
            for (s in collector.probeMultimediaMethods(
                "AVAS|Speaker|Sound|External|Exterior|Outside|Avas"
            )) {
                probeArr.put(s)
            }
            response.put("probedMethods", probeArr)
        } catch (e: Exception) {
            logger.warn("avas-state failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
        }
        return response
    }

    /**
     * Force-enable AVAS and play audio.
     *
     * Body (all optional):
     * ```
     * {
     *   "mode": "tone" | "tts" | "file",   // default: "tone"
     *   "sourceType": 3,                   // AVAS source type to try (default: 3)
     *   "volume": 20,                      // media volume 0-39 (default: 20)
     *   "duration": 3000,                  // tone duration ms (default: 3000)
     *   "text": "Hello from AVAS",         // TTS text (default: "AVAS speaker test")
     *   "restore": true                    // restore original state after (default: true)
     * }
     * ```
     */
    @JvmStatic
    @Throws(Exception::class)
    fun testAvas(requestBody: String?): JSONObject {
        val response = JSONObject()
        val log = JSONObject()

        try {
            // Parse request
            var mode = "tone"
            var sourceType = 3 // media
            var volume = 20
            var duration = 3000
            var ttsText = "AVAS speaker test"
            var restore = true

            if (!requestBody.isNullOrEmpty()) {
                val req = JSONObject(requestBody)
                mode = req.optString("mode", "tone")
                sourceType = req.optInt("sourceType", 3)
                volume = min(req.optInt("volume", 20), 30) // safety cap
                duration = min(req.optInt("duration", 3000), 10000) // max 10s
                ttsText = req.optString("text", "AVAS speaker test")
                restore = req.optBoolean("restore", true)
            }

            logger.info(
                "test-avas: mode=" + mode + " source=" + sourceType +
                    " vol=" + volume + " dur=" + duration
            )

            val collector = BydDataCollector.getInstance()
            val multimediaAvailable = collector.isMultimediaAvailable
            log.put("multimediaAvailable", multimediaAvailable)

            // Step 1: save the original state (only if the multimedia device is available)
            var origSpeaker: Int? = null
            var origSource: Int? = null

            if (multimediaAvailable) {
                origSpeaker = collector.exteriorSpeakerState
                origSource = collector.avasSoundSource

                log.put(
                    "originalState",
                    JSONObject()
                        .put("speakerState", origSpeaker ?: JSONObject.NULL)
                        .put("avasSource", origSource ?: JSONObject.NULL)
                )

                logger.info(
                    "test-avas: original: speaker=" + origSpeaker + " source=" + origSource
                )

                // Step 2: force-enable the AVAS speaker
                val speakerOk = collector.setExteriorSpeakerState(1)
                val sourceOk = collector.setAVASSoundSource(sourceType)

                log.put(
                    "setup",
                    JSONObject()
                        .put("speakerEnabled", speakerOk)
                        .put("avasSourceSet", sourceOk)
                        .put("sourceType", sourceType)
                )

                logger.info("test-avas: setup: speaker=" + speakerOk + " source=" + sourceOk)
            } else {
                log.put("originalState", "skipped (multimedia device unavailable)")
                log.put("setup", "skipped (playing through standard Android audio output)")
                logger.info("test-avas: multimedia unavailable, playing through standard audio")
            }

            // Step 3: play audio
            val playOk = when (mode) {
                "tts" -> playTts(ttsText, duration + 2000)
                "file" -> playFile(duration)
                else -> playTone(duration)
            }

            log.put("playback", JSONObject().put("mode", mode).put("success", playOk))

            logger.info("test-avas: playback " + mode + " = " + playOk)

            // Step 4: restore the original state
            if (restore && multimediaAvailable) {
                var restoreSpeaker = true
                var restoreSource = true

                if (origSpeaker != null) {
                    restoreSpeaker = collector.setExteriorSpeakerState(origSpeaker)
                }
                if (origSource != null) {
                    restoreSource = collector.setAVASSoundSource(origSource)
                }

                log.put(
                    "restore",
                    JSONObject().put("speaker", restoreSpeaker).put("source", restoreSource)
                )
            }

            // Step 5: verify the final state
            if (multimediaAvailable) {
                log.put(
                    "finalState",
                    JSONObject()
                        .put("speakerState", collector.exteriorSpeakerState ?: JSONObject.NULL)
                        .put("avasSource", collector.avasSoundSource ?: JSONObject.NULL)
                )
            }

            response.put("success", true)
            response.put("log", log)
        } catch (e: Exception) {
            logger.warn("test-avas failed: " + e.message)
            response.put("success", false)
            response.put("error", e.message)
            response.put("log", log)
        }
        return response
    }

    // ==================== AUDIO PLAYBACK ====================

    /** Play a tone via ToneGenerator on STREAM_MUSIC. */
    private fun playTone(durationMs: Int): Boolean = try {
        val tg = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
        tg.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, durationMs)
        Thread.sleep((durationMs + 500).toLong())
        tg.release()
        logger.info("playTone: completed (" + durationMs + "ms)")
        true
    } catch (e: Exception) {
        logger.warn("playTone failed: " + e.message)
        false
    }

    /** Play TTS via Android TextToSpeech on STREAM_MUSIC. */
    private fun playTts(text: String, timeoutMs: Int): Boolean {
        val ctx = CameraDaemon.getAppContext()
        if (ctx == null) {
            logger.warn("playTts: no context available")
            return false
        }

        val initLatch = CountDownLatch(1)
        val doneLatch = CountDownLatch(1)
        val initOk = AtomicBoolean(false)

        return try {
            val tts = TextToSpeech(ctx) { status ->
                initOk.set(status == TextToSpeech.SUCCESS)
                initLatch.countDown()
            }

            if (!initLatch.await(5, TimeUnit.SECONDS)) {
                logger.warn("playTts: TTS init timeout")
                tts.shutdown()
                return false
            }

            if (!initOk.get()) {
                logger.warn("playTts: TTS init failed")
                tts.shutdown()
                return false
            }

            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {}
                override fun onDone(utteranceId: String?) {
                    doneLatch.countDown()
                }

                @Deprecated("Required abstract callback on older TTS engines.")
                override fun onError(utteranceId: String?) {
                    doneLatch.countDown()
                }
            })

            val params = Bundle()
            params.putInt(TextToSpeech.Engine.KEY_PARAM_STREAM, AudioManager.STREAM_MUSIC)
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, params, "avas_test")

            val completed = doneLatch.await(timeoutMs.toLong(), TimeUnit.MILLISECONDS)
            tts.shutdown()

            logger.info("playTts: " + (if (completed) "completed" else "timed out"))
            completed
        } catch (e: Exception) {
            logger.warn("playTts failed: " + e.message)
            false
        }
    }

    /** Play a beep pattern using ToneGenerator (distinguishable from a single tone). */
    private fun playFile(durationMs: Int): Boolean = try {
        val tg = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
        for (i in 0 until 3) {
            tg.startTone(ToneGenerator.TONE_PROP_BEEP, 500)
            Thread.sleep(700)
        }
        tg.release()
        logger.info("playFile (beep pattern): completed")
        true
    } catch (e: Exception) {
        logger.warn("playFile failed: " + e.message)
        false
    }
}
