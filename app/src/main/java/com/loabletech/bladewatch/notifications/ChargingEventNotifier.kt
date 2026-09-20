package net.bladewatch.app.notifications

import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.byd.BydVehicleData
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.ChargingDetector
import net.bladewatch.app.monitor.ChargingStateData
import net.bladewatch.app.monitor.ConditionalPoller
import net.bladewatch.app.server.Messages
import org.json.JSONObject
import java.util.Locale
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Publishes `vehicle.charging.*` notifications:
 *
 *  - `vehicle.charging.started` / `.stopped` — driven directly by [ChargingDetector] fused-state
 *    edges. The detector already fuses BMS + Power.isCharging() + L3 inference + plug edges with
 *    hysteresis (30s plug bias, 10s L1↔L2 disagreement, 15s unplug override, 3-sample L3), so
 *    re-debouncing here is redundant and was the cause of silently-dropped sessions.
 *  - `vehicle.charging.full` — once per session when SOC crosses `FULL_SOC_THRESHOLD` (or
 *    plateaus near the top) while a session is active. Suppressed when the session began at or
 *    above the threshold (plugged-in-already-full).
 *  - `vehicle.charging.fault` — every distinct breakdown transition on the BMS edge stream.
 *    Independent of session bookkeeping so a breakdown is always announced even if no session was
 *    active.
 *
 * This notifier is purely a downstream consumer — it never mutates `chargingState` or
 * `chargingPowerKw`. The SOC-history graph reads the snapshot directly via `getData()` and is
 * unaffected by this code path.
 */
class ChargingEventNotifier private constructor() {

    private val fusedListener = ChargingDetector.FusedStateListener { isCharging, source ->
        onFusedEdge(isCharging, source)
    }

    /**
     * Faults come from the raw BMS edge stream, independent of session bookkeeping. A breakdown
     * reported while we never opened a session still warrants a notification.
     */
    private val faultListener = BydDataCollector.ChargingStateListener { prev, now ->
        if (statusOf(now) == ChargingStateData.ChargingStatus.ERROR) {
            publishFault(now)
        }
    }

    private val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "ChargingEventNotifier").apply { isDaemon = true }
    }

    // BladeWatch-t1lg.2: polls only while a charging session is open. Subscribing/closing is
    // driven by onFusedEdge below, which already tracks that lifecycle -- this replaces a
    // hand-rolled ScheduledFuture start/stop with the shared ConditionalPoller primitive.
    private val socPoller = ConditionalPoller<BydVehicleData>(
        "charging-soc", SOC_POLL_INTERVAL_MS,
        { BydDataCollector.getInstance().data!! }, scheduler
    )

    @Volatile private var sessionActive = false
    @Volatile private var socPollSubscription: ConditionalPoller.Subscription? = null
    @Volatile private var fullFiredThisSession = false
    @Volatile private var sessionStartSoc = Double.NaN
    @Volatile private var sessionMaxSoc = Double.NaN
    @Volatile private var plateauStartedAtMs = 0L

    private fun onFusedEdge(isCharging: Boolean, source: String?) {
        if (isCharging == sessionActive) return
        sessionActive = isCharging

        val snap = BydDataCollector.getInstance().data

        if (isCharging) {
            sessionStartSoc = snap?.socPercent ?: Double.NaN
            sessionMaxSoc = sessionStartSoc
            plateauStartedAtMs = 0L
            fullFiredThisSession = false
            startSocPoller()
            val stateCode = snap?.chargingState
                ?: ChargingStateData.CHARGING_BATTERY_STATE_CHARGING
            publishStarted(stateCode)
        } else {
            stopSocPoller()
            val stateCode = snap?.chargingState
                ?: ChargingStateData.CHARGING_BATTERY_STATE_IDLE
            publishStopped(stateCode)
        }
    }

    private fun startSocPoller() {
        stopSocPoller()
        socPollSubscription = socPoller.subscribe(::checkSocFull)
    }

    private fun stopSocPoller() {
        socPollSubscription?.let {
            it.close()
            socPollSubscription = null
        }
    }

    private fun checkSocFull(snap: BydVehicleData?) {
        if (!sessionActive || fullFiredThisSession) return
        if (snap == null) return
        val soc = snap.socPercent
        if (!isFinite(soc)) return

        if (!isFinite(sessionMaxSoc) || soc > sessionMaxSoc) {
            sessionMaxSoc = soc
        }

        val now = System.currentTimeMillis()
        if (soc >= PLATEAU_SOC_FLOOR) {
            if (plateauStartedAtMs == 0L) plateauStartedAtMs = now
        } else {
            plateauStartedAtMs = 0L
        }

        val startedFull = isFinite(sessionStartSoc) && sessionStartSoc >= FULL_SOC_THRESHOLD

        if (soc >= FULL_SOC_THRESHOLD) {
            fullFiredThisSession = true
            if (!startedFull) publishFull(soc)
            return
        }

        if (plateauStartedAtMs != 0L &&
            (now - plateauStartedAtMs) >= PLATEAU_HOLD_MS &&
            !startedFull &&
            isFinite(sessionStartSoc) &&
            (soc - sessionStartSoc) >= MIN_SOC_RISE_FOR_PLATEAU
        ) {
            fullFiredThisSession = true
            publishFull(soc)
        }
    }

    private fun publishStarted(stateCode: Int) {
        val snap = BydDataCollector.getInstance().data
        val powerKw = snap?.chargingPowerKw ?: Double.NaN
        val socPercent = snap?.socPercent ?: Double.NaN

        val body = StringBuilder()
        if (isFinite(powerKw) && abs(powerKw) >= 0.1) {
            body.append(formatKw(powerKw)).append(" kW")
        }
        if (isFinite(socPercent)) {
            if (body.isNotEmpty()) body.append(" • ")
            body.append(socPercent.roundToInt()).append("%")
        }

        val data = JSONObject()
        try {
            data.put("stateCode", stateCode)
            if (isFinite(powerKw)) data.put("powerKw", powerKw)
            if (isFinite(socPercent)) data.put("socPercent", socPercent)
        } catch (ignored: Exception) {
            logger.warn("Failed to build charging started event data: " + ignored.message)
        }

        publish(
            NotificationEvent(
                "vehicle.charging.started",
                NotificationEvent.Severity.INFO,
                Messages.get("notifications.charging_started"),
                body.toString(),
                "charging-session",
                null,
                data
            )
        )
    }

    private fun publishStopped(stateCode: Int) {
        val snap = BydDataCollector.getInstance().data
        val socPercent = snap?.socPercent ?: Double.NaN

        val reason = stateLabel(stateCode)
        val body = StringBuilder(reason)
        if (isFinite(socPercent)) {
            body.append(" • ").append(socPercent.roundToInt()).append("%")
        }

        val data = JSONObject()
        try {
            data.put("stateCode", stateCode)
            data.put("stateName", reason)
            if (isFinite(socPercent)) data.put("socPercent", socPercent)
        } catch (ignored: Exception) {
            logger.warn("Failed to build charging stopped event data: " + ignored.message)
        }

        publish(
            NotificationEvent(
                "vehicle.charging.stopped",
                NotificationEvent.Severity.INFO,
                Messages.get("notifications.charging_stopped"),
                body.toString(),
                "charging-session",
                null,
                data
            )
        )
    }

    private fun publishFull(socPercent: Double) {
        val data = JSONObject()
        try {
            data.put("socPercent", socPercent)
            data.put("threshold", FULL_SOC_THRESHOLD)
        } catch (ignored: Exception) {
            logger.warn("Failed to build charging full event data: " + ignored.message)
        }

        publish(
            NotificationEvent(
                "vehicle.charging.full",
                NotificationEvent.Severity.WARN,
                Messages.get("notifications.charging_complete"),
                Messages.get("notifications.battery_ready_to_unplug", socPercent.roundToInt()),
                "charging-full",
                null,
                data
            )
        )
    }

    private fun publishFault(stateCode: Int) {
        val label = stateLabel(stateCode)

        val data = JSONObject()
        try {
            data.put("stateCode", stateCode)
            data.put("stateName", label)
        } catch (ignored: Exception) {
            logger.warn("Failed to build charging fault event data: " + ignored.message)
        }

        publish(
            NotificationEvent(
                "vehicle.charging.fault",
                NotificationEvent.Severity.CRITICAL,
                Messages.get("notifications.charging_fault"),
                label,
                "charging-fault",
                null,
                data
            )
        )
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("ChargingEventNotifier")

        /**
         * Threshold for the "full" notification. BYD's BMS reports SOC as a whole integer, so any
         * fractional threshold like 99.5 is unreachable below 100. 99 is the earliest reachable
         * signal that the pack is effectively full and the user can unplug.
         */
        private const val FULL_SOC_THRESHOLD = 99.0

        /**
         * Plateau-based completion: if SOC hits this floor, rises substantially from start, and
         * then stays flat for [PLATEAU_HOLD_MS], treat that as full. Catches the BYD pattern of
         * plateauing at 99 during balancing without ever quite hitting 100 before the user
         * unplugs.
         */
        private const val PLATEAU_SOC_FLOOR = 98.0
        private const val PLATEAU_HOLD_MS = 90_000L

        /** Minimum SOC rise to call a plateau "complete" (filters short top-ups). */
        private const val MIN_SOC_RISE_FOR_PLATEAU = 5.0

        /** SOC polling cadence while a session is active. */
        private const val SOC_POLL_INTERVAL_MS = 10_000L

        @Volatile
        private var instance: ChargingEventNotifier? = null

        @JvmStatic
        @Synchronized
        fun start() {
            if (instance != null) return
            val n = ChargingEventNotifier()
            // Single source of truth for session edges. The detector is already fused and
            // debounced; trust its verdict directly.
            val detector = ChargingDetector.getInstance()
            detector.addFusedStateListener(n.fusedListener)
            // Faults are independent — wire to raw BMS edges.
            BydDataCollector.getInstance().addChargingStateListener(n.faultListener)
            instance = n

            // Boot-race replay. The detector does not re-emit current state on subscribe; if
            // BydDataCollector.init() has already driven fused state to true (cable plugged at
            // cold boot), the listener above would otherwise miss the start edge entirely and the
            // user would only get a "stopped" later. Synthesise a single self-call so the session
            // opens and the SOC poller starts.
            if (detector.isCharging()) {
                n.onFusedEdge(true, "boot-replay")
            }
        }

        private fun publish(event: NotificationEvent) {
            try {
                NotificationBus.get().publish(event)
            } catch (t: Throwable) {
                logger.warn("Failed to publish notification event: " + t.message)
            }
        }

        private fun statusOf(stateCode: Int): ChargingStateData.ChargingStatus =
            ChargingStateData(stateCode).status

        private fun stateLabel(stateCode: Int): String = ChargingStateData(stateCode).stateName

        private fun isFinite(v: Double): Boolean = !v.isNaN() && !v.isInfinite()

        private fun formatKw(kw: Double): String = String.format(Locale.US, "%.1f", abs(kw))
    }
}
