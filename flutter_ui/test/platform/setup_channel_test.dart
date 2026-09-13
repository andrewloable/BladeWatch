import 'package:bladewatch_ui/platform/setup_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late SetupChannel setup;

  setUp(() {
    channel = FakePlatformChannel();
    setup = SetupChannel(channel);
  });

  test('openAutoStartSettings invokes setup.openAutoStartSettings', () async {
    channel.stub('setup', 'openAutoStartSettings', null);
    await setup.openAutoStartSettings();
    expect(channel.calls.single.method, 'openAutoStartSettings');
    expect(channel.calls.single.group, 'setup');
  });

  test('openOverlaySettings invokes setup.openOverlaySettings', () async {
    channel.stub('setup', 'openOverlaySettings', null);
    await setup.openOverlaySettings();
    expect(channel.calls.single.method, 'openOverlaySettings');
    expect(channel.calls.single.group, 'setup');
  });

  test('propagates a PlatformChannelError from openAutoStartSettings', () async {
    channel.stubError('setup', 'openAutoStartSettings', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'boom'));
    expect(() => setup.openAutoStartSettings(), throwsA(isA<PlatformChannelError>()));
  });
}
