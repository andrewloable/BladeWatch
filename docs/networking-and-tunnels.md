# Networking and Tunnels

BladeWatch exposes a local authenticated web server and can optionally front it with LAN access or a Tor onion service. The onion service is the only supported remote tunnel, and no proxy layer sits between tor and the local server.

## Local Ports

| Port | Bind | Component | Purpose |
| --- | --- | --- | --- |
| `19876` | `127.0.0.1` | `TcpCommandServer` | JSON command IPC for camera daemon control and secret bridge |
| `19877` | `127.0.0.1` | `SurveillanceIpcServer` | JSON IPC for surveillance, GPS, and update actions |
| `8080` | `127.0.0.1` by default | `HttpServer` | Web UI, REST APIs, ConnectRPC (`/bladewatch.v1.*`), video, thumbnails, WebSocket streaming |

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

Default bind:

```text
127.0.0.1:8080
```

LAN mode bind:

```text
0.0.0.0:8080
```

LAN mode is disabled by default and controlled by unified network config
(`UnifiedConfigManager.isLanHttpEnabled()`). `GET /status` echoes the active
bind (`httpBind`) and a warning when LAN HTTP is on.

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
HiddenServicePort 80 127.0.0.1:8080
Log notice file /data/local/tmp/tor.log
```

`SocksPort 0` because BladeWatch runs tor purely as a *service*; a listener would be an
open proxy on the head unit that nothing uses. `DataDirectory` and `HiddenServiceDir` are
created mode 700 — tor refuses to start if either is group- or world-accessible, and says
so only in a log nobody is watching yet. No bridges and no pluggable transports are
configured: the head unit reached guards on 443/9001 with no interference.

The service is plain HTTP on onion port 80, forwarding to `http://127.0.0.1:8080` with no
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
