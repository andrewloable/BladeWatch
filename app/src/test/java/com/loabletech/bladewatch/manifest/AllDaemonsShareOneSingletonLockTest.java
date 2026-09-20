package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-8d5u: one singleton-lock implementation, not three.
 *
 * <p>Each of the three shell-launched daemons had its own. {@code SentryDaemon} had none at all
 * until BladeWatch-f0y3 and ran twice on the head unit (PIDs 9244 and 9351, one second apart).
 * {@code AccSentryDaemon}'s had no stale handling, so a lock naming a dead PID could only be
 * cleared by hand. Only {@code CameraDaemon}'s was complete, and it is the one
 * {@link net.bladewatch.app.daemon.DaemonSingletonLock} was extracted from.
 *
 * <p>Three copies is how the first one drifted. This pins that none of them grows a private
 * {@code FileLock} again — a regression that would compile cleanly and pass every behavioural
 * test, because nothing else exercises two daemons racing for one lock file.
 *
 * <p>Read as source TEXT: these classes need the BYD HAL and a live camera and cannot be built
 * on the JVM. {@code app/build.gradle.kts} declares {@code src/main/java} as a test input, so
 * this re-runs when they change.
 */
public class AllDaemonsShareOneSingletonLockTest {

    private static final String[] DAEMONS = {
        "CameraDaemon.java", "SentryDaemon.java", "AccSentryDaemon.java",
    };

    @Test
    public void everyDaemonUsesTheSharedLock() throws IOException {
        for (String daemon : DAEMONS) {
            String src = stripComments(read("daemon/" + daemon));
            Assert.assertTrue(daemon + " does not use DaemonSingletonLock. All three daemons "
                    + "share one implementation (BladeWatch-8d5u); a private copy is how the "
                    + "first one drifted.", src.contains("DaemonSingletonLock"));
        }
    }

    @Test
    public void noDaemonHoldsItsOwnFileLock() throws IOException {
        for (String daemon : DAEMONS) {
            String src = stripComments(read("daemon/" + daemon));
            Assert.assertFalse(daemon + " calls tryLock() itself. Locking belongs to "
                    + "DaemonSingletonLock, which also owns the stale-lock reclaim learned on "
                    + "this hardware (BladeWatch-8d5u).", src.contains("tryLock()"));
            Assert.assertFalse(daemon + " declares its own java.nio FileLock field. The lock "
                    + "handle belongs to DaemonSingletonLock (BladeWatch-8d5u).",
                    src.contains("java.nio.channels.FileLock "));
        }
    }

    /**
     * The lock PATHS are load-bearing: the clean-reinstall block in CLAUDE.md removes them by
     * glob, so renaming one silently breaks that cleanup and leaves a daemon unable to restart
     * after a SIGKILL.
     */
    @Test
    public void theLockPathsAreUnchanged() throws IOException {
        Assert.assertTrue(read("daemon/CameraDaemon.java")
                .contains("\"/data/local/tmp/camera_daemon.lock\""));
        Assert.assertTrue(read("daemon/SentryDaemon.java")
                .contains("\"/data/local/tmp/sentry_daemon.lock\""));
        Assert.assertTrue(read("daemon/AccSentryDaemon.java")
                .contains("\"/data/local/tmp/acc_sentry_daemon.lock\""));
    }

    /** Removes comments so the assertions read CODE, not prose. */
    private static String stripComments(String java) {
        return java.replaceAll("(?s)/\\*.*?\\*/", " ").replaceAll("(?m)//.*$", " ");
    }

    private static Path sourceRoot() {
        Path p = Path.of("src/main/java");
        if (!Files.isDirectory(p)) p = Path.of("app/src/main/java");
        Assert.assertTrue("could not locate the app sources from "
                + new File(".").getAbsolutePath(), Files.isDirectory(p));
        return p;
    }

    /**
     * Read a source file by path, in whichever language it is written in today. The extension in
     * the argument is advisory: the app sources are migrating from Java to Kotlin
     * (BladeWatch-dmrg), and a guard that keeps asking for a ".java" that no longer exists stops
     * guarding without ever failing. Both spellings present means a half-finished conversion, and
     * this would read the stale copy.
     */
    private static String read(String relative) throws IOException {
        int dot = relative.lastIndexOf('.');
        String base = relative.endsWith(".java") || relative.endsWith(".kt")
                ? relative.substring(0, dot) : relative;
        Path dir = sourceRoot().resolve("com/loabletech/bladewatch");
        Path java = dir.resolve(base + ".java");
        Path kotlin = dir.resolve(base + ".kt");
        boolean hasJava = Files.isRegularFile(java);
        boolean hasKotlin = Files.isRegularFile(kotlin);
        Assert.assertTrue("missing source file (.java or .kt): " + dir.resolve(base),
                hasJava || hasKotlin);
        Assert.assertFalse("both a .java and a .kt exist for " + base
                + " -- a half-finished conversion; this guard would read the stale copy",
                hasJava && hasKotlin);
        return new String(Files.readAllBytes(hasJava ? java : kotlin), StandardCharsets.UTF_8);
    }
}
