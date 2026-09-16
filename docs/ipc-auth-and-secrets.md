# IPC, Authentication & Secrets

How the **app process** (app UID, e.g. `u0_a85` / 10085) and the
**shell-launched daemons** (shell UID `2000`) authenticate to each other and
share secrets. This is the single most fragile seam in BladeWatch because the
two sides run under **different UIDs** and communicate only through files in
`/data/local/tmp` and loopback TCP. Get a file permission wrong and the symptom
is an opaque **"Camera unavailable" / "Auth unavailable"** in the UI with no
stack trace — so read this before touching auth, the IPC servers, or anything
that writes to `/data/local/tmp`.

## The UID split

| Process | UID | Can write `/data/local/tmp`? |
|---|---|---|
| CameraDaemon / Sentry daemons (`app_process`) | `shell` (2000) | yes |
| Android app (MainActivity, fragments) | app UID (e.g. 10085) | **no** (read-only, and only world/group-readable files) |

The app cannot write to `/data/local/tmp` and cannot read files that are mode
`600 shell`. Every cross-process file therefore has a deliberate permission.

## Cross-process files and their REQUIRED permissions

| File | Primary path (current) | Owner / mode | Why | Who reads it |
|---|---|---|---|---|
| config | `/storage/emulated/0/BladeWatch/data/bladewatch_config.json` | world-rw (`setReadable/Writable(true, false)`) | non-secret config | app + daemon (direct) |
| secrets | `/data/local/tmp/bladewatch_secrets.json` | `shell` `rw-------` (owner-only, and **actually enforced** — see below) | device secret, tunnel tokens, cloud creds | **daemon only**; app fetches values over IPC |
| IPC token | `/data/local/tmp/bladewatch_ipc_token` | `shell` `644` (world-readable) | shared token that authenticates loopback IPC | **app + daemon** — app MUST be able to read it |

> **Why the secrets file is back in `/data/local/tmp` (BladeWatch-078u).**
> It briefly lived at
> `/storage/emulated/0/Android/data/net.bladewatch.app/files/bladewatch_secrets.json`,
> and while there the documented `rw-------` was **not merely unenforceable, it
> was false**. That path is `sdcardfs`, which SYNTHESISES permissions from its
> mount options (`mask=6`, `gid=1015`) instead of storing them per file, so
> `chmod 600` is a silent no-op. Measured on the head unit:
>
> ```
> $ chmod 600 .../files/.perm_probe && ls -l .../files/.perm_probe
> -rw-rw---- 1 u0_a72 sdcard_rw          # unchanged
> $ chmod 600 /data/local/tmp/.perm_probe && ls -l /data/local/tmp/.perm_probe
> -rw------- 1 shell  shell              # takes effect
> ```
>
> and `shell` — a **non-owner uid** — could read the sdcardfs copy. The store
> now reads the sdcardfs path as a *legacy fallback* so an upgraded device
> keeps its paired `deviceSecret`, and `CameraDaemon` migrates it forward at
> startup (`SecretConfigStore.migrateFromLegacyIfNeeded()`), which deletes the
> exposed copy. Only the daemon can do that: `canWriteDirectly()` refuses any
> uid but 2000, and the app reaches secrets over token-gated IPC.
>
> **Do not move it back onto `/storage/emulated/**` for convenience.** Any path
> under that mount silently loses the owner-only property, which is what the
> IPC token's "not a trust boundary" reasoning depends on.
>
> **Path migration.** Config still lives in shared storage as its *primary*
> path, with a best-effort `/data/local/tmp` *legacy mirror*
> (`/data/local/tmp/bladewatch_config.json`, created `0666`) kept only for
> older hardcoded readers. The **IPC token stays in `/data/local/tmp`** — it is the
> one cross-process file that must be world-readable on a path both UIDs agree
> on regardless of external-storage state.

⚠️ **The `bladewatch_ipc_token` permission is load-bearing.** It is written by
`IpcTokenManager.generate()` ([IpcTokenManager.java](../app/src/main/java/com/loabletech/bladewatch/server/IpcTokenManager.java)).
A bare `new FileWriter(path)` creates it mode `600` (shell-only), which the app
cannot read — and then **every app→daemon IPC call fails silently**. The
generator explicitly `setReadable(true, false)` to make it `644`, and **repairs
the perms even when reusing an existing token** (`ensureWorldReadable()` on the
reuse path) in case a prior writer left the file `600`. Do not revert that
without an equivalent chmod.

⚠️ **`generate()` is IDEMPOTENT — it does NOT rotate the token each boot.** It
runs on every CameraDaemon startup. An existing well-formed token is *reused*
(loaded, cached, perms repaired); a fresh `SecureRandom` token is minted only
when the file is missing, empty, or malformed. This is deliberate: minting a new
token every boot meant any process still holding the previous one — the Android
app, or a **stale daemon that survived an app reinstall** (shell-launched
`app_process` daemons are detached, NOT bound to the package manager) — kept
presenting a token the new daemon rejected as `Unauthorized`, producing
"Camera unavailable" and trip stats stuck on "Loading…". The token lives in
`/data/local/tmp` (not the app data dir), so it survives uninstall; reusing it
keeps every process in agreement across daemon restarts and reinstalls.

## Secret-fetch flow (how the app gets a secret it cannot read)

```
App needs deviceSecret
  → SecretConfigBridge.getString("auth", "deviceSecret")
      → 1. directStore.canReadDirectly()? → directStore.getString(...)
      │      └─ FALSE for app UID (secrets file is owner-only, shell-owned)
      → 2. readViaIpc(...)                        // fallback
             → DaemonReadinessChecker.waitUntilReady(30_000)   // gate: don't poll a dead daemon
             → CameraDaemonClient.connect()        // up to 3 retries on IOException
                   → IpcTokenManager.refreshToken() // re-reads bladewatch_ipc_token (644) from disk
                                                     //   (NOT the cache) ← must be readable
                   → 127.0.0.1:19876 (TcpCommandServer): {"token": <token>} as first message
             → TcpCommandServer:
                   PeerCredentials.isTrusted(uid)? → IpcTokenManager.isValid(token)?
                   ├─ no  → "Unauthorized" → app gets null → "Auth unavailable"
                   └─ yes → request: secret_get → returns deviceSecret
```

- `SecretConfigBridge` ([SecretConfigBridge.kt](../app/src/main/java/com/loabletech/bladewatch/config/SecretConfigBridge.kt)) tries the direct read first (`canReadDirectly()`), then falls back to loopback IPC. The IPC path waits for daemon readiness (30 s) and retries up to 3×; on the main thread it is capped at 4 s to stay below the 5 s ANR threshold.
- `TcpCommandServer` (19876) and `SurveillanceIpcServer` (19877) require **both** a trusted caller UID and a valid IPC token on every request (added in the *IPC token management* change).
- The client sends `IpcTokenManager.refreshToken()` (a fresh disk read, not the process cache) as the first message, so a token the daemon rewrote since this process last cached one is picked up automatically — the self-healing path across a daemon restart / app reinstall.
- The IPC token is the **bootstrap**: if the app can't read the token file, the entire fallback path is dead, so secrets/JWTs are unavailable.

## Public (non-secret) config over IPC

`UnifiedConfigManager`'s store is a **separate** store from the secret one and
has its own command pair on 19876 (BladeWatch-hygs):

| Command | Does |
|---|---|
| `config_get_section` `{section}` | returns `{section: {…}}` — the section's current values |
| `config_put` `{section, key, value}` | merges one key into the section |

These exist because the Flutter APK (`net.bladewatch.flutter`) has no path to
`/storage/emulated/0/BladeWatch/data/bladewatch_config.json`, which is where the
Status-overlay and Privacy settings live. Reads go through the same typed
accessors `StatusOverlayService` itself uses (`getStatusOverlay()`,
`isTimingLogsEnabled()`, `isDebugLogsEnabled()`) so the DEFAULT for an absent key
is identical on both sides of the UID — `cameraVisible`/`tripVisible`/
`timingLogsEnabled` default true, `debugLogsEnabled` false.

**They are allow-listed, deliberately, and READ and WRITE have separate lists
(`BladeWatch-i2wv`).**

| Gate | Set | Sections |
|---|---|---|
| Write (`config_put`) | `PUBLIC_CONFIG_SECTIONS` | `statusOverlay`, `developerOptions` |
| Read (`config_get_section`) | `PUBLIC_CONFIG_READABLE_SECTIONS` | the two above **plus** `camera` |

Every other section is refused with `Section not exposed over IPC: <name>`, reads
included. Without that, `config_put` would be a generic "write anything to the
public config" primitive — enough to flip `network.lanHttpEnabled` (which decides
whether the HTTP server binds beyond loopback) or set
`surveillance.surveillanceEnabled` false, neither of which gets any validation on
this path.

`camera` is **readable but not writable**: the Diagnostics camera-probe tile needs
to read it, and putting it in the single old list would have handed every IPC
caller unvalidated *write* access to camera configuration to satisfy a read-only
tile. The read also **projects only `probedCameraId` and `manualOverride`** — the
raw section additionally carries `firmwareFingerprint`, `buildDisplay` and
`productDevice`, which are not returned. Anything that genuinely needs to change
camera config uses its purpose-built, validating command.

**If a new section needs to be reachable, add it to the narrower list that
actually covers the need, and only after checking what a caller could do with
every key in it.**

Both commands sit behind the same caller-UID gate and IPC token as `secret_*` —
they are not a separate trust boundary, just a narrower command.

No cross-process notification is needed after a write: `StatusOverlayService
.updateUI()` re-reads the config on every poll, and `UnifiedConfigManager
.loadConfig()` invalidates its cache on the file's mtime, so a write from the
daemon is visible to the app process (and vice versa) without a restart.

## Tunnel URL over IPC

`tunnelStatus` on 19876 (BladeWatch-m1po) answers
`{"status":"ok","running":<bool>,"url":<string|null>}`.

The Flutter APK cannot reach either place the service host keeps this value —
`TorController`'s in-memory `LiveData`, or `PreferencesManager`'s app-private
`SharedPreferences` — so the daemon reads tor's own files instead:
`/data/local/tmp/tor/hs/hostname` for the address and `/data/local/tmp/tor.log` for the
bootstrap state. No shell and no ADB: the daemon already runs as shell UID, the same UID
tor was launched under, and the hostname file is mode 600 so the app UID could not read it
anyway.

**The URL is gated on TWO things, and both are load-bearing.**

1. *The tunnel process is alive.* Liveness is an **argv[0]** match read from procfs, not a
   `pgrep -f` over whole command lines: `-f` matched any process that merely mentioned a
   daemon name, which defeated this gate (BladeWatch-xzhv — observed with a shell that
   only wrote to the tunnel's log file). `app_process --nice-name=<n>` overwrites argv[0]
   with the nice-name, and tor is exec'd by path, so the comparison is on the basename of
   argv[0], by exact equality — which also keeps `sentry_daemon` from matching
   `acc_sentry_daemon`. The binary is installed as `bladewatch_tor` so that basename is
   both distinctive and inside the kernel's 15-character cap on `comm`.

2. *tor has bootstrapped.* This gate is specific to Tor and did not exist for the previous
   tunnel, which only printed its URL once it was already live. tor writes `hs/hostname`
   about a second after its FIRST launch and then keeps it forever, reboots included, so
   the file says nothing about reachability. A cold start takes ~82 s to reach
   `Bootstrapped 100%` (~6 s warm), and publishing the address during that window would
   put an "online" QR code on the Dashboard for a service nothing can reach.

The bootstrap check reads the tail of `tor.log` — never the whole file, which cost 85 MB+
allocations in the implementation this replaces — and tracks the **latest** of
`Bootstrapped 0%` and `Bootstrapped 100%` rather than merely searching for 100%. tor
appends to one log across launches, so after a restart the previous run's success line sits
above the new run's start; taking the last one is what stops a restart republishing the
address early.

`running=true` with `url=null` is a real state (tor up, not yet reachable), not an error.
`DaemonChannel.tunnelStatus()` surfaces both fields, and the Dashboard renders that state
as "connecting" — with Tor it can last well over a minute, so collapsing it into "offline"
would tell the user there is no tunnel while one is actively coming up.

## Daemon enable/disable over IPC

`daemon_set_enabled` on 19876 takes `{type, enabled}` and answers
`{"status":"ok","enabled":<bool>,"killed":<int>}`.

**`type` is checked against a fixed allow-list before anything happens**
(`TcpCommandServer.TOGGLEABLE_DAEMONS`), and nothing from the request ever reaches a
shell. The PIDs it signals come from this server's own procfs scan, keyed by a process
name looked up from the enum — never from the wire.

The allow-list currently holds **TOR_TUNNEL alone** (BladeWatch-abcx), and the other
three are excluded for structural reasons, not missing work:

| Daemon | Why not |
|---|---|
| `CAMERA_DAEMON` | Hosts this server. Stopping it kills the socket answering the request, and the Flutter APK has no ADB, so nothing could start it again. |
| `SENTRY_DAEMON`, `ACC_SENTRY_DAEMON` | Core daemons. `DaemonStartupManager`'s health check relaunches them within 30 s unless they are in `userStoppedDaemons` — an in-memory set in the *app* process that the daemon cannot reach — so a stop here would silently undo itself. |

Enabling only **records the intent**: `DaemonStartupManager`'s health check performs the
launch through `TorLauncher` within ~30 s.
Disabling records the intent **and kills the process**, because that health check only
ever relaunches, never kills — without the kill the tunnel would keep serving until the
next reboot while the switch read "off".

The shared state is `UnifiedConfigManager`'s `daemons` section
(`{"TOR_TUNNEL": <bool>}`), which both APKs can reach. `DaemonStartupManager` prefers it
and falls back to `PreferencesManager` (app-private SharedPreferences, invisible to the
Flutter APK) when the key is unset, so an install predating the section keeps its
existing setting.

## Caller-UID gate (defence in depth on top of the token)

Because `bladewatch_ipc_token` is **world-readable by design** (the app UID must
read it), the token alone is not a trust boundary: any local process that can
read it could otherwise drive privileged IPC — `secret_get/put/delete` and
`config_put` on 19876, and `GET_VEHICLE_DATA`, `UPDATE_GPS`, `INSTALL_UPDATE`
on 19877. (The `shell` command — free-form `sh -c` as UID 2000 — was removed in
uy93.2; do not reintroduce it.)

Both servers therefore verify the **connecting socket's owning UID** before
processing any command, in addition to the token check:

```
accept() → PeerCredentials.resolvePeerUid(socket)   // map (clientPort, serverPort) → UID
         → PeerCredentials.isTrusted(uid)?
               ├─ no  → close socket, log "rejected untrusted peer uid=…", no command runs
               └─ yes → proceed to token check → command dispatch
```

- **Allow-list:** root (0), system (1000), shell/daemon (2000), and the
  BladeWatch app UID (resolved lazily from the app's package context and cached;
  matched on the per-user base app-id). Every other UID — including other
  installed apps — is rejected.
- **Transport:** a Java TCP `Socket` can't read `SO_PEERCRED`, so
  [PeerCredentials.java](../app/src/main/java/com/loabletech/bladewatch/server/PeerCredentials.java)
  locates the client's row in `/proc/net/tcp` / `/proc/net/tcp6` by its
  `(localPort, remotePort)` pair (unique for an established loopback connection)
  and reads the owning UID. The daemon runs as shell (2000), which retains read
  access to those procfs tables on Android 10+.
- **Fallback when context resolution fails:**  `resolveAppUid()` needs
  `CameraDaemon.getAppContext()` → `ApplicationInfo.uid`.  On BYD firmware where
  `createAppContext()` cannot create a full package context (e.g. `systemMain`
  times out), the fallback `PermissionBypassContext(null)` returns an empty
  `ApplicationInfo` with `uid=0`, so the app UID cannot be resolved.  In that
  situation `isTrusted()` does **not** reject the connection — it logs a warning
  and trusts any regular app UID (≥ 10000), letting the IPC-token gate provide
  primary security.  This is safe because:
  1. Both IPC servers bind exclusively to `127.0.0.1`.
  2. The bearer token is a 32‑char `SecureRandom` value.
  3. The token gate still rejects invalid/absent tokens after the UID check.
- An unresolved UID (-1) from a procfs lookup race (accept→procfs race) is still
  never trusted (fail-closed, after a brief retry to absorb the race).
- This is what gates the privileged `secret_*` / `config_put` / GPS / update
  commands — the 644 token is **not** loosened or changed.

## JWT + live-view flow

```
AuthManager.generateJwt()
  → loadFromConfig() → deviceSecret via SecretConfigBridge (above)
  → HMAC-SHA256(header.payload, deviceSecret)        // AuthManager.java
LiveStreamClient.runStream()                          // native live view
  → getJwt() ── null? → "Camera unavailable\nAuth unavailable"
  → POST http://127.0.0.1:8080/api/stream/enable   (Authorization: Bearer <jwt>)
  → POST /api/stream/view/<direction>
  → GET  /api/stream/quality                         (decoder width/height)
  → WebSocket ws://127.0.0.1:8080/ws?token=<jwt>
  → first binary frame = SPS+PPS (codec config), then H.264 NALs → MediaCodec → Surface
```

- HTTP/WebSocket server is on **8080**; the command/secret IPC server is on **19876**; surveillance IPC on **19877**. All bind to `127.0.0.1` (appear as `::ffff:127.0.0.1:<port>` in `/proc/net/tcp6`).
- `LiveStreamClient.getJwt()` returning null is reported as **"Auth unavailable"**; a `ConnectException` to 8080 is reported as **"Daemon not running"**.

## Auth init retry backoff

`AuthManager.initialize()` ([AuthManager.java](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java))
records `lastInitAttemptMs` when persistence fails and refuses to retry for at
least 3 seconds (`INIT_RETRY_INTERVAL_MS`).  Without this backoff the app can
hammer the daemon's IPC server with rejected connections at 1 Hz while waiting
for the daemon to finish booting and create the unified config file.  The
throttled log line looks like:

    AUTH: Throttling init retry — last attempt was 1123ms ago

## Failure modes → symptoms (debugging cheat sheet)

| Symptom | Likely cause | Check |
|---|---|---|
| "Camera unavailable / Auth unavailable" | app can't read `bladewatch_ipc_token` (mode 600) → IPC secret fetch fails | `ls -la /data/local/tmp/bladewatch_ipc_token` → must be `-rw-r--r--` |
| "Camera unavailable / Auth unavailable" + "Loading…" trip stats after a reinstall | stale daemon survived the reinstall holding an old token; would be fatal if `generate()` rotated — it does NOT (idempotent reuse) | confirm only one `byd_cam_daemon` is running; `cat /data/local/tmp/bladewatch_ipc_token` should match what the daemon expects (no rotation across restart) |
| "Camera unavailable / Auth unavailable" | daemon rejecting IPC token (`Unauthorized` in daemon log) | daemon log: no `Processing command: secret_get` arriving |
| Camera stuck "connecting" forever | ready sentinel missing/stale, or command port not accepting | `ls -la /data/local/tmp/camera_daemon.ready` (must exist, world-readable) AND `cat /proc/net/tcp6 \| grep 4DA4` (19876 listening) — `DaemonReadinessChecker` needs both |
| "Camera unavailable / Auth unavailable" | daemon rejecting the caller's UID | daemon log: `rejected untrusted peer uid=…`; if the app UID is wrongly rejected, app context wasn't ready so `PeerCredentials` couldn't resolve it — check `getAppContext()` is non-null; if UID ≥ 10000, verify fix from `PeerCredentials.isTrusted()` app‑UID fallback is present |
| "Camera unavailable / Daemon not running" | nothing listening on 8080 | `cat /proc/net/tcp6 \| grep 1F90` |
| CameraDaemon crashes on boot (`UnsatisfiedLinkError`) | JNI symbol names don't match the runtime package after a package rename | `grep -r Java_<pkg> app/src/main/cpp/` must match `applicationId` |
| "Another CameraDaemon instance is already running" | stale lock from a hung daemon | kill daemon + `rm /data/local/tmp/camera_daemon.lock` (see CLAUDE.md clean reinstall) |

## Rules for future changes (prevent regressions)

1. **Any file the app must read from `/data/local/tmp` must be world- or group-readable.** Never rely on a bare `FileWriter`/`FileOutputStream` for such files — they default to mode `600`. chmod (`setReadable(true, false)` or `Files.setPosixFilePermissions`) immediately after writing.
2. **Secrets the app must NOT read directly stay owner-only** (`rw-------`) and are fetched over IPC (the token-gated `secret_get` path). Don't loosen `bladewatch_secrets.json`, and don't move it onto `/storage/emulated/**` — that mount cannot enforce the mode at all (BladeWatch-078u).
3. **The IPC token must be readable by the app** — it is the bootstrap for the whole secret/JWT chain. Keep it `644`; the real trust boundary is the caller-UID gate below, **not** the token.
4. **Keep `IpcTokenManager.generate()` idempotent.** It runs every daemon boot; it must reuse an existing well-formed token (and only repair its perms), not rotate it. Rotating each boot strands any process still holding the old token (the app, or a stale reinstall-surviving daemon) with `Unauthorized` failures and "Camera unavailable". Clients re-read via `refreshToken()`, but only the daemon mints — so the daemon must not churn the value.
5. **Don't weaken the caller-UID gate for resolved UIDs.** Both IPC servers reject any peer whose UID is not root/system/shell/app (`PeerCredentials.isTrusted`). If you add a new local client (another daemon UID), add it to the allow-list rather than removing the check. The gate must stay fail-closed on an unresolved UID **from a procfs race**; but when the app UID itself cannot be resolved (`createAppContext` returned a null-safe fallback), it falls back to trusting any app UID (≥ 10000) with a warning — the token gate remains active.
6. **JNI symbol names must track `applicationId`.** A package rename (e.g. `com.loabletech.bladewatch` → `net.bladewatch.app`) requires renaming every `Java_<pkg>_…` symbol in `app/src/main/cpp/`, or the daemon dies with `UnsatisfiedLinkError` at startup and the camera is unavailable.
7. **Rebuild AND clean-reinstall after native or daemon changes** — shell-launched daemons survive an `install -r`; a stale daemon with the old `.so` keeps running. See the clean-reinstall block in `CLAUDE.md`.
