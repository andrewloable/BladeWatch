// Hand-written Connect RPC wrapper for bladewatch.v1.VehicleService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_ui/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_ui/rpc/rpc_transport.dart';

class VehicleServiceClient {
  final RpcTransport _transport;

  const VehicleServiceClient(this._transport);

  Future<GetVehicleStateResponse> getState(GetVehicleStateRequest request) => _transport.call(
        'VehicleService',
        'GetState',
        request,
        (json) => GetVehicleStateResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetAcDiagnosticsResponse> getAcDiagnostics(GetAcDiagnosticsRequest request) => _transport.call(
        'VehicleService',
        'GetAcDiagnostics',
        request,
        (json) => GetAcDiagnosticsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetSeatDiagnosticsResponse> getSeatDiagnostics(GetSeatDiagnosticsRequest request) => _transport.call(
        'VehicleService',
        'GetSeatDiagnostics',
        request,
        (json) => GetSeatDiagnosticsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> lock(LockRequest request) => _transport.call(
        'VehicleService',
        'Lock',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> unlock(UnlockRequest request) => _transport.call(
        'VehicleService',
        'Unlock',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> trunk(TrunkRequest request) => _transport.call(
        'VehicleService',
        'Trunk',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> moveWindow(MoveWindowRequest request) => _transport.call(
        'VehicleService',
        'MoveWindow',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> flash(FlashRequest request) => _transport.call(
        'VehicleService',
        'Flash',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> findCar(FindCarRequest request) => _transport.call(
        'VehicleService',
        'FindCar',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> setClimate(SetClimateRequest request) => _transport.call(
        'VehicleService',
        'SetClimate',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> setSeat(SetSeatRequest request) => _transport.call(
        'VehicleService',
        'SetSeat',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> setLights(SetLightsRequest request) => _transport.call(
        'VehicleService',
        'SetLights',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> setAdas(SetAdasRequest request) => _transport.call(
        'VehicleService',
        'SetAdas',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> setBatteryHeat(SetBatteryHeatRequest request) => _transport.call(
        'VehicleService',
        'SetBatteryHeat',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetChargingScheduleResponse> getChargingSchedule(GetChargingScheduleRequest request) => _transport.call(
        'VehicleService',
        'GetChargingSchedule',
        request,
        (json) => GetChargingScheduleResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> setChargingSchedule(SetChargingScheduleRequest request) => _transport.call(
        'VehicleService',
        'SetChargingSchedule',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetChargeCapResponse> getChargeCap(GetChargeCapRequest request) => _transport.call(
        'VehicleService',
        'GetChargeCap',
        request,
        (json) => GetChargeCapResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<VehicleCommandResponse> setChargeCap(SetChargeCapRequest request) => _transport.call(
        'VehicleService',
        'SetChargeCap',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetGpsLocationResponse> getGpsLocation(GetGpsLocationRequest request) => _transport.call(
        'VehicleService',
        'GetGpsLocation',
        request,
        (json) => GetGpsLocationResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<StartGpsResponse> startGps(StartGpsRequest request) => _transport.call(
        'VehicleService',
        'StartGps',
        request,
        (json) => StartGpsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<StopGpsResponse> stopGps(StopGpsRequest request) => _transport.call(
        'VehicleService',
        'StopGps',
        request,
        (json) => StopGpsResponse()..mergeFromProto3Json(json ?? const {}),
      );

}
