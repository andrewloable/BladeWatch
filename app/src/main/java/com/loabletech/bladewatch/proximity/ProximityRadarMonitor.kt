package net.bladewatch.app.proximity

import android.content.Context
import android.hardware.bydauto.radar.AbsBYDAutoRadarListener

import net.bladewatch.app.byd.radar.RadarConstants
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.proximity.ProximityGuardConfig.TriggerLevel

import java.util.Arrays

/**
 * Proximity Radar Monitor
 *
 * Aggregates radar events from all 8 sensors and triggers callbacks
 * when proximity thresholds are crossed.
 *
 * Features:
 * - Monitors all 8 BYD radar sensors
 * - Configurable trigger thresholds (RED only or YELLOW+RED)
 * - Event debouncing to prevent rapid oscillation
 * - Callback interface for state changes
 */
class ProximityRadarMonitor(
    private val context: Context,
    private val triggerLevel: TriggerLevel
) {

    /** Callback interface for proximity trigger events. */
    interface TriggerCallback {
        /**
         * Called when proximity threshold is crossed (safe -> triggered).
         *
         * @param area The radar area that triggered (0-7)
         * @param state The radar state (YELLOW or RED)
         * @param triggerLevel The highest trigger level detected ("YELLOW" or "RED")
         */
        fun onProximityTrigger(area: Int, state: Int, triggerLevel: String)

        /** Called when all sensors return to safe state (triggered -> safe). */
        fun onProximitySafe()
    }

    private var callback: TriggerCallback? = null

    // Radar device and listener
    private var radarDevice: Any? = null
    private var radarListener: RadarListener? = null

    /** Check if currently listening. */
    var isListening: Boolean = false
        private set

    // Sensor state tracking
    private val sensorStates = IntArray(RadarConstants.SENSOR_COUNT) {
        RadarConstants.STATE_SAFE
    }

    /** Check if currently triggered. */
    var isTriggered: Boolean = false
        private set

    // Debouncing
    private var lastTriggerTime: Long = 0
    private var lastSafeTime: Long = 0

    /** Set the trigger callback. */
    fun setCallback(callback: TriggerCallback?) {
        this.callback = callback
    }

    /** Start listening to radar events. */
    fun startListening() {
        if (isListening) {
            logger.warn("Already listening to radar events")
            return
        }

        try {
            logger.info("Starting radar listener...")

            // Get radar device instance
            val radarClass = Class.forName("android.hardware.bydauto.radar.BYDAutoRadarDevice")
            val getInstance = radarClass.getMethod("getInstance", Context::class.java)
            val device = getInstance.invoke(null, context)
            radarDevice = device

            if (device == null) {
                logger.error("BYDAutoRadarDevice.getInstance() returned null")
                return
            }

            // Create and register listener
            val listener = RadarListener()
            radarListener = listener
            val registerListener = radarClass.getMethod(
                "registerListener",
                Class.forName("android.hardware.bydauto.radar.AbsBYDAutoRadarListener")
            )
            registerListener.invoke(device, listener)

            isListening = true
            logger.info("Radar listener registered successfully")
            logger.info(
                "Trigger configuration: level=" + triggerLevel +
                    " (triggers on: " + getTriggerDescription() + ")"
            )

            // Get initial states
            fetchInitialStates(radarClass)
        } catch (e: Exception) {
            logger.error("Failed to start radar listener: " + e.message)
            e.printStackTrace()
        }
    }

    /** Stop listening to radar events. */
    fun stopListening() {
        if (!isListening) {
            return
        }

        try {
            val device = radarDevice
            val listener = radarListener
            if (device != null && listener != null) {
                val unregisterListener = device.javaClass.getMethod(
                    "unregisterListener",
                    Class.forName("android.hardware.bydauto.radar.AbsBYDAutoRadarListener")
                )
                unregisterListener.invoke(device, listener)
                logger.info("Radar listener unregistered")
            }
        } catch (e: Exception) {
            logger.error("Failed to unregister radar listener: " + e.message)
        } finally {
            isListening = false
            radarDevice = null
            radarListener = null
            Arrays.fill(sensorStates, RadarConstants.STATE_SAFE)
            isTriggered = false
        }
    }

    /** Get current sensor states. */
    fun getSensorStates(): IntArray = sensorStates.clone()

    /** Get human-readable description of what triggers recording. */
    private fun getTriggerDescription(): String =
        if (triggerLevel == TriggerLevel.RED) "RED only" else "YELLOW, RED"

    // ==================== PRIVATE METHODS ====================

    private fun fetchInitialStates(radarClass: Class<*>) {
        try {
            val states = radarClass.getMethod("getAllRadarProbeStates")
                .invoke(radarDevice) as IntArray?
            if (states != null) {
                for (i in 0 until minOf(states.size, RadarConstants.SENSOR_COUNT)) {
                    sensorStates[i] = states[i]
                }
                logger.info("Initial radar states: " + Arrays.toString(states))

                // Check if already triggered
                checkTriggerCondition()
            }
        } catch (e: Exception) {
            logger.warn("Could not get initial radar states: " + e.message)
        }
    }

    /** Handle radar state change event. */
    private fun onRadarEvent(area: Int, state: Int) {
        if (area < 0 || area >= RadarConstants.SENSOR_COUNT) {
            logger.warn("Invalid radar area: $area")
            return
        }

        // Log all radar events for debugging
        logger.debug(
            "Radar event: area=" + RadarConstants.areaToString(area) +
                " state=" + RadarConstants.stateToString(state)
        )

        // Update sensor state
        sensorStates[area] = state

        // Check trigger condition
        val wasTriggered = isTriggered
        val nowTriggered = checkTriggerCondition()

        // Log state for debugging
        logger.debug(
            "Trigger check: wasTriggered=$wasTriggered nowTriggered=$nowTriggered " +
                "isTriggered=$isTriggered"
        )

        // Debounce state changes
        val now = System.currentTimeMillis()

        if (nowTriggered && !wasTriggered) {
            // Transition: safe -> triggered
            if (now - lastTriggerTime > DEBOUNCE_MS) {
                isTriggered = true
                lastTriggerTime = now

                val level = getHighestTriggerLevel()
                logger.info(
                    "PROXIMITY TRIGGER: area=" + RadarConstants.areaToString(area) +
                        " state=" + RadarConstants.stateToString(state) +
                        " level=" + level
                )

                callback?.onProximityTrigger(area, state, level)
            } else {
                logger.debug("Trigger debounced (too soon after last trigger)")
            }
        } else if (!nowTriggered && wasTriggered) {
            // Transition: triggered -> safe
            if (now - lastSafeTime > DEBOUNCE_MS) {
                isTriggered = false
                lastSafeTime = now

                logger.info("PROXIMITY SAFE: all sensors returned to non-trigger state")

                callback?.onProximitySafe()
            } else {
                logger.debug("Safe transition debounced (too soon after last safe)")
            }
        }
    }

    /**
     * Check if any sensor meets the trigger condition.
     *
     * Note: ABNORMAL state (1) indicates sensor malfunction or ADAS shutdown (gear=P).
     * We don't trigger on ABNORMAL - it's expected when parking.
     */
    private fun checkTriggerCondition(): Boolean = sensorStates.any { state ->
        when (triggerLevel) {
            // Only trigger on RED
            TriggerLevel.RED -> state == RadarConstants.STATE_RED
            // Trigger on YELLOW or RED
            TriggerLevel.YELLOW_RED ->
                state == RadarConstants.STATE_YELLOW || state == RadarConstants.STATE_RED
        }
    }

    /** Get the highest trigger level currently detected. */
    private fun getHighestTriggerLevel(): String {
        var hasRed = false
        var hasYellow = false

        for (state in sensorStates) {
            if (state == RadarConstants.STATE_RED) {
                hasRed = true
            } else if (state == RadarConstants.STATE_YELLOW) {
                hasYellow = true
            }
        }

        // Priority: RED > YELLOW > SAFE
        return when {
            hasRed -> "RED"
            hasYellow -> "YELLOW"
            else -> "SAFE"
        }
    }

    // ==================== RADAR LISTENER ====================

    private inner class RadarListener : AbsBYDAutoRadarListener() {
        override fun onRadarProbeStateChanged(area: Int, state: Int) {
            onRadarEvent(area, state)
        }

        override fun onReverseRadarSwitchStateChanged(state: Int) {
            // Not used for proximity guard
        }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("ProximityRadarMonitor")

        /** 500ms debounce */
        private const val DEBOUNCE_MS = 500L
    }
}
