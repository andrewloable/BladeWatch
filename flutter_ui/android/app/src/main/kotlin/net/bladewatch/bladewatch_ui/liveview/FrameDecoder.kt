package net.bladewatch.bladewatch_ui.liveview

import io.flutter.view.TextureRegistry

/**
 * Feeds H.264 access units to a hardware decoder rendering into a texture's
 * [TextureRegistry.SurfaceProducer]. The only genuinely native/hardware
 * boundary in this plugin — [MediaCodecFrameDecoder] is thin and excluded
 * from the coverage gate (see app/build.gradle.kts); all decision logic
 * (frame counting, presentation-timestamp calculation, state tracking,
 * argument validation) lives in [LiveViewTexturePlugin] instead, which IS
 * unit-tested against a fake of this interface.
 *
 * Ground truth: `LiveStreamClient.kt`'s `MediaCodec.createDecoderByType`/
 * `feedToDecoder`/`drainDecoder`.
 */
internal interface FrameDecoder {
    /** Configures and starts the decoder against [producer]'s surface. */
    fun configure(width: Int, height: Int, producer: TextureRegistry.SurfaceProducer)

    /** Queues one complete H.264 access unit and drains any ready output. */
    fun feed(bytes: ByteArray, presentationTimeUs: Long, isCodecConfig: Boolean)

    /** Stops and releases the decoder. Safe to call more than once. */
    fun release()
}
