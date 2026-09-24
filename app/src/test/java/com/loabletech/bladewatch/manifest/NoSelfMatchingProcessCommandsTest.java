package net.bladewatch.app.manifest;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-6jj1: no shell command anywhere may match the shell that issues it.
 *
 * <p>toybox {@code pkill -f} / {@code pgrep -f} match the pattern as a literal SUBSTRING of
 * every {@code /proc/<pid>/cmdline}. Every such command in this project is delivered as
 * {@code adb shell <script>}, so the issuing shell's cmdline IS the script, pattern
 * included — it matches itself. Measured on the head unit on 2026-09-15 with a marker
 * string matching no process at all:
 *
 * <pre>
 *   $ adb shell "echo start; pkill -9 -f 'bwprobe_marker_xyz'; echo SHOULD PRINT"
 *   start
 *   (exit 137 — SIGKILL; the second echo never ran)
 * </pre>
 *
 * <p>The consequences were silent in both directions. A {@code pkill -f} ended the script at
 * its FIRST clause, so every later kill, every {@code rm} and the {@code echo done} a
 * callback waited on became dead code — the hard reset killed nothing and reported failure,
 * and tapping "Kill Sentry" in the Diagnostics console killed the user's own session. A
 * {@code pgrep -f} answered "running" unconditionally, which made the tunnel's liveness
 * probe permanently true and stopped it ever being started.
 *
 * <p>Use {@code DaemonKillCommands} instead: {@code killall}/{@code pidof} match {@code comm}
 * or {@code basename(argv[0])}, both "sh" for the issuing shell, so they cannot self-match.
 * Where a cmdline match is genuinely unavoidable — the watchdog scripts all run as "sh" —
 * {@code killMatchingCmdline} uses {@code grep -E}, which takes a REGEX, so a bracketed
 * pattern does not match its own literal text. That distinction is the whole reason the
 * bracket trick works for grep and fails for {@code pkill -f}.
 *
 * <p>This scans source as DATA; {@code app/build.gradle.kts} declares the directories as
 * explicit test inputs, or the guard would go UP-TO-DATE exactly when it matters.
 */
public class NoSelfMatchingProcessCommandsTest {

    /**
     * Trees whose contents end up inside a shell command on the head unit. bladewatch_rpc is
     * flutter_ui/lib/rpc, moved (BladeWatch-rdtj.10); companion/ never runs on the head unit.
     */
    private static final String[] SCANNED = {
        "app/src/main/java", "flutter_ui/lib", "packages/bladewatch_rpc/lib",
        "flutter_ui/android/app/src/main/kotlin",
    };

    /** The banned forms, assembled so this file is not its own violation. */
    private static final String[] BANNED = {"pkill" + " -f", "pkill -9" + " -f", "pgrep" + " -f"};

    private static Path repoRoot() {
        Path here = Path.of("").toAbsolutePath();
        if (Files.isDirectory(here.resolve("app/src/main"))) return here;
        Path parent = here.getParent();
        if (parent != null && Files.isDirectory(parent.resolve("app/src/main"))) return parent;
        throw new AssertionError("could not locate the repo root from " + here);
    }

    @Test
    public void noSourceIssuesACommandThatCanMatchItsOwnShell() throws IOException {
        Path root = repoRoot();
        List<String> offenders = new ArrayList<>();
        int scanned = 0;

        for (String dir : SCANNED) {
            Path p = root.resolve(dir);
            if (!Files.isDirectory(p)) continue;
            try (Stream<Path> files = Files.walk(p)) {
                for (Path f : (Iterable<Path>) files.filter(Files::isRegularFile)::iterator) {
                    String name = f.getFileName().toString();
                    if (!name.endsWith(".kt") && !name.endsWith(".java") && !name.endsWith(".dart")) {
                        continue;
                    }
                    scanned++;
                    String body = new String(Files.readAllBytes(f), StandardCharsets.UTF_8);
                    for (String line : body.split("\n")) {
                        String t = line.trim();
                        // Prose is allowed to name the trap — that is how the next person
                        // learns why it is banned. Only executable text is policed.
                        if (t.startsWith("//") || t.startsWith("*") || t.startsWith("/*")) continue;
                        for (String banned : BANNED) {
                            if (line.contains(banned)) {
                                offenders.add(root.relativize(f) + ": " + t);
                            }
                        }
                    }
                }
            }
        }

        Assert.assertTrue("the scan covered nothing — a guard that cannot fail is worse than "
                + "no guard", scanned > 50);
        Assert.assertTrue(
                "These match the ADB shell that issues them and kill it (or, for pgrep, "
                        + "answer about it). Use DaemonKillCommands — killall/pidof match "
                        + "comm or argv[0], which are \"sh\" here, so they cannot self-match. "
                        + "Offenders: " + offenders,
                offenders.isEmpty());
    }
}
