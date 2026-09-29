package net.bladewatch.app.daemon

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.Closeable

/** BladeWatch-rdtj.66: what an SD-card unmount's SIGINT closes, and the JVM (no native library). */
class SdCardSignalTest {
    private class File(val throws: Boolean = false) : Closeable {
        var closed = false
        override fun close() {
            closed = true
            if (throws) throw java.io.IOException("already gone")
        }
    }

    @Test
    fun closeAllClosesEveryServedFileOnceAndForgetsThem() {
        OpenMediaFiles.closeAll()
        val a = OpenMediaFiles.track(File())
        val b = OpenMediaFiles.track(File(throws = true))
        val done = OpenMediaFiles.track(File())
        OpenMediaFiles.untrack(done) // its response finished first
        assertEquals(2, OpenMediaFiles.count)

        assertEquals("a close that throws does not count", 1, OpenMediaFiles.closeAll())
        assertTrue(a.closed && b.closed)
        assertFalse(done.closed)
        assertEquals(0, OpenMediaFiles.count)
        assertEquals(0, OpenMediaFiles.closeAll())
    }

    @Test
    fun withoutTheNativeLibraryNothingIsInstalled() {
        var released = 0
        assertFalse(SdCardSignal.start { released++ })
        assertEquals(0, released)
    }
}
