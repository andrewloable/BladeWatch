import { describe, expect, it } from 'vitest';

import {
  CURRENCY_CODES,
  DEFAULT_CURRENCY,
  formatMoney,
  isIsoCodeShaped,
  optionsFor,
} from './currency';

/**
 * BladeWatch-9uu6: currency display in the web UI.
 *
 * This mirrors `flutter_ui/test/util/currency_test.dart` deliberately. The two front-ends
 * implement the same rules against different platform APIs (`Intl.NumberFormat` here,
 * `NumberFormat.simpleCurrency` there), so the rules have to be pinned on both sides — a
 * divergence would show the same trip a different way depending on which screen you opened.
 */
describe('isIsoCodeShaped', () => {
  it('accepts exactly three ASCII letters, either case', () => {
    expect(isIsoCodeShaped('USD')).toBe(true);
    expect(isIsoCodeShaped('php')).toBe(true);
    expect(isIsoCodeShaped('eUr')).toBe(true);
  });

  it('rejects anything that is not three letters', () => {
    for (const v of ['', '$', 'kr', 'Rp', 'USDX', 'US1', 'US ', '€']) {
      expect(isIsoCodeShaped(v), `should reject "${v}"`).toBe(false);
    }
  });
});

describe('formatMoney — ISO codes go through ICU', () => {
  it('renders a symbol rather than the code', () => {
    const usd = formatMoney(12.34, 'USD', 'en-US');
    expect(usd).toContain('12.34');
    expect(usd).toContain('$');
  });

  /**
   * THE case that fails under naive concatenation: JPY has no minor unit, so a correct
   * formatter shows no decimal places at all.
   */
  it('drops the minor unit for a zero-decimal currency', () => {
    const jpy = formatMoney(1234, 'JPY', 'en-US');
    expect(jpy, 'JPY has no minor unit; ".00" means the formatter was bypassed')
      .not.toContain('.00');
    expect(jpy).toContain('1,234');
  });

  it('accepts a lower case code', () => {
    expect(formatMoney(5, 'usd', 'en-US')).toBe(formatMoney(5, 'USD', 'en-US'));
  });

  it('still renders the amount for an unrecognised but well formed code', () => {
    const out = formatMoney(9.5, 'XYZ', 'en-US');
    expect(out).toContain('9.5');
  });
});

describe('formatMoney — legacy values render exactly as before', () => {
  /** The pre-picker rendering, reproduced independently so a production change is caught. */
  const legacyRender = (amount: number, currency: string) =>
    `${currency} ${amount.toFixed(2)}`;

  it('keeps a bare symbol rendering unchanged', () => {
    for (const symbol of ['$', '€', '£', '₹', '¥']) {
      expect(
        formatMoney(12.3, symbol),
        `historical trips priced in "${symbol}" must not change appearance`,
      ).toBe(legacyRender(12.3, symbol));
    }
  });

  it('does not mistake a lower case label for a code', () => {
    expect(formatMoney(12.3, 'kr')).toBe(legacyRender(12.3, 'kr'));
    expect(formatMoney(12.3, 'Rp')).toBe(legacyRender(12.3, 'Rp'));
  });
});

describe('formatMoney — nothing to show', () => {
  it('returns empty for null, undefined and blank', () => {
    expect(formatMoney(12, null)).toBe('');
    expect(formatMoney(12, undefined)).toBe('');
    expect(formatMoney(12, '   ')).toBe('');
  });
});

describe('optionsFor — the select must always show what is stored', () => {
  const catalogue = ['EUR', 'GBP', 'JPY', 'PHP', 'USD'];

  it('offers a catalogue code exactly once', () => {
    const opts = optionsFor('USD', catalogue);
    expect(opts.filter((c) => c === 'USD')).toHaveLength(1);
    expect(opts).toEqual(catalogue);
  });

  /**
   * A `<select>` whose value matches no `<option>` renders with nothing selected, so an owner
   * with a legacy config would see a currency that is not what is stored.
   */
  it('offers a legacy value absent from the catalogue', () => {
    for (const legacy of ['$', 'kr', 'Rp', '₹']) {
      const opts = optionsFor(legacy, catalogue);
      expect(opts.filter((c) => c === legacy), `"${legacy}" must be offered`).toHaveLength(1);
      expect(opts[0], 'prepended so it is visible without scrolling').toBe(legacy);
      expect(opts).toHaveLength(catalogue.length + 1);
    }
  });

  it('keeps every catalogue entry alongside a legacy value', () => {
    const opts = optionsFor('$', catalogue);
    for (const c of catalogue) expect(opts).toContain(c);
  });

  it('does not add a blank entry when nothing is stored', () => {
    expect(optionsFor('', catalogue)).toEqual(catalogue);
    expect(optionsFor('   ', catalogue)).toEqual(catalogue);
  });
});

describe('the generated catalogue', () => {
  it('carries the full ISO 4217 set, sorted', () => {
    expect(CURRENCY_CODES.length).toBeGreaterThan(100);
    expect([...CURRENCY_CODES]).toEqual([...CURRENCY_CODES].sort());
  });

  it('includes the default and common currencies', () => {
    for (const c of [DEFAULT_CURRENCY, 'EUR', 'GBP', 'JPY', 'PHP']) {
      expect(CURRENCY_CODES).toContain(c);
    }
  });

  /**
   * Parity with the Flutter copy is enforced at build time by validateCurrencyCatalog; this
   * pins that the web side is reading the generated file rather than a hand-typed list.
   */
  it('is the generated artifact, not a hand-maintained list', () => {
    expect(CURRENCY_CODES).toContain('SGD');
    expect(CURRENCY_CODES).toContain('ZAR');
  });
});
