// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/system.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'system.pb.dart' as $0;
import 'system.pbjson.dart';

export 'system.pb.dart';

abstract class SystemServiceBase extends $pb.GeneratedService {
  $async.Future<$0.GetStatusResponse> getStatus(
      $pb.ServerContext ctx, $0.GetStatusRequest request);
  $async.Future<$0.GetPerformanceResponse> getPerformance(
      $pb.ServerContext ctx, $0.GetPerformanceRequest request);
  $async.Future<$0.PlayAudioTestResponse> playAudioTest(
      $pb.ServerContext ctx, $0.PlayAudioTestRequest request);
  $async.Future<$0.ListModelsResponse> listModels(
      $pb.ServerContext ctx, $0.ListModelsRequest request);
  $async.Future<$0.DownloadModelResponse> downloadModel(
      $pb.ServerContext ctx, $0.DownloadModelRequest request);
  $async.Future<$0.GetSohNominalResponse> getSohNominal(
      $pb.ServerContext ctx, $0.GetSohNominalRequest request);
  $async.Future<$0.SetSohNominalResponse> setSohNominal(
      $pb.ServerContext ctx, $0.SetSohNominalRequest request);
  $async.Future<$0.GetSohStatusResponse> getSohStatus(
      $pb.ServerContext ctx, $0.GetSohStatusRequest request);
  $async.Future<$0.ResetSohResponse> resetSoh(
      $pb.ServerContext ctx, $0.ResetSohRequest request);
  $async.Future<$0.ResetPerformanceResponse> resetPerformance(
      $pb.ServerContext ctx, $0.ResetPerformanceRequest request);
  $async.Future<$0.GetParkingDeltaResponse> getParkingDelta(
      $pb.ServerContext ctx, $0.GetParkingDeltaRequest request);
  $async.Future<$0.GetLastChargeResponse> getLastCharge(
      $pb.ServerContext ctx, $0.GetLastChargeRequest request);
  $async.Future<$0.GetSelectedModelResponse> getSelectedModel(
      $pb.ServerContext ctx, $0.GetSelectedModelRequest request);
  $async.Future<$0.SetSelectedModelResponse> setSelectedModel(
      $pb.ServerContext ctx, $0.SetSelectedModelRequest request);
  $async.Future<$0.GetModelsManifestResponse> getModelsManifest(
      $pb.ServerContext ctx, $0.GetModelsManifestRequest request);
  $async.Future<$0.PerformanceConnectResponse> performanceConnect(
      $pb.ServerContext ctx, $0.PerformanceConnectRequest request);
  $async.Future<$0.PerformanceHeartbeatResponse> performanceHeartbeat(
      $pb.ServerContext ctx, $0.PerformanceHeartbeatRequest request);
  $async.Future<$0.PerformanceDisconnectResponse> performanceDisconnect(
      $pb.ServerContext ctx, $0.PerformanceDisconnectRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetStatus':
        return $0.GetStatusRequest();
      case 'GetPerformance':
        return $0.GetPerformanceRequest();
      case 'PlayAudioTest':
        return $0.PlayAudioTestRequest();
      case 'ListModels':
        return $0.ListModelsRequest();
      case 'DownloadModel':
        return $0.DownloadModelRequest();
      case 'GetSohNominal':
        return $0.GetSohNominalRequest();
      case 'SetSohNominal':
        return $0.SetSohNominalRequest();
      case 'GetSohStatus':
        return $0.GetSohStatusRequest();
      case 'ResetSoh':
        return $0.ResetSohRequest();
      case 'ResetPerformance':
        return $0.ResetPerformanceRequest();
      case 'GetParkingDelta':
        return $0.GetParkingDeltaRequest();
      case 'GetLastCharge':
        return $0.GetLastChargeRequest();
      case 'GetSelectedModel':
        return $0.GetSelectedModelRequest();
      case 'SetSelectedModel':
        return $0.SetSelectedModelRequest();
      case 'GetModelsManifest':
        return $0.GetModelsManifestRequest();
      case 'PerformanceConnect':
        return $0.PerformanceConnectRequest();
      case 'PerformanceHeartbeat':
        return $0.PerformanceHeartbeatRequest();
      case 'PerformanceDisconnect':
        return $0.PerformanceDisconnectRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetStatus':
        return getStatus(ctx, request as $0.GetStatusRequest);
      case 'GetPerformance':
        return getPerformance(ctx, request as $0.GetPerformanceRequest);
      case 'PlayAudioTest':
        return playAudioTest(ctx, request as $0.PlayAudioTestRequest);
      case 'ListModels':
        return listModels(ctx, request as $0.ListModelsRequest);
      case 'DownloadModel':
        return downloadModel(ctx, request as $0.DownloadModelRequest);
      case 'GetSohNominal':
        return getSohNominal(ctx, request as $0.GetSohNominalRequest);
      case 'SetSohNominal':
        return setSohNominal(ctx, request as $0.SetSohNominalRequest);
      case 'GetSohStatus':
        return getSohStatus(ctx, request as $0.GetSohStatusRequest);
      case 'ResetSoh':
        return resetSoh(ctx, request as $0.ResetSohRequest);
      case 'ResetPerformance':
        return resetPerformance(ctx, request as $0.ResetPerformanceRequest);
      case 'GetParkingDelta':
        return getParkingDelta(ctx, request as $0.GetParkingDeltaRequest);
      case 'GetLastCharge':
        return getLastCharge(ctx, request as $0.GetLastChargeRequest);
      case 'GetSelectedModel':
        return getSelectedModel(ctx, request as $0.GetSelectedModelRequest);
      case 'SetSelectedModel':
        return setSelectedModel(ctx, request as $0.SetSelectedModelRequest);
      case 'GetModelsManifest':
        return getModelsManifest(ctx, request as $0.GetModelsManifestRequest);
      case 'PerformanceConnect':
        return performanceConnect(ctx, request as $0.PerformanceConnectRequest);
      case 'PerformanceHeartbeat':
        return performanceHeartbeat(
            ctx, request as $0.PerformanceHeartbeatRequest);
      case 'PerformanceDisconnect':
        return performanceDisconnect(
            ctx, request as $0.PerformanceDisconnectRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SystemServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SystemServiceBase$messageJson;
}
