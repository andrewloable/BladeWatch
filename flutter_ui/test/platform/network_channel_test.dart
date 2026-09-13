import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late NetworkChannel network;

  setUp(() {
    channel = FakePlatformChannel();
    network = NetworkChannel(channel);
  });

  test('currentNetwork returns wifi with the ssid', () async {
    channel.stub('network', 'current', {'type': 'wifi', 'ssid': 'HomeWifi'});

    final result = await network.currentNetwork();

    expect(result.type, NetworkType.wifi);
    expect(result.ssid, 'HomeWifi');
  });

  test('currentNetwork returns mobile with no ssid', () async {
    channel.stub('network', 'current', {'type': 'mobile', 'ssid': null});

    final result = await network.currentNetwork();

    expect(result.type, NetworkType.mobile);
    expect(result.ssid, isNull);
  });

  test('currentNetwork returns ethernet', () async {
    channel.stub('network', 'current', {'type': 'ethernet', 'ssid': null});

    expect((await network.currentNetwork()).type, NetworkType.ethernet);
  });

  test('currentNetwork returns offline', () async {
    channel.stub('network', 'current', {'type': 'offline', 'ssid': null});

    expect((await network.currentNetwork()).type, NetworkType.offline);
  });

  test('currentNetwork treats an unrecognized type as offline', () async {
    channel.stub('network', 'current', {'type': 'something-new', 'ssid': null});

    expect((await network.currentNetwork()).type, NetworkType.offline);
  });

  test('propagates a PlatformChannelError', () async {
    channel.stubError('network', 'current', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'boom'));

    expect(() => network.currentNetwork(), throwsA(isA<PlatformChannelError>()));
  });
}
