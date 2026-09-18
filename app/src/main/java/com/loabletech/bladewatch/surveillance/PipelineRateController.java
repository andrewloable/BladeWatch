package net.bladewatch.app.surveillance;

import net.bladewatch.app.logging.DaemonLogger;

/**
 * Transitions the surveillance/detection processing rate by driving state, without touching
 * the recording pipeline (BladeWatch-t1lg.3). The bitrate-adapting sibling class owns bitrate;
 * this owns detection frame rate -- two owners for one knob is the bug that split prevents.
 *
 * <p>Recording quality (resolution, codec, bitrate, the encoder, the EGL context) is never
 * touched here. The single hard requirement this class exists to satisfy: a rate change must
 * never cause encoder re-init or EGL teardown, and must never reset the motion pipeline's
 * state (confidence history, quadrant state, tracker continuity) -- it only changes how often
 * frames reach that pipeline, via {@link RateTarget#setDetectionRate}.
 */
public final class PipelineRateController {

    private static final DaemonLogger logger = DaemonLogger.getInstance("PipelineRateController");

    /** Sane default: driving means the head unit has better things to do than watch for prowlers. */
    static final int DEFAULT_DRIVING_FPS = 5;
    /** Sane default: parked and quiet for a while -- still armed, just not working hard. */
    static final int DEFAULT_IDLE_FPS = 2;

    /**
     * Implemented by whatever actually throttles frame delivery to the detection pipeline
     * (e.g. {@code AiLaneWorker}, by adjusting how many submitted frames it accepts). Must
     * never call anything that tears down or re-initializes the encoder/EGL context.
     */
    public interface RateTarget {
        void setDetectionRate(int fps);
    }

    /**
     * Pure decision, no camera/EGL/Android -- see the class doc for the policy. A live viewer
     * or recent motion always wins (full configured rate); otherwise ACC state picks the
     * driving or idle rate, using this project's sane defaults. Never exceeds
     * {@code configuredFps} -- a "power saving" mode that raises the frame rate above what the
     * owner configured would be absurd.
     */
    public static int targetFps(boolean accOn, boolean liveViewersPresent, boolean motionRecently, int configuredFps) {
        return targetFps(accOn, liveViewersPresent, motionRecently, configuredFps, DEFAULT_DRIVING_FPS, DEFAULT_IDLE_FPS);
    }

    /** Same policy, with the driving/idle rates as parameters -- see {@link #loadDrivingFps}/{@link #loadIdleFps}. */
    static int targetFps(boolean accOn, boolean liveViewersPresent, boolean motionRecently,
                          int configuredFps, int drivingFps, int idleFps) {
        if (liveViewersPresent || motionRecently) {
            return configuredFps;
        }
        int reduced = accOn ? drivingFps : idleFps;
        return Math.min(configuredFps, reduced);
    }

    /**
     * Reads {@code camera.detectionDrivingFps} from unified config, mirroring
     * {@code GpuSurveillancePipeline.loadTargetFps}'s pattern exactly. Falls back to
     * {@link #DEFAULT_DRIVING_FPS} if missing or unreadable.
     */
    static int loadDrivingFps() {
        try {
            org.json.JSONObject cameraConfig = net.bladewatch.app.config.UnifiedConfigManager
                    .loadConfig().optJSONObject("camera");
            if (cameraConfig != null) {
                return cameraConfig.optInt("detectionDrivingFps", DEFAULT_DRIVING_FPS);
            }
        } catch (Exception ignored) {
            logger.warn("Failed to read detectionDrivingFps from config — defaulting to "
                    + DEFAULT_DRIVING_FPS + "fps: " + ignored.getMessage());
        }
        return DEFAULT_DRIVING_FPS;
    }

    /** Reads {@code camera.detectionIdleFps} from unified config. See {@link #loadDrivingFps}. */
    static int loadIdleFps() {
        try {
            org.json.JSONObject cameraConfig = net.bladewatch.app.config.UnifiedConfigManager
                    .loadConfig().optJSONObject("camera");
            if (cameraConfig != null) {
                return cameraConfig.optInt("detectionIdleFps", DEFAULT_IDLE_FPS);
            }
        } catch (Exception ignored) {
            logger.warn("Failed to read detectionIdleFps from config — defaulting to "
                    + DEFAULT_IDLE_FPS + "fps: " + ignored.getMessage());
        }
        return DEFAULT_IDLE_FPS;
    }

    // ==================== Transition owner ====================

    /** How long after the last motion event to ramp back down. Not user-configurable (yet) -- unlike
     * the two rates, the issue only asked for the rates themselves to come from config. */
    private static final long DEFAULT_IDLE_AFTER_MOTION_MS = 5 * 60_000L; // 5 minutes
    private static final long VIEWER_POLL_INTERVAL_MS = 15_000L;

    private static volatile PipelineRateController instance;

    private final RateTarget target;
    private final int configuredFps;
    private final int drivingFps;
    private final int idleFps;
    /** Nullable: without a scheduler, motion never auto-clears -- callers must call {@link #clearRecentMotion} themselves (this is the shape every unit test uses). */
    private final java.util.concurrent.ScheduledExecutorService scheduler;
    private final long idleAfterMotionMs;

    private volatile boolean accOn = false;
    private volatile boolean motionRecently = false;
    private volatile boolean liveViewersPresent = false;
    private volatile int lastAppliedFps = -1;
    private volatile java.util.concurrent.ScheduledFuture<?> motionTimeoutTask;

    public PipelineRateController(RateTarget target, int configuredFps, int drivingFps, int idleFps) {
        this(target, configuredFps, drivingFps, idleFps, null, 0L);
    }

    private PipelineRateController(RateTarget target, int configuredFps, int drivingFps, int idleFps,
                                    java.util.concurrent.ScheduledExecutorService scheduler, long idleAfterMotionMs) {
        this.target = target;
        this.configuredFps = configuredFps;
        this.drivingFps = drivingFps;
        this.idleFps = idleFps;
        this.scheduler = scheduler;
        this.idleAfterMotionMs = idleAfterMotionMs;
    }

    /**
     * Production entry point: reads driving/idle rates from config, starts periodic live-viewer
     * polling and per-event motion timeout. {@code liveViewerCheck} is injected (rather than
     * this class reaching for a global) because there is no standalone WebSocketStreamServer
     * singleton -- {@code GpuSurveillancePipeline} owns the instance via {@code getWebSocketServer()}.
     */
    public static synchronized PipelineRateController init(
            RateTarget target, int configuredFps, java.util.function.BooleanSupplier liveViewerCheck) {
        if (instance != null) return instance;
        java.util.concurrent.ScheduledExecutorService scheduler =
                java.util.concurrent.Executors.newSingleThreadScheduledExecutor(r -> {
                    Thread t = new Thread(r, "PipelineRateController");
                    t.setDaemon(true);
                    return t;
                });
        PipelineRateController c = new PipelineRateController(
                target, configuredFps, loadDrivingFps(), loadIdleFps(), scheduler, DEFAULT_IDLE_AFTER_MOTION_MS);
        scheduler.scheduleAtFixedRate(() -> {
            try {
                c.setLiveViewersPresent(liveViewerCheck.getAsBoolean());
            } catch (Exception e) {
                logger.warn("liveViewerCheck failed: " + e.getMessage());
            }
        }, VIEWER_POLL_INTERVAL_MS, VIEWER_POLL_INTERVAL_MS, java.util.concurrent.TimeUnit.MILLISECONDS);
        instance = c;
        return c;
    }

    /** Null until {@link #init} has run (e.g. in a JVM unit test, or before the pipeline starts). */
    public static PipelineRateController getInstance() {
        return instance;
    }

    /** Wire from the same ACC source {@code RecordingModeManager} uses -- do not add a second listener. */
    public synchronized void setAccOn(boolean isOn) {
        this.accOn = isOn;
        recompute();
    }

    /** Call the instant motion is detected -- returns to full rate on this call, not the next tick. */
    public synchronized void onMotionDetected() {
        this.motionRecently = true;
        recompute();
        if (scheduler != null) {
            java.util.concurrent.ScheduledFuture<?> previous = motionTimeoutTask;
            if (previous != null) previous.cancel(false);
            motionTimeoutTask = scheduler.schedule(
                    this::clearRecentMotion, idleAfterMotionMs, java.util.concurrent.TimeUnit.MILLISECONDS);
        }
    }

    /** Call once the "recent motion" window has elapsed with nothing further detected. */
    public synchronized void clearRecentMotion() {
        this.motionRecently = false;
        recompute();
    }

    public synchronized void setLiveViewersPresent(boolean present) {
        this.liveViewersPresent = present;
        recompute();
    }

    private void recompute() {
        int fps = targetFps(accOn, liveViewersPresent, motionRecently, configuredFps, drivingFps, idleFps);
        if (fps != lastAppliedFps) {
            int previousFps = lastAppliedFps;
            lastAppliedFps = fps;
            try {
                target.setDetectionRate(fps);
                logger.info("Detection rate " + previousFps + " -> " + fps + " fps (accOn=" + accOn
                        + ", liveViewers=" + liveViewersPresent + ", motionRecently=" + motionRecently + ")");
            } catch (Exception e) {
                logger.warn("setDetectionRate(" + fps + ") failed: " + e.getMessage());
            }
        }
    }
}
