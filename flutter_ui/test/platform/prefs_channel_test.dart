import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late PrefsChannel prefs;

  setUp(() {
    channel = FakePlatformChannel();
    prefs = PrefsChannel(channel);
  });

  test('getThemeMode returns the stored value', () async {
    channel.stub('prefs', 'getThemeMode', 'dark');
    expect(await prefs.getThemeMode(), 'dark');
  });

  test('getThemeMode returns null when never set', () async {
    channel.stub('prefs', 'getThemeMode', null);
    expect(await prefs.getThemeMode(), isNull);
  });

  test('setThemeMode sends the value under the right key', () async {
    channel.stub('prefs', 'setThemeMode', null);
    await prefs.setThemeMode('light');
    final call = channel.calls.single;
    expect(call.group, 'prefs');
    expect(call.method, 'setThemeMode');
    expect((call.args as Map)['value'], 'light');
  });

  test('getDriveSide returns the stored value', () async {
    channel.stub('prefs', 'getDriveSide', 'right');
    expect(await prefs.getDriveSide(), 'right');
  });

  test('getDriveSide returns null when never set', () async {
    channel.stub('prefs', 'getDriveSide', null);
    expect(await prefs.getDriveSide(), isNull);
  });

  test('setDriveSide sends the value under the right key', () async {
    channel.stub('prefs', 'setDriveSide', null);
    await prefs.setDriveSide('auto');
    final call = channel.calls.single;
    expect(call.group, 'prefs');
    expect(call.method, 'setDriveSide');
    expect((call.args as Map)['value'], 'auto');
  });

  test('propagates a PlatformChannelError from getThemeMode', () async {
    channel.stubError('prefs', 'getThemeMode', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'boom'));
    expect(() => prefs.getThemeMode(), throwsA(isA<PlatformChannelError>()));
  });

  test('getLocationUiMode returns the stored value', () async {
    channel.stub('prefs', 'getLocationUiMode', 'dark');
    expect(await prefs.getLocationUiMode(), 'dark');
  });

  test('getLocationUiMode returns null when never set', () async {
    channel.stub('prefs', 'getLocationUiMode', null);
    expect(await prefs.getLocationUiMode(), isNull);
  });

  test('setLocationUiMode sends the value under the right key', () async {
    channel.stub('prefs', 'setLocationUiMode', null);
    await prefs.setLocationUiMode('light');
    final call = channel.calls.single;
    expect(call.group, 'prefs');
    expect(call.method, 'setLocationUiMode');
    expect((call.args as Map)['value'], 'light');
  });

  test('getSetupGuideLastSeenBuild returns the stored value', () async {
    channel.stub('prefs', 'getSetupGuideLastSeenBuild', '42');
    expect(await prefs.getSetupGuideLastSeenBuild(), '42');
  });

  test('getSetupGuideLastSeenBuild returns null when never set', () async {
    channel.stub('prefs', 'getSetupGuideLastSeenBuild', null);
    expect(await prefs.getSetupGuideLastSeenBuild(), isNull);
  });

  test('setSetupGuideLastSeenBuild sends the value under the right key', () async {
    channel.stub('prefs', 'setSetupGuideLastSeenBuild', null);
    await prefs.setSetupGuideLastSeenBuild('43');
    final call = channel.calls.single;
    expect(call.group, 'prefs');
    expect(call.method, 'setSetupGuideLastSeenBuild');
    expect((call.args as Map)['value'], '43');
  });
}
