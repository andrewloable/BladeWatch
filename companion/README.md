# BladeWatch companion

The owner's app for reaching the car from a phone or a desktop (epic BladeWatch-rdtj):
directly over the car's Wi-Fi when both are on it, otherwise over Pear, which needs no
account, server or open port. It replaces the web UI and has all of its pages.

- **Pairing.** On the car's dashboard, tap **Pair a device** and scan the code, or paste
  its text. A code works once and expires in five minutes.
- **Structure.** `lib/app.dart` is the shell. `lib/car/` holds the session, the store and
  the connection-state page. `lib/screens/` has one directory per page. `lib/transport/`
  is the LAN and Pear gateway. The strings are `assets/i18n/`, the web catalogs plus a
  `companion` section, all 17 languages.
- **Build and test.** See "Build Commands" in the repo's CLAUDE.md and "Platform Scope"
  for which platforms are in scope. In short:

```bash
flutter analyze && flutter test
flutter build apk --release          # arm64-v8a + x86_64 in one APK, unsigned without a keystore
flutter test integration_test/car_e2e_test.dart -d macos --dart-define=BW_PAIRING=<qr text>
```
