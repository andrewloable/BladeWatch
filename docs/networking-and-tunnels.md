# Networking and Tunnels

BladeWatch exposes a local authenticated web server and can optionally front it with LAN access or a Tor onion service. v1.4.0.0 is replacing the onion service with a Pear (Hyperswarm) peer — see [Pear Peer](#pear-peer-hyperswarm) below; until tor is removed both exist, each opt-in. No proxy layer sits between either one and the local server.

## Local Ports

| Port | Bind | Component | Purpose |
| --- | --- | --- | --- |
| `19876` | `127.0.0.1` | `TcpCommandServer` | JSON command IPC for camera daemon control and secret bridge |
| `19877` | `127.0.0.1` | `SurveillanceIpcServer` | JSON IPC for surveillance, GPS, and update actions |
| `8080` | `127.0.0.1` **always** | `HttpServer` | Web UI, REST APIs, ConnectRPC (`/bladewatch.v1.*`), video, thumbnails, WebSocket streaming. Listener trust `LOCAL_APPS` |
| `8081` | `127.0.0.1` **always** | `HttpServer` | tor's way in: the onion service forwards here. Same routes as 8080, listener trust `REMOTE` |
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

`GET /status` reports `httpBind` (always `127.0.0.1`), `lanHttpEnabled` (the
opt-in), and `lanTls: {enabled, port, listening}`.

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
to the listener, not to the peer address. A loopback address proves nothing: tor
connects from `127.0.0.1`, and so does the Pear stream pump. Only `LOCAL_APPS`
(8080) can reach the Tier 2 loopback safety net or skip the vehicle-action second
factor; every other listener is `REMOTE`. `checkAuth` overloads that do not name a
listener assume `REMOTE`, so a listener added later fails closed.

The tunnels therefore enter on their own loopback listeners, never on 8080: tor on
**8081** (BladeWatch-ur11 -- tor used to land on 8080, so every remote request over it
skipped the vehicle-control second factor) and the Pear pump on the TLS listener **8444**
(BladeWatch-rdtj.6/.8). That keeps
a remote peer out of the in-car UI's privileges by construction, not by remembering to
mark a tunnel as active.

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
transport replacing tor. It hosts a bare-kit worklet running pear-end and joins this car's
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
fix -- flutter_pear 0.4.3 or later; 0.4.2's does not work. The car's copy is byte-identical to the one
inside the published 0.4.3 package (the companion is pinned to 0.4.3 too). Only the car needs it -- a companion is normally the dialing side,
and when it is not, its own lookup right after joining tags the connection in seconds -- and it
changes nothing on the wire, so a fixed car works with a 0.4.2 companion. With it, the first
pinned handshake through Pear took 11.3 s and the whole route 19.9-25 s (same network, public
DHT, 2026-09-24): the car's tagging query is most of that.

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

## Tor Onion Service

`TorLauncher` installs and runs tor from the packaged `libtor.so`, and the onion service
is the only remote tunnel. Cloudflared, Tailscale, sing-box and the previous tunnel are
all absent from this codebase.

### How the binary gets here

Unlike the tunnel it replaced, the binary is **not committed**. The `downloadTor` Gradle
task fetches tor 0.4.8.14 from `org.briarproject:tor-android` on Maven Central, verifies
its SHA-256 and writes it to `jniLibs/arm64-v8a/libtor.so` — the same verified-download
pattern OpenH264 and OpenCV already use. Android extracts anything in `jniLibs` to the
app's nativeLibraryDir with the execute bit set, which is the only way to ship a runnable
binary to a non-rooted head unit. `TorBinaryPackagingTest` fails the build if it is
missing or its checksum drifts.

### Runtime paths

```text
/data/local/tmp/bladewatch_tor    the binary, installed under its own process name
/data/local/tmp/tor/torrc         generated config, rewritten on every launch
/data/local/tmp/tor/data          consensus cache (safe to delete; costs a slow start)
/data/local/tmp/tor/hs            hidden-service directory — see the warning below
/data/local/tmp/tor.log           notice log; the bootstrap gate reads this
```

The process name is `bladewatch_tor` rather than `tor`: liveness is decided by
`basename(argv[0])` and a bare `tor` is generic enough to collide, while 14 characters
keeps it inside the kernel's 15-character cap on `/proc/<pid>/comm` so `killall` still
matches it in full.

### Configuration

```text
SocksPort 0
DataDirectory /data/local/tmp/tor/data
HiddenServiceDir /data/local/tmp/tor/hs
HiddenServicePort 80 127.0.0.1:8081
Log notice file /data/local/tmp/tor.log
```

`SocksPort 0` because BladeWatch runs tor purely as a *service*; a listener would be an
open proxy on the head unit that nothing uses. `DataDirectory` and `HiddenServiceDir` are
created mode 700 — tor refuses to start if either is group- or world-accessible, and says
so only in a log nobody is watching yet. No bridges and no pluggable transports are
configured: the head unit reached guards on 443/9001 with no interference.

The service is plain HTTP on onion port 80, forwarding to `http://127.0.0.1:8081` -- the
`REMOTE` loopback listener, not the in-car UI's 8080 (BladeWatch-ur11) -- with no
intermediate proxy. That is correct rather than a downgrade: the onion protocol already
encrypts end to end and authenticates the service by its key, so there is no TLS to add
and no certificate to pin.

### The address is permanent, and its key is a secret

The onion address is derived from `hs/hs_ed25519_secret_key`, so it survives restarts and
reboots unchanged. There is no account, no token, no per-device registration and no
free-tier device limit — all four were requirements of the tunnel this replaced.

**That key IS the car's remote-access identity.** Never log it, copy it to shared storage,
return it over IPC, or commit it. Deleting it is not recoverable: tor mints a new address
on the next start, silently invalidating every QR code the owner has ever scanned. Both
`TorLauncher.stopCommand()` and `DaemonHardReset.hardResetCommand()` are deliberately
written never to remove that directory, and both have tests asserting they do not.

### Measured behaviour on the head unit (2026-09-14)

| | |
|---|---|
| Cold bootstrap | ~82 s to `Bootstrapped 100%` |
| Warm restart (populated DataDirectory) | ~6 s |
| Throughput | 62–75 KB/s |
| Warm request TTFB | 2.1–6.5 s |
| First connect from a cold client | 49 s |
| H.264 WebSocket on `/ws` | sustained 216 kbit/s for 20 s, no stall |
| Cost on device | ~65 MB RSS, ~5% CPU |

Two caveats worth knowing before diagnosing a "bug":

- After the tunnel restarts, a client that was **already** connected can stay broken for
  several minutes on stale introduction points, while a fresh client connects
  immediately. That is ordinary Tor behaviour.
- The address only opens in Tor Browser (or Onion Browser on iOS). Chrome and Safari fail
  with an unhelpful DNS error, which is why the Dashboard ships a help dialog explaining
  the per-platform install.

### Still-frame fallback for decoder-less browsers (BladeWatch-y78o.1)

`GET /api/stream/still` serves a periodically refreshed JPEG of the full 4-camera mosaic
(640×480, quality 80) for browsers that can decode neither WebCodecs nor MSE H.264 — Tor
Browser on Linux is the documented case (see `docs/evaluations/overdrive-remote-communication.md`
and friends for why: Firefox borrows the platform's H.264 decoder and Linux has none by
default). The web client (`web/src/app/pages/live/still-frame-player.ts`) selects this tier
automatically — see `stream-tier.ts` — and shows a persistent "still image, not live video"
banner so the owner never mistakes a stale frame for a live one.

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
the documented **101 KB/s** sustained onion throughput
(`docs/evaluations/overdrive-remote-communication.md`), a 5-second refresh costs ~24 KB/s —
about a quarter of the budget, leaving headroom for the rest of the page. A 2-second refresh
would use ~60%, too tight; 5 seconds was chosen as the default for that reason.

### Reading the current tunnel URL

The Flutter UI is a different APK and cannot read the service host's in-memory state or
its app-private `SharedPreferences` even under the shared UID, so it asks the daemon over
IPC: `{"cmd":"tunnelStatus"}` on 19876. The daemon already runs as shell UID — the same
UID tor runs under — so it reads tor's files directly, with no shell and no ADB.

**The response is gated on two things, and both matter.** The process must be alive, and
tor must have reached `Bootstrapped 100%` on its *current* run. The second gate is new
with Tor: `hs/hostname` is written about a second after the very first launch and then
persists forever, reboots included, so its presence says nothing about reachability.
Publishing the address during the ~82 s cold-start window would put an "online" QR code on
screen for a service nothing can reach. Until then the daemon answers `running: true` with
`url: null`, which the Dashboard renders as connecting.

Because tor appends to one log across launches, the gate tracks the *latest* of
`Bootstrapped 0%` and `Bootstrapped 100%` rather than merely searching for 100% — an old
success line sits above the new run's start. See
[ipc-auth-and-secrets.md](ipc-auth-and-secrets.md) for the response shape.

## BladeWatch's Own Network Usage (BladeWatch-t1lg.1)

On a metered head-unit SIM, streaming a live view or serving the web UI over the onion service
costs real money, and nothing previously told the owner what it costs. `NetworkMonitor` now
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
2. Authenticated Tor onion service.
3. LAN mode only when needed and trusted.

Risk notes:

- LAN mode binds all interfaces and should remain disabled by default.
- The onion address is a **capability URL, not authentication**. Password/JWT auth in
  front of the web server stays mandatory: anyone who learns the address can reach the
  car, and the address is all they need to get that far.
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
- Tor launch path and configuration (only `libtor.so` ships in `jniLibs/arm64-v8a/`, and it is downloaded at build time, not committed): [TorLauncher.kt:44](../app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt#L44), [TorLauncher.kt:92](../app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt#L92), [TorLauncher.kt:111](../app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt#L111).
- Tunnel status and the bootstrap gate: [TcpCommandServer.java:569](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L569), [TcpCommandServer.java:842](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L842), [TcpCommandServer.java:878](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L878).
