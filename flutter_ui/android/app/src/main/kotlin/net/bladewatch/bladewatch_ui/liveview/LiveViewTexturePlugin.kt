package net.bladewatch.bladewatch_ui.liveview

import io.flutter.view.TextureRegistry

/**
 * Ground truth: `LiveStreamClient.kt`. BladeWatch-yz1e.10's texture plugin —
 * see docs/build-and-operations.md for why this screen keeps Kotlin and why
 * the WebSocket connection + `StreamService` RPC calls stay in Dart (only
 * MediaCodec decode is genuinely native-only): registers a
 * [TextureRegistry.SurfaceProducer], feeds it complete H.264 access units
 * Dart has already read off its own WebSocket connection, and renders them
 * via [FrameDecoder] (a real [MediaCodecFrameDecoder] in production).
 *
 * One stream at a time, matching native (`LiveStreamClient`'s own single
 * `running` flag) — `createTexture()` while a texture is already active is a
 * caller bug, not a legitimate "second stream" request; the whole point of
 * the strict state machine below (`createTexture` -> `configure` -> any
 * number of `feedFrame` -> `dispose`, each step validated against a
 * `textureId` that must match the currently-active one) is to make caller
 * mistakes fail loudly here instead of silently leaking a [FrameDecoder]
 * (see this class's own file-level warning about why that is unrecoverable
 * on this device without restarting the daemon).
 *
 * [decoderFactory] is the plugin's only test seam: [MediaCodecFrameDecoder]
 * touches real `android.media.MediaCodec`/`android.view.Surface` APIs that
 * are stubs in a JVM unit test (they throw "not mocked"), so every method
 * here is written to never touch those types directly — only the injected
 * [FrameDecoder] interface and Flutter's own [TextureRegistry] interfaces,
 * both fakeable. This class is unit-tested to 100%; [MediaCodecFrameDecoder]
 * is not (see its own doc comment and the Kover exclusion in
 * app/build.gradle.kts).
 */
internal class LiveViewTexturePlugin(
    private val textureRegistry: TextureRegistry,
    private val decoderFactory: () -> FrameDecoder = { MediaCodecFrameDecoder() },
) {
    private var producer: TextureRegistry.SurfaceProducer? = null
    private var decoder: FrameDecoder? = null
    private var frameCounter = 0L

    /** Registers a new texture and returns its id. Fails if one is already active. */
    fun createTexture(): Long {
        check(producer == null) { "createTexture called while a texture is already active" }
        val p = textureRegistry.createSurfaceProducer(TextureRegistry.SurfaceLifecycle.manual)
        producer = p
        return p.id()
    }

    /**
     * Configures and starts the decoder for the active texture once the
     * stream's real dimensions are known (mirrors `LiveStreamClient.kt`
     * calling `decoder.configure(...)` only after `queryStreamDimensions()`
     * resolves, not at connect time).
     */
    fun configure(textureId: Long, width: Int, height: Int) {
        val p = activeProducer(textureId)
        require(width > 0 && height > 0) { "configure requires positive dimensions, got ${width}x$height" }
        decoder?.release()
        frameCounter = 0
        val d = decoderFactory()
        d.configure(width, height, p)
        decoder = d
    }

    /**
     * Feeds one complete H.264 access unit (Dart has already reassembled any
     * WebSocket fragmentation — see the Dart controller's doc comment) and
     * drains any output the decoder has ready. `presentationTimeUs` is
     * computed the same way as native: an incrementing counter times a
     * fixed ~15fps step, not derived from any wall clock.
     */
    fun feedFrame(textureId: Long, bytes: ByteArray, isCodecConfig: Boolean) {
        activeProducer(textureId)
        val d = checkNotNull(decoder) { "feedFrame called before configure" }
        val pts = frameCounter++ * PTS_STEP_US
        d.feed(bytes, pts, isCodecConfig)
    }

    /**
     * Releases the decoder and the texture. Idempotent: disposing an
     * already-disposed (or never-created) texture is a no-op, not an error
     * — this lets Dart call it unconditionally from a `dispose()`/`stop()`
     * path without tracking whether setup ever completed.
     */
    fun dispose(textureId: Long) {
        val p = producer ?: return
        require(p.id() == textureId) { "dispose called with textureId $textureId but the active texture is ${p.id()}" }
        decoder?.release()
        decoder = null
        p.release()
        producer = null
    }

    private fun activeProducer(textureId: Long): TextureRegistry.SurfaceProducer {
        val p = checkNotNull(producer) { "no active texture (createTexture was never called, or it was already disposed)" }
        require(p.id() == textureId) { "unknown textureId $textureId; the active texture is ${p.id()}" }
        return p
    }

    companion object {
        // ~15fps presentation cadence, matching LiveStreamClient.kt's PTS_STEP_US.
        private const val PTS_STEP_US = 66_667L
    }
}
