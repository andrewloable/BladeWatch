package net.bladewatch.app.streaming

import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * BladeWatch-y78o.1: a still-frame fallback so the remote Live view degrades to a periodically
 * refreshed still image in browsers with no usable H.264 decoder (Tor Browser on Linux was the
 * documented case -- see BladeWatch-nobf), instead of the dead-end "cannot play" banner. Since
 * BladeWatch-rdtj.11 it is also the companion's live view.
 *
 * The source is whatever [source] returns: since BladeWatch-rdtj.68, GpuStillCapture's shot of all
 * four cameras at 1280x960 or one camera at its native 1280x960, captured every 100ms (10fps,
 * BladeWatch-hmk0) on the camera's GL thread while someone watches. [encoder] turns it into a JPEG.
 *
 * What this class adds is the JPEG encode -- but only inside [tick], run on its own
 * [refreshIntervalMs] schedule, fully decoupled from camera FPS. [current] never encodes; it only
 * ever returns whatever [tick] most recently produced. That split is what satisfies the issue's
 * constraint -- "if retaining it requires a new encode per frame, per view, the answer is no" --
 * the encode rate is bounded by the refresh interval, not by the camera. Injected so it is
 * testable without android.graphics.Bitmap (this project has no Mockito/Robolectric).
 */
class StillFrameRefresher<T : Any>(
    private val source: () -> T?,
    private val encoder: (T) -> ByteArray?,
    private val refreshIntervalMs: Long,
    private val scheduler: ScheduledExecutorService,
    /**
     * A number that changes whenever the source holds a new frame, or [NO_VERSION] if the source
     * cannot say. A tick with nothing new keeps the retained still, byte for byte, and encodes
     * nothing (BladeWatch-rdtj.61: "update only when a frame is available").
     */
    private val sourceVersion: () -> Long = { NO_VERSION },
) {
    /** A retained JPEG and the source it was encoded from, read together. */
    class Still<T>(val jpeg: ByteArray, val source: T)

    @Volatile
    private var still: Still<T>? = null

    private var encodedVersion = NO_VERSION

    private var task: ScheduledFuture<*>? = null

    /** The single retained JPEG, or null if none has been produced yet (or streaming stopped). */
    fun current(): ByteArray? = still?.jpeg

    /** The retained JPEG with what it shows. */
    fun latest(): Still<T>? = still

    @Synchronized
    fun start() {
        if (task != null) return
        task = scheduler.scheduleAtFixedRate({ tick() }, 0L, refreshIntervalMs, TimeUnit.MILLISECONDS)
    }

    @Synchronized
    fun stop() {
        task?.cancel(false)
        task = null
        still = null
    }

    /** One refresh cycle: read the source, encode it, replace the retained still. */
    internal fun tick() {
        val version = sourceVersion()
        if (version != NO_VERSION && version == encodedVersion && still != null) return
        val src = source() ?: return
        val jpeg = encoder(src) ?: return
        still = Still(jpeg, src)
        encodedVersion = version
    }

    companion object {
        const val NO_VERSION = -1L
    }
}
