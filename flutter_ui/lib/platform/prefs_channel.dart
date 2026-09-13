import 'platform_channel.dart';

/// Dart side of the `prefs.*` channel group (BladeWatch-yz1e.3) — plain
/// SharedPreferences local to this APK (`net.bladewatch.flutter`), for
/// per-installation UI preferences that are neither secret nor shared with
/// the native app. Ground truth: `PreferencesManager.kt`'s `getThemeMode`/
/// `setThemeMode`/`getDriveSide`/`setDriveSide` — not directly reachable
/// even though the two APKs share a UID, since SharedPreferences files live
/// under each package's own app-private directory.
class PrefsChannel {
  final PlatformChannel _channel;

  const PrefsChannel(this._channel);

  /// 'system' (default), 'light', or 'dark'. Null means never set.
  Future<String?> getThemeMode() => _channel.invoke<String?>('prefs', 'getThemeMode');

  Future<void> setThemeMode(String mode) => _channel.invoke<void>('prefs', 'setThemeMode', {'value': mode});

  /// 'left' (default), 'right', or 'auto'.
  Future<String?> getDriveSide() => _channel.invoke<String?>('prefs', 'getDriveSide');

  Future<void> setDriveSide(String side) => _channel.invoke<void>('prefs', 'setDriveSide', {'value': side});

  /// 'auto' (default), 'light', or 'dark' — the Location screen's own map
  /// tile night-mode override (BladeWatch-yz1e.6). Ground truth:
  /// `LocationSettingsStore.kt`'s `location_fragment_settings` prefs file —
  /// a key distinct from [getThemeMode]/[setThemeMode] above (the app-wide
  /// theme), which `LocationAppearanceResolver`'s "auto" branch also reads.
  Future<String?> getLocationUiMode() => _channel.invoke<String?>('prefs', 'getLocationUiMode');

  Future<void> setLocationUiMode(String mode) => _channel.invoke<void>('prefs', 'setLocationUiMode', {'value': mode});

  /// The Flutter APK's own build number the Setup Guide dialog was last
  /// dismissed on (BladeWatch-yz1e.11) — null means never shown. Ground
  /// truth: `SetupGuideDialog.showIfNeeded()` compares `PackageInfo.
  /// lastUpdateTime`; `package_info_plus` has no install-timestamp
  /// equivalent, so `SetupGuideController` compares build numbers instead —
  /// the same "did the installed build change" signal, measured differently.
  Future<String?> getSetupGuideLastSeenBuild() => _channel.invoke<String?>('prefs', 'getSetupGuideLastSeenBuild');

  Future<void> setSetupGuideLastSeenBuild(String buildNumber) =>
      _channel.invoke<void>('prefs', 'setSetupGuideLastSeenBuild', {'value': buildNumber});
}
