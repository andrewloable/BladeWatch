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
}
