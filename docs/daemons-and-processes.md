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
- `KeepAliveAccessibilityService`: accessibility-backed keepalive. On DiLink 3.0 it binds only once the service host is already running, so it protects a running process but never starts one (see "After a reboot" below).

## ssc_skip also blocks SERVICE starts, not just broadcasts

BYD's `ssc_skip` is known here for suppressing broadcasts to the app package (BladeWatch-5rew,
and why the Flutter APK's `wakeServiceHost()` uses an explicit component start rather than a
broadcast). It applies the same rule to **service starts**: a shell-UID (2000) `am
start-foreground-service` targeting the app UID is ignored outright when that UID is not already
running. Measured on the head unit 2026-09-19:

```text
ActivityManager: ssc_skip startServiceLocked 2000 want to start 10073, package net.bladewatch.app
ActivityManager: UID 10073 is not running
ActivityManager: packageName 10073  NOT RUNNING
ActivityManager: ssc_skip startServiceLocked 2000 want to start 10073 package net.bladewatch.app ignored !!!
```

**ActivityManager reports this as `Error: Not found; no service started.` with exit 255**, which
reads like a missing component and is why it went undiagnosed — the component resolves fine, and
`dumpsys activity services` shows a `ServiceRecord` for it with `app=null`. The real reason is
only in logcat.

The fix is the same explicit-component start used for the broadcast case: bring the host up with
`am start -n net.bladewatch.app/.ui.MainActivity` (a bootstrap that calls `moveTaskToBack(true)`
immediately, so nothing appears on screen), then issue the service start, which then exits 0.
`SentryDaemon.restartLocationService` does this automatically, gated on
`needsServiceHostWake(...)` so a live host is not restarted.

This only affects callers running as the shell UID. `ServiceLauncher` runs inside the app
process, so the UID is by definition already up and the rule does not bite.

## After a reboot: allow BladeWatch in BYD Auto-Start (BladeWatch-8net)

**Out of the box, nothing starts BladeWatch after the head unit reboots**: no dashcam, no sentry
until someone opens the app. The fix is an owner action, not code. On the head unit, open
**BYD Auto-Start** (`com.byd.appstartmanagement`; the in-car Setup Guide's auto-start step opens
it, and it reappears after every new build to say so; from a shell:
`am start -n com.byd.appstartmanagement/.frame.AppStartManagement`) and allow BOTH BladeWatch entries (it lists
one per APK and it *restricts*, so allowing means unchecking both; the rule itself is keyed by
the UID the two share). **Every install or update of
EITHER APK undoes it**: on `PACKAGE_ADDED`, `PACKAGE_REPLACED` and `MY_PACKAGE_REPLACED` BYD writes
`1` ("restricted") for the UID and persists it (`AppOps$UserTableData.putInt(uid, 1)`), and an
uninstall deletes the entry. So redo it after every `adb install`, `install -r` included -- which
is how 8net happened: a reinstall the evening before re-restricted the UID, and the 02:07 boot
started nothing. The persisted table (`content://appops/settings`, `com.byd.providers.appops`)
is not exported (system UID), so shell cannot restore it either.

Measured on the head unit 2026-09-24. Before, a cold boot left all three daemons down
(`ssc_skip reciever ... BOOT_COMPLETED ... ignored !!!`). After allowing it, the next reboot
(no UI touched) started the service host for `BootReceiver` 26 s after boot
(`am_proc_start ... broadcast, {.../BootReceiver}`); `BOOT_COMPLETED` was delivered with no
"ignored"; all three daemons were up at 88 s.

Why, read from the firmware (services.jar / framework.jar, disassembled): `ssc_skip` -- on while
`persist.sys.relatestart` is true, the default -- skips a broadcast, service start or provider
start to a third-party UID unless the package is on BYD's `AutoStartWhite` strategy list or
`isTargetAppEnabledStartedBy3rd(uid)` holds. That reads a per-UID value from the
`bg_datacache` system service (`AppOpsDataCachedService`): exactly `1` means "only while the app
is already running"; no entry or anything else means allowed. So once BladeWatch runs, starts get
through (which is why this hides during development); after a cold boot nothing runs and
everything is skipped. The value is writable only with `android.permission.ACCESS_APPOPSDATA`,
**protection level signature**, held solely by `com.byd.appstartmanagement` -- a binder call from
shell fails with "Neither user 2000 nor current process has android.permission.ACCESS_APPOPSDATA",
and the app UID fails the same way. Hence the owner step. It also means these never worked here:
the `ssc_whitelist` settings `ServiceLauncher` wrote (BYD does not read them),
`setAppOpsData`/`setAppStartupData` from `BydDataCacheWhitelist`, `AccSentryDaemon`,
`SentryDaemon` and `AccModeHelper`, and `content://com.byd.appstartup` (no such provider) --
all deleted in BladeWatch-mgvv. The service host's BYD ACC whitelist call
(`accmodemanager.setPkg2AccWhiteList`) went the same way in BladeWatch-ese8: it needs
`android.permission.DEVICE_ACC`, **protection level signature**, and failed on every launch with
"Neither user 10073 nor current process has android.permission.DEVICE_ACC" (measured on the head
unit; shell does not hold it either). When the daemons once ran as system (UID 1000), where the
call worked, it raised BladeWatch's camera priority above BYD's own dashcam and took its feed.
The last shell-side copies went in BladeWatch-u43d: `AccSentryDaemon`'s direct binder
transactions and `ServiceLauncher`'s `service call accmodemanager` / `setprop
persist.sys.acc.whitelist` lines. They were measured first: the binder calls fail as shell with
the same DEVICE_ACC SecurityException, the property was always empty, and the codes they used were
wrong anyway -- the head unit's `android.os.IAccModeManager` numbers them 1 setPkg2AccWhiteList,
2 rmPkg2AccWhiteList, 3 getAccModeStatus, 4 requestSuspending, 5 acquireAccLock,
6 releaseAccLock, 7 addListener, 8 removeListener, so "code 5" was taking an ACC lock, not
whitelisting. The manifest no longer requests DEVICE_ACC or ACCESS_APPOPSDATA; the installer
stripped both (signature level) on every install. Newer firmware (Android 12+, `byd_datacached`) is a different
service that other BYD apps call from a shell-UID daemon; if DiLink 4+ support is ever added,
measure it there rather than assume either way.

`KeepAliveAccessibilityService` stays in `enabled_accessibility_services`, but the accessibility
manager's own bind at boot does not stick on this firmware. Before the grant it sat in "Binding
services" with every connection record DEAD; after the grant and a reboot it was listed as enabled
only. It does bind while the service host runs (BladeWatch-0z74, measured 2026-09-24).
`ServiceLauncher.enableAccessibilityKeepAlive` writes `accessibility_enabled 1`, the accessibility
manager rebinds on that write, and "AccessibilityService connected" follows within half a second.
After a force-stop, SentryDaemon revived the host 2 s later and the service was bound again 5 s
after that. While it is bound the service host runs at oom adj 50. It restarts nothing, though:
the boot broadcast is what brings the daemons back.

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

- `PEAR_PEER` (the Tor tunnel, `TOR_TUNNEL`, was removed in v1.4.0.0 — BladeWatch-rdtj.12).

Startup timing (measured from app launch / boot):

- Core daemon startup is delayed around `45 seconds` (system stabilization).
- Optional daemon startup is delayed around `60 seconds`.
- Health checks begin around `90 seconds`.
- Health checks repeat every `30 seconds` (`HEALTH_CHECK_INTERVAL_MS`).
- Within the core group, daemons are further staggered: Camera daemon first, Sentry daemon `+5 s`, ACC sentry daemon `+10 s`.

**Staggering is not mutual exclusion.** Each daemon also holds an exclusive `FileLock` on its
own PID-bearing lock file under `/data/local/tmp`, and that is what actually prevents a second
instance:

| Daemon | Lock file | Implementation |
|---|---|---|
| Camera | `camera_daemon.lock` | `DaemonSingletonLock` |
| Sentry | `sentry_daemon.lock` | `DaemonSingletonLock` |
| ACC sentry | `acc_sentry_daemon.lock` | `DaemonSingletonLock` |

All three share one implementation since BladeWatch-8d5u. The lock FILENAMES stay distinct and
must not be renamed — the clean-reinstall block in `CLAUDE.md` removes them by glob
(`camera_daemon.lock` and `*sentry*.lock`), so a rename silently breaks that cleanup and leaves a
`SIGKILL`ed daemon unable to restart. `AllDaemonsShareOneSingletonLockTest` pins both the shared
implementation and the three paths.

`SentryDaemon` had no lock until BladeWatch-f0y3. Its only guard was `isDaemonRunning()`, which
PINGs the control port — a liveness probe, not a lock. It answers true only once an instance has
already bound the port, so two daemons launched inside that window both probe, both find nobody
home, and both start. Observed on the head unit 2026-09-19: PIDs 9244 and 9351 one second apart,
both alive, every periodic task running twice. The port ping is retained as a cheap first check.

A lock naming a dead PID, junk, or our own PID is treated as reclaimable — a daemon killed with
`SIGKILL` (as the clean-reinstall procedure in `CLAUDE.md` does) must be able to start again.
That reclaim logic was learned on this hardware inside `CameraDaemon` and was extracted verbatim;
`AccSentryDaemon`'s old copy had none of it, so a lock naming a dead PID could only be cleared by
hand.

Releasing does **not** delete the lock file, which is a deliberate change from the two older
copies (they deleted at `CameraDaemon:1288` and `AccSentryDaemon:562`). Unlinking a path another
process may already hold a lock on is the classic double-winner race: the rival keeps its lock on
an orphaned inode while the next starter creates a fresh file and locks that, so both believe they
are the singleton. A leftover file is harmless — the next acquire finds no OS lock, takes it and
overwrites the PID. `CameraDaemon` still deletes its READY SENTINEL on release, which is a
different thing: readiness probes read its presence as "this daemon is up".

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
- Android sidecar services.

The Pear peer is not among them: `PearLauncher` / `PearController` start it.

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

**GL watchdog.** `PanoramicCameraGpu` runs a watchdog that `System.exit(0)`s the daemon (the
wrapper restarts it 10 s later) when the GL thread misses its heartbeat for 3 s, or 10 s before
the first frame. Each `start()`/`stop()` bumps a generation number, and only the current start's
watchdog may exit (BladeWatch-honj). Before that, the ACC-off recovery in `CameraDaemon.main`,
which stops the pipeline it has just started whenever the car boots with ACC off, could land
before the camera's GL init post ran. `quitSafely()` still ran that post, which set `running` and
started a watchdog for a GL thread that was already gone. Ten seconds later the orphaned watchdog
killed the healthy daemon the next `start()` had built. That was 7 of the starts measured on
2026-09-24 with ACC off, every post-install start among them. With the fix, 10 consecutive starts
ran clean. The CRITICAL line now carries the GL thread's stack.

### Ready sentinel and readiness probe

The daemon signals "startup complete" by writing its PID to a sentinel file:

```text
/data/local/tmp/camera_daemon.ready
```

It is written world-readable (`644`, via `setReadable(true, false)`) so the app UID can stat it. A stale sentinel left by a `kill -9`'d daemon is the reason readiness is **not** decided by the sentinel alone.

`DaemonReadinessChecker` (app-side, [DaemonReadinessChecker.kt](../app/src/main/java/com/loabletech/bladewatch/client/DaemonReadinessChecker.kt)) decides readiness with two checks:

- The sentinel exists and is non-empty, AND
- a short-lived TCP connect to `127.0.0.1:19876` (the command port) succeeds (`PROBE_TIMEOUT_MS = 1000`).

The TCP connect is the authoritative liveness signal — it is UID-independent and survives the head unit's `hidepid=2,gid=3009` `/proc` mount (the app UID cannot see the shell-owned daemon's `/proc` entry, so a `/proc/<pid>` check would always fail). A connect also catches the stale-sentinel case (a dead daemon refuses the connect).

`waitUntilReady(timeoutMs)` polls every 500 ms and logs progress every 5 s. It is used by `CameraDaemonClient.connect()` (60 s for cold-boot callers, 2 s for mid-session reconnects) and by `SecretConfigBridge` (30 s) before any IPC read/write.

### Recording mode manager

`RecordingModeManager` ([RecordingModeManager.kt](../app/src/main/java/com/loabletech/bladewatch/recording/RecordingModeManager.kt)) coordinates four mutually-exclusive modes (`NONE`, `CONTINUOUS`, `DRIVE_MODE`, `PROXIMITY_GUARD`) driven by ACC state and gear.

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
- Daemon process liveness (`daemonStatus`) and the Pear peer's status (`pearStatus`, see "Pear Peer Process" below).
- Enable/disable an optional daemon (`daemon_set_enabled`), allow-listed to
  `PEAR_PEER`.

The last four exist because the Flutter UI ships as a separate APK with no ADB; each is
deliberately narrow rather than a general-purpose escape hatch. See
`ipc-auth-and-secrets.md` for the allow-lists and why the other daemons are excluded.

Liveness (`daemonStatus`, and `pearStatus`'s `running`) is an **argv[0]** match read
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
127.0.0.1:8080   the in-car UI and local apps     (listener trust LOCAL_APPS)
127.0.0.1:8444   TLS, the Pear pump's way in      (REMOTE)
0.0.0.0:8443     TLS, only while LAN access is on (REMOTE)
```

Plain HTTP never binds anything but loopback; LAN access is the TLS listener's job.

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

## Tor Tunnel Process (removed)

The Tor onion service was the remote-access tunnel until v1.4.0.0, which removed it along with
the `TOR_TUNNEL` daemon type, the `tunnelStatus` IPC command, the REMOTE loopback listener on
8081 and the build-time `libtor.so` download (BladeWatch-rdtj.12). Two traces remain on
purpose:

- `LegacyTunnelCleanup`, on every app launch, runs `killall -9 bladewatch_tor` and drops the
  stale `TOR_TUNNEL` key from the `daemons` config section (`DaemonHardReset` kills it too).
  Every launch, not just the post-install sweep, because that sweep needs the package-replaced
  broadcast BYD suppresses after an install: a v1.3.x tor that survives keeps forwarding its
  onion port to a now-unbound 127.0.0.1:8081 that any app could take (BladeWatch-rdtj.23).
  Use `killall`, never `pkill -9 -f`, by hand as well: toybox `pkill -f` matches the pattern
  as a literal substring of every process's cmdline, including the ADB shell running your own
  kill script, so it kills that shell mid-procedure.

Neither touches `/data/local/tmp/tor`: its `hs/` directory still holds the old onion key, and
deleting it is left to the owner.

## Pear Peer Process

`PearDaemon` is the Pear peer, BladeWatch's remote-access transport since v1.4.0.0, when it
replaced the Tor onion service (epic BladeWatch-rdtj). It is an `app_process` daemon like `sentry_daemon`, launched by
`PearLauncher` as shell UID with `--nice-name=pear_daemon`, and it hosts a bare-kit worklet
running pear-end — the stock flutter_pear worklet bundle, shipped as
`assets/pear/pear-end.bundle`. On boot it joins this car's Hyperswarm topic so a paired
companion can find the car from anywhere.

It also carries the companion's traffic. `PearStreamPump`, inside this process, turns each
stream a companion opens over its Pear connection (`PearMux` framing) into a TCP connection
to byd_cam_daemon's Pear TLS listener, 127.0.0.1:8444, and copies bytes both ways —
a real cross-process hop, so it retries while byd_cam_daemon is (re)starting and closes
pumped streams cleanly when it goes away. Protocol and limits: `docs/networking-and-tunnels.md`
"Stream multiplexing".

It is **opt-in**: `DaemonType.PEAR_PEER` is the one optional daemon, off by default, and
starts on the optional tier (+60 s) only once enabled — pairing a companion is what enables
it. Enabled state lives in the `daemons` config section, so it can be toggled from the Flutter
UI over `daemon_set_enabled`. Crash recovery: a worklet that dies makes the process exit, and
the 30 s health check relaunches it.

**Status for the in-car UI (BladeWatch-rdtj.17).** Running and reachable are different
questions: a live peer on a head unit with no network cannot be found. pear_daemon keeps
`/data/local/tmp/pear_status.json` (mode 600; `PearStatus`) -- whether the topic is joined,
whether HyperDHT is online (pear-end's `dht.status`, polled every 30 s; flutter_pear 0.4.4+,
unknown on older bundles), how many paired devices are connected, and when one last connected.
Counts and times only, never the topic or a peer key. byd_cam_daemon's `pearStatus` IPC command
serves it with liveness and the owner's switch: `reachable` is true only when the process runs,
the file is under 90 s old, the topic is joined and the DHT is online; null when the bundle
cannot tell. Settings -> Services shows it under "Remote access (Pear)", and the dashboard's
Remote access tile reports it while Pear is switched on.

Runtime paths:

```text
/data/local/tmp/pear               pear-end's storage (0700) — NEVER delete, see below
/data/local/tmp/pear/swarm-identity.seed   the car's Pear identity (0600, secret) — see below
/data/local/tmp/pear_daemon.log    stderr/stdout of the process (errors only, see DaemonLogConfig)
/data/local/tmp/pear_daemon.lock   singleton lock; safe to remove when the daemon is stopped
```

**The car keeps one Pear identity across restarts (BladeWatch-rdtj.24).** `PearDaemon` starts
pear-end with `--persistent-identity`, so pear-end derives its Hyperswarm key pair from
`swarm-identity.seed`, written once (0600, via a temp file and rename). Without it every
`pear_daemon` start drew a random key: a companion's swarm went on redialing the dead key and
never reached the car again, and each restart left a dead announcer on the DHT for 20 minutes
that every companion cold start dialed and timed out on (measured: 5 announcers after 5
restarts, 4 dead, ~9 s per failed dial). With it, a car-side restart mid-download was back on
Pear in 3.2 s and the download resumed byte-exact. The seed is a secret: whoever holds it is the
car's Pear peer. It cannot read companion traffic (the companions' TLS is pinned end to end),
but it can stand in the car's place on the DHT.

The topic is `PearTopic`: SHA-256 over a domain tag and a random 32-byte seed kept in the
600 secret store (`pear.topicSeed`), created on first use. It is deliberately independent
of the auth device secret, so rotating that secret revokes sessions without also making
paired companions lose the car.

Six runtime requirements were found and verified on the head unit (BladeWatch-rdtj.2), and
the daemon crashes or silently fails without any one of them — each is documented at its
site in `PearDaemon`, `PearLauncher` and `app/build.gradle.kts`:

1. A stand-in `Application` bound into `ActivityThread.mInitialApplication` before the
   worklet starts. bare-kit's `bare_kit__on_thread_enter` dereferences
   `currentApplication()` unchecked on every native thread it creates; in an `app_process`
   daemon that is null and ART aborts the process.
2. The worklet and its IPC on a thread with a prepared **and pumped** Looper — IPC captures
   the calling thread's `ALooper` with no null check.
3. `-Djava.library.path` with the APK's native dir first, as CameraDaemon's launch does.
4. bare-kit's own `libc++_shared.so` and pear-end's addon libraries in the APK.
5. Storage under `/data/local/tmp`, not the app's `filesDir`, which shell cannot write.
6. `minSdk 29` — bare-kit's real floor (see the API-29 risk in the rdtj.2 close reason).

Measured on the head unit (2026-09-24): `attach.info` answered about 3 s after launch;
112 MB PSS, 0.0 % CPU at idle, alongside the camera daemon recording normally.

**`/data/local/tmp/pear` holds the car's permanent Pear identity** once a companion is
paired: killing the process is fine, deleting the directory strands every paired companion. Keep it 0700 as well — pear-end creates its
corestore inside it as 0777, so the parent's mode is the only thing keeping it private.

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
  -> app_process Java daemons (PearLauncher starts pear_daemon)

Flutter in-car UI (net.bladewatch.flutter, same UID)
  -> TCP 19876 (privileged ops, via its own Kotlin MethodChannels)
  -> HTTP 8080 (all 109 ConnectRPC methods, JWT-authenticated)

Location sidecar / app helpers
  -> TCP 19877 surveillance IPC

Companion over Pear
  -> pear_daemon's stream pump -> TLS 8444

Companion or browser on the car's network (LAN access on)
  -> TLS 8443

Camera daemon
  -> BYD local APIs, storage, Web Push notifications, trips
```

## Source References

- Android components declared in manifest: [AndroidManifest.xml:207](../app/src/main/AndroidManifest.xml#L207), [AndroidManifest.xml:255](../app/src/main/AndroidManifest.xml#L255), [AndroidManifest.xml:306](../app/src/main/AndroidManifest.xml#L306), [AndroidManifest.xml:312](../app/src/main/AndroidManifest.xml#L312), [AndroidManifest.xml:327](../app/src/main/AndroidManifest.xml#L327).
- Application, activity, receivers, and foreground services: [BladeWatchApplication.kt:18](../app/src/main/java/com/loabletech/bladewatch/BladeWatchApplication.kt#L18), [MainActivity.kt:46](../app/src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt#L46), [BootReceiver.kt:24](../app/src/main/java/com/loabletech/bladewatch/receiver/BootReceiver.kt#L24), [ProcessRevivalReceiver.kt:29](../app/src/main/java/com/loabletech/bladewatch/receiver/ProcessRevivalReceiver.kt#L29), [LocationBootReceiver.kt:14](../app/src/main/java/com/loabletech/bladewatch/receiver/LocationBootReceiver.kt#L14), [DaemonKeepaliveService.kt:30](../app/src/main/java/com/loabletech/bladewatch/services/DaemonKeepaliveService.kt#L30), [LocationSidecarService.kt:32](../app/src/main/java/com/loabletech/bladewatch/services/LocationSidecarService.kt#L32).
- Daemon startup and shell launch: [DaemonStartupManager.kt:15](../app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt#L15), [DaemonStartupManager.kt:73](../app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt#L73), [DaemonStartupManager.kt:418](../app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt#L418), [DaemonKeepaliveService.kt:72](../app/src/main/java/com/loabletech/bladewatch/services/DaemonKeepaliveService.kt#L72), [AdbDaemonLauncher.kt:17](../app/src/main/java/com/loabletech/bladewatch/launcher/AdbDaemonLauncher.kt#L17), [DaemonBootstrap.kt:22](../app/src/main/java/com/loabletech/bladewatch/daemon/DaemonBootstrap.kt#L22).
- Camera daemon ports and server setup: [CameraDaemon.kt:51](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.kt#L51), [CameraDaemon.kt:377](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.kt#L377), [CameraDaemon.kt:381](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.kt#L381), [TcpCommandServer.kt:22](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.kt#L22), [SurveillanceIpcServer.kt:23](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.kt#L23), [HttpServer.kt:49](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.kt#L49).
- Daemon readiness sentinel and probe: [CameraDaemon.kt:242](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.kt#L242), [CameraDaemon.kt:633](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.kt#L633), [DaemonReadinessChecker.kt:33](../app/src/main/java/com/loabletech/bladewatch/client/DaemonReadinessChecker.kt#L33), [DaemonReadinessChecker.kt:59](../app/src/main/java/com/loabletech/bladewatch/client/DaemonReadinessChecker.kt#L59).
- TCP and surveillance IPC commands: [CameraDaemonClient.kt:61](../app/src/main/java/com/loabletech/bladewatch/client/CameraDaemonClient.kt#L61), [TcpCommandServer.kt:93](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.kt#L93), [TcpCommandServer.kt:108](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.kt#L108), [SurveillanceIpcServer.kt:75](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.kt#L75), [SurveillanceIpcServer.kt:107](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.kt#L107).
- Location sidecar IPC: [LocationSidecarService.kt:32](../app/src/main/java/com/loabletech/bladewatch/services/LocationSidecarService.kt#L32), [AccSentryDaemon.kt:2078](../app/src/main/java/com/loabletech/bladewatch/daemon/AccSentryDaemon.kt#L2078).
- Pear peer process: [PearLauncher.kt](../app/src/main/java/com/loabletech/bladewatch/launcher/PearLauncher.kt), [PearDaemon.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/PearDaemon.kt), [PearStreamPump.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/PearStreamPump.kt).
