package net.bladewatch.app.monitor

/**
 * Data model for the battery charging state and power, as reported by BYDAutoChargingDevice.
 * Includes error detection for breakdown states and discharging detection.
 *
 * @param stateCode the raw state code from BYDAutoChargingDevice
 */
class ChargingStateData(@JvmField val stateCode: Int) {

    enum class ChargingStatus {
        READY, CHARGING, FINISHED, TERMINATED,
        DISCHARGING, SCHEDULED, TIMEOUT, ERROR,
        IDLE, UNKNOWN
    }

    /** Human-readable name. */
    @JvmField
    val stateName: String = interpretStateName(stateCode)

    @JvmField
    val status: ChargingStatus = interpretStatus(stateCode)

    /** True for breakdown states. */
    @JvmField
    val isError: Boolean = isBreakdownState(stateCode)

    /** "AC", "CHARGER", "GUN", "C10", or null. */
    @JvmField
    val errorType: String? = getErrorType(stateCode)

    /** Current charging power in kW (negative = discharging). */
    @JvmField
    var chargingPowerKW: Double = 0.0

    /** True if the power is negative. */
    @JvmField
    var isDischarging: Boolean = false

    /** True if the power is computed from the SOC rate rather than read from the BYD API. */
    @JvmField
    var isEstimated: Boolean = false

    @JvmField
    val timestamp: Long = System.currentTimeMillis()

    /** Update the charging power and the discharging flag. */
    fun updateChargingPower(powerKW: Double) {
        chargingPowerKW = powerKW
        updateDischargingFlag()
    }

    /** Update the discharging flag from the current power value. */
    fun updateDischargingFlag() {
        isDischarging = chargingPowerKW < 0
    }

    override fun toString(): String =
        "ChargingStateData{" +
            "stateCode=" + stateCode +
            ", stateName='" + stateName + '\'' +
            ", status=" + status +
            ", isError=" + isError +
            ", errorType='" + errorType + '\'' +
            ", chargingPowerKW=" + chargingPowerKW +
            ", isDischarging=" + isDischarging +
            ", timestamp=" + timestamp +
            '}'

    companion object {
        // Charging state constants from BYDAutoChargingDevice
        const val CHARGING_BATTERY_STATE_READY = 0
        const val CHARGING_BATTERY_STATE_CHARGING = 1
        const val CHARGING_BATTERY_STATE_CHARG_FINISH = 2
        const val CHARGING_BATTERY_STATE_DISCHARG = 3
        const val CHARGING_BATTERY_STATE_CHARG_TERMINATE = 4
        const val CHARGING_BATTERY_STATE_BREAKDOWN_C10 = 5
        const val CHARGING_BATTERY_STATE_BREAKDOWN_CHARGING_GUN = 6
        const val CHARGING_BATTERY_STATE_BREAKDOWN_AC = 7
        const val CHARGING_BATTERY_STATE_BREAKDOWN_CHARGER = 8
        const val CHARGING_BATTERY_STATE_SCHEDULE = 9
        const val CHARGING_BATTERY_STATE_TIMEOUT = 10
        const val CHARGING_BATTERY_STATE_DISCHARG_CBU = 11
        const val CHARGING_BATTERY_STATE_DISCHARG_FINISH = 12

        /** Idle — not plugged in. Observed in newer BYD firmware; undocumented. */
        const val CHARGING_BATTERY_STATE_IDLE = 15

        /** Interpret a state code as a human-readable name. */
        private fun interpretStateName(stateCode: Int): String = when (stateCode) {
            CHARGING_BATTERY_STATE_READY -> "Ready"
            CHARGING_BATTERY_STATE_CHARGING -> "Charging"
            CHARGING_BATTERY_STATE_CHARG_FINISH -> "Charge Finished"
            CHARGING_BATTERY_STATE_DISCHARG -> "Discharging"
            CHARGING_BATTERY_STATE_CHARG_TERMINATE -> "Charge Terminated"
            CHARGING_BATTERY_STATE_BREAKDOWN_C10 -> "Breakdown: C10"
            CHARGING_BATTERY_STATE_BREAKDOWN_CHARGING_GUN -> "Breakdown: Charging Gun"
            CHARGING_BATTERY_STATE_BREAKDOWN_AC -> "Breakdown: AC"
            CHARGING_BATTERY_STATE_BREAKDOWN_CHARGER -> "Breakdown: Charger"
            CHARGING_BATTERY_STATE_SCHEDULE -> "Scheduled"
            CHARGING_BATTERY_STATE_TIMEOUT -> "Timeout"
            CHARGING_BATTERY_STATE_DISCHARG_CBU -> "Discharging CBU"
            CHARGING_BATTERY_STATE_DISCHARG_FINISH -> "Discharge Finished"
            CHARGING_BATTERY_STATE_IDLE -> "Idle"
            else -> "Unknown ($stateCode)"
        }

        /** Interpret a state code as an enum status. */
        private fun interpretStatus(stateCode: Int): ChargingStatus = when (stateCode) {
            CHARGING_BATTERY_STATE_READY -> ChargingStatus.READY
            CHARGING_BATTERY_STATE_CHARGING -> ChargingStatus.CHARGING
            CHARGING_BATTERY_STATE_CHARG_FINISH -> ChargingStatus.FINISHED
            CHARGING_BATTERY_STATE_CHARG_TERMINATE -> ChargingStatus.TERMINATED
            CHARGING_BATTERY_STATE_DISCHARG,
            CHARGING_BATTERY_STATE_DISCHARG_CBU,
            CHARGING_BATTERY_STATE_DISCHARG_FINISH -> ChargingStatus.DISCHARGING
            CHARGING_BATTERY_STATE_SCHEDULE -> ChargingStatus.SCHEDULED
            CHARGING_BATTERY_STATE_TIMEOUT -> ChargingStatus.TIMEOUT
            CHARGING_BATTERY_STATE_BREAKDOWN_C10,
            CHARGING_BATTERY_STATE_BREAKDOWN_CHARGING_GUN,
            CHARGING_BATTERY_STATE_BREAKDOWN_AC,
            CHARGING_BATTERY_STATE_BREAKDOWN_CHARGER -> ChargingStatus.ERROR
            CHARGING_BATTERY_STATE_IDLE -> ChargingStatus.IDLE
            else -> ChargingStatus.UNKNOWN
        }

        /** Whether a state code represents a breakdown condition. */
        private fun isBreakdownState(stateCode: Int): Boolean =
            stateCode == CHARGING_BATTERY_STATE_BREAKDOWN_C10 ||
                stateCode == CHARGING_BATTERY_STATE_BREAKDOWN_CHARGING_GUN ||
                stateCode == CHARGING_BATTERY_STATE_BREAKDOWN_AC ||
                stateCode == CHARGING_BATTERY_STATE_BREAKDOWN_CHARGER

        /** The error type for breakdown states. */
        private fun getErrorType(stateCode: Int): String? = when (stateCode) {
            CHARGING_BATTERY_STATE_BREAKDOWN_AC -> "AC"
            CHARGING_BATTERY_STATE_BREAKDOWN_CHARGER -> "CHARGER"
            CHARGING_BATTERY_STATE_BREAKDOWN_CHARGING_GUN -> "GUN"
            CHARGING_BATTERY_STATE_BREAKDOWN_C10 -> "C10"
            else -> null
        }
    }
}
