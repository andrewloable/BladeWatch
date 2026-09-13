// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/stream.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'stream.pb.dart' as $0;
import 'stream.pbjson.dart';

export 'stream.pb.dart';

abstract class StreamServiceBase extends $pb.GeneratedService {
  $async.Future<$0.EnableStreamResponse> enable(
      $pb.ServerContext ctx, $0.EnableStreamRequest request);
  $async.Future<$0.DisableStreamResponse> disable(
      $pb.ServerContext ctx, $0.DisableStreamRequest request);
  $async.Future<$0.GetStreamStatusResponse> getStatus(
      $pb.ServerContext ctx, $0.GetStreamStatusRequest request);
  $async.Future<$0.GetStreamQualityResponse> getQuality(
      $pb.ServerContext ctx, $0.GetStreamQualityRequest request);
  $async.Future<$0.SetStreamQualityResponse> setQuality(
      $pb.ServerContext ctx, $0.SetStreamQualityRequest request);
  $async.Future<$0.SetViewModeResponse> setViewMode(
      $pb.ServerContext ctx, $0.SetViewModeRequest request);
  $async.Future<$0.GetViewModeResponse> getViewMode(
      $pb.ServerContext ctx, $0.GetViewModeRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Enable':
        return $0.EnableStreamRequest();
      case 'Disable':
        return $0.DisableStreamRequest();
      case 'GetStatus':
        return $0.GetStreamStatusRequest();
      case 'GetQuality':
        return $0.GetStreamQualityRequest();
      case 'SetQuality':
        return $0.SetStreamQualityRequest();
      case 'SetViewMode':
        return $0.SetViewModeRequest();
      case 'GetViewMode':
        return $0.GetViewModeRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Enable':
        return enable(ctx, request as $0.EnableStreamRequest);
      case 'Disable':
        return disable(ctx, request as $0.DisableStreamRequest);
      case 'GetStatus':
        return getStatus(ctx, request as $0.GetStreamStatusRequest);
      case 'GetQuality':
        return getQuality(ctx, request as $0.GetStreamQualityRequest);
      case 'SetQuality':
        return setQuality(ctx, request as $0.SetStreamQualityRequest);
      case 'SetViewMode':
        return setViewMode(ctx, request as $0.SetViewModeRequest);
      case 'GetViewMode':
        return getViewMode(ctx, request as $0.GetViewModeRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => StreamServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => StreamServiceBase$messageJson;
}
