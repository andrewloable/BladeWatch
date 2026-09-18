package net.bladewatch.app.storage

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.trips.TripDatabase
import java.io.File

/**
 * One-shot sweep that moves files stranded on internal storage — written while the SD card was
 * unavailable, e.g. during the boot-time mount race [StorageManager.resolveSdCardAutoPriority]
 * fixes — over to the SD card once it becomes available, so a transient mount failure doesn't
 * leave recordings split across two volumes until someone notices and moves them by hand.
 *
 * Recordings/surveillance/proximity clips need no direct database rewrite after the move: the
 * media catalog is reconciled against the filesystem afterwards ([net.bladewatch.app.media.MediaCatalogManager.reconcile]),
 * which removes the stale internal-path rows and re-indexes the same files at their new SD
 * path. Trip telemetry is different — [TripDatabase]'s `telemetry_file_path` column is the only
 * place that path lives, so it is rewritten explicitly per moved file.
 */
object InternalToSdMigrator {
    private val logger = DaemonLogger.getInstance("InternalToSdMigrator")

    /**
     * Files newer than this are left alone. A recorder can still be mid-write to a file even
     * if the active-recording/surveillance flag hasn't caught up yet, and a half-written file
     * must never be moved out from under its writer.
     */
    private const val MIN_AGE_MS = 60_000L

    /**
     * How often to log progress during a large sweep. Internal->SD moves cross filesystems, so
     * every file falls back to copy-then-delete (rename always fails with EXDEV) — a backlog of
     * hundreds of clips can take a long time to clear. Without a progress line, that looks
     * indistinguishable from a hang to anyone watching the log; this is the fix for exactly that
     * (found by watching a real device migrate a ~900-file backlog that had accumulated during
     * the incident this migrator fixes, with nothing in the log until it finished).
     */
    private const val PROGRESS_LOG_INTERVAL = 25

    /**
     * Moves [f] into [destDir] if it is eligible (a real file, old enough, and not already
     * present at the destination). Returns the new [File] on success, or null if the move was
     * skipped or failed. A destination file that already exists is left alone on both sides —
     * that is treated as "already migrated", never overwritten or duplicated.
     */
    private fun moveIfEligible(f: File, destDir: File): File? {
        if (!f.isFile) return null
        if (System.currentTimeMillis() - f.lastModified() < MIN_AGE_MS) return null
        val dest = File(destDir, f.name)
        if (dest.exists()) return null
        return try {
            if (!f.renameTo(dest)) {
                // Cross-filesystem rename (internal fuse -> sdcardfs) can fail even when both
                // sides are writable; fall back to copy-then-delete.
                f.copyTo(dest, overwrite = false)
                if (!f.delete()) {
                    // Copy succeeded but the source didn't go away — harmless (no data lost,
                    // dest.exists() will just make every future pass treat this one as already
                    // migrated), but worth a log line since it silently wastes internal space.
                    logger.warn("Copied ${f.name} to SD but could not delete the internal copy")
                }
            }
            dest
        } catch (e: Exception) {
            logger.warn("Failed to migrate ${f.name}: ${e.message}")
            null
        }
    }

    /**
     * Moves every eligible file from [internalDir] into [sdDir]. Skips entirely while
     * [categoryActive] is true — never touch files while this category is recording.
     *
     * @return number of files actually moved
     */
    @JvmStatic
    fun moveCategory(internalDir: File?, sdDir: File?, categoryActive: Boolean): Int {
        if (internalDir == null || sdDir == null) return 0
        if (internalDir.absolutePath == sdDir.absolutePath) return 0
        if (categoryActive) return 0
        val files = internalDir.listFiles() ?: return 0
        var moved = 0
        for (f in files) {
            if (moveIfEligible(f, sdDir) != null) {
                moved++
                if (moved % PROGRESS_LOG_INTERVAL == 0) {
                    logger.info("Migrating ${internalDir.name}: $moved file(s) so far...")
                }
            }
        }
        if (moved > 0) {
            logger.info("Migrated $moved file(s) from ${internalDir.absolutePath} to ${sdDir.absolutePath}")
        }
        return moved
    }

    /**
     * Moves every eligible trip telemetry file from [internalDir] to [sdDir], rewriting
     * [TripDatabase.updateTelemetryFilePath] for each file actually moved so the trip detail
     * screen keeps working after the move.
     *
     * @return number of files actually moved
     */
    @JvmStatic
    fun migrateTrips(internalDir: File?, sdDir: File?, tripDb: TripDatabase?): Int {
        if (internalDir == null || sdDir == null || tripDb == null) return 0
        if (internalDir.absolutePath == sdDir.absolutePath) return 0
        val files = internalDir.listFiles() ?: return 0
        var moved = 0
        for (f in files) {
            val oldPath = f.absolutePath
            val dest = moveIfEligible(f, sdDir) ?: continue
            moved++
            if (tripDb.updateTelemetryFilePath(oldPath, dest.absolutePath)) {
                logger.info("Trip telemetry migrated + DB updated: $oldPath -> ${dest.absolutePath}")
            } else {
                logger.debug("Trip telemetry file moved but no DB row referenced it: $oldPath")
            }
        }
        return moved
    }

    /**
     * Migrates recordings, surveillance, proximity, and trip telemetry from internal storage to
     * the SD card. Safe to call whenever the SD card becomes available (boot success or a
     * watchdog remount) — a category that is actively recording is skipped, and a category with
     * nothing stranded on internal storage is a fast no-op.
     *
     * @param catalogReconcile invoked once, only if any recordings/surveillance/proximity file
     *        was actually moved, so the media catalog DB picks up the new paths. Nullable so
     *        callers where the catalog isn't available (or in tests) can skip it. Plain
     *        [Runnable], not a Kotlin function type, so Java callers (CameraDaemon) can pass a
     *        method reference without fighting Kotlin's non-void `Unit` return type.
     */
    @JvmStatic
    fun migrate(storage: StorageManager, tripDb: TripDatabase?, catalogReconcile: Runnable?) {
        var mediaMoved = 0
        mediaMoved += moveCategory(
            storage.getInternalRecordingsDir(), storage.getSdCardRecordingsDir(), storage.isRecordingActive()
        )
        mediaMoved += moveCategory(
            storage.getInternalSurveillanceDir(), storage.getSdCardSurveillanceDir(), storage.isSurveillanceActive()
        )
        mediaMoved += moveCategory(
            storage.getInternalProximityDir(), storage.getSdCardProximityDir(), storage.isSurveillanceActive()
        )
        if (mediaMoved > 0 && catalogReconcile != null) {
            try {
                catalogReconcile.run()
            } catch (e: Exception) {
                logger.warn("Media catalog reconcile after migration failed: ${e.message}")
            }
        }
        migrateTrips(storage.getInternalTripsDir(), storage.getSdCardTripsDir(), tripDb)
    }
}
