package net.bladewatch.app.trips

import java.io.File
import java.io.IOException
import org.json.JSONException
import org.json.JSONObject

/**
 * Durable copy of the OPEN manual trip (BladeWatch-gklt.2).
 *
 * A manual trip must survive ACC OFF, a CameraDaemon restart and a head-unit reboot, but the
 * live trip is only a [TripRecord] in memory: the trips table is written when a trip ENDS. So
 * the start-of-trip readings (SoC, kWh, fuel and electricity counters, GPS, odometer) and the
 * recorder's running stats are written here and read back on the next daemon start.
 *
 * One small JSON file in the same directory as the trip database. It is written atomically (a
 * temp sibling, then a rename) so a kill mid-write leaves either the old state or the new one,
 * never half of each. A file that cannot be parsed loads as null and is moved aside to ".bad":
 * the daemon must still start, and the evidence stays on disk for a post-mortem.
 *
 * Pure: the file is injected, so the whole thing runs on the JVM.
 */
class ManualTripStore(private val file: File) {

    /** Everything needed to rebuild the open trip. -1 means "never read" like [TripRecord]. */
    data class State(
        val startTime: Long,
        val socStart: Double,
        val kwhStart: Double,
        val fuelPctStart: Double,
        val fuelConStart: Double,
        val elecConStart: Double,
        val startLat: Double,
        val startLon: Double,
        val extTempC: Int,
        val startOdometerKm: Double,
        val stats: TripTelemetryRecorder.Stats,
        val telemetryPaused: Boolean,
        /** Room for other features' state (reminder, per-mode energy segments). */
        val extras: JSONObject = JSONObject(),
    ) {
        /** The start-of-trip [TripRecord] this state describes. */
        fun toTripRecord(): TripRecord = TripRecord().also {
            it.isManual = true
            it.startTime = startTime
            it.socStart = socStart
            it.kwhStart = kwhStart
            it.fuelPctStart = fuelPctStart
            it.fuelConStart = fuelConStart
            it.elecConStart = elecConStart
            it.startLat = startLat
            it.startLon = startLon
            it.extTempC = extTempC
        }
    }

    /**
     * Write [state]; true when it reached the disk. Failures are logged and swallowed: losing a
     * save must not stop a trip. Synchronized because the minute tick, the ACC callbacks and the
     * Start Trip RPC all save, and they share one temp file.
     */
    @Synchronized
    fun save(state: State): Boolean {
        try {
            val json = JSONObject()
                .put("version", VERSION)
                .put("startTime", state.startTime)
                .put("socStart", state.socStart)
                .put("kwhStart", state.kwhStart)
                .put("fuelPctStart", state.fuelPctStart)
                .put("fuelConStart", state.fuelConStart)
                .put("elecConStart", state.elecConStart)
                .put("startLat", state.startLat)
                .put("startLon", state.startLon)
                .put("extTempC", state.extTempC)
                .put("startOdometerKm", state.startOdometerKm)
                .put("distanceKm", state.stats.distanceKm)
                .put("maxSpeedKmh", state.stats.maxSpeedKmh)
                .put("speedSumKmh", state.stats.speedSumKmh)
                .put("speedSampleCount", state.stats.speedSampleCount)
                .put("telemetryPaused", state.telemetryPaused)
                .put("extras", state.extras)
            file.parentFile?.mkdirs()
            val tmp = File(file.path + ".tmp")
            tmp.writeText(json.toString())
            if (!tmp.renameTo(file)) {
                // renameTo can refuse to replace an existing file on some filesystems.
                file.delete()
                if (!tmp.renameTo(file)) throw IOException("rename ${tmp.name} failed")
            }
            return true
        } catch (e: Exception) {
            // The next periodic save retries; nothing is queued.
            System.err.println("ManualTripStore.save failed: " + e.message)
            return false
        }
    }

    /** The saved state, or null when there is none or the file is unreadable. */
    @Synchronized
    fun load(): State? {
        if (!file.exists()) return null
        return try {
            val j = JSONObject(file.readText())
            State(
                startTime = j.getLong("startTime"),
                socStart = j.getDouble("socStart"),
                kwhStart = j.getDouble("kwhStart"),
                fuelPctStart = j.getDouble("fuelPctStart"),
                fuelConStart = j.getDouble("fuelConStart"),
                elecConStart = j.getDouble("elecConStart"),
                startLat = j.getDouble("startLat"),
                startLon = j.getDouble("startLon"),
                extTempC = j.getInt("extTempC"),
                startOdometerKm = j.getDouble("startOdometerKm"),
                stats = TripTelemetryRecorder.Stats(
                    distanceKm = j.getDouble("distanceKm"),
                    maxSpeedKmh = j.getInt("maxSpeedKmh"),
                    speedSumKmh = j.getLong("speedSumKmh"),
                    speedSampleCount = j.getLong("speedSampleCount"),
                ),
                telemetryPaused = j.getBoolean("telemetryPaused"),
                extras = j.optJSONObject("extras") ?: JSONObject(),
            )
        } catch (e: Exception) {
            if (e is JSONException || e is IOException || e is NumberFormatException) {
                moveAside()
                null
            } else {
                throw e
            }
        }
    }

    /** Delete the saved state (the trip ended). */
    @Synchronized
    fun clear() {
        file.delete()
        File(file.path + ".tmp").delete()
    }

    private fun moveAside() {
        try {
            val bad = File(file.path + ".bad")
            bad.delete()
            file.renameTo(bad)
        } catch (ignored: Exception) {
            // Best effort: a corrupt file we cannot rename is simply overwritten by the next save.
        }
    }

    companion object {
        private const val VERSION = 1
    }
}
