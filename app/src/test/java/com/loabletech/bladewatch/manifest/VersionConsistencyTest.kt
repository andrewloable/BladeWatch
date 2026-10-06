package net.bladewatch.app.manifest

import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-a7mu.9: every app and every platform binary shows the same release version.
 *
 * BladeWatch versions have four parts (1.4.1.3) and pub rejects that in pubspec.yaml, so the
 * four-part string is written out by hand per platform, and nothing kept those files in step: the
 * build docs still said 1.4.0.0 at 1.4.1.2. app/build.gradle.kts is the reference; its versionCode
 * encodes all four parts (major * 10000 + minor * 1000 + patch * 100 + fourth), which is also how
 * the companion's About screen rebuilds the fourth part on Linux, where only pubspec's three parts
 * and the build number are known.
 *
 * Every file read here is a declared test input in app/build.gradle.kts (VERSION_FILES), or this
 * guard would go UP-TO-DATE exactly when one of them drifts.
 */
class VersionConsistencyTest {

    private val root: File = run {
        val here = Path.of("").toAbsolutePath()
        when {
            Files.isDirectory(here.resolve("app/src/main")) -> here
            here.parent != null && Files.isDirectory(here.parent.resolve("app/src/main")) -> here.parent
            else -> throw AssertionError("could not locate the repo root from $here")
        }.toFile()
    }

    private fun read(rel: String): String = File(root, rel).readText()

    private fun single(rel: String, pattern: Regex): String {
        val found = pattern.findAll(read(rel)).map { it.groupValues[1] }.toList()
        assertEquals("$rel: expected exactly one match of $pattern, found $found", 1, found.size)
        return found.single()
    }

    private val versionName = single("app/build.gradle.kts", Regex("""\bversionName = "([0-9.]+)""""))
    private val versionCode = single("app/build.gradle.kts", Regex("""\bversionCode = (\d+)\b""")).toInt()
    private val parts = versionName.split('.').map { it.toInt() }
    private val threeParts = parts.take(3).joinToString(".")

    @Test
    fun `the release version has four parts and the build number encodes them`() {
        assertEquals("versionName $versionName", 4, parts.size)
        assertEquals(parts[0] * 10000 + parts[1] * 1000 + parts[2] * 100 + parts[3], versionCode)
    }

    @Test
    fun `both pubspecs carry the first three parts and the build number`() {
        for (rel in listOf("flutter_ui/pubspec.yaml", "companion/pubspec.yaml")) {
            assertEquals(rel, "$threeParts+$versionCode", single(rel, Regex("""(?m)^version: (\S+)$""")))
        }
    }

    @Test
    fun `both Android builds of the Flutter apps name the four-part version`() {
        for (rel in listOf("flutter_ui/android/app/build.gradle.kts", "companion/android/app/build.gradle.kts")) {
            assertEquals(rel, versionName, single(rel, Regex("""\bversionName = "([0-9.]+)"""")))
        }
    }

    @Test
    fun `iOS and macOS show the four-part version`() {
        val shortVersion = Regex("""<key>CFBundleShortVersionString</key>\s*(?:<!--.*?-->\s*)?<string>([^<]+)</string>""",
            RegexOption.DOT_MATCHES_ALL)
        for (rel in listOf("companion/ios/Runner/Info.plist", "companion/macos/Runner/Info.plist")) {
            assertEquals(rel, versionName, single(rel, shortVersion))
        }
    }

    @Test
    fun `Windows shows the four-part version`() {
        val rel = "companion/windows/runner/Runner.rc"
        assertEquals(parts.joinToString(","), single(rel, Regex("""#define VERSION_AS_NUMBER (\S+)""")))
        assertEquals(versionName, single(rel, Regex("""#define VERSION_AS_STRING "([^"]+)"""")))
    }

    @Test
    fun `the build docs state the current version`() {
        val docs = read("docs/build-and-operations.md")
        val stated = "- Version: `versionName = \"$versionName\"`, `versionCode = $versionCode`."
        assertEquals("docs/build-and-operations.md must say: $stated", true, docs.contains(stated))
    }
}
