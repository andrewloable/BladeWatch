import 'package:bladewatch_ui/platform/pairing_channel.dart';
import 'package:bladewatch_ui/screens/pairing/pairing_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

/// BladeWatch-rdtj.7: the in-car pairing dialog's state.
void main() {
  late FakePlatformChannel fake;
  late DateTime now;
  late PairingController controller;

  setUp(() {
    now = DateTime(2026, 9, 24, 12);
    fake = FakePlatformChannel()
      ..stub('pairing', 'mint', {'payload': 'qr', 'expiresAt': now.add(const Duration(minutes: 5)).millisecondsSinceEpoch, 'lanEnabled': true})
      ..stub('pairing', 'list', {'companions': []});
    controller = PairingController(PairingChannel(fake), now: () => now);
  });

  test('start mints a code and loads the paired devices', () async {
    await controller.start();
    expect(controller.offer?.payload, 'qr');
    expect(controller.lanEnabled, isTrue);
    expect(controller.devices, isEmpty);
    expect(controller.mintFailed, isFalse);
  });

  test('counts down and then reports expiry', () async {
    await controller.start();
    expect(controller.remaining, const Duration(minutes: 5));
    expect(controller.expired, isFalse);
    now = now.add(const Duration(minutes: 5, seconds: 1));
    expect(controller.remaining, Duration.zero);
    expect(controller.expired, isTrue);
  });

  test('nothing has expired before a code exists', () {
    expect(controller.remaining, Duration.zero);
    expect(controller.expired, isFalse);
  });

  test('a failed mint stays reported even when the device list loads fine', () async {
    fake.stubError('pairing', 'mint', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
    await controller.start();
    expect(controller.mintFailed, isTrue, reason: 'a later successful list must not hide the failure');
    expect(controller.actionFailed, isFalse);
    fake.stub('pairing', 'mint', {'payload': 'qr2', 'expiresAt': 0});
    await controller.newCode();
    expect(controller.mintFailed, isFalse);
    expect(controller.offer?.payload, 'qr2');
  });

  test('a failed action is reported, and the next success clears it', () async {
    fake.stubError('pairing', 'revoke', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
    await controller.remove('a');
    expect(controller.actionFailed, isTrue);
    await controller.refreshDevices();
    expect(controller.actionFailed, isFalse);
  });

  test('remove revokes and refreshes the list', () async {
    fake
      ..stub('pairing', 'revoke', {'status': 'ok'})
      ..stub('pairing', 'list', {
        'companions': [<Object?, Object?>{'id': 'b', 'name': 'Tablet', 'pairedAt': 1}],
      });
    await controller.remove('a');
    expect(fake.calls.map((c) => c.method), ['revoke', 'list']);
    expect(controller.devices.single.name, 'Tablet');
  });

  test('the LAN switch shows what the daemon reports', () async {
    fake.stub('pairing', 'setLanAccess', {'enabled': true});
    await controller.setLanAccess(true);
    expect(controller.lanEnabled, isTrue);
  });

  // BladeWatch 1.4.1.2: a device without a camera pairing over Wi-Fi with a matching number.
  test('Wi-Fi pairing: polling keeps it open and brings up the request waiting for the owner', () async {
    fake
      ..stub('pairing', 'wifiWindow', {'status': 'ok', 'lanEnabled': true})
      ..stub('pairing', 'wifiPending', {
        'status': 'ok',
        'request': <Object?, Object?>{'id': 'r1', 'name': 'Living room TV', 'number': '482913'},
      })
      ..stub('pairing', 'wifiDecide', {'status': 'ok'});
    await controller.pollWifi();
    expect(fake.calls.first.args, {'open': true});
    expect(controller.lanEnabled, isTrue);
    expect(controller.wifiRequest?.name, 'Living room TV');
    expect(controller.wifiRequest?.number, '482913');

    await controller.decideWifi(true);
    expect(fake.calls.last.args, {'id': 'r1', 'accept': true});
    expect(controller.wifiRequest, isNull);
    await controller.pollWifi();
    expect(controller.wifiRequest, isNull, reason: 'a poll that crossed the answer must not bring it back');
    await controller.decideWifi(false);
    expect(fake.calls.where((c) => c.method == 'wifiDecide'), hasLength(1), reason: 'nothing is waiting');
  });

  test('Wi-Fi pairing: nothing waiting, a daemon that is down, and the dialog closing', () async {
    fake
      ..stub('pairing', 'wifiWindow', {'status': 'ok'})
      ..stub('pairing', 'wifiPending', {'status': 'ok', 'request': null});
    await controller.pollWifi();
    expect(controller.wifiRequest, isNull);
    await controller.closeWifi();
    expect(fake.calls.last.args, {'open': false});

    fake.stubError('pairing', 'wifiWindow', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
    await controller.pollWifi();
    await controller.closeWifi();
    expect(controller.wifiRequest, isNull);
  });

  test('closing the dialog mid-mint is safe', () async {
    // The dialog disposes the controller when it closes; a mint still in flight then completes
    // into a disposed notifier, which must not throw.
    final pending = controller.newCode();
    controller.dispose();
    await pending;
  });
}
