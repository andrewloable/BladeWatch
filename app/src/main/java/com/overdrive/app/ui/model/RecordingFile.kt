package com.overdrive.app.ui.model

import android.net.Uri
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Represents a recorded video file.
 * SOTA: Supports both direct file access and MediaStore content URIs.
 */
data class RecordingFile(
    val file: File,
    val cameraId: Int,
    val timestamp: Long,
    val durationMs: Long,
    val sizeBytes: Long,
    val type: RecordingType,
    val contentUri: Uri? = null  // SOTA: MediaStore content URI for cross-UID access
) {
    // Secondary constructor for MediaStore results
    constructor(
        file: File,
        name: String,
        sizeBytes: Long,
        timestamp: Long,
        durationMs: Long,
        type: RecordingType,
        contentUri: Uri?
    ) : this(
        file = file,
        cameraId = extractCameraId(name),
        timestamp = timestamp,
        durationMs = durationMs,
        sizeBytes = sizeBytes,
        type = type,
        contentUri = contentUri
    )
    
    val name: String get() = file.name
    val path: String get() = file.absolutePath
    
    val formattedDate: String
        get() = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()).format(Date(timestamp))
    
    val formattedTime: String
        get() = SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(Date(timestamp))
    
    val formattedDuration: String
        get() {
            val seconds = durationMs / 1000
            val hours = seconds / 3600
            val minutes = (seconds % 3600) / 60
            val secs = seconds % 60
            return if (hours > 0) {
                String.format("%d:%02d:%02d", hours, minutes, secs)
            } else {
                String.format("%d:%02d", minutes, secs)
            }
        }
    
    val formattedSize: String
        get() = when {
            sizeBytes >= 1_000_000_000 -> String.format("%.1f GB", sizeBytes / 1_000_000_000.0)
            sizeBytes >= 1_000_000 -> String.format("%.1f MB", sizeBytes / 1_000_000.0)
            sizeBytes >= 1_000 -> String.format("%.1f KB", sizeBytes / 1_000.0)
            else -> "$sizeBytes B"
        }
    
    enum class RecordingType {
        NORMAL,     // Regular recordings (cam_*.mp4)
        SENTRY,     // Sentry event recordings (event_*.mp4)
        PROXIMITY   // Proximity guard recordings (proximity_*.mp4)
    }
    
    companion object {
        // Parse filename like: cam1_20251224_132630.mp4 or cam_20251224_132630.mp4
        private val CAM_FILENAME_PATTERN = Regex("""cam(\d+)?_(\d{8})_(\d{6})\.mp4""")
        // Parse filename like: event_20251224_132630.mp4
        private val EVENT_FILENAME_PATTERN = Regex("""event_(\d{8})_(\d{6})\.mp4""")
        // Parse filename like: proximity_20251224_132630.mp4
        private val PROXIMITY_FILENAME_PATTERN = Regex("""proximity_(\d{8})_(\d{6})\.mp4""")
        private val DATE_FORMAT = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault())
        
        fun fromFile(file: File, type: RecordingType = RecordingType.NORMAL): RecordingFile? {
            // Try type-specific parsing first
            val result = when (type) {
                RecordingType.NORMAL -> parseNormalRecording(file)
                RecordingType.SENTRY -> parseSentryRecording(file)
                RecordingType.PROXIMITY -> parseProximityRecording(file)
            }
            
            // If type-specific parsing failed, try fallback parsing
            // This handles any .mp4 file that doesn't match expected patterns
            return result ?: parseFallbackRecording(file, type)
        }
        
        /**
         * Fallback parser for .mp4 files that don't match expected patterns.
         * Uses file modification time as timestamp.
         */
        private fun parseFallbackRecording(file: File, type: RecordingType): RecordingFile? {
            if (!file.name.endsWith(".mp4")) return null
            
            return RecordingFile(
                file = file,
                cameraId = 0,
                timestamp = file.lastModified(),
                durationMs = 0,
                sizeBytes = file.length(),
                type = type
            )
        }
        
        private fun parseNormalRecording(file: File): RecordingFile? {
            val match = CAM_FILENAME_PATTERN.matchEntire(file.name) ?: return null
            val cameraId = match.groupValues[1].toIntOrNull() ?: 0  // 0 for mosaic recordings
            val dateStr = "${match.groupValues[2]}_${match.groupValues[3]}"
            val timestamp = try {
                DATE_FORMAT.parse(dateStr)?.time ?: file.lastModified()
            } catch (e: Exception) {
                file.lastModified()
            }
            
            return RecordingFile(
                file = file,
                cameraId = cameraId,
                timestamp = timestamp,
                durationMs = 0, // Would need MediaMetadataRetriever to get actual duration
                sizeBytes = file.length(),
                type = RecordingType.NORMAL
            )
        }
        
        private fun parseSentryRecording(file: File): RecordingFile? {
            val match = EVENT_FILENAME_PATTERN.matchEntire(file.name) ?: return null
            val dateStr = "${match.groupValues[1]}_${match.groupValues[2]}"
            val timestamp = try {
                DATE_FORMAT.parse(dateStr)?.time ?: file.lastModified()
            } catch (e: Exception) {
                file.lastModified()
            }
            
            return RecordingFile(
                file = file,
                cameraId = 0,  // Sentry events are mosaic recordings
                timestamp = timestamp,
                durationMs = 0,
                sizeBytes = file.length(),
                type = RecordingType.SENTRY
            )
        }
        
        private fun parseProximityRecording(file: File): RecordingFile? {
            val match = PROXIMITY_FILENAME_PATTERN.matchEntire(file.name) ?: return null
            val dateStr = "${match.groupValues[1]}_${match.groupValues[2]}"
            val timestamp = try {
                DATE_FORMAT.parse(dateStr)?.time ?: file.lastModified()
            } catch (e: Exception) {
                file.lastModified()
            }
            
            return RecordingFile(
                file = file,
                cameraId = 0,  // Proximity events are mosaic recordings
                timestamp = timestamp,
                durationMs = 0,
                sizeBytes = file.length(),
                type = RecordingType.PROXIMITY
            )
        }
        
        /**
         * Extract camera ID from filename.
         */
        private fun extractCameraId(name: String): Int {
            val match = CAM_FILENAME_PATTERN.matchEntire(name)
            return match?.groupValues?.get(1)?.toIntOrNull() ?: 0
        }
    }
}
