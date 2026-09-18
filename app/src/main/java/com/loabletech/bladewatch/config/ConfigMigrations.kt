package net.bladewatch.app.config

import net.bladewatch.app.recording.RecordingPriority
import org.json.JSONObject

/**
 * One-time config migrations, applied by [UnifiedConfigManager.loadConfig] to every config it
 * reads from disk (BladeWatch-l5w4).
 *
 * Extracted from `UnifiedConfigManager` as a pure function of a [JSONObject] -- no `android.*`
 * import anywhere in this file -- so the migrations are testable without a live Android
 * environment, which that class needs for its other members (`android.util.Log`, real paths
 * under `/data/local/tmp`). Same constraint and same remedy as
 * `StorageManager.selectFilesToDelete` and `DrivingSafetyGuard`; see `ConfigMigrationsTest`.
 *
 * Every migration here is **marker-gated**, and that is the load-bearing part: it must fire
 * exactly once for a config that predates the key and never again, because a migration that
 * re-fires would permanently override a setting the owner has since changed by hand. A
 * persisted marker is the only way to express that -- inferring "has this been migrated?" at
 * read time cannot distinguish "never migrated" from "migrated, then deliberately changed
 * back" (see BladeWatch-k1pr for the attempt that got this wrong).
 */
object ConfigMigrations {

    /**
     * Applies every pending migration to [config] in place.
     *
     * @return true if anything changed, so the caller knows to persist it
     */
    @JvmStatic
    fun apply(config: JSONObject): Boolean {
        var changed = false

        // Telemetry overlay default flipped false -> true (2026-06). Configs
        // created under the old false-default are enabled exactly once; the
        // defaultOnMigrated marker prevents re-enabling after the user turns
        // the overlay off in Settings.
        val telemetryOverlay = config.optJSONObject("telemetryOverlay") ?: JSONObject().also {
            config.put("telemetryOverlay", it)
            changed = true
        }
        if (!telemetryOverlay.optBoolean("defaultOnMigrated", false)) {
            telemetryOverlay.put("enabled", true)
            telemetryOverlay.put("defaultOnMigrated", true)
            changed = true
        }

        // Recording priority introduced (2026-09) with RELIABILITY as the new-install
        // default. A config reaching this point predates the key entirely and was running
        // with no segment cap -- i.e. today's actual behaviour is the PERFORMANCE
        // passthrough, not an approximation of it. Migrated exactly once via the
        // priorityMigrated marker (UnifiedConfigManager.applyDefaults() sets both together
        // for configs created after this shipped, so this never re-fires there); a later
        // deliberate switch to RELIABILITY in Settings is never re-overridden.
        // See BladeWatch-gyg1.3.
        val recording = config.optJSONObject("recording") ?: JSONObject().also {
            config.put("recording", it)
            changed = true
        }
        if (!recording.optBoolean("priorityMigrated", false)) {
            recording.put("priority", RecordingPriority.PERFORMANCE.name)
            recording.put("priorityMigrated", true)
            changed = true
        }

        return changed
    }
}
