package net.bladewatch.app.monitor

import kotlin.math.abs

/**
 * Pure resolution of the vehicle's nominal traction-pack capacity in kWh (BladeWatch-x4lf).
 *
 * Split out of [VehicleDataMonitor.getNominalCapacityKwh] with every input injected, because
 * that class is a private-constructor singleton over live BYD data and cannot be constructed
 * on the JVM — the same constraint that shaped `StorageManager.selectFilesToDelete`.
 *
 * This value multiplies a SoC delta into kWh, so it feeds every trip's energy, cost and
 * efficiency figure, and `BydDataCollector.decideDrivetrain`'s PHEV/BEV classification. A
 * wrong-but-plausible number here is invisible downstream, which is exactly how it went
 * unnoticed: see [looksLikeSocMirror].
 */
object NominalCapacityResolver {

    /**
     * SoC is integer-quantised and the mirrored channel tracks it to well under a point, so a
     * tolerance of 2 comfortably separates "mirror" from a real energy reading, which is a
     * different order of magnitude at any realistic state of charge.
     */
    internal const val SOC_MIRROR_TOLERANCE = 2.0

    /** Below this there is not enough charge for `remain / (soc/100)` to be meaningful. */
    internal const val MIN_TRUSTWORTHY_SOC = 5.0

    /**
     * Bounds on a user-set override, inherited from the REST contract that advertised it
     * (`POST /api/performance/soh/nominal`, "Validates 8-120 kWh range"). The smallest BYD
     * traction pack in the catalogue is 8.3 kWh and the largest is 108.8. The point is not
     * precision, it is that a typo must not be able to redefine the pack as 1.83 or 1830 and
     * silently corrupt every trip from then on.
     */
    internal const val MIN_OVERRIDE_KWH = 8.0
    internal const val MAX_OVERRIDE_KWH = 120.0

    /**
     * How far the SDK's capacity may sit from the catalogue and still be believed.
     *
     * ponytail: a judgement call, not a measured value — revisit it if a real BYD trim turns up
     * whose battery options differ by more than this. It is wide enough to cover a battery
     * option within one trim, and it bounds the error rather than eliminating it: a wrong value
     * that lands inside the band is still accepted. For an 18.3 kWh catalogue entry the band is
     * 9.2-27.5, so a percentage reading taken between roughly 9% and 27% SoC passes. That is a
     * ~9% error at worst, against the 5.2x error this whole class of bug produced unguarded, and
     * tightening further starts rejecting genuine per-vehicle variation. The catalogue remains
     * the fallback whenever this refuses.
     */
    internal const val CATALOGUE_AGREEMENT_TOLERANCE = 0.5

    /**
     * True when the "remaining kWh" channel is really mirroring SoC percent instead of
     * reporting energy.
     *
     * Measured on a Seal 5 DM-i (963 SoC-history rows, 2026-09-19): soc=73/remain=72.9,
     * soc=77/remain=77.0, soc=79/remain=78.8 — a 1:1 track across the whole range. Dividing
     * that by `soc/100` yields ~100 for ANY pack, and ~100 kWh reads as a perfectly plausible
     * BEV capacity, so nothing downstream flagged it. On this 18.3 kWh PHEV it inflated every
     * energy, cost and efficiency figure by ~5.2x and pinned the efficiency score at 0.
     *
     * A genuine ~100 kWh pack would also trip this check. That is deliberate: the cost of a
     * false positive is one honest "unknown", while a false negative silently corrupts every
     * trip the owner will ever record.
     */
    @JvmStatic
    fun looksLikeSocMirror(remainKwh: Double, socPercent: Double): Boolean {
        if (remainKwh.isNaN() || socPercent.isNaN()) return false
        return abs(remainKwh - socPercent) <= SOC_MIRROR_TOLERANCE
    }

    /**
     * Nominal pack capacity in kWh, or 0.0 when it genuinely cannot be determined.
     *
     * Priority:
     *  0. [overrideKwh] — a value the owner set explicitly. It outranks everything, because
     *     every other source here is inference and this one is not (BladeWatch-b9vl).
     *  1. [chargingCapacityKwh], but only when it does not contradict [catalogueKwh] — see
     *     [agreesWithCatalogue]. A per-vehicle figure should outrank a per-trim constant
     *     because a trim can ship more than one battery option; what it must not do is
     *     redefine the pack as something the trim could not be.
     *  2. [catalogueKwh] — `nominalKwh` for the configured `vehicle.modelId` from
     *     `models/manifest.json`. Authoritative per trim, and it does not depend on any live
     *     signal being interpreted correctly.
     *  3. Derived `remainKwh / (soc/100)`, but only when the kWh channel is real energy.
     *
     * 0.0 means unknown and callers must treat it as such. Returning a fabricated capacity to
     * avoid an empty figure is what produced the original defect.
     */
    /**
     * Remaining energy in kWh to trust when there is NO nominal capacity to cross-check it
     * against, or 0.0 for unknown.
     *
     * BladeWatch-ofe9. `VehicleDataMonitor.getBatteryRemainPowerKwh` ends with "no nominal
     * capacity: use the raw BMS value if available", and `nominal == 0.0` is exactly the honest
     * "unknown" that [resolve] now returns. Passing the raw value through there converts that
     * unknown straight back into the mirrored number the whole fix exists to eliminate — on
     * this car, roughly 5.4x too high.
     *
     * It fires when the catalogue cannot answer: an unlisted or unset `vehicle.modelId`, or
     * early boot before the web assets holding `models/manifest.json` have been extracted.
     */
    @JvmStatic
    fun trustworthyRemainKwh(rawKwh: Double, socPercent: Double): Double {
        if (rawKwh.isNaN() || rawKwh <= 0) return 0.0
        if (looksLikeSocMirror(rawKwh, socPercent)) return 0.0
        return rawKwh
    }

    /**
     * Whether a user-set override is a real pack size and should be honoured.
     *
     * 0 and NaN both mean "not set" — clearing the override falls back to auto-detection rather
     * than pinning the pack at zero.
     */
    @JvmStatic
    fun isUsableOverride(overrideKwh: Double): Boolean {
        if (overrideKwh.isNaN()) return false
        return overrideKwh >= MIN_OVERRIDE_KWH && overrideKwh <= MAX_OVERRIDE_KWH
    }

    /**
     * Which source [resolve] answers from, for the `nominalSource` field the SOH endpoints
     * report (BladeWatch-b9vl).
     *
     * Derived from the SAME inputs and in the same order as [resolve], because `GetSohNominal`
     * used to return a hardcoded "unset" while a capacity was demonstrably known. A source
     * computed anywhere other than alongside the value drifts from it.
     */
    @JvmStatic
    fun sourceOf(
        overrideKwh: Double,
        chargingCapacityKwh: Double,
        catalogueKwh: Double,
        remainKwh: Double,
        socPercent: Double,
    ): String {
        if (isUsableOverride(overrideKwh)) return "user"
        val sdkAnswered = !chargingCapacityKwh.isNaN() && chargingCapacityKwh > 0
        if (sdkAnswered && (catalogueKwh <= 0 || agreesWithCatalogue(chargingCapacityKwh, catalogueKwh))) {
            return "sdk"
        }
        if (catalogueKwh > 0) return "catalogue"
        val soc = if (socPercent.isNaN()) 0.0 else socPercent
        val rawKwh = if (remainKwh.isNaN()) 0.0 else remainKwh
        if (rawKwh > 0 && soc > MIN_TRUSTWORTHY_SOC && !looksLikeSocMirror(rawKwh, soc)) {
            return "derived"
        }
        return "unset"
    }

    /**
     * Whether the SDK's capacity is close enough to the trim's catalogue value to be believed.
     *
     * [chargingCapacityKwh] is NOT a verified pack-spec field (BladeWatch-phim). Both of its
     * writers in `BydDataCollector` accept it unvalidated — the poll on `> 0`, the
     * `onChargingCapacityChanged` callback on `0 < cap < 200`, a window that admits the entire
     * 0-100 percentage range — and that callback's own comment describes the event as "purely
     * diagnostic for charging session size". Taking it on trust was the same mistake as
     * trusting the mirrored kWh channel: a plausibly-named signal used without checking it
     * against a known-good reference.
     */
    @JvmStatic
    fun agreesWithCatalogue(sdkKwh: Double, catalogueKwh: Double): Boolean {
        if (sdkKwh.isNaN() || catalogueKwh <= 0) return false
        return sdkKwh >= catalogueKwh * (1 - CATALOGUE_AGREEMENT_TOLERANCE) &&
            sdkKwh <= catalogueKwh * (1 + CATALOGUE_AGREEMENT_TOLERANCE)
    }

    @JvmStatic
    fun resolve(
        overrideKwh: Double,
        chargingCapacityKwh: Double,
        catalogueKwh: Double,
        remainKwh: Double,
        socPercent: Double,
    ): Double {
        if (isUsableOverride(overrideKwh)) return overrideKwh
        val sdkAnswered = !chargingCapacityKwh.isNaN() && chargingCapacityKwh > 0
        if (sdkAnswered && (catalogueKwh <= 0 || agreesWithCatalogue(chargingCapacityKwh, catalogueKwh))) {
            return chargingCapacityKwh
        }
        if (catalogueKwh > 0) return catalogueKwh

        val soc = if (socPercent.isNaN()) 0.0 else socPercent
        val rawKwh = if (remainKwh.isNaN()) 0.0 else remainKwh
        if (rawKwh > 0 && soc > MIN_TRUSTWORTHY_SOC && !looksLikeSocMirror(rawKwh, soc)) {
            return rawKwh / (soc / 100.0)
        }
        return 0.0
    }
}
