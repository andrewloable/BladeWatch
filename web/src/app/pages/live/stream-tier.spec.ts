import { describe, expect, it } from 'vitest';

import { selectStreamTier } from './stream-tier';

describe('selectStreamTier', () => {
  it('chooses webcodecs when available, regardless of MSE support', () => {
    expect(selectStreamTier(true, true)).toBe('webcodecs');
    expect(selectStreamTier(true, false)).toBe('webcodecs');
  });

  it('chooses mse when webcodecs is unavailable but MSE H.264 is', () => {
    expect(selectStreamTier(false, true)).toBe('mse');
  });

  it('falls back to the still-frame tier when neither decoder is available', () => {
    expect(selectStreamTier(false, false)).toBe('stillframe');
  });
});
