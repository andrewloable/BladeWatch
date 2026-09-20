package net.bladewatch.app.monitor

import net.bladewatch.app.byd.BydVehicleData
import net.bladewatch.app.logging.DaemonLogger

import java.util.Locale
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Fused charging-state detector.
 *
 * Purpose: replace the old polling-only inference path (which produced the
 * "very inconsistent" detection) with an event-driven layered model that
 * fuses three independent BYD HAL signals plus broadcast-receiver edges.
 *
 * Layers, evaluated in order:
 *
 *   L1. BMS state edge (chargingState == 1 CHARGING) — pushed by the
 *       BYDAutoChargingDevice typed listener (onBatteryManagementDeviceStateChanged).
 *       Authoritative when present. The known firmware bug: some PHEV builds
 *       leave this stuck at 15 IDLE while AC charging, so it's not sufficient
 *       on its own.
 *
 *   L2. BYDAutoPowerDevice.isCharging() — independent ground truth from the
 *       power MCU. Polled once per collect cycle. Used as the primary
 *       cross-check that catches the L1 firmware lie.
 *
 *   L3. Power-flow inference — only fires when L1 AND L2 disagree for
 *       [INFERENCE_DISAGREEMENT_MIN_MS]. Requires the gear-in-park
 *       guard, a positive AC/DC gun assertion (NOT a !=disconnected guard,
 *       which lets UNAVAILABLE through), and [HYSTERESIS_SAMPLES]
 *       consecutive observations. enginePowerKw is invalidated on ACC OFF,
 *       so a stale value from yesterday's drive cannot retrigger this layer.
 *
 *   Edge inputs: ACTION_POWER_CONNECTED / ACTION_POWER_DISCONNECTED
 *       transitions are pushed in directly. CONNECTED nudges fusion toward
 *       charging (sets a "plug recently inserted" flag, accelerating L3
 *       hysteresis); DISCONNECTED forces immediate transition to NOT_CHARGING
 *       and clears all sticky power values.
 *
 * Threading: all mutations happen under [lock]; reads return immutable snapshots.
 */
class ChargingDetector private constructor() {

    /**
     * Listener for fused-state edges. Fires only on actual transitions
     * (true→false or false→true), not on every input. Use this when you
     * want session-level events rather than the raw BMS edge stream
     * (which misses PHEV-stuck-at-IDLE charging sessions entirely).
     */
    fun interface FusedStateListener {
        fun onFusedChargingChanged(isCharging: Boolean, source: String)
    }

    private val fusedListeners = CopyOnWriteArrayList<FusedStateListener>()

    fun addFusedStateListener(l: FusedStateListener?) {
        if (l != null) fusedListeners.addIfAbsent(l)
    }

    fun removeFusedStateListener(l: FusedStateListener?) {
        if (l != null) fusedListeners.remove(l)
    }

    private val lock = Any()

    // L1
    private var bmsState = BydVehicleData.UNAVAILABLE
    private var bmsStateAtMs = 0L

    // L2
    /** Tri-state: TRUE/FALSE/null (unavailable). */
    private var powerIsChargingTri: Boolean? = null
    private var powerIsChargingAtMs = 0L

    // L3 inputs (snapshot pushed in by the collector each cycle)
    private var enginePowerKw = Double.NaN
    private var enginePowerAtMs = 0L
    private var externalChargingPowerKw = Double.NaN
    private var chargingPowerKw = Double.NaN
    private var chargingGunState = BydVehicleData.UNAVAILABLE
    private var inPark = false

    // L3 hysteresis counter (positive = consecutive "charging" samples,
    // negative = consecutive "not charging" samples).
    private var inferenceHysteresis = 0
    private var l3Latched = false

    // ACC awareness
    private var accIsOn = true

    // Edge events
    private var lastPlugConnectedMs = 0L
    private var lastPlugDisconnectedMs = 0L

    // Fused output (what callers see)
    private var fusedCharging = false

    /** Which layer last decided the fused state. For diagnostic logging only. */
    private var fusedSource = "init"

    // ===== Inputs =====

    /**
     * BMS state edge. Called by the typed charging listener on
     * onBatteryManagementDeviceStateChanged AND by the collector after
     * polling getBatteryManagementDeviceState() / chargingState feature ID.
     */
    fun updateBmsState(newState: Int) {
        val transition: FusedTransition
        synchronized(lock) {
            if (newState == bmsState) return
            bmsState = newState
            bmsStateAtMs = System.currentTimeMillis()
            transition = recompute("bms-edge")
        }
        dispatchFusedTransition(transition)
    }

    /**
     * BYDAutoPowerDevice.isCharging() result. May be null if the call
     * failed or returned a sentinel — null means "unavailable, do not use".
     */
    fun updatePowerIsCharging(tri: Boolean?) {
        val transition: FusedTransition
        synchronized(lock) {
            powerIsChargingTri = tri
            powerIsChargingAtMs = System.currentTimeMillis()
            transition = recompute("power-isCharging")
        }
        dispatchFusedTransition(transition)
    }

    /**
     * Push the latest poll snapshot into the detector. Called once per
     * collect cycle by the collector. Used for L3 inference + log
     * diagnostics.
     *
     * @param vd may be null — treated as "no fresh evidence this cycle"
     */
    fun updatePollEvidence(vd: BydVehicleData?, gearMode: Int, gearP: Int) {
        if (vd == null) return
        val transition: FusedTransition
        synchronized(lock) {
            // enginePower freshness — only trust the value if it was
            // populated by an ACC-on collect. invalidateAccDependentSignals()
            // resets enginePowerKw to NaN on ACC OFF, so a stale value
            // from yesterday's drive cannot retrigger inference.
            if (!vd.enginePowerKw.isNaN()) {
                enginePowerKw = vd.enginePowerKw
                enginePowerAtMs = System.currentTimeMillis()
            }
            externalChargingPowerKw = vd.externalChargingPowerKw
            chargingPowerKw = vd.chargingPowerKw
            chargingGunState = vd.chargingGunState
            inPark = gearMode == gearP

            // BMS state seen via poll path (the typed listener edge handler
            // already calls updateBmsState; this catches the case where the
            // listener never fires and the value comes from the polled
            // getBatteryManagementDeviceState() call instead).
            if (vd.chargingState != BydVehicleData.UNAVAILABLE &&
                vd.chargingState != bmsState
            ) {
                bmsState = vd.chargingState
                bmsStateAtMs = System.currentTimeMillis()
            }

            transition = recompute("poll")
        }
        dispatchFusedTransition(transition)
    }

    /** Called when ACC transitions on/off. */
    fun updateAccState(isOn: Boolean) {
        val transition: FusedTransition
        synchronized(lock) {
            accIsOn = isOn
            if (!isOn) {
                // ACC just went OFF. enginePowerKw stops being refreshed,
                // so any value already in this object is the last live
                // reading from while ACC was on. We invalidate to prevent
                // a stale negative reading from yesterday's regen from
                // looking like "current flowing into pack" while parked.
                invalidateAccDependentSignals()
            }
            transition = recompute("acc-" + (if (isOn) "on" else "off"))
        }
        dispatchFusedTransition(transition)
    }

    /**
     * Invalidate signals that go stale when ACC is off. Called on ACC OFF
     * AND on ACTION_POWER_DISCONNECTED.
     */
    private fun invalidateAccDependentSignals() {
        enginePowerKw = Double.NaN
        enginePowerAtMs = 0L
    }

    /** ACTION_POWER_CONNECTED received. */
    fun onPowerConnected() {
        val transition: FusedTransition
        synchronized(lock) {
            lastPlugConnectedMs = System.currentTimeMillis()
            // Any prior "unplugged" override is now stale.
            lastPlugDisconnectedMs = 0L
            logger.info("Plug edge: CONNECTED")
            transition = recompute("plug-connected")
        }
        dispatchFusedTransition(transition)
    }

    /** ACTION_POWER_DISCONNECTED received. */
    fun onPowerDisconnected() {
        val transition: FusedTransition
        synchronized(lock) {
            lastPlugDisconnectedMs = System.currentTimeMillis()
            lastPlugConnectedMs = 0L
            // Wipe sticky power values so a 1-cycle straggler from the
            // BMS doesn't keep us in "charging" after unplug.
            chargingPowerKw = Double.NaN
            externalChargingPowerKw = Double.NaN
            invalidateAccDependentSignals()
            inferenceHysteresis = 0
            l3Latched = false
            logger.info("Plug edge: DISCONNECTED — clearing power evidence")
            transition = recompute("plug-disconnected")
        }
        dispatchFusedTransition(transition)
    }

    // ===== Outputs =====

    /** True if the fused detector currently believes the vehicle is charging. */
    fun isCharging(): Boolean = synchronized(lock) { fusedCharging }

    /** Diagnostic: which layer/event last decided the fused state. */
    fun lastSource(): String = synchronized(lock) { fusedSource }

    // ===== Fusion =====

    /**
     * Carrier for a flip the synchronized recompute saw, so the public
     * caller can dispatch listeners AFTER releasing the lock. Avoids the
     * usual deadlock hazard where a listener calls back into the detector.
     */
    private class FusedTransition(
        val fired: Boolean,
        val isCharging: Boolean,
        val source: String
    ) {
        companion object {
            val NONE = FusedTransition(false, false, "")
        }
    }

    private fun dispatchFusedTransition(t: FusedTransition?) {
        if (t == null || !t.fired) return
        for (l in fusedListeners) {
            try {
                l.onFusedChargingChanged(t.isCharging, t.source)
            } catch (e: Exception) {
                logger.debug("FusedStateListener error: " + e.message)
            }
        }
    }

    private fun recompute(trigger: String): FusedTransition {
        val now = System.currentTimeMillis()
        val prev = fusedCharging
        var next: Boolean
        var source: String

        // Edge override: recent unplug wins for UNPLUG_OVERRIDE_MS.
        if (lastPlugDisconnectedMs > 0 && now - lastPlugDisconnectedMs < UNPLUG_OVERRIDE_MS) {
            next = false
            source = "edge-unplug"
        } else {
            // L1: BMS direct.
            val l1Says = bmsState == ChargingStateData.CHARGING_BATTERY_STATE_CHARGING
            // BMS gives explicit non-charging terminal states we trust.
            val l1Negative =
                bmsState == ChargingStateData.CHARGING_BATTERY_STATE_READY ||
                    bmsState == ChargingStateData.CHARGING_BATTERY_STATE_CHARG_FINISH ||
                    bmsState == ChargingStateData.CHARGING_BATTERY_STATE_CHARG_TERMINATE ||
                    bmsState == ChargingStateData.CHARGING_BATTERY_STATE_DISCHARG_FINISH
            // BMS ambiguous: UNAVAILABLE, IDLE (15 — buggy on PHEVs), or
            // any other code we don't explicitly recognize as terminal.

            // L2: Power MCU isCharging() — null means unavailable, ignore.
            val l2 = powerIsChargingTri

            if (l1Says && (l2 == null || l2)) {
                next = true
                source = "l1-bms"
            } else if (l1Says && l2 == false) {
                // L1 says yes but L2 says no: trust L2 only after the
                // disagreement window. Inside the window, BMS wins (BMS
                // sees cell-level current, more authoritative early on).
                if (now - bmsStateAtMs > INFERENCE_DISAGREEMENT_MIN_MS) {
                    next = false
                    source = "l2-overrides-l1"
                } else {
                    next = true
                    source = "l1-bms"
                }
            } else if (l1Negative) {
                // BMS reports an explicit terminal state (READY/FINISHED/
                // TERMINATED/DISCHARG_FINISH). Trust it — even if Power MCU
                // (L2) momentarily disagrees, an L2-overrides path here
                // would produce inconsistent state codes (caller's
                // effectiveState=CHARGING vs raw vd.chargingState=12). The
                // PHEV firmware bug we route around is BMS *stuck at 15 IDLE*
                // while charging, NOT BMS reporting an explicit terminal
                // state by mistake.
                next = false
                source = "l1-bms-negative"
                inferenceHysteresis = minOf(inferenceHysteresis, 0)
                l3Latched = false
            } else if (l2 == true) {
                next = true
                source = "l2-power"
            } else if (l2 == false) {
                next = false
                source = "l2-power-negative"
            } else {
                // L1 ambiguous + L2 unavailable: fall through to L3 inference.
                next = computeL3Inference()
                source = if (next) "l3-inferred" else "l3-not-inferred"
            }

            // Plug-bias: within PLUG_BIAS_WINDOW_MS of CONNECTED, if any
            // power evidence is positive, force-charging. Handles the
            // ramp-up window where BMS is still initializing.
            if (!next && lastPlugConnectedMs > 0 &&
                now - lastPlugConnectedMs < PLUG_BIAS_WINDOW_MS &&
                hasAnyPowerEvidence(now)
            ) {
                next = true
                source = "plug-bias-power"
            }
        }

        // Update L3 hysteresis counter regardless of which layer fired —
        // this keeps it primed in case L1/L2 go ambiguous.
        updateL3Hysteresis(now)

        fusedCharging = next
        fusedSource = source

        if (next != prev) {
            logger.info(
                "Charging fused " + (if (prev) "ON" else "OFF") + "->" +
                    (if (next) "ON" else "OFF") + " trigger=" + trigger +
                    " source=" + source + " bms=" + bmsState +
                    " power=" + powerIsChargingTri +
                    " gun=" + chargingGunState +
                    " engineKw=" + fmt(enginePowerKw) +
                    " extKw=" + fmt(externalChargingPowerKw) +
                    " chgKw=" + fmt(chargingPowerKw)
            )
            return FusedTransition(true, next, source)
        }
        return FusedTransition.NONE
    }

    private fun computeL3Inference(): Boolean {
        if (!inPark) {
            inferenceHysteresis = minOf(inferenceHysteresis, 0)
            l3Latched = false
            return false
        }
        // Positive gun assertion. AC=2, DC=3, AC_DC=4. VTOL=5 is V2L
        // (vehicle-to-load) — pack is DISCHARGING through the gun, the
        // exact opposite of charging. We must NOT count gun=5 as evidence,
        // and we similarly reject UNAVAILABLE (the PHEV hole the old
        // "!= 1 disconnected" guard fell through).
        val gunPlausible =
            chargingGunState == 2 || chargingGunState == 3 || chargingGunState == 4
        if (!gunPlausible) {
            inferenceHysteresis = minOf(inferenceHysteresis, 0)
            l3Latched = false
            return false
        }
        return l3Latched
    }

    private fun updateL3Hysteresis(now: Long) {
        val evidence = hasAnyPowerEvidence(now)

        if (evidence) {
            inferenceHysteresis = maxOf(0, inferenceHysteresis) + 1
            if (inferenceHysteresis >= HYSTERESIS_SAMPLES) {
                l3Latched = true
            }
        } else {
            inferenceHysteresis = minOf(0, inferenceHysteresis) - 1
            if (-inferenceHysteresis >= HYSTERESIS_SAMPLES) {
                l3Latched = false
                inferenceHysteresis = -HYSTERESIS_SAMPLES // clamp
            }
        }
    }

    /**
     * Any of the three power signals pointing at "current is flowing into the pack".
     *
     * The hysteresis update and the plug-bias check evaluated these three conditions with
     * character-identical code; they are one predicate, stated once.
     */
    private fun hasAnyPowerEvidence(now: Long): Boolean {
        // Engine flow into battery: only count if the value is fresh.
        val engineFresh =
            enginePowerAtMs > 0 && (now - enginePowerAtMs) < ENGINE_POWER_FRESHNESS_MS
        if (engineFresh && !enginePowerKw.isNaN() &&
            enginePowerKw < -ENGINE_POWER_DEADBAND
        ) {
            return true
        }
        // External charger power is reported as positive kW being delivered
        // by the charger to the car — always charging-direction by definition.
        if (!externalChargingPowerKw.isNaN() &&
            externalChargingPowerKw > EXTERNAL_POWER_THRESHOLD
        ) {
            return true
        }
        // chargingPowerKw is signed: positive = into pack (charging),
        // negative = out of pack (V2L / V2G discharge). Only positive
        // values count as charging evidence — abs() previously let V2L
        // sessions latch the detector at CHARGING.
        if (!chargingPowerKw.isNaN() && chargingPowerKw > DEVICE_POWER_THRESHOLD) {
            return true
        }
        return false
    }

    companion object {
        private const val TAG = "ChargingDetector"
        private val logger = DaemonLogger.getInstance(TAG)

        // ===== Tuning =====

        /**
         * How long L1 (BMS) and L2 (Power.isCharging) must disagree before we
         * fall through to L3 (power-flow inference). Both layers can take a few
         * seconds to settle after plug-in, so we tolerate a brief window.
         */
        private const val INFERENCE_DISAGREEMENT_MIN_MS = 10_000L

        /**
         * Samples required to flip the L3 inferred state. Each call to
         * [updatePollEvidence] is one sample. With the 5-second
         * collect cadence, 3 samples = ~15 seconds of consistent evidence
         * before L3 declares charging — long enough to ride out a CAN-bus glitch.
         */
        private const val HYSTERESIS_SAMPLES = 3

        /**
         * After ACTION_POWER_CONNECTED, we know the user just plugged in. This
         * window biases fusion toward charging — useful because the BMS can
         * take 5-10s to start reporting state and we don't want to flap to
         * "not charging" between plug-in and the first BMS event.
         */
        private const val PLUG_BIAS_WINDOW_MS = 30_000L

        /**
         * After ACTION_POWER_DISCONNECTED, we know charging is over regardless
         * of what the BMS says. We snap to NOT_CHARGING and ignore stale BMS
         * for this long (handles the case where the BMS still says 1 CHARGING
         * for a few seconds after unplug).
         */
        private const val UNPLUG_OVERRIDE_MS = 15_000L

        /**
         * Power-evidence thresholds (kW). enginePowerKw negative = current flowing
         * into pack. -0.3 kW is the deadband below which sensor noise dominates.
         */
        private const val ENGINE_POWER_DEADBAND = 0.3
        private const val EXTERNAL_POWER_THRESHOLD = 0.15
        private const val DEVICE_POWER_THRESHOLD = 0.15

        /**
         * Maximum age for enginePowerKw to be trusted as live evidence. Beyond
         * this, the value is stale and [invalidateAccDependentSignals]
         * will have already cleared it on ACC OFF anyway.
         */
        private const val ENGINE_POWER_FRESHNESS_MS = 15_000L

        private val INSTANCE = ChargingDetector()

        @JvmStatic
        fun getInstance(): ChargingDetector = INSTANCE

        private fun fmt(v: Double): String =
            if (v.isNaN()) "NaN" else String.format(Locale.US, "%.2f", v)
    }
}
