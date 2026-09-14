# BladeWatch in-car UI (Flutter)

The in-car UI for BladeWatch, shipped as its own APK — `net.bladewatch.flutter`
— alongside `net.bladewatch.app`, which hosts the daemons, camera/surveillance
pipeline, HTTP + IPC servers and BYD integration.

## Android-only. On purpose.

This app targets exactly one thing: an **arm64 Android head unit** (BYD DiLink
v3, Android 10 / API 29). There is no BladeWatch on a desktop, a phone or a
browser, and there will not be.

Only `android/`, `lib/`, `test/` and `assets/` exist here. If you find yourself
looking for `ios/`, `macos/`, `windows/`, `linux/` or `web/` — **nothing is
broken and nothing needs restoring.** They were deleted deliberately.

Two guards keep it that way:

- **`validateFlutterAndroidOnly`** in [`app/build.gradle.kts`](../app/build.gradle.kts)
  runs on `preBuild` and **fails the build** if any of those directories
  reappear. It is a filesystem check only, with no `flutter` invocation, so the
  main app still builds on a machine with no Flutter toolchain installed.
- The same five paths are in the repo `.gitignore`, so a regenerated tree cannot
  be swept into a commit.

They regenerate more easily than you would think: `flutter create .`, some
`flutter pub get` paths, or adding a plugin that runs platform scaffolding will
all recreate them silently. **Do not run `flutter create` in this directory.**

There is no `platforms:` key in `pubspec.yaml` declaring this. That key is valid
for *plugins* only; on an application Flutter rejects it outright and
`flutter pub get` fails with `Unexpected child "platforms" found under
"flutter"`. Hence the Gradle task.

Note that `web/` at the **repository root** is the Angular SPA — a separate,
browser-targeted project that is tracked and unrelated to Flutter's `web`
platform directory. The guard only looks inside `flutter_ui/`.

## Day-to-day

```bash
cd flutter_ui
flutter analyze
flutter test                                   # no device or daemon needed
flutter test --coverage                        # gate: ../tools/check_flutter_coverage.sh
flutter build apk --profile --target-platform android-arm64
adb -s $CAR_IP:5555 install -r build/app/outputs/flutter-apk/app-profile.apk
```

Installing this APK needs none of the daemon-kill/uninstall ceremony the main
app requires — see the repo [`CLAUDE.md`](../CLAUDE.md) for that.

## Layout

| Path | What |
|---|---|
| `lib/screens/<name>/` | One screen: a pure-Dart `ChangeNotifier` controller, models, and the widget. Controllers have no Flutter imports, which is what makes them testable without a device. |
| `lib/rpc/` | Connect-over-JSON transport and the typed service clients. All RPCs are unary; there is no streaming path. |
| `lib/platform/` | Dart side of the platform channels (privileged ops, live-view texture). |
| `lib/l10n/` | ARB catalogs, ported from `res/values*/strings.xml`. Key parity is build-enforced by `validateArbCatalogs`. |
| `android/app/src/main/kotlin/` | The small Kotlin surface: loopback IPC, JWT minting, daemon control, and the MediaCodec live-view texture plugin. |

Architecture, the two-APK/shared-UID arrangement and the peer-UID gate are
documented in [`docs/`](../docs/) and [`CLAUDE.md`](../CLAUDE.md).
