import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/platform/config_channel.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  group('ConfigChannel', () {
    test('get sends section and key, and returns the value', () async {
      final fake = FakePlatformChannel()..stub('config', 'get', 'ztok_abc');
      final result = await ConfigChannel(fake).get('tunnels', 'zrokToken');

      expect(result, 'ztok_abc');
      expect(fake.calls.single.group, 'config');
      expect(fake.calls.single.method, 'get');
      expect(fake.calls.single.args, {'section': 'tunnels', 'key': 'zrokToken'});
    });

    test('get returns null when the key is not set', () async {
      final fake = FakePlatformChannel()..stub('config', 'get', null);
      expect(await ConfigChannel(fake).get('tunnels', 'zrokToken'), isNull);
    });

    test('put sends section, key, and value, and returns true', () async {
      final fake = FakePlatformChannel()..stub('config', 'put', true);
      final result = await ConfigChannel(fake).put('tunnels', 'zrokToken', 'new-value');

      expect(result, isTrue);
      expect(fake.calls.single.args, {'section': 'tunnels', 'key': 'zrokToken', 'value': 'new-value'});
    });

    test('delete sends section and key, and returns true', () async {
      final fake = FakePlatformChannel()..stub('config', 'delete', true);
      final result = await ConfigChannel(fake).delete('tunnels', 'zrokToken');

      expect(result, isTrue);
      expect(fake.calls.single.args, {'section': 'tunnels', 'key': 'zrokToken'});
    });

    test('propagates a permissionDenied PlatformChannelError from put', () async {
      final fake = FakePlatformChannel()
        ..stubError(
          'config',
          'put',
          const PlatformChannelError(PlatformChannelErrorReason.permissionDenied, 'nope'),
        );

      await expectLater(
        () => ConfigChannel(fake).put('tunnels', 'zrokToken', 'x'),
        throwsA(isA<PlatformChannelError>()),
      );
    });

    test('propagates a timeout from delete', () async {
      final fake = FakePlatformChannel()..stubTimeout('config', 'delete');

      await expectLater(
        () => ConfigChannel(fake).delete('tunnels', 'zrokToken'),
        throwsA(isA<ChannelTimeoutException>()),
      );
    });
  });
}
