package net.bladewatch.app.manifest;

import java.io.File;
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
 * BladeWatch-81g9.1: nothing in the daemon APK may resolve its OWN launcher intent.
 *
 * <p>Phase 4 removed this package's launcher entry, so
 * {@code getPackageManager().getLaunchIntentForPackage(getPackageName())} now returns
 * <b>null</b>. That is not a quiet degradation — feeding a null Intent to
 * {@code PendingIntent.getActivity} throws {@code NullPointerException} deep inside
 * {@code Intent.migrateExtraStreamToClipData}.
 *
 * <p>It happened: {@code StatusOverlayService.buildNotification()} did exactly this, the
 * NPE escaped {@code onStartCommand}, and the whole process died ~2 seconds after launch —
 * taking the startup bootstrap and the daemon launch with it. On a head unit that means no
 * recording, and nothing on screen to explain why. It was found only by a real cold-boot
 * test, because no unit test and no compiler can see it.
 *
 * <p>Looking up the FLUTTER package's launcher intent is fine and expected — that package
 * does have one. This bans looking up our own.
 */
public class NoSelfLaunchIntentTest {

    private static final String BANNED = "getLaunchIntentForPackage(getPackageName())";

    private static Path sourceRoot() {
        Path p = Path.of("src/main/java");
        if (!Files.isDirectory(p)) p = Path.of("app/src/main/java");
        Assert.assertTrue("could not locate the app sources from "
                + new File(".").getAbsolutePath(), Files.isDirectory(p));
        return p;
    }

    @Test
    public void noComponentResolvesThisPackagesOwnLauncherIntent() throws IOException {
        List<String> offenders = new ArrayList<>();
        try (Stream<Path> files = Files.walk(sourceRoot())) {
            for (Path f : (Iterable<Path>) files.filter(Files::isRegularFile)
                    .filter(p -> {
                        String n = p.getFileName().toString();
                        return n.endsWith(".java") || n.endsWith(".kt");
                    })::iterator) {
                String body = new String(Files.readAllBytes(f), StandardCharsets.UTF_8);
                // Strip the ban string out of comments so the explanation above, and the
                // one in StatusOverlayService, do not trip the check they document.
                if (containsOutsideComments(body, BANNED)) {
                    offenders.add(f.toString());
                }
            }
        }
        Assert.assertTrue(
                "These resolve the daemon APK's own launcher intent, which is null after "
                        + "Phase 4 and throws NPE when handed to PendingIntent.getActivity: "
                        + offenders,
                offenders.isEmpty());
    }

    /** True if {@code needle} appears on a line that is not a comment. */
    private static boolean containsOutsideComments(String body, String needle) {
        for (String line : body.split("\n")) {
            String t = line.trim();
            if (t.startsWith("//") || t.startsWith("*") || t.startsWith("/*")) continue;
            if (line.contains(needle)) return true;
        }
        return false;
    }
}
