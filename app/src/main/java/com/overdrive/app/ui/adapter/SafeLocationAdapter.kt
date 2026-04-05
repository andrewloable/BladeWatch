package com.overdrive.app.ui.adapter

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.slider.Slider
import com.google.android.material.switchmaterial.SwitchMaterial
import com.overdrive.app.R

data class SafeLocationItem(
    val id: String,
    val name: String,
    val lat: Double,
    val lng: Double,
    var radiusM: Int,
    var enabled: Boolean
)

class SafeLocationAdapter(
    private val onToggle: (String, Boolean) -> Unit,
    private val onRadiusChanged: (String, Int) -> Unit,
    private val onDelete: (String) -> Unit
) : RecyclerView.Adapter<SafeLocationAdapter.ViewHolder>() {

    private val items = mutableListOf<SafeLocationItem>()

    fun submitList(newItems: List<SafeLocationItem>) {
        items.clear()
        items.addAll(newItems)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_safe_location, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind(items[position])
    }

    override fun getItemCount() = items.size

    inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        private val tvName: TextView = view.findViewById(R.id.tvZoneName)
        private val tvRadius: TextView = view.findViewById(R.id.tvZoneRadius)
        private val tvCoords: TextView = view.findViewById(R.id.tvZoneCoords)
        private val switchEnabled: SwitchMaterial = view.findViewById(R.id.switchZoneEnabled)
        private val sliderRadius: Slider = view.findViewById(R.id.sliderZoneRadius)
        private val btnDelete: ImageButton = view.findViewById(R.id.btnDeleteZone)

        fun bind(item: SafeLocationItem) {
            tvName.text = item.name
            tvRadius.text = "${item.radiusM}m"
            tvCoords.text = String.format("%.6f, %.6f", item.lat, item.lng)

            // Prevent listener triggers during bind
            switchEnabled.setOnCheckedChangeListener(null)
            switchEnabled.isChecked = item.enabled
            switchEnabled.setOnCheckedChangeListener { _, checked ->
                item.enabled = checked
                onToggle(item.id, checked)
            }

            sliderRadius.clearOnChangeListeners()
            sliderRadius.value = item.radiusM.toFloat()
            sliderRadius.addOnChangeListener { _, value, fromUser ->
                if (fromUser) {
                    val radius = value.toInt()
                    item.radiusM = radius
                    tvRadius.text = "${radius}m"
                    onRadiusChanged(item.id, radius)
                }
            }

            btnDelete.setOnClickListener { onDelete(item.id) }
        }
    }
}
