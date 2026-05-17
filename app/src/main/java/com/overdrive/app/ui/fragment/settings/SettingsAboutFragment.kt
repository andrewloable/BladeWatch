package com.overdrive.app.ui.fragment.settings

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.overdrive.app.BuildConfig
import com.overdrive.app.R
import com.overdrive.app.ui.MainActivity

/**
 * Settings → About pane.
 *
 * Renders identity (brand, version, build), MIT license + GitHub source
 * deep-links, and the "Check for updates" action. Version is pulled from
 * [BuildConfig.VERSION_NAME] at runtime.
 */
class SettingsAboutFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = inflater.inflate(R.layout.fragment_settings_about, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        view.findViewById<TextView>(R.id.tvAboutVersion).text = BuildConfig.VERSION_NAME
        view.findViewById<TextView>(R.id.tvAboutBuild).text = BuildConfig.APPLICATION_ID

        view.findViewById<View>(R.id.cardCheckUpdate).setOnClickListener {
            (activity as? MainActivity)?.invokeCheckForUpdates()
        }

        view.findViewById<View>(R.id.cardLicense).setOnClickListener {
            openExternal(getString(R.string.settings_about_license_url))
        }

        view.findViewById<View>(R.id.cardSource).setOnClickListener {
            openExternal(getString(R.string.settings_about_source_url))
        }

        // Tiered support actions — free → social → monetary.
        view.findViewById<View>(R.id.cardStar).setOnClickListener {
            openExternal(getString(R.string.settings_about_star_url))
        }

        view.findViewById<View>(R.id.cardShare).setOnClickListener {
            shareOverdrive()
        }

        view.findViewById<View>(R.id.cardSupport).setOnClickListener {
            openExternal(getString(R.string.settings_about_support_kofi_url))
        }
    }

    /** Fire an Android share-chooser with a prefilled message + repo link. */
    private fun shareOverdrive() {
        val ctx = context ?: return
        try {
            val send = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, getString(R.string.settings_about_support_share_message))
            }
            val chooser = Intent.createChooser(
                send,
                getString(R.string.settings_about_support_share_chooser)
            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            ctx.startActivity(chooser)
        } catch (e: Exception) {
            Toast.makeText(ctx, getString(R.string.settings_about_support_share_message), Toast.LENGTH_LONG).show()
        }
    }

    /** Open a URL in the system browser. Falls back to a Toast if no
     *  browser is installed (rare on the head unit but possible). */
    private fun openExternal(url: String) {
        val ctx = context ?: return
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            ctx.startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(ctx, url, Toast.LENGTH_LONG).show()
        }
    }
}
