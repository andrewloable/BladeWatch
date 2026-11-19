import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('TripsServiceClient', () {
    late FakeRpcClient fake;
    late TripsServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = TripsServiceClient(fake);
    });

    test('listTrips sends TripsService/ListTrips and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ListTripsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'ListTrips', <String, dynamic>{});

      final result = await client.listTrips(ListTripsRequest());

      expect(result, isA<ListTripsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'ListTrips');
      expect(fake.calls.single.request, isA<ListTripsRequest>());
    });

    test('getTrip sends TripsService/GetTrip and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetTripResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetTrip', <String, dynamic>{});

      final result = await client.getTrip(GetTripRequest());

      expect(result, isA<GetTripResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetTrip');
      expect(fake.calls.single.request, isA<GetTripRequest>());
    });

    test('deleteTrip sends TripsService/DeleteTrip and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => DeleteTripResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'DeleteTrip', <String, dynamic>{});

      final result = await client.deleteTrip(DeleteTripRequest());

      expect(result, isA<DeleteTripResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'DeleteTrip');
      expect(fake.calls.single.request, isA<DeleteTripRequest>());
    });

    test('getSummary sends TripsService/GetSummary and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSummaryResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetSummary', <String, dynamic>{});

      final result = await client.getSummary(GetSummaryRequest());

      expect(result, isA<GetSummaryResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetSummary');
      expect(fake.calls.single.request, isA<GetSummaryRequest>());
    });

    test('getDna sends TripsService/GetDna and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetDnaResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetDna', <String, dynamic>{});

      final result = await client.getDna(GetDnaRequest());

      expect(result, isA<GetDnaResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetDna');
      expect(fake.calls.single.request, isA<GetDnaRequest>());
    });

    test('getRange sends TripsService/GetRange and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetRangeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetRange', <String, dynamic>{});

      final result = await client.getRange(GetRangeRequest());

      expect(result, isA<GetRangeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetRange');
      expect(fake.calls.single.request, isA<GetRangeRequest>());
    });

    test('getConfig sends TripsService/GetConfig and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetConfigResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetConfig', <String, dynamic>{});

      final result = await client.getConfig(GetConfigRequest());

      expect(result, isA<GetConfigResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetConfig');
      expect(fake.calls.single.request, isA<GetConfigRequest>());
    });

    test('setConfig sends TripsService/SetConfig and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetConfigResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'SetConfig', <String, dynamic>{});

      final result = await client.setConfig(SetConfigRequest());

      expect(result, isA<SetConfigResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'SetConfig');
      expect(fake.calls.single.request, isA<SetConfigRequest>());
    });

    test('getStorage sends TripsService/GetStorage and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetStorageResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetStorage', <String, dynamic>{});

      final result = await client.getStorage(GetStorageRequest());

      expect(result, isA<GetStorageResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetStorage');
      expect(fake.calls.single.request, isA<GetStorageRequest>());
    });

    test('setStorage sends TripsService/SetStorage and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetStorageResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'SetStorage', <String, dynamic>{});

      final result = await client.setStorage(SetStorageRequest());

      expect(result, isA<SetStorageResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'SetStorage');
      expect(fake.calls.single.request, isA<SetStorageRequest>());
    });

    test('syncTrips sends TripsService/SyncTrips and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SyncTripsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'SyncTrips', <String, dynamic>{});

      final result = await client.syncTrips(SyncTripsRequest());

      expect(result, isA<SyncTripsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'SyncTrips');
      expect(fake.calls.single.request, isA<SyncTripsRequest>());
    });

    test('getTelemetry sends TripsService/GetTelemetry and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetTelemetryResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetTelemetry', <String, dynamic>{});

      final result = await client.getTelemetry(GetTelemetryRequest());

      expect(result, isA<GetTelemetryResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetTelemetry');
      expect(fake.calls.single.request, isA<GetTelemetryRequest>());
    });

    test('getSimilarTrips sends TripsService/GetSimilarTrips and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSimilarTripsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetSimilarTrips', <String, dynamic>{});

      final result = await client.getSimilarTrips(GetSimilarTripsRequest());

      expect(result, isA<GetSimilarTripsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetSimilarTrips');
      expect(fake.calls.single.request, isA<GetSimilarTripsRequest>());
    });

    test('getGpsTrace sends TripsService/GetGpsTrace and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetGpsTraceResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('TripsService', 'GetGpsTrace', <String, dynamic>{});

      final result = await client.getGpsTrace(GetGpsTraceRequest());

      expect(result, isA<GetGpsTraceResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetGpsTrace');
      expect(fake.calls.single.request, isA<GetGpsTraceRequest>());
    });


    test('startManualTrip sends TripsService/StartManualTrip and decodes a real proto3Json response', () async {
      fake.stubJson('TripsService', 'StartManualTrip', <String, dynamic>{'status': {'active': true, 'manual': true, 'startTimeMs': '1700000000123'}});

      final result = await client.startManualTrip(StartManualTripRequest());

      expect(result, isA<StartManualTripResponse>());
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'StartManualTrip');
      expect(fake.calls.single.request, isA<StartManualTripRequest>());
      expect(result.status.manual, isTrue);
      expect(result.status.startTimeMs.toInt(), 1700000000123);
    });

    test('stopManualTrip sends TripsService/StopManualTrip and decodes a real proto3Json response', () async {
      fake.stubJson('TripsService', 'StopManualTrip', <String, dynamic>{'stopped': true});

      final result = await client.stopManualTrip(StopManualTripRequest());

      expect(result, isA<StopManualTripResponse>());
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'StopManualTrip');
      expect(fake.calls.single.request, isA<StopManualTripRequest>());
      expect(result.stopped, isTrue);
    });

    test('getActiveTrip sends TripsService/GetActiveTrip and decodes a real proto3Json response', () async {
      fake.stubJson('TripsService', 'GetActiveTrip', <String, dynamic>{'status': {'active': true, 'manual': true, 'reminderSeq': '2', 'reminderReason': 'acc_off', 'reminderAckedSeq': '1', 'telemetryPaused': true}});

      final result = await client.getActiveTrip(GetActiveTripRequest());

      expect(result, isA<GetActiveTripResponse>());
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'GetActiveTrip');
      expect(fake.calls.single.request, isA<GetActiveTripRequest>());
      expect(result.status.reminderSeq.toInt(), 2);
      expect(result.status.reminderReason, 'acc_off');
      expect(result.status.reminderAckedSeq.toInt(), 1);
      expect(result.status.telemetryPaused, isTrue);
    });

    test('acknowledgeTripReminder sends TripsService/AcknowledgeTripReminder and decodes a real proto3Json response', () async {
      fake.stubJson('TripsService', 'AcknowledgeTripReminder', <String, dynamic>{'status': {'reminderAckedSeq': '3'}});

      final result = await client.acknowledgeTripReminder(AcknowledgeTripReminderRequest());

      expect(result, isA<AcknowledgeTripReminderResponse>());
      expect(fake.calls.single.service, 'TripsService');
      expect(fake.calls.single.method, 'AcknowledgeTripReminder');
      expect(fake.calls.single.request, isA<AcknowledgeTripReminderRequest>());
      expect(result.status.reminderAckedSeq.toInt(), 3);
    });
  });
}
