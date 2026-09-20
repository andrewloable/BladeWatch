package net.bladewatch.app.server

import java.util.concurrent.atomic.AtomicLong

/**
 * Resolves the client id for a performance-monitoring session (BladeWatch-qwqq).
 *
 * Split out so the decision is testable — `PerformanceMonitor` is a daemon singleton over live
 * device counters and cannot be constructed on the JVM.
 */
object PerformanceClientId {

    /** Distinguishes ids minted within the same millisecond; see [resolve]. */
    private val SEQUENCE = AtomicLong()

    /**
     * The caller's id when it supplied one, otherwise a fresh id.
     *
     * The returned id is the one the server registers AND the one the client must send with
     * every heartbeat, so these must never diverge. Generation uses a counter rather than
     * `Math.random()` alone: two panels opened in the same millisecond must not collide onto one
     * session, because disconnecting either would then stop monitoring for both.
     */
    @JvmStatic
    fun resolve(requested: String?): String {
        val trimmed = requested?.trim()
        if (!trimmed.isNullOrEmpty()) return trimmed
        return "client-" + System.currentTimeMillis() + "-" + SEQUENCE.incrementAndGet()
    }
}
