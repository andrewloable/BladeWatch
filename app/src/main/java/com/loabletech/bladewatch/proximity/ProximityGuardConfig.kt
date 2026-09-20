package net.bladewatch.app.proximity

import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONObject

/**
 * Proximity Guard Configuration POJO
 *
 * Immutable configuration for Proximity Guard recording mode.
 * Uses Builder pattern for construction.
 */
class ProximityGuardConfig private constructor(builder: Builder) {

    val isEnabled: Boolean = builder.enabled
    val triggerLevel: TriggerLevel = builder.triggerLevel
    val preRecordSeconds: Int = validatePreRecordSeconds(builder.preRecordSeconds)
    val postRecordSeconds: Int = validatePostRecordSeconds(builder.postRecordSeconds)

    /** Trigger sensitivity levels. */
    enum class TriggerLevel {
        /** Only trigger on very close objects (0-0.5m). */
        RED,

        /** Trigger on medium-close objects (0-0.8m). */
        YELLOW_RED
    }

    // ==================== BUILDER ====================

    class Builder {
        // DEPRECATED: enabled flag is now controlled by RecordingModeManager.mode
        // Kept for backward compatibility but defaults to true
        internal var enabled = true

        // Default to YELLOW_RED for better sensitivity - triggers on medium-close objects
        internal var triggerLevel = TriggerLevel.YELLOW_RED
        internal var preRecordSeconds = 5
        internal var postRecordSeconds = 10

        fun enabled(enabled: Boolean): Builder = apply { this.enabled = enabled }

        fun triggerLevel(triggerLevel: TriggerLevel): Builder = apply {
            this.triggerLevel = triggerLevel
        }

        fun triggerLevel(triggerLevelStr: String): Builder = apply {
            triggerLevel = try {
                TriggerLevel.valueOf(triggerLevelStr.uppercase())
            } catch (e: IllegalArgumentException) {
                logger.warn("Invalid trigger level: $triggerLevelStr, using default RED")
                TriggerLevel.RED
            }
        }

        fun preRecordSeconds(preRecordSeconds: Int): Builder = apply {
            this.preRecordSeconds = preRecordSeconds
        }

        fun postRecordSeconds(postRecordSeconds: Int): Builder = apply {
            this.postRecordSeconds = postRecordSeconds
        }

        fun build(): ProximityGuardConfig = ProximityGuardConfig(this)
    }

    // ==================== UTILITY ====================

    override fun toString(): String =
        "ProximityGuardConfig{" +
            "enabled=" + isEnabled +
            ", triggerLevel=" + triggerLevel +
            ", preRecordSeconds=" + preRecordSeconds +
            ", postRecordSeconds=" + postRecordSeconds +
            '}'

    companion object {
        private val logger = DaemonLogger.getInstance("ProximityGuardConfig")

        // Validation constants
        private const val MIN_PRE_RECORD_SECONDS = 2
        private const val MAX_PRE_RECORD_SECONDS = 15
        private const val MIN_POST_RECORD_SECONDS = 5
        private const val MAX_POST_RECORD_SECONDS = 30

        // ==================== VALIDATION ====================

        private fun validatePreRecordSeconds(seconds: Int): Int = when {
            seconds < MIN_PRE_RECORD_SECONDS -> {
                logger.warn("preRecordSeconds $seconds < min $MIN_PRE_RECORD_SECONDS, clamping")
                MIN_PRE_RECORD_SECONDS
            }
            seconds > MAX_PRE_RECORD_SECONDS -> {
                logger.warn("preRecordSeconds $seconds > max $MAX_PRE_RECORD_SECONDS, clamping")
                MAX_PRE_RECORD_SECONDS
            }
            else -> seconds
        }

        private fun validatePostRecordSeconds(seconds: Int): Int = when {
            seconds < MIN_POST_RECORD_SECONDS -> {
                logger.warn("postRecordSeconds $seconds < min $MIN_POST_RECORD_SECONDS, clamping")
                MIN_POST_RECORD_SECONDS
            }
            seconds > MAX_POST_RECORD_SECONDS -> {
                logger.warn("postRecordSeconds $seconds > max $MAX_POST_RECORD_SECONDS, clamping")
                MAX_POST_RECORD_SECONDS
            }
            else -> seconds
        }

        // ==================== FACTORY METHODS ====================

        /** Create default configuration. */
        @JvmStatic
        fun createDefault(): ProximityGuardConfig = Builder().build()

        /** Create configuration from UnifiedConfigManager. */
        @JvmStatic
        fun fromConfig(config: JSONObject): ProximityGuardConfig {
            val builder = Builder()

            if (config.has("enabled")) {
                builder.enabled(config.optBoolean("enabled", false))
            }

            if (config.has("triggerLevel")) {
                builder.triggerLevel(config.optString("triggerLevel", "RED"))
            }

            if (config.has("preRecordSeconds")) {
                builder.preRecordSeconds(config.optInt("preRecordSeconds", 5))
            }

            if (config.has("postRecordSeconds")) {
                builder.postRecordSeconds(config.optInt("postRecordSeconds", 10))
            }

            return builder.build()
        }

        // ==================== VALIDATION BOUNDS FOR UI ====================

        @JvmStatic
        fun getMinPreRecordSeconds(): Int = MIN_PRE_RECORD_SECONDS

        @JvmStatic
        fun getMaxPreRecordSeconds(): Int = MAX_PRE_RECORD_SECONDS

        @JvmStatic
        fun getMinPostRecordSeconds(): Int = MIN_POST_RECORD_SECONDS

        @JvmStatic
        fun getMaxPostRecordSeconds(): Int = MAX_POST_RECORD_SECONDS
    }
}
