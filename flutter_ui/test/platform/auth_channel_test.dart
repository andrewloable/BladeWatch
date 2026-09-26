import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/platform/auth_channel.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  group('AuthChannel', () {
    test('mintJwt calls auth.mintJwt and returns the token', () async {
      final fake = FakePlatformChannel()..stub('auth', 'mintJwt', 'jwt-value');
      final result = await AuthChannel(fake).mintJwt();

      expect(result, 'jwt-value');
      expect(fake.calls.single.group, 'auth');
      expect(fake.calls.single.method, 'mintJwt');
    });

    test('mintJwt returns null when the native side has none yet', () async {
      final fake = FakePlatformChannel()..stub('auth', 'mintJwt', null);
      expect(await AuthChannel(fake).mintJwt(), isNull);
    });

    test('stateVersion calls auth.stateVersion', () async {
      final fake = FakePlatformChannel()..stub('auth', 'stateVersion', 3);
      expect(await AuthChannel(fake).stateVersion(), 3);
      expect(fake.calls.single.method, 'stateVersion');
    });

    test('invalidate calls auth.invalidate', () async {
      final fake = FakePlatformChannel()..stub('auth', 'invalidate', null);
      await AuthChannel(fake).invalidate();
      expect(fake.calls.single.method, 'invalidate');
    });

    test('propagates a daemonNotUp PlatformChannelError from mintJwt', () async {
      final fake = FakePlatformChannel()
        ..stubError(
          'auth',
          'mintJwt',
          const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'),
        );

      await expectLater(() => AuthChannel(fake).mintJwt(), throwsA(isA<PlatformChannelError>()));
    });

    test('propagates a ChannelTimeoutException from stateVersion', () async {
      final fake = FakePlatformChannel()..stubTimeout('auth', 'stateVersion');

      await expectLater(() => AuthChannel(fake).stateVersion(), throwsA(isA<ChannelTimeoutException>()));
    });
  });
}
