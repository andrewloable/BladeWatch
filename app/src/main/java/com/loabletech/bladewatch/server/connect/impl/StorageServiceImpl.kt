package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.ExternalStorageApiHandler
import net.bladewatch.app.server.FormatStorageApiHandler
import net.bladewatch.app.server.QualitySettingsApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONObject

/**
 * Connect protocol handler for bladewatch.v1.StorageService.
 *
 * Routes:
 *   GetStorageSettings        → QualitySettingsApiHandler.getStorageSettings
 *   SetStorageSettings        → QualitySettingsApiHandler.setStorageSettings
 *   PreviewStorageLimitChange → QualitySettingsApiHandler.previewStorageLimitChange
 *   GetExternalStorage        → ExternalStorageApiHandler.getExternalStorageStatus
 *   SetExternalConfig         → ExternalStorageApiHandler.updateConfig
 *   TriggerCleanup            → ExternalStorageApiHandler.triggerCleanup
 *   PreviewCleanup            → ExternalStorageApiHandler.previewCleanup
 *   RefreshExternalStorage    → ExternalStorageApiHandler.refreshPaths
 *   ListFormatVolumes         → FormatStorageApiHandler.listVolumes
 *   FormatVolume              → FormatStorageApiHandler.formatVolume
 */
class StorageServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register(
            "bladewatch.v1.StorageService", "GetStorageSettings", this::handleGetStorageSettings
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "SetStorageSettings", this::handleSetStorageSettings
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "PreviewStorageLimitChange",
            this::handlePreviewStorageLimitChange
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "GetExternalStorage", this::handleGetExternalStorage
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "SetExternalConfig", this::handleSetExternalConfig
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "TriggerCleanup", this::handleTriggerCleanup
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "PreviewCleanup", this::handlePreviewCleanup
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "RefreshExternalStorage",
            this::handleRefreshExternalStorage
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "ListFormatVolumes", this::handleListFormatVolumes
        )
        dispatcher.register(
            "bladewatch.v1.StorageService", "FormatVolume", this::handleFormatVolume
        )
    }

    @Throws(ConnectException::class)
    private fun handleGetStorageSettings(req: String?, clientIdentity: String?): ConnectResponse =
        json { QualitySettingsApiHandler.getStorageSettings() }

    @Throws(ConnectException::class)
    private fun handleSetStorageSettings(req: String?, clientIdentity: String?): ConnectResponse =
        json { QualitySettingsApiHandler.setStorageSettings(req) }

    @Throws(ConnectException::class)
    private fun handlePreviewStorageLimitChange(
        req: String?,
        clientIdentity: String?
    ): ConnectResponse = json { QualitySettingsApiHandler.previewStorageLimitChange(req) }

    @Throws(ConnectException::class)
    private fun handleGetExternalStorage(req: String?, clientIdentity: String?): ConnectResponse =
        json { ExternalStorageApiHandler.getExternalStorageStatus() }

    @Throws(ConnectException::class)
    private fun handleSetExternalConfig(req: String?, clientIdentity: String?): ConnectResponse =
        json { ExternalStorageApiHandler.updateConfig(req) }

    @Throws(ConnectException::class)
    private fun handleTriggerCleanup(req: String?, clientIdentity: String?): ConnectResponse =
        json { ExternalStorageApiHandler.triggerCleanup(req) }

    @Throws(ConnectException::class)
    private fun handlePreviewCleanup(req: String?, clientIdentity: String?): ConnectResponse {
        // Optional bytes_to_free (canonical JSON "bytesToFree"); 0/absent = handler default.
        var bytesToFree = 0L
        if (!req.isNullOrEmpty()) {
            try {
                bytesToFree = JSONObject(req).optLong("bytesToFree", 0L)
            } catch (ignored: Exception) {
                logger.warn("Failed to parse bytesToFree from request body: " + ignored.message)
            }
        }
        // bytesToFree used to be round-tripped through a query string on a synthetic URL. It is
        // an argument now (BladeWatch-6mnq); 0 still means "use the default".
        return json { ExternalStorageApiHandler.previewCleanup(bytesToFree) }
    }

    @Throws(ConnectException::class)
    private fun handleRefreshExternalStorage(
        req: String?,
        clientIdentity: String?
    ): ConnectResponse = json { ExternalStorageApiHandler.refreshPaths() }

    @Throws(ConnectException::class)
    private fun handleListFormatVolumes(req: String?, clientIdentity: String?): ConnectResponse =
        json { FormatStorageApiHandler.listVolumes() }

    @Throws(ConnectException::class)
    private fun handleFormatVolume(req: String?, clientIdentity: String?): ConnectResponse =
        // invalid_argument / failed_precondition / internal are raised by the handler itself and
        // pass through json{} untouched.
        json {
            val volumeId = if (req.isNullOrEmpty()) "" else JSONObject(req).optString("volumeId", "")
            FormatStorageApiHandler.formatVolume(volumeId)
        }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("StorageServiceImpl")
    }
}
