package net.bladewatch.app.daemon;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.util.HashSet;
import java.util.Set;

import org.junit.Test;

/**
 * BladeWatch-f0y3: two SentryDaemon instances ran concurrently on the head unit (PIDs 9244 and
 * 9351, one second apart). Its guard was {@code isDaemonRunning()} — a PING to the control port,
 * which is a liveness probe, not mutual exclusion: both processes probed before either had bound
 * the port, both saw nobody home, and both proceeded.
 *
 * <p>A real lock closes that window. This exercises the decision logic against a temp directory
 * with the PID-liveness predicate injected, because {@code /proc} and the device's tmpfs are not
 * available to a JVM test.
 */
public class DaemonSingletonLockTest {

    /** Nothing is alive unless a test says so. */
    private static final class FakeLiveness implements DaemonSingletonLock.PidLiveness {
        final Set<Integer> alive = new HashSet<>();
        @Override public boolean isAlive(int pid) { return alive.contains(pid); }
    }

    private File lockPath() throws IOException {
        File dir = Files.createTempDirectory("singleton-lock-test").toFile();
        return new File(dir, "sentry_daemon.lock");
    }

    // ── the stale-vs-live decision ───────────────────────────────────────
    //
    // Asserted directly rather than through acquire(). Two locks on one file inside a single
    // JVM raise OverlappingFileLockException instead of returning null, so an end-to-end test
    // exercises the exception path and never reaches this branch. The first version of this
    // test did exactly that and passed against a mutated `if (false)` — it could not fail.

    @Test
    public void aLiveRivalHoldingTheLockMeansWeMustExit() {
        FakeLiveness live = new FakeLiveness();
        live.alive.add(9244);   // the other SentryDaemon observed on the head unit

        assertNull("a live holder is not stale — the second daemon must refuse to start",
                DaemonSingletonLock.staleReason("9244", 9351, live));
    }

    @Test
    public void aDeadHoldersLockIsReclaimable() {
        FakeLiveness live = new FakeLiveness();   // 9244 is NOT alive
        String reason = DaemonSingletonLock.staleReason("9244", 9351, live);
        assertNotNull("a dead holder must be reclaimable or the daemon can never restart", reason);
        assertTrue(reason.contains("dead PID"));
    }

    @Test
    public void ourOwnPidInTheLockMeansAPreviousCrash() {
        FakeLiveness live = new FakeLiveness();
        live.alive.add(9351);
        assertNotNull(DaemonSingletonLock.staleReason("9351", 9351, live));
    }

    @Test
    public void junkInTheLockFileIsReclaimableRatherThanWedging() {
        FakeLiveness live = new FakeLiveness();
        assertNotNull(DaemonSingletonLock.staleReason(null, 1, live));
        assertNotNull(DaemonSingletonLock.staleReason("", 1, live));
        assertNotNull(DaemonSingletonLock.staleReason("   ", 1, live));
        assertNotNull(DaemonSingletonLock.staleReason("not-a-pid", 1, live));
    }

    @Test
    public void firstAcquirerWins() throws Exception {
        File path = lockPath();
        DaemonSingletonLock first = new DaemonSingletonLock(path, 100, new FakeLiveness(), m -> { });
        assertTrue("the first daemon must get the lock", first.acquire());
        first.release();
    }

    @Test
    public void aLiveRivalIsNamedByPidSoAnOperatorCanFindIt() {
        // CameraDaemon logged "live daemon PID N holds the lock" and the shared class did not.
        // Consolidating onto it (BladeWatch-8d5u) must not lose that: "something else holds the
        // lock" sends you to ps, "PID 9244 holds it" does not.
        assertTrue(DaemonSingletonLock.liveRivalMessage("9244").contains("9244"));
    }

    @Test
    public void anUnreadablePidStillProducesAUsableMessage() {
        // The live branch is reached whenever a rival holds the OS lock, including when the PID
        // in the file is junk. The message must still make sense rather than reading "PID null".
        assertFalse(DaemonSingletonLock.liveRivalMessage(null).contains("null"));
        assertFalse(DaemonSingletonLock.liveRivalMessage("   ").contains("  holds"));
    }

    // ── acquire() over a leftover lock FILE ──────────────────────────────
    //
    // These do NOT exercise staleReason and must not be read as if they did. When the previous
    // holder is gone the kernel has already dropped its lock on the inode, so tryLock() simply
    // succeeds and the stale branch is never entered. Verified by mutation: with staleReason
    // stubbed to "always a live rival" these three still pass, while the three direct tests
    // above all fail. What they pin is the other half of the same requirement -- a leftover
    // file, whatever it contains, must not wedge startup.

    @Test
    public void aLockFileLeftByADeadProcessDoesNotBlockStartup() throws Exception {
        File path = lockPath();
        Files.write(path.toPath(), "100".getBytes());   // what a SIGKILLed daemon leaves behind

        DaemonSingletonLock restarted =
                new DaemonSingletonLock(path, 300, new FakeLiveness(), m -> { });
        assertTrue("a dead holder's lock file must not stop the daemon restarting",
                restarted.acquire());
        restarted.release();
    }

    @Test
    public void aLockFileNamingOurOwnPidDoesNotBlockStartup() throws Exception {
        File path = lockPath();
        Files.write(path.toPath(), "500".getBytes());
        FakeLiveness live = new FakeLiveness();
        live.alive.add(500);   // our own PID is of course "alive"

        DaemonSingletonLock self = new DaemonSingletonLock(path, 500, live, m -> { });
        assertTrue("our own PID in the lock means a previous crash, not a rival", self.acquire());
        self.release();
    }

    @Test
    public void aCorruptOrEmptyLockFileDoesNotWedgeStartup() throws Exception {
        for (String junk : new String[] { "", "   ", "not-a-pid" }) {
            File path = lockPath();
            Files.write(path.toPath(), junk.getBytes());
            DaemonSingletonLock lock =
                    new DaemonSingletonLock(path, 700, new FakeLiveness(), m -> { });
            assertTrue("junk lock content (" + junk + ") must not block startup", lock.acquire());
            lock.release();
        }
    }

    @Test
    public void theHolderPidIsRecordedSoAnOperatorCanSeeWhoHasIt() throws Exception {
        File path = lockPath();
        DaemonSingletonLock lock = new DaemonSingletonLock(path, 4242, new FakeLiveness(), m -> { });
        assertTrue(lock.acquire());

        assertEquals("4242", new String(Files.readAllBytes(path.toPath())).trim());
        lock.release();
    }

    @Test
    public void releaseAllowsAFreshAcquire() throws Exception {
        File path = lockPath();
        FakeLiveness live = new FakeLiveness();

        DaemonSingletonLock a = new DaemonSingletonLock(path, 100, live, m -> { });
        assertTrue(a.acquire());
        a.release();

        DaemonSingletonLock b = new DaemonSingletonLock(path, 200, live, m -> { });
        assertTrue("after a clean release the next daemon must start", b.acquire());
        b.release();
    }
}
