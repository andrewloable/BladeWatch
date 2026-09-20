package net.bladewatch.app.byd.bodywork

import android.content.Context
import android.hardware.bydauto.bodywork.AbsBYDAutoBodyworkListener

import net.bladewatch.app.byd.EventCallback
import net.bladewatch.app.byd.LogCallback

import org.json.JSONObject

/**
 * Manages BYD Bodywork device and events
 */
class BodyworkManager(
    private val context: Context,
    private val eventCallback: EventCallback,
    private val logCallback: LogCallback?
) {

    private var bodyworkDevice: Any? = null

    var isRegistered: Boolean = false
        private set

    var lastPowerLevel: Int = -1
        private set

    var lastBatteryVoltageLevel: Int = -1
        private set

    var lastBatteryPowerValue: Int = -1
        private set

    fun register() {
        try {
            log("Registering bodywork listener...")

            val bodyworkClass =
                Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice")
            val getInstance = bodyworkClass.getMethod("getInstance", Context::class.java)
            val device = getInstance.invoke(null, context)
            bodyworkDevice = device

            if (device == null) {
                log("ERROR: BYDAutoBodyworkDevice.getInstance() returned null")
                return
            }
            log("Got bodywork device: $device")

            val listener = BodyworkListener()

            val registerListener = bodyworkClass.getMethod(
                "registerListener",
                Class.forName("android.hardware.bydauto.bodywork.AbsBYDAutoBodyworkListener")
            )
            registerListener.invoke(device, listener)

            isRegistered = true
            log("Bodywork listener registered successfully")

            // Get initial states
            fetchInitialPowerLevel(bodyworkClass)
            fetchBatteryInfo(bodyworkClass)
        } catch (e: Exception) {
            log("ERROR registering bodywork listener: " + e.message)
            e.printStackTrace()
        }
    }

    private fun fetchInitialPowerLevel(bodyworkClass: Class<*>) {
        try {
            val getPowerLevel = bodyworkClass.getMethod("getPowerLevel")
            lastPowerLevel = getPowerLevel.invoke(bodyworkDevice) as Int
            log("Initial power level: " + BodyworkConstants.powerLevelToString(lastPowerLevel))
        } catch (e: Exception) {
            log("Could not get initial power level: " + e.message)
        }
    }

    private fun fetchBatteryInfo(bodyworkClass: Class<*>) {
        try {
            // Get battery voltage level (LOW/NORMAL/INVALID)
            val getBatteryVoltageLevel = bodyworkClass.getMethod("getBatteryVoltageLevel")
            lastBatteryVoltageLevel = getBatteryVoltageLevel.invoke(bodyworkDevice) as Int
            log(
                "Battery voltage level: " +
                    BodyworkConstants.batteryLevelToString(lastBatteryVoltageLevel)
            )

            // Get battery power value (0-255, represents 0-25.5V)
            val getBatteryPowerValue = bodyworkClass.getMethod("getBatteryPowerValue")
            lastBatteryPowerValue = getBatteryPowerValue.invoke(bodyworkDevice) as Int
            val voltage = lastBatteryPowerValue / 10.0 // Convert to actual voltage
            log("Battery voltage: " + voltage + "V (raw: " + lastBatteryPowerValue + ")")

            // Broadcast initial battery state
            emit("batteryInfo") {
                put("voltageLevel", lastBatteryVoltageLevel)
                put(
                    "voltageLevelName",
                    BodyworkConstants.batteryLevelToString(lastBatteryVoltageLevel)
                )
                put("powerValue", lastBatteryPowerValue)
                put("voltage", voltage)
            }
        } catch (e: Exception) {
            log("Could not get battery info: " + e.message)
        }
    }

    /** Refresh battery info and broadcast it */
    fun refreshBatteryInfo() {
        val device = bodyworkDevice ?: return
        try {
            fetchBatteryInfo(device.javaClass)
        } catch (e: Exception) {
            log("Error refreshing battery info: " + e.message)
        }
    }

    fun getLastPowerLevelName(): String = BodyworkConstants.powerLevelToString(lastPowerLevel)

    fun getLastBatteryVoltageLevelName(): String =
        BodyworkConstants.batteryLevelToString(lastBatteryVoltageLevel)

    fun getLastBatteryVoltage(): Double = lastBatteryPowerValue / 10.0

    private fun log(message: String) {
        logCallback?.log("[Bodywork] $message")
    }

    /**
     * Build and broadcast one `{type, ..., timestamp}` event. Every listener callback below
     * spelled this same try/put/onEvent/catch block out by hand; the only thing that varied was
     * the type and the two or three fields in between.
     */
    private inline fun emit(type: String, fill: JSONObject.() -> Unit) {
        try {
            val event = JSONObject()
            event.put("type", type)
            event.fill()
            event.put("timestamp", System.currentTimeMillis())
            eventCallback.onEvent(event)
        } catch (e: Exception) {
            log("Error broadcasting $type event: " + e.message)
        }
    }

    // ==================== LISTENER ====================

    private inner class BodyworkListener : AbsBYDAutoBodyworkListener() {

        override fun onPowerLevelChanged(level: Int) {
            log(
                ">>> POWER LEVEL: " + BodyworkConstants.powerLevelToString(level) +
                    " (was: " + BodyworkConstants.powerLevelToString(lastPowerLevel) + ")"
            )
            lastPowerLevel = level

            emit("powerLevel") {
                put("level", level)
                put("levelName", BodyworkConstants.powerLevelToString(level))
            }
        }

        override fun onDoorStateChanged(area: Int, state: Int) {
            log(">>> DOOR: area=" + area + " state=" + (if (state == 1) "OPEN" else "CLOSED"))

            emit("door") {
                put("area", area)
                put("state", state)
                put("open", state == BodyworkConstants.STATE_OPEN)
            }
        }

        override fun onWindowStateChanged(area: Int, state: Int) {
            log(">>> WINDOW: area=" + area + " state=" + (if (state == 1) "OPEN" else "CLOSED"))

            emit("window") {
                put("area", area)
                put("state", state)
                put("open", state == BodyworkConstants.STATE_OPEN)
            }
        }

        override fun onAlarmStateChanged(state: Int) {
            log(">>> ALARM: " + (if (state == 1) "ON" else "OFF"))

            emit("alarm") {
                put("state", state)
                put("active", state == BodyworkConstants.ALARM_ON)
            }
        }

        override fun onAutoSystemStateChanged(state: Int) {
            log(">>> SYSTEM STATE: $state")

            emit("systemState") {
                put("state", state)
            }
        }

        override fun onBatteryVoltageLevelChanged(level: Int) {
            log(">>> BATTERY VOLTAGE: " + BodyworkConstants.batteryLevelToString(level))

            emit("batteryVoltage") {
                put("level", level)
                put("levelName", BodyworkConstants.batteryLevelToString(level))
            }
        }
    }
}
