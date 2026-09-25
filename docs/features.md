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
- One-tap bookmark on the recording currently being written (`MarkRecording`,
  BladeWatch-nmao.4) — a Live View button that flags "something happened here"
  without starting a new file, split, or copy. Marked clips are excluded from
  automatic storage cleanup (see [data-flow-and-storage.md](data-flow-and-storage.md))
  and show a marked indicator in the recordings list.
- Recording Priority — Performance vs. Reliability (BladeWatch-gyg1.3). Settings screen
  copy: "Performance — uses less CPU. If power is cut abruptly, the current recording
  segment (up to your Recording Limit) may be lost." / "Reliability — uses a bit more
  CPU to save more often. If power is cut abruptly, at most about a minute may be lost."
  Reliability is the default for new installs; existing installs keep today's behaviour
  (Performance) until changed. See [data-flow-and-storage.md](data-flow-and-storage.md).

Default camera-related values found in code:

- Panoramic recording resolution: `5120x960`.
- View resolution: `1280x960`.
- Default frame rate: `25 fps`.
- Default recording bitrate: `4 Mbps`.
- Segment length: user-configurable "Recording Limit" — `1`, `5` (default), or `10 minutes`
  per file; the Reliability recording priority above caps this to `1 minute` regardless of
  the Recording Limit choice.

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
- Honest in-app warnings: a persistent note that arming Sentry mode draws extra
  12V battery power while armed, and a conditional note (shown only while another
  app actually holds the camera) that camera access has been yielded to it.

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
- Still-frame fallback for browsers with no usable H.264 decoder (WebCodecs or MSE) — a
  periodically refreshed JPEG, clearly labelled "still image, not live video", so the remote
  web view degrades instead of failing outright. See `docs/networking-and-tunnels.md`.

## Embedded Web UI and PWA

The primary web UI is an Angular 19 single-page app (source in `web/`, built with Vite, talking to the daemon over ConnectRPC). Its build output is bundled under `app/src/main/assets/web/angular/`, extracted by the daemon to `/data/local/tmp/web`, and served locally. The retained hand-written assets (the login page, PWA manifest/service worker and credits under `local/`, plus the shared 3D/vendor assets under `shared/`) and the Three.js Vehicle hero (`hero/hero.html`) also ship under `app/src/main/assets/web/`. The old static HTML pages and their `/legacy/` route were retired once the SPA was confirmed stable.

Angular pages (routes), each built for 1:1 parity with its in-car counterpart:

- Dashboard — stats / connect hub (week trip stats, status chips, metric tiles, device-ID + tunnel-URL QR connect card). In-car status chips also show the gear, drive mode (ECO / NORMAL / SPORT), Auto Hold (on / off) and, on a DM-i, EV / HEV (BladeWatch-7zp9, -os88; a dash for anything unmeasured -- see byd-integrations.md). The THIS WEEK card shows its trip count and distance once, in its tiles (BladeWatch-by8d).
- Live — full-bleed camera view with All/Front/Right/Rear/Left selector over the WebSocket stream.
- Recording — dashcam vs surveillance library with day calendar navigation, actor/severity/type filter chips, multi-select delete, and an in-page video player.
- Surveillance — sensitivity, distance preset, AI gate + confidence, per-class detection, pre/post windows, quadrant snapshots, heatmap, and safe-location zones.
- Events — surveillance (sentry) event clips with the shared player.
- Trips — Trips / Stats / Storage tabs, Leaflet route map, driving DNA, personalized range, electricity-rate config.
- Vehicle — Climate / Windows control tabs, read-only lock + charge/range pills, TPMS cards, and a GPS card.
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
  `TextureRegistry` id; everything else is Dart). The camera takes the full
  stage, with a narrow utility rail alongside it carrying the direction
  selector, the recording bookmark button, and a location preview — tapping
  the preview opens the full Location destination, which stays in the nav
  rail (BladeWatch-y78o.2).
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

- **Climate** — AC on/off, max cooling toggle, temperature and fan speed, the outside temperature (the car exposes no cabin temperature — BladeWatch-eh3u), and an explicit screen on/off control (BladeWatch-2000.3 — see below).
- **Windows** — per-window open/close/vent controls (LF, RF, LR, RR) plus an all-windows close/vent/open. The sunroof offers 0 / 50 / 100 %, the only stops its hardware has, and shows where the app last sent it (BladeWatch-b3n7).

There is no seat control anywhere in BladeWatch: seat heating, ventilation and memory recall were removed end to end on the owner's decision (BladeWatch-7bx4, 2026-09-25).

The Angular web `Vehicle` page mirrors the same two tabs (Climate / Windows), plus read-only lock and charge/range pills, TPMS cards, and a GPS card.

The hero region above the tabs shows a Three.js-rendered car with a tyre-pressure overlay: per-corner cards (FL/FR/RL/RR) colour-coded by pressure tier (NORMAL/CAUTION/WARN/ALERT/MUTED), with alert cards distinguishing fast vs slow air-leak states. The hero renders in a `webview_flutter` WebView pointed at `app/src/main/assets/web/hero/hero.html`; **the previously attempted native Filament port was removed because the BYD Adreno 610 GL driver crashes under continuous gltfio rendering — do not reintroduce it.**

The vehicle UI supports 17 languages (Flutter ARB catalogs under `flutter_ui/lib/l10n/`, and the web app via `@ngx-translate`).

Nearly every write action routes through `VehicleCommandRouter`, which gates BYD SDK
actuations behind the motion interlock; media volume (below) is the one deliberate exception.
Lock/Unlock/Flash were removed from both the in-car view and the web page by design — there is no local SDK path and these were never wired to cloud control here. The proto `VehicleService` still declares cloud-style RPCs (Lock, Unlock, Trunk, Flash, FindCar, SetLights, SetAdas, SetBatteryHeat, SetChargingSchedule, SetChargeCap), but the active local controls surfaced to users are:

- Climate (power, max cooling, temperature, fan, front/rear defrost — BladeWatch-2000.1). Wind mode and air-cycle mode are also routed and gated identically, but carry a raw, unlabelled SDK integer with no UI picker: their value meanings are not established anywhere in source, and shipping a labelled control ("Face", "Recirculate", ...) would be a guess actuating the physical car. See `docs/byd-integrations.md`'s "Wind mode and cycle mode" section; establishing the real mapping needs a device and is filed as `BladeWatch-2000.4`.
- Screen on/off (BladeWatch-2000.3) — explicit user action, wired through `VehicleCommandRouter.ScreenOnCommand`/`ScreenOffCommand` to the BYD vendor `PowerManager` backlight primitive (`BacklightController`, shared with the sentry stealth-panel path). Safety requirements, non-negotiable:
  - Screen **off** is permitted only while parked (`DrivingSafetyGuard.evaluate(...)` returns `ALLOW`) — refused otherwise, including when the motion state is unknown.
  - Screen **on** is permitted in every state, including while moving — giving the driver their screen back is never the unsafe direction.
  - If the screen was switched off by this control and the vehicle then leaves the parked state, it is turned back on automatically (`ScreenAutoRecovery`) with no user action required.
  - No screen-off timer, schedule, or automation hook exists or is permitted — off is explicit-only.
- Media volume and mute (BladeWatch-2000.2) — set to an absolute 0-100%, step up/down, mute/unmute (restores the exact pre-mute level, not a default). Android's own `AudioManager` (`STREAM_MUSIC`) only, no BYD SDK. Deliberately **not** routed through `VehicleCommandRouter` — adjusting volume is ordinary, safe-while-driving behaviour (a physical volume knob is never gated on being parked), unlike the actuations that router gates. Touches only the volume level — no audio route, focus request, output device change, or sound playback of any kind.
- Windows (per-window and all-windows position).
- Read-only lock state, charge/range, and TPMS.
- GPS location (`GetGpsLocation`, also used by the Location screen).
- Diagnostics and state reads (AC diagnostics, charge cap).

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
- PHEV fuel leg: litres burned, fuel cost, and a dual-leg trip cost.
- Period costs (BladeWatch-39d2, -mgi9, -c149): the fuel, electric and total cost of a period's
  trips, on the dashboard's THIS WEEK card (in-car and companion, under the trip count, distance
  and drive time), on the Trips Stats tab under Personalized Range, and in the Period Summary.
  One definition in `packages/bladewatch_rpc/lib/trips/trip_costs.dart` (`TripCosts`): per trip,
  `tripCost` is the total and the electric half is `tripCost - fuelCost`, so trips from before the
  fuel leg count fully as electric. Every trip of the period is summed (paging past ListTrips'
  100 per call). Fuel is left out on a car that recorded none; with no rate set the card says so
  instead of showing zeros; amounts in different currencies are never added.

### Fixed: blank Energy tile and 0% "Today" efficiency (Flutter)

Two related client-side display bugs, both in `flutter_ui/lib/screens/trips/`:

- **Trip detail's Energy tile always showed "--"**, even on trips with a clear SoC drop and a
  nonzero electric cost. `trip_detail_controller.dart` hardcoded `energyUsedKwh` to `0.0`,
  reasoning (matching a comment in the native Android reference client) that `TripSummary`'s
  proto has no direct kWh-consumed field. It has `energy_per_km` instead, and
  `energy_per_km * distance_km` **is** that value — the daemon derives one from the other
  internally. Fixed by deriving it client-side rather than reproducing the native gap.
- **The Trips screen's "Today" stat showed 0% efficiency** on days with only short trips.
  `trips_controller.dart` summed `avgEfficiency` from each weekly rollup — the daemon's legacy
  SoC-delta-per-km metric, which is exactly `0.0` whenever a trip's *coarse, integer* SoC%
  reading didn't visibly drop (routine on a short trip) even though real energy was used. Fixed
  by reading `avgEfficiencyScore` instead — the same 0-100, kWh-preferred score
  `TripScoreEngine` already computes correctly and stores in a separate rollup column that the
  client just wasn't reading.

Neither fix touched the daemon; both values were already being computed and sent correctly.

### PHEV trips

On a plug-in hybrid a trip records the petrol leg alongside the electric one, and
`tripCost` becomes `electricCost + fuelCost`. On a BEV `fuelCost` is always 0, so
`tripCost` is unchanged from the electric-only figure it has always been.

Litres come from the delta between two readings of the car's LIFETIME fuel counter,
never from tank percent — percent has no litre scale without a tank capacity, and BYD
local data does not expose one.

The trip detail view in **both** UIs shows the breakdown — litres burned, fuel cost and
electric cost — alongside the combined `tripCost`. It appears only when the trip actually
recorded the fuel counter at both ends (`hasFuelData`), so a BEV renders exactly as it
always has rather than gaining three permanent zeroes. That flag is derived from the
STORED trip, never from a live drivetrain probe, so a historical trip looks the same
forever even on a car whose drivetrain reads differently today.

A PHEV leg driven entirely on battery shows `0.0 L` rather than hiding the rows: the
counter was read and its answer was zero, which is a measurement, and hiding it would
make a real result indistinguishable from a BEV.

These are settable in **both** UIs — the web settings and the in-car Trips screen — so a
driver on the head unit can price a PHEV trip without reaching for a browser over the tunnel.
The currency is chosen from the full ISO 4217 list in both.

**On a BEV the fuel settings are not shown at all.** `TripConfig` carries an `is_phev` flag —
a live drivetrain read, not a stored setting — and both UIs hide the fuel price and tank
capacity when it is false. A car with no tank offering "Fuel Tank Capacity (litres)" reads as
a bug in the app, not as an unused option.

The gate is deliberately not a bare `is_phev`: a value that is ALREADY configured keeps the
fields visible so it can be cleared. The drivetrain probe returns false while the HAL is warming
up, and an owner must never be left with a fuel price that is still applied by a field that has
disappeared.

Two values are configurable and both default to 0 meaning "not configured":

- `fuelPricePerL` — without it the litres are still recorded, just not costed.
- `fuelTankCapacityL` — without it no fuel RANGE can be predicted. Nothing is guessed
  here: a wrong range figure on a dashboard is worse than a blank one, because the
  driver acts on it. The car's own `fuelRangeKm` is still reported for comparison.

Fuel range is reported separately from electric range and never summed into it: the two
are drawn from different tanks with different confidence, and a combined number would
hide which one is about to run out.

Both UIs render it on the range card, under the electric figure, and only when it could
actually be computed: the daemon returns -1 when no tank capacity is configured, and that
sentinel is hidden rather than shown as a range. The car's own `builtInFuelRangeKm` appears
beside it for comparison, mirroring how the electric estimate shows BYD's own number.

A PHEV can learn a fuel rate before it has enough electric samples, so the fuel figure
renders even when the electric estimate is still empty.

## Performance and Telemetry

Performance features include:

- Real-time performance status.
- Historical performance views.
- Connection and heartbeat APIs.
- Battery and SOC data.
- Parking delta.
- Charge session and last-charge tracking.
- Telemetry overlay config, including a per-recording-type field checklist
  (speed, gear, turn signals, brake/accelerator pedals, driver/passenger
  seatbelt, timestamp — BladeWatch-y78o.5). **VIN and GPS coordinates are
  deliberately not selectable fields.** GPS latitude/longitude is still burned
  in unconditionally whenever a fix is available — an existing, pre-y78o.5
  behaviour this issue's own scope explicitly left unchanged — through a
  separate code path the field checklist does not touch, gate, or expose as a
  toggle. See [data-flow-and-storage.md](data-flow-and-storage.md) for why.

Battery state-of-health estimation is not available. The nominal battery capacity value from BYD local telemetry is accessible through the SOC nominal endpoint, but no SoH estimator runs.

## Notifications and Push

Notification features include:

- Notification category APIs.
- Web Push subscription management (PWA push).
- Push preference updates.
- Test push endpoint.
- Android notification channels and foreground service notifications.

Surveillance and proximity events deliver notifications through Web Push. There is no Telegram notification path.

**Companion app: store and forward (BladeWatch-rdtj.14).** The car keeps every notification
it raised: the last 200, for up to 14 days. A newer event with the same tag replaces the
older one. Each time the companion connects, over the LAN or Pear, it collects the alerts
it has not seen yet (`NotificationsService.ListInbox`). No push service is involved: an
alert reaches the phone the next time the companion connects, not the moment it happens.
The owner chose that trade over depending on a central push relay.

Tapping a push opens the Angular SPA at the route for that category — `/events?filter=sentry` or `/events?filter=proximity` for surveillance and proximity clips, `/vehicle` for TPMS, door, and charging alerts, `/trips` for trip lifecycle alerts. Event pushes also carry the clip name as `file=`, which opens that recording directly, and a pre-signed snapshot URL as `hero=`, which the events page renders as an inline banner. The banner exists because iOS Safari ignores `options.image` on Web Push, so the snapshot never reaches the OS notification banner; only a same-origin `/thumb/` path is accepted for `hero=`. Category click targets live in [notifications-categories.json](../app/src/main/assets/notifications-categories.json) as `defaultClickUrl`, used when an event carries no URL of its own.

`trips.started` and `trips.ended` (`TripEventNotifier`, BladeWatch-nmao.3) notify on trip boundaries detected by the gear-based `TripDetector` state machine. Both are **off by default** — a trip ends every time the owner parks, and a notification on every park is how people turn all notifications off. `trips.ended`'s payload carries the trip's distance and duration; discarded trips (below the minimum duration/distance thresholds) never publish anything.

## Remote Access

Remote access options include:

- Local loopback web server.
- Opt-in LAN HTTP.
- Tor onion service (permanent address, no account or token).

**Companion app pairing (v1.4.0.0).** "Pair a device" on the in-car dashboard shows a QR
for the BladeWatch companion app (phones and desktops). The code works once and expires after
five minutes; pairing switches on remote access over Pear, and the same dialog explains and
offers the opt-in direct connection on the car's Wi-Fi. Paired devices are listed there and
can be removed one at a time, which cuts off that device immediately without affecting the
others. Pairing and removing are only possible in the car.

**The companion app (v1.4.0.0, BladeWatch-rdtj.11).** The phone and desktop app that
replaces the web UI. It reaches the car directly on its Wi-Fi when both are on one network,
otherwise over Pear. It has every page the web app had:

- Dashboard.
- Live view.
- Events, meaning the store-and-forward alerts plus the surveillance and proximity clips.
- Recordings, with playback and delete.
- Vehicle: status, climate and windows.
- Location, on a map.
- Trips: routes, scores, range, driving DNA and storage.
- Surveillance: arm and disarm, detection settings, camera snapshots and safe zones.
- Notifications: which alert categories this device shows, and a test alert.
- Settings.
- Performance.
- Diagnostics.
- About.

The web login is replaced by pairing: scan the in-car QR, or paste its text.

- **Paired stays paired.** Only removing the device in the car, or Unpair in the companion, ends
  a pairing; restarts, updates, reboots and a car that cannot answer yet do not (BladeWatch-w7by;
  see ipc-auth-and-secrets.md, "Companion pairing").
- **Connection state is explicit on every page.** It is one of three: still looking for the
  car (a Pear lookup can take a minute), can't reach it (it keeps retrying), or the car
  removed this device (pair again). None of these is ever a spinner that never resolves.
- **Live view is refreshed stills for now.** It shows the four-camera mosaic, updated every
  few seconds, and works on every platform without a video decoder. H.264 video, and with it
  the per-camera views, is a follow-up.
- **Window control asks first, every time.** From a phone, nobody can see whether a hand or
  a pet is in a window. Climate changes are reversible and don't ask. Every command
  carries the car's short-lived action token, and the car's own safety interlock still
  decides.
- **The app is in all 17 of the web app's languages.**
- **Platforms.** It runs on Android, iOS, macOS, Windows and Linux. Clips play in the app on
  Android, iOS and macOS; elsewhere they download. The QR scanner uses the camera on Android,
  iOS and macOS; elsewhere, paste the code's text.

**Remote access status (v1.4.0.0).** Settings -> Services lists "Remote access (Pear)" with
its switch, and, while it runs, whether the car can be reached from anywhere right now
(which a running process alone does not mean), how many paired devices are connected, and
when one last connected. The dashboard's Remote access tile shows the same while Pear is on:
Online, Offline, Starting, or Running when reachability cannot be determined.

LAN HTTP is disabled by default. The Tor onion service fronts the authenticated local web server directly with no intermediate proxy. The onion address is a capability URL, not authentication: the password/JWT layer stays mandatory.

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

The Network tile also shows BladeWatch's own monthly network usage (BladeWatch-t1lg.1) — own-UID
`TrafficStats` totals, not whole-device usage, since a metered head-unit SIM makes "what does
BladeWatch itself cost me" a real question. It survives daemon restarts and device reboots (a
reboot resets the underlying counter; that reset is detected and credited forward rather than
subtracted, so the running month total never goes backward or silently loses data) — see
[networking-and-tunnels.md](networking-and-tunnels.md) for the accounting details.

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
- Remote access: [TorLauncher.kt:44](../app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt#L44).
