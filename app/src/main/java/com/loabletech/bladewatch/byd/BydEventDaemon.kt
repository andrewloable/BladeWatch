package net.bladewatch.app.byd

import android.content.Context
import android.os.Looper
import android.os.Process

import net.bladewatch.app.byd.bodywork.BodyworkManager
import net.bladewatch.app.byd.radar.RadarManager
import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONObject

import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.BindException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.util.concurrent.CopyOnWriteArrayList

/**
 * BYD Event Daemon - runs as UID 1000 (system) via app_process.
 *
 * This daemon:
 * 1. Registers listeners with BYD SDK (Radar, Bodywork)
 * 2. Pushes events to connected clients via TCP (port 19878)
 * 3. Must run as UID 1000 to bypass Binder.getCallingUid() checks
 */
object BydEventDaemon {

    private val logger = DaemonLogger.getInstance("BydEventDaemon")
    private const val TCP_PORT = 19878

    @Volatile
    private var running = true

    private var serverSocket: ServerSocket? = null
    private val clients = CopyOnWriteArrayList<ClientHandler>()

    // Managers
    private var radarManager: RadarManager? = null
    private var bodyworkManager: BodyworkManager? = null

    /** 30 seconds */
    private const val BATTERY_POLL_INTERVAL_MS = 30000L

    @JvmStatic
    fun main(args: Array<String>) {
        val myUid = Process.myUid()

        logger.info("=== BYD Event Daemon Starting ===")
        logger.info("UID: $myUid")
        logger.info("PID: " + Process.myPid())

        if (myUid != 1000) {
            logger.warn("Not running as UID 1000! BYD SDK calls may fail.")
        } else {
            logger.info("Running as SYSTEM (UID 1000) - BYD SDK access enabled")
        }

        if (Looper.myLooper() == null) {
            Looper.prepare()
        }

        try {
            val context = createAppContext()
            if (context == null) {
                logger.error("Could not get context")
                return
            }
            logger.info("Got context: " + context.packageName)

            // Start TCP server
            Thread({ runTcpServer() }, "TcpServer").start()

            // Initialize managers
            radarManager = RadarManager(context, ::broadcastEvent, ::logMessage)
            bodyworkManager = BodyworkManager(context, ::broadcastEvent, ::logMessage)

            // Register listeners
            radarManager?.register()
            bodyworkManager?.register()

            // Start battery polling thread (every 30 seconds)
            Thread({ runBatteryPoller() }, "BatteryPoller").start()

            logger.info("Daemon ready, listening on TCP port $TCP_PORT")

            Looper.loop()
        } catch (e: Exception) {
            logger.error("FATAL: " + e.message)
            e.printStackTrace()
        }
    }

    // ==================== TCP SERVER ====================

    private fun runTcpServer() {
        logger.info("TCP server thread starting...")

        while (running) {
            try {
                serverSocket?.let {
                    if (!it.isClosed) {
                        try {
                            it.close()
                        } catch (e: Exception) {
                            logger.warn(
                                "BydEventDaemon runTcpServer: failed to close serverSocket: " +
                                    e.message
                            )
                        }
                    }
                }

                val server = ServerSocket(TCP_PORT, 10, InetAddress.getByName("127.0.0.1"))
                serverSocket = server
                server.reuseAddress = true
                logger.info("TCP server started on 127.0.0.1:$TCP_PORT")

                while (running && !server.isClosed) {
                    try {
                        val client = server.accept()
                        logger.info("Client connected from " + client.remoteSocketAddress)
                        val handler = ClientHandler(client)
                        clients.add(handler)
                        Thread(handler, "Client-" + System.currentTimeMillis()).start()
                    } catch (e: SocketException) {
                        if (running) logger.warn("TCP socket error: " + e.message)
                        break
                    }
                }

                if (running) {
                    logger.info("TCP server restarting...")
                    Thread.sleep(2000)
                }
            } catch (e: BindException) {
                logger.error("Port $TCP_PORT already in use, retrying in 5s...")
                try {
                    Thread.sleep(5000)
                } catch (ie: InterruptedException) {
                    logger.warn("Port bind retry sleep interrupted: " + ie.message)
                }
            } catch (e: Exception) {
                logger.error("TCP server error: " + e.message)
                if (running) {
                    try {
                        Thread.sleep(3000)
                    } catch (ie: InterruptedException) {
                        // Shutting down; the outer loop's `running` check handles it.
                    }
                }
            }
        }
    }

    private class ClientHandler(private val socket: Socket) : Runnable {
        private var writer: PrintWriter? = null

        @Volatile
        private var connected = true

        override fun run() {
            try {
                socket.soTimeout = 0
                val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
                val out = PrintWriter(socket.getOutputStream(), true)
                writer = out

                sendCurrentState(out)

                var line = reader.readLine()
                while (connected && line != null) {
                    logger.debug("Received: $line")
                    try {
                        out.println(processCommand(JSONObject(line)).toString())
                    } catch (e: Exception) {
                        val error = JSONObject()
                        error.put("status", "error")
                        error.put("message", e.message)
                        out.println(error.toString())
                    }
                    line = reader.readLine()
                }
            } catch (e: Exception) {
                logger.debug("Client disconnected: " + e.message)
            } finally {
                connected = false
                clients.remove(this)
                try {
                    socket.close()
                } catch (e: Exception) {
                    logger.warn(
                        "BydEventDaemon ClientHandler: failed to close client socket: " +
                            e.message
                    )
                }
            }
        }

        fun sendEvent(event: JSONObject) {
            val out = writer
            if (connected && out != null) {
                try {
                    out.println(event.toString())
                } catch (e: Exception) {
                    connected = false
                }
            }
        }

        private fun sendCurrentState(out: PrintWriter) {
            try {
                val state = JSONObject()
                state.put("type", "state")

                bodyworkManager?.let {
                    state.put("powerLevel", it.lastPowerLevel)
                    state.put("powerLevelName", it.getLastPowerLevelName())
                    state.put("batteryVoltageLevel", it.lastBatteryVoltageLevel)
                    state.put("batteryVoltageLevelName", it.getLastBatteryVoltageLevelName())
                    state.put("batteryVoltage", it.getLastBatteryVoltage())
                }

                radarManager?.let { state.put("radar", it.getStateAsJson()) }

                out.println(state.toString())
            } catch (e: Exception) {
                logger.error("Error sending state: " + e.message)
            }
        }
    }

    private fun processCommand(cmd: JSONObject): JSONObject {
        val command = cmd.optString("cmd", "")
        val response = JSONObject()

        when (command) {
            "ping" -> {
                response.put("status", "ok")
                response.put("message", "pong")
            }

            "status" -> {
                response.put("status", "ok")
                response.put("clients", clients.size)
                bodyworkManager?.let {
                    response.put("powerLevel", it.lastPowerLevel)
                    response.put("powerLevelName", it.getLastPowerLevelName())
                    response.put("bodyworkDevice", it.isRegistered)
                }
                radarManager?.let { response.put("radarDevice", it.isRegistered) }
            }

            "getRadar" -> {
                response.put("status", "ok")
                radarManager?.let {
                    val radar = it.getStateAsJson()
                    for (key in radar.keys()) {
                        response.put(key, radar.get(key))
                    }
                }
            }

            "getBattery" -> {
                response.put("status", "ok")
                bodyworkManager?.let {
                    // Refresh battery info first
                    it.refreshBatteryInfo()
                    response.put("voltageLevel", it.lastBatteryVoltageLevel)
                    response.put("voltageLevelName", it.getLastBatteryVoltageLevelName())
                    response.put("voltage", it.getLastBatteryVoltage())
                    response.put("powerValue", it.lastBatteryPowerValue)
                }
            }

            else -> {
                response.put("status", "error")
                response.put("message", "Unknown command: $command")
            }
        }

        logger.debug("Response: $response")
        return response
    }

    // ==================== BROADCASTING ====================

    @JvmStatic
    fun broadcastEvent(event: JSONObject) {
        for (client in clients) {
            client.sendEvent(event)
        }
    }

    // ==================== CONTEXT ====================

    private fun createAppContext(): Context? {
        return try {
            val activityThreadClass = Class.forName("android.app.ActivityThread")

            var activityThread = try {
                activityThreadClass.getMethod("currentActivityThread").invoke(null)
            } catch (e: Exception) {
                null
            }

            if (activityThread == null) {
                activityThread = activityThreadClass.getMethod("systemMain").invoke(null)
            }

            if (activityThread == null) return null

            val systemContext = activityThreadClass.getMethod("getSystemContext")
                .invoke(activityThread) as Context

            systemContext.createPackageContext(
                "net.bladewatch.app",
                Context.CONTEXT_INCLUDE_CODE or Context.CONTEXT_IGNORE_SECURITY
            )
        } catch (e: Exception) {
            logger.error("createAppContext failed: " + e.message)
            null
        }
    }

    // ==================== BATTERY POLLING ====================

    private fun runBatteryPoller() {
        logger.info(
            "Battery poller thread starting (interval: " + BATTERY_POLL_INTERVAL_MS + "ms)..."
        )

        while (running) {
            try {
                Thread.sleep(BATTERY_POLL_INTERVAL_MS)

                bodyworkManager?.let {
                    if (it.isRegistered) {
                        // Refresh battery info - this will broadcast to all clients
                        it.refreshBatteryInfo()
                    }
                }
            } catch (e: InterruptedException) {
                logger.info("Battery poller interrupted")
                break
            } catch (e: Exception) {
                logger.error("Battery poller error: " + e.message)
            }
        }

        logger.info("Battery poller thread exiting")
    }

    // ==================== LOGGING ====================

    /** Log message (for callback compatibility with managers). */
    @JvmStatic
    fun logMessage(message: String) {
        logger.info(message)
    }
}
