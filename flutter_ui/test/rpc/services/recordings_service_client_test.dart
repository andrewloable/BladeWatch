import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  group('RecordingsServiceClient', () {
    late FakeRpcClient fake;
    late RecordingsServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = RecordingsServiceClient(fake);
    });

    test('listRecordings sends RecordingsService/ListRecordings and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ListRecordingsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'ListRecordings', <String, dynamic>{});

      final result = await client.listRecordings(ListRecordingsRequest());

      expect(result, isA<ListRecordingsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'ListRecordings');
      expect(fake.calls.single.request, isA<ListRecordingsRequest>());
    });

    test('getDates sends RecordingsService/GetDates and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetDatesResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'GetDates', <String, dynamic>{});

      final result = await client.getDates(GetDatesRequest());

      expect(result, isA<GetDatesResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'GetDates');
      expect(fake.calls.single.request, isA<GetDatesRequest>());
    });

    test('getStats sends RecordingsService/GetStats and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetStatsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'GetStats', <String, dynamic>{});

      final result = await client.getStats(GetStatsRequest());

      expect(result, isA<GetStatsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'GetStats');
      expect(fake.calls.single.request, isA<GetStatsRequest>());
    });

    test('deleteRecording sends RecordingsService/DeleteRecording and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => DeleteRecordingResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'DeleteRecording', <String, dynamic>{});

      final result = await client.deleteRecording(DeleteRecordingRequest());

      expect(result, isA<DeleteRecordingResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'DeleteRecording');
      expect(fake.calls.single.request, isA<DeleteRecordingRequest>());
    });

    test('batchDelete sends RecordingsService/BatchDelete and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => BatchDeleteResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'BatchDelete', <String, dynamic>{});

      final result = await client.batchDelete(BatchDeleteRequest());

      expect(result, isA<BatchDeleteResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'BatchDelete');
      expect(fake.calls.single.request, isA<BatchDeleteRequest>());
    });

    test('syncCatalog sends RecordingsService/SyncCatalog and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SyncCatalogResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'SyncCatalog', <String, dynamic>{});

      final result = await client.syncCatalog(SyncCatalogRequest());

      expect(result, isA<SyncCatalogResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'SyncCatalog');
      expect(fake.calls.single.request, isA<SyncCatalogRequest>());
    });

    test('getInflightStatus sends RecordingsService/GetInflightStatus and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetInflightStatusResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'GetInflightStatus', <String, dynamic>{});

      final result = await client.getInflightStatus(GetInflightStatusRequest());

      expect(result, isA<GetInflightStatusResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'GetInflightStatus');
      expect(fake.calls.single.request, isA<GetInflightStatusRequest>());
    });

    test('getEventTimeline sends RecordingsService/GetEventTimeline and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetEventTimelineResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('RecordingsService', 'GetEventTimeline', <String, dynamic>{});

      final result = await client.getEventTimeline(GetEventTimelineRequest());

      expect(result, isA<GetEventTimelineResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'RecordingsService');
      expect(fake.calls.single.method, 'GetEventTimeline');
      expect(fake.calls.single.request, isA<GetEventTimelineRequest>());
    });

  });
}
