# Architecture

BladeWatch is a hybrid Android, native, and web application shipped as **two APKs
that share one UID**:

| APK | Package | Role |
|---|---|---|
| Service host | `net.bladewatch.app` | Daemons, receivers, foreground services, BYD integration. **No user-visible UI and no launcher entry.** |
| In-car UI | `net.bladewatch.flutter` | The Flutter app the driver opens. The only launcher icon. |

Both are signed with the same key and declare `android:sharedUserId="net.bladewatch.app"`,
so they run as one UID (10073 on the test head unit). That is load-bearing, not a
convenience: the daemon's loopback IPC servers on 19876/19877 authorise by **peer UID**
(`PeerCredentials.isTrusted`), and `CoResidentAttackerTest` pins that a separate app
holding the world-readable IPC token is rejected. A shared UID makes the Flutter APK pass
that gate unchanged. Never widen the gate instead.

Privileged shell-launched daemon processes do the long-running camera, recording,
surveillance, networking, telemetry, and web-server work.

## High-Level Shape

```text
In-car UI APK (net.bladewatch.flutter)
  -> Flutter/Dart: nav rail, screens, ChangeNotifier controllers
  -> Dart ConnectRPC client -> 127.0.0.1:8080 (JWT)
  -> MethodChannels -> Kotlin in the SAME APK -> loopback IPC 19876
  -> wakes the service host on first resume (explicit component start,
     not a broadcast -- BYD ssc_skip suppresses broadcasts to the app)

Service host APK (net.bladewatch.app) -- no launcher entry
  -> MainActivity: startup bootstrap only, never calls setContentView,
     moveTaskToBack immediately
  -> foreground services and boot receivers
  -> DaemonStartupManager
  -> ADB shell / app_process launchers
  -> CameraDaemon, SentryDaemon, AccSentryDaemon, Tor onion service

CameraDaemon
  -> local TCP command server on 127.0.0.1:19876
  -> local HTTP/WebSocket server on 127.0.0.1:8080
  -> surveillance IPC server on 127.0.0.1:19877
  -> Connect protocol RPC dispatch at /bladewatch.v1.<Service>/<Method>
  -> GPU camera and surveillance pipeline
  -> recording, streaming, telemetry, trips, Web Push notifications

Embedded web UI (Angular 19 SPA)
  -> built with Vite + @analogjs/vite-plugin-angular (no angular.json)
  -> built into web/dist, copied into assets/web/angular, extracted to
     /data/local/tmp/web/angular and served by the daemon at /
  -> talks to CameraDaemon over ConnectRPC (@connectrpc/connect-web)
  -> uses WebSocket streaming for live H.264 frames
  -> used for remote browser / tunnel access ONLY (the in-car UI is Flutter)

BYD integrations
  -> local BYD framework reflection and listeners
  -> vehicle state, diagnostics, and local SDK controls
```

## Build Modules

The repository is a single Android Gradle project:

- Root project: `BladeWatch`.
- Android module: `:app` -- the service host APK.
- `flutter_ui/` -- an independent standalone Flutter project (its own Gradle
  build under `flutter_ui/android/`), not an add-to-app module. It sets its own
  `minSdk = 29` (the head unit is API 29; Impeller Vulkan needs it) rather than
  inheriting the service host's legacy 25.
- Namespace and application id: `net.bladewatch.app` (source dirs still live
  under `com/loabletech/bladewatch/` for historical reasons).
- Minimum SDK: 25.
- Target SDK: 25.
- Compile SDK: 36.
- Native ABI split: `arm64-v8a`.
- Java and Kotlin target: 11.

The service host uses AndroidX core, appcompat, Material, lifecycle/LiveData,
WorkManager, Dadb, OkHttp, ConnectRPC-Kotlin, protobuf-java, TensorFlow Lite, H2,
WebSocket support, and native CMake builds. Navigation, osmdroid and ZXing were
dropped with the native UI (`BladeWatch-81g9.3`). appcompat, Material and
lifecycle stayed: `AppCompatDelegate` drives the night mode the status overlay
reads, `SetupGuideDialog` builds a Material AlertDialog, and `TorController` /
`DaemonsViewModel` publish daemon state as `LiveData`.

The embedded web UI is a separate Angular 19 project under `web/` (Vite +
`@analogjs/vite-plugin-angular`, ConnectRPC, Leaflet, `@ngx-translate`, qrcode).
The Gradle task `buildAngularWebUI` runs `npm run build` in `web/`, copies
`web/dist` into `app/src/main/assets/web/angular/`, and is hooked into `preBuild`
so the SPA is compiled before assets are packaged (skipped if `npm` is absent —
the committed `web/dist` is used instead). Protobuf service contracts live in
`proto/bladewatch/v1/*.proto`; `buf generate` emits TypeScript message classes
into `web/src/gen` and Java messages + Kotlin Connect stubs into the app source
tree.

## Runtime Boundaries

### Service Host App Process (`net.bladewatch.app`)

The ordinary Android app process hosts:

- `BladeWatchApplication`.
- `MainActivity` — the **startup bootstrap, not UI**. It extends `Activity`,
  never calls `setContentView`, and calls `moveTaskToBack(true)` unconditionally.
  It has no launcher `intent-filter` but stays `exported="true"` as the ADB
  recovery path (`am start -n net.bladewatch.app/.ui.MainActivity`) when the
  Flutter APK is broken or absent. `ServiceHostManifestTest` pins both properties.
- Boot, power, location, and process-revival receivers.
- Foreground services used to keep the system alive.
- Shell launch orchestration for daemon processes.
- The status overlay (`StatusOverlayService`) and `SetupGuideDialog` — the only
  two surfaces this APK still draws.

### In-Car UI App Process (`net.bladewatch.flutter`)

- The Flutter engine and all screens, in Dart.
- A small Kotlin layer in the same APK for the privileged operations a
  `MethodChannel` can reach (`ipc.*`, `auth.*`, `daemon.*`, `config.*`,
  `update.*`) plus the Live View texture plugin.
- On first `onResume` it explicitly starts the service host's `MainActivity`
  with `minimize_on_start`, which is how the daemons get launched when the user
  opens the app. Deliberately **not** in `configureFlutterEngine` — starting an
  Activity there interrupts engine setup.

### Shell-Launched Daemon Processes

The daemon processes are launched with Android `app_process` or extracted native binaries. They run outside the normal Activity lifecycle and use shared config under `/data/local/tmp` so that app, daemons, and web server can coordinate.

Core daemon roles:

- Camera daemon: camera, recording, streaming, HTTP API, WebSocket, telemetry, storage, Web Push notifications, trips.
- Sentry daemon: surveillance mode orchestration.
- ACC sentry daemon: ACC-aware sentry behavior.
- Tor onion service (`bladewatch_tor`): optional remote access tunnel.

### Native Libraries

Native code is used for camera texture binding, surveillance motion processing, OpenCV, OpenH264, and related performance-sensitive paths.

Important native areas:

- `app/src/main/cpp/camera/`.
- `app/src/main/cpp/surveillance/`.
- `app/src/main/cpp/CMakeLists.txt`.
- Downloaded OpenH264 and opencv-mobile artifacts handled by Gradle tasks.
- `libtor.so` in `jniLibs/` for the Tor tunnel — downloaded and SHA-256-verified at build
  time by `downloadTor`, not committed.

## Startup Lifecycle

1. Android starts `BladeWatchApplication`.
2. The application initializes logging, preferences, locale/theme, and starts `DaemonKeepaliveService`.
3. The service host's `MainActivity` initializes storage, device identity
   (`DeviceIdGenerator` **before any daemon starts**), daemon startup management, the location
   sidecar, and the status overlay — then immediately backgrounds itself.
4. `BootReceiver` handles boot, package replacement, screen, power, network, and BYD ACC events.
5. `DaemonKeepaliveService` runs as a sticky foreground service, holds a partial wake lock, and schedules process revival.
6. `DaemonStartupManager` delays launch to let the vehicle head unit settle, then starts core daemons and the optional Tor tunnel.
7. `AdbDaemonLauncher` and lower launchers execute shell commands that start Java daemons or the native tor binary.

Core daemon timing is intentionally staggered:

- Core start is delayed around 45 seconds.
- Optional daemon start is delayed around 60 seconds.
- Health checks begin around 90 seconds and repeat every 30 seconds.
- Camera daemon starts first, then sentry and ACC sentry are delayed behind it.

## Main Components

### `BladeWatchApplication`

Initializes global app concerns:

- Locale and theme.
- Logging.
- Preferences manager.
- Foreground keepalive service.

### `MainActivity` (service host)

Owns the startup bootstrap. It draws nothing — the in-car UI is Flutter, see
[UI/UX Design Language](ui-ux-design-language.md).

- Storage setup (kept deferred via `window.decorView.post`).
- Device ID initialization.
- BYD whitelist application.
- Daemon startup manager initialization.
- Location sidecar startup.
- Update checks.
- Post-update daemon reset behavior.
- Status overlay startup.

### `DaemonStartupManager`

Coordinates daemon launch, optional Tor tunnel launch, health checks, and user-stopped daemon state. It treats camera, sentry, and ACC sentry as core daemons and treats the Tor tunnel as the optional tunnel daemon.

### `AdbDaemonLauncher`

Facade over daemon and tunnel launchers. It starts camera, sentry, ACC sentry, and the Tor tunnel through shell execution.

### `DaemonBootstrap`

The bootstrap entrypoint used by shell-launched Java daemons. It creates an Android context from low-level framework classes, hardcodes the package name, grants or bypasses permissions where possible, and invokes daemon main code.

### `CameraDaemon`

The central long-running daemon. It starts local command and web servers, initializes the camera/GPU pipeline, config, auth, storage, telemetry, trip analytics, BYD collection, Web Push notifications, and surveillance IPC.

### `HttpServer`

Embedded HTTP server. It extracts and serves the Angular SPA from
`/data/local/tmp/web/angular` (`index.html` at `/`, hashed chunks under
`/assets/` and `/vendor/`, with an SPA fallback that serves `index.html` for
unrecognised paths so the Angular router resolves them client-side), dispatches
ConnectRPC calls under `/bladewatch.v1.<Service>/<Method>` via `ConnectDispatcher`,
and still exposes the inline REST/camera APIs, auth endpoints, thumbnail/video
serving, i18n catalogs, update APIs, and WebSocket live streaming. The legacy
static pages and their `/legacy/` route were retired once the Angular SPA was
confirmed stable — the SPA is now the only web UI the daemon serves.

### `GpuSurveillancePipeline`

Coordinates panoramic camera input, GPU scaling, recording, AI lane processing, surveillance state, adaptive bitrate, telemetry overlay, and streaming. Its detection stack (native motion pipeline, YOLO gate, texture tracker) has a dedicated invariants document — read [detection-invariants.md](detection-invariants.md) before changing any threshold, filter, or evidence source in `SurveillanceEngineGpu` or the native `motion_pipeline_v2`/`texture_tracker` code.

`PipelineRateController` (BladeWatch-t1lg.3) scales *detection* processing rate by driving state — ACC on trims to a driving rate, parked-and-quiet ramps to an idle rate, and a live viewer or recent motion always forces the full configured rate. It owns frame rate the way `AdaptiveBitrateController` owns bitrate — never both from one place. It does not touch recording resolution, codec, bitrate, the encoder, or the EGL context: the actuator is `AiLaneWorker`'s frame-accept throttle (a wall-clock gate before a frame is even submitted for detection), reached via `PanoramicCameraGpu.setDetectionRate`, never the camera-HAL-touching `setTargetFps`. See [daemons-and-processes.md](daemons-and-processes.md#detection-rate-scaling) for the full policy and wiring.

Camera selection is **not** profile-driven: `configureDefaultCamera()` hardcodes `cameraId=1, surfaceMode=0` (Seal's known-good tuple) for every car, and `PanoCameraDiscovery`'s runtime probe is what actually validates or corrects it — if the HAL opens that tuple but produces no ImageReader callbacks, auto-probe advances to the next camera/surface pair rather than streaming a blank view. A `CameraProfileResolver`/`CameraProfileCatalog` pair was written for BladeWatch-y78o.3 to make that first guess model-aware, but it was never wired into the pipeline and was removed as dead code; making a fresh install stop assuming a Seal needs a camera-profile setting distinct from `vehicle.modelId`, which is the 3D-appearance picker and defaults to `seal` for everyone.

### `BydDataCollector`

The main local BYD telemetry collector. It discovers BYD framework devices through reflection, reads initial values, registers listeners, and maintains a thread-safe vehicle snapshot.

## Design Patterns

- Reflection is used heavily for BYD local APIs so the app can compile with stubs but run against the vehicle firmware classes.
- Shared JSON files under `/data/local/tmp` are used for cross-process config and secrets.
- Daemons expose local TCP/HTTP IPC rather than relying on Activity-bound Android services.
- The embedded web UI is an Angular 19 SPA that talks to the daemon over ConnectRPC; the in-car UI is Flutter, so the SPA serves remote browser / tunnel clients only.
- Two UIs track the same 12 ConnectRPC services by convention: Flutter in the car, Angular in the browser. There is no shared UI code between them — only the protos.
- Optional remote access is layered over the local web server through the Tor onion service instead of exposing internet-facing server code directly. The onion address is a capability URL, not authentication: the password/JWT layer in front of the web server stays mandatory.
- Surveillance and camera paths prioritize long-running stability over tight coupling with Android UI lifecycle.
- **BladeWatch is server-free by design, permanently** (decided BladeWatch-tren.3). The project operates no backend of its own; nothing leaves the car unless the owner points it somewhere (e.g. the Tor onion service, which needs no account, token, or registration). This is a permanent product decision, not a temporary resource constraint, and the following stay permanently out of scope as a result: push notifications while the car is offline, multi-user access to one car, an account/pairing flow, community-authored automations, hazard-sharing between cars, diagnostic log upload with a short code, and car APK distribution from a server.

## Major Risk Areas

- The app relies on privileged shell behavior, BYD firmware APIs, and Android head-unit quirks.
- `/data/local/tmp` config must be protected carefully because multiple processes use it.
- LAN mode exposes the embedded web server on all interfaces and must remain opt-in.
- Tunnel URLs are only safe when paired with token auth.
- BYD local API listener behavior can crash certain firmware paths, so some listeners are intentionally skipped or isolated.

## Source References

- Application startup: [BladeWatchApplication.kt:18](../app/src/main/java/com/loabletech/bladewatch/BladeWatchApplication.kt#L18), [MainActivity.kt](../app/src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt) (service host bootstrap).
- In-car UI: [flutter_ui/lib/main.dart](../flutter_ui/lib/main.dart), [flutter_ui/lib/shell/app_shell.dart](../flutter_ui/lib/shell/app_shell.dart), and the Flutter-side [MainActivity.kt](../flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/MainActivity.kt) that wakes the service host.
- Boot and foreground survival: [BootReceiver.kt:24](../app/src/main/java/com/loabletech/bladewatch/receiver/BootReceiver.kt#L24), [DaemonKeepaliveService.kt:30](../app/src/main/java/com/loabletech/bladewatch/services/DaemonKeepaliveService.kt#L30).
- Daemon orchestration and shell launch: [DaemonStartupManager.kt:15](../app/src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt#L15), [AdbDaemonLauncher.kt:17](../app/src/main/java/com/loabletech/bladewatch/launcher/AdbDaemonLauncher.kt#L17), [DaemonBootstrap.java:22](../app/src/main/java/com/loabletech/bladewatch/daemon/DaemonBootstrap.java#L22).
- Camera daemon and local servers: [CameraDaemon.java:35](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L35), [TcpCommandServer.java:22](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L22), [HttpServer.java:49](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L49), [SurveillanceIpcServer.java:22](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.java#L22).
- Angular SPA serving and Connect dispatch: [HttpServer.java:426](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L426) (SPA static assets), [HttpServer.java:547](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L547) (SPA fallback), [HttpServer.java:568](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L568) (Connect route), [ConnectDispatcher.java:36](../app/src/main/java/com/loabletech/bladewatch/server/connect/ConnectDispatcher.java#L36).
- Angular web UI build/copy: [build.gradle.kts:497](../app/build.gradle.kts#L497) (`buildAngularWebUI`), [web/package.json](../web/package.json), [web/vite.config.ts](../web/vite.config.ts), [web/src/app/app.config.ts](../web/src/app/app.config.ts), [web/src/app/core/connect/connect-clients.ts](../web/src/app/core/connect/connect-clients.ts).
- GPU surveillance and recording stack: [GpuSurveillancePipeline.java:24](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java#L24), [PanoramicCameraGpu.java:39](../app/src/main/java/com/loabletech/bladewatch/camera/PanoramicCameraGpu.java#L39), [GpuMosaicRecorder.java:31](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuMosaicRecorder.java#L31), [HardwareEventRecorderGpu.java:58](../app/src/main/java/com/loabletech/bladewatch/surveillance/HardwareEventRecorderGpu.java#L58).
- BYD local integration: [BydDataCollector.java:20](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L20).
- Build and native boundaries: [build.gradle.kts:276](../app/build.gradle.kts#L276), [build.gradle.kts:413](../app/build.gradle.kts#L413), [CMakeLists.txt:50](../app/src/main/cpp/CMakeLists.txt#L50).
