package net.bladewatch.app.server

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.storage.StorageManager
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Lets the user reformat a removable external drive.
 *
 * Only public: volumes (FAT/exFAT removable media such as SD cards and USB sticks) can be
 * formatted. Internal emulated storage is explicitly rejected, and formatting is blocked while
 * recording is active.
 *
 * Behind `StorageService.{ListFormatVolumes, FormatVolume}`.
 *
 * BladeWatch-6mnq: this was a REST handler writing raw HTTP status lines into an OutputStream that
 * the Connect layer captured straight back out. The two operations now RETURN their JSON, and the
 * HTTP status codes that carried meaning (400 bad volume, 409 recording active, 500 sm failure)
 * became Connect error codes — the same distinction, expressed once, on the surface that is
 * actually served.
 */
object FormatStorageApiHandler {

    private const val MOUNT_POLL_COUNT = 20
    private const val MOUNT_POLL_DELAY_MS = 500L

    // ─── StorageService.ListFormatVolumes ────────────────────────────────────

    @JvmStatic
    @Throws(Exception::class)
    fun listVolumes(): JSONObject {
        val arr = JSONArray()
        for (v in enumPublicVolumes()) {
            val obj = JSONObject()
            obj.put("volumeId", v.id)
            obj.put("uuid", v.uuid ?: JSONObject.NULL)
            obj.put("mounted", v.mounted)
            obj.put("mountPath", if (v.uuid != null) "/storage/" + v.uuid else JSONObject.NULL)
            arr.put(obj)
        }
        val response = JSONObject()
        response.put("success", true)
        response.put("volumes", arr)
        return response
    }

    // ─── StorageService.FormatVolume ─────────────────────────────────────────

    /**
     * Formats a removable volume. **Destructive — erases everything on it.**
     *
     * Throws [ConnectException] `invalid_argument` for a volume id that is not a removable public
     * volume, `failed_precondition` while recording is active, and `internal` when `sm` itself
     * fails. Those were HTTP 400/409/500 when this was a REST endpoint.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun formatVolume(volumeId: String?): JSONObject {
        if (!isValidVolumeId(volumeId)) {
            throw ConnectException(
                "invalid_argument",
                "Invalid volumeId — must be a removable public volume (e.g. public:8,97)"
            )
        }

        // Block if recording or surveillance is active
        val storage = StorageManager.getInstance()
        if (storage != null && storage.isRecordingActive) {
            throw ConnectException(
                "failed_precondition",
                "Cannot format drive while recording is active — stop recording first"
            )
        }

        CameraDaemon.log("FormatStorage: starting format of $volumeId")

        // Unmount (safe even if already unmounted)
        val unmountResult = shell("sm unmount " + shellQuote(volumeId!!))
        CameraDaemon.log("FormatStorage: unmount exit=" + unmountResult[0])

        // Format — destructive: erases all data on the volume
        val formatResult = shell("sm format " + shellQuote(volumeId))
        CameraDaemon.log(
            "FormatStorage: format exit=" + formatResult[0] + " out=" + formatResult[1].trim()
        )

        if ("0" != formatResult[0]) {
            val msg = formatResult[1].trim()
            throw ConnectException(
                "internal",
                "Format failed: " +
                    (if (msg.isEmpty()) "sm format exited " + formatResult[0] else msg)
            )
        }

        // Mount after format
        shell("sm mount " + shellQuote(volumeId))

        // Poll for remount (up to 10 seconds)
        var mountPath: String? = null
        for (i in 0 until MOUNT_POLL_COUNT) {
            Thread.sleep(MOUNT_POLL_DELAY_MS)
            for (v in enumPublicVolumes()) {
                if (v.id == volumeId && v.mounted && v.uuid != null) {
                    mountPath = "/storage/" + v.uuid
                    break
                }
            }
            if (mountPath != null) break
        }

        // Refresh StorageManager so it picks up the newly formatted drive
        storage?.discoverSdCard()

        val response = JSONObject()
        if (mountPath != null) {
            CameraDaemon.log("FormatStorage: success, mounted at $mountPath")
            response.put("success", true)
            response.put("message", "Drive formatted and remounted at $mountPath")
            response.put("mountPath", mountPath)
        } else {
            // Format succeeded but the drive didn't auto-remount — partial success
            CameraDaemon.log("FormatStorage: format OK but drive did not remount")
            response.put("success", false)
            response.put(
                "message", "Drive formatted but did not remount — safely re-insert the drive"
            )
            response.put("mountPath", JSONObject.NULL)
        }
        return response
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /** Run `sm list-volumes all` and return all public: entries. */
    private fun enumPublicVolumes(): List<SmPublicVolume> {
        val result = ArrayList<SmPublicVolume>()
        try {
            val p = Runtime.getRuntime().exec(arrayOf("sm", "list-volumes", "all"))
            val r = BufferedReader(InputStreamReader(p.inputStream))
            while (true) {
                val line = r.readLine()?.trim() ?: break
                if (!line.startsWith("public:")) continue
                val parts = line.split(Regex("\\s+"))
                if (parts.size < 2) continue
                val uuid = if (parts.size >= 3 && "null" != parts[2]) parts[2] else null
                result.add(SmPublicVolume(parts[0], parts[1], uuid))
            }
            r.close()
            p.waitFor()
        } catch (e: Exception) {
            CameraDaemon.log("FormatStorage: enumPublicVolumes error: " + e.message)
        }
        return result
    }

    /** Execute a shell command via sh -c, returning [exitCode, combined stdout+stderr]. */
    private fun shell(command: String): Array<String> = try {
        val p = Runtime.getRuntime().exec(arrayOf("sh", "-c", command))
        val stdout = BufferedReader(InputStreamReader(p.inputStream))
        val stderr = BufferedReader(InputStreamReader(p.errorStream))
        val sb = StringBuilder()
        while (true) {
            val line = stdout.readLine() ?: break
            sb.append(line).append('\n')
        }
        while (true) {
            val line = stderr.readLine() ?: break
            sb.append(line).append('\n')
        }
        stdout.close()
        stderr.close()
        val exit = p.waitFor()
        arrayOf(exit.toString(), sb.toString())
    } catch (e: Exception) {
        CameraDaemon.log("FormatStorage: shell command failed: " + e.message)
        arrayOf("-1", e.message ?: "exec error")
    }

    /** Accept only "public:" followed by alphanumerics and commas — no shell injection. */
    private fun isValidVolumeId(id: String?): Boolean =
        id != null && id.matches(Regex("public:[a-zA-Z0-9,]+"))

    private fun shellQuote(s: String): String = "'" + s.replace("'", "'\"'\"'") + "'"

    private class SmPublicVolume(val id: String, state: String, val uuid: String?) {
        val mounted: Boolean = "mounted" == state
    }
}
