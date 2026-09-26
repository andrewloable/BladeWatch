# Networking and Tunnels

BladeWatch exposes a local authenticated web server and can optionally front it with LAN access or a Pear (Hyperswarm) peer for the companion app — see [Pear Peer](#pear-peer-hyperswarm) below. Both are opt-in, and no proxy layer sits between either one and the local server. The Tor onion service of v1.3.x was removed in v1.4.0.0 — see [Tor Onion Service (removed)](#tor-onion-service-removed).

## Local Ports

| Port | Bind | Component | Purpose |
| --- | --- | --- | --- |
| `19876` | `127.0.0.1` | `TcpCommandServer` | JSON command IPC for camera daemon control and secret bridge |
| `19877` | `127.0.0.1` | `SurveillanceIpcServer` | JSON IPC for surveillance, GPS, and update actions |
| `8080` | `127.0.0.1` **always** | `HttpServer` | Web UI, REST APIs, ConnectRPC (`/bladewatch.v1.*`), video, thumbnails, WebSocket streaming. Listener trust `LOCAL_APPS` |
| `8444` | `127.0.0.1` **always** | `HttpServer` (TLS) | Pear's way in: the stream pump (`PearStreamPump`, in pear_daemon) connects here, and the companion's TLS runs end to end through the Pear stream to it. Same pinned certificate as 8443, independent of the LAN opt-in. Listener trust `REMOTE` |
| `8443` | `0.0.0.0`, only while LAN access is on | `HttpServer` (TLS) | The same server over TLS for a companion on the same LAN; pinned self-signed certificate (`LanTls`). Listener trust `REMOTE` |
| `18443/udp` | all interfaces, only while LAN access is on | `LanDiscoveryResponder` | Answers a paired companion's HMAC-signed discovery probe with the car's LAN IP, 8443 and the TLS pin; silent to everything else |

Both IPC servers (`19876`/`19877`) authenticate callers with the bootstrap token
in `/data/local/tmp/bladewatch_ipc_token` (`IpcTokenManager`). That file is
world-readable (`644`) on purpose so the app UID can authenticate to the
shell-UID daemon; the secret store it gates remains `600`. The IPC token is not
exposed over HTTP — see `docs/ipc-auth-and-secrets.md`.

## Embedded HTTP Server

The HTTP server serves (all on a single port so the tunnel can expose both
HTTP and WebSocket):

- The Angular SPA build (`/`, `/assets/*`, `/vendor/*`).
- Shared JavaScript, CSS, and i18n resources.
- Auth endpoints (`/auth/*`).
- The REST API (`/api/*`, `/status`, `/video/*`, `/thumb/*`).
- The ConnectRPC / gRPC-style API under the `/bladewatch.v1.*` route prefix,
  consumed by the Angular SPA. Unary calls use `application/json`, streaming
  uses `application/connect+json`; both require `Connect-Protocol-Version: 1`.
  The Connect handlers wrap the REST handlers, so they share the same auth and
  the same bind. See `docs/http-api-reference.md` for the full surface.
- WebSocket streaming on the `/ws` upgrade path.

Plain HTTP binds `127.0.0.1:8080` under every configuration — plaintext never
leaves the device (BladeWatch-rdtj.4). Before v1.4.0.0, "LAN mode" rebound this
same plain listener to `0.0.0.0:8080`, which put the Bearer JWT, and with it every
vehicle-control endpoint, on a shared Wi-Fi in the clear. That mode is gone.

LAN access is now a SECOND listener: TLS on `0.0.0.0:8443`, opened only while the
owner's opt-in `network.lanHttpEnabled` is on (the key name predates TLS). It is
off by default. The listener re-reads the flag every 5 s, so switching it off
closes the port within seconds, with no daemon restart. TLS 1.2 and 1.3 only.

The certificate is self-signed, EC P-256, and pinned by the companion: its
SHA-256 fingerprint (lowercase hex over the certificate DER) reaches the companion
out of band in the pairing QR, via the `lanTlsInfo` IPC command — never from the
connection being trusted. The key and certificate live in the 600 secret store
(section `lanTls`). **It is never rotated on expiry**: this head unit's clock jumps
at boot, a rotation changes the fingerprint and strands every paired companion,
and pinning never evaluates validity anyway. It is replaced only if missing or
unreadable, which is logged as an error.

A browser pointed at `https://<car>:8443` gets a certificate warning: there is no
CA to vouch for the car. The web app over the LAN therefore now needs that warning
accepted; the companion app does not, because it pins.

What turning LAN access on exposes to the rest of the LAN (BladeWatch-cjhz), before any
credential:

- **Any client is served, pinned or not.** Only the companion pins. A browser user who
  clicks through the warning can be man-in-the-middled on a shared network and would hand
  over their login. This ends with the web app (rdtj.13).
- **That a car is there.** Port 8443 answers. The certificate subject used to say
  `CN=BladeWatch`; identities created now say `CN=localhost`. An existing certificate keeps
  its subject, because re-minting it would unpair every companion. Until web/ retires, the
  login page it serves carries the product name anyway. The discovery responder (udp/18443)
  stays silent to anything that is not signed with the pairing key.

`SystemService/GetStatus` reports `network.httpBind` (always `127.0.0.1`) and
`network.lanHttpEnabled` (the opt-in). The listener's port and fingerprint reach the in-car UI
over IPC (`lanTlsInfo`), and reach a companion through the pairing QR.

### LAN discovery (udp/18443)

A companion finds the car on its own network by sending it a signed probe, not by
reading the Wi-Fi SSID (which needs `ACCESS_FINE_LOCATION` on Android 10+). If the
car answers, the two share a segment by definition, and the companion connects
straight to 8443 — the path that works even where Hyperswarm cannot (same NAT).

**Probes must be UNICAST — broadcast never reaches the car.** Measured on the head
unit 2026-09-24 (BladeWatch-rdtj.5): valid probes sent to the subnet-directed
broadcast address and to `255.255.255.255` got no reply in six tries, while the same
probes sent to the car's own address were answered every time. The Qualcomm Wi-Fi
firmware drops broadcast and multicast unless someone holds a
`WifiManager.MulticastLock` (`dumpsys wifi`: no locks held), and the daemon cannot
take one — it runs as shell, which lacks `CHANGE_WIFI_MULTICAST_STATE`. Holding one
from the app process would also keep Wi-Fi awake for every multicast packet through
a whole sentry night. iOS independently forbids SENDING broadcast without Apple's
multicast entitlement. So the companion (BladeWatch-rdtj.8) probes the car's
last-known address first, then sweeps its own /24 with the same probe — 254 packets
of 256 bytes, answered only by the car holding the key. Nothing on the car changes:
the responder has always answered unicast.

The exact wire format is in `LanDiscoveryResponder`'s class doc. In short: a probe
is exactly 256 bytes — magic, 16-byte nonce, timestamp, HMAC-SHA256 under the
per-car probe key (`lanDiscovery.probeKey`, carried by the pairing payload), zero
padding. The reply goes unicast to the sender, echoes the nonce, is signed with the
same key, and carries `{ip, port, fp, id}` — routing data and a public certificate
pin only, never a secret.

- **Silent to anything unsigned, replayed, stale or mis-sized.** Answering would
  tell every device on the network that a BladeWatch car is parked there.
- **Never an amplifier.** Probes must be exactly 256 bytes and a reply is enforced
  to be smaller.
- **Freshness is ±24 h, replay protection is a nonce cache on the MONOTONIC clock.**
  This head unit's wall clock jumps after boot, and a tight window silently refuses
  every probe during the skew. Known ceiling: the cache is in memory, so after a
  daemon restart a probe captured in the last 24 h can be answered once more.
- **The car answers; it never advertises.** No unsolicited announcements.

### Listener trust

Every listener declares a `ListenerTrust` (`AuthMiddleware.kt`), and trust belongs
to the listener, not to the peer address. A loopback address proves nothing: the Pear
stream pump connects from `127.0.0.1`, as tor did before it. Only `LOCAL_APPS`
(8080) can reach the Tier 2 loopback safety net or skip the vehicle-action second
factor; every other listener is `REMOTE`. `checkAuth` overloads that do not name a
listener assume `REMOTE`, so a listener added later fails closed.

And even on 8080, `LOCAL_APPS` is for BladeWatch, not for every app on the head unit:
Android loopback is shared. Each connection's peer UID is resolved from `/proc/net`
(`PeerCredentials`, the same check the IPC ports use), and only the BladeWatch app UID,
shell, system and root keep `LOCAL_APPS`; any other app -- or a peer whose UID cannot be
resolved -- is served as `REMOTE` (`AuthMiddleware.effectiveTrust`, BladeWatch-g5u7).
Before that, a debug build handed any installed app the whole API, vehicle control
included, with no credential.

Remote traffic therefore enters on its own listener, never on 8080: the Pear pump on the
TLS listener **8444** (BladeWatch-rdtj.6/.8). tor once landed on 8080, so every remote
request over it skipped the vehicle-control second factor; BladeWatch-ur11 moved it to a
listener of its own (8081), which went with tor. That keeps a remote peer out of the in-car
UI's privileges by construction, not by remembering to mark a tunnel as active — which is
why the Tier 2 bypass no longer asks whether a tunnel is running (that check went with tor,
BladeWatch-rdtj.12): nothing relays into 8080, and `RemoteLoopbackListenerTest` pins the pump
to 8444.

## Authentication

`AuthMiddleware` protects the HTTP server.

Public paths (no auth at all):

- `/auth/status`, `/auth/token`, `/auth/logout`.
- `/login`, `/login.html`.
- `/manifest.json`, `/sw.js`, `/favicon.ico`.
- `/shared/*`, `/i18n/*` (prefixes).
- `/bladewatch.v1.AuthService/Login` — the Connect login RPC must be reachable
  before a session exists. All other `/bladewatch.v1.*` Connect calls are
  protected by the same middleware that guards REST.

Note: `/auth/*` paths are routed in `HttpServer.handleClient` before the auth
middleware runs, so they are always reachable regardless of the list above.

Protected requests require:

- Bearer JWT (`Authorization: Bearer <jwt>`), or
- `byd_session` cookie (HttpOnly JWT), or
- signed thumbnail token for specific `/thumb/*?t=<jws>` access.

Cookies set on successful `/auth/token`:

- `byd_session` — the JWT itself, **HttpOnly** (not readable by JS), used by the
  WebView and browser for authenticated requests.
- `byd_auth=1` — a non-HttpOnly hint cookie so client JS can tell it is logged
  in without exposing the JWT. Both expire together; logout clears both.

Release builds require JWT auth even from loopback clients because Android loopback is shared across apps. Debug builds can bypass loopback auth only when tunnel-forwarding headers are absent.

Tunnel-forwarding headers checked by the middleware include:

- `X-Forwarded-*`.
- `CF-*`.
- `X-Real-IP`.
- `Forwarded`.

## Device Token and JWT

The auth manager derives access from a device token shaped from device id and secret. It issues HMAC-SHA256 JWTs with a token epoch so all sessions can be invalidated.

Important behavior:

- JWTs are time-limited.
- Token epoch invalidation can revoke old tokens.
- Device secret belongs in the secret store.
- Tunnel URLs should never be shared without considering token exposure.

## WebSocket Streaming

The HTTP server handles WebSocket upgrades for live H.264 streaming.

Streaming behavior includes:

- Token query promotion for WebSocket auth.
- Cached SPS/PPS delivery.
- IDR frame request support.
- Fragmenting large frames into smaller chunks.
- Separate streaming encoder path from recording.

## Android WebView Networking (REMOVED — historical)

`WebViewFragment` was deleted in Phase 4 (`BladeWatch-81g9.2`) along with the rest
of the native UI. **Nothing in the app loads the SPA in a WebView any more** — the
in-car UI is Flutter and calls the daemon over ConnectRPC directly, and the SPA is
served only to remote browser / tunnel clients.

What it used to do is recorded here because the underlying head-unit quirks have
not gone away and will bite anything that puts a WebView on `127.0.0.1:8080`
again. It loaded `http://127.0.0.1:8080/<page>` and:

- Injected the auth JWT cookie.
- Cleared/restored WebView proxy state around local server access.
- Injected JavaScript routing mutating API requests through `AndroidBridge.httpRequest`.
- Left normal GET navigation asynchronous.
- Bypassed the proxy for local server requests.

The one WebView left is the Vehicle hero (`webview_flutter` on
`assets/web/hero/hero.html`), which loads a Flutter asset over `file://` and does
**not** talk to the daemon, so none of the above applies to it.

## Pear Peer (Hyperswarm)

`pear_daemon` (`PearDaemon`, see `docs/daemons-and-processes.md`) is the remote-access
transport since v1.4.0.0, when it replaced tor. It hosts a bare-kit worklet running pear-end and joins this car's
Hyperswarm topic as both server and client, so a paired companion finds the car through the
public DHT with no account, relay or central server. Opt-in (`PEAR_PEER`, off by default).

**Network footprint.** It opens no listening TCP port. Hyperswarm speaks UDP (UDX) from
ephemeral ports: outbound to the public DHT bootstrap nodes, then peer-to-peer after UDP
hole-punching. Connections are end-to-end encrypted by Hyperswarm itself (Noise handshake).

**The topic is a capability to find the car, not to use it.** It comes from `PearTopic` — a
SHA-256 over a domain tag and a random per-car seed held in the 600 secret store — so it is
unguessable and unique per car, never a hash of a public string. Anyone who learns it can only
attempt a connection; the HTTP API still demands a JWT. The daemon never logs it.

**Same-NAT limitation.** Two peers behind the same NAT generally cannot reach each other
(router hairpinning breaks the hole-punch), which is the common "phone on the same home Wi-Fi
as the parked car" case. That is what the LAN TLS path (BladeWatch-rdtj.4/.5) is for.

**Wire shape to the worklet.** BareKit IPC frames: 4-byte big-endian length, 1-byte type,
UTF-8 JSON body (`PearIpc`). pear-end delivers connection bytes per PEER, base64-encoded in
those JSON frames, so any HTTP carried over it must be multiplexed per stream by BladeWatch.
Only one IPC write may be in flight: bare-kit's `IPC.write(buf, cb)` finishes a partial
write from a `writable()` callback, and a second write issued meanwhile jumps ahead of the
first one's remainder (read off bare-kit 2.5.5's `IPC.class`), so `PearDaemon` queues them.

### Stream multiplexing (`PearMux`, BladeWatch-rdtj.6)

A companion needs several TCP connections to the car at once -- the live-view WebSocket,
ConnectRPC calls, thumbnails -- over its ONE Pear connection. Each Pear message is one frame
(Protomux keeps message boundaries, so there is no length prefix):

| byte 0 | bytes 1-4 | rest |
|---|---|---|
| `1` OPEN | stream id, u32 BE | 1 byte: protocol version (`1`) |
| `2` DATA | stream id | 1..32768 payload bytes |
| `3` CLOSE | stream id | nothing |
| `4` WINDOW | stream id | u32 BE credit, > 0 |

Only the companion opens streams; the car answers OPEN by connecting to 127.0.0.1:8444
(`PearStreamPump`, in pear_daemon) and copies bytes both ways, opaque. The bytes are TLS
records -- see "Car authentication over Pear" below -- and inside the TLS, ConnectRPC and the
WebSocket live view need no changes. CLOSE closes both directions. Each direction of each
stream starts with 256 KiB of credit and the receiver sends WINDOW as it consumes; a sender
never has more than that unacknowledged. This is the only backpressure there is: pear-end's
`connection.write` ignores Protomux's, so without it a live stream on a slow link would pile
up in the worklet. Limits, because anyone who knows the topic can connect: 16 streams per
peer, 64 in total, a 15 s connect deadline (byd_cam_daemon may be restarting), 5 minutes
idle, and a peer that sends past its credit loses the stream. The class docs of `PearMux`
and `PearStreamPump` are the spec; the companion (BladeWatch-rdtj.8) implements the mirror.

### Car authentication over Pear (TLS inside Pear, BladeWatch-rdtj.8)

Hyperswarm encrypts every connection, but that says nothing about WHO is at the other end.
pear-end's Hyperswarm key pair is random on every worklet start and never exposed to the app,
so a companion cannot pin the car's Pear identity. And the topic is shared: pear-end joins it
as server and client, so the owner's other companions connect to each other there too, and
anyone who ever learned the topic -- a revoked phone, a photographed QR -- could answer as the
car, or relay between a companion and the real car and read its token, JWT and video.

So the companion runs TLS through the Pear stream, end to end to the car's 8444 listener, and
checks the certificate against the same fingerprint pinned at pairing for the LAN path. Only
the car holds that key. A peer counts as the car only once that handshake completes; the
companion tries every peer on the topic at once and drops the ones that never answer
(`findCarOverPear`: 60 s per handshake, `LocalGateway.pearHandshakeTimeout`, within a 90 s
search). A relay sees only TLS records.

### The car's pear-end must tag inbound connections (BladeWatch-ekbp)

pear-end forwards a peer's messages only for topics Hyperswarm has tagged on the connection,
and Hyperswarm tags a connection only when THIS side's own DHT query finds the peer. The car
has usually been on its topic for hours when a phone joins, so the phone's lookup finds the
car and the phone dials in: the car is the accepting side, starts untagged, and flutter_pear
0.4.2's pear-end ignores it -- no connection event, every message dropped -- until the car's
next scheduled refresh, 10 minutes plus up to 2 of jitter. Measured on the head unit
2026-09-24: Hyperswarm connected every time, the pump never saw a single frame.

The fix is upstream, in flutter_pear's pear-end (`tagInboundConnection`): on an inbound
connection the accepting side re-runs discovery straight away, which tags exactly the topics
the peer announces, and holds the peer's messages until then instead of dropping them. The
car's `app/src/main/assets/pear/pear-end.bundle` must be built from a flutter_pear with that
fix -- flutter_pear 0.4.3 or later; 0.4.2's does not work. Until 2026-09-26 the car's copy was
byte-identical to the one inside the published 0.4.4 package (sha256 `089e42ee…`, checked against
the pub.dev archive on 2026-09-24); it is now the published 0.4.5 one, which carries the
accept-unannounced option below. 0.4.4 adds what the car's Pear status needs:
`dht.status`, so "reachable" is HyperDHT's own answer, not a guess from process liveness (rdtj.17).
It also lowers the held-message cap to 256 KiB per untagged connection. Only the car needs it -- a companion is normally the dialing side,
and when it is not, its own lookup right after joining tags the connection in seconds -- and it
changes nothing on the wire, so a fixed car works with a 0.4.2 companion. With it, the first
pinned handshake through Pear took 11.3 s and the whole route 19.9-25 s (same network, public
DHT, 2026-09-24): the car's tagging query is most of that.

### The car accepts companions it cannot find announced (BladeWatch-lw0o)

Tagging by announcement is a race. The accepting side retries discovery at 0, 1, 3, 7, 15 and
30 s and then gives up, and a companion behind a slow or randomizing NAT often has not landed
its announcement by then: its Pear connection forms, the car never uses it, and the route fails
after the 90 s search. Measured 2026-09-26 from a phone hotspot (HyperDHT randomized=true): 5 of
8 routes failed, the companion seeing "swarm connected" and a peer while the car's
`lastCompanionAt` never moved.

So the car joins its topic with `acceptUnannounced` (`PearDaemon.joinParams`): pear-end
attributes an inbound connection to the car's topic the moment it arrives, because it is the
worklet's only topic with that option. The car's `app/src/main/assets/pear/pear-end.bundle` is
therefore the published flutter_pear 0.4.5 bundle, which has that option: byte-identical to the
one inside the pub.dev package (sha256 `00f9adc4…`, checked 2026-09-26); the companion is pinned
to 0.4.5 too. An older bundle ignores the flag. From the same hotspot afterwards, every attempt whose Pear
connection formed reached the car (13 of 13); the 7 of 20 that failed never formed a connection
at all -- NAT traversal from a randomizing NAT, BladeWatch-idfn.

The same option lets the companion join WITHOUT announcing (`announce: false`,
`CarSession.open`), so a session no longer leaves a DHT record that outlives it by 20 minutes
and costs every later dialer a failing dial (BladeWatch-qryk). A companion that announces still
works: the car accepts it either way. The car itself still leaves one dead record per
`pear_daemon` restart: pear-end's key pair is random per start.

### Known limitation: hard NATs (BladeWatch-idfn, accepted 2026-09-26)

From a phone hotspot behind a randomizing NAT (HyperDHT `randomized=true`), hole punching to the
car is probabilistic and slow: 7 of 20 cold starts never formed a Pear connection, and the 13
that did took a median of 44 s. The companion reports this as "can't reach the car" and keeps
retrying by itself. The fix would be a relay for when hole punching fails (hyperdht's
`relayThrough`: a public blind relay, or an always-on peer the owner runs); the owner accepted
the limitation for now, to be revisited if it bites in daily use.

### The companion's side (`companion/lib/transport/`)

The companion's UI talks plain HTTP to `LocalGateway`, a listener on the phone's own loopback,
which forwards each connection to the car over whichever route `TransportSelector` picked:

1. **LAN**, when the car answers a discovery probe (`LanProber`, udp/18443): pinned TLS
   straight to 8443. Lower latency, full bandwidth, and the only path that works when phone
   and car share a NAT.
2. **Pear** otherwise: each connection becomes one `PearMux` stream (`MuxBridge`) with TLS
   through it to 8444, pinned the same way.

The selector reports `discovering` and `failed` as different phases (a DHT lookup can take
30 s or more, and "still looking" must not read as "can't reach the car"). It re-evaluates
when the phone's addresses change (polled every 5 s: it joined or left a Wi-Fi) and when the
Pear connection drops, and retries on its own 30 s after a failure. Either way the phone
never accepts a certificate other than the pinned one.

**Every search for the car is a fresh join (BladeWatch-rdtj.24).** `CarSession` leaves the
topic's old swarm and joins again each time the selector looks for the car -- at start, after a
drop, on a retry, after a network change. A long-lived dial-only swarm did not find the car
again after a car-side restart, and a new swarm also gets the replay of already-established
connections, which `PearSwarm.connections` gives its FIRST listener only. Together with the car's
persistent identity (`--persistent-identity`, see `docs/daemons-and-processes.md`), a car-side
`pear_daemon` restart mid-download measured 3.2 s back to the Pear route, with the download
resuming byte-exact (`companion/integration_test/pear_drop_test.dart`).

## Tor Onion Service (removed)

v1.3.x reached the car through a Tor v3 onion service. v1.4.0.0 removed it
(BladeWatch-rdtj.12): `TorLauncher`, the `TOR_TUNNEL` daemon type, the `tunnelStatus` IPC
command, the REMOTE loopback listener on 8081, the build-time `libtor.so` download, and the
Dashboard's Connect card (onion QR, device ID, web access code). Saved onion URLs and QR codes
stop working, and nothing migrates them: an owner pairs the companion instead.

What stays, on purpose: `LegacyTunnelCleanup` kills a stale `bladewatch_tor` from a v1.3.x
install on every app launch (with `killall`, never `pkill -f`, which matches its own shell) and
drops the stale `TOR_TUNNEL` config key. A surviving tor would keep forwarding its onion port to
a now-unbound 127.0.0.1:8081 that any app on the head unit could bind (BladeWatch-rdtj.23). Neither touches
`/data/local/tmp/tor`, whose `hs/` still holds the old onion key; removing it is the owner's
call.

For comparison with the Pear numbers, tor measured on the head unit (2026-09-14): 62–75 KB/s,
2.1–6.5 s warm request TTFB, ~82 s cold bootstrap, and the address opened only in Tor Browser
or Onion Browser.

## Still-frame fallback for decoder-less browsers (BladeWatch-y78o.1)

`GET /api/stream/still` serves a periodically refreshed JPEG of the full 4-camera mosaic
(640×480, quality 80) for browsers that can decode neither WebCodecs nor MSE H.264 — Tor
Browser on Linux is the documented case (see `docs/evaluations/overdrive-remote-communication.md`
and friends for why: Firefox borrows the platform's H.264 decoder and Linux has none by
default). The web client (`web/src/app/pages/live/still-frame-player.ts`) selects this tier
automatically — see `stream-tier.ts` — and shows a persistent "still image, not live video"
banner so the owner never mistakes a stale frame for a live one.

The companion's live view uses this tier on every platform (BladeWatch-rdtj.11). Stills flow
only while streaming is enabled, and streaming idles out 30 s after the last WebSocket viewer
leaves, which a still-frame viewer never was. Each `/api/stream/still` request therefore
counts as viewer activity (`WebSocketStreamServer.noteStillViewer`), so streaming lasts
exactly as long as someone keeps looking. A 503 means it has not started yet: the companion
calls `StreamService/Enable`, no more than once every 10 s.

**No JPEG encode on the hot camera path.** The source is
`SurveillanceEngineGpu.getLatestMosaicFrame()`, the same continuously-updated RGB buffer
`SurveillanceApiHandler`'s quadrant-snapshot route already reads — it updates every camera
frame regardless of whether this fallback exists. The only new work is the JPEG encode
itself, and it runs on its own 5-second timer (`StillFrameRefresher`), fully decoupled from
camera FPS. Two consecutive HTTP requests between refreshes are served the same retained
bytes with zero additional encoding.

**Step Zero viability (BladeWatch-y78o.1, no physical head unit available this session — see
the issue's own close reason for the full methodology and caveats):** a synthetic
detail-heavy 640×480 JPEG at quality 80 measured 122 KB, chosen as a conservative
(worst-case-compression) proxy for a real camera frame in the absence of device access. At
the then-documented **101 KB/s** sustained onion throughput
(`docs/evaluations/overdrive-remote-communication.md`), a 5-second refresh costs ~24 KB/s —
about a quarter of the budget, leaving headroom for the rest of the page. A 2-second refresh
would use ~60%, too tight; 5 seconds was chosen as the default for that reason.

## BladeWatch's Own Network Usage (BladeWatch-t1lg.1)

On a metered head-unit SIM, streaming a live view to a companion over Pear costs real money, and nothing previously told the owner what it costs. `NetworkMonitor` now
tracks BladeWatch's own (own-UID) `TrafficStats.getUidRxBytes`/`getUidTxBytes` totals — **not**
whole-device usage, and not per-app attribution (`NetworkStatsManager`/`PACKAGE_USAGE_STATS` are
deliberately not used; own-UID totals need no permission).

A background sampler (`DataUsageSampler`, `Thread.MIN_PRIORITY`, every 60s) reads both counters
and feeds them to `DataUsageAccumulator` — a pure, `android.*`-free class specifically so its
hardest case (a device reboot resets the cumulative-since-boot counter to near zero) is
unit-testable without a device. The rule: if the new reading is `>=` the last one, add the delta;
if it went backward, a reboot happened and the whole new reading is credited as new traffic,
never subtracted. The running total also rolls over to a new bucket on the local-time month
boundary, keeping the just-finished month's total for "last month."

State (`rxLastReading`, `rxAccumulatedThisMonth`, `rxCurrentMonthKey`, `rxLastMonthTotal`,
`rxLastMonthKey`, and the `tx` equivalents) persists to `UnifiedConfigManager`'s `dataUsage`
section after every sample, so a daemon restart resumes from where it left off instead of
re-crediting a large reading as if it were a reboot. Surfaced as `thisMonthBytes`/`lastMonthBytes`
(rx+tx combined) on `NetworkInfo` in `GetStatus`, and shown on the Flutter Diagnostics screen's
network tile as "X this month."

## Remote Access Security Model

Recommended exposure order:

1. Loopback only.
2. The Pear peer, for paired companions: TLS end to end into 8444 with a pinned certificate,
   JWT on every request.
3. LAN mode only when needed and trusted.

Risk notes:

- LAN mode binds all interfaces and should remain disabled by default.
- The Pear topic is a **rendezvous point, not authentication**. Anyone who learns it can
  find the car on the DHT and attempt a connection; the pinned TLS and JWT auth behind it
  stay mandatory (`PearTopic`).
- Auth tokens must not be logged.
- Release builds intentionally protect loopback.

## Source References

- Local daemon and server ports: [CameraDaemon.java:51](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L51), [CameraDaemon.java:243](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L243), [CameraDaemon.java:381](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L381).
- HTTP bind mode and LAN opt-in: [HttpServer.java:171](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L171), [UnifiedConfigManager.kt:618](../app/src/main/java/com/loabletech/bladewatch/config/UnifiedConfigManager.kt#L618).
- Connect/gRPC dispatch and service registration: [HttpServer.java:568](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L568), [ConnectDispatcher.java:72](../app/src/main/java/com/loabletech/bladewatch/server/connect/ConnectDispatcher.java#L72), [CameraDaemon.java:387](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L387).
- Auth middleware, public paths, JWTs, and cookies: [AuthMiddleware.java:40](../app/src/main/java/com/loabletech/bladewatch/server/AuthMiddleware.java#L40), [AuthMiddleware.java:95](../app/src/main/java/com/loabletech/bladewatch/server/AuthMiddleware.java#L95), [AuthApiHandler.java:170](../app/src/main/java/com/loabletech/bladewatch/server/AuthApiHandler.java#L170), [AuthManager.java:446](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java#L446), [AuthManager.java:561](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java#L561).
- IPC token bootstrap: [IpcTokenManager.java:54](../app/src/main/java/com/loabletech/bladewatch/server/IpcTokenManager.java#L54).
- WebSocket streaming path: [HttpServer.java:344](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L344), [HttpServer.java:1042](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L1042), [WebSocketStreamServer.java:19](../app/src/main/java/com/loabletech/bladewatch/streaming/WebSocketStreamServer.java#L19).
- Android WebView proxy bypass and cookie injection: `WebViewFragment.kt`, deleted in `BladeWatch-81g9.2` — recover from git history if the behaviour is ever needed again.
- Pear launch path, stream pump and topic: [PearLauncher.kt](../app/src/main/java/com/loabletech/bladewatch/launcher/PearLauncher.kt), [PearDaemon.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/PearDaemon.kt), [PearStreamPump.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/PearStreamPump.kt), [PearTopic.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/PearTopic.kt).
- Pear status over IPC: `pearStatus` in [TcpCommandServer.kt](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.kt), [PearStatus.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/PearStatus.kt).
