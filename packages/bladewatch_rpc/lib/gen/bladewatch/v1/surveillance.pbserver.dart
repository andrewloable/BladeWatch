// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/surveillance.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart' as $0;
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pbjson.dart';

export 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';

abstract class SurveillanceServiceBase extends $pb.GeneratedService {
  $async.Future<$0.GetSurveillanceConfigResponse> getConfig(
      $pb.ServerContext ctx, $0.GetSurveillanceConfigRequest request);
  $async.Future<$0.SetSurveillanceConfigResponse> setConfig(
      $pb.ServerContext ctx, $0.SetSurveillanceConfigRequest request);
  $async.Future<$0.GetSurveillanceStatusResponse> getStatus(
      $pb.ServerContext ctx, $0.GetSurveillanceStatusRequest request);
  $async.Future<$0.EnableSurveillanceResponse> enable(
      $pb.ServerContext ctx, $0.EnableSurveillanceRequest request);
  $async.Future<$0.DisableSurveillanceResponse> disable(
      $pb.ServerContext ctx, $0.DisableSurveillanceRequest request);
  $async.Future<$0.GetHeatmapResponse> getHeatmap(
      $pb.ServerContext ctx, $0.GetHeatmapRequest request);
  $async.Future<$0.GetSnapshotResponse> getSnapshot(
      $pb.ServerContext ctx, $0.GetSnapshotRequest request);
  $async.Future<$0.GetFilterLogResponse> getFilterLog(
      $pb.ServerContext ctx, $0.GetFilterLogRequest request);
  $async.Future<$0.SyncSurveillanceCatalogResponse> syncCatalog(
      $pb.ServerContext ctx, $0.SyncSurveillanceCatalogRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetConfig':
        return $0.GetSurveillanceConfigRequest();
      case 'SetConfig':
        return $0.SetSurveillanceConfigRequest();
      case 'GetStatus':
        return $0.GetSurveillanceStatusRequest();
      case 'Enable':
        return $0.EnableSurveillanceRequest();
      case 'Disable':
        return $0.DisableSurveillanceRequest();
      case 'GetHeatmap':
        return $0.GetHeatmapRequest();
      case 'GetSnapshot':
        return $0.GetSnapshotRequest();
      case 'GetFilterLog':
        return $0.GetFilterLogRequest();
      case 'SyncCatalog':
        return $0.SyncSurveillanceCatalogRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetConfig':
        return getConfig(ctx, request as $0.GetSurveillanceConfigRequest);
      case 'SetConfig':
        return setConfig(ctx, request as $0.SetSurveillanceConfigRequest);
      case 'GetStatus':
        return getStatus(ctx, request as $0.GetSurveillanceStatusRequest);
      case 'Enable':
        return enable(ctx, request as $0.EnableSurveillanceRequest);
      case 'Disable':
        return disable(ctx, request as $0.DisableSurveillanceRequest);
      case 'GetHeatmap':
        return getHeatmap(ctx, request as $0.GetHeatmapRequest);
      case 'GetSnapshot':
        return getSnapshot(ctx, request as $0.GetSnapshotRequest);
      case 'GetFilterLog':
        return getFilterLog(ctx, request as $0.GetFilterLogRequest);
      case 'SyncCatalog':
        return syncCatalog(ctx, request as $0.SyncSurveillanceCatalogRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json =>
      SurveillanceServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SurveillanceServiceBase$messageJson;
}
