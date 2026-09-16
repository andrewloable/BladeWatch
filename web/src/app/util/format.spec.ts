import { describe, expect, it } from 'vitest';

import { formatBytes, formatMb } from './format';

/**
 * Size formatting was previously a pair of `SettingsComponent` methods, reachable only through
 * Angular's DI and therefore untested. It is exactly the shape of code where a `<` should have
 * been `<=`: nothing looks wrong until a value lands precisely on a 1024 boundary, and the
 * symptom is a storage figure that reads "1024.0 KB" instead of "1.0 MB".
 *
 * The emphasis is on those boundaries and on the inputs that should never produce something
 * alarming on a settings screen.
 */
describe('formatBytes', () => {
  it('reports raw bytes below a kibibyte', () => {
    expect(formatBytes(1)).toBe('1 B');
    expect(formatBytes(512)).toBe('512 B');
    expect(formatBytes(1023)).toBe('1023 B');
  });

  it('promotes at each 1024 boundary, not 1000', () => {
    expect(formatBytes(1024), 'exactly 1 KiB must promote').toBe('1.0 KB');
    expect(formatBytes(1024 ** 2), 'exactly 1 MiB must promote').toBe('1.0 MB');
    expect(formatBytes(1024 ** 3), 'exactly 1 GiB must promote').toBe('1.00 GB');
  });

  it('stays in the lower unit just below each boundary', () => {
    expect(formatBytes(1024 ** 2 - 1)).toContain('KB');
    expect(formatBytes(1024 ** 3 - 1)).toContain('MB');
  });

  it('uses two decimals for gigabytes and one below', () => {
    expect(formatBytes(1536)).toBe('1.5 KB');
    expect(formatBytes(1.5 * 1024 ** 3)).toBe('1.50 GB');
  });

  /**
   * These reach the UI straight from an RPC. A settings screen reading "NaN GB" or
   * "-1 B" is worse than one reading "0 B", because it looks like a fault in the car.
   */
  it('renders unusable input as zero rather than something alarming', () => {
    expect(formatBytes(0)).toBe('0 B');
    expect(formatBytes(-1)).toBe('0 B');
    expect(formatBytes(-(1024 ** 3))).toBe('0 B');
    expect(formatBytes(Number.NaN)).toBe('0 B');
  });

  /** Storage RPCs return 64-bit sizes, so bigint has to work, including past 2^53. */
  it('accepts bigint from the storage RPCs', () => {
    expect(formatBytes(1024n)).toBe('1.0 KB');
    expect(formatBytes(0n)).toBe('0 B');
    expect(formatBytes(2n * 1024n ** 3n)).toBe('2.00 GB');
  });
});

describe('formatMb', () => {
  it('keeps megabytes below a gibibyte', () => {
    expect(formatMb(1)).toBe('1 MB');
    expect(formatMb(500)).toBe('500 MB');
    expect(formatMb(1023)).toBe('1023 MB');
  });

  /** The slider setting is in MB; "4096 MB" reads worse than "4.0 GB". */
  it('promotes at exactly 1024 MB', () => {
    expect(formatMb(1024)).toBe('1.0 GB');
    expect(formatMb(4096)).toBe('4.0 GB');
    expect(formatMb(1536)).toBe('1.5 GB');
  });

  it('handles zero without promoting', () => {
    expect(formatMb(0)).toBe('0 MB');
  });
});
