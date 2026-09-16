import {
  Component,
  inject,
  signal,
  OnInit,
  OnDestroy,
  AfterViewInit,
  ElementRef,
  ViewChild,
} from '@angular/core';
import { TranslateModule } from '@ngx-translate/core';
import { ConnectClients } from '../../core/connect/connect-clients';
import { MsePlayer } from './mse-player';

// SotaPlayer is a global loaded from public/vendor/SotaPlayer.js (no module).
declare var SotaPlayer: any;

/**
 * Live — full-bleed camera view, parity with the native LiveViewFragment.
 *
 * Owns the WebSocket live stream (SotaPlayer over /ws) plus the
 * All / Front / Right / Rear / Left camera selector. Selecting a camera
 * switches the daemon's mosaic/single view via StreamService.SetViewMode
 * (viewMode 0=All/Mosaic, 1=Front, 2=Right, 3=Rear, 4=Left).
 *
 * This was moved out of the dashboard so the dashboard can be a stats/connect
 * hub; the dashboard now routerLinks here for the live feed.
 */
@Component({
  selector: 'app-live',
  standalone: true,
  imports: [TranslateModule],
  templateUrl: './live.component.html',
  styleUrl: './live.component.scss',
})
export default class LiveComponent implements OnInit, AfterViewInit, OnDestroy {
  private readonly clients = inject(ConnectClients);

  @ViewChild('streamCanvas') streamCanvasRef!: ElementRef<HTMLCanvasElement>;
  @ViewChild('streamVideo') streamVideoRef!: ElementRef<HTMLVideoElement>;

  readonly streamConnected = signal(false);
  readonly selectedCam = signal(0);

  /**
   * BladeWatch-nobf: this browser has no WebCodecs, so the stream can never play here.
   *
   * SotaPlayer decodes H.264 with VideoDecoder/EncodedVideoChunk. Without them its
   * start() logs to the console and returns before opening a WebSocket, so onConnected
   * never fires. The page then sat on "not connected" with a Retry button that re-ran the
   * same early return — an unwinnable loop, reported from Tor Browser on the car's own
   * onion address.
   *
   * Tor Browser is built on Firefox ESR and WebCodecs only reached Firefox in the 130
   * series, so this is the DOCUMENTED remote-access path for BladeWatch. Saying what is
   * actually wrong beats a retry that cannot succeed.
   */
  readonly decoderUnsupported = signal(false);

  /**
   * A language-neutral capability line, shown only alongside the unsupported banner.
   *
   * BladeWatch-nobf: whether a WebCodecs-less browser can play the stream some OTHER way
   * comes down to one question — does it decode H.264 through MediaSource? Firefox ships
   * no H.264 decoder of its own (patents); it borrows the platform's, so the answer is
   * yes on Android (MediaCodec), macOS (VideoToolbox) and Windows (Media Foundation), and
   * no on Linux without system ffmpeg. Tor Browser also declines Cisco's OpenH264 blob,
   * which is the usual Linux fallback.
   *
   * That makes it a per-device answer, not a per-browser one, so the honest way to find
   * out is to ask the device in front of the user. Deliberately symbols rather than words:
   * this is diagnostic, and shipping prose here would mean 17 new locale entries for a
   * line that exists to answer one engineering question.
   */
  readonly decoderCapabilities = signal('');

  /**
   * Playing through MediaSource rather than WebCodecs (BladeWatch-nobf).
   *
   * Drives which element is on screen: the WebCodecs path paints a canvas, MediaSource
   * drives a real <video>. Both are in the template and exactly one is shown.
   */
  readonly usingMse = signal(false);

  private player: any = null;
  /** Set once the player object exists so the banner can show a retry hint. */
  private playerStarted = false;

  readonly cameras = [
    { id: 0, label: 'All' },
    { id: 1, label: 'Front' },
    { id: 2, label: 'Right' },
    { id: 3, label: 'Rear' },
    { id: 4, label: 'Left' },
  ];

  ngOnInit(): void {
    // Nothing async to load here — the stream wires up in ngAfterViewInit once
    // the canvas element exists.
  }

  ngAfterViewInit(): void {
    this.initStream();
  }

  ngOnDestroy(): void {
    this.player?.stop?.();
    this.player = null;
  }

  private initStream(): void {
    if (typeof SotaPlayer === 'undefined') return;
    const canvas = this.streamCanvasRef?.nativeElement;
    if (!canvas) return;

    // Ask BEFORE constructing a player. SotaPlayer.start() would otherwise swallow this
    // into a console.error and leave the UI claiming it is merely "not connected".
    if (typeof SotaPlayer.isSupported === 'function' && !SotaPlayer.isSupported()) {
      // No WebCodecs. Before giving up, try MediaSource — which is how this plays at all
      // in Tor Browser, the browser our own help dialog tells people to install.
      if (MsePlayer.isSupported()) {
        this.startMseStream();
        return;
      }
      this.decoderUnsupported.set(true);
      this.decoderCapabilities.set(this.probeDecoders());
      this.streamConnected.set(false);
      return;
    }
    this.decoderUnsupported.set(false);
    this.usingMse.set(false);

    this.player = new SotaPlayer(canvas, this.wsUrl());
    this.player.onConnected = () => this.streamConnected.set(true);
    this.player.onDisconnected = () => this.streamConnected.set(false);
    this.player.start();
    this.playerStarted = true;
  }

  /**
   * Bring up the MediaSource path.
   *
   * Sets [usingMse] FIRST so the <video> element is in the DOM before the player reaches
   * for it — MsePlayer hands that element straight to the muxer, and @if would otherwise
   * not have rendered it yet.
   */
  private startMseStream(): void {
    this.decoderUnsupported.set(false);
    this.usingMse.set(true);
    // One tick for @if to materialise the <video>, then start.
    queueMicrotask(() => {
      const video = this.streamVideoRef?.nativeElement;
      if (!video) {
        // Should not happen, but claiming "connecting" forever is the failure mode this
        // whole issue was about, so fall back to the honest message instead.
        this.usingMse.set(false);
        this.decoderUnsupported.set(true);
        this.decoderCapabilities.set(this.probeDecoders());
        return;
      }
      const player = new MsePlayer(video, this.wsUrl());
      player.onConnected = () => this.streamConnected.set(true);
      player.onDisconnected = () => this.streamConnected.set(false);
      this.player = player;
      this.playerStarted = true;
      void player.start();
    });
  }

  /** What this browser can and cannot decode. See [decoderCapabilities]. */
  /** Same origin as the page, so an onion address just works. */
  private wsUrl(): string {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    return `${protocol}//${window.location.host}/ws`;
  }

  private probeDecoders(): string {
    const webCodecs = typeof (globalThis as any).VideoDecoder !== 'undefined';
    let mseH264 = false;
    try {
      const ms = (globalThis as any).MediaSource;
      // The exact codec string the daemon encodes: H.264 Baseline, Level 3.1.
      mseH264 = !!ms && ms.isTypeSupported('video/mp4; codecs="avc1.42C01F"');
    } catch {
      mseH264 = false;
    }
    const tick = (ok: boolean) => (ok ? '\u2713' : '\u2717');
    return `WebCodecs ${tick(webCodecs)} \u00b7 MSE H.264 ${tick(mseH264)}`;
  }

  /** Tear down and re-create the player — used by the retry banner. */
  retryStream(): void {
    this.streamConnected.set(false);
    try {
      this.player?.stop?.();
    } catch {
      /* ignore */
    }
    this.player = null;
    this.playerStarted = false;
    this.initStream();
  }

  selectCamera(camId: number): void {
    this.selectedCam.set(camId);
    this.clients.stream.setViewMode({ viewMode: camId } as any).catch(() => {});
  }
}
