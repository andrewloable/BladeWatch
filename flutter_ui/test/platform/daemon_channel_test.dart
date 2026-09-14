import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  group('DaemonChannel', () {
    test('start calls daemon.start and returns the response as a String-keyed map', () async {
      final fake = FakePlatformChannel()..stub('daemon', 'start', {'status': 'ok'});
      final result = await DaemonChannel(fake).start();

      expect(result, {'status': 'ok'});
      expect(fake.calls.single.group, 'daemon');
      expect(fake.calls.single.method, 'start');
    });

    test('stop calls daemon.stop', () async {
      final fake = FakePlatformChannel()..stub('daemon', 'stop', <String, dynamic>{});
      await DaemonChannel(fake).stop();
      expect(fake.calls.single.method, 'stop');
    });

    test('status calls daemon.status and converts a non-String-keyed map (as the real channel returns)', () async {
      // Object?-keyed map — exactly what MethodChannel's standard codec
      // hands back for a Kotlin Map, not the Map<String, dynamic> a fake
      // test might casually stub.
      final Map<Object?, Object?> raw = {'recording': true};
      final fake = FakePlatformChannel()..stub('daemon', 'status', raw);

      final result = await DaemonChannel(fake).status();

      expect(result, isA<Map<String, dynamic>>());
      expect(result['recording'], true);
    });

    test('processStatus calls daemon.processStatus and returns a String-to-bool map', () async {
      final Map<Object?, Object?> raw = {
        'status': 'ok',
        'daemons': <Object?, Object?>{
          'CAMERA_DAEMON': true,
          'SENTRY_DAEMON': false,
          'ACC_SENTRY_DAEMON': false,
          'ZROK_TUNNEL': false,
        },
      };
      final fake = FakePlatformChannel()..stub('daemon', 'processStatus', raw);

      final result = await DaemonChannel(fake).processStatus();

      expect(fake.calls.single.method, 'processStatus');
      expect(result, {
        'CAMERA_DAEMON': true,
        'SENTRY_DAEMON': false,
        'ACC_SENTRY_DAEMON': false,
        'ZROK_TUNNEL': false,
      });
    });

    test('propagates a shellCallFailed PlatformChannelError', () async {
      final fake = FakePlatformChannel()
        ..stubError(
          'daemon',
          'start',
          const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'rejected'),
        );

      await expectLater(() => DaemonChannel(fake).start(), throwsA(isA<PlatformChannelError>()));
    });

    test('propagates a timeout', () async {
      final fake = FakePlatformChannel()..stubTimeout('daemon', 'status');

      await expectLater(() => DaemonChannel(fake).status(), throwsA(isA<ChannelTimeoutException>()));
    });

    test('processStatus propagates a timeout', () async {
      final fake = FakePlatformChannel()..stubTimeout('daemon', 'processStatus');

      await expectLater(() => DaemonChannel(fake).processStatus(), throwsA(isA<ChannelTimeoutException>()));
    });

    test('tunnelUrl returns the share URL the daemon reports', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{
          'status': 'ok',
          'running': true,
          'url': 'https://bladewatch1a2b3c.share.zrok.io',
        });

      expect(await DaemonChannel(fake).tunnelUrl(), 'https://bladewatch1a2b3c.share.zrok.io');
      expect(fake.calls.single.method, 'tunnelStatus');
    });

    test('tunnelUrl returns null when the tunnel is up but has published no URL yet', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{'status': 'ok', 'running': true, 'url': null});

      expect(await DaemonChannel(fake).tunnelUrl(), isNull);
    });

    test('tunnelUrl returns null when no tunnel is running', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{'status': 'ok', 'running': false, 'url': null});

      expect(await DaemonChannel(fake).tunnelUrl(), isNull);
    });

    test('tunnelUrl treats an empty URL string as no tunnel', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{'status': 'ok', 'running': true, 'url': ''});

      expect(await DaemonChannel(fake).tunnelUrl(), isNull);
    });

    test('setDaemonEnabled sends the native key and the flag, and reports success', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'setEnabled', <Object?, Object?>{'status': 'ok', 'enabled': true, 'killed': 0});

      expect(await DaemonChannel(fake).setDaemonEnabled('ZROK_TUNNEL', true), isTrue);
      expect(fake.calls.single.method, 'setEnabled');
      expect(fake.calls.single.args, {'type': 'ZROK_TUNNEL', 'enabled': true});
    });

    test('setDaemonEnabled reports false when the daemon refuses the type', () async {
      // The allow-list is enforced daemon-side; a refusal must not read as success.
      final fake = FakePlatformChannel()
        ..stub('daemon', 'setEnabled',
            <Object?, Object?>{'status': 'error', 'message': 'Daemon not toggleable over IPC: CAMERA_DAEMON'});

      expect(await DaemonChannel(fake).setDaemonEnabled('CAMERA_DAEMON', false), isFalse);
    });
  });
}
