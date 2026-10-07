import 'package:flutter/foundation.dart';

import 'disposed_safe_notifier.dart';
import 'drive_side.dart';

/// Pure-Dart shell state: which rail destination is selected and which side
/// of the screen the rail sits on. No Flutter widget imports — mirrors the
/// native Controller pattern (e.g. `VehicleController`,
/// `TripsController`): a plain state holder the widget layer renders and
/// forwards intent to, never the other way around.
///
/// [guardedRoutes]/[routeGuard]/[onLeaveGuardedRoute] (BladeWatch-hr6r) let
/// `main.dart` wire the Settings PIN lock in without this class importing
/// anything Flutter-widget-shaped: it knows route names only as bare
/// strings, never `BwRoutes` itself (that file pulls in `material.dart` for
/// `StubScreen`, which this class's own "no Flutter widget imports" rule
/// above predates and still means). [routeGuard] is public and mutable,
/// not constructor-only, because the one that needs a `BuildContext` to
/// show a PIN dialog can only be built fresh inside `build()` — this
/// controller, unlike the widget tree, is constructed once and lives for
/// the app's whole lifetime, so `main.dart` reassigns it every build rather
/// than capturing a `context` that could go stale.
class ShellController extends ChangeNotifier with DisposedSafeNotifier {
  ShellController({
    DriveSide initialDriveSide = DriveSide.left,
    bool Function() detectVehicleRailOnRight = _defaultDetect,
    String initialRoute = 'dashboard',
    Set<String> guardedRoutes = const {},
    this.routeGuard,
    VoidCallback? onLeaveGuardedRoute,
  })  : _driveSide = initialDriveSide,
        // ignore: prefer_initializing_formals
        _detectVehicleRailOnRight = detectVehicleRailOnRight,
        _selectedRoute = initialRoute,
        // ignore: prefer_initializing_formals
        _guardedRoutes = guardedRoutes,
        // ignore: prefer_initializing_formals
        _onLeaveGuardedRoute = onLeaveGuardedRoute;

  // BYD vehicle detection is only reachable from the main APK today (see
  // DriveSide's doc comment) — the safe default mirrors applyDriveSide()'s
  // own catch-all: assume left-hand-drive (rail on the left) until a real
  // detector is wired in.
  static bool _defaultDetect() => false;

  DriveSide _driveSide;
  final bool Function() _detectVehicleRailOnRight;
  String _selectedRoute;
  final Set<String> _guardedRoutes;

  /// Asked for every [_guardedRoutes] entry before `selectRoute` actually switches to it. See
  /// the class doc for why this is a settable field rather than a constructor-only one.
  Future<bool> Function(String route)? routeGuard;
  final VoidCallback? _onLeaveGuardedRoute;

  /// True while a guard prompt (the PIN dialog) is already open — a second tap on the same or
  /// another guarded destination while it is up is ignored rather than stacking a second one.
  bool _guardPending = false;

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

  /// Switches the stage to [routeName]. Synchronous for any unguarded route (every call site
  /// still works unawaited, exactly as before this method started returning a `Future`) — the
  /// `await` below is only ever reached for [_guardedRoutes].
  Future<void> selectRoute(String routeName) async {
    if (routeName == _selectedRoute || _guardPending) return;
    final guard = routeGuard;
    if (_guardedRoutes.contains(routeName) && guard != null) {
      _guardPending = true;
      final allowed = await guard(routeName);
      _guardPending = false;
      if (!allowed) return;
    } else {
      _onLeaveGuardedRoute?.call();
    }
    _selectedRoute = routeName;
    notifyListeners();
  }
}
