package net.bladewatch.app.notifications.push

import android.util.Base64
import android.util.Log
import org.json.JSONArray
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.Arrays
import java.util.Collections
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Persistent push-subscription store. A JSON file at the configured path.
 *
 * Concurrency model: all mutations are serialised via a single monitor on the instance. Reads
 * return defensive copies so iteration in `PushSink` doesn't race with subscribe/unsubscribe.
 */
class SubscriptionStore(private val file: File) {

    private val byId = LinkedHashMap<String, PushSubscription>()
    private val loaded = AtomicBoolean(false)

    @Synchronized
    fun load() {
        if (loaded.get()) return
        loaded.set(true)

        if (!file.exists() || file.length() == 0L) return
        try {
            FileInputStream(file).use { fis ->
                val arr = JSONArray(String(readAll(fis), Charsets.UTF_8))
                for (i in 0 until arr.length()) {
                    try {
                        val sub = PushSubscription.fromJson(arr.getJSONObject(i))
                        byId[sub.id] = sub
                    } catch (e: Exception) {
                        Log.w(
                            TAG,
                            "Skipping corrupt subscription entry at index " + i + ": " + e.message
                        )
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to load subscription store: " + e.message)
        }
    }

    @Synchronized
    fun all(): List<PushSubscription> {
        if (!loaded.get()) load()
        return Collections.unmodifiableList(ArrayList(byId.values))
    }

    @Synchronized
    fun get(id: String): PushSubscription? {
        if (!loaded.get()) load()
        return byId[id]
    }

    @Synchronized
    fun put(sub: PushSubscription) {
        if (!loaded.get()) load()
        byId[sub.id] = sub
        persist()
    }

    @Synchronized
    fun remove(id: String): Boolean {
        if (!loaded.get()) load()
        val removed = byId.remove(id) != null
        if (removed) persist()
        return removed
    }

    @Synchronized
    fun size(): Int {
        if (!loaded.get()) load()
        return byId.size
    }

    // ==================== INTERNAL ====================

    private fun persist() {
        val parent = file.parentFile
        if (parent != null && !parent.exists()) parent.mkdirs()

        val arr = JSONArray()
        for (sub in byId.values) arr.put(sub.toJson())

        val tmp = File(file.absolutePath + ".tmp")
        try {
            FileOutputStream(tmp).use { fos ->
                fos.write(arr.toString().toByteArray(Charsets.UTF_8))
                fos.fd.sync()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist subscriptions: " + e.message)
            return
        }
        // Atomic-rename happy path. On filesystems where rename-overwrite isn't supported, fall
        // through to the swap dance below.
        if (tmp.renameTo(file)) return

        // Swap dance: keep a backup so a second-rename failure doesn't leave us with zero
        // subscriptions. Previously this path did
        //     file.delete(); tmp.renameTo(file);
        // and a second-rename failure (volume unmount, permission flip) wiped every subscription
        // on next boot.
        val backup = File(file.absolutePath + ".bak")
        backup.delete()
        val haveBackup = file.renameTo(backup)
        if (!tmp.renameTo(file)) {
            // tmp couldn't move into place. Restore from backup so we don't end up with no
            // subscriptions on disk. Leave tmp on disk; load() ignores it.
            if (haveBackup) backup.renameTo(file)
            return
        }
        // New file is in place; remove the backup. Best-effort.
        if (haveBackup) backup.delete()
    }

    companion object {
        private const val TAG = "SubscriptionStore"

        @Throws(Exception::class)
        private fun readAll(fis: FileInputStream): ByteArray {
            val out = ByteArrayOutputStream()
            val buf = ByteArray(4096)
            while (true) {
                val n = fis.read(buf)
                if (n <= 0) break
                out.write(buf, 0, n)
            }
            return out.toByteArray()
        }

        /**
         * Derive a stable subscription id from the endpoint URL. The endpoint itself is large and
         * contains opaque tokens — we hash it so the id stays compact and consistent across
         * re-subscribe attempts.
         */
        @JvmStatic
        fun idForEndpoint(endpoint: String): String = try {
            val md = MessageDigest.getInstance("SHA-256")
            val digest = md.digest(endpoint.toByteArray(Charsets.UTF_8))
            Base64.encodeToString(
                Arrays.copyOf(digest, 12),
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            )
        } catch (e: Exception) {
            Log.w(
                TAG,
                "Failed to hash endpoint for subscription ID, falling back to hashCode: " +
                    e.message
            )
            Integer.toHexString(endpoint.hashCode())
        }
    }
}
