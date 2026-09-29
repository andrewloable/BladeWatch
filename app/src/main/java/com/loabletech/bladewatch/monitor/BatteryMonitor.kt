package net.bladewatch.app.monitor

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.server.IpcTokenManager
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.Socket
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Fetches battery info from SurveillanceIpcServer (port 19877) for the status API's display.
 */
object BatteryMonitor {

    private const val SURVEILLANCE_IPC_PORT = 19877

    @Volatile
    private var lastBatteryVoltage = 0.0

    @Volatile
    private var lastBatteryLevel = "UNKNOWN"

    @Volatile
    private var lastBatterySoc = 0.0

    @Volatile
    private var lastBatteryUpdate = 0L

    private const val REFRESH_MS = 30_000L

    /** When a refresh was last started, successful or not -- so a failing one is not retried per call. */
    @Volatile
    private var lastAttempt = 0L
    private val refreshing = AtomicBoolean(false)
    private val refresher: ExecutorService =
        Executors.newSingleThreadExecutor { r -> Thread(r, "BatteryRefresh").apply { isDaemon = true } }

    // Test seams.
    internal var clock: () -> Long = System::currentTimeMillis
    internal var fetcher: () -> Unit = ::fetchBatteryInfo

    internal fun resetForTest() {
        lastAttempt = 0L
        lastBatteryUpdate = 0L
        refreshing.set(false)
        clock = System::currentTimeMillis
        fetcher = ::fetchBatteryInfo
    }

    /**
     * Derive the battery level from the actual voltage when the BYD API returns INVALID.
     *
     * 12V automotive battery voltage ranges:
     *  - below 11.8V: LOW (battery needs charging)
     *  - 11.8V to 14.8V: NORMAL (healthy range; 14.4V+ when charging)
     *  - above 14.8V: overcharging warning
     */
    private fun deriveLevelFromVoltage(voltage: Double): String = when {
        voltage <= 0 -> "UNKNOWN"
        voltage < 11.8 -> "LOW"
        voltage <= 14.8 -> "NORMAL"
        else -> "HIGH" // Overcharging
    }

    /** Fetch battery info from SurveillanceIpcServer. */
    @JvmStatic
    fun fetchBatteryInfo() {
        try {
            Socket("127.0.0.1", SURVEILLANCE_IPC_PORT).use { socket ->
                socket.soTimeout = 3000

                val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
                val writer = PrintWriter(socket.getOutputStream(), true)

                // Send GET_VEHICLE_DATA with the auth token
                val req = JSONObject()
                req.put("command", "GET_VEHICLE_DATA")
                IpcTokenManager.getToken()?.let { req.put("token", it) }
                writer.println(req.toString())

                val response = reader.readLine() ?: return
                val result = JSONObject(response)

                if (!result.optBoolean("success", false)) return
                val data = result.optJSONObject("data") ?: return

                // Battery power voltage (actual volts)
                data.optJSONObject("batteryPower")?.let {
                    lastBatteryVoltage = it.optDouble("voltageVolts", 0.0)
                }

                // Battery voltage level (LOW/NORMAL/INVALID)
                val batteryVoltage = data.optJSONObject("batteryVoltage")
                lastBatteryLevel = if (batteryVoltage != null) {
                    val apiLevel = batteryVoltage.optString("levelName", "UNKNOWN")
                    // If the BYD API returns INVALID, derive the level from the actual voltage
                    if ("INVALID" == apiLevel || "UNKNOWN" == apiLevel) {
                        deriveLevelFromVoltage(lastBatteryVoltage)
                    } else {
                        apiLevel
                    }
                } else {
                    // No API data, derive from voltage
                    deriveLevelFromVoltage(lastBatteryVoltage)
                }

                // Battery SOC percentage
                data.optJSONObject("batterySoc")?.let {
                    lastBatterySoc = it.optDouble("socPercent", 0.0)
                }

                lastBatteryUpdate = System.currentTimeMillis()
                CameraDaemon.log(
                    "Battery updated: " + lastBatteryVoltage + "V (" + lastBatteryLevel +
                        "), SOC: " + lastBatterySoc + "%"
                )
            }
        } catch (e: Exception) {
            CameraDaemon.log("Battery info fetch: " + e.message)
        }
    }

    /**
     * Battery info as JSON, refreshed at most every 30 s -- but never on the caller's thread after
     * the first call. A refresh is an IPC round trip to the surveillance daemon (measured ~700 ms),
     * and SystemService.GetStatus, which the dashboard polls, used to wait for it every 30 s; a
     * failing refresh never advanced the timestamp, so then it waited on EVERY call
     * (BladeWatch-1996). Only the very first call fetches inline, so GetStatus reports the same
     * values it always has.
     */
    @JvmStatic
    fun getBatteryInfo(): JSONObject {
        val now = clock()
        if (lastAttempt == 0L) {
            lastAttempt = now
            fetcher()
        } else if (now - lastAttempt > REFRESH_MS && refreshing.compareAndSet(false, true)) {
            lastAttempt = now
            refresher.execute {
                try {
                    fetcher()
                } finally {
                    refreshing.set(false)
                }
            }
        }

        val battery = JSONObject()
        try {
            battery.put("voltage", lastBatteryVoltage)
            battery.put("level", lastBatteryLevel)
            battery.put("soc", lastBatterySoc)
            battery.put("lastUpdate", lastBatteryUpdate)
        } catch (e: Exception) {
            CameraDaemon.log("Battery: Failed to create battery info JSON: " + e.message)
        }
        return battery
    }
}
