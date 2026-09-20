package net.bladewatch.app.surveillance

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Bundle
import android.view.Surface

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.recording.RecordingPriority
import net.bladewatch.app.server.RecordingsApiHandler
import net.bladewatch.app.storage.StorageManager

import java.io.File
import java.nio.ByteBuffer
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.LinkedBlockingDeque
import java.util.concurrent.atomic.AtomicLong

/**
 * HardwareEventRecorderGpu - MediaCodec encoder with Surface input for GPU pipeline.
 *
 * This encoder receives frames directly from GPU via Surface, enabling
 * zero-copy recording. Configured for 2560x1920 @ 15 FPS with adaptive bitrate.
 *
 * Key features:
 * - COLOR_FormatSurface input (GPU → Encoder)
 * - Sync frame request on event detection
 * - Adaptive bitrate (3-8 Mbps)
 * - File rotation and corruption protection
 * - Stream splitting (H.264 output → Disk + Network simultaneously)
 *
 * <h3>Lock ordering (read this before adding any new lock or call site)</h3>
 * Three locks are used by this class plus its sibling `GpuMosaicRecorder`.
 * Always acquire them in this order; releasing in reverse is fine but never
 * acquire a higher-numbered lock while already holding a lower-numbered one
 * in reverse:
 * 1. `GpuMosaicRecorder.recordingLock` — outermost. Wraps the
 *    wrapper-level `recording` flag and the inner call to
 *    `triggerEventRecording`.
 * 2. [startStopLock] — encoder-level start/stop. Wraps
 *    [triggerEventRecording] and the public stop entry points
 *    (so a start cannot interleave with a stop on a different thread).
 *    The drainer/disk-writer threads do NOT take this lock.
 * 3. [muxerLock] — innermost. Serializes muxer field access
 *    (writeSampleData, addTrack, start, stop, release, reassign).
 *
 * Violating the order risks a deadlock if any path ever tries to acquire
 * `startStopLock` while already holding `muxerLock`, or
 * `recordingLock` while already holding `startStopLock`. Today
 * no path does, and the lock-ordering invariant exists to keep it that way.
 *
 * Background threads (drainer at [drainerThread], disk writer at
 * [diskWriterThread], segment-rotator running on the drainer) only
 * touch `muxerLock`. They observe state changes to the volatile
 * `isWritingToFile` / `muxerStarted` flags written by the
 * start/stop paths, and never try to acquire the higher-level locks.
 *
 * @param width Video width (typically 2560)
 * @param height Video height (typically 1920)
 * @param fps Frame rate (typically 15)
 * @param bitrate Bitrate in bps (typically 2-8 Mbps)
 * @param codecMimeType MIME type (MIMETYPE_VIDEO_AVC for H.264, MIMETYPE_VIDEO_HEVC for H.265)
 */
class HardwareEventRecorderGpu @JvmOverloads constructor(
    private val width: Int,
    private val height: Int,
    private var fps: Int,
    private var bitrate: Int,
    private var codecMimeType: String = MediaFormat.MIMETYPE_VIDEO_AVC
) {
    /**
     * Callback interface for streaming H.264 packets.
     * Enables zero-overhead streaming by reusing encoder output.
     */
    interface StreamCallback {
        /**
         * Called when SPS/PPS headers are available (codec config).
         * Must be sent to clients before any video frames.
         */
        fun onSpsPps(sps: ByteBuffer, pps: ByteBuffer)

        /**
         * Called for each encoded H.264 frame.
         *
         * @param h264Data Encoded frame data
         * @param info Buffer info (size, offset, timestamp, flags)
         */
        fun onH264Packet(h264Data: ByteBuffer, info: MediaCodec.BufferInfo)
    }

    // Encoder
    private var encoder: MediaCodec? = null
    private var inputSurface: Surface? = null

    // Muxer
    // SOTA: All muxer operations (writeSampleData, addTrack, start, stop, release,
    // and reassignment of the `muxer` reference) MUST be performed while holding
    // muxerLock. This makes muxer access fully serial across the drainer thread,
    // disk writer thread, rotator (drainer), and the close caller. Without this
    // lock, a concurrent writeSampleData against a stopping muxer corrupts the
    // moov atom and leaves a sized-but-unplayable .mp4 on disk — exactly the
    // failure mode that triggered this rewrite.
    private val muxerLock = Any()
    @Volatile private var muxer: MediaMuxer? = null
    @Volatile private var trackIndex = -1
    @Volatile private var muxerStarted = false
    // Set true by the disk writer when it gives up after repeated I/O failures
    // (typically SD card unmount). The current segment's mdat is broken at that
    // point — the close/rotate paths consult this flag and refuse to rename
    // tempFile -> outputPath, so the user never sees a half-written .mp4 with the
    // final extension. Reset whenever a new disk writer instance starts.
    @Volatile private var writerAbortedCorrupt = false
    private var savedFormat: MediaFormat? = null  // Save format for reuse

    // Circular buffer for pre-record
    private var preRecordBuffer: H264CircularBuffer? = null  // Reference to shared buffer
    // Volatile + accessed only under startStopLock for read-modify-write safety.
    // Concurrent triggerEventRecording calls (e.g., RecordingModeManager + the
    // deferred-format listener thread firing in the same window) used to both
    // pass the `if (isWritingToFile)` check and build two muxers, leaving two
    // .mp4.tmp files on disk with timestamps milliseconds apart. The lock
    // closes that window.
    @Volatile private var isWritingToFile = false
    private val startStopLock = Any()
    private var postRecordStopTime: Long = 0

    // SOTA: Async pre-record flush queue (eliminates blocking on motion trigger)
    // Packets are queued here and written by drainEncoder() on the GL thread.
    // Bounded to prevent OOM under SD-card stalls — at 30 fps a stalled SD
    // card would otherwise let this grow without bound.
    private val pendingFlushQueue = ConcurrentLinkedQueue<H264CircularBuffer.Packet>()
    @Volatile private var flushInProgress = false
    @Volatile private var actualPreRecordDurationMs: Long = 0  // Actual duration of flushed pre-record buffer

    private class MuxerPacket(src: ByteBuffer, srcInfo: MediaCodec.BufferInfo) {
        // Deep copy — the encoder buffer is released immediately after
        val data: ByteBuffer = ByteBuffer.allocateDirect(srcInfo.size).also { d ->
            src.position(srcInfo.offset)
            src.limit(srcInfo.offset + srcInfo.size)
            d.put(src)
            d.flip()
        }
        val info: MediaCodec.BufferInfo = MediaCodec.BufferInfo().also {
            it.set(0, srcInfo.size, srcInfo.presentationTimeUs, srcInfo.flags)
        }

        fun isKeyFrame(): Boolean = (info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0
    }

    // Use Deque for drop-oldest semantics. Bounded capacity prevents unbounded
    // growth under SD-card backpressure.
    private val muxerWriteQueue = LinkedBlockingDeque<MuxerPacket>(MUXER_WRITE_QUEUE_CAPACITY)
    private val muxerDropCount = AtomicLong(0)

    /**
     * Add a packet to the muxer write queue. If the queue is full, drop the
     * oldest non-keyframe packet to make room. If the queue is full and
     * everything in it is a keyframe (extreme stall), drop the new packet
     * unless it's also a keyframe (in which case drop the oldest keyframe).
     *
     * Logged every 30 drops so a chronic SD-card stall is visible in the
     * field instead of silently corrupting recordings.
     */
    private fun offerMuxerPacket(packet: MuxerPacket) {
        if (muxerWriteQueue.offer(packet)) {
            return
        }
        // Queue full. Walk from the head looking for a non-keyframe to drop.
        val it = muxerWriteQueue.iterator()
        var dropped = false
        while (it.hasNext()) {
            val head = it.next()
            if (!head.isKeyFrame()) {
                it.remove()
                dropped = true
                break
            }
        }
        if (!dropped) {
            // All entries are keyframes — drop the oldest. This only happens
            // under multi-second SD stalls; the recording will have a gap
            // but the daemon stays alive.
            muxerWriteQueue.pollFirst()
        }
        // Now there's space.
        muxerWriteQueue.offer(packet)
        val n = muxerDropCount.incrementAndGet()
        if (n % 30 == 1L) {
            logger.warn(
                "Muxer write queue saturated — dropped " + n +
                    " packets total. SD card likely stalled."
            )
        }
    }
    @Volatile private var diskWriterRunning = false
    private var diskWriterThread: Thread? = null

    // SOTA: Background drainer thread (moves SD card I/O off GL thread)
    @Volatile private var drainerRunning = false
    private var drainerThread: Thread? = null

    // SOTA: Flag to disable pre-record buffer for stream-only encoders
    private var usePreRecordBuffer = true

    // FIX (Bug A): Initial pre-record buffer duration. Settable BEFORE init() so the
    // first allocation honours the user's saved value instead of the hardcoded 5s.
    // setPreRecordDuration() can still resize after init.
    private var preRecordDurationSeconds = 5

    // Pre-allocated BufferInfo — reused every drain cycle to avoid per-frame allocation
    private val reusableBufferInfo = MediaCodec.BufferInfo()

    // Callback for when file is closed
    private var fileClosedCallback: Runnable? = null

    // Streaming
    private var streamCallback: StreamCallback? = null
    private var streamHeadersSent = false

    // Recording state
    private var recording = false
    private var outputPath: String? = null
    private var tempFile: File? = null
    private var recordedFrames = 0
    private var firstFramePtsUs: Long = -1   // PTS of first frame written to muxer
    private var lastFramePtsUs: Long = -1    // PTS of last frame written to muxer

    // Segment rotation
    private var segmentStartTime: Long = 0
    // Per-file recording limit. User-configurable via Settings > Recording >
    // Capture (recording.segmentMinutes in unified config; options 1/5/10).
    // Loaded from config at each recording start so changes apply to the next
    // recording. Default 5 minutes.
    private var segmentDurationMs = DEFAULT_SEGMENT_DURATION_MS
    private var segmentNumber = 0
    private var segmentBasePath: String? = null  // Base path for segment rotation (without .mp4)

    // Timing
    private var startTimeNs: Long = 0

    /**
     * Returns the configured frame rate (KEY_FRAME_RATE on the encoder format).
     * Used by the pipeline to detect FPS config drift.
     */
    fun getFps(): Int = fps

    /**
     * Sets the codec MIME type before initialization.
     * Must be called before init().
     *
     * @param mimeType MIMETYPE_VIDEO_AVC (H.264) or MIMETYPE_VIDEO_HEVC (H.265)
     */
    fun setCodecMimeType(mimeType: String) {
        if (encoder != null) {
            logger.warn("Cannot change codec after initialization - restart required")
            return
        }
        this.codecMimeType = mimeType
        logger.info(
            "Codec set to: " +
                (if (mimeType == MediaFormat.MIMETYPE_VIDEO_HEVC) "H.265/HEVC" else "H.264/AVC")
        )
    }

    /**
     * Gets the current codec MIME type.
     */
    fun getCodecMimeType(): String = codecMimeType

    /**
     * Checks if using H.265/HEVC codec.
     */
    fun isHevcCodec(): Boolean = MediaFormat.MIMETYPE_VIDEO_HEVC == codecMimeType

    /**
     * Initializes the encoder with Surface input.
     *
     * @throws Exception if initialization fails
     */
    @Throws(Exception::class)
    fun init() {
        logger.info(
            String.format(
                "Initializing: %dx%d @ %dfps, %d Mbps, codec=%s",
                width, height, fps, bitrate / 1_000_000,
                if (codecMimeType == MediaFormat.MIMETYPE_VIDEO_HEVC) "H.265" else "H.264"
            )
        )

        // Create format with Surface input - use configured codec
        val format = MediaFormat.createVideoFormat(codecMimeType, width, height)

        // CRITICAL: Use COLOR_FormatSurface for GPU input
        format.setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface
        )

        format.setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
        format.setInteger(MediaFormat.KEY_FRAME_RATE, fps)
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)  // I-frame every 2 seconds

        // Set max input size to prevent Qualcomm crashes
        format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, width * height * 3 / 2)

        // Low latency hints (optional)
        try {
            format.setInteger(MediaFormat.KEY_LATENCY, 0)
            format.setInteger(MediaFormat.KEY_PRIORITY, 0)
        } catch (e: Exception) {
            logger.warn("Low-latency hints not supported on this device: " + e.message)
        }

        // H.265 specific optimizations for Snapdragon 665
        if (codecMimeType == MediaFormat.MIMETYPE_VIDEO_HEVC) {
            try {
                // Use Main profile for better compatibility
                format.setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.HEVCProfileMain)
                format.setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.HEVCMainTierLevel4)
                logger.info("H.265 profile set to Main/Level 4")
            } catch (e: Exception) {
                logger.warn("Could not set H.265 profile: " + e.message)
            }
        } else {
            // H.264: Use Baseline Profile for iOS Safari compatibility
            try {
                format.setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.AVCProfileBaseline)
                format.setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.AVCLevel31)
                logger.info("H.264 profile set to Baseline/Level 3.1 (iOS compatible)")
            } catch (e: Exception) {
                logger.warn("Could not set H.264 profile: " + e.message)
            }
        }

        // CRITICAL: All MediaCodec operations can block if hardware encoder is stuck
        // Wrap each operation with a timeout to prevent daemon freeze
        val finalCodecMimeType = codecMimeType

        // Create encoder with timeout
        logger.info("Creating MediaCodec encoder...")
        var createdEncoder: MediaCodec? = null
        var createError: Exception? = null
        val createThread = Thread({
            try {
                createdEncoder = MediaCodec.createEncoderByType(finalCodecMimeType)
            } catch (e: Exception) {
                createError = e
            }
        }, "EncoderCreate")
        createThread.start()
        try {
            createThread.join(10000)
        } catch (e: InterruptedException) {
            logger.warn("Encoder create interrupted")
        }
        if (createThread.isAlive) {
            logger.error("MediaCodec.createEncoderByType TIMEOUT - hardware encoder stuck")
            createThread.interrupt()
            throw RuntimeException("Encoder create timeout - try restarting mediaserver")
        }
        createError?.let { throw it }
        val enc = createdEncoder!!
        encoder = enc
        // Confirm the negotiated codec name on this device, not just our intent.
        // If the device-side codec selection silently downgraded HEVC→AVC (rare,
        // but possible if the platform encoder list rejects HEVC for our params),
        // this log line surfaces it instead of leaving the user to guess from
        // file sizes.
        try {
            val negotiatedName = enc.name
            logger.info("MediaCodec encoder created (codec=$finalCodecMimeType, impl=$negotiatedName)")
        } catch (ignored: Exception) {
            logger.info("MediaCodec encoder created")
        }

        // Configure encoder with timeout
        logger.info("Configuring encoder...")
        var configDone = false
        var configError: Exception? = null
        val configThread = Thread({
            try {
                enc.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                configDone = true
            } catch (e: Exception) {
                configError = e
            }
        }, "EncoderConfig")
        configThread.start()
        try {
            configThread.join(10000)
        } catch (e: InterruptedException) {
            logger.warn("Encoder config interrupted")
        }
        if (!configDone) {
            if (configThread.isAlive) {
                logger.error("encoder.configure TIMEOUT - hardware encoder stuck")
                configThread.interrupt()
                try {
                    enc.release()
                } catch (e: Exception) {
                    logger.warn("Encoder release failed during configure timeout cleanup: " + e.message)
                }
                encoder = null
                throw RuntimeException("Encoder configure timeout")
            }
            configError?.let { throw it }
        }
        logger.info("Encoder configured")

        // Create input surface with timeout
        logger.info("Creating input surface...")
        var surfaceResult: Surface? = null
        var surfaceError: Exception? = null
        val surfaceThread = Thread({
            try {
                surfaceResult = enc.createInputSurface()
            } catch (e: Exception) {
                surfaceError = e
            }
        }, "EncoderSurface")
        surfaceThread.start()
        try {
            surfaceThread.join(10000)
        } catch (e: InterruptedException) {
            logger.warn("Surface create interrupted")
        }
        if (surfaceResult == null) {
            if (surfaceThread.isAlive) {
                logger.error("createInputSurface TIMEOUT - hardware encoder stuck")
                surfaceThread.interrupt()
                try {
                    enc.release()
                } catch (e: Exception) {
                    logger.warn("Encoder release failed during surface timeout cleanup: " + e.message)
                }
                encoder = null
                throw RuntimeException("Surface create timeout")
            }
            surfaceError?.let { throw it }
        }
        inputSurface = surfaceResult
        logger.info("Input surface created")

        // Start encoder with timeout
        logger.info("Starting encoder...")
        var startError: Exception? = null
        var startDone = false

        val startThread = Thread({
            try {
                enc.start()
                startDone = true
            } catch (e: Exception) {
                startError = e
            }
        }, "EncoderStart")

        startThread.start()
        try {
            startThread.join(10000) // 10 second timeout
        } catch (e: InterruptedException) {
            logger.warn("Encoder start interrupted")
        }

        if (!startDone) {
            if (startThread.isAlive) {
                logger.error("Encoder start TIMEOUT after 10s - hardware encoder may be stuck")
                startThread.interrupt()
                // Try to release the encoder
                try {
                    enc.release()
                } catch (e: Exception) {
                    logger.warn("Encoder release failed during start timeout cleanup: " + e.message)
                }
                encoder = null
                inputSurface = null
                throw RuntimeException("Encoder start timeout - hardware encoder busy or stuck")
            }
            startError?.let { throw it }
        }
        logger.info("Encoder started")

        // SOTA: Reuse shared buffer across encoder instances (avoids 23MB allocation on reinit)
        // Only allocate for encoders that use pre-record (not stream-only encoders)
        if (usePreRecordBuffer) {
            synchronized(bufferLock) {
                val desiredSec = Math.max(1, preRecordDurationSeconds)
                // Pass the encoder's fps so the buffer pool is sized for
                // duration × fps + headroom. Without this, switching to
                // 30 fps recording exhausts the pool (sized for 15 fps) and
                // triggers emergency allocations under sustained load.
                val shared = sharedPreRecordBuffer
                if (shared == null) {
                    logger.info("Allocating NEW pre-record buffer ($desiredSec sec @ ${fps}fps)...")
                    sharedPreRecordBuffer = H264CircularBuffer(desiredSec, fps)
                } else {
                    val desiredUs = desiredSec * 1_000_000L
                    if (shared.maxDurationUs != desiredUs) {
                        logger.info("Resizing existing pre-record buffer to $desiredSec sec @ ${fps}fps")
                        sharedPreRecordBuffer = H264CircularBuffer(desiredSec, fps)
                    } else {
                        logger.info("Reusing EXISTING pre-record buffer (Zero-Allocation)")
                        shared.clear()  // Clear old data but keep allocated memory
                    }
                }
                preRecordBuffer = sharedPreRecordBuffer
            }
        } else {
            logger.info("Pre-record buffer disabled (stream-only mode)")
            preRecordBuffer = null
        }

        // SOTA: Start background drainer thread (moves SD card I/O off GL thread)
        startDrainerThread()

        logger.info(
            "Encoder initialized successfully" +
                if (usePreRecordBuffer) " (pre-record: " + Math.max(1, preRecordDurationSeconds) + " sec)" else " (stream-only)"
        )
    }

    /**
     * Updates the pre-record buffer size.
     *
     * SOTA: Reuses existing buffer if same duration to avoid 23MB allocation.
     * Only recreates if duration actually changed.
     *
     * @param durationSeconds New buffer duration in seconds
     */
    fun setPreRecordDuration(durationSeconds: Int) {
        val clamped = Math.max(1, durationSeconds)
        // FIX (Bug A): always remember the desired duration so that a later init()
        // (e.g. after pipeline reinit) allocates the correct size.
        this.preRecordDurationSeconds = clamped
        synchronized(bufferLock) {
            val shared = sharedPreRecordBuffer
            if (shared != null) {
                // SOTA: Check if duration actually changed before reallocating
                val currentMaxDurationUs = clamped * 1_000_000L
                // Only recreate if duration is different (avoid 23MB allocation on every settings change)
                if (shared.maxDurationUs != currentMaxDurationUs) {
                    logger.info("Pre-record duration changed, recreating buffer: $clamped seconds")
                    val newBuf = H264CircularBuffer(clamped, fps)
                    sharedPreRecordBuffer = newBuf
                    preRecordBuffer = newBuf
                } else {
                    logger.info("Pre-record buffer already at $clamped seconds, clearing only")
                    shared.clear()
                }
            }
        }
    }

    /**
     * Sets whether this encoder uses the pre-record buffer.
     * Should be set to false for stream-only encoders.
     *
     * @param useBuffer true to use pre-record buffer, false for stream-only mode
     */
    fun setUsePreRecordBuffer(useBuffer: Boolean) {
        this.usePreRecordBuffer = useBuffer
        if (!useBuffer) {
            logger.info("Pre-record buffer disabled (stream-only mode)")
        }
    }

    /**
     * Sets the streaming callback for H.264 packet distribution.
     *
     * If the encoder has already output its format (SPS/PPS), the callback
     * will receive them immediately. This handles the case where a new
     * client connects after the encoder has already started.
     *
     * @param callback Callback to receive H.264 packets
     */
    fun setStreamCallback(callback: StreamCallback?) {
        this.streamCallback = callback
        this.streamHeadersSent = false

        // If format already available, send SPS/PPS immediately
        // This handles late-joining clients after encoder has started
        val format = savedFormat
        if (callback != null && format != null) {
            try {
                val sps = format.getByteBuffer("csd-0")
                val pps = format.getByteBuffer("csd-1")
                if (sps != null && pps != null) {
                    callback.onSpsPps(sps.duplicate(), pps.duplicate())
                    streamHeadersSent = true
                    logger.info("SPS/PPS sent immediately to new callback (late join)")
                }
            } catch (e: Exception) {
                logger.error("Failed to send SPS/PPS to new callback", e)
            }
        }

        logger.info("Stream callback registered")
    }

    /**
     * Checks if the encoder format (SPS/PPS) is available.
     *
     * @return true if format is available, false otherwise
     */
    fun isFormatAvailable(): Boolean = savedFormat != null

    /**
     * One-shot listener invoked the first time the encoder publishes its
     * output format (SPS/PPS available). Set by GpuSurveillancePipeline so
     * deferred recordings can start as soon as the format is ready, without
     * waiting for the camera-probe callback that doesn't fire when probe
     * is disabled (validated camera config path on cold start).
     *
     * `fun interface`, not a plain `interface`: GpuSurveillancePipeline.kt registers it with
     * Kotlin lambda syntax (`enc?.setFormatAvailableListener { ... }`), which needs SAM
     * conversion.
     */
    fun interface FormatAvailableListener {
        fun onFormatAvailable()
    }

    @Volatile private var formatAvailableListener: FormatAvailableListener? = null

    /**
     * Listener fired when [rotateSegment] finalises an old segment
     * before opening a new one. Lets the surveillance engine flush hero
     * thumbnails + JSON sidecar against the segment's actual filename
     * (otherwise long events split across multiple .mp4 files would attach
     * all metadata to the FIRST segment, leaving subsequent segments as
     * unbadged plain MP4s in the recordings list).
     *
     * Fired AFTER the old segment is renamed from .tmp to its final .mp4
     * name. Safe to read the file from inside `onSegmentClosed`.
     * Fires on the encoder drainer thread; consumers should not block.
     */
    fun interface SegmentListener {
        /**
         * @param closedSegment   the .mp4 file just renamed from .tmp,
         *                        or `null` if the rotation produced
         *                        no playable file (broken segment quarantined).
         * @param newSegment      the new .mp4 path (still pre-finalize, pending
         *                        bytes), so the engine knows what filename the
         *                        next stop / next rotation will land on.
         */
        fun onSegmentClosed(closedSegment: File?, newSegment: File)
    }

    @Volatile private var segmentListener: SegmentListener? = null

    fun setSegmentListener(listener: SegmentListener?) {
        this.segmentListener = listener
    }

    fun setFormatAvailableListener(listener: FormatAvailableListener?) {
        this.formatAvailableListener = listener
        // If format is already available when the listener is registered,
        // fire immediately so callers don't miss the edge.
        if (listener != null && savedFormat != null) {
            try {
                listener.onFormatAvailable()
            } catch (e: Exception) {
                logger.warn("FormatAvailableListener error: " + e.message)
            }
            this.formatAvailableListener = null
        }
    }

    /**
     * Waits for the encoder format to become available.
     *
     * @param timeoutMs Maximum time to wait in milliseconds
     * @return true if format became available, false if timeout
     */
    fun waitForFormat(timeoutMs: Long): Boolean {
        val startTime = System.currentTimeMillis()
        while (savedFormat == null) {
            if (System.currentTimeMillis() - startTime > timeoutMs) {
                return false
            }
            try {
                Thread.sleep(50)
            } catch (e: InterruptedException) {
                return false
            }
        }
        return true
    }

    /**
     * Removes the streaming callback.
     */
    fun clearStreamCallback() {
        this.streamCallback = null
        this.streamHeadersSent = false
        logger.info("Stream callback cleared")
    }

    /**
     * Gets the input surface for GPU rendering.
     *
     * @return Surface that GPU should render to
     */
    fun getInputSurface(): Surface? = inputSurface

    /**
     * Triggers event recording with pre-record buffer flush.
     *
     * SOTA: Non-blocking implementation. Pre-record packets are queued
     * and written by drainEncoder() on the GL thread, eliminating the
     * blocking I/O that caused video stutter on motion detection.
     *
     * @param outputPath Path for the output MP4 file
     * @param postRecordDurationMs Post-record duration in milliseconds
     * @return true if started successfully, false otherwise
     */
    fun triggerEventRecording(outputPath: String, postRecordDurationMs: Long): Boolean {
        // Hold startStopLock across the entire start path so two concurrent
        // callers can't both observe isWritingToFile == false and race ahead
        // to build two muxers. The work inside is dominated by a few mkdirs
        // and a MediaMuxer ctor (sub-100ms typically), so blocking another
        // start request for that long is acceptable — the alternative is the
        // duplicate-files-on-disk bug.
        synchronized(startStopLock) {
            if (isWritingToFile) {
                // Already recording, extend post-record duration
                postRecordStopTime = System.currentTimeMillis() + postRecordDurationMs
                logger.info("Event extended - post-record timer reset to " + postRecordDurationMs + "ms")
                return true
            }

            try {
                this.outputPath = outputPath

                // Write to temp file during recording
                val newTempFile = File("$outputPath.tmp")
                tempFile = newTempFile

                // Ensure parent directory exists
                val parentDir = newTempFile.parentFile
                if (parentDir != null && !parentDir.exists()) {
                    var created = parentDir.mkdirs()
                    if (!created && !parentDir.exists()) {
                        // Retry once after short delay (SD card may need time to be accessible)
                        try {
                            Thread.sleep(100)
                        } catch (ignored: InterruptedException) {
                            logger.warn("Sleep interrupted during directory retry")
                        }
                        created = parentDir.mkdirs()
                    }
                    if (created) {
                        logger.info("Created parent directory: " + parentDir.absolutePath)
                        parentDir.setReadable(true, false)
                        parentDir.setWritable(true, false)
                        parentDir.setExecutable(true, false)
                    } else if (!parentDir.exists()) {
                        logger.error("Failed to create parent directory: " + parentDir.absolutePath)
                        return false
                    }
                    // Directory exists (either created or already existed) - continue
                }

                // SOTA: clear any stale per-segment state from the previous
                // recording before the new muxer goes live. Without this, leftover
                // PTS/frame counters from a prior run would mislead the duration
                // computation in closeEventRecording.
                recordedFrames = 0
                firstFramePtsUs = -1
                lastFramePtsUs = -1
                writerAbortedCorrupt = false

                // Create muxer. Hold muxerLock so the disk writer never observes a
                // half-constructed muxer (e.g., started but trackIndex still -1).
                var muxerOk = false
                synchronized(muxerLock) {
                    try {
                        val newMuxer = MediaMuxer(
                            newTempFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
                        )
                        muxer = newMuxer

                        // If we have a saved format, use it immediately
                        val format = savedFormat
                        if (format != null) {
                            trackIndex = newMuxer.addTrack(format)
                            newMuxer.start()
                            muxerStarted = true
                            logger.info("Muxer started with saved format (track=$trackIndex)")
                        }
                        muxerOk = true
                    } catch (e: Exception) {
                        logger.error("MediaMuxer setup failed", e)
                        muxer?.let {
                            try {
                                it.release()
                            } catch (ignored: Exception) {
                                logger.warn("Muxer release failed during setup error cleanup: " + ignored.message)
                            }
                            muxer = null
                        }
                        muxerStarted = false
                        trackIndex = -1
                    }
                }
                if (!muxerOk) {
                    if (newTempFile.exists()) newTempFile.delete()
                    tempFile = null
                    return false
                }

                if (savedFormat != null) {
                    // SOTA: Queue pre-record packets for async flush (NON-BLOCKING!)
                    // drainEncoder() will write these on the GL thread
                    val preRecordPackets = preRecordBuffer!!.getPacketsForFlush()
                    val preRecordDuration = if (preRecordPackets.isEmpty()) 0.0 else
                        (preRecordPackets[preRecordPackets.size - 1].info.presentationTimeUs -
                            preRecordPackets[0].info.presentationTimeUs) / 1_000_000.0

                    // Store actual pre-record duration for timeline alignment
                    actualPreRecordDurationMs = (preRecordDuration * 1000).toLong()

                    // Add all packets to the flush queue (instant, no I/O)
                    pendingFlushQueue.addAll(preRecordPackets)
                    flushInProgress = true

                    logger.info(
                        String.format(
                            "Queued %d pre-record packets (%.1f sec) for async flush",
                            preRecordPackets.size, preRecordDuration
                        )
                    )
                }

                // Reset state
                startTimeNs = System.nanoTime()
                segmentDurationMs = loadSegmentDurationMs()  // Pick up the user's per-file limit
                segmentStartTime = System.currentTimeMillis()  // Enable segment rotation for long events
                segmentNumber = 0
                segmentBasePath = outputPath.replace(Regex("\\.mp4$"), "")  // Store base path for segment rotation
                postRecordStopTime = System.currentTimeMillis() + postRecordDurationMs

                isWritingToFile = true
                recording = true  // Keep for compatibility

                logger.info(
                    String.format(
                        "Event recording started: %s (codec=%s, bitrate=%d Mbps, post-record=%dms)",
                        newTempFile.name,
                        if (codecMimeType == MediaFormat.MIMETYPE_VIDEO_HEVC) "H.265" else "H.264",
                        bitrate / 1_000_000,
                        postRecordDurationMs
                    )
                )
                return true
            } catch (e: Exception) {
                logger.error("Failed to trigger event recording", e)
                // Best-effort cleanup so a partial init doesn't leave a muxer alive
                // referencing a now-orphaned tmp file.
                synchronized(muxerLock) {
                    muxer?.let {
                        try {
                            it.release()
                        } catch (ignored: Exception) {
                            logger.warn("Muxer release failed during event recording error cleanup: " + ignored.message)
                        }
                        muxer = null
                    }
                    muxerStarted = false
                    trackIndex = -1
                }
                tempFile?.let { if (it.exists()) it.delete() }
                tempFile = null
                isWritingToFile = false
                recording = false
                return false
            }
        } // end synchronized (startStopLock)
    }

    /**
     * Legacy method for compatibility - redirects to triggerEventRecording.
     */
    fun startRecording(outputPath: String): Boolean {
        return triggerEventRecording(outputPath, 5000)  // Default 5 sec post-record
    }

    /**
     * Stops recording immediately or schedules post-record stop.
     *
     * Held under `startStopLock` for symmetry with
     * [triggerEventRecording]: a start cannot race a stop. The check
     * outside the lock is a cheap volatile read so callers don't pay the lock
     * cost when there's nothing to stop. The check inside the lock is the
     * authoritative one.
     *
     * @param immediate If true, stops immediately. If false, does nothing (timeout handled by caller)
     * @param postRecordDurationMs Post-record duration (ignored, kept for API compatibility)
     */
    fun stopEventRecording(immediate: Boolean, postRecordDurationMs: Long) {
        if (!isWritingToFile) {
            return
        }
        synchronized(startStopLock) {
            if (!isWritingToFile) {
                // Another thread already finalised between the volatile read
                // above and our acquisition of the lock — nothing to do.
                return
            }
            if (immediate) {
                closeEventRecording()
            }
            // Note: Post-record timeout is now handled by SurveillanceEngineGpu
            // The encoder just writes frames until explicitly told to stop
        }
    }

    /**
     * Closes the current event recording and finalizes the file.
     */
    private fun closeEventRecording() {
        // CRITICAL FIX: Do NOT set isWritingToFile=false yet!
        // The drainer thread checks isWritingToFile to decide whether to write
        // frames to the muxer. Setting it false first causes the drainer to
        // dequeue frames from the encoder but SKIP writing them — losing the
        // last segment's frames on shutdown.
        //
        // Correct order:
        //   1. Stop drainer thread (waits for current drain cycle to finish)
        //   2. Do one final synchronous drain WITH isWritingToFile still true
        //   3. THEN set isWritingToFile=false and close the muxer

        recording = false

        // Step 1: Stop drainer thread BEFORE touching the muxer.
        // The drainer may be in the middle of muxer.writeSampleData() —
        // calling muxer.stop() concurrently corrupts the MP4 (broken moov atom).
        stopDrainerThread()

        // Step 2: Final synchronous drain — flush any frames still queued in
        // the encoder's output buffer. isWritingToFile is still true so these
        // frames WILL be written to the muxer.
        // FIX: Drain in a loop until the encoder is truly empty. A single call
        // to drainEncoderInternal() may not get all frames if the encoder is still
        // processing the last few input buffers. Loop with a short sleep to give
        // the hardware encoder time to finish encoding in-flight frames.
        try {
            for (drainPass in 0 until 5) {
                val framesBefore = recordedFrames
                drainEncoderInternal()
                val framesWritten = recordedFrames - framesBefore
                if (framesWritten == 0 && drainPass > 0) {
                    break  // Encoder is empty
                }
                if (framesWritten > 0 && drainPass < 4) {
                    // More frames were available — give encoder a moment to finish any in-flight
                    try {
                        Thread.sleep(20)
                    } catch (ignored: InterruptedException) {
                        logger.warn("Sleep interrupted during final frame drain")
                    }
                }
            }
        } catch (e: Exception) {
            logger.warn("Final drain before close failed: " + e.message)
        }

        // Step 3 + 4: under muxerLock, flush remaining queued packets into the
        // still-live muxer, then stop+release. Tracking stopOk lets us refuse
        // to rename a file whose moov was never written — that file would be
        // sized, named .mp4, and unplayable.
        var stopOk = false
        synchronized(muxerLock) {
            var packet: MuxerPacket?
            var flushed = 0
            while (muxerWriteQueue.poll().also { packet = it } != null) {
                val p = packet!!
                if (muxerStarted && muxer != null) {
                    try {
                        muxer!!.writeSampleData(trackIndex, p.data, p.info)
                        if (firstFramePtsUs < 0) firstFramePtsUs = p.info.presentationTimeUs
                        lastFramePtsUs = p.info.presentationTimeUs
                        recordedFrames++
                        flushed++
                    } catch (e: Exception) {
                        logger.warn("Final flush write error: " + e.message)
                        writerAbortedCorrupt = true
                        break
                    }
                }
            }
            if (flushed > 0) {
                logger.info("Final muxer queue flush: $flushed frames written")
            }

            // No more writers can race us now — flag the writer state OFF before
            // touching muxer.stop(). isWritingToFile is also cleared under the
            // lock so the upcoming format-change handler can't reopen the muxer.
            isWritingToFile = false

            // Stop muxer (may throw if no frames were written, or if the
            // underlying file descriptor was severed by an SD-card unmount).
            try {
                if (muxerStarted && muxer != null) {
                    muxer!!.stop()
                    stopOk = true
                }
            } catch (e: Exception) {
                logger.warn("Muxer stop error (may have had no frames): " + e.message)
            } finally {
                muxerStarted = false
            }

            try {
                muxer?.release()
            } catch (e: Exception) {
                logger.warn("Muxer release error: " + e.message)
            } finally {
                muxer = null
                trackIndex = -1
            }
        }

        // Rename temp to final, quarantine if broken, or delete if empty.
        // SOTA: never promote a tempFile to a final .mp4 unless the muxer
        // actually finalized — that's the single rule that prevents the
        // "60 MB file that won't play" symptom.
        val recordingBroken = !stopOk || writerAbortedCorrupt
        val temp = tempFile
        if (temp != null && temp.exists()) {
            if (!recordingBroken && recordedFrames > 0 && temp.length() > 1024) {
                val finalFile = File(outputPath!!)
                if (temp.renameTo(finalFile)) {
                    // Use actual PTS range for accurate duration (not recordedFrames/fps
                    // which is misleading when pre-record frames are included)
                    val durationSec = if (firstFramePtsUs >= 0 && lastFramePtsUs > firstFramePtsUs)
                        (lastFramePtsUs - firstFramePtsUs) / 1_000_000.0f
                    else
                        recordedFrames / fps.toFloat()
                    logger.info(
                        String.format(
                            "Event saved: %s (segment %d, %d frames, %.1f sec, %d KB, codec=%s, bitrate=%d Mbps)",
                            finalFile.name, segmentNumber, recordedFrames, durationSec, finalFile.length() / 1024,
                            if (codecMimeType == MediaFormat.MIMETYPE_VIDEO_HEVC) "H.265" else "H.264",
                            bitrate / 1_000_000
                        )
                    )

                    // Make file visible to events page and UI app
                    try {
                        StorageManager.getInstance().onFileSaved(finalFile)
                    } catch (e: Exception) {
                        logger.warn("onFileSaved error: " + e.message)
                    }
                } else {
                    logger.error("Failed to rename temp file — deleting orphan")
                    temp.delete()
                }
            } else if (recordingBroken) {
                // Quarantine: keep evidence under a sidecar extension so the
                // recordings UI's *.mp4 listing doesn't pick it up. An
                // operator can still find it on disk for diagnostics.
                val broken = File(outputPath + ".broken")
                if (!temp.renameTo(broken)) {
                    logger.warn("Quarantine rename failed; deleting broken tmp: " + temp.name)
                    temp.delete()
                } else {
                    logger.warn(
                        "Quarantined broken recording (stopOk=" + stopOk +
                            ", writerAborted=" + writerAbortedCorrupt +
                            ", " + (broken.length() / 1024) + " KB): " + broken.name
                    )
                }
            } else {
                // Empty / sub-1KB recording — drop it silently.
                logger.warn(
                    "Deleting empty/corrupt temp file: " + temp.name +
                        " (frames=" + recordedFrames + ", size=" + temp.length() + ")"
                )
                temp.delete()
            }
        }

        // Reset state
        recordedFrames = 0
        firstFramePtsUs = -1
        lastFramePtsUs = -1
        postRecordStopTime = 0
        segmentStartTime = 0
        segmentNumber = 0
        segmentBasePath = null

        // Restart drainer thread — encoder is still alive, just not writing to file.
        // Pre-record buffer and streaming still need draining.
        startDrainerThread()

        fileClosedCallback?.run()
    }

    /**
     * Legacy method for compatibility.
     */
    fun stopRecording() {
        stopEventRecording(true, 0)
    }

    /**
     * Sets callback for when file is closed.
     *
     * @param callback Callback to run when file closes
     */
    fun setFileClosedCallback(callback: Runnable?) {
        this.fileClosedCallback = callback
    }

    /**
     * Requests a sync frame (I-frame) immediately.
     *
     * Used when an event is detected to ensure clean playback start.
     */
    fun requestSyncFrame() {
        encoder?.let { enc ->
            try {
                val params = Bundle()
                params.putInt(MediaCodec.PARAMETER_KEY_REQUEST_SYNC_FRAME, 0)
                enc.setParameters(params)
                logger.debug("Sync frame requested")
            } catch (e: Exception) {
                logger.error("Failed to request sync frame", e)
            }
        }
    }

    /**
     * Changes the encoder bitrate dynamically.
     *
     * @param newBitrate New bitrate in bps
     */
    fun setBitrate(newBitrate: Int) {
        val enc = encoder
        if (enc != null && newBitrate != bitrate) {
            try {
                val params = Bundle()
                params.putInt(MediaCodec.PARAMETER_KEY_VIDEO_BITRATE, newBitrate)
                enc.setParameters(params)

                this.bitrate = newBitrate
                logger.info("Bitrate changed to: " + (newBitrate / 1_000_000) + " Mbps")
            } catch (e: Exception) {
                logger.error("Failed to change bitrate", e)
            }
        }
    }

    /**
     * Checks if currently recording.
     *
     * @return true if recording, false otherwise
     */
    fun isRecording(): Boolean = recording

    /**
     * The base filename (no directory, no `.tmp` suffix) currently being written, or
     * `null` if nothing is recording. Used by `MarkRecording` (BladeWatch-nmao.4)
     * to resolve "the current clip" without the caller (a Live View button) ever knowing a
     * filename itself.
     *
     * A real property (not `fun getCurrentRecordingFilename()`): RecordingsApiHandler.kt reads
     * it as `encoder?.currentRecordingFilename`, Kotlin property-access syntax.
     */
    val currentRecordingFilename: String?
        get() {
            val tmp = tempFile
            if (tmp == null || !tmp.exists()) return null
            val name = tmp.name
            return if (name.endsWith(".tmp")) name.substring(0, name.length - 4) else name
        }

    /**
     * Checks if currently writing to file.
     *
     * @return true if actively writing to file, false otherwise
     */
    fun isWritingToFile(): Boolean = isWritingToFile

    /**
     * Gets the number of recorded frames.
     *
     * @return Frame count
     */
    fun getRecordedFrames(): Int = recordedFrames

    /**
     * Get the actual duration of the pre-record buffer that was flushed.
     * This may be longer than the configured preRecordMs because the H.264
     * circular buffer starts from the nearest keyframe.
     */
    fun getActualPreRecordDurationMs(): Long = actualPreRecordDurationMs

    /**
     * Gets the current bitrate.
     *
     * @return Bitrate in bps
     */
    fun getBitrate(): Int = bitrate

    /**
     * Releases all resources.
     */
    fun release() {
        // SOTA: Stop drainer thread first
        stopDrainerThread()

        if (recording) {
            stopRecording()
        }

        encoder?.let { enc ->
            // Note: by the time we reach release(), stopRecording() above
            // has already finalized any active recording (drained and stopped
            // the muxer). Final-frame-loss is handled there. We just stop
            // and release the codec.
            try {
                enc.stop()
            } catch (e: Exception) {
                logger.error("Error stopping encoder", e)
            }

            try {
                enc.release()
            } catch (e: Exception) {
                logger.error("Error releasing encoder", e)
            }

            encoder = null
        }

        inputSurface?.let {
            it.release()
            inputSurface = null
        }

        // Clear the shared pre-record buffer if THIS instance owned it. The
        // buffer is static + shared across encoder reinits to avoid 23MB
        // realloc, but stale packets from a previous codec/resolution must
        // not survive into the next event recording. Without this, a crash
        // path that skips stopRecording() leaves packets in the buffer that
        // the next instance will flush into its first event MP4.
        preRecordBuffer?.let { buf ->
            synchronized(bufferLock) {
                if (buf === sharedPreRecordBuffer) {
                    sharedPreRecordBuffer?.clear()
                }
            }
            preRecordBuffer = null
        }

        logger.info("Released")
    }

    // ==================== SOTA: Background Drainer Thread ====================

    /**
     * Starts the background drainer thread.
     * This moves SD card I/O off the GL thread to prevent freezes.
     */
    private fun startDrainerThread() {
        if (drainerRunning) {
            logger.warn("Drainer thread already running")
            return
        }

        drainerRunning = true
        val thread = Thread({
            logger.info("Encoder drainer thread started")
            while (drainerRunning) {
                try {
                    // Drain the encoder (SD card I/O happens here, not on GL thread)
                    drainEncoderInternal()

                    // Don't burn CPU - wait a tiny bit for new frames
                    Thread.sleep(DRAIN_INTERVAL_MS)
                } catch (e: InterruptedException) {
                    break
                } catch (e: Exception) {
                    logger.error("Drainer error: " + e.message)
                }
            }
            logger.info("Encoder drainer thread stopped")
        }, "GpuEncoderDrainer")
        drainerThread = thread

        thread.priority = Thread.NORM_PRIORITY
        thread.start()

        // Start disk writer thread (handles muxer I/O separately from encoder dequeue)
        startDiskWriterThread()
    }

    /**
     * Stops the background drainer thread.
     */
    private fun stopDrainerThread() {
        drainerRunning = false
        drainerThread?.let { thread ->
            try {
                thread.interrupt()
                // SOTA: 2 s join matches the disk writer's join. The drainer can
                // be inside a single drainEncoderInternal() pass that takes
                // 100+ ms under SD-card pressure; the old 500 ms ceiling let
                // the close path move on while the drainer was still pushing
                // packets to the queue, racing the muxer.stop() call.
                thread.join(2000)
            } catch (e: InterruptedException) {
                logger.warn("Interrupted while waiting for drainer thread to stop")
            }
            drainerThread = null
        }

        // Stop disk writer after drainer (drainer may still be pushing to the queue)
        stopDiskWriterThread()
    }

    /**
     * FORTIFY FIX: Stops the drainer thread before camera close.
     *
     * The drainer thread calls MediaCodec.dequeueOutputBuffer() which internally
     * accesses the camera's SurfaceTexture buffer queue. If the camera is closed
     * (destroying the native mutex) while the drainer is mid-dequeue, we get:
     *   FORTIFY: pthread_mutex_lock called on a destroyed mutex
     *
     * This method stops the drainer and waits for it to fully exit before returning,
     * making it safe to close the camera afterwards.
     *
     * Call restartDrainerAfterCameraClose() after the camera is reopened.
     */
    fun stopDrainerForCameraClose() {
        logger.info("Stopping drainer for camera close...")
        drainerRunning = false
        drainerThread?.let { thread ->
            try {
                thread.interrupt()
                thread.join(1000)  // Wait up to 1 second for clean exit
                if (thread.isAlive) {
                    logger.warn("Drainer thread still alive after 1s — proceeding anyway")
                }
            } catch (e: InterruptedException) {
                logger.warn("Interrupted while waiting for drainer thread during camera close")
            }
            drainerThread = null
        }
        logger.info("Drainer stopped for camera close")
    }

    /**
     * Restarts the drainer thread after camera has been reopened.
     * Call this after startCamera() succeeds.
     */
    fun restartDrainerAfterCameraClose() {
        if (!drainerRunning) {
            startDrainerThread()
            logger.info("Drainer restarted after camera reopen")
        }
    }

    // ==================== SOTA: Disk Writer Thread ====================

    /**
     * Starts the disk writer thread that polls the muxer write queue
     * and writes to the SD card. This decouples SD card I/O from the
     * encoder dequeue loop, preventing I/O stalls from dropping frames.
     */
    private fun startDiskWriterThread() {
        if (diskWriterRunning) return

        diskWriterRunning = true
        // Each disk writer instance starts with a clean abort flag. The flag is
        // only set when this writer hits the unrecoverable failure threshold; the
        // close/rotate paths read it to decide whether to keep or quarantine the
        // current tempFile.
        writerAbortedCorrupt = false
        // SD-unmount detection: if writes start failing repeatedly, the underlying
        // file descriptor is dead (typical when BYD/Android unmounts the SD card
        // mid-recording). The MP4's moov atom is written only on stopRecording, so
        // continuing to drain into a broken FD produces an unrecoverable corrupt
        // file. Track consecutive write failures and abort the recording cleanly
        // once we cross a threshold — at least the MP4 prefix on disk has the
        // partial frames already written, and the user gets a clear log instead
        // of a silent corruption.
        var consecutiveWriteFailures = 0
        val writeFailureAbortThreshold = 5
        val thread = Thread({
            logger.info("Disk writer thread started")
            while (diskWriterRunning || !muxerWriteQueue.isEmpty()) {
                try {
                    val packet = muxerWriteQueue.poll()
                    if (packet != null) {
                        // SOTA: serialize against rotateSegment / closeEventRecording.
                        // Without this lock, a concurrent muxer.stop() corrupts the
                        // moov atom and produces a sized-but-unplayable .mp4.
                        synchronized(muxerLock) {
                            if (muxerStarted && muxer != null) {
                                muxer!!.writeSampleData(trackIndex, packet.data, packet.info)
                                if (firstFramePtsUs < 0) firstFramePtsUs = packet.info.presentationTimeUs
                                lastFramePtsUs = packet.info.presentationTimeUs
                                recordedFrames++
                                consecutiveWriteFailures = 0
                            }
                        }
                    } else {
                        // Queue empty — sleep briefly to avoid busy-waiting
                        Thread.sleep(4)
                    }
                } catch (e: InterruptedException) {
                    // Drain remaining packets before exiting. We deliberately do
                    // NOT write here: by the time the writer is interrupted, the
                    // close/rotate path is about to (or has already) called
                    // muxer.stop(), so any further writeSampleData would corrupt
                    // the moov. The close path drains the queue itself under the
                    // lock before stopping the muxer.
                    break
                } catch (e: Exception) {
                    consecutiveWriteFailures++
                    logger.error("Disk writer error (#$consecutiveWriteFailures): " + e.message)
                    if (consecutiveWriteFailures >= writeFailureAbortThreshold) {
                        logger.error(
                            "Aborting recording: " + writeFailureAbortThreshold +
                                " consecutive write failures (likely SD card unmounted). " +
                                "Partial file at " + (tempFile?.absolutePath ?: "unknown") +
                                " will not be playable."
                        )
                        // Mark the current segment corrupt so the close/rotate
                        // path quarantines it rather than promoting tempFile to
                        // outputPath. The user must never see a final .mp4
                        // filename for a file whose moov was never written.
                        writerAbortedCorrupt = true
                        // Clear queue so the writer loop exits promptly
                        muxerWriteQueue.clear()
                        diskWriterRunning = false
                        // Don't call stopRecording() from here — that's a heavyweight
                        // operation that touches state owned by other threads. Just
                        // exit the writer; the main pipeline's existing watchdog or
                        // the next user action will trigger cleanup.
                        break
                    }
                }
            }
            logger.info("Disk writer thread stopped")
        }, "GpuDiskWriter")
        diskWriterThread = thread

        // Lower priority than drainer — SD card I/O should never preempt encoder dequeue
        thread.priority = Thread.MIN_PRIORITY + 1
        thread.start()
    }

    /**
     * Stops the disk writer thread, flushing any remaining packets.
     */
    private fun stopDiskWriterThread() {
        diskWriterRunning = false
        diskWriterThread?.let { thread ->
            try {
                thread.interrupt()
                thread.join(2000)  // Allow up to 2s for final flush
            } catch (e: InterruptedException) {
                logger.warn("Interrupted while waiting for disk writer thread to stop")
            }
            diskWriterThread = null
        }
    }

    /**
     * Public drainEncoder() - now just a no-op since draining happens on background thread.
     * Kept for API compatibility with existing code that calls it.
     */
    fun drainEncoder() {
        // SOTA: Draining now happens on background thread, not GL thread
        // This method is kept for API compatibility but does nothing
    }

    /**
     * Internal drain method called by background thread.
     * Handles all encoder output and SD card I/O.
     */
    private fun drainEncoderInternal() {
        val enc = encoder ?: return

        // SOTA: Process queued pre-record packets first (flush all at once).
        // These packets are written to the SD card via the muxer, which does NOT
        // block the encoder's input surface. The original chunking was added to prevent
        // MediaCodec backpressure, but that was only an issue when flushing on the GL
        // thread. Now that draining happens on a background thread, writing all packets
        // in one pass is safe and ensures no PTS gap between pre-record and live frames.
        //
        // CRITICAL: Live frames must NOT be written until this flush completes.
        // The pre-record packets have older PTS values. If live frames (with current PTS)
        // are interleaved, the muxer sees non-monotonic timestamps and the MP4 is corrupt.
        if (flushInProgress && muxerStarted) {
            var flushedCount = 0
            var queuedPacket: H264CircularBuffer.Packet?
            while (pendingFlushQueue.poll().also { queuedPacket = it } != null) {
                // Push pre-record packets to the muxer write queue (same path as live frames)
                offerMuxerPacket(MuxerPacket(queuedPacket!!.data, queuedPacket!!.info))
                flushedCount++
            }
            if (flushedCount > 0) {
                logger.info("Async flush complete: $flushedCount pre-record frames queued for disk write")
            }
            flushInProgress = false
        }

        // Check if segment rotation needed (only when actively writing to file).
        // SOTA: rotation requires a live disk writer + drainer; if either is
        // shutting down (e.g., we're inside the synchronous final drain in
        // closeEventRecording) the rotation logic would deadlock or produce a
        // stranded muxer. Skip in that case.
        if (isWritingToFile && segmentStartTime > 0 && drainerRunning && diskWriterRunning) {
            val elapsed = System.currentTimeMillis() - segmentStartTime
            if (elapsed >= segmentDurationMs) {
                logger.info("Segment duration reached (" + (elapsed / 1000) + "s), rotating to new file...")
                rotateSegment()
            }
        }

        val bufferInfo = reusableBufferInfo

        while (true) {
            val outputBufferIndex: Int
            try {
                outputBufferIndex = enc.dequeueOutputBuffer(bufferInfo, 0)
            } catch (e: Exception) {
                // Encoder may have been released
                break
            }

            if (outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                break  // No more output available
            } else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                // Format changed - add track to muxer and send SPS/PPS to stream
                val format = enc.outputFormat

                // Save format for reuse in subsequent recordings
                if (savedFormat == null) {
                    savedFormat = format
                    val mime = format.getString(MediaFormat.KEY_MIME)
                    logger.info(
                        "Saved encoder format for reuse (codec=" +
                            (if (mime != null && mime.contains("hevc")) "H.265" else "H.264") + ")"
                    )

                    // Notify any waiter (one-shot). This is the canonical
                    // moment isFormatAvailable() flips false→true.
                    val l = formatAvailableListener
                    if (l != null) {
                        formatAvailableListener = null
                        try {
                            l.onFormatAvailable()
                        } catch (e: Exception) {
                            logger.warn("FormatAvailableListener error: " + e.message)
                        }
                    }
                }

                if (recording && !muxerStarted) {
                    synchronized(muxerLock) {
                        val m = muxer
                        if (m != null && !muxerStarted) {
                            trackIndex = m.addTrack(format)
                            m.start()
                            muxerStarted = true
                            logger.info("Muxer started (track=$trackIndex)")
                        }
                    }
                }

                // Send SPS/PPS to streaming callback
                val cb = streamCallback
                if (cb != null && !streamHeadersSent) {
                    try {
                        val sps = format.getByteBuffer("csd-0")
                        val pps = format.getByteBuffer("csd-1")
                        if (sps != null && pps != null) {
                            cb.onSpsPps(sps.duplicate(), pps.duplicate())
                            streamHeadersSent = true
                            logger.info("SPS/PPS sent to stream")
                        }
                    } catch (e: Exception) {
                        logger.error("Failed to send SPS/PPS", e)
                    }
                }
            } else if (outputBufferIndex >= 0) {
                // Got encoded data
                val outputBuffer = enc.getOutputBuffer(outputBufferIndex)

                if (outputBuffer != null && bufferInfo.size > 0) {
                    // ALWAYS add to circular buffer (for pre-record) - unless stream-only mode
                    if (usePreRecordBuffer && preRecordBuffer != null) {
                        preRecordBuffer!!.add(outputBuffer, bufferInfo)
                    }

                    // PATH A: Write to disk (if event recording active)
                    // SOTA: Don't write to muxer directly — push to the muxer write queue.
                    // The disk writer thread handles the actual SD card I/O, preventing
                    // I/O stalls from blocking the encoder dequeue loop.
                    if (isWritingToFile && muxerStarted && !flushInProgress) {
                        offerMuxerPacket(MuxerPacket(outputBuffer, bufferInfo))
                    }

                    // PATH B: Send to network (if streaming)
                    val cb = streamCallback
                    if (cb != null && streamHeadersSent) {
                        try {
                            // Duplicate buffer to avoid interfering with muxer
                            val streamBuffer = outputBuffer.duplicate()
                            streamBuffer.position(bufferInfo.offset)
                            streamBuffer.limit(bufferInfo.offset + bufferInfo.size)
                            cb.onH264Packet(streamBuffer, bufferInfo)
                        } catch (e: Exception) {
                            logger.error("Stream callback error", e)
                        }
                    }
                }

                // Release output buffer
                enc.releaseOutputBuffer(outputBufferIndex, false)
            }
        }
    }

    /**
     * Reads the user-configured per-file recording limit (minutes) from the
     * unified config (recording.segmentMinutes; options 1/5/10), applies the
     * recording.priority cap (BladeWatch-gyg1.3 -- RELIABILITY shortens this to 1
     * minute regardless of segmentMinutes, so an abrupt power loss loses at most
     * one unfinalised segment instead of up to segmentMinutes), and converts the
     * result to milliseconds. Falls back to the default (5 min) on any error or
     * an unexpected value, so a bad config can never disable rotation entirely.
     */
    private fun loadSegmentDurationMs(): Long {
        try {
            val rec = UnifiedConfigManager.getRecording()
            val mins = rec.optInt("segmentMinutes", 5)
            if (mins == 1 || mins == 5 || mins == 10) {
                // The key is always present by the time this reads: UnifiedConfigManager's
                // applyDefaults sets it for new configs and migrateConfig back-fills
                // PERFORMANCE for any config predating it, both persisted. A missing value
                // here therefore means a hand-edited config, where RELIABILITY (the cap) is
                // the right thing to fall back to.
                val priority = RecordingPriority.fromConfigValue(rec.optString("priority", null))
                return priority.effectiveSegmentMinutes(mins) * 60_000L
            }
        } catch (e: Exception) {
            logger.warn("Could not read recording.segmentMinutes, using default: " + e.message)
        }
        return DEFAULT_SEGMENT_DURATION_MS
    }

    /**
     * Rotates to a new segment file.
     *
     * Closes current file and starts new segment WITHOUT flushing pre-record buffer
     * (since we're continuing the same event, not starting a new one).
     */
    private fun rotateSegment() {
        if (!isWritingToFile) {
            return
        }

        logger.info("Rotating segment $segmentNumber - closing current file")

        // SOTA: Capture the old segment's identity locally. Field-level state
        // (tempFile / outputPath / recordedFrames / firstFramePtsUs / lastFramePtsUs)
        // belongs to the *new* segment by the end of this method; we must not
        // let the new segment's stats mask whether the old one was finalized
        // cleanly.
        val oldTemp = tempFile
        val oldOutputPath = outputPath
        val oldRecordedFrames = recordedFrames
        val oldFirstPtsUs = firstFramePtsUs
        val oldLastPtsUs = lastFramePtsUs
        val oldSegmentNumber = segmentNumber

        // Step 1: stop the disk writer BEFORE touching the muxer.
        // Without this, the writer may be inside muxer.writeSampleData() when
        // we call muxer.stop(), corrupting the moov atom and leaving an
        // unplayable but final-named .mp4 on disk. stopDiskWriterThread() also
        // joins the thread, so by the time it returns no other thread is
        // racing us.
        stopDiskWriterThread()

        var stopOk = false
        synchronized(muxerLock) {
            // Step 2: drain any packets that the writer left in the queue
            // straight into the still-live old muxer. Anything we drop here
            // turns into a gap in the segment.
            var pkt: MuxerPacket?
            var drained = 0
            while (muxerWriteQueue.poll().also { pkt = it } != null) {
                val p = pkt!!
                if (muxerStarted && muxer != null) {
                    try {
                        muxer!!.writeSampleData(trackIndex, p.data, p.info)
                        if (firstFramePtsUs < 0) firstFramePtsUs = p.info.presentationTimeUs
                        lastFramePtsUs = p.info.presentationTimeUs
                        recordedFrames++
                        drained++
                    } catch (e: Exception) {
                        logger.warn("Rotation flush error: " + e.message)
                        writerAbortedCorrupt = true
                        break
                    }
                }
            }
            if (drained > 0) {
                logger.debug("Rotation drained $drained queued frames into old segment")
            }

            // Step 3: stop the old muxer. Track success so we can quarantine
            // the file if anything goes wrong — a swallowed exception here
            // used to ship a sized-but-unplayable .mp4 to the user.
            try {
                if (muxerStarted && muxer != null) {
                    muxer!!.stop()
                    stopOk = true
                }
            } catch (e: Exception) {
                logger.warn("Muxer stop error during rotation: " + e.message)
            } finally {
                muxerStarted = false
            }

            try {
                muxer?.release()
            } catch (e: Exception) {
                logger.warn("Muxer release error during rotation: " + e.message)
            } finally {
                muxer = null
                trackIndex = -1
            }
        }

        // Step 4: finalize the old tempFile on disk — but ONLY rename to the
        // final extension if the muxer actually finalized cleanly. Otherwise
        // the file has no moov atom and would be a sized, named, unplayable
        // .mp4 — exactly the bug we're fixing. Quarantine instead.
        val segmentBroken = !stopOk || writerAbortedCorrupt
        // Tracks the .mp4 produced by THIS rotation (or null if none usable).
        // Used to notify the SegmentListener after the new segment is open
        // so the engine can flush hero/sidecar against the right filename.
        var finalisedSegment: File? = null
        if (oldTemp != null && oldTemp.exists()) {
            if (!segmentBroken && oldRecordedFrames > 0 && oldTemp.length() > 1024) {
                val finalFile = File(oldOutputPath!!)
                if (oldTemp.renameTo(finalFile)) {
                    finalisedSegment = finalFile
                    val durationSec = if (oldFirstPtsUs >= 0 && oldLastPtsUs > oldFirstPtsUs)
                        (oldLastPtsUs - oldFirstPtsUs) / 1_000_000.0f
                    else
                        oldRecordedFrames / fps.toFloat()
                    logger.info(
                        String.format(
                            "Segment %d saved: %s (%d frames, %.1f sec, %d KB)",
                            oldSegmentNumber, finalFile.name, oldRecordedFrames,
                            durationSec, finalFile.length() / 1024
                        )
                    )
                    try {
                        StorageManager.getInstance().onFileSaved(finalFile)
                    } catch (e: Exception) {
                        logger.warn("onFileSaved error: " + e.message)
                    }
                } else {
                    logger.error("Failed to rename segment $oldSegmentNumber — deleting orphan")
                    oldTemp.delete()
                }
            } else if (segmentBroken) {
                // Quarantine the broken segment under a .broken.mp4 sidecar so
                // an operator can tell *something* went wrong without it
                // showing up in the recordings UI as a real .mp4.
                val broken = File(oldOutputPath + ".broken")
                if (!oldTemp.renameTo(broken)) {
                    logger.warn("Quarantine rename failed; deleting broken tmp: " + oldTemp.name)
                    oldTemp.delete()
                } else {
                    logger.warn(
                        "Quarantined broken segment " + oldSegmentNumber +
                            " (stopOk=" + stopOk + ", writerAborted=" + writerAbortedCorrupt +
                            ", " + (broken.length() / 1024) + " KB): " + broken.name
                    )
                }
            } else {
                logger.warn("Deleting empty segment $oldSegmentNumber tmp file")
                oldTemp.delete()
            }
        }

        // SOTA: if the SD card just died we should not optimistically open a new
        // muxer and pretend recording continues — every subsequent write would
        // fail and pile up another quarantined segment. Stop here; the next
        // user-driven start will trigger a fresh recorder init.
        if (writerAbortedCorrupt) {
            logger.warn("Writer aborted — abandoning rotation, recording stopped")
            isWritingToFile = false
            recording = false
            recordedFrames = 0
            firstFramePtsUs = -1
            lastFramePtsUs = -1
            segmentStartTime = 0
            segmentNumber = 0
            segmentBasePath = null
            return
        }

        // Step 5: open the next segment. Each rotated segment gets a fresh
        // yyyyMMdd_HHmmss timestamp (no _1, _2 suffixes) so it matches the
        // naming convention used at recording start.
        segmentNumber++
        val newPath = nextSegmentPath(segmentBasePath!!)

        try {
            this.outputPath = newPath
            val newTemp = File("$newPath.tmp")
            tempFile = newTemp
            // Reset per-segment counters BEFORE the new muxer goes live so the
            // disk writer (restarted below) records frames against the new
            // file, not the old segment's totals.
            recordedFrames = 0
            firstFramePtsUs = -1
            lastFramePtsUs = -1
            segmentStartTime = System.currentTimeMillis()

            synchronized(muxerLock) {
                val newMuxer = MediaMuxer(newTemp.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
                muxer = newMuxer

                val format = savedFormat
                if (format != null) {
                    trackIndex = newMuxer.addTrack(format)
                    newMuxer.start()
                    muxerStarted = true
                }
            }

            // Request a keyframe immediately so the new segment is independently
            // decodable from its first sample. Without this, the segment would
            // start with P-frames referencing a previous I-frame that lives in
            // the old (now closed) file, and players would render garbage until
            // the next 2-second I-frame interval.
            requestSyncFrame()

            logger.info("Segment $segmentNumber started: " + newTemp.name)

            // Notify the engine: old segment is finalised, new segment is open.
            // Engine flushes hero JPEG + per-actor thumbs + JSON sidecar against
            // closedSegment, then resets ThumbnailBuffer/EventTimelineCollector
            // so the next 2 minutes of metadata accumulates against newSegment.
            // Failing here would orphan the metadata, so swallow exceptions —
            // the new segment is already open and writing.
            val listener = segmentListener
            if (listener != null) {
                try {
                    listener.onSegmentClosed(finalisedSegment, File(newPath))
                } catch (t: Throwable) {
                    logger.warn("SegmentListener error: " + t.message)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to start new segment — stopping recording", e)
            // Clean up the failed tmp file
            tempFile?.let { if (it.exists()) it.delete() }
            synchronized(muxerLock) {
                muxer?.let {
                    try {
                        it.release()
                    } catch (ignored: Exception) {
                        logger.warn("Muxer release failed during segment rotation error cleanup: " + ignored.message)
                    }
                    muxer = null
                }
                muxerStarted = false
                trackIndex = -1
            }
            isWritingToFile = false
            recording = false
            return
        }

        // Step 6: bring the disk writer back online. It will pick up frames
        // from the (now drained, then refilled by the drainer) queue and write
        // them to the new muxer.
        startDiskWriterThread()
    }

    /**
     * Flushes and closes muxer immediately.
     *
     * Used when ACC state changes during recording to ensure
     * file is properly closed before shutdown.
     */
    fun flushAndClose() {
        if (recording) {
            logger.info("Flushing and closing muxer (ACC state change)")
            stopRecording()
        }
    }

    /**
     * Gets the path of the file currently being written to.
     * Used by cleanup to avoid deleting active files.
     */
    fun getCurrentOutputPath(): String? = outputPath

    /**
     * Build the path for the next rotated segment.
     *
     * Input is the base path of the original recording (no extension), e.g.
     * `/sdcard/.../cam_20260513_140523`. The original filename is
     * `<prefix>_yyyyMMdd_HHmmss`; we drop the trailing timestamp and
     * append a fresh one so each segment is a self-describing
     * `<prefix>_yyyyMMdd_HHmmss.mp4`, never `_1`, `_2`, etc.
     *
     * If the basename can't be parsed (unexpected format), falls back to
     * the legacy `<base>_<n>.mp4` naming so a single bad recording
     * doesn't lose its rotation.
     */
    private fun nextSegmentPath(basePath: String): String {
        val fresh = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        try {
            val slash = basePath.lastIndexOf('/')
            val dir = if (slash >= 0) basePath.substring(0, slash + 1) else ""
            val name = if (slash >= 0) basePath.substring(slash + 1) else basePath
            // Strip the original _yyyyMMdd_HHmmss suffix (last two underscore
            // segments — date and time). Anything else is the prefix.
            val lastUnderscore = name.lastIndexOf('_')
            if (lastUnderscore > 0) {
                val prevUnderscore = name.lastIndexOf('_', lastUnderscore - 1)
                if (prevUnderscore > 0) {
                    val prefix = name.substring(0, prevUnderscore)
                    var candidate = dir + prefix + "_" + fresh + ".mp4"
                    // Same-second rotation (or pre-existing file) — disambiguate
                    // with a short suffix rather than overwriting.
                    if (File(candidate).exists() || candidate == outputPath) {
                        // Underscore (not dash) so the UI regexes in
                        // RecordingsApiHandler — CAM_PATTERN / EVENT_PATTERN /
                        // PROXIMITY_PATTERN, all `(?:_\d+)?` — accept the
                        // disambiguated filename. A dash made the segment
                        // invisible to the web UI, calendar, and storage stats.
                        candidate = dir + prefix + "_" + fresh + "_" + segmentNumber + ".mp4"
                    }
                    return candidate
                }
            }
        } catch (ignored: Exception) {
            logger.warn("nextSegmentPath name parsing failed — falling back to numeric suffix: " + ignored.message)
        }
        return basePath + "_" + segmentNumber + ".mp4"
    }

    companion object {
        private const val TAG = "HWEncoderGpu"
        private val logger = DaemonLogger.getInstance(TAG)

        // SOTA: Static buffer shared across encoder instances to avoid 23MB reallocation on reinit
        @Volatile private var sharedPreRecordBuffer: H264CircularBuffer? = null
        private val bufferLock = Any()

        // SOTA: Muxer write queue — decouples encoder dequeue from SD card I/O.
        // The encoder dequeue loop copies frame data and releases the encoder buffer
        // immediately, then pushes to this queue. A dedicated disk writer thread
        // polls the queue and writes to the muxer. This prevents SD card I/O stalls
        // (which can be 50-100ms during garbage collection) from blocking the encoder,
        // which would cause the GPU to stall and drop camera frames.
        //
        // Capacity reasoning: at worst-case 30 fps × ~256KB per packet, 300 entries
        // = ~75 MB ceiling. SD stalls beyond ~10 seconds at 30 fps drop oldest
        // non-keyframes (drop-policy in offerMuxerPacket). Daemon stays alive
        // instead of OOMing.
        private const val MUXER_WRITE_QUEUE_CAPACITY = 300

        private const val DRAIN_INTERVAL_MS = 16L  // ~60Hz cadence, matches frame arrival rate

        // Per-file recording limit default. See loadSegmentDurationMs's doc comment.
        private const val DEFAULT_SEGMENT_DURATION_MS = 5 * 60 * 1000L

        /**
         * How long a file must sit untouched before either orphan sweeper will reap it.
         * Shared so [cleanupOrphanedTmpFiles] and [cleanupOrphanedSidecars] cannot drift:
         * both are guarding the same window, the gap between a sidecar being written and
         * its .mp4 being renamed off .tmp.
         */
        private const val ORPHAN_MIN_AGE_MS = 5 * 60 * 1000L

        /**
         * Implements loop recording by deleting oldest segments when storage is low.
         *
         * CRITICAL: Protects files that are currently being written to prevent corruption.
         *
         * @param directory Directory containing recordings
         * @param maxSizeBytes Maximum total size in bytes
         */
        @JvmStatic
        @JvmOverloads
        fun cleanupOldSegments(directory: File, maxSizeBytes: Long, activeRecorder: HardwareEventRecorderGpu? = null) {
            if (!directory.exists() || !directory.isDirectory) {
                return
            }

            val files = directory.listFiles { _, name -> name.endsWith(".mp4") }
            if (files == null || files.isEmpty()) {
                return
            }

            // Get the currently active file path (if any)
            var activeFilePath: String? = null
            var activeTempPath: String? = null
            if (activeRecorder != null && activeRecorder.isWritingToFile()) {
                activeFilePath = activeRecorder.outputPath
                activeRecorder.tempFile?.let { activeTempPath = it.absolutePath }
            }

            // Calculate total size (excluding active files)
            var totalSize = 0L
            for (file in files) {
                // Skip files currently being written
                val filePath = file.absolutePath
                if (filePath == activeFilePath || filePath == activeTempPath) {
                    logger.debug("Skipping active file in size calculation: " + file.name)
                    continue
                }
                // Skip temp files (*.tmp) - they're being written
                if (file.name.endsWith(".tmp")) {
                    logger.debug("Skipping temp file in size calculation: " + file.name)
                    continue
                }
                totalSize += file.length()
            }

            // Delete oldest files if over limit
            if (totalSize > maxSizeBytes) {
                // Sort by last modified (oldest first)
                files.sortBy { it.lastModified() }

                for (file in files) {
                    if (totalSize <= maxSizeBytes) {
                        break
                    }

                    val filePath = file.absolutePath

                    // CRITICAL: Never delete the file currently being written
                    if (filePath == activeFilePath || filePath == activeTempPath) {
                        logger.warn("Skipping deletion of active file: " + file.name)
                        continue
                    }

                    // Skip temp files - they're being written
                    if (file.name.endsWith(".tmp")) {
                        logger.warn("Skipping deletion of temp file: " + file.name)
                        continue
                    }

                    // Skip very recent files (less than 5 seconds old) - may still be finalizing
                    val fileAge = System.currentTimeMillis() - file.lastModified()
                    if (fileAge < 5000) {
                        logger.warn("Skipping deletion of recent file (age=" + fileAge + "ms): " + file.name)
                        continue
                    }

                    val fileSize = file.length()
                    if (file.delete()) {
                        totalSize -= fileSize
                        val sidecarBytes = deleteSegmentSidecars(file)
                        logger.info(
                            "Deleted old segment: " + file.name +
                                " (" + (fileSize / 1024) + " KB" +
                                (if (sidecarBytes > 0) ", +" + (sidecarBytes / 1024) + " KB sidecars" else "") +
                                ")"
                        )
                    } else {
                        logger.warn("Failed to delete file: " + file.name)
                    }
                }
            }
        }

        /**
         * Clean up orphaned .tmp files that were left behind by crashed recordings,
         * and reap *.broken quarantine sidecars produced by the close/rotate paths
         * when a muxer.stop() failed or the disk writer aborted. Files older than
         * 5 minutes are removed.
         */
        @JvmStatic
        fun cleanupOrphanedTmpFiles(directory: File) {
            if (!directory.exists() || !directory.isDirectory) return

            val orphans = directory.listFiles { _, name -> name.endsWith(".tmp") || name.endsWith(".broken") }
                ?: return

            val now = System.currentTimeMillis()
            for (f in orphans) {
                val age = now - f.lastModified()
                if (age > ORPHAN_MIN_AGE_MS) {
                    val size = f.length()
                    if (f.delete()) {
                        logger.info("Cleaned orphan: " + f.name + " (" + (size / 1024) + " KB, age=" + (age / 1000) + "s)")
                    }
                }
            }
        }

        /**
         * Reaps sidecars whose .mp4 is already gone: `<base>.json`, `<base>.jpg`,
         * `<base>.srt` and `thumb_<base>_a*.jpg` with no `<base>.mp4` beside them.
         *
         * [deleteSegmentSidecars] and StorageManager's reaper keep these in step going
         * forward, but nothing reaps what an older build, a crash between the sidecar
         * write and the .mp4 rename, or any future gap in a deletion path already
         * stranded. Measured on the head unit 2026-09-20: 823 orphans, 111 MB, nine
         * days, entirely undetected (BladeWatch-k3b0 / BladeWatch-g8ee).
         *
         * What that costs, precisely — an earlier version of this comment overstated it
         * and the correction is worth keeping. `StorageManager.getDirectoriesTotalSize`
         * counts only `.mp4` and `.json` toward a category limit, so orphaned `.jpg` and
         * `.srt` are invisible to limit accounting and cost disk only. All 823 found were
         * `.jpg`/`.srt`, so the real damage there was 111 MB of a shared SD card, not
         * deleted footage. An orphaned `.json` IS counted, and that one does consume quota
         * and make the reaper delete more real footage to hit its target — rare, because
         * both deletion paths have always handled `.json`, but a crash between the `.json`
         * write and the `.mp4` rename still strands one with nothing to sweep it.
         *
         * Startup-only, like [cleanupOrphanedTmpFiles] — the leak accrues at roughly
         * 12 MB/day and k3b0 stops new orphans at the source, so a scheduler would buy
         * nothing.
         *
         * Pass the category's WHOLE directory list in one call —
         * `StorageManager.sweepableDirs(category)`. That accessor exists for two reasons:
         * it keeps this function away from the shared legacy base (which holds
         * `bladewatch_secrets.json`, not media), and passing every directory at once is what
         * makes the pooled base set above correct.
         */
        @JvmStatic
        fun cleanupOrphanedSidecars(directories: List<File>) {
            val listings = directories
                .filter { it.exists() && it.isDirectory }
                .mapNotNull { dir -> dir.listFiles()?.let { dir to it } }
            if (listings.isEmpty()) return

            // Live segment bases, pooled across EVERY directory of the category — not just
            // the one being swept. InternalToSdMigrator.moveIfEligible moves files one at a
            // time and skips any file younger than its own age gate, so it routinely leaves
            // "<base>.mp4" on the SD card while "<base>.jpg" is still on internal. Sweeping a
            // mirror in isolation would read that as an orphan and delete a live segment's
            // sidecars. A segment mid-write is "<base>.mp4.tmp" and its sidecars land before
            // the rename, so count those as present too.
            val bases = HashSet<String>()
            for ((_, files) in listings) {
                for (f in files) {
                    val n = f.name
                    when {
                        n.endsWith(".mp4.tmp") -> bases.add(n.substring(0, n.length - 8))
                        n.endsWith(".mp4") -> bases.add(n.substring(0, n.length - 4))
                    }
                }
            }

            val now = System.currentTimeMillis()
            var freed = 0L
            var count = 0
            for (f in listings.flatMap { it.second.asList() }) {
                val n = f.name
                val base = when {
                    n.startsWith("thumb_") && n.endsWith(".jpg") ->
                        // Inverse of the forward "thumb_<base>_a..." rule in
                        // deleteSegmentSidecars, so the two can never disagree about
                        // which segment a thumbnail belongs to.
                        // ponytail: O(files x segments) string compares, once at daemon
                        // start over a few thousand names. Index the bases by prefix if a
                        // directory ever gets big enough for that to matter.
                        bases.firstOrNull { n.startsWith("thumb_" + it + "_a") }
                    n.endsWith(".jpg") || n.endsWith(".srt") || n.endsWith(".json") ->
                        n.substring(0, n.lastIndexOf('.'))
                    // .mp4, .tmp, .broken and anything unrecognised: not ours to reap.
                    else -> continue
                }
                if (base != null && bases.contains(base)) continue
                if (now - f.lastModified() < ORPHAN_MIN_AGE_MS) continue
                val size = f.length()
                if (f.delete()) {
                    freed += size
                    count++
                }
            }
            if (count > 0) {
                logger.info(
                    "Cleaned " + count + " orphaned sidecars (" + (freed / 1024) + " KB) across " +
                        listings.joinToString(", ") { it.first.absolutePath }
                )
            }
        }

        /**
         * Removes the sidecar files that accompany an .mp4 segment: JSON event
         * timeline, v3 hero JPEG, and per-actor thumbnails `thumb_<base>_a*.jpg`.
         *
         * Without this, the loop-rotation deletion only frees the .mp4's bytes —
         * sidecars accumulate as orphans because future passes continue to skip
         * non-.mp4 files. Returns the freed bytes.
         */
        private fun deleteSegmentSidecars(mp4File: File): Long {
            // Drop the API-handler cache entry for this segment so /api/recordings
            // doesn't keep returning a phantom row for a file that's been rotated.
            try {
                RecordingsApiHandler.invalidateRecordingCache(mp4File.absolutePath)
            } catch (ignored: Throwable) {
                logger.warn("Failed to invalidate recording cache for " + mp4File.name + ": " + ignored.message)
            }

            val parent = mp4File.parentFile ?: return 0L
            val mp4Name = mp4File.name
            if (!mp4Name.endsWith(".mp4")) return 0L
            val base = mp4Name.substring(0, mp4Name.length - 4)
            var freed = 0L

            val jsonFile = File(parent, "$base.json")
            if (jsonFile.exists()) {
                val s = jsonFile.length()
                if (jsonFile.delete()) freed += s
            }
            val heroFile = File(parent, "$base.jpg")
            if (heroFile.exists()) {
                val s = heroFile.length()
                if (heroFile.delete()) freed += s
            }
            // SRT subtitle track written by SrtWriter as "<base>.srt". Without this it
            // outlives the segment forever (BladeWatch-k3b0).
            val srtFile = File(parent, "$base.srt")
            if (srtFile.exists()) {
                val s = srtFile.length()
                if (srtFile.delete()) freed += s
            }
            // Anchor with "_a" so sibling segment thumbs (e.g. <base>_2's actor
            // thumbs at "thumb_<base>_2_a*.jpg") aren't swept when this segment
            // is rotated out. ThumbnailBuffer always writes "thumb_<base>_a<id>...".
            val perActorPrefix = "thumb_" + base + "_a"
            val perActor = parent.listFiles { _, name -> name.startsWith(perActorPrefix) && name.endsWith(".jpg") }
            if (perActor != null) {
                for (f in perActor) {
                    val s = f.length()
                    if (f.delete()) freed += s
                }
            }
            return freed
        }
    }
}
