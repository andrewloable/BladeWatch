package net.bladewatch.app.streaming

import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Produces a JPEG from an RGB byte[], or null on failure. Injected so [StillFrameRefresher] is
 * testable without android.graphics.Bitmap -- this project has no Mockito/Robolectric.
 */
fun interface JpegEncoder {
    fun encode(rgb: ByteArray, width: Int, height: Int): ByteArray?
}

/**
 * BladeWatch-y78o.1: a still-frame fallback so the remote Live view degrades to a periodically
 * refreshed still image in browsers with no usable H.264 decoder (Tor Browser on Linux was the
 * documented case -- see BladeWatch-nobf), instead of the dead-end "cannot play" banner.
 *
 * The source frame is [mosaicSource] -- SurveillanceEngineGpu.getLatestMosaicFrame(), the same
 * already-continuously-produced 640x480 RGB buffer SurveillanceApiHandler's quadrant-snapshot
 * route already reads. It updates on every camera frame regardless of whether this class exists,
 * so reading it adds nothing to the hot camera path.
 *
 * What this class DOES add is the JPEG encode -- but only inside [tick], run on its own
 * [refreshIntervalMs] schedule, fully decoupled from camera FPS (a handful of times a minute,
 * not tens of times a second). [current] never encodes; it only ever returns whatever [tick]
 * most recently produced. That split is what satisfies the issue's constraint -- "if retaining
 * it requires a new encode per frame, per view, the answer is no" -- the encode rate is bounded
 * by the refresh interval, not by the camera.
 */
class StillFrameRefresher(
    private val mosaicSource: () -> ByteArray?,
    private val width: Int,
    private val height: Int,
    private val encoder: JpegEncoder,
    private val refreshIntervalMs: Long,
    private val scheduler: ScheduledExecutorService,
) {
    @Volatile
    private var frame: ByteArray? = null

    private var task: ScheduledFuture<*>? = null

    /** The single retained JPEG, or null if none has been produced yet (or streaming stopped). */
    fun current(): ByteArray? = frame

    @Synchronized
    fun start() {
        if (task != null) return
        task = scheduler.scheduleAtFixedRate({ tick() }, 0L, refreshIntervalMs, TimeUnit.MILLISECONDS)
    }

    @Synchronized
    fun stop() {
        task?.cancel(false)
        task = null
        frame = null
    }

    /** One refresh cycle: read the current mosaic, encode it, replace the retained frame. */
    internal fun tick() {
        val rgb = mosaicSource() ?: return
        val jpeg = encoder.encode(rgb, width, height) ?: return
        frame = jpeg
    }
}
