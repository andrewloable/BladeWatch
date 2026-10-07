import 'dart:async';

import 'package:bladewatch_ui/shell/drive_side.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShellController.railOnRight', () {
    test('DriveSide.left is never on the right', () {
      final c = ShellController(initialDriveSide: DriveSide.left, detectVehicleRailOnRight: () => true);
      expect(c.railOnRight, isFalse);
    });

    test('DriveSide.right is always on the right', () {
      final c = ShellController(initialDriveSide: DriveSide.right, detectVehicleRailOnRight: () => false);
      expect(c.railOnRight, isTrue);
    });

    test('DriveSide.auto defers to vehicle detection when it reports right-hand-drive', () {
      final c = ShellController(initialDriveSide: DriveSide.auto, detectVehicleRailOnRight: () => true);
      expect(c.railOnRight, isTrue);
    });

    test('DriveSide.auto defers to vehicle detection when it reports left-hand-drive', () {
      final c = ShellController(initialDriveSide: DriveSide.auto, detectVehicleRailOnRight: () => false);
      expect(c.railOnRight, isFalse);
    });

    test('defaults to left (not on the right) when no detector is supplied, matching the native fallback', () {
      final c = ShellController(initialDriveSide: DriveSide.auto);
      expect(c.railOnRight, isFalse);
    });
  });

  group('ShellController.setDriveSide', () {
    test('changes driveSide and notifies listeners', () {
      final c = ShellController();
      var notified = 0;
      c.addListener(() => notified++);

      c.setDriveSide(DriveSide.right);

      expect(c.driveSide, DriveSide.right);
      expect(c.railOnRight, isTrue);
      expect(notified, 1);
    });

    test('is a no-op when set to the same value already in effect', () {
      final c = ShellController(initialDriveSide: DriveSide.right);
      var notified = 0;
      c.addListener(() => notified++);

      c.setDriveSide(DriveSide.right);

      expect(notified, 0);
    });
  });

  group('ShellController.selectRoute', () {
    test('starts on the given initial route', () {
      final c = ShellController(initialRoute: 'dashboard');
      expect(c.selectedRoute, 'dashboard');
    });

    test('changes selectedRoute and notifies listeners', () {
      final c = ShellController(initialRoute: 'dashboard');
      var notified = 0;
      c.addListener(() => notified++);

      c.selectRoute('trips');

      expect(c.selectedRoute, 'trips');
      expect(notified, 1);
    });

    test('is a no-op when selecting the already-selected route', () {
      final c = ShellController(initialRoute: 'dashboard');
      var notified = 0;
      c.addListener(() => notified++);

      c.selectRoute('dashboard');

      expect(notified, 0);
    });
  });

  // BladeWatch-hr6r: the Settings PIN lock's route gate.
  group('ShellController route guard', () {
    test('a guarded route switches once the guard resolves true', () async {
      final c = ShellController(initialRoute: 'dashboard', guardedRoutes: {'settings'}, routeGuard: (_) async => true);

      await c.selectRoute('settings');

      expect(c.selectedRoute, 'settings');
    });

    test('a guarded route stays put when the guard resolves false', () async {
      final c = ShellController(initialRoute: 'dashboard', guardedRoutes: {'settings'}, routeGuard: (_) async => false);

      await c.selectRoute('settings');

      expect(c.selectedRoute, 'dashboard');
    });

    test('the guard is asked which route is being entered', () async {
      String? asked;
      final c = ShellController(
        initialRoute: 'dashboard',
        guardedRoutes: {'settings', 'surveillance'},
        routeGuard: (route) async {
          asked = route;
          return true;
        },
      );

      await c.selectRoute('surveillance');

      expect(asked, 'surveillance');
    });

    test('routeGuard is a settable field, reassignable after construction', () async {
      final c = ShellController(initialRoute: 'dashboard', guardedRoutes: {'settings'});
      c.routeGuard = (_) async => false;

      await c.selectRoute('settings');
      expect(c.selectedRoute, 'dashboard');

      c.routeGuard = (_) async => true;
      await c.selectRoute('settings');
      expect(c.selectedRoute, 'settings');
    });

    test('no guard set means a guarded route switches unconditionally', () async {
      final c = ShellController(initialRoute: 'dashboard', guardedRoutes: {'settings'});

      await c.selectRoute('settings');

      expect(c.selectedRoute, 'settings');
    });

    test('switching to a non-guarded route calls onLeaveGuardedRoute', () async {
      var relocked = 0;
      final c = ShellController(
        initialRoute: 'dashboard',
        guardedRoutes: {'settings'},
        onLeaveGuardedRoute: () => relocked++,
      );

      await c.selectRoute('trips');

      expect(c.selectedRoute, 'trips');
      expect(relocked, 1);
    });

    test('moving between two guarded routes does not call onLeaveGuardedRoute', () async {
      var relocked = 0;
      final c = ShellController(
        initialRoute: 'settings',
        guardedRoutes: {'settings', 'surveillance'},
        routeGuard: (_) async => true,
        onLeaveGuardedRoute: () => relocked++,
      );

      await c.selectRoute('surveillance');

      expect(c.selectedRoute, 'surveillance');
      expect(relocked, 0);
    });

    test('a second selectRoute while a guard prompt is already open is ignored', () async {
      final prompts = <Completer<bool>>[];
      final c = ShellController(
        initialRoute: 'dashboard',
        guardedRoutes: {'settings'},
        routeGuard: (_) {
          final completer = Completer<bool>();
          prompts.add(completer);
          return completer.future;
        },
      );

      final first = c.selectRoute('settings'); // starts the (still-pending) guard prompt
      await Future<void>.delayed(Duration.zero);
      final second = c.selectRoute('settings'); // a second tap while it is up: ignored
      expect(prompts, hasLength(1), reason: 'the guard must be asked only once');

      prompts.single.complete(true);
      await first;
      await second;

      expect(c.selectedRoute, 'settings');
    });
  });
}
