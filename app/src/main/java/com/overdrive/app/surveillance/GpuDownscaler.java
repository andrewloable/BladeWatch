package com.overdrive.app.surveillance;

import android.graphics.PixelFormat;
import android.media.Image;
import android.media.ImageReader;
import android.opengl.EGL14;
import android.opengl.EGLConfig;
import android.opengl.EGLContext;
import android.opengl.EGLDisplay;
import android.opengl.EGLSurface;
import android.opengl.GLES11Ext;
import android.opengl.GLES20;
import android.os.Handler;
import android.os.HandlerThread;

import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.camera.GlUtil;

import java.nio.ByteBuffer;
import java.nio.FloatBuffer;

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
public class GpuDownscaler {
    private static final String TAG = "GpuDownscaler";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);
    
    private static final int WIDTH = 640;
    private static final int HEIGHT = 480;
    
    // ImageReader for DMA output
    private ImageReader imageReader;
    
    // Background thread
    private HandlerThread renderThread;
    private Handler renderHandler;
    
    // EGL state (owned by background thread)
    private EGLDisplay eglDisplay;
    private EGLContext eglContext;
    private EGLSurface eglSurface;
    
    // Shared context from main thread
    private EGLContext sharedContext;
    
    // Shader program
    private int programId;
    private int aPositionLocation;
    private int aTexCoordLocation;
    private int uCameraTexLocation;
    
    // Vertex buffers
    private FloatBuffer vertexBuffer;
    private FloatBuffer texCoordBuffer;
    
    private volatile boolean initialized = false;
    
    // Fullscreen quad
    private static final float[] VERTEX_COORDS = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
        -1.0f,  1.0f,
         1.0f,  1.0f
    };
    
    // Texture coordinates (flipped vertically for correct orientation)
    // OpenGL renders with Y=0 at bottom, but images expect Y=0 at top
    private static final float[] TEX_COORDS = {
        0.0f, 1.0f,  // Bottom-left vertex → top-left of texture
        1.0f, 1.0f,  // Bottom-right vertex → top-right of texture
        0.0f, 0.0f,  // Top-left vertex → bottom-left of texture
        1.0f, 0.0f   // Top-right vertex → bottom-right of texture
    };
    
    // Vertex shader
    private static final String VERTEX_SHADER =
        "attribute vec4 aPosition;\n" +
        "attribute vec2 aTexCoord;\n" +
        "varying vec2 vTexCoord;\n" +
        "void main() {\n" +
        "    gl_Position = aPosition;\n" +
        "    vTexCoord = aTexCoord;\n" +
        "}\n";
    
    // Fragment shader - mosaic transformation (5120x960 strip → 2x2 grid)
    // Grid layout: TL=Front, TR=Right, BL=Rear, BR=Left
    // Strip layout: cam1(Rear)=0.00, cam2(Left)=0.25, cam3(Right)=0.50, cam4(Front)=0.75
    private static final String FRAGMENT_SHADER =
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
        "}\n";

    /**
     * Creates the async downscaler with shared EGL context.
     * 
     * @param mainThreadContext EGL context from main render thread (for texture sharing)
     */
    public GpuDownscaler(EGLContext mainThreadContext) {
        this.sharedContext = mainThreadContext;
        
        // Start background thread
        renderThread = new HandlerThread("GpuDownscalerThread");
        renderThread.start();
        renderHandler = new Handler(renderThread.getLooper());
        
        // Initialize EGL on background thread
        renderHandler.post(this::initGlOnThread);
    }
    
    /**
     * Default constructor - call init() later with context.
     */
    public GpuDownscaler() {
        // Will be initialized via init()
    }
    
    /**
     * Initialize with main thread's EGL context.
     */
    public void init(EGLContext mainThreadContext) {
        this.sharedContext = mainThreadContext;
        
        renderThread = new HandlerThread("GpuDownscalerThread");
        renderThread.start();
        renderHandler = new Handler(renderThread.getLooper());
        
        renderHandler.post(this::initGlOnThread);
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
    public void init() {
        EGLContext ctx = EGL14.eglGetCurrentContext();
        if (ctx == EGL14.EGL_NO_CONTEXT) {
            logger.error("init() called without EGL context! Must call from GL thread (onSurfaceCreated)");
            throw new IllegalStateException("GpuDownscaler.init() must be called from GL thread");
        }
        init(ctx);
    }
    
    /**
     * Legacy init with grayscale flag (ignored, always RGBA).
     * 
     * ⚠️ WARNING: Must be called from GL thread!
     */
    public void init(boolean grayscaleMode) {
        init();
    }
    
    private void initGlOnThread() {
        try {
            // Setup ImageReader
            imageReader = ImageReader.newInstance(WIDTH, HEIGHT, PixelFormat.RGBA_8888, 2);
            
            // Setup EGL with shared context
            eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY);
            int[] version = new int[2];
            EGL14.eglInitialize(eglDisplay, version, 0, version, 1);
            
            int[] configAttribs = {
                EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
                EGL14.EGL_RED_SIZE, 8,
                EGL14.EGL_GREEN_SIZE, 8,
                EGL14.EGL_BLUE_SIZE, 8,
                EGL14.EGL_ALPHA_SIZE, 8,
                EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
                EGL14.EGL_NONE
            };
            EGLConfig[] configs = new EGLConfig[1];
            int[] numConfigs = new int[1];
            EGL14.eglChooseConfig(eglDisplay, configAttribs, 0, configs, 0, 1, numConfigs, 0);
            
            // Create context with sharing (can read main thread's textures)
            int[] contextAttribs = {
                EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
                EGL14.EGL_NONE
            };
            eglContext = EGL14.eglCreateContext(eglDisplay, configs[0], sharedContext, contextAttribs, 0);
            
            if (eglContext == EGL14.EGL_NO_CONTEXT) {
                throw new RuntimeException("Failed to create shared EGL context");
            }
            
            // Create surface from ImageReader
            int[] surfaceAttribs = { EGL14.EGL_NONE };
            eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, configs[0], 
                imageReader.getSurface(), surfaceAttribs, 0);
            
            // Make current ONCE AND FOREVER (no more context switching!)
            EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext);
            
            // Setup shaders
            setupShaders();
            
            initialized = true;
            logger.info("AsyncGpuDownscaler initialized (shared context, zero-stutter)");
            
        } catch (Exception e) {
            logger.error("Failed to init GL on thread: " + e.getMessage());
        }
    }
    
    private void setupShaders() {
        programId = GlUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER);
        if (programId == 0) {
            throw new RuntimeException("Failed to create shader program");
        }
        
        aPositionLocation = GLES20.glGetAttribLocation(programId, "aPosition");
        aTexCoordLocation = GLES20.glGetAttribLocation(programId, "aTexCoord");
        uCameraTexLocation = GLES20.glGetUniformLocation(programId, "uCameraTex");
        
        vertexBuffer = GlUtil.createFloatBuffer(VERTEX_COORDS);
        texCoordBuffer = GlUtil.createFloatBuffer(TEX_COORDS);
    }

    /**
     * Non-blocking call to trigger a downscale.
     * Returns immediately - rendering happens on background thread.
     * 
     * @param textureId Camera texture ID from main thread
     */
    public void postFrame(int textureId) {
        if (!initialized || renderHandler == null) return;
        renderHandler.post(() -> drawFrame(textureId));
    }
    
    /**
     * Get the latest image for AI inference.
     * Call from AI thread, not main thread.
     * 
     * @return Image with RGBA data, or null if not available
     */
    public Image acquireLatestImage() {
        if (imageReader == null) return null;
        return imageReader.acquireLatestImage();
    }
    
    private void drawFrame(int textureId) {
        if (!initialized) return;
        
        GLES20.glViewport(0, 0, WIDTH, HEIGHT);
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        
        GLES20.glUseProgram(programId);
        
        // Bind main thread's camera texture (allowed via shared context)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textureId);
        GLES20.glUniform1i(uCameraTexLocation, 0);
        
        // Draw quad
        GLES20.glEnableVertexAttribArray(aPositionLocation);
        GLES20.glVertexAttribPointer(aPositionLocation, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer);
        
        GLES20.glEnableVertexAttribArray(aTexCoordLocation);
        GLES20.glVertexAttribPointer(aTexCoordLocation, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer);
        
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4);
        
        GLES20.glDisableVertexAttribArray(aPositionLocation);
        GLES20.glDisableVertexAttribArray(aTexCoordLocation);
        
        // Swap to ImageReader (DMA transfer)
        EGL14.eglSwapBuffers(eglDisplay, eglSurface);
    }
    
    /**
     * Legacy method for compatibility - blocks and copies to byte array.
     * Prefer postFrame() + acquireLatestImage() for zero-copy.
     * 
     * SOTA FIX: Uses reusable buffer to eliminate 900KB allocation per frame.
     */
    public byte[] readPixels(int cameraTextureId, int width, int height) {
        // Post frame and wait briefly
        postFrame(cameraTextureId);
        
        try {
            Thread.sleep(5); // Give GPU time to render
        } catch (InterruptedException ignored) {}
        
        Image image = acquireLatestImage();
        if (image == null) return null;
        
        try {
            Image.Plane plane = image.getPlanes()[0];
            ByteBuffer buffer = plane.getBuffer();
            int rowStride = plane.getRowStride();
            int pixelStride = plane.getPixelStride();
            int bufferCapacity = buffer.capacity();
            
            // SOTA FIX: Reuse buffer instead of allocating new byte[] per frame
            int rgbSize = WIDTH * HEIGHT * 3;
            if (reusableRgbBuffer == null || reusableRgbBuffer.length != rgbSize) {
                reusableRgbBuffer = new byte[rgbSize];
                logger.info("Allocated reusable RGB buffer: " + rgbSize + " bytes");
            }
            
            // Validate buffer size before processing
            int expectedSize = (HEIGHT - 1) * rowStride + WIDTH * pixelStride;
            if (bufferCapacity < expectedSize) {
                logger.warn("Buffer too small: " + bufferCapacity + " < " + expectedSize + 
                    " (rowStride=" + rowStride + ", pixelStride=" + pixelStride + ")");
                // Return black frame instead of crashing
                java.util.Arrays.fill(reusableRgbBuffer, (byte) 0);
                return reusableRgbBuffer;
            }
            
            // RGBA -> RGB conversion into reusable buffer
            int srcOffset = 0;
            int dstOffset = 0;
            for (int y = 0; y < HEIGHT; y++) {
                for (int x = 0; x < WIDTH; x++) {
                    int srcIdx = srcOffset + x * pixelStride;
                    // Safety check (should not trigger if validation above passed)
                    if (srcIdx + 2 >= bufferCapacity) {
                        break;
                    }
                    reusableRgbBuffer[dstOffset++] = buffer.get(srcIdx);     // R
                    reusableRgbBuffer[dstOffset++] = buffer.get(srcIdx + 1); // G
                    reusableRgbBuffer[dstOffset++] = buffer.get(srcIdx + 2); // B
                }
                srcOffset += rowStride;
            }
            return reusableRgbBuffer;
        } catch (Exception e) {
            logger.warn("Buffer read error: " + e.getClass().getSimpleName());
            // Return black frame on error
            if (reusableRgbBuffer != null) {
                java.util.Arrays.fill(reusableRgbBuffer, (byte) 0);
                return reusableRgbBuffer;
            }
            return null;
        } finally {
            image.close();
        }
    }
    
    // Utility methods
    public static ByteBuffer getDirectBuffer(Image image) {
        if (image == null) return null;
        return image.getPlanes()[0].getBuffer();
    }
    
    public static int getRowStride(Image image) {
        if (image == null) return 0;
        return image.getPlanes()[0].getRowStride();
    }
    
    public static int getPixelStride(Image image) {
        if (image == null) return 0;
        return image.getPlanes()[0].getPixelStride();
    }
    
    public int getWidth() { return WIDTH; }
    public int getHeight() { return HEIGHT; }
    public boolean isGrayscaleMode() { return false; }
    public int getBytesPerPixel() { return 4; }
    public void recycleBuffer(byte[] buffer) { }
    public String getPoolStats() { return "Async ImageReader (zero-stutter)"; }
    
    // SOTA FIX: Reusable RGB buffer to eliminate 900KB allocation per frame
    private byte[] reusableRgbBuffer = null;
    
    /**
     * Release all resources.
     */
    public void release() {
        initialized = false;
        
        if (renderHandler != null) {
            renderHandler.post(() -> {
                if (eglSurface != null && eglSurface != EGL14.EGL_NO_SURFACE) {
                    EGL14.eglDestroySurface(eglDisplay, eglSurface);
                }
                if (eglContext != null && eglContext != EGL14.EGL_NO_CONTEXT) {
                    EGL14.eglDestroyContext(eglDisplay, eglContext);
                }
                if (programId != 0) {
                    GLES20.glDeleteProgram(programId);
                }
            });
        }
        
        if (renderThread != null) {
            renderThread.quitSafely();
            renderThread = null;
        }
        
        if (imageReader != null) {
            imageReader.close();
            imageReader = null;
        }
        
        logger.info("AsyncGpuDownscaler released");
    }
}
