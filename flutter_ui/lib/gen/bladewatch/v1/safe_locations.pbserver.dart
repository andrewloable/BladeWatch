// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/safe_locations.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'safe_locations.pb.dart' as $0;
import 'safe_locations.pbjson.dart';

export 'safe_locations.pb.dart';

abstract class SafeLocationsServiceBase extends $pb.GeneratedService {
  $async.Future<$0.ListZonesResponse> listZones(
      $pb.ServerContext ctx, $0.ListZonesRequest request);
  $async.Future<$0.AddZoneResponse> addZone(
      $pb.ServerContext ctx, $0.AddZoneRequest request);
  $async.Future<$0.UpdateZoneResponse> updateZone(
      $pb.ServerContext ctx, $0.UpdateZoneRequest request);
  $async.Future<$0.DeleteZoneResponse> deleteZone(
      $pb.ServerContext ctx, $0.DeleteZoneRequest request);
  $async.Future<$0.ToggleSafeLocationsResponse> toggle(
      $pb.ServerContext ctx, $0.ToggleSafeLocationsRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ListZones':
        return $0.ListZonesRequest();
      case 'AddZone':
        return $0.AddZoneRequest();
      case 'UpdateZone':
        return $0.UpdateZoneRequest();
      case 'DeleteZone':
        return $0.DeleteZoneRequest();
      case 'Toggle':
        return $0.ToggleSafeLocationsRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ListZones':
        return listZones(ctx, request as $0.ListZonesRequest);
      case 'AddZone':
        return addZone(ctx, request as $0.AddZoneRequest);
      case 'UpdateZone':
        return updateZone(ctx, request as $0.UpdateZoneRequest);
      case 'DeleteZone':
        return deleteZone(ctx, request as $0.DeleteZoneRequest);
      case 'Toggle':
        return toggle(ctx, request as $0.ToggleSafeLocationsRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json =>
      SafeLocationsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SafeLocationsServiceBase$messageJson;
}
