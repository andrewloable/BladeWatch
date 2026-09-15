/**
 * MediaSource fallback for browsers with no WebCodecs decoder (BladeWatch-nobf).
 *
 * ## Why this exists
 *
 * `SotaPlayer` decodes the daemon's H.264 with `VideoDecoder` (WebCodecs) and paints a
 * canvas. Firefox only gained WebCodecs in the 130 series, and Tor Browser tracks Firefox
 * ESR — so on the browser BladeWatch's own help dialog tells people to install, the live
 * stream could not play at all, and said so only in the console.
 *
 * MediaSource is the way through. Firefox ships no H.264 decoder of its own (patents); it
 * borrows the platform's, which means H.264-via-MSE works on Android (MediaCodec), macOS
 * (VideoToolbox) and Windows (Media Foundation), and not on Linux without system ffmpeg.
 * CONFIRMED on the owner's Android Tor Browser 2026-09-15: `MSE H.264 ✓`.
 *
 * ## Why a muxer is needed at all
 *
 * The daemon sends raw H.264 Annex-B NAL units over `/ws`. MediaSource does not take those
 * — it takes a container, fragmented MP4. jmuxer (MIT) wraps the NAL units into fMP4 and
 * owns the MediaSource/SourceBuffer plumbing, so this class only has to move bytes from
 * the socket into it.
 *
 * It is `import()`ed lazily, ON PURPOSE. The muxer is dead weight for Chromium, which takes
 * the WebCodecs path, and every kilobyte here crosses a Tor circuit measured at 62-75 KB/s.
 * Vite code-splits the dynamic import so it downloads only when this fallback actually runs.
 * Bundled locally rather than pulled from a CDN — a CDN fetch over Tor is both slow and a
 * privacy leak.
 */
export class MsePlayer {
  /**
   * The daemon's stream rate — `Constants.STREAM_FPS`. jmuxer needs it to assign frame
   * durations; guessing high makes playback drift ahead and stall, guessing low makes it
   * lag further behind real time the longer it runs.
   */
  private static readonly STREAM_FPS = 15;

  private ws: WebSocket | null = null;
  private muxer: any = null;
  private running = false;
  /** Set once teardown has begun, so an in-flight async import cannot resurrect us. */
  private disposed = false;

  onConnected: (() => void) | null = null;
  onDisconnected: (() => void) | null = null;

  constructor(
    private readonly video: HTMLVideoElement,
    private readonly url: string,
  ) {}

  /** Whether this browser can play the stream through MediaSource. */
  static isSupported(): boolean {
    try {
      const ms = (globalThis as any).MediaSource;
      // The exact profile the daemon encodes: H.264 Baseline, Level 3.1.
      return !!ms && ms.isTypeSupported('video/mp4; codecs="avc1.42C01F"');
    } catch {
      return false;
    }
  }

  async start(): Promise<void> {
    if (this.running || this.disposed) return;
    this.running = true;

    const { default: JMuxer } = await import('jmuxer');
    // The await above is a suspension point: stop() may have run while it was in flight.
    if (this.disposed) return;

    this.muxer = new JMuxer({
      node: this.video,
      mode: 'video',
      // No buffering delay before handing data on. The whole point of a live view is
      // latency, and Tor already adds seconds of its own.
      flushingTime: 0,
      fps: MsePlayer.STREAM_FPS,
      debug: false,
    });

    this.connect();
  }

  private connect(): void {
    if (this.disposed) return;
    const ws = new WebSocket(this.url);
    ws.binaryType = 'arraybuffer';
    this.ws = ws;

    ws.onopen = () => {
      if (this.disposed) return;
      // autoplay is a REQUEST, not a guarantee — a refusal leaves a paused <video>, which
      // on screen is indistinguishable from the decode failure this path exists to fix.
      // The element is muted, so this should always be permitted; ask anyway and swallow
      // the rejection rather than leaving it as an unhandled promise.
      void this.video.play().catch(() => {});
      this.onConnected?.();
    };
    ws.onmessage = (e) => {
      if (this.disposed || !this.muxer) return;
      this.muxer.feed({ video: new Uint8Array(e.data as ArrayBuffer) });
    };
    ws.onclose = () => {
      this.onDisconnected?.();
      // Same 2 s reconnect cadence SotaPlayer uses, so the two paths behave alike when the
      // car drops off the network.
      if (this.running && !this.disposed) {
        setTimeout(() => this.connect(), 2000);
      }
    };
    // Deliberately no `running = false` here, unlike SotaPlayer: an error is followed by a
    // close, and clearing the flag first would silently disable that reconnect.
    ws.onerror = () => {};
  }

  stop(): void {
    this.disposed = true;
    this.running = false;
    try {
      this.ws?.close();
    } catch {
      /* already gone */
    }
    this.ws = null;
    try {
      this.muxer?.destroy();
    } catch {
      /* jmuxer throws if it never attached */
    }
    this.muxer = null;
  }
}
