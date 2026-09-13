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

    test('getAccessCode calls auth.getAccessCode and returns the raw secret', () async {
      final fake = FakePlatformChannel()..stub('auth', 'getAccessCode', 'shh-fake-secret');
      final result = await AuthChannel(fake).getAccessCode();

      expect(result, 'shh-fake-secret');
      expect(fake.calls.single.method, 'getAccessCode');
    });

    test('getAccessCode returns null when the auth section is unavailable', () async {
      final fake = FakePlatformChannel()..stub('auth', 'getAccessCode', null);
      expect(await AuthChannel(fake).getAccessCode(), isNull);
    });

    test('regenerateAccessCode calls auth.regenerateAccessCode and returns the new code', () async {
      final fake = FakePlatformChannel()..stub('auth', 'regenerateAccessCode', 'new-code-value');
      final result = await AuthChannel(fake).regenerateAccessCode();

      expect(result, 'new-code-value');
      expect(fake.calls.single.method, 'regenerateAccessCode');
    });

    test('regenerateAccessCode returns null when the daemon rejected the write', () async {
      final fake = FakePlatformChannel()..stub('auth', 'regenerateAccessCode', null);
      expect(await AuthChannel(fake).regenerateAccessCode(), isNull);
    });

    test('setCustomAccessCode sends the password and returns success', () async {
      final fake = FakePlatformChannel()..stub('auth', 'setCustomAccessCode', true);
      final result = await AuthChannel(fake).setCustomAccessCode('my-custom-password-1');

      expect(result, isTrue);
      expect(fake.calls.single.method, 'setCustomAccessCode');
      expect(fake.calls.single.args, {'password': 'my-custom-password-1'});
    });

    test('setCustomAccessCode returns false when rejected', () async {
      final fake = FakePlatformChannel()..stub('auth', 'setCustomAccessCode', false);
      expect(await AuthChannel(fake).setCustomAccessCode('short'), isFalse);
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

    test('propagates a PlatformChannelError from regenerateAccessCode', () async {
      final fake = FakePlatformChannel()
        ..stubError(
          'auth',
          'regenerateAccessCode',
          const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'),
        );

      await expectLater(() => AuthChannel(fake).regenerateAccessCode(), throwsA(isA<PlatformChannelError>()));
    });
  });
}
