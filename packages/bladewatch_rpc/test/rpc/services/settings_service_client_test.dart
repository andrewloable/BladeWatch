import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

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

    test('getTelemetryOverlayFields sends SettingsService/GetTelemetryOverlayFields and decodes a real proto3Json response', () async {
      fake.stubJson('SettingsService', 'GetTelemetryOverlayFields', <String, dynamic>{});

      final result = await client.getTelemetryOverlayFields(GetTelemetryOverlayFieldsRequest());

      expect(result, isA<GetTelemetryOverlayFieldsResponse>());
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'GetTelemetryOverlayFields');
      expect(fake.calls.single.request, isA<GetTelemetryOverlayFieldsRequest>());
    });

    test('setTelemetryOverlayFields sends SettingsService/SetTelemetryOverlayFields and decodes a real proto3Json response', () async {
      fake.stubJson('SettingsService', 'SetTelemetryOverlayFields', <String, dynamic>{});

      final result = await client.setTelemetryOverlayFields(SetTelemetryOverlayFieldsRequest());

      expect(result, isA<SetTelemetryOverlayFieldsResponse>());
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'SetTelemetryOverlayFields');
      expect(fake.calls.single.request, isA<SetTelemetryOverlayFieldsRequest>());
    });


    test('getStatusOverlay and setStatusOverlay send SettingsService/*StatusOverlay and decode', () async {
      fake.stubJson('SettingsService', 'GetStatusOverlay', <String, dynamic>{'cameraVisible': true});
      fake.stubJson('SettingsService', 'SetStatusOverlay', <String, dynamic>{'success': true});

      expect((await client.getStatusOverlay(GetStatusOverlayRequest())).cameraVisible, isTrue);
      expect((await client.setStatusOverlay(SetStatusOverlayRequest(tripVisible: true, setTripVisible: true))).success, isTrue);
      expect(fake.calls.map((c) => c.method), ['GetStatusOverlay', 'SetStatusOverlay']);
    });

    // BladeWatch-hr6r: the Settings PIN lock.

    test('getSettingsLock sends SettingsService/GetSettingsLock and decodes retryAfterMs from a proto3Json int64 string', () async {
      // int64 fields are serialised as JSON STRINGS in proto3 JSON, never bare numbers --
      // this proves mergeFromProto3Json actually decodes that shape, not just an int.
      fake.stubJson('SettingsService', 'GetSettingsLock', <String, dynamic>{'enabled': true, 'retryAfterMs': '45000'});

      final result = await client.getSettingsLock(GetSettingsLockRequest());

      expect(result, isA<GetSettingsLockResponse>());
      expect(result.enabled, isTrue);
      expect(result.retryAfterMs.toInt(), 45000);
      expect(fake.calls.single.service, 'SettingsService');
      expect(fake.calls.single.method, 'GetSettingsLock');
      expect(fake.calls.single.request, isA<GetSettingsLockRequest>());
    });

    test('setSettingsLock sends the enabled and pin fields and decodes success/error', () async {
      fake.stubJson('SettingsService', 'SetSettingsLock', <String, dynamic>{'success': true, 'error': ''});

      final result = await client.setSettingsLock(SetSettingsLockRequest(enabled: true, pin: '123456'));

      expect(result.success, isTrue);
      expect(result.error, '');
      expect(fake.calls.single.method, 'SetSettingsLock');
      final sent = fake.calls.single.request as SetSettingsLockRequest;
      expect(sent.enabled, isTrue);
      expect(sent.pin, '123456');
    });

    test('verifySettingsPin sends the pin and decodes ok, retryAfterMs and attemptsLeft', () async {
      fake.stubJson(
        'SettingsService',
        'VerifySettingsPin',
        <String, dynamic>{'ok': false, 'retryAfterMs': '60000', 'attemptsLeft': 0},
      );

      final result = await client.verifySettingsPin(VerifySettingsPinRequest(pin: '000000'));

      expect(result.ok, isFalse);
      expect(result.retryAfterMs.toInt(), 60000);
      expect(result.attemptsLeft, 0);
      expect(fake.calls.single.method, 'VerifySettingsPin');
      expect((fake.calls.single.request as VerifySettingsPinRequest).pin, '000000');
    });

  });
}
