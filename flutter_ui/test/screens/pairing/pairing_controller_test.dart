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

  test('closing the dialog mid-mint is safe', () async {
    // The dialog disposes the controller when it closes; a mint still in flight then completes
    // into a disposed notifier, which must not throw.
    final pending = controller.newCode();
    controller.dispose();
    await pending;
  });
}
