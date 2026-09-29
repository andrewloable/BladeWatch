import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/rpc/services/stream_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('StreamServiceClient', () {
    late FakeRpcClient fake;
    late StreamServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = StreamServiceClient(fake);
    });

    test('enable sends StreamService/Enable and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => EnableStreamResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StreamService', 'Enable', <String, dynamic>{});

      final result = await client.enable(EnableStreamRequest());

      expect(result, isA<EnableStreamResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StreamService');
      expect(fake.calls.single.method, 'Enable');
      expect(fake.calls.single.request, isA<EnableStreamRequest>());
    });

    test('disable sends StreamService/Disable and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => DisableStreamResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StreamService', 'Disable', <String, dynamic>{});

      final result = await client.disable(DisableStreamRequest());

      expect(result, isA<DisableStreamResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StreamService');
      expect(fake.calls.single.method, 'Disable');
      expect(fake.calls.single.request, isA<DisableStreamRequest>());
    });

    test('getStatus sends StreamService/GetStatus and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetStreamStatusResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StreamService', 'GetStatus', <String, dynamic>{});

      final result = await client.getStatus(GetStreamStatusRequest());

      expect(result, isA<GetStreamStatusResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StreamService');
      expect(fake.calls.single.method, 'GetStatus');
      expect(fake.calls.single.request, isA<GetStreamStatusRequest>());
    });

    test('getQuality sends StreamService/GetQuality and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetStreamQualityResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StreamService', 'GetQuality', <String, dynamic>{});

      final result = await client.getQuality(GetStreamQualityRequest());

      expect(result, isA<GetStreamQualityResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StreamService');
      expect(fake.calls.single.method, 'GetQuality');
      expect(fake.calls.single.request, isA<GetStreamQualityRequest>());
    });

    test('setQuality sends StreamService/SetQuality and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetStreamQualityResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StreamService', 'SetQuality', <String, dynamic>{});

      final result = await client.setQuality(SetStreamQualityRequest());

      expect(result, isA<SetStreamQualityResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StreamService');
      expect(fake.calls.single.method, 'SetQuality');
      expect(fake.calls.single.request, isA<SetStreamQualityRequest>());
    });

    test('setViewMode sends StreamService/SetViewMode and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => SetViewModeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StreamService', 'SetViewMode', <String, dynamic>{});

      final result = await client.setViewMode(SetViewModeRequest());

      expect(result, isA<SetViewModeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StreamService');
      expect(fake.calls.single.method, 'SetViewMode');
      expect(fake.calls.single.request, isA<SetViewModeRequest>());
    });

    test('getViewMode sends StreamService/GetViewMode and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetViewModeResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('StreamService', 'GetViewMode', <String, dynamic>{});

      final result = await client.getViewMode(GetViewModeRequest());

      expect(result, isA<GetViewModeResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'StreamService');
      expect(fake.calls.single.method, 'GetViewMode');
      expect(fake.calls.single.request, isA<GetViewModeRequest>());
    });

  });
}
