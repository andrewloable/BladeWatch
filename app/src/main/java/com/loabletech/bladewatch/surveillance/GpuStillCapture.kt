package net.bladewatch.app.surveillance

import android.graphics.Bitmap
import android.opengl.GLES11Ext
import android.opengl.GLES20
import net.bladewatch.app.camera.GlUtil
import net.bladewatch.app.logging.DaemonLogger
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * The remote live view's still at the cameras' own resolution (BladeWatch-rdtj.68): all four in a
 * 1280x960 mosaic, or ONE camera at its native 1280x960, cut from the 5120x960 strip on the GPU.
 * The motion detector's 640x480 frame, which the still used before, gave a picked camera 320x240.
 *
 * Runs on the camera's GL thread (it samples the camera's external texture), twice a second while
 * someone watches. The frame is drawn upside down on purpose, so glReadPixels, which reads bottom
 * row first, returns it top-down and it goes into a Bitmap with no per-pixel copy.
 */
class GpuStillCapture {
    private var program = 0
    private var aPosition = -1
    private var aTexCoord = -1
    private var uCameraTex = -1
    private var uMosaic = -1
    private var uStripX = -1
    private var fbo = 0
    private var texture = 0
    private var pixels: ByteBuffer? = null
    private var vertices: FloatBuffer? = null
    private var texCoords: FloatBuffer? = null

    // Two, alternated: the encoder thread may still be compressing the previous shot.
    private val bitmaps = arrayOfNulls<Bitmap>(2)
    private var next = 0

    /**
     * Renders [view] ([MOSAIC], or a camera 0..3 in the live view's order: Front, Right, Rear,
     * Left) of [cameraTextureId] and returns it, or null if GL could not be set up. The Bitmap is
     * reused two calls later.
     */
    fun capture(cameraTextureId: Int, view: Int): Bitmap? {
        if (program == 0 && !init()) return null
        val buf = pixels ?: return null
        val saved = IntArray(4)
        GLES20.glGetIntegerv(GLES20.GL_VIEWPORT, saved, 0)

        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fbo)
        GLES20.glViewport(0, 0, WIDTH, HEIGHT)
        GLES20.glUseProgram(program)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTextureId)
        GLES20.glUniform1i(uCameraTex, 0)
        GLES20.glUniform1f(uMosaic, if (view == MOSAIC) 1f else 0f)
        GLES20.glUniform1f(uStripX, stripX(view))
        GLES20.glEnableVertexAttribArray(aPosition)
        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 0, vertices)
        GLES20.glEnableVertexAttribArray(aTexCoord)
        GLES20.glVertexAttribPointer(aTexCoord, 2, GLES20.GL_FLOAT, false, 0, texCoords)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(aPosition)
        GLES20.glDisableVertexAttribArray(aTexCoord)

        buf.clear()
        // ponytail: a synchronous read (~a few ms, twice a second); double-buffered PBOs if it shows
        // in the GL loop's timing.
        GLES20.glReadPixels(0, 0, WIDTH, HEIGHT, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, buf)
        GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
        GLES20.glViewport(saved[0], saved[1], saved[2], saved[3])

        val bitmap = bitmaps[next] ?: Bitmap.createBitmap(WIDTH, HEIGHT, Bitmap.Config.ARGB_8888).also { bitmaps[next] = it }
        buf.rewind()
        bitmap.copyPixelsFromBuffer(buf) // ARGB_8888 is RGBA in memory, as glReadPixels writes it
        next = 1 - next
        return bitmap
    }

    private fun init(): Boolean {
        return try {
            program = GlUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
            if (program == 0) return false
            aPosition = GLES20.glGetAttribLocation(program, "aPosition")
            aTexCoord = GLES20.glGetAttribLocation(program, "aTexCoord")
            uCameraTex = GLES20.glGetUniformLocation(program, "uCameraTex")
            uMosaic = GLES20.glGetUniformLocation(program, "uMosaic")
            uStripX = GLES20.glGetUniformLocation(program, "uStripX")

            val ids = IntArray(1)
            GLES20.glGenTextures(1, ids, 0)
            texture = ids[0]
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
            GLES20.glTexImage2D(
                GLES20.GL_TEXTURE_2D, 0, GLES20.GL_RGBA, WIDTH, HEIGHT, 0,
                GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, null
            )
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR)
            GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR)
            GLES20.glGenFramebuffers(1, ids, 0)
            fbo = ids[0]
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, fbo)
            GLES20.glFramebufferTexture2D(
                GLES20.GL_FRAMEBUFFER, GLES20.GL_COLOR_ATTACHMENT0, GLES20.GL_TEXTURE_2D, texture, 0
            )
            val status = GLES20.glCheckFramebufferStatus(GLES20.GL_FRAMEBUFFER)
            GLES20.glBindFramebuffer(GLES20.GL_FRAMEBUFFER, 0)
            if (status != GLES20.GL_FRAMEBUFFER_COMPLETE) {
                logger.error("Still FBO incomplete: $status")
                release()
                return false
            }
            pixels = ByteBuffer.allocateDirect(WIDTH * HEIGHT * 4).order(ByteOrder.nativeOrder())
            vertices = GlUtil.createFloatBuffer(VERTEX_COORDS)
            texCoords = GlUtil.createFloatBuffer(TEX_COORDS)
            logger.info("Still capture ready (${WIDTH}x$HEIGHT)")
            true
        } catch (e: Exception) {
            logger.error("Still capture init failed: " + e.message)
            release()
            false
        }
    }

    /** On the GL thread. */
    fun release() {
        if (fbo != 0) GLES20.glDeleteFramebuffers(1, intArrayOf(fbo), 0)
        if (texture != 0) GLES20.glDeleteTextures(1, intArrayOf(texture), 0)
        if (program != 0) GLES20.glDeleteProgram(program)
        fbo = 0
        texture = 0
        program = 0
        bitmaps.forEachIndexed { i, b -> b?.recycle(); bitmaps[i] = null }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("GpuStillCapture")

        const val WIDTH = 1280
        const val HEIGHT = 960

        /** All four cameras. Otherwise a view is a camera 0..3: Front, Right, Rear, Left. */
        const val MOSAIC = -1

        /**
         * Where camera [view] starts in the strip (Rear 0.00, Left 0.25, Right 0.50, Front 0.75, the
         * same strip layout as GpuDownscaler's mosaic shader); 0 for [MOSAIC], which ignores it.
         */
        fun stripX(view: Int): Float = when (view) {
            0 -> 0.75f
            1 -> 0.50f
            2 -> 0.00f
            3 -> 0.25f
            else -> 0f
        }

        private val VERTEX_COORDS = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)

        // NOT GpuDownscaler's flipped coordinates: the bottom FBO row gets the image's top row, so
        // glReadPixels hands back rows top-down.
        private val TEX_COORDS = floatArrayOf(0f, 0f, 1f, 0f, 0f, 1f, 1f, 1f)

        private const val VERTEX_SHADER =
            "attribute vec4 aPosition;\n" +
                "attribute vec2 aTexCoord;\n" +
                "varying vec2 vTexCoord;\n" +
                "void main() {\n" +
                "    gl_Position = aPosition;\n" +
                "    vTexCoord = aTexCoord;\n" +
                "}\n"

        // highp: sampling one camera at its native width needs finer steps than mediump has across
        // a 5120-pixel strip.
        private const val FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
                "precision highp float;\n" +
                "uniform samplerExternalOES uCameraTex;\n" +
                "uniform float uMosaic;\n" +
                "uniform float uStripX;\n" +
                "varying vec2 vTexCoord;\n" +
                "void main() {\n" +
                "    vec2 gridPos = step(0.5, vTexCoord);\n" +
                "    float gridX = 0.75 - (gridPos.x * 0.25) - (gridPos.y * 0.75) + (gridPos.x * gridPos.y * 0.50);\n" +
                "    vec2 mosaic = vec2(mod(vTexCoord.x, 0.5) * 0.5 + gridX, mod(vTexCoord.y, 0.5) * 2.0);\n" +
                "    vec2 single = vec2(uStripX + vTexCoord.x * 0.25, vTexCoord.y);\n" +
                "    gl_FragColor = texture2D(uCameraTex, mix(single, mosaic, uMosaic));\n" +
                "}\n"
    }
}
