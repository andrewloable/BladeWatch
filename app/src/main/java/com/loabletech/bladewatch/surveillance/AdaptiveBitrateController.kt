package net.bladewatch.app.surveillance

import android.animation.ValueAnimator
import net.bladewatch.app.logging.DaemonLogger

/**
 * Adjusts the encoder bitrate based on the motion score, to optimise storage usage. Static scenes
 * use a low bitrate (3 Mbps); high-motion scenes use a high one (8 Mbps).
 *
 * Benefits: 2-3x storage savings on idle footage, quality maintained during important events, and
 * smooth 500ms transitions that prevent encoder artifacts.
 *
 * @param encoder the hardware encoder to control
 * @param initialBitrate the initial bitrate in bps
 */
class AdaptiveBitrateController(
    private val encoder: HardwareEventRecorderGpu,
    initialBitrate: Int
) {

    /** Current bitrate in bps. */
    var currentBitrate: Int = initialBitrate
        private set

    /** Target bitrate in bps. */
    var targetBitrate: Int = initialBitrate
        private set

    private var bitrateAnimator: ValueAnimator? = null

    /**
     * Update the bitrate from the motion score. Call this periodically (e.g. every second).
     *
     * @param motionScore 0.0 (static) to 1.0 (maximum motion)
     */
    fun updateBitrate(motionScore: Float) {
        val newTarget = when {
            motionScore < THRESHOLD_LOW -> BITRATE_LOW
            motionScore < THRESHOLD_HIGH -> BITRATE_MEDIUM
            else -> BITRATE_HIGH
        }

        // Only change if different from the current target
        if (newTarget != targetBitrate) {
            targetBitrate = newTarget
            rampToBitrate(newTarget)
        }
    }

    /** Ramp the bitrate smoothly to avoid encoder artifacts. */
    private fun rampToBitrate(target: Int) {
        // Cancel any ongoing animation
        bitrateAnimator?.let { if (it.isRunning) it.cancel() }

        logger.info(
            String.format(
                "Ramping bitrate: %d → %d Mbps (motion-based)",
                currentBitrate / 1_000_000, target / 1_000_000
            )
        )

        bitrateAnimator = ValueAnimator.ofInt(currentBitrate, target).apply {
            duration = RAMP_DURATION_MS.toLong()
            addUpdateListener { animation ->
                val animatedBitrate = animation.animatedValue as Int
                encoder.setBitrate(animatedBitrate)
                currentBitrate = animatedBitrate
            }
            start()
        }
    }

    /** Set the bitrate immediately, without ramping. */
    fun setImmediateBitrate(bitrate: Int) {
        bitrateAnimator?.let { if (it.isRunning) it.cancel() }

        encoder.setBitrate(bitrate)
        currentBitrate = bitrate
        targetBitrate = bitrate

        logger.info("Bitrate set immediately: " + (bitrate / 1_000_000) + " Mbps")
    }

    /** Release resources. */
    fun release() {
        bitrateAnimator?.let { if (it.isRunning) it.cancel() }
        bitrateAnimator = null
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("AdaptiveBitrate")

        // Bitrate levels (bps)
        const val BITRATE_LOW = 3_000_000 // 3 Mbps — static scenes
        const val BITRATE_MEDIUM = 5_000_000 // 5 Mbps — moderate motion
        const val BITRATE_HIGH = 8_000_000 // 8 Mbps — high motion

        // Motion score thresholds
        const val THRESHOLD_LOW = 0.10f // 10% motion
        const val THRESHOLD_HIGH = 0.50f // 50% motion

        /** Ramp duration for smooth transitions. */
        const val RAMP_DURATION_MS = 500
    }
}
