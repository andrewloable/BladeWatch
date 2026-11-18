package net.bladewatch.app.trips

import java.io.File
import java.nio.charset.StandardCharsets
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-gklt.3: the manual-trip routes of [TripApiHandler].
 *
 * Run against a real [TripAnalyticsManager] with a real [TripDetector] (see attachForTest), so
 * the route table, the manager and the detector are exercised together. The Connect layer passes
 * the handler's JSON straight through, so these are the wire shapes.
 */
class TripManualApiTest {

    private val detector = TripDetector()
    private val manager = TripAnalyticsManager().also { it.attachForTest(detector, null) }
    private val api = TripApiHandler(manager)

    @After
    fun shutdown() {
        detector.shutdown()
    }

    private fun call(method: String, path: String, body: String? = null): JSONObject =
        api.handleRequest(path, method, null, body)

    private fun status(r: JSONObject) = r.getJSONObject("status")

    @Test
    fun `active with no trip reports nothing`() {
        val s = status(call("GET", "/api/trips/active"))

        assertFalse(s.getBoolean("active"))
        assertFalse(s.getBoolean("manual"))
        assertEquals(0L, s.getLong("startTimeMs"))
        assertEquals(0L, s.getLong("autoStopAtMs"))
    }

    @Test
    fun `start opens a manual trip and a second start returns the same one`() {
        val first = status(call("POST", "/api/trips/manual/start"))
        val second = status(call("POST", "/api/trips/manual/start"))

        assertTrue(first.getBoolean("active"))
        assertTrue(first.getBoolean("manual"))
        assertEquals(first.getLong("startTimeMs"), second.getLong("startTimeMs"))
        assertEquals(
            first.getLong("startTimeMs") + 7L * 24 * 60 * 60 * 1000,
            first.getLong("autoStopAtMs"),
        )
    }

    @Test
    fun `stop ends the manual trip and a second stop reports false`() {
        call("POST", "/api/trips/manual/start")

        assertTrue(call("POST", "/api/trips/manual/stop").getBoolean("stopped"))
        assertFalse(call("POST", "/api/trips/manual/stop").getBoolean("stopped"))
        assertFalse(status(call("GET", "/api/trips/active")).getBoolean("active"))
    }

    @Test
    fun `stop leaves an auto trip running`() {
        detector.onGearChanged(4)

        assertFalse(call("POST", "/api/trips/manual/stop").getBoolean("stopped"))

        val s = status(call("GET", "/api/trips/active"))
        assertTrue(s.getBoolean("active"))
        assertFalse(s.getBoolean("manual"))
    }

    @Test
    fun `ack keeps the highest sequence`() {
        call("POST", "/api/trips/manual/start")

        call("POST", "/api/trips/manual/ack", """{"reminderSeq":"3"}""")
        val after = status(call("POST", "/api/trips/manual/ack", """{"reminderSeq":2}"""))

        assertEquals(3L, after.getLong("reminderAckedSeq"))
    }

    @Test
    fun `ack with a bad body is a 400 and ack without a trip changes nothing`() {
        assertEquals(400, call("POST", "/api/trips/manual/ack", "{not json").getInt("_status"))

        val s = status(call("POST", "/api/trips/manual/ack", """{"reminderSeq":5}"""))
        assertEquals(0L, s.getLong("reminderAckedSeq"))
    }

    /** The new exact paths must not be read as a trip id by the by-id routes. */
    @Test
    fun `manual routes are exact paths not trip ids`() {
        assertEquals(404, call("GET", "/api/trips/manual/start").getInt("_status"))
        assertEquals(404, call("POST", "/api/trips/active").getInt("_status"))
        assertTrue(call("GET", "/api/trips/active").getBoolean("success"))
    }

    @Test
    fun `routes are unavailable when trip analytics is not running`() {
        val idle = TripApiHandler(TripAnalyticsManager())

        assertEquals(503, idle.handleRequest("/api/trips/manual/start", "POST", null, null).getInt("_status"))
        assertFalse(
            idle.handleRequest("/api/trips/active", "GET", null, null)
                .getJSONObject("status").getBoolean("active")
        )
    }

    // ── proto contract ──

    private fun protoSource(): String {
        var f = File("../proto/bladewatch/v1/trips.proto")
        if (!f.isFile) f = File("proto/bladewatch/v1/trips.proto")
        assertTrue("could not locate trips.proto", f.isFile)
        return String(f.readBytes(), StandardCharsets.UTF_8)
    }

    private fun fieldsOf(message: String): Map<String, Int> {
        val proto = protoSource()
        val start = proto.indexOf("message $message {")
        assertTrue("proto must declare message $message", start >= 0)
        val body = proto.substring(start, proto.indexOf("\n}", start))
        return Regex("""^\s*(?:repeated\s+)?[A-Za-z0-9_.]+\s+([a-z0-9_]+)\s*=\s*(\d+)\s*;""", RegexOption.MULTILINE)
            .findAll(body)
            .associate { it.groupValues[1] to it.groupValues[2].toInt() }
    }

    @Test
    fun `proto declares the four rpcs and the summary flag at a new number`() {
        val proto = protoSource()
        for (rpc in listOf("StartManualTrip", "StopManualTrip", "GetActiveTrip", "AcknowledgeTripReminder")) {
            assertTrue("TripsService must declare $rpc", proto.contains("rpc $rpc("))
        }
        val summary = fieldsOf("TripSummary")
        assertEquals("manual must take the next free number", 25, summary["manual"])
        assertEquals("has_fuel_data must keep 24", 24, summary["has_fuel_data"])
    }

    /** The JSON keys the handler emits must be the camelCase names protobuf derives. */
    @Test
    fun `status json keys match the proto field names`() {
        val proto = fieldsOf("ActiveTripStatus").keys
        val camel = proto.map { n -> n.split("_").mapIndexed { i, p -> if (i == 0) p else p.replaceFirstChar { it.uppercase() } }.joinToString("") }.toSet()

        call("POST", "/api/trips/manual/start")
        val keys = status(call("GET", "/api/trips/active")).keys().asSequence().toSet()

        assertEquals(camel, keys)
    }

    /**
     * Regression (review of gklt.3): extras updates, acknowledgements, status reads and saves run
     * on different threads and share one JSONObject that is not thread-safe. A save must
     * therefore wait while an update holds the lock. Deterministic on purpose: a stress test
     * cannot reliably catch a missing lock (a first attempt passed with the lock removed).
     */
    @Test
    fun `a save waits while an extras update holds the lock`() {
        val dir = java.nio.file.Files.createTempDirectory("manualapi").toFile()
        val d = TripDetector()
        try {
            val m = TripAnalyticsManager().also {
                it.attachForTest(d, TripTelemetryRecorder(null), ManualTripStore(File(dir, "s.json")))
            }
            m.startManualTrip()
            val inBlock = java.util.concurrent.CountDownLatch(1)
            val release = java.util.concurrent.CountDownLatch(1)
            val saved = java.util.concurrent.atomic.AtomicBoolean(false)

            val holder = Thread { m.updateExtras { inBlock.countDown(); release.await() } }
            holder.start()
            assertTrue(inBlock.await(5, java.util.concurrent.TimeUnit.SECONDS))
            val saver = Thread { m.saveManualState(); saved.set(true) }
            saver.start()

            Thread.sleep(300)
            assertFalse("the save must wait for the update to finish", saved.get())

            release.countDown()
            saver.join(5_000)
            holder.join(5_000)
            assertTrue(saved.get())
        } finally {
            d.shutdown()
            dir.deleteRecursively()
        }
    }

    @Test
    fun `extras updates are saved and survive a reload`() {
        val dir = java.nio.file.Files.createTempDirectory("manualapi").toFile()
        val d = TripDetector()
        try {
            val store = ManualTripStore(File(dir, "s.json"))
            val m = TripAnalyticsManager().also {
                it.attachForTest(d, TripTelemetryRecorder(null), store)
            }
            m.startManualTrip()

            m.updateExtras { it.put("reminder", JSONObject().put("seq", 4).put("lastReason", "acc_off")) }
            m.acknowledgeReminder(3)

            val loaded = store.load()!!.extras
            assertEquals(4, loaded.getJSONObject("reminder").getInt("seq"))
            val s = m.activeTripStatus()
            assertEquals(4L, s.getLong("reminderSeq"))
            assertEquals("acc_off", s.getString("reminderReason"))
            assertEquals(3L, s.getLong("reminderAckedSeq"))
        } finally {
            d.shutdown()
            dir.deleteRecursively()
        }
    }

    // ── gklt.4: the reminder is wired to the manager and shows up in the status ──

    @Test
    fun `acc off with a manual trip raises a reminder visible in the status`() {
        call("POST", "/api/trips/manual/start")

        manager.onAccOff()
        manager.onAccOff()   // the same event twice: still one reminder

        val s = status(call("GET", "/api/trips/active"))
        assertEquals(1L, s.getLong("reminderSeq"))
        assertEquals("acc_off", s.getString("reminderReason"))
        assertEquals(0L, s.getLong("reminderAckedSeq"))

        val acked = status(call("POST", "/api/trips/manual/ack", """{"reminderSeq":1}"""))
        assertEquals(1L, acked.getLong("reminderAckedSeq"))
    }

    @Test
    fun `a new manual trip starts with no reminder`() {
        call("POST", "/api/trips/manual/start")
        manager.onAccOff()
        call("POST", "/api/trips/manual/stop")

        val s = status(call("POST", "/api/trips/manual/start"))

        assertEquals(0L, s.getLong("reminderSeq"))
        assertEquals("", s.getString("reminderReason"))
    }

    @Test
    fun `acc off without a manual trip raises nothing`() {
        manager.onAccOff()

        assertEquals(0L, status(call("GET", "/api/trips/active")).getLong("reminderSeq"))
    }

    // ── live cost so far ──

    private fun liveManager(rate: Double, price: Double, currency: String = "USD"): Pair<TripAnalyticsManager, TripDetector> {
        val d = TripDetector()
        val cfg = TripConfig().apply { setElectricityRate(rate); setFuelPricePerL(price); setCurrency(currency) }
        val m = TripAnalyticsManager().also { it.attachForTest(d, null, null, cfg) }
        m.startManualTrip()
        return m to d
    }

    private fun snap(t: Long, mode: Int, elec: Double, fuel: Double) =
        EnergyModeSegments.Snapshot(t * 1000, mode, -1.0, elec, -1.0, fuel, -1.0)

    @Test
    fun `live cost is electricity only while the trip is in EV mode`() {
        val (m, d) = liveManager(rate = 0.2, price = 1.8)
        m.energySegments().start(snap(0, 1, 50.0, 300.0))
        m.energySegments().onSnapshot(snap(60, 1, 52.0, 300.0))

        val s = m.activeTripStatus()

        assertTrue(s.getBoolean("liveCostAvailable"))
        assertEquals(0.4, s.getDouble("liveElectricCost"), 1e-9)
        assertEquals(0.0, s.getDouble("liveFuelCost"), 1e-9)
        assertEquals("USD", s.getString("liveCurrency"))
        assertTrue(s.getBoolean("liveHasFuel"))
        d.shutdown()
    }

    @Test
    fun `live cost is the sum of both modes in a mixed trip`() {
        val (m, d) = liveManager(rate = 0.2, price = 1.8)
        m.energySegments().start(snap(0, 1, 50.0, 300.0))
        m.energySegments().onSnapshot(snap(60, 3, 51.5, 300.0))   // EV: 1.5 kWh
        m.energySegments().onSnapshot(snap(120, 3, 52.5, 301.0))  // HEV: 1.0 L

        val s = m.activeTripStatus()

        assertEquals(0.3, s.getDouble("liveElectricCost"), 1e-9)
        assertEquals(1.8, s.getDouble("liveFuelCost"), 1e-9)
        d.shutdown()
    }

    @Test
    fun `live cost leaves the fuel part out when no fuel price is set`() {
        val (m, d) = liveManager(rate = 0.2, price = 0.0)
        m.energySegments().start(snap(0, 3, 50.0, 300.0))
        m.energySegments().onSnapshot(snap(60, 3, 50.5, 301.0))

        val s = m.activeTripStatus()

        assertTrue(s.getBoolean("liveCostAvailable"))
        assertFalse(s.getBoolean("liveHasFuel"))
        assertEquals(0.0, s.getDouble("liveFuelCost"), 1e-9)
        d.shutdown()
    }

    @Test
    fun `live cost is not available without a rate, without a trip, or without a tracker`() {
        val (noRate, d1) = liveManager(rate = 0.0, price = 0.0)
        noRate.energySegments().start(snap(0, 1, 50.0, 300.0))
        noRate.energySegments().onSnapshot(snap(60, 1, 52.0, 300.0))
        assertFalse(noRate.activeTripStatus().getBoolean("liveCostAvailable"))
        d1.shutdown()

        val (noTracker, d2) = liveManager(rate = 0.2, price = 1.8)
        assertFalse(noTracker.activeTripStatus().getBoolean("liveCostAvailable"))
        d2.shutdown()

        val idle = TripAnalyticsManager()
        assertFalse(idle.activeTripStatus().getBoolean("liveCostAvailable"))
    }

    @Test
    fun `live cost goes away when the trip ends`() {
        val (m, d) = liveManager(rate = 0.2, price = 1.8)
        m.energySegments().start(snap(0, 1, 50.0, 300.0))
        m.energySegments().onSnapshot(snap(60, 1, 52.0, 300.0))
        assertTrue(m.activeTripStatus().getBoolean("liveCostAvailable"))

        m.stopManualTrip()

        assertFalse(m.activeTripStatus().getBoolean("liveCostAvailable"))
        d.shutdown()
    }
}

