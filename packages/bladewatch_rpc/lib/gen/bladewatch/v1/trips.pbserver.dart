// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/trips.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart' as $0;
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pbjson.dart';

export 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';

abstract class TripsServiceBase extends $pb.GeneratedService {
  $async.Future<$0.ListTripsResponse> listTrips(
      $pb.ServerContext ctx, $0.ListTripsRequest request);
  $async.Future<$0.GetTripResponse> getTrip(
      $pb.ServerContext ctx, $0.GetTripRequest request);
  $async.Future<$0.DeleteTripResponse> deleteTrip(
      $pb.ServerContext ctx, $0.DeleteTripRequest request);
  $async.Future<$0.GetSummaryResponse> getSummary(
      $pb.ServerContext ctx, $0.GetSummaryRequest request);
  $async.Future<$0.GetDnaResponse> getDna(
      $pb.ServerContext ctx, $0.GetDnaRequest request);
  $async.Future<$0.GetRangeResponse> getRange(
      $pb.ServerContext ctx, $0.GetRangeRequest request);
  $async.Future<$0.GetConfigResponse> getConfig(
      $pb.ServerContext ctx, $0.GetConfigRequest request);
  $async.Future<$0.SetConfigResponse> setConfig(
      $pb.ServerContext ctx, $0.SetConfigRequest request);
  $async.Future<$0.GetStorageResponse> getStorage(
      $pb.ServerContext ctx, $0.GetStorageRequest request);
  $async.Future<$0.SetStorageResponse> setStorage(
      $pb.ServerContext ctx, $0.SetStorageRequest request);
  $async.Future<$0.SyncTripsResponse> syncTrips(
      $pb.ServerContext ctx, $0.SyncTripsRequest request);
  $async.Future<$0.GetTelemetryResponse> getTelemetry(
      $pb.ServerContext ctx, $0.GetTelemetryRequest request);
  $async.Future<$0.GetSimilarTripsResponse> getSimilarTrips(
      $pb.ServerContext ctx, $0.GetSimilarTripsRequest request);
  $async.Future<$0.GetGpsTraceResponse> getGpsTrace(
      $pb.ServerContext ctx, $0.GetGpsTraceRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ListTrips':
        return $0.ListTripsRequest();
      case 'GetTrip':
        return $0.GetTripRequest();
      case 'DeleteTrip':
        return $0.DeleteTripRequest();
      case 'GetSummary':
        return $0.GetSummaryRequest();
      case 'GetDna':
        return $0.GetDnaRequest();
      case 'GetRange':
        return $0.GetRangeRequest();
      case 'GetConfig':
        return $0.GetConfigRequest();
      case 'SetConfig':
        return $0.SetConfigRequest();
      case 'GetStorage':
        return $0.GetStorageRequest();
      case 'SetStorage':
        return $0.SetStorageRequest();
      case 'SyncTrips':
        return $0.SyncTripsRequest();
      case 'GetTelemetry':
        return $0.GetTelemetryRequest();
      case 'GetSimilarTrips':
        return $0.GetSimilarTripsRequest();
      case 'GetGpsTrace':
        return $0.GetGpsTraceRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ListTrips':
        return listTrips(ctx, request as $0.ListTripsRequest);
      case 'GetTrip':
        return getTrip(ctx, request as $0.GetTripRequest);
      case 'DeleteTrip':
        return deleteTrip(ctx, request as $0.DeleteTripRequest);
      case 'GetSummary':
        return getSummary(ctx, request as $0.GetSummaryRequest);
      case 'GetDna':
        return getDna(ctx, request as $0.GetDnaRequest);
      case 'GetRange':
        return getRange(ctx, request as $0.GetRangeRequest);
      case 'GetConfig':
        return getConfig(ctx, request as $0.GetConfigRequest);
      case 'SetConfig':
        return setConfig(ctx, request as $0.SetConfigRequest);
      case 'GetStorage':
        return getStorage(ctx, request as $0.GetStorageRequest);
      case 'SetStorage':
        return setStorage(ctx, request as $0.SetStorageRequest);
      case 'SyncTrips':
        return syncTrips(ctx, request as $0.SyncTripsRequest);
      case 'GetTelemetry':
        return getTelemetry(ctx, request as $0.GetTelemetryRequest);
      case 'GetSimilarTrips':
        return getSimilarTrips(ctx, request as $0.GetSimilarTripsRequest);
      case 'GetGpsTrace':
        return getGpsTrace(ctx, request as $0.GetGpsTraceRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => TripsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => TripsServiceBase$messageJson;
}
