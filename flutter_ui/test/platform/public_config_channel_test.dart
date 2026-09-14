import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/platform/public_config_channel.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  group('PublicConfigChannel', () {
    test('getSection sends the section name and types the result', () async {
      final fake = FakePlatformChannel()
        ..stub('publicConfig', 'getSection', <Object?, Object?>{'cameraVisible': true, 'tripVisible': false});

      final section = await PublicConfigChannel(fake).getSection('statusOverlay');

      expect(section, {'cameraVisible': true, 'tripVisible': false});
      expect(fake.calls.single.group, 'publicConfig');
      expect(fake.calls.single.args, {'section': 'statusOverlay'});
    });

    test('getSection returns an empty map when the daemon refuses the section', () async {
      // Distinguishable from "every flag is off" — callers fall back to their
      // own defaults on an empty map rather than showing everything disabled.
      final fake = FakePlatformChannel()..stub('publicConfig', 'getSection', <Object?, Object?>{});
      expect(await PublicConfigChannel(fake).getSection('network'), isEmpty);
    });

    test('putBoolean sends section, key and value', () async {
      final fake = FakePlatformChannel()..stub('publicConfig', 'putBoolean', true);

      expect(await PublicConfigChannel(fake).putBoolean('developerOptions', 'debugLogsEnabled', true), isTrue);
      expect(fake.calls.single.args, {'section': 'developerOptions', 'key': 'debugLogsEnabled', 'value': true});
    });

    test('putBoolean reports false when the daemon refuses the write', () async {
      final fake = FakePlatformChannel()..stub('publicConfig', 'putBoolean', false);
      expect(await PublicConfigChannel(fake).putBoolean('network', 'lanHttpEnabled', true), isFalse);
    });

    test('propagates a daemonNotUp error rather than reporting success', () async {
      final fake = FakePlatformChannel()
        ..stubError(
          'publicConfig',
          'putBoolean',
          const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'daemon down'),
        );

      await expectLater(
        () => PublicConfigChannel(fake).putBoolean('statusOverlay', 'tripVisible', false),
        throwsA(isA<PlatformChannelError>()),
      );
    });
  });
}
