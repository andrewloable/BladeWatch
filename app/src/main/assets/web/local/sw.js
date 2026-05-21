/**
 * OverDrive Service Worker
 *
 * Receives Web Push payloads from the head unit, renders notifications,
 * and routes taps back into the PWA.
 *
 * Auth model: the page postMessages its JWT to the SW on each load. SW caches
 * it (in-memory only, deliberately not persisted) for any auth-required fetch
 * the SW itself needs to make — for example, snapshot enrichment.
 */

let cachedToken = null;

self.addEventListener('install', (event) => {
  // Activate this SW immediately on install — there's nothing to precache.
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || typeof data !== 'object') return;
  if (data.type === 'set-token' && typeof data.token === 'string') {
    cachedToken = data.token;
  } else if (data.type === 'clear-token') {
    cachedToken = null;
  }
});

// ==================== PUSH ====================

self.addEventListener('push', (event) => {
  let payload;
  try {
    payload = event.data ? event.data.json() : {};
  } catch (e) {
    payload = { title: 'OverDrive', body: '(unreadable payload)', severity: 'info' };
  }

  event.waitUntil(showFromPayload(payload));
});

function showFromPayload(payload) {
  const title = payload.title || 'OverDrive';
  const severity = payload.severity || 'info';

  const options = {
    body: payload.body || '',
    // Large icon shown next to the body. Use the full app icon edge-to-edge.
    // The OS may still apply a circular mask on Android — that's the system
    // notification rail and not controllable from the SW.
    icon: '/shared/app-icon-light.webp',
    // Status-bar badge: small monochrome glyph rendered next to the time.
    // Without this, Android falls back to a generic dot which looks worse
    // than the real branding. Same source file — Android renders it
    // monochrome anyway.
    badge: '/shared/app-icon-light.webp',
    tag: payload.tag || payload.category || 'overdrive',
    timestamp: payload.ts || Date.now(),
    data: payload,
    renotify: severity === 'critical'
  };

  if (severity === 'critical') {
    options.requireInteraction = true;
    options.vibrate = [300, 100, 300, 100, 300];
  } else if (severity === 'warn') {
    options.vibrate = [200];
  }

  // Best-effort enrichment for surveillance pushes — fetch a snapshot if the
  // payload referenced one, but never let enrichment delay or fail the
  // notification itself. Cellular-only iPhones with the tunnel down will
  // simply get a text-only banner.
  if (payload.data && payload.data.snapshot && cachedToken) {
    return enrichWithSnapshot(payload.data.snapshot, options)
      .catch(() => {})
      .then(() => self.registration.showNotification(title, options));
  }

  return self.registration.showNotification(title, options);
}

/**
 * Snapshot enrichment with 202-aware retry.
 *
 * The /thumb/ endpoint returns:
 *   200 — JPEG ready (hero sibling JPEG written by ThumbnailBuffer at recording
 *         close, or cached MediaMetadataRetriever frame).
 *   202 — Frame extraction kicked off in the background; retry shortly.
 *
 * Notifications fired at recording START will hit 202 because the hero JPEG
 * doesn't exist until recording-end. Without retry, the OS banner is text-only.
 * events.js does up to 8 retries with backoff for this same reason; the SW
 * mirrors a smaller version (3 attempts, ~5s total) to keep the push handler's
 * lifetime within Web Push budget.
 */
function enrichWithSnapshot(url, options) {
  const ATTEMPTS = 3;
  const BACKOFF_MS = [800, 1500, 2500];

  function attempt(i) {
    return fetch(url, {
      headers: { 'Authorization': 'Bearer ' + cachedToken }
    }).then((res) => {
      if (res.status === 200) {
        return res.blob().then((blob) => {
          options.image = URL.createObjectURL(blob);
        });
      }
      if (res.status === 202 && i + 1 < ATTEMPTS) {
        return new Promise((resolve) => setTimeout(resolve, BACKOFF_MS[i]))
          .then(() => attempt(i + 1));
      }
      // 4xx / 5xx / final 202 — give up and ship text-only banner
      throw new Error('snapshot fetch failed: ' + res.status);
    });
  }

  return attempt(0);
}

// ==================== CLICK ====================

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  const url = data.url || '/';

  event.waitUntil((async () => {
    const wins = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    const sameOrigin = wins.find((w) => {
      try { return new URL(w.url).origin === self.location.origin; } catch (e) { return false; }
    });

    if (sameOrigin) {
      try { await sameOrigin.focus(); } catch (e) {}
      // Navigating an existing window keeps SW + tab state; openWindow would create a new one.
      try { await sameOrigin.navigate(url); return; } catch (e) {}
      // Fallback: postMessage so the page can route in-app
      try { sameOrigin.postMessage({ type: 'notification-click', payload: data }); return; } catch (e) {}
    }
    await self.clients.openWindow(url);
  })());
});
