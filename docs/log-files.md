# Log Files

Where BladeWatch writes logs on the device, who owns each file, and how rotation/retention works. Most logs live under `/data/local/tmp` (shell UID 2000) because the long-running daemons run as detached `app_process` processes outside the Android app sandbox. The app process (app UID) **cannot** write to `/data/local/tmp`, so its own debug log goes to shared storage instead.

## Daemon logs (`/data/local/tmp`, shell UID 2000)

These are the primary logs. Each daemon's stdout/stderr is redirected to a fixed file by its launch script, and `DaemonLogger` also appends structured lines here.

| File | Producer | Notes |
|------|----------|-------|
| `/data/local/tmp/cam_daemon.log` | `CameraDaemon` (`byd_cam_daemon`) | Busiest log — camera/GPU pipeline, H.264/H.265 recording, HTTP/TCP/IPC servers, BYD telemetry, `PerformanceMonitor`. Grows fastest (hundreds of KB). |
| `/data/local/tmp/sentry_daemon.log` | `SentryDaemon` (`sentry_daemon`) | Surveillance orchestration, location monitor, control socket (port 19879). |
| `/data/local/tmp/acc_sentry_daemon.log` | `AccSentryDaemon` (`acc_sentry_daemon`) | ACC power-state watcher, bodywork listener, 60s status checks. |
| `/data/local/tmp/pear_daemon.log` | Pear peer (`pear_daemon`, launched by `PearLauncher`) | Worklet start, swarm join, companion connections and the stream pump. Only while `PEAR_PEER` is on — see `docs/networking-and-tunnels.md`. (A `tor.log` here is left over from a v1.3.x install; nothing writes it since v1.4.0.0.) |
| `/data/local/tmp/bladewatch_install.log` | Install/bootstrap scripts | Daemon install/startup bootstrap trace. |
| `/data/local/tmp/sentry_network_diag.log` | Sentry network diagnostics | Network reachability diagnostics (when enabled). |

Defined in [DaemonLauncher.kt:28-31](app/src/main/java/com/loabletech/bladewatch/launcher/DaemonLauncher.kt#L28-L31) and surfaced in the UI by the Flutter Daemons settings section, [flutter_ui/lib/screens/settings/settings_daemons_screen.dart](flutter_ui/lib/screens/settings/settings_daemons_screen.dart).

### System-dir fallback (sentry)

When the sentry daemon runs under a higher-privilege UID it may instead write to:

- `/data/data/com.android.providers.settings/sentry_daemon.log` (UID 1000)

vs. the normal `/data/local/tmp/sentry_daemon.log` (UID 2000). The system path is defined at [DaemonLauncher.kt:30](app/src/main/java/com/loabletech/bladewatch/launcher/DaemonLauncher.kt#L30); the two-location read is at [DaemonLauncher.kt:619-622](app/src/main/java/com/loabletech/bladewatch/launcher/DaemonLauncher.kt#L619-L622).

## App-process log (shared storage, app UID)

| File | Producer | Notes |
|------|----------|-------|
| `/storage/emulated/0/BladeWatch/data/debug_app.log` | `DebugAppLogger` | The Android UI process (Application, MainActivity, fragments, services) logs here because it cannot write to `/data/local/tmp`. Rotates at **5 MB**, keeps **3** rotations. |

Defined in [DebugAppLogger.kt:26-28](app/src/main/java/com/loabletech/bladewatch/logging/DebugAppLogger.kt#L26-L28).

## logcat

`DaemonLogger`/`DebugAppLogger` also mirror to Android logcat under per-component tags. View live:

```bash
adb -s $CAR_IP:5555 logcat -s BladeWatch:V CameraDaemon:V SentryDaemon:V AccSentryDaemon:V
```

Note: when daemons are running detached and logging only to files, the logcat tag buffers may be empty — read the files directly for the full history.

## Rotation & retention

- **Daemon logs** (`DaemonLogger`, [DaemonLogger.java:46-47](app/src/main/java/com/loabletech/bladewatch/logging/DaemonLogger.java#L46-L47), rotation at [DaemonLogger.java:332-386](app/src/main/java/com/loabletech/bladewatch/logging/DaemonLogger.java#L332-L386)): rotate by size (`maxFileSizeMB` = 10 by default) to `<name>.log.1`, `.log.2`, `.log.3`; `rotationCount` = 3 by default. Oldest beyond the count is deleted.
- **Debug app log** ([DebugAppLogger.kt:27-28](app/src/main/java/com/loabletech/bladewatch/logging/DebugAppLogger.kt#L27-L28), rotation at [DebugAppLogger.kt:110-132](app/src/main/java/com/loabletech/bladewatch/logging/DebugAppLogger.kt#L110-L132)): 5 MB/file (`MAX_SIZE_BYTES`), 3 rotations (`MAX_ROTATIONS`).
### Session banners — find the current run

Size-based rotation alone does not tell you **which build** wrote a line. A low-volume log
takes weeks to reach its rotation threshold, so one file routinely spans several days and
several builds. An audit on 2026-09-15 found two `[CRASH]` entries in `debug_app.log` for a
bug that had already been fixed and regression-tested; they came from a build whose UI no
longer existed, and nothing in the file said so.

Every run therefore starts with a banner ([SessionBanner.kt](app/src/main/java/com/loabletech/bladewatch/logging/SessionBanner.kt)):

```
========================================================================
BLADEWATCH-SESSION [2026-09-15 10:30:00.000] process=camera-daemon version=1.3.2.0 branch=feature-v1.3.2.0 build=debug
========================================================================
```

- The service host writes it to `debug_app.log` as soon as debug logging is enabled.
- `CameraDaemon` writes it to stdout, which the launcher script appends to `cam_daemon.log`.
  Straight to stdout rather than through `DaemonLogger`, whose stdout path is deliberately
  ERROR-only for that file — a run boundary is not an error.

To read only the current run:

```bash
# where does the last run start?
adb -s $CAR_IP:5555 shell 'grep -n BLADEWATCH-SESSION /data/local/tmp/cam_daemon.log | tail -1'
# everything since then
adb -s $CAR_IP:5555 shell 'sed -n "$(adb ... | cut -d: -f1),\$p" /data/local/tmp/cam_daemon.log'
```

`branch` comes from `BuildConfig.GIT_BRANCH`, which Gradle already computes for the APK
filename. **Before treating any log entry as a live fault, check which banner it falls
under.**

- **LogCleaner** ([LogCleaner.kt](app/src/main/java/com/loabletech/bladewatch/logging/LogCleaner.kt)): periodic sweep that deletes old `*.log` and rotated `*.log.<n>` files by retention policy.
- Verbosity is gated by [DaemonLogConfig.kt](app/src/main/java/com/loabletech/bladewatch/logging/DaemonLogConfig.kt); in release builds with all flags `false`, R8 strips log calls (see CLAUDE.md → Logging).

## Quick commands

```bash
# Tail each daemon log
adb -s $CAR_IP:5555 shell 'tail -n 60 /data/local/tmp/cam_daemon.log'
adb -s $CAR_IP:5555 shell 'tail -n 40 /data/local/tmp/sentry_daemon.log'
adb -s $CAR_IP:5555 shell 'tail -n 40 /data/local/tmp/acc_sentry_daemon.log'

# App UI debug log (shared storage)
adb -s $CAR_IP:5555 shell 'tail -n 80 /storage/emulated/0/BladeWatch/data/debug_app.log'

# List all current log files + sizes
adb -s $CAR_IP:5555 shell 'ls -la /data/local/tmp/*.log* 2>/dev/null'

# Clear all logs (logcat buffer + daemon files + app debug log)
adb -s $CAR_IP:5555 logcat -c
adb -s $CAR_IP:5555 shell 'rm -f /data/local/tmp/*.log /data/local/tmp/*.log.*; rm -f /storage/emulated/0/BladeWatch/data/debug_app.log'
```

## Related sidecar files (not logs)

Co-located in `/data/local/tmp` but used for process coordination, not logging:

- `*_daemon.pid` — daemon PID files (e.g. `sentry_daemon.pid`)
- `*.lock` — singleton locks (`camera_daemon.lock`, `sentry_daemon.lock`, `acc_sentry_daemon.lock`); each holds the owning PID
- `camera_daemon.ready` — readiness sentinel (PID of a fully-started CameraDaemon, world-readable `644`); read by the app's `DaemonReadinessChecker` (see `daemons-and-processes.md`)
- `camera_daemon.disabled` / `cam_watchdog.pid` — camera disable sentinel / camera-watchdog PID (the watchdog script respawns the daemon)
- `bladewatch_ipc_token` — IPC bootstrap token (see `ipc-auth-and-secrets.md`)
- `start_*.sh` — daemon launcher scripts
