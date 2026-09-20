package net.bladewatch.app.monitor

import android.content.Context

import net.bladewatch.app.logging.DaemonLogger

import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * Abstract base class for BYD device monitors.
 *
 * Provides common functionality:
 * - Lifecycle management (init, start, stop)
 * - Retry logic with exponential backoff
 * - Availability tracking
 * - DaemonLogger integration
 * - Error handling
 *
 * @param T The data type this monitor produces
 * @param monitorName The name of this monitor for logging
 */
abstract class BaseDeviceMonitor<T> protected constructor(
    @JvmField protected val monitorName: String
) {

    @JvmField
    protected val logger: DaemonLogger = DaemonLogger.getInstance(monitorName)

    @JvmField
    protected var context: Context? = null

    // Named `running`/`available` rather than `isRunning`/`isAvailable`: Kotlin cannot have a
    // property and a function of the same name, and the public accessors below own those names.
    @JvmField
    protected val running = AtomicBoolean(false)

    @JvmField
    protected val available = AtomicBoolean(false)

    @JvmField
    protected val retryCount = AtomicInteger(0)

    @JvmField
    protected var retryThread: Thread? = null

    // ==================== LIFECYCLE ====================

    /**
     * Initialize the monitor with context.
     * Pass null for daemon mode.
     *
     * @param context Android context, or null for daemon mode
     */
    abstract fun init(context: Context?)

    /**
     * Start monitoring.
     * Subclasses should register BYD device listeners here.
     */
    abstract fun start()

    /**
     * Stop monitoring.
     * Subclasses should unregister BYD device listeners here.
     */
    abstract fun stop()

    // ==================== DATA ACCESS ====================

    /**
     * Get the current cached value.
     *
     * @return The current value, or null if unavailable
     */
    abstract fun getCurrentValue(): T?

    /**
     * Get the timestamp of the last update.
     *
     * @return Timestamp in milliseconds, or 0 if never updated
     */
    abstract fun getLastUpdateTime(): Long

    /**
     * Check if this monitor is available.
     *
     * @return true if the monitor is successfully connected to BYD API
     */
    fun isAvailable(): Boolean = available.get()

    /**
     * Check if this monitor is running.
     *
     * @return true if start() has been called and monitor is active
     */
    fun isRunning(): Boolean = running.get()

    // ==================== RETRY MANAGEMENT ====================

    /** Mark this monitor as available. */
    protected fun markAvailable() {
        available.set(true)
        retryCount.set(0)
        log("Monitor available")
    }

    /** Mark this monitor as unavailable and schedule retry. */
    protected fun markUnavailable() {
        available.set(false)
        scheduleRetry()
    }

    /**
     * Schedule a retry with exponential backoff.
     * After [MAX_RETRIES], switches to periodic reconnection.
     */
    protected fun scheduleRetry() {
        val currentRetry = retryCount.getAndIncrement()

        if (currentRetry >= MAX_RETRIES) {
            // Exhausted retries, switch to periodic reconnection
            log("Max retries exhausted, will retry every " + (RECONNECT_INTERVAL_MS / 1000) + "s")
            schedulePeriodicReconnect()
            return
        }

        val backoffMs = RETRY_BACKOFF_MS[minOf(currentRetry, RETRY_BACKOFF_MS.size - 1)]
        log("Scheduling retry " + (currentRetry + 1) + "/" + MAX_RETRIES + " in " + backoffMs + "ms")

        // Cancel any existing retry thread before spawning a new one
        cancelRetries()

        val thread = Thread({
            try {
                Thread.sleep(backoffMs)
                if (!available.get()) {
                    log("Retrying initialization...")
                    init(context)
                    if (available.get()) {
                        start()
                    }
                }
            } catch (e: InterruptedException) {
                logger.warn("Retry cancelled (interrupted)")
            } catch (e: Exception) {
                logError("Retry failed", e)
            }
        }, "$monitorName-Retry")

        retryThread = thread
        thread.start()
    }

    /**
     * Schedule periodic reconnection attempts.
     * Only one reconnect thread runs at a time.
     */
    protected fun schedulePeriodicReconnect() {
        // Cancel any existing retry/reconnect thread
        cancelRetries()

        val thread = Thread({
            while (!available.get() && !Thread.currentThread().isInterrupted) {
                try {
                    Thread.sleep(RECONNECT_INTERVAL_MS)
                    if (!available.get()) {
                        log("Attempting periodic reconnection...")
                        retryCount.set(0)
                        init(context)
                        if (available.get()) {
                            start()
                        }
                    }
                } catch (e: InterruptedException) {
                    break
                } catch (e: Exception) {
                    logError("Reconnection failed", e)
                }
            }
        }, "$monitorName-Reconnect")

        retryThread = thread
        thread.isDaemon = true
        thread.start()
    }

    /** Cancel any pending retries. */
    protected fun cancelRetries() {
        retryThread?.interrupt()
        retryThread = null
    }

    // ==================== LOGGING ====================

    /** Log an info message. */
    protected fun log(message: String) {
        logger.info(message)
    }

    /** Log an error message with exception. */
    protected fun logError(message: String, t: Throwable?) {
        logger.error(message, t)
    }

    companion object {
        // Retry configuration
        const val MAX_RETRIES = 3

        /** 1s, 2s, 4s */
        @JvmField
        val RETRY_BACKOFF_MS = longArrayOf(1000, 2000, 4000)

        /** 30 seconds */
        const val RECONNECT_INTERVAL_MS = 30000L
    }
}
