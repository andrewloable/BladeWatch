package net.bladewatch.app.monitor

import android.content.Context
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.abs
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.byd.BydVehicleData
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Singleton coordinator for BYD vehicle data.
 *
 * Phase 3: a thin wrapper around [BydDataCollector]. All data reads delegate to the collector.
 * Keeps the same API surface so existing consumers (HttpServer, SurveillanceIpcServer,
 * TripDetector, etc.) do not need changes.
 *
 * [BatteryPowerMonitor] is kept for AccSentryDaemon's voltage-based MCU control — it needs
 * listener callbacks for real-time voltage changes.
 */
class VehicleDataMonitor private constructor() {

    // Only BatteryPowerMonitor is kept — AccSentryDaemon needs its listener for voltage-based
    // MCU control.
    private val batteryPowerMonitor = BatteryPowerMonitor()

    private val listeners = CopyOnWriteArrayList<VehicleDataListener>()

    @Volatile
    private var running = false

    private var context: Context? = null

    // ==================== LIFECYCLE ====================

    fun init(context: Context) {
        this.context = context
        logger.info("Initializing VehicleDataMonitor (BydDataCollector mode)")

        // Only init the battery power monitor (for the AccSentryDaemon voltage listener).
        try {
            batteryPowerMonitor.init(context)
        } catch (e: Exception) {
            logger.error("Failed to init BatteryPowerMonitor", e)
        }

        logger.info("Initialization complete (data from BydDataCollector)")
    }

    fun initBatteryPowerOnly(context: Context) {
        this.context = context
        try {
            batteryPowerMonitor.init(context)
        } catch (e: Exception) {
            logger.error("Failed to init BatteryPowerMonitor", e)
        }
    }

    @Synchronized
    fun start() {
        if (running) return
        try {
            batteryPowerMonitor.start()
        } catch (e: Exception) {
            logger.error("BatteryPowerMonitor start failed", e)
        }
        running = true
        logger.info("VehicleDataMonitor started")
    }

    @Synchronized
    fun startBatteryPowerOnly() {
        if (running) return
        try {
            batteryPowerMonitor.start()
        } catch (e: Exception) {
            logger.error("BatteryPowerMonitor start failed", e)
        }
        running = true
    }

    @Synchronized
    fun stop() {
        if (!running) return
        try {
            batteryPowerMonitor.stop()
        } catch (e: Exception) {
            logger.warn("batteryPowerMonitor.stop() failed: " + e.message)
        }
        running = false
        logger.info("VehicleDataMonitor stopped")
    }

    @Synchronized
    fun stopBatteryPowerOnly() {
        if (!running) return
        try {
            batteryPowerMonitor.stop()
        } catch (e: Exception) {
            logger.warn("batteryPowerMonitor.stop() (power-only) failed: " + e.message)
        }
        running = false
    }

    fun isRunning(): Boolean = running

    // ==================== DATA ACCESS (delegates to BydDataCollector) ====================

    fun getVd(): BydVehicleData? = try {
        val c = BydDataCollector.getInstance()
        if (c.isInitialized) c.data else null
    } catch (e: Exception) {
        null
    }

    fun getBatteryVoltage(): BatteryVoltageData? {
        val vd = getVd()
        if (vd != null && vd.voltageLevelRaw != BydVehicleData.UNAVAILABLE) {
            return BatteryVoltageData(vd.voltageLevelRaw)
        }
        return null
    }

    fun getBatteryPower(): BatteryPowerData? {
        // Try the collector first, fall back to the monitor (for AccSentryDaemon compat).
        val vd = getVd()
        if (vd != null && !java.lang.Double.isNaN(vd.voltage12v)) {
            return BatteryPowerData(vd.voltage12v)
        }
        return batteryPowerMonitor.getCurrentValue()
    }

    fun getBatterySoc(): BatterySocData? {
        val vd = getVd()
        if (vd != null && !vd.socPercent.isNaN()) {
            return BatterySocData(vd.socPercent)
        }
        return null
    }

    /**
     * Charging state derivation — fused detector.
     *
     * The "is charging?" decision is owned by [ChargingDetector], which fuses three
     * independent signals and two edge inputs:
     *
     *  - L1. BMS state edge (chargingState == 1) via the typed AbsBYDAutoChargingListener
     *    registered in BydDataCollector.
     *  - L2. BYDAutoPowerDevice.isCharging() polled once per cycle as a cross-check that
     *    catches the PHEV "BMS stuck at 15 IDLE while charging" firmware bug.
     *  - L3. Power-flow inference with hysteresis and a positive AC/DC gun assertion
     *    (gun==2/3/4/5; UNAVAILABLE no longer slips through like the old
     *    "!= 1 disconnected" guard).
     *  - E1. ACTION_POWER_CONNECTED — biases fusion toward charging during the ramp-up
     *    window before the BMS reports.
     *  - E2. ACTION_POWER_DISCONNECTED — overrides the fused state to NOT_CHARGING for
     *    UNPLUG_OVERRIDE_MS so a stale BMS value cannot keep us in "charging" after the
     *    cable comes out.
     *
     * This method is a thin presentation wrapper: ask the detector for the verdict, choose an
     * effective state code (CHARGING when the detector says yes, else the BMS state if known,
     * else null), and resolve power magnitude.
     *
     * Power magnitude resolution (when fused says CHARGING):
     *  1. external charging power (InstrumentDevice — charger-reported)
     *  2. chargingDevice.chargingPower
     *  3. abs(engine power) — only when ACC is on (NaN-guarded after ACC OFF invalidation in
     *     BydDataCollector.setAccState)
     *  4. nominal-capacity hint (3.3 kW PHEV / 7 kW BEV, marked estimated)
     *
     * @return the charging state, or null when no state signal is available at all.
     */
    fun getChargingState(): ChargingStateData? {
        val vd = getVd() ?: return null

        val fusedCharging = ChargingDetector.getInstance().isCharging()

        val effectiveState: Int = when {
            fusedCharging -> ChargingStateData.CHARGING_BATTERY_STATE_CHARGING
            // Pass through whatever the BMS reports (READY, FINISHED, IDLE, error...).
            vd.chargingState != BydVehicleData.UNAVAILABLE -> vd.chargingState
            // No BMS state and the detector is OFF — the caller has nothing to show.
            else -> return null
        }

        val data = ChargingStateData(effectiveState)

        // ---- Power magnitude ----
        if (effectiveState == ChargingStateData.CHARGING_BATTERY_STATE_CHARGING) {
            if (!vd.externalChargingPowerKw.isNaN() && vd.externalChargingPowerKw > 0) {
                data.updateChargingPower(vd.externalChargingPowerKw)
            } else if (!vd.chargingPowerKw.isNaN() && vd.chargingPowerKw > 0) {
                data.updateChargingPower(vd.chargingPowerKw)
            } else if (!vd.enginePowerKw.isNaN() && vd.enginePowerKw < -0.3) {
                // Engine current flowing into the pack. setAccState(false) wipes this to NaN,
                // so a value here is fresh from an ACC-on cycle.
                data.updateChargingPower(abs(vd.enginePowerKw))
            } else {
                // The detector says CHARGING but no real kW signal arrived. Show a
                // nominal-based hint so the UI does not say "Charging at 0 kW".
                try {
                    val nominal = getNominalCapacityKwh()
                    if (nominal > 0) {
                        // Sub-30 kWh nominal pack means PHEV (3.3 kW AC), else BEV (7 kW AC).
                        data.updateChargingPower(
                            if (nominal < BydDataCollector.PHEV_MAX_NOMINAL_KWH) 3.3 else 7.0
                        )
                        data.isEstimated = true
                    }
                } catch (e: Exception) {
                    logger.debug("charging power estimate failed: " + e.message)
                }
            }
        }
        return data
    }

    fun getDrivingRange(): DrivingRangeData? {
        val vd = getVd()
        if (vd != null && vd.elecRangeKm != BydVehicleData.UNAVAILABLE) {
            return DrivingRangeData(
                vd.elecRangeKm,
                if (vd.fuelRangeKm != BydVehicleData.UNAVAILABLE) vd.fuelRangeKm else 0,
                vd.fuelPercent // NaN on BEVs (BydDataCollector only sets it on PHEVs)
            )
        }
        return null
    }

    fun getBatteryThermal(): BatteryThermalData? {
        val vd = getVd()
        if (vd != null) {
            val hi = vd.highCellTempC
            val lo = vd.lowCellTempC
            val avg = vd.avgCellTempC
            if (!hi.isNaN() || !lo.isNaN() || !avg.isNaN()) {
                return BatteryThermalData(hi, lo, avg, System.currentTimeMillis())
            }
        }
        return null
    }

    fun getBatteryRemainPowerKwh(): Double {
        val vd = getVd() ?: return 0.0

        val soc = if (vd.socPercent.isNaN()) 0.0 else vd.socPercent
        val rawKwh = if (vd.remainKwh.isNaN()) 0.0 else vd.remainKwh

        // Nominal pack capacity from BYD local data (charging device report, or implied from a
        // trustworthy raw remain-kWh reading).
        val nominal = getNominalCapacityKwh()
        if (nominal > 0 && soc > 0) {
            val isPhev = isPhevVehicle(nominal)
            // No SOH degradation source is available from BYD local data, so the pack is
            // treated as healthy (100% SOH).
            val computedKwh = (soc / 100.0) * nominal

            // Validate the raw BMS value: if implied capacity is wildly off from nominal, the
            // BMS is returning garbage (common on Seal and Han EV when ACC is off). Use the
            // computed value instead.
            if (rawKwh > 0 && soc > 5) {
                val impliedCap = rawKwh / (soc / 100.0)
                val ratio = impliedCap / nominal
                if (ratio < 0.5 || ratio > 1.5) {
                    return computedKwh
                }
            }

            if (isPhev) return computedKwh
            // BEV with a valid raw value: use it.
            if (rawKwh > 0) return rawKwh
            // BEV with no raw value: use computed.
            return computedKwh
        }

        // No nominal capacity: use the raw BMS value, but only if it is really energy.
        // nominal == 0.0 is the honest "unknown" NominalCapacityResolver now returns, and
        // handing the raw value back here would convert that straight into the mirrored
        // number the fix exists to eliminate (BladeWatch-ofe9).
        return NominalCapacityResolver.trustworthyRemainKwh(rawKwh, soc)
    }

    /**
     * Derive nominal pack capacity (kWh). See [NominalCapacityResolver] for the priority order
     * and, importantly, for why the `remainKwh / (soc/100)` derivation is no longer trusted
     * unconditionally (BladeWatch-x4lf: on this car that channel mirrors SoC percent, which
     * made every pack look like ~100 kWh).
     *
     * Returns 0 when capacity genuinely cannot be determined. There is no SOH/degradation
     * source in BYD local data — callers treat the pack as 100% healthy.
     */
    /**
     * Which source [getNominalCapacityKwh] answered from — "user", "sdk", "catalogue",
     * "derived" or "unset" (BladeWatch-b9vl).
     *
     * Computed from the same inputs, in the same order, by the same object that picks the
     * value. `GetSohNominal` used to return a hardcoded "unset" while a capacity was
     * demonstrably known; a source derived anywhere else drifts from the value again.
     */
    fun getNominalCapacitySource(): String {
        val vd = getVd() ?: return "unset"
        return NominalCapacityResolver.sourceOf(
            overrideKwh = nominalOverrideKwh(),
            chargingCapacityKwh = vd.chargingCapacityKwh,
            catalogueKwh = catalogueNominalKwh(),
            remainKwh = vd.remainKwh,
            socPercent = vd.socPercent,
        )
    }

    /** The per-trim `nominalKwh` from models/manifest.json, or 0 when it cannot answer. */
    private fun catalogueNominalKwh(): Double = try {
        net.bladewatch.app.server.ModelsApiHandler.nominalKwhForSelectedModel()
    } catch (e: Throwable) {
        0.0
    }

    /** The owner's explicit capacity, or 0 when unset. Best-effort: config is off-process. */
    private fun nominalOverrideKwh(): Double = try {
        net.bladewatch.app.config.UnifiedConfigManager.getNominalCapacityOverrideKwh()
    } catch (e: Throwable) {
        0.0
    }

    fun getNominalCapacityKwh(): Double {
        val vd = getVd() ?: return 0.0
        // The per-trim `nominalKwh` in models/manifest.json. The lookup already existed and
        // had no callers at all, so the catalogue value was never consulted.
        val catalogueKwh = catalogueNominalKwh()
        return NominalCapacityResolver.resolve(
            overrideKwh = nominalOverrideKwh(),
            chargingCapacityKwh = vd.chargingCapacityKwh,
            catalogueKwh = catalogueKwh,
            remainKwh = vd.remainKwh,
            socPercent = vd.socPercent,
        )
    }

    /**
     * Lifetime fuel consumed, in litres, from the BYD statistic HAL. `NaN` when unavailable —
     * which is the normal case on a BEV.
     *
     * This is a monotonic LIFETIME counter, not a per-trip figure. A trip's litres come from
     * the delta between two readings (BladeWatch-fpdz.7), never from tank percent: percent has
     * no litre scale without a tank capacity, which BYD local data does not expose.
     */
    fun getTotalFuelCon(): Double = getVd()?.totalFuelCon ?: Double.NaN

    /**
     * Lifetime electricity consumed, in kWh, from the BYD statistic HAL — the electric twin of
     * [getTotalFuelCon]. `NaN` when unavailable.
     *
     * Meaningful on BOTH drivetrains. This is the counter that lets a trip shorter than SoC
     * resolution report a real figure instead of a flat zero.
     */
    fun getTotalElecCon(): Double = getVd()?.totalElecCon ?: Double.NaN

    /** Fuel tank level, 0-100. `NaN` on a BEV — the collector only sets it on PHEVs. */
    fun getFuelPercent(): Double = getVd()?.fuelPercent ?: Double.NaN

    private fun isPhevVehicle(nominalCapacityKwh: Double): Boolean {
        try {
            val collector = BydDataCollector.getInstance()
            if (collector.isInitialized) {
                return collector.isPhevVehicle()
            }
        } catch (t: Throwable) {
            logger.debug("isPhevVehicle BydDataCollector check failed: " + t.message)
        }
        // Fallback for early daemon startup, before the fuel HAL probes complete. Same
        // threshold the collector's own capacity gate uses — shared so the two cannot drift.
        return nominalCapacityKwh > 0 && nominalCapacityKwh < BydDataCollector.PHEV_MAX_NOMINAL_KWH
    }

    fun getAllData(): JSONObject {
        val json = JSONObject()
        val vd = getVd()

        try {
            // Battery voltage (old format, for BatteryMonitor compatibility)
            if (vd != null && vd.voltageLevelRaw != BydVehicleData.UNAVAILABLE) {
                val bvJson = JSONObject()
                bvJson.put("level", vd.voltageLevelRaw)
                bvJson.put(
                    "levelName",
                    when (vd.voltageLevelRaw) {
                        1 -> "NORMAL"
                        0 -> "LOW"
                        else -> "INVALID"
                    }
                )
                json.put("batteryVoltage", bvJson)
            }

            // Battery power (old format)
            if (vd != null && !vd.voltage12v.isNaN()) {
                val bpJson = JSONObject()
                bpJson.put("voltageVolts", vd.voltage12v)
                bpJson.put("isWarning", vd.voltage12v < 11.5)
                bpJson.put("isCritical", vd.voltage12v < 10.5)
                bpJson.put(
                    "healthStatus",
                    when {
                        vd.voltage12v < 10.5 -> "CRITICAL"
                        vd.voltage12v < 11.5 -> "WARNING"
                        else -> "NORMAL"
                    }
                )
                json.put("batteryPower", bpJson)
            }

            // Battery SOC (old format)
            if (vd != null && !vd.socPercent.isNaN()) {
                val bsJson = JSONObject()
                bsJson.put("socPercent", vd.socPercent)
                bsJson.put("isLow", vd.socPercent < 20)
                bsJson.put("isCritical", vd.socPercent < 10)
                json.put("batterySoc", bsJson)
            }

            // Charging state — single source of truth via getChargingState(), so this JSON dump
            // matches what the SOC graph sees. The raw BMS field (vd.chargingState) is no
            // longer surfaced standalone because it is known to lag and to misreport on PHEVs.
            val cs = getChargingState()
            if (cs != null) {
                val csJson = JSONObject()
                csJson.put("stateCode", cs.stateCode)
                csJson.put("stateName", cs.stateName)
                csJson.put("status", cs.status.name)
                csJson.put("isError", cs.isError)
                csJson.put("chargingPowerKW", cs.chargingPowerKW)
                csJson.put("isDischarging", cs.isDischarging)
                csJson.put("isEstimated", cs.isEstimated)
                json.put("chargingState", csJson)
            }

            // Driving range (old format)
            if (vd != null && vd.elecRangeKm != BydVehicleData.UNAVAILABLE) {
                val fuelRange =
                    if (vd.fuelRangeKm != BydVehicleData.UNAVAILABLE) vd.fuelRangeKm else 0
                val drJson = JSONObject()
                drJson.put("elecRangeKm", vd.elecRangeKm)
                drJson.put("fuelRangeKm", fuelRange)
                drJson.put("totalRangeKm", vd.elecRangeKm + fuelRange)
                json.put("drivingRange", drJson)
            }

            // Battery thermal (old format)
            if (vd != null && (!vd.highCellTempC.isNaN() || !vd.avgCellTempC.isNaN())) {
                val btJson = JSONObject()
                if (!vd.highCellTempC.isNaN()) btJson.put("highestTempC", vd.highCellTempC)
                if (!vd.lowCellTempC.isNaN()) btJson.put("lowestTempC", vd.lowCellTempC)
                if (!vd.avgCellTempC.isNaN()) btJson.put("averageTempC", vd.avgCellTempC)
                json.put("batteryThermal", btJson)
            }

            json.put("timestamp", System.currentTimeMillis())
        } catch (e: Exception) {
            logger.error("Failed to create JSON", e)
        }

        return json
    }

    fun getAvailability(): Map<String, Boolean> {
        val c = BydDataCollector.getInstance()
        val ready = c.isInitialized
        return hashMapOf(
            "batteryVoltage" to ready,
            "batteryPower" to (ready || batteryPowerMonitor.isAvailable()),
            "batterySoc" to ready,
            "chargingState" to ready,
            "drivingRange" to ready,
            "batteryThermal" to ready,
        )
    }

    // ==================== MONITOR ACCESS (kept for backward compat) ====================

    fun getBatteryPowerMonitor(): BatteryPowerMonitor = batteryPowerMonitor

    // ==================== LISTENER MANAGEMENT ====================

    fun addListener(listener: VehicleDataListener?) {
        if (listener != null && !listeners.contains(listener)) {
            listeners.add(listener)
        }
    }

    fun removeListener(listener: VehicleDataListener?) {
        if (listener != null) listeners.remove(listener)
    }

    /**
     * Deliver one callback to every listener, isolating each from the others.
     *
     * A listener that throws must not stop the remaining listeners from being told — these
     * feed the ACC sentry's MCU control, and a silently skipped notification there is a
     * behaviour change rather than a logged nuisance.
     */
    private inline fun notifyEach(what: String, block: (VehicleDataListener) -> Unit) {
        for (l in listeners) {
            try {
                block(l)
            } catch (e: Exception) {
                logger.warn("listener $what threw: " + e.message)
            }
        }
    }

    fun notifyBatteryVoltageChanged(data: BatteryVoltageData) =
        notifyEach("onBatteryVoltageChanged") { it.onBatteryVoltageChanged(data) }

    fun notifyBatteryPowerChanged(data: BatteryPowerData) =
        notifyEach("onBatteryPowerChanged") { it.onBatteryPowerChanged(data) }

    fun notifyChargingStateChanged(data: ChargingStateData) =
        notifyEach("onChargingStateChanged") { it.onChargingStateChanged(data) }

    fun notifyChargingPowerChanged(powerKW: Double) =
        notifyEach("onChargingPowerChanged") { it.onChargingPowerChanged(powerKW) }

    fun notifyDataUnavailable(monitorName: String, reason: String) =
        notifyEach("onDataUnavailable") { it.onDataUnavailable(monitorName, reason) }

    companion object {
        private const val TAG = "VehicleDataMonitor"
        private val logger = DaemonLogger.getInstance(TAG)

        @Volatile
        private var instance: VehicleDataMonitor? = null

        @JvmStatic
        fun getInstance(): VehicleDataMonitor =
            instance ?: synchronized(this) {
                instance ?: VehicleDataMonitor().also { instance = it }
            }
    }
}
