# BladeWatch Documentation

This directory is the project reference for the BladeWatch Android app, its native daemons, embedded web UI, BYD integrations, tunnels, APIs, and operational workflows.

BladeWatch is an Android application for BYD DiLink vehicles, shipped as **two
APKs that share one UID**: `net.bladewatch.flutter` (the Flutter in-car UI, the
only launcher icon) and `net.bladewatch.app` (the UI-less service host that runs
the foreground services, receivers and privileged shell-launched daemons). It
coordinates the in-car UI, camera and surveillance pipelines, local and remote
web access, BYD vehicle telemetry, trip analytics, Web Push notifications, and
the Tor tunnel process.

## Document Map

- [Architecture](architecture.md) describes the major modules, runtime boundaries, startup lifecycle, and component relationships.
- [Features](features.md) catalogs the user-facing and system-facing features implemented by the app.
- [UI/UX Design Language](ui-ux-design-language.md) documents the Material 3 design system shared by the Flutter in-car UI (the source of truth), the Android status overlay, and the embedded web UI — color roles, typography, shape, elevation, motion, components, and the cross-layer token pipeline.
- [Data Flow and Storage](data-flow-and-storage.md) explains where data comes from, how it moves between components, and where it is persisted.
- [Daemons and Processes](daemons-and-processes.md) documents Android components, app-process daemons, watchdogs, foreground services, and local IPC ports.
- [IPC, Authentication & Secrets](ipc-auth-and-secrets.md) explains the app/daemon UID split, the IPC token bootstrap, the secret-fetch and JWT flows, the **required `/data/local/tmp` file permissions**, and the failure modes that surface as "Camera unavailable".
- [Networking and Tunnels](networking-and-tunnels.md) covers HTTP, WebSocket streaming, auth, LAN mode, the Tor onion service, and remote access behavior.
- [HTTP API Reference](http-api-reference.md) lists the embedded web API route families and known endpoints.
- [BYD Integrations](byd-integrations.md) explains local BYD hardware APIs, compile-time stubs, telemetry collection, and local vehicle controls.
- [Surveillance Implementation](surveillance-implementation.md) documents sentry-mode activation, the GPU/native motion pipeline, AI confirmation, recording lifecycle, safe locations, schedules, APIs, and guardrails.
- [360 Camera Recording](360-camera-recording.md) explains how the shared 360 camera GPU/encoder stack records surveillance events and ACC-on driving clips.
- [Build and Operations](build-and-operations.md) covers build inputs, native dependencies, assets, tests, updates, issue tracking, and release/session procedures.
- [Throughput Harness](throughput-harness.md) defines how every remote-access path (loopback, LAN TLS, tor, Pear) is measured, so the numbers compare.
- [Log Files](log-files.md) documents where each daemon and the app process write logs on the device, the UID split, rotation/retention, and quick tail/clear commands.

## Source Areas

- `flutter_ui/lib/` contains the in-car UI: Dart screens, `ChangeNotifier`
  controllers, theme tokens, ARB catalogs, and the generated ConnectRPC client.
- `flutter_ui/android/app/src/main/kotlin/` contains that APK's small Kotlin
  layer — the privileged-operation MethodChannels and the Live View texture plugin.
- `app/src/main/java/com/loabletech/bladewatch/` contains the service host:
  daemons, local servers, BYD integrations, telemetry, storage, and the startup
  bootstrap.
- `app/src/main/assets/web/` contains the local web app and PWA assets served by the camera daemon.
- `app/src/main/assets/models/` contains AI model assets used by surveillance.
- `app/src/main/cpp/` contains native camera, surveillance, and OpenCV/OpenH264 build integration.
- `app/build.gradle.kts` defines Android, Kotlin, CMake, embedded native
  downloads, asset extraction, and the i18n/ARB validation gates.
- `flutter_ui/android/app/build.gradle.kts` is the Flutter APK's independent
  build, including the Dart and Kotlin coverage gates.
- `docs/security-smoke-test.md` documents the security smoke-test plan that existed before this documentation set.

Each detailed document includes a `Source References` section. References use `filename:line` labels and GitHub-style line anchors so refactors can jump from documentation to the implementation point being described.

## Important Defaults

- Local daemon command TCP: `127.0.0.1:19876`.
- Surveillance IPC TCP: `127.0.0.1:19877`.
- Embedded web server: `127.0.0.1:8080` by default, or `0.0.0.0:8080` only when LAN HTTP is explicitly enabled.
- Main shared config: `/storage/emulated/0/BladeWatch/data/bladewatch_config.json` (mirrored to `/data/local/tmp/bladewatch_config.json` for legacy readers).
- Shared daemon secret store: `/data/local/tmp/bladewatch_secrets.json` (`shell` `rw-------`, enforced on that filesystem; the app reads it only over IPC). It left sdcardfs in BladeWatch-078u -- see `ipc-auth-and-secrets.md`.
- Media base directory: `/storage/emulated/0/BladeWatch`.

## Security Notes

The embedded web UI is token-protected in release builds, including loopback access. LAN HTTP is disabled by default. Tunnel URLs and auth tokens should be treated as secrets. Secret values embedded in local config, tunnel tokens, and device auth secrets must not be copied into documentation or logs.

## Source References

- Documentation map entry points: [CameraDaemon.java:35](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L35), [HttpServer.java:49](../app/src/main/java/com/loabletech/bladewatch/server/HttpServer.java#L49), [GpuSurveillancePipeline.java:24](../app/src/main/java/com/loabletech/bladewatch/surveillance/GpuSurveillancePipeline.java#L24), [BydDataCollector.java:20](../app/src/main/java/com/loabletech/bladewatch/byd/BydDataCollector.java#L20), [StorageManager.java:100](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L100).
- Important defaults: [CameraDaemon.java:53](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L53), [CameraDaemon.java:350](../app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.java#L350), [StorageManager.java:100](../app/src/main/java/com/loabletech/bladewatch/storage/StorageManager.java#L100).
- Auth and secret handling: [AuthManager.java:50](../app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java#L50), [AuthMiddleware.java:133](../app/src/main/java/com/loabletech/bladewatch/server/AuthMiddleware.java#L133), [SecretConfigStore.kt:22](../app/src/main/java/com/loabletech/bladewatch/config/SecretConfigStore.kt#L22), [UnifiedConfigManager.kt:559](../app/src/main/java/com/loabletech/bladewatch/config/UnifiedConfigManager.kt#L559).
