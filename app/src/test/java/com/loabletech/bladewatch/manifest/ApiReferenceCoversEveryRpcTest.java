package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-7m7t: {@code docs/http-api-reference.md}'s service table is the index people use to
 * find an RPC, and nothing kept it honest. Three RPCs added on one branch
 * ({@code MarkRecording}, {@code SetScreen}, {@code SetMediaVolume}) reached the dispatcher while
 * a fourth added in the same work ({@code PreviewStorageLimitChange}) was documented — a partial
 * update, which is the hardest kind of drift to notice afterwards.
 *
 * <p>This reads both sides as DATA: every {@code dispatcher.register("bladewatch.v1.X", "Y", ...)}
 * in the Connect impls, and the doc. {@code app/build.gradle.kts} already declares both
 * {@code src/main/java} and the repo's {@code docs} directory as test inputs, so this re-runs when
 * either side changes rather than going UP-TO-DATE exactly when it matters.
 *
 * <p>Deliberately scoped to the RPC-name column only. The table's path column uses wildcards
 * ({@code /api/vehicle/*}, {@code /api/recordings*}) on purpose, so asserting exact paths would
 * demand documenting roughly a dozen pre-existing routes those wildcards already cover — a
 * separate decision, not this guard's job.
 */
public class ApiReferenceCoversEveryRpcTest {

    private static final Pattern REGISTER = Pattern.compile(
            "dispatcher\\.register\\(\\s*\"bladewatch\\.v1\\.[A-Za-z]+\"\\s*,\\s*\"([A-Za-z]+)\"");

    @Test
    public void everyRegisteredRpcAppearsInTheApiReference() throws IOException {
        String doc = new String(Files.readAllBytes(apiReference()), StandardCharsets.UTF_8);

        Set<String> registered = new TreeSet<>();
        for (Path impl : connectImpls()) {
            Matcher m = REGISTER.matcher(
                    new String(Files.readAllBytes(impl), StandardCharsets.UTF_8));
            while (m.find()) {
                registered.add(m.group(1));
            }
        }
        Assert.assertTrue("found no dispatcher.register calls at all -- this guard has stopped "
                + "reading the Connect impls and can no longer fail", registered.size() > 50);

        List<String> undocumented = new ArrayList<>();
        for (String rpc : registered) {
            // Backticked, as every RPC in the table is written -- a bare match would be
            // satisfied by prose mentioning the name in passing.
            if (!doc.contains("`" + rpc + "`")) {
                undocumented.add(rpc);
            }
        }

        Assert.assertEquals(
                "These RPCs are registered with the Connect dispatcher but missing from "
                        + "docs/http-api-reference.md's service table. Add them to the row for "
                        + "their service -- see this project's Documentation Maintenance rule "
                        + "(HTTP route changes -> http-api-reference.md). Undocumented: "
                        + undocumented,
                List.of(), undocumented);
    }

    private static Path apiReference() {
        Path p = Path.of("docs/http-api-reference.md");
        if (!Files.isRegularFile(p)) p = Path.of("../docs/http-api-reference.md");
        Assert.assertTrue("could not locate docs/http-api-reference.md from "
                + new File(".").getAbsolutePath(), Files.isRegularFile(p));
        return p;
    }

    private static List<Path> connectImpls() throws IOException {
        Path root = Path.of("src/main/java");
        if (!Files.isDirectory(root)) root = Path.of("app/src/main/java");
        Assert.assertTrue("could not locate the app sources from "
                + new File(".").getAbsolutePath(), Files.isDirectory(root));
        Path impls = root.resolve("com/loabletech/bladewatch/server/connect/impl");
        Assert.assertTrue("missing Connect impl directory: " + impls, Files.isDirectory(impls));
        try (Stream<Path> s = Files.list(impls)) {
            return s.filter(p -> p.getFileName().toString().endsWith(".java"))
                    .collect(Collectors.toList());
        }
    }
}
