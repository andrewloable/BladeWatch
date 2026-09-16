<p align="center">
  <img src="flutter_ui/assets/brand/app_icon.png" width="120" alt="BladeWatch Logo">
</p>

<h1 align="center">BladeWatch</h1>

Free, open-source dashcam and sentry mode app built specifically for BYD vehicles with DiLink v3. All recordings and data stay on your device — no cloud, no accounts, no subscriptions. Optional remote viewing is direct, peer-to-peer through your own tunnel.

BladeWatch targets BYD DiLink v3 head units (`arm64-v8a`, Android 10+) and installs onto the car's head unit over ADB.

It ships as **two APKs that must both be installed**:

| APK | Package | Role |
|---|---|---|
| In-car UI | `net.bladewatch.flutter` | Everything you see and tap. The only launcher icon. |
| Service host | `net.bladewatch.app` | Daemons, recording, surveillance, BYD integration. No UI, no launcher icon. |

They share one Android UID, which is what lets the UI talk to the daemons over loopback IPC. That only works when **both are signed with the same key**, so install them as a pair and never mix builds from different sources.

## Quick Start (Use Pre-built APK)

Download **both** APKs from [GitHub Releases](../../releases) and install them on your BYD head unit.

Release builds are published **unsigned**, so the signing key never touches CI. Sign both with the same key before installing:

```bash
for f in bladewatch-*-unsigned.apk; do
  apksigner sign --ks release.jks --ks-key-alias key0 \
    --out "${f%-unsigned.apk}.apk" "$f"
done
# both digests must match, or the UI cannot reach the daemons:
apksigner verify --print-certs bladewatch-*-arm64-v8a.apk | grep 'SHA-256 digest'

adb install bladewatch-service-host-*-arm64-v8a.apk
adb install bladewatch-ui-*-arm64-v8a.apk
```

### 1. Prerequisites
- Ensure **Wireless ADB** is enabled on your device before launching the app.

### 2. Initial Configuration
1. **Authorize ADB:** On first launch, accept the ADB authentication prompt on your device screen.
2. **Background Persistence:** In the head unit's autostart settings, make sure autostart is **enabled for both entries** — **"BladeWatch"** (the UI) and **"BladeWatch Service"** (the daemons). Two entries appear because BladeWatch is two APKs. This is critical: on this head unit BYD suppresses the usual boot broadcast, so autostart is what allows the app to run at boot at all. Enabling only the UI leaves the daemons dead.

> ⚠️ **CRITICAL: Hard Reboot Required**
> After the first installation and initial run, you must hard reboot the device:
> Press and hold the **Volume Down** button for 5 seconds. Wait for the system to fully restart.
> This step is necessary to finalize the installation.

---

## Features

### Recording
- **Panoramic Dashcam** — Records the BYD 360° panoramic camera through a GPU mosaic pipeline (H.264/H.265), segmented into configurable clips with a recording library and calendar view for browsing and managing footage.
- **Proximity Recording (Market First)** — Uses BYD's 8 parking radar sensors to trigger recording only when objects approach the parked car. Configurable trigger levels, pre-event buffer, and 500ms debouncing.
- **Advanced Sentry Mode** — 24/7 surveillance with GPU motion detection, per-quadrant tracking, and an optional on-device AI object-recognition gate (TFLite YOLO11n). Supports safe-location zones, schedules, and pre/post-event windows.

### Vehicle & Driving
- **Vehicle Control** — Operate climate (AC, temperature, fan, max-cooling), windows (open/close and partial positioning), and seats (heat, ventilation, memory recall) directly from the app. Runs entirely through the local BYD SDK — no cloud account required.
- **3D Vehicle Hero** — An interactive 3D model of your car (Seal, Seal U, Dolphin, Atto 3, Han, Tang, and more) with a live state dashboard: doors, windows, battery SOC and range, per-tyre pressure, and climate.
- **Live Location** — Map view of the car's current position with a heading-rotated marker and a one-tap link out to Google Maps.
- **Trips & Analytics** — Trip history with route maps, telemetry, and driving insights.

### Monitoring & Remote Access
- **Real-time Performance Monitor** — CPU, GPU, memory usage, and battery voltage dashboard.
- **Diagnostics** — Network, storage, camera, and battery health checks.
- **Live Streaming** — Low-latency H.264 streaming over WebSocket with multiple view modes (all cameras, front, rear, left, right).
- **Remote Web App** — A full Angular web UI served by the on-device daemon, reachable from any browser through your tunnel. Token-protected.
- **Web Push Notifications** — Get surveillance event alerts pushed to your phone or desktop.
- **ADB Shell Runner** — Built-in terminal for running commands, checking processes, and viewing logs.
- **17 Languages** — Fully localized UI.

### Tor Onion Service
_(Versions before 1.3.1 used a different tunnel that required an account and an invite token. It has been removed; no migration is needed beyond enabling the Tor tunnel.)_

Remote access runs over a Tor v3 onion service: no account, no token, no sign-up, and no
device limit. The address is permanent — it survives restarts and reboots — so the QR code
on the Dashboard keeps working once you have scanned it.

**Setup:** enable the Tor tunnel under Daemons in the app. That is the whole setup. The
first start takes about 80 seconds while tor connects to the network (a few seconds
afterwards), and the Dashboard shows the QR code once it is actually reachable.

**Opening the address:** a `.onion` address does not work in Chrome or Safari. Install
[Tor Browser](https://www.torproject.org/download/) (Android, Windows, macOS, Linux) or
Onion Browser on iPhone and iPad, then scan or paste the address. The Dashboard's info
button shows the same instructions on the car's screen.

**The address is not a password.** Anyone who has it can reach your car's login page, so
the app's password still protects everything behind it — keep both to yourself.

Expect roughly 60–75 KB/s and a couple of seconds of latency per request: slower than a
direct connection, comfortably enough for the web UI and for live video.

> Should work on all BYD vehicles with DiLink v3 and the panoramic camera system.

## Building from Source

BladeWatch is a hybrid project built from three codebases:

- **`flutter_ui/`** — the in-car UI (Flutter/Dart), built as `net.bladewatch.flutter`.
- **`app/`** — the service host (Android/Kotlin/Java + C++), built as `net.bladewatch.app`. Owns the daemons, the camera/GPU pipeline and the BYD integration.
- **`web/`** — the Angular SPA the on-device daemon serves to remote browsers over your tunnel. Bundled into the service host APK.

The in-car UI was native Android until it was rewritten in Flutter; the Angular app is not the in-car UI and is only used by remote clients.

### Requirements
- Android SDK (`compileSdk 36`) and NDK `26.1.10909125`
- JDK 17 (the modules themselves target Java 11 bytecode)
- [Flutter](https://docs.flutter.dev/get-started/install) 3.44+ — for the in-car UI APK
- Node.js + npm — **required**, not optional. The Angular SPA is built during `preBuild` and
  neither `web/dist` nor its packaged copy is committed, so without Node the build fails rather
  than quietly producing an APK with no web UI.
- [`buf`](https://buf.build) — optional, only needed to regenerate the protobuf / ConnectRPC stubs

### Build

The two APKs build independently, from different toolchains:

```bash
# Service host (net.bladewatch.app) — also builds the Angular web UI and the
# native libraries, then bundles them into an arm64-v8a APK.
./gradlew assembleDebug
# Output: app/build/outputs/apk/debug/bladewatch-<branch>-arm64-v8a-debug.apk
#         (the git branch is embedded so builds stay distinguishable)

# In-car UI (net.bladewatch.flutter)
cd flutter_ui && flutter build apk --target-platform android-arm64 --debug
# Output: flutter_ui/build/app/outputs/flutter-apk/app-debug.apk
```

Both packages must report the **same UID** or the UI cannot reach the daemons:

```bash
adb shell 'dumpsys package net.bladewatch.app | grep userId'
adb shell 'dumpsys package net.bladewatch.flutter | grep userId'
```

Release builds without a keystore come out **unsigned** by design (see Quick Start).
Tagged releases are built by GitHub Actions — see `.github/workflows/release.yml`.

The Gradle build orchestrates everything:
- `buildAngularWebUI` builds the Angular app under `web/` and copies the output into the APK assets (hooked into `preBuild`; requires npm).
- Native dependencies (OpenH264, opencv-mobile, TensorFlow Lite) are auto-downloaded and checksum-verified — no manual download step.
- `generateConnectProtos` regenerates Java + TypeScript stubs from `proto/bladewatch/v1/*.proto` (only needed when the API schemas change).

The UI communicates with the daemon over a REST API and a 1:1 ConnectRPC layer on `127.0.0.1:8080`, with privileged operations going through loopback IPC on `127.0.0.1:19876`. For device install, daemon cleanup, and the full development workflow, see [`CLAUDE.md`](CLAUDE.md) and the [`docs/`](docs/) directory.

### Documentation
In-depth documentation lives in [`docs/`](docs/) — architecture, daemons and processes, IPC/auth/secrets, networking and tunnels, the HTTP API reference, BYD integrations, the surveillance pipeline, and storage.

## Privacy

- 100% local storage — all recordings saved on device
- No account required
- No cloud upload — remote viewing is direct via tunnels you control
- Open source — audit the code yourself

## Acknowledgments

- **3D BYD Vehicle Models** — The Vehicle Control page renders interactive 3D cars with [Three.js](https://threejs.org/), using base models from [ddiaz-design's BYD collection on Sketchfab](https://sketchfab.com/ddiaz-design/collections/byd-base-models-5bf92ab5f2be4ff6be5c3ac49f7099f3).

## License

Open source under MIT License. Your data stays on your device.
