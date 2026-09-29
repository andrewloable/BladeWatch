package net.bladewatch.app.monitor

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkAddress
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Process

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon

import org.json.JSONObject

import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.Inet4Address
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * Network Monitor - provides WiFi SSID, IP address, or Mobile Data status
 * for the HTTP status API sidebar display.
 *
 * Strategy:
 * 1. Try standard Android APIs (ConnectivityManager/WifiManager) first
 * 2. Fall back to shell commands (ip addr, dumpsys wifi) if Android APIs fail
 *
 * The shell fallback uses Runtime.exec() directly (same pattern as AccSentryDaemon,
 * SentryDaemon, etc.) — NOT AdbShellExecutor which requires ADB over TCP.
 */
object NetworkMonitor {

    @Volatile
    private var networkType = "none"

    @Volatile
    private var wifiSsid = ""

    @Volatile
    private var ipAddress = ""

    @Volatile
    private var signalPercent = -1

    @Volatile
    private var lastUpdate = 0L

    @Volatile
    private var appContext: Context? = null

    @Volatile
    private var shellFallbackLogged = false

    private const val REFRESH_MS = 10_000L

    /** When a refresh was last started, successful or not -- so a failing one is not retried per call. */
    @Volatile
    private var lastAttempt = 0L
    private val refreshing = AtomicBoolean(false)
    private val refresher: ExecutorService =
        Executors.newSingleThreadExecutor { r -> Thread(r, "NetworkRefresh").apply { isDaemon = true } }

    // Test seams.
    internal var clock: () -> Long = System::currentTimeMillis
    internal var refreshAction: () -> Unit = ::refresh

    internal fun resetForTest() {
        lastAttempt = 0L
        refreshing.set(false)
        clock = System::currentTimeMillis
        refreshAction = ::refresh
    }

    // ==================== DATA USAGE (BladeWatch-t1lg.1) ====================

    private val rxAccumulator = DataUsageAccumulator()
    private val txAccumulator = DataUsageAccumulator()
    private const val DATA_USAGE_SAMPLE_INTERVAL_SECONDS = 60L
    private var dataUsageScheduler: ScheduledExecutorService? = null

    @JvmStatic
    fun init(context: Context?) {
        appContext = context
        CameraDaemon.log(
            "NetworkMonitor: init with context=" +
                (context?.javaClass?.simpleName ?: "null")
        )
        refresh()

        loadDataUsageState()
        sampleDataUsage() // one immediate sample so /status isn't empty until the first tick
        startDataUsageSampling()
    }

    /**
     * Own-UID (own network) totals only, not whole-device usage — see
     * [DataUsageAccumulator]'s own doc comment for why a naive counter is wrong across a
     * reboot. Starts a low-priority periodic sampler; idempotent, safe to call more than once.
     */
    private fun startDataUsageSampling() {
        if (dataUsageScheduler != null) return
        val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "DataUsageSampler").apply {
                isDaemon = true
                priority = Thread.MIN_PRIORITY
            }
        }
        dataUsageScheduler = scheduler
        scheduler.scheduleAtFixedRate(
            { sampleDataUsage() },
            DATA_USAGE_SAMPLE_INTERVAL_SECONDS, DATA_USAGE_SAMPLE_INTERVAL_SECONDS,
            TimeUnit.SECONDS
        )
    }

    private fun sampleDataUsage() {
        try {
            val uid = Process.myUid()
            val rx = TrafficStats.getUidRxBytes(uid)
            val tx = TrafficStats.getUidTxBytes(uid)
            val now = System.currentTimeMillis()
            rxAccumulator.sample(rx, now)
            txAccumulator.sample(tx, now)
            saveDataUsageState()
        } catch (e: Exception) {
            CameraDaemon.log("NetworkMonitor: data usage sampling failed: " + e.message)
        }
    }

    private fun loadDataUsageState() {
        try {
            val section = UnifiedConfigManager.loadConfig().optJSONObject("dataUsage") ?: return
            rxAccumulator.restore(
                section.optLong("rxLastReading", -1L),
                section.optLong("rxAccumulatedThisMonth", 0L),
                section.optInt("rxCurrentMonthKey", -1),
                section.optLong("rxLastMonthTotal", 0L),
                section.optInt("rxLastMonthKey", -1)
            )
            txAccumulator.restore(
                section.optLong("txLastReading", -1L),
                section.optLong("txAccumulatedThisMonth", 0L),
                section.optInt("txCurrentMonthKey", -1),
                section.optLong("txLastMonthTotal", 0L),
                section.optInt("txLastMonthKey", -1)
            )
        } catch (e: Exception) {
            CameraDaemon.log("NetworkMonitor: failed to load data usage state: " + e.message)
        }
    }

    private fun saveDataUsageState() {
        try {
            val section = JSONObject()
            section.put("rxLastReading", rxAccumulator.lastReading)
            section.put("rxAccumulatedThisMonth", rxAccumulator.accumulatedThisMonth)
            section.put("rxCurrentMonthKey", rxAccumulator.currentMonthKeyForPersistence())
            section.put("rxLastMonthTotal", rxAccumulator.lastMonthTotal)
            section.put("rxLastMonthKey", rxAccumulator.lastMonthKeyForPersistence())
            section.put("txLastReading", txAccumulator.lastReading)
            section.put("txAccumulatedThisMonth", txAccumulator.accumulatedThisMonth)
            section.put("txCurrentMonthKey", txAccumulator.currentMonthKeyForPersistence())
            section.put("txLastMonthTotal", txAccumulator.lastMonthTotal)
            section.put("txLastMonthKey", txAccumulator.lastMonthKeyForPersistence())
            UnifiedConfigManager.updateSection("dataUsage", section)
        } catch (e: Exception) {
            CameraDaemon.log("NetworkMonitor: failed to save data usage state: " + e.message)
        }
    }

    /** This-month / last-month totals (rx+tx combined), for the /status network block. */
    @JvmStatic
    fun getDataUsageInfo(): JSONObject {
        val usage = JSONObject()
        try {
            usage.put(
                "thisMonthBytes",
                rxAccumulator.accumulatedThisMonth + txAccumulator.accumulatedThisMonth
            )
            usage.put(
                "lastMonthBytes",
                rxAccumulator.lastMonthTotal + txAccumulator.lastMonthTotal
            )
        } catch (e: Exception) {
            CameraDaemon.log("DEBUG: getDataUsageInfo JSON build failed: " + e.message)
        }
        return usage
    }

    /** Refresh network state. Tries Android APIs first, falls back to shell. */
    @JvmStatic
    fun refresh() {
        // Try Android APIs first
        if (appContext != null && tryAndroidApis()) {
            return
        }
        // Fallback: shell commands
        tryShellFallback()
    }

    // ==================== ANDROID API APPROACH ====================

    private fun tryAndroidApis(): Boolean {
        try {
            val ctx = appContext ?: return false
            val cm = ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager?
            if (cm == null) {
                CameraDaemon.log("NetworkMonitor: ConnectivityManager is null")
                return false
            }

            // Silent fallback — common when running as UID 2000 (shell daemon)
            val activeNetwork = cm.activeNetwork ?: return false

            val caps = cm.getNetworkCapabilities(activeNetwork) ?: return false

            // Get IP from LinkProperties
            var ip = ""
            try {
                val lp = cm.getLinkProperties(activeNetwork)
                if (lp != null) {
                    for (la: LinkAddress in lp.linkAddresses) {
                        val addr = la.address
                        if (addr is Inet4Address && !addr.isLoopbackAddress) {
                            ip = addr.hostAddress ?: ""
                            break
                        }
                    }
                }
            } catch (e: Exception) {
                // LinkProperties may fail under UID 2000 — not critical, IP from shell
            }

            when {
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> {
                    networkType = "wifi"
                    ipAddress = ip
                    readWifiDetailsAndroid()
                    lastUpdate = System.currentTimeMillis()
                    return true
                }

                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                    setNonWifi("cellular", ip)
                    return true
                }

                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> {
                    setNonWifi("ethernet", ip)
                    return true
                }
            }

            return false
        } catch (e: SecurityException) {
            // UID 2000 (shell) cannot access package manager APIs on some devices.
            // "Package android does not belong to 2000" — expected on DiLink 5.
            // Silent fallback to shell commands which work fine under UID 2000.
            if (!shellFallbackLogged) {
                CameraDaemon.log(
                    "NetworkMonitor: Android APIs unavailable (UID 2000), using shell fallback"
                )
                shellFallbackLogged = true
            }
            return false
        } catch (e: Exception) {
            // Other unexpected errors — log once then go silent
            if (!shellFallbackLogged) {
                CameraDaemon.log(
                    "NetworkMonitor: Android API error: " + e.message + " — using shell fallback"
                )
                shellFallbackLogged = true
            }
            return false
        }
    }

    /** Cellular / ethernet / none all report the same shape: a type, an IP, no Wi-Fi fields. */
    private fun setNonWifi(type: String, ip: String) {
        networkType = type
        ipAddress = ip
        wifiSsid = ""
        signalPercent = -1
        lastUpdate = System.currentTimeMillis()
    }

    private fun readWifiDetailsAndroid() {
        try {
            val ctx = appContext ?: return
            val wm = ctx.getSystemService(Context.WIFI_SERVICE) as WifiManager?
            if (wm == null) {
                CameraDaemon.log("NetworkMonitor: WifiManager is null")
                wifiSsid = "WiFi"
                return
            }
            val info: WifiInfo? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val cm =
                    ctx.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager?
                val activeNetwork = cm?.activeNetwork
                val caps = if (cm != null && activeNetwork != null) {
                    cm.getNetworkCapabilities(activeNetwork)
                } else {
                    null
                }
                // API 31+ moved Wi-Fi identity to NetworkCapabilities; older
                // Android Auto head units still use WifiManager below.
                caps?.transportInfo as? WifiInfo
            } else {
                @Suppress("DEPRECATION")
                wm.connectionInfo
            }
            if (info == null) {
                wifiSsid = "WiFi"
                return
            }
            var ssid: String? = info.ssid
            if (ssid != null && ssid.startsWith("\"") && ssid.endsWith("\"")) {
                ssid = ssid.substring(1, ssid.length - 1)
            }
            wifiSsid = if (ssid == null || ssid.contains("unknown") || ssid == "<none>") {
                // SSID hidden by Android — try shell fallback for SSID only
                val shellSsid = shellGetWifiSsid()
                if (!shellSsid.isNullOrEmpty()) shellSsid else "WiFi"
            } else {
                ssid
            }
            signalPercent = rssiToPercent(info.rssi)
        } catch (e: Exception) {
            CameraDaemon.log("NetworkMonitor: WifiInfo error: " + e.message)
            wifiSsid = "WiFi"
        }
    }

    private fun rssiToPercent(rssi: Int): Int = ((rssi + 90) * 100 / 60).coerceIn(0, 100)

    // ==================== SHELL FALLBACK ====================

    private fun tryShellFallback() {
        try {
            // Check wlan0 for WiFi
            val wlanIp = ifaceIp("wlan0")
            if (wlanIp.isNotEmpty()) {
                networkType = "wifi"
                ipAddress = wlanIp
                val ssid = shellGetWifiSsid()
                wifiSsid = if (!ssid.isNullOrEmpty()) ssid else "WiFi"
                shellGetWifiSignal()
                lastUpdate = System.currentTimeMillis()
                return
            }

            // Check rmnet for mobile data
            for (iface in arrayOf("rmnet_data0", "rmnet_data1", "rmnet_data2", "rmnet_data3")) {
                val rmnetIp = ifaceIp(iface)
                if (rmnetIp.isNotEmpty()) {
                    setNonWifi("cellular", rmnetIp)
                    return
                }
            }

            // Check eth0
            val ethIp = ifaceIp("eth0")
            if (ethIp.isNotEmpty()) {
                setNonWifi("ethernet", ethIp)
                return
            }

            // No network
            setNonWifi("none", "")
        } catch (e: Exception) {
            CameraDaemon.log("NetworkMonitor: shell fallback error: " + e.message)
        }
    }

    private fun ifaceIp(iface: String): String = execShell(
        "ip addr show $iface 2>/dev/null | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1"
    )

    /** Get WiFi SSID via shell (dumpsys wifi or wpa_cli). */
    private fun shellGetWifiSsid(): String? {
        // Try dumpsys wifi — look for SSID in mWifiInfo line
        val dump = execShell("dumpsys wifi 2>/dev/null | grep 'mWifiInfo' | head -1")
        if (dump.isNotEmpty()) {
            var idx = dump.indexOf("SSID: ")
            if (idx >= 0) {
                idx += 6
                var end = dump.indexOf(",", idx)
                if (end < 0) end = dump.length
                var ssid = dump.substring(idx, end).trim()
                if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
                    ssid = ssid.substring(1, ssid.length - 1)
                }
                if (ssid.isNotEmpty() && !ssid.contains("unknown") && ssid != "<none>") {
                    return ssid
                }
            }
        }
        // Fallback: wpa_cli
        val wpa = execShell("wpa_cli -i wlan0 status 2>/dev/null | grep '^ssid='")
        if (wpa.startsWith("ssid=")) {
            return wpa.substring(5).trim()
        }
        return null
    }

    private fun shellGetWifiSignal() {
        val wpa = execShell("wpa_cli -i wlan0 signal_poll 2>/dev/null | grep '^RSSI='")
        if (wpa.startsWith("RSSI=")) {
            try {
                signalPercent = rssiToPercent(wpa.substring(5).trim().toInt())
                return
            } catch (e: NumberFormatException) {
                CameraDaemon.log("DEBUG: RSSI parse failed: " + e.message)
            }
        }
        signalPercent = -1
    }

    // ==================== STATUS API ====================

    /**
     * Network info for SystemService.GetStatus, refreshed when older than 10 s. The refresh can
     * run `dumpsys wifi` (the shell fallback, which the daemon takes), and it used to run on the
     * request: GetStatus stalled 600-850 ms every ~11 s, measured on the head unit after the
     * battery half of BladeWatch-1996 was fixed. Only the very first call refreshes inline, so
     * GetStatus reports the same values it always has; later ones refresh in the background, one
     * at a time.
     */
    @JvmStatic
    fun getNetworkInfo(): JSONObject {
        val now = clock()
        if (lastAttempt == 0L) {
            lastAttempt = now
            refreshAction()
        } else if (now - lastAttempt > REFRESH_MS && refreshing.compareAndSet(false, true)) {
            lastAttempt = now
            refresher.execute {
                try {
                    refreshAction()
                } finally {
                    refreshing.set(false)
                }
            }
        }
        val net = JSONObject()
        try {
            net.put("type", networkType)
            net.put("ssid", wifiSsid)
            net.put("ip", ipAddress)
            net.put("signal", signalPercent)
        } catch (e: Exception) {
            CameraDaemon.log("DEBUG: getNetworkInfo JSON build failed: " + e.message)
        }
        return net
    }

    // ==================== SHELL UTIL ====================

    private fun execShell(cmd: String): String = try {
        val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", cmd))
        val sb = StringBuilder()
        BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
            var line = reader.readLine()
            while (line != null) {
                if (sb.isNotEmpty()) sb.append("\n")
                sb.append(line)
                line = reader.readLine()
            }
        }
        process.waitFor()
        sb.toString().trim()
    } catch (e: Exception) {
        ""
    }
}
