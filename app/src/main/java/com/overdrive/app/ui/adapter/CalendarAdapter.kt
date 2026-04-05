package com.overdrive.app.ui.adapter

import android.graphics.drawable.GradientDrawable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.RecyclerView
import com.overdrive.app.R

/**
 * Adapter for calendar day grid with modern design.
 * Shows recording indicators with color-coded dots based on count.
 */
class CalendarAdapter(
    private val onDaySelected: (Int) -> Unit
) : RecyclerView.Adapter<CalendarAdapter.DayViewHolder>() {
    
    private var days: List<CalendarDay> = emptyList()
    private var selectedDay: Int = -1
    private var recordingCounts: Map<Int, Int> = emptyMap()
    
    fun setDays(days: List<CalendarDay>, recordingCounts: Map<Int, Int> = emptyMap()) {
        this.days = days
        this.recordingCounts = recordingCounts
        notifyDataSetChanged()
    }
    
    fun setSelectedDay(day: Int) {
        val oldSelected = selectedDay
        selectedDay = day
        if (oldSelected > 0) {
            val oldIndex = days.indexOfFirst { it.dayOfMonth == oldSelected }
            if (oldIndex >= 0) notifyItemChanged(oldIndex)
        }
        val newIndex = days.indexOfFirst { it.dayOfMonth == day }
        if (newIndex >= 0) notifyItemChanged(newIndex)
    }
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): DayViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_calendar_day, parent, false)
        return DayViewHolder(view)
    }
    
    override fun onBindViewHolder(holder: DayViewHolder, position: Int) {
        holder.bind(days[position])
    }
    
    override fun getItemCount(): Int = days.size
    
    inner class DayViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val dayContainer: View = itemView.findViewById(R.id.dayContainer)
        private val tvDay: TextView = itemView.findViewById(R.id.tvDay)
        private val indicatorDot1: View = itemView.findViewById(R.id.indicatorDot1)
        
        fun bind(day: CalendarDay) {
            if (day.dayOfMonth == 0) {
                // Empty cell
                tvDay.text = ""
                tvDay.isEnabled = false
                dayContainer.background = null
                indicatorDot1.visibility = View.GONE
                itemView.setOnClickListener(null)
            } else {
                tvDay.text = day.dayOfMonth.toString()
                tvDay.isEnabled = !day.isFuture
                
                val count = recordingCounts[day.dayOfMonth] ?: 0
                val isSelected = day.dayOfMonth == selectedDay
                
                // Set background based on state
                val bgRes = when {
                    day.isFuture -> 0
                    isSelected -> R.drawable.calendar_day_bg_selected
                    day.isToday -> R.drawable.calendar_day_bg_today
                    count > 0 -> R.drawable.calendar_day_bg_has_recordings
                    else -> 0
                }
                dayContainer.setBackgroundResource(bgRes)
                
                // Text color based on state
                val textColor = when {
                    day.isFuture -> R.color.text_muted
                    isSelected -> R.color.white
                    day.isToday -> R.color.brand_primary
                    day.isCurrentMonth -> R.color.text_primary
                    else -> R.color.text_secondary
                }
                tvDay.setTextColor(ContextCompat.getColor(itemView.context, textColor))
                
                // Show single indicator dot if has recordings and not selected
                if (count > 0 && !isSelected && !day.isFuture) {
                    indicatorDot1.visibility = View.VISIBLE
                    // Color based on count intensity
                    val dotColor = when {
                        count >= 10 -> R.color.status_danger
                        count >= 5 -> R.color.status_warning
                        else -> R.color.status_success
                    }
                    val color = ContextCompat.getColor(itemView.context, dotColor)
                    (indicatorDot1.background as? GradientDrawable)?.setColor(color)
                } else {
                    indicatorDot1.visibility = View.GONE
                }
                
                if (day.isFuture) {
                    itemView.setOnClickListener(null)
                    itemView.isClickable = false
                } else {
                    itemView.setOnClickListener {
                        onDaySelected(day.dayOfMonth)
                    }
                }
            }
        }
    }
    
    data class CalendarDay(
        val dayOfMonth: Int,
        val isCurrentMonth: Boolean = true,
        val isToday: Boolean = false,
        val isFuture: Boolean = false
    )
}
