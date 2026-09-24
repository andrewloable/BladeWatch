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
          'TOR_TUNNEL': false,
        },
      };
      final fake = FakePlatformChannel()..stub('daemon', 'processStatus', raw);

      final result = await DaemonChannel(fake).processStatus();

      expect(fake.calls.single.method, 'processStatus');
      expect(result, {
        'CAMERA_DAEMON': true,
        'SENTRY_DAEMON': false,
        'ACC_SENTRY_DAEMON': false,
        'TOR_TUNNEL': false,
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

    // A v3 onion address: 56 base32 chars. Obviously fake — never put a real one in
    // a fixture, it is a capability granting network access to a real car.
    const onion = 'http://abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx.onion';

    test('pearStatus reads reachability, connected devices and the last connection', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'pearStatus', <Object?, Object?>{
          'status': 'ok',
          'running': true,
          'enabled': true,
          'reachable': true,
          'companions': 2,
          'lastCompanionAt': 1700000000000,
        });
      final s = await DaemonChannel(fake).pearStatus();
      expect(fake.calls.single.method, 'pearStatus');
      expect(s.running, isTrue);
      expect(s.enabled, isTrue);
      expect(s.reachable, isTrue);
      expect(s.devicesConnected, 2);
      expect(s.lastConnection, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('pearStatus keeps unknown reachability unknown, and tolerates a sparse reply', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'pearStatus', <Object?, Object?>{'status': 'ok', 'reachable': null, 'lastCompanionAt': null});
      final s = await DaemonChannel(fake).pearStatus();
      expect(s.reachable, isNull, reason: 'null means "cannot tell", never "not reachable"');
      expect(s.running, isFalse);
      expect(s.enabled, isFalse);
      expect(s.devicesConnected, 0);
      expect(s.lastConnection, isNull);
      expect(PearStatus.unknown.reachable, isNull);
    });

    test('tunnelStatus reports the onion URL the daemon publishes', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{
          'status': 'ok',
          'running': true,
          'url': onion,
        });

      final status = await DaemonChannel(fake).tunnelStatus();

      expect(status.running, isTrue);
      expect(status.url, onion);
      expect(fake.calls.single.method, 'tunnelStatus');
    });

    test('tunnelStatus keeps running=true with no URL distinct from offline', () async {
      // THE state this type exists for. tor writes its hostname file a second after
      // first launch but takes ~82 s to reach the network on a cold start, so the
      // daemon withholds the URL until it has bootstrapped. Collapsing this into
      // "offline" would show "no tunnel" for a minute and a half while one starts.
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{'status': 'ok', 'running': true, 'url': null});

      final status = await DaemonChannel(fake).tunnelStatus();

      expect(status.running, isTrue);
      expect(status.url, isNull);
    });

    test('tunnelStatus reports not running when no tunnel is up', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{'status': 'ok', 'running': false, 'url': null});

      final status = await DaemonChannel(fake).tunnelStatus();

      expect(status.running, isFalse);
      expect(status.url, isNull);
    });

    test('tunnelStatus treats an empty URL string as no URL', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{'status': 'ok', 'running': true, 'url': ''});

      expect((await DaemonChannel(fake).tunnelStatus()).url, isNull);
    });

    test('tunnelStatus defaults running to false when the daemon omits it', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'tunnelStatus', <Object?, Object?>{'status': 'ok'});

      final status = await DaemonChannel(fake).tunnelStatus();

      expect(status.running, isFalse);
      expect(status.url, isNull);
    });

    test('setDaemonEnabled sends the native key and the flag, and reports success', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'setEnabled', <Object?, Object?>{'status': 'ok', 'enabled': true, 'killed': 0});

      expect(await DaemonChannel(fake).setDaemonEnabled('TOR_TUNNEL', true), isTrue);
      expect(fake.calls.single.method, 'setEnabled');
      expect(fake.calls.single.args, {'type': 'TOR_TUNNEL', 'enabled': true});
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
