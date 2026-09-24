// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/vehicle.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart' as $0;
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pbjson.dart';

export 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';

abstract class VehicleServiceBase extends $pb.GeneratedService {
  $async.Future<$0.GetVehicleStateResponse> getState(
      $pb.ServerContext ctx, $0.GetVehicleStateRequest request);
  $async.Future<$0.GetAcDiagnosticsResponse> getAcDiagnostics(
      $pb.ServerContext ctx, $0.GetAcDiagnosticsRequest request);
  $async.Future<$0.GetSeatDiagnosticsResponse> getSeatDiagnostics(
      $pb.ServerContext ctx, $0.GetSeatDiagnosticsRequest request);
  $async.Future<$0.VehicleCommandResponse> lock(
      $pb.ServerContext ctx, $0.LockRequest request);
  $async.Future<$0.VehicleCommandResponse> unlock(
      $pb.ServerContext ctx, $0.UnlockRequest request);
  $async.Future<$0.VehicleCommandResponse> trunk(
      $pb.ServerContext ctx, $0.TrunkRequest request);
  $async.Future<$0.VehicleCommandResponse> moveWindow(
      $pb.ServerContext ctx, $0.MoveWindowRequest request);
  $async.Future<$0.VehicleCommandResponse> flash(
      $pb.ServerContext ctx, $0.FlashRequest request);
  $async.Future<$0.VehicleCommandResponse> findCar(
      $pb.ServerContext ctx, $0.FindCarRequest request);
  $async.Future<$0.VehicleCommandResponse> setClimate(
      $pb.ServerContext ctx, $0.SetClimateRequest request);
  $async.Future<$0.VehicleCommandResponse> setSeat(
      $pb.ServerContext ctx, $0.SetSeatRequest request);
  $async.Future<$0.VehicleCommandResponse> setLights(
      $pb.ServerContext ctx, $0.SetLightsRequest request);
  $async.Future<$0.VehicleCommandResponse> setScreen(
      $pb.ServerContext ctx, $0.SetScreenRequest request);
  $async.Future<$0.VehicleCommandResponse> setMediaVolume(
      $pb.ServerContext ctx, $0.SetMediaVolumeRequest request);
  $async.Future<$0.VehicleCommandResponse> setAdas(
      $pb.ServerContext ctx, $0.SetAdasRequest request);
  $async.Future<$0.VehicleCommandResponse> setBatteryHeat(
      $pb.ServerContext ctx, $0.SetBatteryHeatRequest request);
  $async.Future<$0.GetChargingScheduleResponse> getChargingSchedule(
      $pb.ServerContext ctx, $0.GetChargingScheduleRequest request);
  $async.Future<$0.VehicleCommandResponse> setChargingSchedule(
      $pb.ServerContext ctx, $0.SetChargingScheduleRequest request);
  $async.Future<$0.GetChargeCapResponse> getChargeCap(
      $pb.ServerContext ctx, $0.GetChargeCapRequest request);
  $async.Future<$0.VehicleCommandResponse> setChargeCap(
      $pb.ServerContext ctx, $0.SetChargeCapRequest request);
  $async.Future<$0.GetGpsLocationResponse> getGpsLocation(
      $pb.ServerContext ctx, $0.GetGpsLocationRequest request);
  $async.Future<$0.StartGpsResponse> startGps(
      $pb.ServerContext ctx, $0.StartGpsRequest request);
  $async.Future<$0.StopGpsResponse> stopGps(
      $pb.ServerContext ctx, $0.StopGpsRequest request);
  $async.Future<$0.IssueActionTokenResponse> issueActionToken(
      $pb.ServerContext ctx, $0.IssueActionTokenRequest request);
  $async.Future<$0.GetAdasInventoryResponse> getAdasInventory(
      $pb.ServerContext ctx, $0.GetAdasInventoryRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetState':
        return $0.GetVehicleStateRequest();
      case 'GetAcDiagnostics':
        return $0.GetAcDiagnosticsRequest();
      case 'GetSeatDiagnostics':
        return $0.GetSeatDiagnosticsRequest();
      case 'Lock':
        return $0.LockRequest();
      case 'Unlock':
        return $0.UnlockRequest();
      case 'Trunk':
        return $0.TrunkRequest();
      case 'MoveWindow':
        return $0.MoveWindowRequest();
      case 'Flash':
        return $0.FlashRequest();
      case 'FindCar':
        return $0.FindCarRequest();
      case 'SetClimate':
        return $0.SetClimateRequest();
      case 'SetSeat':
        return $0.SetSeatRequest();
      case 'SetLights':
        return $0.SetLightsRequest();
      case 'SetScreen':
        return $0.SetScreenRequest();
      case 'SetMediaVolume':
        return $0.SetMediaVolumeRequest();
      case 'SetAdas':
        return $0.SetAdasRequest();
      case 'SetBatteryHeat':
        return $0.SetBatteryHeatRequest();
      case 'GetChargingSchedule':
        return $0.GetChargingScheduleRequest();
      case 'SetChargingSchedule':
        return $0.SetChargingScheduleRequest();
      case 'GetChargeCap':
        return $0.GetChargeCapRequest();
      case 'SetChargeCap':
        return $0.SetChargeCapRequest();
      case 'GetGpsLocation':
        return $0.GetGpsLocationRequest();
      case 'StartGps':
        return $0.StartGpsRequest();
      case 'StopGps':
        return $0.StopGpsRequest();
      case 'IssueActionToken':
        return $0.IssueActionTokenRequest();
      case 'GetAdasInventory':
        return $0.GetAdasInventoryRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetState':
        return getState(ctx, request as $0.GetVehicleStateRequest);
      case 'GetAcDiagnostics':
        return getAcDiagnostics(ctx, request as $0.GetAcDiagnosticsRequest);
      case 'GetSeatDiagnostics':
        return getSeatDiagnostics(ctx, request as $0.GetSeatDiagnosticsRequest);
      case 'Lock':
        return lock(ctx, request as $0.LockRequest);
      case 'Unlock':
        return unlock(ctx, request as $0.UnlockRequest);
      case 'Trunk':
        return trunk(ctx, request as $0.TrunkRequest);
      case 'MoveWindow':
        return moveWindow(ctx, request as $0.MoveWindowRequest);
      case 'Flash':
        return flash(ctx, request as $0.FlashRequest);
      case 'FindCar':
        return findCar(ctx, request as $0.FindCarRequest);
      case 'SetClimate':
        return setClimate(ctx, request as $0.SetClimateRequest);
      case 'SetSeat':
        return setSeat(ctx, request as $0.SetSeatRequest);
      case 'SetLights':
        return setLights(ctx, request as $0.SetLightsRequest);
      case 'SetScreen':
        return setScreen(ctx, request as $0.SetScreenRequest);
      case 'SetMediaVolume':
        return setMediaVolume(ctx, request as $0.SetMediaVolumeRequest);
      case 'SetAdas':
        return setAdas(ctx, request as $0.SetAdasRequest);
      case 'SetBatteryHeat':
        return setBatteryHeat(ctx, request as $0.SetBatteryHeatRequest);
      case 'GetChargingSchedule':
        return getChargingSchedule(
            ctx, request as $0.GetChargingScheduleRequest);
      case 'SetChargingSchedule':
        return setChargingSchedule(
            ctx, request as $0.SetChargingScheduleRequest);
      case 'GetChargeCap':
        return getChargeCap(ctx, request as $0.GetChargeCapRequest);
      case 'SetChargeCap':
        return setChargeCap(ctx, request as $0.SetChargeCapRequest);
      case 'GetGpsLocation':
        return getGpsLocation(ctx, request as $0.GetGpsLocationRequest);
      case 'StartGps':
        return startGps(ctx, request as $0.StartGpsRequest);
      case 'StopGps':
        return stopGps(ctx, request as $0.StopGpsRequest);
      case 'IssueActionToken':
        return issueActionToken(ctx, request as $0.IssueActionTokenRequest);
      case 'GetAdasInventory':
        return getAdasInventory(ctx, request as $0.GetAdasInventoryRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => VehicleServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => VehicleServiceBase$messageJson;
}
