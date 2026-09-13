import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_models.dart';
import 'package:bladewatch_ui/shell/drive_side.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late ShellController shellController;

  SettingsAppearanceController build() => SettingsAppearanceController(
        prefs: PrefsChannel(channel),
        shellController: shellController,
      );

  setUp(() {
    channel = FakePlatformChannel();
    shellController = ShellController();
  });

  group('load()', () {
    test('defaults to system theme and left drive side when nothing is stored', () async {
      channel.stub('prefs', 'getThemeMode', null);
      channel.stub('prefs', 'getDriveSide', null);
      final c = build();

      await c.load();

      expect(c.themeMode, AppThemeMode.system);
      expect(shellController.driveSide, DriveSide.left);
    });

    test('restores a stored theme mode and drive side', () async {
      channel.stub('prefs', 'getThemeMode', 'dark');
      channel.stub('prefs', 'getDriveSide', 'right');
      final c = build();

      await c.load();

      expect(c.themeMode, AppThemeMode.dark);
      expect(shellController.driveSide, DriveSide.right);
    });

    test('a channel failure leaves defaults in place rather than crashing', () async {
      channel.stubError('prefs', 'getThemeMode', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'x'));
      channel.stubError('prefs', 'getDriveSide', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'x'));
      final c = build();

      await c.load();

      expect(c.themeMode, AppThemeMode.system);
      expect(shellController.driveSide, DriveSide.left);
    });
  });

  group('setThemeMode()', () {
    test('updates state, notifies, and persists the new value', () async {
      channel.stub('prefs', 'setThemeMode', null);
      final c = build();
      var notified = 0;
      c.addListener(() => notified++);

      await c.setThemeMode(AppThemeMode.light);

      expect(c.themeMode, AppThemeMode.light);
      expect(notified, 1);
      final call = channel.calls.single;
      expect(call.method, 'setThemeMode');
      expect((call.args as Map)['value'], 'light');
    });

    test('persists "dark"', () async {
      channel.stub('prefs', 'setThemeMode', null);
      final c = build();
      await c.setThemeMode(AppThemeMode.dark);
      expect((channel.calls.single.args as Map)['value'], 'dark');
    });

    test('persists "system"', () async {
      channel.stub('prefs', 'setThemeMode', null);
      final c = build();
      await c.setThemeMode(AppThemeMode.system);
      expect((channel.calls.single.args as Map)['value'], 'system');
    });
  });

  group('setDriveSide()', () {
    test('updates the shell controller and persists the new value', () async {
      channel.stub('prefs', 'setDriveSide', null);
      final c = build();

      await c.setDriveSide(DriveSide.auto);

      expect(shellController.driveSide, DriveSide.auto);
      expect(c.driveSide, DriveSide.auto);
      final call = channel.calls.single;
      expect(call.method, 'setDriveSide');
      expect((call.args as Map)['value'], 'auto');
    });

    test('persists "left"', () async {
      channel.stub('prefs', 'setDriveSide', null);
      final c = build();
      await c.setDriveSide(DriveSide.left);
      expect((channel.calls.single.args as Map)['value'], 'left');
    });

    test('persists "right"', () async {
      channel.stub('prefs', 'setDriveSide', null);
      final c = build();
      await c.setDriveSide(DriveSide.right);
      expect((channel.calls.single.args as Map)['value'], 'right');
      expect(c.railOnRight, isTrue);
    });
  });
}
