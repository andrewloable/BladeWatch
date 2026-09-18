/**
 * Still-frame fallback for browsers with neither WebCodecs nor MediaSource H.264 (BladeWatch-
 * y78o.1). Tor Browser on Linux is the documented case that reaches this tier — see
 * mse-player.ts's doc comment for why MSE alone doesn't cover every platform. A periodically
 * refreshed JPEG needs no video decoder at all, so it works in every browser and degrades at
 * low bandwidth instead of never connecting.
 *
 * Deliberately the simplest possible player: a fixed-interval `<img src>` refresh, same-origin
 * so the session cookie authenticates it like any other request — no fetch/blob plumbing
 * needed. No backoff, no reconnect ramp, nothing that ever changes the interval: the issue this
 * exists for requires the refresh rate to never tighten under any condition.
 */
export class StillFramePlayer {
  /** `<img>` works everywhere; this fallback has no capability precondition of its own. */
  static isSupported(): boolean {
    return true;
  }

  private timer: ReturnType<typeof setInterval> | null = null;
  private disposed = false;

  onConnected: (() => void) | null = null;
  onDisconnected: (() => void) | null = null;

  constructor(
    private readonly img: HTMLImageElement,
    private readonly url: string,
    private readonly refreshIntervalMs: number = 5000,
  ) {}

  start(): void {
    if (this.disposed) return;
    this.img.onload = () => this.onConnected?.();
    this.img.onerror = () => this.onDisconnected?.();
    this.refresh();
    this.timer = setInterval(() => this.refresh(), this.refreshIntervalMs);
  }

  private refresh(): void {
    if (this.disposed) return;
    // Cache-bust: browsers cache image responses by URL, and this one must never be served
    // stale from the disk/memory cache once a newer frame exists on the daemon.
    this.img.src = `${this.url}?t=${Date.now()}`;
  }

  stop(): void {
    this.disposed = true;
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }
}
