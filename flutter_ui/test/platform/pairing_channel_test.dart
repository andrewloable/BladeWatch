import 'package:bladewatch_ui/platform/pairing_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_channel.dart';

/// BladeWatch-rdtj.7: the pairing.* channel group, typed.
void main() {
  test('mint returns the QR text, its expiry and the LAN opt-in', () async {
    final fake = FakePlatformChannel()
      ..stub('pairing', 'mint', <Object?, Object?>{'status': 'ok', 'payload': 'qr-text', 'expiresAt': 1700000300000, 'lanEnabled': true});
    final offer = await PairingChannel(fake).mint();
    expect(offer.payload, 'qr-text');
    expect(offer.expiresAt, DateTime.fromMillisecondsSinceEpoch(1700000300000));
    expect(offer.lanEnabled, isTrue);
    expect(fake.calls.single.method, 'mint');
  });

  test('mint treats a missing LAN flag as off', () async {
    final fake = FakePlatformChannel()..stub('pairing', 'mint', {'payload': 'q', 'expiresAt': 1});
    expect((await PairingChannel(fake).mint()).lanEnabled, isFalse);
  });

  test('list returns the paired devices, oldest first as the daemon sends them', () async {
    final fake = FakePlatformChannel()
      ..stub('pairing', 'list', {
        'companions': [
          <Object?, Object?>{'id': 'a1', 'name': 'Phone', 'pairedAt': 1000},
          <Object?, Object?>{'id': 'b2', 'pairedAt': null},
        ],
      });
    final devices = await PairingChannel(fake).list();
    expect(devices.map((d) => d.id), ['a1', 'b2']);
    expect(devices.first.name, 'Phone');
    expect(devices.first.pairedAt, DateTime.fromMillisecondsSinceEpoch(1000));
    expect(devices.last.name, '');
  });

  test('list copes with no companions key at all', () async {
    final fake = FakePlatformChannel()..stub('pairing', 'list', {'status': 'ok'});
    expect(await PairingChannel(fake).list(), isEmpty);
  });

  test('revoke names the companion', () async {
    final fake = FakePlatformChannel()..stub('pairing', 'revoke', {'status': 'ok'});
    await PairingChannel(fake).revoke('a1');
    expect(fake.calls.single.args, {'id': 'a1'});
  });

  test('setLanAccess returns the setting now in force', () async {
    final fake = FakePlatformChannel()..stub('pairing', 'setLanAccess', {'status': 'ok', 'enabled': false});
    expect(await PairingChannel(fake).setLanAccess(true), isFalse);
    expect(fake.calls.single.args, {'enabled': true});
  });

  test('setLanAccess falls back to the request when the reply omits it', () async {
    final fake = FakePlatformChannel()..stub('pairing', 'setLanAccess', {'status': 'ok'});
    expect(await PairingChannel(fake).setLanAccess(true), isTrue);
  });
}
