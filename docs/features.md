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
- The in-car Surveillance screen's Status row reads Running only while sentry is armed
  (BladeWatch-nrwh). It is not Running just because the preference is on (for example while
  the door-lock gate is still pending after ACC OFF) or because the camera pipeline is running
  for dashcam recording.

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

A dedicated Location experience exists in both the in-car UI and the companion app:

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
- Still-frame live view for the companion — a JPEG refreshed 10 times a second
  (`/api/stream/still`), clearly labelled as a still, not live video. See `docs/networking-and-tunnels.md`.

## No web app

The Angular web app (`web/`), its login, its PWA assets and Web Push were removed in v1.4.0.0
(BladeWatch-rdtj.22). The in-car UI is Flutter and the phone and desktop client is the companion
app (below); a browser is not a client of the car any more, and the daemon serves no static files.

## In-Car UI (Flutter)

The in-car UI ships as its own APK, `net.bladewatch.incarapp`, sharing a UID with
the daemon host. It provides (the cyberpunk HUD look, dark and light, since
v1.4.1.0 — see [UI/UX Design Language](ui-ux-design-language.md)):

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
- The Startup screen's timers (the header and each daemon row) count from the moment it
  opened, whether or not the daemon channel answers yet; they used to stay at "0s" until the
  first successful poll, which is the whole ~45 s after a boot (v1.4.1.2, BladeWatch-y87b).
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
- Notification category choices and a test alert.
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

The hero region above the tabs shows a Three.js-rendered car with a tyre-pressure overlay: per-corner cards (FL/FR/RL/RR) colour-coded by pressure tier (NORMAL/CAUTION/WARN/ALERT/MUTED), with alert cards distinguishing fast vs slow air-leak states. The hero renders in a `webview_flutter` WebView pointed at `flutter_ui/assets/web/hero/hero.html`; **the previously attempted native Filament port was removed because the BYD Adreno 610 GL driver crashes under continuous gltfio rendering — do not reintroduce it.**

The vehicle UI supports 17 languages (Flutter ARB catalogs under `flutter_ui/lib/l10n/`; the companion carries its own catalogs).

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
- Charge and fuel now (BladeWatch-4zr7): the battery and electric range and, on a car with a
  tank, the fuel and fuel range, in the car's distance unit. These are current values from the
  GetStatus the dashboard already makes; the fuel pair is left out when the car reports neither
  (a BEV). Since 2026-10-04 they are the car's, not the week's: in the car a VEHICLE card under
  THIS WEEK, on the same three columns; in the companion the Vehicle section, a value over its
  label two to a row, ahead of This week. The companion dropped its SOC row (it is Battery) and
  its total Range (the two ranges added up). Refresh: charge and fuel every 2 s in the car (on
  the drive chips' status read) and every 5 s in the companion; the week's trips and costs once
  a minute in both.
- What is left, as an amount: battery and fuel read "77% / 14.1 kWh" and "30% / 14 L" (on the
  in-car VEHICLE card, the companion's Vehicle section and its Vehicle page's Charge and Fuel)
  once the size is known, and just the percent until then.
  The amount is percent x size (`energyLeft` in `bladewatch_rpc`, shared by both apps): the
  pack's nominal kWh from `GetSohNominal` (SDK, or the model picked in the in-car Vehicle
  dialog), and the tank's litres from Settings -> Trips -> fuel tank capacity, since BYD exposes
  no tank size. It is an estimate: battery health and BYD's reserve are not counted. The sizes
  reload with the 15 s refresh in the car and once a minute in the companion. The companion
  writes the amount with no-break spaces (`Fmt.energy`), so a narrow phone row wraps only after
  the slash. Its Battery capacity dialog was removed as redundant (2026-10-04): the pack size
  comes from the selected model.

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
The currency is picked from a list of currency symbols (`$`, `€`, `₱`, no ISO codes) in both apps.

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

## Notifications

Notification features include:

- Notification category APIs.
- A test alert endpoint.
- Android notification channels and foreground service notifications.

Surveillance and proximity events raise notifications on the car's notification bus; the companion
collects them from the car's store-and-forward inbox (below). Web Push (browser push) was removed
with the web app, and there is no Telegram notification path.

**Companion app: store and forward (BladeWatch-rdtj.14).** The car keeps every notification
it raised: the last 200, for up to 14 days. A newer event with the same tag replaces the
older one. Each time the companion connects, over the LAN or Pear, it collects the alerts
it has not seen yet (`NotificationsService.ListInbox`). No push service is involved: an
alert reaches the phone the next time the companion connects, not the moment it happens.
The owner chose that trade over depending on a central push relay.

A notification carries an optional click URL naming where it points: `/events?filter=sentry` or `/events?filter=proximity` for surveillance and proximity clips (with the clip name as `file=`), `/vehicle` for TPMS, door and charging alerts, `/trips` for trip lifecycle alerts. The companion reads the clip name from it to open the recording. Category click targets live in [notifications-categories.json](../app/src/main/assets/notifications-categories.json) as `defaultClickUrl`, used when an event carries no URL of its own.

`trips.started` and `trips.ended` (`TripEventNotifier`, BladeWatch-nmao.3) notify on trip boundaries detected by the gear-based `TripDetector` state machine. Both are **off by default** — a trip ends every time the owner parks, and a notification on every park is how people turn all notifications off. `trips.ended`'s payload carries the trip's distance and duration; discarded trips (below the minimum duration/distance thresholds) never publish anything.

## Settings PIN Lock

A 6-digit PIN, held by the car (BladeWatch-hr6r), can protect Settings and Surveillance from
anyone with physical access to the head unit — a valet, a passenger, a child in the back seat.
Turn it on from **Settings > Security**: set a PIN (entered twice, to catch a typo), and from
then on opening Settings or Surveillance — from the nav rail, from a shortcut elsewhere in the
app, or pairing a new companion device from Settings > Security — asks for it first. A wrong PIN says
how many tries are left; five wrong PINs in a row lock entry out for a minute, doubling on each
further miss. Leaving Settings, or the head unit's screen going to sleep, locks it again — the
next person to open Settings sees the PIN prompt, not whatever pane was left open.

The PIN is the car's, not the app's: every paired companion checks the same one, and a forgotten
PIN can be reset from any companion that unlocks itself locally (fingerprint or face, where the
device has one) without needing the old PIN. This is a screen lock, not an access-control list —
anything already authorized to talk to the car's API (a companion's login, a direct RPC call)
still works exactly as before; the PIN only gates what the two apps' own Settings screens show.

**In the companion app**, the same PIN also gates Surveillance and Notifications, not just
Settings — those are where a remote viewer sees camera footage and alerts, so they get the same
screen lock as Settings. Turning the lock on or off, and changing the PIN, is done from
**Settings** in the companion too (a switch plus a "Change PIN" button once it is on); the setting
and the cached last-known lock state travel with the paired car, so a companion that cannot reach
the car still shows the PIN prompt rather than silently admitting if the lock was last known to be
on. Backgrounding the companion app relocks immediately and returns to Dashboard, so switching
away mid-session never leaves a gated screen unlocked for whoever picks the phone up next.

**Biometric unlock (v1.4.1.4, BladeWatch-hr6r.6).** A companion device with a fingerprint reader
or face recognition can use it instead of typing the PIN each time. It is off by default and
per device: turning on **Use biometrics instead of PIN** in Settings asks for the car's PIN one
last time to prove the owner knows it, then that device's own sensor opens Settings, Surveillance
and Notifications from then on. A failed or cancelled biometric check falls back to the PIN
dialog, which offers a button to try the sensor again. Unpairing the device turns the opt-in back
off — a different car has a different PIN, so the device must prove it again before trusting its
sensor for it. Biometric unlock is local to the device (the car is never asked), which is sound
only because pairing a new companion already requires the PIN at the car; see
docs/ipc-auth-and-secrets.md for the threat-model note. Devices without a sensor, or with none
enrolled — Android TV included — never see the switch and keep using the PIN.

## Remote Access

Remote access options include:

- Local loopback web server.
- Opt-in LAN access: TLS on 8443 with a pinned self-signed certificate.
- The companion app over Pear (below). The Tor onion service of v1.3.x was removed in
  v1.4.0.0 (BladeWatch-rdtj.12), and with it the Dashboard's Connect card: the onion QR, the
  device ID and the web access code. The web app and its login were removed too (BladeWatch-rdtj.22).

**Companion app pairing (v1.4.0.0).** "Pair a device" in the in-car Settings > Security pane
(moved there from the Dashboard in v1.4.1.4, BladeWatch-xfb5 -- device pairing is configuration,
not status) shows a QR for the BladeWatch companion app (phones and desktops). The code works
once and expires after five minutes; pairing switches on remote access over Pear, and the same
dialog explains and offers the opt-in direct connection on the car's Wi-Fi. Paired devices are
listed there and can be removed one at a time, which cuts off that device immediately without
affecting the others. Pairing and removing are only possible in the car, and -- since the
Settings PIN lock (BladeWatch-hr6r) -- both ask for the PIN first whenever the lock is on. The
companion names itself in that list with the device's own name -- the computer name on macOS and
Windows, the phone's name on Android and iOS (iOS 16+ gives only "iPhone") -- and the owner can
edit it before pairing.

**Pairing a TV or a computer (v1.4.1.2).** Devices without a camera -- Android TVs, and the
macOS, Windows and Linux companions -- pair over the car's Wi-Fi instead of scanning: with
Pair a device open in the car and Direct connection on, choose **Pair over Wi-Fi** on the device.
Both screens show the same six-digit number and the owner taps **Pair** in the car if they match.
Phones keep scanning the QR; desktops no longer offer the scan. Settings > Security also lists
the paired devices, each with when it was paired and a Remove button (which asks first).

**Android TV (v1.4.1.2).** The companion installs on Android TV (Google TV, Sony BRAVIA and the
like), including 32-bit ones (flutter_pear 0.4.8+). It is driven by the remote: a bright ring
marks the focused control; up and down stay in the side panel or the page, scrolling the page to
its text before focus leaves it, and leave text fields rather than move their caret; the remote
walks down Events' alerts, surveillance and proximity clips one at a time; per-clip delete buttons
are hidden (Select still deletes) so the remote lands on the clips themselves; the Location and trip
maps are for looking at on a TV -- the remote passes over them to the map's buttons; on a page with
nothing to select below its title bar, such as a trip's summary, up and down scroll it; a slider
(Surveillance's sensitivity and AI confidence) changes with left and right, and up and down move past it.

**The companion app (v1.4.0.0, BladeWatch-rdtj.11).** The phone and desktop app that
replaced the web UI. It reaches the car directly on its Wi-Fi when both are on one network,
otherwise over Pear. Pear cannot connect a phone on mobile data to a car on its built-in SIM
directly, because both then sit behind randomizing carrier NATs, which hole punching cannot cross.
Put the phone on Wi-Fi in that case, or run your own relay (v1.4.1.3, BladeWatch-a7mu): a server you set up from [`relay/README.md`](../relay/README.md), turned on with
the same 12-digit key under Settings > **Relay access** in the car and in each companion. Nobody
without the key can use it. Details: "Known limitation: hard NATs" and "Owner-run relay" in
`docs/networking-and-tunnels.md`.
It has every page the web app had (the web app itself is gone):

- Dashboard.
- Live view.
- Events, meaning the store-and-forward alerts plus the surveillance and proximity clips.
- Recordings, with playback and delete.
- Vehicle: status, climate and windows.
- Location, on a map.
- Trips: what the in-car Trips page shows (2026-10-04): 7/14/30-day periods, the period summary (trips, hours,
  kWh, distance, efficiency, kWh/100km) with its fuel, electric and total cost, each trip with its cost, then the
  driver score out of 500, personalized range with BYD's own figures, the period's cost and driving DNA as bars;
  a trip's detail adds energy used, speeds in the owner's unit and banded score bars. Money is written as the car
  writes it (`₱49.96`). The trip settings (Trips' Storage tab, and Settings > Trips & costs > Trip Analytics) put
  the currency first, then the electricity rate (₱/kWh), fuel price (₱/L) and tank size.
- Surveillance: arm and disarm, detection settings and safe zones. (Its camera snapshots were
  removed in v1.4.1.2: Live shows the cameras.)
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
- **Live view is refreshed stills for now.** It shows the four-camera mosaic, updated 10 times a
  second (BladeWatch-hmk0; a JPEG still, not H.264 video), and works on every platform without a
  video decoder. Smooth H.264, and with it the per-camera views, is a follow-up. A dropped
  connection only skips stills: the last one stays on screen with its time, and the next arrives
  once the route is back.
- **A dropped connection does not end a clip or a download** (BladeWatch-tayl). A clip that
  was playing reconnects and carries on from where it was; a download that drops resumes from
  the byte it reached, with a Range request, instead of starting over. While the companion has
  no route to the car, both wait for it to come back (up to 10 minutes) rather than spending
  retries: from mobile data a reconnect measured 5 s to 90+ s. Only failures while the route is
  up count against the five tries.
- **Short Pear drops are invisible** (BladeWatch-bbvx). When the Pear connection drops and the
  companion finds the car again within a minute, every request, clip and download that was in
  flight carries on over the new connection from the byte it reached, with no error and no
  retry: the car and the companion resume each stream underneath the encrypted session. Longer
  gaps, or switching to the car's Wi-Fi, fall back to the retries above.
- **Clips start playing while they download** (BladeWatch-rdtj.31). Over Pear on the car's LAN
  the first moving frame arrives in about 2 s; it used to wait for the whole file (30-50 s). The
  car serves every clip with its index first and cut into small chunks, without changing the
  file. From mobile data the link is often slower than the clip (4-6 Mbit/s against 6), so the
  player first builds a buffer: measured 4 to 23 s, or longer on a weaker signal. After 5 s
  without moving, the player says the connection is slower than the clip and offers Download.
- **A clip too sharp for the phone plays anyway** (BladeWatch-rdtj.73). The car's own mosaic
  (2560x1920) is above what some Android phones' hardware decoders support -- one tested device
  capped at 1920px on either dimension and failed outright rather than playing slowly. On
  Android, the companion asks the OS what its decoder can handle and tells the car; a clip that
  doesn't fit is transcoded down to 1920x1080 on the car before being served, cached so later
  plays of the same clip are instant. A clip already within the phone's own decode ceiling is
  served untouched, and every other platform (iOS, macOS, Windows, Linux), which already plays
  the native file fine, is unaffected. Downloading a clip always saves the original, full-quality
  file, regardless of what played on screen. Live view is unaffected -- it has no video codec in
  its path to begin with (refreshed stills, see above).
- **Window control asks first, every time.** From a phone, nobody can see whether a hand or
  a pet is in a window. Climate changes are reversible and don't ask. Every command
  carries the car's short-lived action token, and the car's own safety interlock still
  decides.
- **The app is in 17 languages** (the catalogs the web app used, now kept in `companion/assets/i18n`).
- **Platforms.** It runs on Android, iOS, macOS, Windows and Linux. Clips play in the app on
  Android, iOS and macOS; elsewhere they download. The QR scanner uses the camera on Android,
  iOS and macOS; elsewhere, paste the code's text.

**Remote access status (v1.4.0.0).** Settings -> Services lists "Remote access (Pear)" with
its switch, and, while it runs, whether the car can be reached from anywhere right now
(which a running process alone does not mean), how many paired devices are connected, and
when one last connected. The dashboard's Remote access tile shows the same while Pear is on:
Online, Offline, Starting, or Running when reachability cannot be determined.

LAN access is disabled by default. Both remote paths reach the authenticated local web server on `REMOTE` listener trust with no intermediate proxy, so the JWT layer stays mandatory for every request.

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

The companion app's Diagnostics has a **Speed test** section (BladeWatch-j6ra): a button that measures the link between the phone or desktop and the car and reports the delay (median of four empty requests on a warm connection) and the download speed from the car (about eight seconds of back-to-back 16 MiB downloads), labelled with the path it measured, direct on Wi-Fi or over the internet (Pear). It tests whichever path the companion is using right then, never both. While it runs the session does not report the car as silent (`CarSession.duringBulkTransfer`): the test fills the link, so the watchdog's own question would time out behind it and the page, with the result, would be replaced by "Your car isn't answering" (BladeWatch-a7ev). It is only ever started by the owner, because it moves tens of MB, which is mobile data off the car's Wi-Fi. There is no upload test, and the in-car UI has no speed test: the car only serves the payload (`GET /speedtest/down`, see `http-api-reference.md`). Runner: `companion/lib/car/speed_test.dart`.

The Network tile also shows BladeWatch's own monthly network usage (BladeWatch-t1lg.1) — own-UID
`TrafficStats` totals, not whole-device usage, since a metered head-unit SIM makes "what does
BladeWatch itself cost me" a real question. It survives daemon restarts and device reboots (a
reboot resets the underlying counter; that reset is detected and credited forward rather than
subtracted, so the running month total never goes backward or silently loses data) — see
[networking-and-tunnels.md](networking-and-tunnels.md) for the accounting details.

## ConnectRPC API

The daemon exposes a typed ConnectRPC API (also reachable over Connect/JSON HTTP) defined by the `bladewatch.v1` proto contracts in `proto/`. It comprises 12 services — Auth, Notifications, Recordings, SafeLocations, Settings, Storage, Stream, Surveillance, System, Trips, Update, and Vehicle — consumed by the Flutter in-car UI and the companion (Dart stubs under `packages/bladewatch_rpc/lib/gen/`) and the daemon host (Kotlin stubs).

## Source References

- Recording and camera control: [CameraDaemon.java:677](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L677), [GpuSurveillancePipeline.java:1194](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java#L1194), [GpuMosaicRecorder.java:614](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuMosaicRecorder.java#L614), [RecordingsApiHandler.java:41](../app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java#L41).
- ACC-on recording modes: [RecordingModeManager.java:31](../app/src/main/java/com/loabletech/bladewatch/recording/RecordingModeManager.java#L31), [RecordingModeManager.java:533](../app/src/main/java/com/loabletech/bladewatch/recording/RecordingModeManager.java#L533), [ProximityRecordingHandler.java:49](../app/src/main/java/com/loabletech/bladewatch/proximity/ProximityRecordingHandler.java#L49).
- Surveillance and AI: [SurveillanceEngineGpu.java:22](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.java#L22), [MotionPipelineV2.java:14](../app/src/main/java/com/loabletech/bladewatch/surveillance/MotionPipelineV2.java#L14), [YoloDetector.kt:43](../app/src/main/java/com/loabletech/bladewatch/ai/YoloDetector.kt#L43), [SurveillanceConfig.java:9](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceConfig.java#L9).
- Live streaming: [GpuSurveillancePipeline.java:30](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java#L30), [WebSocketStreamServer.java:19](../app/src/main/java/com/loabletech/bladewatch/streaming/WebSocketStreamServer.java#L19), [HttpServer.java:538](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L538).
- BYD telemetry and vehicle control: [BydDataCollector.java:20](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L20), [VehicleControlApiHandler.java:43](../app/src/main/java/com/loabletech/bladewatch/server/VehicleControlApiHandler.java#L43), [VehicleCommandRouter.java:37](../app/src/main/java/com/loabletech/bladewatch/byd/routing/VehicleCommandRouter.java#L37), [flutter_ui/lib/screens/vehicle/](../flutter_ui/lib/screens/vehicle/).
- Proximity radar recording: [ProximityRadarMonitor.java:16](../app/src/main/java/com/loabletech/bladewatch/proximity/ProximityRadarMonitor.java#L16), [RadarConstants.java:27](../app/src/main/java/com/loabletech/bladewatch/byd/radar/RadarConstants.java#L27), [ProximityRecordingHandler.java:49](../app/src/main/java/com/loabletech/bladewatch/proximity/ProximityRecordingHandler.java#L49).
- Location and GPS: [flutter_ui/lib/screens/location/](../flutter_ui/lib/screens/location/), [vehicle.proto:51](../proto/bladewatch/v1/vehicle.proto#L51).
- Trips, notifications, updates, and diagnostics: [TripAnalyticsManager.java:23](../app/src/main/java/com/loabletech/bladewatch/trips/TripAnalyticsManager.java#L23), [TripApiHandler.java:35](../app/src/main/java/com/loabletech/bladewatch/trips/TripApiHandler.java#L35), [NotificationApiHandler.java:30](../app/src/main/java/com/loabletech/bladewatch/server/NotificationApiHandler.java#L30), [PerformanceApiHandler.java:30](../app/src/main/java/com/loabletech/bladewatch/server/PerformanceApiHandler.java#L30), [adb_console_screen.dart](../flutter_ui/lib/screens/diagnostics/adb_console_screen.dart).
- Remote access: [PearLauncher.kt](../app/src/main/java/com/loabletech/bladewatch/launcher/PearLauncher.kt), [PearDaemon.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/PearDaemon.kt), [companion/lib/car/](../companion/lib/car/).
