package net.bladewatch.app.daemon

/**
 * Arm/disarm decisions for the ACC-OFF door-lock gate (BladeWatch-l55j). Pure state, no Android
 * dependency, so the JVM suite can test it; [CameraDaemon] acts on the returned [Action].
 */
internal class DoorLockArmGate {
    enum class Action { ARM, DISARM, NONE }

    @Volatile var armed = false
        private set

    /** Id of the current gate session. Every [reset] starts a new one. */
    @Volatile var session = 0
        private set

    /** Gate opened (ACC OFF) or closed (ACC ON): forget the previous session. Returns the id of the session this reset starts. */
    @Synchronized fun reset(): Int {
        armed = false
        return ++session
    }

    /** Watchdog disarm: clears armed WITHOUT starting a new session, so the open session's timeout can still re-arm. */
    @Synchronized fun disarm() { armed = false }

    /** A lock-state report from any source (device listener, poll). */
    @Synchronized fun onLockEvent(locked: Boolean, accOn: Boolean): Action {
        if (accOn) return Action.NONE
        if (locked) {
            if (armed) return Action.NONE
            armed = true
            return Action.ARM
        }
        if (!armed) return Action.NONE
        armed = false
        return Action.DISARM
    }

    /** The 60 s timeout of [forSession] fired. Depends ONLY on accOn, armed, and whether [forSession] is still the current session. */
    @Synchronized fun onTimeout(accOn: Boolean, forSession: Int): Action {
        if (accOn || armed || forSession != session) return Action.NONE
        armed = true
        return Action.ARM
    }
}
