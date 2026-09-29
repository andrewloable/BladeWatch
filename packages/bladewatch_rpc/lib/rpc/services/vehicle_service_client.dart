// Hand-written Connect RPC wrapper for bladewatch.v1.VehicleService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class VehicleServiceClient {
  final RpcTransport _transport;

  const VehicleServiceClient(this._transport);

  Future<GetVehicleStateResponse> getState(GetVehicleStateRequest request) => _transport.call(
        'VehicleService',
        'GetState',
        request,
        (json) => GetVehicleStateResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetAcDiagnosticsResponse> getAcDiagnostics(GetAcDiagnosticsRequest request) => _transport.call(
        'VehicleService',
        'GetAcDiagnostics',
        request,
        (json) => GetAcDiagnosticsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );



  Future<VehicleCommandResponse> trunk(TrunkRequest request) => _transport.call(
        'VehicleService',
        'Trunk',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<VehicleCommandResponse> moveWindow(MoveWindowRequest request) => _transport.call(
        'VehicleService',
        'MoveWindow',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );



  Future<VehicleCommandResponse> setClimate(SetClimateRequest request) => _transport.call(
        'VehicleService',
        'SetClimate',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<VehicleCommandResponse> setLights(SetLightsRequest request) => _transport.call(
        'VehicleService',
        'SetLights',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<VehicleCommandResponse> setScreen(SetScreenRequest request) => _transport.call(
        'VehicleService',
        'SetScreen',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<VehicleCommandResponse> setMediaVolume(SetMediaVolumeRequest request) => _transport.call(
        'VehicleService',
        'SetMediaVolume',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<VehicleCommandResponse> setAdas(SetAdasRequest request) => _transport.call(
        'VehicleService',
        'SetAdas',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );




  Future<GetChargeCapResponse> getChargeCap(GetChargeCapRequest request) => _transport.call(
        'VehicleService',
        'GetChargeCap',
        request,
        (json) => GetChargeCapResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<VehicleCommandResponse> setChargeCap(SetChargeCapRequest request) => _transport.call(
        'VehicleService',
        'SetChargeCap',
        request,
        (json) => VehicleCommandResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetGpsLocationResponse> getGpsLocation(GetGpsLocationRequest request) => _transport.call(
        'VehicleService',
        'GetGpsLocation',
        request,
        (json) => GetGpsLocationResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<StartGpsResponse> startGps(StartGpsRequest request) => _transport.call(
        'VehicleService',
        'StartGps',
        request,
        (json) => StartGpsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<StopGpsResponse> stopGps(StopGpsRequest request) => _transport.call(
        'VehicleService',
        'StopGps',
        request,
        (json) => StopGpsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  /// The short-lived second factor every remote caller needs on an actuating command
  /// (`X-Vehicle-Action-Token`, VehicleActionGate on the car).
  Future<IssueActionTokenResponse> issueActionToken(IssueActionTokenRequest request) => _transport.call(
        'VehicleService',
        'IssueActionToken',
        request,
        (json) => IssueActionTokenResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );
}
