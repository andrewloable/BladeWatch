import 'package:flutter/foundation.dart';

import 'drive_side.dart';

/// Pure-Dart shell state: which rail destination is selected and which side
/// of the screen the rail sits on. No Flutter widget imports — mirrors the
/// native Controller pattern (e.g. `VehicleController`,
/// `TripsController`): a plain state holder the widget layer renders and
/// forwards intent to, never the other way around.
class ShellController extends ChangeNotifier {
  ShellController({
    DriveSide initialDriveSide = DriveSide.left,
    bool Function() detectVehicleRailOnRight = _defaultDetect,
    String initialRoute = 'dashboard',
  })  : _driveSide = initialDriveSide,
        // ignore: prefer_initializing_formals
        _detectVehicleRailOnRight = detectVehicleRailOnRight,
        _selectedRoute = initialRoute;

  // BYD vehicle detection is only reachable from the main APK today (see
  // DriveSide's doc comment) — the safe default mirrors applyDriveSide()'s
  // own catch-all: assume left-hand-drive (rail on the left) until a real
  // detector is wired in.
  static bool _defaultDetect() => false;

  DriveSide _driveSide;
  final bool Function() _detectVehicleRailOnRight;
  String _selectedRoute;

  DriveSide get driveSide => _driveSide;
  String get selectedRoute => _selectedRoute;

  /// Mirrors `applyDriveSide()`'s pref resolution: "right" is always on the
  /// right, "auto" defers to vehicle detection, everything else (including
  /// "left") is on the left.
  bool get railOnRight => switch (_driveSide) {
        DriveSide.right => true,
        DriveSide.auto => _detectVehicleRailOnRight(),
        DriveSide.left => false,
      };

  void setDriveSide(DriveSide side) {
    if (side == _driveSide) return;
    _driveSide = side;
    notifyListeners();
  }

  void selectRoute(String routeName) {
    if (routeName == _selectedRoute) return;
    _selectedRoute = routeName;
    notifyListeners();
  }
}
