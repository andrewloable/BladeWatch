package net.bladewatch.app.surveillance

import android.media.MediaCodec

import net.bladewatch.app.logging.DaemonLogger

import java.nio.ByteBuffer
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ConcurrentLinkedDeque

/**
 * H264CircularBuffer - SOTA Zero-Allocation Edition.
 *
 * Fixes video stutter by pooling ByteBuffers.
 * Eliminates 'ByteBuffer.allocateDirect' calls during recording.
 *
 * Key optimizations:
 * - Pre-allocated buffer pool (no runtime allocations)
 * - Object recycling (zero GC pressure)
 * - Keyframe-aligned pruning (valid MP4 generation)
 * - Thread-safe operations
 *
 * Creates a circular buffer sized for `durationSeconds × fps` packets plus 25%
 * headroom, capped at [POOL_CAPACITY].
 *
 * @param durationSeconds Buffer duration in seconds (e.g., 5)
 * @param fps             Encoder fps used to size the pool. Pass the
 *                        encoder's KEY_FRAME_RATE so 30 fps recordings
 *                        don't exhaust the pool and trigger emergency
 *                        allocations that leak GC pressure under load.
 *                        Defaults to a conservative [DEFAULT_FPS_HINT].
 */
class H264CircularBuffer @JvmOverloads constructor(
    durationSeconds: Int,
    fps: Int = DEFAULT_FPS_HINT
) {

    /** Mutable Packet wrapper (reusable). */
    class Packet(capacity: Int) {
        /** Reusable container, allocated ONCE during init. */
        @JvmField
        val data: ByteBuffer = ByteBuffer.allocateDirect(capacity)

        @JvmField
        val info: MediaCodec.BufferInfo = MediaCodec.BufferInfo()

        @JvmField
        var isKeyFrame: Boolean = false

        /**
         * Copies the source bytes into the pooled direct buffer.
         *
         * @return `true` on success, `false` if the source is larger than
         *         [MAX_PACKET_SIZE] (caller MUST drop the packet — we never grow
         *         the buffer at runtime since the discarded direct buffer would
         *         only be reclaimed via the Cleaner / finalizer, leaking native
         *         heap until then).
         */
        fun copyFrom(src: ByteBuffer, srcInfo: MediaCodec.BufferInfo): Boolean {
            if (data.capacity() < srcInfo.size) {
                // Oversized I-frame spike. Drop rather than reallocate: the
                // old direct buffer would otherwise wait for the Cleaner.
                return false
            }
            info.set(0, srcInfo.size, srcInfo.presentationTimeUs, srcInfo.flags)
            isKeyFrame = (srcInfo.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0

            data.clear()
            src.position(srcInfo.offset)
            src.limit(srcInfo.offset + srcInfo.size)
            data.put(src)
            data.flip()
            return true
        }
    }

    /** The active ring buffer */
    private val buffer = ConcurrentLinkedDeque<Packet>()

    /** The Object Pool (Recycler) */
    private val pool: ArrayBlockingQueue<Packet>

    /**
     * Gets the maximum buffer duration in microseconds.
     * Used to check if buffer needs to be recreated on settings change.
     */
    val maxDurationUs: Long = durationSeconds * 1_000_000L

    private var currentDurationUs: Long = 0
    private var keyframeCount = 0

    /** Debug: track total adds */
    private var addCount = 0

    /** Minimum keyframes to keep based on duration */
    private val minKeyframes: Int

    init {
        // Calculate minimum keyframes needed based on duration. With 2-second
        // I-frame interval, we need (duration / 2) + 1 keyframes; +1 margin.
        minKeyframes = (durationSeconds / 2) + 2

        // Pool size = duration × fps × 1.25, clamped to POOL_CAPACITY.
        // Clamped fps to [10..30] so a bogus value can't blow up sizing.
        val safeFps = fps.coerceIn(10, 30)
        val estimatedPackets = durationSeconds * safeFps
        val poolSize = minOf(estimatedPackets + (estimatedPackets / 4), POOL_CAPACITY)

        logger.info(
            "Pre-allocating circular buffer pool (" + poolSize + " packets × " +
                (MAX_PACKET_SIZE / 1024) + "KB = " +
                (poolSize * MAX_PACKET_SIZE / 1024 / 1024) + "MB) for " +
                durationSeconds + "s @ " + safeFps + "fps..."
        )
        pool = ArrayBlockingQueue(poolSize)
        repeat(poolSize) {
            pool.offer(Packet(MAX_PACKET_SIZE))
        }
        logger.info(
            "Buffer pool ready (" + durationSeconds + "s, minKeyframes=" +
                minKeyframes + "). Zero-allocation mode active."
        )
    }

    /**
     * Adds a packet to the buffer using pooled allocation.
     *
     * @param data Encoded H.264 data
     * @param info Buffer metadata
     */
    @Synchronized
    fun add(data: ByteBuffer, info: MediaCodec.BufferInfo) {
        // Borrow a packet from the pool (Instant - no allocation)
        var packet = pool.poll()

        if (packet == null) {
            // Pool empty? We are generating frames faster than pruning.
            // Force prune to recycle an old packet.
            if (!buffer.isEmpty()) {
                recyclePacket(buffer.removeFirst())
                packet = pool.poll()
            }

            // Still null? Drop this frame rather than emergency-allocating
            // a fresh direct ByteBuffer. An emergency packet can't be safely
            // returned to a full pool (recyclePacket would have to drop it,
            // leaking its 256KB direct buffer until the Cleaner runs). Pool
            // sizing already accounts for duration × fps × 1.25; sustained
            // exhaustion means the encoder is mis-paced, not a transient.
            if (packet == null) {
                logger.warn(
                    "Pool exhausted - dropping packet (size=" + info.size +
                        ", flags=" + info.flags + ")"
                )
                return
            }
        }

        // Copy data (Fast memcpy, no allocation). Returns false if the source
        // is larger than MAX_PACKET_SIZE — drop and recycle in that case.
        if (!packet.copyFrom(data, info)) {
            logger.warn(
                "Dropping oversized packet (size=" + info.size + " > " + MAX_PACKET_SIZE + ")"
            )
            pool.offer(packet) // Pool slot still owned by us; return it.
            return
        }
        buffer.addLast(packet)

        if (packet.isKeyFrame) {
            keyframeCount++
        }

        addCount++

        // Update duration
        if (buffer.size > 1) {
            currentDurationUs = buffer.last.info.presentationTimeUs -
                buffer.first.info.presentationTimeUs
        }

        // Debug: Log buffer state every 50 frames (~6 seconds at 8 FPS)
        if (addCount % 50 == 0) {
            logger.debug(
                String.format(
                    "Buffer state: %d packets, %.1f sec, %d keyframes, pool=%d free",
                    buffer.size, currentDurationUs / 1_000_000.0, keyframeCount, pool.size
                )
            )
        }

        // Prune and Recycle old packets
        pruneOldPackets()
    }

    /**
     * Recycles a packet back to the pool. Pool capacity equals the number of
     * packets ever allocated (we never allocate beyond pool size; oversize /
     * exhaustion paths drop instead — see [add]). offer() therefore
     * always succeeds.
     *
     * @param p Packet to recycle
     */
    private fun recyclePacket(p: Packet?) {
        if (p != null) {
            if (p.isKeyFrame) {
                keyframeCount--
            }
            p.data.clear()
            pool.offer(p)
        }
    }

    /**
     * Prunes old packets to maintain buffer duration limit.
     *
     * CRITICAL: Keeps enough keyframes to maintain target duration.
     * minKeyframes is calculated based on configured pre-record duration.
     */
    private fun pruneOldPackets() {
        while (currentDurationUs > maxDurationUs && buffer.size > 1) {
            val first = buffer.first

            // Don't prune if we'd drop below minimum keyframes
            if (first.isKeyFrame && keyframeCount <= minKeyframes) {
                break // Keep this keyframe, we're at minimum
            }

            // Find the next keyframe in the buffer
            val nextKeyframe = buffer.firstOrNull { it.isKeyFrame && it !== first }

            // Logic to keep Keyframe alignment
            if (first.isKeyFrame && nextKeyframe != null) {
                // Safe to remove - we have another keyframe
                recyclePacket(buffer.removeFirst())
            } else if (!first.isKeyFrame) {
                // Not a keyframe, safe to remove
                recyclePacket(buffer.removeFirst())
            } else {
                // This is the only keyframe, keep it even if over budget
                break
            }

            // Recalculate duration
            if (buffer.size > 1) {
                currentDurationUs = buffer.last.info.presentationTimeUs -
                    buffer.first.info.presentationTimeUs
            } else {
                currentDurationUs = 0
                break
            }
        }
    }

    /**
     * Returns all packets for flushing to file.
     *
     * Ensures the returned list starts with a keyframe for valid MP4 generation.
     * NOTE: Packets are NOT removed from buffer - they will be recycled naturally
     * when they fall out of the time window.
     *
     * @return List of packets starting with keyframe
     */
    @Synchronized
    fun getPacketsForFlush(): List<Packet> {
        val result = ArrayList<Packet>()
        var foundKeyFrame = false

        for (p in buffer) {
            if (p.isKeyFrame) {
                foundKeyFrame = true
            }
            if (foundKeyFrame) {
                result.add(p)
            }
        }

        logger.info(
            String.format(
                "Flushing %d packets (%.1f sec, %d keyframes)",
                result.size,
                if (result.isEmpty()) {
                    0.0
                } else {
                    (
                        result[result.size - 1].info.presentationTimeUs -
                            result[0].info.presentationTimeUs
                        ) / 1_000_000.0
                },
                result.count { it.isKeyFrame }
            )
        )

        return result
    }

    /** Clears the buffer and recycles all packets back to pool. */
    @Synchronized
    fun clear() {
        // Recycle EVERYTHING back to pool
        while (!buffer.isEmpty()) {
            recyclePacket(buffer.poll())
        }
        currentDurationUs = 0
        keyframeCount = 0
        logger.info("Buffer cleared (packets recycled to pool)")
    }

    /**
     * Gets current buffer statistics.
     *
     * @return Human-readable stats string
     */
    @Synchronized
    fun getStats(): String = String.format(
        "Buffer: %d packets, %.1f sec, %d keyframes, pool=%d free",
        buffer.size,
        currentDurationUs / 1_000_000.0,
        keyframeCount,
        pool.size
    )

    /**
     * Gets the number of packets in buffer.
     *
     * @return Packet count
     */
    @Synchronized
    fun size(): Int = buffer.size

    /**
     * Gets the current buffer duration in seconds.
     *
     * @return Duration in seconds
     */
    @Synchronized
    fun getDurationSeconds(): Double = currentDurationUs / 1_000_000.0

    /**
     * Gets the number of free packets in the pool.
     *
     * @return Free packet count
     */
    fun getPoolFreeCount(): Int = pool.size

    companion object {
        private const val TAG = "H264CircularBuffer"
        private val logger = DaemonLogger.getInstance(TAG)

        // MAX BUFFER SIZE: 768KB per packet. Handles I-frames at HIGH H.264 (6 Mbps,
        // 2-sec GOP → I-frame spike ~900KB), covers STANDARD-H.264 comfortably (observed
        // 527KB I-frame) through PREMIUM typical. At 200-pool ceiling = 150 MB peak.
        private const val MAX_PACKET_SIZE = 768 * 1024

        // POOL CEILING: hard cap to bound peak memory regardless of fps. With
        // 30 fps × 10 s × 768KB = 225 MB worst-case, we allow up to 200 packets
        // (~150 MB peak). Pool sizing inside the ctor uses configured fps and
        // adds 25% headroom; this constant only kicks in if duration × fps
        // somehow exceeds the cap.
        private const val POOL_CAPACITY = 200

        /** Default fps used when caller doesn't specify. Conservative. */
        private const val DEFAULT_FPS_HINT = 15
    }
}
