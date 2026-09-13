import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  group('SystemServiceClient', () {
    late FakeRpcClient fake;
    late SystemServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = SystemServiceClient(fake);
    });

    test('getStatus sends SystemService/GetStatus and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetStatusResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetStatus', <String, dynamic>{});

      final result = await client.getStatus(GetStatusRequest());

      expect(result, isA<GetStatusResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetStatus');
      expect(fake.calls.single.request, isA<GetStatusRequest>());
    });

    test('getPerformance sends SystemService/GetPerformance and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetPerformanceResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetPerformance', <String, dynamic>{});

      final result = await client.getPerformance(GetPerformanceRequest());

      expect(result, isA<GetPerformanceResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetPerformance');
      expect(fake.calls.single.request, isA<GetPerformanceRequest>());
    });

    test('playAudioTest sends SystemService/PlayAudioTest and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => PlayAudioTestResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'PlayAudioTest', <String, dynamic>{});

      final result = await client.playAudioTest(PlayAudioTestRequest());

      expect(result, isA<PlayAudioTestResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'PlayAudioTest');
      expect(fake.calls.single.request, isA<PlayAudioTestRequest>());
    });

    test('listModels sends SystemService/ListModels and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ListModelsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'ListModels', <String, dynamic>{});

      final result = await client.listModels(ListModelsRequest());

      expect(result, isA<ListModelsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'ListModels');
      expect(fake.calls.single.request, isA<ListModelsRequest>());
    });

    test('downloadModel sends SystemService/DownloadModel and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => DownloadModelResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'DownloadModel', <String, dynamic>{});

      final result = await client.downloadModel(DownloadModelRequest());

      expect(result, isA<DownloadModelResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'DownloadModel');
      expect(fake.calls.single.request, isA<DownloadModelRequest>());
    });

    test('getSohNominal sends SystemService/GetSohNominal and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSohNominalResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetSohNominal', <String, dynamic>{});

      final result = await client.getSohNominal(GetSohNominalRequest());

      expect(result, isA<GetSohNominalResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetSohNominal');
      expect(fake.calls.single.request, isA<GetSohNominalRequest>());
    });

    test('setSohNominal sends SystemService/SetSohNominal and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetSohNominalResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'SetSohNominal', <String, dynamic>{});

      final result = await client.setSohNominal(SetSohNominalRequest());

      expect(result, isA<SetSohNominalResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'SetSohNominal');
      expect(fake.calls.single.request, isA<SetSohNominalRequest>());
    });

    test('getSohStatus sends SystemService/GetSohStatus and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSohStatusResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetSohStatus', <String, dynamic>{});

      final result = await client.getSohStatus(GetSohStatusRequest());

      expect(result, isA<GetSohStatusResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetSohStatus');
      expect(fake.calls.single.request, isA<GetSohStatusRequest>());
    });

    test('resetSoh sends SystemService/ResetSoh and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ResetSohResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'ResetSoh', <String, dynamic>{});

      final result = await client.resetSoh(ResetSohRequest());

      expect(result, isA<ResetSohResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'ResetSoh');
      expect(fake.calls.single.request, isA<ResetSohRequest>());
    });

    test('resetPerformance sends SystemService/ResetPerformance and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ResetPerformanceResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'ResetPerformance', <String, dynamic>{});

      final result = await client.resetPerformance(ResetPerformanceRequest());

      expect(result, isA<ResetPerformanceResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'ResetPerformance');
      expect(fake.calls.single.request, isA<ResetPerformanceRequest>());
    });

    test('getParkingDelta sends SystemService/GetParkingDelta and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetParkingDeltaResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetParkingDelta', <String, dynamic>{});

      final result = await client.getParkingDelta(GetParkingDeltaRequest());

      expect(result, isA<GetParkingDeltaResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetParkingDelta');
      expect(fake.calls.single.request, isA<GetParkingDeltaRequest>());
    });

    test('getLastCharge sends SystemService/GetLastCharge and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetLastChargeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetLastCharge', <String, dynamic>{});

      final result = await client.getLastCharge(GetLastChargeRequest());

      expect(result, isA<GetLastChargeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetLastCharge');
      expect(fake.calls.single.request, isA<GetLastChargeRequest>());
    });

    test('getSelectedModel sends SystemService/GetSelectedModel and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSelectedModelResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetSelectedModel', <String, dynamic>{});

      final result = await client.getSelectedModel(GetSelectedModelRequest());

      expect(result, isA<GetSelectedModelResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetSelectedModel');
      expect(fake.calls.single.request, isA<GetSelectedModelRequest>());
    });

    test('setSelectedModel sends SystemService/SetSelectedModel and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetSelectedModelResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'SetSelectedModel', <String, dynamic>{});

      final result = await client.setSelectedModel(SetSelectedModelRequest());

      expect(result, isA<SetSelectedModelResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'SetSelectedModel');
      expect(fake.calls.single.request, isA<SetSelectedModelRequest>());
    });

    test('getModelsManifest sends SystemService/GetModelsManifest and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetModelsManifestResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SystemService', 'GetModelsManifest', <String, dynamic>{});

      final result = await client.getModelsManifest(GetModelsManifestRequest());

      expect(result, isA<GetModelsManifestResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SystemService');
      expect(fake.calls.single.method, 'GetModelsManifest');
      expect(fake.calls.single.request, isA<GetModelsManifestRequest>());
    });

  });
}
