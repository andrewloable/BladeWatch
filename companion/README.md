# BladeWatch companion

The owner's app for reaching the car from a phone or a desktop (epic BladeWatch-rdtj):
directly over the car's Wi-Fi when both are on it, otherwise over Pear, which needs no
account, server or open port. It replaces the web UI and has all of its pages.

- **Pairing.** On the car's dashboard, tap **Pair a device** and scan the code, or paste
  its text. A code works once and expires in five minutes. TVs and desktops pair over the
  car's Wi-Fi by number instead.
- **Relay access (v1.4.1.3).** Settings > Relay access, or the button on the "can't reach the
  car" page: the owner's own relay, with the same 12-digit key as the car, for a car on its SIM
  and a phone on mobile data. Setup: `../relay/README.md`.
- **Structure.** `lib/app.dart` is the shell. `lib/car/` holds the session, the store and
  the connection-state page. `lib/screens/` has one directory per page. `lib/transport/`
  is the LAN and Pear gateway. The strings are `assets/i18n/`, the web catalogs plus a
  `companion` section, all 17 languages.
- **Build and test.** See "Build Commands" in the repo's CLAUDE.md and "Platform Scope"
  for which platforms are in scope. In short:

```bash
flutter analyze && flutter test
flutter build apk --release --target-platform android-arm64   # one APK per ABI; unsigned without a keystore
flutter test integration_test/car_e2e_test.dart -d macos --dart-define=BW_PAIRING=<qr text>
flutter test integration_test/relay_key_test.dart -d macos    # the relay key on the real worklet
```

- **iOS** is never built by CI (it needs Apple signing). To sideload it with SideStore, build the
  unsigned app and zip its `.ipa` for AirDrop: the commands and the iPhone steps are under
  "iOS" in "Install the Companion App" in the repo's `Readme.md`.
