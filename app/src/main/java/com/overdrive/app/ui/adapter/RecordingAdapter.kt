package com.overdrive.app.ui.adapter

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.overdrive.app.ui.model.RecordingFile
import com.overdrive.app.R
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Adapter for displaying recording files with video thumbnails.
 */
class RecordingAdapter(
    private val onPlay: (RecordingFile) -> Unit,
    private val onDelete: (RecordingFile) -> Unit
) : ListAdapter<RecordingFile, RecordingAdapter.RecordingViewHolder>(RecordingDiffCallback()) {
    
    // Cache for thumbnails
    private val thumbnailCache = mutableMapOf<String, Bitmap?>()
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecordingViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_recording, parent, false)
        return RecordingViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: RecordingViewHolder, position: Int) {
        holder.bind(getItem(position))
    }
    
    inner class RecordingViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val ivThumbnail: ImageView = itemView.findViewById(R.id.ivThumbnail)
        private val tvCameraId: TextView = itemView.findViewById(R.id.tvCameraId)
        private val tvRecordingTime: TextView = itemView.findViewById(R.id.tvRecordingTime)
        private val tvDuration: TextView = itemView.findViewById(R.id.tvDuration)
        private val tvSize: TextView = itemView.findViewById(R.id.tvSize)
        private val btnPlay: ImageButton = itemView.findViewById(R.id.btnPlay)
        private val btnDelete: ImageButton = itemView.findViewById(R.id.btnDelete)
        
        fun bind(recording: RecordingFile) {
            tvCameraId.text = "C${recording.cameraId}"
            tvRecordingTime.text = recording.formattedTime
            tvDuration.text = if (recording.durationMs > 0) recording.formattedDuration else "--:--"
            tvSize.text = recording.formattedSize
            
            // Load thumbnail
            loadThumbnail(recording)
            
            btnPlay.setOnClickListener { onPlay(recording) }
            btnDelete.setOnClickListener { onDelete(recording) }
        }
        
        private fun loadThumbnail(recording: RecordingFile) {
            val path = recording.path
            
            // Check cache first
            if (thumbnailCache.containsKey(path)) {
                val cached = thumbnailCache[path]
                if (cached != null) {
                    ivThumbnail.setImageBitmap(cached)
                } else {
                    ivThumbnail.setImageResource(R.color.surface_variant)
                }
                return
            }
            
            // Set placeholder while loading
            ivThumbnail.setImageResource(R.color.surface_variant)
            
            // Load thumbnail async
            CoroutineScope(Dispatchers.IO).launch {
                val thumbnail = extractThumbnail(path)
                thumbnailCache[path] = thumbnail
                
                withContext(Dispatchers.Main) {
                    // Only update if still showing same recording
                    if (bindingAdapterPosition != RecyclerView.NO_POSITION &&
                        getItem(bindingAdapterPosition).path == path) {
                        if (thumbnail != null) {
                            ivThumbnail.setImageBitmap(thumbnail)
                        }
                    }
                }
            }
        }
        
        private fun extractThumbnail(path: String): Bitmap? {
            return try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(path)
                val frame = retriever.getFrameAtTime(1_000_000) // 1 second in
                retriever.release()
                frame
            } catch (e: Exception) {
                null
            }
        }
    }
    
    fun clearCache() {
        thumbnailCache.clear()
    }
    
    private class RecordingDiffCallback : DiffUtil.ItemCallback<RecordingFile>() {
        override fun areItemsTheSame(oldItem: RecordingFile, newItem: RecordingFile): Boolean {
            return oldItem.path == newItem.path
        }
        
        override fun areContentsTheSame(oldItem: RecordingFile, newItem: RecordingFile): Boolean {
            return oldItem == newItem
        }
    }
}
