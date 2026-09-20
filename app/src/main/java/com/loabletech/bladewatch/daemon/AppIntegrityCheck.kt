package net.bladewatch.app.daemon

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import net.bladewatch.app.BuildConfig
import java.io.FileWriter
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * APK signing-certificate self-check (uy93.10).
 *
 * Protects against repackaged/tampered BladeWatch APKs distributed under the same package name
 * that could gain IPC access to the car daemon.
 *
 * HOW IT WORKS: the expected signing cert SHA-256 is baked into
 * `BuildConfig.RELEASE_CERT_SHA256` at CI build time. When that field is empty (dev builds,
 * unsigned APKs) the check is a no-op — unsigned builds are never blocked.
 *
 * ENFORCEMENT: on a signature mismatch [isTampered] returns true and callers refuse privileged
 * actions (IPC secret fetches). Non-privileged UI still works.
 *
 * PLAY INTEGRITY: investigated and DROPPED. BYD DiLink v3 is not a certified Android device and
 * does not have Google Play Services. The Play Integrity API requires com.google.android.gms at
 * runtime; without it every API call throws IntegrityServiceConnectionException. This certificate
 * self-check provides equivalent anti-repackaging protection without requiring Play Services.
 *
 * KILL-SWITCH: set `BuildConfig.RELEASE_CERT_SHA256` to "" at build time to skip enforcement
 * (the default for dev/unsigned builds).
 */
object AppIntegrityCheck {

    private const val SECURITY_LOG = "/data/local/tmp/bladewatch_security.log"

    /** null = not yet checked. */
    @Volatile
    private var tampered: Boolean? = null

    /**
     * True if the APK signing cert does NOT match the expected release cert. Always false when
     * `BuildConfig.RELEASE_CERT_SHA256` is empty (dev/unsigned). The result is cached after the
     * first check.
     */
    @JvmStatic
    fun isTampered(ctx: Context): Boolean {
        tampered?.let { return it }
        val computed = computeTampered(ctx)
        tampered = computed
        return computed
    }

    /**
     * The cached result, without requiring a Context. Returns false if [isTampered] has not been
     * called yet (fail-open). Safe to call from any thread after BladeWatchApplication.onCreate()
     * runs.
     */
    @JvmStatic
    fun isTamperedCached(): Boolean = tampered == true

    /** Force a fresh re-check (unit-test helper). */
    @JvmStatic
    fun resetForTest() {
        tampered = null
    }

    // --- implementation ---

    private fun computeTampered(ctx: Context): Boolean {
        val expected = BuildConfig.RELEASE_CERT_SHA256
        if (expected.isNullOrEmpty()) {
            // Dev / unsigned build — no expected cert configured, skip the check
            return false
        }
        return try {
            val pi = ctx.packageManager.getPackageInfo(
                ctx.packageName, PackageManager.GET_SIGNING_CERTIFICATES
            )

            val signingInfo = pi.signingInfo
            val sigs = if (Build.VERSION.SDK_INT >= 28 && signingInfo != null) {
                signingInfo.apkContentsSigners
            } else {
                null
            }
            if (sigs == null) {
                // Older API fallback — counts as unsigned/dev, no enforcement
                return false
            }

            val sha = MessageDigest.getInstance("SHA-256")
            for (sig in sigs) {
                sha.reset()
                if (bytesToHex(sha.digest(sig.toByteArray())).equals(expected, ignoreCase = true)) {
                    return false // cert matches
                }
            }

            // No cert matched — report tampering
            reportEvent("SIGNATURE_MISMATCH", "expected=$expected")
            true
        } catch (e: Exception) {
            // PackageManager unavailable (e.g. a test context) — fail-open
            false
        }
    }

    private fun reportEvent(type: String, detail: String) {
        try {
            val ts = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(Date())
            FileWriter(SECURITY_LOG, true).use { fw ->
                fw.write("$ts [INTEGRITY:$type] $detail\n")
            }
        } catch (ignored: Exception) {
            // The report is best-effort; losing it must not affect startup.
        }
    }

    private fun bytesToHex(bytes: ByteArray): String {
        val sb = StringBuilder(bytes.size * 2)
        for (b in bytes) sb.append(String.format("%02x", b))
        return sb.toString()
    }
}
