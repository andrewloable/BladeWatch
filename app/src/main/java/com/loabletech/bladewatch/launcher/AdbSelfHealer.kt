package net.bladewatch.app.launcher

import android.content.ContentResolver
import android.provider.Settings

/**
 * Settings.Global.ADB_ENABLED access, extracted so [AdbSelfHealer] is
 * testable on the JVM without a live ContentResolver (this project has no
 * Robolectric). There is deliberately no method here that can write 0 —
 * see BladeWatch-ofzb: writing adb_enabled=0 on a car with no USB access
 * would permanently strand remote access to the head unit.
 */
interface AdbEnableGateway {
    fun isAdbEnabled(): Boolean

    /** Writes ADB_ENABLED=1. Returns true on success, false if the OS threw SecurityException. */
    fun enableAdb(): Boolean
}

class SystemAdbEnableGateway(private val contentResolver: ContentResolver) : AdbEnableGateway {
    override fun isAdbEnabled(): Boolean =
        Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0) != 0

    // Settings.Global.putInt RETURNS false when the write is rejected; it does not
    // always throw. Dropping that return value made a rejected write look like a
    // success, so the healer went on to report "wrote adb_enabled=1 but the port is
    // still closed" — pointing at BYD's wireless-ADB flag when the real problem was
    // that we never wrote anything. Honour both failure modes.
    override fun enableAdb(): Boolean = try {
        Settings.Global.putInt(contentResolver, Settings.Global.ADB_ENABLED, 1)
    } catch (e: SecurityException) {
        false
    }
}

/**
 * BladeWatch-ofzb: a BYD firmware update can reset `adb_enabled` to 0, which
 * kills every daemon (all launched via ADB to 127.0.0.1). The app holds
 * WRITE_SECURE_SETTINGS and can turn `adb_enabled` back on with no ADB
 * connection at all — but that only restores the TCP transport if BYD's own
 * `persist.sys.adb.wiress.enable` flag also survived (only a BYD-signed
 * process can write that one). This runs the retry exactly once; a dead
 * adbd will not come back by looping.
 */
class AdbSelfHealer(
    private val gateway: AdbEnableGateway,
    private val isPortOpen: () -> Boolean,
    private val sleep: (Long) -> Unit = Thread::sleep,
    private val onHealed: () -> Unit = {},
    private val onCouldNotHeal: (String) -> Unit = {},
) {
    companion object {
        const val WAIT_FOR_ADBD_MS = 1500L
    }

    /** Returns true if the ADB port is open by the end of this call. */
    fun attemptHeal(): Boolean {
        if (gateway.isAdbEnabled()) {
            onCouldNotHeal(
                "adb_enabled is already 1 — BYD's wireless-ADB flag likely needs re-enabling by hand"
            )
            return false
        }

        if (!gateway.enableAdb()) {
            onCouldNotHeal("writing adb_enabled=1 failed (SecurityException)")
            return false
        }

        sleep(WAIT_FOR_ADBD_MS)

        if (isPortOpen()) {
            onHealed()
            return true
        }

        onCouldNotHeal(
            "wrote adb_enabled=1 but the TCP port is still closed — BYD's wireless-ADB flag likely needs re-enabling by hand"
        )
        return false
    }
}
