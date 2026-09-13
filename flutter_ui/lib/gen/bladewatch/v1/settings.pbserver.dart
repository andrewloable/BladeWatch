// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'settings.pb.dart' as $0;
import 'settings.pbjson.dart';

export 'settings.pb.dart';

abstract class SettingsServiceBase extends $pb.GeneratedService {
  $async.Future<$0.GetQualityResponse> getQuality(
      $pb.ServerContext ctx, $0.GetQualityRequest request);
  $async.Future<$0.SetQualityResponse> setQuality(
      $pb.ServerContext ctx, $0.SetQualityRequest request);
  $async.Future<$0.GetAppearanceResponse> getAppearance(
      $pb.ServerContext ctx, $0.GetAppearanceRequest request);
  $async.Future<$0.SetAppearanceResponse> setAppearance(
      $pb.ServerContext ctx, $0.SetAppearanceRequest request);
  $async.Future<$0.GetLocaleResponse> getLocale(
      $pb.ServerContext ctx, $0.GetLocaleRequest request);
  $async.Future<$0.SetLocaleResponse> setLocale(
      $pb.ServerContext ctx, $0.SetLocaleRequest request);
  $async.Future<$0.SetRecordingModeResponse> setRecordingMode(
      $pb.ServerContext ctx, $0.SetRecordingModeRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetQuality':
        return $0.GetQualityRequest();
      case 'SetQuality':
        return $0.SetQualityRequest();
      case 'GetAppearance':
        return $0.GetAppearanceRequest();
      case 'SetAppearance':
        return $0.SetAppearanceRequest();
      case 'GetLocale':
        return $0.GetLocaleRequest();
      case 'SetLocale':
        return $0.SetLocaleRequest();
      case 'SetRecordingMode':
        return $0.SetRecordingModeRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetQuality':
        return getQuality(ctx, request as $0.GetQualityRequest);
      case 'SetQuality':
        return setQuality(ctx, request as $0.SetQualityRequest);
      case 'GetAppearance':
        return getAppearance(ctx, request as $0.GetAppearanceRequest);
      case 'SetAppearance':
        return setAppearance(ctx, request as $0.SetAppearanceRequest);
      case 'GetLocale':
        return getLocale(ctx, request as $0.GetLocaleRequest);
      case 'SetLocale':
        return setLocale(ctx, request as $0.SetLocaleRequest);
      case 'SetRecordingMode':
        return setRecordingMode(ctx, request as $0.SetRecordingModeRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => SettingsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => SettingsServiceBase$messageJson;
}
