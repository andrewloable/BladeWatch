# BYD Integrations

BladeWatch integrates with BYD vehicles through local BYD Android framework APIs available on the head unit. There is no BYD cloud integration path in this codebase; all vehicle data and controls use the local SDK only. (A previous generation used BYD cloud over HTTPS + MQTT v5 with Bangcle white-box crypto; that code has been removed. Commands that only had a cloud implementation now resolve to `NOT_SUPPORTED` — see Vehicle Control below.)

## Android Manifest Permissions

The manifest declares a broad set of BYD and Android permissions. Major categories include:

- Camera, microphone, storage, internet, wake lock, notifications, boot, network, Wi-Fi, location, and overlay permissions.
- BYD AC permissions.
- BYD bodywork permissions.
- BYD instrument permissions.
- BYD engine permissions.
- BYD charging permissions.
- BYD BMS permissions.
- BYD statistic permissions.
- BYD speed permissions.
- BYD gearbox permissions.
- BYD lights permissions.
- BYD energy permissions.
- BYD tyre permissions.
- BYD radar permissions.
- BYD setting permissions.
- BYD door lock permissions.
- BYD safety belt permissions.
- BYD seat permissions.
- BYD sensor permissions.
- BYD PM2.5 permissions.
- BYD multimedia and audio permissions.
- BYD panorama and camera permissions.
- BYD OTA and power permissions.
- BYD ADAS, wiper, mirror, SRS, and security permissions.
- BYDACQUISITION and BYDDIAGNOSTIC permissions.

Many of these permissions are only meaningful on BYD firmware.

## Compile-Time Stubs

The source tree contains `android.hardware.bydauto.*` stubs so the app can compile outside a BYD head-unit environment.

Runtime behavior depends on real BYD framework classes loaded by the Android boot classloader. The stubs are compile-time placeholders and should not be treated as the source of runtime behavior.

## Reflection Helper

`BydDeviceHelper` centralizes local BYD reflection behavior.

Capabilities:

- Load device classes with `Class.forName`.
- Call `getInstance(Context)` factory methods.
- Invoke no-arg, integer, two-integer, and four-integer methods safely.
- Register listener proxies for `android.hardware.IBYDAutoListener`.
- Support typed listener subclasses for abstract listener classes.
- Log and isolate firmware-specific failures.

This pattern lets the app survive missing classes, changed methods, or firmware-specific behavior.

## Local Data Collector

`BydDataCollector` is the main local telemetry collector.

It initializes and reads from device areas including:

- Bodywork.
- Speed.
- Engine.
- Statistic.
- Energy.
- Tyre.
- Charging.
- Door lock.
- Instrument.
- OTA.
- Sensor.
- Gearbox.
- Safety belt.
- AC.
- Light.
- ADAS.
- Radar.
- Power.
- Setting.
- Multimedia.

The collector keeps a thread-safe `BydVehicleData` snapshot for other app systems.

### Drivetrain detection (BEV vs PHEV)

`BydDataCollector.computeIsPhev()`, exposed as `isPhevVehicle()`. `getEnergyType` is
unreliable — observed returning 1 on both BEV and PHEV firmware — so it is not used as
the discriminator. The verdict is cached with a 60s TTL and resolved in this order:

1. **Pack capacity.** A known nominal pack strictly below `PHEV_MAX_NOMINAL_KWH`
   (30 kWh) is a PHEV outright. The smallest BYD BEV is the Atto 3 at 49.9 kWh, so
   sub-30 kWh uniquely names a PHEV across the catalogue.
2. **Both fuel HAL signals real** (`getFuelPercentageValue` and
   `getFuelDrivingRangeValue`) → PHEV.
3. **Both at a BMS sentinel** (255/2046/etc) → BEV.
4. **One real, one sentinel** → PHEV with an empty tank or zero range, cached on a
   SHORT TTL so a transient HAL miss re-probes in seconds.

**Capacity is consulted FIRST and that ordering is the whole point.** The fuel HAL
returns BMS sentinels during firmware warm-up, so on a PHEV that has not finished
booting both signals read as sentinel, rule 3 concludes BEV, and that verdict is cached
for a full minute — during which fuel percent disappears and fuel-aware trip logic sees
nothing. Overdrive shipped exactly that regression in v17 and fixed it by promoting the
capacity gate. A known pack size is simply stronger evidence than a signal that is
allowed to lie while it warms up.

A fuel percent of `0` is deliberately NOT counted as a "real" reading: a BEV that
returns 0 instead of a sentinel would otherwise classify as a PHEV.

The 30 kWh threshold is **inherited from Overdrive and was not re-derived on this car**.
The same rule also appears in `VehicleDataMonitor.isPhevVehicle` as a startup fallback
for a different caller; if one moves, move both.

## Polling and Listeners

The collector combines initial reads, polling, and listeners.

Observed behavior:

- Faster polling while ACC is on.
- Slower polling while ACC is off.
- Per-device failures are isolated.
- Listener registration is used for bodywork, charging, engine, door lock, and tyre areas where supported.
- Gearbox listener registration is intentionally avoided because a known BYD API path can crash under shell UID on some firmware.

Mileage conversion considers the instrument mileage unit so miles can be normalized to kilometers.

## Door Lock Semantics

The code contains an important conversion note:

- BYD SDK door lock values use one convention.
- The web API historically used another convention.

Do not change door lock mapping without checking both local SDK behavior and web client expectations.

## Vehicle Control

`VehicleControlApiHandler` exposes vehicle-control HTTP endpoints. All controls go through `VehicleCommandRouter`, which dispatches to the local BYD SDK (`BydDataCollector`) only. The contract is defined by `VehicleService` in `proto/bladewatch/v1/vehicle.proto`; the REST handler is the HTTP mapping of those RPCs.

### Command surface

`VehicleService` RPCs and their `/api/vehicle/*` mappings:

- State reads: `GetState` (`GET /api/vehicle/state`), `GetAcDiagnostics`, `GetSeatDiagnostics`.
- Climate: `SetClimate` (`POST /api/vehicle/climate`) — power on/off, set temperature, fan level, wind mode, and max-cooling. Max-cooling carries restore parameters so prior AC power/temp/fan state can be re-applied when it is turned off.
- Windows: `MoveWindow` (`POST /api/vehicle/window`) — per-window open/close by direction, or closed-loop positioning to a target percent. Window index `0` means all side windows; `1`–`4` are the four doors; `5`/`6` are sunroof/sunshade.
- Seats: `SetSeat` (`POST /api/vehicle/seat`) — per-seat heating and ventilation levels, and seat-memory position recall. The request also carries the full current seat state (driver/passenger heat and vent) so the SDK call is applied against a consistent snapshot.
- Lights/appearance: `SetLights` (`POST /api/vehicle/lights`) — daytime running light (DRL) on/off.
- ADAS: `SetAdas` (`POST /api/vehicle/adas`) — speed-limit-warning on/off.
- Trunk/tailgate: `Trunk` (`POST /api/vehicle/trunk`) — open, close, or stop the tailgate motor. Trunk open invokes the local tailgate motor directly with no remote-unlock pre-step, so a locked vehicle may decline the motor or trip the alarm.
- Charge cap (BEV): `GetChargeCap`/`SetChargeCap` (`/api/vehicle/charge-cap`) — `BYDAutoChargingDevice` stop-capacity percent (50–100%) and on/off switch. The collector probes the framework on first write and reports failure if the value does not stick.

The bodywork range and battery SOC, door/window/trunk/sunroof status, light/ADAS state, seat heat/cool levels, climate setpoint, and tyre pressures are all returned by `GetState` for the UI to render.

### Commands removed with the BYD cloud

These were implemented only through the BYD cloud path deleted in `61b4d7f`. They had
no local SDK primitive, so they could answer nothing but `NOT_SUPPORTED`. In
`BladeWatch-c2h1` the dead implementations were **removed** — the command classes, the
REST routes and the Connect registrations:

- Lock and unlock (`Lock`, `Unlock`).
- Flash lights (`Flash`).
- Find car (`FindCar`).
- Battery heat (`SetBatteryHeat`).
- Charging schedule (`GetChargingSchedule`/`SetChargingSchedule`).
- Smart charging master switch.
- **Trunk OPEN** — see below; this one was not merely dead, it was dangerous.

The `.proto` still declares these RPCs, so the wire contract is unchanged for any
existing client, but the daemon no longer registers handlers for them. No first-party
client calls them: `web/` removed the Lock/Unlock/Flash controls by decision (see
`web/src/app/pages/vehicle/vehicle.component.ts`) and the Flutter in-car UI never had
them. `web/`'s remaining `lock` references are a **read-only lock status pill**, not a
command.

### Trunk open: removed, not merely unsupported

Trunk open was a two-leg command — BYD cloud unlock, then the SDK tailgate motor, with
`VehicleCommandRouter` firing the motor **only if the unlock leg returned SUCCESS**.
Deleting the cloud removed the unlock leg but left the motor call, so `openTailgate()`
was being invoked unconditionally. On a locked car the body controller may decline it
or **set off the alarm**, and nothing warned the driver.

It is now gone: no `TrunkOpenCommand`, no `executeTrunkOpen()`, no `open` action.
`BydDataCollector.openTailgate()` is deliberately KEPT — it is the BYD SDK surface a
future implementation with a real lock-state interlock will need — but
`NoUngatedTrunkOpenTest` pins that **nothing calls it**, so wiring it back up fails the
build. `BydDataCollector` already polls all five lock areas, so the interlock is
implementable when someone wants it.

Trunk **close** and **stop** are unaffected and still work: neither opens anything, and
both map to real local primitives.

### Close-all-windows needs the car awake

`area=0 + command=2` used to route through the cloud `CLOSEWINDOW` command, which worked
while the car was asleep. It now uses the local `setAllWindowsCommand(2)`, which needs
the head unit awake — so remote "close my windows, it is raining" no longer works. The
Flutter Windows tab states this inline (`vehicle_window_awake_note`).

`VehicleCommandRouter` only exposes `Outcome.{SUCCESS, FAILED, NOT_SUPPORTED, ...}` and `Path.{SDK, NONE}`. Every dispatch returns a structured `CommandResult` whose `outcome`/`path` are surfaced in the JSON response so the UI can render a "sent via direct connection" (local) badge. Cloud-first and cloud-only routing strategies are no longer present.

## GPS / Location

GPS is not read from the BYD SDK. A separate `LocationSidecarService` runs under the app UID, obtains fixes from Android location providers, and pushes updates to the daemon over the surveillance IPC channel (port 19877). `GpsMonitor` (daemon side) receives `updateFromIpc(...)`, caches the last fix to `/data/local/tmp/gps_cache.json`, and feeds `SafeLocationManager` for geofence checks. It rejects `(0,0)` fixes and loads the cached fix on startup for immediate availability.

`GpsApiHandler` exposes the location HTTP surface, mapped from the `VehicleService` GPS RPCs:

- `GetGpsLocation` (`GET /api/gps`) — returns the location JSON (`GpsMonitor.getLocationJson()`: lat/lng, speed, heading, accuracy, altitude, timestamp) plus a Google Maps URL.
- `StartGps` (`POST /api/gps/start`) — starts the sidecar service.
- `StopGps` (`POST /api/gps/stop`) — stops GPS tracking.

The web Location page polls `GetGpsLocation` every few seconds and renders a Leaflet map with a heading-rotated car marker; it is a presentation layer over the same cached fix, not a separate location source.

## 3D Vehicle Hero

The Vehicle Control page shows a rotating 3D model of the car. This is a **web/GPU rendering of the vehicle, not a native BYD SDK feature** — it does not read or control the car. The shipped renderer is **Three.js r147** (with Draco-compressed GLB models under `web/shared/models/`, e.g. Seal, Seal U, Dolphin, Atto 3, Han, Tang, M6, Seagull, Destroyer), served from `web/hero/hero.html`.

It is rendered in a small embedded WebView (`VehicleHeroView`) inside the native vehicle fragment, with `TyreOverlay` floating tyre-pressure and control cards over the full-bleed car background. The native side drives it through an `AndroidHero`/`Hero` JS bridge (`loadModel`, `setColor`, `setRunning`); the selected model and body paint color are user-chosen vehicle-appearance settings, not live telemetry.

History note: an earlier change integrated a native **Filament** 3D engine for the hero, but the head unit's Adreno 610 GL driver crashes under sustained `gltfio` rendering, so the hero was reverted to the proven Three.js WebView stack. The public surface was kept identical to the Filament version. Do not describe the current hero as native Filament.

## Lock Detection for Surveillance

`CameraDaemon` waits for the vehicle to be locked before arming surveillance after ACC turns off. Lock state is determined using the local BYD device SDK door-lock listener and periodic local door-lock polling only. A force-arm timeout fires after roughly 60 seconds if no lock event arrives.

## Safety and Maintenance Notes

- Local BYD APIs are firmware-dependent and must be treated as unstable.
- Reflection calls should keep per-device isolation.
- Avoid listener registration on known-crashing BYD APIs.
- Do not log credentials or BYD-derived secrets.
- Keep local SDK stubs compile-only.

## Source References

- BYD manifest permissions: [AndroidManifest.xml:35](../app/src/main/AndroidManifest.xml#L35), [AndroidManifest.xml:120](../app/src/main/AndroidManifest.xml#L120), [AndroidManifest.xml:193](../app/src/main/AndroidManifest.xml#L193).
- BYD SDK stub strategy and dependencies: [build.gradle.kts:413](../app/build.gradle.kts#L413), [build.gradle.kts:476](../app/build.gradle.kts#L476), [IAccModeManager.java:5](../app/src/main/java/android/os/IAccModeManager.java#L5).
- Local telemetry collector and reflection-based device access: [BydDataCollector.java:20](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L20), [BydDataCollector.java:247](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L247), [BydDataCollector.java:3907](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L3907).
- ACC, gear, and event plumbing: [BydFeatureIds.java](../app/src/main/java/com/loabletech/bladewatch/byd/BydFeatureIds.java) (replaced `BydConstants.java`, removed in `8e98aaf`), [GearMonitor.java:132](../app/src/main/java/com/loabletech/bladewatch/monitor/GearMonitor.java#L132), [CameraDaemon.java:1905](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L1905), [CameraDaemon.java:2206](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L2206).
- Door lock and surveillance gating: [CameraDaemon.java:1764](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L1764), [CameraDaemon.java:1439](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L1439), [AccSentryDaemon.java:1900](../app/src/main/java/com/loabletech/bladewatch/daemon/AccSentryDaemon.java#L1900).
- Vehicle control contract and routing: [vehicle.proto:32](../proto/bladewatch/v1/vehicle.proto#L32), [VehicleControlApiHandler.java:43](../app/src/main/java/com/loabletech/bladewatch/server/VehicleControlApiHandler.java#L43), [VehicleCommandRouter.java:17](../app/src/main/java/com/loabletech/bladewatch/byd/routing/VehicleCommandRouter.java#L17), [VehicleCommandRouter.java:315](../app/src/main/java/com/loabletech/bladewatch/byd/routing/VehicleCommandRouter.java#L315).
- Local SDK control primitives: [BydDataCollector.java:3839](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L3839), [BydDataCollector.java:4803](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L4803), [BydDataCollector.java:5064](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L5064).
- GPS / location: [vehicle.proto:51](../proto/bladewatch/v1/vehicle.proto#L51), [GpsApiHandler.java:18](../app/src/main/java/com/loabletech/bladewatch/server/GpsApiHandler.java#L18), [GpsApiHandler.java:24](../app/src/main/java/com/loabletech/bladewatch/server/GpsApiHandler.java#L24), [GpsMonitor.java:23](../app/src/main/java/com/loabletech/bladewatch/monitor/GpsMonitor.java#L23), [GpsMonitor.java:84](../app/src/main/java/com/loabletech/bladewatch/monitor/GpsMonitor.java#L84), [GpsMonitor.java:253](../app/src/main/java/com/loabletech/bladewatch/monitor/GpsMonitor.java#L253).
- 3D vehicle hero (Three.js in a WebView — **not** Filament, see the Adreno 610 note in [build-and-operations.md](build-and-operations.md)): [hero.html:15](../app/src/main/assets/web/hero/hero.html#L15), [hero.html:20](../app/src/main/assets/web/hero/hero.html#L20), [flutter_ui/lib/screens/vehicle/vehicle_hero.dart](../flutter_ui/lib/screens/vehicle/vehicle_hero.dart).
