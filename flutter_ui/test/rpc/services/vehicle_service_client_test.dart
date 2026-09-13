import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_ui/rpc/services/vehicle_service_client.dart';

import '../../fakes/fake_rpc_client.dart';

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

    test('getSeatDiagnostics sends VehicleService/GetSeatDiagnostics and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetSeatDiagnosticsResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'GetSeatDiagnostics', <String, dynamic>{});

      final result = await client.getSeatDiagnostics(GetSeatDiagnosticsRequest());

      expect(result, isA<GetSeatDiagnosticsResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'GetSeatDiagnostics');
      expect(fake.calls.single.request, isA<GetSeatDiagnosticsRequest>());
    });

    test('lock sends VehicleService/Lock and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'Lock', <String, dynamic>{});

      final result = await client.lock(LockRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'Lock');
      expect(fake.calls.single.request, isA<LockRequest>());
    });

    test('unlock sends VehicleService/Unlock and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'Unlock', <String, dynamic>{});

      final result = await client.unlock(UnlockRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'Unlock');
      expect(fake.calls.single.request, isA<UnlockRequest>());
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

    test('flash sends VehicleService/Flash and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'Flash', <String, dynamic>{});

      final result = await client.flash(FlashRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'Flash');
      expect(fake.calls.single.request, isA<FlashRequest>());
    });

    test('findCar sends VehicleService/FindCar and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'FindCar', <String, dynamic>{});

      final result = await client.findCar(FindCarRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'FindCar');
      expect(fake.calls.single.request, isA<FindCarRequest>());
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

    test('setSeat sends VehicleService/SetSeat and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'SetSeat', <String, dynamic>{});

      final result = await client.setSeat(SetSeatRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetSeat');
      expect(fake.calls.single.request, isA<SetSeatRequest>());
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

    test('setBatteryHeat sends VehicleService/SetBatteryHeat and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'SetBatteryHeat', <String, dynamic>{});

      final result = await client.setBatteryHeat(SetBatteryHeatRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetBatteryHeat');
      expect(fake.calls.single.request, isA<SetBatteryHeatRequest>());
    });

    test('getChargingSchedule sends VehicleService/GetChargingSchedule and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetChargingScheduleResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'GetChargingSchedule', <String, dynamic>{});

      final result = await client.getChargingSchedule(GetChargingScheduleRequest());

      expect(result, isA<GetChargingScheduleResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'GetChargingSchedule');
      expect(fake.calls.single.request, isA<GetChargingScheduleRequest>());
    });

    test('setChargingSchedule sends VehicleService/SetChargingSchedule and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => VehicleCommandResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('VehicleService', 'SetChargingSchedule', <String, dynamic>{});

      final result = await client.setChargingSchedule(SetChargingScheduleRequest());

      expect(result, isA<VehicleCommandResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'VehicleService');
      expect(fake.calls.single.method, 'SetChargingSchedule');
      expect(fake.calls.single.request, isA<SetChargingScheduleRequest>());
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

  });
}
