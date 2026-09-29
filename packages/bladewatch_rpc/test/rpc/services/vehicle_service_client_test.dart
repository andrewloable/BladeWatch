import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('VehicleServiceClient', () {
    late FakeRpcClient fake;
    late VehicleServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = VehicleServiceClient(fake);
    });

    test('getState sends VehicleService/GetState and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetVehicleStateResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'GetState', <String, dynamic>{});

      final result = await client.getState(GetVehicleStateRequest());

      expect(result, isA<GetVehicleStateResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'GetState');
      expect(fake.calls.single.request, isA<GetVehicleStateRequest>());
    });

    test('getAcDiagnostics sends VehicleService/GetAcDiagnostics and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetAcDiagnosticsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'GetAcDiagnostics', <String, dynamic>{});

      final result = await client.getAcDiagnostics(GetAcDiagnosticsRequest());

      expect(result, isA<GetAcDiagnosticsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'GetAcDiagnostics');
      expect(fake.calls.single.request, isA<GetAcDiagnosticsRequest>());
    });



    test('trunk sends VehicleService/Trunk and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'Trunk', <String, dynamic>{});

      final result = await client.trunk(TrunkRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'Trunk');
      expect(fake.calls.single.request, isA<TrunkRequest>());
    });

    test('moveWindow sends VehicleService/MoveWindow and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'MoveWindow', <String, dynamic>{});

      final result = await client.moveWindow(MoveWindowRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'MoveWindow');
      expect(fake.calls.single.request, isA<MoveWindowRequest>());
    });



    test('setClimate sends VehicleService/SetClimate and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'SetClimate', <String, dynamic>{});

      final result = await client.setClimate(SetClimateRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetClimate');
      expect(fake.calls.single.request, isA<SetClimateRequest>());
    });

    test('setLights sends VehicleService/SetLights and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'SetLights', <String, dynamic>{});

      final result = await client.setLights(SetLightsRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetLights');
      expect(fake.calls.single.request, isA<SetLightsRequest>());
    });

    test('setAdas sends VehicleService/SetAdas and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'SetAdas', <String, dynamic>{});

      final result = await client.setAdas(SetAdasRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetAdas');
      expect(fake.calls.single.request, isA<SetAdasRequest>());
    });




    test('getChargeCap sends VehicleService/GetChargeCap and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetChargeCapResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'GetChargeCap', <String, dynamic>{});

      final result = await client.getChargeCap(GetChargeCapRequest());

      expect(result, isA<GetChargeCapResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'GetChargeCap');
      expect(fake.calls.single.request, isA<GetChargeCapRequest>());
    });

    test('setChargeCap sends VehicleService/SetChargeCap and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'SetChargeCap', <String, dynamic>{});

      final result = await client.setChargeCap(SetChargeCapRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetChargeCap');
      expect(fake.calls.single.request, isA<SetChargeCapRequest>());
    });

    test('getGpsLocation sends VehicleService/GetGpsLocation and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetGpsLocationResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'GetGpsLocation', <String, dynamic>{});

      final result = await client.getGpsLocation(GetGpsLocationRequest());

      expect(result, isA<GetGpsLocationResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'GetGpsLocation');
      expect(fake.calls.single.request, isA<GetGpsLocationRequest>());
    });

    test('startGps sends VehicleService/StartGps and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => StartGpsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'StartGps', <String, dynamic>{});

      final result = await client.startGps(StartGpsRequest());

      expect(result, isA<StartGpsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'StartGps');
      expect(fake.calls.single.request, isA<StartGpsRequest>());
    });

    test('stopGps sends VehicleService/StopGps and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => StopGpsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'StopGps', <String, dynamic>{});

      final result = await client.stopGps(StopGpsRequest());

      expect(result, isA<StopGpsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'StopGps');
      expect(fake.calls.single.request, isA<StopGpsRequest>());
    });

    test('setScreen sends VehicleService/SetScreen and decodes a real proto3Json response', () async {
      fake.stubJson('VehicleService', 'SetScreen', <String, dynamic>{});

      final result = await client.setScreen(SetScreenRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetScreen');
      expect(fake.calls.single.request, isA<SetScreenRequest>());
    });

    test('setMediaVolume sends VehicleService/SetMediaVolume and decodes a real proto3Json response', () async {
      fake.stubJson('VehicleService', 'SetMediaVolume', <String, dynamic>{});

      final result = await client.setMediaVolume(SetMediaVolumeRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetMediaVolume');
      expect(fake.calls.single.request, isA<SetMediaVolumeRequest>());
    });


    test('issueActionToken sends VehicleService/IssueActionToken and decodes the token', () async {
      fake.stubJson('VehicleService', 'IssueActionToken', <String, dynamic>{'success': true, 'token': 't', 'expiresInSeconds': 30});

      final result = await client.issueActionToken(IssueActionTokenRequest());

      expect(result.token, 't');
      expect(result.expiresInSeconds, 30);
      expect(fake.calls.single.method, 'IssueActionToken');
    });

  });
}
