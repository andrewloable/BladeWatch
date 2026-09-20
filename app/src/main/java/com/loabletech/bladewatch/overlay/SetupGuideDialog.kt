package net.bladewatch.app.overlay

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView

import androidx.appcompat.app.AlertDialog

import com.google.android.material.dialog.MaterialAlertDialogBuilder

import net.bladewatch.app.BuildConfig
import net.bladewatch.app.R

/**
 * First-launch and post-update setup guide.
 *
 * Two guided steps:
 *   1. Disable BYD auto-start restriction (head unit kills background apps)
 *   2. Allow "Display over other apps" for the status overlay
 *
 * Re-show policy: the dialog re-appears every time PackageInfo.lastUpdateTime
 * advances past the stored marker. That covers first install, in-app update,
 * adb sideload, and any other replace path. BYD wipes its autostart whitelist
 * on every install, so the user MUST be reminded to re-enable it.
 */
object SetupGuideDialog {

    private const val TAG = "SetupGuideDialog"
    private const val PREFS_NAME = "bladewatch_setup"
    private const val KEY_LAST_SEEN_INSTALL_TIME = "last_seen_install_time"

    /**
     * Show the setup guide if the app's last install/update time has advanced
     * past the stored marker. Returns true if the dialog was shown.
     */
    @JvmStatic
    fun showIfNeeded(context: Context): Boolean {
        val currentInstallTime = getCurrentInstallTime(context)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastSeen = prefs.getLong(KEY_LAST_SEEN_INSTALL_TIME, 0L)

        if (currentInstallTime > 0 && currentInstallTime <= lastSeen) {
            return false
        }

        val isUpdate = lastSeen > 0L
        show(context, isUpdate)
        return true
    }

    /**
     * Show the setup guide. Called with no [isUpdate] it force-shows the first-install
     * variant (e.g. from a settings entry).
     *
     * @param isUpdate when true, the dialog shows a "Updated to vX" banner so
     *                 the user understands why it reappeared.
     */
    @JvmStatic
    @JvmOverloads
    fun show(context: Context, isUpdate: Boolean = false) {
        val view = LayoutInflater.from(context).inflate(R.layout.dialog_setup_guide, null)

        // Version banner — only when re-showing after an update, not on first install.
        val tvVersionBanner: TextView? = view.findViewById(R.id.tvVersionBanner)
        if (tvVersionBanner != null) {
            if (isUpdate) {
                tvVersionBanner.text =
                    context.getString(R.string.setup_version_banner, BuildConfig.VERSION_NAME)
                tvVersionBanner.visibility = View.VISIBLE
            } else {
                tvVersionBanner.visibility = View.GONE
            }
        }

        // Step 1: Language. Always shown as "complete" because Auto is a valid
        // selection out of the box; the row exists so users can opt in to a
        // specific language before they hit Done.
        // BladeWatch-81g9.2: language now belongs to the Flutter UI, which owns every
        // in-car string. The native LanguagePickerDialog went with the rest of the
        // native UI, so this row opens the Flutter app instead of a picker this APK no
        // longer has. Steps 2 and 3 below stay here because they are device-permission
        // flows only this package can drive.
        val btnLanguage: TextView? = view.findViewById(R.id.btnOpenLanguage)
        btnLanguage?.setOnClickListener { openFlutterUi(context) }

        // Step 2: Auto-start restriction
        val btnAutoStart: TextView = view.findViewById(R.id.btnOpenAutoStart)
        btnAutoStart.setOnClickListener { openAutoStartSettings(context) }

        // Step 3: Overlay permission
        val btnOverlay: TextView = view.findViewById(R.id.btnOpenOverlay)
        val stepOverlayCheck: View = view.findViewById(R.id.ivOverlayCheck)

        if (Settings.canDrawOverlays(context)) {
            stepOverlayCheck.visibility = View.VISIBLE
            btnOverlay.text = context.getString(R.string.setup_overlay_already_granted)
            btnOverlay.isEnabled = false
        }

        btnOverlay.setOnClickListener {
            try {
                context.startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:" + context.packageName)
                    )
                )
            } catch (e: Exception) {
                try {
                    context.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
                } catch (e2: Exception) {
                    context.startActivity(Intent(Settings.ACTION_SETTINGS))
                }
            }
        }

        val dialog: AlertDialog =
            MaterialAlertDialogBuilder(context, R.style.Theme_BladeWatch_M3_Dialog)
                .setView(view)
                .setCancelable(true)
                .create()

        // "Don't show again" — record current install time so the dialog stays
        // suppressed until PackageInfo.lastUpdateTime advances (next install
        // or update). BYD wipes the autostart whitelist on every install, so
        // the marker naturally invalidates and the dialog reappears post-update.
        view.findViewById<View>(R.id.btnDone).setOnClickListener {
            markCurrentInstallSeen(context)
            StatusOverlayService.startIfPermitted(context)
            dialog.dismiss()
        }

        // "Remind me later" — soft nag: do NOT update the seen marker, so the
        // dialog reappears on next launch. Autostart is load-bearing; a single
        // accidental dismiss shouldn't permanently silence the reminder.
        view.findViewById<View>(R.id.btnSkip).setOnClickListener { dialog.dismiss() }

        dialog.show()
    }

    /**
     * Open the Flutter in-car UI, where the language picker lives after
     * BladeWatch-81g9.2. Silent no-op if that APK is absent — the setup guide must not
     * crash on a device that only has the daemon host.
     */
    private fun openFlutterUi(context: Context) {
        try {
            val i = context.packageManager.getLaunchIntentForPackage("net.bladewatch.flutter")
            if (i != null) context.startActivity(i)
        } catch (e: Exception) {
            Log.w(TAG, "Could not open the Flutter UI: " + e.message)
        }
    }

    /**
     * Open the BYD autostart-management activity directly. Falls back through:
     *   1. com.byd.appstartmanagement/.frame.AppStartManagement (canonical deep link)
     *   2. Default launcher intent for com.byd.appstartmanagement
     *   3. ACTION_APPLICATION_DETAILS_SETTINGS for BladeWatch (legacy fallback)
     *   4. ACTION_APPLICATION_SETTINGS / ACTION_SETTINGS
     */
    private fun openAutoStartSettings(context: Context) {
        // 1) Canonical BYD deep link.
        try {
            val direct = Intent()
            direct.component = ComponentName(
                "com.byd.appstartmanagement",
                "com.byd.appstartmanagement.frame.AppStartManagement"
            )
            direct.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(direct)
            return
        } catch (e: Exception) {
            Log.w(TAG, "BYD AppStartManagement deep link failed: " + e.message)
        }

        // 2) Launch the BYD app via its default activity.
        try {
            val launch =
                context.packageManager.getLaunchIntentForPackage("com.byd.appstartmanagement")
            if (launch != null) {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launch)
                return
            }
        } catch (e: Exception) {
            Log.w(TAG, "BYD AppStartManagement launch intent failed: " + e.message)
        }

        // 3) Generic app-info page (BYD ROMs that lack appstartmanagement still
        //    expose an "auto-start" toggle inside the app-info page).
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:" + context.packageName)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            return
        } catch (e: Exception) {
            Log.w(TAG, "ACTION_APPLICATION_DETAILS_SETTINGS failed: " + e.message)
        }

        // 4) Last resort.
        try {
            context.startActivity(Intent(Settings.ACTION_APPLICATION_SETTINGS))
        } catch (e: Exception) {
            Log.w(
                TAG,
                "ACTION_APPLICATION_SETTINGS failed, trying ACTION_SETTINGS: " + e.message
            )
            try {
                context.startActivity(Intent(Settings.ACTION_SETTINGS))
            } catch (e2: Exception) {
                Log.w(TAG, "All autostart settings navigation fallbacks failed: " + e2.message)
            }
        }
    }

    private fun getCurrentInstallTime(context: Context): Long = try {
        context.packageManager.getPackageInfo(context.packageName, 0).lastUpdateTime
    } catch (e: Exception) {
        Log.w(TAG, "Failed to get package install time: " + e.message)
        0L
    }

    private fun markCurrentInstallSeen(context: Context) {
        val t = getCurrentInstallTime(context)
        if (t <= 0L) return
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_LAST_SEEN_INSTALL_TIME, t)
            .apply()
    }

    /** Reset the seen marker (testing / re-show from settings). */
    @JvmStatic
    fun reset(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putLong(KEY_LAST_SEEN_INSTALL_TIME, 0L)
            .apply()
    }
}
