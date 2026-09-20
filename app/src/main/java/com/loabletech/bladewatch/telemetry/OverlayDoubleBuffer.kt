package net.bladewatch.app.telemetry

import android.graphics.Bitmap

/**
 * Double-buffer for overlay bitmap rendering: a background thread writes the back bitmap, the GL
 * thread reads the front one.
 *
 * Thread safety: [swapReady] is volatile and the swap itself is `@Synchronized`.
 */
internal class OverlayDoubleBuffer(width: Int, height: Int) {

    private var frontBitmap: Bitmap? = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    private var backBitmap: Bitmap? = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

    @Volatile
    private var swapReady = false

    /** The back bitmap, for Canvas rendering by the background thread. */
    fun getBackForWriting(): Bitmap? = backBitmap

    /** Signals that the back bitmap is fully rendered and ready to swap. */
    fun markBackReady() {
        swapReady = true
    }

    /**
     * Swaps front/back and returns the new front when a frame is ready, otherwise null.
     *
     * Returning null when no swap occurred lets the GL thread skip the expensive `texImage2D`
     * upload — the previously uploaded texture is still valid.
     */
    @Synchronized
    fun swapAndGetFront(): Bitmap? {
        if (!swapReady) return null
        val temp = frontBitmap
        frontBitmap = backBitmap
        backBitmap = temp
        swapReady = false
        return frontBitmap
    }

    /**
     * The current front bitmap, without swapping. Used when the GL thread needs the reference
     * but no new content is available.
     */
    fun getFront(): Bitmap? = frontBitmap

    /** Recycles both bitmaps and clears the references. */
    fun release() {
        frontBitmap?.recycle()
        frontBitmap = null
        backBitmap?.recycle()
        backBitmap = null
    }
}
