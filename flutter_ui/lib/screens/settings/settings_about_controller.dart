import 'package:flutter/foundation.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Current app identity — sourced from `package_info_plus` by the widget
/// layer and injected here so this controller needs no platform-channel
/// mocking of its own to test. Ground truth for the *values shown*:
/// `SettingsAboutFragment.kt`'s `tvAboutVersion`/`tvAboutBuild`
/// (`BuildConfig.VERSION_NAME`/`BuildConfig.APPLICATION_ID`) — this reads
/// the FLUTTER APK's own identity (`net.bladewatch.flutter`), a distinct
/// package from the main app.
class AppVersionInfo {
  final String version;
  final String buildNumber;
  final String packageName;

  const AppVersionInfo({required this.version, required this.buildNumber, required this.packageName});
}

/// Ground truth: `SettingsAboutFragment.kt` for version/build/license.
/// "Check for Updates" is NOT in that fragment (grepped: unused since no
/// native code references `settings_about_check_update_value`/
/// `auto_update_title`/`source_title` etc. — leftover ARB keys from a
/// richer About page that was never built) — this instead uses the
/// already-built `update.*` channel (BladeWatch-ncbb.2), which updates
/// *this Flutter APK*, a separate, simpler mechanism from the main app's
/// ADB-based `AppUpdater.java`. The license text and the "show setup guide
/// again" row are both faithfully ported; the setup-guide dialog itself is
/// BladeWatch-yz1e.11's job, same split as the language picker elsewhere in
/// Settings — this screen only needs a callback to open it.
class SettingsAboutController extends ChangeNotifier with DisposedSafeNotifier {
  SettingsAboutController({required Future<AppVersionInfo> Function() versionSource})
    : _versionSource = versionSource; // ignore: prefer_initializing_formals

  final Future<AppVersionInfo> Function() _versionSource;

  AppVersionInfo? _versionInfo;
  AppVersionInfo? get versionInfo => _versionInfo;

  Future<void> load() async {
    try {
      _versionInfo = await _versionSource();
    } catch (_) {
      _versionInfo = null;
    }
    notifyListeners();
  }
}
