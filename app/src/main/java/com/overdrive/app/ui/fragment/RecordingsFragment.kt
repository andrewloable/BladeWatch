package com.overdrive.app.ui.fragment

import android.content.res.Configuration
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.format.Formatter
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.commit
import androidx.navigation.fragment.findNavController
import com.google.android.material.button.MaterialButton
import com.google.android.material.button.MaterialButtonToggleGroup
import com.overdrive.app.R
import com.overdrive.app.ui.model.RecordingFile
import com.overdrive.app.ui.util.RecordingScanner
import java.io.File
import java.lang.ref.WeakReference
import java.util.Calendar
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Recordings page — single native two-pane surface.
 *
 * Top header: title + counts subtitle ("X today · Y total · Z GB") + M3
 * segmented Dashcam | Surveillance whose labels gain a per-segment count
 * suffix at runtime, plus a tonal "Settings" trailing button that
 * deep-links to the matching settings page (recording vs surveillance)
 * based on the active segment.
 *
 * Body: hosts RecordingLibraryFragment and drives its source filter so
 * the same list infra serves both segments without duplicate code.
 *
 * Counts are scanned on a single-thread executor and posted back to the
 * UI via a main-Looper Handler. The post is lifecycle-safe via a weak
 * view reference and is cleared on [onDestroyView].
 */
class RecordingsFragment : Fragment() {

    private var libraryFragment: RecordingLibraryFragment? = null
    private var currentSource: Source = Source.DASHCAM

    /** Single-thread executor for filesystem scans. Recreated per view. */
    private var metricsExecutor: ExecutorService? = null

    /** Main-thread handler for posting scan results back to the UI. */
    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * Pending UI posts so onDestroyView can cancel any in-flight scan
     * results before the view is gone. Touched from both the metrics
     * executor (add) and the main thread (remove + iteration), so all
     * mutations are guarded by `synchronized(pendingPosts)`.
     */
    private val pendingPosts = mutableListOf<Runnable>()

    enum class Source { DASHCAM, SURVEILLANCE }

    private val isLandscape: Boolean
        get() = resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = inflater.inflate(R.layout.fragment_recordings, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Restore the segment selection across rotation.
        currentSource = savedInstanceState?.getString(KEY_SOURCE)
            ?.let { runCatching { Source.valueOf(it) }.getOrNull() }
            ?: Source.DASHCAM

        metricsExecutor = Executors.newSingleThreadExecutor { r ->
            Thread(r, "RecordingsMetrics").apply { isDaemon = true }
        }

        attachLibraryFragment()
        setupSegmentedControl(view)
        setupSettingsAction(view)
        refreshCounts()
    }

    override fun onResume() {
        super.onResume()
        // Refresh counts every time the user returns to this page so the
        // header reflects any new captures since the last visit.
        refreshCounts()
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putString(KEY_SOURCE, currentSource.name)
    }

    override fun onDestroyView() {
        // Clear any pending UI posts and shut down the scan executor.
        synchronized(pendingPosts) {
            pendingPosts.forEach { mainHandler.removeCallbacks(it) }
            pendingPosts.clear()
        }
        metricsExecutor?.shutdownNow()
        metricsExecutor = null
        super.onDestroyView()
    }

    private fun attachLibraryFragment() {
        val existing = childFragmentManager
            .findFragmentById(R.id.libraryContainer) as? RecordingLibraryFragment
        if (existing != null) {
            libraryFragment = existing
        } else {
            // Use the embedded factory so the library hides its own filter
            // chip strip — we drive filtering from the segmented control above.
            val frag = RecordingLibraryFragment.newInstanceEmbedded()
            childFragmentManager.commit {
                replace(R.id.libraryContainer, frag)
            }
            libraryFragment = frag
        }
        // Apply the current source filter once the child has bound its views.
        libraryFragment?.let {
            applySourceFilter(it)
            // Landscape: route taps into the inline preview pane.
            // Portrait: leave the override null so the library falls through
            //           to its default global-nav full-screen launch.
            it.onPlayRecording = if (isLandscape) {
                { recording -> showInlinePreview(recording) }
            } else {
                null
            }
        }
    }

    /**
     * Replace the right-pane preview placeholder with an inline
     * VideoPlayerFragment for the given recording. Uses a soft fade
     * (300ms in / 200ms out) for a non-jarring swap between recordings.
     *
     * Only called on landscape — guarded by [isLandscape] in
     * [attachLibraryFragment]. The target container only exists in
     * `layout-land/fragment_recordings.xml`, so this is also a structural
     * safeguard against accidental portrait invocation.
     */
    private fun showInlinePreview(recording: RecordingFile) {
        // Defensive: container only exists in the landscape layout. If the
        // fragment was somehow recreated in portrait while the override was
        // still cached, fall back to global-nav launch instead of crashing.
        val view = view ?: return
        if (view.findViewById<View>(R.id.previewContainer) == null) return

        val player = VideoPlayerFragment().apply {
            arguments = Bundle().apply {
                putString(VideoPlayerFragment.ARG_VIDEO_PATH, recording.path)
                putString(VideoPlayerFragment.ARG_VIDEO_TITLE, recording.name)
                putBoolean(VideoPlayerFragment.ARG_INLINE, true)
            }
        }
        childFragmentManager.commit {
            setCustomAnimations(R.anim.fade_in, R.anim.fade_out)
            replace(R.id.previewContainer, player, TAG_INLINE_PLAYER)
        }
    }

    private fun setupSegmentedControl(view: View) {
        val group = view.findViewById<MaterialButtonToggleGroup>(R.id.segmentedSource)
        val dashcam = view.findViewById<MaterialButton>(R.id.segmentDashcam)
        val surveillance = view.findViewById<MaterialButton>(R.id.segmentSurveillance)

        // Initial check state without triggering listener.
        when (currentSource) {
            Source.DASHCAM -> group.check(R.id.segmentDashcam)
            Source.SURVEILLANCE -> group.check(R.id.segmentSurveillance)
        }

        group.addOnButtonCheckedListener { _, checkedId, isChecked ->
            if (!isChecked) return@addOnButtonCheckedListener
            currentSource = when (checkedId) {
                R.id.segmentSurveillance -> Source.SURVEILLANCE
                else -> Source.DASHCAM
            }
            libraryFragment?.let { applySourceFilter(it) }
        }
    }

    private fun applySourceFilter(library: RecordingLibraryFragment) {
        val filter = when (currentSource) {
            Source.DASHCAM -> RecordingLibraryFragment.RecordingFilter.NORMAL
            Source.SURVEILLANCE -> RecordingLibraryFragment.RecordingFilter.SENTRY
        }
        library.setSourceFilter(filter)
    }

    private fun setupSettingsAction(view: View) {
        view.findViewById<MaterialButton>(R.id.btnRecordingsSettings)?.setOnClickListener {
            val target = when (currentSource) {
                Source.DASHCAM -> R.id.recordingSettingsWebFragment
                Source.SURVEILLANCE -> R.id.surveillanceSettingsWebFragment
            }
            findNavController().navigate(target)
        }
    }

    /**
     * Walk both recording directories on the metrics executor, then post
     * the totals back to the UI. Lifecycle-safe: the executor is shut
     * down in onDestroyView, and the UI post bails if the view is gone.
     */
    private fun refreshCounts() {
        val ctx = context ?: return
        val executor = metricsExecutor ?: return
        val viewRef = WeakReference(view)

        executor.execute {
            val today0 = startOfTodayMillis()
            val dashcamStats = scanDirectory(RecordingScanner.getRecordingsDir(ctx), today0)
            val surveillanceStats = scanDirectory(RecordingScanner.getSentryEventsDir(ctx), today0)

            val totalCount = dashcamStats.total + surveillanceStats.total
            val totalToday = dashcamStats.today + surveillanceStats.today
            val totalBytes = dashcamStats.bytes + surveillanceStats.bytes

            val post = object : Runnable {
                override fun run() {
                    synchronized(pendingPosts) { pendingPosts.remove(this) }
                    val v = viewRef.get() ?: return
                    val activeCtx = v.context ?: return
                    val sizeText = Formatter.formatShortFileSize(activeCtx, totalBytes)

                    v.findViewById<TextView>(R.id.tvRecordingsSummary)?.text =
                        activeCtx.getString(
                            R.string.recordings_summary_format,
                            totalToday,
                            totalCount,
                            sizeText
                        )
                    v.findViewById<MaterialButton>(R.id.segmentDashcam)?.text =
                        activeCtx.getString(
                            R.string.recordings_segment_dashcam_count,
                            dashcamStats.total
                        )
                    v.findViewById<MaterialButton>(R.id.segmentSurveillance)?.text =
                        activeCtx.getString(
                            R.string.recordings_segment_surveillance_count,
                            surveillanceStats.total
                        )
                }
            }
            synchronized(pendingPosts) { pendingPosts.add(post) }
            mainHandler.post(post)
        }
    }

    /**
     * Aggregate stats for a recording directory: total .mp4 count,
     * count of files modified today, and summed byte size.
     * Quiet on missing directories (returns zero stats).
     */
    private fun scanDirectory(dir: File, startOfTodayMillis: Long): DirStats {
        if (!dir.exists() || !dir.isDirectory) return DirStats(0, 0, 0L)
        var total = 0
        var today = 0
        var bytes = 0L
        val files = dir.listFiles() ?: return DirStats(0, 0, 0L)
        for (f in files) {
            if (!f.isFile) continue
            if (!f.name.endsWith(".mp4", ignoreCase = true)) continue
            total++
            bytes += f.length()
            if (f.lastModified() >= startOfTodayMillis) today++
        }
        return DirStats(total, today, bytes)
    }

    private fun startOfTodayMillis(): Long {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return cal.timeInMillis
    }

    private data class DirStats(val total: Int, val today: Int, val bytes: Long)

    companion object {
        private const val KEY_SOURCE = "recordings_source"
        private const val TAG_INLINE_PLAYER = "inline_player"
    }
}
