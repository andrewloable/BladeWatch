package net.bladewatch.app.server

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.connect.ConnectException
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.io.File
import java.io.FileInputStream

/**
 * Serves the 3D vehicle models for the vehicle-control page.
 *
 * All models ship inside the APK (bundled: true in manifest.json) and are extracted to WEB_ROOT at
 * startup. No network downloads are performed.
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/models/ paths and writing JSON into an
 * OutputStream that the Connect layer captured straight back out. Each operation now RETURNS its
 * JSON. Every model ships inside the APK, so the download operation is a constant — it is kept
 * because the clients still call it, not because anything is fetched.
 */
object ModelsApiHandler {

    private const val TAG = "ModelsApiHandler"
    private val logger: DaemonLogger = DaemonLogger.getInstance(TAG)

    const val MODELS_DIR = "/data/local/tmp/bladewatch/models"

    private const val MANIFEST_BUNDLED_PATH =
        "/data/local/tmp/web/shared/models/manifest.json"

    /** All models are bundled in the APK — there is nothing to download. */
    @JvmStatic
    @Throws(Exception::class)
    fun download(): JSONObject {
        val response = JSONObject()
        response.put("ok", true)
        response.put("alreadyCached", true)
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun getManifest(): JSONObject = readManifest()
        ?: throw ConnectException("unavailable", Messages.get("errors.models_no_manifest"))

    @JvmStatic
    @Throws(Exception::class)
    fun getSelected(): JSONObject {
        val vehicle = UnifiedConfigManager.getVehicle()
        val manifest = readManifest()
        val defaultId = manifest?.optString("default", "destroyer") ?: "destroyer"
        var modelId = vehicle.optString("modelId", defaultId)
        if (manifest != null && findModel(manifest, modelId) == null) {
            modelId = defaultId
        }
        val response = JSONObject()
        response.put("modelId", modelId)
        response.put("color", vehicle.optString("color", "#E8E8EC"))
        return response
    }

    /**
     * True iff the color string matches a valid 6-digit CSS hex color (#RRGGBB). Pure function —
     * safe to call in unit tests, which is why it is public rather than module-internal (Kotlin
     * mangles `internal` names, and ModelsApiHandlerValidationTest is Java).
     */
    @JvmStatic
    fun isValidColor(color: String?): Boolean =
        color != null && color.matches(Regex("^#[0-9A-Fa-f]{6}$"))

    /**
     * True iff [id] is present in the manifest's models array. Pure function — see [isValidColor]
     * on why it is public.
     *
     * @param manifest a parsed manifest JSONObject (must not be null)
     * @param id the candidate model id
     */
    @JvmStatic
    fun isValidModelId(manifest: JSONObject?, id: String?): Boolean {
        if (manifest == null || id == null) return false
        return findModel(manifest, id) != null
    }

    @JvmStatic
    @Throws(Exception::class)
    fun setSelected(requestBody: String?): JSONObject {
        if (requestBody.isNullOrEmpty()) {
            throw ConnectException("invalid_argument", Messages.get("errors.models_empty_body"))
        }
        val incoming = try {
            JSONTokener(requestBody).nextValue() as JSONObject
        } catch (e: Exception) {
            logger.warn("Failed to parse incoming JSON body: " + e.message)
            throw ConnectException("invalid_argument", Messages.get("errors.models_invalid_json"))
        }
        val patch = JSONObject()
        if (incoming.has("modelId")) {
            val id = incoming.optString("modelId")
            val manifest = readManifest()
            if (manifest != null && !isValidModelId(manifest, id)) {
                throw ConnectException(
                    "invalid_argument", Messages.get("errors.models_unknown_id_with_id", id)
                )
            }
            patch.put("modelId", id)
        }
        if (incoming.has("color")) {
            val color = incoming.optString("color", "")
            if (!isValidColor(color)) {
                throw ConnectException(
                    "invalid_argument", Messages.get("errors.models_invalid_color")
                )
            }
            patch.put("color", color)
        }
        if (patch.length() == 0) {
            throw ConnectException(
                "invalid_argument", Messages.get("errors.models_nothing_to_update")
            )
        }
        if (!UnifiedConfigManager.setVehicle(patch)) {
            throw ConnectException("internal", Messages.get("errors.models_persist_failed"))
        }
        val response = JSONObject()
        response.put("ok", true)
        return response
    }

    /** Returns a GLB from the legacy download cache, used as a fallback by HttpServer. */
    @JvmStatic
    fun cachedModelFile(fileName: String?): File? {
        if (fileName == null || fileName.contains("/") || fileName.contains("..")) return null
        val f = File(MODELS_DIR, fileName)
        return if (f.exists() && f.isFile) f else null
    }

    /**
     * Look up the nominal pack capacity (kWh) for the user-selected model. Consulted by
     * VehicleDataMonitor.getNominalCapacityKwh() as the per-trim fallback when the SDK reports no
     * capacity (BladeWatch-x4lf). Returns 0 on any failure.
     */
    @JvmStatic
    fun nominalKwhForSelectedModel(): Double = try {
        val modelId = UnifiedConfigManager.getVehicle().optString("modelId", "")
        if (modelId.isEmpty()) {
            0.0
        } else {
            val manifest = readManifest()
            val m = if (manifest == null) null else findModel(manifest, modelId)
            m?.optDouble("nominalKwh", 0.0) ?: 0.0
        }
    } catch (t: Throwable) {
        logger.warn("nominalKwhForSelectedModel failed: " + t.message)
        0.0
    }

    @JvmStatic
    @Throws(Exception::class)
    fun list(): JSONObject {
        val manifest = readManifest()
            ?: throw ConnectException(
                "unavailable", Messages.get("errors.models_manifest_unavailable")
            )
        val models = manifest.optJSONArray("models") ?: JSONArray()

        val result = JSONArray()
        for (i in 0 until models.length()) {
            val m = models.getJSONObject(i)
            val o = JSONObject()
            o.put("id", m.optString("id"))
            o.put("name", m.optString("name", m.optString("id")))
            o.put("file", m.optString("file"))
            o.put("sizeBytes", m.optLong("sizeBytes", 0))
            o.put("bundled", true)
            o.put("downloaded", true)
            o.put("cachedSizeBytes", 0)
            result.put(o)
        }

        val response = JSONObject()
        response.put("models", result)
        response.put("default", manifest.optString("default", "destroyer"))
        return response
    }

    private fun readManifest(): JSONObject? = readManifestFile(File(MANIFEST_BUNDLED_PATH))

    private fun readManifestFile(f: File): JSONObject? {
        if (!f.exists()) return null
        return try {
            FileInputStream(f).use { fis ->
                val buf = ByteArray(f.length().toInt())
                var totalRead = 0
                while (totalRead < buf.size) {
                    val n = fis.read(buf, totalRead, buf.size - totalRead)
                    if (n == -1) break
                    totalRead += n
                }
                val json = String(buf, 0, totalRead, Charsets.UTF_8)
                val parsed = JSONTokener(json).nextValue() as JSONObject
                if (!parsed.has("version") || parsed.optJSONArray("models") == null) {
                    logger.warn(
                        TAG + ": manifest at " + f.absolutePath + " missing required fields"
                    )
                    null
                } else {
                    parsed
                }
            }
        } catch (e: Exception) {
            logger.warn(
                TAG + ": failed to read manifest at " + f.absolutePath + ": " + e.message
            )
            null
        }
    }

    private fun findModel(manifest: JSONObject, id: String): JSONObject? {
        val arr = manifest.optJSONArray("models") ?: return null
        for (i in 0 until arr.length()) {
            val m = arr.optJSONObject(i)
            if (m != null && id == m.optString("id")) return m
        }
        return null
    }
}
