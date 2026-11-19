package net.bladewatch.app.trips

import java.io.File
import java.nio.file.Files
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** BladeWatch-gklt.2: the durable copy of the open manual trip. */
class ManualTripStoreTest {

    private lateinit var dir: File
    private lateinit var file: File
    private lateinit var store: ManualTripStore

    @Before
    fun setUp() {
        dir = Files.createTempDirectory("manualtrip").toFile()
        file = File(dir, "active_manual_trip.json")
        store = ManualTripStore(file)
    }

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    private fun state(paused: Boolean = false) = ManualTripStore.State(
        startTime = 1_700_000_000_123L,
        socStart = 81.5,
        kwhStart = 14.25,
        fuelPctStart = 62.0,
        fuelConStart = 1200.125,
        elecConStart = 5000.5,
        startLat = 14.5995,
        startLon = 120.9842,
        extTempC = 31,
        startOdometerKm = 12345.6,
        stats = TripTelemetryRecorder.Stats(
            distanceKm = 7.75, maxSpeedKmh = 96, speedSumKmh = 54_321L, speedSampleCount = 900L,
        ),
        telemetryPaused = paused,
        extras = JSONObject().put("reminder", JSONObject().put("seq", 3)),
    )

    @Test
    fun `save then load round trips every field`() {
        store.save(state(paused = true))

        val read = store.load()
        assertNotNull(read)
        read!!
        val expected = state(paused = true)
        assertEquals(expected.startTime, read.startTime)
        assertEquals(expected.socStart, read.socStart, 1e-9)
        assertEquals(expected.kwhStart, read.kwhStart, 1e-9)
        assertEquals(expected.fuelPctStart, read.fuelPctStart, 1e-9)
        assertEquals(expected.fuelConStart, read.fuelConStart, 1e-9)
        assertEquals(expected.elecConStart, read.elecConStart, 1e-9)
        assertEquals(expected.startLat, read.startLat, 1e-9)
        assertEquals(expected.startLon, read.startLon, 1e-9)
        assertEquals(expected.extTempC, read.extTempC)
        assertEquals(expected.startOdometerKm, read.startOdometerKm, 1e-9)
        assertEquals(expected.stats, read.stats)
        assertTrue(read.telemetryPaused)
        assertEquals(3, read.extras.getJSONObject("reminder").getInt("seq"))
    }

    @Test
    fun `state rebuilds a manual trip record`() {
        val t = state().toTripRecord()
        assertTrue(t.isManual)
        assertEquals(1_700_000_000_123L, t.startTime)
        assertEquals(1200.125, t.fuelConStart, 1e-9)
    }

    @Test
    fun `load with no file is null`() {
        assertNull(store.load())
    }

    @Test
    fun `corrupt file loads as null and is moved aside`() {
        file.writeText("{ this is not json")

        assertNull(store.load())

        assertFalse(file.exists())
        assertTrue(File(file.path + ".bad").exists())
    }

    @Test
    fun `file missing a required key loads as null`() {
        file.writeText("""{"version":1,"startTime":5}""")
        assertNull(store.load())
        assertTrue(File(file.path + ".bad").exists())
    }

    @Test
    fun `clear removes the file`() {
        store.save(state())
        assertTrue(file.exists())

        store.clear()

        assertFalse(file.exists())
        assertNull(store.load())
    }

    @Test
    fun `save leaves no temp file and replaces an existing state`() {
        store.save(state())
        store.save(state(paused = true))

        assertFalse(File(file.path + ".tmp").exists())
        assertTrue(store.load()!!.telemetryPaused)
    }

    @Test
    fun `save creates the parent directory`() {
        val nested = ManualTripStore(File(dir, "a/b/state.json"))
        nested.save(state())
        assertNotNull(nested.load())
    }

    /**
     * Regression: the minute tick, the ACC callbacks and the Start Trip RPC all save at once.
     * Unsynchronised they share one temp file and a rename can fail, losing the save.
     */
    @Test
    fun `concurrent saves all succeed and the file stays loadable`() {
        val failures = java.util.concurrent.atomic.AtomicInteger()
        val threads = (1..8).map {
            Thread {
                repeat(60) { i ->
                    if (!store.save(state(paused = i % 2 == 0))) failures.incrementAndGet()
                    store.load()
                }
            }
        }
        threads.forEach { it.start() }
        threads.forEach { it.join() }

        assertEquals(0, failures.get())
        assertNotNull(store.load())
        assertFalse(File(file.path + ".tmp").exists())
    }
}
