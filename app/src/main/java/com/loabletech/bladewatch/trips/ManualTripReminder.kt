package net.bladewatch.app.trips

import net.bladewatch.app.monitor.GearMonitor
import org.json.JSONObject

/**
 * Decides when to remind the driver to stop an open manual trip (BladeWatch-gklt.4).
 *
 * A manual trip never ends by itself, so a driver who forgets leaves it recording. Two events
 * raise a reminder, each at most ONCE until the car drives again:
 *
 *  - **acc_off**: ACC went OFF while the trip is open.
 *  - **parked_30m**: ACC is ON and the gear has been Park continuously for 30 minutes.
 *
 * Driving (ACC on and a driving gear) re-arms both. Nothing is reported without an open manual
 * trip.
 *
 * Pure: the clock and the output are injected and no thread is started, so the rules run on the
 * JVM. The owner of this object calls [tick] about once a minute (the parked rule is the only
 * one that needs it). The state round-trips through [toJson] / [restore] so a daemon restart
 * neither re-fires a reminder that was already sent nor forgets how long the car has been
 * parked.
 */
class ManualTripReminder(
    private val clock: () -> Long,
    private val fire: (reason: String) -> Unit,
) {
    private var tripOpen = false
    private var accOn = true

    /** Number of reminders raised for this trip; the in-car dialog shows one per increment. */
    var seq = 0L
        private set

    /** "acc_off" or "parked_30m" for the latest reminder, "" before the first. */
    var lastReason = ""
        private set

    private var accOffFired = false
    private var parkFired = false

    /** Epoch ms the car (ACC on) entered Park, 0 when it is not parked. */
    private var parkSinceMs = 0L

    /** A manual trip just started. [gear] is the current gear, or null when unknown. */
    @Synchronized
    fun onManualTripStarted(gear: Int?, accOn: Boolean) {
        tripOpen = true
        this.accOn = accOn
        seq = 0
        lastReason = ""
        accOffFired = false
        parkFired = false
        parkSinceMs = if (accOn && gear == GearMonitor.GEAR_P) clock() else 0L
    }

    /** The manual trip ended: forget everything. */
    @Synchronized
    fun onManualTripEnded() {
        tripOpen = false
        accOn = true
        seq = 0
        lastReason = ""
        accOffFired = false
        parkFired = false
        parkSinceMs = 0L
    }

    @Synchronized
    fun onAcc(accOn: Boolean) {
        if (!tripOpen) return
        this.accOn = accOn
        if (!accOn) {
            // Parked time only counts while the car is on.
            parkSinceMs = 0L
            if (!accOffFired) {
                accOffFired = true
                raise(REASON_ACC_OFF)
            }
        }
    }

    @Synchronized
    fun onGear(gear: Int) {
        if (!tripOpen || !accOn) return
        if (gear == GearMonitor.GEAR_P) {
            if (parkSinceMs == 0L) parkSinceMs = clock()
        } else {
            // Driving again (or any non-Park gear): the car is no longer parked, and both
            // reminders may fire again for the next stop.
            parkSinceMs = 0L
            accOffFired = false
            parkFired = false
        }
    }

    /** Call about once a minute. */
    @Synchronized
    fun tick() {
        if (!tripOpen || !accOn || parkFired || parkSinceMs == 0L) return
        if (clock() - parkSinceMs >= PARK_REMINDER_MS) {
            parkFired = true
            raise(REASON_PARKED)
        }
    }

    private fun raise(reason: String) {
        seq++
        lastReason = reason
        fire(reason)
    }

    /** The state to persist with the open manual trip. */
    @Synchronized
    fun toJson(): JSONObject = JSONObject()
        .put("seq", seq)
        .put("lastReason", lastReason)
        .put("accOn", accOn)
        .put("accOffFired", accOffFired)
        .put("parkFired", parkFired)
        .put("parkSinceMs", parkSinceMs)

    /**
     * Resume from a saved state (the trip is open). Missing or malformed fields fall back to a
     * fresh, armed state rather than throwing: a daemon that cannot start is worse than a
     * reminder that fires twice.
     */
    @Synchronized
    fun restore(json: JSONObject?) {
        tripOpen = true
        seq = json?.optLong("seq", 0L) ?: 0L
        lastReason = json?.optString("lastReason", "") ?: ""
        accOn = json?.optBoolean("accOn", true) ?: true
        accOffFired = json?.optBoolean("accOffFired", false) ?: false
        parkFired = json?.optBoolean("parkFired", false) ?: false
        parkSinceMs = json?.optLong("parkSinceMs", 0L) ?: 0L
    }

    companion object {
        const val REASON_ACC_OFF = "acc_off"
        const val REASON_PARKED = "parked_30m"

        /** 30 minutes in Park with ACC on. */
        const val PARK_REMINDER_MS = 30L * 60 * 1000
    }
}
