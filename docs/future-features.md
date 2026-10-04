# Future Features

A comparison of BladeWatch against three comparable products, listing the features BladeWatch
lacks and whether each is practical to build. Compiled 2026-10-05 from this repository's source
and the competitors' public material.

Compared against:

- **Overdrive** — the app BladeWatch was forked from (site and README as of v52.1).
- **Tesla Sentry Mode** — including the Tesla app and Dashcam Viewer (as of software 2026.20).
- **BYD "Electro"-type apps** — Electro (electro.app.br, a paid Brazilian subscription app) and
  sentry·ev, the same kind of product.

This is an evaluation, not a task list. Nothing here is committed work: pick rows, then file
`bd` issues against that decision (see `AGENTS.md`).

**Effort key:** **S** = a contained change inside existing code. **M** = a new component in one
layer. **L** = a new subsystem, or work across the daemon, the proto contract and both apps.

## Earlier evaluations and settled decisions

Overdrive and Electro were evaluated in September 2026 (epics `BladeWatch-0kgu` and
`BladeWatch-ntum`). Those epics wrote their findings to `docs/evaluations/`, but the files were
never committed and no longer exist. Only the issues' close reasons survive in
`.beads/issues.jsonl`. Four docs still link to the missing directory:
[byd-integrations.md](byd-integrations.md), [daemons-and-processes.md](daemons-and-processes.md),
[detection-invariants.md](detection-invariants.md) and
[networking-and-tunnels.md](networking-and-tunnels.md). Tesla had never been compared before
this document.

Four product decisions came out of that work (epic `BladeWatch-tren`). They are settled. Do not
re-propose anything they rule out:

| Decision | Answer |
|---|---|
| `tren.1` — a user-facing automation engine? | **No.** All-or-nothing scope (~20,000 lines). A partial rules engine is worse than none. |
| `tren.2` — an AI assistant? | **No.** It would send vehicle context to a third party on every request. |
| `tren.3` — stay server-free? | **Yes, permanently.** The project will never run a backend. See [architecture.md](architecture.md). |
| `tren.4` — BEV-only? | **No, PHEVs are supported.** PHEV battery-health (SoH), SAVE mode, HEV range and PHEV charging power are legitimate future work. |

## Defects found during this comparison

- **The horn/flash deterrent option does nothing.** The Surveillance screen offers
  `silent / horn / flash`
  ([surveillance_models.dart:15](../flutter_ui/lib/screens/surveillance/surveillance_models.dart#L15)).
  The daemon stores the choice
  ([UnifiedConfigManager.kt:255](../app/src/main/java/com/loabletech/bladewatch/config/UnifiedConfigManager.kt#L255),
  [SurveillanceApiHandler.kt:468](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceApiHandler.kt#L468))
  but nothing reads it to act. `deterrentFiredTime` in
  [SurveillanceEngineGpu.kt](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.kt#L220)
  is only ever reset to 0, so the deterrent-suppression logic built around it never runs either.
  In Overdrive this was a BYD Cloud feature, and BladeWatch's cloud package was deleted in
  `61b4d7f`. Practical row 2 below covers the fix.
- **A screen deterrent is not possible on this head unit.** Tested on the car in `BladeWatch-gyg1.5`:
  with ACC off, the panel stays dark although every software layer (`BacklightController`,
  `PowerManagerService`) reports success. That rules out every idea that relies on showing
  something on the screen of a parked car: Tesla's alert screen, Dog Mode's message, and
  Overdrive's screen deterrent.

## Already at parity

These exist in BladeWatch today. They are listed so nobody re-proposes them.

- **Sentry:** AI detection of person, car, bike and animal
  ([YoloDetector.kt](../app/src/main/java/com/loabletech/bladewatch/ai/YoloDetector.kt)).
  Notice / Alert / Critical severity tiers (separate notification categories). Pre- and
  post-event buffers. Safe locations, equivalent to Tesla's "Exclude Home / Work / Favorites".
  Time-window schedule. Remote arm and disarm from the companion. Region-of-interest masks.
- **Recording:** H.264 and H.265, SRT subtitle sidecars
  ([SrtWriter.kt](../app/src/main/java/com/loabletech/bladewatch/surveillance/SrtWriter.kt)),
  hero thumbnails, a bookmark button, the Performance / Reliability priority, a 1 / 5 / 10 minute
  segment limit, the telemetry overlay with a per-type field checklist, and storage-limit
  deletion warnings.
- **Proximity recording from the 8 parking-radar sensors.** Overdrive also has it. Tesla and
  Electro do not.
- **Remote access:** the companion over Pear or the LAN, still-frame live view, resumable clip
  playback and download, store-and-forward alerts, and the app's own monthly mobile-data
  accounting.
- **Vehicle:** climate (power, max cooling, temperature, fan, defrost), windows and sunroof by
  percentage, media volume and mute, screen on/off with a driving interlock, charge cap, and
  read-only TPMS, lock state and GPS.
- **Trips:** detection, GPS traces, driving score and Driving DNA, personalized range, PHEV fuel
  leg, period costs.
- **17 languages**, in both the in-car app and the companion.

## Practical to build

| # | Feature | Who has it | Effort | What exists today / what is needed |
|---|---|---|---|---|
| 1 | **Turn sentry off automatically on low battery**, at a traction-battery % and/or 12V voltage threshold, and notify the owner when it happens | Tesla (turns off at 20%), Overdrive (`SocCutoffMonitor`, `BatteryVoltageMonitorV2`) | S | No cutoff exists anywhere: no SoC or voltage threshold, no maximum arm duration. Both inputs are already collected: SoC, and `voltage12v` / `voltageLevelRaw` in [BydVehicleData.kt](../app/src/main/java/com/loabletech/bladewatch/byd/BydVehicleData.kt#L24). The app already tells the owner that sentry draws 12V power (`gyg1.2`) but does nothing to stop it. This is the row that protects the car. |
| 2 | **Fix the dead horn/flash option**: hide it, or show it as unavailable | — | S | See Defects above. If row "Horn or light flash through the car's own SDK" under device checks succeeds, wire the option up instead. |
| 3 | **"Left open / unlocked" alert**: once, a few minutes after ACC off, if any door, window or the boot is open, or the car is unlocked | Tesla | S | `doorLockStatus` and `windowOpenPercent` are already read ([BydVehicleData.kt:91](../app/src/main/java/com/loabletech/bladewatch/byd/BydVehicleData.kt#L91)). Needs a new category in [notifications-categories.json](../app/src/main/assets/notifications-categories.json). Today's door categories fire on every open and close, and are off by default. |
| 4 | **"Charged to X%" alert**, and a "charging now, time to full" card | sentry·ev, Tesla app, Overdrive | S | `ChargingDetector` already publishes session state. `vehicle.charging.full` exists, but there is no owner-chosen target. Because alerts are store-and-forward, its value depends on the instant-alerts decision below. |
| 5 | **More overlay fields**: battery %, 12V voltage, headlight beams, and an on/off for GPS | Overdrive v52.1 | S | Extend `OverlayField` in [OverlayFieldSelection.kt](../app/src/main/java/com/loabletech/bladewatch/telemetry/OverlayFieldSelection.kt). GPS coordinates are burned into every clip unconditionally whenever there is a fix (see [features.md](features.md), Performance and Telemetry). Making that optional is a privacy improvement as well as a feature. |
| 6 | **Thumbnail on companion alerts** | Tesla (60-second preview in the app), Overdrive (thumbnails in Telegram alerts) | S–M | Hero JPEGs are already written per event (`ThumbnailBuffer`, `EventTimelineCollector`). [notifications.proto](../proto/bladewatch/v1/notifications.proto) inbox items carry no image or thumbnail reference. |
| 7 | **Arm on lock, disarm on unlock** | Tesla, Overdrive | S–M | Sentry is driven by ACC state today ([AccSentryDaemon.kt](../app/src/main/java/com/loabletech/bladewatch/daemon/AccSentryDaemon.kt)). Nothing in the sentry daemons reads lock state. Lock state is readable, but first confirm on the car that lock changes are still reported with ACC off. |
| 8 | **Steering-wheel button bookmarks the current clip** | Tesla (honking saves a dashcam clip) | S–M | One fixed binding, not the automation engine `tren.1` rejected. The shipped accessibility service cannot receive keys: [accessibility_service_config.xml](../app/src/main/res/xml/accessibility_service_config.xml) sets `accessibilityEventTypes=""` and does not request key filtering. The `ntum.5` close reason records that Overdrive needed event types declared before `onKeyEvent` was dispatched on a real DiLink unit. |
| 9 | **In-car PIN lock**, so a passenger or valet cannot disarm sentry or delete clips | Overdrive | S | Flutter-only. The daemons keep recording behind the lock. |
| 10 | **Back up and restore settings and trips to a file** | Overdrive | M | No export or import RPC exists. A file on USB, or one downloaded through the companion, needs no server. It protects against a head-unit reset or a reinstall. Never include `bladewatch_secrets.json` or the ADB key in it. |
| 11 | **Charging history**: a list of past sessions (start, end, SoC change, estimated kWh, place), without tariffs | Overdrive, Electro, sentry·ev | M | `GetLastCharge` returns only the most recent session (`SocHistoryDatabase.getMostRecentCompletedChargingSession()`). Overdrive's full charging package with tariffs is ~6,700 lines and needs a calibrated energy counter (`0kgu.8`). Keep tariffs out of the first version. |
| 12 | **Lower frame rate while parked and idle**, ramping up on motion | Overdrive v34 ("low-power parked mode") | M | The surveillance pipeline has no ACC-aware or idle scaling. `AdaptiveBitrateController` varies bitrate, not frame rate (`0kgu.5`, `0kgu.7`). It pairs with row 1 against battery drain. Read [detection-invariants.md](detection-invariants.md) before changing anything here, because detection thresholds assume the current frame rate. |
| 13 | **Real H.264 live video in the companion** | Tesla, Electro, sentry·ev (WebRTC) | M–L | Already a known follow-up: the companion shows a JPEG refreshed 10 times a second (`BladeWatch-hmk0`). Pear throughput measurements are in [networking-and-tunnels.md](networking-and-tunnels.md). |
| 14 | **Encrypt recordings on the card or USB drive**, opt-in | Tesla 2026.20 | M–L | Stops someone who takes the card from just watching it on a PC. The cost: every player (in-car and companion) has to decrypt, the key lives in `SecretConfigStore`, and the owner loses "pull the card and watch it anywhere". It must stay opt-in for that reason. |
| 15 | **MQTT / Home Assistant** (read-only first), and **ABRP export** | Overdrive, Electro | M–L | Allowed under `tren.3` because the owner chooses where the data goes. Broker credentials belong in `SecretConfigStore`. ABRP sends exact position, heading, speed, odometer and SoC continuously while driving, so it must be opt-in and say so where it is switched on. Overdrive's MQTT source is ~140 KB, which gives a sense of the size. |

## Needs a check on the car before deciding

Each of these depends on something the head unit may not allow. Run the cheapest read-only probe
first, and decide only after it.

- **Horn or light flash through the car's own SDK, with ACC off.** This is the only way Tesla's
  alarm response or Overdrive's flash deterrent could come back. Lock, Unlock and Flash had no
  local path on v3 (see [byd-integrations.md](byd-integrations.md)), but `SetLights` exists in
  [vehicle.proto](../proto/bladewatch/v1/vehicle.proto#L42). Any actuation must be parked-only.
- **Dog / Camp Mode: keep the climate running while parked.** It is unknown whether the A/C runs
  with ACC off on DiLink v3. The "your pet is fine" screen message cannot be shown (see Defects).
- **Cabin audio recording.** `RECORD_AUDIO` is declared, but nothing records audio. Electro's own
  UI says the microphone is unavailable with ACC off, so at best this would be while driving.
- **Side camera on the turn signal, fisheye-corrected live view, per-camera zoom.** Overdrive,
  sentry·ev and Tesla have these. Many BYD models already do the turn-signal view natively, so
  check for duplication first. `FisheyeDewarp.kt` exists, but only on the AI path.
- **Integration with the car's own dashcam (`com.byd.cdr`).** Both competitors integrate with it.
  BladeWatch only hands the camera over to it (`BydCameraCoordinator`, `AvcHalWarmup`).
- **PHEV battery-hold (SAVE) mode, a battery-health (SoH) estimate, AC charging current.**
  Unblocked by `tren.4`. The earlier SoH feature was removed as a stub (`BladeWatch-p7vi`,
  `BladeWatch-uuo6`); Overdrive estimates SoH from long-run voltage and cell-temperature history.

## Decision needed: instant alerts

This is the biggest user-facing gap against all three products. Tesla, Overdrive (Telegram and
Web Push) and Electro all push alerts the moment they happen. BladeWatch's companion receives them
only the next time it connects (`BladeWatch-rdtj.14`).

`tren.3` rules out a relay run by the project. A relay the owner sets up and points the car at,
such as their own Telegram bot or a self-hosted ntfy server, fits that decision's wording ("nothing
leaves the car unless the owner points it somewhere"). However, BladeWatch deliberately removed
its Telegram path earlier, so this is a product decision for the developer, not a feature to
build straight away. It only helps while the car itself is online.

## Not practical — do not re-propose

| Reason | Features |
|---|---|
| Already decided no (`tren.1`, `tren.2`) | Automation engine, community automations, key mapping as a general system, AI assistant |
| Server-free (`tren.3`) | Push while the car is offline, multi-user access to one car, accounts, uploading diagnostic logs to a server, sharing road hazards between cars, distributing the car APK from a server |
| Needs BYD Cloud, which was deleted (`61b4d7f`) | Remote lock/unlock, cloud horn/flash, charging schedule, remote wake |
| Hardware the car or head unit lacks | DiLink 4/5 support, Tesla's B-pillar and cabin cameras, Boombox / external speaker |
| Unsafe | Projecting to the instrument cluster (it blanks the driver's gauges for the duration). Two-way talk and listen-in (no motion interlock on the audio path, and the microphone is unavailable with ACC off). Switching off driver-assist safety systems such as emergency braking or lane keeping |
| A separate product | Pothole and speed-bump detection (Overdrive's RoadSense), turn-by-turn navigation |
| Cannot be enforced from the head unit | Tesla's Valet mode and PIN-to-drive: the app cannot stop the car being driven |

## Suggested order

1. Rows 1 and 2. Both are small; one protects the car's battery and the other removes a misleading setting.
2. The instant-alerts decision. It changes the value of rows 4 and 6.
3. Rows 3, 4 and 6: small alert improvements.
4. Row 10: backup and restore.
5. Repoint the four dangling `docs/evaluations/` links at this document.

## Sources

The Electro site renders its content with JavaScript, and the Whirlpool forum thread returned
HTTP 403, so the Electro details here come from press coverage plus the `ntum.1` catalogue (built
from Electro's Sept 2026 web bundle).

- [Overdrive site](https://overdrive-5lc.pages.dev/)
- [Overdrive-release README](https://github.com/HTTPS1121/Overdrive-release)
- [Electro app](https://electro.app.br/)
- [Electro coverage (A Crítica)](https://acritica.net/tecnologia/app-brasileiro-electro-byd-tesla-privacidade/)
- [Whirlpool Electro thread](https://forums.whirlpool.net.au/archive/31mmxlpv)
- [sentry·ev](https://sentryev.com/en)
- [Not a Tesla App: Sentry Mode](https://www.notateslaapp.com/tesla-reference/1303/tesla-sentry-mode-what-it-is-how-to-use-it-and-battery-drain)
- [SentryPro: Tesla 2025 Sentry updates](https://sentrypro.app/blog/tesla-sentry-mode-2025-updates/)
- [Brian Kehm: Tesla Sentry guide](https://briankehm.com/tesla-sentry-mode/)
- [Tesla Model Y manual: Sentry Mode](https://www.tesla.com/ownersmanual/modely/en_us/GUID-56703182-8191-4DAE-AF07-2FDC0EB64663.html)
