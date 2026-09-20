# Data Flow and Storage

BladeWatch coordinates data across the Android app process, shell-launched Java daemons, native camera code, web assets, the Tor tunnel binary, and BYD local sources. Most cross-process state is intentionally stored in files under `/data/local/tmp`.

## Primary Data Flows

### Camera to Recording

```text
BYD camera HAL / Android camera feed
  -> PanoramicCameraGpu
  -> GPU texture and mosaic pipeline
  -> GpuMosaicRecorder
  -> segmented video files
  -> StorageManager
  -> /storage/emulated/0/BladeWatch/recordings or configured external storage
```

The camera pipeline uses GPU paths and native helpers to avoid expensive CPU copies where possible.

**Recording Priority (BladeWatch-gyg1.3).** A recording segment's MP4 moov atom is written
only when `HardwareEventRecorderGpu` finalizes the file at segment rotation
(`recording.segmentMinutes` — 1/5/10 minutes, default 5) or on a clean stop. An abrupt
daemon kill (power loss) leaves the in-progress segment as an unplayable `.tmp` file,
later garbage-collected by `cleanupOrphanedTmpFiles` — not a shortened-but-valid clip.
`recording.priority` (`RecordingPriority`, values `PERFORMANCE`/`RELIABILITY`) is a cap
layered on top of `segmentMinutes`, not a replacement for it: Performance — "uses less
CPU. If power is cut abruptly, the current recording segment (up to your Recording
Limit) may be lost." Reliability — "uses a bit more CPU to save more often. If power is
cut abruptly, at most about a minute may be lost" (segment length capped to 1 minute
regardless of `segmentMinutes`). New installs default to Reliability; an existing config
migrates once to Performance, preserving its pre-existing (uncapped) behaviour.

**Orphan sweeping at daemon startup (BladeWatch-k3b0, BladeWatch-g8ee).** Every `.jpg`,
`.srt` and `.json` in `recordings/` and `surveillance/` is a sidecar keyed to an `.mp4`
basename — hero JPEG `<base>.jpg`, per-actor thumbnails `thumb_<base>_a*.jpg`, subtitle
track `<base>.srt`, event timeline `<base>.json`. Both deletion paths
(`StorageManager.ensureSpace` and `HardwareEventRecorderGpu.deleteSegmentSidecars`) take
the whole set with the `.mp4`, and `CameraDaemon` additionally runs two sweepers at
startup:

| Sweeper | Reaps |
|---|---|
| `cleanupOrphanedTmpFiles` | `.tmp` / `.broken` older than 5 minutes |
| `cleanupOrphanedSidecars` | sidecars with no `<base>.mp4` beside them, older than 5 minutes |

Measured on the head unit 2026-09-20 before the fix: 823 orphans, 111 MB, nine days,
undetected — `startPeriodicCleanup` is size-driven and oldest-first, so it cannot tell an
orphan from real footage.

**What an orphan actually costs, because it is easy to overstate.**
`getDirectoriesTotalSize` counts only `.mp4` and `.json` toward a category limit
(`StorageManager.kt`, the `namePrefix`/extension filter). Orphaned `.jpg` and `.srt` are
therefore invisible to limit accounting: they waste disk on a card shared with CDR footage,
but they never inflate a limit and never cause extra footage to be deleted. All 823 found
were `.jpg`/`.srt`. An orphaned `.json` *is* counted, so that one does consume quota and
make the reaper delete more real footage — rare, because both deletion paths have always
handled `.json`, but a crash between the `.json` write and the `.mp4` rename still strands
one. A side effect of the same rule: thumbnails and subtitle tracks sit outside the
configured limit entirely, so a category limit is not a cap on disk used. A segment mid-write is `<base>.mp4.tmp`, and its sidecars are written before
the rename, so the sweeper counts an in-flight `.mp4.tmp` as a live base and the 5-minute
window covers the gap. Thumbnail attribution is anchored on `_a` (`thumb_<base>_a…`) so a
live `<base>` never shelters a reaped `<base>_2`'s thumbnails, and vice versa.

**Which directories get swept — and the one that must not.** The sweepers run over
`StorageManager.sweepableDirs(category)` for `recordings`, `surveillance` and `proximity`:
every place a category's segments live, including the internal/SD mirror and the dedicated
legacy path, so an orphan left behind by a storage switch is still reachable. It
deliberately drops the shared flat legacy base
`/storage/emulated/0/Android/data/net.bladewatch.app/files`, which `getReapableDirs`
includes for `recordings`. That directory is not a media directory — it holds
`bladewatch_secrets.json`, `bladewatch_config.json` and `.bladewatch_device_id`, and a
sidecar sweeper pointed at it would delete all the `.json` files as orphans. `ensureSpace`
is safe there only because it passes a category name prefix; a sweeper cannot, since
`thumb_<base>_a*.jpg` carries no category prefix. `trips` is not sweepable at all — trip
telemetry is `<tripId>.jsonl.gz` with no `.mp4` anywhere.

**Telemetry overlay field selection (BladeWatch-y78o.5).** `OverlayBitmapRenderer` draws a
burned-in bar (speed, gear, left/right turn signal, brake/accelerator pedal,
driver/passenger seatbelt, timestamp) into continuous/drive-mode/proximity-triggered
recordings — `GpuMosaicRecorder`'s one call site reads the CONTINUOUS type's selection from
`telemetryOverlay.fields.continuous` (`UnifiedConfigManager`, `OverlayFieldSelectionResolver`)
on every overlay refresh (~5 fps). A field absent from that array, or the whole `fields`
section, or the whole config, is drawn — the default is every field, so an existing install
with no `fields` key sees no change. Deselecting a field leaves a gap at its fixed position
rather than reflowing the remaining fields (their layout is otherwise unconditional).
Selecting no fields at all skips the bar entirely, no empty box drawn.

**GPS latitude/longitude is a permanently separate case, not a selectable field.** It is
drawn through its own unconditional path in the same method, gated only on
`TelemetrySnapshot.hasGps` — burned into every recording with a GPS fix regardless of the
field checklist, exactly as it already was before y78o.5. That issue's own scope explicitly
excluded VIN and location from the new selection mechanism (burning either into a video
frame defeats text search on the resulting file, which is the whole reason to be careful
with them); y78o.5 did not add, remove, or gate the existing GPS behaviour, and
`OverlayField`'s enumeration cannot contain `vin`/`location`/`latitude`/`longitude`/`gps`/
`address`/`coordinates` in any case — a reflection-based test
(`OverlayFieldSelectionTest.kt`) fails the build if it ever does.

Surveillance (sentry) recording shows no overlay at all today, independent of this field
selection — `GpuSurveillancePipeline` calls
`recorder.setOverlayRecordingModeAllowed(false)` when surveillance mode is enabled, a
pre-existing, unrelated gate this issue did not change. Proximity-triggered recording is
different: `ProximityRecordingHandler` calls the SAME `startRecording(dir, "proximity")`
continuous-recording path (`Mode.NORMAL_RECORDING`, overlay enabled) as drive-mode
recording, so it already shows an overlay today — using the CONTINUOUS type's field
selection, since the daemon has no separate call site to read a `proximity`-specific one
from. The Settings UI (Recording -> Capture tab -> Overlay Fields) therefore only exposes
the CONTINUOUS checklist; `telemetryOverlay.fields.surveillance` / `.proximity` exist in the
config format and resolve correctly if read, for a future issue to wire a genuinely separate
per-type call site (or, for surveillance, to enable an overlay there at all).

### Camera to Live Stream

```text
Camera frame
  -> GpuSurveillancePipeline
  -> stream scaler and encoder
  -> WebSocketStreamServer / HttpServer WebSocket upgrade
  -> browser client
```

Live streaming is separate from recording. The server handles H.264 headers, cached SPS/PPS, IDR requests, and frame fragmentation.

### Camera to Surveillance Event

```text
Camera frame
  -> GPU downscale
  -> native motion pipeline
  -> per-quadrant motion state
  -> optional TFLite YOLO gate
  -> surveillance decision
  -> event recording and Web Push notification
```

Surveillance uses motion detection first and AI as a gated assist. Event windows include pre-event and post-event recording.

### Web UI to Daemon

```text
Browser or Android WebView
  -> http://127.0.0.1:8080
  -> AuthMiddleware
  -> HttpServer route handlers
  -> daemon managers, config, storage, camera, trips
```

The Android WebView injects auth cookies and JavaScript bridge behavior so mutating API calls can bypass local proxy interference.

### Android App to Daemon

```text
Android UI or service
  -> CameraDaemonClient
  -> TCP JSON command on 127.0.0.1:19876
  -> CameraDaemon command handlers
```

The TCP command server provides control for recording, streaming, status, storage, auth invalidation, and secret/config bridge operations.

### Location Sidecar to Surveillance IPC

```text
Android LocationSidecarService
  -> GPS cache in app files
  -> TCP JSON command UPDATE_GPS on 127.0.0.1:19877
  -> SurveillanceIpcServer
  -> surveillance/trip/telemetry consumers
```

The sidecar sends GPS updates roughly every two seconds while running.

### BYD Local Telemetry

```text
BYD framework device classes
  -> reflection helpers and listener proxies
  -> BydDataCollector
  -> BydVehicleData snapshot
  -> telemetry, web APIs, trips, performance pages
```

The collector reads initial values, registers listeners, and polls at different intervals depending on ACC state.

## Configuration Files

### Unified Config

Main config path:

```text
/storage/emulated/0/BladeWatch/data/bladewatch_config.json
```

This lives under the user-visible BladeWatch tree (not app-scoped external
files), so it survives app uninstall/reinstall and updates. A `/data/local/tmp/bladewatch_config.json`
mirror is still written for older hardcoded readers (`StorageManager`,
`SurveillanceConfigManager`). On first run after the relocation, a prior
unified config at `/storage/emulated/0/Android/data/net.bladewatch.app/files/bladewatch_config.json`
or the `/data/local/tmp` mirror is promoted to the new path rather than rebuilt.

`UnifiedConfigManager` is the main config source. It stores app and daemon settings for:

- Surveillance.
- Recording.
- Streaming.
- Network.
- Proximity guard.
- Telemetry overlay.
- Trip analytics.
- Status overlay.
- Vehicle appearance/model.
- Auth public state.

Writes use an atomic temporary-file-and-rename strategy where possible, with a direct-write fallback for app UID limitations in `/data/local/tmp`.

Legacy configs may be migrated from:

- `/data/local/tmp/sentry_config.json`.
- `/data/local/tmp/camera_settings.json`.
- `/data/data/com.android.providers.settings/sentry_config.json`.

#### `tripAnalytics` keys

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `true` | Always forced true; there is no user-facing off switch |
| `electricityRate` | `0` | Cost per kWh; 0 means not configured |
| `fuelPricePerL` | `0` | Cost per litre; 0 means not configured |
| `fuelTankCapacityL` | `0` | Tank size in litres; 0 means no fuel range can be predicted |
| `currency` | `""` | ISO 4217 code, shared by both rates — one car, one wallet |
| `distanceUnit` | `"km"` | `"km"` or `"mi"` |

A `0` in either price means "not configured", not "free": the leg is still recorded, it
is simply not costed. `fuelTankCapacityL` has no default value because BYD local data
does not expose a tank size and one must not be guessed.

#### Currency

`currency` stores an **ISO 4217 code** ("USD", "PHP"). Both settings UIs pick it from a
generated catalogue rather than accepting free text.

**No symbol table is shipped.** Symbols, their placement, the spacing around them and the
number of decimal digits vary by currency *and* by locale — JPY has no minor unit, many
European locales put the symbol after the amount. Each platform formats from its own ICU
data instead: `Intl.NumberFormat` on the web, `NumberFormat.simpleCurrency` (via `intl`) in
the Flutter UI.

**Legacy free text still works.** Configs predating the picker hold a bare symbol such as
`$`, and trips already priced in one must not change appearance. Both renderers apply the
same rule: a value shaped like an ISO code (exactly three letters) is formatted through ICU;
anything else falls back to the original rendering — the stored string, a space, then the
amount to two decimals. `TripConfig.setCurrency` mirrors that shape test, upper-casing
code-shaped input so "php" and "PHP" cannot become two stored values, and storing anything
else unchanged.

The daemon deliberately does **not** carry the 162-code list. Its job is to reject garbage,
not to be the ISO authority: the picker constrains the choice, and "exactly three letters"
is a complete structural rule with no table to keep in sync.

**There is no currency conversion, by design.** A trip is costed in the currency it was paid
in, and `TripRecord.currency` is snapshotted at cost time so history stays truthful. There is
no exchange-rate source and none is wanted — converting historical costs at today's rate
would misreport what the owner actually spent.

**The code list is generated, not hand-maintained.** `tools/gen-currencies.mjs` derives it
from ICU via `Intl.supportedValuesOf('currency')` and writes a byte-identical copy to
`web/src/assets/iso4217.json` and `flutter_ui/assets/iso4217.json`. Regenerate with:

```bash
node tools/gen-currencies.mjs
```

`validateCurrencyCatalog` (wired into `preBuild`, like `validateI18nCatalogs`) fails the
build if the two copies drift, if the list is truncated, if it is unsorted, or if a common
currency is missing. Shipped code never calls `Intl.supportedValuesOf` — it is ES2022 and
the head unit's Android 10 WebView cannot be relied on to have it.

### Trip database columns

The trips table gained ten columns for the PHEV fuel leg and metered energy:

| Column | Default | Meaning |
|---|---|---|
| `fuel_pct_start` / `fuel_pct_end` | `-1` | Tank level %, 0-100 |
| `fuel_con_start` / `fuel_con_end` | `-1` | Lifetime fuel counter, litres |
| `elec_con_start` / `elec_con_end` | `-1` | Lifetime electricity counter, kWh |
| `litres_used` | `0` | Litres burned this trip (counter delta) |
| `fuel_price_per_l` | `0` | Price snapshot at trip end |
| `fuel_cost` | `0` | `litres_used * fuel_price_per_l` |
| `electric_cost` | `0` | Electric leg cost |

**The defaults are deliberately not uniform.** The six OBSERVED counters default to
`-1`, meaning "never read". `0` is a legitimate measurement — an empty tank, a PHEV leg
driven entirely on electricity, a fresh lifetime counter — and the two must never be
collapsed. Defaulting the counters to `0` would make every historical BEV trip claim a
full set of real fuel readings that all happen to be zero. The four COMPUTED columns do
default to `0`, because they are sums: nothing measured is nothing spent.

These ten are `DOUBLE PRECISION` while their older neighbours are `REAL`. That is not an
inconsistency for its own sake: H2's `REAL` is 32-bit, and these are lifetime counters
whose value is only ever used as a small difference of two large numbers. At a
100,000 kWh counter, float32 resolution is about 0.008 kWh, which would quantise a
0.4 kWh short trip by roughly 2% — and the short trip is precisely what the metered
energy tier exists to measure.

Migration is additive (`ADD COLUMN IF NOT EXISTS`) and the columns are appended after
`route_id`, so no pre-existing prepared-statement parameter position shifts. A database
written before these columns existed opens unchanged, with the counters reading `-1`.

### Energy accounting

`TripRecord.getEnergyUsedKwh()` resolves in two tiers, in this order:

1. **Net remaining-energy delta** (`kwhStart - kwhEnd`). Wins whenever it can answer,
   because it is net of regeneration — the quantity a cost must be based on, since you
   only buy back the energy the pack actually ended up short. A pack that ended fuller
   than it started returns `0`, never a negative.
2. **Gross lifetime counter** (`elecConEnd - elecConStart`). Used only when tier 1 cannot
   answer — notably when the two readings are EQUAL. Remaining energy is derived from a
   1%-resolution SoC (~0.6 kWh, several km of driving), so on a short trip it reports a
   flat 0 while the accumulator has still advanced. Equal is "below this channel's
   resolution", not "consumed nothing".

`energyPerKm` stays electric-only kWh/km. Litres are never folded into it, or every
stored efficiency figure would change meaning and historical comparison would break.

### Secret Store

Main secret path:

```text
/storage/emulated/0/Android/data/net.bladewatch.app/files/bladewatch_secrets.json
```

The secret store lives under the user-visible BladeWatch app-files tree so
secrets survive uninstall/reinstall. On upgrade the store falls back to reading
from the legacy `/data/local/tmp/bladewatch_secrets.json` path if the primary
file is absent; once a write succeeds to the primary, the legacy file is
deleted so plaintext secrets are never left in `/data/local/tmp`.

**At-rest permission enforcement note (BYD DiLink v3):** the primary path is on
sdcardfs (`/storage/emulated/0`). POSIX mode bits are set to `rw-------` via
`Files.setPosixFilePermissions`, but sdcardfs enforces permissions primarily via
Android permission grants rather than traditional Unix mode bits — `mode 600` is
best-effort on this filesystem. The long-term fix is moving secrets to a
daemon-held native key store (Track1 `uy93.12`). Until then, the primary
protection is restricting writes to the shell-UID daemon and requiring the IPC
token for all app→daemon secret reads.

`SecretConfigStore` stores secret sections such as auth device secret and tunnel tokens. The file is created with owner-only (`rw-------`) permissions. Direct writes are restricted to shell UID where practical; the Android app uses the TCP bridge when it cannot access the file directly.

Sensitive values must not be logged or copied into docs.

### Device Identity

The auth manager uses a device id and secret to derive local access tokens. Legacy identity state includes:

```text
/data/local/tmp/.bladewatch_device_id
/data/local/tmp/.byd_auth.json
```

The current release auth model uses a JWT HMAC secret stored through the secret/config bridge.

## Media Storage

Main media base directory:

```text
/storage/emulated/0/BladeWatch
```

Common subdirectories:

- `recordings`.
- `surveillance`.
- `proximity`.
- `trips`.

`StorageSetup` prepares the app-owned external storage directory and requests or grants storage permissions. `StorageManager` also detects external SD-card-style paths and can manage separate storage choices for recordings, surveillance, and trips.

### Storage Priority (Auto-Select on Startup)

On daemon startup, `StorageManager.applyAutoStoragePriority()` resolves which physical drive to use:

1. **SD card** — discovered via `sm list-volumes all` and a write probe under `/storage/<uuid>`. If a `BladeWatch/` folder exists it is preferred; if not, the folder is created.
2. **USB drive** — if no SD card, scans `/mnt/usb*` and `/storage/usb*` for the first writable directory and applies the same BladeWatch/ creation logic.
3. **Internal storage** (`/storage/emulated/0/BladeWatch`) — fallback when no external drive is found.

The resolved storage type is persisted to the unified config (`recordingsStorageType`, `surveillanceStorageType`, `tripsStorageType`). The scan runs unconditionally on every boot so inserting or removing a drive between reboots is always reflected. All three storage types (recordings, surveillance, trips) are set to the same device.

**SD card mount retry, not a silent downgrade to internal.** Step 1's `sm mount` can lose a
boot-timing race — the card is physically present but `vold` hasn't finished mounting it yet by
the time `applyAutoStoragePriority()` runs. `StorageManager.resolveSdCardAutoPriority` (extracted
static + dependency-injected, same reasoning as `selectFilesToDelete` below) retries the mount up
to 5 times, 2 seconds apart, before giving up. If retries are exhausted **and** the persisted
config already had at least one category set to `SD_CARD`, the daemon does **not** downgrade that
preference to `INTERNAL` and save it — a config rewrite here used to mean the SD card preference
was silently lost until someone happened to reboot at a moment the race went the other way,
sometimes needing more than one restart. Instead `isSdCardMountFailedAtBoot()` /
`getSdCardMountErrorMessage()` are set, surfaced to the Flutter Recording Storage screen via
`GetStorageSettings`'s `sd_card_mount_failed` / `sd_card_mount_error` proto fields as a banner
telling the owner to restart the device with the card seated. Active directories still fall back
to internal storage in the meantime (the existing `ensureStorageReady` behavior) so recording
never stalls. Only a genuinely first-time auto-detect (no prior `SD_CARD` preference at all) falls
through to step 3 as before.

The SD-card watchdog (`startSdCardWatchdog`) starts after the priority scan and keeps the
selected drive mounted continuously (not just during sentry mode — BYD/Android can unmount the SD
card at any time). Whenever it (or the boot-time retry above) brings the card back — after being
absent at boot or unmounted mid-session — `InternalToSdMigrator.migrate()` runs on a background,
`Thread.MIN_PRIORITY` thread and sweeps any recordings/surveillance/proximity/trip files that were
written to internal storage in the meantime over to the SD card. Files younger than 60 seconds are
left alone (still possibly open for writing); a destination file that already exists is left
untouched on both sides rather than overwritten.

Internal storage and the SD card are different physical volumes, so every move falls back to a
copy-then-delete (a same-filesystem `rename` always fails with `EXDEV` across them) — confirmed on
a real device where a ~900-file backlog, accumulated during the exact mount-race incident this
migrator fixes, took over an hour to fully clear. `moveCategory`/`migrateTrips` log progress every
25 files for exactly this reason: with nothing logged until a whole category finishes, a large
backlog looks indistinguishable from a hung thread. Low thread priority keeps a large sweep from
contending with the active recording/camera pipeline for I/O or CPU while it runs.

Recordings/surveillance/proximity need no database rewrite — `MediaCatalogManager.reconcile()`
runs afterward and picks up the new paths by re-scanning the filesystem — but trip telemetry's
`telemetry_file_path` column is rewritten explicitly per moved file
(`TripDatabase.updateTelemetryFilePath`), since that path isn't discoverable any other way.

Storage cleanup behavior includes:

- Default storage limit `500 MB` (per type: recordings, surveillance, proximity, trips).
- Minimum supported limit `100 MB`.
- Maximum limit is dynamic: the effective ceiling is the selected drive's physical free space when known. The static fallback ceiling is `2 TB` (`MAX_LIMIT_MB_INTERNAL` / `MAX_LIMIT_MB_SD_CARD`, both `2_000_000` MB). The proto exposes a separate `max_limit_mb_sd_card` field so the UI can clamp SD-card limits independently from internal.
- Periodic cleanup checks every `30 seconds`.
- Avoiding storage-directory switches while recording or surveillance is active.
- **Marked recordings are never deleted by cleanup** (`MarkedRecordingsStore`,
  BladeWatch-nmao.4). `ensureSpace`'s oldest-first deletion loop skips any file whose
  name is in the marked-recordings store before deleting it — a bookmark set via
  `POST /api/recordings/mark` on a clip protects it from the retention sweep
  indefinitely, with no separate "keep forever" flag or expiry. Marks persist to
  `/data/local/tmp/marked_recordings.json`, independent of the storage type the
  clip itself lives on.

### Previewing a storage limit change (BladeWatch-gyg1.4)

Lowering the recordings/surveillance limit can delete existing clips the moment
`SetStorageSettings` is applied — `handleStorageSettingsPost` writes the new limit and kicks
off an async cleanup thread immediately, with no confirmation step of its own. To let the
Settings UI warn honestly before that happens, `StorageManager.selectFilesToDelete` — the
oldest-first, marked-recording-excluding selection algorithm `ensureSpace` itself deletes with
— was extracted into a static, dependency-injected method shared, unmodified, by both:

- `ensureSpace` (the real cleanup — deletes the files the selection returns), and
- `previewRecordingsLimitChange(hypotheticalLimitMb)` /
  `previewSurveillanceLimitChange(hypotheticalLimitMb)` (new — sums the selection into a
  `CleanupImpact { fileCount, totalBytes }` and deletes nothing).

Because both paths run the identical selection code, a preview and the cleanup it previews can
never disagree about which files a given limit would remove.

The preview is exposed as its own RPC, `PreviewStorageLimitChange` (`POST
/api/settings/storage/preview`) — deliberately not a flag on `SetStorageSettings` — so a
caller previewing a lowered limit has a structural guarantee that `SetStorageSettings` itself
was never called: nothing was written, no cleanup ran, regardless of what the owner does next.
Both the Flutter Recording Storage screen (`SettingsRecordingScreen`, BladeWatch-gyg1.4) and
the Surveillance Storage tab (`SurveillanceSettingsScreen`, BladeWatch-gyg1.6) call it the
same way — only when the proposed limit is lower than the current one (raising a limit can
never delete anything); if the preview reports at least one file, the owner sees a
confirmation naming the real count and size before Apply proceeds, and cancelling leaves the
RPC path to `SetStorageSettings` completely untaken. A preview call that itself fails shows a
distinct "impact unknown" confirmation rather than silently proceeding as if nothing would be
deleted. The two screens' confirmation dialog code (`_applyStorage`/
`_confirmStorageLimitChange`) is duplicated per screen rather than shared, matching this
codebase's existing convention of one small controller/screen pair per settings surface (see
e.g. `settings_recording_models.dart`'s own note on why `FormatDriveResult` is copied rather
than imported) — only the `StorageLimitImpact` model and the four `settings_recording_storage_confirm_*`
l10n strings are actually shared between them.

### Format Storage API

`FormatStorageApiHandler` lets the UI wipe and re-mount a removable drive so a freshly inserted or full SD card / USB stick can be reused:

- `GET /api/storage/format` — `ListFormatVolumes`. Returns the removable public volumes visible to `StorageManager`: `{ success, volumes: [{ volumeId, uuid, mounted, mountPath }] }`. `mountPath` is `/storage/<uuid>`.
- `POST /api/storage/format` — `FormatVolume`. Body `{ "volumeId": "public:..." }`. Runs `sm unmount` → `sm format` → `sm mount` for the volume, polls up to ~10 seconds for the remount, then calls `StorageManager.discoverSdCard()` so the drive is re-picked-up.

Guardrails:

- Only removable `public:` volumes are accepted; internal emulated storage is rejected.
- The request is refused with HTTP 409 while a recording is active.

The proto contract is `StorageService.ListFormatVolumes` / `FormatVolume` in `proto/bladewatch/v1/storage.proto`.

## Web Assets

Source assets:

```text
app/src/main/assets/web/
```

Runtime extracted assets:

```text
/data/local/tmp/web
/data/local/tmp/overlay
```

`HttpServer` extracts web and overlay assets when the daemon starts. Gradle also defines an `extractWebAssets` helper task that can push web assets to `/data/local/tmp/web` during development.

GPU kernel cache:

```text
/data/local/tmp/tflite_gpu_cache
```

`YoloDetector` enables TFLite GPU kernel serialization (`GpuDelegateFactory.Options.setSerializationParams`) into this directory. The Adreno OpenCL backend otherwise recompiles all GPU kernels on every daemon start (~3–5s); serialization persists the compiled kernels so only the first-ever boot pays that cost. The cache key (`modelToken`) is a SHA-256 content hash of `yolo11n.tflite` plus the TFLite version, so a re-exported model or a runtime bump invalidates stale kernels automatically. The cache is OpenCL-only and silently no-ops on the OpenGL ES backend; a failure to create or write the directory falls back to a bare delegate without disabling GPU.

## Tunnel Runtime Files

Tor onion service:

```text
/data/local/tmp/bladewatch_tor    the binary, installed under its own process name
/data/local/tmp/tor/torrc         generated config, rewritten on every launch
/data/local/tmp/tor/data          consensus cache (safe to delete; costs a slow start)
/data/local/tmp/tor/hs            hidden-service directory — see the warning below
/data/local/tmp/tor/hs/hostname   the onion address, mode 600, shell-owned
/data/local/tmp/tor.log           notice log
```

**`hs/hs_ed25519_secret_key` is a SECRET and it is permanent.** It is the private key the
car's onion address is derived from, so it belongs in the same category as the entries in
`bladewatch_secrets.json`: never logged, never copied to shared storage, never returned
over IPC, never committed. It differs from those in one important way — it cannot be
rotated harmlessly. Deleting it mints a new address on the next start and silently breaks
every QR code the owner has ever scanned, so the tunnel is stopped by killing the process,
never by deleting its directory.

## Auth Data Flow

```text
Client requests /auth/token
  -> AuthApiHandler
  -> AuthManager validates device token
  -> JWT issued with token epoch
  -> client stores Bearer token or byd_session cookie
  -> AuthMiddleware validates future requests
```

Release builds require JWT auth even for loopback requests because Android loopback is shared. Debug loopback bypass exists only when tunnel-forwarding headers are absent.

Public paths are limited to auth bootstrap, login/static shell assets, manifest/service worker, shared assets, and i18n assets.

## Trip Data Flow

```text
Telemetry and GPS inputs
  -> trip analytics collectors
  -> trip storage
  -> TripApiHandler
  -> web trips pages
```

Trip APIs expose lists, details, telemetry, similar trips, GPS traces, summary, driving DNA, range analytics, config, and storage management.

Trip catalog, rollups, and consumption buckets are persisted in an H2 embedded
database under the user-visible BladeWatch tree so trip history survives app
uninstall/reinstall and updates:

```text
/storage/emulated/0/BladeWatch/data/bladewatch_trips_h2.mv.db
```

`TripDatabase` migrates an existing database from the old `/data/local/tmp/bladewatch_trips_h2.mv.db`
location once, on first init after the relocation. Trip telemetry sample files
remain under the `trips` media subdirectory and are governed by `StorageManager`.

A manual reconcile (`POST /api/trips/sync`) prunes trip rows whose telemetry
`.jsonl.gz` file is missing (legacy rows with no `telemetry_file_path` are
preserved), then re-indexes orphan telemetry files as minimal trip records
(start/end/duration/distance derived from GPS; SOC and driving-DNA scores set to 0
because telemetry samples carry no SOC field).

## Media Catalog (Recordings + Surveillance + Proximity)

Recordings, surveillance clips, and proximity clips are indexed in a second H2 database:

```text
/storage/emulated/0/BladeWatch/data/bladewatch_media_h2.mv.db
```

Owned by `MediaCatalogManager` (initialized by `CameraDaemon` alongside the trips
DB). The single `recordings` table stores one row per `.mp4` clip; the natural key
is the absolute file path. Indexes on `timestamp_ms` and `type` make the common
list-by-type-and-date queries fast.

### Live indexing

Clips are indexed the moment they are finalized:

- All clip types (normal cam, event, proximity) — `StorageManager.onFileSaved()`
  at the single finalize convergence point. Every recording finalizes through
  `HardwareEventRecorderGpu` (the `tmp→final` rename), which calls `onFileSaved()`,
  which calls `MediaCatalogManager.indexRecording()`. The clip type is derived
  from the filename prefix (`cam_`, `event_`, `proximity_`).
- Sidecar enrichment — `EventTimelineCollector.writeJsonSidecar()` triggers a
  second upsert (MERGE by path) so the row is enriched with actor/severity data as
  soon as the `.json` sidecar is written; the two-phase upsert is idempotent.

### DB-first reads with lazy auto-rebuild

`RecordingsApiHandler` reads from the DB for list, dates, and stats queries. If the
DB is empty (fresh install, DB wipe, or pre-existing clips), one reconcile fires
automatically (`MediaCatalogManager.ensureIndexedOnce`) so the UI is never blank.
The filesystem scan stays as both the rebuild mechanism and the fallback if the DB
is unavailable.

### Manual sync

`POST /api/recordings/sync` (and the alias `POST /api/surveillance/sync`) run a
full reconcile: scan all recording/surveillance/proximity directories, diff against
`getAllPathState()` (path→[size, mtime, sidecar-mtime]), add/update/remove as
needed. Returns `{success, added, updated, removed, total}`. A concurrent call
returns `{success:false, error:"sync_in_progress"}` without blocking.

## Notification Data Flow

```text
Daemon or surveillance event
  -> notification manager/API
  -> Web Push subscription target
  -> web notification state APIs
```

Notification APIs expose categories, push subscription management, preferences, and test delivery.

## Data Ownership Summary

- Android app owns user-visible lifecycle, permissions, UI navigation, WebView session setup, and foreground service lifecycles.
- Camera daemon owns camera state, recording state, HTTP APIs, auth enforcement, streaming, and most runtime telemetry.
- Shared files under `/data/local/tmp` allow app and daemons to coordinate.
- Media files live under `/storage/emulated/0/BladeWatch` or configured external storage.
- BYD local data is read from firmware APIs and kept in memory snapshots.
- Tunnel secrets belong in the secret store.

## Source References

- Camera-to-recording path: [PanoramicCameraGpu.java:39](../app/src/main/java/com/loabletech/bladewatch/camera/PanoramicCameraGpu.java#L39), [GpuMosaicRecorder.java:31](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuMosaicRecorder.java#L31), [HardwareEventRecorderGpu.java:56](../app/src/main/java/com/loabletech/bladewatch/surveillance/HardwareEventRecorderGpu.java#L56), [StorageManager.java:2234](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L2234).
- Live-stream path: [GpuSurveillancePipeline.java:30](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java#L30), [WebSocketStreamServer.java:19](../app/src/main/java/com/loabletech/bladewatch/streaming/WebSocketStreamServer.java#L19), [HttpServer.java:538](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L538).
- Surveillance-event path: [GpuDownscaler.java:51](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuDownscaler.java#L51), [SurveillanceEngineGpu.java:635](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.java#L635), [SurveillanceEngineGpu.java:3095](../app/src/main/java/com/loabletech/bladewatch/surveillance/SurveillanceEngineGpu.java#L3095).
- Web UI to daemon: [HttpServer.java:50](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L50), [AuthMiddleware.java:135](../app/src/main/java/com/loabletech/bladewatch/server/AuthMiddleware.java#L135). (The in-car `WebViewFragment` client was deleted in Phase 4; the SPA now serves remote browsers only, and the in-car UI is the Flutter app's Dart ConnectRPC client, [flutter_ui/lib/rpc/](../flutter_ui/lib/rpc/).)
- App TCP client to daemon: [CameraDaemonClient.java:24](../app/src/main/java/com/loabletech/bladewatch/client/CameraDaemonClient.java#L24), [TcpCommandServer.java:22](../app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java#L22), [CameraDaemon.java:53](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L53).
- Location IPC: [LocationSidecarService.java:32](../app/src/main/java/com/loabletech/bladewatch/services/LocationSidecarService.java#L32), [SurveillanceIpcServer.java:23](../app/src/main/java/com/loabletech/bladewatch/server/SurveillanceIpcServer.java#L23), [CameraDaemon.java:383](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L383).
- BYD local data flow: [BydDataCollector.java:20](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L20).
- Unified config, secrets, and auth identity: [UnifiedConfigManager.kt:30](../app/src/main/java/com/loabletech/bladewatch/config/UnifiedConfigManager.kt#L30), [SecretConfigStore.kt:22](../app/src/main/java/com/loabletech/bladewatch/config/SecretConfigStore.kt#L22), [AuthManager.java:50](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java#L50), [AuthManager.java:349](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java#L349).
- Media and SD-card storage: [StorageManager.java:100](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L100), [StorageManager.java:113](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L113), [StorageManager.java:918](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L918), [StorageManager.java:967](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L967), [StorageManager.java:2378](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L2378).
- Format storage API: [FormatStorageApiHandler.java:27](../app/src/main/java/com/loabletech/bladewatch/server/FormatStorageApiHandler.java#L27), [storage.proto:20](../proto/bladewatch/v1/storage.proto#L20).
- Media catalog and sync: [MediaCatalogManager.java:26](../app/src/main/java/com/loabletech/bladewatch/media/MediaCatalogManager.java#L26), [MediaCatalogManager.java:81](../app/src/main/java/com/loabletech/bladewatch/media/MediaCatalogManager.java#L81), [MediaCatalogManager.java:130](../app/src/main/java/com/loabletech/bladewatch/media/MediaCatalogManager.java#L130), [RecordingsApiHandler.java:185](../app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java#L185).
- Trip database and sync: [TripDatabase.java:19](../app/src/main/java/com/loabletech/bladewatch/trips/TripDatabase.java#L19), [TripDatabase.java:30](../app/src/main/java/com/loabletech/bladewatch/trips/TripDatabase.java#L30).
- Runtime assets and tunnel files: [build.gradle.kts:226](../app/build.gradle.kts#L226), [HttpServer.java:50](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L50), [TorLauncher.kt:92](../app/src/main/java/com/loabletech/bladewatch/launcher/TorLauncher.kt#L92).
- Trips and notifications: [TripDetector.java:27](../app/src/main/java/com/loabletech/bladewatch/trips/TripDetector.java#L27), [TripAnalyticsManager.java:23](../app/src/main/java/com/loabletech/bladewatch/trips/TripAnalyticsManager.java#L23), [TripApiHandler.java:35](../app/src/main/java/com/loabletech/bladewatch/trips/TripApiHandler.java#L35), [NotificationApiHandler.java:31](../app/src/main/java/com/loabletech/bladewatch/server/NotificationApiHandler.java#L31).
