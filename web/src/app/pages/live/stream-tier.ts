/**
 * Which live-view rendering path to use, in preference order (BladeWatch-y78o.1 adds the third
 * tier). A pure function so the selection logic is testable without Angular's TestBed -- this
 * project has no component-test harness set up (see util/format.spec.ts and friends: every
 * existing spec here tests a plain function, not a component).
 *
 * Feature-detected only -- never derived from the browser's self-reported identity string.
 * Tor Browser deliberately misreports that value, so sniffing it would be both wrong and
 * fragile (BladeWatch-nobf).
 */
export type StreamTier = 'webcodecs' | 'mse' | 'stillframe';

export function selectStreamTier(webCodecsSupported: boolean, mseSupported: boolean): StreamTier {
  if (webCodecsSupported) return 'webcodecs';
  if (mseSupported) return 'mse';
  return 'stillframe';
}
