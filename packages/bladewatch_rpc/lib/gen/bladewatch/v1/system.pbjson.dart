// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/system.proto.

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

@$core.Deprecated('Use batteryInfoDescriptor instead')
const BatteryInfo$json = {
  '1': 'BatteryInfo',
  '2': [
    {'1': 'level', '3': 1, '4': 1, '5': 9, '10': 'level'},
  ],
  '9': [
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
  ],
  '10': ['status', 'is_charging', 'status_string'],
};

/// Descriptor for `BatteryInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batteryInfoDescriptor = $convert.base64Decode(
    'CgtCYXR0ZXJ5SW5mbxIUCgVsZXZlbBgBIAEoCVIFbGV2ZWxKBAgCEANKBAgDEARKBAgEEAVSBn'
    'N0YXR1c1ILaXNfY2hhcmdpbmdSDXN0YXR1c19zdHJpbmc=');

@$core.Deprecated('Use chargingInfoDescriptor instead')
const ChargingInfo$json = {
  '1': 'ChargingInfo',
  '2': [
    {'1': 'state_name', '3': 1, '4': 1, '5': 9, '10': 'stateName'},
    {'1': 'status', '3': 2, '4': 1, '5': 9, '10': 'status'},
    {
      '1': 'charging_power_k_w',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'chargingPowerKW'
    },
    {'1': 'is_discharging', '3': 4, '4': 1, '5': 8, '10': 'isDischarging'},
    {'1': 'is_error', '3': 5, '4': 1, '5': 8, '10': 'isError'},
    {'1': 'is_estimated', '3': 6, '4': 1, '5': 8, '10': 'isEstimated'},
  ],
};

/// Descriptor for `ChargingInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chargingInfoDescriptor = $convert.base64Decode(
    'CgxDaGFyZ2luZ0luZm8SHQoKc3RhdGVfbmFtZRgBIAEoCVIJc3RhdGVOYW1lEhYKBnN0YXR1cx'
    'gCIAEoCVIGc3RhdHVzEisKEmNoYXJnaW5nX3Bvd2VyX2tfdxgDIAEoAVIPY2hhcmdpbmdQb3dl'
    'cktXEiUKDmlzX2Rpc2NoYXJnaW5nGAQgASgIUg1pc0Rpc2NoYXJnaW5nEhkKCGlzX2Vycm9yGA'
    'UgASgIUgdpc0Vycm9yEiEKDGlzX2VzdGltYXRlZBgGIAEoCFILaXNFc3RpbWF0ZWQ=');

@$core.Deprecated('Use socInfoDescriptor instead')
const SocInfo$json = {
  '1': 'SocInfo',
  '2': [
    {'1': 'percent', '3': 1, '4': 1, '5': 1, '10': 'percent'},
    {'1': 'is_low', '3': 2, '4': 1, '5': 8, '10': 'isLow'},
    {'1': 'is_critical', '3': 3, '4': 1, '5': 8, '10': 'isCritical'},
    {'1': 'status', '3': 4, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `SocInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List socInfoDescriptor = $convert.base64Decode(
    'CgdTb2NJbmZvEhgKB3BlcmNlbnQYASABKAFSB3BlcmNlbnQSFQoGaXNfbG93GAIgASgIUgVpc0'
    'xvdxIfCgtpc19jcml0aWNhbBgDIAEoCFIKaXNDcml0aWNhbBIWCgZzdGF0dXMYBCABKAlSBnN0'
    'YXR1cw==');

@$core.Deprecated('Use rangeInfoDescriptor instead')
const RangeInfo$json = {
  '1': 'RangeInfo',
  '2': [
    {'1': 'elec_range_km', '3': 1, '4': 1, '5': 1, '10': 'elecRangeKm'},
    {'1': 'fuel_range_km', '3': 2, '4': 1, '5': 1, '10': 'fuelRangeKm'},
    {'1': 'total_range_km', '3': 3, '4': 1, '5': 1, '10': 'totalRangeKm'},
    {'1': 'is_low', '3': 4, '4': 1, '5': 8, '10': 'isLow'},
    {'1': 'is_critical', '3': 5, '4': 1, '5': 8, '10': 'isCritical'},
    {'1': 'status', '3': 6, '4': 1, '5': 9, '10': 'status'},
    {'1': 'fuel_percent', '3': 7, '4': 1, '5': 1, '10': 'fuelPercent'},
  ],
};

/// Descriptor for `RangeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rangeInfoDescriptor = $convert.base64Decode(
    'CglSYW5nZUluZm8SIgoNZWxlY19yYW5nZV9rbRgBIAEoAVILZWxlY1JhbmdlS20SIgoNZnVlbF'
    '9yYW5nZV9rbRgCIAEoAVILZnVlbFJhbmdlS20SJAoOdG90YWxfcmFuZ2Vfa20YAyABKAFSDHRv'
    'dGFsUmFuZ2VLbRIVCgZpc19sb3cYBCABKAhSBWlzTG93Eh8KC2lzX2NyaXRpY2FsGAUgASgIUg'
    'ppc0NyaXRpY2FsEhYKBnN0YXR1cxgGIAEoCVIGc3RhdHVzEiEKDGZ1ZWxfcGVyY2VudBgHIAEo'
    'AVILZnVlbFBlcmNlbnQ=');

@$core.Deprecated('Use sohInfoDescriptor instead')
const SohInfo$json = {
  '1': 'SohInfo',
  '2': [
    {'1': 'percent', '3': 1, '4': 1, '5': 1, '10': 'percent'},
  ],
};

/// Descriptor for `SohInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sohInfoDescriptor =
    $convert.base64Decode('CgdTb2hJbmZvEhgKB3BlcmNlbnQYASABKAFSB3BlcmNlbnQ=');

@$core.Deprecated('Use recordingStatusDescriptor instead')
const RecordingStatus$json = {
  '1': 'RecordingStatus',
  '2': [
    {'1': 'configured_mode', '3': 1, '4': 1, '5': 9, '10': 'configuredMode'},
    {'1': 'is_recording', '3': 2, '4': 1, '5': 8, '10': 'isRecording'},
    {'1': 'pipeline_running', '3': 3, '4': 1, '5': 8, '10': 'pipelineRunning'},
    {'1': 'gear', '3': 4, '4': 1, '5': 9, '10': 'gear'},
    {'1': 'acc_on', '3': 5, '4': 1, '5': 8, '10': 'accOn'},
  ],
};

/// Descriptor for `RecordingStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingStatusDescriptor = $convert.base64Decode(
    'Cg9SZWNvcmRpbmdTdGF0dXMSJwoPY29uZmlndXJlZF9tb2RlGAEgASgJUg5jb25maWd1cmVkTW'
    '9kZRIhCgxpc19yZWNvcmRpbmcYAiABKAhSC2lzUmVjb3JkaW5nEikKEHBpcGVsaW5lX3J1bm5p'
    'bmcYAyABKAhSD3BpcGVsaW5lUnVubmluZxISCgRnZWFyGAQgASgJUgRnZWFyEhUKBmFjY19vbh'
    'gFIAEoCFIFYWNjT24=');

@$core.Deprecated('Use tripStatusDescriptor instead')
const TripStatus$json = {
  '1': 'TripStatus',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'trip_active', '3': 2, '4': 1, '5': 8, '10': 'tripActive'},
    {'1': 'trip_start_time', '3': 3, '4': 1, '5': 3, '10': 'tripStartTime'},
    {'1': 'trip_duration_sec', '3': 4, '4': 1, '5': 3, '10': 'tripDurationSec'},
  ],
};

/// Descriptor for `TripStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tripStatusDescriptor = $convert.base64Decode(
    'CgpUcmlwU3RhdHVzEhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSHwoLdHJpcF9hY3RpdmUYAi'
    'ABKAhSCnRyaXBBY3RpdmUSJgoPdHJpcF9zdGFydF90aW1lGAMgASgDUg10cmlwU3RhcnRUaW1l'
    'EioKEXRyaXBfZHVyYXRpb25fc2VjGAQgASgDUg90cmlwRHVyYXRpb25TZWM=');

@$core.Deprecated('Use networkInfoDescriptor instead')
const NetworkInfo$json = {
  '1': 'NetworkInfo',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'ssid', '3': 2, '4': 1, '5': 9, '10': 'ssid'},
    {'1': 'ip', '3': 3, '4': 1, '5': 9, '10': 'ip'},
    {'1': 'lan_http_enabled', '3': 4, '4': 1, '5': 8, '10': 'lanHttpEnabled'},
    {'1': 'http_bind', '3': 5, '4': 1, '5': 9, '10': 'httpBind'},
    {'1': 'http_mode_warning', '3': 6, '4': 1, '5': 9, '10': 'httpModeWarning'},
    {'1': 'this_month_bytes', '3': 7, '4': 1, '5': 3, '10': 'thisMonthBytes'},
    {'1': 'last_month_bytes', '3': 8, '4': 1, '5': 3, '10': 'lastMonthBytes'},
  ],
};

/// Descriptor for `NetworkInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List networkInfoDescriptor = $convert.base64Decode(
    'CgtOZXR3b3JrSW5mbxISCgR0eXBlGAEgASgJUgR0eXBlEhIKBHNzaWQYAiABKAlSBHNzaWQSDg'
    'oCaXAYAyABKAlSAmlwEigKEGxhbl9odHRwX2VuYWJsZWQYBCABKAhSDmxhbkh0dHBFbmFibGVk'
    'EhsKCWh0dHBfYmluZBgFIAEoCVIIaHR0cEJpbmQSKgoRaHR0cF9tb2RlX3dhcm5pbmcYBiABKA'
    'lSD2h0dHBNb2RlV2FybmluZxIoChB0aGlzX21vbnRoX2J5dGVzGAcgASgDUg50aGlzTW9udGhC'
    'eXRlcxIoChBsYXN0X21vbnRoX2J5dGVzGAggASgDUg5sYXN0TW9udGhCeXRlcw==');

@$core.Deprecated('Use gpsStatusInfoDescriptor instead')
const GpsStatusInfo$json = {
  '1': 'GpsStatusInfo',
  '2': [
    {'1': 'lat', '3': 1, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lng', '3': 2, '4': 1, '5': 1, '10': 'lng'},
    {'1': 'speed_kmh', '3': 3, '4': 1, '5': 1, '10': 'speedKmh'},
    {'1': 'has_location', '3': 4, '4': 1, '5': 8, '10': 'hasLocation'},
  ],
};

/// Descriptor for `GpsStatusInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gpsStatusInfoDescriptor = $convert.base64Decode(
    'Cg1HcHNTdGF0dXNJbmZvEhAKA2xhdBgBIAEoAVIDbGF0EhAKA2xuZxgCIAEoAVIDbG5nEhsKCX'
    'NwZWVkX2ttaBgDIAEoAVIIc3BlZWRLbWgSIQoMaGFzX2xvY2F0aW9uGAQgASgIUgtoYXNMb2Nh'
    'dGlvbg==');

@$core.Deprecated('Use getStatusRequestDescriptor instead')
const GetStatusRequest$json = {
  '1': 'GetStatusRequest',
};

/// Descriptor for `GetStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusRequestDescriptor =
    $convert.base64Decode('ChBHZXRTdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use getStatusResponseDescriptor instead')
const GetStatusResponse$json = {
  '1': 'GetStatusResponse',
  '2': [
    {'1': 'device_id', '3': 1, '4': 1, '5': 9, '10': 'deviceId'},
    {
      '1': 'vehicle_data_ready',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'vehicleDataReady'
    },
    {'1': 'app_version', '3': 3, '4': 1, '5': 9, '10': 'appVersion'},
    {'1': 'recording', '3': 4, '4': 3, '5': 5, '10': 'recording'},
    {'1': 'viewing', '3': 5, '4': 3, '5': 5, '10': 'viewing'},
    {'1': 'active', '3': 6, '4': 3, '5': 5, '10': 'active'},
    {'1': 'available', '3': 7, '4': 3, '5': 5, '10': 'available'},
    {
      '1': 'battery',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.BatteryInfo',
      '10': 'battery'
    },
    {'1': 'acc', '3': 9, '4': 1, '5': 8, '10': 'acc'},
    {
      '1': 'charging',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.ChargingInfo',
      '10': 'charging'
    },
    {
      '1': 'soc',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SocInfo',
      '10': 'soc'
    },
    {
      '1': 'range',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.RangeInfo',
      '10': 'range'
    },
    {
      '1': 'soh',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SohInfo',
      '10': 'soh'
    },
    {'1': 'distance_unit', '3': 14, '4': 1, '5': 9, '10': 'distanceUnit'},
    {'1': 'locale', '3': 15, '4': 1, '5': 9, '10': 'locale'},
    {
      '1': 'safe_zone_suppressed',
      '3': 16,
      '4': 1,
      '5': 8,
      '10': 'safeZoneSuppressed'
    },
    {'1': 'in_safe_zone', '3': 17, '4': 1, '5': 8, '10': 'inSafeZone'},
    {'1': 'safe_zone_name', '3': 18, '4': 1, '5': 9, '10': 'safeZoneName'},
    {'1': 'gpu_surveillance', '3': 19, '4': 1, '5': 8, '10': 'gpuSurveillance'},
    {
      '1': 'recording_status',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.RecordingStatus',
      '10': 'recordingStatus'
    },
    {
      '1': 'trip_status',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TripStatus',
      '10': 'tripStatus'
    },
    {
      '1': 'network',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.NetworkInfo',
      '10': 'network'
    },
    {
      '1': 'vehicle_data_error',
      '3': 24,
      '4': 1,
      '5': 9,
      '10': 'vehicleDataError'
    },
    {
      '1': 'drive_status',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.DriveStatus',
      '10': 'driveStatus'
    },
  ],
  '9': [
    {'1': 22, '2': 23},
  ],
  '10': ['gps_json'],
};

/// Descriptor for `GetStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusResponseDescriptor = $convert.base64Decode(
    'ChFHZXRTdGF0dXNSZXNwb25zZRIbCglkZXZpY2VfaWQYASABKAlSCGRldmljZUlkEiwKEnZlaG'
    'ljbGVfZGF0YV9yZWFkeRgCIAEoCFIQdmVoaWNsZURhdGFSZWFkeRIfCgthcHBfdmVyc2lvbhgD'
    'IAEoCVIKYXBwVmVyc2lvbhIcCglyZWNvcmRpbmcYBCADKAVSCXJlY29yZGluZxIYCgd2aWV3aW'
    '5nGAUgAygFUgd2aWV3aW5nEhYKBmFjdGl2ZRgGIAMoBVIGYWN0aXZlEhwKCWF2YWlsYWJsZRgH'
    'IAMoBVIJYXZhaWxhYmxlEjQKB2JhdHRlcnkYCCABKAsyGi5ibGFkZXdhdGNoLnYxLkJhdHRlcn'
    'lJbmZvUgdiYXR0ZXJ5EhAKA2FjYxgJIAEoCFIDYWNjEjcKCGNoYXJnaW5nGAogASgLMhsuYmxh'
    'ZGV3YXRjaC52MS5DaGFyZ2luZ0luZm9SCGNoYXJnaW5nEigKA3NvYxgLIAEoCzIWLmJsYWRld2'
    'F0Y2gudjEuU29jSW5mb1IDc29jEi4KBXJhbmdlGAwgASgLMhguYmxhZGV3YXRjaC52MS5SYW5n'
    'ZUluZm9SBXJhbmdlEigKA3NvaBgNIAEoCzIWLmJsYWRld2F0Y2gudjEuU29oSW5mb1IDc29oEi'
    'MKDWRpc3RhbmNlX3VuaXQYDiABKAlSDGRpc3RhbmNlVW5pdBIWCgZsb2NhbGUYDyABKAlSBmxv'
    'Y2FsZRIwChRzYWZlX3pvbmVfc3VwcHJlc3NlZBgQIAEoCFISc2FmZVpvbmVTdXBwcmVzc2VkEi'
    'AKDGluX3NhZmVfem9uZRgRIAEoCFIKaW5TYWZlWm9uZRIkCg5zYWZlX3pvbmVfbmFtZRgSIAEo'
    'CVIMc2FmZVpvbmVOYW1lEikKEGdwdV9zdXJ2ZWlsbGFuY2UYEyABKAhSD2dwdVN1cnZlaWxsYW'
    '5jZRJJChByZWNvcmRpbmdfc3RhdHVzGBQgASgLMh4uYmxhZGV3YXRjaC52MS5SZWNvcmRpbmdT'
    'dGF0dXNSD3JlY29yZGluZ1N0YXR1cxI6Cgt0cmlwX3N0YXR1cxgVIAEoCzIZLmJsYWRld2F0Y2'
    'gudjEuVHJpcFN0YXR1c1IKdHJpcFN0YXR1cxI0CgduZXR3b3JrGBcgASgLMhouYmxhZGV3YXRj'
    'aC52MS5OZXR3b3JrSW5mb1IHbmV0d29yaxIsChJ2ZWhpY2xlX2RhdGFfZXJyb3IYGCABKAlSEH'
    'ZlaGljbGVEYXRhRXJyb3ISPQoMZHJpdmVfc3RhdHVzGBkgASgLMhouYmxhZGV3YXRjaC52MS5E'
    'cml2ZVN0YXR1c1ILZHJpdmVTdGF0dXNKBAgWEBdSCGdwc19qc29u');

@$core.Deprecated('Use driveStatusDescriptor instead')
const DriveStatus$json = {
  '1': 'DriveStatus',
  '2': [
    {'1': 'gear', '3': 1, '4': 1, '5': 9, '10': 'gear'},
    {'1': 'drive_mode', '3': 2, '4': 1, '5': 9, '10': 'driveMode'},
    {'1': 'drive_mode_raw', '3': 3, '4': 1, '5': 5, '10': 'driveModeRaw'},
    {'1': 'auto_hold', '3': 4, '4': 1, '5': 9, '10': 'autoHold'},
    {'1': 'auto_hold_raw', '3': 5, '4': 1, '5': 5, '10': 'autoHoldRaw'},
    {'1': 'energy_mode', '3': 6, '4': 1, '5': 9, '10': 'energyMode'},
    {'1': 'energy_mode_raw', '3': 7, '4': 1, '5': 5, '10': 'energyModeRaw'},
  ],
};

/// Descriptor for `DriveStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List driveStatusDescriptor = $convert.base64Decode(
    'CgtEcml2ZVN0YXR1cxISCgRnZWFyGAEgASgJUgRnZWFyEh0KCmRyaXZlX21vZGUYAiABKAlSCW'
    'RyaXZlTW9kZRIkCg5kcml2ZV9tb2RlX3JhdxgDIAEoBVIMZHJpdmVNb2RlUmF3EhsKCWF1dG9f'
    'aG9sZBgEIAEoCVIIYXV0b0hvbGQSIgoNYXV0b19ob2xkX3JhdxgFIAEoBVILYXV0b0hvbGRSYX'
    'cSHwoLZW5lcmd5X21vZGUYBiABKAlSCmVuZXJneU1vZGUSJgoPZW5lcmd5X21vZGVfcmF3GAcg'
    'ASgFUg1lbmVyZ3lNb2RlUmF3');

@$core.Deprecated('Use getPerformanceRequestDescriptor instead')
const GetPerformanceRequest$json = {
  '1': 'GetPerformanceRequest',
};

/// Descriptor for `GetPerformanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPerformanceRequestDescriptor =
    $convert.base64Decode('ChVHZXRQZXJmb3JtYW5jZVJlcXVlc3Q=');

@$core.Deprecated('Use getPerformanceResponseDescriptor instead')
const GetPerformanceResponse$json = {
  '1': 'GetPerformanceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'performance_json', '3': 2, '4': 1, '5': 9, '10': 'performanceJson'},
  ],
};

/// Descriptor for `GetPerformanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPerformanceResponseDescriptor =
    $convert.base64Decode(
        'ChZHZXRQZXJmb3JtYW5jZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSKQoQcG'
        'VyZm9ybWFuY2VfanNvbhgCIAEoCVIPcGVyZm9ybWFuY2VKc29u');

@$core.Deprecated('Use playAudioTestRequestDescriptor instead')
const PlayAudioTestRequest$json = {
  '1': 'PlayAudioTestRequest',
  '2': [
    {'1': 'duration_ms', '3': 1, '4': 1, '5': 5, '10': 'durationMs'},
  ],
};

/// Descriptor for `PlayAudioTestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playAudioTestRequestDescriptor = $convert.base64Decode(
    'ChRQbGF5QXVkaW9UZXN0UmVxdWVzdBIfCgtkdXJhdGlvbl9tcxgBIAEoBVIKZHVyYXRpb25Ncw'
    '==');

@$core.Deprecated('Use playAudioTestResponseDescriptor instead')
const PlayAudioTestResponse$json = {
  '1': 'PlayAudioTestResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `PlayAudioTestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playAudioTestResponseDescriptor = $convert.base64Decode(
    'ChVQbGF5QXVkaW9UZXN0UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZX'
    'NzYWdlGAIgASgJUgdtZXNzYWdlEhQKBWVycm9yGAMgASgJUgVlcnJvcg==');

@$core.Deprecated('Use modelInfoDescriptor instead')
const ModelInfo$json = {
  '1': 'ModelInfo',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'downloaded', '3': 3, '4': 1, '5': 8, '10': 'downloaded'},
    {'1': 'size_bytes', '3': 4, '4': 1, '5': 3, '10': 'sizeBytes'},
  ],
  '9': [
    {'1': 2, '2': 3},
  ],
  '10': ['url'],
};

/// Descriptor for `ModelInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modelInfoDescriptor = $convert.base64Decode(
    'CglNb2RlbEluZm8SEgoEbmFtZRgBIAEoCVIEbmFtZRIeCgpkb3dubG9hZGVkGAMgASgIUgpkb3'
    'dubG9hZGVkEh0KCnNpemVfYnl0ZXMYBCABKANSCXNpemVCeXRlc0oECAIQA1IDdXJs');

@$core.Deprecated('Use listModelsRequestDescriptor instead')
const ListModelsRequest$json = {
  '1': 'ListModelsRequest',
};

/// Descriptor for `ListModelsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModelsRequestDescriptor =
    $convert.base64Decode('ChFMaXN0TW9kZWxzUmVxdWVzdA==');

@$core.Deprecated('Use listModelsResponseDescriptor instead')
const ListModelsResponse$json = {
  '1': 'ListModelsResponse',
  '2': [
    {
      '1': 'models',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.ModelInfo',
      '10': 'models'
    },
  ],
  '9': [
    {'1': 1, '2': 2},
  ],
  '10': ['success'],
};

/// Descriptor for `ListModelsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listModelsResponseDescriptor = $convert.base64Decode(
    'ChJMaXN0TW9kZWxzUmVzcG9uc2USMAoGbW9kZWxzGAIgAygLMhguYmxhZGV3YXRjaC52MS5Nb2'
    'RlbEluZm9SBm1vZGVsc0oECAEQAlIHc3VjY2Vzcw==');

@$core.Deprecated('Use downloadModelRequestDescriptor instead')
const DownloadModelRequest$json = {
  '1': 'DownloadModelRequest',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `DownloadModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadModelRequestDescriptor = $convert.base64Decode(
    'ChREb3dubG9hZE1vZGVsUmVxdWVzdBIQCgN1cmwYASABKAlSA3VybBISCgRuYW1lGAIgASgJUg'
    'RuYW1l');

@$core.Deprecated('Use downloadModelResponseDescriptor instead')
const DownloadModelResponse$json = {
  '1': 'DownloadModelResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `DownloadModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadModelResponseDescriptor = $convert.base64Decode(
    'ChVEb3dubG9hZE1vZGVsUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZX'
    'NzYWdlGAIgASgJUgdtZXNzYWdlEhQKBWVycm9yGAMgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getSohNominalRequestDescriptor instead')
const GetSohNominalRequest$json = {
  '1': 'GetSohNominalRequest',
};

/// Descriptor for `GetSohNominalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSohNominalRequestDescriptor =
    $convert.base64Decode('ChRHZXRTb2hOb21pbmFsUmVxdWVzdA==');

@$core.Deprecated('Use getSohNominalResponseDescriptor instead')
const GetSohNominalResponse$json = {
  '1': 'GetSohNominalResponse',
  '2': [
    {
      '1': 'nominal_kwh',
      '3': 1,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'nominalKwh',
      '17': true
    },
    {'1': 'nominal_source', '3': 2, '4': 1, '5': 9, '10': 'nominalSource'},
  ],
  '8': [
    {'1': '_nominal_kwh'},
  ],
};

/// Descriptor for `GetSohNominalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSohNominalResponseDescriptor = $convert.base64Decode(
    'ChVHZXRTb2hOb21pbmFsUmVzcG9uc2USJAoLbm9taW5hbF9rd2gYASABKAFIAFIKbm9taW5hbE'
    't3aIgBARIlCg5ub21pbmFsX3NvdXJjZRgCIAEoCVINbm9taW5hbFNvdXJjZUIOCgxfbm9taW5h'
    'bF9rd2g=');

@$core.Deprecated('Use setSohNominalRequestDescriptor instead')
const SetSohNominalRequest$json = {
  '1': 'SetSohNominalRequest',
  '2': [
    {
      '1': 'nominal_kwh',
      '3': 1,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'nominalKwh',
      '17': true
    },
  ],
  '8': [
    {'1': '_nominal_kwh'},
  ],
};

/// Descriptor for `SetSohNominalRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSohNominalRequestDescriptor = $convert.base64Decode(
    'ChRTZXRTb2hOb21pbmFsUmVxdWVzdBIkCgtub21pbmFsX2t3aBgBIAEoAUgAUgpub21pbmFsS3'
    'doiAEBQg4KDF9ub21pbmFsX2t3aA==');

@$core.Deprecated('Use setSohNominalResponseDescriptor instead')
const SetSohNominalResponse$json = {
  '1': 'SetSohNominalResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetSohNominalResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSohNominalResponseDescriptor = $convert.base64Decode(
    'ChVTZXRTb2hOb21pbmFsUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgVlcn'
    'JvchgCIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use getSohStatusRequestDescriptor instead')
const GetSohStatusRequest$json = {
  '1': 'GetSohStatusRequest',
};

/// Descriptor for `GetSohStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSohStatusRequestDescriptor =
    $convert.base64Decode('ChNHZXRTb2hTdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use getSohStatusResponseDescriptor instead')
const GetSohStatusResponse$json = {
  '1': 'GetSohStatusResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'nominal_capacity_kwh',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'nominalCapacityKwh'
    },
    {'1': 'nominal_source', '3': 3, '4': 1, '5': 9, '10': 'nominalSource'},
    {'1': 'display_soh', '3': 4, '4': 1, '5': 1, '10': 'displaySoh'},
    {'1': 'display_source', '3': 5, '4': 1, '5': 9, '10': 'displaySource'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `GetSohStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSohStatusResponseDescriptor = $convert.base64Decode(
    'ChRHZXRTb2hTdGF0dXNSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEjAKFG5vbW'
    'luYWxfY2FwYWNpdHlfa3doGAIgASgBUhJub21pbmFsQ2FwYWNpdHlLd2gSJQoObm9taW5hbF9z'
    'b3VyY2UYAyABKAlSDW5vbWluYWxTb3VyY2USHwoLZGlzcGxheV9zb2gYBCABKAFSCmRpc3BsYX'
    'lTb2gSJQoOZGlzcGxheV9zb3VyY2UYBSABKAlSDWRpc3BsYXlTb3VyY2USFAoFZXJyb3IYBiAB'
    'KAlSBWVycm9y');

@$core.Deprecated('Use resetSohRequestDescriptor instead')
const ResetSohRequest$json = {
  '1': 'ResetSohRequest',
};

/// Descriptor for `ResetSohRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetSohRequestDescriptor =
    $convert.base64Decode('Cg9SZXNldFNvaFJlcXVlc3Q=');

@$core.Deprecated('Use resetSohResponseDescriptor instead')
const ResetSohResponse$json = {
  '1': 'ResetSohResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ResetSohResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetSohResponseDescriptor = $convert.base64Decode(
    'ChBSZXNldFNvaFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSFAoFZXJyb3IYAi'
    'ABKAlSBWVycm9y');

@$core.Deprecated('Use resetPerformanceRequestDescriptor instead')
const ResetPerformanceRequest$json = {
  '1': 'ResetPerformanceRequest',
  '2': [
    {'1': 'categories', '3': 1, '4': 3, '5': 9, '10': 'categories'},
  ],
};

/// Descriptor for `ResetPerformanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPerformanceRequestDescriptor =
    $convert.base64Decode(
        'ChdSZXNldFBlcmZvcm1hbmNlUmVxdWVzdBIeCgpjYXRlZ29yaWVzGAEgAygJUgpjYXRlZ29yaW'
        'Vz');

@$core.Deprecated('Use resetPerformanceResponseDescriptor instead')
const ResetPerformanceResponse$json = {
  '1': 'ResetPerformanceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'results_json', '3': 2, '4': 1, '5': 9, '10': 'resultsJson'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `ResetPerformanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resetPerformanceResponseDescriptor = $convert.base64Decode(
    'ChhSZXNldFBlcmZvcm1hbmNlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIhCg'
    'xyZXN1bHRzX2pzb24YAiABKAlSC3Jlc3VsdHNKc29uEhQKBWVycm9yGAMgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getParkingDeltaRequestDescriptor instead')
const GetParkingDeltaRequest$json = {
  '1': 'GetParkingDeltaRequest',
  '2': [
    {'1': 'max_age_hours', '3': 1, '4': 1, '5': 5, '10': 'maxAgeHours'},
  ],
};

/// Descriptor for `GetParkingDeltaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getParkingDeltaRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRQYXJraW5nRGVsdGFSZXF1ZXN0EiIKDW1heF9hZ2VfaG91cnMYASABKAVSC21heEFnZU'
        'hvdXJz');

@$core.Deprecated('Use getParkingDeltaResponseDescriptor instead')
const GetParkingDeltaResponse$json = {
  '1': 'GetParkingDeltaResponse',
  '2': [
    {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    {'1': 'raw_json', '3': 2, '4': 1, '5': 9, '10': 'rawJson'},
  ],
};

/// Descriptor for `GetParkingDeltaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getParkingDeltaResponseDescriptor =
    $convert.base64Decode(
        'ChdHZXRQYXJraW5nRGVsdGFSZXNwb25zZRIcCglhdmFpbGFibGUYASABKAhSCWF2YWlsYWJsZR'
        'IZCghyYXdfanNvbhgCIAEoCVIHcmF3SnNvbg==');

@$core.Deprecated('Use getLastChargeRequestDescriptor instead')
const GetLastChargeRequest$json = {
  '1': 'GetLastChargeRequest',
  '2': [
    {'1': 'hours_back', '3': 1, '4': 1, '5': 5, '10': 'hoursBack'},
  ],
};

/// Descriptor for `GetLastChargeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLastChargeRequestDescriptor = $convert.base64Decode(
    'ChRHZXRMYXN0Q2hhcmdlUmVxdWVzdBIdCgpob3Vyc19iYWNrGAEgASgFUglob3Vyc0JhY2s=');

@$core.Deprecated('Use getLastChargeResponseDescriptor instead')
const GetLastChargeResponse$json = {
  '1': 'GetLastChargeResponse',
  '2': [
    {'1': 'available', '3': 1, '4': 1, '5': 8, '10': 'available'},
    {'1': 'raw_json', '3': 2, '4': 1, '5': 9, '10': 'rawJson'},
  ],
};

/// Descriptor for `GetLastChargeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLastChargeResponseDescriptor = $convert.base64Decode(
    'ChVHZXRMYXN0Q2hhcmdlUmVzcG9uc2USHAoJYXZhaWxhYmxlGAEgASgIUglhdmFpbGFibGUSGQ'
    'oIcmF3X2pzb24YAiABKAlSB3Jhd0pzb24=');

@$core.Deprecated('Use getSelectedModelRequestDescriptor instead')
const GetSelectedModelRequest$json = {
  '1': 'GetSelectedModelRequest',
};

/// Descriptor for `GetSelectedModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSelectedModelRequestDescriptor =
    $convert.base64Decode('ChdHZXRTZWxlY3RlZE1vZGVsUmVxdWVzdA==');

@$core.Deprecated('Use getSelectedModelResponseDescriptor instead')
const GetSelectedModelResponse$json = {
  '1': 'GetSelectedModelResponse',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'color', '3': 2, '4': 1, '5': 9, '10': 'color'},
  ],
};

/// Descriptor for `GetSelectedModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSelectedModelResponseDescriptor =
    $convert.base64Decode(
        'ChhHZXRTZWxlY3RlZE1vZGVsUmVzcG9uc2USGQoIbW9kZWxfaWQYASABKAlSB21vZGVsSWQSFA'
        'oFY29sb3IYAiABKAlSBWNvbG9y');

@$core.Deprecated('Use setSelectedModelRequestDescriptor instead')
const SetSelectedModelRequest$json = {
  '1': 'SetSelectedModelRequest',
  '2': [
    {'1': 'model_id', '3': 1, '4': 1, '5': 9, '10': 'modelId'},
    {'1': 'color', '3': 2, '4': 1, '5': 9, '10': 'color'},
  ],
};

/// Descriptor for `SetSelectedModelRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSelectedModelRequestDescriptor =
    $convert.base64Decode(
        'ChdTZXRTZWxlY3RlZE1vZGVsUmVxdWVzdBIZCghtb2RlbF9pZBgBIAEoCVIHbW9kZWxJZBIUCg'
        'Vjb2xvchgCIAEoCVIFY29sb3I=');

@$core.Deprecated('Use setSelectedModelResponseDescriptor instead')
const SetSelectedModelResponse$json = {
  '1': 'SetSelectedModelResponse',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetSelectedModelResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSelectedModelResponseDescriptor =
    $convert.base64Decode(
        'ChhTZXRTZWxlY3RlZE1vZGVsUmVzcG9uc2USDgoCb2sYASABKAhSAm9rEhQKBWVycm9yGAIgAS'
        'gJUgVlcnJvcg==');

@$core.Deprecated('Use getModelsManifestRequestDescriptor instead')
const GetModelsManifestRequest$json = {
  '1': 'GetModelsManifestRequest',
};

/// Descriptor for `GetModelsManifestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModelsManifestRequestDescriptor =
    $convert.base64Decode('ChhHZXRNb2RlbHNNYW5pZmVzdFJlcXVlc3Q=');

@$core.Deprecated('Use getModelsManifestResponseDescriptor instead')
const GetModelsManifestResponse$json = {
  '1': 'GetModelsManifestResponse',
  '2': [
    {'1': 'manifest_json', '3': 1, '4': 1, '5': 9, '10': 'manifestJson'},
  ],
};

/// Descriptor for `GetModelsManifestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getModelsManifestResponseDescriptor =
    $convert.base64Decode(
        'ChlHZXRNb2RlbHNNYW5pZmVzdFJlc3BvbnNlEiMKDW1hbmlmZXN0X2pzb24YASABKAlSDG1hbm'
        'lmZXN0SnNvbg==');

@$core.Deprecated('Use performanceConnectRequestDescriptor instead')
const PerformanceConnectRequest$json = {
  '1': 'PerformanceConnectRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `PerformanceConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List performanceConnectRequestDescriptor =
    $convert.base64Decode(
        'ChlQZXJmb3JtYW5jZUNvbm5lY3RSZXF1ZXN0EhsKCWNsaWVudF9pZBgBIAEoCVIIY2xpZW50SW'
        'Q=');

@$core.Deprecated('Use performanceConnectResponseDescriptor instead')
const PerformanceConnectResponse$json = {
  '1': 'PerformanceConnectResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'client_id', '3': 2, '4': 1, '5': 9, '10': 'clientId'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `PerformanceConnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List performanceConnectResponseDescriptor =
    $convert.base64Decode(
        'ChpQZXJmb3JtYW5jZUNvbm5lY3RSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'sKCWNsaWVudF9pZBgCIAEoCVIIY2xpZW50SWQSFAoFZXJyb3IYAyABKAlSBWVycm9y');

@$core.Deprecated('Use performanceHeartbeatRequestDescriptor instead')
const PerformanceHeartbeatRequest$json = {
  '1': 'PerformanceHeartbeatRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `PerformanceHeartbeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List performanceHeartbeatRequestDescriptor =
    $convert.base64Decode(
        'ChtQZXJmb3JtYW5jZUhlYXJ0YmVhdFJlcXVlc3QSGwoJY2xpZW50X2lkGAEgASgJUghjbGllbn'
        'RJZA==');

@$core.Deprecated('Use performanceHeartbeatResponseDescriptor instead')
const PerformanceHeartbeatResponse$json = {
  '1': 'PerformanceHeartbeatResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `PerformanceHeartbeatResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List performanceHeartbeatResponseDescriptor =
    $convert.base64Decode(
        'ChxQZXJmb3JtYW5jZUhlYXJ0YmVhdFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3'
        'MSFAoFZXJyb3IYAiABKAlSBWVycm9y');

@$core.Deprecated('Use performanceDisconnectRequestDescriptor instead')
const PerformanceDisconnectRequest$json = {
  '1': 'PerformanceDisconnectRequest',
  '2': [
    {'1': 'client_id', '3': 1, '4': 1, '5': 9, '10': 'clientId'},
  ],
};

/// Descriptor for `PerformanceDisconnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List performanceDisconnectRequestDescriptor =
    $convert.base64Decode(
        'ChxQZXJmb3JtYW5jZURpc2Nvbm5lY3RSZXF1ZXN0EhsKCWNsaWVudF9pZBgBIAEoCVIIY2xpZW'
        '50SWQ=');

@$core.Deprecated('Use performanceDisconnectResponseDescriptor instead')
const PerformanceDisconnectResponse$json = {
  '1': 'PerformanceDisconnectResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `PerformanceDisconnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List performanceDisconnectResponseDescriptor =
    $convert.base64Decode(
        'Ch1QZXJmb3JtYW5jZURpc2Nvbm5lY3RSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZX'
        'NzEhQKBWVycm9yGAIgASgJUgVlcnJvcg==');

const $core.Map<$core.String, $core.dynamic> SystemServiceBase$json = {
  '1': 'SystemService',
  '2': [
    {
      '1': 'GetStatus',
      '2': '.bladewatch.v1.GetStatusRequest',
      '3': '.bladewatch.v1.GetStatusResponse'
    },
    {
      '1': 'GetPerformance',
      '2': '.bladewatch.v1.GetPerformanceRequest',
      '3': '.bladewatch.v1.GetPerformanceResponse'
    },
    {
      '1': 'PlayAudioTest',
      '2': '.bladewatch.v1.PlayAudioTestRequest',
      '3': '.bladewatch.v1.PlayAudioTestResponse'
    },
    {
      '1': 'ListModels',
      '2': '.bladewatch.v1.ListModelsRequest',
      '3': '.bladewatch.v1.ListModelsResponse'
    },
    {
      '1': 'DownloadModel',
      '2': '.bladewatch.v1.DownloadModelRequest',
      '3': '.bladewatch.v1.DownloadModelResponse'
    },
    {
      '1': 'GetSohNominal',
      '2': '.bladewatch.v1.GetSohNominalRequest',
      '3': '.bladewatch.v1.GetSohNominalResponse'
    },
    {
      '1': 'SetSohNominal',
      '2': '.bladewatch.v1.SetSohNominalRequest',
      '3': '.bladewatch.v1.SetSohNominalResponse'
    },
    {
      '1': 'GetSohStatus',
      '2': '.bladewatch.v1.GetSohStatusRequest',
      '3': '.bladewatch.v1.GetSohStatusResponse'
    },
    {
      '1': 'ResetSoh',
      '2': '.bladewatch.v1.ResetSohRequest',
      '3': '.bladewatch.v1.ResetSohResponse'
    },
    {
      '1': 'ResetPerformance',
      '2': '.bladewatch.v1.ResetPerformanceRequest',
      '3': '.bladewatch.v1.ResetPerformanceResponse'
    },
    {
      '1': 'GetParkingDelta',
      '2': '.bladewatch.v1.GetParkingDeltaRequest',
      '3': '.bladewatch.v1.GetParkingDeltaResponse'
    },
    {
      '1': 'GetLastCharge',
      '2': '.bladewatch.v1.GetLastChargeRequest',
      '3': '.bladewatch.v1.GetLastChargeResponse'
    },
    {
      '1': 'GetSelectedModel',
      '2': '.bladewatch.v1.GetSelectedModelRequest',
      '3': '.bladewatch.v1.GetSelectedModelResponse'
    },
    {
      '1': 'SetSelectedModel',
      '2': '.bladewatch.v1.SetSelectedModelRequest',
      '3': '.bladewatch.v1.SetSelectedModelResponse'
    },
    {
      '1': 'GetModelsManifest',
      '2': '.bladewatch.v1.GetModelsManifestRequest',
      '3': '.bladewatch.v1.GetModelsManifestResponse'
    },
    {
      '1': 'PerformanceConnect',
      '2': '.bladewatch.v1.PerformanceConnectRequest',
      '3': '.bladewatch.v1.PerformanceConnectResponse'
    },
    {
      '1': 'PerformanceHeartbeat',
      '2': '.bladewatch.v1.PerformanceHeartbeatRequest',
      '3': '.bladewatch.v1.PerformanceHeartbeatResponse'
    },
    {
      '1': 'PerformanceDisconnect',
      '2': '.bladewatch.v1.PerformanceDisconnectRequest',
      '3': '.bladewatch.v1.PerformanceDisconnectResponse'
    },
  ],
};

@$core.Deprecated('Use systemServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    SystemServiceBase$messageJson = {
  '.bladewatch.v1.GetStatusRequest': GetStatusRequest$json,
  '.bladewatch.v1.GetStatusResponse': GetStatusResponse$json,
  '.bladewatch.v1.BatteryInfo': BatteryInfo$json,
  '.bladewatch.v1.ChargingInfo': ChargingInfo$json,
  '.bladewatch.v1.SocInfo': SocInfo$json,
  '.bladewatch.v1.RangeInfo': RangeInfo$json,
  '.bladewatch.v1.SohInfo': SohInfo$json,
  '.bladewatch.v1.RecordingStatus': RecordingStatus$json,
  '.bladewatch.v1.TripStatus': TripStatus$json,
  '.bladewatch.v1.NetworkInfo': NetworkInfo$json,
  '.bladewatch.v1.DriveStatus': DriveStatus$json,
  '.bladewatch.v1.GetPerformanceRequest': GetPerformanceRequest$json,
  '.bladewatch.v1.GetPerformanceResponse': GetPerformanceResponse$json,
  '.bladewatch.v1.PlayAudioTestRequest': PlayAudioTestRequest$json,
  '.bladewatch.v1.PlayAudioTestResponse': PlayAudioTestResponse$json,
  '.bladewatch.v1.ListModelsRequest': ListModelsRequest$json,
  '.bladewatch.v1.ListModelsResponse': ListModelsResponse$json,
  '.bladewatch.v1.ModelInfo': ModelInfo$json,
  '.bladewatch.v1.DownloadModelRequest': DownloadModelRequest$json,
  '.bladewatch.v1.DownloadModelResponse': DownloadModelResponse$json,
  '.bladewatch.v1.GetSohNominalRequest': GetSohNominalRequest$json,
  '.bladewatch.v1.GetSohNominalResponse': GetSohNominalResponse$json,
  '.bladewatch.v1.SetSohNominalRequest': SetSohNominalRequest$json,
  '.bladewatch.v1.SetSohNominalResponse': SetSohNominalResponse$json,
  '.bladewatch.v1.GetSohStatusRequest': GetSohStatusRequest$json,
  '.bladewatch.v1.GetSohStatusResponse': GetSohStatusResponse$json,
  '.bladewatch.v1.ResetSohRequest': ResetSohRequest$json,
  '.bladewatch.v1.ResetSohResponse': ResetSohResponse$json,
  '.bladewatch.v1.ResetPerformanceRequest': ResetPerformanceRequest$json,
  '.bladewatch.v1.ResetPerformanceResponse': ResetPerformanceResponse$json,
  '.bladewatch.v1.GetParkingDeltaRequest': GetParkingDeltaRequest$json,
  '.bladewatch.v1.GetParkingDeltaResponse': GetParkingDeltaResponse$json,
  '.bladewatch.v1.GetLastChargeRequest': GetLastChargeRequest$json,
  '.bladewatch.v1.GetLastChargeResponse': GetLastChargeResponse$json,
  '.bladewatch.v1.GetSelectedModelRequest': GetSelectedModelRequest$json,
  '.bladewatch.v1.GetSelectedModelResponse': GetSelectedModelResponse$json,
  '.bladewatch.v1.SetSelectedModelRequest': SetSelectedModelRequest$json,
  '.bladewatch.v1.SetSelectedModelResponse': SetSelectedModelResponse$json,
  '.bladewatch.v1.GetModelsManifestRequest': GetModelsManifestRequest$json,
  '.bladewatch.v1.GetModelsManifestResponse': GetModelsManifestResponse$json,
  '.bladewatch.v1.PerformanceConnectRequest': PerformanceConnectRequest$json,
  '.bladewatch.v1.PerformanceConnectResponse': PerformanceConnectResponse$json,
  '.bladewatch.v1.PerformanceHeartbeatRequest':
      PerformanceHeartbeatRequest$json,
  '.bladewatch.v1.PerformanceHeartbeatResponse':
      PerformanceHeartbeatResponse$json,
  '.bladewatch.v1.PerformanceDisconnectRequest':
      PerformanceDisconnectRequest$json,
  '.bladewatch.v1.PerformanceDisconnectResponse':
      PerformanceDisconnectResponse$json,
};

/// Descriptor for `SystemService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List systemServiceDescriptor = $convert.base64Decode(
    'Cg1TeXN0ZW1TZXJ2aWNlEk4KCUdldFN0YXR1cxIfLmJsYWRld2F0Y2gudjEuR2V0U3RhdHVzUm'
    'VxdWVzdBogLmJsYWRld2F0Y2gudjEuR2V0U3RhdHVzUmVzcG9uc2USXQoOR2V0UGVyZm9ybWFu'
    'Y2USJC5ibGFkZXdhdGNoLnYxLkdldFBlcmZvcm1hbmNlUmVxdWVzdBolLmJsYWRld2F0Y2gudj'
    'EuR2V0UGVyZm9ybWFuY2VSZXNwb25zZRJaCg1QbGF5QXVkaW9UZXN0EiMuYmxhZGV3YXRjaC52'
    'MS5QbGF5QXVkaW9UZXN0UmVxdWVzdBokLmJsYWRld2F0Y2gudjEuUGxheUF1ZGlvVGVzdFJlc3'
    'BvbnNlElEKCkxpc3RNb2RlbHMSIC5ibGFkZXdhdGNoLnYxLkxpc3RNb2RlbHNSZXF1ZXN0GiEu'
    'YmxhZGV3YXRjaC52MS5MaXN0TW9kZWxzUmVzcG9uc2USWgoNRG93bmxvYWRNb2RlbBIjLmJsYW'
    'Rld2F0Y2gudjEuRG93bmxvYWRNb2RlbFJlcXVlc3QaJC5ibGFkZXdhdGNoLnYxLkRvd25sb2Fk'
    'TW9kZWxSZXNwb25zZRJaCg1HZXRTb2hOb21pbmFsEiMuYmxhZGV3YXRjaC52MS5HZXRTb2hOb2'
    '1pbmFsUmVxdWVzdBokLmJsYWRld2F0Y2gudjEuR2V0U29oTm9taW5hbFJlc3BvbnNlEloKDVNl'
    'dFNvaE5vbWluYWwSIy5ibGFkZXdhdGNoLnYxLlNldFNvaE5vbWluYWxSZXF1ZXN0GiQuYmxhZG'
    'V3YXRjaC52MS5TZXRTb2hOb21pbmFsUmVzcG9uc2USVwoMR2V0U29oU3RhdHVzEiIuYmxhZGV3'
    'YXRjaC52MS5HZXRTb2hTdGF0dXNSZXF1ZXN0GiMuYmxhZGV3YXRjaC52MS5HZXRTb2hTdGF0dX'
    'NSZXNwb25zZRJLCghSZXNldFNvaBIeLmJsYWRld2F0Y2gudjEuUmVzZXRTb2hSZXF1ZXN0Gh8u'
    'YmxhZGV3YXRjaC52MS5SZXNldFNvaFJlc3BvbnNlEmMKEFJlc2V0UGVyZm9ybWFuY2USJi5ibG'
    'FkZXdhdGNoLnYxLlJlc2V0UGVyZm9ybWFuY2VSZXF1ZXN0GicuYmxhZGV3YXRjaC52MS5SZXNl'
    'dFBlcmZvcm1hbmNlUmVzcG9uc2USYAoPR2V0UGFya2luZ0RlbHRhEiUuYmxhZGV3YXRjaC52MS'
    '5HZXRQYXJraW5nRGVsdGFSZXF1ZXN0GiYuYmxhZGV3YXRjaC52MS5HZXRQYXJraW5nRGVsdGFS'
    'ZXNwb25zZRJaCg1HZXRMYXN0Q2hhcmdlEiMuYmxhZGV3YXRjaC52MS5HZXRMYXN0Q2hhcmdlUm'
    'VxdWVzdBokLmJsYWRld2F0Y2gudjEuR2V0TGFzdENoYXJnZVJlc3BvbnNlEmMKEEdldFNlbGVj'
    'dGVkTW9kZWwSJi5ibGFkZXdhdGNoLnYxLkdldFNlbGVjdGVkTW9kZWxSZXF1ZXN0GicuYmxhZG'
    'V3YXRjaC52MS5HZXRTZWxlY3RlZE1vZGVsUmVzcG9uc2USYwoQU2V0U2VsZWN0ZWRNb2RlbBIm'
    'LmJsYWRld2F0Y2gudjEuU2V0U2VsZWN0ZWRNb2RlbFJlcXVlc3QaJy5ibGFkZXdhdGNoLnYxLl'
    'NldFNlbGVjdGVkTW9kZWxSZXNwb25zZRJmChFHZXRNb2RlbHNNYW5pZmVzdBInLmJsYWRld2F0'
    'Y2gudjEuR2V0TW9kZWxzTWFuaWZlc3RSZXF1ZXN0GiguYmxhZGV3YXRjaC52MS5HZXRNb2RlbH'
    'NNYW5pZmVzdFJlc3BvbnNlEmkKElBlcmZvcm1hbmNlQ29ubmVjdBIoLmJsYWRld2F0Y2gudjEu'
    'UGVyZm9ybWFuY2VDb25uZWN0UmVxdWVzdBopLmJsYWRld2F0Y2gudjEuUGVyZm9ybWFuY2VDb2'
    '5uZWN0UmVzcG9uc2USbwoUUGVyZm9ybWFuY2VIZWFydGJlYXQSKi5ibGFkZXdhdGNoLnYxLlBl'
    'cmZvcm1hbmNlSGVhcnRiZWF0UmVxdWVzdBorLmJsYWRld2F0Y2gudjEuUGVyZm9ybWFuY2VIZW'
    'FydGJlYXRSZXNwb25zZRJyChVQZXJmb3JtYW5jZURpc2Nvbm5lY3QSKy5ibGFkZXdhdGNoLnYx'
    'LlBlcmZvcm1hbmNlRGlzY29ubmVjdFJlcXVlc3QaLC5ibGFkZXdhdGNoLnYxLlBlcmZvcm1hbm'
    'NlRGlzY29ubmVjdFJlc3BvbnNl');
