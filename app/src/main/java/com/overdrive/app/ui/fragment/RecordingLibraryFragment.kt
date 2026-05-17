package com.overdrive.app.ui.fragment

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.overdrive.app.ui.adapter.RecordingAdapter
import com.overdrive.app.ui.model.RecordingFile
import com.overdrive.app.ui.util.RecordingScanner
import com.overdrive.app.ui.util.RecordingSectionHeaderDecoration
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.google.android.material.datepicker.CalendarConstraints
import com.google.android.material.datepicker.DateValidatorPointBackward
import com.google.android.material.datepicker.MaterialDatePicker
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.overdrive.app.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

/**
 * Fragment for browsing recorded videos with a slim, list-first UI.
 *
 * v4 redesign (item: SOTA recording library):
 *  - Replaced the 3-stack calendar (header + week strip + month grid) with a
 *    single tappable date row that opens a MaterialDatePicker, plus ◀/▶
 *    one-day jumps.
 *  - Replaced the always-visible Actor + Severity chip rows with a slim
 *    "Filter" pill + bottom sheet. Active filters surface as inline,
 *    individually-dismissable chips.
 *  - Added sticky time-of-day section headers via RecordingSectionHeaderDecoration.
 *  - When embedded inside RecordingsFragment (ARG_HIDE_INTERNAL_FILTERS=true),
 *    the entire filter bar collapses too — the parent's segmented control
 *    drives the source filter, and the bottom-sheet's actor/severity controls
 *    are still reachable if the parent ever flips the flag back.
 */
class RecordingLibraryFragment : Fragment() {

    companion object {
        private const val TAG = "RecordingLibrary"

        /** When true, the fragment hides its internal filter bar — used when a
         *  parent (RecordingsFragment) drives the filter via its own segmented
         *  control. */
        const val ARG_HIDE_INTERNAL_FILTERS = "hide_internal_filters"

        /** Convenience factory for embedded use. */
        fun newInstanceEmbedded(): RecordingLibraryFragment =
            RecordingLibraryFragment().apply {
                arguments = Bundle().apply {
                    putBoolean(ARG_HIDE_INTERNAL_FILTERS, true)
                }
            }
    }

    // -------- Date row --------
    private lateinit var tvSelectedDate: TextView
    private lateinit var tvDayClipCount: TextView
    private lateinit var cardDateJump: MaterialCardView
    private lateinit var btnPrevDay: MaterialButton
    private lateinit var btnNextDay: MaterialButton

    // -------- Filter bar --------
    private var filterBar: View? = null
    private var activeFiltersGroup: ChipGroup? = null
    private var btnOpenFilters: MaterialButton? = null

    // -------- List + empty state --------
    private lateinit var recyclerRecordings: RecyclerView
    private lateinit var tvEmptyState: TextView
    private var emptyStateContainer: LinearLayout? = null

    // -------- Multi-select --------
    private var selectToolbar: LinearLayout? = null
    private var tvSelectedCount: TextView? = null
    private var btnSelectAll: View? = null
    private var btnDeleteSelected: View? = null
    private var btnCancelSelect: View? = null

    // -------- Filter sheet (lazily inflated) --------
    private var filterSheet: BottomSheetDialog? = null
    // Refs into the inflated sheet content; null until the first open.
    private var sheetChipActorAny: Chip? = null
    private var sheetChipActorPerson: Chip? = null
    private var sheetChipActorVehicle: Chip? = null
    private var sheetChipActorBike: Chip? = null
    private var sheetChipActorAnimal: Chip? = null
    private var sheetChipSevAny: Chip? = null
    private var sheetChipSevAlert: Chip? = null
    private var sheetChipSevCritical: Chip? = null

    private lateinit var recordingAdapter: RecordingAdapter
    private var sectionHeaderDecoration: RecordingSectionHeaderDecoration? = null
    // Snapshot of currently displayed list — read by the decoration on every
    // draw pass. Single source of truth so the decoration doesn't have to
    // know about ListAdapter internals.
    private var currentList: List<RecordingFile> = emptyList()

    // Date state: we keep using a Calendar instance so the existing
    // loadRecordingsForSelectedDate() logic (year/month/selectedDay) is a
    // mechanical move from the old implementation.
    private val calendar = Calendar.getInstance()
    private var selectedDay = calendar.get(Calendar.DAY_OF_MONTH)
    private var currentFilter = RecordingFilter.ALL

    // v3 actor + severity filter state — unchanged semantics
    private val actorClassFilter = mutableSetOf<String>()  // lowercased class group names
    private val severityFilter = mutableSetOf<String>()    // "ALERT" / "CRITICAL"

    private val dayHeaderFormat = SimpleDateFormat("MMM d, yyyy", Locale.getDefault())

    // SOTA: Background executor for scanning operations
    private var scanExecutor = Executors.newSingleThreadExecutor()

    enum class RecordingFilter {
        ALL, NORMAL, SENTRY, PROXIMITY
    }

    /**
     * Optional override for tap-to-play behavior. When non-null,
     * [playRecording] invokes this callback INSTEAD of launching the
     * global full-screen [VideoPlayerFragment] via nav action.
     */
    var onPlayRecording: ((RecordingFile) -> Unit)? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_recording_library, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Single source of executor lifecycle: created here when needed,
        // shut down in onDestroyView. The previous version also rebuilt it
        // in onCreate which created a race when onCreate / onViewCreated
        // ran out-of-expected-order on configuration change.
        if (scanExecutor.isShutdown || scanExecutor.isTerminated) {
            scanExecutor = Executors.newSingleThreadExecutor()
        }

        initViews(view)
        setupRecordingsList()
        setupClickListeners()

        // When the parent drives filters via its own segmented control, also
        // hide the in-page filter bar. Actor + severity stay reachable via
        // setSourceFilter() and (if the parent ever surfaces it) the bottom
        // sheet — but visually the user sees just the date row and the list.
        if (arguments?.getBoolean(ARG_HIDE_INTERNAL_FILTERS, false) == true) {
            filterBar?.visibility = View.GONE
        }

        checkPermissionsAndScan()

        updateDateHeader()
        loadRecordingsForSelectedDate()
        renderActiveFilters()
    }

    /**
     * SOTA: Setup directories and load recordings.
     * Since App owns the directories, we use direct file access.
     */
    private fun checkPermissionsAndScan() {
        setupStorageDirectories()
        RecordingScanner.invalidateCache()
        loadRecordingsForSelectedDate()
    }

    private fun setupStorageDirectories() {
        try {
            val recordingsDir = RecordingScanner.getRecordingsDir(requireContext())
            val surveillanceDir = RecordingScanner.getSentryEventsDir(requireContext())
            val proximityDir = RecordingScanner.getProximityEventsDir(requireContext())

            Log.d(TAG, "Configured directories:")
            Log.d(TAG, "  Recordings: ${recordingsDir.absolutePath}")
            Log.d(TAG, "  Surveillance: ${surveillanceDir.absolutePath}")
            Log.d(TAG, "  Proximity: ${proximityDir.absolutePath}")

            val baseDir = recordingsDir.parentFile
            if (baseDir != null && !baseDir.exists()) {
                val created = baseDir.mkdirs()
                Log.d(TAG, "Created base directory: ${baseDir.absolutePath} (success=$created)")
            }

            listOf(recordingsDir, surveillanceDir, proximityDir).forEach { dir ->
                if (!dir.exists()) {
                    val created = dir.mkdirs()
                    Log.d(TAG, "Created subdirectory: ${dir.absolutePath} (success=$created)")
                }
            }

            val files = recordingsDir.listFiles()
            Log.d(TAG, "After setup - recordings dir listFiles: ${files?.size ?: "null"}")

        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup storage directories: ${e.message}")
        }
    }

    private fun initViews(view: View) {
        // Date row
        tvSelectedDate = view.findViewById(R.id.tvSelectedDate)
        tvDayClipCount = view.findViewById(R.id.tvDayClipCount)
        cardDateJump = view.findViewById(R.id.cardDateJump)
        btnPrevDay = view.findViewById(R.id.btnPrevDay)
        btnNextDay = view.findViewById(R.id.btnNextDay)

        // Filter bar
        filterBar = view.findViewById(R.id.filterBar)
        activeFiltersGroup = view.findViewById(R.id.activeFiltersGroup)
        btnOpenFilters = view.findViewById(R.id.btnOpenFilters)

        // List
        recyclerRecordings = view.findViewById(R.id.recyclerRecordings)
        tvEmptyState = view.findViewById(R.id.tvEmptyState)
        emptyStateContainer = view.findViewById(R.id.emptyStateContainer)

        // Multi-select
        selectToolbar = view.findViewById(R.id.selectToolbar)
        tvSelectedCount = view.findViewById(R.id.tvSelectedCount)
        btnSelectAll = view.findViewById(R.id.btnSelectAll)
        btnDeleteSelected = view.findViewById(R.id.btnDeleteSelected)
        btnCancelSelect = view.findViewById(R.id.btnCancelSelect)

        btnSelectAll?.setOnClickListener { recordingAdapter.selectAll() }
        btnDeleteSelected?.setOnClickListener { confirmBatchDelete() }
        btnCancelSelect?.setOnClickListener { exitSelectMode() }
    }

    /**
     * Public entry point so a parent fragment (e.g. RecordingsFragment's
     * segmented Dashcam / Surveillance control) can drive the source filter
     * without needing to find and click the internal chips.
     */
    fun setSourceFilter(filter: RecordingFilter) {
        if (currentFilter == filter) return
        currentFilter = filter
        if (view != null) {
            loadRecordingsForSelectedDate()
        }
    }

    // -----------------------------------------------------------------
    // Filter sheet
    // -----------------------------------------------------------------

    private fun openFilterSheet() {
        // Dismiss any leftover sheet from a previous open (e.g. config change).
        filterSheet?.dismiss()
        val ctx = context ?: return
        val sheet = BottomSheetDialog(ctx, R.style.Theme_Overdrive_M3_BottomSheet)
        val sheetView = LayoutInflater.from(ctx)
            .inflate(R.layout.sheet_recording_library_filters, null, false)
        sheet.setContentView(sheetView)

        sheetChipActorAny      = sheetView.findViewById(R.id.chipActorAny)
        sheetChipActorPerson   = sheetView.findViewById(R.id.chipActorPerson)
        sheetChipActorVehicle  = sheetView.findViewById(R.id.chipActorVehicle)
        sheetChipActorBike     = sheetView.findViewById(R.id.chipActorBike)
        sheetChipActorAnimal   = sheetView.findViewById(R.id.chipActorAnimal)
        sheetChipSevAny        = sheetView.findViewById(R.id.chipSevAny)
        sheetChipSevAlert      = sheetView.findViewById(R.id.chipSevAlert)
        sheetChipSevCritical   = sheetView.findViewById(R.id.chipSevCritical)

        // Per-row "Any" — clears that row only. Same semantics as before.
        sheetChipActorAny?.setOnClickListener {
            actorClassFilter.clear()
            syncSheetChipChecks()
        }
        sheetChipSevAny?.setOnClickListener {
            severityFilter.clear()
            syncSheetChipChecks()
        }
        sheetChipActorPerson?.setOnClickListener  { toggleActorClass("person") }
        sheetChipActorVehicle?.setOnClickListener { toggleActorClass("vehicle") }
        sheetChipActorBike?.setOnClickListener    { toggleActorClass("bike") }
        sheetChipActorAnimal?.setOnClickListener  { toggleActorClass("animal") }
        sheetChipSevAlert?.setOnClickListener     { toggleSeverity("ALERT") }
        sheetChipSevCritical?.setOnClickListener  { toggleSeverity("CRITICAL") }

        val btnReset = sheetView.findViewById<MaterialButton>(R.id.btnFilterReset)
        btnReset.setOnClickListener {
            actorClassFilter.clear()
            severityFilter.clear()
            syncSheetChipChecks()
        }

        val btnApply = sheetView.findViewById<MaterialButton>(R.id.btnFilterApply)
        btnApply.setOnClickListener {
            sheet.dismiss()
            renderActiveFilters()
            loadRecordingsForSelectedDate()
        }

        sheet.setOnDismissListener {
            // Clear refs so a stale view from a now-destroyed sheet doesn't
            // get touched on the next state change.
            sheetChipActorAny = null
            sheetChipActorPerson = null
            sheetChipActorVehicle = null
            sheetChipActorBike = null
            sheetChipActorAnimal = null
            sheetChipSevAny = null
            sheetChipSevAlert = null
            sheetChipSevCritical = null
            // Re-render bar from the latest filter state (apply already did
            // this; this is the cancel/dismiss-by-back path).
            renderActiveFilters()
            loadRecordingsForSelectedDate()
            filterSheet = null
        }

        syncSheetChipChecks()
        filterSheet = sheet
        sheet.show()
    }

    private fun toggleActorClass(name: String) {
        if (actorClassFilter.contains(name)) actorClassFilter.remove(name)
        else actorClassFilter.add(name)
        syncSheetChipChecks()
    }

    private fun toggleSeverity(name: String) {
        if (severityFilter.contains(name)) severityFilter.remove(name)
        else severityFilter.add(name)
        syncSheetChipChecks()
    }

    private fun syncSheetChipChecks() {
        sheetChipActorAny?.isChecked      = actorClassFilter.isEmpty()
        sheetChipSevAny?.isChecked        = severityFilter.isEmpty()
        sheetChipActorPerson?.isChecked   = actorClassFilter.contains("person")
        sheetChipActorVehicle?.isChecked  = actorClassFilter.contains("vehicle")
        sheetChipActorBike?.isChecked     = actorClassFilter.contains("bike")
        sheetChipActorAnimal?.isChecked   = actorClassFilter.contains("animal")
        sheetChipSevAlert?.isChecked      = severityFilter.contains("ALERT")
        sheetChipSevCritical?.isChecked   = severityFilter.contains("CRITICAL")
    }

    /**
     * Rebuild the inline active-filter chips and update the trailing pill's
     * label/badge to reflect the current filter state.
     */
    private fun renderActiveFilters() {
        val group = activeFiltersGroup ?: return
        val ctx = context ?: return

        group.removeAllViews()

        val active = mutableListOf<Pair<String, () -> Unit>>()
        if (actorClassFilter.contains("person"))
            active += getString(R.string.recording_lib_chip_person) to {
                actorClassFilter.remove("person")
            }
        if (actorClassFilter.contains("vehicle"))
            active += getString(R.string.recording_lib_chip_vehicle) to {
                actorClassFilter.remove("vehicle")
            }
        if (actorClassFilter.contains("bike"))
            active += getString(R.string.recording_lib_chip_bike) to {
                actorClassFilter.remove("bike")
            }
        if (actorClassFilter.contains("animal"))
            active += getString(R.string.recording_lib_chip_animal) to {
                actorClassFilter.remove("animal")
            }
        if (severityFilter.contains("ALERT"))
            active += getString(R.string.recording_lib_chip_alert) to {
                severityFilter.remove("ALERT")
            }
        if (severityFilter.contains("CRITICAL"))
            active += getString(R.string.recording_lib_chip_critical) to {
                severityFilter.remove("CRITICAL")
            }

        for ((label, removeAction) in active) {
            val chip = Chip(ctx).apply {
                setEnsureMinTouchTargetSize(false)
                text = label
                isCloseIconVisible = true
                isCheckable = false
                isClickable = true
                contentDescription = getString(R.string.cd_clear_filter)
                setOnCloseIconClickListener {
                    removeAction()
                    renderActiveFilters()
                    loadRecordingsForSelectedDate()
                }
            }
            group.addView(chip)
        }

        // Pill label updates with active count (n>0 → "Filter · 2", else "Filter")
        btnOpenFilters?.text = if (active.isEmpty()) {
            getString(R.string.recording_lib_filter_button)
        } else {
            getString(R.string.recording_lib_filter_button_active, active.size)
        }
    }

    // -----------------------------------------------------------------
    // Date handling
    // -----------------------------------------------------------------

    private fun setupClickListeners() {
        cardDateJump.setOnClickListener { showDatePicker() }
        btnPrevDay.setOnClickListener { shiftSelectedDay(-1) }
        btnNextDay.setOnClickListener { shiftSelectedDay(+1) }
        btnOpenFilters?.setOnClickListener { openFilterSheet() }
    }

    private fun showDatePicker() {
        val constraints = CalendarConstraints.Builder()
            .setEnd(MaterialDatePicker.todayInUtcMilliseconds())
            .setValidator(DateValidatorPointBackward.now())
            .build()

        // Pre-select the current selection in UTC midnight (MaterialDatePicker
        // expects UTC ms from epoch).
        val selectedUtcMs = utcMidnightMillis(
            calendar.get(Calendar.YEAR),
            calendar.get(Calendar.MONTH),
            selectedDay
        )

        val picker = MaterialDatePicker.Builder.datePicker()
            .setTitleText(R.string.recording_lib_pick_date)
            .setCalendarConstraints(constraints)
            .setSelection(selectedUtcMs)
            .build()

        picker.addOnPositiveButtonClickListener { utcMs ->
            // Convert UTC ms back to local Y/M/D.
            val cal = Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC")).apply {
                timeInMillis = utcMs
            }
            val y = cal.get(Calendar.YEAR)
            val m = cal.get(Calendar.MONTH)
            val d = cal.get(Calendar.DAY_OF_MONTH)
            calendar.set(y, m, 1)
            selectedDay = d
            updateDateHeader()
            loadRecordingsForSelectedDate()
        }

        picker.show(parentFragmentManager, "recording_lib_date_picker")
    }

    private fun utcMidnightMillis(year: Int, month: Int, day: Int): Long {
        val cal = Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC")).apply {
            clear()
            set(year, month, day, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return cal.timeInMillis
    }

    /** ◀ / ▶ one-day jumps. Clamps at today (no future days). */
    private fun shiftSelectedDay(delta: Int) {
        val cal = Calendar.getInstance().apply {
            set(
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH),
                selectedDay
            )
            add(Calendar.DAY_OF_MONTH, delta)
        }
        // Clamp at today.
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        val candidate = (cal.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        if (candidate.after(today)) return

        calendar.set(cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), 1)
        selectedDay = cal.get(Calendar.DAY_OF_MONTH)
        updateDateHeader()
        loadRecordingsForSelectedDate()
    }

    private fun updateDateHeader() {
        val selectedCal = Calendar.getInstance().apply {
            set(
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH),
                selectedDay,
                0, 0, 0
            )
            set(Calendar.MILLISECOND, 0)
        }
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }
        val yesterday = (today.clone() as Calendar).apply {
            add(Calendar.DAY_OF_YEAR, -1)
        }

        tvSelectedDate.text = when (selectedCal.timeInMillis) {
            today.timeInMillis -> getString(R.string.recording_lib_date_today)
            yesterday.timeInMillis -> getString(R.string.recording_lib_date_yesterday)
            else -> dayHeaderFormat.format(Date(selectedCal.timeInMillis))
        }

        // Disable forward-day button when we're already on today.
        btnNextDay.isEnabled = selectedCal.timeInMillis < today.timeInMillis
        btnNextDay.alpha = if (btnNextDay.isEnabled) 1f else 0.4f
    }

    // -----------------------------------------------------------------
    // List
    // -----------------------------------------------------------------

    private fun setupRecordingsList() {
        recordingAdapter = RecordingAdapter(
            onPlay = { recording -> playRecording(recording) },
            onDelete = { recording -> confirmDelete(recording) },
            onSelectionChanged = { count -> onSelectionChanged(count) }
        )

        recyclerRecordings.apply {
            layoutManager = GridLayoutManager(context, 2)
            adapter = recordingAdapter
            setHasFixedSize(true)
        }

        // Sticky time-of-day section headers. Decoration reads `currentList`
        // every frame so it stays in sync without us re-attaching it on every
        // submitList().
        sectionHeaderDecoration?.let { recyclerRecordings.removeItemDecoration(it) }
        val deco = RecordingSectionHeaderDecoration(requireContext()) { currentList }
        recyclerRecordings.addItemDecoration(deco)
        sectionHeaderDecoration = deco
    }

    private fun onSelectionChanged(count: Int) {
        tvSelectedCount?.text = getString(R.string.recording_lib_selected_count, count)
        if (recordingAdapter.selectMode && selectToolbar?.visibility != View.VISIBLE) {
            selectToolbar?.visibility = View.VISIBLE
        }
    }

    private fun loadRecordingsForSelectedDate() {
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)

        Log.d(TAG, "Loading recordings for $year-${month+1}-$selectedDay")

        if (scanExecutor.isShutdown) return
        scanExecutor.submit {
            try {
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

                val typeFiltered = when (currentFilter) {
                    RecordingFilter.ALL -> allRecordings
                    RecordingFilter.NORMAL -> allRecordings.filter { it.type == RecordingFile.RecordingType.NORMAL }
                    RecordingFilter.SENTRY -> allRecordings.filter { it.type == RecordingFile.RecordingType.SENTRY }
                    RecordingFilter.PROXIMITY -> allRecordings.filter { it.type == RecordingFile.RecordingType.PROXIMITY }
                }

                val recordings = if (actorClassFilter.isEmpty() && severityFilter.isEmpty()) {
                    typeFiltered
                } else {
                    typeFiltered.filter { rec ->
                        val classOk = actorClassFilter.isEmpty()
                                || rec.actorClasses.any { it.lowercase() in actorClassFilter }
                        val sevOk = severityFilter.isEmpty()
                                || (rec.peakSeverity?.uppercase() in severityFilter)
                        classOk && sevOk
                    }
                }

                Log.d(TAG, "After filter (${currentFilter}, actor=$actorClassFilter, sev=$severityFilter): ${recordings.size} recordings")

                activity?.runOnUiThread {
                    if (isAdded) {
                        renderRecordings(recordings)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error loading recordings", e)
            }
        }
    }

    private fun renderRecordings(recordings: List<RecordingFile>) {
        currentList = recordings

        // Day clip count pill on the date jump card. We show the total
        // matching the source filter only — actor/severity filters are
        // additive narrowings, but the pill is meant to represent the day's
        // total clips, so we show the raw count here.
        if (recordings.isNotEmpty()) {
            tvDayClipCount.visibility = View.VISIBLE
            tvDayClipCount.text = resources.getQuantityStringSafe(
                R.string.recording_lib_clip_count_one,
                R.string.recording_lib_clip_count,
                recordings.size
            )
        } else {
            tvDayClipCount.visibility = View.GONE
        }

        // Decoration mode: single-day always, since the list is filtered to one day.
        sectionHeaderDecoration?.singleDayMode = true

        if (recordings.isEmpty()) {
            recyclerRecordings.visibility = View.GONE
            emptyStateContainer?.visibility = View.VISIBLE
            tvEmptyState.visibility = View.VISIBLE
            tvEmptyState.text = when (currentFilter) {
                RecordingFilter.ALL -> getString(R.string.recording_lib_no_recordings)
                RecordingFilter.NORMAL -> "No normal recordings"
                RecordingFilter.SENTRY -> "No sentry events"
                RecordingFilter.PROXIMITY -> "No proximity events"
            }
            recordingAdapter.submitList(emptyList())
        } else {
            recyclerRecordings.visibility = View.VISIBLE
            emptyStateContainer?.visibility = View.GONE
            tvEmptyState.visibility = View.GONE
            recordingAdapter.submitList(recordings) {
                // After the diff applies, the decoration reads `currentList`
                // and re-paints sections.
                recyclerRecordings.invalidateItemDecorations()
            }
        }
    }

    // Tiny helper: pluralized "%d clip(s)" without forcing a strings.xml plural
    // (we already keep both forms separately for fast reuse).
    private fun android.content.res.Resources.getQuantityStringSafe(
        oneRes: Int, otherRes: Int, count: Int
    ): String {
        return if (count == 1) getString(oneRes, count) else getString(otherRes, count)
    }

    // -----------------------------------------------------------------
    // Playback / delete
    // -----------------------------------------------------------------

    private fun playRecording(recording: RecordingFile) {
        onPlayRecording?.let {
            it(recording)
            return
        }
        try {
            val bundle = Bundle().apply {
                putString(VideoPlayerFragment.ARG_VIDEO_PATH, recording.path)
                putString(VideoPlayerFragment.ARG_VIDEO_TITLE, recording.name)
            }
            androidx.navigation.fragment.NavHostFragment.findNavController(this)
                .navigate(R.id.action_global_videoPlayer, bundle)
        } catch (e: Exception) {
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
                startActivity(Intent.createChooser(intent, getString(R.string.play_with_chooser)))
            } catch (e2: Exception) {
                Toast.makeText(context, getString(R.string.toast_cannot_play_video, e2.message ?: ""), Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun confirmDelete(recording: RecordingFile) {
        MaterialAlertDialogBuilder(requireContext(), R.style.Theme_Overdrive_M3_Dialog)
            .setTitle(getString(R.string.dialog_delete_recording_title))
            .setMessage(getString(R.string.dialog_delete_recording_message, recording.name))
            .setNegativeButton(getString(R.string.action_cancel), null)
            .setPositiveButton(getString(R.string.dialog_delete)) { _, _ ->
                deleteRecording(recording)
            }
            .show()
    }

    private fun deleteRecording(recording: RecordingFile) {
        if (RecordingScanner.deleteRecording(recording)) {
            Toast.makeText(context, getString(R.string.toast_recording_deleted), Toast.LENGTH_SHORT).show()
            loadRecordingsForSelectedDate()
        } else {
            Toast.makeText(context, getString(R.string.toast_recording_delete_failed), Toast.LENGTH_SHORT).show()
        }
    }

    private fun confirmBatchDelete() {
        val selected = recordingAdapter.getSelectedRecordings()
        if (selected.isEmpty()) return

        MaterialAlertDialogBuilder(requireContext(), R.style.Theme_Overdrive_M3_Dialog)
            .setTitle(resources.getQuantityString(R.plurals.delete_recordings_title, selected.size, selected.size))
            .setMessage(resources.getQuantityString(R.plurals.delete_recordings_message, selected.size, selected.size))
            .setNegativeButton(getString(R.string.action_cancel), null)
            .setPositiveButton(getString(R.string.dialog_delete)) { _, _ ->
                batchDeleteRecordings(selected)
            }
            .show()
    }

    private fun batchDeleteRecordings(recordings: List<RecordingFile>) {
        if (scanExecutor.isShutdown) return

        scanExecutor.submit {
            var deleted = 0
            var failed = 0

            for (recording in recordings) {
                if (RecordingScanner.deleteRecording(recording)) {
                    deleted++
                } else {
                    failed++
                }
            }

            activity?.runOnUiThread {
                if (isAdded) {
                    val msg = if (failed > 0) {
                        getString(R.string.toast_batch_delete_partial, deleted, failed)
                    } else {
                        resources.getQuantityString(R.plurals.recordings_deleted_count, deleted, deleted)
                    }
                    Toast.makeText(context, msg, Toast.LENGTH_SHORT).show()
                    exitSelectMode()
                    loadRecordingsForSelectedDate()
                }
            }
        }
    }

    private fun exitSelectMode() {
        recordingAdapter.exitSelectMode()
        selectToolbar?.visibility = View.GONE
    }

    override fun onResume() {
        super.onResume()
        RecordingScanner.invalidateCache()
        loadRecordingsForSelectedDate()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        // Lifecycle-safe: dismiss any open sheet & clear decoration ref so
        // the GC can collect the fragment cleanly.
        filterSheet?.dismiss()
        filterSheet = null
        sectionHeaderDecoration?.let { recyclerRecordings.removeItemDecoration(it) }
        sectionHeaderDecoration = null
        // shutdownNow so a stuck disk walk doesn't hold the fragment alive.
        scanExecutor.shutdownNow()
    }
}
