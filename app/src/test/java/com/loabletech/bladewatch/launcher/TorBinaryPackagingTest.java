package net.bladewatch.app.launcher;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-3lbz.1: the Tor binary must be packaged, and the one it replaced must be gone.
 *
 * <p>Both tunnels ship the same way: a plain ELF executable placed in {@code jniLibs} under a
 * {@code lib*.so} name, so Android extracts it to the app's nativeLibraryDir with the execute
 * bit set. That is the only way to ship a runnable binary to a non-rooted head unit.
 *
 * <p>Unlike the 19.2 MB binary it replaces, tor is NOT committed — {@code downloadTor} in
 * {@code app/build.gradle.kts} fetches it from Maven Central and verifies its SHA-256, the same
 * pattern OpenH264 and OpenCV already use. This test is what makes that download load-bearing:
 * without it a build could silently package no tunnel at all.
 *
 * <p>NOTE for anyone touching this: the test reads {@code jniLibs} as DATA, not through the
 * classpath, so Gradle cannot see the dependency on its own. {@code app/build.gradle.kts}
 * declares that directory as an explicit test input; without it the task stays UP-TO-DATE when
 * the binary changes and this guard silently stops running.
 */
public class TorBinaryPackagingTest {

    /**
     * SHA-256 of {@code arm64-v8a/libtor.so} inside
     * {@code org.briarproject:tor-android:0.4.8.14}. Verified on the BYD head unit on
     * 2026-09-14: it runs as shell UID and reports "Tor version 0.4.8.14".
     */
    private static final String TOR_SHA256 =
            "9aa3a500bc3edd495cd33c61fd65d536f49b92692e16f6e23e3ada44e76a94a9";

    private static Path jniLibsDir() {
        Path p = Path.of("src/main/jniLibs/arm64-v8a");
        if (!Files.isDirectory(p)) p = Path.of("app/src/main/jniLibs/arm64-v8a");
        Assert.assertTrue("could not locate jniLibs from " + new File(".").getAbsolutePath(),
                Files.isDirectory(p));
        return p;
    }

    @Test
    public void torBinaryIsPackagedAndMatchesThePinnedChecksum() throws IOException {
        Path tor = jniLibsDir().resolve("libtor.so");
        Assert.assertTrue(
                "libtor.so is missing. The downloadTor Gradle task should have fetched it "
                        + "before the tests ran; run ./gradlew downloadTor.",
                Files.isRegularFile(tor));
        Assert.assertEquals(
                "libtor.so does not match the pinned checksum — refusing to ship an "
                        + "unverified tunnel binary.",
                TOR_SHA256, sha256Hex(tor));
    }

    @Test
    public void theReplacedTunnelBinaryIsNoLongerShipped() {
        // Named indirectly on purpose: NoRemovedTunnelReferencesTest bans the old name
        // from the tree, and this file would otherwise be its own violation.
        Path old = jniLibsDir().resolve("lib" + "z" + "rok.so");
        Assert.assertFalse(
                "The replaced tunnel binary is still present. Shipping it again adds "
                        + "19.2 MB and a dead tunnel.",
                Files.exists(old));
    }

    private static String sha256Hex(Path file) throws IOException {
        MessageDigest md;
        try {
            md = MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException e) {
            throw new AssertionError("SHA-256 unavailable", e);
        }
        byte[] digest = md.digest(Files.readAllBytes(file));
        StringBuilder sb = new StringBuilder(digest.length * 2);
        for (byte b : digest) {
            sb.append(Character.forDigit((b >> 4) & 0xf, 16));
            sb.append(Character.forDigit(b & 0xf, 16));
        }
        return sb.toString();
    }
}
