package net.bladewatch.app.notifications

import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.byd.bodywork.BodyworkConstants
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.Messages
import net.bladewatch.app.surveillance.SafeLocationManager
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

/**
 * Publishes `vehicle.security.door.opened` / `.closed` notifications when the BYD bodywork HAL
 * reports a door state change while the car is parked (ACC OFF). Driving-state edges are ignored
 * to avoid spam every time the driver enters or exits.
 */
class DoorEventNotifier private constructor() {

    private val listener = BydDataCollector.DoorStateListener { area, state ->
        onDoorStateChanged(area, state)
    }

    // Last published state per area; absent means "no event yet" so the first edge after
    // subscription doesn't double-fire on a stale snapshot.
    private val lastState: MutableMap<Int, Int> = ConcurrentHashMap()

    private fun onDoorStateChanged(area: Int, state: Int) {
        if (state != BodyworkConstants.STATE_OPEN && state != BodyworkConstants.STATE_CLOSED) {
            return
        }
        val prev = lastState.put(area, state)
        if (prev != null && prev == state) return

        // Gate on ACC OFF. If the snapshot doesn't yet have a powerLevel (very early boot), skip
        // — we'd rather miss a transient edge than fire while driving.
        val snap = BydDataCollector.getInstance().data ?: return
        if (snap.powerLevel != BodyworkConstants.POWER_LEVEL_OFF) return

        val opened = state == BodyworkConstants.STATE_OPEN
        val category = if (opened) {
            "vehicle.security.door.opened"
        } else {
            "vehicle.security.door.closed"
        }
        val areaLabel = areaLabel(area)

        // Append the user-defined safe-zone name when available so a buzz on the phone reads
        // "Driver front door opened — While parked at Home" instead of an anonymous "While
        // parked". When the car is outside any configured zone the "at <zone>" suffix is omitted
        // entirely; we never make up a location.
        var body = Messages.get("notifications.while_parked")
        try {
            val zone = SafeLocationManager.getInstance().currentZoneName
            if (!zone.isNullOrEmpty()) {
                body = Messages.get("notifications.while_parked_at", zone)
            }
        } catch (t: Throwable) {
            logger.warn("Failed to get current zone name for door event: " + t.message)
        }

        val data = JSONObject()
        try {
            data.put("area", area)
            data.put("areaLabel", areaLabel)
            data.put("state", state)
        } catch (e: Exception) {
            logger.warn("Failed to build door event data JSON: " + e.message)
        }

        try {
            NotificationBus.get().publish(
                NotificationEvent(
                    category,
                    NotificationEvent.Severity.WARN,
                    if (opened) {
                        Messages.get("notifications.door_opened", areaLabel)
                    } else {
                        Messages.get("notifications.door_closed", areaLabel)
                    },
                    body,
                    "door-" + area + "-" + (if (opened) "open" else "close"),
                    null,
                    data
                )
            )
        } catch (t: Throwable) {
            logger.warn("Failed to publish door event notification: " + t.message)
        }
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("DoorEventNotifier")

        // BYD bodywork area constants. The SDK publishes BODYWORK_CMD_DOOR_LEFT_FRONT=1 /
        // RIGHT_FRONT=2 / LEFT_REAR=3 / RIGHT_REAR=4, but field-tested telemetry on
        // Sealion/Atto/Seal swaps L↔R on the FRONT axis only — area 1 is the right front door in
        // real life, area 2 is the left front. The REAR axis matches the SDK declaration as-is
        // (LR=3, RR=4). We remap accordingly so notification copy matches the physical door the
        // user sees.
        private const val AREA_RF = 1
        private const val AREA_LF = 2
        private const val AREA_LR = 3
        private const val AREA_RR = 4
        private const val AREA_HOOD = 5
        private const val AREA_TRUNK = 6
        private const val AREA_FUEL_CAP = 7

        @Volatile
        private var instance: DoorEventNotifier? = null

        @JvmStatic
        @Synchronized
        fun start() {
            if (instance != null) return
            val n = DoorEventNotifier()
            BydDataCollector.getInstance().addDoorStateListener(n.listener)
            instance = n
        }

        private fun areaLabel(area: Int): String = when (area) {
            AREA_LF -> Messages.get("notifications.area_front_left")
            AREA_RF -> Messages.get("notifications.area_front_right")
            AREA_LR -> Messages.get("notifications.area_rear_left")
            AREA_RR -> Messages.get("notifications.area_rear_right")
            AREA_HOOD -> Messages.get("notifications.area_hood")
            AREA_TRUNK -> Messages.get("notifications.area_trunk")
            AREA_FUEL_CAP -> Messages.get("notifications.area_fuel_cap")
            else -> Messages.get("notifications.area_door_n", area)
        }
    }
}
