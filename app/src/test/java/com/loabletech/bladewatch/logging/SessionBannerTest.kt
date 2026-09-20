package net.bladewatch.app.logging

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-gn2y: every log must say which build wrote it, and where one run ends.
 *
 * ## The failure this prevents
 *
 * On 2026-09-15 an audit of the head unit's logs found two `[CRASH] UncaughtException`
 * entries in `debug_app.log` for the StatusOverlayService null-launch-intent NPE — a real,
 * process-killing bug. They were dated 09-14 and came from a build whose UI no longer
 * exists: the crash is fixed and regression-tested (`NoSelfLaunchIntentTest`). Nothing in
 * the file said so. The only things separating "broken now" from "broken last Tuesday" were
 * the timestamps and a passing reference to `StartupFragment`, a class that has since been
 * deleted.
 *
 * That file already rotates — 5 MB, 3 generations — but a low-volume log takes weeks to
 * reach 5 MB, so four days and several builds shared one file with no marker between them.
 * Size-based rotation was never the missing piece; a per-run banner is.
 *
 * Anyone handed the log alone, human or agent, would have reported that crash as current.
 */
class SessionBannerTest {

    @Test
    fun `banner names the version, branch and build type`() {
        val banner = SessionBanner.format(
            version = "1.3.2.0",
            branch = "feature/v1.3.2.0",
            buildType = "debug",
            timestamp = "2026-09-15 10:30:00.000",
            process = "service-host",
        )

        assertTrue("must name the version: $banner", banner.contains("1.3.2.0"))
        assertTrue("must name the branch: $banner", banner.contains("feature/v1.3.2.0"))
        assertTrue("must name the build type: $banner", banner.contains("debug"))
        assertTrue("must name the process: $banner", banner.contains("service-host"))
        assertTrue("must be timestamped like every other line: $banner",
            banner.contains("2026-09-15 10:30:00.000"))
    }

    /**
     * It has to be findable by eye in a wall of text, and greppable by a script that wants
     * to read only the current run. A line that looks like every other line would not have
     * helped the audit above.
     */
    @Test
    fun `banner is visually and textually distinctive`() {
        val banner = SessionBanner.format(
            version = "1.3.2.0", branch = "main", buildType = "release",
            timestamp = "2026-09-15 10:30:00.000", process = "camera-daemon",
        )

        assertTrue("needs a scannable marker: $banner", banner.contains(SessionBanner.MARKER))
        assertTrue("a rule makes the boundary visible when skimming: $banner",
            banner.contains("====="))
    }

    /** Unknown metadata must not produce a blank or misleading banner. */
    @Test
    fun `banner degrades to something honest when metadata is missing`() {
        val banner = SessionBanner.format(
            version = "", branch = "", buildType = "",
            timestamp = "2026-09-15 10:30:00.000", process = "camera-daemon",
        )

        assertTrue("must still carry the marker: $banner", banner.contains(SessionBanner.MARKER))
        assertTrue("empty metadata must read as unknown, not as a blank: $banner",
            banner.contains("unknown"))
    }

    /**
     * Grepping for the marker is how a reader isolates the current run, so it must appear
     * exactly once per banner — not once per field.
     */
    @Test
    fun `marker appears exactly once`() {
        val banner = SessionBanner.format(
            version = "1.3.2.0", branch = "main", buildType = "debug",
            timestamp = "2026-09-15 10:30:00.000", process = "service-host",
        )

        assertEquals(1, banner.split(SessionBanner.MARKER).size - 1)
    }
}
