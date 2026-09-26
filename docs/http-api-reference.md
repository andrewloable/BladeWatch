# HTTP API Reference

The embedded HTTP server is implemented by `HttpServer` and route-specific handlers under `net.bladewatch.app.server` (filesystem path `app/src/main/java/com/loabletech/bladewatch/server/`). This file lists the route families and endpoints discovered in the codebase. Request and response schemas should be read from the corresponding handler classes or the proto schemas in `proto/bladewatch/v1/` before changing clients.

Base URL by default:

```text
http://127.0.0.1:8080
```

## Listeners and what each one trusts

The same routes are served on up to three listeners. The routes are identical on each; the
difference is the auth posture. That posture comes from the listener a request arrived on,
never from its source address. The Pear pump delivers remote traffic from 127.0.0.1
(as tor did before v1.4.0.0), so a loopback address proves nothing (`ListenerTrust`, BladeWatch-rdtj.4).

| Listener | Who connects | Trust | Notes |
|---|---|---|---|
| `127.0.0.1:8080`, plain HTTP | the in-car UI and the service host | `LOCAL_APPS`, only when the peer UID is BladeWatch's own (or shell, system, root); otherwise `REMOTE` | The only listener that can get the debug-build loopback bypass or skip the vehicle-action second factor. Another app on the head unit is served like a remote caller (BladeWatch-g5u7). |
| `127.0.0.1:8444`, TLS | `PearStreamPump`, carrying a companion's Pear stream | `REMOTE` | Serves the LAN listener's certificate. The companion runs TLS end to end over the Pear stream and pins that certificate, so pear_daemon never sees plaintext. |
| `0.0.0.0:8443`, TLS | a companion or browser on the car's network | `REMOTE` | Only when the owner opts in (`network.lanHttpEnabled`, off by default). Self-signed certificate, pinned by fingerprint from the pairing QR. |

`REMOTE` means every protected route needs a JWT, and every vehicle action also needs an
`X-Vehicle-Action-Token` from `VehicleService/IssueActionToken`. Plain HTTP never binds beyond loopback. `SystemService/GetStatus` reports
`network.lanHttpEnabled` and `network.httpBind` (always `127.0.0.1`). The LAN listener's port
and fingerprint reach the in-car UI over IPC (`lanTlsInfo`), not through status.

The server exposes two parallel API surfaces over the same port:

1. **HTTP, for things a browser must fetch directly.** There is **no REST JSON API any more**
   (BladeWatch-6mnq). What the server still serves over plain HTTP is not an API:

   | Route | Why it cannot be an RPC |
   |---|---|
   | `/`, `angular/*`, `/assets/*` | the SPA bundle itself |
   | `/login`, `/login.html` | pre-auth page; no Connect client exists yet when it loads |
   | `/auth/status`, `/auth/token`, `/auth/logout` | the login bootstrap those pages call |
   | `/manifest.json`, `/sw.js`, `/favicon.ico`, `/credits.json` | static assets |
   | `/i18n/*`, `/shared/*` | catalogs and legacy assets |
   | `/video/*` | player byte-range requests (Range, 206, ETag) |
   | `/thumb/*` | `<img src>`, additionally auth'd by a signed `?t=` token |
   | `/api/stream/still` | a JPEG the live view consumes as an image URL |
   | `/hero/*` | the three.js vehicle page |

   Everything else — every JSON endpoint that used to live under `/api/*`, and `/status` — is a
   ConnectRPC method. `AuthApiHandler` is the one handler that still has an HTTP entry point
   for JSON, because the login bootstrap needs it; `RecordingsApiHandler` and
   `StreamingApiHandler` keep one for their binary routes only.

2. **Connect/gRPC** — ConnectRPC unary calls under the `/bladewatch.v1.*` route prefix, consumed by both the Flutter in-car UI (Dart client, `packages/bladewatch_rpc/lib/rpc/`, shared with the companion app) and the Angular SPA. See [Connect / gRPC Layer](#connect--grpc-layer). The Connect handlers wrap the same REST handlers to keep the two surfaces in 1:1 parity, so the REST families below are the source of truth for behaviour.

## Auth

Handled by `AuthApiHandler` (all `/auth/*` paths are routed before the auth
middleware runs, so they are reachable without a session):

- `GET /auth/status` — returns the device id hint for the login page. Public.
- `POST /auth/token` — body `{token}`; validates the device token and, on
  success, issues a JWT and sets the `byd_session` (HttpOnly) + `byd_auth=1`
  (hint) cookies. Rate-limited to 10 attempts/min per client identity,
  which is the socket's peer IP (X-Forwarded-For is ignored), then a 30 s lockout. Any 30
  failures across all callers within 2 minutes trigger a 5-minute global lockout (BladeWatch-rlgv).
- `POST /auth/logout` — clears the session cookies. Idempotent.
- `POST /auth/pair` — body `{code, name}`; redeems a single-use pairing code from the in-car QR
  (BladeWatch-rdtj.7) and answers `{success, companionId, token}` exactly once, or
  `{success:false, error:"pairing_code_refused"}`. Public; same rate limits as `/auth/token`.
- `POST /auth/companion` — body `{companionId, token}`; a paired companion's token for a session
  JWT, returned in the body (`{success, jwt, expiresIn}`), not a cookie. The JWT carries `cid`
  and stops validating the moment that companion is un-paired. Public; same rate limits.

The login page is served as a static file:

- `GET /login` / `GET /login.html` → `local/login.html`.

Most other routes require a JWT Bearer token or `byd_session` cookie (see
`AuthMiddleware`). `/auth/status`, `/auth/pair`, `/auth/companion`, `/login`, `/login.html`, `/manifest.json`,
`/sw.js`, `/favicon.ico`, `/shared/*`, `/i18n/*`, and the Connect login RPC
`/bladewatch.v1.AuthService/Login` are the only paths that bypass auth.
`/thumb/*` additionally accepts a signed `?t=` thumbnail token. `/thumb/<clip>.mp4` answers a small JPEG: the clip's hero frame when one exists (scaled to a 480 px long edge and cached as `thumbs/hero_<name>.jpg` when larger -- some heroes are 2560x1920, BladeWatch-820b), else a generated 320x180 frame (202 while it is being made). `/thumb/<name>.jpg` returns that file as stored.

## Connect / gRPC Layer

A ConnectRPC (gRPC-style) API mirrors the REST surface 1:1 for the Angular SPA.
`ConnectDispatcher` routes any request whose path starts with `/bladewatch.v1.`
to a registered service handler; everything else falls through to the REST
routing in `routeToHandlers`.

- **Route prefix / path format:** `POST /bladewatch.v1.{ServiceName}/{MethodName}`,
  e.g. `POST /bladewatch.v1.AuthService/Login`. Only `POST` is accepted; other
  methods return Connect `unimplemented` (HTTP 405).
- **Required headers:** `Connect-Protocol-Version: 1` (else `invalid_argument` /
  HTTP 400) and a JSON content-type (else `invalid_argument` / HTTP 415).
- **Content-type negotiation:** unary calls send `application/json`; streaming
  calls send `application/connect+json`. The response Content-Type echoes the
  request form — `application/connect+json` is echoed verbatim, everything else
  (including early errors) returns `application/json`. The UI uses unary calls
  only.
- **Auth:** the server's `AuthMiddleware` runs before Connect dispatch, so
  handlers do no extra JWT check. `/bladewatch.v1.AuthService/Login` is the only
  Connect path on the public allowlist.
- **Errors:** failures are returned as `{code, message}` JSON; Connect codes map
  to HTTP status (`invalid_argument`→400, `unauthenticated`→401,
  `permission_denied`→403, `not_found`→404, `already_exists`→409,
  `resource_exhausted`→429, `unimplemented`→501, `unavailable`→503,
  `internal`→500).
- **1:1 parity mechanism:** each Connect impl wraps the corresponding REST
  handler via `ConnectHandlerUtil.capture*` (it invokes the REST handler against
  an in-memory buffer, strips the HTTP framing, and re-emits the JSON body). REST
  4xx/5xx responses are translated into Connect errors, and `Set-Cookie` headers
  (auth flows) are forwarded. The REST families below are therefore the source of
  truth; the Connect method just renames/repackages them.

### Registered services and RPCs

All 12 services are registered at daemon startup (`CameraDaemon.startDaemon`,
~line 387). Method → REST mapping (representative):

| Service (`bladewatch.v1.*`) | RPC methods | Mirrors REST |
| --- | --- | --- |
| `AuthService` | `Login`, `Logout`, `GetAuthStatus`, `InvalidateAuthCache` | `/auth/token`, `/auth/logout`, `/auth/status` |
| `SystemService` | `GetStatus`, `GetPerformance`, `PlayAudioTest`, `ListModels`, `DownloadModel`, `GetSelectedModel`, `SetSelectedModel`, `GetModelsManifest`, `GetSohNominal`/`SetSohNominal`, `GetSohStatus`, `ResetSoh`, `ResetPerformance`, `GetParkingDelta`, `GetLastCharge`, `PerformanceConnect`, `PerformanceHeartbeat`, `PerformanceDisconnect` | `/status`, `/api/performance*`, `/api/audio/test-avas`, `/api/models/*` |
| `RecordingsService` | `ListRecordings`, `GetDates`, `GetStats`, `DeleteRecording`, `BatchDelete`, `SyncCatalog`, `GetInflightStatus`, `GetEventTimeline`, `MarkRecording` | `/api/recordings*`, `/api/events/*` |
| `TripsService` | `ListTrips`, `GetTrip`, `DeleteTrip`, `GetSummary`, `GetDna`, `GetRange`, `GetConfig`/`SetConfig`, `GetStorage`/`SetStorage`, `SyncTrips`, `GetTelemetry`, `GetSimilarTrips`, `GetGpsTrace` | `/api/trips*` |
| `SurveillanceService` | `GetConfig`/`SetConfig`, `GetStatus`, `Enable`, `Disable`, `GetHeatmap`, `GetSnapshot`, `GetFilterLog`, `SyncCatalog` | `/api/surveillance/*` |
| `SafeLocationsService` | `ListZones`, `AddZone`, `UpdateZone`, `DeleteZone`, `Toggle` | `/api/surveillance/safe-locations*` |
| `StreamService` | `Enable`, `Disable`, `GetStatus`, `GetQuality`/`SetQuality`, `GetViewMode`/`SetViewMode` | `/api/stream/*` |
| — | `GET /api/stream/still` (REST-only, no Connect RPC): the still-frame fallback JPEG for browsers with no usable H.264 decoder (BladeWatch-y78o.1) | `/api/stream/still` |
| `SettingsService` | `GetQuality`/`SetQuality`, `GetAppearance`/`SetAppearance`, `GetLocale`/`SetLocale`, `SetRecordingMode`, `GetStatusOverlay`/`SetStatusOverlay`, `GetTelemetryOverlayFields`/`SetTelemetryOverlayFields` | `/api/settings/*`, `/api/recording/mode`, `/api/i18n/lang` |
| `StorageService` | `GetStorageSettings`/`SetStorageSettings`, `PreviewStorageLimitChange`, `GetExternalStorage`, `SetExternalConfig`, `TriggerCleanup`, `PreviewCleanup`, `RefreshExternalStorage`, `ListFormatVolumes`, `FormatVolume` | `/api/settings/storage`, `/api/storage/external/*`, `/api/storage/format` |
| `VehicleService` | `GetState`, `GetAcDiagnostics`, `Trunk`, `MoveWindow`, `SetClimate`, `SetLights`, `SetAdas`, `SetScreen`, `SetMediaVolume`, `GetChargeCap`/`SetChargeCap`, `GetGpsLocation`, `StartGps`, `StopGps`, plus cloud-only `Lock`/`Unlock`/`Flash`/`FindCar`/`SetBatteryHeat`/`Get-`/`SetChargingSchedule` (return not-supported), `IssueActionToken`, `GetAdasInventory` | `/api/vehicle/*`, `/api/gps/*` |
| `NotificationsService` | `GetCategories`, `Subscribe`, `Unsubscribe`, `ListSubscriptions`, `UpdatePreferences`, `SendTest`, `ListInbox` | `/api/notifications/*`, `/api/push/*` (`ListInbox`: Connect only) |

The full request/response message shapes are in `proto/bladewatch/v1/*.proto`
(one file per service, plus `common.proto`). Regenerate stubs with
`cd proto && buf generate`.

## Static Web Routes

The web UI is an Angular SPA. `GET /` and any unrecognised path fall through to
`angular/index.html` so the Angular router resolves the route client-side — the
old per-page routes (`/recording`, `/surveillance`, `/trips`, …) are no longer
distinct server routes.

Angular build output and asset areas:

- `GET /assets/*`, `GET /vendor/*` → Angular SPA chunks (`angular/...`).
- `GET /shared/*`, `GET /local/*` → bundled static assets. `?v=` cache-busting
  and `#` fragments are stripped before disk lookup.
- `GET /i18n/{tag}.json` → locale catalogs (404 on unsupported tags so the
  runtime falls back to `en`). Served with `Cache-Control: no-store, no-cache,
  must-revalidate, max-age=0` — the catalog URLs are unhashed (unlike the
  content-hashed Angular bundle), so they must revalidate on every load or a
  stale cached catalog would render the SPA as raw keys after an app update.
  `?query`/`#fragment` are stripped before disk lookup (future `?v=` busting).
  Catalogs are validated at build time by the `validateI18nCatalogs` Gradle
  task (fails the build on invalid JSON or missing keys vs `en.json`).
- `GET /manifest.json`, `GET /sw.js`, `GET /credits.json` → PWA assets
  (served from `local/`).

i18n:

- `GET /api/i18n/lang` — current locale + supported list.
- `POST /api/i18n/lang` — body `{lang}`; persists and echoes the resolved locale.

## Recording and Events

Handled by `RecordingsApiHandler`:

- `/api/recordings`.
- `/video/*`.
- `/thumb/*`.
- `/api/events/*`.
- `POST /api/recordings/sync` — reconcile the media catalog DB against the filesystem.
  Empty body. Returns `{success:true, added, updated, removed, total}` or
  `{success:false, error:"sync_in_progress"}` if a reconcile is already running.
- `GET /api/recording/mode` — returns `{status:"ok", mode}`.
- `POST /api/recording/mode` — body `{mode}` (e.g. `CONTINUOUS`/`EVENTS`/`OFF`);
  returns `{status:"ok", mode}`. Connect: `SettingsService.SetRecordingMode`
  (`{mode}` → `{success, mode}`), which calls `CameraDaemon.setRecordingMode`
  directly rather than shelling this inline route.
- `POST /api/recordings/mark` — bookmarks the recording currently being written
  (BladeWatch-nmao.4). Metadata only: no new file, no split, no copy. Empty body —
  the server resolves "current" from the shared encoder's live output file, since
  the caller (a Live View button) has no filename to give it. Returns
  `{success:true, filename, markTimestampMs}`, or `{success:false,
  reason:"not_recording"}` when nothing is recording (not an error — no exception,
  no non-2xx status). Marking the same clip twice is idempotent: the second call
  returns the original `markTimestampMs` unchanged, not a new one. A marked file is
  excluded from `StorageManager`'s automatic cleanup sweep (see
  [data-flow-and-storage.md](data-flow-and-storage.md)) and gains `marked`/
  `markedAtMs` fields on its `ListRecordings`/`RecordingEntry` entry.

Connect mirrors: `RecordingsService.{ListRecordings,GetDates,GetStats,
DeleteRecording,BatchDelete,SyncCatalog,GetInflightStatus,GetEventTimeline,
MarkRecording}`.

## Surveillance

Handled by `SurveillanceApiHandler` and `SafeLocationApiHandler`:

- `GET /api/surveillance/config`.
- `POST /api/surveillance/config`.
- `GET /api/surveillance/status`.
- `POST /api/surveillance/enable`.
- `POST /api/surveillance/disable`.
- `GET /api/surveillance/heatmap`.
- `GET /api/surveillance/snapshot/{quadrant}`.
- `GET /api/surveillance/filterlog`.
- `POST /api/surveillance/sync` — alias for `POST /api/recordings/sync`; reconciles
  the shared media catalog for all clip types. Same response shape.

Safe locations (`SafeLocationApiHandler`, matched before the generic
`/api/surveillance` prefix):

- `GET /api/surveillance/safe-locations` — list zones.
- `POST /api/surveillance/safe-locations` — add a zone.
- `PUT /api/surveillance/safe-locations` — update a zone.
- `DELETE /api/surveillance/safe-locations` — delete a zone.
- `POST /api/surveillance/safe-locations/toggle` — enable/disable the feature.

Connect mirrors: `SurveillanceService.{GetConfig,SetConfig,GetStatus,Enable,
Disable,GetHeatmap,GetSnapshot,GetFilterLog,SyncCatalog}` and
`SafeLocationsService.{ListZones,AddZone,UpdateZone,DeleteZone,Toggle}`.

## Streaming

Handled by `StreamingApiHandler` and WebSocket upgrade paths:

- `/api/stream/*` — stream enable/disable, quality, and view-mode control.
- `GET /ws` (WebSocket upgrade) — live H.264 stream used by the live stream
  client. Browser WebSocket clients can pass the JWT as `?token=` (promoted to a
  synthetic `Authorization: Bearer` header) since cookies may be dropped through
  a tunnel's SameSite policy.

Connect mirror: `StreamService.{Enable,Disable,GetStatus,GetQuality,SetQuality,
GetViewMode,SetViewMode}`. The binary stream itself stays on the `/ws` WebSocket;
only the control plane is mirrored to Connect.

## GPS

Handled by `GpsApiHandler`:

- `GET /api/gps` — current location JSON.
- `POST /api/gps/start` — start GPS acquisition.
- `POST /api/gps/stop` — stop GPS acquisition.

Connect mirror: `VehicleService.GetGpsLocation` / `StartGps` / `StopGps`.

GPS also enters the daemon through `SurveillanceIpcServer` command `UPDATE_GPS`,
and a snapshot of the current location is included in `GET /status` under `gps`.

## Quality and Settings

Handled by `QualitySettingsApiHandler`:

- `GET /api/settings/quality`.
- `POST /api/settings/quality`.
- `GET /api/settings/storage`.
- `POST /api/settings/storage`.
- `POST /api/settings/storage/preview` — `PreviewStorageLimitChange` (BladeWatch-gyg1.4).
  Body: `{ recordingsLimitMb?, surveillanceLimitMb? }`, either or both. Returns the real
  (not estimated) `{ recordingsImpact?/surveillanceImpact?: { fileCount, totalBytes } }` that
  applying those limits would delete, using the identical selection algorithm
  `StorageManager.ensureSpace` uses — but writes nothing and deletes nothing. A limit key
  omitted from the request is omitted from the response. See
  [data-flow-and-storage.md](data-flow-and-storage.md#previewing-a-storage-limit-change-bladewatch-gyg14).
- `GET /api/settings/unified`.
- `POST /api/settings/unified`.
- `GET /api/settings/telemetry-overlay`.
- `POST /api/settings/telemetry-overlay`.
- `GET /api/settings/appearance`.
- `POST /api/settings/appearance`.

Note: `/api/settings/storage` and `/api/settings/unified` are served here, but
the storage settings are also surfaced via `StorageService` on Connect.

Connect mirrors: `SettingsService.{GetQuality,SetQuality,GetAppearance,
SetAppearance,GetLocale,SetLocale,SetRecordingMode}` and
`StorageService.{GetStorageSettings,SetStorageSettings,PreviewStorageLimitChange}`.

## External Storage

Handled by `ExternalStorageApiHandler`:

- `GET /api/storage/external`.
- `POST /api/storage/external/config`.
- `POST /api/storage/external/cleanup`.
- `GET /api/storage/external/preview`.
- `POST /api/storage/external/refresh`.

Connect mirror: `StorageService.GetExternalStorage`, `SetExternalConfig`,
`TriggerCleanup`, `PreviewCleanup`, `RefreshExternalStorage`.

## Format Storage

Handled by `FormatStorageApiHandler` (reformat SD card / USB drive):

- `GET /api/storage/format` — list formattable volumes.
- `POST /api/storage/format` — reformat the selected volume.

Connect mirror: `StorageService.ListFormatVolumes` / `FormatVolume`.

## Trips

Handled by `TripApiHandler`:

- `GET /api/trips`.
- `GET /api/trips/{id}`.
- `DELETE /api/trips/{id}`.
- `GET /api/trips/{id}/telemetry`.
- `GET /api/trips/{id}/similar`.
- `GET /api/trips/{id}/gps`.
- `GET /api/trips/summary` — `?days=N` (default 7): ONE rollup aggregated over exactly the trips of the last N days, the same trips `GET /api/trips` lists (BladeWatch-jkuz); an empty list when there are none. It used to return the last (N+6)/7 calendar-week rollups, so "7 Days" meant "this week so far".
- `GET /api/trips/dna`.
- `GET /api/trips/range`.
- `GET /api/trips/config` — also returns `isPhev`, a LIVE drivetrain read rather than a
  stored setting. Both UIs hide the fuel price and tank capacity when it is false, so a BEV
  is never offered settings for a tank it does not have. A probe failure yields `false`,
  which clients treat as "hide unless a value is already configured" rather than as proof
  the car is a BEV.
- `POST /api/trips/config` — `isPhev` is ignored on write; it is not a setting.
- `GET /api/trips/storage`.
- `POST /api/trips/storage`.
- `POST /api/trips/sync` — reconcile the trips DB against telemetry files on disk.
  Empty body. Returns `{success:true, added, removed, total}` or
  `{success:false, error:...}`.

Connect mirror: `TripsService.{ListTrips,GetTrip,DeleteTrip,GetSummary,GetDna,
GetRange,GetConfig,SetConfig,GetStorage,SetStorage,SyncTrips,GetTelemetry,
GetSimilarTrips,GetGpsTrace}`.

### PHEV fuel fields on a trip

The trip LIST rows (`toSummaryJson`) carry derived values only:

| Field | Meaning |
|---|---|
| `litresUsed` | Litres burned this trip, from the lifetime counter delta |
| `fuelCost` | `litresUsed * fuelPricePerL` |
| `electricCost` | Electric leg cost |
| `hasFuelData` | Whether this trip recorded both ends of the fuel counter |

The trip DETAIL response (`toJson`) adds the raw readings: `fuelPctStart`/`fuelPctEnd`,
`fuelConStart`/`fuelConEnd`, `elecConStart`/`elecConEnd`, `fuelPricePerL`.

Raw lifetime counters are deliberately kept OUT of list rows. Handing a client the
counters invites it to compute its own delta, which then disagrees with the daemon's the
moment a counter resets.

**`hasFuelData` is derived from the stored trip, never from a live drivetrain probe.** A
historical trip therefore renders identically forever, including on a car whose
drivetrain reads differently today. It is also the only way to tell a BEV from a PHEV
that burned nothing: both report `litresUsed: 0`, so a `litresUsed > 0` check cannot
distinguish them.

**BEV representation.** The fuel fields are emitted as `0`, never `null` and never
omitted — one shape for every trip, so a client needs no special case.

`GET /api/trips/range` additionally returns `fuelRangeKm`, `fuelLitresPerKm` and
`builtInFuelRangeKm`. `fuelRangeKm` is `-1` when it cannot be predicted (no learned fuel
samples, or no configured tank capacity).

**Wire compatibility.** The proto fields were added at NEW numbers only — `TripSummary`
21-24, `TripDetail` 11-17, `TripConfig` 5 — so a client built against the old schema
parses these messages unchanged.

## Audio Test

Handled by `AudioTestApiHandler`:

- `/api/audio/*`.

## Vehicle Control

Handled by `VehicleControlApiHandler`. Connect mirror: `VehicleService` (e.g.
`GetState`, `Trunk`, `MoveWindow`, `SetClimate`, `SetLights`,
`SetAdas`, `GetChargeCap`/`SetChargeCap`, `GetAcDiagnostics`). Seat control (`SetSeat`,
`GetSeatDiagnostics`, the seat state and capabilities) was removed end to end in
BladeWatch-7bx4; the proto reserves its field numbers. The cloud-only RPCs (`Lock`, `Unlock`, `Flash`, `FindCar`,
`SetBatteryHeat`, `Get`/`SetChargingSchedule`) exist in the proto for parity but
return the not-supported responses described under
[Removed or unsupported endpoints](#removed-or-unsupported-endpoints).

### Endpoints

- `GET /api/vehicle/state` — returns current door/window/trunk/lock/battery/climate/tyre/lights/ADAS state. `climate` carries `setpointC` and `outsideTempC` (absent when unavailable; there is no cabin temperature — `insideTempC` was the outside air and is gone, BladeWatch-eh3u). `windows.sunroof` is the stop of the last successful sunroof command (BladeWatch-b3n7).
- `GET /api/vehicle/ac-diagnostics` — read-only AC SDK method probe.
- `VehicleService.GetAdasInventory` — read-only ADAS field inventory (BladeWatch-2pnn.3). It WAS REST-only, with a note to add an RPC "if a client needs it"; removing the REST surface was that moment (BladeWatch-6mnq), and without the RPC the diagnostic would simply have vanished. Returns `{ success, adas: { sdkClassPresent, declared: [...], sdkOnly: [...] } }` — see [byd-integrations.md](byd-integrations.md#adas-field-inventory-bladewatch-2pnn3) for the shape and the (important) caveat that `sdkClassPresent` alone does not mean "this car has ADAS".
- `POST /api/vehicle/trunk` — body `{ "action": "open" | "close" | "stop" }`.
- `POST /api/vehicle/window` — see window variants below.
- `POST /api/vehicle/climate` — body `{ "action": "power_on"|"power_off"|"set_temp"|"set_fan"|"max_cooling", ... }`.
- `POST /api/vehicle/lights` — body `{ "action": "dayTimeLight", "on": bool }` (ConnectRPC) or `{ "target": "dayTimeLight", "enable": bool }` (legacy REST). The boolean key is required; omitting both `on` and `enable` returns an error.
- `POST /api/vehicle/adas` — body `{ "action": "speedLimitWarning", "on": bool }` (ConnectRPC) or `{ "target": "speedLimitWarning", "enable": bool }` (legacy REST). The boolean key is required; omitting both `on` and `enable` returns an error.
- `GET /api/vehicle/charge-cap` — returns `{ success, percent, enabled, supported }`. `supported` is `null` until the first write-read-back probe; the UI shows optimistically until then.
- `POST /api/vehicle/charge-cap` — body `{ "percent"?: 50–100, "enabled"?: bool }`. At least one field must be present; when both are present the toggle runs first.

### Window endpoint variants

`POST /api/vehicle/window` accepts two request forms:

1. **Command form** — `{ "area": 0–6, "command": 1=open | 2=close | 3=stop }`. `area=0` + `command=2` routes through `CloseAllWindowsCommand`, which has its own local SDK primitive (`setAllWindowsCommand(2)`). All combinations are local-SDK only — the cloud-first strategy this route once used no longer exists.
2. **Target-percent form** — `{ "area": 0–6, "targetPercent": 0–100 }`. SDK closed-loop positioning. `area` must be 0–6; omitting it returns an error.

Area mapping: 0=all, 1=LF, 2=RF, 3=LR, 4=RR, 5=sunroof, 6=sunshade.

### VehicleCommandResponse shape

All write endpoints return the `routedResponse` shape built by `VehicleControlApiHandler.routedResponse`:

```json
{
  "success": true,
  "commandSuccess": true,
  "path": "local",
  "latencyMs": 312,
  "message": "Done",
  "outcome": "success",
  "action": "power_on"
}
```

- `success` / `commandSuccess` — both true on `SUCCESS`; `commandSuccess` is included for legacy UI branches.
- `path` — `"local"` or `"none"`. (`CommandResult.pathString()` maps `Path.SDK` to `"local"` and everything else to `"none"`. The former `"cloud"` and `"cloud-then-local"` values are gone with the cloud path.)
- `outcome` — lowercase `CommandResult.Outcome` name: `"success"`, `"not_supported"`, `"error"`, etc.
- `message` — localized user-facing string.
- `error` — present when `success` is false; the exception message or display message.

Additional action-specific fields (e.g. `area`, `target`, `enable`, `percent`) are echoed in the response alongside the above keys.

### Removed or unsupported endpoints

The following endpoints existed previously but are no longer supported:

- `GET /api/vehicle/cloud-status` — removed (required BYD cloud).
- `GET /api/vehicle/cloud-lock` — removed (required BYD cloud MQTT lock source).
- `POST /api/vehicle/lock` — **route removed** (`BladeWatch-c2h1`).
- `POST /api/vehicle/unlock` — **route removed**.
- `POST /api/vehicle/flash` — **route removed**.
- `POST /api/vehicle/find-car` — **route removed**.
- `POST /api/vehicle/battery-heat` — **route removed**.
- `GET` / `POST /api/vehicle/charging-schedule` — **routes removed**.

Those six previously existed and answered `NOT_SUPPORTED`, because each was cloud-only
and the cloud went in `61b4d7f`. Keeping them was dead surface that read like a
capability, so the handlers, routes and Connect registrations were deleted. The `.proto`
still declares the corresponding RPCs, so the wire contract is unchanged, but the daemon
no longer registers them.

`POST /api/vehicle/trunk` still exists, but accepts **only** `{"action": "close"}` or
`{"action": "stop"}`. `"open"` — and a missing action, which used to default to open —
answers `NOT_SUPPORTED`. Open had lost its unlock-first interlock when the cloud was
removed and could trip the car alarm on a locked vehicle; see
[byd-integrations.md](byd-integrations.md).

All supported vehicle actions use local SDK paths only.

## Performance

Handled by `PerformanceApiHandler`:

- `GET /api/performance`.
- `GET /api/performance/history`.
- `GET /api/performance/full`.
- `POST /api/performance/connect`.
- `POST /api/performance/disconnect`.
- `POST /api/performance/heartbeat`.
- `POST /api/performance/start`.
- `POST /api/performance/stop`.
- `GET /api/performance/status`.
- `GET /api/performance/discover`.
- `GET /api/performance/parking-delta`.
- `GET /api/performance/last-charge`.
- SOC-related endpoints under `/api/performance/soc`.
- Battery-related endpoints under `/api/performance/battery`.
- `GET /api/performance/soh` — nominal pack CAPACITY and its source. SoH *estimation* is still
  gone (there is no BYD-local degradation source, so `displaySoh` is 0 and `displaySource` is
  `unavailable`), but capacity is resolvable and is what the dashboard read-outs consume.
  `success` is false only when capacity genuinely cannot be determined.
- `POST /api/performance/soh/reset` — still a stub; returns "not available". SoH estimation has
  been removed and there is nothing to reset.
- `GET /api/performance/soh/nominal` — `{nominalKwh, nominalSource}`. `nominalKwh` is JSON null
  when unknown, never a fake zero. `nominalSource` is one of `user`, `sdk`, `catalogue`,
  `derived`, `unset`, computed by `NominalCapacityResolver.sourceOf` from the same inputs and in
  the same order that pick the value, so the two cannot drift.
- `POST /api/performance/soh/nominal` — body `{"nominalKwh": 18.3}` sets the owner's override,
  `{"nominalKwh": null}` clears it and returns to auto-detection. Validated to 8-120 kWh; an
  out-of-range value is refused with `errors.soh_nominal_range` rather than stored, because a
  typo must not be able to redefine the pack and corrupt every trip from then on. The override
  outranks every detected source — see "Where nominal pack capacity comes from" in
  `byd-integrations.md` (BladeWatch-b9vl).
- `POST /api/performance/reset`.

## Models

Handled by `ModelsApiHandler`:

- `GET /api/models/list`.
- `POST /api/models/download?id=ID`.
- `GET /api/models/status?id=ID`.
- `GET /api/models/selected`.
- `POST /api/models/selected`.
- `GET /api/models/manifest`.
- `POST /api/models/manifest/refresh`.

Connect mirror (via `SystemService`): `ListModels`, `DownloadModel`,
`GetSelectedModel`, `SetSelectedModel`, `GetModelsManifest`. Performance and SoH
routes are mirrored by `SystemService.{GetPerformance,ResetPerformance,
GetParkingDelta,GetLastCharge,GetSohNominal,SetSohNominal,GetSohStatus,ResetSoh}`.

## Notifications and Push

Handled by `NotificationApiHandler`:

- `GET /api/notifications/categories`.
- `POST /api/push/subscribe`.
- `POST /api/push/unsubscribe`.
- `GET /api/push/subscriptions`.
- `POST /api/push/preferences`.
- `POST /api/push/test`.

Connect mirror: `NotificationsService.{GetCategories,Subscribe,Unsubscribe,
ListSubscriptions,UpdatePreferences,SendTest}`.

`NotificationsService.ListInbox` is Connect only, with no REST twin. It serves the
companion's store-and-forward alerts (BladeWatch-rdtj.14, `CompanionInbox`). Request
`{afterId, limit}`: `limit` 0 means 100 and is capped at 500. The response is
`{entries, latestId, oldestId}`, oldest first, containing only entries with an id
above `afterId`. Ids strictly increase and are never reused, so a companion that sends
back the last id it saw can neither skip nor repeat an alert. If `latestId` is below
the companion's cursor, the car's inbox was wiped, and the companion starts over from 0.

## Status and Control

General status and control routes handled inline by `HttpServer`:

- `GET /status` — aggregate device + vehicle + recording + GPS + network status
  (see field-parity note below). Requires auth.
- `POST /api/start/{id}` — start recording camera `{id}`.
- `POST /api/view/{id}` — start view-only (no recording) for camera `{id}`.
- `POST /api/stop/{id}` — stop camera `{id}`.
- `POST /api/stopall` — stop all cameras.
- `GET /api/recording/mode` / `POST /api/recording/mode` — see
  [Recording and Events](#recording-and-events).

Additional command behavior may be implemented by the TCP command server
(`127.0.0.1:19876`) rather than HTTP.

### System status field parity (by design)

`GET /status` (Connect: `SystemService.GetStatus`) intentionally drops several
REST-emitted fields because no Connect/Angular consumer reads them, so they are
not modelled in the proto (`proto/bladewatch/v1/system.proto`):

- `BatteryMonitor.getBatteryInfo()` emits `voltage`, `soc`, `lastUpdate`, but
  `BatteryInfo` carries only `level` — the dashboard reads `battery.level` (and
  the vehicle state-of-charge separately via the `soc`/`ChargingInfo` object,
  not the Android battery `soc`).
- `NetworkMonitor.getNetworkInfo()` emits `signal` (signal percent), but
  `NetworkInfo` has no signal field — no client surfaces it.
- The top-level `status: "ok"` string is cosmetic and intentionally dropped.

If a future client needs these, add the corresponding proto fields
(`battery: voltage/soc/last_update`, `network: signal_percent`) and regenerate
stubs (`cd proto && buf generate`). Tracked by BladeWatch-852m.

## Client Guidance

- Always authenticate before calling protected APIs.
- Use the local base URL from the Android app, the LAN TLS listener (8443, pinned certificate) on the car's network, or the companion's Pear connection from anywhere.
- Avoid assuming response schemas from this list alone — read the handler class
  (REST) or `proto/bladewatch/v1/*.proto` (Connect) for the authoritative shape.
- New clients — Dart or Angular — should use the Connect API (`/bladewatch.v1.*`,
  with `Connect-Protocol-Version: 1` and a JSON content-type). REST remains the
  behavioural source of truth because the Connect handlers wrap it, but it has no
  first-party client any more.
- Prefer the `/ws` WebSocket stream for live video rather than polling snapshots.

## Source References

- HTTP server route dispatch, inline camera/status routes, and static/websocket handling: [HttpServer.java:216](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L216), [HttpServer.java:344](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L344), [HttpServer.java:498](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L498), [HttpServer.java:562](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L562), [HttpServer.java:703](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L703).
- Connect/gRPC dispatch, content-type negotiation, error mapping, and parity wrapper: [HttpServer.java:568](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L568), [ConnectDispatcher.java:72](../app/src/main/java/com/loabletech/bladewatch/server/connect/ConnectDispatcher.java#L72), [ConnectDispatcher.java:173](../app/src/main/java/com/loabletech/bladewatch/server/connect/ConnectDispatcher.java#L173), [ConnectDispatcher.java:197](../app/src/main/java/com/loabletech/bladewatch/server/connect/ConnectDispatcher.java#L197), [ConnectHandlerUtil.java:90](../app/src/main/java/com/loabletech/bladewatch/server/connect/ConnectHandlerUtil.java#L90), [SystemServiceImpl.java:36](../app/src/main/java/com/loabletech/bladewatch/server/connect/impl/SystemServiceImpl.java#L36), [CameraDaemon.java:387](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L387).
- Proto schemas (one file per service): [system.proto:27](../proto/bladewatch/v1/system.proto#L27), [vehicle.proto:32](../proto/bladewatch/v1/vehicle.proto#L32), [storage.proto:20](../proto/bladewatch/v1/storage.proto#L20), [trips.proto:26](../proto/bladewatch/v1/trips.proto#L26).
- Auth endpoints and middleware: [AuthApiHandler.java:26](../app/src/main/java/com/loabletech/bladewatch/server/AuthApiHandler.java#L26), [AuthApiHandler.java:51](../app/src/main/java/com/loabletech/bladewatch/server/AuthApiHandler.java#L51), [AuthMiddleware.java:40](../app/src/main/java/com/loabletech/bladewatch/server/AuthMiddleware.java#L40), [AuthMiddleware.java:95](../app/src/main/java/com/loabletech/bladewatch/server/AuthMiddleware.java#L95), [AuthManager.java:446](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java#L446), [AuthManager.java:561](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java#L561).
- Recording and event APIs: [RecordingsApiHandler.java:41](../app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java#L41), [RecordingsApiHandler.java:229](../app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java#L229).
- Surveillance and safe-location APIs and IPC crossover: [SurveillanceApiHandler.java:22](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceApiHandler.java#L22), [SafeLocationApiHandler.java:24](../app/src/main/java/com/loabletech/bladewatch/server/SafeLocationApiHandler.java#L24), [SurveillanceIpcServer.java:276](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.java#L276).
- Streaming APIs: [StreamingApiHandler.java:32](../app/src/main/java/com/loabletech/bladewatch/server/StreamingApiHandler.java#L32), [WebSocketStreamServer.java:19](../app/src/main/java/com/loabletech/bladewatch/streaming/WebSocketStreamServer.java#L19), [HttpServer.java:1042](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L1042).
- GPS, quality/settings, storage: [GpsApiHandler.java:24](../app/src/main/java/com/loabletech/bladewatch/server/GpsApiHandler.java#L24), [QualitySettingsApiHandler.java:48](../app/src/main/java/com/loabletech/bladewatch/server/QualitySettingsApiHandler.java#L48), [ExternalStorageApiHandler.java:42](../app/src/main/java/com/loabletech/bladewatch/server/ExternalStorageApiHandler.java#L42), [FormatStorageApiHandler.java:32](../app/src/main/java/com/loabletech/bladewatch/server/FormatStorageApiHandler.java#L32).
- Trips, performance, models, updates, notifications: [TripApiHandler.java:35](../app/src/main/java/com/loabletech/bladewatch/trips/TripApiHandler.java#L35), [PerformanceApiHandler.java:30](../app/src/main/java/com/loabletech/bladewatch/server/PerformanceApiHandler.java#L30), [ModelsApiHandler.java:38](../app/src/main/java/com/loabletech/bladewatch/server/ModelsApiHandler.java#L38), [NotificationApiHandler.java:47](../app/src/main/java/com/loabletech/bladewatch/server/NotificationApiHandler.java#L47).
- Vehicle control APIs: [VehicleControlApiHandler.java:43](../app/src/main/java/com/loabletech/bladewatch/server/VehicleControlApiHandler.java#L43).
