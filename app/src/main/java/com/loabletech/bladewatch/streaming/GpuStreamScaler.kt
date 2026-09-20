package net.bladewatch.app.streaming

import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20

import net.bladewatch.app.camera.EGLCore
import net.bladewatch.app.camera.GlUtil
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.surveillance.HardwareEventRecorderGpu

import java.nio.FloatBuffer

/**
 * GpuStreamScaler - GPU-based downscaler for H.264 streaming.
 *
 * Renders camera texture to a smaller resolution for efficient streaming.
 * Works in parallel with GpuMosaicRecorder - both sample the same source texture.
 *
 * Typical usage:
 * - Recording: 2560×1920 @ 15fps (high quality)
 * - Streaming: 1280×960 @ 10fps (bandwidth-optimized)
 *
 * GPU cost: <1% (texture sampling is nearly free)
 */
class GpuStreamScaler(
    private val outputWidth: Int,
    private val outputHeight: Int
) {

    // EGL and OpenGL state
    private var eglCore: EGLCore? = null
    private var encoderSurface: EGLSurface? = null

    // OpenGL program and locations
    private var programId = 0
    private var uCameraTexLocation = 0
    private var uViewModeLocation = 0
    private var uApaModeLocation = 0
    private var aPositionLocation = 0
    private var aTexCoordLocation = 0

    /**
     * View mode: 0=Mosaic, 1=Front, 2=Right, 3=Rear, 4=Left, 5=Raw
     */
    @Volatile
    private var currentViewMode = 0

    /** 0=4-cam, 1=APA, 2=3-cam */
    @Volatile
    private var cameraLayout = 0

    // Vertex data
    private var vertexBuffer: FloatBuffer? = null
    private var texCoordBuffer: FloatBuffer? = null

    /** Exposed as a property so Kotlin reads `scaler.width` and Java keeps calling `getWidth()`. */
    val width: Int get() = outputWidth

    val height: Int get() = outputHeight

    /**
     * Initializes the stream scaler.
     *
     * @param eglCore EGL context manager
     * @param encoder Hardware encoder for streaming
     */
    fun init(eglCore: EGLCore, encoder: HardwareEventRecorderGpu) {
        this.eglCore = eglCore

        // Get encoder's input surface
        val encoderInputSurface = encoder.getInputSurface()
            ?: throw RuntimeException("Stream encoder input surface is null")

        // Create EGL surface from encoder surface
        encoderSurface = eglCore.createWindowSurface(encoderInputSurface)

        // Compile shaders
        programId = GlUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        if (programId == 0) {
            throw RuntimeException("Failed to create shader program")
        }

        // Get locations
        aPositionLocation = GLES20.glGetAttribLocation(programId, "aPosition")
        aTexCoordLocation = GLES20.glGetAttribLocation(programId, "aTexCoord")
        uCameraTexLocation = GLES20.glGetUniformLocation(programId, "uCameraTex")
        uViewModeLocation = GLES20.glGetUniformLocation(programId, "uViewMode")
        uApaModeLocation = GLES20.glGetUniformLocation(programId, "uApaMode")

        GlUtil.checkGlError("glGetLocation")

        // Create vertex buffers
        vertexBuffer = GlUtil.createFloatBuffer(VERTEX_COORDS)
        texCoordBuffer = GlUtil.createFloatBuffer(TEX_COORDS)

        logger.info("GpuStreamScaler initialized: " + outputWidth + "×" + outputHeight)
    }

    /**
     * Renders a frame to the stream encoder.
     *
     * @param cameraTextureId Camera texture ID
     */
    fun drawFrame(cameraTextureId: Int) {
        val egl = eglCore ?: return
        val surface = encoderSurface ?: return

        // Make encoder surface current
        egl.makeCurrent(surface)

        // Set viewport
        GLES20.glViewport(0, 0, outputWidth, outputHeight)

        // Clear
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        // Use shader
        GLES20.glUseProgram(programId)

        // Bind texture
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTextureId)
        GLES20.glUniform1i(uCameraTexLocation, 0)

        // Set view mode (0=Mosaic, 1-4=Single camera, 5=Raw)
        GLES20.glUniform1i(uViewModeLocation, currentViewMode)
        GLES20.glUniform1f(uApaModeLocation, cameraLayout.toFloat())

        // Set up vertex attributes
        GLES20.glEnableVertexAttribArray(aPositionLocation)
        GLES20.glVertexAttribPointer(
            aPositionLocation, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer
        )

        GLES20.glEnableVertexAttribArray(aTexCoordLocation)
        GLES20.glVertexAttribPointer(
            aTexCoordLocation, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer
        )

        // Draw
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Disable vertex arrays
        GLES20.glDisableVertexAttribArray(aPositionLocation)
        GLES20.glDisableVertexAttribArray(aTexCoordLocation)

        // Submit to encoder
        egl.swapBuffers(surface)
    }

    /**
     * Sets the view mode for streaming.
     *
     * @param mode 0=Mosaic (2x2 grid), 1=Front(cam4), 2=Right(cam3), 3=Rear(cam1), 4=Left(cam2), 5=Raw strip
     */
    fun setViewMode(mode: Int) {
        if (mode in 0..5) {
            currentViewMode = mode
            logger.info("Stream view mode set to " + mode + " (" + MODE_NAMES[mode] + ")")
        }
    }

    /** Gets the current view mode. */
    fun getViewMode(): Int = currentViewMode

    /**
     * Sets APA mode / camera layout.
     * 0=4-camera, 1=APA passthrough, 2=3-camera
     */
    fun setApaMode(apa: Boolean) {
        cameraLayout = if (apa) 1 else 0
    }

    fun setCameraLayout(layout: Int) {
        cameraLayout = layout
    }

    /** Releases all resources. */
    fun release() {
        if (programId != 0) {
            GlUtil.deleteProgram(programId)
            programId = 0
        }

        encoderSurface?.let { eglCore?.destroySurface(it) }
        encoderSurface = null

        logger.info("GpuStreamScaler released")
    }

    companion object {
        private const val TAG = "GpuStreamScaler"
        private val logger = DaemonLogger.getInstance(TAG)

        private val MODE_NAMES = arrayOf("Mosaic", "Front", "Right", "Rear", "Left", "Raw")

        /** Fullscreen quad vertices */
        private val VERTEX_COORDS = floatArrayOf(
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f
        )

        /** Texture coordinates (flipped vertically) */
        private val TEX_COORDS = floatArrayOf(
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f
        )

        /** Simple passthrough vertex shader */
        private val VERTEX_SHADER =
            "attribute vec4 aPosition;\n" +
            "attribute vec2 aTexCoord;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_Position = aPosition;\n" +
            "    vTexCoord = aTexCoord;\n" +
            "}\n"

        // Fragment shader - supports 4-cam mosaic, 3-cam mosaic, APA passthrough, single view, raw strip
        // uViewMode: 0=Mosaic, 1=Front, 2=Right, 3=Rear, 4=Left, 5=Raw strip
        // uApaMode: 0.0=4-camera, 1.0=APA passthrough, 2.0=3-camera mosaic
        private val FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "uniform samplerExternalOES uCameraTex;\n" +
            "uniform int uViewMode;\n" +
            "uniform float uApaMode;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    vec2 samplePos;\n" +
            "    if (uViewMode == 5) {\n" +
            "        samplePos = vTexCoord;\n" +
            "    } else if (uApaMode > 1.5) {\n" +
            "        // 3-camera: TL=Front, BL=Rear, Right=Side\n" +
            // Front
            "        if (uViewMode == 1) { samplePos = vec2(0.75 + vTexCoord.x * 0.25, vTexCoord.y); }\n" +
            // Rear
            "        else if (uViewMode == 3) { samplePos = vec2(vTexCoord.x * 0.25, vTexCoord.y); }\n" +
            // Side
            "        else if (uViewMode == 2 || uViewMode == 4) { samplePos = vec2(0.25 + vTexCoord.x * 0.5, vTexCoord.y); }\n" +
            "        else {\n" +
            "            // Mosaic for 3-cam\n" +
            "            if (vTexCoord.x < 0.5) {\n" +
            "                float lx = vTexCoord.x * 0.5;\n" +
            "                float ly = mod(vTexCoord.y, 0.5) * 2.0;\n" +
            "                if (vTexCoord.y < 0.5) { samplePos = vec2(lx + 0.75, ly); }\n" +
            "                else { samplePos = vec2(lx, ly); }\n" +
            "            } else {\n" +
            "                samplePos = vec2(0.25 + (vTexCoord.x - 0.5) * 1.0 * 0.5, vTexCoord.y);\n" +
            "            }\n" +
            "        }\n" +
            "    } else if (uApaMode > 0.5) {\n" +
            "        samplePos = vTexCoord;\n" +
            "    } else if (uViewMode == 0) {\n" +
            "        vec2 gridPos = step(0.5, vTexCoord);\n" +
            "        float stripOffsetX = 0.75 - (gridPos.x * 0.25) - (gridPos.y * 0.75) + (gridPos.x * gridPos.y * 0.50);\n" +
            "        float localX = mod(vTexCoord.x, 0.5) * 0.5;\n" +
            "        float localY = mod(vTexCoord.y, 0.5) * 2.0;\n" +
            "        samplePos = vec2(localX + stripOffsetX, localY);\n" +
            "    } else {\n" +
            "        float stripIndex;\n" +
            "        if (uViewMode == 1) stripIndex = 3.0;\n" +
            "        else if (uViewMode == 2) stripIndex = 2.0;\n" +
            "        else if (uViewMode == 3) stripIndex = 0.0;\n" +
            "        else stripIndex = 1.0;\n" +
            "        float startX = stripIndex * 0.25;\n" +
            "        samplePos = vec2(startX + (vTexCoord.x * 0.25), vTexCoord.y);\n" +
            "    }\n" +
            "    gl_FragColor = texture2D(uCameraTex, samplePos);\n" +
            "}\n"
    }
}
