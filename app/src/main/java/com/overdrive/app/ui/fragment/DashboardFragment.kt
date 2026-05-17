package com.overdrive.app.ui.fragment

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.text.format.Formatter
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.Observer
import androidx.navigation.fragment.findNavController
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
import com.google.android.material.chip.Chip
import com.google.android.material.chip.ChipGroup
import com.overdrive.app.R
import com.overdrive.app.auth.AuthManager
import com.overdrive.app.client.CameraDaemonClient
import com.overdrive.app.ui.dashboard.DashboardInsight
import com.overdrive.app.ui.dashboard.DashboardInsightProvider
import com.overdrive.app.ui.model.DaemonStatus
import com.overdrive.app.ui.model.DaemonType
import com.overdrive.app.ui.util.QrCodeGenerator
import com.overdrive.app.ui.util.RecordingScanner
import com.overdrive.app.ui.viewmodel.DaemonsViewModel
import com.overdrive.app.ui.viewmodel.MainViewModel
import com.overdrive.app.ui.viewmodel.RecordingViewModel
import com.overdrive.app.util.DeviceIdGenerator
import java.io.File
import java.util.Calendar
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * SOTA Dashboard.
 *
 * Layout (top to bottom):
 *   - Hero card: time-of-day greeting + system summary subtitle.
 *   - Metric grid: Recordings · Storage · Remote · Services.
 *   - Connect card: QR + tunnel chips + access code.
 *   - Quick actions row: Live · Recordings · Settings.
 */
class DashboardFragment : Fragment() {

    private val mainViewModel: MainViewModel by activityViewModels()
    private val daemonsViewModel: DaemonsViewModel by activityViewModels()
    private val recordingViewModel: RecordingViewModel by activityViewModels()

    // Hero
    private lateinit var heroGreeting: TextView
    private lateinit var heroSubtitle: TextView

    // Metric tiles
    private lateinit var metricRecordings: MaterialCardView
    private lateinit var metricRecordingsValue: TextView
    private lateinit var metricStorage: MaterialCardView
    private lateinit var metricStorageValue: TextView
    private lateinit var metricTunnel: MaterialCardView
    private lateinit var metricTunnelValue: TextView
    private lateinit var tunnelStateDot: View
    private lateinit var cardDaemons: MaterialCardView
    private lateinit var tvDaemonsStatus: TextView

    // Connect card
    private lateinit var ivQrCode: ImageView
    private lateinit var tvQrPlaceholder: TextView
    private lateinit var tvUrl: TextView
    private lateinit var tvDeviceId: TextView
    private lateinit var chipGroupTunnels: ChipGroup
    private var selectedTunnel: DaemonType? = null

    // Auth
    private lateinit var tvDeviceToken: TextView
    private lateinit var btnToggleToken: ImageView
    private lateinit var btnCopyToken: ImageView
    private lateinit var btnRegenerateToken: MaterialButton
    private var isTokenVisible = false

    // Quick actions
    private lateinit var quickLive: MaterialButton
    private lateinit var quickRecordings: MaterialButton
    private lateinit var quickSettings: MaterialButton

    // Background work for storage / recording-count tiles. Single thread is enough
    // — both probes are just a directory walk, and serializing them keeps disk I/O
    // out of the UI thread without contending with itself.
    private val mainHandler = Handler(Looper.getMainLooper())
    private var metricsExecutor: ExecutorService? = null

    // Latest values cached so the recording-state observer (which fires on its
    // own cadence) can re-render without re-walking the disk.
    @Volatile private var todayClipCount: Int = 0

    // ============== Hero subtitle insights carousel ==============
    //
    // Tesla/Polestar-tier rotating data line. Each insight is computed on a
    // worker thread (DB + filesystem), then posted back to fade through the
    // existing heroSubtitle TextView. We deliberately reuse the existing view
    // — no layout changes — and just animate its text content.
    private var insightsProvider: DashboardInsightProvider? = null
    private var insights: List<DashboardInsight> = emptyList()
    private var insightIndex: Int = 0
    private var rotationPaused: Boolean = false
    private var firstVisitCount: Int = -1
    // Track the running daemon-summary so we can show it as the bottom-of-the-
    // ladder fallback only when no real insights are available.
    private var lastDaemonRunning: Int = 0
    private var lastDaemonTotal: Int = 0

    private val insightRotateRunnable = Runnable { rotateInsight() }
    private val insightResumeRunnable = Runnable {
        rotationPaused = false
        scheduleNextInsight()
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = inflater.inflate(R.layout.fragment_dashboard, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        bindViews(view)
        wireClicks()
        observeViewModels()

        heroGreeting.text = greetingForTime()
        tvDeviceId.text = DeviceIdGenerator.generateDeviceId(requireContext())
        loadAuthState()

        // First paint of the metric tiles. onResume will refresh on every return.
        refreshMetricsTiles()

        // Insights carousel — initialize provider once; bump visit counter so
        // the welcome-on-first-install insight is exclusive to visit #0.
        if (insightsProvider == null) {
            val provider = DashboardInsightProvider(requireContext().applicationContext)
            insightsProvider = provider
            firstVisitCount = provider.recordDashboardVisit()
        }
        wireSubtitleTouchPause()
    }

    override fun onResume() {
        super.onResume()
        // Cheap-but-not-free disk walk: refresh on every resume so the storage
        // and today's-clip-count numbers update after the user records, deletes,
        // or sentry events fire while the dashboard wasn't on screen.
        refreshMetricsTiles()
        // Always rebuild the insight list on resume — data may have changed
        // while we were backgrounded (new clips, finished charging session,
        // SOC delta from a parking session that ended off-screen, etc.).
        rotationPaused = false
        rebuildInsightsAsync()
    }

    override fun onPause() {
        super.onPause()
        cancelInsightCallbacks()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        cancelInsightCallbacks()
        metricsExecutor?.shutdownNow()
        metricsExecutor = null
    }

    private fun bindViews(view: View) {
        heroGreeting = view.findViewById(R.id.heroGreeting)
        heroSubtitle = view.findViewById(R.id.heroSubtitle)

        metricRecordings = view.findViewById(R.id.metricRecordings)
        metricRecordingsValue = view.findViewById(R.id.metricRecordingsValue)
        metricStorage = view.findViewById(R.id.metricStorage)
        metricStorageValue = view.findViewById(R.id.metricStorageValue)
        metricTunnel = view.findViewById(R.id.metricTunnel)
        metricTunnelValue = view.findViewById(R.id.metricTunnelValue)
        tunnelStateDot = view.findViewById(R.id.tunnelStateDot)
        cardDaemons = view.findViewById(R.id.cardDaemons)
        tvDaemonsStatus = view.findViewById(R.id.tvDaemonsStatus)

        ivQrCode = view.findViewById(R.id.ivQrCode)
        tvQrPlaceholder = view.findViewById(R.id.tvQrPlaceholder)
        tvUrl = view.findViewById(R.id.tvUrl)
        tvDeviceId = view.findViewById(R.id.tvDeviceId)
        chipGroupTunnels = view.findViewById(R.id.chipGroupTunnels)

        tvDeviceToken = view.findViewById(R.id.tvDeviceToken)
        btnToggleToken = view.findViewById(R.id.btnToggleToken)
        btnCopyToken = view.findViewById(R.id.btnCopyToken)
        btnRegenerateToken = view.findViewById(R.id.btnRegenerateToken)

        quickLive = view.findViewById(R.id.quickLive)
        quickRecordings = view.findViewById(R.id.cardRecording)
        quickSettings = view.findViewById(R.id.quickSettings)
    }

    private fun wireClicks() {
        // Tile taps deep-link to the matching destination.
        metricRecordings.setOnClickListener {
            findNavController().navigate(R.id.recordingsFragment)
        }
        metricStorage.setOnClickListener {
            findNavController().navigate(R.id.recordingsFragment)
        }
        metricTunnel.setOnClickListener {
            findNavController().navigate(R.id.daemonsFragment)
        }
        cardDaemons.setOnClickListener {
            findNavController().navigate(R.id.daemonsFragment)
        }
        quickLive.setOnClickListener {
            findNavController().navigate(R.id.liveViewFragment)
        }
        quickRecordings.setOnClickListener {
            findNavController().navigate(R.id.recordingsFragment)
        }
        quickSettings.setOnClickListener {
            findNavController().navigate(R.id.settingsFragment)
        }

        btnToggleToken.setOnClickListener { toggleTokenVisibility() }
        btnCopyToken.setOnClickListener { copyTokenToClipboard() }
        btnRegenerateToken.setOnClickListener { showRegenerateConfirmation() }
    }

    private fun observeViewModels() {
        // Daemon health drives the hero subtitle, the services tile, and chip rebuild.
        daemonsViewModel.daemonStates.observe(viewLifecycleOwner) { states ->
            val running = states.values.count { it.status == DaemonStatus.RUNNING }
            val total = states.size
            tvDaemonsStatus.text = getString(R.string.dashboard_daemons_running, running, total)
            updateHeroSubtitle(running, total)
            rebuildTunnelChips()
        }

        // Tunnel URL → tile state + chip refresh.
        val rebuild = Observer<String?> { _ ->
            rebuildTunnelChips()
            updateTunnelTile()
        }
        daemonsViewModel.cloudflaredController.tunnelUrl.observe(viewLifecycleOwner, rebuild)
        daemonsViewModel.zrokController.tunnelUrl.observe(viewLifecycleOwner, rebuild)
        daemonsViewModel.tailscaleController.tunnelUrl.observe(viewLifecycleOwner, rebuild)

        // Recording state → live "● <count>" prefix on the recordings tile.
        // The numeric count itself comes from refreshMetricsTiles() below; this
        // observer just toggles the red-dot prefix without re-walking the disk.
        recordingViewModel.isRecording.observe(viewLifecycleOwner) { _ ->
            renderRecordingsValue()
        }
    }

    // ============== Metric tiles (storage + today's recordings) ==============

    /**
     * Walks the recordings directory on a background thread, then posts both
     * the storage-used string and today's clip count back to the UI.
     */
    private fun refreshMetricsTiles() {
        val ctx = context?.applicationContext ?: return
        val executor = metricsExecutor ?: Executors.newSingleThreadExecutor()
            .also { metricsExecutor = it }

        executor.execute {
            var clipCountToday = 0
            var usedBytes = 0L
            var freeBytes = 0L
            try {
                val recordingsDir = RecordingScanner.getRecordingsDir(ctx)
                val sentryDir = RecordingScanner.getSentryEventsDir(ctx)

                // Total used = every .mp4 across both dirs (matches what the
                // diagnostics Storage tile already shows).
                usedBytes += sumMp4Sizes(recordingsDir)
                usedBytes += sumMp4Sizes(sentryDir)

                // Today's clips: count files modified between local-time
                // midnight and now, across both dirs.
                val startOfDayMs = Calendar.getInstance().apply {
                    set(Calendar.HOUR_OF_DAY, 0)
                    set(Calendar.MINUTE, 0)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }.timeInMillis
                clipCountToday += countMp4SinceMtime(recordingsDir, startOfDayMs)
                clipCountToday += countMp4SinceMtime(sentryDir, startOfDayMs)

                // Free bytes on whichever filesystem actually backs the
                // recordings dir (internal vs. SD).
                val statFsTarget = when {
                    recordingsDir.exists() -> recordingsDir
                    sentryDir.exists() -> sentryDir
                    else -> null
                }
                if (statFsTarget != null) {
                    try {
                        val stat = StatFs(statFsTarget.absolutePath)
                        freeBytes = stat.availableBytes
                    } catch (_: Throwable) {
                        freeBytes = 0L
                    }
                }
            } catch (_: Throwable) {
                // Leave defaults — still post so the tile updates off "—".
            }

            val usedHuman = Formatter.formatShortFileSize(ctx, usedBytes)
            val freeHuman = Formatter.formatShortFileSize(ctx, freeBytes)

            mainHandler.post {
                if (!isAdded || view == null) return@post
                metricStorageValue.text = usedHuman
                // Free-space subtitle is informational; surface it via
                // contentDescription so screen readers / long-press still
                // expose it without changing the layout.
                metricStorageValue.contentDescription =
                    "$usedHuman used · $freeHuman free"

                todayClipCount = clipCountToday
                renderRecordingsValue()
            }
        }
    }

    /**
     * Renders the recordings tile value from the cached clip count + the
     * current recording state. Pulled into a helper so both the metric
     * refresh and the isRecording observer can call it without duplicating
     * the format logic.
     */
    private fun renderRecordingsValue() {
        if (!::metricRecordingsValue.isInitialized) return
        val isRec = recordingViewModel.isRecording.value == true
        metricRecordingsValue.text = if (isRec) {
            getString(R.string.dashboard_recordings_value_live, todayClipCount)
        } else {
            todayClipCount.toString()
        }
    }

    private fun sumMp4Sizes(dir: File): Long {
        if (!dir.exists() || !dir.isDirectory || !dir.canRead()) return 0L
        val files = dir.listFiles() ?: return 0L
        var sum = 0L
        for (f in files) {
            if (f.isFile && f.name.endsWith(".mp4")) sum += f.length()
        }
        return sum
    }

    private fun countMp4SinceMtime(dir: File, sinceMs: Long): Int {
        if (!dir.exists() || !dir.isDirectory || !dir.canRead()) return 0
        val files = dir.listFiles() ?: return 0
        var n = 0
        for (f in files) {
            if (f.isFile && f.name.endsWith(".mp4") && f.length() > 0L &&
                f.lastModified() >= sinceMs
            ) n++
        }
        return n
    }

    private fun greetingForTime(): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        val keyRes = when (hour) {
            in 5..11 -> R.string.dashboard_greeting_morning
            in 12..16 -> R.string.dashboard_greeting_afternoon
            in 17..21 -> R.string.dashboard_greeting_evening
            else -> R.string.dashboard_greeting_night
        }
        return getString(keyRes)
    }

    private fun updateHeroSubtitle(running: Int, total: Int) {
        // Cache the daemon summary so the carousel can fall through to it when
        // no real insights have data. This keeps the legacy "X of Y services
        // online" line as the safety net the user has always seen.
        lastDaemonRunning = running
        lastDaemonTotal = total
        // If insights are already populated, the carousel owns the subtitle.
        // Otherwise show the daemon-summary fallback immediately so the line
        // doesn't read stale text while we wait for the first build to finish.
        if (insights.isEmpty()) {
            heroSubtitle.text = daemonFallbackText(running, total)
        }
    }

    private fun daemonFallbackText(running: Int, total: Int): CharSequence = when {
        total == 0 -> getString(R.string.dashboard_subtitle_no_tunnel)
        running == total -> getString(R.string.dashboard_subtitle_all_systems)
        else -> getString(R.string.dashboard_subtitle_some_offline, running, total)
    }

    // ============== Insights carousel ==============

    /**
     * Re-build the insight list off the main thread. Posts the result back to
     * the UI which restarts the rotation from index 0.
     */
    private fun rebuildInsightsAsync() {
        val provider = insightsProvider ?: return
        val executor = metricsExecutor ?: Executors.newSingleThreadExecutor()
            .also { metricsExecutor = it }
        val visitCount = if (firstVisitCount >= 0) firstVisitCount else 0
        executor.execute {
            val built = try {
                provider.build(visitCount)
            } catch (_: Throwable) {
                emptyList()
            }
            mainHandler.post {
                if (!isAdded || view == null) return@post
                applyInsightList(built)
            }
        }
    }

    private fun applyInsightList(built: List<DashboardInsight>) {
        cancelInsightCallbacks()
        insights = built
        insightIndex = 0
        if (built.isEmpty()) {
            // Static fallback — no rotation. The daemon-summary observer keeps
            // this line accurate as services flip online/offline.
            heroSubtitle.text = daemonFallbackText(lastDaemonRunning, lastDaemonTotal)
            return
        }
        // Show the first insight immediately (no fade — we want it instant on
        // dashboard open / resume). Subsequent transitions cross-fade.
        heroSubtitle.alpha = 0.78f
        heroSubtitle.text = built[0].text
        if (built.size > 1) {
            scheduleNextInsight()
        }
    }

    private fun scheduleNextInsight() {
        if (rotationPaused) return
        if (insights.size <= 1) return
        mainHandler.removeCallbacks(insightRotateRunnable)
        mainHandler.postDelayed(insightRotateRunnable, INSIGHT_HOLD_MS)
    }

    private fun rotateInsight() {
        if (!isAdded || view == null) return
        if (rotationPaused) return
        if (insights.size <= 1) return
        val nextIdx = (insightIndex + 1) % insights.size
        val next = insights[nextIdx]
        // 250ms cross-fade: fade current to alpha=0, swap text, fade back to
        // the resting 0.78 the layout uses for the subtitle. M3 standard
        // easing is the AccelerateDecelerateInterpolator default on animate().
        heroSubtitle.animate()
            .alpha(0f)
            .setDuration(INSIGHT_FADE_MS)
            .withEndAction {
                if (!isAdded || view == null) return@withEndAction
                heroSubtitle.text = next.text
                heroSubtitle.animate()
                    .alpha(0.78f)
                    .setDuration(INSIGHT_FADE_MS)
                    .start()
                insightIndex = nextIdx
                scheduleNextInsight()
            }
            .start()
    }

    private fun cancelInsightCallbacks() {
        mainHandler.removeCallbacks(insightRotateRunnable)
        mainHandler.removeCallbacks(insightResumeRunnable)
        // Cancel any in-flight fade so onPause / onDestroyView don't leave a
        // dangling animation that targets a TextView whose host is gone.
        if (::heroSubtitle.isInitialized) {
            heroSubtitle.animate().cancel()
            heroSubtitle.alpha = 0.78f
        }
    }

    /**
     * Long-press on the subtitle pauses the rotation; release resumes it after
     * a 5 s grace period so the user has time to actually read the line they
     * paused on. We use ACTION_DOWN / ACTION_UP (not OnLongClick) so the
     * pause kicks in immediately, not after the system long-press timeout.
     */
    @android.annotation.SuppressLint("ClickableViewAccessibility")
    private fun wireSubtitleTouchPause() {
        if (!::heroSubtitle.isInitialized) return
        heroSubtitle.setOnTouchListener { _, ev ->
            when (ev.actionMasked) {
                android.view.MotionEvent.ACTION_DOWN -> {
                    rotationPaused = true
                    mainHandler.removeCallbacks(insightRotateRunnable)
                    mainHandler.removeCallbacks(insightResumeRunnable)
                }
                android.view.MotionEvent.ACTION_UP,
                android.view.MotionEvent.ACTION_CANCEL -> {
                    mainHandler.removeCallbacks(insightResumeRunnable)
                    mainHandler.postDelayed(insightResumeRunnable, INSIGHT_RESUME_AFTER_MS)
                }
            }
            // Don't consume — let click-through still work for accessibility.
            false
        }
    }

    private fun updateTunnelTile() {
        val anyUrl = listOf(
            daemonsViewModel.cloudflaredController.tunnelUrl.value,
            daemonsViewModel.zrokController.tunnelUrl.value,
            daemonsViewModel.tailscaleController.tunnelUrl.value
        ).any { !it.isNullOrEmpty() }

        val states = daemonsViewModel.daemonStates.value
        val anyStarting = states?.values?.any {
            (it.type == DaemonType.CLOUDFLARED_TUNNEL ||
                it.type == DaemonType.ZROK_TUNNEL ||
                it.type == DaemonType.TAILSCALE_TUNNEL) &&
                it.status == DaemonStatus.STARTING
        } == true

        when {
            anyUrl -> {
                metricTunnelValue.text = getString(R.string.dashboard_tunnel_online)
                tunnelStateDot.setBackgroundResource(R.drawable.status_dot_online)
            }
            anyStarting -> {
                metricTunnelValue.text = getString(R.string.dashboard_tunnel_connecting)
                tunnelStateDot.setBackgroundResource(R.drawable.status_dot_offline)
            }
            else -> {
                metricTunnelValue.text = getString(R.string.dashboard_tunnel_offline)
                tunnelStateDot.setBackgroundResource(R.drawable.status_dot_offline)
            }
        }
    }

    // ============== Tunnel chips + QR ==============

    private fun rebuildTunnelChips() {
        val available = collectAvailableTunnels()

        if (available.isEmpty()) {
            chipGroupTunnels.removeAllViews()
            chipGroupTunnels.visibility = View.GONE
            selectedTunnel = null
            renderQr(null)
            return
        }

        val newSelection = selectedTunnel?.takeIf { prev -> available.any { it.first == prev } }
            ?: available.first().first
        selectedTunnel = newSelection

        val currentTags = (0 until chipGroupTunnels.childCount)
            .map { (chipGroupTunnels.getChildAt(it) as Chip).tag as DaemonType }
        val newTags = available.map { it.first }
        if (currentTags != newTags) {
            chipGroupTunnels.setOnCheckedStateChangeListener(null)
            chipGroupTunnels.removeAllViews()
            available.forEach { (type, _) ->
                val chip = Chip(requireContext()).apply {
                    id = View.generateViewId()
                    tag = type
                    text = labelFor(type)
                    isCheckable = true
                    isCheckedIconVisible = false
                }
                chipGroupTunnels.addView(chip)
            }
            chipGroupTunnels.setOnCheckedStateChangeListener { group, ids ->
                val checkedId = ids.firstOrNull() ?: return@setOnCheckedStateChangeListener
                val chip = group.findViewById<Chip>(checkedId) ?: return@setOnCheckedStateChangeListener
                val type = chip.tag as? DaemonType ?: return@setOnCheckedStateChangeListener
                if (type != selectedTunnel) {
                    selectedTunnel = type
                    renderQr(urlFor(type))
                }
            }
        }

        for (i in 0 until chipGroupTunnels.childCount) {
            val chip = chipGroupTunnels.getChildAt(i) as Chip
            chip.isChecked = (chip.tag as DaemonType) == newSelection
        }

        chipGroupTunnels.visibility = if (available.size > 1) View.VISIBLE else View.GONE
        renderQr(urlFor(newSelection))
    }

    private fun collectAvailableTunnels(): List<Pair<DaemonType, String>> {
        val list = mutableListOf<Pair<DaemonType, String>>()
        daemonsViewModel.cloudflaredController.tunnelUrl.value
            ?.takeIf { it.isNotEmpty() }
            ?.let { list.add(DaemonType.CLOUDFLARED_TUNNEL to it) }
        daemonsViewModel.zrokController.tunnelUrl.value
            ?.takeIf { it.isNotEmpty() }
            ?.let { list.add(DaemonType.ZROK_TUNNEL to it) }
        daemonsViewModel.tailscaleController.tunnelUrl.value
            ?.takeIf { it.isNotEmpty() }
            ?.let { list.add(DaemonType.TAILSCALE_TUNNEL to it) }
        return list
    }

    private fun urlFor(type: DaemonType): String? = when (type) {
        DaemonType.CLOUDFLARED_TUNNEL -> daemonsViewModel.cloudflaredController.tunnelUrl.value
        DaemonType.ZROK_TUNNEL -> daemonsViewModel.zrokController.tunnelUrl.value
        DaemonType.TAILSCALE_TUNNEL -> daemonsViewModel.tailscaleController.tunnelUrl.value
        else -> null
    }

    private fun labelFor(type: DaemonType): String = when (type) {
        DaemonType.CLOUDFLARED_TUNNEL -> getString(R.string.tunnel_label_cloudflared)
        DaemonType.ZROK_TUNNEL -> getString(R.string.tunnel_label_zrok)
        DaemonType.TAILSCALE_TUNNEL -> getString(R.string.tunnel_label_tailscale)
        else -> type.displayName
    }

    private fun renderQr(url: String?) {
        if (url.isNullOrEmpty()) {
            showPlaceholder()
            return
        }
        try {
            val qrBitmap = QrCodeGenerator.generate(url, 400)
            if (qrBitmap != null) {
                ivQrCode.setImageBitmap(qrBitmap)
                ivQrCode.visibility = View.VISIBLE
                tvQrPlaceholder.visibility = View.GONE
                tvUrl.text = url
                tvUrl.visibility = View.VISIBLE
            } else {
                showPlaceholder()
            }
        } catch (e: Exception) {
            showPlaceholder()
        }
    }

    private fun showPlaceholder() {
        ivQrCode.setImageDrawable(null)
        ivQrCode.visibility = View.VISIBLE
        tvQrPlaceholder.visibility = View.VISIBLE
        tvQrPlaceholder.text = getTunnelPlaceholderText()
        tvUrl.visibility = View.GONE
    }

    private fun getTunnelPlaceholderText(): String {
        val states = daemonsViewModel.daemonStates.value ?: return getString(R.string.dashboard_no_tunnel)
        val cfState = states[DaemonType.CLOUDFLARED_TUNNEL]
        val zrokState = states[DaemonType.ZROK_TUNNEL]
        val tailscaleState = states[DaemonType.TAILSCALE_TUNNEL]
        return when {
            zrokState?.status == DaemonStatus.STARTING -> getString(R.string.dashboard_starting_zrok)
            cfState?.status == DaemonStatus.STARTING -> getString(R.string.dashboard_starting_cloudflared)
            tailscaleState?.status == DaemonStatus.STARTING -> getString(R.string.dashboard_starting_tailscale)
            zrokState?.status == DaemonStatus.RUNNING -> getString(R.string.dashboard_waiting_url)
            cfState?.status == DaemonStatus.RUNNING -> getString(R.string.dashboard_waiting_url)
            tailscaleState?.status == DaemonStatus.RUNNING -> getString(R.string.dashboard_waiting_url)
            else -> getString(R.string.dashboard_no_tunnel)
        }
    }

    // ============== Auth (access code) ==============

    private fun loadAuthState() {
        try {
            val state = AuthManager.getState()
            if (state != null) {
                updateTokenDisplay(state.secret)
            } else {
                AuthManager.initialize()
                loadAuthState()
            }
        } catch (e: Exception) {
            tvDeviceToken.text = getString(R.string.dashboard_token_masked)
        }
    }

    private fun updateTokenDisplay(secret: String) {
        tvDeviceToken.text = if (isTokenVisible) secret else getString(R.string.dashboard_token_masked)
    }

    private fun toggleTokenVisibility() {
        isTokenVisible = !isTokenVisible
        AuthManager.getState()?.let { updateTokenDisplay(it.secret) }
        btnToggleToken.setImageResource(
            if (isTokenVisible) android.R.drawable.ic_menu_close_clear_cancel
            else android.R.drawable.ic_menu_view
        )
    }

    private fun copyTokenToClipboard() {
        val state = AuthManager.getState() ?: return
        val clipboard = requireContext().getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText(getString(R.string.clip_label_access_code), state.secret)
        clipboard.setPrimaryClip(clip)
        Toast.makeText(requireContext(), getString(R.string.toast_access_code_copied), Toast.LENGTH_SHORT).show()
    }

    private fun showRegenerateConfirmation() {
        com.google.android.material.dialog.MaterialAlertDialogBuilder(requireContext(), R.style.Theme_Overdrive_M3_Dialog)
            .setTitle(getString(R.string.dialog_regenerate_token_title))
            .setMessage(getString(R.string.dialog_regenerate_token_message))
            .setPositiveButton(getString(R.string.dialog_regenerate)) { _, _ -> regenerateToken() }
            .setNegativeButton(getString(R.string.action_cancel), null)
            .show()
    }

    private fun regenerateToken() {
        AuthManager.regenerateToken()
        // Use the lifecycle-managed metricsExecutor (shut down in onDestroyView)
        // instead of a bare Thread that would outlive the fragment and leak
        // its Activity reference. The applicationContext for the Toast also
        // bypasses requireContext()'s detach-aware throw.
        val ctx = context?.applicationContext ?: return
        val executor = metricsExecutor ?: Executors.newSingleThreadExecutor()
            .also { metricsExecutor = it }
        executor.execute {
            val msgRes = try {
                val client = CameraDaemonClient()
                if (client.connect()) {
                    val ok = client.invalidateAuthCacheSync()
                    client.disconnect()
                    if (ok) R.string.toast_token_regenerated_logged_out
                    else R.string.toast_token_regenerated_restart
                } else {
                    R.string.toast_token_regenerated_no_notify
                }
            } catch (_: Exception) {
                R.string.toast_token_regenerated
            }
            // Use the application context for Toast — survives fragment detach
            // and is the recommended pattern for "fire-and-forget" notifications
            // from a background thread.
            mainHandler.post {
                if (isAdded) {
                    Toast.makeText(ctx, ctx.getString(msgRes), Toast.LENGTH_SHORT).show()
                }
            }
        }
        loadAuthState()
    }

    companion object {
        // Hero-subtitle insights carousel timing.
        // 5 s hold matches Tesla / Polestar style; 250 ms cross-fade is M3
        // "duration-medium2" (close enough for a one-line text swap).
        private const val INSIGHT_HOLD_MS = 5_000L
        private const val INSIGHT_FADE_MS = 250L
        private const val INSIGHT_RESUME_AFTER_MS = 5_000L
    }
}
