package net.bladewatch.app.daemon

import java.io.File
import org.json.JSONObject

/**
 * What the Pear peer tells the rest of the car about itself (BladeWatch-rdtj.17): pear_daemon
 * writes it, byd_cam_daemon's `pearStatus` IPC command reads it for the in-car UI.
 *
 * "Running" and "reachable" are different questions, and only the second answers "can I check on
 * my car from work": the process can be alive with the head unit offline. A peer that only waits to
 * be found sits in pear-end's `discovering` state either way, so reachability comes from HyperDHT
 * itself -- pear-end's `dht.status` (flutter_pear 0.4.4+), polled every sweep.
 *
 * Holds counts and times only -- never the topic, a peer key or anything a companion sent. Mode 600:
 * both daemons run as shell.
 */
class PearStatus(private val file: File, private val now: () -> Long = System::currentTimeMillis) {

    /** pear-end acknowledged `swarm.join` for this car's topic. */
    @Volatile var joined = false

    /** HyperDHT is online; null when this pear-end cannot say (a bundle without `dht.status`). */
    @Volatile var online: Boolean? = null

    @Volatile var companions = 0

    @Volatile var lastCompanionAt: Long? = null

    /** Atomically replaces the file. A failure is only a stale status, never a reason to stop. */
    @Synchronized
    fun write(): Boolean = try {
        val json = JSONObject()
            .put("updatedAt", now())
            .put("joined", joined)
            .put("online", online ?: JSONObject.NULL)
            .put("companions", companions)
            .put("lastCompanionAt", lastCompanionAt ?: JSONObject.NULL)
        val tmp = File(file.path + ".tmp")
        tmp.writeText(json.toString())
        tmp.setReadable(false, false)
        tmp.setWritable(false, false)
        tmp.setReadable(true, true)
        tmp.setWritable(true, true)
        tmp.renameTo(file)
    } catch (e: Exception) {
        false
    }

    companion object {
        const val PATH = "/data/local/tmp/pear_status.json"

        /** Older than three sweeps: pear_daemon has stopped updating it, whatever it last said. */
        const val STALE_MS = 90_000L

        /**
         * The in-car UI's view. `reachable` is true only when the process runs, its status is fresh,
         * the topic is joined and HyperDHT is online; null when this pear-end cannot report DHT
         * state; false otherwise. The companion count only counts while the status is fresh.
         */
        @JvmStatic
        fun report(file: File, running: Boolean, enabled: Boolean, nowMs: Long): JSONObject {
            val stored = try {
                if (file.isFile) JSONObject(file.readText()) else null
            } catch (e: Exception) {
                null
            }
            val fresh = running && stored != null && nowMs - stored.optLong("updatedAt", 0L) in 0..STALE_MS
            val joined = fresh && stored!!.optBoolean("joined", false)
            val online: Boolean? = if (stored == null || stored.isNull("online")) null else stored.optBoolean("online")
            val reachable: Boolean? = when {
                !fresh || !joined -> false
                online == null -> null
                else -> online
            }
            return JSONObject()
                .put("status", "ok")
                .put("running", running)
                .put("enabled", enabled)
                .put("reachable", reachable ?: JSONObject.NULL)
                .put("companions", if (fresh) stored!!.optInt("companions", 0) else 0)
                .put(
                    "lastCompanionAt",
                    if (stored == null || stored.isNull("lastCompanionAt")) JSONObject.NULL else stored.optLong("lastCompanionAt"),
                )
        }
    }
}
