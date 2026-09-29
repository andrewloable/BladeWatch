import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/platform/public_config_channel.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_models.dart';

import '../fakes/fake_platform_channel.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';

void main() {
  _cameraProbeSourceTests();
  _batterySocSourceTests();
  group('PublicConfigChannel', () {
    test('getSection sends the section name and types the result', () async {
      final fake = FakePlatformChannel()
        ..stub('publicConfig', 'getSection', <Object?, Object?>{'cameraVisible': true, 'tripVisible': false});

      final section = await PublicConfigChannel(fake).getSection('statusOverlay');

      expect(section, {'cameraVisible': true, 'tripVisible': false});
      expect(fake.calls.single.group, 'publicConfig');
      expect(fake.calls.single.args, {'section': 'statusOverlay'});
    });

    test('getSection returns an empty map when the daemon refuses the section', () async {
      // Distinguishable from "every flag is off" — callers fall back to their
      // own defaults on an empty map rather than showing everything disabled.
      final fake = FakePlatformChannel()..stub('publicConfig', 'getSection', <Object?, Object?>{});
      expect(await PublicConfigChannel(fake).getSection('network'), isEmpty);
    });

    test('putBoolean sends section, key and value', () async {
      final fake = FakePlatformChannel()..stub('publicConfig', 'putBoolean', true);

      expect(await PublicConfigChannel(fake).putBoolean('developerOptions', 'debugLogsEnabled', true), isTrue);
      expect(fake.calls.single.args, {'section': 'developerOptions', 'key': 'debugLogsEnabled', 'value': true});
    });

    test('putBoolean reports false when the daemon refuses the write', () async {
      final fake = FakePlatformChannel()..stub('publicConfig', 'putBoolean', false);
      expect(await PublicConfigChannel(fake).putBoolean('network', 'lanHttpEnabled', true), isFalse);
    });

    test('propagates a daemonNotUp error rather than reporting success', () async {
      final fake = FakePlatformChannel()
        ..stubError(
          'publicConfig',
          'putBoolean',
          const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'daemon down'),
        );

      await expectLater(
        () => PublicConfigChannel(fake).putBoolean('statusOverlay', 'tripVisible', false),
        throwsA(isA<PlatformChannelError>()),
      );
    });
  
    // BladeWatch-i2wv: the Diagnostics camera tile's typed read. getSection would
    // coerce probedCameraId to a bool, which is why this exists.
    test('getCameraProbe types probedCameraId as an int', () async {
      final fake = FakePlatformChannel()
        ..stub('publicConfig', 'getCameraProbe',
            <Object?, Object?>{'probedCameraId': 2, 'manualOverride': true});

      final probe = await PublicConfigChannel(fake).getCameraProbe();

      expect(probe, isNotNull);
      expect(probe!.probedCameraId, 2);
      expect(probe.manualOverride, isTrue);
      expect(fake.calls.single.group, 'publicConfig');
      expect(fake.calls.single.method, 'getCameraProbe');
    });

    // A failed read is NOT the same as "not probed yet" (-1): the first means the
    // daemon did not answer, the second that it answered and has no camera bound.
    test('getCameraProbe returns null when the read fails', () async {
      final fake = FakePlatformChannel()..stub('publicConfig', 'getCameraProbe', null);

      expect(await PublicConfigChannel(fake).getCameraProbe(), isNull);
    });

    test('getCameraProbe defaults a missing probedCameraId to not-probed', () async {
      final fake = FakePlatformChannel()
        ..stub('publicConfig', 'getCameraProbe', <Object?, Object?>{});

      final probe = await PublicConfigChannel(fake).getCameraProbe();

      expect(probe!.probedCameraId, -1);
      expect(probe.manualOverride, isFalse);
    });
});
}

// BladeWatch-i2wv: the adapter that turns a channel read into the model the
// Diagnostics controller consumes. It lives in a class rather than a closure in
// main.dart precisely so these can exist — the composition root is not covered.
void _cameraProbeSourceTests() {
  group('CameraProbeSource', () {
    test('maps a real probe through', () async {
      final fake = FakePlatformChannel()
        ..stub('publicConfig', 'getCameraProbe',
            <Object?, Object?>{'probedCameraId': 0, 'manualOverride': false});

      final config = await CameraProbeSource(PublicConfigChannel(fake)).read();

      expect(config.probedCameraId, 0);
      expect(config.manualOverride, isFalse);
    });

    test('a failed read falls back to not-probed rather than throwing', () async {
      final fake = FakePlatformChannel()..stub('publicConfig', 'getCameraProbe', null);

      final config = await CameraProbeSource(PublicConfigChannel(fake)).read();

      expect(config.probedCameraId, -1);
      expect(config.manualOverride, isFalse);
    });

    test('a manual override survives the round trip', () async {
      final fake = FakePlatformChannel()
        ..stub('publicConfig', 'getCameraProbe',
            <Object?, Object?>{'probedCameraId': 3, 'manualOverride': true});

      final config = await CameraProbeSource(PublicConfigChannel(fake)).read();

      expect(config.probedCameraId, 3);
      expect(config.manualOverride, isTrue);
    });
  });
}

// BladeWatch-1ovy: the Diagnostics battery tile's charge source. Same reasoning
// as CameraProbeSource — a class, not a closure in main.dart, so the branches are
// reachable from tests.
void _batterySocSourceTests() {
  group('BatterySocSource', () {
    FakeRpcClient rpcWith(Map<String, Object?> state) =>
        FakeRpcClient()..stubJson('VehicleService', 'GetState', state);

    test('reads the charge percentage off the vehicle state', () async {
      final source = BatterySocSource(
          VehicleServiceClient(rpcWith({'success': true, 'battery': {'soc': 61.0, 'rangeKm': 56}})));

      expect(await source.read(), 61);
    });

    // The success flag is the same gate VehicleController applies before reading
    // any field off this response.
    test('returns null when the response reports failure', () async {
      final source = BatterySocSource(
          VehicleServiceClient(rpcWith({'success': false, 'battery': {'soc': 61.0}})));

      expect(await source.read(), isNull);
    });

    // 0 is the proto default for "no reading". Rendering it as 0% would look like
    // a flat pack every time the vehicle is asleep.
    test('treats a zero reading as no reading, not as a flat pack', () async {
      final source = BatterySocSource(
          VehicleServiceClient(rpcWith({'success': true, 'battery': {'soc': 0.0}})));

      expect(await source.read(), isNull);
    });

    test('rejects an out-of-range percentage rather than rendering nonsense', () async {
      final source = BatterySocSource(
          VehicleServiceClient(rpcWith({'success': true, 'battery': {'soc': 140.0}})));

      expect(await source.read(), isNull);
    });

    test('a throwing transport yields null rather than propagating', () async {
      final rpc = FakeRpcClient()..stubError('VehicleService', 'GetState', const ConnectError('unavailable', 'daemon down'));

      expect(await BatterySocSource(VehicleServiceClient(rpc)).read(), isNull);
    });
  });
}
