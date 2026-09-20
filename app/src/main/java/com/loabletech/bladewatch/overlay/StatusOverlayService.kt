package net.bladewatch.app.overlay

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

import androidx.appcompat.app.AppCompatDelegate

import net.bladewatch.app.R
import net.bladewatch.app.client.ConnectClientProvider
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.grpc.v1.GetStatusResponse

import org.json.JSONObject

import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.Socket
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

import kotlin.math.abs

/**
 * Floating status overlay service.
 *
 * Shows a small draggable pill on top of all apps indicating whether
 * configured features are actually running or not.
 *
 * Rules:
 * - Only shows items that are CONFIGURED (recording mode != NONE, trip analytics enabled)
 * - Each item shows a tinted active/inactive icon next to its label
 * - Tapping a not-running item restarts it (it's configured, so it should be running)
 * - Hides entirely if nothing is configured
 * - Gracefully handles missing SYSTEM_ALERT_WINDOW — just stops itself
 */
class StatusOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val running = AtomicBoolean(false)

    // Views
    private var recContainer: LinearLayout? = null
    private var tripContainer: LinearLayout? = null
    private var ivRecIcon: ImageView? = null
    private var ivTripIcon: ImageView? = null
    private var tvRecLabel: TextView? = null
    private var tvTripLabel: TextView? = null

    // State
    @Volatile
    private var configuredMode = "NONE"

    @Volatile
    private var isRecording = false

    @Volatile
    private var tripEnabled = false

    @Volatile
    private var tripActive = false

    @Volatile
    private var daemonReachable = false

    @Volatile
    private var currentGear = "P"

    @Volatile
    private var accOn = false

    // Grace period: don't flicker the overlay on transient poll failures.
    // The daemon may be restarting, the HTTP server may be briefly busy, etc.
    // Only treat the daemon as truly gone after UNREACHABLE_THRESHOLD consecutive failures.
    @Volatile
    private var consecutivePollFailures = 0

    /** Track whether we ever had something to show (so we keep the window during blips) */
    @Volatile
    private var hadContentBefore = false

    // Drag support
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var initialX = 0
    private var initialY = 0
    private var isDragging = false
    private var layoutParams: WindowManager.LayoutParams? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        startOverlayForeground()

        if (!Settings.canDrawOverlays(this)) {
            Log.w(TAG, "SYSTEM_ALERT_WINDOW not granted — stopping")
            stopSelf()
            return START_NOT_STICKY
        }

        // Don't create overlay window yet — wait for first poll to confirm
        // there's something to show. This avoids adding an empty overlay window
        // that can interfere with GPU rendering on BYD head units.
        if (windowManager == null) {
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        }

        // Theme refresh — caller flipped the app's day/night setting.
        // Rebuild the overlay against the new uiMode. rebuildOverlay() also
        // re-fires pollStatus() so the pill repaints; return early so the
        // standard start path doesn't double-poll.
        if (intent != null && ACTION_REFRESH_THEME == intent.action) {
            Log.i(TAG, "ACTION_REFRESH_THEME — rebuilding overlay")
            rebuildOverlay()
            return START_STICKY
        }
        if (!running.get()) {
            startPolling()
        } else {
            // Re-entry while we're already running: MainActivity is asking
            // us to refresh. Cancel any in-flight delayed poll and fire one
            // immediately so a stale "ACC=off, slow poll" loop doesn't keep
            // us hidden for up to POLL_INTERVAL_ACC_OFF_MS.
            handler.removeCallbacksAndMessages(null)
            pollStatus()
        }

        return START_STICKY
    }

    /**
     * Enter the foreground with an explicit service type so the platform
     * treats us as a long-running special-use service. Without passing the
     * type on Android 14+, the system can terminate the process along with
     * the Activity task, which is what makes the pill disappear on app close.
     */
    private fun startOverlayForeground() {
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "startForeground with type failed, falling back: " + e.message)
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        running.set(false)
        handler.removeCallbacksAndMessages(null)
        executor.shutdownNow()
        removeOverlay()
        super.onDestroy()
    }

    /**
     * Re-inflate the overlay when the device configuration changes (light ↔
     * dark, locale, font scale). Without this, the user toggling the app
     * theme leaves the overlay stuck on whatever palette it was created with
     * because the View tree was inflated once and is never re-resolved.
     *
     * We blow the view away and let the next pollStatus()/updateUI()
     * tick rebuild it; that path also re-binds icon tints so the active /
     * inactive states pick up the new status color tokens.
     */
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (overlayView == null) return
        Log.i(TAG, "Configuration changed — rebuilding overlay so theme tokens reapply")
        rebuildOverlay()
    }

    /**
     * Tear down + recreate the overlay so a theme change reaches the
     * resolved drawables and color tokens. Persists current position so
     * the new pill lands where the user last dragged it.
     */
    private fun rebuildOverlay() {
        try {
            persistPosition()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to persist overlay position before rebuild: " + e.message)
        }
        removeOverlay()
        handler.removeCallbacksAndMessages(null)
        pollStatus()
    }

    /** Save the pill's current x/y so it survives recreation, restarts and reboots. */
    private fun persistPosition() {
        val lp = layoutParams ?: return
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putInt(PREF_POS_X, lp.x)
            .putInt(PREF_POS_Y, lp.y)
            .apply()
    }

    /**
     * Build a context whose resources honor the app's day/night override.
     *
     * Plain Service contexts read uiMode straight from the system config,
     * so AppCompatDelegate.setDefaultNightMode(MODE_NIGHT_NO) doesn't reach
     * the overlay — the pill stays dark on a light-themed system. Mapping
     * the AppCompat mode onto Configuration.UI_MODE_NIGHT_* and creating a
     * configuration-context with that override fixes it.
     */
    private fun themedContext(): Context {
        val uiNight = when (AppCompatDelegate.getDefaultNightMode()) {
            AppCompatDelegate.MODE_NIGHT_YES -> Configuration.UI_MODE_NIGHT_YES
            AppCompatDelegate.MODE_NIGHT_NO -> Configuration.UI_MODE_NIGHT_NO
            // Follow-system / unspecified — leave the system's value alone.
            else -> return this
        }
        val cfg = Configuration(resources.configuration)
        cfg.uiMode = (cfg.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or uiNight
        return createConfigurationContext(cfg)
    }

    /**
     * Called when the user swipes the app away from Recents.
     *
     * On many Android builds (including BYD head units running AOSP forks)
     * this triggers the service to be torn down alongside the activity task,
     * which makes the floating overlay disappear. Re-schedule ourselves so
     * the service (and the overlay window) survives the task being cleared.
     *
     * The re-launch uses an AlarmManager one-shot because Android restricts
     * starting foreground services directly from inside onTaskRemoved on
     * newer platform versions.
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(TAG, "onTaskRemoved — scheduling overlay service restart")
        try {
            val restart = Intent(applicationContext, StatusOverlayService::class.java)
            restart.setPackage(packageName)
            val flags = PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
            val pi = PendingIntent.getForegroundService(applicationContext, 1, restart, flags)
            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager?
            if (am != null && pi != null) {
                // 1s out so the current task-removal flow unwinds first.
                am.set(
                    AlarmManager.ELAPSED_REALTIME,
                    SystemClock.elapsedRealtime() + 1000,
                    pi
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to schedule overlay restart: " + e.message)
        }
        super.onTaskRemoved(rootIntent)
    }

    // ==================== OVERLAY ====================

    private fun createOverlay() {
        if (overlayView != null) return // Already created

        // Inflate against a context whose configuration honors the app's
        // chosen day/night setting. A bare Service runs against the system
        // configuration, so AppCompatDelegate.setDefaultNightMode(MODE_NIGHT_NO)
        // wouldn't reach the overlay — the pill would stay dark on a
        // light-themed system because the Service never saw the override.
        // Wrapping with createConfigurationContext gives us a context whose
        // resources resolve light/dark drawables according to the user's
        // explicit choice.
        val view = LayoutInflater.from(themedContext()).inflate(R.layout.overlay_status, null)
        overlayView = view

        val lp = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )
        layoutParams = lp
        lp.gravity = Gravity.TOP or Gravity.START
        // Restore last user-placed position (falls back to defaults on first run)
        val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        lp.x = prefs.getInt(PREF_POS_X, DEFAULT_POS_X)
        lp.y = prefs.getInt(PREF_POS_Y, DEFAULT_POS_Y)

        bindViews(view)
        setupDrag(view)

        try {
            windowManager?.addView(view, lp)
            Log.i(TAG, "Overlay window added")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add overlay: " + e.message)
            overlayView = null
        }
    }

    private fun removeOverlay() {
        val view = overlayView
        if (view != null && windowManager != null) {
            try {
                windowManager?.removeView(view)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to remove overlay view: " + e.message)
            }
            overlayView = null
        }
    }

    private fun bindViews(view: View) {
        val rec: LinearLayout = view.findViewById(R.id.recContainer)
        val trip: LinearLayout = view.findViewById(R.id.tripContainer)
        recContainer = rec
        tripContainer = trip
        ivRecIcon = view.findViewById(R.id.ivRecIcon)
        ivTripIcon = view.findViewById(R.id.ivTripIcon)
        tvRecLabel = view.findViewById(R.id.tvRecLabel)
        tvTripLabel = view.findViewById(R.id.tvTripLabel)

        // Tap on recording item → restart recording if it should be running but isn't
        rec.setOnClickListener {
            if (!isRecording && shouldRecordingBeActive()) {
                restartRecording()
            }
        }

        // Tap on trip item → restart trip detection if not running
        trip.setOnClickListener {
            if (tripEnabled && !tripActive) {
                restartTripDetection()
            }
        }
    }

    private fun setupDrag(view: View) {
        val pill: View = view.findViewById(R.id.pillContainer)
        pill.setOnTouchListener { _, event ->
            val lp = layoutParams ?: return@setOnTouchListener false
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    initialX = lp.x
                    initialY = lp.y
                    isDragging = false
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - initialTouchX
                    val dy = event.rawY - initialTouchY
                    if (abs(dx) > DRAG_THRESHOLD || abs(dy) > DRAG_THRESHOLD) {
                        isDragging = true
                    }
                    if (isDragging) {
                        lp.x = initialX + dx.toInt()
                        lp.y = initialY + dy.toInt()
                        try {
                            windowManager?.updateViewLayout(overlayView, lp)
                        } catch (e: Exception) {
                            Log.w(
                                TAG,
                                "Failed to update overlay layout during drag: " + e.message
                            )
                        }
                    }
                    true
                }

                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        // Let child click handlers fire
                        false
                    } else {
                        // Persist the new position so it survives overlay recreation,
                        // service restarts, and reboots
                        try {
                            persistPosition()
                        } catch (e: Exception) {
                            Log.w(
                                TAG,
                                "Failed to persist overlay drag position: " + e.message
                            )
                        }
                        true
                    }
                }

                else -> false
            }
        }
    }

    // ==================== POLLING ====================

    private fun startPolling() {
        running.set(true)
        pollStatus()
    }

    private fun pollStatus() {
        if (!running.get()) return

        executor.execute {
            try {
                val status = fetchStatus()
                if (status != null) {
                    daemonReachable = true
                    consecutivePollFailures = 0
                    parseStatus(status)
                } else {
                    consecutivePollFailures++
                    if (consecutivePollFailures >= UNREACHABLE_THRESHOLD) {
                        daemonReachable = false
                    }
                    // else: keep daemonReachable as-is (grace period)
                }
                handler.post { updateUI() }
            } catch (e: Exception) {
                consecutivePollFailures++
                if (consecutivePollFailures >= UNREACHABLE_THRESHOLD) {
                    daemonReachable = false
                }
                handler.post { updateUI() }
            }

            if (running.get()) {
                // Always reschedule. Detect ACC by VALUE on each poll, not by
                // edge — single-shot SCREEN_ON suspension was racy because
                // the ACC-on signal propagation (AccSentryDaemon → IPC →
                // RecordingModeManager) lags SCREEN_ON, so the first poll
                // after wake saw accOn=false and stranded us. Slow-poll
                // loopback to the in-process daemon HTTP is negligible.
                val interval = if (accOn) POLL_INTERVAL_MS else POLL_INTERVAL_ACC_OFF_MS
                handler.postDelayed({ pollStatus() }, interval)
            }
        }
    }

    private fun fetchStatus(): GetStatusResponse? = try {
        ConnectClientProvider.fetchStatusSync()
    } catch (e: Exception) {
        Log.w(TAG, "fetchStatus failed: " + e.message)
        null
    }

    private fun parseStatus(status: GetStatusResponse) {
        try {
            if (status.hasRecordingStatus()) {
                val rec = status.recordingStatus
                configuredMode = rec.configuredMode.ifEmpty { "NONE" }
                isRecording = rec.isRecording
                currentGear = rec.gear.ifEmpty { "P" }
                accOn = rec.accOn
            }
            if (status.hasTripStatus()) {
                val trip = status.tripStatus
                tripEnabled = trip.enabled
                tripActive = trip.tripActive
            }
        } catch (e: Exception) {
            Log.w(TAG, "Parse error: " + e.message)
        }
    }

    // ==================== UI ====================

    private fun updateUI() {
        // User-facing visibility toggles. Stored in the unified config file
        // (/data/local/tmp/bladewatch_config.json) rather than SharedPreferences
        // because both the app UID and the shell/daemon UID need to see the
        // same values. Read fresh on every poll so a flip in Settings reflects
        // without a service restart. Defaults to true so existing installs
        // (where the section doesn't exist yet) keep current behavior.
        var cameraOverlayEnabled = true
        var tripOverlayEnabled = true
        try {
            val statusOverlayCfg =
                UnifiedConfigManager.loadConfig().optJSONObject("statusOverlay")
            if (statusOverlayCfg != null) {
                cameraOverlayEnabled = statusOverlayCfg.optBoolean("cameraVisible", true)
                tripOverlayEnabled = statusOverlayCfg.optBoolean("tripVisible", true)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to read statusOverlay prefs: " + e.message)
        }

        val recConfigured = "NONE" != configuredMode && "UNKNOWN" != configuredMode
        val anythingToShow = (recConfigured && cameraOverlayEnabled) ||
            (tripEnabled && tripOverlayEnabled)

        Log.d(
            TAG,
            "updateUI: mode=" + configuredMode + " isRec=" + isRecording +
                " gear=" + currentGear + " acc=" + accOn +
                " tripEnabled=" + tripEnabled + " tripActive=" + tripActive +
                " recConfigured=" + recConfigured +
                " shouldRec=" + (recConfigured && shouldRecordingBeActive()) +
                " pollFails=" + consecutivePollFailures
        )

        // During the grace period (daemon briefly unreachable), keep the overlay
        // visible with last-known state. This prevents the pill from flickering
        // every time the daemon restarts or a single HTTP poll times out.
        if (!daemonReachable) {
            if (hadContentBefore && consecutivePollFailures < UNREACHABLE_THRESHOLD * 2) {
                // Still in grace window — keep overlay as-is, don't touch it.
                // The stale data is better than a disappearing/reappearing pill.
                return
            }
            // Sustained unreachability — hide (but don't destroy) the overlay.
            Log.d(
                TAG,
                "updateUI: daemon unreachable for $consecutivePollFailures polls — hiding overlay"
            )
            overlayView?.visibility = View.GONE
            return
        }

        if (!anythingToShow) {
            // If the user disabled both segments via Settings, fully tear
            // down the overlay window so we don't keep a hidden View
            // attached to WindowManager. A hidden TYPE_APPLICATION_OVERLAY
            // still consumes a surface on BYD head units.
            Log.d(TAG, "updateUI: nothing to show — removing overlay")
            removeOverlay()
            hadContentBefore = false
            return
        }

        // Hide overlay when ACC is off — car is parked, no need to show status.
        // We keep polling (at a slower rate) so we can show it again when ACC turns on.
        if (!accOn) {
            overlayView?.visibility = View.GONE
            return
        }

        // Determine what's visible before creating the window.
        // Proximity guard should stay visible even when idle/armed (waiting for
        // a radar trigger) — hiding it would make users think the feature is off.
        val isProximityMode = "PROXIMITY_GUARD" == configuredMode
        val shouldShowRec = recConfigured && cameraOverlayEnabled &&
            (isRecording || shouldRecordingBeActive() || isProximityMode)
        val shouldShowTrip = tripEnabled && tripOverlayEnabled

        if (!shouldShowRec && !shouldShowTrip) {
            // Configured but conditions don't require display (e.g., drive mode in P)
            overlayView?.visibility = View.GONE
            return
        }

        // After config-merge gating, double-check: if BOTH user segments are
        // toggled off, fully remove the window rather than leaving an empty
        // shell attached. (anythingToShow guarded the entry, but reaching
        // here with both flags off means a partial config state — be safe.)
        if (!cameraOverlayEnabled && !tripOverlayEnabled) {
            removeOverlay()
            return
        }

        hadContentBefore = true

        // We have something to show — create overlay window if not yet created
        createOverlay()
        val view = overlayView ?: return
        val rec = recContainer ?: return
        val trip = tripContainer ?: return

        view.visibility = View.VISIBLE

        // Recording: show only if configured AND user hasn't toggled the
        // camera segment off in Settings → Status overlay.
        if (recConfigured && cameraOverlayEnabled) {
            rec.visibility = View.VISIBLE

            // Determine if recording SHOULD be happening right now given mode + gear + ACC
            val shouldBeRecording = shouldRecordingBeActive()

            if (isRecording) {
                // All good — recording as expected.
                // Proximity mode uses an amber tint + "PROX" label so users can
                // tell at a glance that this is radar-triggered recording,
                // not continuous/drive recording.
                if (isProximityMode) {
                    setRecState(
                        R.drawable.ic_overlay_rec_active,
                        R.string.overlay_prox_label,
                        R.color.status_warning
                    )
                } else {
                    setRecState(
                        R.drawable.ic_overlay_rec_active,
                        R.string.overlay_rec_inactive_label,
                        R.color.status_success
                    )
                }
            } else if (shouldBeRecording) {
                // Problem — should be recording but isn't
                setRecState(
                    R.drawable.ic_overlay_rec_inactive,
                    if (isProximityMode) {
                        R.string.overlay_prox_label
                    } else {
                        R.string.overlay_rec_inactive_label
                    },
                    R.color.status_danger
                )
            } else if (isProximityMode) {
                // Proximity guard is armed but not currently recording (no radar trigger).
                // Show an armed/idle indicator instead of hiding — users want to know
                // the car is being watched even when nothing has triggered yet.
                setRecState(
                    R.drawable.ic_overlay_rec_inactive,
                    R.string.overlay_prox_label,
                    R.color.status_warning
                )
            } else {
                // Not recording, but that's expected (e.g., drive mode in P gear)
                // Hide the recording indicator since conditions don't require it
                rec.visibility = View.GONE
            }
        } else {
            rec.visibility = View.GONE
        }

        // Trip: show only if enabled in config AND user hasn't toggled the
        // trip segment off in Settings → Status overlay.
        if (tripEnabled && tripOverlayEnabled) {
            trip.visibility = View.VISIBLE
            if (tripActive) {
                ivTripIcon?.setImageResource(R.drawable.ic_overlay_trip_active)
                tvTripLabel?.setText(R.string.overlay_trip_inactive_label)
                tvTripLabel?.setTextColor(getColor(R.color.status_success))
            } else {
                ivTripIcon?.setImageResource(R.drawable.ic_overlay_trip_inactive)
                tvTripLabel?.setText(R.string.overlay_trip_inactive_label)
                tvTripLabel?.setTextColor(getColor(R.color.status_danger))
            }
        } else {
            trip.visibility = View.GONE
        }

        // Show/hide separator between items
        val separator: View? = view.findViewById(R.id.separator)
        val recVisible = rec.visibility == View.VISIBLE
        val tripVisible = trip.visibility == View.VISIBLE
        separator?.visibility = if (recVisible && tripVisible) View.VISIBLE else View.GONE
    }

    /** The recording row is one icon + one label + one tint; set all three together. */
    private fun setRecState(iconRes: Int, labelRes: Int, colorRes: Int) {
        ivRecIcon?.setImageResource(iconRes)
        tvRecLabel?.setText(labelRes)
        tvRecLabel?.setTextColor(getColor(colorRes))
    }

    // ==================== RESTART ACTIONS ====================

    /**
     * Determine if recording SHOULD be active right now based on mode, gear, and ACC state.
     *
     * Rules (from RecordingModeManager):
     * - CONTINUOUS: should record whenever ACC is ON
     * - DRIVE_MODE: should record in driving gears (D, R, S, M) when ACC is ON
     * - PROXIMITY_GUARD: should be active in all gears except P when ACC is ON
     */
    private fun shouldRecordingBeActive(): Boolean {
        if (!accOn) return false

        return when (configuredMode) {
            "CONTINUOUS" -> true
            "DRIVE_MODE" -> isDrivingGear(currentGear)
            "PROXIMITY_GUARD" -> "P" != currentGear
            else -> false
        }
    }

    /**
     * Restart recording by re-sending the configured mode via TCP.
     * This just re-triggers what's already configured — no config change.
     */
    private fun restartRecording() {
        executor.execute {
            var socket: Socket? = null
            try {
                val s = Socket("127.0.0.1", 19876)
                socket = s
                s.soTimeout = 3000

                val cmd = JSONObject()
                cmd.put("cmd", "setRecordingMode")
                cmd.put("mode", configuredMode)

                val os = s.getOutputStream()
                os.write((cmd.toString() + "\n").toByteArray())
                os.flush()

                val response =
                    BufferedReader(InputStreamReader(s.getInputStream())).readLine()
                Log.i(TAG, "Restart recording ($configuredMode): $response")
            } catch (e: Exception) {
                Log.e(TAG, "Restart recording failed: " + e.message)
            } finally {
                if (socket != null) {
                    try {
                        socket.close()
                    } catch (ignored: Exception) {
                        Log.w(
                            TAG,
                            "Failed to close socket during cleanup: " + ignored.message
                        )
                    }
                }
            }
        }
    }

    /**
     * Restart trip detection by toggling the config off then on.
     * This re-initializes the TripDetector without changing user settings.
     */
    private fun restartTripDetection() {
        executor.execute {
            try {
                // Toggle off then on to force re-init
                postTripConfig(false)
                Thread.sleep(500)
                postTripConfig(true)
                Log.i(TAG, "Restart trip detection: toggled")
            } catch (e: Exception) {
                Log.e(TAG, "Restart trip failed: " + e.message)
            }
        }
    }

    private fun postTripConfig(enabled: Boolean) {
        try {
            ConnectClientProvider.postTripsConfigSync(enabled)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to post trip config (enabled=$enabled): " + e.message)
        }
    }

    // ==================== NOTIFICATION ====================

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID, "Status Overlay", NotificationManager.IMPORTANCE_LOW
        )
        channel.description = "Recording and trip status overlay"
        channel.setShowBadge(false)
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    /**
     * Where tapping the overlay notification should go.
     *
     * BladeWatch-81g9.1: this used to be
     * `getLaunchIntentForPackage(getPackageName())`. Once Phase 4 removed THIS
     * package's launcher entry that returns **null**, and
     * `PendingIntent.getActivity` with a null Intent throws
     * `NullPointerException` inside `migrateExtraStreamToClipData` — which
     * crashed the whole process from `onStartCommand`, taking the startup
     * bootstrap and the daemon launch down with it. Caught by a real cold-boot test.
     *
     * Now it targets the Flutter UI, which is what the user should actually see, and
     * falls back to this app's bootstrap activity by explicit component so the result is
     * NEVER null. A notification that cannot be built is a dead process, not a dead tap.
     */
    private fun notificationTarget(): Intent {
        packageManager.getLaunchIntentForPackage(FLUTTER_UI_PACKAGE)?.let { return it }
        val fallback = Intent()
        fallback.setClassName(packageName, "net.bladewatch.app.ui.MainActivity")
        fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return fallback
    }

    private fun buildNotification(): Notification {
        val pi = PendingIntent.getActivity(
            this, 0, notificationTarget(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.status_overlay_notif_title))
            .setContentText(getString(R.string.status_overlay_notif_text))
            .setSmallIcon(R.drawable.ic_recording)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    companion object {
        /** The Flutter UI APK — the only package with a launcher entry after Phase 4. */
        private const val FLUTTER_UI_PACKAGE = "net.bladewatch.flutter"

        private const val TAG = "StatusOverlay"
        private const val CHANNEL_ID = "status_overlay"
        private const val NOTIFICATION_ID = 9001
        private const val POLL_INTERVAL_MS = 3000L

        /** Slower polling when ACC is off */
        private const val POLL_INTERVAL_ACC_OFF_MS = 10000L

        // Persisted overlay position
        private const val PREFS_NAME = "status_overlay_prefs"
        private const val PREF_POS_X = "pos_x"
        private const val PREF_POS_Y = "pos_y"
        private const val DEFAULT_POS_X = 20
        private const val DEFAULT_POS_Y = 100

        /** ~9 seconds at 3s poll interval */
        private const val UNREACHABLE_THRESHOLD = 3

        private const val DRAG_THRESHOLD = 10

        const val ACTION_REFRESH_THEME = "net.bladewatch.app.overlay.REFRESH_THEME"

        /**
         * Check if gear is a driving gear (D, R, S, M, N — not P).
         * N is included because BYD Auto Hold reports N while stopped at traffic lights.
         */
        private fun isDrivingGear(gear: String): Boolean =
            "D" == gear || "R" == gear || "S" == gear || "M" == gear || "N" == gear

        @JvmStatic
        fun hasOverlayPermission(context: Context): Boolean {
            val has = Settings.canDrawOverlays(context)
            Log.i(TAG, "hasOverlayPermission: $has")
            return has
        }

        @JvmStatic
        fun startIfPermitted(context: Context): Boolean {
            if (!hasOverlayPermission(context)) {
                Log.w(TAG, "startIfPermitted: NO overlay permission — service not started")
                return false
            }
            Log.i(TAG, "startIfPermitted: permission OK — starting service")
            context.startForegroundService(Intent(context, StatusOverlayService::class.java))
            return true
        }

        @JvmStatic
        fun stop(context: Context) {
            context.stopService(Intent(context, StatusOverlayService::class.java))
        }

        /**
         * Trigger a re-inflation of the overlay so a freshly-changed theme
         * takes effect immediately. AppCompatDelegate.setDefaultNightMode()
         * fires onConfigurationChanged for foreground Activities but NOT for
         * plain Services, so the overlay would otherwise stay on its old
         * palette until the system config changed for unrelated reasons.
         *
         * No-op when overlay permission is missing or the service isn't
         * running — startForegroundService would just respawn an unwanted
         * pill in that case.
         */
        @JvmStatic
        fun refreshTheme(context: Context) {
            if (!hasOverlayPermission(context)) return
            val intent = Intent(context, StatusOverlayService::class.java)
            intent.action = ACTION_REFRESH_THEME
            try {
                context.startService(intent)
            } catch (e: Exception) {
                Log.w(TAG, "refreshTheme failed: " + e.message)
            }
        }
    }
}
