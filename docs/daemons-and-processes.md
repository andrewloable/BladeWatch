# Daemons and Processes

BladeWatch is built around long-running processes that survive normal Android UI lifecycle changes. Android components start and supervise shell-launched daemons, while local TCP and HTTP servers provide control and data access.

## Android Components

### Application

`BladeWatchApplication` initializes:

- Locale.
- Theme.
- Logging.
- Preferences.
- Foreground keepalive service startup.

### Activities

- `MainActivity`: the **startup bootstrap**, not UI. Since Phase 4 it extends
  `Activity`, never calls `setContentView`, and calls `moveTaskToBack(true)`
  immediately. It has **no launcher `intent-filter`** — `net.bladewatch.flutter`
  is the only launcher icon — but stays `exported="true"` so
  `am start -n net.bladewatch.app/.ui.MainActivity` remains the ADB recovery path.
  It is started in normal operation by the Flutter APK's `wakeServiceHost()` on
  first resume. `ServiceHostManifestTest` pins both manifest properties.
- `BlockerActivity`: internal activity.
- `LocationStarterActivity`: internal activity.

### Receivers

- `BootReceiver`: handles boot, screen/user actions, power events, network changes, BYD ACC events, and package replacement.
- `ProcessRevivalReceiver`: internal explicit receiver used to revive processes.
- `LocationBootReceiver`: starts location-related behavior at boot.

### Foreground and Accessibility Services

- `DaemonKeepaliveService`: sticky foreground service, wake lock holder, daemon kickoff, process revival scheduling, status overlay coordination.
- `LocationSidecarService`: foreground location service that sends GPS to daemon IPC.
- `StatusOverlayService`: overlay status display.
- `KeepAliveAccessibilityService`: accessibility-backed keepalive support.

## Boot and Revival Behavior

`BootReceiver` responds to:

- Boot completion.
- Locked boot completion.
- Screen and user-present events.
- Power connected/disconnected.
- BYD ACC events.
- Network and Wi-Fi changes.
- Package replacement.

Normal boot behavior starts the keepalive service and schedules daemon startup. Package replacement is handled specially: the receiver launches `MainActivity` with a post-update flag and does not start daemons directly. This lets update recovery perform a cleaner daemon reset.

`DaemonKeepaliveService`:

- Starts in the foreground.
- Acquires a partial wake lock.
- Registers screen-off handling.
- Schedules process revival.
- Starts daemon launch after boot unless post-update reset is pending.
- Coordinates status overlay startup.

## Daemon Startup Manager

`DaemonStartupManager` is the main orchestrator.

Core daemons:

- `CAMERA_DAEMON`.
- `SENTRY_DAEMON`.
- `ACC_SENTRY_DAEMON`.

Optional daemons:

- `TOR_TUNNEL`.

Startup timing (measured from app launch / boot):

- Core daemon startup is delayed around `45 seconds` (system stabilization).
- Optional daemon startup is delayed around `60 seconds`.
- Health checks begin around `90 seconds`.
- Health checks repeat every `30 seconds` (`HEALTH_CHECK_INTERVAL_MS`).
- Within the core group, daemons are further staggered: Camera daemon first, Sentry daemon `+5 s`, ACC sentry daemon `+10 s`.

The manager tracks daemons intentionally stopped by the user (`userStoppedDaemons`) so health checks do not immediately restart them. The user-stopped set is cleared on each fresh app launch / boot.

The health check is stale-aware for the camera daemon: instead of a plain process-exists check it runs the full launch flow, which verifies **both** process existence (`ps`) and port responsiveness (`nc -z`), so a hung daemon that `ps` shows but won't accept connections is killed and relaunched, while transient ADB blips do not trigger false relaunches.

`DaemonKeepaliveService` is the boot entrypoint into the manager (`startOnBoot`), but it **skips** daemon startup when a post-update launch is in progress — in that case `MainActivity` is the sole orchestrator (it runs `UpdateLifecycle.hardResetDaemons` first, then `initializeOnAppLaunch`) to avoid racing two 45 s schedules and overlapping camera handles on the AVMCamera HAL.

## Shell Launch Layer

`AdbDaemonLauncher` coordinates:

- `AdbShellExecutor`.
- `DaemonLauncher`.
- `ServiceLauncher`.

It can start:

- Camera daemon.
- Sentry daemon.
- ACC sentry daemon.
- Tor tunnel.
- Android sidecar services.

It also applies selected power, location, ACC whitelist, and Wi-Fi settings.

## Java Daemon Bootstrap

`DaemonBootstrap` is the `app_process` entrypoint used by Java daemons.

Responsibilities:

- Create an Android application context from low-level framework APIs.
- Use package `com.loabletech.bladewatch`.
- Grant or bypass permissions where possible.
- Wrap context permission checks so daemons can function from shell context.
- Dispatch into daemon entrypoints.

## Camera Daemon

`CameraDaemon` is the central daemon. Its startup sequence:

1. Singleton enforcement: a port-in-use probe (`anyPortInUse()`) plus a `FileLock` on `/data/local/tmp/camera_daemon.lock`. If either indicates a live instance, the new process exits ("Another CameraDaemon instance is already running").
2. Deletes any stale ready sentinel left by a previous crash.
3. Generates the shared IPC token via `IpcTokenManager.generate()` **before** starting servers (idempotent — reuses an existing well-formed token, see `ipc-auth-and-secrets.md`).
4. Starts the three local servers:
   - TCP command server on `127.0.0.1:19876`.
   - HTTP server on `127.0.0.1:8080` by default.
   - Surveillance IPC server on `127.0.0.1:19877`.
5. Initializes ACC monitor, GPU camera and surveillance pipeline, recording/streaming state, unified config, auth state, storage manager, web asset extraction, native libraries, BYD data collector, trip analytics, telemetry collector, and Web Push notifications.
6. Confirms `TCP_PORT` is actually accepting connections (polls up to 5s), then writes the ready sentinel.

The daemon uses an Android Looper and defensive retry handling around BYD listener paths because some firmware listeners can fail or crash unexpectedly.

### Ready sentinel and readiness probe

The daemon signals "startup complete" by writing its PID to a sentinel file:

```text
/data/local/tmp/camera_daemon.ready
```

It is written world-readable (`644`, via `setReadable(true, false)`) so the app UID can stat it. A stale sentinel left by a `kill -9`'d daemon is the reason readiness is **not** decided by the sentinel alone.

`DaemonReadinessChecker` (app-side, [DaemonReadinessChecker.java](../app/src/main/java/com/loabletech/bladewatch/client/DaemonReadinessChecker.java)) decides readiness with two checks:

- The sentinel exists and is non-empty, AND
- a short-lived TCP connect to `127.0.0.1:19876` (the command port) succeeds (`PROBE_TIMEOUT_MS = 1000`).

The TCP connect is the authoritative liveness signal — it is UID-independent and survives the head unit's `hidepid=2,gid=3009` `/proc` mount (the app UID cannot see the shell-owned daemon's `/proc` entry, so a `/proc/<pid>` check would always fail). A connect also catches the stale-sentinel case (a dead daemon refuses the connect).

`waitUntilReady(timeoutMs)` polls every 500 ms and logs progress every 5 s. It is used by `CameraDaemonClient.connect()` (60 s for cold-boot callers, 2 s for mid-session reconnects) and by `SecretConfigBridge` (30 s) before any IPC read/write.

### Recording mode manager

`RecordingModeManager` ([RecordingModeManager.java](../app/src/main/java/com/loabletech/bladewatch/recording/RecordingModeManager.java)) coordinates four mutually-exclusive modes (`NONE`, `CONTINUOUS`, `DRIVE_MODE`, `PROXIMITY_GUARD`) driven by ACC state and gear.

`ChargingDetector`'s fused charging state (`BladeWatch-nmao.1`) is an additional input: `CONTINUOUS` and `DRIVE_MODE` are suppressed while the fused detector reports charging, so a spurious non-P gear read at a wallbox cannot start a drive recording. `PROXIMITY_GUARD` is deliberately excluded — a car at a public charger is exactly when radar triggers matter most. The decision is a pure static, `RecordingModeManager.isSuppressedByCharging(Mode, boolean)`, consulted once at the top of `activateMode` so every activation path (constructor auto-activate, `setMode`, ACC-on, gear-change, and hardware resync) is gated the same way without duplicating the check. `RecordingModeManager` seeds the flag from `ChargingDetector.getInstance().isCharging()` at construction (a daemon that boots already plugged in starts suppressed) and subscribes/unsubscribes a `FusedStateListener` in its constructor/`shutdown()`; on the charging-started edge it deactivates the running mode immediately, and on charging-ended it retries activation through the same warmup path the constructor and resync use, so a still-open pipeline resumes recording with no teardown.

## TCP Command Server

`TcpCommandServer` listens on:

```text
127.0.0.1:19876
```

It accepts JSON commands for local control. Known command areas include:

- Start and stop recording.
- Status and ping.
- Output path.
- Shutdown.
- Start and stop streaming.
- Quality and bitrate.
- Recording mode.
- Storage.
- Auth invalidation.
- Secret get, put, delete, and section operations.
- Public (non-secret) config read/write, allow-listed to the `statusOverlay` and
  `developerOptions` sections (`config_get_section`, `config_put`).
- Daemon process liveness (`daemonStatus`) and the Tor onion URL (`tunnelStatus`, gated on tor having bootstrapped).
- Enable/disable an optional daemon (`daemon_set_enabled`), allow-listed to
  `TOR_TUNNEL`.

The last four exist because the Flutter UI ships as a separate APK with no ADB; each is
deliberately narrow rather than a general-purpose escape hatch. See
`ipc-auth-and-secrets.md` for the allow-lists and why the other daemons are excluded.

Liveness (`daemonStatus`, and the gate inside `tunnelStatus`) is an **argv[0]** match read
from procfs, not a `pgrep -f` over whole command lines — `-f` matched any process that
merely mentioned a daemon name.

Every connection is gated twice before any command runs: the connecting socket's owning UID must be trusted (`PeerCredentials.isTrusted`), and the first message must carry a valid IPC token (`IpcTokenManager.isValid`). See `ipc-auth-and-secrets.md`.

`CameraDaemonClient` is the app-side client for this interface. Before connecting it calls `DaemonReadinessChecker.waitUntilReady(...)` so it does not poll a not-yet-listening port, retries `connect()` up to 3× on `IOException` (connection refused / slow accept), and sends `IpcTokenManager.refreshToken()` (a fresh on-disk read, not the cache) as the first message so it never presents a token cached before the daemon's last (re)write.

## Surveillance IPC Server

`SurveillanceIpcServer` listens on:

```text
127.0.0.1:19877
```

It accepts local JSON commands used by the app, location sidecar, update flows, and surveillance controllers. Known command areas include:

- Start, stop, and status.
- Enable and disable surveillance.
- GPS update.
- Update install actions.

Like the TCP command server, each request is gated by both the caller-UID check (`PeerCredentials.isTrusted`) and a valid IPC token (`IpcTokenManager.isValid`).

The server uses a fixed thread pool (8 threads) for concurrent local requests.

## HTTP Server

`HttpServer` listens on:

```text
127.0.0.1:8080
```

If LAN HTTP is explicitly enabled, it binds:

```text
0.0.0.0:8080
```

Responsibilities:

- Serve extracted web app assets.
- Serve static local and shared assets.
- Serve recording videos and thumbnails.
- Enforce auth middleware.
- Handle REST APIs.
- Handle WebSocket upgrades for streaming.
- Expose auth endpoints.
- Extract web and support assets from the APK.

## Location Sidecar Service

`LocationSidecarService` is an Android foreground service. It:

- Reads Android location updates.
- Caches GPS state in app files as `gps_cache.json`.
- Sends GPS JSON to `127.0.0.1:19877`.
- Uses the `UPDATE_GPS` surveillance IPC command.
- Sends updates roughly every two seconds while active.

## Tor Tunnel Process

The Tor onion service is the sole remote-access tunnel. `TorLauncher` copies the binary out
of the packaged `libtor.so` to `/data/local/tmp/bladewatch_tor` and runs it as a shell-UID
subprocess, like every other daemon. The binary is downloaded and SHA-256-verified at build
time by `downloadTor`, not committed.

Runtime paths:

```text
/data/local/tmp/bladewatch_tor    the binary, installed under its own process name
/data/local/tmp/tor/torrc         generated config, rewritten on every launch
/data/local/tmp/tor/data          consensus cache (safe to delete; costs a slow start)
/data/local/tmp/tor/hs            hidden-service directory — NEVER delete, see below
/data/local/tmp/tor.log           notice log; the tunnelStatus bootstrap gate reads this
```

It fronts the local HTTP server at `http://127.0.0.1:8080` as a v3 onion service on port 80,
with no intermediate proxy layer. There is no account, token or registration, and the
address is permanent because it is derived from a key in the hidden-service directory.

The process is named `bladewatch_tor`, not `tor`: liveness is decided by
`basename(argv[0])`, a bare `tor` could collide, and 14 characters stays inside the
kernel's 15-character cap on `/proc/<pid>/comm` so `killall` matches it in full. That cap
matters in practice — when stopping the tunnel by hand use `killall -9 bladewatch_tor`, not
`pkill -9 -f`: toybox `pkill -f` matches the pattern as a literal substring of every
process's cmdline, including the ADB shell running your own kill script, so it kills that
shell mid-procedure.

**`/data/local/tmp/tor/hs` holds `hs_ed25519_secret_key`, which IS the car's permanent
onion address.** Killing the process is fine and reversible; deleting that directory is
not — tor mints a new address on the next start and every QR code ever scanned stops
working.

Startup timing measured on the head unit: ~82 s from a cold start to `Bootstrapped 100%`,
~6 s on a restart with a populated `DataDirectory`. `tunnelStatus` reports
`running: true, url: null` throughout that window.

## Conditional Polling

`ConditionalPoller<T>` (BladeWatch-t1lg.2) polls a value only while at least one subscriber
wants it: zero subscribers means no scheduled task exists at all (not a task that returns
early — a no-op task still wakes the CPU). The first `subscribe()` starts the schedule and
samples immediately so the first subscriber does not wait a full interval; the last `close()`
cancels it. Modelled on Overdrive's `ConditionalPoller` (`docs/evaluations/overdrive-automations.md`)
— the one piece of that project's automation subsystem that pays for itself with none of the
rest, which is why it is here and no automation engine is.

First (and, deliberately, only — a sweep of every fixed-rate poller in the daemon is a
separate issue once this has run on a car for a while) converted caller:
`ChargingEventNotifier`'s SOC-during-charging poll (10s interval — the shortest-interval
fixed-rate/fixed-delay task in the daemon whose consumer is clearly identifiable and outside
the camera/recording/vehicle-telemetry hot path; `PerformanceMonitor`, `BydDataCollector`,
`TelemetryDataCollector`, `SocHistoryDatabase`, and the `StorageManager`/`ExternalStorageCleaner`
watchdogs were all considered and rejected — see BladeWatch-t1lg.2's close reason for why each
one). `startSocPoller()`/`stopSocPoller()` now subscribe/close a `ConditionalPoller<BydVehicleData>`
instead of hand-rolling a `ScheduledFuture`, still driven by the same charging-session lifecycle
(`onFusedEdge`) as before.

## Detection Rate Scaling

`PipelineRateController` (BladeWatch-t1lg.3) is the transition owner that changes how hard the
detection pipeline works, mid-session, without dropping the encoder or tearing down the EGL
context. `RecordingModeManager` already decides *whether* to record based on ACC/gear; this
decides how much *surveillance/detection* work happens once something is running — recording
quality itself (resolution, codec, bitrate, the encoder) is never touched.

**Policy** (`targetFps`, a pure function — no camera, no EGL, no Android):

1. A live viewer attached, or motion in the last 5 minutes → full configured rate, always. A
   viewer or recent motion overrides everything else.
2. ACC on (driving) → the driving rate (default 5 fps).
3. ACC off, parked, quiet → the idle rate (default 2 fps).
4. The result never exceeds the user's configured recording fps — a "power saving" mode that
   raises the frame rate would be absurd.

Both rates are configurable via `UnifiedConfigManager`'s `camera` section
(`detectionDrivingFps`, `detectionIdleFps`), read the same way
`GpuSurveillancePipeline.loadTargetFps()` reads `camera.targetFps`.

**Wiring** — three inputs, no new listeners:

- **ACC**: `RecordingModeManager.onAccStateChanged()` forwards the edge to
  `PipelineRateController.getInstance().setAccOn(...)` — the same ACC source
  `RecordingModeManager` already listens to, not a second listener.
- **Motion**: `SurveillanceEngineGpu.processFrameV2()`'s `anyMotion` block calls
  `onMotionDetected()`, which applies the full rate synchronously (not on the next scheduled
  tick) and (re)starts a 5-minute one-shot timer that calls `clearRecentMotion()` if nothing
  further happens.
- **Live viewer**: `PipelineRateController` itself polls
  `GpuSurveillancePipeline.getWebSocketServer().hasActiveClients()` every 15s on its own
  injected scheduler (no standalone `WebSocketStreamServer` singleton exists to push from).

**The actuator, and why it can't touch the encoder**: `PipelineRateController` never reaches
the camera HAL or the encoder. It calls `PanoramicCameraGpu.setDetectionRate(fps)`, which
delegates to `AiLaneWorker.setDetectionRate(fps)` — a wall-clock throttle (`fps <= 0` disables
it) applied in `AiLaneWorker.submitFrame()`, *before* a frame is even accepted for
`SurveillanceEngineGpu.processFrame()`. This is deliberately not the same path as
`PanoramicCameraGpu.setTargetFps()`, which reaches `AvmCameraHelper.setCameraFps()` on the live
camera HAL and the encoder's `KEY_FRAME_RATE` — reusing it for automatic, frequent ACC-driven
scaling would mean an encoder reinit on every drive-to-park transition, which is exactly the
disruption this feature exists to avoid. Because throttling happens purely by dropping some
frames before they reach the motion pipeline (the same recycle-on-drop path `AiLaneWorker`
already uses when busy), the native pipeline's own state — confidence history, quadrant state,
tracker continuity — is never reset by a rate change.

**Not yet verified on a device**: the unit tests prove the decision logic and that the
transition owner calls only the rate setter, never a teardown/re-init/release method on its
target. They cannot prove the EGL/encoder survive a real ACC on→off transition on the actual
hardware — that requires a car. See BladeWatch-t1lg.3's status.

## Process Interaction Summary

```text
BootReceiver / MainActivity (woken by the Flutter APK)
  -> DaemonKeepaliveService
  -> DaemonStartupManager
  -> AdbDaemonLauncher
  -> app_process Java daemons and the extracted tor native binary

Flutter in-car UI (net.bladewatch.flutter, same UID)
  -> TCP 19876 (privileged ops, via its own Kotlin MethodChannels)
  -> HTTP 8080 (all 109 ConnectRPC methods, JWT-authenticated)

Location sidecar / app helpers
  -> TCP 19877 surveillance IPC

Browser or tunnel client
  -> HTTP/WebSocket 8080

Camera daemon
  -> BYD local APIs, storage, Web Push notifications, trips
```

## Source References

- Android components declared in manifest: [AndroidManifest.xml:207](../app/src/main/AndroidManifest.xml#L207), [AndroidManifest.xml:255](../app/src/main/AndroidManifest.xml#L255), [AndroidManifest.xml:306](../app/src/main/AndroidManifest.xml#L306), [AndroidManifest.xml:312](../app/src/main/AndroidManifest.xml#L312), [AndroidManifest.xml:327](../app/src/main/AndroidManifest.xml#L327).
- Application, activity, receivers, and foreground services: [BladeWatchApplication.kt:18](../app/src/main/java/com/loabletech/bladewatch/BladeWatchApplication.kt#L18), [MainActivity.kt:46](../app/src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt#L46), [BootReceiver.kt:24](../app/src/main/java/com/loabletech/bladewatch/receiver/BootReceiver.kt#L24), [ProcessRevivalReceiver.kt:29](../app/src/main/java/com/loabletech/bladewatch/receiver/ProcessRevivalReceiver.kt#L29), [LocationBootReceiver.kt:14](../app/src/main/java/com/loabletech/bladewatch/receiver/LocationBootReceiver.kt#L14), [DaemonKeepaliveService.kt:30](../app/src/main/java/com/loabletech/bladewatch/services/DaemonKeepaliveService.kt#L30), [LocationSidecarService.java:32](../app/src/main/java/com/loabletech/bladewatch/services/LocationSidecarService.java#L32).
- Daemon startup and shell launch: [DaemonStartupManager.kt:15](../app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt#L15), [DaemonStartupManager.kt:73](../app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt#L73), [DaemonStartupManager.kt:418](../app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt#L418), [DaemonKeepaliveService.kt:72](../app/src/main/java/com/loabletech/bladewatch/services/DaemonKeepaliveService.kt#L72), [AdbDaemonLauncher.kt:17](../app/src/main/java/com/loabletech/bladewatch/launcher/AdbDaemonLauncher.kt#L17), [DaemonBootstrap.java:22](../app/src/main/java/com/loabletech/bladewatch/daemon/DaemonBootstrap.java#L22).
- Camera daemon ports and server setup: [CameraDaemon.java:51](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L51), [CameraDaemon.java:377](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L377), [CameraDaemon.java:381](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L381), [TcpCommandServer.java:22](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L22), [SurveillanceIpcServer.java:23](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.java#L23), [HttpServer.java:49](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L49).
- Daemon readiness sentinel and probe: [CameraDaemon.java:242](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L242), [CameraDaemon.java:633](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L633), [DaemonReadinessChecker.java:33](../app/src/main/java/com/loabletech/bladewatch/client/DaemonReadinessChecker.java#L33), [DaemonReadinessChecker.java:59](../app/src/main/java/com/loabletech/bladewatch/client/DaemonReadinessChecker.java#L59).
- TCP and surveillance IPC commands: [CameraDaemonClient.java:61](../app/src/main/java/com/loabletech/bladewatch/client/CameraDaemonClient.java#L61), [TcpCommandServer.java:93](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L93), [TcpCommandServer.java:108](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L108), [SurveillanceIpcServer.java:75](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.java#L75), [SurveillanceIpcServer.java:107](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.java#L107).
- Location sidecar IPC: [LocationSidecarService.java:32](../app/src/main/java/com/loabletech/bladewatch/services/LocationSidecarService.java#L32), [AccSentryDaemon.java:2078](../app/src/main/java/com/loabletech/bladewatch/daemon/AccSentryDaemon.java#L2078).
- Tor tunnel process: [TorLauncher.kt:44](../app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt#L44), [TorLauncher.kt:92](../app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt#L92).
