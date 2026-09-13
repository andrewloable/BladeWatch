import '../../shell/drive_side.dart';

/// Ground truth: `SettingsAppearanceFragment.kt`'s theme tile picker. A
/// separate enum from Flutter's own `ThemeMode` (used only by the screen
/// widget) so this pure-Dart controller has no Flutter import.
enum AppThemeMode { system, light, dark }

AppThemeMode themeModeFromPref(String? value) => switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };

String themeModeToPref(AppThemeMode mode) => switch (mode) {
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
      AppThemeMode.system => 'system',
    };

DriveSide driveSideFromPref(String? value) => switch (value) {
      'right' => DriveSide.right,
      'auto' => DriveSide.auto,
      _ => DriveSide.left,
    };

String driveSideToPref(DriveSide side) => switch (side) {
      DriveSide.left => 'left',
      DriveSide.right => 'right',
      DriveSide.auto => 'auto',
    };
