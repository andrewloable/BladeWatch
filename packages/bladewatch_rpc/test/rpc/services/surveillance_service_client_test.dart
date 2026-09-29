import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/rpc/services/surveillance_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('SurveillanceServiceClient', () {
    late FakeRpcClient fake;
    late SurveillanceServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = SurveillanceServiceClient(fake);
    });

    test('getConfig sends SurveillanceService/GetConfig and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSurveillanceConfigResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'GetConfig', <String, dynamic>{});

      final result = await client.getConfig(GetSurveillanceConfigRequest());

      expect(result, isA<GetSurveillanceConfigResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'GetConfig');
      expect(fake.calls.single.request, isA<GetSurveillanceConfigRequest>());
    });

    test('setConfig sends SurveillanceService/SetConfig and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetSurveillanceConfigResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'SetConfig', <String, dynamic>{});

      final result = await client.setConfig(SetSurveillanceConfigRequest());

      expect(result, isA<SetSurveillanceConfigResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'SetConfig');
      expect(fake.calls.single.request, isA<SetSurveillanceConfigRequest>());
    });

    test('getStatus sends SurveillanceService/GetStatus and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSurveillanceStatusResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'GetStatus', <String, dynamic>{});

      final result = await client.getStatus(GetSurveillanceStatusRequest());

      expect(result, isA<GetSurveillanceStatusResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'GetStatus');
      expect(fake.calls.single.request, isA<GetSurveillanceStatusRequest>());
    });

    test('enable sends SurveillanceService/Enable and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => EnableSurveillanceResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'Enable', <String, dynamic>{});

      final result = await client.enable(EnableSurveillanceRequest());

      expect(result, isA<EnableSurveillanceResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'Enable');
      expect(fake.calls.single.request, isA<EnableSurveillanceRequest>());
    });

    test('disable sends SurveillanceService/Disable and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => DisableSurveillanceResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'Disable', <String, dynamic>{});

      final result = await client.disable(DisableSurveillanceRequest());

      expect(result, isA<DisableSurveillanceResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'Disable');
      expect(fake.calls.single.request, isA<DisableSurveillanceRequest>());
    });

    test('getHeatmap sends SurveillanceService/GetHeatmap and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetHeatmapResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'GetHeatmap', <String, dynamic>{});

      final result = await client.getHeatmap(GetHeatmapRequest());

      expect(result, isA<GetHeatmapResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'GetHeatmap');
      expect(fake.calls.single.request, isA<GetHeatmapRequest>());
    });

    test('getSnapshot sends SurveillanceService/GetSnapshot and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSnapshotResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'GetSnapshot', <String, dynamic>{});

      final result = await client.getSnapshot(GetSnapshotRequest());

      expect(result, isA<GetSnapshotResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'GetSnapshot');
      expect(fake.calls.single.request, isA<GetSnapshotRequest>());
    });

    test('getFilterLog sends SurveillanceService/GetFilterLog and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetFilterLogResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'GetFilterLog', <String, dynamic>{});

      final result = await client.getFilterLog(GetFilterLogRequest());

      expect(result, isA<GetFilterLogResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'GetFilterLog');
      expect(fake.calls.single.request, isA<GetFilterLogRequest>());
    });

    test('syncCatalog sends SurveillanceService/SyncCatalog and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SyncSurveillanceCatalogResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SurveillanceService', 'SyncCatalog', <String, dynamic>{});

      final result = await client.syncCatalog(SyncSurveillanceCatalogRequest());

      expect(result, isA<SyncSurveillanceCatalogResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SurveillanceService');
      expect(fake.calls.single.method, 'SyncCatalog');
      expect(fake.calls.single.request, isA<SyncSurveillanceCatalogRequest>());
    });

  });
}
