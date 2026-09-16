import { describe, expect, it } from 'vitest';

import { showFuelSettings } from './drivetrain';

/**
 * The BEV/PHEV rule for the trips settings screen.
 *
 * The case that matters most is the negative one: a BEV owner must not be offered a fuel price
 * or a tank size. A test that only checked "a PHEV sees them" would pass just as happily if the
 * gate were removed altogether.
 */
describe('showFuelSettings', () => {
  it('shows the fuel settings on a PHEV', () => {
    expect(showFuelSettings(true, '0', '0')).toBe(true);
  });

  it('hides them on a BEV with nothing configured', () => {
    expect(showFuelSettings(false, '0', '0')).toBe(false);
    expect(showFuelSettings(false, '0.00', '0.0')).toBe(false);
    expect(showFuelSettings(false, 0, 0)).toBe(false);
  });

  /**
   * The drivetrain probe reads false while the HAL warms up. A configured value is still being
   * APPLIED, so hiding the field holding it would leave the owner unable to clear it from
   * anywhere in the UI.
   */
  it('keeps a configured value visible even when the probe says BEV', () => {
    expect(showFuelSettings(false, '1.85', '0')).toBe(true);
    expect(showFuelSettings(false, '0', '47.5')).toBe(true);
    expect(showFuelSettings(false, 1.85, 0)).toBe(true);
  });

  /** Unusable input is "not configured", never a reason to show the fields. */
  it('treats unparseable or non-positive values as not configured', () => {
    expect(showFuelSettings(false, '', '')).toBe(false);
    expect(showFuelSettings(false, 'abc', 'abc')).toBe(false);
    expect(showFuelSettings(false, null, undefined)).toBe(false);
    expect(showFuelSettings(false, '-1', '-1'), 'negative is not configured').toBe(false);
    expect(showFuelSettings(false, Number.NaN, Number.NaN)).toBe(false);
  });

  /** A PHEV shows them whatever the figures say, including unusable ones. */
  it('a PHEV shows them regardless of the configured values', () => {
    expect(showFuelSettings(true, 'abc', null)).toBe(true);
    expect(showFuelSettings(true, '-1', '-1')).toBe(true);
  });
});
