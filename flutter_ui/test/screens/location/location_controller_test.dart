import 'package:bladewatch_ui/platform/location_channel.dart';
import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/screens/location/location_controller.dart';
import 'package:bladewatch_ui/screens/location/location_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late LocationController controller;
  int now = 1000;

  void stubOnline() => channel.stub('network', 'current', {'type': 'wifi', 'ssid': 'car'});
  void stubOffline() => channel.stub('network', 'current', {'type': 'offline', 'ssid': null});
  void stubSample({double lat = 37.7749, double lng = -122.4194, int timestampMs = 1000, double? bearing}) =>
      channel.stub('location', 'currentSample', {
        'latitude': lat,
        'longitude': lng,
        'bearingDegrees': bearing,
        'provider': 'gps',
        'timestampMs': timestampMs,
      });

  setUp(() {
    now = 1000;
    channel = FakePlatformChannel();
    controller = LocationController(
      channel: LocationChannel(channel),
      prefs: PrefsChannel(channel),
      networkChannel: NetworkChannel(channel),
      nowMs: () => now,
    );
    stubOnline();
  });

  test('initial state is Loading', () {
    expect(controller.state, isA<LocationLoading>());
  });

  test('the real-clock default is used when nowMs is not overridden', () async {
    final realClockController = LocationController(
      channel: LocationChannel(channel),
      prefs: PrefsChannel(channel),
      networkChannel: NetworkChannel(channel),
    );
    channel.stub('location', 'hasPermission', true);
    channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
    channel.stub('location', 'startUpdates', {'ok': true});
    await realClockController.start();
    expect(realClockController.state, isA<LocationWaitingForFix>());
  });

  group('start()', () {
    test('no permission, never prompted -> PermissionMissing', () async {
      channel.stub('location', 'hasPermission', false);
      await controller.start();
      expect(controller.state, isA<LocationPermissionMissing>());
    });

    test('permission granted, no provider enabled -> ProviderDisabled', () async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': false, 'network': false});
      await controller.start();
      expect(controller.state, isA<LocationProviderDisabled>());
    });

    test('prefers gps over network when both are enabled', () async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': true});
      channel.stub('location', 'startUpdates', {'ok': true});
      await controller.start();
      final call = channel.calls.firstWhere((c) => c.method == 'startUpdates');
      expect((call.args as Map)['provider'], 'gps');
    });

    test('falls back to network when only network is enabled', () async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': false, 'network': true});
      channel.stub('location', 'startUpdates', {'ok': true});
      await controller.start();
      final call = channel.calls.firstWhere((c) => c.method == 'startUpdates');
      expect((call.args as Map)['provider'], 'network');
    });

    test('provider available, startUpdates succeeds -> WaitingForFix with no prior location', () async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
      channel.stub('location', 'startUpdates', {'ok': true});
      await controller.start();
      expect(controller.state, isA<LocationWaitingForFix>());
    });

    test('startUpdates failure -> Error carrying the reason', () async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
      channel.stub('location', 'startUpdates', {'ok': false, 'reason': 'permission revoked'});
      await controller.start();
      expect(controller.state, isA<LocationError>());
      expect((controller.state as LocationError).reason, 'permission revoked');
    });

    test('a channel exception is caught and surfaces as LocationError, not an uncaught throw', () async {
      channel.stubError('location', 'hasPermission', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'no handler'));
      await controller.start();
      expect(controller.state, isA<LocationError>());
    });

    test('a prior denial makes a later start() report PermissionDenied, not PermissionMissing', () async {
      channel.stub('location', 'hasPermission', false);
      channel.stub('location', 'requestPermission', false);
      await controller.requestPermission();
      expect(controller.state, isA<LocationPermissionDenied>());

      await controller.start();
      expect(controller.state, isA<LocationPermissionDenied>());
    });
  });

  group('requestPermission()', () {
    test('granted -> proceeds through start()', () async {
      channel.stub('location', 'requestPermission', true);
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
      channel.stub('location', 'startUpdates', {'ok': true});
      await controller.requestPermission();
      expect(controller.state, isA<LocationWaitingForFix>());
      expect(channel.calls.any((c) => c.method == 'startUpdates'), isTrue);
    });

    test('denied -> PermissionDenied, does not call start()', () async {
      channel.stub('location', 'requestPermission', false);
      await controller.requestPermission();
      expect(controller.state, isA<LocationPermissionDenied>());
      expect(channel.calls.any((c) => c.method == 'providerEnabled'), isFalse);
    });
  });

  group('onBannerAction()', () {
    test('from PermissionMissing, requests permission', () async {
      channel.stub('location', 'hasPermission', false);
      await controller.start();
      expect(controller.state, isA<LocationPermissionMissing>());

      channel.stub('location', 'requestPermission', false);
      await controller.onBannerAction();
      expect(channel.calls.any((c) => c.method == 'requestPermission'), isTrue);
      expect(controller.state, isA<LocationPermissionDenied>());
    });

    test('from any other actionable state, retries via stop()+start()', () async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': false, 'network': false});
      await controller.start();
      expect(controller.state, isA<LocationProviderDisabled>());

      channel.stub('location', 'stopUpdates', null);
      channel.calls.clear();
      await controller.onBannerAction();
      expect(channel.calls.first.method, 'stopUpdates');
      expect(channel.calls.any((c) => c.method == 'providerEnabled'), isTrue);
    });
  });

  group('poll()', () {
    Future<void> startListening() async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
      channel.stub('location', 'startUpdates', {'ok': true});
      await controller.start();
    }

    test('not listening: just refreshes staleness, does not touch the channel', () async {
      // Fresh controller, start() never called.
      channel.calls.clear();
      await controller.poll();
      expect(controller.state, isA<LocationLoading>());
      expect(channel.calls.any((c) => c.method == 'providerEnabled'), isFalse);
    });

    test('a fresh sample becomes LocationFresh and updates the viewport', () async {
      await startListening();
      stubSample(timestampMs: 1000);
      await controller.poll();
      expect(controller.state, isA<LocationFresh>());
      expect(controller.viewportState.lastLocation, isNotNull);
      expect(controller.viewportState.firstLocationSeen, isTrue);
    });

    test('an unchanged sample is not reapplied, but staleness still advances', () async {
      await startListening();
      stubSample(timestampMs: 1000);
      await controller.poll();
      expect(controller.state, isA<LocationFresh>());

      now += LocationStateReducer.staleThresholdMs; // same sample, but time has passed
      await controller.poll();
      expect(controller.state, isA<LocationStale>());
    });

    test('a channel exception mid-tick is swallowed, leaving state as the next tick left it', () async {
      await startListening();
      stubSample(timestampMs: 1000);
      await controller.poll();
      expect(controller.state, isA<LocationFresh>());

      channel.stubError('location', 'providerEnabled', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'x'));
      await controller.poll();
      expect(controller.state, isA<LocationFresh>(), reason: 'a failed tick should not clobber the last good state');
    });

    test('no cached sample yet leaves WaitingForFix untouched', () async {
      await startListening();
      channel.stub('location', 'currentSample', null);
      await controller.poll();
      expect(controller.state, isA<LocationWaitingForFix>());
    });

    test('provider becomes disabled mid-listening -> ProviderDisabled', () async {
      await startListening();
      channel.stub('location', 'providerEnabled', {'gps': false, 'network': false});
      await controller.poll();
      expect(controller.state, isA<LocationProviderDisabled>());
    });

    test('provider recovers -> restarts via stop()+start()', () async {
      await startListening();
      channel.stub('location', 'providerEnabled', {'gps': false, 'network': false});
      await controller.poll();
      expect(controller.state, isA<LocationProviderDisabled>());

      channel.stub('location', 'stopUpdates', null);
      channel.calls.clear();
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
      channel.stub('location', 'startUpdates', {'ok': true});
      await controller.poll();
      final stopIndex = channel.calls.indexWhere((c) => c.method == 'stopUpdates');
      final restartIndex = channel.calls.indexWhere((c) => c.method == 'startUpdates');
      expect(stopIndex, greaterThanOrEqualTo(0), reason: 'must stop the old listener');
      expect(restartIndex, greaterThan(stopIndex), reason: 'must restart after stopping');
      expect(controller.state, isA<LocationWaitingForFix>());
    });
  });

  group('effectiveState', () {
    test('downgrades Fresh to TileFailure while offline, without mutating state', () async {
      channel.stub('location', 'hasPermission', true);
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
      channel.stub('location', 'startUpdates', {'ok': true});
      await controller.start();
      stubSample(timestampMs: 1000);
      await controller.poll();
      expect(controller.state, isA<LocationFresh>());

      stubOffline();
      await controller.poll();
      expect(controller.state, isA<LocationFresh>(), reason: 'raw state stays Fresh');
      expect(controller.effectiveState, isA<LocationTileFailure>());
    });

    test('leaves non-location states alone even when offline', () async {
      stubOffline();
      await controller.poll();
      expect(controller.effectiveState, isA<LocationLoading>());
    });
  });

  group('viewport', () {
    test('onUserPan clears followCar and notifies', () {
      var notified = 0;
      controller.addListener(() => notified++);
      controller.onUserPan();
      expect(controller.viewportState.followCar, isFalse);
      expect(notified, 1);
    });

    test('onRecenterRequested sets followCar and notifies', () {
      controller.onUserPan();
      var notified = 0;
      controller.addListener(() => notified++);
      controller.onRecenterRequested();
      expect(controller.viewportState.followCar, isTrue);
      expect(notified, 1);
    });
  });

  group('ui mode preference', () {
    test('loadUiModePreference reads the stored value', () async {
      channel.stub('prefs', 'getLocationUiMode', 'dark');
      await controller.loadUiModePreference();
      expect(controller.uiModePreference, LocationUiModePreference.dark);
    });

    test('loadUiModePreference falls back to auto on a channel error', () async {
      channel.stubError('prefs', 'getLocationUiMode', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'x'));
      await controller.loadUiModePreference();
      expect(controller.uiModePreference, LocationUiModePreference.auto);
    });

    test('setUiModePreference persists and updates local state', () async {
      channel.stub('prefs', 'setLocationUiMode', null);
      await controller.setUiModePreference(LocationUiModePreference.light);
      expect(controller.uiModePreference, LocationUiModePreference.light);
      final call = channel.calls.firstWhere((c) => c.method == 'setLocationUiMode');
      expect((call.args as Map)['value'], 'light');
    });
  });

  group('useNightTiles', () {
    test('reads the app-wide theme preference and combines it with the screen preference', () async {
      channel.stub('prefs', 'getThemeMode', 'dark');
      expect(await controller.useNightTiles(systemIsDark: false), isTrue);
    });

    test('falls back to systemIsDark when the app-wide pref read fails', () async {
      channel.stubError('prefs', 'getThemeMode', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'x'));
      expect(await controller.useNightTiles(systemIsDark: true), isTrue);
    });
  });

  test('stop() clears listening and calls the channel', () async {
    channel.stub('location', 'hasPermission', true);
    channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
    channel.stub('location', 'startUpdates', {'ok': true});
    await controller.start();

    channel.stub('location', 'stopUpdates', null);
    await controller.stop();
    expect(channel.calls.last.method, 'stopUpdates');

    // No longer listening -- a subsequent poll() should not touch providerEnabled.
    channel.calls.clear();
    await controller.poll();
    expect(channel.calls.any((c) => c.method == 'providerEnabled'), isFalse);
  });
}
