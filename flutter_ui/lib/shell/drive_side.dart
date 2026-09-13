/// Mirrors `PreferencesManager.getDriveSide()`'s three values in
/// `app/src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt`'s
/// `applyDriveSide()`. "auto" defers to BYD vehicle detection
/// (`CustomVehicleConfig.isRightDriver()` via reflection on the native
/// side — not reachable from the Flutter APK, so callers inject a
/// `detectVehicleRailOnRight` callback instead; see `ShellController`).
enum DriveSide { left, right, auto }
