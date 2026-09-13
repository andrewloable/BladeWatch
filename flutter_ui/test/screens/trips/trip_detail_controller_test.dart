import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late TripDetailController controller;

  Map<String, dynamic> aTripDetailResponse({int id = 1}) => {
        'success': true,
        'trip': {
          'summary': {
            'id': '$id',
            'startTime': '1000',
            'endTime': '5000',
            'distanceKm': 20.0,
            'durationSeconds': 1200,
            'avgSpeedKmh': 45.0,
            'maxSpeedKmh': 90,
            'socStart': 80.0,
            'socEnd': 60.0,
            'tripCost': 3.5,
            'currency': 'USD',
            'overallScore': 88,
            'gradientProfile': 'flat',
            'extTempC': 22,
          },
          'anticipationScore': 70,
          'smoothnessScore': 60,
          'speedDisciplineScore': 90,
          'efficiencyScore': 80,
          'consistencyScore': 75,
          'elevationGainM': 12.0,
          'elevationLossM': 8.0,
        },
      };

  setUp(() {
    rpc = FakeRpcClient();
    controller = TripDetailController(tripsService: TripsServiceClient(rpc));
  });

  test('starts in the loading state', () {
    expect(controller.loading, isTrue);
    expect(controller.detail, isNull);
  });

  group('load', () {
    test('populates detail and telemetry on success', () async {
      rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
      rpc.stubJson('TripsService', 'GetTelemetry', {
        'success': true,
        'telemetry': [
          {'sampleJson': '{"t":1000,"s":50,"a":10,"b":0,"la":37.1,"lo":-122.1}'},
          {'sampleJson': '{"t":2000,"s":55,"a":5,"b":0,"la":37.2,"lo":-122.2}'},
        ],
      });

      await controller.load(1);

      expect(controller.loading, isFalse);
      expect(controller.hasError, isFalse);
      final detail = controller.detail!;
      expect(detail.id, 1);
      expect(detail.distanceKm, 20.0);
      expect(detail.maxSpeedKmh, 90.0); // proto int32 cast to double
      expect(detail.extTempC, 22.0);
      expect(detail.elevationGainM, 12.0);
      expect(controller.telemetry, hasLength(2));
    });

    test('skips a telemetry sample with unparseable JSON rather than crashing', () async {
      rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
      rpc.stubJson('TripsService', 'GetTelemetry', {
        'success': true,
        'telemetry': [
          {'sampleJson': 'not json'},
          {'sampleJson': '{"t":1000,"s":50,"a":10,"b":0,"la":37.1,"lo":-122.1}'},
        ],
      });

      await controller.load(1);

      expect(controller.telemetry, hasLength(1));
    });

    test('does not fetch telemetry when the trip itself is unavailable', () async {
      rpc.stubJson('TripsService', 'GetTrip', {'success': true, 'trip': null});

      await controller.load(1);

      expect(controller.hasError, isTrue);
      expect(controller.detail, isNull);
      expect(rpc.calls.where((c) => c.method == 'GetTelemetry'), isEmpty);
    });

    test('sets an error message when the summary is missing from the trip', () async {
      rpc.stubJson('TripsService', 'GetTrip', {
        'success': true,
        'trip': {'anticipationScore': 1},
      });

      await controller.load(1);

      expect(controller.hasError, isTrue);
      expect(controller.detail, isNull);
    });

    test('sets an error message when the RPC fails', () async {
      rpc.stubError('TripsService', 'GetTrip', const ConnectError('unavailable', 'no daemon'));

      await controller.load(1);

      expect(controller.loading, isFalse);
      expect(controller.hasError, isTrue);
    });

    test('notifies listeners', () async {
      rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
      rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load(1);

      expect(notifications, greaterThan(0));
    });
  });
}
