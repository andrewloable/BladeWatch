package net.bladewatch.app.monitor

import android.content.Context

import java.util.concurrent.atomic.AtomicReference

import kotlin.math.abs

/**
 * Monitor for 12V battery power voltage.
 *
 * Monitors the actual battery voltage in volts via BYDAutoOtaDevice.
 * Uses reflection and PermissionBypassContext to access real BYD hardware API.
 * Uses polling since OTA device may not support listeners reliably.
 */
class BatteryPowerMonitor : BaseDeviceMonitor<BatteryPowerData>("BatteryPowerMonitor") {

    /** Real BYDAutoOtaDevice from system. */
    private var device: Any? = null
    private val cachedData = AtomicReference<BatteryPowerData?>()
    private var pollThread: Thread? = null

    override fun init(context: Context?) {
        this.context = context

        try {
            log("Initializing BYDAutoOtaDevice via reflection...")

            // Context is already PermissionBypassContext from AccSentryDaemon
            // Get real device via reflection
            val deviceClass = Class.forName("android.hardware.bydauto.ota.BYDAutoOtaDevice")
            val getInstance = deviceClass.getMethod("getInstance", Context::class.java)
            val obtained = getInstance.invoke(null, context)
            device = obtained

            if (obtained == null) {
                logError("BYDAutoOtaDevice.getInstance returned null", null)
                markUnavailable()
                return
            }

            log("Got real BYDAutoOtaDevice: " + obtained.javaClass.name)

            // Get initial value
            try {
                val getBatteryPowerVoltage = deviceClass.getMethod("getBatteryPowerVoltage")
                val initialVoltage = getBatteryPowerVoltage.invoke(obtained) as Double
                cachedData.set(BatteryPowerData(initialVoltage))
                log("Initial battery power voltage: " + initialVoltage + "V")
            } catch (e: Exception) {
                logError("Failed to get initial battery power voltage", e)
            }

            markAvailable()
            log("Initialized successfully")
        } catch (e: Exception) {
            logError("Initialization failed", e)
            markUnavailable()
        }
    }

    override fun start() {
        val dev = device
        if (dev == null) {
            logError("Cannot start - device not initialized", null)
            return
        }

        if (running.getAndSet(true)) {
            log("Already running")
            return
        }

        // Start polling thread
        val thread = Thread({
            log("Polling thread started")

            while (running.get()) {
                try {
                    // Poll voltage via reflection
                    val getBatteryPowerVoltage =
                        dev.javaClass.getMethod("getBatteryPowerVoltage")
                    val voltage = getBatteryPowerVoltage.invoke(dev) as Double

                    val oldData = cachedData.get()
                    val newData = BatteryPowerData(voltage)

                    // Only log if value changed significantly (> 0.1V)
                    if (oldData == null || abs(voltage - oldData.voltageVolts) > 0.1) {
                        log("Battery power voltage: " + voltage + "V")

                        if (newData.isCritical) {
                            log("CRITICAL: Battery voltage is critically low ($voltage" + "V < 10.5V)!")
                        } else if (newData.isWarning) {
                            log("WARNING: Battery voltage is low ($voltage" + "V < 11.5V)")
                        }

                        if (!newData.isValidRange()) {
                            log("WARNING: Battery voltage out of valid range (9.0-16.0V): " + voltage + "V")
                        }
                    }

                    cachedData.set(newData)

                    Thread.sleep(POLL_INTERVAL_MS)
                } catch (e: InterruptedException) {
                    break
                } catch (e: Exception) {
                    logError("Polling error", e)
                    try {
                        Thread.sleep(POLL_INTERVAL_MS)
                    } catch (ie: InterruptedException) {
                        break
                    }
                }
            }

            log("Polling thread stopped")
        }, "BatteryPowerPoll")

        pollThread = thread
        thread.start()
        log("Started successfully (polling mode)")
    }

    override fun stop() {
        if (!running.getAndSet(false)) {
            log("Already stopped")
            return
        }

        cancelRetries()

        pollThread?.let {
            it.interrupt()
            try {
                it.join(1000)
            } catch (e: InterruptedException) {
                log("pollThread.join interrupted during stop")
            }
        }
        pollThread = null

        log("Stopped successfully")
    }

    override fun getCurrentValue(): BatteryPowerData? = cachedData.get()

    override fun getLastUpdateTime(): Long = cachedData.get()?.timestamp ?: 0

    companion object {
        /** Poll every 5 min (collector handles frequent reads). */
        private const val POLL_INTERVAL_MS = 300000L
    }
}
