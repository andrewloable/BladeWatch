package net.bladewatch.app.surveillance

import android.graphics.PixelFormat
import android.media.Image
import android.media.ImageReader
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLContext
import android.opengl.EGLDisplay
import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.os.Handler
import android.os.HandlerThread

import net.bladewatch.app.camera.GlUtil
import net.bladewatch.app.logging.DaemonLogger

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.Arrays

/**
 * AsyncGpuDownscaler - Zero-stutter GPU thumbnail generator.
 *
 * Uses a dedicated background thread with EGL context sharing to avoid
 * expensive eglMakeCurrent calls on the main render thread.
 *
 * Key features:
 * - Dedicated background thread (never touches main thread's EGL)
 * - Shared EGL context (can read main thread's camera texture)
 * - ImageReader DMA output (zero-copy to system RAM)
 * - Non-blocking postFrame() returns instantly
 *
 * USAGE:
 * 1. Initialize from GL thread (onSurfaceCreated):
 *    gpuDownscaler.init(EGL14.eglGetCurrentContext());
 *
 * 2. In onDrawFrame (main thread):
 *    drawCameraPreview();
 *    GLES20.glFlush();  // Ensure texture is ready before background reads it
 *    gpuDownscaler.postFrame(cameraTextureId);
 *
 * 3. In AI thread:
 *    Image image = gpuDownscaler.acquireLatestImage();
 *    if (image != null) {
 *        ByteBuffer buf = GpuDownscaler.getDirectBuffer(image);
 *        tflite.run(buf, output);  // Zero-copy!
 *        image.close();
 *    }
 */
class GpuDownscaler {

    /** ImageReader for DMA output */
    private var imageReader: ImageReader? = null

    // Background thread
    private var renderThread: HandlerThread? = null
    private var renderHandler: Handler? = null

    // EGL state (owned by background thread)
    private var eglDisplay: EGLDisplay? = null
    private var eglContext: EGLContext? = null
    private var eglSurface: EGLSurface? = null

    /** Shared context from main thread */
    private var sharedContext: EGLContext? = null

    // Shader program
    private var programId = 0
    private var aPositionLocation = 0
    private var aTexCoordLocation = 0
    private var uCameraTexLocation = 0

    // Vertex buffers
    private var vertexBuffer: FloatBuffer? = null
    private var texCoordBuffer: FloatBuffer? = null

    @Volatile
    private var initialized = false

    /** SOTA FIX: Reusable RGB buffer to eliminate 900KB allocation per frame */
    private var reusableRgbBuffer: ByteArray? = null

    /**
     * Creates the async downscaler with shared EGL context.
     *
     * @param mainThreadContext EGL context from main render thread (for texture sharing)
     */
    constructor(mainThreadContext: EGLContext?) {
        startRenderThread(mainThreadContext)
    }

    /** Default constructor - call init() later with context. */
    constructor() {
        // Will be initialized via init()
    }

    /** Initialize with main thread's EGL context. */
    fun init(mainThreadContext: EGLContext?) {
        startRenderThread(mainThreadContext)
    }

    private fun startRenderThread(mainThreadContext: EGLContext?) {
        sharedContext = mainThreadContext

        val thread = HandlerThread("GpuDownscalerThread")
        renderThread = thread
        thread.start()
        val handler = Handler(thread.looper)
        renderHandler = handler

        // Initialize EGL on background thread
        handler.post { initGlOnThread() }
    }

    /**
     * Legacy init - grabs current context automatically.
     *
     * ⚠️ WARNING: Must be called from GL thread (e.g., onSurfaceCreated), NOT from
     * Activity.onCreate() or UI thread! The UI thread has no EGL context.
     *
     * If called from wrong thread, EGL14.eglGetCurrentContext() returns EGL_NO_CONTEXT
     * and texture sharing will silently fail.
     */
    fun init() {
        val ctx = EGL14.eglGetCurrentContext()
        if (ctx == EGL14.EGL_NO_CONTEXT) {
            logger.error(
                "init() called without EGL context! Must call from GL thread (onSurfaceCreated)"
            )
            throw IllegalStateException("GpuDownscaler.init() must be called from GL thread")
        }
        init(ctx)
    }

    /**
     * Legacy init with grayscale flag (ignored, always RGBA).
     *
     * ⚠️ WARNING: Must be called from GL thread!
     */
    fun init(grayscaleMode: Boolean) {
        init()
    }

    private fun initGlOnThread() {
        try {
            // Setup ImageReader
            val reader = ImageReader.newInstance(WIDTH, HEIGHT, PixelFormat.RGBA_8888, 2)
            imageReader = reader

            // Setup EGL with shared context
            val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
            eglDisplay = display
            val version = IntArray(2)
            EGL14.eglInitialize(display, version, 0, version, 1)

            val configAttribs = intArrayOf(
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
                EGL14.EGL_NONE
            )
            val configs = arrayOfNulls<EGLConfig>(1)
            val numConfigs = IntArray(1)
            EGL14.eglChooseConfig(display, configAttribs, 0, configs, 0, 1, numConfigs, 0)

            // Create context with sharing (can read main thread's textures)
            val contextAttribs = intArrayOf(
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                EGL14.EGL_NONE
            )
            val context =
                EGL14.eglCreateContext(display, configs[0], sharedContext, contextAttribs, 0)
            eglContext = context

            if (context == EGL14.EGL_NO_CONTEXT) {
                throw RuntimeException("Failed to create shared EGL context")
            }

            // Create surface from ImageReader
            val surface = EGL14.eglCreateWindowSurface(
                display, configs[0], reader.surface, intArrayOf(EGL14.EGL_NONE), 0
            )
            eglSurface = surface

            // Make current ONCE AND FOREVER (no more context switching!)
            EGL14.eglMakeCurrent(display, surface, surface, context)

            // Setup shaders
            setupShaders()

            initialized = true
            logger.info("AsyncGpuDownscaler initialized (shared context, zero-stutter)")
        } catch (e: Exception) {
            logger.error("Failed to init GL on thread: " + e.message)
        }
    }

    private fun setupShaders() {
        programId = GlUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        if (programId == 0) {
            throw RuntimeException("Failed to create shader program")
        }

        aPositionLocation = GLES20.glGetAttribLocation(programId, "aPosition")
        aTexCoordLocation = GLES20.glGetAttribLocation(programId, "aTexCoord")
        uCameraTexLocation = GLES20.glGetUniformLocation(programId, "uCameraTex")

        vertexBuffer = GlUtil.createFloatBuffer(VERTEX_COORDS)
        texCoordBuffer = GlUtil.createFloatBuffer(TEX_COORDS)
    }

    /**
     * Non-blocking call to trigger a downscale.
     * Returns immediately - rendering happens on background thread.
     *
     * @param textureId Camera texture ID from main thread
     */
    fun postFrame(textureId: Int) {
        if (!initialized) return
        renderHandler?.post { drawFrame(textureId) }
    }

    /**
     * Get the latest image for AI inference.
     * Call from AI thread, not main thread.
     *
     * @return Image with RGBA data, or null if not available
     */
    fun acquireLatestImage(): Image? = imageReader?.acquireLatestImage()

    private fun drawFrame(textureId: Int) {
        if (!initialized) return

        GLES20.glViewport(0, 0, WIDTH, HEIGHT)
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        GLES20.glUseProgram(programId)

        // Bind main thread's camera texture (allowed via shared context)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId)
        GLES20.glUniform1i(uCameraTexLocation, 0)

        // Draw quad
        GLES20.glEnableVertexAttribArray(aPositionLocation)
        GLES20.glVertexAttribPointer(
            aPositionLocation, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer
        )

        GLES20.glEnableVertexAttribArray(aTexCoordLocation)
        GLES20.glVertexAttribPointer(
            aTexCoordLocation, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer
        )

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(aPositionLocation)
        GLES20.glDisableVertexAttribArray(aTexCoordLocation)

        // Swap to ImageReader (DMA transfer)
        EGL14.eglSwapBuffers(eglDisplay, eglSurface)
    }

    /**
     * Synchronous downscale + readback. Draws the camera texture on the downscaler
     * thread, waits for completion, then reads the result.
     *
     * SOTA: Previous async pattern (postFrame + sleep(5ms) + acquireLatestImage) was
     * unreliable — the 5ms sleep was often not enough for the render thread to complete,
     * resulting in stale frames. This synchronous approach ensures the readback always
     * gets the current frame.
     */
    fun readPixels(cameraTextureId: Int, width: Int, height: Int): ByteArray? {
        if (!initialized) return null
        val handler = renderHandler ?: return null

        // Draw synchronously on the downscaler thread and wait for completion
        val lock = Object()
        val done = booleanArrayOf(false)

        handler.post {
            drawFrame(cameraTextureId)
            synchronized(lock) {
                done[0] = true
                lock.notify()
            }
        }

        // Wait for draw to complete (max 50ms — if it takes longer, skip this frame)
        synchronized(lock) {
            if (!done[0]) {
                try {
                    lock.wait(50)
                } catch (e: InterruptedException) {
                    logger.warn("readPixels wait interrupted: " + e.message)
                    Thread.currentThread().interrupt()
                }
            }
        }

        if (!done[0]) {
            // Render thread didn't complete in time — skip this frame
            return null
        }

        val image = acquireLatestImage() ?: return null

        try {
            val plane = image.planes[0]
            val buffer = plane.buffer
            val rowStride = plane.rowStride
            val pixelStride = plane.pixelStride
            val bufferCapacity = buffer.capacity()

            // SOTA FIX: Reuse buffer instead of allocating new byte[] per frame
            val rgbSize = WIDTH * HEIGHT * 3
            var rgb = reusableRgbBuffer
            if (rgb == null || rgb.size != rgbSize) {
                rgb = ByteArray(rgbSize)
                reusableRgbBuffer = rgb
                logger.info("Allocated reusable RGB buffer: $rgbSize bytes")
            }

            // Validate buffer size before processing
            val expectedSize = (HEIGHT - 1) * rowStride + WIDTH * pixelStride
            if (bufferCapacity < expectedSize) {
                logger.warn(
                    "Buffer too small: " + bufferCapacity + " < " + expectedSize +
                        " (rowStride=" + rowStride + ", pixelStride=" + pixelStride + ")"
                )
                // Return black frame instead of crashing
                Arrays.fill(rgb, 0.toByte())
                return rgb
            }

            // RGBA -> RGB conversion into reusable buffer
            var srcOffset = 0
            var dstOffset = 0
            for (y in 0 until HEIGHT) {
                for (x in 0 until WIDTH) {
                    val srcIdx = srcOffset + x * pixelStride
                    // Safety check (should not trigger if validation above passed)
                    if (srcIdx + 2 >= bufferCapacity) {
                        break
                    }
                    rgb[dstOffset++] = buffer.get(srcIdx) // R
                    rgb[dstOffset++] = buffer.get(srcIdx + 1) // G
                    rgb[dstOffset++] = buffer.get(srcIdx + 2) // B
                }
                srcOffset += rowStride
            }
            return rgb
        } catch (e: Exception) {
            logger.warn("Buffer read error: " + e.javaClass.simpleName)
            // Return black frame on error
            val rgb = reusableRgbBuffer
            if (rgb != null) {
                Arrays.fill(rgb, 0.toByte())
                return rgb
            }
            return null
        } finally {
            image.close()
        }
    }

    // ========================================================================
    // SOTA: Direct GL-thread readback (bypasses broken async ImageReader path)
    // ========================================================================

    private var directFbo = -1
    private var directTexture = -1
    private var directProgram = -1
    private var directAPosition = -1
    private var directATexCoord = -1
    private var directUCameraTex = -1
    private var directReadBuffer: ByteBuffer? = null
    private var directRgbBuffer: ByteArray? = null

    /** bulk-copy RGBA scratch for Y-flip pack */
    private var directScratchRgba: ByteArray? = null
    private var directInitialized = false

    // Double-buffered async readback: eliminates glFinish() stall.
    // We maintain two FBOs. On frame N, we render to FBO[current] and read back
    // from FBO[previous] (which the GPU finished rendering on frame N-1).
    // This pipelines the readback one frame behind, eliminating the 10-15ms
    // synchronous CPU-GPU block that glFinish() + glReadPixels causes.
    private var directFbo2 = -1
    private var directTexture2 = -1

    /** 0 or 1 — which FBO to render to this frame */
    private var directCurrentFbo = 0

    /** First frame has nothing to read back */
    private var directHasPreviousFrame = false

    /**
     * SOTA: Double-buffered async readback on the current GL thread.
     *
     * Previous implementation used glFinish() + glReadPixels which stalls the CPU
     * for 10-15ms waiting for the GPU to complete rendering. This double-buffered
     * approach renders to FBO[N] while reading back from FBO[N-1], pipelining the
     * readback one frame behind. The GPU has already finished FBO[N-1] by the time
     * we read it, so glReadPixels returns immediately without a stall.
     *
     * Trade-off: the AI lane sees data that is one frame old (~100ms at 10 FPS).
     * This is negligible for motion detection — a person moves ~3 pixels in 100ms.
     */
    fun readPixelsDirect(cameraTextureId: Int): ByteArray? {
        if (!directInitialized) initDirectFbo()
        if (!directInitialized) return null
        val readBuf = directReadBuffer ?: return null
        val dst = directRgbBuffer ?: return null

        val savedViewport = IntArray(4)
        GLES20.glGetIntegerv(GLES20.GL_VIEWPORT, savedViewport, 0)

        // Determine which FBO to render to (current) and which to read from (previous)
        val renderFbo = if (directCurrentFbo == 0) directFbo else directFbo2
        val readFbo = if (directCurrentFbo == 0) directFbo2 else directFbo

        // Step 1: Render current frame to renderFbo
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, renderFbo)
        GLES20.glViewport(0, 0, WIDTH, HEIGHT)
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        GLES20.glUseProgram(directProgram)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTextureId)
        GLES20.glUniform1i(directUCameraTex, 0)

        GLES20.glEnableVertexAttribArray(directAPosition)
        GLES20.glVertexAttribPointer(directAPosition, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer)
        GLES20.glEnableVertexAttribArray(directATexCoord)
        GLES20.glVertexAttribPointer(directATexCoord, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer)

        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        GLES20.glDisableVertexAttribArray(directAPosition)
        GLES20.glDisableVertexAttribArray(directATexCoord)

        // Step 2: Read back from readFbo (previous frame — GPU already finished it)
        // No glFinish() needed! The previous frame was submitted at least one full
        // render loop iteration ago (~33ms at 30 FPS camera), which is far more than
        // the GPU needs to complete a simple FBO blit.
        var result: ByteArray? = null
        if (directHasPreviousFrame) {
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, readFbo)
            readBuf.clear()
            GLES20.glReadPixels(
                0, 0, WIDTH, HEIGHT, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, readBuf
            )

            // RGBA → RGB with Y-flip. The previous version did a 921 K-iter Java
            // loop with per-byte ByteBuffer.get(int) calls — each one a JNI hop.
            // That loop alone was ~80 ms and the dominant cost in this stage.
            //
            // Bulk-copy the whole RGBA into a scratch byte[] in one JNI call,
            // then walk it as a Java array. Y-flip happens during the row pack.
            var src = directScratchRgba
            if (src == null || src.size != WIDTH * HEIGHT * 4) {
                src = ByteArray(WIDTH * HEIGHT * 4)
                directScratchRgba = src
            }
            readBuf.rewind()
            readBuf.get(src, 0, WIDTH * HEIGHT * 4)

            val rowRgbaBytes = WIDTH * 4
            var dstIdx = 0
            for (y in HEIGHT - 1 downTo 0) {
                val srcRow = y * rowRgbaBytes
                for (x in 0 until WIDTH) {
                    val s = srcRow + (x shl 2)
                    dst[dstIdx++] = src[s]
                    dst[dstIdx++] = src[s + 1]
                    dst[dstIdx++] = src[s + 2]
                }
            }
            result = dst
        } else {
            // First frame — nothing to read back yet. Render submitted, will be
            // available next call. Return null this one time.
            directHasPreviousFrame = true
        }

        // Step 3: Swap FBOs for next frame
        directCurrentFbo = 1 - directCurrentFbo

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glViewport(savedViewport[0], savedViewport[1], savedViewport[2], savedViewport[3])

        return result
    }

    private fun initDirectFbo() {
        try {
            directProgram = GlUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
            if (directProgram == 0) {
                logger.error("Direct FBO shader failed")
                return
            }
            directAPosition = GLES20.glGetAttribLocation(directProgram, "aPosition")
            directATexCoord = GLES20.glGetAttribLocation(directProgram, "aTexCoord")
            directUCameraTex = GLES20.glGetUniformLocation(directProgram, "uCameraTex")

            // Create FBO #1
            directTexture = createFboTexture()
            directFbo = createFbo(directTexture)
            if (GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER) !=
                GLES20.GL_FRAMEBUFFER_COMPLETE
            ) {
                logger.error(
                    "FBO #1 incomplete: " +
                        GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER)
                )
                GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
                return
            }

            // Create FBO #2 (for double-buffered async readback)
            directTexture2 = createFboTexture()
            directFbo2 = createFbo(directTexture2)
            val status2 = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER)
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
            if (status2 != GLES20.GL_FRAMEBUFFER_COMPLETE) {
                logger.error("FBO #2 incomplete: $status2")
                return
            }

            directReadBuffer = ByteBuffer.allocateDirect(WIDTH * HEIGHT * 4)
                .order(ByteOrder.nativeOrder())
            directRgbBuffer = ByteArray(WIDTH * HEIGHT * 3)

            if (vertexBuffer == null) vertexBuffer = GlUtil.createFloatBuffer(VERTEX_COORDS)
            if (texCoordBuffer == null) texCoordBuffer = GlUtil.createFloatBuffer(TEX_COORDS)

            directCurrentFbo = 0
            directHasPreviousFrame = false

            directInitialized = true
            logger.info("Double-buffered FBO readback initialized (640x480, async)")
        } catch (e: Exception) {
            logger.error("Failed to init direct FBO: " + e.message)
        }
    }

    /** One 640×480 RGBA colour texture. Both FBOs need an identical one. */
    private fun createFboTexture(): Int {
        val texIds = IntArray(1)
        GLES20.glGenTextures(1, texIds, 0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texIds[0])
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, WIDTH, HEIGHT, 0,
            GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR
        )
        return texIds[0]
    }

    /** Creates an FBO with [texture] as COLOR_ATTACHMENT0, leaving it bound. */
    private fun createFbo(texture: Int): Int {
        val fboIds = IntArray(1)
        GLES20.glGenFramebuffers(1, fboIds, 0)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fboIds[0])
        GLES20.glFramebufferTexture2D(
            GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0,
            GLES20.GL_TEXTURE_2D, texture, 0
        )
        return fboIds[0]
    }

    fun getWidth(): Int = WIDTH

    fun getHeight(): Int = HEIGHT

    fun isGrayscaleMode(): Boolean = false

    fun getBytesPerPixel(): Int = 4

    fun recycleBuffer(buffer: ByteArray?) {}

    fun getPoolStats(): String = "Async ImageReader (zero-stutter)"

    /** Release all resources. */
    fun release() {
        initialized = false
        directInitialized = false

        renderHandler?.post {
            // Clean up double-buffered FBOs
            if (directFbo >= 0) {
                GLES20.glDeleteFramebuffers(1, intArrayOf(directFbo), 0)
                directFbo = -1
            }
            if (directFbo2 >= 0) {
                GLES20.glDeleteFramebuffers(1, intArrayOf(directFbo2), 0)
                directFbo2 = -1
            }
            if (directTexture >= 0) {
                GLES20.glDeleteTextures(1, intArrayOf(directTexture), 0)
                directTexture = -1
            }
            if (directTexture2 >= 0) {
                GLES20.glDeleteTextures(1, intArrayOf(directTexture2), 0)
                directTexture2 = -1
            }
            if (directProgram > 0) {
                GLES20.glDeleteProgram(directProgram)
                directProgram = -1
            }

            val surface = eglSurface
            if (surface != null && surface != EGL14.EGL_NO_SURFACE) {
                EGL14.eglDestroySurface(eglDisplay, surface)
            }
            val context = eglContext
            if (context != null && context != EGL14.EGL_NO_CONTEXT) {
                EGL14.eglDestroyContext(eglDisplay, context)
            }
            if (programId != 0) {
                GLES20.glDeleteProgram(programId)
            }
        }

        renderThread?.quitSafely()
        renderThread = null

        imageReader?.close()
        imageReader = null

        logger.info("AsyncGpuDownscaler released")
    }

    companion object {
        private const val TAG = "GpuDownscaler"
        private val logger = DaemonLogger.getInstance(TAG)

        private const val WIDTH = 640
        private const val HEIGHT = 480

        /** Fullscreen quad */
        private val VERTEX_COORDS = floatArrayOf(
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f
        )

        /**
         * Texture coordinates (flipped vertically for correct orientation).
         * OpenGL renders with Y=0 at bottom, but images expect Y=0 at top.
         */
        private val TEX_COORDS = floatArrayOf(
            0.0f, 1.0f, // Bottom-left vertex → top-left of texture
            1.0f, 1.0f, // Bottom-right vertex → top-right of texture
            0.0f, 0.0f, // Top-left vertex → bottom-left of texture
            1.0f, 0.0f // Top-right vertex → bottom-right of texture
        )

        /** Vertex shader */
        private val VERTEX_SHADER =
            "attribute vec4 aPosition;\n" +
            "attribute vec2 aTexCoord;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_Position = aPosition;\n" +
            "    vTexCoord = aTexCoord;\n" +
            "}\n"

        // Fragment shader - mosaic transformation (5120x960 strip → 2x2 grid)
        // Grid layout: TL=Front, TR=Right, BL=Rear, BR=Left
        // Strip layout: cam1(Rear)=0.00, cam2(Left)=0.25, cam3(Right)=0.50, cam4(Front)=0.75
        private val FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "uniform samplerExternalOES uCameraTex;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    vec2 gridPos = step(0.5, vTexCoord);\n" +
            "    // TL=Front(0.75), TR=Right(0.50), BL=Rear(0.00), BR=Left(0.25)\n" +
            "    float stripOffsetX = 0.75 - (gridPos.x * 0.25) - (gridPos.y * 0.75) + (gridPos.x * gridPos.y * 0.50);\n" +
            "    float localX = mod(vTexCoord.x, 0.5) * 0.5;\n" +
            "    float localY = mod(vTexCoord.y, 0.5) * 2.0;\n" +
            "    vec2 samplePos = vec2(localX + stripOffsetX, localY);\n" +
            "    gl_FragColor = texture2D(uCameraTex, samplePos);\n" +
            "}\n"

        // Utility methods
        @JvmStatic
        fun getDirectBuffer(image: Image?): ByteBuffer? = image?.planes?.get(0)?.buffer

        @JvmStatic
        fun getRowStride(image: Image?): Int = image?.planes?.get(0)?.rowStride ?: 0

        @JvmStatic
        fun getPixelStride(image: Image?): Int = image?.planes?.get(0)?.pixelStride ?: 0
    }
}
