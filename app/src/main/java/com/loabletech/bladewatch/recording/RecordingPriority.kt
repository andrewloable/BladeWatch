package net.bladewatch.app.recording

/**
 * BladeWatch-gyg1.3: honest performance/reliability trade for recording.
 *
 * Step Zero found exactly one lever that changes how much recording could be lost on an
 * abrupt power loss: segment rotation length (see
 * `HardwareEventRecorderGpu.loadSegmentDurationMs`). That length is already a separate,
 * already-shipped user control ("Recording Limit", 1/5/10 minutes) with no honest framing of
 * the trade. This does not replace it -- it is a cap layered on top: [RELIABILITY] forces the
 * shortest already-supported segment length regardless of Recording Limit; [PERFORMANCE] is a
 * pure passthrough, bit-identical to pre-issue behaviour.
 */
enum class RecordingPriority {
    PERFORMANCE,
    RELIABILITY;

    /**
     * Applies this priority to a segment length chosen independently via the existing
     * Recording Limit setting. This return value is the actual knob -- tests assert on it,
     * not on the enum constant.
     */
    fun effectiveSegmentMinutes(configuredMinutes: Int): Int =
        if (this == RELIABILITY) minOf(configuredMinutes, RELIABILITY_CAP_MINUTES) else configuredMinutes

    companion object {
        private const val RELIABILITY_CAP_MINUTES = 1

        // The new-install default (RELIABILITY) and the one-time upgrade migration to
        // PERFORMANCE both live in UnifiedConfigManager -- applyDefaults() and
        // migrateConfig()'s priorityMigrated marker respectively -- because only a persisted,
        // marked migration can run exactly once and survive the user later choosing
        // RELIABILITY deliberately. Inferring either of those at read time here would be a
        // second owner of the same decision, free to disagree with the persisted one.

        /** Never throws. An absent or unrecognised config value falls back to RELIABILITY --
         * the safe choice -- rather than silently disabling the cap. Prefer [resolve], which
         * additionally applies the upgrade migration for an absent value. */
        @JvmStatic
        fun fromConfigValue(value: String?): RecordingPriority =
            try {
                valueOf(value ?: "")
            } catch (e: IllegalArgumentException) {
                RELIABILITY
            }
    }
}
