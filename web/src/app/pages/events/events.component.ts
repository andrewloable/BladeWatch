import { Component, computed, inject, signal, OnInit } from '@angular/core';
import { DatePipe } from '@angular/common';
import { ActivatedRoute } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';
import { ConnectClients } from '../../core/connect/connect-clients';
import {
  VideoPlayerComponent,
  type PlayerItem,
} from '../../shared/video-player/video-player.component';
import type { RecordingEntry } from '../../../gen/bladewatch/v1/recordings_pb';

@Component({
  selector: 'app-events',
  standalone: true,
  imports: [DatePipe, VideoPlayerComponent, TranslateModule],
  templateUrl: './events.component.html',
  styleUrl: './events.component.scss',
})
export default class EventsComponent implements OnInit {
  private readonly clients = inject(ConnectClients);
  private readonly route = inject(ActivatedRoute);

  readonly events = signal<readonly RecordingEntry[]>([]);
  readonly loading = signal(true);
  readonly error = signal('');
  readonly activeFile = signal<PlayerItem | null>(null);
  /** Snapshot from a push notification, shown inline (see ngOnInit). */
  readonly heroUrl = signal<string | null>(null);

  /** Playlist for the shared player — the full ordered events list. */
  readonly playlist = computed<PlayerItem[]>(() =>
    this.events().map((e) => ({
      filename: e.filename,
      title: e.timeLabel || e.dateLabel || e.filename,
      hasEvents: e.hasEvents,
    })),
  );

  ngOnInit(): void {
    // Web Push deep links arrive as a fresh page load (/events?filter=…&file=…),
    // so a snapshot read is enough — there is no in-app navigation that swaps
    // these params while the component stays mounted.
    const params = this.route.snapshot.queryParamMap;
    // Only 'proximity' switches the listing; anything else (absent, unknown,
    // or 'sentry') keeps the sentry default so existing links don't change.
    const filter = params.get('filter') === 'proximity' ? 'proximity' : 'sentry';
    // iOS Safari drops options.image on Web Push, so the service worker
    // forwards the snapshot as ?hero=<url> for us to render inline instead.
    // That value reaches us through the URL bar, so only accept the shape the
    // daemon actually produces — a same-origin, root-relative /thumb/ path —
    // rather than pointing an <img> at whatever a crafted link supplies.
    const hero = params.get('hero');
    if (hero && hero.startsWith('/thumb/') && !hero.startsWith('//')) {
      this.heroUrl.set(hero);
    }
    this.loadEvents(filter, params.get('file'));
  }

  private async loadEvents(type: string, wantFile: string | null): Promise<void> {
    try {
      const resp = await this.clients.recordings.listRecordings({
        type,
        pageSize: 100,
      });
      const list = resp.recordings ?? [];
      this.events.set(list);
      // Auto-open the clip the notification was about. A link naming a clip
      // outside this page of results just shows the list — not an error.
      if (wantFile) {
        const match = list.find((r) => r.filename === wantFile);
        if (match) this.playVideo(match);
      }
    } catch {
      this.error.set('Failed to load events');
    } finally {
      this.loading.set(false);
    }
  }

  playVideo(rec: RecordingEntry): void {
    this.activeFile.set({
      filename: rec.filename,
      title: rec.timeLabel || rec.dateLabel || rec.filename,
      hasEvents: rec.hasEvents,
    });
  }

  onPlayerFileChange(item: PlayerItem): void {
    this.activeFile.set(item);
  }

  closeVideo(): void {
    this.activeFile.set(null);
  }

  /** int64 timestamp → number for DatePipe (0 when unset). */
  tsMs(ev: RecordingEntry): number {
    return Number(ev.timestampMs);
  }

  typeBadge(type: string | number): string {
    const map: Record<string, string> = { SENTRY: 'Sentry', PROXIMITY: 'Proximity', '2': 'Sentry', '3': 'Proximity' };
    return map[String(type)] ?? String(type);
  }
}
