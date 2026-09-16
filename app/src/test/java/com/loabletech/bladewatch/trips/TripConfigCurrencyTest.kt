package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-9uu6.2: how the daemon stores the currency.
 *
 * The stored value used to be free text — both UIs offered an 8-character box, and the result
 * was inconsistent by construction: both defaulted to the CODE "USD" while `TripRecord.currency`
 * was documented as a SYMBOL. The pickers now offer ISO 4217 codes, so the daemon normalises
 * anything code-SHAPED to upper case.
 *
 * **The daemon deliberately does not carry the 162-code list.** Its job is to reject garbage,
 * not to be the ISO authority: the picker is what constrains the choice, and a structural rule
 * (exactly three letters) is complete for ISO 4217 without a table to keep in sync. An
 * unrecognised-but-well-formed code costs nothing — the UIs fall back to prefix rendering when
 * ICU does not know it.
 *
 * **Legacy values must keep working.** A config already holding "$" belongs to an owner with
 * trips priced in it. Those are stored unchanged, so nothing starts rendering blank.
 */
class TripConfigCurrencyTest {

    private fun cfg() = TripConfig()

    // ── ISO codes ──

    @Test
    fun `an iso code is stored as given`() {
        val c = cfg()
        c.setCurrency("USD")
        assertEquals("USD", c.getCurrency())
    }

    /** Case is normalised so "php" and "PHP" cannot become two different stored values. */
    @Test
    fun `a lower case code is normalised to upper case`() {
        val c = cfg()
        c.setCurrency("php")
        assertEquals("PHP", c.getCurrency())

        val mixed = cfg()
        mixed.setCurrency("eUr")
        assertEquals("EUR", mixed.getCurrency())
    }

    /**
     * A well-formed code the daemon does not recognise is still stored. The daemon is not the
     * ISO authority, and the render path falls back to prefix display for anything ICU cannot
     * format — so this costs nothing and avoids a list to keep in sync.
     */
    @Test
    fun `an unrecognised but well formed code is accepted`() {
        val c = cfg()
        c.setCurrency("XYZ")
        assertEquals("XYZ", c.getCurrency())
    }

    // ── legacy free text ──

    /**
     * THE compatibility case. An owner whose config predates the picker has a symbol stored and
     * trips priced in it. Storing it unchanged means their costs keep rendering exactly as they
     * always have.
     */
    @Test
    fun `a legacy symbol is preserved unchanged`() {
        for (symbol in listOf("$", "€", "£", "₹", "¥")) {
            val c = cfg()
            c.setCurrency(symbol)
            assertEquals("legacy symbol $symbol must survive", symbol, c.getCurrency())
        }
    }

    /**
     * Legacy labels that contain lower-case letters but are NOT three-letter codes must not be
     * upper-cased. "kr" is how a krona is written and "Rp" a rupiah; mangling them to "KR" and
     * "RP" would change what an existing owner sees against every trip they have ever taken.
     *
     * This is the case that separates "exactly three letters" from a loose length check — a
     * `length <= 3` rule passes every other test in this class (measured) because upper-casing
     * a symbol like "$" is a no-op.
     */
    @Test
    fun `a legacy lower case label is not treated as a code`() {
        for (label in listOf("kr", "Rp", "zł", "R$")) {
            val c = cfg()
            c.setCurrency(label)
            assertEquals("legacy label $label must not be upper-cased", label, c.getCurrency())
        }
    }

    // ── rejection ──

    @Test
    fun `null and empty clear the currency`() {
        val c = cfg()
        c.setCurrency("USD")
        c.setCurrency(null)
        assertEquals("", c.getCurrency())

        c.setCurrency("USD")
        c.setCurrency("")
        assertEquals("", c.getCurrency())
    }

    /** Angle brackets stay rejected — this value is interpolated into UI and log strings. */
    @Test
    fun `angle brackets are still rejected`() {
        for (bad in listOf("<b>", "a<b", "US>", "<script>")) {
            val c = cfg()
            c.setCurrency(bad)
            assertEquals("must reject $bad", "", c.getCurrency())
        }
    }

    @Test
    fun `an over long value is still rejected`() {
        val c = cfg()
        c.setCurrency("TOOLONGVALUE")
        assertEquals("", c.getCurrency())
    }

    /** The settings UIs read the value back from this projection. */
    @Test
    fun `the json projection carries the stored code`() {
        val c = cfg()
        c.setCurrency("jpy")
        assertEquals("JPY", c.toJson().getString("currency"))
    }
}
