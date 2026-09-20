package net.bladewatch.app.byd

import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONArray
import org.json.JSONObject

import kotlin.math.roundToLong

/**
 * Immutable snapshot of all BYD vehicle data.
 * Thread-safe — created via Builder, read from any thread.
 */
class BydVehicleData private constructor(b: Builder) {

    // ==================== IDENTITY ====================
    @JvmField val vin: String? = b.vin

    // ==================== BATTERY ====================
    @JvmField val socPercent: Double = b.socPercent  // 0-100
    @JvmField val socHevPercent: Double = b.socHevPercent  // HEV SOC
    @JvmField val capacityAh: Double = b.capacityAh
    @JvmField val remainKwh: Double = b.remainKwh  // remaining energy
    @JvmField val voltage12v: Double = b.voltage12v  // 12V battery volts
    @JvmField val voltageLevelRaw: Int = b.voltageLevelRaw  // LOW/NORMAL/INVALID

    // ==================== THERMAL ====================
    @JvmField val highCellTempC: Double = b.highCellTempC  // highest cell temp (°C)
    @JvmField val lowCellTempC: Double = b.lowCellTempC  // lowest cell temp (°C)
    @JvmField val avgCellTempC: Double = b.avgCellTempC  // average pack temp (°C)
    @JvmField val waterTempC: Double = b.waterTempC  // coolant temp
    @JvmField val outsideTempC: Double = b.outsideTempC  // external temp
    @JvmField val insideTempC: Double = b.insideTempC  // cabin temp
    @JvmField val bodyworkBattTempC: Double = b.bodyworkBattTempC  // battery temp from bodywork device

    // ==================== CELL VOLTAGE ====================
    @JvmField val highCellVoltage: Double = b.highCellVoltage  // V
    @JvmField val lowCellVoltage: Double = b.lowCellVoltage  // V

    // ==================== SPEED ====================
    @JvmField val speedKmh: Double = b.speedKmh
    @JvmField val accelPercent: Int = b.accelPercent
    @JvmField val brakePercent: Int = b.brakePercent

    // ==================== MOTOR ====================
    @JvmField val frontMotorSpeed: Int = b.frontMotorSpeed  // RPM (negated from SDK)
    @JvmField val rearMotorSpeed: Int = b.rearMotorSpeed  // RPM
    @JvmField val frontMotorTorque: Double = b.frontMotorTorque  // Nm (negated from SDK)
    @JvmField val engineSpeedRpm: Int = b.engineSpeedRpm
    @JvmField val enginePowerKw: Double = b.enginePowerKw

    // ==================== ENERGY ====================
    @JvmField val energyMode: Int = b.energyMode  // EV/HEV
    @JvmField val operationMode: Int = b.operationMode  // ECO/SPORT/NORMAL
    @JvmField val totalElecCon: Double = b.totalElecCon  // total electricity consumed
    @JvmField val totalFuelCon: Double = b.totalFuelCon  // total fuel consumed

    // ==================== RANGE ====================
    @JvmField val elecRangeKm: Int = b.elecRangeKm
    @JvmField val fuelRangeKm: Int = b.fuelRangeKm
    @JvmField val bodyworkRangeKm: Int = b.bodyworkRangeKm  // range from bodywork device
    @JvmField val fuelPercent: Double = b.fuelPercent  // fuel tank level % (PHEV only, -1 = unavailable)

    // ==================== MILEAGE ====================
    @JvmField val totalMileageKm: Int = b.totalMileageKm
    @JvmField val evMileageKm: Int = b.evMileageKm

    // ==================== CHARGING ====================
    @JvmField val chargingState: Int = b.chargingState
    @JvmField val chargingGunState: Int = b.chargingGunState
    @JvmField val chargerWorkState: Int = b.chargerWorkState
    @JvmField val chargingMode: Int = b.chargingMode  // SDK getChargingMode() raw (AC vs DC vs wireless — model-specific)
    @JvmField val chargingPowerKw: Double = b.chargingPowerKw
    @JvmField val externalChargingPowerKw: Double = b.externalChargingPowerKw
    @JvmField val hvPackVoltage: Double = b.hvPackVoltage  // HV battery pack voltage (V), from CAN event

    // ==================== GEAR ====================
    @JvmField val gearMode: Int = b.gearMode

    // ==================== TYRES ====================
    @JvmField val tyrePressure: IntArray? = b.tyrePressure  // [FL, FR, RL, RR] in kPa (raw int from BYDAutoTyreDevice.getTyrePressureValue)
    @JvmField val tyrePressureState: IntArray? = b.tyrePressureState  // [FL, FR, RL, RR] — 0=NORMAL, 1=UNDERPRESSURE, 2=OVERPRESSURE
    @JvmField val tyreAirLeakState: IntArray? = b.tyreAirLeakState  // [FL, FR, RL, RR] — 0=Normal, 1=Slow leak, 2=Fast leak
    @JvmField val tyreSignalState: IntArray? = b.tyreSignalState  // [FL, FR, RL, RR] — 0=Signal OK, 1=Signal Error
    @JvmField val tyreTemperature: IntArray? = b.tyreTemperature  // [FL, FR, RL, RR] in °C; UNAVAILABLE until TPMS fires
    @JvmField val tyreSystemState: Int = b.tyreSystemState  // overall TPMS health (raw enum)
    @JvmField val tyreTemperatureState: Int = b.tyreTemperatureState  // overall TPMS temperature warning (raw enum)

    // ==================== DOORS ====================
    @JvmField val doorLockStatus: IntArray? = b.doorLockStatus  // [1-7]

    // ==================== WINDOWS ====================
    @JvmField val windowOpenPercent: IntArray? = b.windowOpenPercent  // [1-6]

    // ==================== LIGHTS ====================
    @JvmField val leftTurnState: Int = b.leftTurnState
    @JvmField val rightTurnState: Int = b.rightTurnState
    @JvmField val lowBeam: Boolean = b.lowBeam
    @JvmField val highBeam: Boolean = b.highBeam
    @JvmField val rearFog: Boolean = b.rearFog
    @JvmField val frontFog: Boolean = b.frontFog
    @JvmField val hazard: Boolean = b.hazard
    @JvmField val dayTimeLight: Boolean = b.dayTimeLight

    // ==================== ADAS ====================
    @JvmField val speedLimitWarning: Boolean = b.speedLimitWarning

    // ==================== SEATBELTS ====================
    @JvmField val seatbeltStatus: IntArray? = b.seatbeltStatus  // [1-5]

    // ==================== SEATS ====================
    @JvmField val seatHeat: IntArray? = b.seatHeat  // [driver, passenger] — 0=off, 1=low, 2=high
    @JvmField val seatCool: IntArray? = b.seatCool  // [driver, passenger] — 0=off, 1=low, 2=high

    // ==================== CLIMATE ====================
    @JvmField val acStartState: Int = b.acStartState
    @JvmField val acCycleMode: Int = b.acCycleMode
    @JvmField val acWindMode: Int = b.acWindMode
    @JvmField val acFanLevel: Int = b.acFanLevel
    @JvmField val tempUnit: Int = b.tempUnit

    // ==================== SENSOR ====================
    @JvmField val slopeDegrees: Double = b.slopeDegrees

    // ==================== POWER ====================
    @JvmField val powerLevel: Int = b.powerLevel
    @JvmField val mcuStatus: Int = b.mcuStatus

    // ==================== ALARM ====================
    @JvmField val emergencyAlarmState: Int = b.emergencyAlarmState

    // ==================== RADAR ====================
    @JvmField val radarDistances: IntArray? = b.radarDistances  // 9 sensors

    // ==================== EXTENDED BATTERY ====================
    @JvmField val sohPercent: Double = b.sohPercent  // OEM SOH from STATISTIC_BATTERY_HEALTHY_INDEX
    @JvmField val keyBatteryLevel: Int = b.keyBatteryLevel  // 0=low, 1=normal
    @JvmField val battery12vLevel: Int = b.battery12vLevel  // LOW/NORMAL/INVALID from bodywork

    // ==================== KEY PROXIMITY ====================
    // Discrete proximity / authentication signals from the BYD body controller.
    // Semantics are model-specific; values are the raw int from the SDK.
    @JvmField val keyStartState: Int = b.keyStartState  // SettingDevice.getStartKeyState() — key recognized for start
    @JvmField val keyMissingInd: Int = b.keyMissingInd  // SettingDevice.getMissKeyInd() — "key missing" indicator
    @JvmField val keyBtLowPowerMode: Int = b.keyBtLowPowerMode  // SettingDevice.getIKEYBTLowPowerMode() — BLE-key low-power flag
    @JvmField val keyPowerLowInd: Int = b.keyPowerLowInd  // SettingDevice.getKeyPowerLowInd() — fob battery low
    @JvmField val keyDetectionReminder: Int = b.keyDetectionReminder  // InstrumentDevice.getKeyDetectionReminder()
    @JvmField val smartKeyWarnState: Int = b.smartKeyWarnState  // InstrumentDevice.getSmartKeySysWarnLightState()

    // ==================== EXTENDED THERMAL ====================
    @JvmField val insideTempCelsius: Double = b.insideTempCelsius  // Cabin temp from AC_TEMP_INSIDE

    // ==================== EXTENDED CHARGING ====================
    @JvmField val chargingRestTimeHours: Int = b.chargingRestTimeHours
    @JvmField val chargingRestTimeMinutes: Int = b.chargingRestTimeMinutes
    @JvmField val chargingPercent: Int = b.chargingPercent  // charging session progress % (from chargingDevice or instrument feature ID 842006544)
    @JvmField val chargingType: Int = b.chargingType  // 0=DEFAULT, 3=VTOG (vehicle-to-grid)
    @JvmField val vtolCharging: Boolean = b.vtolCharging  // V2L/V2G active
    @JvmField val chargingCapacityKwh: Double = b.chargingCapacityKwh  // from chargingDevice.getChargingCapacity()
    @JvmField val wirelessChargingLeftState: Int = b.wirelessChargingLeftState
    @JvmField val wirelessChargingRightState: Int = b.wirelessChargingRightState

    // ==================== EXTENDED DRIVING ====================
    @JvmField val drivingTimeHours: Double = b.drivingTimeHours
    @JvmField val last50KmConsumption: Double = b.last50KmConsumption  // kWh/100km
    @JvmField val steeringAngleDegrees: Double = b.steeringAngleDegrees
    @JvmField val autoSystemState: Int = b.autoSystemState  // 0=normal, 1=set_secure, 2=start_secure

    // ==================== EXTENDED TRIP ====================
    @JvmField val currentTripMileageKm: Double = b.currentTripMileageKm
    @JvmField val currentTripTimeHours: Double = b.currentTripTimeHours
    @JvmField val currentTripConsumptionKwh: Double = b.currentTripConsumptionKwh

    // ==================== EXTENDED ENGINE ====================
    @JvmField val engineCoolantLevel: Int = b.engineCoolantLevel  // 0=normal, 1=low
    @JvmField val oilLevel: Int = b.oilLevel  // 0-254
    @JvmField val engineCode: String? = b.engineCode  // e.g. "BYD473QF"

    // ==================== EXTENDED BODYWORK ====================
    @JvmField val wiperState: Int = b.wiperState
    @JvmField val sunroofState: Int = b.sunroofState
    @JvmField val sunroofPosition: Int = b.sunroofPosition
    @JvmField val sunshadePercent: Int = b.sunshadePercent
    @JvmField val wirelessChargingStatus: Int = b.wirelessChargingStatus
    @JvmField val driftModeEnabled: Boolean = b.driftModeEnabled

    // ==================== EXTENDED SAFETY ====================
    @JvmField val passengerDetection: IntArray? = b.passengerDetection  // OMS detection per seat

    // ==================== EXTENDED AIR QUALITY ====================
    @JvmField val pm25Inside: Int = b.pm25Inside
    @JvmField val pm25Outside: Int = b.pm25Outside

    // ==================== META ====================
    @JvmField val timestamp: Long = b.timestamp
    @JvmField val availableDevices: Array<String>? = b.availableDevices
    @JvmField val unavailableDevices: Array<String>? = b.unavailableDevices

    /** Cell voltage delta (imbalance indicator) */
    fun getCellVoltageDelta(): Double {
        if (highCellVoltage.isNaN() || lowCellVoltage.isNaN()) return Double.NaN
        return highCellVoltage - lowCellVoltage
    }

    /** Cell temperature delta */
    fun getCellTempDelta(): Double {
        if (highCellTempC.isNaN() || lowCellTempC.isNaN()) return Double.NaN
        return highCellTempC - lowCellTempC
    }

    /** Best available battery temperature */
    fun getBestBatteryTemp(): Double {
        if (!avgCellTempC.isNaN()) return avgCellTempC
        if (!highCellTempC.isNaN()) return highCellTempC
        if (!bodyworkBattTempC.isNaN()) return bodyworkBattTempC
        if (!waterTempC.isNaN()) return waterTempC
        return Double.NaN
    }

    /** Convert to JSON for API responses */
    fun toJson(): JSONObject {
        val j = JSONObject()
        try {
            if (vin != null) j.put("vin", vin)

            // Battery
            val batt = JSONObject()
            putIfValid(batt, "socPercent", socPercent)
            putIfValid(batt, "socHevPercent", socHevPercent)
            putIfValid(batt, "capacityAh", capacityAh)
            putIfValid(batt, "remainKwh", remainKwh)
            putIfValid(batt, "voltage12v", voltage12v)
            putIfSet(batt, "voltageLevelRaw", voltageLevelRaw)
            j.put("battery", batt)

            // Thermal
            val therm = JSONObject()
            putIfValid(therm, "highCellTempC", highCellTempC)
            putIfValid(therm, "lowCellTempC", lowCellTempC)
            putIfValid(therm, "avgCellTempC", avgCellTempC)
            putIfValid(therm, "waterTempC", waterTempC)
            putIfValid(therm, "outsideTempC", outsideTempC)
            putIfValid(therm, "insideTempC", insideTempC)
            putIfValid(therm, "bodyworkBattTempC", bodyworkBattTempC)
            putIfValid(therm, "bestBatteryTempC", getBestBatteryTemp())
            j.put("thermal", therm)

            // Cell voltage
            val cellV = JSONObject()
            putIfValid(cellV, "highV", highCellVoltage)
            putIfValid(cellV, "lowV", lowCellVoltage)
            putIfValid(cellV, "deltaV", getCellVoltageDelta())
            j.put("cellVoltage", cellV)

            // Speed
            val spd = JSONObject()
            putIfValid(spd, "kmh", speedKmh)
            putIfSet(spd, "accelPercent", accelPercent)
            putIfSet(spd, "brakePercent", brakePercent)
            j.put("speed", spd)

            // Motor
            val mot = JSONObject()
            putIfSet(mot, "frontSpeed", frontMotorSpeed)
            putIfSet(mot, "rearSpeed", rearMotorSpeed)
            putIfValid(mot, "frontTorque", frontMotorTorque)
            putIfSet(mot, "engineRpm", engineSpeedRpm)
            putIfValid(mot, "enginePowerKw", enginePowerKw)
            j.put("motor", mot)

            // Energy
            val eng = JSONObject()
            putIfSet(eng, "mode", energyMode)
            putIfSet(eng, "operationMode", operationMode)
            putIfValid(eng, "totalElecCon", totalElecCon)
            putIfValid(eng, "totalFuelCon", totalFuelCon)
            j.put("energy", eng)

            // Range
            val rng = JSONObject()
            putIfSet(rng, "elecKm", elecRangeKm)
            putIfSet(rng, "fuelKm", fuelRangeKm)
            if (!fuelPercent.isNaN() && fuelPercent >= 0) rng.put("fuelPercent", fuelPercent)
            putIfSet(rng, "bodyworkKm", bodyworkRangeKm)
            j.put("range", rng)

            // Mileage
            val mil = JSONObject()
            putIfSet(mil, "totalKm", totalMileageKm)
            putIfSet(mil, "evKm", evMileageKm)
            j.put("mileage", mil)

            // Charging
            val chg = JSONObject()
            putIfSet(chg, "state", chargingState)
            putIfSet(chg, "gunState", chargingGunState)
            putIfSet(chg, "chargerState", chargerWorkState)
            putIfSet(chg, "mode", chargingMode)
            putIfValid(chg, "powerKw", chargingPowerKw)
            putIfValid(chg, "externalPowerKw", externalChargingPowerKw)
            j.put("charging", chg)

            // Gear
            putIfSet(j, "gearMode", gearMode)

            // Tyres
            if (tyrePressure != null) {
                j.put("tyrePressure", intArrayToJson(tyrePressure))
                j.put("tyrePressureUnit", "kPa")
            }
            if (tyrePressureState != null) j.put("tyrePressureState", intArrayToJson(tyrePressureState))
            if (tyreAirLeakState != null) j.put("tyreAirLeakState", intArrayToJson(tyreAirLeakState))
            if (tyreSignalState != null) j.put("tyreSignalState", intArrayToJson(tyreSignalState))
            if (tyreTemperature != null) {
                val a = JSONArray()
                // UNAVAILABLE reads as JSON null, not as Integer.MIN_VALUE: the UI must be able
                // to tell "TPMS has not reported yet" from a real (absurd) temperature.
                for (v in tyreTemperature) a.put(if (v == UNAVAILABLE) JSONObject.NULL else v)
                j.put("tyreTemperature", a)
                j.put("tyreTemperatureUnit", "C")
            }
            putIfSet(j, "tyreSystemState", tyreSystemState)
            putIfSet(j, "tyreTemperatureState", tyreTemperatureState)

            // Doors
            if (doorLockStatus != null) j.put("doorLockStatus", intArrayToJson(doorLockStatus))

            // Windows
            if (windowOpenPercent != null) j.put("windowOpenPercent", intArrayToJson(windowOpenPercent))

            // Lights
            val lt = JSONObject()
            putIfSet(lt, "leftTurn", leftTurnState)
            putIfSet(lt, "rightTurn", rightTurnState)
            lt.put("lowBeam", lowBeam)
            lt.put("highBeam", highBeam)
            lt.put("rearFog", rearFog)
            lt.put("frontFog", frontFog)
            lt.put("hazard", hazard)
            j.put("lights", lt)

            // Seatbelts
            if (seatbeltStatus != null) j.put("seatbeltStatus", intArrayToJson(seatbeltStatus))
            if (seatHeat != null) j.put("seatHeat", intArrayToJson(seatHeat))
            if (seatCool != null) j.put("seatCool", intArrayToJson(seatCool))

            // Climate
            val clim = JSONObject()
            putIfSet(clim, "acOn", acStartState)
            putIfSet(clim, "cycleMode", acCycleMode)
            putIfSet(clim, "windMode", acWindMode)
            putIfSet(clim, "fanLevel", acFanLevel)
            putIfSet(clim, "tempUnit", tempUnit)
            j.put("climate", clim)

            // Sensor
            putIfValid(j, "slopeDegrees", slopeDegrees)

            // Power
            putIfSet(j, "powerLevel", powerLevel)
            putIfSet(j, "mcuStatus", mcuStatus)
            putIfSet(j, "emergencyAlarm", emergencyAlarmState)

            // Radar
            if (radarDistances != null) j.put("radarDistances", intArrayToJson(radarDistances))

            // Meta
            j.put("timestamp", timestamp)
            if (availableDevices != null) {
                val ad = JSONArray()
                for (d in availableDevices) ad.put(d)
                j.put("availableDevices", ad)
            }

            // ==================== EXTENDED SUB-OBJECTS ====================

            // Extended Battery
            val extBatt = JSONObject()
            putIfValid(extBatt, "sohPercent", sohPercent)
            putIfSet(extBatt, "keyBatteryLevel", keyBatteryLevel)
            putIfSet(extBatt, "battery12vLevel", battery12vLevel)
            if (extBatt.length() > 0) j.put("extendedBattery", extBatt)

            // Key proximity
            val keyJson = JSONObject()
            putIfSet(keyJson, "startState", keyStartState)
            putIfSet(keyJson, "missingInd", keyMissingInd)
            putIfSet(keyJson, "btLowPowerMode", keyBtLowPowerMode)
            putIfSet(keyJson, "powerLowInd", keyPowerLowInd)
            putIfSet(keyJson, "detectionReminder", keyDetectionReminder)
            putIfSet(keyJson, "smartKeyWarnState", smartKeyWarnState)
            if (keyJson.length() > 0) j.put("key", keyJson)

            // Extended Thermal (insideTempCelsius)
            // Note: insideTempCelsius is separate from the existing insideTempC in thermal
            val extTherm = JSONObject()
            putIfValid(extTherm, "insideTempCelsius", insideTempCelsius)
            if (extTherm.length() > 0) j.put("extendedThermal", extTherm)

            // Extended Charging
            val extChg = JSONObject()
            putIfSet(extChg, "restTimeHours", chargingRestTimeHours)
            putIfSet(extChg, "restTimeMinutes", chargingRestTimeMinutes)
            putIfSet(extChg, "chargingPercent", chargingPercent)
            putIfSet(extChg, "chargingType", chargingType)
            if (vtolCharging) extChg.put("vtolCharging", true)
            putIfValid(extChg, "chargingCapacityKwh", chargingCapacityKwh)
            putIfSet(extChg, "wirelessChargingLeftState", wirelessChargingLeftState)
            putIfSet(extChg, "wirelessChargingRightState", wirelessChargingRightState)
            if (extChg.length() > 0) j.put("extendedCharging", extChg)

            // Extended Driving
            val extDrv = JSONObject()
            putIfValid(extDrv, "drivingTimeHours", drivingTimeHours)
            putIfValid(extDrv, "last50KmConsumption", last50KmConsumption)
            putIfValid(extDrv, "steeringAngleDegrees", steeringAngleDegrees)
            putIfSet(extDrv, "autoSystemState", autoSystemState)
            if (extDrv.length() > 0) j.put("extendedDriving", extDrv)

            // Extended Trip
            val extTrip = JSONObject()
            putIfValid(extTrip, "currentTripMileageKm", currentTripMileageKm)
            putIfValid(extTrip, "currentTripTimeHours", currentTripTimeHours)
            putIfValid(extTrip, "currentTripConsumptionKwh", currentTripConsumptionKwh)
            if (extTrip.length() > 0) j.put("extendedTrip", extTrip)

            // Extended Engine
            val extEng = JSONObject()
            putIfSet(extEng, "engineCoolantLevel", engineCoolantLevel)
            putIfSet(extEng, "oilLevel", oilLevel)
            if (engineCode != null) extEng.put("engineCode", engineCode)
            if (extEng.length() > 0) j.put("extendedEngine", extEng)

            // Extended Bodywork
            val extBody = JSONObject()
            putIfSet(extBody, "wiperState", wiperState)
            putIfSet(extBody, "sunroofState", sunroofState)
            putIfSet(extBody, "sunroofPosition", sunroofPosition)
            putIfSet(extBody, "sunshadePercent", sunshadePercent)
            putIfSet(extBody, "wirelessChargingStatus", wirelessChargingStatus)
            if (driftModeEnabled) extBody.put("driftModeEnabled", true)
            if (extBody.length() > 0) j.put("extendedBodywork", extBody)

            // Extended Safety
            if (passengerDetection != null) {
                val extSafety = JSONObject()
                extSafety.put("passengerDetection", intArrayToJson(passengerDetection))
                j.put("extendedSafety", extSafety)
            }

            // Extended Air Quality
            val extAir = JSONObject()
            putIfSet(extAir, "pm25Inside", pm25Inside)
            putIfSet(extAir, "pm25Outside", pm25Outside)
            if (extAir.length() > 0) j.put("extendedAir", extAir)
        } catch (e: Exception) {
            logger.debug("toJson error: " + e.message)
        }
        return j
    }

    /** Create a new builder pre-filled with this snapshot's values */
    fun toBuilder(): Builder {
        val b = Builder()
        b.vin = vin
        b.socPercent = socPercent
        b.socHevPercent = socHevPercent
        b.capacityAh = capacityAh
        b.remainKwh = remainKwh
        b.voltage12v = voltage12v
        b.voltageLevelRaw = voltageLevelRaw
        b.highCellTempC = highCellTempC
        b.lowCellTempC = lowCellTempC
        b.avgCellTempC = avgCellTempC
        b.waterTempC = waterTempC
        b.outsideTempC = outsideTempC
        b.insideTempC = insideTempC
        b.bodyworkBattTempC = bodyworkBattTempC
        b.highCellVoltage = highCellVoltage
        b.lowCellVoltage = lowCellVoltage
        b.speedKmh = speedKmh
        b.accelPercent = accelPercent
        b.brakePercent = brakePercent
        b.frontMotorSpeed = frontMotorSpeed
        b.rearMotorSpeed = rearMotorSpeed
        b.frontMotorTorque = frontMotorTorque
        b.engineSpeedRpm = engineSpeedRpm
        b.enginePowerKw = enginePowerKw
        b.energyMode = energyMode
        b.operationMode = operationMode
        b.totalElecCon = totalElecCon
        b.totalFuelCon = totalFuelCon
        b.elecRangeKm = elecRangeKm
        b.fuelRangeKm = fuelRangeKm
        b.bodyworkRangeKm = bodyworkRangeKm
        b.fuelPercent = fuelPercent
        b.totalMileageKm = totalMileageKm
        b.evMileageKm = evMileageKm
        b.chargingState = chargingState
        b.chargingGunState = chargingGunState
        b.chargerWorkState = chargerWorkState
        b.chargingMode = chargingMode
        b.chargingPowerKw = chargingPowerKw
        b.externalChargingPowerKw = externalChargingPowerKw
        b.hvPackVoltage = hvPackVoltage
        b.gearMode = gearMode
        b.tyrePressure = tyrePressure
        b.tyrePressureState = tyrePressureState
        b.tyreAirLeakState = tyreAirLeakState
        b.tyreSignalState = tyreSignalState
        b.tyreTemperature = tyreTemperature
        b.tyreSystemState = tyreSystemState
        b.tyreTemperatureState = tyreTemperatureState
        b.doorLockStatus = doorLockStatus
        b.windowOpenPercent = windowOpenPercent
        b.leftTurnState = leftTurnState
        b.rightTurnState = rightTurnState
        b.lowBeam = lowBeam
        b.highBeam = highBeam
        b.rearFog = rearFog
        b.frontFog = frontFog
        b.hazard = hazard
        b.dayTimeLight = dayTimeLight
        b.speedLimitWarning = speedLimitWarning
        b.seatbeltStatus = seatbeltStatus
        b.seatHeat = seatHeat
        b.seatCool = seatCool
        b.acStartState = acStartState
        b.acCycleMode = acCycleMode
        b.acWindMode = acWindMode
        b.acFanLevel = acFanLevel
        b.tempUnit = tempUnit
        b.slopeDegrees = slopeDegrees
        b.powerLevel = powerLevel
        b.mcuStatus = mcuStatus
        b.emergencyAlarmState = emergencyAlarmState
        b.radarDistances = radarDistances
        b.sohPercent = sohPercent
        b.keyBatteryLevel = keyBatteryLevel
        b.battery12vLevel = battery12vLevel
        b.keyStartState = keyStartState
        b.keyMissingInd = keyMissingInd
        b.keyBtLowPowerMode = keyBtLowPowerMode
        b.keyPowerLowInd = keyPowerLowInd
        b.keyDetectionReminder = keyDetectionReminder
        b.smartKeyWarnState = smartKeyWarnState
        b.insideTempCelsius = insideTempCelsius
        b.chargingRestTimeHours = chargingRestTimeHours
        b.chargingRestTimeMinutes = chargingRestTimeMinutes
        b.chargingPercent = chargingPercent
        b.chargingType = chargingType
        b.vtolCharging = vtolCharging
        b.chargingCapacityKwh = chargingCapacityKwh
        b.wirelessChargingLeftState = wirelessChargingLeftState
        b.wirelessChargingRightState = wirelessChargingRightState
        b.drivingTimeHours = drivingTimeHours
        b.last50KmConsumption = last50KmConsumption
        b.steeringAngleDegrees = steeringAngleDegrees
        b.autoSystemState = autoSystemState
        b.currentTripMileageKm = currentTripMileageKm
        b.currentTripTimeHours = currentTripTimeHours
        b.currentTripConsumptionKwh = currentTripConsumptionKwh
        b.engineCoolantLevel = engineCoolantLevel
        b.oilLevel = oilLevel
        b.engineCode = engineCode
        b.wiperState = wiperState
        b.sunroofState = sunroofState
        b.sunroofPosition = sunroofPosition
        b.sunshadePercent = sunshadePercent
        b.wirelessChargingStatus = wirelessChargingStatus
        b.driftModeEnabled = driftModeEnabled
        b.passengerDetection = passengerDetection
        b.pm25Inside = pm25Inside
        b.pm25Outside = pm25Outside
        b.timestamp = timestamp
        b.availableDevices = availableDevices
        b.unavailableDevices = unavailableDevices
        return b
    }

    class Builder {
        @JvmField var vin: String? = null
        @JvmField var socPercent: Double = Double.NaN
        @JvmField var socHevPercent: Double = Double.NaN
        @JvmField var capacityAh: Double = Double.NaN
        @JvmField var remainKwh: Double = Double.NaN
        @JvmField var voltage12v: Double = Double.NaN
        @JvmField var voltageLevelRaw: Int = UNAVAILABLE
        @JvmField var highCellTempC: Double = Double.NaN
        @JvmField var lowCellTempC: Double = Double.NaN
        @JvmField var avgCellTempC: Double = Double.NaN
        @JvmField var waterTempC: Double = Double.NaN
        @JvmField var outsideTempC: Double = Double.NaN
        @JvmField var insideTempC: Double = Double.NaN
        @JvmField var bodyworkBattTempC: Double = Double.NaN
        @JvmField var highCellVoltage: Double = Double.NaN
        @JvmField var lowCellVoltage: Double = Double.NaN
        @JvmField var speedKmh: Double = Double.NaN
        @JvmField var accelPercent: Int = UNAVAILABLE
        @JvmField var brakePercent: Int = UNAVAILABLE
        @JvmField var frontMotorSpeed: Int = UNAVAILABLE
        @JvmField var rearMotorSpeed: Int = UNAVAILABLE
        @JvmField var frontMotorTorque: Double = Double.NaN
        @JvmField var engineSpeedRpm: Int = UNAVAILABLE
        @JvmField var enginePowerKw: Double = Double.NaN
        @JvmField var energyMode: Int = UNAVAILABLE
        @JvmField var operationMode: Int = UNAVAILABLE
        @JvmField var totalElecCon: Double = Double.NaN
        @JvmField var totalFuelCon: Double = Double.NaN
        @JvmField var elecRangeKm: Int = UNAVAILABLE
        @JvmField var fuelRangeKm: Int = UNAVAILABLE
        @JvmField var bodyworkRangeKm: Int = UNAVAILABLE
        @JvmField var fuelPercent: Double = Double.NaN
        @JvmField var totalMileageKm: Int = UNAVAILABLE
        @JvmField var evMileageKm: Int = UNAVAILABLE
        @JvmField var chargingState: Int = UNAVAILABLE
        @JvmField var chargingGunState: Int = UNAVAILABLE
        @JvmField var chargerWorkState: Int = UNAVAILABLE
        @JvmField var chargingMode: Int = UNAVAILABLE
        @JvmField var chargingPowerKw: Double = Double.NaN
        @JvmField var externalChargingPowerKw: Double = Double.NaN
        @JvmField var hvPackVoltage: Double = Double.NaN
        @JvmField var gearMode: Int = UNAVAILABLE
        @JvmField var tyrePressure: IntArray? = null
        @JvmField var tyrePressureState: IntArray? = null
        @JvmField var tyreAirLeakState: IntArray? = null
        @JvmField var tyreSignalState: IntArray? = null
        @JvmField var tyreTemperature: IntArray? = null
        @JvmField var tyreSystemState: Int = UNAVAILABLE
        @JvmField var tyreTemperatureState: Int = UNAVAILABLE
        @JvmField var doorLockStatus: IntArray? = null
        @JvmField var windowOpenPercent: IntArray? = null
        @JvmField var leftTurnState: Int = UNAVAILABLE
        @JvmField var rightTurnState: Int = UNAVAILABLE
        @JvmField var lowBeam: Boolean = false
        @JvmField var highBeam: Boolean = false
        @JvmField var rearFog: Boolean = false
        @JvmField var frontFog: Boolean = false
        @JvmField var hazard: Boolean = false
        @JvmField var dayTimeLight: Boolean = false
        @JvmField var speedLimitWarning: Boolean = false
        @JvmField var seatbeltStatus: IntArray? = null
        @JvmField var seatHeat: IntArray? = null
        @JvmField var seatCool: IntArray? = null
        @JvmField var acStartState: Int = UNAVAILABLE
        @JvmField var acCycleMode: Int = UNAVAILABLE
        @JvmField var acWindMode: Int = UNAVAILABLE
        @JvmField var acFanLevel: Int = UNAVAILABLE
        @JvmField var tempUnit: Int = UNAVAILABLE
        @JvmField var slopeDegrees: Double = Double.NaN
        @JvmField var powerLevel: Int = UNAVAILABLE
        @JvmField var mcuStatus: Int = UNAVAILABLE
        @JvmField var emergencyAlarmState: Int = UNAVAILABLE
        @JvmField var radarDistances: IntArray? = null
        @JvmField var sohPercent: Double = Double.NaN
        @JvmField var keyBatteryLevel: Int = UNAVAILABLE
        @JvmField var battery12vLevel: Int = UNAVAILABLE
        @JvmField var keyStartState: Int = UNAVAILABLE
        @JvmField var keyMissingInd: Int = UNAVAILABLE
        @JvmField var keyBtLowPowerMode: Int = UNAVAILABLE
        @JvmField var keyPowerLowInd: Int = UNAVAILABLE
        @JvmField var keyDetectionReminder: Int = UNAVAILABLE
        @JvmField var smartKeyWarnState: Int = UNAVAILABLE
        @JvmField var insideTempCelsius: Double = Double.NaN
        @JvmField var chargingRestTimeHours: Int = UNAVAILABLE
        @JvmField var chargingRestTimeMinutes: Int = UNAVAILABLE
        @JvmField var chargingPercent: Int = UNAVAILABLE
        @JvmField var chargingType: Int = UNAVAILABLE
        @JvmField var vtolCharging: Boolean = false
        @JvmField var chargingCapacityKwh: Double = Double.NaN
        @JvmField var wirelessChargingLeftState: Int = UNAVAILABLE
        @JvmField var wirelessChargingRightState: Int = UNAVAILABLE
        @JvmField var drivingTimeHours: Double = Double.NaN
        @JvmField var last50KmConsumption: Double = Double.NaN
        @JvmField var steeringAngleDegrees: Double = Double.NaN
        @JvmField var autoSystemState: Int = UNAVAILABLE
        @JvmField var currentTripMileageKm: Double = Double.NaN
        @JvmField var currentTripTimeHours: Double = Double.NaN
        @JvmField var currentTripConsumptionKwh: Double = Double.NaN
        @JvmField var engineCoolantLevel: Int = UNAVAILABLE
        @JvmField var oilLevel: Int = UNAVAILABLE
        @JvmField var engineCode: String? = null
        @JvmField var wiperState: Int = UNAVAILABLE
        @JvmField var sunroofState: Int = UNAVAILABLE
        @JvmField var sunroofPosition: Int = UNAVAILABLE
        @JvmField var sunshadePercent: Int = UNAVAILABLE
        @JvmField var wirelessChargingStatus: Int = UNAVAILABLE
        @JvmField var driftModeEnabled: Boolean = false
        @JvmField var passengerDetection: IntArray? = null
        @JvmField var pm25Inside: Int = UNAVAILABLE
        @JvmField var pm25Outside: Int = UNAVAILABLE
        @JvmField var timestamp: Long = System.currentTimeMillis()
        @JvmField var availableDevices: Array<String>? = null
        @JvmField var unavailableDevices: Array<String>? = null

        fun vin(v: String?): Builder = apply { vin = v }
        fun socPercent(v: Double): Builder = apply { socPercent = v }
        fun socHevPercent(v: Double): Builder = apply { socHevPercent = v }
        fun capacityAh(v: Double): Builder = apply { capacityAh = v }
        fun remainKwh(v: Double): Builder = apply { remainKwh = v }
        fun voltage12v(v: Double): Builder = apply { voltage12v = v }
        fun voltageLevelRaw(v: Int): Builder = apply { voltageLevelRaw = v }
        fun highCellTempC(v: Double): Builder = apply { highCellTempC = v }
        fun lowCellTempC(v: Double): Builder = apply { lowCellTempC = v }
        fun avgCellTempC(v: Double): Builder = apply { avgCellTempC = v }
        fun waterTempC(v: Double): Builder = apply { waterTempC = v }
        fun outsideTempC(v: Double): Builder = apply { outsideTempC = v }
        fun insideTempC(v: Double): Builder = apply { insideTempC = v }
        fun bodyworkBattTempC(v: Double): Builder = apply { bodyworkBattTempC = v }
        fun highCellVoltage(v: Double): Builder = apply { highCellVoltage = v }
        fun lowCellVoltage(v: Double): Builder = apply { lowCellVoltage = v }
        fun speedKmh(v: Double): Builder = apply { speedKmh = v }
        fun accelPercent(v: Int): Builder = apply { accelPercent = v }
        fun brakePercent(v: Int): Builder = apply { brakePercent = v }
        fun frontMotorSpeed(v: Int): Builder = apply { frontMotorSpeed = v }
        fun rearMotorSpeed(v: Int): Builder = apply { rearMotorSpeed = v }
        fun frontMotorTorque(v: Double): Builder = apply { frontMotorTorque = v }
        fun engineSpeedRpm(v: Int): Builder = apply { engineSpeedRpm = v }
        fun enginePowerKw(v: Double): Builder = apply { enginePowerKw = v }
        fun energyMode(v: Int): Builder = apply { energyMode = v }
        fun operationMode(v: Int): Builder = apply { operationMode = v }
        fun totalElecCon(v: Double): Builder = apply { totalElecCon = v }
        fun totalFuelCon(v: Double): Builder = apply { totalFuelCon = v }
        fun elecRangeKm(v: Int): Builder = apply { elecRangeKm = v }
        fun fuelRangeKm(v: Int): Builder = apply { fuelRangeKm = v }
        fun bodyworkRangeKm(v: Int): Builder = apply { bodyworkRangeKm = v }
        fun fuelPercent(v: Double): Builder = apply { fuelPercent = v }
        fun totalMileageKm(v: Int): Builder = apply { totalMileageKm = v }
        fun evMileageKm(v: Int): Builder = apply { evMileageKm = v }
        fun chargingState(v: Int): Builder = apply { chargingState = v }
        fun chargingGunState(v: Int): Builder = apply { chargingGunState = v }
        fun chargerWorkState(v: Int): Builder = apply { chargerWorkState = v }
        fun chargingMode(v: Int): Builder = apply { chargingMode = v }
        fun chargingPowerKw(v: Double): Builder = apply { chargingPowerKw = v }
        fun externalChargingPowerKw(v: Double): Builder = apply { externalChargingPowerKw = v }
        fun hvPackVoltage(v: Double): Builder = apply { hvPackVoltage = v }
        fun gearMode(v: Int): Builder = apply { gearMode = v }
        fun tyrePressure(v: IntArray?): Builder = apply { tyrePressure = v }
        fun tyrePressureState(v: IntArray?): Builder = apply { tyrePressureState = v }
        fun tyreAirLeakState(v: IntArray?): Builder = apply { tyreAirLeakState = v }
        fun tyreSignalState(v: IntArray?): Builder = apply { tyreSignalState = v }
        fun tyreTemperature(v: IntArray?): Builder = apply { tyreTemperature = v }
        fun tyreSystemState(v: Int): Builder = apply { tyreSystemState = v }
        fun tyreTemperatureState(v: Int): Builder = apply { tyreTemperatureState = v }
        fun doorLockStatus(v: IntArray?): Builder = apply { doorLockStatus = v }
        fun windowOpenPercent(v: IntArray?): Builder = apply { windowOpenPercent = v }
        fun leftTurnState(v: Int): Builder = apply { leftTurnState = v }
        fun rightTurnState(v: Int): Builder = apply { rightTurnState = v }
        fun lowBeam(v: Boolean): Builder = apply { lowBeam = v }
        fun highBeam(v: Boolean): Builder = apply { highBeam = v }
        fun rearFog(v: Boolean): Builder = apply { rearFog = v }
        fun frontFog(v: Boolean): Builder = apply { frontFog = v }
        fun hazard(v: Boolean): Builder = apply { hazard = v }
        fun dayTimeLight(v: Boolean): Builder = apply { dayTimeLight = v }
        fun speedLimitWarning(v: Boolean): Builder = apply { speedLimitWarning = v }
        fun seatbeltStatus(v: IntArray?): Builder = apply { seatbeltStatus = v }
        fun seatHeat(v: IntArray?): Builder = apply { seatHeat = v }
        fun seatCool(v: IntArray?): Builder = apply { seatCool = v }
        fun acStartState(v: Int): Builder = apply { acStartState = v }
        fun acCycleMode(v: Int): Builder = apply { acCycleMode = v }
        fun acWindMode(v: Int): Builder = apply { acWindMode = v }
        fun acFanLevel(v: Int): Builder = apply { acFanLevel = v }
        fun tempUnit(v: Int): Builder = apply { tempUnit = v }
        fun slopeDegrees(v: Double): Builder = apply { slopeDegrees = v }
        fun powerLevel(v: Int): Builder = apply { powerLevel = v }
        fun mcuStatus(v: Int): Builder = apply { mcuStatus = v }
        fun emergencyAlarmState(v: Int): Builder = apply { emergencyAlarmState = v }
        fun radarDistances(v: IntArray?): Builder = apply { radarDistances = v }
        fun sohPercent(v: Double): Builder = apply { sohPercent = v }
        fun keyBatteryLevel(v: Int): Builder = apply { keyBatteryLevel = v }
        fun battery12vLevel(v: Int): Builder = apply { battery12vLevel = v }
        fun keyStartState(v: Int): Builder = apply { keyStartState = v }
        fun keyMissingInd(v: Int): Builder = apply { keyMissingInd = v }
        fun keyBtLowPowerMode(v: Int): Builder = apply { keyBtLowPowerMode = v }
        fun keyPowerLowInd(v: Int): Builder = apply { keyPowerLowInd = v }
        fun keyDetectionReminder(v: Int): Builder = apply { keyDetectionReminder = v }
        fun smartKeyWarnState(v: Int): Builder = apply { smartKeyWarnState = v }
        fun insideTempCelsius(v: Double): Builder = apply { insideTempCelsius = v }
        fun chargingRestTimeHours(v: Int): Builder = apply { chargingRestTimeHours = v }
        fun chargingRestTimeMinutes(v: Int): Builder = apply { chargingRestTimeMinutes = v }
        fun chargingPercent(v: Int): Builder = apply { chargingPercent = v }
        fun chargingType(v: Int): Builder = apply { chargingType = v }
        fun vtolCharging(v: Boolean): Builder = apply { vtolCharging = v }
        fun chargingCapacityKwh(v: Double): Builder = apply { chargingCapacityKwh = v }
        fun wirelessChargingLeftState(v: Int): Builder = apply { wirelessChargingLeftState = v }
        fun wirelessChargingRightState(v: Int): Builder = apply { wirelessChargingRightState = v }
        fun drivingTimeHours(v: Double): Builder = apply { drivingTimeHours = v }
        fun last50KmConsumption(v: Double): Builder = apply { last50KmConsumption = v }
        fun steeringAngleDegrees(v: Double): Builder = apply { steeringAngleDegrees = v }
        fun autoSystemState(v: Int): Builder = apply { autoSystemState = v }
        fun currentTripMileageKm(v: Double): Builder = apply { currentTripMileageKm = v }
        fun currentTripTimeHours(v: Double): Builder = apply { currentTripTimeHours = v }
        fun currentTripConsumptionKwh(v: Double): Builder = apply { currentTripConsumptionKwh = v }
        fun engineCoolantLevel(v: Int): Builder = apply { engineCoolantLevel = v }
        fun oilLevel(v: Int): Builder = apply { oilLevel = v }
        fun engineCode(v: String?): Builder = apply { engineCode = v }
        fun wiperState(v: Int): Builder = apply { wiperState = v }
        fun sunroofState(v: Int): Builder = apply { sunroofState = v }
        fun sunroofPosition(v: Int): Builder = apply { sunroofPosition = v }
        fun sunshadePercent(v: Int): Builder = apply { sunshadePercent = v }
        fun wirelessChargingStatus(v: Int): Builder = apply { wirelessChargingStatus = v }
        fun driftModeEnabled(v: Boolean): Builder = apply { driftModeEnabled = v }
        fun passengerDetection(v: IntArray?): Builder = apply { passengerDetection = v }
        fun pm25Inside(v: Int): Builder = apply { pm25Inside = v }
        fun pm25Outside(v: Int): Builder = apply { pm25Outside = v }
        fun timestamp(v: Long): Builder = apply { timestamp = v }
        fun availableDevices(v: Array<String>?): Builder = apply { availableDevices = v }
        fun unavailableDevices(v: Array<String>?): Builder = apply { unavailableDevices = v }

        fun build(): BydVehicleData {
            timestamp = System.currentTimeMillis()
            return BydVehicleData(this)
        }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("BydVehicleData")

        // Sentinel for unavailable numeric values
        @JvmField
        val NaN = Double.NaN

        const val UNAVAILABLE = Int.MIN_VALUE

        private fun putIfValid(j: JSONObject, key: String, v: Double) {
            if (!v.isNaN()) j.put(key, (v * 100).roundToLong() / 100.0)
        }

        /**
         * An int field is emitted only when it is not the [UNAVAILABLE] sentinel — the Java
         * original spelled this `if (x != UNAVAILABLE) o.put(k, x)` at 40-odd call sites.
         */
        private fun putIfSet(j: JSONObject, key: String, v: Int) {
            if (v != UNAVAILABLE) j.put(key, v)
        }

        private fun intArrayToJson(values: IntArray): JSONArray {
            val a = JSONArray()
            for (v in values) a.put(v)
            return a
        }
    }
}
