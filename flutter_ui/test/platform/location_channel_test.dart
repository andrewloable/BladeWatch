import 'package:bladewatch_ui/platform/location_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late LocationChannel location;

  setUp(() {
    channel = FakePlatformChannel();
    location = LocationChannel(channel);
  });

  test('hasPermission returns the raw bool', () async {
    channel.stub('location', 'hasPermission', true);
    expect(await location.hasPermission(), isTrue);
  });

  test('requestPermission returns the raw bool', () async {
    channel.stub('location', 'requestPermission', false);
    expect(await location.requestPermission(), isFalse);
  });

  group('providerEnabled', () {
    test('maps both flags', () async {
      channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
      final result = await location.providerEnabled();
      expect(result.gps, isTrue);
      expect(result.network, isFalse);
    });

    test('defaults missing flags to false', () async {
      channel.stub('location', 'providerEnabled', <Object?, Object?>{});
      final result = await location.providerEnabled();
      expect(result.gps, isFalse);
      expect(result.network, isFalse);
    });
  });

  group('startUpdates', () {
    test('sends the chosen provider and reports success', () async {
      channel.stub('location', 'startUpdates', {'ok': true});
      final result = await location.startUpdates('gps');
      expect(result.ok, isTrue);
      expect(result.reason, isNull);
      final call = channel.calls.single;
      expect(call.method, 'startUpdates');
      expect((call.args as Map)['provider'], 'gps');
    });

    test('reports a failure reason', () async {
      channel.stub('location', 'startUpdates', {'ok': false, 'reason': 'permission revoked'});
      final result = await location.startUpdates('network');
      expect(result.ok, isFalse);
      expect(result.reason, 'permission revoked');
    });
  });

  test('stopUpdates invokes with no return value', () async {
    channel.stub('location', 'stopUpdates', null);
    await location.stopUpdates();
    expect(channel.calls.single.method, 'stopUpdates');
  });

  group('currentSample', () {
    test('returns null when there is no fix yet', () async {
      channel.stub('location', 'currentSample', null);
      expect(await location.currentSample(), isNull);
    });

    test('maps every field of a full sample', () async {
      channel.stub('location', 'currentSample', {
        'latitude': 37.7749,
        'longitude': -122.4194,
        'bearingDegrees': 90.0,
        'speedMetersPerSecond': 12.5,
        'accuracyMeters': 4.0,
        'altitudeMeters': 15.0,
        'provider': 'gps',
        'timestampMs': 1700000000000,
      });
      final sample = await location.currentSample();
      expect(sample!.latitude, 37.7749);
      expect(sample.longitude, -122.4194);
      expect(sample.bearingDegrees, 90.0);
      expect(sample.speedMetersPerSecond, 12.5);
      expect(sample.accuracyMeters, 4.0);
      expect(sample.altitudeMeters, 15.0);
      expect(sample.provider, 'gps');
      expect(sample.timestampMs, 1700000000000);
    });

    test('tolerates a sample with only the required fields', () async {
      channel.stub('location', 'currentSample', {
        'latitude': 1.0,
        'longitude': 2.0,
        'provider': 'network',
        'timestampMs': 1000,
      });
      final sample = await location.currentSample();
      expect(sample!.bearingDegrees, isNull);
      expect(sample.speedMetersPerSecond, isNull);
      expect(sample.accuracyMeters, isNull);
      expect(sample.altitudeMeters, isNull);
    });
  });
}
