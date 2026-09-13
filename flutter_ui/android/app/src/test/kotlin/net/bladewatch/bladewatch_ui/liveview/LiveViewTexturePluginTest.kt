package net.bladewatch.bladewatch_ui.liveview

import android.graphics.SurfaceTexture
import io.flutter.view.TextureRegistry
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

/** Records every call; never touches a real Surface (this fake's own
 * [getSurface]/[getForcedNewSurface] are unreachable from the plugin under
 * test — see [FakeFrameDecoder], which never calls them either — and would
 * throw if invoked, same as any other real-Android-class stub in a JVM
 * test). */
private class FakeSurfaceProducer(private val fakeId: Long) : TextureRegistry.SurfaceProducer {
    var released = false
    var sizeSetWidth = -1
    var sizeSetHeight = -1

    override fun id(): Long = fakeId
    override fun release() {
        released = true
    }

    override fun setSize(width: Int, height: Int) {
        sizeSetWidth = width
        sizeSetHeight = height
    }

    override fun getWidth(): Int = sizeSetWidth
    override fun getHeight(): Int = sizeSetHeight
    override fun getSurface() = error("not needed by LiveViewTexturePlugin or FakeFrameDecoder")
    override fun getForcedNewSurface() = error("not used by this plugin")
    override fun setCallback(callback: TextureRegistry.SurfaceProducer.Callback?) {}
    override fun scheduleFrame() {}
    override fun handlesCropAndRotation(): Boolean = false
}

private class FakeTextureRegistry(private val nextId: Long = 1L) : TextureRegistry {
    var lastLifecycle: TextureRegistry.SurfaceLifecycle? = null
    var lastCreated: FakeSurfaceProducer? = null

    override fun createSurfaceProducer(lifecycle: TextureRegistry.SurfaceLifecycle): TextureRegistry.SurfaceProducer {
        lastLifecycle = lifecycle
        val p = FakeSurfaceProducer(nextId)
        lastCreated = p
        return p
    }

    override fun createSurfaceTexture(): TextureRegistry.SurfaceTextureEntry = error("not used by this plugin")
    override fun registerSurfaceTexture(surfaceTexture: SurfaceTexture): TextureRegistry.SurfaceTextureEntry = error("not used")
    override fun createImageTexture(): TextureRegistry.ImageTextureEntry = error("not used by this plugin")
}

private class FakeFrameDecoder : FrameDecoder {
    var configuredWidth: Int? = null
    var configuredHeight: Int? = null
    var configuredProducer: TextureRegistry.SurfaceProducer? = null
    val fedFrames = mutableListOf<Triple<ByteArray, Long, Boolean>>()
    var released = false

    override fun configure(width: Int, height: Int, producer: TextureRegistry.SurfaceProducer) {
        configuredWidth = width
        configuredHeight = height
        configuredProducer = producer
    }

    override fun feed(bytes: ByteArray, presentationTimeUs: Long, isCodecConfig: Boolean) {
        fedFrames.add(Triple(bytes, presentationTimeUs, isCodecConfig))
    }

    override fun release() {
        released = true
    }
}

class LiveViewTexturePluginTest {

    private fun build(registry: FakeTextureRegistry = FakeTextureRegistry(), decoder: FakeFrameDecoder = FakeFrameDecoder()) =
        Triple(LiveViewTexturePlugin(registry, decoderFactory = { decoder }), registry, decoder)

    @Test
    fun `createTexture registers a manual-lifecycle producer and returns its id`() {
        val registry = FakeTextureRegistry(nextId = 42L)
        val plugin = LiveViewTexturePlugin(registry, decoderFactory = { FakeFrameDecoder() })

        val id = plugin.createTexture()

        assertEquals(42L, id)
        assertEquals(TextureRegistry.SurfaceLifecycle.manual, registry.lastLifecycle)
    }

    @Test
    fun `createTexture twice without dispose throws`() {
        val (plugin, _, _) = build()
        plugin.createTexture()

        assertThrows(IllegalStateException::class.java) { plugin.createTexture() }
    }

    @Test
    fun `createTexture after dispose succeeds again`() {
        val (plugin, _, _) = build()
        val first = plugin.createTexture()
        plugin.dispose(first)

        val second = plugin.createTexture()

        assertEquals(first, second) // same fake registry always hands back the same id
    }

    @Test
    fun `configure passes width height and the active producer to the decoder`() {
        val (plugin, registry, decoder) = build()
        val id = plugin.createTexture()

        plugin.configure(id, 640, 480)

        assertEquals(640, decoder.configuredWidth)
        assertEquals(480, decoder.configuredHeight)
        // Calling producer.setSize(...) is MediaCodecFrameDecoder's own job
        // (it is the real implementation of the interface exercised here by
        // a fake), not LiveViewTexturePlugin's -- this only asserts the
        // plugin hands the *active* producer through unchanged.
        assertEquals(registry.lastCreated, decoder.configuredProducer)
    }

    @Test
    fun `configure with a mismatched textureId throws`() {
        val (plugin, _, _) = build()
        plugin.createTexture()

        assertThrows(IllegalArgumentException::class.java) { plugin.configure(999L, 640, 480) }
    }

    @Test
    fun `configure with no active texture throws`() {
        val (plugin, _, _) = build()

        assertThrows(IllegalStateException::class.java) { plugin.configure(1L, 640, 480) }
    }

    @Test
    fun `configure rejects non-positive dimensions`() {
        val (plugin, _, _) = build()
        val id = plugin.createTexture()

        assertThrows(IllegalArgumentException::class.java) { plugin.configure(id, 0, 480) }
        assertThrows(IllegalArgumentException::class.java) { plugin.configure(id, 640, -1) }
    }

    @Test
    fun `reconfigure releases the previous decoder and resets the frame counter`() {
        val registry = FakeTextureRegistry()
        var created = 0
        val decoders = mutableListOf<FakeFrameDecoder>()
        val plugin = LiveViewTexturePlugin(registry, decoderFactory = { created++; FakeFrameDecoder().also(decoders::add) })
        val id = plugin.createTexture()
        plugin.configure(id, 640, 480)
        plugin.feedFrame(id, byteArrayOf(1), isCodecConfig = true)
        plugin.feedFrame(id, byteArrayOf(2), isCodecConfig = false)

        plugin.configure(id, 1280, 720)
        plugin.feedFrame(id, byteArrayOf(3), isCodecConfig = true)

        assertEquals(2, created)
        assertEquals(true, decoders[0].released)
        // Frame counter reset: the first frame fed after reconfigure is pts=0 again.
        assertEquals(0L, decoders[1].fedFrames.single().second)
    }

    @Test
    fun `feedFrame computes an incrementing pts at the fixed 15fps step`() {
        val (plugin, _, decoder) = build()
        val id = plugin.createTexture()
        plugin.configure(id, 640, 480)

        plugin.feedFrame(id, byteArrayOf(1), isCodecConfig = true)
        plugin.feedFrame(id, byteArrayOf(2), isCodecConfig = false)
        plugin.feedFrame(id, byteArrayOf(3), isCodecConfig = false)

        assertEquals(listOf(0L, 66_667L, 133_334L), decoder.fedFrames.map { it.second })
        assertEquals(listOf(true, false, false), decoder.fedFrames.map { it.third })
        assertEquals(listOf(byteArrayOf(1), byteArrayOf(2), byteArrayOf(3)).map { it.toList() }, decoder.fedFrames.map { it.first.toList() })
    }

    @Test
    fun `feedFrame before configure throws`() {
        val (plugin, _, _) = build()
        val id = plugin.createTexture()

        assertThrows(IllegalStateException::class.java) { plugin.feedFrame(id, byteArrayOf(1), false) }
    }

    @Test
    fun `feedFrame with no active texture throws`() {
        val (plugin, _, _) = build()

        assertThrows(IllegalStateException::class.java) { plugin.feedFrame(1L, byteArrayOf(1), false) }
    }

    @Test
    fun `feedFrame with a mismatched textureId throws`() {
        val (plugin, _, _) = build()
        val id = plugin.createTexture()
        plugin.configure(id, 640, 480)

        assertThrows(IllegalArgumentException::class.java) { plugin.feedFrame(id + 1, byteArrayOf(1), false) }
    }

    @Test
    fun `dispose releases the decoder and the producer`() {
        val (plugin, registry, decoder) = build()
        val id = plugin.createTexture()
        plugin.configure(id, 640, 480)

        plugin.dispose(id)

        assertEquals(true, decoder.released)
        assertEquals(true, registry.lastCreated!!.released)
    }

    @Test
    fun `dispose before configure still releases the producer (no decoder to release)`() {
        val (plugin, registry, _) = build()
        val id = plugin.createTexture()

        plugin.dispose(id)

        assertEquals(true, registry.lastCreated!!.released)
    }

    @Test
    fun `dispose with no active texture is a no-op, not an error`() {
        val (plugin, _, _) = build()

        plugin.dispose(1L) // must not throw
    }

    @Test
    fun `dispose twice is a no-op the second time`() {
        val (plugin, _, _) = build()
        val id = plugin.createTexture()

        plugin.dispose(id)
        plugin.dispose(id) // must not throw
    }

    @Test
    fun `dispose with a mismatched textureId while a texture is active throws`() {
        val (plugin, _, _) = build()
        plugin.createTexture()

        assertThrows(IllegalArgumentException::class.java) { plugin.dispose(999L) }
    }
}
