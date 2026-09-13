package net.bladewatch.bladewatch_ui.network

import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build

/**
 * BladeWatch-yz1e.4 (Diagnostics → Network health tile): this APK's own
 * network-state probe. Ported from
 * `app/src/main/java/com/loabletech/bladewatch/ui/fragment/DiagnosticsFragment.kt`'s
 * `computeNetworkTopLine()` — this is plain on-device OS telemetry with no
 * daemon involvement at all, so unlike most of this port it needs no IPC:
 * both APKs run on the same device and can each ask Android directly.
 *
 * Excluded from the Kover coverage gate (see `build.gradle.kts`) for the
 * same reason `PackageInstallerBridge` is: `ConnectivityManager`/
 * `WifiManager` are framework services this project does not use Robolectric
 * to fake, so this class is kept to plain wiring with no branches of its own
 * beyond what the framework APIs already branch on.
 */
class NetworkInfoChannel(private val context: Context) {

    /** Result shape: `type` is one of "wifi"/"mobile"/"ethernet"/"offline"; `ssid` is set only for "wifi". */
    fun currentNetwork(): Map<String, Any?> {
        try {
            val appContext = context.applicationContext
            val wifi = appContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val cm = appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                cm?.getNetworkCapabilities(cm.activeNetwork)?.transportInfo as? WifiInfo
            } else {
                @Suppress("DEPRECATION")
                wifi?.connectionInfo
            }
            val rawSsid = info?.ssid
            val networkId = info?.networkId ?: -1
            if (!rawSsid.isNullOrBlank() && rawSsid != WifiManager.UNKNOWN_SSID && rawSsid != "0x" && networkId != -1) {
                val stripped = if (rawSsid.length >= 2 && rawSsid.startsWith("\"") && rawSsid.endsWith("\"")) {
                    rawSsid.substring(1, rawSsid.length - 1)
                } else {
                    rawSsid
                }
                if (stripped.isNotBlank()) {
                    return mapOf("type" to "wifi", "ssid" to stripped)
                }
            }
        } catch (_: SecurityException) {
            // Permission denied — fall through to the type-only probe below.
        } catch (_: Throwable) {
            // Defensive — never let this probe crash the caller.
        }

        return try {
            val cm = context.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            @Suppress("DEPRECATION")
            val ni = cm?.activeNetworkInfo
            @Suppress("DEPRECATION")
            val type = when {
                ni == null || !ni.isConnected -> "offline"
                ni.type == ConnectivityManager.TYPE_MOBILE -> "mobile"
                ni.type == ConnectivityManager.TYPE_ETHERNET -> "ethernet"
                else -> "offline"
            }
            mapOf("type" to type, "ssid" to null)
        } catch (_: Throwable) {
            mapOf("type" to "offline", "ssid" to null)
        }
    }
}
