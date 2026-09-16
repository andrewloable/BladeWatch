# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**BladeWatch** is an advanced sentry mode / dashcam Android app for BYD vehicles with DiLink v3. It targets `arm64-v8a` only (BYD head units), runs on Android 10+ (API 29+), and deploys to the car's head unit via ADB.

It ships as **two APKs that share one UID**:

| APK | Package | Built from | Role |
|---|---|---|---|
| Service host | `net.bladewatch.app` | `app/` (Gradle `:app`) | Daemons, receivers, foreground services, BYD integration. **No launcher entry, no UI.** |
| In-car UI | `net.bladewatch.flutter` | `flutter_ui/` (its own Flutter project) | The Flutter app the driver opens. The only launcher icon. |

Both are signed with the same key and declare `android:sharedUserId="net.bladewatch.app"`. That is **load-bearing**: the daemon's loopback IPC on 19876/19877 authorises by peer UID (`PeerCredentials.isTrusted`), and `CoResidentAttackerTest` pins that a separate app holding the world-readable IPC token is rejected. A shared UID lets the Flutter APK pass that gate unchanged — **never widen the gate instead.**

This project was forked from "Overdrive" and rebranded to BladeWatch (package `com.loabletech.bladewatch`). The legacy BladeWatch app is kept at `/Volumes/mandark-1Tb/projects/loabletech/BladeWatch-Legacy` for reference only — do not modify it.

## Execution Mode

Do **not** use subagents, the `Agent` tool, or the `Workflow` tool in this project. Do all work directly in the foreground yourself — investigation, ADB commands, code reads, and edits included. Do not launch background tasks; run commands in the foreground and wait for their result before continuing.

## Git Workflow

Do **not** run `git add`, `git commit`, or `git push` automatically. All commits are reviewed and made manually by the developer. Make code changes and stop — do not stage or commit them.

**Beads commit model**: `.beads/issues.jsonl` and `.beads/export-state.json` are tracked snapshots. Never stage `.beads/backup/*.darc` files — they are large binary Dolt chunks, gitignored, and should never appear in source commits. When running `git add`, target specific source files only, never `git add .` or `git add -A`.

## Device Connection

The test device (BYD head unit) is reached over ADB TCP at **`$CAR_IP:5555`**.
Export `CAR_IP` with your own head unit's LAN address before running any of the
commands below — it is deliberately not hardcoded in this repo:

```bash
export CAR_IP=<your head unit's LAN IP>
```

```bash
# Connect to device
adb connect $CAR_IP:5555

# Verify connection
adb -s $CAR_IP:5555 devices

# Always target this device explicitly when multiple devices may be listed
adb -s $CAR_IP:5555 <command>
```

Always pass `-s $CAR_IP:5555` to every `adb` command to avoid ambiguity if a USB device is also attached.

## Build Commands

The two APKs build independently. `./gradlew` builds the **service host** only;
the Flutter APK is built from `flutter_ui/` with the Flutter toolchain.

```bash
# --- in-car UI (net.bladewatch.flutter), from flutter_ui/ ---
cd flutter_ui && flutter analyze && flutter test
cd flutter_ui && flutter build apk --target-platform android-arm64 --debug
cd flutter_ui && flutter run -d "$CAR_IP:5555"   # hot reload; no Gradle, no daemon restart

# --- service host (net.bladewatch.app), from the repo root ---
# Debug build
./gradlew assembleDebug

# Release build. With KEYSTORE_FILE/KEYSTORE_PASSWORD/KEY_PASSWORD/KEY_ALIAS set it
# is signed; WITHOUT them BOTH projects now build UNSIGNED (signingConfig = null),
# to be signed later with apksigner. Sign the two APKs with the SAME key or the
# shared UID will not resolve.
./gradlew assembleRelease

# Run unit tests
./gradlew test

# Push web assets to connected device for development iteration
./gradlew :app:extractWebAssets

# APK filename convention — the git branch is always embedded:
#   app/build/outputs/apk/debug/bladewatch-<branch>-arm64-v8a-debug.apk
# e.g. on branch flutter-refactor:
#   bladewatch-flutter-refactor-arm64-v8a-debug.apk
# This is enforced by applicationVariants.all { } in app/build.gradle.kts.

# Install debug APK to device (branch name is in the filename — see above)
#
# IMPORTANT: Always STOP all running BladeWatch daemons and UNINSTALL the old
# app BEFORE installing a new APK. The shell-launched daemons run as detached
# `app_process` processes (NOT bound to the package manager), so they keep
# running after an uninstall and a plain `install -r` — leaving stale daemons
# with an old native `.so`/lock that block the fresh build (e.g. "Another
# CameraDaemon instance is already running"). Clean reinstall:
adb -s $CAR_IP:5555 shell '
  # Kill watcher launcher scripts first so they do not respawn daemons.
  # Bracket trick (start_[c]am_daemon) prevents the grep from matching this
  # very command line, which would kill the adb shell itself.
  for p in $(ps -A -o PID,ARGS 2>/dev/null | grep -E "start_[c]am_daemon|start_[a]cc_sentry|start_[s]entry|net.bladewatch.[a]pp.daemon" | awk "{print \$1}"); do kill -9 $p 2>/dev/null; done
  sleep 1
  # Kill the daemon processes by name, SPELLED IN FULL. killall matches comm or
  # basename(argv[0]) -- both "sh" for this adb shell -- so it cannot kill the
  # session, and it needs no bracket trick.
  #
  # This block used to say acc_sentry_daemon had to be truncated to
  # acc_sentry_daem because the kernel caps /proc/<pid>/comm at 15 characters.
  # The cap is real; the conclusion was wrong, and the truncated spelling is the
  # one that matches NOTHING. toybox falls back to basename(argv[0]), and these
  # daemons are launched with --nice-name, so argv[0] IS the full name while comm
  # is just "main". Measured on this head unit 2026-09-15:
  #   pidof acc_sentry_daemon -> 4571
  #   pidof acc_sentry_daem   -> (nothing)
  #   pidof main              -> 2851 3102 4571   (comm for all three is "main")
  killall -9 byd_cam_daemon sentry_daemon acc_sentry_daemon 2>/dev/null
  # NO `pkill -9 -f` belt-and-braces line here. There used to be one, claiming the
  # bracket trick kept it from matching this shell. It does not -- see the tor
  # block below -- and it killed the adb session mid-procedure, so every step
  # after it silently never ran.
  # Kill the Tor tunnel — the only remaining BladeWatch tunnel daemon.
  #
  # killall, NOT pkill -f, and this is verified-on-device important: toybox pkill
  # matches the pattern as a literal SUBSTRING of each /proc/<pid>/cmdline, and
  # this adb shell's own cmdline is the whole script you are reading — including
  # the pattern. So `pkill -9 -f /data/local/tmp/bladewatch_tor` kills the ADB
  # shell mid-procedure (observed: exit 137, daemons never stopped). The usual
  # bracket trick does NOT save you here either, because substring matching finds
  # the literal "[b]ladewatch_tor" in the script text too.
  #
  # killall matches `comm` / basename(argv[0]), which is "sh" for this shell and
  # "bladewatch_tor" for the tunnel, so it cannot match itself. The name is 14
  # characters precisely so it survives the kernel's 15-char cap on comm — see
  # TorLauncher.TOR_PROCESS.
  killall -9 bladewatch_tor 2>/dev/null
  am force-stop net.bladewatch.app
  # Remove launcher scripts + stale locks/sentinels so nothing relaunches.
  #
  # !! NEVER widen any of these globs to cover /data/local/tmp/tor. That directory
  # !! holds hs/hs_ed25519_secret_key, which IS the car's permanent onion address.
  # !! Delete it and tor mints a brand-new address on the next start, silently
  # !! breaking every QR code the owner has ever scanned, with no way back. The
  # !! tunnel is stopped by killing the process, never by deleting its directory.
  rm -f /data/local/tmp/start_*.sh /data/local/tmp/camera_daemon.lock /data/local/tmp/*sentry*.lock /data/local/tmp/*sentry*.pid 2>/dev/null
  sleep 1
  ps -A -o PID,ARGS 2>/dev/null | grep -E "byd_cam_daemon|sentry_daemon|acc_sentry|bladewatch_to[r]" | grep -v grep || echo "all daemons stopped"
'
# NOTE: killing daemons can briefly drop the ADB-over-TCP connection; if so,
# reconnect: until [ "$(adb -s $CAR_IP:5555 get-state)" = device ]; do adb connect $CAR_IP:5555; sleep 3; done
adb -s $CAR_IP:5555 uninstall net.bladewatch.app
# APK filename includes the branch name (e.g. flutter-refactor):
# NOTE the tr: a branch name containing a slash (feature/v1.3.1.0) would otherwise put a
# DIRECTORY SEPARATOR in the path and adb fails with "failed to stat". Gradle sanitises the
# slash to a dash when it names the APK, so the lookup has to sanitise it the same way.
# Verified on 2026-09-15 -- the unsanitised form below failed on branch feature/v1.3.1.0.
adb -s $CAR_IP:5555 install "app/build/outputs/apk/debug/bladewatch-$(git rev-parse --abbrev-ref HEAD | tr '/' '-')-arm64-v8a-debug.apk"

# !! UNINSTALLING WIPES THE APP'S ADB KEY PAIR from its filesDir (AdbShellExecutor
# !! stores it at files/adbkey + files/adbkey.pub). The next launch generates a NEW,
# !! unauthorized key, so every AdbShellExecutor call fails with "ADB auth pending"
# !! and NO DAEMON STARTS until someone taps OK on the car's screen. It cannot be
# !! dismissed remotely: with the panel asleep, screencap is all black, uiautomator
# !! returns "null root node", and key events do not reach the dialog -- even though
# !! dumpsys power still reports "Display Power: state=ON". See BladeWatch-ssoh.
#
# PRESERVE THE KEY ACROSS THE REINSTALL and no tap is needed. Verified working on
# this device 2026-09-14, byte-exact in both directions. DEBUG BUILDS ONLY --
# run-as requires DEBUGGABLE, so a release reinstall always needs the tap.
#
#   # BEFORE the uninstall:
#   adb -s $CAR_IP:5555 exec-out run-as net.bladewatch.app cat files/adbkey     > /tmp/adbkey
#   adb -s $CAR_IP:5555 exec-out run-as net.bladewatch.app cat files/adbkey.pub > /tmp/adbkey.pub
#
#   # ... uninstall + install ... then launch once so filesDir exists, then:
#   adb -s $CAR_IP:5555 shell "run-as net.bladewatch.app sh -c 'cat > files/adbkey'"     < /tmp/adbkey
#   adb -s $CAR_IP:5555 shell "run-as net.bladewatch.app sh -c 'cat > files/adbkey.pub'" < /tmp/adbkey.pub
#   rm -f /tmp/adbkey /tmp/adbkey.pub       # it is a private key -- do not leave it lying around
#
# NEVER move this key to shared storage to "solve" this. A world-readable ADB
# private key hands any installed app shell-level ADB on the head unit.

# The FLUTTER APK needs none of the above -- it installs over itself:
adb -s $CAR_IP:5555 install flutter_ui/build/app/outputs/flutter-apk/app-debug.apk

# Both packages MUST report the same UID or privileged IPC is refused:
adb -s $CAR_IP:5555 shell 'dumpsys package net.bladewatch.app | grep userId'
adb -s $CAR_IP:5555 shell 'dumpsys package net.bladewatch.flutter | grep userId'

# Clear all logs (logcat buffer + daemon log files + debug app log)
adb -s $CAR_IP:5555 logcat -c
adb -s $CAR_IP:5555 shell 'rm -f /data/local/tmp/*.log /data/local/tmp/*.log.*; rm -f /storage/emulated/0/BladeWatch/data/debug_app.log'

# View live logcat (filter to BladeWatch tags)
adb -s $CAR_IP:5555 logcat -s BladeWatch:V CameraDaemon:V SentryDaemon:V AccSentryDaemon:V

# Push and extract web assets directly to device
adb -s $CAR_IP:5555 shell mkdir -p /data/local/tmp/web
adb -s $CAR_IP:5555 push app/src/main/assets/web/. /data/local/tmp/web/
```

Native dependencies (OpenH264, opencv-mobile) are auto-downloaded by Gradle before any CMake/ExternalNative task. No manual download step needed.

**Node/npm is required to build, not optional.** `buildAngularWebUI` runs during
`preBuild`, and neither `web/dist` nor its packaged copy at
`app/src/main/assets/web/angular/` is committed (both gitignored). A build without
npm used to skip it with a warning and produce a *successful* APK containing no web
UI at all; `verifyWebAssetsPresent` now fails the build in that state instead.

### Release builds in CI

`.github/workflows/release.yml` builds **both** APKs on a `v*` tag and attaches them
to the GitHub Release. It needs **no secrets**: both come out unsigned, and the
workflow fails if either is signed or if fewer than two are produced. Sign the pair
afterwards with the same key — `android:sharedUserId` only collapses them into one
UID when the certificates are identical.

A tag build is a **detached HEAD**, so the branch embedded in the service host APK
filename becomes the literal `HEAD`; the workflow globs for the file and stamps the
tag on the uploaded name rather than relying on that convention.

See `docs/build-and-operations.md` for the toolchain pins and the signing recipe.

## Architecture

BladeWatch is a hybrid Android + shell-daemon + embedded web app. The critical design split:

**Flutter UI process** (`net.bladewatch.flutter`) — every screen, in Dart under `flutter_ui/lib/`, with plain `ChangeNotifier` controllers (no Riverpod/BLoC). Talks to the daemon over ConnectRPC on 8080 with a JWT; privileged operations go through MethodChannels to a small Kotlin layer **in the same APK**, which uses loopback IPC on 19876. On first `onResume` it explicitly starts the service host's `MainActivity` (`wakeServiceHost()`) — an explicit component start, because BYD's `ssc_skip` suppresses broadcasts to the app package.

**Service host process** (`net.bladewatch.app`) — no UI: `BladeWatchApplication`, `MainActivity` (startup bootstrap only — extends `Activity`, never calls `setContentView`, `moveTaskToBack(true)` immediately; kept `exported` as the ADB recovery path), boot/power receivers, `DaemonKeepaliveService`, `DaemonStartupManager`, `StatusOverlayService`.

**Shell-launched daemon processes** — launched via `app_process` ADB shell, run outside Activity lifecycle:
- `CameraDaemon` — the central long-running process. Owns the camera/GPU pipeline, H.264/H.265 recording, WebSocket live streaming, HTTP API server (`127.0.0.1:8080`), TCP command server (`127.0.0.1:19876`), surveillance IPC server (`127.0.0.1:19877`), telemetry, trips.
- `SentryDaemon` / `AccSentryDaemon` — surveillance orchestration.
- Tor onion service (`TorLauncher`, binary shipped as `libtor.so` in `jniLibs/`) — **the only remaining tunnel/proxy daemon**. Runs as `bladewatch_tor`, exposes `127.0.0.1:8080` as a v3 onion service, and needs no account, token or registration. Unlike its predecessor the binary is NOT committed: `downloadTor` fetches and SHA-256-verifies it at build time. Cloudflared, Tailscale, sing-box and the Telegram daemon were all removed; do not re-add generic kills for them. **`/data/local/tmp/tor/hs` holds the permanent onion identity key — killing the tunnel is fine, deleting that directory is not.** See `docs/networking-and-tunnels.md`.

**Embedded web UI** — the Angular 19 SPA under `web/`, built into `app/src/main/assets/web/angular/` and extracted to `/data/local/tmp/web` at runtime. Talks to CameraDaemon over ConnectRPC. It serves **remote browser / tunnel clients only** — the in-car UI is Flutter and does not embed it.

**BYD integrations** — local firmware APIs accessed via reflection (stubs in `android.hardware.*` and `android.os.*` compile against stubs; real classes loaded at runtime from boot classloader). **Local SDK only — there is no BYD cloud path.** The whole `byd/cloud/` package (client, MQTT subscriber, Bangcle white-box crypto) was deleted in `61b4d7f`; `VehicleCommandRouter.Path` is now `{SDK, NONE}`, and commands that only ever had a cloud implementation (Lock, Unlock, Flash, FindCar, SetBatteryHeat, charging schedule) resolve to `NOT_SUPPORTED`. See `docs/byd-integrations.md`.

### Startup Timing

Daemon launch is intentionally staggered to let the head unit settle: core daemons start ~45s after boot, optional daemons ~60s, health checks begin ~90s repeating every 30s. Camera daemon starts first; sentry daemons start behind it.

### Cross-Process Coordination

All cross-process config and secrets live under `/data/local/tmp`:
- Config: `/data/local/tmp/bladewatch_config.json` (owned by `UnifiedConfigManager`)
- Secrets: `/data/local/tmp/bladewatch_secrets.json` (owned by `SecretConfigStore`)
- Media: `/storage/emulated/0/BladeWatch/{recordings,surveillance,proximity,trips}`

The Android app cannot write secrets directly when running as app UID — it uses the TCP command bridge to have the daemon (shell UID) write them.

### Native Code

C++17 sources in `app/src/main/cpp/`:
- `camera/` — `HardwareBufferTextureBinder` (GPU texture binding)
- `surveillance/` — `motion_pipeline_v2`, `texture_tracker`, `native_motion` (OpenCV-based motion detection)
- CMakeLists.txt links OpenH264, opencv-mobile, and TensorFlow Lite GPU delegate

### Surveillance Pipeline

```
Camera frame → GPU downscale → native motion pipeline → per-quadrant state
  → optional TFLite YOLO11n gate → event decision
  → event recording + Web Push notification
```

## Key Source Locations

- In-car UI (Flutter): [flutter_ui/lib/main.dart](flutter_ui/lib/main.dart), [flutter_ui/lib/shell/](flutter_ui/lib/shell/), [flutter_ui/lib/screens/](flutter_ui/lib/screens/), [flutter_ui/lib/theme/](flutter_ui/lib/theme/), [flutter_ui/lib/rpc/](flutter_ui/lib/rpc/), [flutter_ui/lib/l10n/](flutter_ui/lib/l10n/)
- Flutter-side Kotlin (MethodChannels + Live View texture plugin): [flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/MainActivity.kt](flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/MainActivity.kt)
- Service host entry: [BladeWatchApplication.kt](app/src/main/java/com/loabletech/bladewatch/BladeWatchApplication.kt), [MainActivity.kt](app/src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt) (bootstrap only)
- Daemon launch: [DaemonStartupManager.kt](app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt), [AdbDaemonLauncher.kt](app/src/main/java/com/loabletech/bladewatch/launcher/AdbDaemonLauncher.kt), [DaemonBootstrap.java](app/src/main/java/com/loabletech/bladewatch/daemon/DaemonBootstrap.java)
- Central daemon: [CameraDaemon.java](app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java)
- HTTP server: [HttpServer.java](app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java)
- Auth: [AuthManager.java](app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java), [AuthMiddleware.java](app/src/main/java/com/loabletech/bladewatch/server/AuthMiddleware.java)
- GPU pipeline: [GpuSurveillancePipeline.java](app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java), [PanoramicCameraGpu.java](app/src/main/java/com/loabletech/bladewatch/camera/PanoramicCameraGpu.java)
- BYD local: [BydDataCollector.java](app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java)
- Config: [UnifiedConfigManager.kt](app/src/main/java/com/loabletech/bladewatch/config/UnifiedConfigManager.kt), [SecretConfigStore.kt](app/src/main/java/com/loabletech/bladewatch/config/SecretConfigStore.kt)
- Web UI (remote clients): [web/](web/), built into [app/src/main/assets/web/](app/src/main/assets/web/)

## BYD SDK Stub Pattern

Classes in `android.hardware.*` and `android.os.*` are **compile-time stubs only**. At runtime on BYD devices, the real SDK classes are loaded by the boot classloader (higher priority). All manager code uses `Class.forName()` reflection — the stubs in the APK are never instantiated. Do not change this pattern.

## Logging

`DaemonLogConfig.java` controls log verbosity. The release build Gradle script auto-detects if any logging flags are `true` — if so, `proguard-rules-strip-logs.pro` is excluded and log calls survive R8. In production (all flags false), R8 strips all log calls from bytecode. Do not enable logging flags in commits intended for release.

## Platform Scope (read before writing or running any test)

Two front-ends with **different** platform scopes. Confusing them wastes effort on targets that
do not exist, or skips a target that does.

**Native Flutter app (`flutter_ui/`) — BYD Android head unit ONLY.**
One device: arm64, BYD DiLink v3, Android 10 / API 29. There is no BladeWatch on a phone, a
tablet, a desktop or a browser.

- **Do NOT test, build, or debug for iOS, macOS, Windows, Linux or Flutter web.** Not with
  simulators, not with `flutter test -d chrome`, not "just to check".
- **Do NOT add or restore those platform directories.** `flutter create .`, some `flutter pub
  get` paths, and plugins that run platform scaffolding will silently recreate them; they are
  removed on purpose and `app/build.gradle.kts` enforces their absence.
- An iOS build failure is **not a bug to fix** — it is a target that should not exist. The same
  goes for a plugin that "supports only desktop/web": it resolves fine on a dev machine and
  fails at APK build time.
- macOS hosts complicate this: a transitive dependency (`objective_c`, pulled in by
  `video_player` / `webview_flutter`'s darwin implementations) runs a native-asset build hook
  that calls `xcrun`, so an unaccepted Xcode licence blocks `flutter test` entirely. That is a
  host-toolchain problem, not an iOS target — fix it with `sudo xcodebuild -license accept`,
  never by adding iOS support.

**Web app (`web/`) — browsers, including phones.**
This one IS reached from a phone: it is what the owner opens when away from the car, over the
tunnel. Mobile browsers — iOS Safari included — are in scope here, and that is not a
contradiction of the rule above. A mobile *browser* is a supported client of the web app; a
native *iOS build* of the Flutter app is not a thing that exists.

```bash
cd web && npm run typecheck           # tsc --noEmit — `vite build` does NOT typecheck
cd web && npm run typecheck:templates # ngc --strictTemplates — nothing else checks templates
cd web && npm run test:unit           # vitest — framework-free logic
cd web && npm run test:mobile   # Playwright, Pixel 7 + iPhone 13, against a local build
cd web && npm run test:e2e      # Playwright against a LIVE head unit (needs e2e/.env)
```

`test:mobile` serves the built app itself and needs no daemon, so mobile layout regressions are
catchable without powering up a car. `test:e2e` does need a live device.

**Component TEMPLATES are checked by neither of the above — run `npm run typecheck:templates`.**
`tsc` only parses `.ts`, and `vite build` hands templates to esbuild without checking them.
Measured 2026-09-16: a template calling a method that does not exist on its component compiled
clean and exited 0 under BOTH. Nothing fails at runtime either — `@if (typoName())` is
`undefined`, which is falsy, so the guarded block silently never renders and the page just looks
empty. `./gradlew :app:webTemplateCheck` runs the same check.

**`npm run build` does not typecheck — run `npm run typecheck` separately.** `vite build` bundles
with esbuild, which strips types without checking them, so a type error produces a perfectly
successful build. This is not theoretical: four files imported generated protobuf types through a
path one level too deep, and because they were `import type` declarations esbuild erased them
before ever resolving the path. The build stayed green for months while those pages had no
compile-time protection at all. `./gradlew :app:webTypecheck` runs the same check; like
`:app:webUnitTests` it is deliberately NOT wired into `preBuild`, because it needs `node_modules`
and `buildAngularWebUI` already owns the "is the web toolchain present" question.

## Testing

**Service host (Kotlin/Java)** — 24 JVM test files under `app/src/test/java/com/loabletech/bladewatch/`, covering auth (`AuthMiddlewareTest`, `AuthManagerTest`), secrets (`SecretConfigStoreTest`, `SecretRedactorTest`), the Connect wire contract, server handlers, vehicle formatting/i18n, and the Phase 4 structural guards (`ServiceHostManifestTest`, `NoSelfLaunchIntentTest`). Run with `./gradlew test`; coverage gate is `./gradlew koverVerify`.

```bash
# NOTE: `:app:test` is an aggregate lifecycle task and does NOT accept --tests
# ("Unknown command-line option '--tests'"). Target the variant task:
./gradlew :app:testDebugUnitTest --tests "com.loabletech.bladewatch.auth.AuthManagerTest"
```

**In-car UI (Dart)** — 111 test files under `flutter_ui/test/`, ~1450 tests. **Android head unit only — see "Platform Scope" above; never test this app for iOS or any other platform.** There are deliberately **no golden tests** — visual parity is verified on the head unit. Note that `flutter test` uses a fixed-width placeholder font, so any text-fit or overflow assertion in a widget test is meaningless; measure on the device.

```bash
cd flutter_ui && flutter analyze && flutter test
cd flutter_ui && flutter test --coverage && cd .. && tools/check_flutter_coverage.sh
```

**In-car UI (Kotlin)** — the Flutter APK's privileged layer (IPC client, JWT
minting, daemon control, secret/public config, the Live View texture plugin) has
its own test suite under `flutter_ui/android/app/src/test/kotlin/`, gated by
Kover at a **100%** bound with documented per-class exclusions.

`flutter_ui/android` is a **separate Gradle build** with its own wrapper. The
repo-root `./gradlew koverVerify` verifies the SERVICE HOST only and will pass
while this gate is failing, so it has to be run on its own:

```bash
cd flutter_ui/android && ./gradlew koverVerify
```

This was not previously written down, and the gate had silently dropped to 96.2%
— `PublicConfigChannel.getCameraProbe()` shipped for the Diagnostics camera tile
with no test. Run it whenever you touch `flutter_ui/android/app/src/main/kotlin/`.

All three coverage gates **ratchet upward and may never be lowered**.

**Gradle up-to-date blindness:** a test that reads a file which is not on the classpath (a manifest, a source tree scanned as data) will not re-run when that file changes, so it can pass against a mutation. Declare such files as explicit test `inputs` — `app/build.gradle.kts` does this for `AndroidManifest.xml` and `src/main/java`. A guard that cannot fail is worse than no guard.

## Shell Command Safety

Always use non-interactive flags for file operations — some shells alias `cp`/`mv`/`rm` to interactive mode which will hang:

```bash
cp -f source dest      # not: cp source dest
mv -f source dest      # not: mv source dest
rm -f file             # not: rm file
rm -rf directory       # not: rm -r directory
```

## Issue Tracking

Use `bd` (beads) for all task tracking. See `AGENTS.md` for the full workflow. Never use markdown TODOs or other tracking systems.

When creating a `bd` task, write the `--description` for a **low-context implementing agent that has none of your current context**. Put everything needed into the description: problem/context, exact file paths + class/function names + line numbers, step-by-step instructions, constraints (what NOT to change), and **always** a verifiable **acceptance criteria** checklist. **Always end the description with a warning to not make mistakes** — i.e. "Do not make mistakes. Read the referenced files fully before editing. Verify the build compiles and all acceptance criteria pass before closing. If anything is ambiguous, stop and ask rather than guessing." See the "Writing Task Descriptions (CRITICAL)" section in `AGENTS.md` for the required template.

## Documentation Maintenance

When changing route handlers, daemon ports, config paths, startup timing, tunnel behavior, BYD vehicle behavior, or storage paths, update the relevant file in `docs/`:
- Runtime/lifecycle changes → `architecture.md`, `daemons-and-processes.md`
- HTTP route changes → `http-api-reference.md`
- Tunnel/proxy/network changes → `networking-and-tunnels.md`
- BYD local SDK / vehicle-control changes → `byd-integrations.md`
- Storage/config/media changes → `data-flow-and-storage.md`
- Auth / IPC token / secret store / cross-process file permission changes → `ipc-auth-and-secrets.md`
- User-facing changes → `features.md`
- UI/UX, design-language, theme, or color/typography/shape/motion token changes → `ui-ux-design-language.md`

`docs/webview-migration.md` is **retired** — it describes a superseded
architecture (WebView → native fragments, both since replaced by Flutter). Do not
update it; read it only for its WebView-quirk notes.

## Security Notes

- `/data/local/tmp/bladewatch_secrets.json` contains device tokens and tunnel tokens. Never log or copy these values. It is mode `600` (shell-only); the app fetches values it needs over token-gated IPC, not by reading this file.
- `/data/local/tmp/bladewatch_ipc_token` MUST stay world-readable (`644`). It is the bootstrap token the app uses to authenticate IPC to the daemon; if it reverts to `600`, every app→daemon secret fetch fails and the UI shows "Camera unavailable". See `docs/ipc-auth-and-secrets.md`.
- LAN HTTP (`http://<car-ip>:8080`) is disabled by default and must remain opt-in. The server binds to `127.0.0.1` by default.
- Tunnel URLs are only safe when paired with JWT token auth.
- **BYD vehicle control APIs affect the physical car — test conservatively.** This applies to the local SDK commands that still exist (climate, windows, seats, trunk, lights, ADAS, charge cap), which actuate real hardware. The cloud control path is gone (see Architecture above), so the risk now lives entirely in `VehicleCommandRouter`'s SDK path — not a reason to relax the rule.
- VLESS proxy credentials use encrypted `Safe.s("...")` values — use `generate_safe_enc.py` to encrypt before committing.

<!-- rtk-instructions v2 -->
## RTK (token-optimized command proxy)

A hook rewrites shell commands through `rtk`, which compacts noisy output. It is a
pass-through when it has no filter for a command, so it is always safe.

Only a few of its filters are relevant here — this project is Android/Gradle/Flutter,
not cargo/jest/pnpm/docker, so most of RTK's catalogue never applies:

| Command | Why it matters here |
|---|---|
| `rtk git status` / `log` / `diff` | Compacts large diffs — this repo has some very large ones |
| `rtk grep` / `find` / `ls` | Grouped, compact search output |
| `rtk gh pr` / `run list` | Compact GitHub CLI output |
| `rtk gain` | Token savings so far |

**`rtk proxy <cmd>` runs a command completely unfiltered.** Reach for it when you need
*exact* output rather than a summary — notably `rtk proxy git diff`, since the
compacted diff drops the `+`/`-` line prefixes that patch-parsing depends on.

Run `rtk --version` to confirm you have the right binary: an unrelated tool
(reachingforthejack/rtk) shares the name, and `rtk gain` failing is the giveaway.
<!-- /rtk-instructions -->

## Issue tracking and session completion

The full beads workflow lives in **[AGENTS.md](AGENTS.md)** — it is not repeated here,
because two copies drift. Run `bd prime` for the command reference.

> **This project overrides the generic beads "Session Completion" protocol.** That
> protocol ends with "PUSH TO REMOTE — this is MANDATORY ... YOU must push". It does
> not apply here: see **Git Workflow** above. Do not run `git add`, `git commit` or
> `git push`. Finish by leaving the work tree clean-but-uncommitted and handing the
> developer a summary. Everything else in that protocol (file issues for remaining
> work, run the quality gates, update issue status, hand off context) does apply.
>
> If a regenerated beads block reintroduces the mandatory-push wording, this
> paragraph wins.
