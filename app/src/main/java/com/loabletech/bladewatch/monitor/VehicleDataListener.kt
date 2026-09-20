package net.bladewatch.app.monitor

/**
 * Listener for vehicle data updates.
 *
 * Not a `fun interface`: it has five methods, so implementers are classes rather than lambdas.
 */
interface VehicleDataListener {

    /** Battery voltage level changed. */
    fun onBatteryVoltageChanged(data: BatteryVoltageData)

    /** Battery power voltage changed. */
    fun onBatteryPowerChanged(data: BatteryPowerData)

    /** Charging state changed. */
    fun onChargingStateChanged(data: ChargingStateData)

    /** Charging power changed. */
    fun onChargingPowerChanged(powerKW: Double)

    /**
     * A monitor became unavailable.
     *
     * @param monitorName the monitor that failed
     * @param reason why it failed
     */
    fun onDataUnavailable(monitorName: String, reason: String)
}
