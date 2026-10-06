package net.bladewatch.app.daemon

import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject

/**
 * The owner relay (BladeWatch-a7mu): reach the car from mobile data while it is online through its
 * SIM. Two randomizing carrier NATs cannot hole-punch at all, so the owner runs a blind relay
 * (relay/ in this repo) and gives the car, the relay and every companion the same 12-digit relay
 * key. pear-end derives the relay's keys from it (flutter_pear 0.4.9, `relay.set`); this daemon
 * only hands the key over.
 *
 * The in-car app writes [SECTION] through the ordinary secret IPC (secret_put; this section is
 * deliberately NOT in TcpCommandServer's daemon-only list): [KEY_ENABLED] as the string
 * "true"/"false", because its ConfigChannel only sends strings, and [KEY_KEY] as the bare digits.
 * Off unless both are present and valid -- an owner without a relay connects exactly as before.
 *
 * The key never leaves the secret store except in the one relay.set frame to the worklet: it is
 * not logged, not written to [PearStatus], not put in public config.
 */
object PearRelay {
    const val SECTION = "pear_relay"
    const val KEY_ENABLED = "enabled"
    const val KEY_KEY = "key"

    private val SEPARATORS = Regex("[\\s-]")
    private val TWELVE_ASCII_DIGITS = Regex("^[0-9]{12}$")

    /** [raw] as its bare 12 digits, or null if it is not a relay key. The relay applies the same rule. */
    fun normalize(raw: String?): String? =
        raw?.replace(SEPARATORS, "")?.takeIf { TWELVE_ASCII_DIGITS.matches(it) }

    /** The relay key pear-end should use right now, or null for no relay. */
    fun desiredKey(store: SecretConfigStore): String? =
        if (store.getBoolean(SECTION, KEY_ENABLED, false)) normalize(store.getString(SECTION, KEY_KEY)) else null

    /** pear-end's relay.set params: the key, or an explicit null to stop relaying. */
    fun relaySetParams(key: String?): JSONObject = JSONObject().put("key", key ?: JSONObject.NULL)
}
