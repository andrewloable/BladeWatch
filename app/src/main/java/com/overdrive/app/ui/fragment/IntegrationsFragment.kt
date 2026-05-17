package com.overdrive.app.ui.fragment

import android.content.Context
import android.os.Bundle
import android.util.TypedValue
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.annotation.AttrRes
import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import androidx.fragment.app.Fragment
import androidx.navigation.fragment.findNavController
import com.overdrive.app.R
import com.overdrive.app.abrp.AbrpTokenConfig
import com.overdrive.app.mqtt.MqttConnectionConfig
import com.overdrive.app.telegram.impl.BotTokenConfig
import org.json.JSONArray
import java.io.File

/**
 * Integrations roll-up: Telegram / ABRP / MQTT cards. Each card navigates to
 * the existing per-integration destination so we don't duplicate any of the
 * native or web settings surfaces.
 *
 * Per-card status row shows token-presence at a glance:
 *   - Telegram → BotTokenConfig#hasToken (encrypted SharedPreferences).
 *   - ABRP     → AbrpTokenConfig#hasToken (encrypted SharedPreferences).
 *   - MQTT     → at least one configured connection in the daemon's JSON store
 *                at /data/local/tmp/mqtt_connections.json. The app process can
 *                read that path even though it can't write to it.
 *
 * Card click handlers are unchanged — the dot+label binding is purely visual.
 */
class IntegrationsFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = inflater.inflate(R.layout.fragment_integrations, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.findViewById<View>(R.id.cardTelegram).setOnClickListener {
            findNavController().navigate(R.id.telegramSettingsFragment)
        }
        view.findViewById<View>(R.id.cardAbrp).setOnClickListener {
            findNavController().navigate(R.id.abrpSettingsFragment)
        }
        view.findViewById<View>(R.id.cardMqtt).setOnClickListener {
            findNavController().navigate(R.id.mqttFragment)
        }
    }

    override fun onResume() {
        super.onResume()
        // Token-presence is a fast SharedPreferences read; the MQTT JSON file
        // is a few KB at most and lives on internal storage. Doing this on the
        // main thread is acceptable for an integrations roll-up.
        refreshAllStatuses()
    }

    private fun refreshAllStatuses() {
        val view = view ?: return
        val ctx = context ?: return

        bindStatus(
            view,
            dotId = R.id.dotTelegram,
            labelId = R.id.tvTelegramStatus,
            configured = isTelegramConfigured(ctx)
        )
        bindStatus(
            view,
            dotId = R.id.dotAbrp,
            labelId = R.id.tvAbrpStatus,
            configured = isAbrpConfigured(ctx)
        )
        bindStatus(
            view,
            dotId = R.id.dotMqtt,
            labelId = R.id.tvMqttStatus,
            configured = isMqttConfigured()
        )
    }

    // ============== Probes ==============

    private fun isTelegramConfigured(ctx: Context): Boolean = try {
        BotTokenConfig(ctx.applicationContext).hasToken()
    } catch (_: Throwable) {
        false
    }

    private fun isAbrpConfigured(ctx: Context): Boolean = try {
        AbrpTokenConfig(ctx.applicationContext).hasToken()
    } catch (_: Throwable) {
        false
    }

    /**
     * MQTT is "configured" when at least one connection in the store has a
     * broker URL + topic populated. We read the store file directly because
     * MqttConnectionStore is owned by the daemon process — there's no app-side
     * singleton to consult. The path is world-readable in practice (created by
     * an ADB shell) so the app process can read it even though it can't write.
     */
    private fun isMqttConfigured(): Boolean = try {
        val file = File(MQTT_CONFIG_PATH)
        if (!file.exists() || !file.canRead() || file.length() <= 0L) {
            false
        } else {
            val text = file.readText(Charsets.UTF_8)
            val arr = JSONArray(text)
            var anyConfigured = false
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                val cfg = MqttConnectionConfig.fromJson(obj)
                if (cfg.isConfigured) {
                    anyConfigured = true
                    break
                }
            }
            anyConfigured
        }
    } catch (_: Throwable) {
        false
    }

    // ============== Binding helpers ==============

    private fun bindStatus(
        root: View,
        dotId: Int,
        labelId: Int,
        configured: Boolean
    ) {
        val dot = root.findViewById<View>(dotId) ?: return
        val label = root.findViewById<TextView>(labelId) ?: return

        @StringRes val labelRes: Int
        @DrawableRes val dotRes: Int
        @AttrRes val labelAttr: Int

        if (configured) {
            labelRes = R.string.integrations_status_configured
            dotRes = R.drawable.status_dot_online
            labelAttr = androidx.appcompat.R.attr.colorPrimary
        } else {
            labelRes = R.string.integrations_status_not_set_up
            dotRes = R.drawable.status_dot_offline
            labelAttr = com.google.android.material.R.attr.colorOnSurfaceVariant
        }

        label.setText(labelRes)
        label.setTextColor(resolveAttrColor(label.context, labelAttr))
        dot.setBackgroundResource(dotRes)
    }

    private fun resolveAttrColor(ctx: Context, @AttrRes attr: Int): Int {
        val tv = TypedValue()
        ctx.theme.resolveAttribute(attr, tv, true)
        return tv.data
    }

    companion object {
        private const val MQTT_CONFIG_PATH = "/data/local/tmp/mqtt_connections.json"
    }
}
