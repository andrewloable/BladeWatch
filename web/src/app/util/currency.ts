import isoCatalog from '../../assets/iso4217.json';

/**
 * Currency display and the ISO 4217 code catalogue.
 *
 * **No symbol table is shipped.** Symbols, their placement, the spacing around them and the
 * number of decimal digits all vary by currency and by locale — JPY has no minor unit, many
 * European locales put the symbol after the amount. `Intl.NumberFormat` already carries ICU's
 * rules for all of it, so this delegates rather than reimplementing a subset badly.
 *
 * The catalogue is a generated asset (`tools/gen-currencies.mjs`), imported at BUILD time.
 * `Intl.supportedValuesOf` is deliberately NOT used at runtime: it is ES2022 and the head
 * unit's Android 10 WebView cannot be relied on to have it.
 */

/** Fallback when nothing is configured. Matches the in-car UI and the daemon. */
export const DEFAULT_CURRENCY = 'USD';

/** The ISO 4217 codes offered by the picker. */
export const CURRENCY_CODES: readonly string[] = isoCatalog.codes;

/**
 * Whether a value has the shape of an ISO 4217 code: exactly three ASCII letters.
 *
 * The same structural rule the daemon applies in `TripConfig.setCurrency`, and deliberately a
 * SHAPE test rather than a catalogue lookup — a well-formed code ICU does not recognise still
 * formats sensibly, and the check stays synchronous and cheap.
 */
export function isIsoCodeShaped(value: string): boolean {
  return /^[A-Za-z]{3}$/.test(value);
}

/**
 * The options a picker must offer, given the currently-stored `current` value.
 *
 * **The current value is always present.** A `<select>` whose value matches no `<option>`
 * renders with nothing selected, so an owner whose config predates the picker — holding a
 * bare symbol like `$`, or a label like `kr` — would open settings and see a currency that is
 * not what is actually stored. Less violent than the Flutter equivalent, which asserts
 * outright, but the same class of bug and the same fix.
 *
 * A legacy value is prepended rather than appended so it is visible without scrolling 162
 * entries, and it drops out of the list as soon as the owner picks a real code.
 */
export function optionsFor(
  current: string,
  catalogue: readonly string[],
): readonly string[] {
  const trimmed = (current ?? '').trim();
  if (!trimmed || catalogue.includes(trimmed)) return catalogue;
  return [trimmed, ...catalogue];
}

/**
 * Format an amount for display.
 *
 * An ISO-shaped code goes through ICU, so JPY shows no decimals and EUR follows the locale's
 * placement. Anything else — a bare symbol like `$`, or a label like `kr` from a config
 * predating the picker — renders exactly as it always did: the stored string, a space, then
 * the amount to two decimals. Historical trips must not change appearance just because the
 * settings screen grew a picker.
 *
 * Returns an empty string when there is nothing to show, so callers test one condition
 * rather than duplicating the empty/zero logic.
 */
export function formatMoney(
  amount: number,
  currency: string | null | undefined,
  locale?: string,
): string {
  const code = (currency ?? '').trim();
  if (!code) return '';

  if (!isIsoCodeShaped(code)) {
    // Legacy free text — preserve the original rendering.
    return `${code} ${amount.toFixed(2)}`;
  }

  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: code.toUpperCase(),
    }).format(amount);
  } catch {
    // ICU refused the code for this locale. Degrade to the legacy shape rather than
    // showing the user nothing.
    return `${code.toUpperCase()} ${amount.toFixed(2)}`;
  }
}
