package com.overdrive.app.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.overdrive.app.ui.model.LogEntry
import com.overdrive.app.ui.model.LogLevel
import com.overdrive.app.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Adapter for displaying log entries in a RecyclerView.
 */
class LogsAdapter : ListAdapter<LogEntry, LogsAdapter.LogViewHolder>(LogDiffCallback()) {
    
    private val timeFormat = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): LogViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_log_entry, parent, false)
        return LogViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: LogViewHolder, position: Int) {
        holder.bind(getItem(position))
    }
    
    inner class LogViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val tvTimestamp: TextView = itemView.findViewById(R.id.tvTimestamp)
        private val levelIndicator: View = itemView.findViewById(R.id.levelIndicator)
        private val tvTag: TextView = itemView.findViewById(R.id.tvTag)
        private val tvMessage: TextView = itemView.findViewById(R.id.tvMessage)
        
        fun bind(entry: LogEntry) {
            tvTimestamp.text = timeFormat.format(Date(entry.timestamp))
            tvTag.text = "[${entry.tag}]"
            tvMessage.text = entry.message
            
            // Set level indicator color
            val colorRes = when (entry.level) {
                LogLevel.DEBUG -> R.color.text_secondary
                LogLevel.INFO -> R.color.status_running
                LogLevel.WARN -> R.color.accent_orange
                LogLevel.ERROR -> R.color.status_error
            }
            levelIndicator.setBackgroundResource(colorRes)
        }
    }
    
    private class LogDiffCallback : DiffUtil.ItemCallback<LogEntry>() {
        override fun areItemsTheSame(oldItem: LogEntry, newItem: LogEntry): Boolean {
            return oldItem.timestamp == newItem.timestamp && oldItem.tag == newItem.tag
        }
        
        override fun areContentsTheSame(oldItem: LogEntry, newItem: LogEntry): Boolean {
            return oldItem == newItem
        }
    }
}
