package net.bladewatch.app.logging

import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.io.PrintWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

/**
 * Unified logger for all daemon processes: thread-safe file logging, size-based rotation,
 * retention cleanup, per-daemon files, and dual console/file output. Works in both the app
 * context and the daemon context (`app_process`).
 *
 * ```
 * val logger = DaemonLogger.getInstance("CameraDaemon")
 * logger.info("Camera started")
 * logger.error("Failed to start", exception)
 * ```
 */
class DaemonLogger private constructor(
    /** The tag for this logger. */
    @get:JvmName("getTag")
    val tag: String,
    logDir: String,
) {

    /** The log file path for this logger. */
    @get:JvmName("getLogFilePath")
    val logFilePath: String = logDir + "/" + tag.lowercase() + ".log"

    private var writer: PrintWriter? = null
    private val writeLock = Any()
    private val timestampFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US)

    /** Current file size in bytes. */
    @get:JvmName("getCurrentFileSize")
    var currentFileSize: Long = 0
        private set

    @Volatile
    private var writerInitialized = false

    // ==================== INSTANCE LOGGING ====================

    /** Log a message at [level]. */
    fun log(level: Level, message: String?) {
        // redactMessage returns null only for a null input, which Log.* will not accept.
        // Java passed the null straight through to Log, which prints "null"; keep that.
        val redactedMessage = SecretRedactor.redactMessage(message) ?: "null"
        val timestamp = timestampFormat.format(Date())
        val logLine = "[$timestamp] [" + level.name + "] [$tag] " + redactedMessage

        if (globalConfig.enableConsoleLog) {
            try {
                when (level) {
                    Level.DEBUG -> Log.d(tag, redactedMessage)
                    Level.INFO -> Log.i(tag, redactedMessage)
                    Level.WARN -> Log.w(tag, redactedMessage)
                    Level.ERROR -> Log.e(tag, redactedMessage)
                }
            } catch (ignored: RuntimeException) {
                // Local JVM unit tests do not provide a real android.util.Log implementation.
                // Keep file/stdout logging working and move on. Do NOT call Log.* here — that
                // would throw again.
            }
        }

        // Stdout for daemons launched via app_process, with a timestamp so the shell wrapper's
        // file has one on every line rather than only on its own echo statements.
        //
        // ERRORS ONLY: the shell launcher appends this stream to an unbounded, never-rotated
        // file across every daemon restart. DEBUG/INFO/WARN volume there grew that file to
        // multiple gigabytes.
        if (globalConfig.enableStdoutLog && level == Level.ERROR) {
            println("$tag: [$timestamp] $redactedMessage")
        }

        if (globalConfig.enableFileLog && DaemonLogConfig.isFileLoggingEnabled(tag)) {
            writeToFile(logLine)
        }
    }

    fun debug(message: String?) = log(Level.DEBUG, message)

    fun info(message: String?) = log(Level.INFO, message)

    fun warn(message: String?) = log(Level.WARN, message)

    fun error(message: String?) = log(Level.ERROR, message)

    /** Log an error and append the stack trace to the file. */
    fun error(message: String?, throwable: Throwable?) {
        val fullMessage = if (throwable != null) "$message: " + throwable.message else message
        log(Level.ERROR, fullMessage)

        if (throwable != null && globalConfig.enableFileLog &&
            DaemonLogConfig.isFileLoggingEnabled(tag)
        ) {
            synchronized(writeLock) {
                writer?.let {
                    throwable.printStackTrace(it)
                    it.flush()
                }
            }
        }
    }

    // ==================== FILE OPERATIONS ====================

    private fun initWriter() {
        if (!globalConfig.enableFileLog) return
        if (!DaemonLogConfig.isFileLoggingEnabled(tag)) return
        if (writerInitialized) return

        try {
            val logFile = File(logFilePath)
            logFile.parentFile?.let { if (!it.exists()) it.mkdirs() }

            // Rotate before opening if the existing file is already over the limit.
            if (logFile.exists()) {
                currentFileSize = logFile.length()
                checkAndRotateIfNeeded()
            }

            writer = PrintWriter(
                OutputStreamWriter(FileOutputStream(logFile, true), "UTF-8"), true
            )
            writerInitialized = true
        } catch (e: Exception) {
            Log.w(META_TAG, "Failed to initialize log file writer: " + e.message)
            // Silently skip file logging when the directory is not writable — expected when the
            // app process touches /data/local/tmp. Falls back to logcat only.
        }
    }

    private fun writeToFile(logLine: String) {
        synchronized(writeLock) {
            if (writer == null) initWriter()
            writer?.let {
                try {
                    it.println(logLine)
                    it.flush()
                    currentFileSize += logLine.length + 1
                    checkAndRotateIfNeeded()
                } catch (e: Exception) {
                    Log.e(META_TAG, "Failed to write log: " + e.message)
                }
            }
        }
    }

    private fun checkAndRotateIfNeeded() {
        val maxSizeBytes = globalConfig.maxFileSizeMB * 1024L * 1024L
        if (currentFileSize >= maxSizeBytes) rotateLogFile()
    }

    /** Rotate by renaming to .1, .2, .3…; anything beyond `rotationCount` is deleted. */
    private fun rotateLogFile() {
        try {
            writer?.close()
            writer = null
            writerInitialized = false

            val logFile = File(logFilePath)
            val parentDir = logFile.parentFile
            val baseName = logFile.name

            for (i in globalConfig.rotationCount downTo 1) {
                val oldFile = File(parentDir, "$baseName.$i")
                if (i == globalConfig.rotationCount) {
                    if (oldFile.exists()) oldFile.delete()
                } else if (oldFile.exists()) {
                    oldFile.renameTo(File(parentDir, "$baseName." + (i + 1)))
                }
            }

            if (logFile.exists()) logFile.renameTo(File(parentDir, "$baseName.1"))

            currentFileSize = 0
            // The writer is re-created lazily on the next write.

            Log.i(META_TAG, "Rotated log file: $baseName")
        } catch (e: Exception) {
            Log.e(META_TAG, "Failed to rotate log file: " + e.message)
        }
    }

    // ==================== LIFECYCLE ====================

    /** Close this logger and release its writer. */
    fun close() {
        synchronized(writeLock) {
            writer?.close()
            writer = null
            writerInitialized = false
        }
        instances.remove(tag)
    }

    /** Log configuration. */
    class Config {
        @JvmField var logDir: String = "/data/local/tmp"
        @JvmField var retentionHours: Int = 24
        @JvmField var maxFileSizeMB: Int = 10
        @JvmField var rotationCount: Int = 3
        @JvmField var enableConsoleLog: Boolean = true
        @JvmField var enableFileLog: Boolean = true

        /** Only enable for daemon processes (app_process). */
        @JvmField var enableStdoutLog: Boolean = false

        fun withLogDir(dir: String): Config = apply { logDir = dir }
        fun withMaxFileSizeMB(size: Int): Config = apply { maxFileSizeMB = size }
        fun withRotationCount(count: Int): Config = apply { rotationCount = count }
        fun withConsoleLog(enable: Boolean): Config = apply { enableConsoleLog = enable }
        fun withFileLog(enable: Boolean): Config = apply { enableFileLog = enable }
        fun withStdoutLog(enable: Boolean): Config = apply { enableStdoutLog = enable }

        companion object {
            @JvmStatic
            fun defaults(): Config = Config()
        }
    }

    /** Log levels. */
    enum class Level { DEBUG, INFO, WARN, ERROR }

    /** Cleanup statistics. */
    class CleanupStats(
        @JvmField val lastCleanupTime: Long,
        @JvmField val filesDeleted: Int,
        @JvmField val spaceFreeKB: Long,
    ) {
        override fun toString(): String =
            "CleanupStats{deleted=$filesDeleted, freedKB=$spaceFreeKB}"
    }

    companion object {
        private const val META_TAG = "DaemonLogger"

        @Volatile
        private var globalConfig: Config = Config.defaults()

        private val instances = ConcurrentHashMap<String, DaemonLogger>()
        private val globalLock = Any()

        /** Get or create a logger for [tag], using the global log directory. */
        @JvmStatic
        fun getInstance(tag: String): DaemonLogger =
            instances.computeIfAbsent(tag) { DaemonLogger(it, globalConfig.logDir) }

        /**
         * Get a logger with a custom log directory.
         *
         * Keyed by "tag@dir", so the same tag in two directories is two instances — otherwise
         * the second caller would silently get the first one's file.
         */
        @JvmStatic
        fun getInstance(tag: String, logDir: String): DaemonLogger =
            instances.computeIfAbsent("$tag@$logDir") { DaemonLogger(tag, logDir) }

        /** Configure global settings. Call before getting instances. */
        @JvmStatic
        fun configure(config: Config) {
            synchronized(globalLock) { globalConfig = config }
        }

        @JvmStatic
        fun getConfig(): Config = globalConfig

        /** Convenience: log at INFO under [tag]. */
        @JvmStatic
        fun log(tag: String, message: String?) = getInstance(tag).info(message)

        /** Convenience: log at [level] under [tag]. */
        @JvmStatic
        fun log(tag: String, message: String?, level: Level) = getInstance(tag).log(level, message)

        /** Convenience: log an error with an exception under [tag]. */
        @JvmStatic
        fun logError(tag: String, message: String?, throwable: Throwable?) =
            getInstance(tag).error(message, throwable)

        /**
         * Delete log files older than the retention window. Call periodically — on daemon
         * startup or from a scheduler.
         */
        @JvmStatic
        fun cleanupOldLogs(): CleanupStats {
            var filesDeleted = 0
            var spaceFreeBytes = 0L
            try {
                val logDir = File(globalConfig.logDir)
                if (!logDir.exists() || !logDir.isDirectory) {
                    return CleanupStats(System.currentTimeMillis(), 0, 0)
                }
                val retentionMs = globalConfig.retentionHours * 60L * 60L * 1000L
                val cutoffTime = System.currentTimeMillis() - retentionMs

                logDir.listFiles { _, name -> name.endsWith(".log") || name.contains(".log.") }
                    ?.forEach { file ->
                        if (file.lastModified() < cutoffTime) {
                            val fileSize = file.length()
                            if (file.delete()) {
                                filesDeleted++
                                spaceFreeBytes += fileSize
                                Log.i(META_TAG, "Deleted old log: " + file.name)
                            }
                        }
                    }
            } catch (e: Exception) {
                Log.e(META_TAG, "Cleanup error: " + e.message)
            }
            return CleanupStats(System.currentTimeMillis(), filesDeleted, spaceFreeBytes / 1024)
        }

        /** Close every logger instance. */
        @JvmStatic
        fun closeAll() {
            synchronized(globalLock) {
                for (logger in instances.values) {
                    synchronized(logger.writeLock) {
                        logger.writer?.close()
                        logger.writer = null
                        logger.writerInitialized = false
                    }
                }
                instances.clear()
            }
            Log.i(META_TAG, "All loggers closed")
        }
    }
}
