package net.bladewatch.app.server

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.storage.ExternalStorageCleaner
import net.bladewatch.app.storage.StorageManager
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.roundToLong

/**
 * Manages SD card and CDR cleanup settings.
 *
 * Auto-cleanup of BYD dashcam (CDR) files, to ensure BladeWatch has space on the SD card. When
 * BladeWatch uses the SD card for recordings/surveillance, this automatically manages the BYD
 * dashcam files to maintain the reserved space.
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/storage/external paths and writing JSON
 * into an OutputStream that the Connect layer captured straight back out. Each operation now
 * RETURNS its JSON and takes its arguments directly — bytesToFree is a parameter rather than
 * something parsed out of a query string.
 */
object ExternalStorageApiHandler {

    private val logger: DaemonLogger = DaemonLogger.getInstance("ExternalStorageApiHandler")

    /** SD card status, CDR info, and cleanup configuration. */
    @JvmStatic
    @Throws(Exception::class)
    fun getExternalStorageStatus(): JSONObject {
        val cleaner = ExternalStorageCleaner.getInstance()
        val storage = StorageManager.getInstance()

        // Refresh SD card detection if it is not currently available: this handles the case where
        // the card was inserted after app start.
        if (!cleaner.isSdCardAvailable) {
            cleaner.refresh()
            storage.refreshSdCard()
        }

        val response = JSONObject()
        response.put("success", true)

        // SD Card info
        response.put("sdCardAvailable", cleaner.isSdCardAvailable)
        response.put("sdCardPath", cleaner.sdCardPath)

        if (cleaner.isSdCardAvailable) {
            val sdFree = cleaner.sdCardFreeSpace
            val sdTotal = cleaner.sdCardTotalSpace
            response.put("sdCardFree", sdFree)
            response.put("sdCardTotal", sdTotal)
            response.put("sdCardFreeFormatted", ExternalStorageCleaner.formatSize(sdFree))
            response.put("sdCardTotalFormatted", ExternalStorageCleaner.formatSize(sdTotal))
            response.put(
                "sdCardUsedPercent",
                if (sdTotal > 0) ((sdTotal - sdFree) * 100.0 / sdTotal).roundToLong() else 0L
            )
        }

        // CDR info
        response.put("cdrPath", cleaner.cdrPath)

        if (cleaner.cdrPath != null) {
            val cdrUsage = cleaner.cdrUsage
            val protectedSize = cleaner.protectedSize
            val deletableSize = cleaner.deletableSize

            response.put("cdrUsage", cdrUsage)
            response.put("cdrUsageFormatted", ExternalStorageCleaner.formatSize(cdrUsage))
            response.put("cdrFileCount", cleaner.cdrFileCount)
            response.put("cdrProtectedSize", protectedSize)
            response.put(
                "cdrProtectedFormatted", ExternalStorageCleaner.formatSize(protectedSize)
            )
            response.put("cdrDeletableSize", deletableSize)
            response.put(
                "cdrDeletableFormatted", ExternalStorageCleaner.formatSize(deletableSize)
            )
        }

        // Cleanup configuration
        response.put("cleanupEnabled", cleaner.isEnabled)
        response.put("reservedSpaceMb", cleaner.reservedSpaceMb)
        response.put("protectedHours", cleaner.protectedHours)
        response.put("minFilesKeep", cleaner.minFilesKeep)
        response.put("monitoringActive", cleaner.isMonitoringActive)

        // Statistics
        response.put("totalBytesFreed", cleaner.totalBytesFreed)
        response.put(
            "totalBytesFreedFormatted", ExternalStorageCleaner.formatSize(cleaner.totalBytesFreed)
        )
        response.put("totalFilesDeleted", cleaner.totalFilesDeleted)
        response.put("lastCleanupTime", cleaner.lastCleanupTime)

        // Show whether BladeWatch is using the SD card (auto-enable recommendation)
        val bladewatchUsesSdCard =
            storage.recordingsStorageType == StorageManager.StorageType.SD_CARD ||
                storage.surveillanceStorageType == StorageManager.StorageType.SD_CARD
        response.put("bladewatchUsesSdCard", bladewatchUsesSdCard)
        response.put("recommendAutoCleanup", bladewatchUsesSdCard && !cleaner.isEnabled)

        return response
    }

    /**
     * Update the cleanup configuration.
     *
     * Body: `{ enabled, reservedSpaceMb, protectedHours, minFilesKeep }`
     */
    @JvmStatic
    @Throws(Exception::class)
    fun updateConfig(requestBody: String?): JSONObject {
        val cleaner = ExternalStorageCleaner.getInstance()

        try {
            val config = JSONObject(requestBody)

            if (config.has("enabled")) {
                cleaner.isEnabled = config.getBoolean("enabled")
            }
            if (config.has("reservedSpaceMb")) {
                cleaner.reservedSpaceMb = config.getLong("reservedSpaceMb")
            }
            if (config.has("protectedHours")) {
                cleaner.protectedHours = config.getInt("protectedHours")
            }
            if (config.has("minFilesKeep")) {
                cleaner.minFilesKeep = config.getInt("minFilesKeep")
            }

            val response = JSONObject()
            response.put("success", true)
            response.put("message", Messages.get("messages.external_storage_config_updated"))
            response.put("cleanupEnabled", cleaner.isEnabled)
            response.put("reservedSpaceMb", cleaner.reservedSpaceMb)
            response.put("protectedHours", cleaner.protectedHours)
            response.put("minFilesKeep", cleaner.minFilesKeep)

            return response
        } catch (e: Exception) {
            throw ConnectException(
                "invalid_argument",
                Messages.get("errors.external_storage_invalid_config_with_detail", e.message)
            )
        }
    }

    /**
     * Trigger a manual cleanup.
     *
     * Body (optional): `{ bytesToFree }` — if not specified, uses the reserved-space calculation.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun triggerCleanup(requestBody: String?): JSONObject {
        val cleaner = ExternalStorageCleaner.getInstance()

        // Refuse to force-delete OEM dashcam files when the feature is disabled. Previously this
        // endpoint silently bypassed the user's opt-out; an empty POST or any caller could nuke
        // 500MB+ of OEM recordings even when the user had cleanup off.
        if (!cleaner.isEnabled) {
            // Was HTTP 403. failed_precondition is the honest code: the caller is allowed to do
            // this, the feature is simply switched off.
            throw ConnectException(
                "failed_precondition",
                Messages.get("errors.external_storage_cleanup_disabled")
            )
        }

        val result: ExternalStorageCleaner.CleanupResult = if (!requestBody.isNullOrEmpty()) {
            try {
                val bytesToFree = JSONObject(requestBody).optLong("bytesToFree", 0)
                if (bytesToFree > 0) {
                    cleaner.forceCleanup(bytesToFree)
                } else {
                    cleaner.ensureReservedSpace()
                }
            } catch (e: Exception) {
                logger.warn(
                    "Failed to parse cleanup request body, using reserved-space defaults: " +
                        e.message
                )
                cleaner.ensureReservedSpace()
            }
        } else {
            // Empty body → run reserved-space-driven cleanup, not a hardcoded 500MB force-delete.
            // The previous default was a footgun: an accidental empty POST silently deleted 500MB
            // of OEM files even when the SD card had plenty of free space.
            cleaner.ensureReservedSpace()
        }

        val response = JSONObject()
        response.put("success", result.isSuccess)

        if (result.isSuccess) {
            response.put("bytesFreed", result.bytesFreed)
            response.put("freedFormatted", ExternalStorageCleaner.formatSize(result.bytesFreed))
            response.put("filesDeleted", result.filesDeleted)

            val deletedArray = JSONArray()
            for (fileName in result.deletedFiles) {
                deletedArray.put(fileName)
            }
            response.put("deletedFiles", deletedArray)

            // Include updated stats
            response.put("sdCardFree", cleaner.sdCardFreeSpace)
            response.put(
                "sdCardFreeFormatted", ExternalStorageCleaner.formatSize(cleaner.sdCardFreeSpace)
            )
        } else {
            response.put("error", result.error)
        }

        return response
    }

    /**
     * Preview what a cleanup would delete.
     *
     * @param bytesToFreeOrZero 0 means "unspecified" and keeps the previous default of 500MB.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun previewCleanup(bytesToFreeOrZero: Long): JSONObject {
        val cleaner = ExternalStorageCleaner.getInstance()

        val bytesToFree =
            if (bytesToFreeOrZero > 0) bytesToFreeOrZero else 500L * 1024 * 1024

        val preview = cleaner.previewCleanup(bytesToFree)

        val response = JSONObject()
        response.put("success", true)
        response.put("targetBytes", bytesToFree)
        response.put("targetFormatted", ExternalStorageCleaner.formatSize(bytesToFree))

        val filesArray = JSONArray()
        var totalSize = 0L

        for (file in preview) {
            val fileObj = JSONObject()
            fileObj.put("name", file.name)
            fileObj.put("size", file.size)
            fileObj.put("sizeFormatted", ExternalStorageCleaner.formatSize(file.size))
            fileObj.put("lastModified", file.lastModified)
            fileObj.put("path", file.path)
            filesArray.put(fileObj)
            totalSize += file.size
        }

        response.put("files", filesArray)
        response.put("fileCount", preview.size)
        response.put("totalSize", totalSize)
        response.put("totalSizeFormatted", ExternalStorageCleaner.formatSize(totalSize))

        return response
    }

    /** Refresh SD card and CDR path detection. */
    @JvmStatic
    @Throws(Exception::class)
    fun refreshPaths(): JSONObject {
        val cleaner = ExternalStorageCleaner.getInstance()
        cleaner.refresh()

        val response = JSONObject()
        response.put("success", true)
        response.put("sdCardAvailable", cleaner.isSdCardAvailable)
        response.put("sdCardPath", cleaner.sdCardPath)
        response.put("cdrPath", cleaner.cdrPath)

        return response
    }
}
