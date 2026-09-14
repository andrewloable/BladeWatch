# Features

This file catalogs the main capabilities implemented in the repository.

## Recording

- Panoramic camera recording from BYD camera feeds.
- GPU mosaic recording pipeline.
- Multiple recording modes through unified config.
- Recording quality settings.
- Codec settings.
- Bitrate control.
- Segment-based recording.
- Recording library with day/calendar navigation and dashcam-vs-surveillance segmenting.
- Proximity recording triggered by the BYD parking radar (see Proximity Recording below).
- Thumbnail and video serving through the embedded HTTP server.
- Storage selection and cleanup.
- External storage detection and configuration.

Default camera-related values found in code:

- Panoramic recording resolution: `5120x960`.
- View resolution: `1280x960`.
- Default frame rate: `25 fps`.
- Default recording bitrate: `4 Mbps`.
- Segment length: `2 minutes`.

## Surveillance and Sentry Mode

- Manual surveillance enable and disable.
- ACC-aware sentry behavior.
- GPU-based motion detection.
- Per-quadrant motion processing.
- AI-assisted object detection using TensorFlow Lite.
- YOLO model support from `assets/models/yolo11n.tflite`.
- Flash-immunity settings.
- Region-of-interest mask support.
- Pre-event and post-event recording windows.
- Loitering and sustained-motion logic.
- Surveillance heatmap and snapshots.
- Safe locations.
- Filter logging.

Default surveillance config includes:

- Surveillance disabled by default.
- Pre-recording window: `5 seconds`.
- Post-recording window: `10 seconds`.
- Motion block size: `32`.
- Required motion blocks: `3`.
- Sensitivity: `0.04`.
- AI confidence: `0.25`.
- Person and car detection enabled by default.
- Bike detection disabled by default.

## Proximity Recording

When the car is parked, BladeWatch can record clips triggered by the BYD parking radar rather than by camera motion:

- Monitors all 8 BYD ultrasonic parking radar sensors (`RadarConstants.SENSOR_COUNT = 8`).
- Aggregates per-sensor distance zones and fires on a configurable trigger level (e.g. YELLOW / RED).
- Records a proximity clip (separate `PROXIMITY` recording type, filterable in the recording library) and can raise a notification.
- Reserves storage headroom before recording starts.

## Location and GPS

A dedicated Location experience exists in both the in-car UI and the web app:

- GPS position is sourced from the daemon (`VehicleService.GetGpsLocation`, backed by `GpsMonitor`), which returns latitude, longitude, heading, accuracy, staleness, and a Google Maps URL.
- In-car Location screen (Flutter): `flutter_map` on the same MAPNIK tiles, with a heading-rotated car marker, follow mode with a Recenter button after the user pans, and Auto/Light/Dark map appearance (dark inverts tiles), persisted.
- Web Location page: the same behaviour on a Leaflet/OpenStreetMap map.
- Status banner reflects loading / waiting-for-fix / fresh / stale / unavailable states (stale threshold 30s).
- GPS can be started and stopped on the daemon (`StartGps` / `StopGps`).

## Live Streaming

- Local H.264 live stream over WebSocket.
- Single-port streaming on the embedded HTTP server.
- SPS/PPS caching.
- IDR frame request support.
- Fragmentation support for large frames.
- Separate streaming encoder path from recording.
- Streaming quality configuration.

## Embedded Web UI and PWA

The primary web UI is an Angular 19 single-page app (source in `web/`, built with Vite, talking to the daemon over ConnectRPC). Its build output is bundled under `app/src/main/assets/web/angular/`, extracted by the daemon to `/data/local/tmp/web`, and served locally. The retained hand-written assets (the login page, PWA manifest/service worker and credits under `local/`, plus the shared 3D/vendor assets under `shared/`) and the Three.js Vehicle hero (`hero/hero.html`) also ship under `app/src/main/assets/web/`. The old static HTML pages and their `/legacy/` route were retired once the SPA was confirmed stable.

Angular pages (routes), each built for 1:1 parity with its in-car counterpart:

- Dashboard — stats / connect hub (week trip stats, status chips, metric tiles, device-ID + tunnel-URL QR connect card).
- Live — full-bleed camera view with All/Front/Right/Rear/Left selector over the WebSocket stream.
- Recording — dashcam vs surveillance library with day calendar navigation, actor/severity/type filter chips, multi-select delete, and an in-page video player.
- Surveillance — sensitivity, distance preset, AI gate + confidence, per-class detection, pre/post windows, quadrant snapshots, heatmap, and safe-location zones.
- Events — surveillance (sentry) event clips with the shared player.
- Trips — Trips / Stats / Storage tabs, Leaflet route map, driving DNA, personalized range, electricity-rate config.
- Vehicle — Climate / Seats / Windows control tabs, read-only lock + charge/range pills, TPMS cards, and a GPS card.
- Location — full-screen Leaflet map with a heading-rotated car marker, follow/recenter, and Auto/Light/Dark map themes.
- Diagnostics — Network / Storage / Camera / Battery health tiles, a Camera Probe dialog, and a Battery Health (SOH) dialog. (No ADB console — ADB is excluded from the web build.)
- Notifications — Web Push subscribe/unsubscribe, VAPID key, and test push.
- Performance — CPU / Memory / GPU / app-process metric cards and an audio test.
- Settings — Appearance, Recording, Surveillance, Status overlay, Daemons, Privacy & data sub-sections.
- About — identity (name/version/build), MIT license, and setup guide.
- Login — access-code authentication.

The web app supports 17 UI languages via `@ngx-translate`, loaded from `/i18n/<locale>.json`.

These pages are for remote browser / tunnel clients. The in-car app does **not**
embed them — it is a Flutter app talking to the same daemon over ConnectRPC.

## In-Car UI (Flutter)

The in-car UI ships as its own APK, `net.bladewatch.flutter`, sharing a UID with
the daemon host. It provides (Material 3 — see
[UI/UX Design Language](ui-ux-design-language.md)):

- Navigation rail shell with 8 destinations — Dashboard, Live, Recordings,
  Vehicle, Trips, Location, Diagnostics, Settings — mirrored to the driver's side.
- Branded launch: a native window background
  (`flutter_ui/android/app/src/main/res/drawable/launch_background.xml`) paints
  the app icon and wordmark from the first frame, and the Startup screen redraws
  the same lockup in Dart (`widgets/brand_lockup.dart`) so the branding is
  continuous rather than a flash — Startup waits on the daemons, which is far
  longer than the window background survives. The two must be changed together
  or the handoff visibly jumps. The pre-surface frame is white in light mode and
  black in dark (`values/colors.xml` + `values-night/colors.xml`).
- Startup / daemon boot progress.
- Dashboard.
- Live camera view (the one platform-channel exception: a Kotlin texture plugin
  decodes the H.264 WebSocket stream through `MediaCodec` and hands Flutter a
  `TextureRegistry` id; everything else is Dart).
- Recordings library and video playback.
- Surveillance settings.
- Trips list, stats and storage.
- Vehicle view (tabbed, with the three.js tyre-pressure hero in a
  `webview_flutter`).
- Location (`flutter_map` on MAPNIK tiles, car marker, follow/recenter, theming).
- Diagnostics, Performance monitor (CPU/memory/GPU/app metrics), and an ADB
  console / shell runner with preset commands (in-car only; not exposed in the
  web build).
- Notifications and Web Push management.
- Daemon status and control.
- Settings (Appearance, Recording, Surveillance, Status overlay, Daemons,
  Privacy, About) and the language picker.

The service host APK (`net.bladewatch.app`) draws only the status overlay and the
setup-guide dialog. It has no launcher entry.

## BYD Local Telemetry

The app reads local BYD framework data through reflection and listener registration.

Telemetry areas include:

- Bodywork.
- Speed.
- Engine.
- Statistic data.
- Energy.
- Tyres.
- Charging.
- Door locks.
- Instrument cluster values.
- OTA state.
- Sensors.
- Gearbox.
- Safety belts.
- Air conditioning.
- Lights.
- ADAS.
- Radar.
- Power.
- Settings.
- Multimedia.

The collector isolates failures by device type so one unavailable BYD API does not disable all telemetry.

## Local Vehicle Control

The in-car app includes a Vehicle screen under `flutter_ui/lib/screens/vehicle/`. Its tab bar exposes three control tabs:

- **Climate** — AC on/off, max cooling toggle, temperature and fan speed.
- **Seats** — heat and ventilation level for driver and passenger (Off / Low / High). The tab is hidden when no seat controls are available.
- **Windows** — per-window open/close/vent controls (LF, RF, LR, RR) plus an all-windows close/vent/open.

The Angular web `Vehicle` page mirrors the same three tabs (Climate / Seats / Windows), plus read-only lock and charge/range pills, TPMS cards, and a GPS card.

The hero region above the tabs shows a Three.js-rendered car with a tyre-pressure overlay: per-corner cards (FL/FR/RL/RR) colour-coded by pressure tier (NORMAL/CAUTION/WARN/ALERT/MUTED), with alert cards distinguishing fast vs slow air-leak states. The hero renders in a `webview_flutter` WebView pointed at `app/src/main/assets/web/hero/hero.html`; **the previously attempted native Filament port was removed because the BYD Adreno 610 GL driver crashes under continuous gltfio rendering — do not reintroduce it.**

The vehicle UI supports 17 languages (Flutter ARB catalogs under `flutter_ui/lib/l10n/`, and the web app via `@ngx-translate`).

All write actions route through `VehicleCommandRouter`. Lock/Unlock/Flash were removed from both the in-car view and the web page by design — there is no local SDK path and these were never wired to cloud control here. The proto `VehicleService` still declares cloud-style RPCs (Lock, Unlock, Trunk, Flash, FindCar, SetLights, SetAdas, SetBatteryHeat, SetChargingSchedule, SetChargeCap), but the active local controls surfaced to users are:

- Climate (power, max cooling, temperature, fan).
- Seats (heat / ventilation).
- Windows (per-window and all-windows position).
- Read-only lock state, charge/range, and TPMS.
- GPS location (`GetGpsLocation`, also used by the Location screen).
- Diagnostics and state reads (AC / seat diagnostics, charge cap).

## Trips and Analytics

Trip functionality includes:

- Trip list and details.
- Telemetry history per trip.
- Similar trip lookup.
- GPS traces.
- Summary statistics.
- Driving DNA.
- Range analytics.
- Trip config.
- Trip storage management.

## Performance and Telemetry

Performance features include:

- Real-time performance status.
- Historical performance views.
- Connection and heartbeat APIs.
- Battery and SOC data.
- Parking delta.
- Charge session and last-charge tracking.
- Telemetry overlay config.

Battery state-of-health estimation is not available. The nominal battery capacity value from BYD local telemetry is accessible through the SOC nominal endpoint, but no SoH estimator runs.

## Notifications and Push

Notification features include:

- Notification category APIs.
- Web Push subscription management (PWA push).
- Push preference updates.
- Test push endpoint.
- Android notification channels and foreground service notifications.

Surveillance and proximity events deliver notifications through Web Push. There is no Telegram notification path.

Tapping a push opens the Angular SPA at the route for that category — `/events?filter=sentry` or `/events?filter=proximity` for surveillance and proximity clips, `/vehicle` for TPMS, door, and charging alerts. Event pushes also carry the clip name as `file=`, which opens that recording directly, and a pre-signed snapshot URL as `hero=`, which the events page renders as an inline banner. The banner exists because iOS Safari ignores `options.image` on Web Push, so the snapshot never reaches the OS notification banner; only a same-origin `/thumb/` path is accepted for `hero=`. Category click targets live in [notifications-categories.json](../app/src/main/assets/notifications-categories.json) as `defaultClickUrl`, used when an event carries no URL of its own.

## Remote Access

Remote access options include:

- Local loopback web server.
- Opt-in LAN HTTP.
- Zrok public or reserved share.

LAN HTTP is disabled by default. Zrok is designed to front the authenticated local web server directly with no intermediate proxy.

## Updates

The app includes update APIs for:

- Checking update metadata.
- Previewing available updates.
- Installing confirmed updates.
- Reporting install progress.
- Handling post-update daemon reset behavior.

## Diagnostics and Logs

Diagnostics exist across the in-car UI, daemon state, ConnectRPC/HTTP APIs, and log files. The app includes daemon health checks, process revival, overlay status, and logging utilities.

The Diagnostics screen surfaces Network, Storage, Camera, and Battery tiles, a Camera Probe dialog (Auto or pin camera 0-5), and a Battery Health dialog with an SOH reset. The Battery tile shows the current state-of-charge percentage. An ADB console / shell runner (`flutter_ui/lib/screens/diagnostics/adb_console_screen.dart`) provides preset and ad-hoc shell commands; it is intentionally not exposed in the web build.

## ConnectRPC API

The daemon exposes a typed ConnectRPC API (also reachable over Connect/JSON HTTP) defined by the `bladewatch.v1` proto contracts in `proto/`. It comprises 12 services — Auth, Notifications, Recordings, SafeLocations, Settings, Storage, Stream, Surveillance, System, Trips, Update, and Vehicle — consumed by the Angular web client (TypeScript stubs), the Flutter in-car UI (Dart stubs under `flutter_ui/lib/gen/`), and the daemon host (Kotlin stubs). The web client wraps all 12 services in a single `ConnectClients` injectable.

## Source References

- Recording and camera control: [CameraDaemon.java:677](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L677), [GpuSurveillancePipeline.java:1194](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java#L1194), [GpuMosaicRecorder.java:614](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuMosaicRecorder.java#L614), [RecordingsApiHandler.java:41](../app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java#L41).
- ACC-on recording modes: [RecordingModeManager.java:31](../app/src/main/java/com/loabletech/bladewatch/recording/RecordingModeManager.java#L31), [RecordingModeManager.java:533](../app/src/main/java/com/loabletech/bladewatch/recording/RecordingModeManager.java#L533), [ProximityRecordingHandler.java:49](../app/src/main/java/com/loabletech/bladewatch/proximity/ProximityRecordingHandler.java#L49).
- Surveillance and AI: [SurveillanceEngineGpu.java:22](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.java#L22), [MotionPipelineV2.java:14](../app/src/main/java/com/loabletech/bladewatch/surveillance/MotionPipelineV2.java#L14), [YoloDetector.kt:43](../app/src/main/java/com/loabletech/bladewatch/ai/YoloDetector.kt#L43), [SurveillanceConfig.java:9](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceConfig.java#L9).
- Live streaming: [GpuSurveillancePipeline.java:30](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java#L30), [WebSocketStreamServer.java:19](../app/src/main/java/com/loabletech/bladewatch/streaming/WebSocketStreamServer.java#L19), [HttpServer.java:538](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L538).
- Embedded web UI: [HttpServer.java:49](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L49), [app/src/main/assets/web/shared/core.js:537](../app/src/main/assets/web/shared/core.js#L537).
- BYD telemetry and vehicle control: [BydDataCollector.java:20](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L20), [VehicleControlApiHandler.java:43](../app/src/main/java/com/loabletech/bladewatch/server/VehicleControlApiHandler.java#L43), [VehicleCommandRouter.java:37](../app/src/main/java/com/loabletech/bladewatch/byd/routing/VehicleCommandRouter.java#L37), [flutter_ui/lib/screens/vehicle/](../flutter_ui/lib/screens/vehicle/).
- Proximity radar recording: [ProximityRadarMonitor.java:16](../app/src/main/java/com/loabletech/bladewatch/proximity/ProximityRadarMonitor.java#L16), [RadarConstants.java:27](../app/src/main/java/com/loabletech/bladewatch/byd/radar/RadarConstants.java#L27), [ProximityRecordingHandler.java:49](../app/src/main/java/com/loabletech/bladewatch/proximity/ProximityRecordingHandler.java#L49).
- Location and GPS: [flutter_ui/lib/screens/location/](../flutter_ui/lib/screens/location/), [location.component.ts:1](../web/src/app/pages/location/location.component.ts#L1), [vehicle.proto:51](../proto/bladewatch/v1/vehicle.proto#L51).
- Trips, notifications, updates, and diagnostics: [TripAnalyticsManager.java:23](../app/src/main/java/com/loabletech/bladewatch/trips/TripAnalyticsManager.java#L23), [TripApiHandler.java:35](../app/src/main/java/com/loabletech/bladewatch/trips/TripApiHandler.java#L35), [NotificationApiHandler.java:30](../app/src/main/java/com/loabletech/bladewatch/server/NotificationApiHandler.java#L30), [PerformanceApiHandler.java:30](../app/src/main/java/com/loabletech/bladewatch/server/PerformanceApiHandler.java#L30), [adb_console_screen.dart](../flutter_ui/lib/screens/diagnostics/adb_console_screen.dart).
- ConnectRPC API and web UI: [connect-clients.ts:19](../web/src/app/core/connect/connect-clients.ts#L19), [app.routes.ts:5](../web/src/app/app.routes.ts#L5).
- Remote access: [ZrokLauncher.kt:27](../app/src/main/java/com/loabletech/bladewatch/launcher/ZrokLauncher.kt#L27).
