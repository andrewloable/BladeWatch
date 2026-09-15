package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Stream;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-3lbz.6: the previous tunnel is gone; keep it gone.
 *
 * <p>Its removal touched five APK source trees, twenty locale catalogues, fourteen
 * documents and a Gradle file. A migration that wide leaves stragglers, and a straggler
 * here is not cosmetic: a stale kill command, a dead log path in a settings row, or a
 * document telling the next person to configure an account that no longer exists.
 *
 * <p>This also stops it coming BACK. A future agent reading an old doc, an old commit or
 * a stale memory could reintroduce the name in perfectly good faith; the build should say
 * no. The single allowed mention is the one in {@code AuthMiddleware}, which explains a
 * security decision that only makes sense if you know what the old tunnel did — the same
 * convention {@code AdbDaemonLauncher} uses to record the sing-box removal.
 *
 * <p><b>Gradle up-to-date blindness:</b> this test reads the tree as DATA, not through the
 * classpath, so Gradle cannot infer the dependency. {@code app/build.gradle.kts} declares
 * the scanned directories as explicit test inputs. Without that the task stays UP-TO-DATE
 * when the files change — which is exactly when the guard matters. A guard that cannot
 * fail is worse than no guard, because it is believed.
 */
public class NoRemovedTunnelReferencesTest {

    /** Assembled at runtime so this file is not itself a match. */
    private static final String BANNED = "z" + "rok";

    /**
     * The one file allowed to say it, and why. Pinned to the exact path so a second
     * occurrence anywhere — including elsewhere in this same file — still fails.
     */
    private static final String ALLOWED_FILE = "AuthMiddleware.java";
    private static final int ALLOWED_OCCURRENCES = 1;

    /** Everything a developer edits. Build output and dependencies are not ours to police. */
    private static final String[] SCANNED = {
        "app/src/main", "app/src/test",
        "flutter_ui/lib", "flutter_ui/test",
        "flutter_ui/android/app/src",
        "web/src", "web/e2e",
        "docs",
    };

    /**
     * Skipped: developer-local, gitignored, and legitimately holds a real tunnel URL for
     * whoever is running the end-to-end suite. Not ours to police.
     */
    private static final String SKIPPED_FILENAME = ".env";

    private static final String[] SCANNED_FILES = {
        "CLAUDE.md", "Readme.md", "AGENTS.md", "app/build.gradle.kts", ".gitignore",
    };

    private static Path repoRoot() {
        // Tests run with the module directory as the working directory, but tooling
        // sometimes uses the repo root. Accept either rather than guessing.
        Path here = Path.of("").toAbsolutePath();
        if (Files.isDirectory(here.resolve("app/src/main"))) return here;
        Path parent = here.getParent();
        if (parent != null && Files.isDirectory(parent.resolve("app/src/main"))) return parent;
        throw new AssertionError("could not locate the repo root from " + here);
    }

    @Test
    public void theRemovedTunnelIsNotMentionedAnywhereItStillMatters() throws IOException {
        Path root = repoRoot();
        List<String> offenders = new ArrayList<>();
        int allowedSeen = 0;

        List<Path> targets = new ArrayList<>();
        for (String dir : SCANNED) {
            Path p = root.resolve(dir);
            if (!Files.isDirectory(p)) continue;
            try (Stream<Path> files = Files.walk(p)) {
                files.filter(Files::isRegularFile).forEach(targets::add);
            }
        }
        for (String f : SCANNED_FILES) {
            Path p = root.resolve(f);
            if (Files.isRegularFile(p)) targets.add(p);
        }

        for (Path f : targets) {
            if (isProbablyBinary(f)) continue;
            if (f.getFileName().toString().equals(SKIPPED_FILENAME)) continue;
            String body;
            try {
                body = new String(Files.readAllBytes(f), StandardCharsets.UTF_8);
            } catch (IOException e) {
                continue;
            }
            int count = countOccurrences(body.toLowerCase(Locale.ROOT), BANNED);
            if (count == 0) continue;
            if (f.getFileName().toString().equals(ALLOWED_FILE) && count <= ALLOWED_OCCURRENCES) {
                allowedSeen += count;
                continue;
            }
            offenders.add(root.relativize(f) + " (" + count + ")");
        }

        Assert.assertTrue(
                "The previous tunnel is gone — these still refer to it. Update them rather "
                        + "than widening this allow-list: " + offenders,
                offenders.isEmpty());
        Assert.assertEquals(
                "The explanatory mention in " + ALLOWED_FILE + " has disappeared. If it was "
                        + "deliberately removed, drop the allow-list entry too so the next "
                        + "reference is caught.",
                ALLOWED_OCCURRENCES, allowedSeen);
    }

    /** Cheap check: NUL in the first 8 KB means it is not source or prose. */
    private static boolean isProbablyBinary(Path f) {
        try {
            byte[] head = new byte[8192];
            try (java.io.InputStream in = Files.newInputStream(f)) {
                int read = in.read(head);
                for (int i = 0; i < read; i++) {
                    if (head[i] == 0) return true;
                }
            }
            return false;
        } catch (IOException e) {
            return true;
        }
    }

    private static int countOccurrences(String haystack, String needle) {
        int count = 0;
        int i = haystack.indexOf(needle);
        while (i >= 0) {
            count++;
            i = haystack.indexOf(needle, i + needle.length());
        }
        return count;
    }

    @Test
    public void theGuardActuallyScansSomething() throws IOException {
        // Cheap sanity check against the failure mode where a bad path or a wrong working
        // directory makes the scan silently cover nothing and pass forever.
        Path root = repoRoot();
        int found = 0;
        for (String dir : SCANNED) {
            if (Files.isDirectory(root.resolve(dir))) found++;
        }
        Assert.assertTrue("the scanned directories do not exist — this guard is scanning "
                + "nothing and would pass no matter what. Root was " + root,
                found >= SCANNED.length - 1);
        Assert.assertTrue("expected " + new File(root.toFile(), "CLAUDE.md") + " to exist",
                Files.isRegularFile(root.resolve("CLAUDE.md")));
    }
}
