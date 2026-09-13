import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/platform/setup_channel.dart';
import 'package:bladewatch_ui/screens/dialogs/setup_guide_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_about_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late SetupGuideController controller;

  const info = AppVersionInfo(version: '1.2.0', buildNumber: '7', packageName: 'net.bladewatch.flutter');

  setUp(() {
    channel = FakePlatformChannel();
    controller = SetupGuideController(
      prefs: PrefsChannel(channel),
      setup: SetupChannel(channel),
      versionSource: () async => info,
    );
  });

  group('checkIfNeeded', () {
    test('returns true (first launch) when nothing has ever been seen, with no update banner', () async {
      channel.stub('prefs', 'getSetupGuideLastSeenBuild', null);

      expect(await controller.checkIfNeeded(), isTrue);
      expect(controller.updatedToVersion, isNull);
    });

    test('returns false when the current build matches the last-seen build', () async {
      channel.stub('prefs', 'getSetupGuideLastSeenBuild', '7');

      expect(await controller.checkIfNeeded(), isFalse);
      expect(controller.updatedToVersion, isNull);
    });

    test('returns true with the update banner set when the build has changed', () async {
      channel.stub('prefs', 'getSetupGuideLastSeenBuild', '6');

      expect(await controller.checkIfNeeded(), isTrue);
      expect(controller.updatedToVersion, '1.2.0');
    });

    test('notifies listeners', () async {
      channel.stub('prefs', 'getSetupGuideLastSeenBuild', null);
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.checkIfNeeded();

      expect(notified, 1);
    });

    test('a platform-channel failure is treated as "nothing to show", not propagated', () async {
      channel.stubError('prefs', 'getSetupGuideLastSeenBuild', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'x'));

      expect(await controller.checkIfNeeded(), isFalse);
      expect(controller.updatedToVersion, isNull);
    });
  });

  test('markSeen persists the current build number', () async {
    channel.stub('prefs', 'setSetupGuideLastSeenBuild', null);

    await controller.markSeen();

    final call = channel.calls.single;
    expect(call.method, 'setSetupGuideLastSeenBuild');
    expect((call.args as Map)['value'], '7');
  });

  test('openAutoStartSettings delegates to SetupChannel', () async {
    channel.stub('setup', 'openAutoStartSettings', null);
    await controller.openAutoStartSettings();
    expect(channel.calls.single.method, 'openAutoStartSettings');
  });

  test('openOverlaySettings delegates to SetupChannel', () async {
    channel.stub('setup', 'openOverlaySettings', null);
    await controller.openOverlaySettings();
    expect(channel.calls.single.method, 'openOverlaySettings');
  });
}
