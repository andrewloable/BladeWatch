package net.bladewatch.app.trips

import net.bladewatch.app.monitor.NominalCapacityResolver

/**
 * One-time repair of trips stored while nominal pack capacity resolved to ~100 kWh
 * (BladeWatch-aa3i, following BladeWatch-x4lf).
 *
 * The BYD "remaining kWh" channel on this car mirrors SoC percent 1:1 rather than reporting
 * energy, so `kwhStart`/`kwhEnd` were written as percentages and everything derived from them —
 * `energyPerKm`, `electricCost`, `tripCost` — came out roughly 5.2x too high on an 18.3 kWh
 * pack. Measured on the device's own trip database: trip 193 stored soc 77 -> 71 with kwh
 * 77.0 -> 71.3 and an efficiency of 0.6417 kWh/km.
 *
 * Pure, with every input injected, because `TripDatabase` needs a live H2 connection and cannot
 * be built on the JVM — the same constraint that shaped [NominalCapacityResolver] and
 * `StorageManager.selectFilesToDelete`.
 *
 * **Idempotent by data, not by a marker file.** [needsCorrection] asks whether the stored energy
 * still mirrors SoC; once repaired it does not, so a second pass skips the row. That survives a
 * database restore, which a marker beside the database would not. Even in the pathological case
 * of a very low SoC — where 2% of an 18.3 kWh pack is 0.37, close enough to 2 to re-trigger —
 * recomputing from the unchanged SoC yields exactly the same numbers.
 */
object TripEnergyMigration {

    /** The repaired figures for one trip. Fuel is carried through untouched. */
    data class Corrected(
        val kwhStart: Double,
        val kwhEnd: Double,
        val energyPerKm: Double,
        val electricCost: Double,
        val tripCost: Double,
    )

    /**
     * Whether this row's stored energy is really the mirrored SoC channel.
     *
     * Both ends must mirror. One end alone is not enough to be confident, and a row with no
     * stored energy at all has nothing to repair.
     */
    @JvmStatic
    fun needsCorrection(
        socStart: Double,
        socEnd: Double,
        kwhStart: Double,
        kwhEnd: Double,
    ): Boolean {
        if (kwhStart <= 0 || kwhEnd <= 0) return false
        return NominalCapacityResolver.looksLikeSocMirror(kwhStart, socStart) &&
            NominalCapacityResolver.looksLikeSocMirror(kwhEnd, socEnd)
    }

    /**
     * Recompute one trip's electric leg from its SoC endpoints and the real pack capacity.
     *
     * The tiering deliberately mirrors `TripRecord.getEnergyUsedKwh` so repaired history sits on
     * the SAME axis as everything recorded since the fix:
     *  1. the NET remaining-energy delta, which is what cost must be based on — you only buy
     *     back what the pack ended up short;
     *  2. zero when the pack ended fuller, rather than a negative that would bill energy put
     *     back by regeneration;
     *  3. the metered GROSS counter only when the net delta cannot answer at all, which on a
     *     1%-resolution SoC is the short-hop case that tier exists for.
     */
    @JvmStatic
    fun correct(
        socStart: Double,
        socEnd: Double,
        distanceKm: Double,
        electricityRate: Double,
        fuelCost: Double,
        meteredEnergyKwh: Double,
        nominalKwh: Double,
    ): Corrected {
        val kwhStart = (socStart / 100.0) * nominalKwh
        val kwhEnd = (socEnd / 100.0) * nominalKwh

        val energyUsed = when {
            kwhStart > kwhEnd -> kwhStart - kwhEnd
            kwhEnd > kwhStart -> 0.0
            else -> if (meteredEnergyKwh > 0) meteredEnergyKwh else 0.0
        }

        val energyPerKm = if (distanceKm > 0) energyUsed / distanceKm else 0.0
        val electricCost = if (energyUsed > 0 && electricityRate > 0) {
            energyUsed * electricityRate
        } else {
            0.0
        }

        return Corrected(
            kwhStart = kwhStart,
            kwhEnd = kwhEnd,
            energyPerKm = energyPerKm,
            electricCost = electricCost,
            // tripCost = electricCost + fuelCost, exactly as TripAnalyticsManager.computeCosts
            // composes it. The fuel leg came from a counter this bug never touched.
            tripCost = electricCost + fuelCost,
        )
    }
}
