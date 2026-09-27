package net.bladewatch.app.daemon

import net.bladewatch.app.surveillance.isLibraryLoaded
import java.io.Closeable
import java.util.concurrent.ConcurrentHashMap

/**
 * BladeWatch-rdtj.66: vold's SIGINT at an SD-card unmount, handled instead of fatal.
 *
 * vold signals every process holding a file on a card it unmounts (BYD's ACC OFF shutdown does),
 * waits 5 s, retries, then escalates to SIGTERM and SIGKILL. On 2026-09-27 that ended the camera
 * daemon while it served a clip to the companion, leaving no dashcam, sentry or remote access until
 * the watchdog restarted it (rdtj.65, ~25 s). Now [start]'s thread wakes on the signal (native
 * sd_signal.cpp: ART here has no sun.misc.Signal) and runs the release: the daemon lets go of the
 * card inside vold's 5 s and keeps running. If it does not, vold's SIGTERM still ends it and the
 * watchdog brings it back.
 */
object SdCardSignal {
    @JvmStatic private external fun nativeInstall(): Boolean
    @JvmStatic private external fun nativeAwait(): Boolean

    /** Installs the handler and runs [release] on each SIGINT; false if the native library is absent. */
    fun start(release: () -> Unit): Boolean {
        if (!isLibraryLoaded()) return false
        val installed = try {
            nativeInstall()
        } catch (_: UnsatisfiedLinkError) {
            false
        }
        if (!installed) return false
        Thread({
            while (nativeAwait()) {
                try {
                    release()
                } catch (_: Throwable) {
                    // The next signal tries again; vold's SIGTERM is the backstop.
                }
            }
        }, "sd-sigint").apply { isDaemon = true }.start()
        return true
    }
}

/**
 * Media files the daemon has open for serving (rdtj.66), so a card unmount can close them all at
 * once: a remote player that stopped reading holds its clip open for as long as the stream stays
 * up. Closing one fails the response that uses it; the player asks again.
 */
object OpenMediaFiles {
    private val open: MutableSet<Closeable> = ConcurrentHashMap.newKeySet()

    fun <T : Closeable> track(file: T): T = file.also { open.add(it) }

    fun untrack(file: Closeable) {
        open.remove(file)
    }

    val count: Int get() = open.size

    /** Closes every tracked file; returns how many. */
    fun closeAll(): Int {
        var closed = 0
        for (f in open.toList()) {
            open.remove(f)
            try {
                f.close()
                closed++
            } catch (_: Exception) {
            }
        }
        return closed
    }
}
