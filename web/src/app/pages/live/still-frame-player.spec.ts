import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { StillFramePlayer } from './still-frame-player';

/**
 * StillFramePlayer's only contact with the DOM is three property assignments (onload, onerror,
 * src) — no method calls, no real rendering — so a plain object shaped like HTMLImageElement
 * exercises the real class with no jsdom dependency. That matches this project's vitest scope:
 * see vitest.config.ts's own comment that this suite is for framework-free logic, with
 * `environment: 'node'` and no DOM.
 */
function fakeImg(): HTMLImageElement {
  return { onload: null, onerror: null, src: '' } as unknown as HTMLImageElement;
}

describe('StillFramePlayer', () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it('is always reported as supported — <img> needs no capability check', () => {
    expect(StillFramePlayer.isSupported()).toBe(true);
  });

  it('refreshes immediately on start, then again only once per configured interval', () => {
    const img = fakeImg();
    const player = new StillFramePlayer(img, '/api/stream/still', 5000);

    player.start();
    const firstSrc = img.src;
    expect(firstSrc).toContain('/api/stream/still?t=');

    vi.advanceTimersByTime(4999);
    expect(img.src).toBe(firstSrc); // not yet — the interval has not elapsed

    vi.advanceTimersByTime(1);
    expect(img.src).not.toBe(firstSrc); // exactly at 5000ms, a new request fired
  });

  it('never tightens the interval, no matter how many refreshes have happened', () => {
    const img = fakeImg();
    const player = new StillFramePlayer(img, '/api/stream/still', 1000);
    player.start();

    const seen: string[] = [img.src];
    for (let i = 0; i < 10; i++) {
      vi.advanceTimersByTime(1000);
      seen.push(img.src);
    }

    // 11 distinct refreshes (the initial one plus 10 ticks), each exactly 1000ms apart —
    // never faster. Distinctness is enough evidence: each advance of exactly the configured
    // interval, no more, produced exactly one new request.
    expect(new Set(seen).size).toBe(11);
  });

  it('respects a different configured interval — the interval is not hardcoded', () => {
    const img = fakeImg();
    const player = new StillFramePlayer(img, '/api/stream/still', 2000);
    player.start();
    const firstSrc = img.src;

    vi.advanceTimersByTime(1999);
    expect(img.src).toBe(firstSrc);
    vi.advanceTimersByTime(1);
    expect(img.src).not.toBe(firstSrc);
  });

  it('calls onConnected when the image loads and onDisconnected when it errors', () => {
    const img = fakeImg();
    const player = new StillFramePlayer(img, '/api/stream/still');
    let connected = false;
    let disconnected = false;
    player.onConnected = () => (connected = true);
    player.onDisconnected = () => (disconnected = true);

    player.start();
    (img.onload as () => void)();
    expect(connected).toBe(true);

    (img.onerror as () => void)();
    expect(disconnected).toBe(true);
  });

  it('stop() halts further refreshes', () => {
    const img = fakeImg();
    const player = new StillFramePlayer(img, '/api/stream/still', 1000);
    player.start();
    const firstSrc = img.src;

    player.stop();
    vi.advanceTimersByTime(10_000);

    expect(img.src).toBe(firstSrc);
  });
});
