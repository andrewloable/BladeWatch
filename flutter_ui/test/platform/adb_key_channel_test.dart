import 'dart:typed_data';

import 'package:bladewatch_ui/platform/adb_key_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late AdbKeyChannel adbKeys;

  setUp(() {
    channel = FakePlatformChannel();
    adbKeys = AdbKeyChannel(channel);
  });

  test('getPublicKey returns the native side\'s ADB-formatted key blob', () async {
    channel.stub('adb', 'getPublicKey', 'QAAAAA... user@bladewatch');
    expect(await adbKeys.getPublicKey(), 'QAAAAA... user@bladewatch');
  });

  test('sign sends the token bytes under the right key and returns the signature', () async {
    final token = Uint8List.fromList(List.generate(20, (i) => i));
    final signature = Uint8List.fromList(List.filled(256, 7));
    channel.stub('adb', 'sign', signature);

    final result = await adbKeys.sign(token);

    expect(result, signature);
    final call = channel.calls.single;
    expect(call.group, 'adb');
    expect(call.method, 'sign');
    expect((call.args as Map)['token'], token);
  });

  test('propagates a PlatformChannelError from getPublicKey', () async {
    channel.stubError('adb', 'getPublicKey', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'boom'));
    expect(() => adbKeys.getPublicKey(), throwsA(isA<PlatformChannelError>()));
  });

  test('propagates a PlatformChannelError from sign', () async {
    channel.stubError('adb', 'sign', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'boom'));
    expect(() => adbKeys.sign(Uint8List(20)), throwsA(isA<PlatformChannelError>()));
  });
}
