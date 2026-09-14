import 'package:bladewatch_ui/screens/settings/settings_overlay_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('default wiring (no follow-up IPC yet)', () {
    test('load() reports both indicators visible by default', () async {
      final c = SettingsOverlayController();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.cameraVisible, isTrue);
      expect(c.tripVisible, isTrue);
    });

    test('toggling updates in-memory state even though nothing persists yet', () async {
      final c = SettingsOverlayController();
      await c.load();

      await c.setCameraVisible(false);
      await c.setTripVisible(false);

      expect(c.cameraVisible, isFalse);
      expect(c.tripVisible, isFalse);
    });
  });

  group('injected load/persist', () {
    test('load() reflects whatever the injected loader returns', () async {
      final c = SettingsOverlayController(loadSettings: () async => (cameraVisible: false, tripVisible: true));

      await c.load();

      expect(c.cameraVisible, isFalse);
      expect(c.tripVisible, isTrue);
    });

    test('a loader that throws falls back to both visible, not a crash', () async {
      final c = SettingsOverlayController(loadSettings: () async => throw StateError('unavailable'));

      await c.load();

      expect(c.loading, isFalse);
      expect(c.cameraVisible, isTrue);
      expect(c.tripVisible, isTrue);
    });

    test('setCameraVisible calls persist with the camera key and notifies', () async {
      final calls = <(String, bool)>[];
      final c = SettingsOverlayController(persist: (key, value) async => calls.add((key, value)));
      var notified = 0;
      c.addListener(() => notified++);

      await c.setCameraVisible(false);

      expect(calls, [('cameraVisible', false)]);
      expect(notified, 1);
    });

    test('setTripVisible calls persist with the trip key and notifies', () async {
      final calls = <(String, bool)>[];
      final c = SettingsOverlayController(persist: (key, value) async => calls.add((key, value)));

      await c.setTripVisible(false);

      expect(calls, [('tripVisible', false)]);
    });

    // BladeWatch-hygs: persist is now a real IPC write to the daemon, which can
    // be down. A switch that stays flipped after a failed write shows a setting
    // that silently reverts on the next app start.
    test('a failed camera write snaps the switch back and notifies again', () async {
      final c = SettingsOverlayController(persist: (key, value) async => throw StateError('daemon down'));
      var notified = 0;
      c.addListener(() => notified++);

      await c.setCameraVisible(false);

      expect(c.cameraVisible, isTrue, reason: 'the write failed, so the setting did not change');
      expect(notified, 2, reason: 'once optimistically, once on the revert');
    });

    test('a failed trip write snaps the switch back', () async {
      final c = SettingsOverlayController(persist: (key, value) async => throw StateError('daemon down'));

      await c.setTripVisible(false);

      expect(c.tripVisible, isTrue);
    });
  });
}
