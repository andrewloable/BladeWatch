package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.server.RecordingsApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectHandlerUtil
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * Connect protocol handler for bladewatch.v1.RecordingsService.
 *
 * Routes:
 *   ListRecordings    → RecordingsApiHandler.listRecordings
 *   GetDates          → RecordingsApiHandler.datesWithRecordings
 *   GetStats          → RecordingsApiHandler.storageStats
 *   DeleteRecording   → RecordingsApiHandler.deleteRecording
 *   BatchDelete       → RecordingsApiHandler.batchDeleteRecordings
 *   SyncCatalog       → RecordingsApiHandler.syncCatalog
 *   GetInflightStatus → RecordingsApiHandler.inflightStatus
 *   GetEventTimeline  → RecordingsApiHandler.eventTimeline
 *   MarkRecording     → RecordingsApiHandler.markRecording
 */
class RecordingsServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register(
            "bladewatch.v1.RecordingsService", "ListRecordings", this::handleListRecordings
        )
        dispatcher.register("bladewatch.v1.RecordingsService", "GetDates", this::handleGetDates)
        dispatcher.register("bladewatch.v1.RecordingsService", "GetStats", this::handleGetStats)
        dispatcher.register(
            "bladewatch.v1.RecordingsService", "DeleteRecording", this::handleDeleteRecording
        )
        dispatcher.register(
            "bladewatch.v1.RecordingsService", "BatchDelete", this::handleBatchDelete
        )
        dispatcher.register(
            "bladewatch.v1.RecordingsService", "SyncCatalog", this::handleSyncCatalog
        )
        dispatcher.register(
            "bladewatch.v1.RecordingsService", "GetInflightStatus", this::handleGetInflightStatus
        )
        dispatcher.register(
            "bladewatch.v1.RecordingsService", "GetEventTimeline", this::handleGetEventTimeline
        )
        dispatcher.register(
            "bladewatch.v1.RecordingsService", "MarkRecording", this::handleMarkRecording
        )
    }

    @Throws(ConnectException::class)
    private fun handleListRecordings(req: String?, clientIdentity: String?): ConnectResponse {
        // The filters used to be serialised into a query string on a synthetic URL, which the
        // handler then parsed back apart — including a guard that dropped any value containing
        // '&' or '=' because it would have corrupted that string. They are arguments now, so that
        // hazard is gone with it (BladeWatch-6mnq).
        val r = body(req)
        val raw = json {
            RecordingsApiHandler.listRecordings(
                emptyToNull(r.optString("type", "")),
                emptyToNull(r.optString("date", "")),
                r.optInt("page", 1).takeIf { it > 0 } ?: 1,
                r.optInt("pageSize", 12).takeIf { it > 0 } ?: 12,
                emptyToNull(r.optString("classFilter", "")),
                emptyToNull(r.optString("severityFilter", "")),
                emptyToNull(r.optString("proximityFilter", ""))
            )
        }
        // The handler emits an enriched `actors` array per recording; the proto RecordingEntry
        // models detected_classes as repeated string (consumed by the Angular events page).
        // Derive detectedClasses from the distinct actor class names so the proto field populates.
        return json {
            val result = JSONObject(raw.body)
            // total: REST emits "totalCount"; proto ListRecordingsResponse.total reads "total".
            if (result.has("totalCount") && !result.has("total")) {
                result.put("total", result.optInt("totalCount"))
            }
            val recs = result.optJSONArray("recordings")
            if (recs != null) {
                for (i in 0 until recs.length()) {
                    val rec = recs.optJSONObject(i) ?: continue
                    // type: REST emits a lowercase string (normal/sentry/proximity); proto
                    // RecordingEntry.type is an enum parsed only from value names.
                    rec.put("type", recordingTypeEnum(rec.optString("type", "")))
                    // has_events: derive from the enriched actors[] (events present).
                    val actors = rec.optJSONArray("actors")
                    val hasEvents = actors != null && actors.length() > 0
                    if (!rec.has("hasEvents")) rec.put("hasEvents", hasEvents)
                    // detected_classes: distinct actor class names (Angular events page).
                    if (!rec.has("detectedClasses") && actors != null) {
                        val classes = LinkedHashSet<String>()
                        for (j in 0 until actors.length()) {
                            val a = actors.optJSONObject(j) ?: continue
                            val c = a.optString("class", "").lowercase(Locale.US)
                            if (c.isNotEmpty()) classes.add(c)
                        }
                        val dc = JSONArray()
                        for (c in classes) dc.put(c)
                        rec.put("detectedClasses", dc)
                    }
                }
            }
            result
        }
    }

    @Throws(ConnectException::class)
    private fun handleGetDates(req: String?, clientIdentity: String?): ConnectResponse =
        // REST emits dates as an array of {date,count,hasSentry} objects; the proto
        // GetDatesResponse.dates is `repeated string`. Objects can't parse into strings (every
        // element drops), so map each object to its date string.
        json {
            val payload = RecordingsApiHandler.datesWithRecordings()
            val arr = payload.optJSONArray("dates")
            val dates = JSONArray()
            if (arr != null) {
                for (i in 0 until arr.length()) {
                    val o = arr.optJSONObject(i) ?: continue
                    val d = o.optString("date", "")
                    if (d.isNotEmpty()) dates.put(d)
                }
            }
            payload.put("dates", dates)
        }

    @Throws(ConnectException::class)
    private fun handleGetStats(req: String?, clientIdentity: String?): ConnectResponse {
        val raw = json { RecordingsApiHandler.storageStats() }
        // The handler emits a FLAT object (normalCount/sentrySize/...); the proto GetStatsResponse
        // expects a nested `stats` (RecordingStats) with normalised names. Reshape into the nested
        // shape (Kotlin reads stats.recordingsCount/etc; the Angular consumer reads stats.stats.*).
        return json {
            val flat = JSONObject(raw.body)
            val stats = JSONObject()
                .put("recordingsSizeBytes", flat.optLong("normalSize"))
                .put("surveillanceSizeBytes", flat.optLong("sentrySize"))
                .put("proximitySizeBytes", flat.optLong("proximitySize"))
                .put("recordingsCount", flat.optInt("normalCount"))
                .put("surveillanceCount", flat.optInt("sentryCount"))
                .put("proximityCount", flat.optInt("proximityCount"))
                .put("totalSizeBytes", flat.optLong("totalSize"))
                .put("totalCount", flat.optInt("totalCount"))
            JSONObject().put("stats", stats)
        }
    }

    @Throws(ConnectException::class)
    private fun handleDeleteRecording(req: String?, clientIdentity: String?): ConnectResponse {
        val filename = ConnectHandlerUtil.requireString(req, "filename")
        return json { RecordingsApiHandler.deleteRecording(filename) }
    }

    @Throws(ConnectException::class)
    private fun handleBatchDelete(req: String?, clientIdentity: String?): ConnectResponse =
        json { RecordingsApiHandler.batchDeleteRecordings(req) }

    @Throws(ConnectException::class)
    private fun handleSyncCatalog(req: String?, clientIdentity: String?): ConnectResponse =
        json { RecordingsApiHandler.syncCatalog() }

    @Throws(ConnectException::class)
    private fun handleGetInflightStatus(req: String?, clientIdentity: String?): ConnectResponse {
        val filename = ConnectHandlerUtil.requireString(req, "filename")
        // REST emits {filename, inflight:bool, sizeBytes}; the proto GetInflightStatusResponse has
        // only a string `status`. Derive it: an active .tmp means "recording", otherwise
        // "not_found" (the REST has no signal to distinguish the finalizing state).
        return json {
            val payload = RecordingsApiHandler.inflightStatus(filename)
            val status = if (payload.optBoolean("inflight", false)) "recording" else "not_found"
            JSONObject().put("status", status)
        }
    }

    @Throws(ConnectException::class)
    private fun handleMarkRecording(req: String?, clientIdentity: String?): ConnectResponse =
        // REST and proto field names already match 1:1 (success, reason, filename,
        // markTimestampMs <-> mark_timestamp_ms's default JSON name) -- no reshaping needed,
        // unlike GetDates/GetInflightStatus above.
        json { RecordingsApiHandler.markRecording() }

    @Throws(ConnectException::class)
    private fun handleGetEventTimeline(req: String?, clientIdentity: String?): ConnectResponse {
        val filename = ConnectHandlerUtil.requireString(req, "filename")
        val raw = json { RecordingsApiHandler.eventTimeline(filename) }
        // The handler returns the rich v3 sidecar object; the proto delivers it verbatim as the
        // timeline_json string blob so clients can parse it without a flattened schema.
        return json { JSONObject().put("timelineJson", raw.body) }
    }

    private companion object {
        /** The handler treats null as "no filter"; an empty proto string means the same thing. */
        fun emptyToNull(v: String?): String? = if (v.isNullOrEmpty()) null else v

        /** Map the REST lowercase recording type to the proto RecordingType enum value name. */
        fun recordingTypeEnum(type: String): String = when (type) {
            "normal" -> "RECORDING_TYPE_NORMAL"
            "sentry" -> "RECORDING_TYPE_SENTRY"
            "proximity" -> "RECORDING_TYPE_PROXIMITY"
            else -> "RECORDING_TYPE_UNSPECIFIED"
        }
    }
}
