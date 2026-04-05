package com.overdrive.app.camera;

import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.HandlerThread;
import android.view.Surface;

import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.surveillance.GpuDownscaler;
import com.overdrive.app.surveillance.GpuMosaicRecorder;
import com.overdrive.app.surveillance.HardwareEventRecorderGpu;
import com.overdrive.app.surveillance.SurveillanceEngineGpu;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

/**
 * PanoramicCameraGpu - GPU Edition with Zero-Copy Pipeline.
 * 
 * This is the GPU-native version of PanoramicCamera that replaces ImageReader
 * with SurfaceTexture. Camera frames flow directly to GPU texture, enabling:
 * - Zero-copy recording (camera → GPU → encoder)
 * - Minimal AI readback (GPU downscales to 320x240)
 * - <10% total CPU usage
 * 
 * Architecture:
 * - Camera writes to GL_TEXTURE_EXTERNAL_OES via SurfaceTexture
 * - Render loop on dedicated GL thread distributes frames to:
 *   - Recording Lane: GpuMosaicRecorder (zero-copy to encoder)
 *   - AI Lane: GpuDownscaler (2 FPS readback for motion detection)
 */
public class PanoramicCameraGpu {
    private static final String TAG = "PanoramicCameraGpu";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);
    private static final int PHYSICAL_CAMERA_ID = 1;
    
    // AVMCamera surface mode — 0 works on Seal, Atto 1 may need different value
    // Set via setCameraSurfaceMode() before start() for per-model override
    private int cameraSurfaceMode = 0;
    
    // Camera ID override — set via setCameraId() before start()
    private int cameraIdOverride = -1;  // -1 = use default PHYSICAL_CAMERA_ID
    
    // Auto-probe mode — tries all camera IDs to find one with actual image data
    private boolean autoProbeCameras = false;
    
    // Camera dimensions
    private final int width;
    private final int height;
    
    // EGL and OpenGL
    private EGLCore eglCore;
    private android.opengl.EGLSurface dummySurface;  // Pbuffer for headless context
    private int cameraTextureId;
    private SurfaceTexture cameraSurfaceTexture;
    private Surface cameraSurface;
    
    // Camera object (via reflection)
    private Object cameraObj;
    
    // Render loop
    private HandlerThread glThread;
    private Handler glHandler;
    private volatile boolean running = false;
    private final Object frameSync = new Object();
    
    // Consumers
    private GpuMosaicRecorder recorder;
    private HardwareEventRecorderGpu encoder;  // Direct encoder reference for draining
    private com.overdrive.app.streaming.GpuStreamScaler streamScaler;  // Stream scaler (optional)
    private HardwareEventRecorderGpu streamEncoder;  // Stream encoder (optional)
    private GpuDownscaler downscaler;
    private SurveillanceEngineGpu sentry;
    
    // Frame timing
    private int frameCounter = 0;
    private static final int AI_FRAME_SKIP = 15;  // 30fps / 15 = 2 FPS for AI
    private long lastFrameTime = 0;
    private long startTime = 0;
    
    // Watchdog for GL thread hang detection
    private volatile long lastGlThreadHeartbeat = 0;
    private Thread watchdogThread;
    private static final long GL_THREAD_TIMEOUT_MS = 3000;
    
    // CPU usage monitoring
    private long lastCpuCheckTime = 0;
    private static final long CPU_CHECK_INTERVAL_MS = 10000;  // Every 10 seconds
    
    // Stats logging (time-based, not frame-based)
    private long lastStatsTime = 0;
    private static final long STATS_INTERVAL_MS = 120000;  // Every 2 minutes
    
    /**
     * Creates a GPU-based panoramic camera.
     * 
     * @param width Camera width (typically 5120)
     * @param height Camera height (typically 960)
     */
    public PanoramicCameraGpu(int width, int height) {
        this.width = width;
        this.height = height;
    }
    
    /**
     * Sets the consumers for the camera frames.
     * 
     * @param recorder GPU mosaic recorder for zero-copy recording
     * @param downscaler GPU downscaler for AI lane
     * @param sentry Surveillance engine for motion detection
     */
    public void setConsumers(GpuMosaicRecorder recorder, GpuDownscaler downscaler, 
                            SurveillanceEngineGpu sentry) {
        this.recorder = recorder;
        this.downscaler = downscaler;
        this.sentry = sentry;
    }
    
    /**
     * Starts the GPU camera pipeline.
     * 
     * @throws Exception if initialization fails
     */
    public void start() throws Exception {
        logger.info( "Starting GPU camera pipeline...");
        startTime = System.currentTimeMillis();
        
        // Start GL thread
        glThread = new HandlerThread("GL-RenderLoop");
        glThread.start();
        glHandler = new Handler(glThread.getLooper());
        
        // Initialize on GL thread
        glHandler.post(() -> {
            try {
                initializeGl();
                startCamera();
                running = true;
                
                // Start render loop
                glHandler.post(this::renderLoop);
                
                // Start watchdog
                startWatchdog();
                
                logger.info( "GPU camera pipeline started");
            } catch (Exception e) {
                logger.error( "Failed to start GPU pipeline", e);
                throw new RuntimeException(e);
            }
        });
    }
    
    /**
     * Initializes OpenGL context and textures.
     */
    private void initializeGl() {
        // Create EGL context
        eglCore = new EGLCore();
        
        // Create a dummy pbuffer surface and make it current
        // This is required before any OpenGL calls can be made
        dummySurface = eglCore.createPbufferSurface(1, 1);
        eglCore.makeCurrent(dummySurface);
        
        // Log GL info (now that context is current)
        GlUtil.logGlInfo();
        
        // Create camera texture (OES type for external camera)
        cameraTextureId = GlUtil.createExternalTexture();
        
        // Create SurfaceTexture from camera texture
        cameraSurfaceTexture = new SurfaceTexture(cameraTextureId);
        cameraSurfaceTexture.setDefaultBufferSize(width, height);
        cameraSurfaceTexture.setOnFrameAvailableListener(this::onFrameAvailable);
        
        // Create Surface for camera
        cameraSurface = new Surface(cameraSurfaceTexture);
        
        // Initialize GPU components now that EGL context exists
        if (recorder != null) {
            // Recorder needs to be initialized with EGLCore and encoder
            // This should be done by the caller after encoder is created
            logger.debug( "Recorder initialization deferred to caller");
        }
        
        if (downscaler != null) {
            downscaler.init();  // Default RGB mode
            logger.debug( "Downscaler initialized");
        }
        
        logger.info( "OpenGL initialized (texture=" + cameraTextureId + ")");
    }
    
    /**
     * Initializes the recorder on the GL thread.
     * 
     * This must be called after the GL context is created and made current.
     * 
     * @param recorder GPU mosaic recorder to initialize
     * @param encoder Hardware encoder providing the input surface
     */
    public void initRecorderOnGlThread(GpuMosaicRecorder recorder, HardwareEventRecorderGpu encoder) {
        if (glHandler == null) {
            logger.error( "GL thread not started");
            return;
        }
        
        // Store encoder reference for draining in render loop
        this.encoder = encoder;
        
        glHandler.post(() -> {
            try {
                recorder.init(eglCore, encoder);
                logger.info( "Recorder initialized on GL thread");
                
                // Notify pipeline that recorder is ready
                if (recorderInitCallback != null) {
                    recorderInitCallback.run();
                }
            } catch (Exception e) {
                logger.error( "Failed to initialize recorder on GL thread", e);
            }
        });
    }
    
    // Callback for when recorder is initialized
    private Runnable recorderInitCallback;
    
    /**
     * Sets a callback to be invoked when the recorder is initialized.
     * 
     * @param callback Callback to run on GL thread after recorder init
     */
    public void setRecorderInitCallback(Runnable callback) {
        this.recorderInitCallback = callback;
    }
    
    /**
     * Initializes the stream scaler on the GL thread.
     * 
     * @param streamScaler GPU stream scaler to initialize
     * @param streamEncoder Hardware encoder for streaming
     */
    public void initStreamScalerOnGlThread(com.overdrive.app.streaming.GpuStreamScaler streamScaler,
                                          HardwareEventRecorderGpu streamEncoder) {
        if (glHandler == null) {
            logger.error("GL thread not started");
            return;
        }
        
        glHandler.post(() -> {
            try {
                streamScaler.init(eglCore, streamEncoder);
                logger.info("Stream scaler initialized on GL thread");
            } catch (Exception e) {
                logger.error("Failed to initialize stream scaler on GL thread", e);
            }
        });
    }
    
    /**
     * Gets the EGL core for initializing GPU components.
     * 
     * @return EGLCore instance (only valid after start() is called)
     */
    public EGLCore getEglCore() {
        return eglCore;
    }
    
    /**
     * Starts the BYD camera via reflection.
     */
    private void startCamera() throws Exception {
        // Open physical camera via AVMCamera
        int cameraId = cameraIdOverride >= 0 ? cameraIdOverride : PHYSICAL_CAMERA_ID;
        Class<?> avmClass = Class.forName("android.hardware.AVMCamera");
        Constructor<?> constructor = avmClass.getDeclaredConstructor(int.class);
        constructor.setAccessible(true);
        cameraObj = constructor.newInstance(cameraId);
        
        Method mOpen = avmClass.getDeclaredMethod("open");
        mOpen.setAccessible(true);
        if (!(boolean) mOpen.invoke(cameraObj)) {
            throw new RuntimeException("Failed to open panoramic camera (id=" + cameraId + ")");
        }
        
        // Connect surface — mode 0 works on Seal, other models may need different mode
        Method mAddSurface = avmClass.getDeclaredMethod("addPreviewSurface", Surface.class, int.class);
        mAddSurface.setAccessible(true);
        mAddSurface.invoke(cameraObj, cameraSurface, cameraSurfaceMode);
        
        // Start preview
        Method mStart = avmClass.getDeclaredMethod("startPreview");
        mStart.setAccessible(true);
        mStart.invoke(cameraObj);
        
        logger.info("Camera started (" + width + "x" + height + 
            ", id=" + cameraId + ", surfaceMode=" + cameraSurfaceMode + ")");
    }
    
    /**
     * Called when a new camera frame is available.
     */
    private void onFrameAvailable(SurfaceTexture st) {
        synchronized (frameSync) {
            frameSync.notify();
        }
    }
    
    /**
     * Main render loop - distributes frames to recording and AI lanes.
     */
    private void renderLoop() {
        if (!running) {
            return;
        }

        try {
            // Wait for new frame (hardware sync)
            synchronized (frameSync) {
                try {
                    frameSync.wait(100);  // Timeout to check running flag
                } catch (InterruptedException e) {
                    // Continue
                }
            }

            if (!running) {
                return;
            }

            // Update watchdog heartbeat
            lastGlThreadHeartbeat = System.currentTimeMillis();

            // CRITICAL: Always consume camera texture FIRST to keep the camera HAL's
            // BufferQueue flowing. If we don't call updateTexImage() promptly, the HAL
            // buffer fills up and the BYD native camera app loses video signal.
            cameraSurfaceTexture.updateTexImage();
            frameCounter++;
            lastFrameTime = System.currentTimeMillis();
            
            // AUTO-PROBE: After 15 frames, check if current camera has image data.
            // If blank and auto-probe is enabled, try next camera ID.
            if (frameCounter == 15 && downscaler != null) {
                try {
                    byte[] probe = downscaler.readPixels(cameraTextureId, 8, 8);
                    boolean hasData = false;
                    if (probe != null) {
                        for (int i = 0; i < Math.min(probe.length, 192); i++) {
                            if ((probe[i] & 0xFF) > 10) { hasData = true; break; }
                        }
                    }
                    int currentId = cameraIdOverride >= 0 ? cameraIdOverride : PHYSICAL_CAMERA_ID;
                    boolean isPanoramic = width >= 5000;
                    logger.info("Camera ID " + currentId + " probe: " + 
                        (hasData ? "HAS DATA" : "BLACK") +
                        " | resolution=" + width + "x" + height +
                        " | type=" + (isPanoramic ? "PANORAMIC" : "SINGLE") +
                        " | surfaceMode=" + cameraSurfaceMode);
                    
                    if (hasData && isPanoramic) {
                        // Found a working panoramic camera — use it
                        logger.info("Auto-probe: SELECTED camera ID " + currentId + 
                            " (panoramic, has image data, surfaceMode=" + cameraSurfaceMode + ")");
                        autoProbeCameras = false;
                    } else if (autoProbeCameras) {
                        String reason = !hasData ? "blank" : "single-view (need panoramic)";
                        // Try next camera ID sequentially (0, 1, 2, 3, 4, 5)
                        int nextId = currentId + 1;
                        
                        if (nextId <= 5) {
                            logger.info("Auto-probe: camera ID " + currentId + " " + reason + ", trying ID " + nextId + "...");
                            cameraIdOverride = nextId;
                            frameCounter = 0;  // Reset to re-probe
                            
                            // Close current camera and reopen with new ID
                            try {
                                Class<?> avmClass = Class.forName("android.hardware.AVMCamera");
                                Method mStop = avmClass.getDeclaredMethod("stopPreview");
                                mStop.setAccessible(true);
                                mStop.invoke(cameraObj);
                                Method mClose = avmClass.getDeclaredMethod("close");
                                mClose.setAccessible(true);
                                mClose.invoke(cameraObj);
                            } catch (Exception closeEx) {
                                logger.warn("Error closing camera for probe: " + closeEx.getMessage());
                            }
                            startCamera();
                        } else if (cameraSurfaceMode == 0) {
                            // All IDs blank with mode 0 — retry from ID 0 with surface mode 1
                            logger.info("Auto-probe: all IDs blank with surfaceMode=0, retrying with surfaceMode=1...");
                            cameraSurfaceMode = 1;
                            cameraIdOverride = 0;
                            frameCounter = 0;
                            try {
                                Class<?> avmClass = Class.forName("android.hardware.AVMCamera");
                                Method mStop = avmClass.getDeclaredMethod("stopPreview");
                                mStop.setAccessible(true);
                                mStop.invoke(cameraObj);
                                Method mClose = avmClass.getDeclaredMethod("close");
                                mClose.setAccessible(true);
                                mClose.invoke(cameraObj);
                            } catch (Exception closeEx) {
                                logger.warn("Error closing camera for mode probe: " + closeEx.getMessage());
                            }
                            startCamera();
                        } else {
                            logger.error("Auto-probe: all camera IDs (0-5) with surfaceMode 0 and 1 returned blank");
                            autoProbeCameras = false;
                        }
                    }
                } catch (Exception e) {
                    logger.warn("Camera probe failed: " + e.getMessage());
                }
            }

            long loopStartNs = System.nanoTime();

            // PASS 1: Recording (Zero-Copy GPU Path)
            // SOTA: Always render to encoder (for pre-record circular buffer)
            if (recorder != null) {
                recorder.drawFrame(cameraTextureId);

                // CRITICAL: Drain encoder immediately after frame submission
                // This prevents eglSwapBuffers from blocking when encoder buffers fill up
                if (encoder != null) {
                    encoder.drainEncoder();
                }
                
                // RECOVERY: If encoder surface died (EGL_BAD_SURFACE after prolonged use),
                // reinitialize the encoder and reconnect the recorder
                if (recorder.needsReinit() && encoder != null) {
                    logger.warn("Encoder surface lost - reinitializing encoder...");
                    try {
                        recorder.releaseEncoderSurface();
                        encoder.release();
                        encoder.init();
                        recorder.init(eglCore, encoder);
                        recorder.clearReinitFlag();
                        logger.info("Encoder reinitialized successfully after surface loss");
                    } catch (Exception reinitEx) {
                        logger.error("Encoder reinit failed: " + reinitEx.getMessage());
                        // If reinit fails, force process restart — EGL context is likely corrupt
                        logger.error("CRITICAL: Encoder reinit failed, forcing process restart");
                        try { Thread.sleep(100); } catch (InterruptedException ignored) {}
                        System.exit(0);
                    }
                }
            }

            // PASS 1B: Streaming (Parallel Zero-Copy GPU Path)
            // Only runs if streaming is enabled - uses separate encoder at lower resolution
            if (streamScaler != null && streamEncoder != null) {
                streamScaler.drawFrame(cameraTextureId);
                streamEncoder.drainEncoder();
            }

            // PASS 2: AI Lane (Downscale & Readback at 2 FPS)
            // Only run AI lane if we have time budget remaining (< 50ms per loop iteration)
            // This prevents AI processing from starving the camera HAL during heavy recording
            long elapsedMs = (System.nanoTime() - loopStartNs) / 1_000_000;
            if (sentry != null && sentry.isActive() && downscaler != null && elapsedMs < 50) {
                if (frameCounter % AI_FRAME_SKIP == 0) {
                    try {
                        byte[] smallFrame = downscaler.readPixels(cameraTextureId, 640, 480);
                        if (smallFrame != null) {
                            // Buffer is recycled inside processFrame's finally block
                            sentry.processFrame(smallFrame);
                        }
                    } catch (Exception e) {
                        // Log but don't crash - AI lane is non-critical
                        logger.warn("AI lane error: " + (e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName()));
                    }
                }
            }

            // Log stats periodically (every 2 minutes, time-based)
            long now = System.currentTimeMillis();
            if (now - lastStatsTime >= STATS_INTERVAL_MS) {
                lastStatsTime = now;
                long elapsed = now - startTime;
                float fps = (frameCounter * 1000.0f) / elapsed;
                logger.info( String.format("Stats: %d frames, %.1f FPS, uptime=%ds",
                        frameCounter, fps, elapsed / 1000));
            }

        } catch (Exception e) {
            String msg = e.getMessage();
            if (msg == null) {
                msg = e.getClass().getSimpleName();
            }
            logger.error("Render loop error: " + msg, e);
        }

        // Schedule next frame
        if (running) {
            glHandler.post(this::renderLoop);
        }
    }
    
    /**
     * Starts the watchdog thread that monitors GL thread health.
     * 
     * If the GL thread hangs (e.g., eglSwapBuffers blocks), the watchdog
     * will call System.exit(0) to force a process restart, since EGL
     * contexts cannot be recovered from a blocked thread.
     */
    private void startWatchdog() {
        lastGlThreadHeartbeat = System.currentTimeMillis();
        
        watchdogThread = new Thread(() -> {
            while (running) {
                try {
                    Thread.sleep(1000);  // Check every second
                    
                    long now = System.currentTimeMillis();
                    long timeSinceHeartbeat = now - lastGlThreadHeartbeat;
                    
                    if (timeSinceHeartbeat > GL_THREAD_TIMEOUT_MS) {
                        logger.error( "CRITICAL: GL thread blocked for " + timeSinceHeartbeat + 
                                "ms - forcing process restart");
                        
                        // Try to flush logs before exit
                        try {
                            Thread.sleep(100);
                        } catch (InterruptedException ignored) {}
                        
                        // Exit code 0 triggers restart loop in DaemonLauncher wrapper.
                        // EGL contexts cannot be recovered from a blocked thread.
                        System.exit(0);
                    }
                    
                } catch (InterruptedException e) {
                    break;
                }
            }
        }, "GL-Watchdog");
        
        watchdogThread.setDaemon(true);
        watchdogThread.start();
        
        logger.info( "GL thread watchdog started (timeout=" + GL_THREAD_TIMEOUT_MS + "ms)");
    }
    
    /**
     * Stops the GPU camera pipeline.
     */
    public void stop() {
        logger.info( "Stopping GPU camera pipeline...");
        running = false;
        
        // Stop watchdog
        if (watchdogThread != null) {
            watchdogThread.interrupt();
            watchdogThread = null;
        }
        
        // Stop camera
        try {
            if (cameraObj != null) {
                Class<?> avmClass = Class.forName("android.hardware.AVMCamera");
                Method mStop = avmClass.getDeclaredMethod("stopPreview");
                mStop.setAccessible(true);
                mStop.invoke(cameraObj);
                
                Method mClose = avmClass.getDeclaredMethod("close");
                mClose.setAccessible(true);
                mClose.invoke(cameraObj);
            }
        } catch (Exception e) {
            logger.error( "Error stopping camera", e);
        }
        
        // Cleanup on GL thread
        if (glHandler != null) {
            glHandler.post(this::releaseGl);
        }
        
        // Stop GL thread
        if (glThread != null) {
            glThread.quitSafely();
            try {
                glThread.join(1000);
            } catch (InterruptedException e) {
                logger.warn( "GL thread join interrupted");
            }
            glThread = null;
        }
        
        logger.info( "GPU camera pipeline stopped");
    }
    /**
     * Releases and reopens the AVMCamera without tearing down the GL pipeline.
     *
     * This is needed during ACC OFF→ON transitions. The daemon holds the camera
     * open continuously (surveillance → recording mode), which prevents the BYD
     * native camera app from getting video frames. By briefly releasing the camera,
     * the native app can grab it, and when we reopen we get added as a secondary
     * consumer via addPreviewSurface.
     */
    /**
     * Releases and reopens the AVMCamera without tearing down the GL pipeline.
     * 
     * During ACC OFF→ON, the daemon holds the camera from surveillance mode.
     * The BYD native camera app starts on ACC ON but can't get frames.
     * Releasing briefly lets the native app grab the primary slot, then we
     * get added as secondary consumer via addPreviewSurface.
     */
    public void reopenCamera() {
        reopenCamera(8000); // Default 8 seconds for ACC ON boot
    }

    public void reopenCamera(long delayMs) {
        if (!running) {
            logger.warn("Cannot reopen camera - not running");
            return;
        }

        logger.info("Reopening AVMCamera (delay=" + delayMs + "ms)...");

        try {
            if (cameraObj != null) {
                Class<?> avmClass = Class.forName("android.hardware.AVMCamera");
                Method mStop = avmClass.getDeclaredMethod("stopPreview");
                mStop.setAccessible(true);
                mStop.invoke(cameraObj);

                Method mClose = avmClass.getDeclaredMethod("close");
                mClose.setAccessible(true);
                mClose.invoke(cameraObj);
                cameraObj = null;

                logger.info("Camera closed, waiting for BYD native app...");
            }

            Thread.sleep(delayMs);

            startCamera();
            logger.info("Camera reopened successfully");

        } catch (Exception e) {
            logger.error("Failed to reopen camera: " + e.getMessage(), e);
            try {
                if (cameraObj == null) {
                    logger.warn("Retry camera open...");
                    startCamera();
                }
            } catch (Exception e2) {
                logger.error("Camera retry failed: " + e2.getMessage());
            }
        }
    }
    
    /**
     * Releases OpenGL resources.
     */
    private void releaseGl() {
        if (cameraSurfaceTexture != null) {
            cameraSurfaceTexture.release();
            cameraSurfaceTexture = null;
        }
        
        if (cameraSurface != null) {
            cameraSurface.release();
            cameraSurface = null;
        }
        
        if (cameraTextureId != 0) {
            GlUtil.deleteTexture(cameraTextureId);
            cameraTextureId = 0;
        }
        
        if (dummySurface != null) {
            eglCore.destroySurface(dummySurface);
            dummySurface = null;
        }
        
        if (eglCore != null) {
            eglCore.release();
            eglCore = null;
        }
        
        logger.info( "OpenGL resources released");
    }
    
    /**
     * Sets streaming components for parallel GPU path.
     * 
     * @param streamScaler GPU stream scaler
     * @param streamEncoder Stream encoder
     */
    public void setStreamingComponents(com.overdrive.app.streaming.GpuStreamScaler streamScaler,
                                      HardwareEventRecorderGpu streamEncoder) {
        this.streamScaler = streamScaler;
        this.streamEncoder = streamEncoder;
    }
    
    /**
     * Clears streaming components (called when streaming is disabled).
     * This prevents the render loop from trying to use released surfaces.
     */
    public void clearStreamingComponents() {
        this.streamScaler = null;
        this.streamEncoder = null;
    }
    
    /**
     * Gets the GL thread handler for posting operations.
     * 
     * @return Handler for GL thread
     */
    public Handler getGlHandler() {
        return glHandler;
    }
    
    /**
     * Checks if the camera is running.
     * 
     * @return true if running, false otherwise
     */
    public boolean isRunning() {
        return running;
    }
    
    /**
     * Sets the AVMCamera surface mode for addPreviewSurface().
     * Must be called before start(). Default is 0 (works on Seal).
     * Atto 1 may need mode 1 for processed panoramic output.
     */
    public void setCameraSurfaceMode(int mode) {
        this.cameraSurfaceMode = mode;
        logger.info("Camera surface mode set to: " + mode);
    }
    
    /**
     * Sets the AVMCamera ID to use.
     * Must be called before start(). Default is 1 (works on Seal).
     * Dolphin/Atto 1 may need ID 0.
     */
    public void setCameraId(int id) {
        this.cameraIdOverride = id;
        logger.info("Camera ID override set to: " + id);
    }
    
    /**
     * Enables auto-probe mode: tries camera IDs 0-5 at startup to find
     * the one that produces actual image data. Logs resolution and pixel
     * content for each ID. Auto-selects the first panoramic (5120-wide) camera
     * with non-black frames.
     */
    public void setAutoProbeCameras(boolean enabled) {
        this.autoProbeCameras = enabled;
        logger.info("Camera auto-probe: " + (enabled ? "ENABLED" : "DISABLED"));
    }
    
    /**
     * Gets the timestamp of the last frame.
     * 
     * @return Timestamp in milliseconds
     */
    public long getLastFrameTime() {
        return lastFrameTime;
    }
    
    /**
     * Gets the total frame count.
     * 
     * @return Frame count
     */
    public int getFrameCount() {
        return frameCounter;
    }
    
    /**
     * Gets the camera width.
     * 
     * @return Width in pixels
     */
    public int getWidth() {
        return width;
    }
    
    /**
     * Gets the camera height.
     * 
     * @return Height in pixels
     */
    public int getHeight() {
        return height;
    }
    
    /**
     * Gets the latest JPEG frame for a specific camera (for HTTP snapshot).
     * 
     * @param cameraId Camera ID (1-4)
     * @return JPEG byte array, or null if not available
     */
    public byte[] getLatestJpegFrame(int cameraId) {
        // This would need to be implemented by storing the latest extracted frame
        // For now, return null (MJPEG streaming handles this via callback)
        return null;
    }
    
    /**
     * Checks CPU usage and logs warning if exceeds threshold.
     * 
     * Provides breakdown by component to identify bottlenecks.
     */
    private void checkCpuUsage() {
        long now = System.currentTimeMillis();
        if (now - lastCpuCheckTime < CPU_CHECK_INTERVAL_MS) {
            return;
        }
        
        lastCpuCheckTime = now;
        
        try {
            // Read /proc/stat for total CPU time
            java.io.BufferedReader reader = new java.io.BufferedReader(
                    new java.io.FileReader("/proc/stat"));
            String line = reader.readLine();
            reader.close();
            
            // Parse CPU times
            String[] tokens = line.split("\\s+");
            long totalCpu = 0;
            for (int i = 1; i < tokens.length; i++) {
                totalCpu += Long.parseLong(tokens[i]);
            }
            
            // Read /proc/self/stat for process CPU time
            reader = new java.io.BufferedReader(
                    new java.io.FileReader("/proc/self/stat"));
            line = reader.readLine();
            reader.close();
            
            tokens = line.split("\\s+");
            long processCpu = Long.parseLong(tokens[13]) + Long.parseLong(tokens[14]);
            
            // Calculate CPU percentage (simplified)
            // Note: This is a rough estimate. For accurate measurement, use
            // Android Profiler or systrace.
            // Logging disabled to reduce log spam - uncomment for debugging
            // logger.debug( String.format("CPU check: process=%d, total=%d", processCpu, totalCpu));
            
        } catch (Exception e) {
            // Silent fail - CPU monitoring is optional
        }
    }
}
