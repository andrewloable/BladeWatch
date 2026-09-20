package net.bladewatch.app.daemon

import java.io.File
import java.io.RandomAccessFile
import java.nio.channels.FileLock
import java.util.function.Consumer

/**
 * Mutual exclusion for a shell-launched daemon, via an exclusive [FileLock] on a lock file that
 * records the holder's PID.
 *
 * BladeWatch-f0y3. SentryDaemon previously guarded itself with `isDaemonRunning()`, which PINGs
 * its control port. That is a liveness probe, not a mutual-exclusion primitive: it only answers
 * true once the first instance has already bound the port, so two daemons launched inside that
 * window both probe, both find nobody home, and both start. Observed on the head unit 2026-09-19 —
 * PIDs 9244 and 9351, one second apart, both alive, every periodic task running twice.
 *
 * The stale-lock handling here is taken from `CameraDaemon.acquireSingletonLock`, which learned it
 * on this hardware; it is not a second pattern invented alongside it. In particular a lock naming
 * a dead PID, our own PID (a previous crash), or holding junk must all be reclaimable, or a daemon
 * killed with SIGKILL could never start again.
 *
 * The PID-liveness check is injected so the decision logic is unit-testable: /proc is not available
 * to a JVM test.
 */
class DaemonSingletonLock(
    private val lockFileObj: File,
    private val myPid: Int,
    private val liveness: PidLiveness,
    private val log: Consumer<String>
) {

    /** Whether a PID belongs to a live process. Production reads `/proc/<pid>`. */
    fun interface PidLiveness {
        fun isAlive(pid: Int): Boolean
    }

    private var lockFile: RandomAccessFile? = null
    private var fileLock: FileLock? = null

    /**
     * @return true if this process now holds the lock; false if a live daemon holds it and this
     *   process must exit.
     */
    fun acquire(): Boolean {
        try {
            val parent = lockFileObj.parentFile
            if (parent != null && !parent.exists()) parent.mkdirs()

            var raf = RandomAccessFile(lockFileObj, "rw")
            lockFile = raf
            var lock = raf.channel.tryLock()
            fileLock = lock

            if (lock == null) {
                // Someone holds the OS lock. Treat "dead PID", "missing/corrupt PID" and "our own
                // PID" all as stale — each means no live daemon actually owns it.
                val pidStr = readPidQuietly()
                val reason = staleReason(pidStr, myPid, liveness)
                if (reason == null) {
                    log.accept(liveRivalMessage(pidStr))
                    closeQuietly()
                    return false // a live rival: the caller must exit
                }
                log.accept("Singleton: stale lock ($reason) — cleaning up")
                closeQuietly()
                lockFileObj.delete()
                try {
                    Thread.sleep(STALE_RETRY_DELAY_MS)
                } catch (e: InterruptedException) {
                    Thread.currentThread().interrupt()
                }
                raf = RandomAccessFile(lockFileObj, "rw")
                lockFile = raf
                lock = raf.channel.tryLock()
                fileLock = lock
                if (lock == null) {
                    log.accept("Singleton: retry after stale-lock cleanup still failed")
                    closeQuietly()
                    return false
                }
            }

            raf.seek(0)
            raf.setLength(0)
            raf.writeBytes(myPid.toString())
            return true
        } catch (e: Exception) {
            log.accept("Singleton: lock acquisition failed: " + e.message)
            closeQuietly()
            return false
        }
    }

    /** The PID string in the lock file, or null when it cannot be read. */
    private fun readPidQuietly(): String? = try {
        lockFile?.seek(0)
        lockFile?.readLine()
    } catch (e: Exception) {
        null
    }

    /**
     * Release the lock. Safe to call more than once.
     *
     * Deliberately does NOT delete the lock file, which is where this diverges from
     * `CameraDaemon.acquireSingletonLock` and `AccSentryDaemon`. Unlinking the path while another
     * process may already hold a lock on that inode is the classic double-winner race: the rival
     * keeps a lock on an orphaned inode while the next starter creates a fresh file and locks
     * that. A leftover file costs nothing — the next [acquire] finds no OS lock, takes it, and
     * overwrites the PID — and the clean-reinstall block in CLAUDE.md removes it by glob anyway.
     * Whoever consolidates the three implementations (BladeWatch-8d5u) must keep this behaviour
     * rather than adopting the older two.
     */
    fun release() {
        try {
            fileLock?.let { if (it.isValid) it.release() }
        } catch (ignored: Exception) {
            // Releasing a lock we no longer hold is not an error worth reporting.
        }
        fileLock = null
        closeQuietly()
    }

    private fun closeQuietly() {
        try {
            lockFile?.close()
        } catch (ignored: Exception) {
            // Nothing useful to do if the handle is already gone.
        }
        lockFile = null
    }

    companion object {

        /** Production liveness: the process directory exists. */
        @JvmField
        val PROC_LIVENESS = PidLiveness { pid -> File("/proc/$pid").exists() }

        /** Lets the kernel drop the inode lock before we retry on a fresh inode. */
        private const val STALE_RETRY_DELAY_MS = 200L

        /**
         * What to log when a live rival holds the lock.
         *
         * Carried over from CameraDaemon, which named the holder while the other two
         * implementations did not (BladeWatch-8d5u). "Something else holds the lock" sends an
         * operator to `ps`; "PID 9244 holds it" does not.
         *
         * Public rather than module-internal so the Java test in this package can reach it.
         */
        @JvmStatic
        fun liveRivalMessage(pidStr: String?): String {
            val trimmed = pidStr?.trim() ?: ""
            return "Singleton: live daemon PID " +
                (if (trimmed.isEmpty()) "(unreadable)" else trimmed) + " holds the lock"
        }

        /**
         * The actual stale-vs-live decision, over the PID string read from the lock file.
         *
         * Pure, and public for the same test reason, because it cannot be reached through
         * [acquire] in a JVM test: two locks on one file inside a single JVM raise
         * OverlappingFileLockException rather than returning null, so an end-to-end test
         * exercises the exception path and never this branch. A first attempt at testing it that
         * way passed against a mutated `if (false)` — i.e. it could not fail.
         *
         * @return null when a live rival holds the lock (the caller must exit), otherwise the
         *   reason it is reclaimable
         */
        @JvmStatic
        fun staleReason(pidStr: String?, myPid: Int, liveness: PidLiveness): String? {
            if (pidStr == null || pidStr.trim().isEmpty()) return "empty lock file"
            val pid = try {
                pidStr.trim().toInt()
            } catch (nfe: NumberFormatException) {
                return "corrupt PID in lock file"
            }
            if (pid == myPid) return "lock held by our own PID (previous crash)"
            if (!liveness.isAlive(pid)) return "dead PID $pid"
            return null
        }
    }
}
