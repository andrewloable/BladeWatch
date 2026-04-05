package com.overdrive.app.surveillance;
import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.ai.YoloDetector;
import com.overdrive.app.ai.Detection;
import com.overdrive.app.telegram.TelegramNotifier;

import java.io.File;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * SurveillanceEngineGpu - SOTA Optimized Edition
 * 
 * SOTA UPGRADES:
 * 1. Multi-Frame Ring Buffer (N vs N-3 comparison) to kill jitter/shadows.
 * 2. Chroma (Hue) Sensitivity to ignore lighting changes.
 * 3. Distance-based Filtering (Ignore small motion at bottom of frame).
 * 
 * Why N vs N-3 works:
 * - Real Motion (Person/Car): Moves significantly in 300ms -> Detected.
 * - Shadows/Leaves: Move randomly or slowly -> Ignored (Change is too small or cancels out).
 */
public class SurveillanceEngineGpu {
    private static final String TAG = "SurveillanceEngineGpu";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);
    
    // Motion detection buffers
    private ByteBuffer referenceFrame;  // Used for legacy fallback
    private ByteBuffer currentFrame;
    private long lastMotionTime = 0;
    private long firstMotionTime = 0;  // When sustained motion started (for duration check)
    
    // --- SOTA: RING BUFFER ---
    // We store the last 4 frames. We compare Current (N) vs History[Index-3]
    // At 10 FPS, this gives a 300ms delta.
    private static final int FRAME_HISTORY_SIZE = 4;
    private static final int FRAME_COMPARE_OFFSET = 3;
    private ByteBuffer[] frameHistory;
    private int frameHistoryIndex = 0;
    private int frameHistoryCount = 0;
    // -------------------------
    
    // SUSTAINED MOTION: Reduced to 300ms for faster response to walk-bys
    // The ring buffer (N vs N-3) already provides 300ms temporal filtering
    private static final long SUSTAINED_MOTION_MS = 300;
    
    // MOTION THROTTLING: Process motion at 10 FPS max (saves 66% CPU vs 30 FPS)
    private static final long MOTION_PROCESS_INTERVAL_MS = 100;  // 10 FPS
    private long lastMotionProcessTime = 0;
    
    // ROI mask (null = full frame, otherwise byte array with 0/1 values)
    private byte[] roiMask = null;
    private int roiPixelCount = 0;  // Number of pixels in ROI (for normalization)
    
    // Reference to downscaler for buffer recycling
    private GpuDownscaler downscaler;
    
    // Reference to mosaic recorder for triggering recording
    private GpuMosaicRecorder recorder;
    
    // Thresholds
    private float sadThreshold = 0.05f;  // 5% pixel change (legacy fallback)
    private float mog2Threshold = 0.05f;  // 5% for MOG2 (legacy fallback)
    private float lightThreshold = 0.4f;  // 40% sudden change = light flash (filter out)
    
    // SOTA: Grid Motion Configuration
    // 640x480 / 32 = 20x15 grid. 32px blocks are ideal for human detection at distance.
    private static final int GRID_BLOCK_SIZE = 32;
    private static final int GRID_COLS = 640 / GRID_BLOCK_SIZE;  // 20
    private static final int GRID_ROWS = 480 / GRID_BLOCK_SIZE;  // 15
    private static final int TOTAL_BLOCKS = GRID_COLS * GRID_ROWS;  // 300
    
    // SIMPLIFIED: Frame-to-frame motion detection
    // sensitivity = average pixel difference threshold per block
    // 0.04 = 4% = ~10 out of 255 - balanced for distant detection
    private float blockSensitivity = 0.04f;  // 4% - balanced
    private int requiredActiveBlocks = 3;    // Need 3+ blocks changed to trigger
    private boolean useGridMotion = true;    // Use grid motion instead of global SAD
    
    // Sensitivity for frame-to-frame comparison (same as blockSensitivity)
    private float chromaSensitivity = 0.04f; // 4% average pixel difference threshold
    
    // SOTA: Flash Immunity Level (0=OFF, 1=LOW, 2=MEDIUM, 3=HIGH)
    // Uses edge-based detection to ignore light flashes while detecting real motion
    private int flashImmunity = 2;  // Default: MEDIUM
    
    // SOTA: Unified configuration for motion detection, flash filtering, and distance estimation
    private SurveillanceConfig config = createDefaultConfig();
    
    /**
     * Creates default config with proper resolution for mosaic mode.
     * SOTA: Enables chroma filtering by default to ignore lighting changes.
     */
    private static SurveillanceConfig createDefaultConfig() {
        SurveillanceConfig cfg = new SurveillanceConfig(
            SurveillanceConfig.DistancePreset.MEDIUM,
            SurveillanceConfig.FlashMode.ADAPTIVE
        );
        // CRITICAL: Set resolution to match THUMBNAIL dimensions
        cfg.setResolution(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
        cfg.setIsMosaic(true);  // We use 2x2 mosaic layout
        cfg.setUseChroma(true); // SOTA: Enable chroma filtering to ignore lighting changes
        return cfg;
    }
    
    // Track active blocks for UI display
    private int lastActiveBlocksCount = 0;
    private int lastTemporalBlocksCount = 0;  // SOTA: Temporally consistent blocks
    private int lastMotionMinY = 0;           // SOTA: Top of motion bounding box
    private int lastMotionMaxY = 0;           // SOTA: Bottom of motion bounding box
    private float lastEstimatedDistance = 0;  // SOTA: Estimated distance in meters
    
    // First frame flag - need one frame to initialize reference
    private boolean hasFirstFrame = false;
    
    // Pre-record and post-record configuration (configurable via API)
    private long preRecordMs = 5000;    // 5 seconds before motion (default)
    private long postRecordMs = 10000;  // 10 seconds after motion (default)
    private long recordingStopTime = 0;  // When to stop recording (motion time + post-record)
    private long lastRecordingStopTime = 0;  // When last recording stopped (for cooldown)
    
    // Detection mode
    private boolean useMog2 = false;
    private boolean useObjectDetection = false;
    private YoloDetector yoloDetector = null;
    
    // Object detection filters (SOTA: Quadrant-relative height filter in YoloDetector)
    private float minObjectSize = 0.12f;  // 12% of QUADRANT height (~8m for person in 2x2 grid)
    private float aiConfidence = 0.25f;  // 25% confidence (lowered for debugging)
    private int[] classFilter = null;  // null = all classes, or {0, 2, 3} for person, car, bike
    
    // AI throttling - only run YOLO every 500ms to save CPU
    private long lastAiTimeMs = 0;
    private static final long AI_COOLDOWN_MS = 500;
    
    // --- SOTA FIX: Persistent Resources (Eliminates GC Stutter) ---
    // 1. Reusable Buffer: Prevents ~900KB allocation per frame
    private byte[] aiBuffer = null;
    // 2. Single Thread Executor: Prevents OS thread creation overhead
    private final ExecutorService aiExecutor = Executors.newSingleThreadExecutor();
    // 3. Atomic Flag for thread safety
    private final AtomicBoolean isAiRunning = new AtomicBoolean(false);
    // --- END SOTA FIX ---
    
    // Motion mask for overlap checking (stored from last MOG2 run)
    private byte[] lastMotionMask = null;
    
    // State
    private boolean active = false;
    private boolean inActiveMode = false;
    private boolean recording = false;
    
    // SOTA: Event timeline collector for JSON sidecar files
    private final EventTimelineCollector timelineCollector = new EventTimelineCollector();
    
    // Output directory
    private File eventOutputDir;
    private File currentEventFile;
    
    // Frame dimensions - SOTA: Increased to 640x480 for better AI detection
    // At 320x240 with quad view, each camera is 160x120 - too small for YOLO
    // At 640x480 with quad view, each camera is 320x240 - YOLO can detect people at 5m
    private static final int THUMBNAIL_WIDTH = 640;
    private static final int THUMBNAIL_HEIGHT = 480;
    private static final int BYTES_PER_PIXEL = 3;  // RGB
    private static final int FRAME_SIZE = THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT * BYTES_PER_PIXEL;
    
    // Stats
    private int frameCount = 0;
    private int motionDetections = 0;
    
    /**
     * Initializes the surveillance engine.
     * 
     * @param eventDir Directory for saving event recordings
     * @param downscaler GPU downscaler reference for buffer recycling
     */
    public void init(File eventDir, GpuDownscaler downscaler) {
        init(eventDir, downscaler, null, null);
    }
    
    /**
     * Initializes the surveillance engine with optional AssetManager for YOLO loading.
     * 
     * @param eventDir Directory for saving event recordings
     * @param downscaler GPU downscaler reference for buffer recycling
     * @param assetManager Android AssetManager for loading YOLO model (null = skip YOLO)
     */
    public void init(File eventDir, GpuDownscaler downscaler, android.content.res.AssetManager assetManager) {
        init(eventDir, downscaler, assetManager, null);
    }
    
    /**
     * Initializes the surveillance engine with Context for Java TFLite.
     * 
     * @param eventDir Directory for saving event recordings
     * @param downscaler GPU downscaler reference for buffer recycling
     * @param assetManager Android AssetManager (unused, kept for compatibility)
     * @param context Android Context for TFLite initialization
     */
    public void init(File eventDir, GpuDownscaler downscaler, android.content.res.AssetManager assetManager, android.content.Context context) {
        this.eventOutputDir = eventDir;
        this.downscaler = downscaler;
        
        if (!eventDir.exists()) {
            eventDir.mkdirs();
        }
        
        // Allocate direct buffers for NativeMotion
        referenceFrame = ByteBuffer.allocateDirect(FRAME_SIZE);
        referenceFrame.order(ByteOrder.nativeOrder());
        
        currentFrame = ByteBuffer.allocateDirect(FRAME_SIZE);
        currentFrame.order(ByteOrder.nativeOrder());
        
        // --- SOTA: Initialize Ring Buffer ---
        frameHistory = new ByteBuffer[FRAME_HISTORY_SIZE];
        for (int i = 0; i < FRAME_HISTORY_SIZE; i++) {
            frameHistory[i] = ByteBuffer.allocateDirect(FRAME_SIZE);
            frameHistory[i].order(ByteOrder.nativeOrder());
            // Initialize to black
            for (int k = 0; k < FRAME_SIZE; k++) {
                frameHistory[i].put((byte) 0);
            }
            frameHistory[i].flip();
        }
        frameHistoryIndex = 0;
        frameHistoryCount = 0;
        // ------------------------------------
        
        // Initialize reference frame to black
        for (int i = 0; i < FRAME_SIZE; i++) {
            referenceFrame.put(i, (byte) 0);
        }
        
        // Detect available features
        try {
            // SOTA: MOG2 disabled - we use Ring Buffer + Edge Detection instead
            // MOG2 has issues with auto-exposure and doesn't work well with our temporal filtering
            useMog2 = false;  // NativeMotion.isMog2Available();
            
            logger.info("Features: MOG2=disabled (using SOTA Ring Buffer)");
            
            if (useMog2) {
                logger.info("Using MOG2 background subtraction (SOTA)");
            } else {
                logger.info("Using SAD motion detection (fallback)");
            }
            
            // Initialize Java TFLite YOLO detector
            // Note: We don't have a full Context in daemon mode, but we can create one from AssetManager
            if (context != null) {
                try {
                    logger.info("Initializing Java TFLite YOLO detector...");
                    yoloDetector = new YoloDetector(context);
                    boolean yoloLoaded = yoloDetector.init();
                    
                    if (yoloLoaded) {
                        useObjectDetection = true;
                        logger.info("YOLO model loaded successfully - object detection enabled");
                        logger.info("GPU acceleration: " + (yoloDetector.isGpuEnabled() ? "ENABLED" : "disabled (CPU fallback)"));
                    } else {
                        logger.warn("Failed to load YOLO model");
                        useObjectDetection = false;
                        yoloDetector = null;
                    }
                } catch (Exception e) {
                    logger.error("Error initializing YOLO detector: " + e.getMessage(), e);
                    useObjectDetection = false;
                    yoloDetector = null;
                }
            } else if (assetManager != null) {
                // Daemon mode: Create minimal context from AssetManager
                try {
                    logger.info("Creating AssetContext for TFLite (daemon mode)...");
                    android.content.Context assetContext = new com.overdrive.app.ai.AssetContext(assetManager);
                    
                    yoloDetector = new YoloDetector(assetContext);
                    boolean yoloLoaded = yoloDetector.init();
                    
                    if (yoloLoaded) {
                        useObjectDetection = true;
                        logger.info("YOLO model loaded successfully - object detection enabled");
                        logger.info("GPU acceleration: " + (yoloDetector.isGpuEnabled() ? "ENABLED" : "disabled (CPU fallback)"));
                    } else {
                        logger.warn("Failed to load YOLO model");
                        useObjectDetection = false;
                        yoloDetector = null;
                    }
                } catch (Exception e) {
                    logger.error("Error creating AssetContext: " + e.getMessage(), e);
                    useObjectDetection = false;
                    yoloDetector = null;
                }
            } else {
                logger.info("No Context or AssetManager provided - object detection disabled");
                useObjectDetection = false;
            }
        } catch (UnsatisfiedLinkError e) {
            logger.warn("Native features not available: " + e.getMessage());
            useMog2 = false;
            useObjectDetection = false;
        }
        
        logger.info("Initialized SOTA Engine (RingBuffer=" + FRAME_HISTORY_SIZE + ", buffer=" + FRAME_SIZE + " bytes)");
    }
    
    /**
     * Sets the mosaic recorder for event recording.
     * 
     * @param recorder Mosaic recorder instance
     */
    public void setRecorder(GpuMosaicRecorder recorder) {
        this.recorder = recorder;
    }
    
    /**
     * SOTA: Updates the event output directory.
     * Called when storage type changes (internal <-> SD card) to ensure
     * events are saved to the correct location.
     * 
     * @param eventDir New directory for saving event recordings
     */
    public void setEventOutputDir(File eventDir) {
        this.eventOutputDir = eventDir;
        if (eventDir != null && !eventDir.exists()) {
            boolean created = eventDir.mkdirs();
            logger.info("Updated event output directory: " + eventDir.getAbsolutePath() + " (created=" + created + ")");
            if (created) {
                eventDir.setReadable(true, false);
                eventDir.setExecutable(true, false);
            }
        } else {
            logger.info("Updated event output directory: " + (eventDir != null ? eventDir.getAbsolutePath() : "null"));
        }
    }
    
    /**
     * Processes a frame from the GPU downscaler.
     * 
     * This is called at 2 FPS during idle mode. When motion is detected,
     * it can be called at 5 FPS for more responsive AI.
     * 
     * CRITICAL: This method receives a BORROWED buffer from the pool.
     * The buffer MUST be recycled in a finally block to prevent pool exhaustion.
     * If async AI is needed, the data must be copied before recycling.
     * 
     * @param smallRgbFrame 320x240 RGB frame from GPU (borrowed from pool)
     */
    public void processFrame(byte[] smallRgbFrame) {
        if (!active) {
            // Still need to recycle even if not active
            if (downscaler != null) {
                downscaler.recycleBuffer(smallRgbFrame);
            }
            return;
        }
        
        if (smallRgbFrame == null || smallRgbFrame.length != FRAME_SIZE) {
            logger.warn( "Invalid frame size: " + (smallRgbFrame != null ? smallRgbFrame.length : 0));
            if (downscaler != null && smallRgbFrame != null) {
                downscaler.recycleBuffer(smallRgbFrame);
            }
            return;
        }
        
        try {
            frameCount++;
            long now = System.currentTimeMillis();
            
            // Log frame count every 100 frames to confirm frames are arriving
            if (frameCount % 100 == 0) {
                logger.info("Surveillance frame #" + frameCount + " received");
            }
            
            // MOTION THROTTLING: Skip frames to achieve 10 FPS (saves 66% CPU)
            // Still count frames and recycle buffers, just skip motion processing
            if (now - lastMotionProcessTime < MOTION_PROCESS_INTERVAL_MS) {
                return;  // Skip this frame, buffer recycled in finally block
            }
            lastMotionProcessTime = now;
            
            // First frame: store as reference, skip motion detection
            if (!hasFirstFrame) {
                currentFrame.clear();
                currentFrame.put(smallRgbFrame);
                currentFrame.flip();
                
                referenceFrame.clear();
                referenceFrame.put(smallRgbFrame);
                referenceFrame.flip();
                
                // SOTA: Fill entire ring buffer with first frame
                for (ByteBuffer buf : frameHistory) {
                    buf.clear();
                    buf.put(smallRgbFrame);
                    buf.flip();
                }
                frameHistoryIndex = 0;
                frameHistoryCount = FRAME_HISTORY_SIZE;
                
                hasFirstFrame = true;
                logger.info("First frame captured - motion detection active (RingBuffer mode)");
                return;
            }
            
            // Check if we're in active mode (within cooldown of last motion)
            boolean inCooldown = (now - lastMotionTime) < postRecordMs;
            
            // Run motion detection (frame-to-frame comparison with SOTA flash filtering)
            float motionScore = runMotionCheck(smallRgbFrame);
            
            // Grid motion returns 1.0 if enough blocks changed (and not a flash), 0.0 otherwise
            float threshold = useGridMotion ? 0.5f : (useMog2 ? mog2Threshold : sadThreshold);
            
            if (motionScore > threshold) {
                // Motion detected in this frame
                lastMotionTime = now;  // Always update last motion time
                
                // Start sustained motion timer if not already running
                if (firstMotionTime == 0) {
                    firstMotionTime = now;
                }
                
                // Check if motion has persisted long enough (SUSTAINED_MOTION_MS)
                long motionDuration = now - firstMotionTime;
                
                if (motionDuration >= SUSTAINED_MOTION_MS) {
                    // SUSTAINED MOTION CONFIRMED
                    inActiveMode = true;
                    
                    // SOTA: Log motion event to timeline collector
                    if (recording && timelineCollector.isCollecting()) {
                        timelineCollector.onMotionDetected(lastActiveBlocksCount);
                    }
                    
                    // Start recording if not already
                    if (!recording) {
                        // Check if we just stopped recording (within post-record duration)
                        boolean recentlyStoppedRecording = (now - lastRecordingStopTime) < postRecordMs;
                        
                        if (!recentlyStoppedRecording || lastRecordingStopTime == 0) {
                            motionDetections++;
                            logger.info(String.format("Sustained motion confirmed! Duration=%.1fs, blocks=%d",
                                    motionDuration / 1000.0, lastActiveBlocksCount));
                            logger.info("Starting event recording...");
                            recordingStopTime = now + postRecordMs;
                            startRecording();
                            
                            // Send motion notification with video filename after recording starts
                            try {
                                String videoFilename = currentEventFile != null ? currentEventFile.getName() : null;
                                TelegramNotifier.notifyMotion("motion", 1.0f, videoFilename);
                            } catch (Exception e) {
                                logger.warn("Failed to send motion notification: " + e.getMessage());
                            }
                        } else {
                            logger.debug(String.format("Motion during cooldown (%.1fs since stop) - ignoring",
                                    (now - lastRecordingStopTime) / 1000.0));
                        }
                    } else {
                        // Already recording - extend the stop time
                        // This keeps extending as long as motion continues
                        long newStopTime = now + postRecordMs;
                        if (newStopTime > recordingStopTime) {
                            recordingStopTime = newStopTime;
                            logger.debug(String.format("Motion continues - extending recording (stop in %.1fs)",
                                    (recordingStopTime - now) / 1000.0));
                        }
                    }
                } else {
                    // Motion detected but not sustained long enough yet
                    logger.debug(String.format("Motion building: %.1fs / %.1fs", 
                            motionDuration / 1000.0, SUSTAINED_MOTION_MS / 1000.0));
                }
            } else {
                // No motion in this frame
                
                // Only reset sustained motion timer if we're NOT currently recording
                // AND there's been no motion for a grace period (prevents single-frame resets)
                // This prevents the "stop/restart" issue during continuous motion
                if (!recording) {
                    // Grace period: 500ms (5 frames at 10 FPS) before resetting timer
                    // This allows for intermittent motion detection (e.g., every 2-3 frames)
                    long timeSinceLastMotion = now - lastMotionTime;
                    if (firstMotionTime != 0 && timeSinceLastMotion > 500) {
                        logger.debug("Motion stopped - resetting timer");
                        firstMotionTime = 0;
                    }
                }
                // If recording, keep firstMotionTime so brief gaps don't reset the timer
            }
            
            // Run AI detection if in cooldown (for logging/debugging)
            if (inCooldown && useObjectDetection) {
                runAiDetection(smallRgbFrame);
            }
            
            // Post-record check: Stop recording when stop time is reached AND no recent motion
            if (recording && now >= recordingStopTime && recordingStopTime > 0) {
                // Only stop if there's been no motion for a while
                long timeSinceLastMotion = now - lastMotionTime;
                if (timeSinceLastMotion >= postRecordMs) {
                    logger.info(String.format("Post-record complete - stopping (no motion for %.1fs)",
                            timeSinceLastMotion / 1000.0));
                    stopRecording();
                    recordingStopTime = 0;
                    firstMotionTime = 0;  // Reset for next detection cycle
                }
            }
            
            // Log stats periodically (every 500 frames = ~50 seconds at 10 FPS)
            if (frameCount % 500 == 0) {
                logger.info(String.format("Surveillance stats: frames=%d, motions=%d, recording=%b",
                        frameCount, motionDetections, recording));
            }
            
        } finally {
            // CRITICAL: Always recycle buffer back to pool
            // This MUST happen in finally block to prevent pool exhaustion
            if (downscaler != null) {
                downscaler.recycleBuffer(smallRgbFrame);
            }
        }
    }
    
    /**
     * Sets the Region of Interest (ROI) mask for motion detection.
     * 
     * @param mask Byte array (320×240) where 1 = check motion, 0 = ignore
     *             Pass null to use entire frame (default)
     */
    public void setRoiMask(byte[] mask) {
        if (mask != null && mask.length != THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT) {
            logger.error("Invalid ROI mask size: " + mask.length + 
                       " (expected " + (THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT) + ")");
            return;
        }
        
        this.roiMask = mask;
        
        // Count pixels in ROI for normalization
        if (mask != null) {
            roiPixelCount = 0;
            for (byte b : mask) {
                if (b != 0) roiPixelCount++;
            }
            logger.info("ROI mask set: " + roiPixelCount + " pixels (" + 
                      (roiPixelCount * 100 / (THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT)) + "%)");
        } else {
            roiPixelCount = THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT;
            logger.info("ROI mask cleared (using full frame)");
        }
    }
    
    /**
     * Sets ROI from polygon points (normalized 0.0-1.0 coordinates).
     * 
     * @param points Array of [x, y] pairs defining polygon vertices
     */
    public void setRoiFromPolygon(float[][] points) {
        if (points == null || points.length < 3) {
            setRoiMask(null);  // Clear ROI
            return;
        }
        
        // Create mask by rasterizing polygon
        byte[] mask = new byte[THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT];
        
        for (int y = 0; y < THUMBNAIL_HEIGHT; y++) {
            for (int x = 0; x < THUMBNAIL_WIDTH; x++) {
                float nx = (float) x / THUMBNAIL_WIDTH;
                float ny = (float) y / THUMBNAIL_HEIGHT;
                
                // Point-in-polygon test (ray casting algorithm)
                if (isPointInPolygon(nx, ny, points)) {
                    mask[y * THUMBNAIL_WIDTH + x] = 1;
                }
            }
        }
        
        setRoiMask(mask);
    }
    
    /**
     * Point-in-polygon test using ray casting.
     */
    private boolean isPointInPolygon(float x, float y, float[][] polygon) {
        boolean inside = false;
        int n = polygon.length;
        
        for (int i = 0, j = n - 1; i < n; j = i++) {
            float xi = polygon[i][0], yi = polygon[i][1];
            float xj = polygon[j][0], yj = polygon[j][1];
            
            if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
                inside = !inside;
            }
        }
        
        return inside;
    }
    
    /**
     * SOTA: Ring-Buffer Motion Check.
     * 
     * Compares current frame to previous frame (legacy) OR to frame N-3 (SOTA ring buffer).
     * After comparison, updates reference = current for next frame.
     * 
     * SOTA: Uses edge-based detection with temporal consistency,
     * chrominance filtering, and distance estimation.
     * 
     * @param rgbFrame Current RGB frame
     * @return Motion score (1.0 if motion detected, 0.0 otherwise)
     */
    private float runMotionCheck(byte[] rgbFrame) {
        // Copy current frame to direct buffer
        currentFrame.clear();
        currentFrame.put(rgbFrame);
        currentFrame.flip();
        
        float score;
        
        if (useGridMotion) {
            // SOTA: Use ring buffer comparison (N vs N-3)
            return runSOTAMotionCheck();
            
        } else if (useMog2) {
            // Legacy: MOG2 background subtraction
            score = NativeMotion.computeMOG2(
                    currentFrame, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT, 
                    roiMask, 0.001f);
            return score;
            
        } else {
            // Legacy fallback: Global SAD
            if (roiMask == null) {
                score = NativeMotion.computeSAD(
                        currentFrame, referenceFrame, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
            } else {
                score = computeSadWithRoi(currentFrame, referenceFrame, roiMask);
            }
            
            // Update reference
            NativeMotion.updateReference(
                    currentFrame, referenceFrame, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT, 0.02f);
            
            return score;
        }
    }
    
    /**
     * Computes SAD with ROI masking.
     * 
     * @param current Current frame buffer
     * @param reference Reference frame buffer
     * @param mask ROI mask (1 = check, 0 = ignore)
     * @return Normalized motion score (0.0-1.0)
     */
    private float computeSadWithRoi(ByteBuffer current, ByteBuffer reference, byte[] mask) {
        current.rewind();
        reference.rewind();
        
        long totalDiff = 0;
        int pixelCount = THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT;
        
        for (int i = 0; i < pixelCount; i++) {
            // Skip if outside ROI
            if (mask[i] == 0) {
                current.position(current.position() + 3);  // Skip RGB
                reference.position(reference.position() + 3);
                continue;
            }
            
            // Compute SAD for this pixel (RGB)
            for (int c = 0; c < 3; c++) {
                int curr = current.get() & 0xFF;
                int ref = reference.get() & 0xFF;
                totalDiff += Math.abs(curr - ref);
            }
        }
        
        // Normalize by ROI pixel count (not total pixels)
        float maxDiff = roiPixelCount * 3 * 255.0f;  // 3 channels, max diff = 255
        return totalDiff / maxDiff;
    }
    
    /**
     * SOTA: Enhanced motion detection with Ring Buffer (N vs N-3) comparison.
     * 
     * Key principles:
     * - Ring Buffer: Compare frame N to frame N-3 (300ms delta at 10 FPS)
     * - Unified Physics: Close range = Mass Law, Far range = Shape Law
     * - Dynamic Thresholds: Based on distance and object geometry
     * - Temporal Consistency: Must persist over 300ms
     * 
     * SOTA FILTERS:
     * 1. Flash Detection - Global lighting changes
     * 2. Unified Physics Gate - Distance + Mass + Shape
     * 3. Dynamic Threshold - Zone-based requirements
     * 4. Temporal Consistency - Must persist over 300ms
     * 
     * @return Motion score (1.0 if valid motion detected, 0.0 otherwise)
     */
    /**
     * GRAYSCALE GRID MOTION CHECK - UNIFIED SENSITIVITY API
     * 
     * Uses a single "Sensitivity" slider (0-100%) that intelligently maps to:
     * - Shadow Threshold: How dark a pixel change must be to count
     * - Density Threshold: How many pixels per block must change
     * - Alarm Threshold: How many blocks must trigger to start recording
     * 
     * The native code handles:
     * 1. RGB to grayscale conversion (eliminates color noise)
     * 2. N vs N-3 frame comparison (ring buffer for stability)
     * 3. Per-pixel shadow filtering (ignores faint changes)
     * 4. Global light filter (ignores auto-exposure)
     * 5. Spatial clustering (rejects scattered noise)
     */
    private float runSOTAMotionCheck() {
        // =====================================================================
        // UNIFIED SENSITIVITY MAPPING
        // =====================================================================
        // Get thresholds from config (mapped from 0-100% slider)
        int shadowThreshold = config.getShadowThreshold();      // 25 (day) or 40 (night)
        int densityThreshold = config.getDensityThreshold();    // 8-64 based on sensitivity
        int alarmBlockThreshold = config.getAlarmBlockThreshold(); // 1-5 based on sensitivity
        
        // Periodic status log every 50 frames (~5 seconds at 10 FPS)
        // Log BEFORE native call to confirm frames are being processed
        if (frameCount % 50 == 0) {
            logger.info(String.format("Motion check #%d: alarm=%d, density=%d, shadow=%d",
                frameCount, alarmBlockThreshold, densityThreshold, shadowThreshold));
        }
        
        // --- GET COMPARISON FRAME (N-3) from Ring Buffer ---
        // This 300ms delta filters out engine vibration and jitter
        int compareIndex = (frameHistoryIndex - FRAME_COMPARE_OFFSET + FRAME_HISTORY_SIZE) % FRAME_HISTORY_SIZE;
        ByteBuffer compareFrame = frameHistory[compareIndex];
        
        // Call native Grayscale Grid detection with explicit thresholds
        long result = NativeMotion.computeGrayscaleGrid(
                currentFrame, compareFrame,
                THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT,
                shadowThreshold, densityThreshold, alarmBlockThreshold);
        
        // --- UPDATE RING BUFFER ---
        // CRITICAL: Reset buffer positions before copying
        // currentFrame was flipped after put(), so position=0, limit=FRAME_SIZE
        frameHistory[frameHistoryIndex].clear();  // position=0, limit=capacity
        currentFrame.position(0);
        currentFrame.limit(FRAME_SIZE);
        frameHistory[frameHistoryIndex].put(currentFrame);
        frameHistory[frameHistoryIndex].flip();
        
        // Reset currentFrame for next use
        currentFrame.clear();
        
        // Advance ring buffer index
        frameHistoryIndex = (frameHistoryIndex + 1) % FRAME_HISTORY_SIZE;
        if (frameHistoryCount < FRAME_HISTORY_SIZE) {
            frameHistoryCount++;
        }
        
        // Update legacy reference frame for backward compatibility
        referenceFrame.clear();
        currentFrame.position(0);
        currentFrame.limit(FRAME_SIZE);
        referenceFrame.put(currentFrame);
        referenceFrame.flip();
        currentFrame.clear();
        
        // Unpack 64-bit result
        boolean isFlash = NativeMotion.unpackIsFlash(result);
        int temporalBlocks = NativeMotion.unpackTemporalBlocks(result);
        int maxY = NativeMotion.unpackMaxY(result);
        int minY = NativeMotion.unpackMinY(result);
        int rawBlocks = NativeMotion.unpackRawBlocks(result);
        
        // Store for UI display
        lastActiveBlocksCount = rawBlocks;
        lastTemporalBlocksCount = temporalBlocks;
        lastMotionMinY = minY;
        lastMotionMaxY = maxY;
        
        // --- FILTER 1: Global Light Change (handled in native, but double-check) ---
        if (isFlash) {
            logger.debug(String.format("💡 Global light change - Ignored (raw=%d)", rawBlocks));
            return 0.0f;
        }
        
        // --- FILTER 2: Distance Estimation (optional) ---
        if (maxY > 0) {
            float distance = config.estimateDistance(maxY);
            lastEstimatedDistance = distance;
            
            // Optional: Max distance filter
            float maxDist = config.getMaxDistanceM();
            if (maxDist > 0 && distance > maxDist) {
                logger.debug(String.format("Motion too far: %.1fm > %.1fm", distance, maxDist));
                return 0.0f;
            }
        } else {
            lastEstimatedDistance = -1.0f;
        }
        
        // --- FILTER 3: Minimum Block Threshold ---
        // Native code already applies alarmBlockThreshold, but we keep a sanity check
        if (rawBlocks < alarmBlockThreshold) {
            if (rawBlocks > 0) {
                logger.debug(String.format("👻 Ignored: %d blocks (need>=%d)", rawBlocks, alarmBlockThreshold));
            }
            return 0.0f;
        }
        
        // --- MOTION CONFIRMED ---
        // Log with sensitivity info for debugging
        int sensitivity = config.getUnifiedSensitivity();
        logger.info(String.format("✓ Motion DETECTED: raw=%d, sens=%d%% (alarm=%d, density=%d, shadow=%d), dist=%.1fm", 
                rawBlocks, sensitivity, alarmBlockThreshold, densityThreshold, shadowThreshold, lastEstimatedDistance));
        return 1.0f;
    }
    
    /**
     * Sets the SOTA surveillance configuration.
     * 
     * @param config Configuration object with distance preset, flash mode, and camera calibration
     */
    public void setConfig(SurveillanceConfig config) {
        this.config = config;
        
        // Sync legacy fields for backward compatibility
        this.flashImmunity = config.getFlashImmunity();
        this.blockSensitivity = config.getSensitivity();
        this.chromaSensitivity = config.getSensitivity();
        this.requiredActiveBlocks = config.getRequiredBlocks();
        this.minObjectSize = config.getMinObjectSize();
        this.aiConfidence = config.getAiConfidence();
        this.preRecordMs = config.getPreRecordSeconds() * 1000L;
        this.postRecordMs = config.getPostRecordSeconds() * 1000L;
        
        // Update frame dimensions in config for distance estimation
        config.setResolution(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);
        config.setIsMosaic(true);  // We use 2x2 mosaic layout
        
        logger.info("SOTA config applied: " + config.toString());
    }
    
    /**
     * Gets the current SOTA configuration.
     * 
     * @return Current configuration
     */
    public SurveillanceConfig getConfig() {
        return config;
    }
    
    /**
     * Gets the last estimated distance to motion.
     * 
     * @return Distance in meters, or 0 if no motion detected
     */
    public float getLastEstimatedDistance() {
        return lastEstimatedDistance;
    }
    
    /**
     * Gets the last temporal blocks count (blocks with temporal consistency).
     * 
     * @return Number of temporally consistent blocks
     */
    public int getLastTemporalBlocksCount() {
        return lastTemporalBlocksCount;
    }
    
    /**
     * Gets the last motion bounding box Y coordinates.
     * 
     * @return int array [minY, maxY] or null if no motion
     */
    public int[] getLastMotionBounds() {
        if (lastMotionMaxY > lastMotionMinY) {
            return new int[] { lastMotionMinY, lastMotionMaxY };
        }
        return null;
    }
    
    /**
     * Runs AI detection on the frame with object detection and filtering.
     * 
     * SOTA: Runs asynchronously to prevent blocking video encoder.
     * If previous AI inference is still running, this frame is skipped.
     * 
     * Uses YOLO or similar detector to identify specific objects (person, car, bike).
     * Filters by object height (better for distance filtering than area).
     * Throttled to run every 500ms to save CPU for recording.
     * 
     * @param rgbFrame 320x240 RGB frame (borrowed from pool - will be copied for async)
     */
    private void runAiDetection(byte[] rgbFrame) {
        if (!useObjectDetection) {
            // Object detection not available
            return;
        }
        
        // Skip if previous AI inference is still running
        if (isAiRunning.get()) {
            return;
        }
        
        // AI throttling - only run every 500ms to save CPU
        long now = System.currentTimeMillis();
        if ((now - lastAiTimeMs) < AI_COOLDOWN_MS) {
            return;
        }
        lastAiTimeMs = now;
        
        // SOTA FIX: Lazy-init reusable buffer (allocates ONCE per session)
        if (aiBuffer == null || aiBuffer.length != rgbFrame.length) {
            aiBuffer = new byte[rgbFrame.length];
        }
        
        // SOTA FIX: System.arraycopy to reusable buffer (no GC allocation)
        System.arraycopy(rgbFrame, 0, aiBuffer, 0, rgbFrame.length);
        
        // Mark as running
        isAiRunning.set(true);
        
        // SOTA FIX: Submit to executor (reuses thread, no Thread creation overhead)
        aiExecutor.execute(() -> {
            try {
                long startTime = System.currentTimeMillis();
                
                // Use the persistent buffer
                byte[] rgbArray = aiBuffer;
                
                // Parse class filter
                boolean detectPerson = true;
                boolean detectCar = true;
                boolean detectBike = true;
                
                if (classFilter != null && classFilter.length > 0) {
                    detectPerson = false;
                    detectCar = false;
                    detectBike = false;
                    
                    for (int cls : classFilter) {
                        if (cls == 0) detectPerson = true;
                        if (cls == 2 || cls == 5 || cls == 7) detectCar = true;
                        if (cls == 1 || cls == 3) detectBike = true;
                    }
                }
                
                // Run object detection
                List<Detection> detections = yoloDetector.detect(
                        rgbArray, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT,
                        aiConfidence, detectPerson, detectCar, false, detectBike,
                        minObjectSize
                );
                
                long inferenceTime = System.currentTimeMillis() - startTime;
                
                if (detections != null && !detections.isEmpty()) {
                    int relevantCount = 0;
                    
                    for (Detection det : detections) {
                        int classId = det.getClassId();
                        // person=0, bicycle=1, car=2, motorcycle=3, bus=5, truck=7
                        if (classId == 0 || classId == 1 || classId == 2 || 
                            classId == 3 || classId == 5 || classId == 7) {
                            relevantCount++;
                        }
                    }
                    
                    // Extend recording if relevant objects with active motion
                    if (relevantCount > 0) {
                        long timeSinceMotion = System.currentTimeMillis() - lastMotionTime;
                        if (timeSinceMotion < 2000) {
                            lastMotionTime = System.currentTimeMillis();
                        }
                        
                        // SOTA: Log AI detections to timeline (only with active motion)
                        boolean hasActiveMotion = timeSinceMotion < 2000;
                        if (recording && timelineCollector.isCollecting()) {
                            timelineCollector.onAiDetection(detections, hasActiveMotion);
                        }
                    }
                }
                
            } catch (Exception e) {
                logger.error("AI detection error", e);
            } finally {
                isAiRunning.set(false);
            }
        });
    }
    
    /**
     * Gets class name from COCO class ID.
     */
    private String getClassName(int classId) {
        switch (classId) {
            case 0: return "person";
            case 2: return "car";
            case 3: return "motorcycle";
            case 5: return "bus";
            case 7: return "truck";
            default: return "object_" + classId;
        }
    }
    
    /**
     * Sets object detection filters.
     * 
     * Also adjusts motion detection sensitivity based on minSize:
     * - Lower minSize (for distant objects) = lower motion sensitivity
     * - Higher minSize (for close objects) = higher motion sensitivity
     * 
     * @param minSize Minimum object size (0.0-1.0, fraction of frame area)
     * @param confidence Minimum confidence (0.0-1.0)
     * @param detectPerson Enable person detection
     * @param detectCar Enable car detection
     * @param detectBike Enable bike detection
     */
    public void setObjectFilters(float minSize, float confidence, 
                                 boolean detectPerson, boolean detectCar, boolean detectBike) {
        this.minObjectSize = minSize;
        this.aiConfidence = confidence;
        
        // Build class filter for YOLO
        java.util.ArrayList<Integer> classes = new java.util.ArrayList<>();
        if (detectPerson) classes.add(0);  // COCO: person
        if (detectCar) {
            classes.add(2);  // COCO: car
            classes.add(5);  // COCO: bus
            classes.add(7);  // COCO: truck
        }
        if (detectBike) {
            classes.add(1);  // COCO: bicycle
            classes.add(3);  // COCO: motorcycle
        }
        
        if (classes.isEmpty()) {
            classFilter = null;  // Detect all classes
        } else {
            classFilter = new int[classes.size()];
            for (int i = 0; i < classes.size(); i++) {
                classFilter[i] = classes.get(i);
            }
        }
        
        logger.info(String.format("Object filters: minSize=%.1f%%, confidence=%.0f%%, classes=%s",
                minSize * 100, confidence * 100, classes));
    }
    
    /**
     * Starts recording an event with pre-record support.
     * 
     * The encoder is always running and buffering frames. This method
     * triggers the flush of the pre-record buffer and starts writing to file.
     */
    private void startRecording() {
        if (recorder == null) {
            logger.error("Cannot start recording - recorder is null");
            return;
        }
        
        if (recording) {
            logger.debug("Already recording");
            return;
        }
        
        // SOTA: Ensure storage space before recording (auto-cleanup oldest files)
        try {
            com.overdrive.app.storage.StorageManager storageManager =
                com.overdrive.app.storage.StorageManager.getInstance();
            
            // Safety net: verify SD card is still mounted before writing
            // BYD system can unmount it at any time when ACC is off
            if (storageManager.getSurveillanceStorageType() == 
                com.overdrive.app.storage.StorageManager.StorageType.SD_CARD &&
                !storageManager.isSdCardMounted()) {
                logger.warn("SD card unmounted before recording - attempting remount");
                if (!storageManager.ensureSdCardMounted(true)) {
                    logger.error("SD card remount failed - event may write to stale path");
                }
            }
            
            // Reserve ~50MB for new recording (typical event is 10-30MB)
            boolean spaceAvailable = storageManager.ensureSurveillanceSpace(50 * 1024 * 1024);
            if (!spaceAvailable) {
                logger.warn("Storage cleanup could not free enough space, recording anyway");
            }
        } catch (Exception e) {
            logger.warn("Storage check failed: " + e.getMessage());
        }
        
        String timestamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
        String fileName = "event_" + timestamp + ".mp4";
        currentEventFile = new File(eventOutputDir, fileName);
        
        logger.info("Triggering event recording: " + currentEventFile.getAbsolutePath());
        logger.info(String.format("Pre-record: %d sec, Post-record: %d sec", 
                preRecordMs / 1000, postRecordMs / 1000));
        
        // Trigger event recording (flushes pre-record buffer)
        recorder.triggerEventRecording(currentEventFile.getAbsolutePath(), postRecordMs);
        recording = true;
        
        // SOTA: Start timeline event collection for this recording
        timelineCollector.startCollecting();
        
        logger.info("Event recording triggered successfully");
    }
    
    /**
     * Stops recording an event with post-record support.
     */
    private void stopRecording() {
        if (recorder == null || !recording) {
            return;
        }
        
        // Stop immediately (post-record already handled by timeout)
        recorder.stopEventRecording(true, 0);
        recording = false;
        lastRecordingStopTime = System.currentTimeMillis();  // Track when we stopped
        
        if (currentEventFile != null && currentEventFile.exists()) {
            logger.info( String.format("Saved: %s (%d KB)",
                    currentEventFile.getName(), currentEventFile.length() / 1024));
            
            // SOTA: Write timeline JSON sidecar alongside the MP4
            timelineCollector.stopAndWrite(currentEventFile);
        }
        
        currentEventFile = null;
        logger.info("Recording stopped, motion detection continues");
    }
    
    /**
     * Enables surveillance (starts monitoring).
     */
    public void enable() {
        // Check if native library is loaded
        if (!NativeMotion.isLibraryLoaded()) {
            logger.error("Cannot enable surveillance: NativeMotion library not loaded. Error: " + 
                NativeMotion.getLoadError());
            return;
        }
        
        active = true;
        frameCount = 0;
        motionDetections = 0;
        firstMotionTime = 0;  // Reset sustained motion timer
        
        // Reset first frame flag - next frame will initialize reference
        hasFirstFrame = false;
        
        // Reset reference frame to zeros
        if (referenceFrame != null) {
            referenceFrame.clear();
            for (int i = 0; i < FRAME_SIZE; i++) {
                referenceFrame.put((byte) 0);
            }
            referenceFrame.flip();
        }
        
        // SOTA: Reset ring buffer for clean start
        if (frameHistory != null) {
            for (ByteBuffer buf : frameHistory) {
                buf.clear();
                for (int i = 0; i < FRAME_SIZE; i++) {
                    buf.put((byte) 0);
                }
                buf.flip();
            }
        }
        frameHistoryIndex = 0;
        frameHistoryCount = 0;
        
        // SOTA: Reset temporal history for clean start
        try {
            NativeMotion.resetTemporalHistory();
        } catch (UnsatisfiedLinkError e) {
            logger.warn("Could not reset temporal history: " + e.getMessage());
        }
        
        // Reset SOTA tracking variables
        lastTemporalBlocksCount = 0;
        lastMotionMinY = 0;
        lastMotionMaxY = 0;
        lastEstimatedDistance = 0;
        
        // SOTA: Notify StorageManager that surveillance is active (for periodic cleanup)
        try {
            com.overdrive.app.storage.StorageManager.getInstance().setSurveillanceActive(true);
        } catch (Exception e) {
            logger.warn("Could not set surveillance active state: " + e.getMessage());
        }
        
        logger.info("Surveillance enabled (RingBuffer mode, sustained motion: " + (SUSTAINED_MOTION_MS / 1000.0) + "s)");
    }
    
    /**
     * Disables surveillance (stops monitoring).
     */
    public void disable() {
        if (recording) {
            stopRecording();
        }
        active = false;
        inActiveMode = false;
        
        // SOTA: Notify StorageManager that surveillance is inactive
        try {
            com.overdrive.app.storage.StorageManager.getInstance().setSurveillanceActive(false);
        } catch (Exception e) {
            logger.warn("Could not set surveillance inactive state: " + e.getMessage());
        }
        
        logger.info("Surveillance disabled");
    }
    
    /**
     * Checks if surveillance is active.
     * 
     * @return true if active, false otherwise
     */
    public boolean isActive() {
        return active;
    }
    
    /**
     * Checks if currently recording.
     * 
     * @return true if recording, false otherwise
     */
    public boolean isRecording() {
        return recording;
    }
    
    /**
     * Checks if in active mode (heavy AI).
     * 
     * @return true if in active mode, false if idle
     */
    public boolean isInActiveMode() {
        return inActiveMode;
    }
    
    /**
     * Gets the current SAD threshold.
     * 
     * @return Threshold value (0.0-1.0)
     */
    public float getSadThreshold() {
        return sadThreshold;
    }
    
    /**
     * Gets the grid motion block sensitivity.
     * 
     * @return Sensitivity value (0.0-1.0, typically 0.04-0.10)
     */
    public float getBlockSensitivity() {
        return blockSensitivity;
    }
    
    /**
     * Sets the grid motion block sensitivity.
     * Lower values detect more distant/subtle motion.
     * 
     * @param sensitivity Sensitivity value (0.01-0.20, default 0.04)
     */
    public void setBlockSensitivity(float sensitivity) {
        this.blockSensitivity = Math.max(0.01f, Math.min(0.20f, sensitivity));
        this.chromaSensitivity = this.blockSensitivity;  // Keep in sync
        // Sync with SOTA config
        config.setSensitivity(this.blockSensitivity);
        logger.info("Block sensitivity set to: " + this.blockSensitivity);
    }
    
    /**
     * Sets the unified motion sensitivity (0-100%).
     * 
     * This is the recommended API for controlling motion detection.
     * A single slider that intelligently adjusts:
     * - Density Threshold: How many pixels must change per block
     * - Alarm Threshold: How many blocks must trigger to start recording
     * 
     * Mapping:
     * - 0-30%:   LOW (large/close objects only)
     * - 31-60%:  MEDIUM (balanced, default)
     * - 61-80%:  HIGH (detects distant objects)
     * - 81-100%: VERY HIGH (any motion)
     * 
     * @param sensitivity 0-100 percentage
     */
    public void setUnifiedSensitivity(int sensitivity) {
        config.setUnifiedSensitivity(sensitivity);
        
        // Sync legacy fields for backward compatibility
        this.requiredActiveBlocks = config.getAlarmBlockThreshold();
        
        logger.info(String.format("Unified sensitivity set to: %d%% (alarm=%d blocks, density=%d pixels, shadow=%d)",
                sensitivity, config.getAlarmBlockThreshold(), config.getDensityThreshold(), config.getShadowThreshold()));
    }
    
    /**
     * Gets the unified motion sensitivity (0-100%).
     * 
     * @return Sensitivity percentage
     */
    public int getUnifiedSensitivity() {
        return config.getUnifiedSensitivity();
    }
    
    /**
     * Sets night mode (affects shadow threshold).
     * 
     * Night mode uses a higher shadow threshold (40 vs 25) to filter
     * out headlight reflections and other light artifacts.
     * 
     * @param enabled true for night mode
     */
    public void setNightMode(boolean enabled) {
        config.setNightMode(enabled);
        logger.info("Night mode set to: " + enabled + " (shadow threshold=" + config.getShadowThreshold() + ")");
    }
    
    /**
     * Gets night mode state.
     * 
     * @return true if night mode is enabled
     */
    public boolean isNightMode() {
        return config.isNightMode();
    }
    
    /**
     * Gets the required active blocks threshold.
     * 
     * @return Number of blocks required to trigger motion
     */
    public int getRequiredActiveBlocks() {
        return requiredActiveBlocks;
    }
    
    /**
     * Sets the required active blocks threshold.
     * Lower values are more sensitive to small/distant motion.
     * 
     * @param blocks Number of blocks (1-10, default 2)
     */
    public void setRequiredActiveBlocks(int blocks) {
        this.requiredActiveBlocks = Math.max(1, Math.min(10, blocks));
        // Sync with SOTA config
        config.setRequiredBlocks(this.requiredActiveBlocks);
        logger.info("Required active blocks set to: " + this.requiredActiveBlocks);
    }
    
    /**
     * Gets the flash immunity level.
     * 
     * @return Flash immunity level (0=OFF, 1=LOW, 2=MEDIUM, 3=HIGH)
     */
    public int getFlashImmunity() {
        return flashImmunity;
    }
    
    /**
     * Gets the minimum object size for detection.
     * 
     * @return Minimum object size as fraction of frame (0.02 = 2% = ~15m, 0.20 = 20% = ~3m)
     */
    public float getMinObjectSize() {
        return minObjectSize;
    }
    
    /**
     * Sets the flash immunity level.
     * 
     * Uses edge-based detection to ignore light flashes (headlights, lightning, etc.)
     * while still detecting real object motion.
     * 
     * Levels:
     * - 0 = OFF: Legacy pixel differencing, sensitive to flashes
     * - 1 = LOW: Edge-based, some flash filtering
     * - 2 = MEDIUM: Edge-based + brightness normalization (default)
     * - 3 = HIGH: Edge-based + aggressive flash rejection
     * 
     * @param level Flash immunity level (0-3)
     */
    public void setFlashImmunity(int level) {
        this.flashImmunity = Math.max(0, Math.min(3, level));
        // Sync with SOTA config
        config.setFlashImmunity(this.flashImmunity);
        String[] levelNames = {"OFF", "LOW", "MEDIUM", "HIGH"};
        logger.info("Flash immunity set to: " + levelNames[this.flashImmunity] + " (" + this.flashImmunity + ")");
    }
    
    /**
     * Gets the total number of grid blocks.
     * 
     * @return Total blocks (300 for 640x480 with 32px blocks)
     */
    public int getTotalBlocks() {
        return TOTAL_BLOCKS;
    }
    
    /**
     * Gets the last active blocks count (for UI display).
     * 
     * @return Number of blocks that were active in the last frame
     */
    public int getLastActiveBlocksCount() {
        return lastActiveBlocksCount;
    }
    
    /**
     * Gets the baseline noise blocks count (deprecated - always returns 0).
     * 
     * @return Always 0 (baseline logic removed)
     */
    public int getBaselineNoiseBlocks() {
        return 0;  // Baseline logic removed for simplicity
    }
    
    /**
     * Sets the SAD threshold for motion detection.
     * 
     * @param threshold Threshold value (0.0-1.0, typically 0.05 for 5%)
     */
    public void setSadThreshold(float threshold) {
        this.sadThreshold = threshold;
        logger.info( "SAD threshold set to: " + threshold);
    }
    
    /**
     * Gets the pre-record duration in seconds.
     * 
     * @return Pre-record duration in seconds
     */
    public int getPreRecordSeconds() {
        return (int) (preRecordMs / 1000);
    }
    
    /**
     * Sets the pre-record duration.
     * 
     * @param seconds Duration in seconds (e.g., 10 for 10 seconds before motion)
     */
    public void setPreRecordSeconds(int seconds) {
        this.preRecordMs = seconds * 1000L;
        // Sync with SOTA config
        config.setPreRecordSeconds(seconds);
        logger.info("Pre-record duration set to: " + seconds + " seconds");
        
        // Update the circular buffer size in the recorder's encoder
        if (recorder != null && recorder.getEncoder() != null) {
            recorder.getEncoder().setPreRecordDuration(seconds);
        }
    }
    
    /**
     * Gets the post-record duration in seconds.
     * 
     * @return Post-record duration in seconds
     */
    public int getPostRecordSeconds() {
        return (int) (postRecordMs / 1000);
    }
    
    /**
     * Sets the post-record duration.
     * 
     * @param seconds Duration in seconds (e.g., 5 for 5 seconds after motion stops)
     */
    public void setPostRecordSeconds(int seconds) {
        this.postRecordMs = seconds * 1000L;
        // Sync with SOTA config
        config.setPostRecordSeconds(seconds);
        logger.info("Post-record duration set to: " + seconds + " seconds");
    }
    
    /**
     * Gets the frame count.
     * 
     * @return Total frames processed
     */
    public int getFrameCount() {
        return frameCount;
    }
    
    /**
     * Gets the motion detection count.
     * 
     * @return Total motion events detected
     */
    public int getMotionDetections() {
        return motionDetections;
    }
    
    /**
     * Releases all resources.
     */
    public void release() {
        disable();
        
        // SOTA FIX: Shutdown the executor
        aiExecutor.shutdownNow();
        
        // Clean up YOLO detector
        if (yoloDetector != null) {
            yoloDetector.close();
            yoloDetector = null;
        }
        
        referenceFrame = null;
        currentFrame = null;
        aiBuffer = null;  // Let GC reclaim the large buffer
        
        // SOTA: Clean up ring buffer
        if (frameHistory != null) {
            for (int i = 0; i < frameHistory.length; i++) {
                frameHistory[i] = null;
            }
            frameHistory = null;
        }
        
        logger.info("Released");
    }
    
}
