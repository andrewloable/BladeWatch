package net.bladewatch.app.monitor

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import android.os.Process

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONArray
import org.json.JSONObject

import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.io.RandomAccessFile
import java.util.LinkedList
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

import kotlin.math.roundToLong

/**
 * SOTA Performance Monitor - Tracks CPU, Memory, GPU, and app-specific metrics.
 *
 * Collects metrics at configurable intervals and maintains history for charting.
 * Optimized for minimal overhead while providing comprehensive instrumentation.
 *
 * ON-DEMAND ARCHITECTURE:
 * - CPU/GPU/Memory polling only runs when clients are actively viewing the performance page
 * - Uses reference counting to track active clients
 * - Auto-starts when first client connects, auto-stops when last client disconnects
 * - Clients must send heartbeats to maintain connection (timeout: 10 seconds)
 */
class PerformanceMonitor private constructor() {

    // Context
    private var context: Context? = null
    private var activityManager: ActivityManager? = null
    private var pid = 0
    private var uid = 0

    // Metrics history (circular buffers)
    private val history = LinkedList<PerformanceSnapshot>()
    private val latestSnapshot = AtomicReference<PerformanceSnapshot?>()

    // CPU tracking
    private var lastCpuTime = 0L
    private var lastAppCpuTime = 0L

    /** Tracks CPU time baseline for app CPU calculation */
    private var lastCpuTimeForApp = 0L
    private var lastIdleTime = 0L

    // Scheduler
    private var scheduler: ScheduledExecutorService? = null

    @Volatile
    var isRunning = false
        private set

    private val csvLock = Any()

    @Volatile
    private var csvEnabled = false

    /** SOTA: Client connection tracking for on-demand polling */
    private val activeClients = ConcurrentHashMap<String, Long>()
    private var clientCleanupScheduler: ScheduledExecutorService? = null

    // ==================== LIFECYCLE ====================

    fun init(context: Context?) {
        this.context = context
        if (context != null) {
            activityManager =
                context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager?
        }
        pid = Process.myPid()
        uid = Process.myUid()
        logger.info("PerformanceMonitor initialized (PID: $pid, UID: $uid)")
    }

    fun start() {
        if (isRunning) return
        isRunning = true

        csvEnabled = UnifiedConfigManager.isTimingLogsEnabled()
        if (csvEnabled) {
            initCsvFile()
        }

        val s = Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "PerfMonitor").apply { priority = Thread.MIN_PRIORITY }
        }
        scheduler = s

        s.scheduleAtFixedRate(
            { collectMetrics() }, 0, SAMPLE_INTERVAL_MS, TimeUnit.MILLISECONDS
        )
        logger.info("Performance monitoring started (csvPersistence=$csvEnabled)")
    }

    fun stop() {
        isRunning = false
        scheduler?.shutdownNow()
        scheduler = null
        csvEnabled = false
        logger.info("Performance monitoring stopped")
    }

    // ==================== SOTA: ON-DEMAND CLIENT MANAGEMENT ====================

    /**
     * Register a client connection. Starts monitoring if this is the first client.
     * @param clientId Unique identifier for the client (e.g., session ID or IP:port)
     */
    fun clientConnected(clientId: String?) {
        val id = if (clientId.isNullOrEmpty()) {
            "anonymous-" + System.currentTimeMillis()
        } else {
            clientId
        }

        val wasEmpty = activeClients.isEmpty()
        activeClients[id] = System.currentTimeMillis()

        logger.debug("Client connected: " + id + " (total: " + activeClients.size + ")")

        // Start monitoring if this is the first client
        if (wasEmpty) {
            logger.info("First client connected - starting performance monitoring")
            start()
            startClientCleanup()
        }
    }

    /**
     * Update client heartbeat timestamp.
     * @param clientId Client identifier
     */
    fun clientHeartbeat(clientId: String?) {
        if (clientId == null) return
        if (activeClients.containsKey(clientId)) {
            activeClients[clientId] = System.currentTimeMillis()
        } else {
            // New client via heartbeat - register it
            clientConnected(clientId)
        }
    }

    /**
     * Unregister a client connection. Stops monitoring if this was the last client.
     * @param clientId Client identifier
     */
    fun clientDisconnected(clientId: String?) {
        if (clientId == null) return

        val removed = activeClients.remove(clientId)
        if (removed != null) {
            logger.debug(
                "Client disconnected: " + clientId + " (remaining: " + activeClients.size + ")"
            )

            // Stop monitoring if no clients remain
            if (activeClients.isEmpty()) {
                logger.info("Last client disconnected - stopping performance monitoring")
                stop()
                stopClientCleanup()
            }
        }
    }

    /** Start the client cleanup scheduler to remove stale clients. */
    private fun startClientCleanup() {
        if (clientCleanupScheduler != null) return

        val s = Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "PerfClientCleanup").apply { priority = Thread.MIN_PRIORITY }
        }
        clientCleanupScheduler = s

        s.scheduleAtFixedRate(
            { cleanupStaleClients() },
            CLEANUP_INTERVAL_MS, CLEANUP_INTERVAL_MS, TimeUnit.MILLISECONDS
        )
    }

    /** Stop the client cleanup scheduler. */
    private fun stopClientCleanup() {
        clientCleanupScheduler?.shutdownNow()
        clientCleanupScheduler = null
    }

    /** Remove clients that haven't sent a heartbeat within the timeout period. */
    private fun cleanupStaleClients() {
        val now = System.currentTimeMillis()
        val stale = activeClients.entries
            .filter { now - it.value > CLIENT_TIMEOUT_MS }
            .map { it.key }

        for (clientId in stale) {
            logger.debug("Removing stale client: $clientId")
            clientDisconnected(clientId)
        }
    }

    /** Get the number of active clients. */
    fun getActiveClientCount(): Int = activeClients.size

    /** Check if any clients are connected. */
    fun hasActiveClients(): Boolean = activeClients.isNotEmpty()

    // ==================== METRICS COLLECTION ====================

    private fun collectMetrics() {
        try {
            val snapshot = PerformanceSnapshot()
            snapshot.timestamp = System.currentTimeMillis()

            // CPU metrics
            collectCpuMetrics(snapshot)

            // Memory metrics
            collectMemoryMetrics(snapshot)

            // GPU metrics (estimated from thermal/frequency)
            collectGpuMetrics(snapshot)

            // App-specific metrics
            collectAppMetrics(snapshot)

            // Store in history
            synchronized(history) {
                history.addLast(snapshot)
                while (history.size > HISTORY_SIZE) {
                    history.removeFirst()
                }
            }
            latestSnapshot.set(snapshot)

            if (csvEnabled) {
                appendSnapshotToCsv(snapshot)
            }
        } catch (e: Exception) {
            logger.error("Failed to collect metrics", e)
        }
    }

    private fun collectCpuMetrics(snapshot: PerformanceSnapshot) {
        try {
            // Read /proc/stat for system CPU
            val line = RandomAccessFile("/proc/stat", "r").use { it.readLine() }

            if (line != null && line.startsWith("cpu ")) {
                val parts = line.split(Regex("\\s+"))
                val user = parts[1].toLong()
                val nice = parts[2].toLong()
                val system = parts[3].toLong()
                val idle = parts[4].toLong()
                val iowait = parts[5].toLong()
                val irq = parts[6].toLong()
                val softirq = parts[7].toLong()

                val totalCpu = user + nice + system + idle + iowait + irq + softirq
                val totalIdle = idle + iowait

                if (lastCpuTime > 0) {
                    val cpuDelta = totalCpu - lastCpuTime
                    val idleDelta = totalIdle - lastIdleTime

                    if (cpuDelta > 0) {
                        snapshot.cpuUsagePercent = 100.0 * (cpuDelta - idleDelta) / cpuDelta
                    }
                }

                lastCpuTime = totalCpu
                lastIdleTime = totalIdle
            }

            // Read /proc/[pid]/stat for app CPU
            val appLine = RandomAccessFile("/proc/$pid/stat", "r").use { it.readLine() }

            if (appLine != null) {
                val parts = appLine.split(Regex("\\s+"))
                if (parts.size > 14) {
                    val appCpuTime = parts[13].toLong() + parts[14].toLong()

                    if (lastAppCpuTime > 0 && lastCpuTime > 0) {
                        val appDelta = appCpuTime - lastAppCpuTime
                        val cpuDelta = lastCpuTime - lastCpuTimeForApp

                        if (cpuDelta > 0) {
                            // Calculate app CPU as percentage of total CPU time
                            // This ensures app CPU <= system CPU (logically correct)
                            // Multiply by number of cores since /proc/stat is aggregate
                            val numCores = Runtime.getRuntime().availableProcessors()
                            snapshot.appCpuUsagePercent = 100.0 * appDelta / cpuDelta * numCores
                            // Clamp: app CPU should never exceed system CPU usage
                            snapshot.appCpuUsagePercent = minOf(
                                snapshot.cpuUsagePercent,
                                maxOf(0.0, snapshot.appCpuUsagePercent)
                            )
                        }
                    }
                    lastAppCpuTime = appCpuTime
                    lastCpuTimeForApp = lastCpuTime
                }
            }

            // CPU frequency
            snapshot.cpuFreqMhz = readCpuFrequency()

            // CPU temperature
            snapshot.cpuTempCelsius = readCpuTemperature()
        } catch (e: Exception) {
            logger.debug("CPU metrics error: " + e.message)
        }
    }

    private fun collectMemoryMetrics(snapshot: PerformanceSnapshot) {
        try {
            // System memory from /proc/meminfo
            var memTotal = 0L
            var memAvailable = 0L

            File("/proc/meminfo").bufferedReader().use { reader ->
                var line = reader.readLine()
                while (line != null) {
                    val parts = line.split(Regex("\\s+"))
                    if (parts.size >= 2) {
                        val value = parts[1].toLong() // in KB
                        when (parts[0]) {
                            "MemTotal:" -> memTotal = value
                            "MemAvailable:" -> memAvailable = value
                        }
                    }
                    line = reader.readLine()
                }
            }

            snapshot.memTotalMb = memTotal / 1024.0
            snapshot.memUsedMb = (memTotal - memAvailable) / 1024.0
            snapshot.memUsagePercent = 100.0 * (memTotal - memAvailable) / memTotal

            // App memory via Debug API
            val memInfo = Debug.MemoryInfo()
            Debug.getMemoryInfo(memInfo)

            snapshot.appMemoryMb = memInfo.totalPss / 1024.0 // PSS in KB -> MB
            snapshot.appNativeHeapMb = Debug.getNativeHeapAllocatedSize() / (1024.0 * 1024.0)
            snapshot.appJavaHeapMb =
                (Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()) /
                    (1024.0 * 1024.0)
        } catch (e: Exception) {
            logger.debug("Memory metrics error: " + e.message)
        }
    }

    private fun collectGpuMetrics(snapshot: PerformanceSnapshot) {
        try {
            // SOTA: Auto-detect GPU via /sys/class/devfreq/
            // Modern kernels expose GPU as a generic 'devfreq' device - works on MediaTek,
            // Snapdragon, Exynos
            val devfreqDir = File("/sys/class/devfreq/")
            if (devfreqDir.exists() && devfreqDir.isDirectory) {
                val devices = devfreqDir.listFiles()
                if (devices != null) {
                    for (device in devices) {
                        val name = device.name.lowercase()
                        // Filter for known GPU device names
                        if (name.contains("kgsl") || // Adreno (Qualcomm)
                            name.contains("mali") || // Mali (ARM)
                            name.contains("gpu") || // Generic
                            name.contains("g3d") // PowerVR/Other
                        ) {
                            // 1. Get Frequency
                            val freq = readLongFromFile(File(device, "cur_freq"))
                            if (freq > 0) {
                                snapshot.gpuFreqMhz = normalizeFrequency(freq)
                            }

                            // 2. Get Load/Busy - different drivers expose load differently
                            // Try standard 'load' (0-100)
                            val load = readLongFromFile(File(device, "load"))
                            if (load in 0..100) {
                                snapshot.gpuUsagePercent = load.toDouble()
                                break
                            }

                            // Try 'gpu_busy_percentage' (Qualcomm specific)
                            val busyPercent = readLongFromFile(File(device, "gpu_busy_percentage"))
                            if (busyPercent in 0..100) {
                                snapshot.gpuUsagePercent = busyPercent.toDouble()
                                break
                            }

                            // If we found freq but no load, continue to try other methods
                            if (snapshot.gpuFreqMhz > 0) break
                        }
                    }
                }
            }

            // Fallback: Try legacy kgsl paths directly (Qualcomm Adreno)
            if (snapshot.gpuFreqMhz == 0.0) {
                val freq = readLongFromFile(File("/sys/class/kgsl/kgsl-3d0/gpuclk"))
                if (freq > 0) {
                    snapshot.gpuFreqMhz = normalizeFrequency(freq)
                }
            }

            // Try kgsl gpu_busy (returns "busy_time total_time" format)
            if (snapshot.gpuUsagePercent == 0.0) {
                val gpuBusyFile = File("/sys/class/kgsl/kgsl-3d0/gpu_busy")
                if (gpuBusyFile.exists() && gpuBusyFile.canRead()) {
                    try {
                        val line = gpuBusyFile.bufferedReader().use { it.readLine() }
                        if (line != null) {
                            val parts = line.trim().split(Regex("\\s+"))
                            if (parts.size >= 2) {
                                val busy = parts[0].toLong()
                                val total = parts[1].toLong()
                                if (total > 0) {
                                    snapshot.gpuUsagePercent = (busy * 100.0) / total
                                }
                            }
                        }
                    } catch (e: Exception) {
                        logger.debug("GPU usage parsing error: " + e.message)
                    }
                }
            }

            // If still no usage, estimate from frequency ratio
            if (snapshot.gpuUsagePercent == 0.0 && snapshot.gpuFreqMhz > 0) {
                val maxFreq = readGpuMaxFrequency()
                if (maxFreq > 0) {
                    snapshot.gpuUsagePercent =
                        minOf(100.0, (snapshot.gpuFreqMhz / maxFreq) * 100)
                }
            }

            // GPU temperature
            snapshot.gpuTempCelsius = readGpuTemperature()
        } catch (e: Exception) {
            logger.debug("GPU metrics error: " + e.message)
        }
    }

    /** Normalize frequency to MHz - handles Hz, KHz, MHz inputs */
    private fun normalizeFrequency(value: Long): Double = when {
        value > 1_000_000 -> value / 1_000_000.0 // Hz -> MHz
        value > 1_000 -> value / 1_000.0 // KHz -> MHz
        else -> value.toDouble() // Already MHz
    }

    /** Robust single-line file reader - strips non-numeric chars for parsing */
    private fun readLongFromFile(file: File): Long {
        if (!file.exists() || !file.canRead()) return -1
        return try {
            val line = file.bufferedReader().use { it.readLine() } ?: return -1
            // Scrub non-numeric characters (handles "45 %" or "45@1000")
            val numOnly = line.replace(Regex("[^0-9]"), "").trim()
            if (numOnly.isEmpty()) -1 else numOnly.toLong()
        } catch (e: Exception) {
            -1
        }
    }

    private fun collectAppMetrics(snapshot: PerformanceSnapshot) {
        try {
            // Thread count
            snapshot.threadCount = Thread.activeCount()

            // GC stats
            snapshot.gcCount = 0 // Would need to track via GC callbacks

            // File descriptors
            try {
                snapshot.openFileDescriptors = File("/proc/$pid/fd").list()?.size ?: 0
            } catch (e: Exception) {
                logger.debug("fdDir count failed: " + e.message)
            }
        } catch (e: Exception) {
            logger.debug("App metrics error: " + e.message)
        }
    }

    // ==================== HELPER METHODS ====================

    /** First line of [path], or null when it cannot be read. */
    private fun readLine(path: String): String? = try {
        File(path).bufferedReader().use { it.readLine() }
    } catch (e: Exception) {
        null
    }

    private fun readCpuFrequency(): Int {
        val paths = arrayOf(
            "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq",
            "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq"
        )

        for (path in paths) {
            try {
                val line = readLine(path)
                if (line != null) {
                    return line.trim().toInt() / 1000 // KHz to MHz
                }
            } catch (e: Exception) {
                logger.debug("CPU freq read failed: " + e.message)
            }
        }
        return 0
    }

    /**
     * Scan thermal_zone0..29 for a zone whose `type` contains one of [keywords] and return its
     * temperature in °C, normalising millidegrees. [accept] filters implausible readings.
     * The CPU and GPU probes differ only in the keyword list and that filter.
     */
    private fun thermalZoneTemp(keywords: Array<String>, accept: (Double) -> Boolean): Double {
        for (i in 0 until 30) {
            try {
                val type = readLine("/sys/class/thermal/thermal_zone$i/type")
                if (type != null) {
                    val typeLower = type.lowercase().trim()
                    for (keyword in keywords) {
                        if (typeLower.contains(keyword)) {
                            val tempLine = readLine("/sys/class/thermal/thermal_zone$i/temp")
                            if (!tempLine.isNullOrBlank()) {
                                val temp = tempLine.trim().toDouble()
                                val result = if (temp > 1000) temp / 1000.0 else temp
                                if (accept(result)) {
                                    return result
                                }
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                logger.debug("thermal zone $i read failed: " + e.message)
            }
        }
        return 0.0
    }

    /** First readable temperature among [paths], normalising millidegrees. */
    private fun firstTempFrom(paths: Array<String>): Double {
        for (path in paths) {
            try {
                val line = readLine(path)
                if (!line.isNullOrBlank()) {
                    val temp = line.trim().toDouble()
                    // Usually in millidegrees
                    return if (temp > 1000) temp / 1000.0 else temp
                }
            } catch (e: Exception) {
                logger.debug("temp read failed for $path: " + e.message)
            }
        }
        return 0.0
    }

    private fun readCpuTemperature(): Double {
        // Try CPU-specific thermal zones first. Only a reasonable temperature counts (10-120°C).
        val zoneTemp = thermalZoneTemp(CPU_THERMAL_KEYWORDS) { it in 10.0..120.0 }
        if (zoneTemp != 0.0) return zoneTemp

        // Fallback to direct paths
        return firstTempFrom(
            arrayOf(
                "/sys/class/thermal/thermal_zone0/temp",
                "/sys/devices/virtual/thermal/thermal_zone0/temp",
                "/sys/devices/system/cpu/cpu0/cpufreq/cpu_temp",
                "/sys/kernel/cpu/temp"
            )
        )
    }

    /** Read GPU max frequency for load estimation. */
    private fun readGpuMaxFrequency(): Double {
        val paths = arrayOf(
            "/sys/class/kgsl/kgsl-3d0/max_gpuclk",
            "/sys/class/kgsl/kgsl-3d0/devfreq/max_freq",
            "/sys/class/devfreq/kgsl-3d0/max_freq",
            "/sys/devices/platform/mali.0/max_clock",
            "/sys/class/misc/mali0/device/max_clock",
            // Additional Qualcomm paths
            "/sys/class/kgsl/kgsl-3d0/gpu_available_frequencies",
            "/sys/class/kgsl/kgsl-3d0/devfreq/available_frequencies"
        )

        for (path in paths) {
            try {
                val line = readLine(path)
                if (!line.isNullOrBlank()) {
                    // Handle available_frequencies format (space-separated list)
                    if (path.contains("available_frequencies")) {
                        var maxFreq = 0L
                        for (f in line.trim().split(Regex("\\s+"))) {
                            try {
                                val freq = f.trim().toLong()
                                if (freq > maxFreq) maxFreq = freq
                            } catch (e: Exception) {
                                logger.debug("GPU max freq token parse failed: " + e.message)
                            }
                        }
                        if (maxFreq > 0) {
                            return normalizeFrequency(maxFreq)
                        }
                    }

                    // Convert to MHz based on magnitude
                    return normalizeFrequency(line.trim().toLong())
                }
            } catch (e: Exception) {
                logger.debug("GPU max freq file read failed: " + e.message)
            }
        }

        // Fallback: estimate max based on typical Adreno GPU max frequencies
        // If we're reading from kgsl (Qualcomm), assume typical max of 600-700 MHz
        return 650.0 // Conservative estimate for Adreno GPUs
    }

    /**
     * Diagnostic method to discover available thermal zones and GPU paths.
     * Call this to identify what's available on the device.
     */
    fun discoverSystemPaths(): JSONObject {
        val discovery = JSONObject()

        try {
            // Discover thermal zones
            val thermalZones = JSONArray()
            for (i in 0 until 40) {
                try {
                    val type = readLine("/sys/class/thermal/thermal_zone$i/type")
                    val tempLine = readLine("/sys/class/thermal/thermal_zone$i/temp")

                    if (type != null && tempLine != null) {
                        val zone = JSONObject()
                        zone.put("zone", i)
                        zone.put("type", type.trim())
                        val temp = tempLine.trim().toDouble()
                        zone.put("temp", if (temp > 1000) temp / 1000.0 else temp)
                        thermalZones.put(zone)
                    }
                } catch (e: Exception) {
                    logger.debug("thermal zone $i read failed: " + e.message)
                }
            }
            discovery.put("thermalZones", thermalZones)

            // Check GPU paths
            val gpuPaths = JSONArray()
            val allGpuPaths = arrayOf(
                "/sys/class/kgsl/kgsl-3d0/gpuclk",
                "/sys/class/kgsl/kgsl-3d0/devfreq/cur_freq",
                "/sys/devices/platform/mali.0/clock",
                "/sys/class/misc/mali0/device/clock",
                "/sys/class/devfreq/mali/cur_freq",
                "/sys/kernel/gpu/gpu_clock",
                "/sys/class/devfreq/gpu/cur_freq"
            )

            for (path in allGpuPaths) {
                try {
                    val line = readLine(path)
                    if (line != null) {
                        val pathInfo = JSONObject()
                        pathInfo.put("path", path)
                        pathInfo.put("value", line.trim())
                        gpuPaths.put(pathInfo)
                    }
                } catch (e: Exception) {
                    logger.debug("GPU path probe failed for $path: " + e.message)
                }
            }
            discovery.put("gpuPaths", gpuPaths)

            // Check devfreq devices
            val devfreqDevices = JSONArray()
            val devfreqDir = File("/sys/class/devfreq")
            if (devfreqDir.exists() && devfreqDir.isDirectory) {
                devfreqDir.list()?.forEach { device ->
                    try {
                        val freq = readLine("/sys/class/devfreq/$device/cur_freq")

                        val devInfo = JSONObject()
                        devInfo.put("device", device)
                        devInfo.put("cur_freq", freq?.trim() ?: "N/A")
                        devfreqDevices.put(devInfo)
                    } catch (e: Exception) {
                        logger.debug("devfreq $device read failed: " + e.message)
                    }
                }
            }
            discovery.put("devfreqDevices", devfreqDevices)

            logger.info("System discovery: $discovery")
        } catch (e: Exception) {
            logger.error("Discovery failed", e)
        }

        return discovery
    }

    private fun readGpuTemperature(): Double {
        // Try various thermal zones for GPU - expanded for different chipsets.
        // Any reading is accepted here (unlike CPU, which filters to 10-120°C).
        val zoneTemp = thermalZoneTemp(GPU_THERMAL_KEYWORDS) { true }
        if (zoneTemp != 0.0) return zoneTemp

        // Fallback: try direct GPU thermal paths
        return firstTempFrom(
            arrayOf(
                "/sys/class/kgsl/kgsl-3d0/temp",
                "/sys/devices/platform/mali.0/temp",
                "/sys/kernel/gpu/gpu_temp",
                "/sys/devices/virtual/thermal/gpu/temp"
            )
        )
    }

    // ==================== DATA ACCESS ====================

    fun getLatestSnapshot(): PerformanceSnapshot? = latestSnapshot.get()

    fun getLatestAsJson(): JSONObject = latestSnapshot.get()?.toJson() ?: JSONObject()

    fun getHistoryAsJson(): JSONArray {
        val array = JSONArray()
        synchronized(history) {
            for (snapshot in history) {
                array.put(snapshot.toJson())
            }
        }
        return array
    }

    fun getFullReport(): JSONObject {
        return try {
            val report = JSONObject()
            report.put("current", getLatestAsJson())
            report.put("history", getHistoryAsJson())
            report.put("historySize", HISTORY_SIZE)
            report.put("sampleIntervalMs", SAMPLE_INTERVAL_MS)
            report.put("pid", pid)
            report.put("uid", uid)
            report
        } catch (e: Exception) {
            logger.error("Failed to create full report", e)
            JSONObject()
        }
    }

    // ==================== CSV PERSISTENCE SINK ====================

    private fun initCsvFile() {
        synchronized(csvLock) {
            try {
                val file = File(PERF_CSV_PATH)
                file.parentFile?.let { if (!it.exists()) it.mkdirs() }
                // Write header only if file does not already exist or is empty.
                if (!file.exists() || file.length() == 0L) {
                    FileOutputStream(file, true).use { fos ->
                        OutputStreamWriter(fos, "UTF-8").use { w ->
                            w.write(CSV_HEADER)
                            w.write("\n")
                            w.flush()
                        }
                    }
                }
                logger.info("Performance CSV sink opened: $PERF_CSV_PATH")
            } catch (e: Exception) {
                logger.warn("Failed to init performance CSV: " + e.message)
                csvEnabled = false
            }
        }
    }

    private fun appendSnapshotToCsv(s: PerformanceSnapshot) {
        synchronized(csvLock) {
            try {
                val file = File(PERF_CSV_PATH)
                file.parentFile?.let { if (!it.exists()) it.mkdirs() }
                if (file.exists() && file.length() >= PERF_CSV_MAX_BYTES) {
                    rotateCsvFile(file)
                }
                // If header is missing after rotation, write it first.
                val needsHeader = !file.exists() || file.length() == 0L
                FileOutputStream(file, true).use { fos ->
                    OutputStreamWriter(fos, "UTF-8").use { w ->
                        if (needsHeader) {
                            w.write(CSV_HEADER)
                            w.write("\n")
                        }
                        w.write(
                            String.format(
                                Locale.US,
                                "%d,%.1f,%.1f,%d,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f," +
                                    "%.1f,%.1f,%.1f,%d,%d,%d\n",
                                s.timestamp,
                                s.cpuUsagePercent, s.appCpuUsagePercent,
                                s.cpuFreqMhz, s.cpuTempCelsius,
                                s.memTotalMb, s.memUsedMb, s.memUsagePercent,
                                s.appMemoryMb, s.appNativeHeapMb, s.appJavaHeapMb,
                                s.gpuUsagePercent, s.gpuFreqMhz, s.gpuTempCelsius,
                                s.threadCount, s.gcCount, s.openFileDescriptors
                            )
                        )
                        w.flush()
                    }
                }
            } catch (e: Exception) {
                // Never crash the monitor thread for a persistence failure.
                logger.warn("Failed to append perf snapshot to CSV: " + e.message)
            }
        }
    }

    private fun rotateCsvFile(file: File) {
        try {
            // Mirrors DebugAppLogger rotation: delete oldest, shift others up.
            for (i in PERF_CSV_MAX_ROTATIONS downTo 1) {
                val f = File("$PERF_CSV_PATH.$i")
                if (i == PERF_CSV_MAX_ROTATIONS) {
                    f.delete()
                } else if (f.exists()) {
                    f.renameTo(File("$PERF_CSV_PATH.${i + 1}"))
                }
            }
            file.renameTo(File("$PERF_CSV_PATH.1"))
        } catch (e: Exception) {
            logger.warn("Failed to rotate performance CSV: " + e.message)
        }
    }

    // ==================== SNAPSHOT DATA CLASS ====================

    class PerformanceSnapshot {
        @JvmField var timestamp = 0L

        // CPU
        @JvmField var cpuUsagePercent = 0.0
        @JvmField var appCpuUsagePercent = 0.0
        @JvmField var cpuFreqMhz = 0
        @JvmField var cpuTempCelsius = 0.0

        // Memory
        @JvmField var memTotalMb = 0.0
        @JvmField var memUsedMb = 0.0
        @JvmField var memUsagePercent = 0.0
        @JvmField var appMemoryMb = 0.0
        @JvmField var appNativeHeapMb = 0.0
        @JvmField var appJavaHeapMb = 0.0

        // GPU
        @JvmField var gpuUsagePercent = 0.0
        @JvmField var gpuFreqMhz = 0.0
        @JvmField var gpuTempCelsius = 0.0

        // App
        @JvmField var threadCount = 0
        @JvmField var gcCount = 0
        @JvmField var openFileDescriptors = 0

        fun toJson(): JSONObject {
            return try {
                val json = JSONObject()
                json.put("timestamp", timestamp)

                // CPU
                val cpu = JSONObject()
                cpu.put("system", round(cpuUsagePercent))
                cpu.put("app", round(appCpuUsagePercent))
                cpu.put("freqMhz", cpuFreqMhz)
                cpu.put("tempC", round(cpuTempCelsius))
                json.put("cpu", cpu)

                // Memory
                val mem = JSONObject()
                mem.put("totalMb", round(memTotalMb))
                mem.put("usedMb", round(memUsedMb))
                mem.put("usagePercent", round(memUsagePercent))
                mem.put("appTotalMb", round(appMemoryMb))
                mem.put("appNativeMb", round(appNativeHeapMb))
                mem.put("appJavaMb", round(appJavaHeapMb))
                json.put("memory", mem)

                // GPU
                val gpu = JSONObject()
                gpu.put("usage", round(gpuUsagePercent))
                gpu.put("freqMhz", round(gpuFreqMhz))
                gpu.put("tempC", round(gpuTempCelsius))
                json.put("gpu", gpu)

                // App
                val app = JSONObject()
                app.put("threads", threadCount)
                app.put("gcCount", gcCount)
                app.put("openFds", openFileDescriptors)
                json.put("app", app)

                json
            } catch (e: Exception) {
                JSONObject()
            }
        }

        private fun round(value: Double): Double = (value * 10.0).roundToLong() / 10.0
    }

    companion object {
        private const val TAG = "PerformanceMonitor"
        private val logger = DaemonLogger.getInstance(TAG)

        // Singleton
        private var instance: PerformanceMonitor? = null
        private val lock = Any()

        @JvmStatic
        fun getInstance(): PerformanceMonitor =
            instance ?: synchronized(lock) {
                instance ?: PerformanceMonitor().also { instance = it }
            }

        // Configuration
        /** 60 samples = 1 minute at 1s interval */
        private const val HISTORY_SIZE = 60

        /** 1 second */
        private const val SAMPLE_INTERVAL_MS = 1000L

        /** 10 seconds heartbeat timeout */
        private const val CLIENT_TIMEOUT_MS = 10_000L

        /** Check for stale clients every 5s */
        private const val CLEANUP_INTERVAL_MS = 5_000L

        // Persistence sink — CSV file written when isTimingLogsEnabled() is on.
        // Rotation mirrors DebugAppLogger: ~5 MB per file, 3 backups (.1/.2/.3).
        private const val PERF_CSV_PATH =
            "/storage/emulated/0/BladeWatch/data/performance.csv"
        private const val PERF_CSV_MAX_BYTES = 5L * 1024 * 1024
        private const val PERF_CSV_MAX_ROTATIONS = 3
        private const val CSV_HEADER =
            "timestamp_ms,cpu_pct,app_cpu_pct,cpu_freq_mhz,cpu_temp_c," +
                "mem_total_mb,mem_used_mb,mem_pct,app_mem_mb,app_native_mb,app_java_mb," +
                "gpu_pct,gpu_freq_mhz,gpu_temp_c,threads,gc_count,open_fds"

        private val CPU_THERMAL_KEYWORDS = arrayOf(
            "cpu", "soc", "core", "cluster", "little", "big", "prime",
            "cpu-thermal", "cpu_thermal", "cpuss", "cpuss-0", "cpuss-1",
            "cpu-0-0", "cpu-0-1", "cpu-1-0", "cpu-1-1", "tsens_tz_sensor"
        )

        private val GPU_THERMAL_KEYWORDS = arrayOf(
            "gpu", "adreno", "mali", "g3d", "graphics", "pvr", "vivante",
            "gpu-thermal", "gpu_thermal", "gpu-usr", "gpuss", "gpuss-0",
            "gpuss-1", "gpuss-max", "gpu-step"
        )
    }
}
