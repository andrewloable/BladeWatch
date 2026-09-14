import 'package:bladewatch_ui/platform/config_channel.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/screens/settings/settings_daemons_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_daemons_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;

  SettingsDaemonsController build({Future<bool> Function(DaemonKind, bool)? setDaemonEnabled}) =>
      SettingsDaemonsController(
        daemonChannel: DaemonChannel(channel),
        configChannel: ConfigChannel(channel),
        setDaemonEnabled: setDaemonEnabled,
      );

  setUp(() {
    channel = FakePlatformChannel();
  });

  group('load()', () {
    test('populates all 4 daemon rows from daemon.processStatus', () async {
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': true, 'ZROK_TUNNEL': false},
      });
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.rows, hasLength(4));
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.camera).running, isTrue);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.sentry).running, isFalse);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.accSentry).running, isTrue);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.zrokTunnel).running, isFalse);
    });

    test('a channel failure reports all 4 daemons as stopped rather than crashing', () async {
      channel.stubError('daemon', 'processStatus', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.rows, hasLength(4));
      expect(c.rows.every((r) => !r.running), isTrue);
    });
  });

  group('toggle()', () {
    test('with no start/stop capability injected, returns false and does not change state', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      final c = build();
      await c.load();

      final ok = await c.toggle(DaemonKind.zrokTunnel, true);

      expect(ok, isFalse);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.sentry).running, isFalse);
    });

    test('with an injected capability, a successful toggle reloads and reflects the new state', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      final c = build(setDaemonEnabled: (kind, enabled) async => true);
      await c.load();
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': true},
      });

      final ok = await c.toggle(DaemonKind.zrokTunnel, true);

      expect(ok, isTrue);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.zrokTunnel).running, isTrue);
    });

    // BladeWatch-abcx: only the Zrok tunnel is toggleable. The other three are
    // refused HERE, without an IPC call, because the reasons are structural — see
    // DaemonKind.canToggle.
    test('a non-toggleable daemon is refused without calling the capability at all', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'ZROK_TUNNEL': false},
      });
      var called = 0;
      final c = build(setDaemonEnabled: (kind, enabled) async {
        called++;
        return true;
      });
      await c.load();

      for (final kind in [DaemonKind.camera, DaemonKind.sentry, DaemonKind.accSentry]) {
        expect(await c.toggle(kind, false), isFalse, reason: '${kind.nativeKey} must be refused');
      }

      expect(called, 0, reason: 'no IPC round trip for a fact this process already knows');
      expect(c.rows.every((r) => r.kind == DaemonKind.zrokTunnel || r.running), isTrue,
          reason: 'the refused daemons must be left running');
    });

    test('a capability that returns false leaves state as-is', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      final c = build(setDaemonEnabled: (kind, enabled) async => false);
      await c.load();

      final ok = await c.toggle(DaemonKind.zrokTunnel, true);

      expect(ok, isFalse);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.sentry).running, isFalse);
    });
  });

  group('Zrok token management (config.* channel)', () {
    test('getZrokToken reads the zrok/enableToken key', () async {
      channel.stub('config', 'get', 'my-token');
      final c = build();

      final token = await c.getZrokToken();

      expect(token, 'my-token');
      final call = channel.calls.single;
      expect((call.args as Map)['section'], 'zrok');
      expect((call.args as Map)['key'], 'enableToken');
    });

    test('saveZrokToken writes the zrok/enableToken key', () async {
      channel.stub('config', 'put', true);
      final c = build();

      final ok = await c.saveZrokToken('new-token');

      expect(ok, isTrue);
      final call = channel.calls.single;
      expect((call.args as Map)['section'], 'zrok');
      expect((call.args as Map)['key'], 'enableToken');
      expect((call.args as Map)['value'], 'new-token');
    });

    test('deleteZrokToken deletes the zrok/enableToken key', () async {
      channel.stub('config', 'delete', true);
      final c = build();

      final ok = await c.deleteZrokToken();

      expect(ok, isTrue);
      final call = channel.calls.single;
      expect((call.args as Map)['section'], 'zrok');
      expect((call.args as Map)['key'], 'enableToken');
    });
  });

  group('resetZrokEnvironment()', () {
    test('stops the tunnel (when a capability is injected) and deletes the token', () async {
      final stopCalls = <DaemonKind>[];
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': true},
      });
      channel.stub('config', 'delete', true);
      final c = build(setDaemonEnabled: (kind, enabled) async {
        stopCalls.add(kind);
        return true;
      });
      await c.load();

      final ok = await c.resetZrokEnvironment();

      expect(ok, isTrue);
      expect(stopCalls, [DaemonKind.zrokTunnel]);
      final deleteCall = channel.calls.firstWhere((c) => c.method == 'delete');
      expect((deleteCall.args as Map)['section'], 'zrok');
    });

    test('still deletes the token even when no stop capability is available', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('config', 'delete', true);
      final c = build();
      await c.load();

      final ok = await c.resetZrokEnvironment();

      expect(ok, isTrue);
    });

    test('reports failure when the token delete itself fails', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('config', 'delete', false);
      final c = build();
      await c.load();

      final ok = await c.resetZrokEnvironment();

      expect(ok, isFalse);
    });

  group('enabledSetterFor()', () {
    test('maps each DaemonKind to the exact enum string the daemon expects', () async {
      // The daemon matches the type against a fixed allow-list by exact string, so a
      // drifting key here would read as "not toggleable" rather than failing loudly.
      final fake = FakePlatformChannel()
        ..stub('daemon', 'setEnabled', <Object?, Object?>{'status': 'ok'});
      final setter = SettingsDaemonsController.enabledSetterFor(DaemonChannel(fake));

      for (final kind in DaemonKind.values) {
        await setter(kind, true);
      }

      expect(
        fake.calls.map((c) => (c.args as Map)['type']).toList(),
        ['CAMERA_DAEMON', 'SENTRY_DAEMON', 'ACC_SENTRY_DAEMON', 'ZROK_TUNNEL'],
      );
    });

    test('passes the flag through and reports what the daemon answered', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'setEnabled', <Object?, Object?>{'status': 'error'});
      final setter = SettingsDaemonsController.enabledSetterFor(DaemonChannel(fake));

      expect(await setter(DaemonKind.zrokTunnel, false), isFalse);
      expect((fake.calls.single.args as Map)['enabled'], false);
    });
  });
  });
}
