import 'package:flutter/foundation.dart';

import '../../platform/prefs_channel.dart';
import '../../shell/drive_side.dart';
import '../../shell/shell_controller.dart';
import 'settings_appearance_models.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Ground truth: `SettingsAppearanceFragment.kt`. Theme mode is this
/// controller's own state; drive side is delegated straight to
/// [ShellController] (the single source of truth Epic 1 already built for
/// rail mirroring) — this controller only adds persistence on top of it.
/// The language picker is opened, not modeled, here — its dialog is
/// BladeWatch-yz1e.11's job; this screen only needs a callback to show it.
class SettingsAppearanceController extends ChangeNotifier with DisposedSafeNotifier {
  SettingsAppearanceController({required PrefsChannel prefs, required ShellController shellController})
      : _prefs = prefs, // ignore: prefer_initializing_formals
        _shellController = shellController; // ignore: prefer_initializing_formals

  final PrefsChannel _prefs;
  final ShellController _shellController;

  AppThemeMode _themeMode = AppThemeMode.system;
  AppThemeMode get themeMode => _themeMode;

  DriveSide get driveSide => _shellController.driveSide;
  bool get railOnRight => _shellController.railOnRight;

  Future<void> load() async {
    try {
      _themeMode = themeModeFromPref(await _prefs.getThemeMode());
    } catch (_) {
      _themeMode = AppThemeMode.system;
    }
    try {
      final storedSide = await _prefs.getDriveSide();
      _shellController.setDriveSide(driveSideFromPref(storedSide));
    } catch (_) {
      // Leave ShellController's own default (left) in place.
    }
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setThemeMode(themeModeToPref(mode));
  }

  Future<void> setDriveSide(DriveSide side) async {
    _shellController.setDriveSide(side);
    notifyListeners();
    await _prefs.setDriveSide(driveSideToPref(side));
  }
}
