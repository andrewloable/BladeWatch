import 'package:flutter_test/flutter_test.dart';

import 'fake_platform_channel.dart';

void main() {
  group('FakePlatformChannel', () {
    test('returns the stubbed response and records the call', () async {
      final channel = FakePlatformChannel();
      channel.stub('daemon', 'ping', {'ok': true});

      final response = await channel.invoke<Map<String, dynamic>>('daemon', 'ping');

      expect(response, {'ok': true});
      expect(channel.calls, hasLength(1));
      expect(channel.calls.single.group, 'daemon');
      expect(channel.calls.single.method, 'ping');
    });

    test('simulates a dead shell call', () async {
      final channel = FakePlatformChannel();
      channel.stubError(
        'daemon',
        'start',
        const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'adb port closed'),
      );

      await expectLater(
        () => channel.invoke<void>('daemon', 'start'),
        throwsA(
          isA<PlatformChannelError>().having(
            (e) => e.reason,
            'reason',
            PlatformChannelErrorReason.shellCallFailed,
          ),
        ),
      );
    });

    test('simulates the daemon not being up yet', () async {
      final channel = FakePlatformChannel();
      channel.stubError(
        'storage',
        'secretGet',
        const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'CameraDaemon not started'),
      );

      await expectLater(
        () => channel.invoke<void>('storage', 'secretGet', 'ipc_token'),
        throwsA(
          isA<PlatformChannelError>().having(
            (e) => e.reason,
            'reason',
            PlatformChannelErrorReason.daemonNotUp,
          ),
        ),
      );
    });

    test('simulates a denied permission', () async {
      final channel = FakePlatformChannel();
      channel.stubError(
        'config',
        'writeSecureSetting',
        const PlatformChannelError(PlatformChannelErrorReason.permissionDenied, 'WRITE_SECURE_SETTINGS'),
      );

      await expectLater(
        () => channel.invoke<void>('config', 'writeSecureSetting'),
        throwsA(
          isA<PlatformChannelError>().having(
            (e) => e.reason,
            'reason',
            PlatformChannelErrorReason.permissionDenied,
          ),
        ),
      );
    });

    test('throws a timeout when stubbed', () async {
      final channel = FakePlatformChannel();
      channel.stubTimeout('logs', 'tail');

      await expectLater(
        () => channel.invoke<void>('logs', 'tail'),
        throwsA(isA<ChannelTimeoutException>()),
      );
    });

    test('throws StateError when nothing was stubbed for that call', () async {
      final channel = FakePlatformChannel();

      await expectLater(
        () => channel.invoke<void>('device', 'getId'),
        throwsA(isA<StateError>()),
      );
    });

    test('the same method name in different groups is stubbed independently', () async {
      // "ping" style overlap: two groups could plausibly define a similarly
      // named method — group must be part of the key, not just method.
      final channel = FakePlatformChannel();
      channel.stub('auth', 'invalidate', {'ok': true});
      channel.stubError(
        'daemon',
        'invalidate',
        const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'no such command'),
      );

      expect(await channel.invoke<Map<String, dynamic>>('auth', 'invalidate'), {'ok': true});
      await expectLater(
        () => channel.invoke<void>('daemon', 'invalidate'),
        throwsA(isA<PlatformChannelError>()),
      );
    });
  });
}
