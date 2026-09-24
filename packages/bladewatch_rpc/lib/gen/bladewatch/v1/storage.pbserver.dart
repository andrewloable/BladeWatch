// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/storage.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart' as $0;
import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pbjson.dart';

export 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart';

abstract class StorageServiceBase extends $pb.GeneratedService {
  $async.Future<$0.GetStorageSettingsResponse> getStorageSettings(
      $pb.ServerContext ctx, $0.GetStorageSettingsRequest request);
  $async.Future<$0.SetStorageSettingsResponse> setStorageSettings(
      $pb.ServerContext ctx, $0.SetStorageSettingsRequest request);
  $async.Future<$0.PreviewStorageLimitChangeResponse> previewStorageLimitChange(
      $pb.ServerContext ctx, $0.PreviewStorageLimitChangeRequest request);
  $async.Future<$0.GetExternalStorageResponse> getExternalStorage(
      $pb.ServerContext ctx, $0.GetExternalStorageRequest request);
  $async.Future<$0.SetExternalConfigResponse> setExternalConfig(
      $pb.ServerContext ctx, $0.SetExternalConfigRequest request);
  $async.Future<$0.TriggerCleanupResponse> triggerCleanup(
      $pb.ServerContext ctx, $0.TriggerCleanupRequest request);
  $async.Future<$0.PreviewCleanupResponse> previewCleanup(
      $pb.ServerContext ctx, $0.PreviewCleanupRequest request);
  $async.Future<$0.RefreshExternalStorageResponse> refreshExternalStorage(
      $pb.ServerContext ctx, $0.RefreshExternalStorageRequest request);
  $async.Future<$0.ListFormatVolumesResponse> listFormatVolumes(
      $pb.ServerContext ctx, $0.ListFormatVolumesRequest request);
  $async.Future<$0.FormatVolumeResponse> formatVolume(
      $pb.ServerContext ctx, $0.FormatVolumeRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'GetStorageSettings':
        return $0.GetStorageSettingsRequest();
      case 'SetStorageSettings':
        return $0.SetStorageSettingsRequest();
      case 'PreviewStorageLimitChange':
        return $0.PreviewStorageLimitChangeRequest();
      case 'GetExternalStorage':
        return $0.GetExternalStorageRequest();
      case 'SetExternalConfig':
        return $0.SetExternalConfigRequest();
      case 'TriggerCleanup':
        return $0.TriggerCleanupRequest();
      case 'PreviewCleanup':
        return $0.PreviewCleanupRequest();
      case 'RefreshExternalStorage':
        return $0.RefreshExternalStorageRequest();
      case 'ListFormatVolumes':
        return $0.ListFormatVolumesRequest();
      case 'FormatVolume':
        return $0.FormatVolumeRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'GetStorageSettings':
        return getStorageSettings(ctx, request as $0.GetStorageSettingsRequest);
      case 'SetStorageSettings':
        return setStorageSettings(ctx, request as $0.SetStorageSettingsRequest);
      case 'PreviewStorageLimitChange':
        return previewStorageLimitChange(
            ctx, request as $0.PreviewStorageLimitChangeRequest);
      case 'GetExternalStorage':
        return getExternalStorage(ctx, request as $0.GetExternalStorageRequest);
      case 'SetExternalConfig':
        return setExternalConfig(ctx, request as $0.SetExternalConfigRequest);
      case 'TriggerCleanup':
        return triggerCleanup(ctx, request as $0.TriggerCleanupRequest);
      case 'PreviewCleanup':
        return previewCleanup(ctx, request as $0.PreviewCleanupRequest);
      case 'RefreshExternalStorage':
        return refreshExternalStorage(
            ctx, request as $0.RefreshExternalStorageRequest);
      case 'ListFormatVolumes':
        return listFormatVolumes(ctx, request as $0.ListFormatVolumesRequest);
      case 'FormatVolume':
        return formatVolume(ctx, request as $0.FormatVolumeRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => StorageServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => StorageServiceBase$messageJson;
}
