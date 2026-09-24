// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/surveillance.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use distancePresetDescriptor instead')
const DistancePreset$json = {
  '1': 'DistancePreset',
  '2': [
    {'1': 'DISTANCE_PRESET_UNSPECIFIED', '2': 0},
    {'1': 'DISTANCE_PRESET_NEAR', '2': 1},
    {'1': 'DISTANCE_PRESET_SHORT', '2': 2},
    {'1': 'DISTANCE_PRESET_MEDIUM', '2': 3},
    {'1': 'DISTANCE_PRESET_LONG', '2': 4},
    {'1': 'DISTANCE_PRESET_FAR', '2': 5},
  ],
};

/// Descriptor for `DistancePreset`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List distancePresetDescriptor = $convert.base64Decode(
    'Cg5EaXN0YW5jZVByZXNldBIfChtESVNUQU5DRV9QUkVTRVRfVU5TUEVDSUZJRUQQABIYChRESV'
    'NUQU5DRV9QUkVTRVRfTkVBUhABEhkKFURJU1RBTkNFX1BSRVNFVF9TSE9SVBACEhoKFkRJU1RB'
    'TkNFX1BSRVNFVF9NRURJVU0QAxIYChRESVNUQU5DRV9QUkVTRVRfTE9ORxAEEhcKE0RJU1RBTk'
    'NFX1BSRVNFVF9GQVIQBQ==');

@$core.Deprecated('Use surveillanceConfigDescriptor instead')
const SurveillanceConfig$json = {
  '1': 'SurveillanceConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'sensitivity', '3': 2, '4': 1, '5': 5, '10': 'sensitivity'},
    {'1': 'distance', '3': 3, '4': 1, '5': 5, '10': 'distance'},
    {'1': 'sad_threshold', '3': 4, '4': 1, '5': 1, '10': 'sadThreshold'},
    {
      '1': 'pre_record_seconds',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'preRecordSeconds'
    },
    {
      '1': 'post_record_seconds',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'postRecordSeconds'
    },
    {'1': 'total_blocks', '3': 7, '4': 1, '5': 5, '10': 'totalBlocks'},
    {'1': 'flash_immunity', '3': 8, '4': 1, '5': 5, '10': 'flashImmunity'},
    {'1': 'ai_enabled', '3': 9, '4': 1, '5': 8, '10': 'aiEnabled'},
    {'1': 'ai_confidence', '3': 10, '4': 1, '5': 1, '10': 'aiConfidence'},
    {'1': 'min_object_size', '3': 11, '4': 1, '5': 1, '10': 'minObjectSize'},
    {'1': 'detect_person', '3': 12, '4': 1, '5': 8, '10': 'detectPerson'},
    {'1': 'detect_car', '3': 13, '4': 1, '5': 8, '10': 'detectCar'},
    {'1': 'detect_bike', '3': 14, '4': 1, '5': 8, '10': 'detectBike'},
    {'1': 'distance_preset', '3': 15, '4': 1, '5': 9, '10': 'distancePreset'},
    {'1': 'block_size', '3': 16, '4': 1, '5': 5, '10': 'blockSize'},
    {'1': 'max_distance_m', '3': 17, '4': 1, '5': 1, '10': 'maxDistanceM'},
    {'1': 'night_mode', '3': 18, '4': 1, '5': 8, '10': 'nightMode'},
    {'1': 'shadow_threshold', '3': 19, '4': 1, '5': 1, '10': 'shadowThreshold'},
    {
      '1': 'density_threshold',
      '3': 20,
      '4': 1,
      '5': 1,
      '10': 'densityThreshold'
    },
    {
      '1': 'alarm_block_threshold',
      '3': 21,
      '4': 1,
      '5': 5,
      '10': 'alarmBlockThreshold'
    },
    {
      '1': 'recording_quality',
      '3': 22,
      '4': 1,
      '5': 9,
      '10': 'recordingQuality'
    },
    {'1': 'recording_codec', '3': 23, '4': 1, '5': 9, '10': 'recordingCodec'},
    {'1': 'camera_front', '3': 24, '4': 1, '5': 8, '10': 'cameraFront'},
    {'1': 'camera_right', '3': 25, '4': 1, '5': 8, '10': 'cameraRight'},
    {'1': 'camera_rear', '3': 26, '4': 1, '5': 8, '10': 'cameraRear'},
    {'1': 'camera_left', '3': 27, '4': 1, '5': 8, '10': 'cameraLeft'},
    {'1': 'deterrent_action', '3': 28, '4': 1, '5': 9, '10': 'deterrentAction'},
    {
      '1': 'deterrent_cooldown_seconds',
      '3': 29,
      '4': 1,
      '5': 5,
      '10': 'deterrentCooldownSeconds'
    },
  ],
  '9': [
    {'1': 30, '2': 35},
  ],
  '10': [
    'roi_polygons',
    'roi_enabled_q0',
    'roi_enabled_q1',
    'roi_enabled_q2',
    'roi_enabled_q3'
  ],
};

/// Descriptor for `SurveillanceConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List surveillanceConfigDescriptor = $convert.base64Decode(
    'ChJTdXJ2ZWlsbGFuY2VDb25maWcSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBIgCgtzZW5zaX'
    'Rpdml0eRgCIAEoBVILc2Vuc2l0aXZpdHkSGgoIZGlzdGFuY2UYAyABKAVSCGRpc3RhbmNlEiMK'
    'DXNhZF90aHJlc2hvbGQYBCABKAFSDHNhZFRocmVzaG9sZBIsChJwcmVfcmVjb3JkX3NlY29uZH'
    'MYBSABKAVSEHByZVJlY29yZFNlY29uZHMSLgoTcG9zdF9yZWNvcmRfc2Vjb25kcxgGIAEoBVIR'
    'cG9zdFJlY29yZFNlY29uZHMSIQoMdG90YWxfYmxvY2tzGAcgASgFUgt0b3RhbEJsb2NrcxIlCg'
    '5mbGFzaF9pbW11bml0eRgIIAEoBVINZmxhc2hJbW11bml0eRIdCgphaV9lbmFibGVkGAkgASgI'
    'UglhaUVuYWJsZWQSIwoNYWlfY29uZmlkZW5jZRgKIAEoAVIMYWlDb25maWRlbmNlEiYKD21pbl'
    '9vYmplY3Rfc2l6ZRgLIAEoAVINbWluT2JqZWN0U2l6ZRIjCg1kZXRlY3RfcGVyc29uGAwgASgI'
    'UgxkZXRlY3RQZXJzb24SHQoKZGV0ZWN0X2NhchgNIAEoCFIJZGV0ZWN0Q2FyEh8KC2RldGVjdF'
    '9iaWtlGA4gASgIUgpkZXRlY3RCaWtlEicKD2Rpc3RhbmNlX3ByZXNldBgPIAEoCVIOZGlzdGFu'
    'Y2VQcmVzZXQSHQoKYmxvY2tfc2l6ZRgQIAEoBVIJYmxvY2tTaXplEiQKDm1heF9kaXN0YW5jZV'
    '9tGBEgASgBUgxtYXhEaXN0YW5jZU0SHQoKbmlnaHRfbW9kZRgSIAEoCFIJbmlnaHRNb2RlEikK'
    'EHNoYWRvd190aHJlc2hvbGQYEyABKAFSD3NoYWRvd1RocmVzaG9sZBIrChFkZW5zaXR5X3Rocm'
    'VzaG9sZBgUIAEoAVIQZGVuc2l0eVRocmVzaG9sZBIyChVhbGFybV9ibG9ja190aHJlc2hvbGQY'
    'FSABKAVSE2FsYXJtQmxvY2tUaHJlc2hvbGQSKwoRcmVjb3JkaW5nX3F1YWxpdHkYFiABKAlSEH'
    'JlY29yZGluZ1F1YWxpdHkSJwoPcmVjb3JkaW5nX2NvZGVjGBcgASgJUg5yZWNvcmRpbmdDb2Rl'
    'YxIhCgxjYW1lcmFfZnJvbnQYGCABKAhSC2NhbWVyYUZyb250EiEKDGNhbWVyYV9yaWdodBgZIA'
    'EoCFILY2FtZXJhUmlnaHQSHwoLY2FtZXJhX3JlYXIYGiABKAhSCmNhbWVyYVJlYXISHwoLY2Ft'
    'ZXJhX2xlZnQYGyABKAhSCmNhbWVyYUxlZnQSKQoQZGV0ZXJyZW50X2FjdGlvbhgcIAEoCVIPZG'
    'V0ZXJyZW50QWN0aW9uEjwKGmRldGVycmVudF9jb29sZG93bl9zZWNvbmRzGB0gASgFUhhkZXRl'
    'cnJlbnRDb29sZG93blNlY29uZHNKBAgeECNSDHJvaV9wb2x5Z29uc1IOcm9pX2VuYWJsZWRfcT'
    'BSDnJvaV9lbmFibGVkX3ExUg5yb2lfZW5hYmxlZF9xMlIOcm9pX2VuYWJsZWRfcTM=');

@$core.Deprecated('Use getSurveillanceConfigRequestDescriptor instead')
const GetSurveillanceConfigRequest$json = {
  '1': 'GetSurveillanceConfigRequest',
};

/// Descriptor for `GetSurveillanceConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSurveillanceConfigRequestDescriptor =
    $convert.base64Decode('ChxHZXRTdXJ2ZWlsbGFuY2VDb25maWdSZXF1ZXN0');

@$core.Deprecated('Use getSurveillanceConfigResponseDescriptor instead')
const GetSurveillanceConfigResponse$json = {
  '1': 'GetSurveillanceConfigResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'config',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SurveillanceConfig',
      '10': 'config'
    },
  ],
};

/// Descriptor for `GetSurveillanceConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSurveillanceConfigResponseDescriptor =
    $convert.base64Decode(
        'Ch1HZXRTdXJ2ZWlsbGFuY2VDb25maWdSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZX'
        'NzEjkKBmNvbmZpZxgCIAEoCzIhLmJsYWRld2F0Y2gudjEuU3VydmVpbGxhbmNlQ29uZmlnUgZj'
        'b25maWc=');

@$core.Deprecated('Use setSurveillanceConfigRequestDescriptor instead')
const SetSurveillanceConfigRequest$json = {
  '1': 'SetSurveillanceConfigRequest',
  '2': [
    {
      '1': 'config',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SurveillanceConfig',
      '10': 'config'
    },
    {
      '1': 'manual_camera_id',
      '3': 2,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'manualCameraId',
      '17': true
    },
    {
      '1': 'clear_manual_camera_id',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'clearManualCameraId'
    },
  ],
  '8': [
    {'1': '_manual_camera_id'},
  ],
};

/// Descriptor for `SetSurveillanceConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSurveillanceConfigRequestDescriptor = $convert.base64Decode(
    'ChxTZXRTdXJ2ZWlsbGFuY2VDb25maWdSZXF1ZXN0EjkKBmNvbmZpZxgBIAEoCzIhLmJsYWRld2'
    'F0Y2gudjEuU3VydmVpbGxhbmNlQ29uZmlnUgZjb25maWcSLQoQbWFudWFsX2NhbWVyYV9pZBgC'
    'IAEoBUgAUg5tYW51YWxDYW1lcmFJZIgBARIzChZjbGVhcl9tYW51YWxfY2FtZXJhX2lkGAMgAS'
    'gIUhNjbGVhck1hbnVhbENhbWVyYUlkQhMKEV9tYW51YWxfY2FtZXJhX2lk');

@$core.Deprecated('Use setSurveillanceConfigResponseDescriptor instead')
const SetSurveillanceConfigResponse$json = {
  '1': 'SetSurveillanceConfigResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetSurveillanceConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSurveillanceConfigResponseDescriptor =
    $convert.base64Decode(
        'Ch1TZXRTdXJ2ZWlsbGFuY2VDb25maWdSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZX'
        'NzEhQKBWVycm9yGAIgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getSurveillanceStatusRequestDescriptor instead')
const GetSurveillanceStatusRequest$json = {
  '1': 'GetSurveillanceStatusRequest',
};

/// Descriptor for `GetSurveillanceStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSurveillanceStatusRequestDescriptor =
    $convert.base64Decode('ChxHZXRTdXJ2ZWlsbGFuY2VTdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use getSurveillanceStatusResponseDescriptor instead')
const GetSurveillanceStatusResponse$json = {
  '1': 'GetSurveillanceStatusResponse',
  '2': [
    {'1': 'pipeline_running', '3': 1, '4': 1, '5': 8, '10': 'pipelineRunning'},
    {
      '1': 'surveillance_active',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'surveillanceActive'
    },
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
    {'1': 'camera_yielded', '3': 5, '4': 1, '5': 8, '10': 'cameraYielded'},
    {'1': 'native_app_active', '3': 6, '4': 1, '5': 8, '10': 'nativeAppActive'},
  ],
  '9': [
    {'1': 3, '2': 4},
  ],
  '10': ['active_cameras'],
};

/// Descriptor for `GetSurveillanceStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSurveillanceStatusResponseDescriptor = $convert.base64Decode(
    'Ch1HZXRTdXJ2ZWlsbGFuY2VTdGF0dXNSZXNwb25zZRIpChBwaXBlbGluZV9ydW5uaW5nGAEgAS'
    'gIUg9waXBlbGluZVJ1bm5pbmcSLwoTc3VydmVpbGxhbmNlX2FjdGl2ZRgCIAEoCFISc3VydmVp'
    'bGxhbmNlQWN0aXZlEhQKBWVycm9yGAQgASgJUgVlcnJvchIlCg5jYW1lcmFfeWllbGRlZBgFIA'
    'EoCFINY2FtZXJhWWllbGRlZBIqChFuYXRpdmVfYXBwX2FjdGl2ZRgGIAEoCFIPbmF0aXZlQXBw'
    'QWN0aXZlSgQIAxAEUg5hY3RpdmVfY2FtZXJhcw==');

@$core.Deprecated('Use enableSurveillanceRequestDescriptor instead')
const EnableSurveillanceRequest$json = {
  '1': 'EnableSurveillanceRequest',
};

/// Descriptor for `EnableSurveillanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enableSurveillanceRequestDescriptor =
    $convert.base64Decode('ChlFbmFibGVTdXJ2ZWlsbGFuY2VSZXF1ZXN0');

@$core.Deprecated('Use enableSurveillanceResponseDescriptor instead')
const EnableSurveillanceResponse$json = {
  '1': 'EnableSurveillanceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `EnableSurveillanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enableSurveillanceResponseDescriptor =
    $convert.base64Decode(
        'ChpFbmFibGVTdXJ2ZWlsbGFuY2VSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'gKB21lc3NhZ2UYAiABKAlSB21lc3NhZ2USFAoFZXJyb3IYAyABKAlSBWVycm9y');

@$core.Deprecated('Use disableSurveillanceRequestDescriptor instead')
const DisableSurveillanceRequest$json = {
  '1': 'DisableSurveillanceRequest',
};

/// Descriptor for `DisableSurveillanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disableSurveillanceRequestDescriptor =
    $convert.base64Decode('ChpEaXNhYmxlU3VydmVpbGxhbmNlUmVxdWVzdA==');

@$core.Deprecated('Use disableSurveillanceResponseDescriptor instead')
const DisableSurveillanceResponse$json = {
  '1': 'DisableSurveillanceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `DisableSurveillanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disableSurveillanceResponseDescriptor =
    $convert.base64Decode(
        'ChtEaXNhYmxlU3VydmVpbGxhbmNlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcx'
        'IYCgdtZXNzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use getHeatmapRequestDescriptor instead')
const GetHeatmapRequest$json = {
  '1': 'GetHeatmapRequest',
};

/// Descriptor for `GetHeatmapRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHeatmapRequestDescriptor =
    $convert.base64Decode('ChFHZXRIZWF0bWFwUmVxdWVzdA==');

@$core.Deprecated('Use heatmapQuadrantDescriptor instead')
const HeatmapQuadrant$json = {
  '1': 'HeatmapQuadrant',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 5, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'enabled', '3': 3, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'suppressed', '3': 4, '4': 1, '5': 8, '10': 'suppressed'},
    {'1': 'mean_luma', '3': 5, '4': 1, '5': 1, '10': 'meanLuma'},
    {'1': 'active_blocks', '3': 6, '4': 1, '5': 5, '10': 'activeBlocks'},
    {'1': 'confirmed_blocks', '3': 7, '4': 1, '5': 5, '10': 'confirmedBlocks'},
    {'1': 'threat_level', '3': 8, '4': 1, '5': 5, '10': 'threatLevel'},
    {'1': 'component_size', '3': 9, '4': 1, '5': 5, '10': 'componentSize'},
    {'1': 'confidence', '3': 10, '4': 3, '5': 1, '10': 'confidence'},
  ],
};

/// Descriptor for `HeatmapQuadrant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heatmapQuadrantDescriptor = $convert.base64Decode(
    'Cg9IZWF0bWFwUXVhZHJhbnQSDgoCaWQYASABKAVSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGA'
    'oHZW5hYmxlZBgDIAEoCFIHZW5hYmxlZBIeCgpzdXBwcmVzc2VkGAQgASgIUgpzdXBwcmVzc2Vk'
    'EhsKCW1lYW5fbHVtYRgFIAEoAVIIbWVhbkx1bWESIwoNYWN0aXZlX2Jsb2NrcxgGIAEoBVIMYW'
    'N0aXZlQmxvY2tzEikKEGNvbmZpcm1lZF9ibG9ja3MYByABKAVSD2NvbmZpcm1lZEJsb2NrcxIh'
    'Cgx0aHJlYXRfbGV2ZWwYCCABKAVSC3RocmVhdExldmVsEiUKDmNvbXBvbmVudF9zaXplGAkgAS'
    'gFUg1jb21wb25lbnRTaXplEh4KCmNvbmZpZGVuY2UYCiADKAFSCmNvbmZpZGVuY2U=');

@$core.Deprecated('Use getHeatmapResponseDescriptor instead')
const GetHeatmapResponse$json = {
  '1': 'GetHeatmapResponse',
  '2': [
    {'1': 'grid_cols', '3': 2, '4': 1, '5': 5, '10': 'gridCols'},
    {'1': 'grid_rows', '3': 3, '4': 1, '5': 5, '10': 'gridRows'},
    {'1': 'view_mode', '3': 4, '4': 1, '5': 5, '10': 'viewMode'},
    {
      '1': 'quadrants',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.HeatmapQuadrant',
      '10': 'quadrants'
    },
  ],
  '9': [
    {'1': 1, '2': 2},
  ],
  '10': ['image_jpeg'],
};

/// Descriptor for `GetHeatmapResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHeatmapResponseDescriptor = $convert.base64Decode(
    'ChJHZXRIZWF0bWFwUmVzcG9uc2USGwoJZ3JpZF9jb2xzGAIgASgFUghncmlkQ29scxIbCglncm'
    'lkX3Jvd3MYAyABKAVSCGdyaWRSb3dzEhsKCXZpZXdfbW9kZRgEIAEoBVIIdmlld01vZGUSPAoJ'
    'cXVhZHJhbnRzGAUgAygLMh4uYmxhZGV3YXRjaC52MS5IZWF0bWFwUXVhZHJhbnRSCXF1YWRyYW'
    '50c0oECAEQAlIKaW1hZ2VfanBlZw==');

@$core.Deprecated('Use getSnapshotRequestDescriptor instead')
const GetSnapshotRequest$json = {
  '1': 'GetSnapshotRequest',
  '2': [
    {'1': 'quadrant', '3': 1, '4': 1, '5': 5, '10': 'quadrant'},
  ],
};

/// Descriptor for `GetSnapshotRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSnapshotRequestDescriptor =
    $convert.base64Decode(
        'ChJHZXRTbmFwc2hvdFJlcXVlc3QSGgoIcXVhZHJhbnQYASABKAVSCHF1YWRyYW50');

@$core.Deprecated('Use getSnapshotResponseDescriptor instead')
const GetSnapshotResponse$json = {
  '1': 'GetSnapshotResponse',
  '2': [
    {'1': 'image_jpeg', '3': 1, '4': 1, '5': 12, '10': 'imageJpeg'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `GetSnapshotResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSnapshotResponseDescriptor = $convert.base64Decode(
    'ChNHZXRTbmFwc2hvdFJlc3BvbnNlEh0KCmltYWdlX2pwZWcYASABKAxSCWltYWdlSnBlZxIUCg'
    'VlcnJvchgCIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use getFilterLogRequestDescriptor instead')
const GetFilterLogRequest$json = {
  '1': 'GetFilterLogRequest',
};

/// Descriptor for `GetFilterLogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFilterLogRequestDescriptor =
    $convert.base64Decode('ChNHZXRGaWx0ZXJMb2dSZXF1ZXN0');

@$core.Deprecated('Use getFilterLogResponseDescriptor instead')
const GetFilterLogResponse$json = {
  '1': 'GetFilterLogResponse',
  '2': [
    {'1': 'entries', '3': 2, '4': 3, '5': 9, '10': 'entries'},
    {'1': 'count', '3': 3, '4': 1, '5': 5, '10': 'count'},
  ],
  '9': [
    {'1': 1, '2': 2},
  ],
};

/// Descriptor for `GetFilterLogResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFilterLogResponseDescriptor = $convert.base64Decode(
    'ChRHZXRGaWx0ZXJMb2dSZXNwb25zZRIYCgdlbnRyaWVzGAIgAygJUgdlbnRyaWVzEhQKBWNvdW'
    '50GAMgASgFUgVjb3VudEoECAEQAg==');

@$core.Deprecated('Use syncSurveillanceCatalogRequestDescriptor instead')
const SyncSurveillanceCatalogRequest$json = {
  '1': 'SyncSurveillanceCatalogRequest',
};

/// Descriptor for `SyncSurveillanceCatalogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncSurveillanceCatalogRequestDescriptor =
    $convert.base64Decode('Ch5TeW5jU3VydmVpbGxhbmNlQ2F0YWxvZ1JlcXVlc3Q=');

@$core.Deprecated('Use syncSurveillanceCatalogResponseDescriptor instead')
const SyncSurveillanceCatalogResponse$json = {
  '1': 'SyncSurveillanceCatalogResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'added', '3': 3, '4': 1, '5': 5, '10': 'added'},
    {'1': 'removed', '3': 4, '4': 1, '5': 5, '10': 'removed'},
  ],
};

/// Descriptor for `SyncSurveillanceCatalogResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncSurveillanceCatalogResponseDescriptor =
    $convert.base64Decode(
        'Ch9TeW5jU3VydmVpbGxhbmNlQ2F0YWxvZ1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2'
        'Nlc3MSFAoFZXJyb3IYAiABKAlSBWVycm9yEhQKBWFkZGVkGAMgASgFUgVhZGRlZBIYCgdyZW1v'
        'dmVkGAQgASgFUgdyZW1vdmVk');

const $core.Map<$core.String, $core.dynamic> SurveillanceServiceBase$json = {
  '1': 'SurveillanceService',
  '2': [
    {
      '1': 'GetConfig',
      '2': '.bladewatch.v1.GetSurveillanceConfigRequest',
      '3': '.bladewatch.v1.GetSurveillanceConfigResponse'
    },
    {
      '1': 'SetConfig',
      '2': '.bladewatch.v1.SetSurveillanceConfigRequest',
      '3': '.bladewatch.v1.SetSurveillanceConfigResponse'
    },
    {
      '1': 'GetStatus',
      '2': '.bladewatch.v1.GetSurveillanceStatusRequest',
      '3': '.bladewatch.v1.GetSurveillanceStatusResponse'
    },
    {
      '1': 'Enable',
      '2': '.bladewatch.v1.EnableSurveillanceRequest',
      '3': '.bladewatch.v1.EnableSurveillanceResponse'
    },
    {
      '1': 'Disable',
      '2': '.bladewatch.v1.DisableSurveillanceRequest',
      '3': '.bladewatch.v1.DisableSurveillanceResponse'
    },
    {
      '1': 'GetHeatmap',
      '2': '.bladewatch.v1.GetHeatmapRequest',
      '3': '.bladewatch.v1.GetHeatmapResponse'
    },
    {
      '1': 'GetSnapshot',
      '2': '.bladewatch.v1.GetSnapshotRequest',
      '3': '.bladewatch.v1.GetSnapshotResponse'
    },
    {
      '1': 'GetFilterLog',
      '2': '.bladewatch.v1.GetFilterLogRequest',
      '3': '.bladewatch.v1.GetFilterLogResponse'
    },
    {
      '1': 'SyncCatalog',
      '2': '.bladewatch.v1.SyncSurveillanceCatalogRequest',
      '3': '.bladewatch.v1.SyncSurveillanceCatalogResponse'
    },
  ],
};

@$core.Deprecated('Use surveillanceServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    SurveillanceServiceBase$messageJson = {
  '.bladewatch.v1.GetSurveillanceConfigRequest':
      GetSurveillanceConfigRequest$json,
  '.bladewatch.v1.GetSurveillanceConfigResponse':
      GetSurveillanceConfigResponse$json,
  '.bladewatch.v1.SurveillanceConfig': SurveillanceConfig$json,
  '.bladewatch.v1.SetSurveillanceConfigRequest':
      SetSurveillanceConfigRequest$json,
  '.bladewatch.v1.SetSurveillanceConfigResponse':
      SetSurveillanceConfigResponse$json,
  '.bladewatch.v1.GetSurveillanceStatusRequest':
      GetSurveillanceStatusRequest$json,
  '.bladewatch.v1.GetSurveillanceStatusResponse':
      GetSurveillanceStatusResponse$json,
  '.bladewatch.v1.EnableSurveillanceRequest': EnableSurveillanceRequest$json,
  '.bladewatch.v1.EnableSurveillanceResponse': EnableSurveillanceResponse$json,
  '.bladewatch.v1.DisableSurveillanceRequest': DisableSurveillanceRequest$json,
  '.bladewatch.v1.DisableSurveillanceResponse':
      DisableSurveillanceResponse$json,
  '.bladewatch.v1.GetHeatmapRequest': GetHeatmapRequest$json,
  '.bladewatch.v1.GetHeatmapResponse': GetHeatmapResponse$json,
  '.bladewatch.v1.HeatmapQuadrant': HeatmapQuadrant$json,
  '.bladewatch.v1.GetSnapshotRequest': GetSnapshotRequest$json,
  '.bladewatch.v1.GetSnapshotResponse': GetSnapshotResponse$json,
  '.bladewatch.v1.GetFilterLogRequest': GetFilterLogRequest$json,
  '.bladewatch.v1.GetFilterLogResponse': GetFilterLogResponse$json,
  '.bladewatch.v1.SyncSurveillanceCatalogRequest':
      SyncSurveillanceCatalogRequest$json,
  '.bladewatch.v1.SyncSurveillanceCatalogResponse':
      SyncSurveillanceCatalogResponse$json,
};

/// Descriptor for `SurveillanceService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List surveillanceServiceDescriptor = $convert.base64Decode(
    'ChNTdXJ2ZWlsbGFuY2VTZXJ2aWNlEmYKCUdldENvbmZpZxIrLmJsYWRld2F0Y2gudjEuR2V0U3'
    'VydmVpbGxhbmNlQ29uZmlnUmVxdWVzdBosLmJsYWRld2F0Y2gudjEuR2V0U3VydmVpbGxhbmNl'
    'Q29uZmlnUmVzcG9uc2USZgoJU2V0Q29uZmlnEisuYmxhZGV3YXRjaC52MS5TZXRTdXJ2ZWlsbG'
    'FuY2VDb25maWdSZXF1ZXN0GiwuYmxhZGV3YXRjaC52MS5TZXRTdXJ2ZWlsbGFuY2VDb25maWdS'
    'ZXNwb25zZRJmCglHZXRTdGF0dXMSKy5ibGFkZXdhdGNoLnYxLkdldFN1cnZlaWxsYW5jZVN0YX'
    'R1c1JlcXVlc3QaLC5ibGFkZXdhdGNoLnYxLkdldFN1cnZlaWxsYW5jZVN0YXR1c1Jlc3BvbnNl'
    'El0KBkVuYWJsZRIoLmJsYWRld2F0Y2gudjEuRW5hYmxlU3VydmVpbGxhbmNlUmVxdWVzdBopLm'
    'JsYWRld2F0Y2gudjEuRW5hYmxlU3VydmVpbGxhbmNlUmVzcG9uc2USYAoHRGlzYWJsZRIpLmJs'
    'YWRld2F0Y2gudjEuRGlzYWJsZVN1cnZlaWxsYW5jZVJlcXVlc3QaKi5ibGFkZXdhdGNoLnYxLk'
    'Rpc2FibGVTdXJ2ZWlsbGFuY2VSZXNwb25zZRJRCgpHZXRIZWF0bWFwEiAuYmxhZGV3YXRjaC52'
    'MS5HZXRIZWF0bWFwUmVxdWVzdBohLmJsYWRld2F0Y2gudjEuR2V0SGVhdG1hcFJlc3BvbnNlEl'
    'QKC0dldFNuYXBzaG90EiEuYmxhZGV3YXRjaC52MS5HZXRTbmFwc2hvdFJlcXVlc3QaIi5ibGFk'
    'ZXdhdGNoLnYxLkdldFNuYXBzaG90UmVzcG9uc2USVwoMR2V0RmlsdGVyTG9nEiIuYmxhZGV3YX'
    'RjaC52MS5HZXRGaWx0ZXJMb2dSZXF1ZXN0GiMuYmxhZGV3YXRjaC52MS5HZXRGaWx0ZXJMb2dS'
    'ZXNwb25zZRJsCgtTeW5jQ2F0YWxvZxItLmJsYWRld2F0Y2gudjEuU3luY1N1cnZlaWxsYW5jZU'
    'NhdGFsb2dSZXF1ZXN0Gi4uYmxhZGV3YXRjaC52MS5TeW5jU3VydmVpbGxhbmNlQ2F0YWxvZ1Jl'
    'c3BvbnNl');
