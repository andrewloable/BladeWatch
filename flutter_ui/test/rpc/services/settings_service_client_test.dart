import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_ui/rpc/services/settings_service_client.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  group('SettingsServiceClient', () {
    late FakeRpcClient fake;
    late SettingsServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = SettingsServiceClient(fake);
    });

    test('getQuality sends SettingsService/GetQuality and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetQualityResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SettingsService', 'GetQuality', <String, dynamic>{});

      final result = await client.getQuality(GetQualityRequest());

      expect(result, isA<GetQualityResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'GetQuality');
      expect(fake.calls.single.request, isA<GetQualityRequest>());
    });

    test('setQuality sends SettingsService/SetQuality and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetQualityResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SettingsService', 'SetQuality', <String, dynamic>{});

      final result = await client.setQuality(SetQualityRequest());

      expect(result, isA<SetQualityResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'SetQuality');
      expect(fake.calls.single.request, isA<SetQualityRequest>());
    });

    test('getAppearance sends SettingsService/GetAppearance and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetAppearanceResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SettingsService', 'GetAppearance', <String, dynamic>{});

      final result = await client.getAppearance(GetAppearanceRequest());

      expect(result, isA<GetAppearanceResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'GetAppearance');
      expect(fake.calls.single.request, isA<GetAppearanceRequest>());
    });

    test('setAppearance sends SettingsService/SetAppearance and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetAppearanceResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SettingsService', 'SetAppearance', <String, dynamic>{});

      final result = await client.setAppearance(SetAppearanceRequest());

      expect(result, isA<SetAppearanceResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'SetAppearance');
      expect(fake.calls.single.request, isA<SetAppearanceRequest>());
    });

    test('getLocale sends SettingsService/GetLocale and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetLocaleResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SettingsService', 'GetLocale', <String, dynamic>{});

      final result = await client.getLocale(GetLocaleRequest());

      expect(result, isA<GetLocaleResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'GetLocale');
      expect(fake.calls.single.request, isA<GetLocaleRequest>());
    });

    test('setLocale sends SettingsService/SetLocale and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetLocaleResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SettingsService', 'SetLocale', <String, dynamic>{});

      final result = await client.setLocale(SetLocaleRequest());

      expect(result, isA<SetLocaleResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'SetLocale');
      expect(fake.calls.single.request, isA<SetLocaleRequest>());
    });

    test('setRecordingMode sends SettingsService/SetRecordingMode and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetRecordingModeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('SettingsService', 'SetRecordingMode', <String, dynamic>{});

      final result = await client.setRecordingMode(SetRecordingModeRequest());

      expect(result, isA<SetRecordingModeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'SetRecordingMode');
      expect(fake.calls.single.request, isA<SetRecordingModeRequest>());
    });

  });
}
