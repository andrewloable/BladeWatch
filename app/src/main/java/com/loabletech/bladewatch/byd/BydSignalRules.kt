package net.bladewatch.app.byd

import kotlin.math.abs

/**
 * The pure decision rules that turn raw BYD HAL readings into trustworthy values.
 *
 * **Why this exists.** `BydDataCollector` is ~5,500 lines in which these rules were inlined
 * among reflection calls, so none of them could be tested: exercising a single range check
 * meant standing up a BYD device. Every rule here encodes a specific, hard-won fact about BYD
 * firmware — a scale that differs between models, a sentinel that means "no data", a value
 * that is physically impossible and therefore garbage — and each is a place where an off-by-one
 * or a transposed digit corrupts vehicle telemetry silently, with nothing to catch it.
 *
 * Splitting them out changes no behaviour. It makes them testable, which they were not.
 *
 * Every function is total: it takes a raw reading and returns either a usable value or an
 * explicit "no reading" ([NO_VALUE] / null). None of them throw, because a drivetrain or
 * telemetry probe must never propagate a failure into the collector.
 */
object BydSignalRules {

    /** Returned when a raw reading is unusable. Matches `BydVehicleData.UNAVAILABLE`. */
    const val NO_VALUE: Int = Int.MIN_VALUE

    // ── sentinels ────────────────────────────────────────────────────────────────

    /**
     * Values a BYD fuel getter returns to mean "there is no fuel system here".
     *
     * These are CAN-bus all-ones patterns at various widths (8-bit 255, 9-bit 511, 10-bit
     * 1023, 11-bit 2047, 12-bit 4095, 16-bit 65535) plus the one-below variants some
     * firmwares use for "signal invalid" as distinct from "not present".
     */
    @JvmStatic
    fun isBevFuelSentinel(v: Int): Boolean =
        v == 255 || v == 254 || v == 511 || v == 1023 ||
            v == 2046 || v == 2047 || v == 4095 ||
            v == 65534 || v == 65535

    // ── 12V auxiliary battery ────────────────────────────────────────────────────

    /**
     * 12V battery voltage from `getBatteryPowerValue`, or null when implausible.
     *
     * The getter is dual-scale: some firmware reports decivolts (0-255 for 0-25.5V), some
     * reports volts directly. A reading above 100 can only be the decivolt scale, because no
     * 12V system reads 100V.
     *
     * The 8-16V window is the physical envelope of a lead-acid 12V bus: below 8V the car
     * cannot crank, above 16V the alternator would be destroying the battery. Anything outside
     * it is a HAL glitch, not a measurement — and this is the reading that gates ACC-off
     * sentry shutdown, so accepting garbage here strands the car.
     */
    @JvmStatic
    fun scale12vVoltage(raw: Double): Double? {
        if (raw.isNaN()) return null
        val volts = if (raw > 100) raw / 10.0 else raw
        return if (volts >= 8.0 && volts <= 16.0) volts else null
    }

    // ── traction pack cells ──────────────────────────────────────────────────────

    /**
     * Cell temperature in Celsius from a raw statistic reading, or null when unusable.
     *
     * BYD encodes cell temperature with a +40 offset so the wire value stays unsigned: raw 0
     * is -40C, raw 120 is +80C. The 0..120 window is therefore the full representable range,
     * and a value outside it is a sentinel or noise rather than an extreme temperature.
     */
    @JvmStatic
    fun cellTempC(raw: Int): Double? {
        if (raw == NO_VALUE || isInvalidSentinel(raw)) return null
        if (raw < 0 || raw > 120) return null
        return (raw - 40).toDouble()
    }

    /**
     * Single-cell voltage in volts from a raw millivolt reading, or null when unusable.
     *
     * The 1.0-5.0V window brackets every chemistry BYD ships: LFP rests near 3.2V and tops at
     * 3.65V, NMC tops at 4.2V. A cell outside this range is not a cell reading — it is a pack
     * voltage, a sentinel, or garbage.
     */
    @JvmStatic
    fun cellVoltage(rawMillivolts: Int): Double? {
        if (rawMillivolts == NO_VALUE || isInvalidSentinel(rawMillivolts)) return null
        if (rawMillivolts <= 0) return null
        val volts = rawMillivolts / 1000.0
        return if (volts >= 1.0 && volts <= 5.0) volts else null
    }

    // ── power flow ───────────────────────────────────────────────────────────────

    /**
     * Net HV-bus power in kW, or null when implausible.
     *
     * Sign convention: positive is motor draw, negative is current flowing INTO the pack —
     * regen while driving, plug-in charging while parked. That sign is load-bearing:
     * `ChargingDetector` uses a negative reading as charging evidence on PHEVs whose BMS
     * reports a stuck IDLE state.
     *
     * Dual-scale like the 12V reading: some firmware reports deciwatts x10, so a magnitude
     * above 100 is scaled down. The -200..400 envelope covers every BYD drivetrain (the
     * largest is roughly 400 kW peak) while excluding the sentinels.
     */
    @JvmStatic
    fun enginePowerKw(raw: Double): Double? {
        if (raw.isNaN()) return null
        if (raw < -200.0 || raw > 400.0) return null
        return if (abs(raw) > 100.0) raw * 0.1 else raw
    }

    /**
     * External (charger-reported) charging power in kW, or null when implausible.
     *
     * Two scaling regimes seen across BYD firmware, and telling them apart is the whole job:
     *  - the listener path pre-scales to kW;
     *  - the polled getter on some PHEV firmware returns the raw CAN value in hectowatts
     *    (observed: 221.7 raw for a real ~1.9 kW charger).
     *
     * The discriminator is physical reality. AC charging tops out near 22 kW on 3-phase and a
     * PHEV onboard charger maxes around 7 kW, so anything above 50 from a getter that is
     * supposed to be kW must be the hectowatt scale. BYD's 104857.5 sentinel falls cleanly
     * above the 50000 cap and is rejected rather than scaled.
     */
    @JvmStatic
    fun externalChargingPowerKw(raw: Double): Double? {
        if (raw.isNaN()) return null
        val kw = if (raw > 50.0 && raw < 50000.0) raw / 100.0 else raw
        return if (kw > 0.1 && kw <= 500.0) kw else null
    }

    /** True when [raw] came from the hectowatt scale — for the one-shot diagnostic log. */
    @JvmStatic
    fun isHectowattScale(raw: Double): Boolean = raw > 50.0 && raw < 50000.0

    // ── remaining pack energy ────────────────────────────────────────────────────

    /**
     * Whether a remaining-kWh reading is consistent with the reported SoC.
     *
     * Implied capacity is `kwh / (soc/100)`. Every BYD pack falls between roughly 10 kWh
     * (a DM-i plug-in) and 130 kWh, so a reading implying something outside that is the BMS
     * returning garbage — common on Seal and Han EV once ACC is off.
     *
     * This check is what stopped a real regression: on Seal, one source reported 16.5 kWh
     * (correct — 82.5 kWh nominal at 20% SoC) while another reported 20.6 kWh (implying
     * 103 kWh), and the wrong one poisoned every downstream auto-detection.
     *
     * @param soc state of charge 0-100; readings at or below 5% cannot validate anything
     *   because the division amplifies noise without bound
     */
    @JvmStatic
    fun isRemainKwhConsistentWithSoc(kwh: Double, soc: Double): Boolean {
        if (kwh.isNaN() || soc.isNaN() || soc <= 5) return false
        val impliedCapacity = kwh / (soc / 100.0)
        return impliedCapacity >= 10 && impliedCapacity <= 130
    }

    /** Plausible remaining energy for any BYD model, before SoC cross-validation. */
    @JvmStatic
    fun isPlausibleRemainKwh(kwh: Double): Boolean = !kwh.isNaN() && kwh > 1.0 && kwh < 120.0

    /**
     * Whether `getBatteryCapacity` is reporting a static Ah rating rather than remaining
     * energy in 0.1 kWh units.
     *
     * The getter's meaning varies by model, and confusing the two writes an Ah number scaled
     * by 10 into a kWh field. The 50-350 Ah window is the giveaway: a fixed pack rating (150
     * for an Atto 3) versus a value that moves with SoC.
     */
    @JvmStatic
    fun looksLikeAhRating(capValue: Double): Boolean = capValue >= 50 && capValue <= 350

    // ── charging state ───────────────────────────────────────────────────────────

    /**
     * Whether a BMS charging state explicitly means "the session is over".
     *
     * READY(0), FINISHED(2), TERMINATED(4) and DISCHARG_FINISH(12) are unambiguous, so sticky
     * listener-delivered power can be cleared on them.
     *
     * **IDLE(15) is deliberately NOT in this set.** That is the buggy reading some PHEV
     * firmwares give *while actually charging*; treating it as terminal is what broke charge
     * detection on those cars in the first place.
     */
    @JvmStatic
    fun isTerminalChargingState(state: Int): Boolean =
        state == 0 || state == 2 || state == 4 || state == 12

    /** Gun states that assert a connected AC or DC charger. */
    @JvmStatic
    fun isChargingGunConnected(gunState: Int): Boolean =
        gunState == 2 || gunState == 3 || gunState == 4 || gunState == 5

    /**
     * Whether the car might be charging while ACC is off, and therefore whether engine power
     * is still worth collecting.
     *
     * Deliberately permissive: a false positive costs one extra HAL read, a false negative
     * loses the most authoritative charging signal available on a PHEV (current flowing into
     * the pack reads negative on the engine bus) exactly when `chargingGunState` is
     * UNAVAILABLE and `chargingState` is stuck at IDLE.
     */
    @JvmStatic
    fun possiblyChargingWhileParked(
        chargingPowerKw: Double,
        externalChargingPowerKw: Double,
        chargingState: Int,
        chargingGunState: Int,
    ): Boolean =
        (!chargingPowerKw.isNaN() && abs(chargingPowerKw) > 0.1) ||
            (!externalChargingPowerKw.isNaN() && externalChargingPowerKw > 0.1) ||
            chargingState == 1 || // BMS explicitly says CHARGING
            isChargingGunConnected(chargingGunState)

    /** Vehicle-to-load: asserted by either the gun state or the charging type. */
    @JvmStatic
    fun isVtolCharging(gunState: Int, chargingType: Int): Boolean =
        gunState == 5 || chargingType == 3

    // ── door locks ───────────────────────────────────────────────────────────────

    /**
     * Convert an SDK lock state to the web API's lock state.
     *
     * **The two are inverted and that is not a bug.** The BYD SDK reports 1=unlock, 2=lock;
     * the web API has historically exposed 1=locked, 2=unlocked. Collection converts at the
     * boundary so exactly one place has to know, and this is that place.
     *
     * @return [LOCK_API_LOCKED], [LOCK_API_UNLOCKED], or [LOCK_API_UNKNOWN]
     */
    @JvmStatic
    fun lockSdkToApi(sdkState: Int): Int = when (sdkState) {
        LOCK_SDK_LOCKED -> LOCK_API_LOCKED
        LOCK_SDK_UNLOCKED -> LOCK_API_UNLOCKED
        else -> LOCK_API_UNKNOWN // includes LOCK_SDK_INVALID
    }

    const val LOCK_API_UNKNOWN: Int = -1
    const val LOCK_API_LOCKED: Int = 1
    const val LOCK_API_UNLOCKED: Int = 2
    const val LOCK_SDK_INVALID: Int = 0
    const val LOCK_SDK_UNLOCKED: Int = 1
    const val LOCK_SDK_LOCKED: Int = 2

    /**
     * Aggregate the four door locks into one "is the car locked?" verdict.
     *
     * The asymmetry is deliberate and is the whole point:
     *  - **any** door reading UNLOCKED makes the car UNLOCKED, immediately;
     *  - a single UNKNOWN door makes the whole verdict UNKNOWN, never LOCKED;
     *  - only all four reading LOCKED yields LOCKED.
     *
     * In other words this never reports LOCKED on partial information. Surveillance arming
     * keys off this value, so a false LOCKED is the expensive direction — it would arm a
     * sentry on a car standing open — while a false UNKNOWN merely declines to act.
     *
     * @param locks at least four entries, in API semantics (see [lockSdkToApi])
     */
    @JvmStatic
    fun deriveOverallLock(locks: IntArray): Int {
        if (locks.size < 4) return LOCK_API_UNKNOWN
        var sawLockedDoor = false
        for (i in 0 until 4) {
            if (locks[i] == LOCK_API_UNLOCKED) return LOCK_API_UNLOCKED
            if (locks[i] != LOCK_API_LOCKED) return LOCK_API_UNKNOWN
            sawLockedDoor = true
        }
        return if (sawLockedDoor) LOCK_API_LOCKED else LOCK_API_UNKNOWN
    }

    // ── seats ────────────────────────────────────────────────────────────────────

    /**
     * Normalise a seat heat/vent level from the SDK's 1-based scale to the wire format's
     * 0-based one: SDK 1=off/2=low/3=high becomes 0/1/2.
     *
     * @return the normalised level, or -1 when the firmware does not support the getter
     */
    @JvmStatic
    fun normalizeSeatGetterLevel(raw: Int): Int {
        if (raw == NO_VALUE) return -1
        val normalized = raw - 1
        return if (normalized in 0..2) normalized else -1
    }

    // ── units ────────────────────────────────────────────────────────────────────

    /** Miles to kilometres. BYD getters return values in the cluster's configured unit. */
    const val MILES_TO_KM: Double = 1.60934

    /**
     * Distance conversion factor from the cluster's `getMileageUnit`: 1 means km, 0 means
     * miles. Any other value is treated as km, because km is the safe default — over-reporting
     * distance by 60% would corrupt every trip and every consumption bucket.
     */
    @JvmStatic
    fun distanceFactorForMileageUnit(unit: Int): Double =
        if (unit == 0) MILES_TO_KM else 1.0

    // ── shared sentinel test ─────────────────────────────────────────────────────

    /**
     * The BMS/feature-id sentinels shared across statistic reads. Mirrors the constants in
     * `BydFeatureIds`; kept as a single predicate so every call site rejects the same set.
     */
    private fun isInvalidSentinel(raw: Int): Boolean =
        raw == BydFeatureIds.BMS_UNAVAILABLE ||
            raw == BydFeatureIds.INVALID_VALUE ||
            raw == BydFeatureIds.INVALID_VALUE_2
}
