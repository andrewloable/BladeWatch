package net.bladewatch.app.byd.routing

import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.ConditionalPoller
import net.bladewatch.app.monitor.GearMonitor
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.function.Supplier

/**
 * Turns the screen back on automatically if it was switched off via the explicit
 * `ScreenOffCommand` (BladeWatch-2000.3) and the vehicle then leaves the safely-parked state
 * -- "any transition out of the parked state while the screen is off must turn it back on
 * automatically. Do not require a user action to recover." This is a safety recovery, not the
 * screen-off timer/schedule/automation hook the issue explicitly forbids: it only ever turns
 * the screen ON, never off, and only while armed by a prior explicit screen-off.
 *
 * Polls only while armed, via [ConditionalPoller] (BladeWatch-t1lg.2) -- zero polling the
 * rest of the time, matching this project's "no CPU while not needed" convention (see
 * `ChargingEventNotifier.socPoller` for the precedent this mirrors).
 *
 * The constructor is internal -- production uses [getInstance]; tests (same Gradle module)
 * inject both the decision source and the recovery action so this is verifiable without
 * Android.
 */
class ScreenAutoRecovery internal constructor(
    sampleDecision: Supplier<DrivingSafetyGuard.Decision>,
    private val turnScreenOn: Supplier<Boolean>
) {

    private val scheduler: ScheduledExecutorService =
        Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "ScreenAutoRecovery").apply { isDaemon = true }
        }

    private val poller = ConditionalPoller("screen-auto-recovery", POLL_INTERVAL_MS, sampleDecision, scheduler)

    @Volatile
    private var subscription: ConditionalPoller.Subscription? = null

    @Volatile
    private var armed: Boolean = false

    /** Call once a `ScreenOffCommand` has actually succeeded. */
    fun armed() {
        armed = true
        if (subscription == null) {
            val s = poller.subscribe(this::onSample)
            subscription = s
            // subscribe() runs the first tick synchronously, so onSample may already have
            // recovered and called disarm() -- at which point this handle did not exist yet
            // and disarm() had nothing to close. Close it here instead, or the poll outlives
            // the disarm and never stops.
            if (!armed) {
                subscription = null
                s.close()
            }
        }
    }

    /** Call once the screen is known to be on again -- by this class's own recovery or a
     * user-issued `ScreenOnCommand` -- so a later motion sample does not re-fire. */
    fun disarm() {
        armed = false
        val s = subscription
        subscription = null
        s?.close()
    }

    /** Test visibility only. */
    internal fun isArmed(): Boolean = armed

    /** Test visibility only -- whether a poll is currently scheduled. */
    internal fun isPolling(): Boolean = poller.isPolling()

    /** Internal so tests (same module) can drive it directly without a real poll tick. */
    internal fun onSample(decision: DrivingSafetyGuard.Decision) {
        if (!armed || decision == DrivingSafetyGuard.Decision.ALLOW) return
        logger.info("Motion detected while screen off by user request ($decision) -- restoring screen")
        turnScreenOn.get()
        disarm()
    }

    companion object {
        private const val POLL_INTERVAL_MS = 2_000L
        private val logger = DaemonLogger.getInstance("ScreenAutoRecovery")

        private val instance = ScreenAutoRecovery(
            Supplier { liveDecision() },
            Supplier {
                VehicleCommandRouter.getInstance().execute(VehicleCommandRouter.ScreenOnCommand()).outcome ==
                    VehicleCommandRouter.Outcome.SUCCESS
            }
        )

        @JvmStatic
        fun getInstance(): ScreenAutoRecovery = instance

        private fun liveDecision(): DrivingSafetyGuard.Decision {
            val gear = GearMonitor.getInstance().currentGear
            val data = BydDataCollector.getInstance().data
            val speedKmh = data?.speedKmh ?: Double.NaN
            val requireKnownState = GearMonitor.getInstance().lastUpdateTime != 0L
            return DrivingSafetyGuard.evaluate(gear, speedKmh, requireKnownState)
        }
    }
}
