import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../platform/prefs_channel.dart';
import '../../platform/setup_channel.dart';
import '../settings/settings_about_controller.dart' show AppVersionInfo;

/// First-launch / post-update setup guide — BladeWatch-yz1e.11. Ground
/// truth: `SetupGuideDialog.java`. Two guided steps beyond the language
/// picker (already built elsewhere): auto-start and overlay permission,
/// both launched via [SetupChannel]. The "seen" marker persists via
/// [PrefsChannel] (per-installation, this APK's own — see its doc comment
/// for why it isn't `PackageInfo.lastUpdateTime` as native uses).
///
/// [versionSource] mirrors [SettingsAboutController]'s own injection shape —
/// this app's version/build come from the widget layer via
/// `package_info_plus`, not this controller, so it needs no platform-channel
/// mocking of its own beyond [prefs]/[setup].
class SetupGuideController extends ChangeNotifier {
  SetupGuideController({
    required PrefsChannel prefs,
    required SetupChannel setup,
    required Future<AppVersionInfo> Function() versionSource,
  })  : _prefs = prefs, // ignore: prefer_initializing_formals
        _setup = setup, // ignore: prefer_initializing_formals
        _versionSource = versionSource; // ignore: prefer_initializing_formals

  final PrefsChannel _prefs;
  final SetupChannel _setup;
  final Future<AppVersionInfo> Function() _versionSource;

  /// Non-null only after an update (a build change from a previously-seen
  /// one) — the version banner shows only then, matching native's own
  /// `isUpdate` flag.
  String? _updatedToVersion;
  String? get updatedToVersion => _updatedToVersion;

  /// Whether the guide should be shown automatically on this launch — ground
  /// truth: `SetupGuideDialog.showIfNeeded()`. Does not itself decide
  /// whether to show a force-opened guide (Settings' "show setup guide
  /// again" row always shows it, matching native's `show(context)`).
  /// A platform-channel failure (e.g. called before the engine has finished
  /// registering the channel) is treated as "nothing to show" rather than
  /// propagating — this call has no daemon dependency and normally resolves
  /// near-instantly, but [main.dart]'s auto-show path runs from a
  /// post-frame callback outside any user gesture, so nothing downstream
  /// is positioned to usefully handle a thrown error either. Not showing an
  /// onboarding dialog on a transient failure is the safe default; a
  /// force-open from Settings gets another chance regardless.
  Future<bool> checkIfNeeded() async {
    try {
      final info = await _versionSource();
      final lastSeen = await _prefs.getSetupGuideLastSeenBuild();
      final bool shouldShow;
      if (lastSeen == null) {
        _updatedToVersion = null;
        shouldShow = true;
      } else if (lastSeen == info.buildNumber) {
        _updatedToVersion = null;
        shouldShow = false;
      } else {
        _updatedToVersion = info.version;
        shouldShow = true;
      }
      notifyListeners();
      return shouldShow;
    } catch (_) {
      _updatedToVersion = null;
      return false;
    }
  }

  /// Records this build as seen — ground truth: `markCurrentInstallSeen()`,
  /// called from "Done" only, not "Remind me later" (native: a soft nag that
  /// must reappear next launch until the user explicitly finishes the
  /// guide).
  Future<void> markSeen() async {
    final info = await _versionSource();
    await _prefs.setSetupGuideLastSeenBuild(info.buildNumber);
  }

  Future<void> openAutoStartSettings() => _setup.openAutoStartSettings();

  Future<void> openOverlaySettings() => _setup.openOverlaySettings();
}
