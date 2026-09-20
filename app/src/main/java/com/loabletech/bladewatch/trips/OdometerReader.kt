package net.bladewatch.app.trips

import android.content.Context
import net.bladewatch.app.logging.DaemonLogger
import java.lang.reflect.Method

/**
 * Reads the vehicle odometer from `BYDAutoStatisticDevice` by reflection.
 *
 * This is the PRIMARY distance source for trip analytics — an exact hardware reading. GPS
 * haversine is only the fallback when the odometer is unavailable.
 */
class OdometerReader private constructor() {

    private var statisticDevice: Any? = null
    private var getTotalMileageValueMethod: Method? = null
    private var initialized = false

    /** Initialise with a Context (a PermissionBypassContext is preferred). Call once at startup. */
    fun init(context: Context) {
        if (initialized) return
        try {
            val deviceClass =
                Class.forName("android.hardware.bydauto.statistic.BYDAutoStatisticDevice")
            statisticDevice = deviceClass.getMethod("getInstance", Context::class.java)
                .invoke(null, context)
            getTotalMileageValueMethod = deviceClass.getMethod("getTotalMileageValue")
            initialized = true
            logger.info("OdometerReader initialized")
        } catch (e: Exception) {
            logger.warn("OdometerReader init failed (odometer unavailable): " + e.message)
        }
    }

    /**
     * Current odometer reading in km, or -1 when unavailable.
     *
     * `getTotalMileageValue()` returns an int whose UNIT varies by model: some report km
     * directly, some report 0.1 km. The magnitude disambiguates them — a value above 1,000,000
     * cannot be kilometres on a road car, so it must be tenths. The result is then scaled by the
     * cluster's distance factor, because a cluster set to miles reports miles here.
     */
    fun readOdometerKm(): Double {
        val device = statisticDevice
        val method = getTotalMileageValueMethod
        if (!initialized || device == null || method == null) return -1.0
        return try {
            val rawOdometer = method.invoke(device) as Int
            if (rawOdometer <= 0) return -1.0

            val value = if (rawOdometer > 1_000_000) rawOdometer / 10.0 else rawOdometer.toDouble()
            val factor = net.bladewatch.app.byd.BydDataCollector.getInstance().distanceToKmFactor
            value * factor
        } catch (e: Exception) {
            logger.debug("Failed to read odometer: " + e.message)
            -1.0
        }
    }

    fun isAvailable(): Boolean = initialized && statisticDevice != null

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("OdometerReader")

        private var instance: OdometerReader? = null

        @JvmStatic
        @Synchronized
        fun getInstance(): OdometerReader =
            instance ?: OdometerReader().also { instance = it }
    }
}
