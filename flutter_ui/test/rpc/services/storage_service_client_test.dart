import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  group('StorageServiceClient', () {
    late FakeRpcClient fake;
    late StorageServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = StorageServiceClient(fake);
    });

    test('getStorageSettings sends StorageService/GetStorageSettings and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetStorageSettingsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'GetStorageSettings', <String, dynamic>{});

      final result = await client.getStorageSettings(GetStorageSettingsRequest());

      expect(result, isA<GetStorageSettingsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'GetStorageSettings');
      expect(fake.calls.single.request, isA<GetStorageSettingsRequest>());
    });

    test('setStorageSettings sends StorageService/SetStorageSettings and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetStorageSettingsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'SetStorageSettings', <String, dynamic>{});

      final result = await client.setStorageSettings(SetStorageSettingsRequest());

      expect(result, isA<SetStorageSettingsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'SetStorageSettings');
      expect(fake.calls.single.request, isA<SetStorageSettingsRequest>());
    });

    test('getExternalStorage sends StorageService/GetExternalStorage and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetExternalStorageResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'GetExternalStorage', <String, dynamic>{});

      final result = await client.getExternalStorage(GetExternalStorageRequest());

      expect(result, isA<GetExternalStorageResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'GetExternalStorage');
      expect(fake.calls.single.request, isA<GetExternalStorageRequest>());
    });

    test('setExternalConfig sends StorageService/SetExternalConfig and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetExternalConfigResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'SetExternalConfig', <String, dynamic>{});

      final result = await client.setExternalConfig(SetExternalConfigRequest());

      expect(result, isA<SetExternalConfigResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'SetExternalConfig');
      expect(fake.calls.single.request, isA<SetExternalConfigRequest>());
    });

    test('triggerCleanup sends StorageService/TriggerCleanup and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => TriggerCleanupResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'TriggerCleanup', <String, dynamic>{});

      final result = await client.triggerCleanup(TriggerCleanupRequest());

      expect(result, isA<TriggerCleanupResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'TriggerCleanup');
      expect(fake.calls.single.request, isA<TriggerCleanupRequest>());
    });

    test('previewCleanup sends StorageService/PreviewCleanup and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => PreviewCleanupResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'PreviewCleanup', <String, dynamic>{});

      final result = await client.previewCleanup(PreviewCleanupRequest());

      expect(result, isA<PreviewCleanupResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'PreviewCleanup');
      expect(fake.calls.single.request, isA<PreviewCleanupRequest>());
    });

    test('refreshExternalStorage sends StorageService/RefreshExternalStorage and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => RefreshExternalStorageResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'RefreshExternalStorage', <String, dynamic>{});

      final result = await client.refreshExternalStorage(RefreshExternalStorageRequest());

      expect(result, isA<RefreshExternalStorageResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'RefreshExternalStorage');
      expect(fake.calls.single.request, isA<RefreshExternalStorageRequest>());
    });

    test('listFormatVolumes sends StorageService/ListFormatVolumes and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => ListFormatVolumesResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'ListFormatVolumes', <String, dynamic>{});

      final result = await client.listFormatVolumes(ListFormatVolumesRequest());

      expect(result, isA<ListFormatVolumesResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'ListFormatVolumes');
      expect(fake.calls.single.request, isA<ListFormatVolumesRequest>());
    });

    test('formatVolume sends StorageService/FormatVolume and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => FormatVolumeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StorageService', 'FormatVolume', <String, dynamic>{});

      final result = await client.formatVolume(FormatVolumeRequest());

      expect(result, isA<FormatVolumeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StorageService');
      expect(fake.calls.single.method, 'FormatVolume');
      expect(fake.calls.single.request, isA<FormatVolumeRequest>());
    });

  });
}
