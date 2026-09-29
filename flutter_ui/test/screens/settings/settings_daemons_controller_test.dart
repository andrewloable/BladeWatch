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
        setDaemonEnabled: setDaemonEnabled,
      );

  setUp(() {
    channel = FakePlatformChannel();
  });

  group('load()', () {
    test('populates all 4 daemon rows from daemon.processStatus', () async {
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': true, 'PEAR_PEER': true},
      });
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.rows, hasLength(4));
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.pearPeer).running, isTrue);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.camera).running, isTrue);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.sentry).running, isFalse);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.accSentry).running, isTrue);
    });

    test('a channel failure reports all 4 daemons as stopped rather than crashing', () async {
      channel.stubError('daemon', 'processStatus', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.rows, hasLength(4));
      expect(c.rows.every((r) => !r.running), isTrue);
    });

    test('reads the Pear status, and its failure leaves the rows alone', () async {
      channel
        ..stub('daemon', 'processStatus', {'daemons': {'PEAR_PEER': true}})
        ..stub('daemon', 'pearStatus', {'running': true, 'enabled': true, 'reachable': false, 'companions': 1});
      final c = build();
      await c.load();
      expect(c.pear.reachable, isFalse);
      expect(c.pear.devicesConnected, 1);

      channel.stubError('daemon', 'pearStatus', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
      await c.load();
      expect(c.pear.reachable, isNull);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.pearPeer).running, isTrue);
    });
  });

  group('toggle()', () {
    test('with no start/stop capability injected, returns false and does not change state', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
      final c = build();
      await c.load();

      final ok = await c.toggle(DaemonKind.pearPeer, true);

      expect(ok, isFalse);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.sentry).running, isFalse);
    });

    test('with an injected capability, a successful toggle reloads and reflects the new state', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
      final c = build(setDaemonEnabled: (kind, enabled) async => true);
      await c.load();
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': true},
      });

      final ok = await c.toggle(DaemonKind.pearPeer, true);

      expect(ok, isTrue);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.pearPeer).running, isTrue);
    });

    // BladeWatch-abcx: only the remote-access daemon (the Pear peer) is
    // toggleable. The other three are refused HERE, without an IPC call, because the
    // reasons are structural — see DaemonKind.canToggle.
    test('a non-toggleable daemon is refused without calling the capability at all', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'PEAR_PEER': false},
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
      expect(c.rows.every((r) => r.kind.canToggle || r.running), isTrue,
          reason: 'the refused daemons must be left running');
    });

    test('the Pear peer is toggleable', () async {
      channel.stub('daemon', 'processStatus', {'daemons': {'PEAR_PEER': false}});
      final toggled = <(DaemonKind, bool)>[];
      final c = build(setDaemonEnabled: (kind, enabled) async {
        toggled.add((kind, enabled));
        return true;
      });
      await c.load();

      expect(DaemonKind.pearPeer.canToggle, isTrue);
      expect(await c.toggle(DaemonKind.pearPeer, true), isTrue);
      expect(toggled, [(DaemonKind.pearPeer, true)]);
    });

    test('a capability that returns false leaves state as-is', () async {
      channel.stub('daemon', 'processStatus', {
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
      final c = build(setDaemonEnabled: (kind, enabled) async => false);
      await c.load();

      final ok = await c.toggle(DaemonKind.pearPeer, true);

      expect(ok, isFalse);
      expect(c.rows.firstWhere((r) => r.kind == DaemonKind.sentry).running, isFalse);
    });
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
        ['CAMERA_DAEMON', 'SENTRY_DAEMON', 'ACC_SENTRY_DAEMON', 'PEAR_PEER'],
      );
    });

    test('passes the flag through and reports what the daemon answered', () async {
      final fake = FakePlatformChannel()
        ..stub('daemon', 'setEnabled', <Object?, Object?>{'status': 'error'});
      final setter = SettingsDaemonsController.enabledSetterFor(DaemonChannel(fake));

      expect(await setter(DaemonKind.pearPeer, false), isFalse);
      expect((fake.calls.single.args as Map)['enabled'], false);
    });
  });
}
