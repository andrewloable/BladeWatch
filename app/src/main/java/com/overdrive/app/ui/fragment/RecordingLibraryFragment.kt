package com.overdrive.app.ui.fragment

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.overdrive.app.ui.adapter.CalendarAdapter
import com.overdrive.app.ui.adapter.RecordingAdapter
import com.overdrive.app.ui.model.RecordingFile
import com.overdrive.app.ui.util.RecordingScanner
import com.google.android.material.chip.Chip
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.overdrive.app.R
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.concurrent.Executors

/**
 * Fragment for browsing recorded videos with calendar view.
 * SOTA: Uses background thread for scanning to prevent UI lag.
 */
class RecordingLibraryFragment : Fragment() {
    
    companion object {
        private const val TAG = "RecordingLibrary"
    }
    
    private lateinit var tvCurrentMonth: TextView
    private lateinit var btnPrevMonth: ImageButton
    private lateinit var btnNextMonth: ImageButton
    private lateinit var recyclerCalendar: RecyclerView
    private lateinit var tvSelectedDate: TextView
    private lateinit var recyclerRecordings: RecyclerView
    private lateinit var tvEmptyState: TextView
    private var emptyStateContainer: LinearLayout? = null
    private var chipFilterAll: Chip? = null
    private var chipFilterNormal: Chip? = null
    private var chipFilterSentry: Chip? = null
    private var chipFilterProximity: Chip? = null
    
    private val calendarAdapter = CalendarAdapter { day -> onDaySelected(day) }
    private lateinit var recordingAdapter: RecordingAdapter
    
    private val calendar = Calendar.getInstance()
    private var selectedDay = calendar.get(Calendar.DAY_OF_MONTH)
    private var currentFilter = RecordingFilter.ALL
    
    private val monthFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
    
    // SOTA: Background executor for scanning operations
    private var scanExecutor = Executors.newSingleThreadExecutor()
    
    enum class RecordingFilter {
        ALL, NORMAL, SENTRY, PROXIMITY
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure executor is available (may have been shutdown on previous destroy)
        if (scanExecutor.isShutdown) {
            scanExecutor = Executors.newSingleThreadExecutor()
        }
    }
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_recording_library, container, false)
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        // Ensure executor is available (may have been shutdown in onDestroyView)
        if (scanExecutor.isShutdown || scanExecutor.isTerminated) {
            scanExecutor = Executors.newSingleThreadExecutor()
        }
        
        initViews(view)
        setupCalendar()
        setupRecordingsList()
        setupClickListeners()
        
        // SOTA: Check for All Files Access permission and trigger MediaScan
        checkPermissionsAndScan()
        
        updateCalendar()
        loadRecordingsForSelectedDate()
    }
    
    /**
     * SOTA: Setup directories and load recordings.
     * Since App owns the directories, we use direct file access.
     */
    private fun checkPermissionsAndScan() {
        // SOTA: UI App creates directories so it OWNS them (can listFiles)
        setupStorageDirectories()
        
        // Direct file access - no MediaStore needed
        RecordingScanner.invalidateCache()
        updateCalendar()
        loadRecordingsForSelectedDate()
    }
    
    /**
     * SOTA: UI App creates directories so it OWNS them.
     * This ensures listFiles() works even for files created by daemon (UID 2000).
     * Directory ownership = listFiles() access, not file ownership.
     * 
     * Now uses RecordingScanner to get configured storage paths (internal or SD card).
     */
    private fun setupStorageDirectories() {
        try {
            // Get configured directories from RecordingScanner
            val recordingsDir = RecordingScanner.getRecordingsDir(requireContext())
            val surveillanceDir = RecordingScanner.getSentryEventsDir(requireContext())
            val proximityDir = RecordingScanner.getProximityEventsDir(requireContext())
            
            Log.d(TAG, "Configured directories:")
            Log.d(TAG, "  Recordings: ${recordingsDir.absolutePath}")
            Log.d(TAG, "  Surveillance: ${surveillanceDir.absolutePath}")
            Log.d(TAG, "  Proximity: ${proximityDir.absolutePath}")
            
            // Ensure base directory exists
            val baseDir = recordingsDir.parentFile
            if (baseDir != null && !baseDir.exists()) {
                val created = baseDir.mkdirs()
                Log.d(TAG, "Created base directory: ${baseDir.absolutePath} (success=$created)")
            }
            
            // Ensure subdirectories exist
            listOf(recordingsDir, surveillanceDir, proximityDir).forEach { dir ->
                if (!dir.exists()) {
                    val created = dir.mkdirs()
                    Log.d(TAG, "Created subdirectory: ${dir.absolutePath} (success=$created)")
                }
            }
            
            // Verify we can list files now
            val files = recordingsDir.listFiles()
            Log.d(TAG, "After setup - recordings dir listFiles: ${files?.size ?: "null"}")
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup storage directories: ${e.message}")
        }
    }
    
    private fun initViews(view: View) {
        tvCurrentMonth = view.findViewById(R.id.tvCurrentMonth)
        btnPrevMonth = view.findViewById(R.id.btnPrevMonth)
        btnNextMonth = view.findViewById(R.id.btnNextMonth)
        recyclerCalendar = view.findViewById(R.id.recyclerCalendar)
        tvSelectedDate = view.findViewById(R.id.tvSelectedDate)
        recyclerRecordings = view.findViewById(R.id.recyclerRecordings)
        tvEmptyState = view.findViewById(R.id.tvEmptyState)
        emptyStateContainer = view.findViewById(R.id.emptyStateContainer)
        
        // Filter chips - modern design
        try {
            chipFilterAll = view.findViewById(R.id.btnFilterAll)
            chipFilterNormal = view.findViewById(R.id.btnFilterNormal)
            chipFilterSentry = view.findViewById(R.id.btnFilterSentry)
            chipFilterProximity = view.findViewById(R.id.btnFilterProximity)
            setupFilterChips()
        } catch (e: Exception) {
            // Filter chips not available - use default filter
        }
    }
    
    private fun setupFilterChips() {
        chipFilterAll?.setOnClickListener {
            currentFilter = RecordingFilter.ALL
            updateFilterChips()
            loadRecordingsForSelectedDate()
        }
        
        chipFilterNormal?.setOnClickListener {
            currentFilter = RecordingFilter.NORMAL
            updateFilterChips()
            loadRecordingsForSelectedDate()
        }
        
        chipFilterSentry?.setOnClickListener {
            currentFilter = RecordingFilter.SENTRY
            updateFilterChips()
            loadRecordingsForSelectedDate()
        }
        
        chipFilterProximity?.setOnClickListener {
            currentFilter = RecordingFilter.PROXIMITY
            updateFilterChips()
            loadRecordingsForSelectedDate()
        }
        
        updateFilterChips()
    }
    
    private fun updateFilterChips() {
        // Skip if chips not available
        if (chipFilterAll == null) return
        
        chipFilterAll?.isChecked = currentFilter == RecordingFilter.ALL
        chipFilterNormal?.isChecked = currentFilter == RecordingFilter.NORMAL
        chipFilterSentry?.isChecked = currentFilter == RecordingFilter.SENTRY
        chipFilterProximity?.isChecked = currentFilter == RecordingFilter.PROXIMITY
    }
    
    private fun setupCalendar() {
        recyclerCalendar.apply {
            layoutManager = GridLayoutManager(context, 7)
            adapter = calendarAdapter
        }
    }
    
    private fun setupRecordingsList() {
        recordingAdapter = RecordingAdapter(
            onPlay = { recording -> playRecording(recording) },
            onDelete = { recording -> confirmDelete(recording) }
        )
        
        recyclerRecordings.apply {
            layoutManager = LinearLayoutManager(context)
            adapter = recordingAdapter
        }
    }
    
    private fun setupClickListeners() {
        btnPrevMonth.setOnClickListener {
            calendar.add(Calendar.MONTH, -1)
            selectedDay = 1
            updateCalendar()
            loadRecordingsForSelectedDate()
        }
        
        btnNextMonth.setOnClickListener {
            calendar.add(Calendar.MONTH, 1)
            selectedDay = 1
            updateCalendar()
            loadRecordingsForSelectedDate()
        }
    }
    
    private fun updateCalendar() {
        tvCurrentMonth.text = monthFormat.format(calendar.time)
        
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        
        Log.d(TAG, "Updating calendar for $year-${month+1}")
        
        // Build calendar days first (fast operation)
        val days = buildCalendarDays(year, month)
        
        // SOTA: Load recording counts in background to prevent UI lag
        if (!scanExecutor.isShutdown) {
            scanExecutor.submit {
                try {
                    val recordingCounts = RecordingScanner.getRecordingCountsByDate(requireContext(), year, month)
                    Log.d(TAG, "Recording counts for month: $recordingCounts")
                    
                    activity?.runOnUiThread {
                        if (isAdded) {
                            calendarAdapter.setDays(days, recordingCounts)
                            calendarAdapter.setSelectedDay(selectedDay)
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error getting recording counts", e)
                }
            }
        }
        
        // Set days immediately with empty counts for instant feedback
        calendarAdapter.setDays(days, emptyMap())
        calendarAdapter.setSelectedDay(selectedDay)
    }
    
    private fun buildCalendarDays(year: Int, month: Int): List<CalendarAdapter.CalendarDay> {
        val days = mutableListOf<CalendarAdapter.CalendarDay>()
        
        val tempCal = Calendar.getInstance().apply {
            set(year, month, 1)
        }
        
        val today = Calendar.getInstance()
        val isCurrentMonth = today.get(Calendar.YEAR) == year && today.get(Calendar.MONTH) == month
        val isFutureMonth = (year > today.get(Calendar.YEAR)) || 
            (year == today.get(Calendar.YEAR) && month > today.get(Calendar.MONTH))
        val todayDay = if (isCurrentMonth) today.get(Calendar.DAY_OF_MONTH) else -1
        
        // Add empty cells for days before the first of the month
        val firstDayOfWeek = tempCal.get(Calendar.DAY_OF_WEEK) - 1
        repeat(firstDayOfWeek) {
            days.add(CalendarAdapter.CalendarDay(0, false))
        }
        
        // Add days of the month
        val daysInMonth = tempCal.getActualMaximum(Calendar.DAY_OF_MONTH)
        for (day in 1..daysInMonth) {
            val isFuture = isFutureMonth || (isCurrentMonth && day > todayDay)
            days.add(CalendarAdapter.CalendarDay(
                dayOfMonth = day,
                isCurrentMonth = true,
                isToday = day == todayDay,
                isFuture = isFuture
            ))
        }
        
        return days
    }
    
    private fun onDaySelected(day: Int) {
        selectedDay = day
        calendarAdapter.setSelectedDay(day)
        loadRecordingsForSelectedDate()
    }
    
    private fun loadRecordingsForSelectedDate() {
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        
        // Update header immediately
        val selectedCal = Calendar.getInstance().apply {
            set(year, month, selectedDay)
        }
        tvSelectedDate.text = SimpleDateFormat("MMM d", Locale.getDefault()).format(selectedCal.time)
        
        Log.d(TAG, "Loading recordings for $year-${month+1}-$selectedDay")
        
        // SOTA: Load recordings in background to prevent UI lag during date selection
        if (scanExecutor.isShutdown) return
        scanExecutor.submit {
            try {
                // Debug: Check directories
                val recordingsDir = RecordingScanner.getRecordingsDir(requireContext())
                val sentryDir = RecordingScanner.getSentryEventsDir(requireContext())
                val proximityDir = RecordingScanner.getProximityEventsDir(requireContext())
                
                Log.d(TAG, "Recordings dir: ${recordingsDir.absolutePath}, exists: ${recordingsDir.exists()}")
                Log.d(TAG, "Sentry dir: ${sentryDir.absolutePath}, exists: ${sentryDir.exists()}")
                Log.d(TAG, "Proximity dir: ${proximityDir.absolutePath}, exists: ${proximityDir.exists()}")
                
                if (recordingsDir.exists()) {
                    val files = recordingsDir.listFiles()
                    Log.d(TAG, "Recordings dir files: ${files?.size ?: 0}")
                    files?.take(5)?.forEach { Log.d(TAG, "  - ${it.name}") }
                }
                
                val allRecordings = RecordingScanner.getRecordingsForDate(requireContext(), year, month, selectedDay)
                Log.d(TAG, "Found ${allRecordings.size} recordings for date")
                
                val recordings = when (currentFilter) {
                    RecordingFilter.ALL -> allRecordings
                    RecordingFilter.NORMAL -> allRecordings.filter { it.type == RecordingFile.RecordingType.NORMAL }
                    RecordingFilter.SENTRY -> allRecordings.filter { it.type == RecordingFile.RecordingType.SENTRY }
                    RecordingFilter.PROXIMITY -> allRecordings.filter { it.type == RecordingFile.RecordingType.PROXIMITY }
                }
                
                Log.d(TAG, "After filter (${currentFilter}): ${recordings.size} recordings")
                
                activity?.runOnUiThread {
                    if (isAdded) {
                        if (recordings.isEmpty()) {
                            recyclerRecordings.visibility = View.GONE
                            emptyStateContainer?.visibility = View.VISIBLE
                            tvEmptyState.visibility = View.VISIBLE
                            tvEmptyState.text = when (currentFilter) {
                                RecordingFilter.ALL -> "No recordings for this date"
                                RecordingFilter.NORMAL -> "No normal recordings"
                                RecordingFilter.SENTRY -> "No sentry events"
                                RecordingFilter.PROXIMITY -> "No proximity events"
                            }
                        } else {
                            recyclerRecordings.visibility = View.VISIBLE
                            emptyStateContainer?.visibility = View.GONE
                            tvEmptyState.visibility = View.GONE
                            recordingAdapter.submitList(recordings)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading recordings", e)
            }
        }
    }
    
    private fun playRecording(recording: RecordingFile) {
        try {
            val bundle = Bundle().apply {
                putString(VideoPlayerFragment.ARG_VIDEO_PATH, recording.path)
                putString(VideoPlayerFragment.ARG_VIDEO_TITLE, recording.name)
            }
            androidx.navigation.fragment.NavHostFragment.findNavController(this)
                .navigate(R.id.action_global_videoPlayer, bundle)
        } catch (e: Exception) {
            // Fallback: open with external player if navigation fails
            try {
                val uri = recording.contentUri ?: FileProvider.getUriForFile(
                    requireContext(),
                    "${requireContext().packageName}.fileprovider",
                    recording.file
                )
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "video/mp4")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                startActivity(Intent.createChooser(intent, "Play with"))
            } catch (e2: Exception) {
                Toast.makeText(context, "Cannot play video: ${e2.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }
    
    private fun confirmDelete(recording: RecordingFile) {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle("Delete Recording")
            .setMessage("Delete ${recording.name}?\nThis cannot be undone.")
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Delete") { _, _ ->
                deleteRecording(recording)
            }
            .show()
    }
    
    private fun deleteRecording(recording: RecordingFile) {
        if (RecordingScanner.deleteRecording(recording)) {
            Toast.makeText(context, "Recording deleted", Toast.LENGTH_SHORT).show()
            loadRecordingsForSelectedDate()
            updateCalendar() // Refresh indicators
        } else {
            Toast.makeText(context, "Failed to delete recording", Toast.LENGTH_SHORT).show()
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Invalidate cache on resume to pick up new recordings
        RecordingScanner.invalidateCache()
        updateCalendar()
        loadRecordingsForSelectedDate()
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        // Shutdown executor to prevent memory leaks
        scanExecutor.shutdown()
    }
}
