package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-nmao.4: a marked recording must never be swept by automatic cleanup. Bookmarking
 * a clip and then having the retention sweep delete it is worse than having no bookmark.
 *
 * <p>{@code MarkedRecordingsStore}'s own persistence/de-dupe behaviour is covered directly by
 * {@code MarkedRecordingsStoreTest}. {@code StorageManager.ensureSpace} (the actual deletion
 * loop) operates on real on-disk directories under {@code /storage/emulated/0/...} and is not
 * practical to drive end-to-end in a JVM unit test -- this is a structural guard, modelled on
 * {@code NoUngatedTrunkOpenTest}, pinning that the deletion loop's body still consults the
 * store before deleting a file. A future refactor that drops that check would compile clean
 * and pass every other test, which is exactly the failure mode this exists to catch.
 */
public class MarkedRecordingsExcludedFromCleanupTest {

    @Test
    public void ensureSpaceDeletionLoopConsultsMarkedRecordingsStore() throws IOException {
        String source = read("storage/StorageManager.java");
        String body = extractMethodBody(source, ensureSpaceSignature(source));
        Assert.assertTrue(
                "StorageManager.ensureSpace() no longer references MarkedRecordingsStore -- "
                        + "the cleanup sweep can delete a bookmarked clip. Skip marked files in "
                        + "the deletion loop before deleting each candidate file.",
                body.contains("MarkedRecordingsStore"));
    }

    /**
     * BladeWatch-gv9v: excluding marked files from the sweep created a second, quieter way to
     * get the wrong answer. {@code selectFilesToDelete} returns an empty selection BOTH when
     * the pool is already under target AND when it is over target but every candidate was
     * skipped for being marked. An early {@code return true} keyed on the selection being
     * empty conflates the two: {@code ensureSpace} then claims space is available while the
     * category is still over its limit, and the early return also skips the
     * {@code ExternalStorageCleaner} CDR fallback further down. The pool size, which
     * {@code CleanupSelection} already carries, is the only thing that answers "are we within
     * the limit" — so that is what the early return must consult.
     */
    @Test
    public void ensureSpaceEarlyReturnIsKeyedOnPoolSizeNotOnAnEmptySelection() throws IOException {
        String source = read("storage/StorageManager.java");
        String body = extractMethodBody(source, ensureSpaceSignature(source));

        Assert.assertFalse(
                "StorageManager.ensureSpace() returns early on an empty selection. That is also "
                        + "what selectFilesToDelete returns when the pool is OVER target but every "
                        + "candidate is marked -- so ensureSpace reports success while still over "
                        + "the limit, and skips the CDR fallback. Key the early return on "
                        + "selection.poolSizeAtStart instead.",
                body.contains("selection.files.isEmpty()"));

        Assert.assertTrue(
                "StorageManager.ensureSpace() no longer compares selection.poolSizeAtStart "
                        + "against the target, so it cannot tell 'already within limit' apart "
                        + "from 'over limit but everything is marked'.",
                body.contains("selection.poolSizeAtStart <= targetSize"));
    }

    /**
     * The `ensureSpace` signature, in whichever language {@code StorageManager} is written in
     * today. Java spells it {@code private boolean ensureSpace(} and Kotlin
     * {@code private fun ensureSpace(} -- a guard that only knows one of them stops guarding the
     * moment the file is converted, without ever failing (BladeWatch-dmrg).
     */
    private static String ensureSpaceSignature(String source) {
        return source.contains("private boolean ensureSpace(")
                ? "private boolean ensureSpace(" : "private fun ensureSpace(";
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

    private static Path sourceRoot() {
        Path p = Path.of("src/main/java");
        if (!Files.isDirectory(p)) p = Path.of("app/src/main/java");
        Assert.assertTrue("could not locate the app sources from " + new File(".").getAbsolutePath(),
                Files.isDirectory(p));
        return p;
    }

    private static String extractMethodBody(String source, String signaturePrefix) {
        int sigIdx = source.indexOf(signaturePrefix);
        Assert.assertTrue("could not find method starting with '" + signaturePrefix + "' in source", sigIdx >= 0);
        int openBrace = source.indexOf('{', sigIdx);
        Assert.assertTrue("could not find opening brace after '" + signaturePrefix + "'", openBrace >= 0);
        int depth = 0;
        for (int i = openBrace; i < source.length(); i++) {
            char c = source.charAt(i);
            if (c == '{') {
                depth++;
            } else if (c == '}') {
                depth--;
                if (depth == 0) return source.substring(openBrace, i + 1);
            }
        }
        throw new AssertionError("unbalanced braces while extracting '" + signaturePrefix + "'");
    }
}
