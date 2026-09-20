package net.bladewatch.app.recording

import net.bladewatch.app.grpc.v1.SetQualityRequest
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-gyg1.3: pure policy tests for [RecordingPriority].
 *
 * Step Zero found there is exactly one lever that changes how much recording could be lost on
 * an abrupt power loss: segment rotation length (see
 * `HardwareEventRecorderGpu.loadSegmentDurationMs`). That length is already a separate,
 * already-shipped user control ("Recording Limit", 1/5/10 minutes) with no honest framing of
 * the trade. [RecordingPriority] does not replace it -- it is a cap layered on top: RELIABILITY
 * forces the shortest already-supported segment length regardless of Recording Limit;
 * PERFORMANCE is a pure passthrough, bit-identical to pre-issue behaviour.
 */
class RecordingPriorityTest {

    @Test
    fun `performance leaves the configured segment length unchanged`() {
        // Asserted on the knob (effective minutes), not on the enum constant.
        assertEquals(10, RecordingPriority.PERFORMANCE.effectiveSegmentMinutes(10))
        assertEquals(5, RecordingPriority.PERFORMANCE.effectiveSegmentMinutes(5))
        assertEquals(1, RecordingPriority.PERFORMANCE.effectiveSegmentMinutes(1))
    }

    @Test
    fun `reliability caps the segment length to one minute`() {
        assertEquals(1, RecordingPriority.RELIABILITY.effectiveSegmentMinutes(10))
        assertEquals(1, RecordingPriority.RELIABILITY.effectiveSegmentMinutes(5))
        assertEquals(1, RecordingPriority.RELIABILITY.effectiveSegmentMinutes(1))
    }

    @Test
    fun `unrecognised config value falls back to reliability, and does not throw`() {
        assertEquals(RecordingPriority.RELIABILITY, RecordingPriority.fromConfigValue("bogus"))
        assertEquals(RecordingPriority.RELIABILITY, RecordingPriority.fromConfigValue(null))
        assertEquals(RecordingPriority.RELIABILITY, RecordingPriority.fromConfigValue(""))
        assertEquals(RecordingPriority.RELIABILITY, RecordingPriority.fromConfigValue("performance"))
    }

    @Test
    fun `settings round trip through the proto preserves the value`() {
        val req = SetQualityRequest.newBuilder()
            .setRecordingPriority(RecordingPriority.RELIABILITY.name)
            .build()
        val wire = req.toByteArray()
        val parsed = SetQualityRequest.parseFrom(wire)
        assertEquals("RELIABILITY", parsed.recordingPriority)
    }
}
