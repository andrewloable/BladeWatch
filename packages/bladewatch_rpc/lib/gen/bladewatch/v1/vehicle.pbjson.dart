// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/vehicle.proto.

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

@$core.Deprecated('Use doorStatusDescriptor instead')
const DoorStatus$json = {
  '1': 'DoorStatus',
  '2': [
    {'1': 'lf', '3': 1, '4': 1, '5': 5, '10': 'lf'},
    {'1': 'rf', '3': 2, '4': 1, '5': 5, '10': 'rf'},
    {'1': 'lr', '3': 3, '4': 1, '5': 5, '10': 'lr'},
    {'1': 'rr', '3': 4, '4': 1, '5': 5, '10': 'rr'},
    {'1': 'trunk', '3': 5, '4': 1, '5': 5, '10': 'trunk'},
    {'1': 'hood', '3': 6, '4': 1, '5': 5, '10': 'hood'},
    {'1': 'overall', '3': 7, '4': 1, '5': 5, '10': 'overall'},
  ],
};

/// Descriptor for `DoorStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List doorStatusDescriptor = $convert.base64Decode(
    'CgpEb29yU3RhdHVzEg4KAmxmGAEgASgFUgJsZhIOCgJyZhgCIAEoBVICcmYSDgoCbHIYAyABKA'
    'VSAmxyEg4KAnJyGAQgASgFUgJychIUCgV0cnVuaxgFIAEoBVIFdHJ1bmsSEgoEaG9vZBgGIAEo'
    'BVIEaG9vZBIYCgdvdmVyYWxsGAcgASgFUgdvdmVyYWxs');

@$core.Deprecated('Use windowStatusDescriptor instead')
const WindowStatus$json = {
  '1': 'WindowStatus',
  '2': [
    {'1': 'lf', '3': 1, '4': 1, '5': 5, '10': 'lf'},
    {'1': 'rf', '3': 2, '4': 1, '5': 5, '10': 'rf'},
    {'1': 'lr', '3': 3, '4': 1, '5': 5, '10': 'lr'},
    {'1': 'rr', '3': 4, '4': 1, '5': 5, '10': 'rr'},
    {'1': 'sunroof', '3': 5, '4': 1, '5': 5, '10': 'sunroof'},
    {'1': 'sunshade', '3': 6, '4': 1, '5': 5, '10': 'sunshade'},
  ],
};

/// Descriptor for `WindowStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List windowStatusDescriptor = $convert.base64Decode(
    'CgxXaW5kb3dTdGF0dXMSDgoCbGYYASABKAVSAmxmEg4KAnJmGAIgASgFUgJyZhIOCgJschgDIA'
    'EoBVICbHISDgoCcnIYBCABKAVSAnJyEhgKB3N1bnJvb2YYBSABKAVSB3N1bnJvb2YSGgoIc3Vu'
    'c2hhZGUYBiABKAVSCHN1bnNoYWRl');

@$core.Deprecated('Use windowCapabilitiesDescriptor instead')
const WindowCapabilities$json = {
  '1': 'WindowCapabilities',
  '2': [
    {'1': 'sunroof', '3': 1, '4': 1, '5': 8, '10': 'sunroof'},
    {'1': 'sunshade', '3': 2, '4': 1, '5': 8, '10': 'sunshade'},
  ],
};

/// Descriptor for `WindowCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List windowCapabilitiesDescriptor = $convert.base64Decode(
    'ChJXaW5kb3dDYXBhYmlsaXRpZXMSGAoHc3Vucm9vZhgBIAEoCFIHc3Vucm9vZhIaCghzdW5zaG'
    'FkZRgCIAEoCFIIc3Vuc2hhZGU=');

@$core.Deprecated('Use vehicleCapabilitiesDescriptor instead')
const VehicleCapabilities$json = {
  '1': 'VehicleCapabilities',
  '2': [
    {
      '1': 'windows',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.WindowCapabilities',
      '10': 'windows'
    },
  ],
  '9': [
    {'1': 2, '2': 3},
  ],
  '10': ['seats'],
};

/// Descriptor for `VehicleCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleCapabilitiesDescriptor = $convert.base64Decode(
    'ChNWZWhpY2xlQ2FwYWJpbGl0aWVzEjsKB3dpbmRvd3MYASABKAsyIS5ibGFkZXdhdGNoLnYxLl'
    'dpbmRvd0NhcGFiaWxpdGllc1IHd2luZG93c0oECAIQA1IFc2VhdHM=');

@$core.Deprecated('Use trunkStatusDescriptor instead')
const TrunkStatus$json = {
  '1': 'TrunkStatus',
  '2': [
    {'1': 'lock_status', '3': 1, '4': 1, '5': 5, '10': 'lockStatus'},
  ],
};

/// Descriptor for `TrunkStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trunkStatusDescriptor = $convert.base64Decode(
    'CgtUcnVua1N0YXR1cxIfCgtsb2NrX3N0YXR1cxgBIAEoBVIKbG9ja1N0YXR1cw==');

@$core.Deprecated('Use sunroofStatusDescriptor instead')
const SunroofStatus$json = {
  '1': 'SunroofStatus',
  '2': [
    {'1': 'state', '3': 1, '4': 1, '5': 5, '10': 'state'},
    {'1': 'position', '3': 2, '4': 1, '5': 5, '10': 'position'},
  ],
};

/// Descriptor for `SunroofStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sunroofStatusDescriptor = $convert.base64Decode(
    'Cg1TdW5yb29mU3RhdHVzEhQKBXN0YXRlGAEgASgFUgVzdGF0ZRIaCghwb3NpdGlvbhgCIAEoBV'
    'IIcG9zaXRpb24=');

@$core.Deprecated('Use batteryStatusDescriptor instead')
const BatteryStatus$json = {
  '1': 'BatteryStatus',
  '2': [
    {'1': 'soc', '3': 1, '4': 1, '5': 1, '10': 'soc'},
    {'1': 'range_km', '3': 2, '4': 1, '5': 5, '10': 'rangeKm'},
    {'1': 'bodywork_range_km', '3': 3, '4': 1, '5': 5, '10': 'bodyworkRangeKm'},
    {'1': 'fuel_percent', '3': 4, '4': 1, '5': 1, '10': 'fuelPercent'},
    {'1': 'fuel_range_km', '3': 5, '4': 1, '5': 5, '10': 'fuelRangeKm'},
  ],
};

/// Descriptor for `BatteryStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batteryStatusDescriptor = $convert.base64Decode(
    'Cg1CYXR0ZXJ5U3RhdHVzEhAKA3NvYxgBIAEoAVIDc29jEhkKCHJhbmdlX2ttGAIgASgFUgdyYW'
    '5nZUttEioKEWJvZHl3b3JrX3JhbmdlX2ttGAMgASgFUg9ib2R5d29ya1JhbmdlS20SIQoMZnVl'
    'bF9wZXJjZW50GAQgASgBUgtmdWVsUGVyY2VudBIiCg1mdWVsX3JhbmdlX2ttGAUgASgFUgtmdW'
    'VsUmFuZ2VLbQ==');

@$core.Deprecated('Use lightStatusDescriptor instead')
const LightStatus$json = {
  '1': 'LightStatus',
  '2': [
    {'1': 'low_beam', '3': 1, '4': 1, '5': 8, '10': 'lowBeam'},
    {'1': 'high_beam', '3': 2, '4': 1, '5': 8, '10': 'highBeam'},
    {'1': 'hazard', '3': 3, '4': 1, '5': 8, '10': 'hazard'},
    {'1': 'day_time_light', '3': 4, '4': 1, '5': 8, '10': 'dayTimeLight'},
  ],
};

/// Descriptor for `LightStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lightStatusDescriptor = $convert.base64Decode(
    'CgtMaWdodFN0YXR1cxIZCghsb3dfYmVhbRgBIAEoCFIHbG93QmVhbRIbCgloaWdoX2JlYW0YAi'
    'ABKAhSCGhpZ2hCZWFtEhYKBmhhemFyZBgDIAEoCFIGaGF6YXJkEiQKDmRheV90aW1lX2xpZ2h0'
    'GAQgASgIUgxkYXlUaW1lTGlnaHQ=');

@$core.Deprecated('Use adasStatusDescriptor instead')
const AdasStatus$json = {
  '1': 'AdasStatus',
  '2': [
    {
      '1': 'speed_limit_warning',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'speedLimitWarning'
    },
  ],
};

/// Descriptor for `AdasStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List adasStatusDescriptor = $convert.base64Decode(
    'CgpBZGFzU3RhdHVzEi4KE3NwZWVkX2xpbWl0X3dhcm5pbmcYASABKAhSEXNwZWVkTGltaXRXYX'
    'JuaW5n');

@$core.Deprecated('Use climateStatusDescriptor instead')
const ClimateStatus$json = {
  '1': 'ClimateStatus',
  '2': [
    {'1': 'ac_on', '3': 1, '4': 1, '5': 8, '10': 'acOn'},
    {'1': 'setpoint_c', '3': 2, '4': 1, '5': 1, '10': 'setpointC'},
    {'1': 'wind_mode', '3': 4, '4': 1, '5': 5, '10': 'windMode'},
    {'1': 'fan_level', '3': 5, '4': 1, '5': 5, '10': 'fanLevel'},
    {'1': 'max_cooling', '3': 6, '4': 1, '5': 8, '10': 'maxCooling'},
    {
      '1': 'outside_temp_c',
      '3': 7,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'outsideTempC',
      '17': true
    },
  ],
  '8': [
    {'1': '_outside_temp_c'},
  ],
  '9': [
    {'1': 3, '2': 4},
  ],
  '10': ['inside_temp_c'],
};

/// Descriptor for `ClimateStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List climateStatusDescriptor = $convert.base64Decode(
    'Cg1DbGltYXRlU3RhdHVzEhMKBWFjX29uGAEgASgIUgRhY09uEh0KCnNldHBvaW50X2MYAiABKA'
    'FSCXNldHBvaW50QxIbCgl3aW5kX21vZGUYBCABKAVSCHdpbmRNb2RlEhsKCWZhbl9sZXZlbBgF'
    'IAEoBVIIZmFuTGV2ZWwSHwoLbWF4X2Nvb2xpbmcYBiABKAhSCm1heENvb2xpbmcSKQoOb3V0c2'
    'lkZV90ZW1wX2MYByABKAFIAFIMb3V0c2lkZVRlbXBDiAEBQhEKD19vdXRzaWRlX3RlbXBfY0oE'
    'CAMQBFINaW5zaWRlX3RlbXBfYw==');

@$core.Deprecated('Use tyrePressureDescriptor instead')
const TyrePressure$json = {
  '1': 'TyrePressure',
  '2': [
    {'1': 'k_pa', '3': 1, '4': 1, '5': 5, '10': 'kPa'},
    {'1': 'psi', '3': 2, '4': 1, '5': 1, '10': 'psi'},
    {'1': 'temp_c', '3': 3, '4': 1, '5': 5, '10': 'temperatureC'},
    {'1': 'pressure_state', '3': 4, '4': 1, '5': 5, '10': 'pressureState'},
    {'1': 'leak_state', '3': 5, '4': 1, '5': 5, '10': 'airLeakState'},
    {'1': 'signal_state', '3': 6, '4': 1, '5': 5, '10': 'signalState'},
  ],
};

/// Descriptor for `TyrePressure`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tyrePressureDescriptor = $convert.base64Decode(
    'CgxUeXJlUHJlc3N1cmUSEQoEa19wYRgBIAEoBVIDa1BhEhAKA3BzaRgCIAEoAVIDcHNpEhwKBn'
    'RlbXBfYxgDIAEoBVIMdGVtcGVyYXR1cmVDEiUKDnByZXNzdXJlX3N0YXRlGAQgASgFUg1wcmVz'
    'c3VyZVN0YXRlEiAKCmxlYWtfc3RhdGUYBSABKAVSDGFpckxlYWtTdGF0ZRIhCgxzaWduYWxfc3'
    'RhdGUYBiABKAVSC3NpZ25hbFN0YXRl');

@$core.Deprecated('Use tyreStatusDescriptor instead')
const TyreStatus$json = {
  '1': 'TyreStatus',
  '2': [
    {
      '1': 'fl',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TyrePressure',
      '10': 'fl'
    },
    {
      '1': 'fr',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TyrePressure',
      '10': 'fr'
    },
    {
      '1': 'rl',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TyrePressure',
      '10': 'rl'
    },
    {
      '1': 'rr',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TyrePressure',
      '10': 'rr'
    },
  ],
};

/// Descriptor for `TyreStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tyreStatusDescriptor = $convert.base64Decode(
    'CgpUeXJlU3RhdHVzEisKAmZsGAEgASgLMhsuYmxhZGV3YXRjaC52MS5UeXJlUHJlc3N1cmVSAm'
    'ZsEisKAmZyGAIgASgLMhsuYmxhZGV3YXRjaC52MS5UeXJlUHJlc3N1cmVSAmZyEisKAnJsGAMg'
    'ASgLMhsuYmxhZGV3YXRjaC52MS5UeXJlUHJlc3N1cmVSAnJsEisKAnJyGAQgASgLMhsuYmxhZG'
    'V3YXRjaC52MS5UeXJlUHJlc3N1cmVSAnJy');

@$core.Deprecated('Use getVehicleStateRequestDescriptor instead')
const GetVehicleStateRequest$json = {
  '1': 'GetVehicleStateRequest',
};

/// Descriptor for `GetVehicleStateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getVehicleStateRequestDescriptor =
    $convert.base64Decode('ChZHZXRWZWhpY2xlU3RhdGVSZXF1ZXN0');

@$core.Deprecated('Use getVehicleStateResponseDescriptor instead')
const GetVehicleStateResponse$json = {
  '1': 'GetVehicleStateResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'doors',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.DoorStatus',
      '10': 'doors'
    },
    {
      '1': 'windows',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.WindowStatus',
      '10': 'windows'
    },
    {
      '1': 'capabilities',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.VehicleCapabilities',
      '10': 'capabilities'
    },
    {
      '1': 'trunk',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TrunkStatus',
      '10': 'trunk'
    },
    {
      '1': 'sunroof',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SunroofStatus',
      '10': 'sunroof'
    },
    {
      '1': 'battery',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.BatteryStatus',
      '10': 'battery'
    },
    {
      '1': 'lights',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.LightStatus',
      '10': 'lights'
    },
    {
      '1': 'adas',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.AdasStatus',
      '10': 'adas'
    },
    {
      '1': 'climate',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.ClimateStatus',
      '10': 'climate'
    },
    {
      '1': 'tyres',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TyreStatus',
      '10': 'tyres'
    },
    {'1': 'error', '3': 13, '4': 1, '5': 9, '10': 'error'},
    {
      '1': 'media_volume_percent',
      '3': 14,
      '4': 1,
      '5': 5,
      '10': 'mediaVolumePercent'
    },
    {'1': 'media_muted', '3': 15, '4': 1, '5': 8, '10': 'mediaMuted'},
  ],
  '9': [
    {'1': 10, '2': 11},
  ],
  '10': ['seats'],
};

/// Descriptor for `GetVehicleStateResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getVehicleStateResponseDescriptor = $convert.base64Decode(
    'ChdHZXRWZWhpY2xlU3RhdGVSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEi8KBW'
    'Rvb3JzGAIgASgLMhkuYmxhZGV3YXRjaC52MS5Eb29yU3RhdHVzUgVkb29ycxI1Cgd3aW5kb3dz'
    'GAMgASgLMhsuYmxhZGV3YXRjaC52MS5XaW5kb3dTdGF0dXNSB3dpbmRvd3MSRgoMY2FwYWJpbG'
    'l0aWVzGAQgASgLMiIuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ2FwYWJpbGl0aWVzUgxjYXBhYmls'
    'aXRpZXMSMAoFdHJ1bmsYBSABKAsyGi5ibGFkZXdhdGNoLnYxLlRydW5rU3RhdHVzUgV0cnVuax'
    'I2CgdzdW5yb29mGAYgASgLMhwuYmxhZGV3YXRjaC52MS5TdW5yb29mU3RhdHVzUgdzdW5yb29m'
    'EjYKB2JhdHRlcnkYByABKAsyHC5ibGFkZXdhdGNoLnYxLkJhdHRlcnlTdGF0dXNSB2JhdHRlcn'
    'kSMgoGbGlnaHRzGAggASgLMhouYmxhZGV3YXRjaC52MS5MaWdodFN0YXR1c1IGbGlnaHRzEi0K'
    'BGFkYXMYCSABKAsyGS5ibGFkZXdhdGNoLnYxLkFkYXNTdGF0dXNSBGFkYXMSNgoHY2xpbWF0ZR'
    'gLIAEoCzIcLmJsYWRld2F0Y2gudjEuQ2xpbWF0ZVN0YXR1c1IHY2xpbWF0ZRIvCgV0eXJlcxgM'
    'IAEoCzIZLmJsYWRld2F0Y2gudjEuVHlyZVN0YXR1c1IFdHlyZXMSFAoFZXJyb3IYDSABKAlSBW'
    'Vycm9yEjAKFG1lZGlhX3ZvbHVtZV9wZXJjZW50GA4gASgFUhJtZWRpYVZvbHVtZVBlcmNlbnQS'
    'HwoLbWVkaWFfbXV0ZWQYDyABKAhSCm1lZGlhTXV0ZWRKBAgKEAtSBXNlYXRz');

@$core.Deprecated('Use getAcDiagnosticsRequestDescriptor instead')
const GetAcDiagnosticsRequest$json = {
  '1': 'GetAcDiagnosticsRequest',
};

/// Descriptor for `GetAcDiagnosticsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAcDiagnosticsRequestDescriptor =
    $convert.base64Decode('ChdHZXRBY0RpYWdub3N0aWNzUmVxdWVzdA==');

@$core.Deprecated('Use getAcDiagnosticsResponseDescriptor instead')
const GetAcDiagnosticsResponse$json = {
  '1': 'GetAcDiagnosticsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'raw_json', '3': 2, '4': 1, '5': 9, '10': 'rawJson'},
  ],
};

/// Descriptor for `GetAcDiagnosticsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAcDiagnosticsResponseDescriptor =
    $convert.base64Decode(
        'ChhHZXRBY0RpYWdub3N0aWNzUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIZCg'
        'hyYXdfanNvbhgCIAEoCVIHcmF3SnNvbg==');

@$core.Deprecated('Use vehicleCommandResponseDescriptor instead')
const VehicleCommandResponse$json = {
  '1': 'VehicleCommandResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
    {'1': 'outcome', '3': 4, '4': 1, '5': 9, '10': 'outcome'},
    {'1': 'path', '3': 5, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `VehicleCommandResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleCommandResponseDescriptor = $convert.base64Decode(
    'ChZWZWhpY2xlQ29tbWFuZFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbW'
    'Vzc2FnZRgCIAEoCVIHbWVzc2FnZRIUCgVlcnJvchgDIAEoCVIFZXJyb3ISGAoHb3V0Y29tZRgE'
    'IAEoCVIHb3V0Y29tZRISCgRwYXRoGAUgASgJUgRwYXRo');

@$core.Deprecated('Use lockRequestDescriptor instead')
const LockRequest$json = {
  '1': 'LockRequest',
};

/// Descriptor for `LockRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockRequestDescriptor =
    $convert.base64Decode('CgtMb2NrUmVxdWVzdA==');

@$core.Deprecated('Use unlockRequestDescriptor instead')
const UnlockRequest$json = {
  '1': 'UnlockRequest',
};

/// Descriptor for `UnlockRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unlockRequestDescriptor =
    $convert.base64Decode('Cg1VbmxvY2tSZXF1ZXN0');

@$core.Deprecated('Use flashRequestDescriptor instead')
const FlashRequest$json = {
  '1': 'FlashRequest',
};

/// Descriptor for `FlashRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flashRequestDescriptor =
    $convert.base64Decode('CgxGbGFzaFJlcXVlc3Q=');

@$core.Deprecated('Use findCarRequestDescriptor instead')
const FindCarRequest$json = {
  '1': 'FindCarRequest',
};

/// Descriptor for `FindCarRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List findCarRequestDescriptor =
    $convert.base64Decode('Cg5GaW5kQ2FyUmVxdWVzdA==');

@$core.Deprecated('Use trunkRequestDescriptor instead')
const TrunkRequest$json = {
  '1': 'TrunkRequest',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
  ],
};

/// Descriptor for `TrunkRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trunkRequestDescriptor = $convert
    .base64Decode('CgxUcnVua1JlcXVlc3QSFgoGYWN0aW9uGAEgASgJUgZhY3Rpb24=');

@$core.Deprecated('Use moveWindowRequestDescriptor instead')
const MoveWindowRequest$json = {
  '1': 'MoveWindowRequest',
  '2': [
    {'1': 'window_index', '3': 1, '4': 1, '5': 5, '10': 'windowIndex'},
    {'1': 'direction', '3': 2, '4': 1, '5': 9, '10': 'direction'},
    {
      '1': 'target_percent',
      '3': 3,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'targetPercent',
      '17': true
    },
  ],
  '8': [
    {'1': '_target_percent'},
  ],
};

/// Descriptor for `MoveWindowRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List moveWindowRequestDescriptor = $convert.base64Decode(
    'ChFNb3ZlV2luZG93UmVxdWVzdBIhCgx3aW5kb3dfaW5kZXgYASABKAVSC3dpbmRvd0luZGV4Eh'
    'wKCWRpcmVjdGlvbhgCIAEoCVIJZGlyZWN0aW9uEioKDnRhcmdldF9wZXJjZW50GAMgASgFSABS'
    'DXRhcmdldFBlcmNlbnSIAQFCEQoPX3RhcmdldF9wZXJjZW50');

@$core.Deprecated('Use setClimateRequestDescriptor instead')
const SetClimateRequest$json = {
  '1': 'SetClimateRequest',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {'1': 'on', '3': 2, '4': 1, '5': 8, '10': 'on'},
    {'1': 'setpoint_c', '3': 3, '4': 1, '5': 1, '10': 'setpointC'},
    {'1': 'fan_level', '3': 4, '4': 1, '5': 5, '10': 'fanLevel'},
    {'1': 'wind_mode', '3': 5, '4': 1, '5': 5, '10': 'windMode'},
    {'1': 'max_cooling', '3': 6, '4': 1, '5': 8, '10': 'maxCooling'},
    {'1': 'restore_ac_on', '3': 7, '4': 1, '5': 8, '10': 'restoreAcOn'},
    {'1': 'restore_temp_c', '3': 8, '4': 1, '5': 1, '10': 'restoreTempC'},
    {'1': 'restore_fan_level', '3': 9, '4': 1, '5': 5, '10': 'restoreFanLevel'},
    {'1': 'cycle_mode', '3': 10, '4': 1, '5': 5, '10': 'cycleMode'},
  ],
};

/// Descriptor for `SetClimateRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setClimateRequestDescriptor = $convert.base64Decode(
    'ChFTZXRDbGltYXRlUmVxdWVzdBIWCgZhY3Rpb24YASABKAlSBmFjdGlvbhIOCgJvbhgCIAEoCF'
    'ICb24SHQoKc2V0cG9pbnRfYxgDIAEoAVIJc2V0cG9pbnRDEhsKCWZhbl9sZXZlbBgEIAEoBVII'
    'ZmFuTGV2ZWwSGwoJd2luZF9tb2RlGAUgASgFUgh3aW5kTW9kZRIfCgttYXhfY29vbGluZxgGIA'
    'EoCFIKbWF4Q29vbGluZxIiCg1yZXN0b3JlX2FjX29uGAcgASgIUgtyZXN0b3JlQWNPbhIkCg5y'
    'ZXN0b3JlX3RlbXBfYxgIIAEoAVIMcmVzdG9yZVRlbXBDEioKEXJlc3RvcmVfZmFuX2xldmVsGA'
    'kgASgFUg9yZXN0b3JlRmFuTGV2ZWwSHQoKY3ljbGVfbW9kZRgKIAEoBVIJY3ljbGVNb2Rl');

@$core.Deprecated('Use setLightsRequestDescriptor instead')
const SetLightsRequest$json = {
  '1': 'SetLightsRequest',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {'1': 'on', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'on', '17': true},
  ],
  '8': [
    {'1': '_on'},
  ],
};

/// Descriptor for `SetLightsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLightsRequestDescriptor = $convert.base64Decode(
    'ChBTZXRMaWdodHNSZXF1ZXN0EhYKBmFjdGlvbhgBIAEoCVIGYWN0aW9uEhMKAm9uGAIgASgISA'
    'BSAm9uiAEBQgUKA19vbg==');

@$core.Deprecated('Use setScreenRequestDescriptor instead')
const SetScreenRequest$json = {
  '1': 'SetScreenRequest',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'on', '17': true},
  ],
  '8': [
    {'1': '_on'},
  ],
};

/// Descriptor for `SetScreenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setScreenRequestDescriptor = $convert.base64Decode(
    'ChBTZXRTY3JlZW5SZXF1ZXN0EhMKAm9uGAEgASgISABSAm9uiAEBQgUKA19vbg==');

@$core.Deprecated('Use setMediaVolumeRequestDescriptor instead')
const SetMediaVolumeRequest$json = {
  '1': 'SetMediaVolumeRequest',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {
      '1': 'percent',
      '3': 2,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'percent',
      '17': true
    },
  ],
  '8': [
    {'1': '_percent'},
  ],
};

/// Descriptor for `SetMediaVolumeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setMediaVolumeRequestDescriptor = $convert.base64Decode(
    'ChVTZXRNZWRpYVZvbHVtZVJlcXVlc3QSFgoGYWN0aW9uGAEgASgJUgZhY3Rpb24SHQoHcGVyY2'
    'VudBgCIAEoBUgAUgdwZXJjZW50iAEBQgoKCF9wZXJjZW50');

@$core.Deprecated('Use setAdasRequestDescriptor instead')
const SetAdasRequest$json = {
  '1': 'SetAdasRequest',
  '2': [
    {'1': 'action', '3': 1, '4': 1, '5': 9, '10': 'action'},
    {'1': 'on', '3': 2, '4': 1, '5': 8, '9': 0, '10': 'on', '17': true},
  ],
  '8': [
    {'1': '_on'},
  ],
};

/// Descriptor for `SetAdasRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setAdasRequestDescriptor = $convert.base64Decode(
    'Cg5TZXRBZGFzUmVxdWVzdBIWCgZhY3Rpb24YASABKAlSBmFjdGlvbhITCgJvbhgCIAEoCEgAUg'
    'JvbogBAUIFCgNfb24=');

@$core.Deprecated('Use setBatteryHeatRequestDescriptor instead')
const SetBatteryHeatRequest$json = {
  '1': 'SetBatteryHeatRequest',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'on', '17': true},
  ],
  '8': [
    {'1': '_on'},
  ],
};

/// Descriptor for `SetBatteryHeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setBatteryHeatRequestDescriptor =
    $convert.base64Decode(
        'ChVTZXRCYXR0ZXJ5SGVhdFJlcXVlc3QSEwoCb24YASABKAhIAFICb26IAQFCBQoDX29u');

@$core.Deprecated('Use getChargingScheduleRequestDescriptor instead')
const GetChargingScheduleRequest$json = {
  '1': 'GetChargingScheduleRequest',
};

/// Descriptor for `GetChargingScheduleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getChargingScheduleRequestDescriptor =
    $convert.base64Decode('ChpHZXRDaGFyZ2luZ1NjaGVkdWxlUmVxdWVzdA==');

@$core.Deprecated('Use getChargingScheduleResponseDescriptor instead')
const GetChargingScheduleResponse$json = {
  '1': 'GetChargingScheduleResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'enabled', '3': 2, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'start_charge_time', '3': 3, '4': 1, '5': 9, '10': 'startChargeTime'},
    {'1': 'end_charge_time', '3': 4, '4': 1, '5': 9, '10': 'endChargeTime'},
    {'1': 'charge_way', '3': 5, '4': 1, '5': 5, '10': 'chargeWay'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
    {'1': 'supported', '3': 7, '4': 1, '5': 8, '10': 'supported'},
    {'1': 'reason', '3': 8, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `GetChargingScheduleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getChargingScheduleResponseDescriptor = $convert.base64Decode(
    'ChtHZXRDaGFyZ2luZ1NjaGVkdWxlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcx'
    'IYCgdlbmFibGVkGAIgASgIUgdlbmFibGVkEioKEXN0YXJ0X2NoYXJnZV90aW1lGAMgASgJUg9z'
    'dGFydENoYXJnZVRpbWUSJgoPZW5kX2NoYXJnZV90aW1lGAQgASgJUg1lbmRDaGFyZ2VUaW1lEh'
    '0KCmNoYXJnZV93YXkYBSABKAVSCWNoYXJnZVdheRIUCgVlcnJvchgGIAEoCVIFZXJyb3ISHAoJ'
    'c3VwcG9ydGVkGAcgASgIUglzdXBwb3J0ZWQSFgoGcmVhc29uGAggASgJUgZyZWFzb24=');

@$core.Deprecated('Use setChargingScheduleRequestDescriptor instead')
const SetChargingScheduleRequest$json = {
  '1': 'SetChargingScheduleRequest',
  '2': [
    {'1': 'start_charge_time', '3': 1, '4': 1, '5': 9, '10': 'startChargeTime'},
    {'1': 'end_charge_time', '3': 2, '4': 1, '5': 9, '10': 'endChargeTime'},
    {'1': 'charge_way', '3': 3, '4': 1, '5': 5, '10': 'chargeWay'},
    {
      '1': 'enabled',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'enabled',
      '17': true
    },
  ],
  '8': [
    {'1': '_enabled'},
  ],
};

/// Descriptor for `SetChargingScheduleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setChargingScheduleRequestDescriptor = $convert.base64Decode(
    'ChpTZXRDaGFyZ2luZ1NjaGVkdWxlUmVxdWVzdBIqChFzdGFydF9jaGFyZ2VfdGltZRgBIAEoCV'
    'IPc3RhcnRDaGFyZ2VUaW1lEiYKD2VuZF9jaGFyZ2VfdGltZRgCIAEoCVINZW5kQ2hhcmdlVGlt'
    'ZRIdCgpjaGFyZ2Vfd2F5GAMgASgFUgljaGFyZ2VXYXkSHQoHZW5hYmxlZBgEIAEoCEgAUgdlbm'
    'FibGVkiAEBQgoKCF9lbmFibGVk');

@$core.Deprecated('Use getChargeCapRequestDescriptor instead')
const GetChargeCapRequest$json = {
  '1': 'GetChargeCapRequest',
};

/// Descriptor for `GetChargeCapRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getChargeCapRequestDescriptor =
    $convert.base64Decode('ChNHZXRDaGFyZ2VDYXBSZXF1ZXN0');

@$core.Deprecated('Use getChargeCapResponseDescriptor instead')
const GetChargeCapResponse$json = {
  '1': 'GetChargeCapResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'percent',
      '3': 2,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'percent',
      '17': true
    },
    {
      '1': 'enabled',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'enabled',
      '17': true
    },
    {
      '1': 'supported',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'supported',
      '17': true
    },
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
  ],
  '8': [
    {'1': '_percent'},
    {'1': '_enabled'},
    {'1': '_supported'},
  ],
};

/// Descriptor for `GetChargeCapResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getChargeCapResponseDescriptor = $convert.base64Decode(
    'ChRHZXRDaGFyZ2VDYXBSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh0KB3Blcm'
    'NlbnQYAiABKAVIAFIHcGVyY2VudIgBARIdCgdlbmFibGVkGAMgASgISAFSB2VuYWJsZWSIAQES'
    'IQoJc3VwcG9ydGVkGAQgASgISAJSCXN1cHBvcnRlZIgBARIUCgVlcnJvchgFIAEoCVIFZXJyb3'
    'JCCgoIX3BlcmNlbnRCCgoIX2VuYWJsZWRCDAoKX3N1cHBvcnRlZA==');

@$core.Deprecated('Use setChargeCapRequestDescriptor instead')
const SetChargeCapRequest$json = {
  '1': 'SetChargeCapRequest',
  '2': [
    {'1': 'percent', '3': 1, '4': 1, '5': 5, '10': 'percent'},
    {
      '1': 'enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'enabled',
      '17': true
    },
  ],
  '8': [
    {'1': '_enabled'},
  ],
};

/// Descriptor for `SetChargeCapRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setChargeCapRequestDescriptor = $convert.base64Decode(
    'ChNTZXRDaGFyZ2VDYXBSZXF1ZXN0EhgKB3BlcmNlbnQYASABKAVSB3BlcmNlbnQSHQoHZW5hYm'
    'xlZBgCIAEoCEgAUgdlbmFibGVkiAEBQgoKCF9lbmFibGVk');

@$core.Deprecated('Use getGpsLocationRequestDescriptor instead')
const GetGpsLocationRequest$json = {
  '1': 'GetGpsLocationRequest',
};

/// Descriptor for `GetGpsLocationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGpsLocationRequestDescriptor =
    $convert.base64Decode('ChVHZXRHcHNMb2NhdGlvblJlcXVlc3Q=');

@$core.Deprecated('Use getGpsLocationResponseDescriptor instead')
const GetGpsLocationResponse$json = {
  '1': 'GetGpsLocationResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'location_json', '3': 2, '4': 1, '5': 9, '10': 'locationJson'},
    {'1': 'google_maps_url', '3': 3, '4': 1, '5': 9, '10': 'googleMapsUrl'},
  ],
};

/// Descriptor for `GetGpsLocationResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGpsLocationResponseDescriptor = $convert.base64Decode(
    'ChZHZXRHcHNMb2NhdGlvblJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSIwoNbG'
    '9jYXRpb25fanNvbhgCIAEoCVIMbG9jYXRpb25Kc29uEiYKD2dvb2dsZV9tYXBzX3VybBgDIAEo'
    'CVINZ29vZ2xlTWFwc1VybA==');

@$core.Deprecated('Use startGpsRequestDescriptor instead')
const StartGpsRequest$json = {
  '1': 'StartGpsRequest',
};

/// Descriptor for `StartGpsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startGpsRequestDescriptor =
    $convert.base64Decode('Cg9TdGFydEdwc1JlcXVlc3Q=');

@$core.Deprecated('Use startGpsResponseDescriptor instead')
const StartGpsResponse$json = {
  '1': 'StartGpsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'location_json', '3': 3, '4': 1, '5': 9, '10': 'locationJson'},
  ],
};

/// Descriptor for `StartGpsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startGpsResponseDescriptor = $convert.base64Decode(
    'ChBTdGFydEdwc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHbWVzc2FnZR'
    'gCIAEoCVIHbWVzc2FnZRIjCg1sb2NhdGlvbl9qc29uGAMgASgJUgxsb2NhdGlvbkpzb24=');

@$core.Deprecated('Use stopGpsRequestDescriptor instead')
const StopGpsRequest$json = {
  '1': 'StopGpsRequest',
};

/// Descriptor for `StopGpsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopGpsRequestDescriptor =
    $convert.base64Decode('Cg5TdG9wR3BzUmVxdWVzdA==');

@$core.Deprecated('Use stopGpsResponseDescriptor instead')
const StopGpsResponse$json = {
  '1': 'StopGpsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `StopGpsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopGpsResponseDescriptor = $convert.base64Decode(
    'Cg9TdG9wR3BzUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZXNzYWdlGA'
    'IgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use issueActionTokenRequestDescriptor instead')
const IssueActionTokenRequest$json = {
  '1': 'IssueActionTokenRequest',
};

/// Descriptor for `IssueActionTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueActionTokenRequestDescriptor =
    $convert.base64Decode('ChdJc3N1ZUFjdGlvblRva2VuUmVxdWVzdA==');

@$core.Deprecated('Use issueActionTokenResponseDescriptor instead')
const IssueActionTokenResponse$json = {
  '1': 'IssueActionTokenResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'expires_in_seconds',
      '3': 3,
      '4': 1,
      '5': 5,
      '10': 'expiresInSeconds'
    },
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `IssueActionTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueActionTokenResponseDescriptor = $convert.base64Decode(
    'ChhJc3N1ZUFjdGlvblRva2VuUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCg'
    'V0b2tlbhgCIAEoCVIFdG9rZW4SLAoSZXhwaXJlc19pbl9zZWNvbmRzGAMgASgFUhBleHBpcmVz'
    'SW5TZWNvbmRzEhQKBWVycm9yGAQgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getAdasInventoryRequestDescriptor instead')
const GetAdasInventoryRequest$json = {
  '1': 'GetAdasInventoryRequest',
};

/// Descriptor for `GetAdasInventoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAdasInventoryRequestDescriptor =
    $convert.base64Decode('ChdHZXRBZGFzSW52ZW50b3J5UmVxdWVzdA==');

@$core.Deprecated('Use getAdasInventoryResponseDescriptor instead')
const GetAdasInventoryResponse$json = {
  '1': 'GetAdasInventoryResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'adas_json', '3': 2, '4': 1, '5': 9, '10': 'adasJson'},
  ],
};

/// Descriptor for `GetAdasInventoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAdasInventoryResponseDescriptor =
    $convert.base64Decode(
        'ChhHZXRBZGFzSW52ZW50b3J5UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIbCg'
        'lhZGFzX2pzb24YAiABKAlSCGFkYXNKc29u');

const $core.Map<$core.String, $core.dynamic> VehicleServiceBase$json = {
  '1': 'VehicleService',
  '2': [
    {
      '1': 'GetState',
      '2': '.bladewatch.v1.GetVehicleStateRequest',
      '3': '.bladewatch.v1.GetVehicleStateResponse'
    },
    {
      '1': 'GetAcDiagnostics',
      '2': '.bladewatch.v1.GetAcDiagnosticsRequest',
      '3': '.bladewatch.v1.GetAcDiagnosticsResponse'
    },
    {
      '1': 'Lock',
      '2': '.bladewatch.v1.LockRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'Unlock',
      '2': '.bladewatch.v1.UnlockRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'Trunk',
      '2': '.bladewatch.v1.TrunkRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'MoveWindow',
      '2': '.bladewatch.v1.MoveWindowRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'Flash',
      '2': '.bladewatch.v1.FlashRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'FindCar',
      '2': '.bladewatch.v1.FindCarRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'SetClimate',
      '2': '.bladewatch.v1.SetClimateRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'SetLights',
      '2': '.bladewatch.v1.SetLightsRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'SetScreen',
      '2': '.bladewatch.v1.SetScreenRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'SetMediaVolume',
      '2': '.bladewatch.v1.SetMediaVolumeRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'SetAdas',
      '2': '.bladewatch.v1.SetAdasRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'SetBatteryHeat',
      '2': '.bladewatch.v1.SetBatteryHeatRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'GetChargingSchedule',
      '2': '.bladewatch.v1.GetChargingScheduleRequest',
      '3': '.bladewatch.v1.GetChargingScheduleResponse'
    },
    {
      '1': 'SetChargingSchedule',
      '2': '.bladewatch.v1.SetChargingScheduleRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'GetChargeCap',
      '2': '.bladewatch.v1.GetChargeCapRequest',
      '3': '.bladewatch.v1.GetChargeCapResponse'
    },
    {
      '1': 'SetChargeCap',
      '2': '.bladewatch.v1.SetChargeCapRequest',
      '3': '.bladewatch.v1.VehicleCommandResponse'
    },
    {
      '1': 'GetGpsLocation',
      '2': '.bladewatch.v1.GetGpsLocationRequest',
      '3': '.bladewatch.v1.GetGpsLocationResponse'
    },
    {
      '1': 'StartGps',
      '2': '.bladewatch.v1.StartGpsRequest',
      '3': '.bladewatch.v1.StartGpsResponse'
    },
    {
      '1': 'StopGps',
      '2': '.bladewatch.v1.StopGpsRequest',
      '3': '.bladewatch.v1.StopGpsResponse'
    },
    {
      '1': 'IssueActionToken',
      '2': '.bladewatch.v1.IssueActionTokenRequest',
      '3': '.bladewatch.v1.IssueActionTokenResponse'
    },
    {
      '1': 'GetAdasInventory',
      '2': '.bladewatch.v1.GetAdasInventoryRequest',
      '3': '.bladewatch.v1.GetAdasInventoryResponse'
    },
  ],
};

@$core.Deprecated('Use vehicleServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    VehicleServiceBase$messageJson = {
  '.bladewatch.v1.GetVehicleStateRequest': GetVehicleStateRequest$json,
  '.bladewatch.v1.GetVehicleStateResponse': GetVehicleStateResponse$json,
  '.bladewatch.v1.DoorStatus': DoorStatus$json,
  '.bladewatch.v1.WindowStatus': WindowStatus$json,
  '.bladewatch.v1.VehicleCapabilities': VehicleCapabilities$json,
  '.bladewatch.v1.WindowCapabilities': WindowCapabilities$json,
  '.bladewatch.v1.TrunkStatus': TrunkStatus$json,
  '.bladewatch.v1.SunroofStatus': SunroofStatus$json,
  '.bladewatch.v1.BatteryStatus': BatteryStatus$json,
  '.bladewatch.v1.LightStatus': LightStatus$json,
  '.bladewatch.v1.AdasStatus': AdasStatus$json,
  '.bladewatch.v1.ClimateStatus': ClimateStatus$json,
  '.bladewatch.v1.TyreStatus': TyreStatus$json,
  '.bladewatch.v1.TyrePressure': TyrePressure$json,
  '.bladewatch.v1.GetAcDiagnosticsRequest': GetAcDiagnosticsRequest$json,
  '.bladewatch.v1.GetAcDiagnosticsResponse': GetAcDiagnosticsResponse$json,
  '.bladewatch.v1.LockRequest': LockRequest$json,
  '.bladewatch.v1.VehicleCommandResponse': VehicleCommandResponse$json,
  '.bladewatch.v1.UnlockRequest': UnlockRequest$json,
  '.bladewatch.v1.TrunkRequest': TrunkRequest$json,
  '.bladewatch.v1.MoveWindowRequest': MoveWindowRequest$json,
  '.bladewatch.v1.FlashRequest': FlashRequest$json,
  '.bladewatch.v1.FindCarRequest': FindCarRequest$json,
  '.bladewatch.v1.SetClimateRequest': SetClimateRequest$json,
  '.bladewatch.v1.SetLightsRequest': SetLightsRequest$json,
  '.bladewatch.v1.SetScreenRequest': SetScreenRequest$json,
  '.bladewatch.v1.SetMediaVolumeRequest': SetMediaVolumeRequest$json,
  '.bladewatch.v1.SetAdasRequest': SetAdasRequest$json,
  '.bladewatch.v1.SetBatteryHeatRequest': SetBatteryHeatRequest$json,
  '.bladewatch.v1.GetChargingScheduleRequest': GetChargingScheduleRequest$json,
  '.bladewatch.v1.GetChargingScheduleResponse':
      GetChargingScheduleResponse$json,
  '.bladewatch.v1.SetChargingScheduleRequest': SetChargingScheduleRequest$json,
  '.bladewatch.v1.GetChargeCapRequest': GetChargeCapRequest$json,
  '.bladewatch.v1.GetChargeCapResponse': GetChargeCapResponse$json,
  '.bladewatch.v1.SetChargeCapRequest': SetChargeCapRequest$json,
  '.bladewatch.v1.GetGpsLocationRequest': GetGpsLocationRequest$json,
  '.bladewatch.v1.GetGpsLocationResponse': GetGpsLocationResponse$json,
  '.bladewatch.v1.StartGpsRequest': StartGpsRequest$json,
  '.bladewatch.v1.StartGpsResponse': StartGpsResponse$json,
  '.bladewatch.v1.StopGpsRequest': StopGpsRequest$json,
  '.bladewatch.v1.StopGpsResponse': StopGpsResponse$json,
  '.bladewatch.v1.IssueActionTokenRequest': IssueActionTokenRequest$json,
  '.bladewatch.v1.IssueActionTokenResponse': IssueActionTokenResponse$json,
  '.bladewatch.v1.GetAdasInventoryRequest': GetAdasInventoryRequest$json,
  '.bladewatch.v1.GetAdasInventoryResponse': GetAdasInventoryResponse$json,
};

/// Descriptor for `VehicleService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List vehicleServiceDescriptor = $convert.base64Decode(
    'Cg5WZWhpY2xlU2VydmljZRJZCghHZXRTdGF0ZRIlLmJsYWRld2F0Y2gudjEuR2V0VmVoaWNsZV'
    'N0YXRlUmVxdWVzdBomLmJsYWRld2F0Y2gudjEuR2V0VmVoaWNsZVN0YXRlUmVzcG9uc2USYwoQ'
    'R2V0QWNEaWFnbm9zdGljcxImLmJsYWRld2F0Y2gudjEuR2V0QWNEaWFnbm9zdGljc1JlcXVlc3'
    'QaJy5ibGFkZXdhdGNoLnYxLkdldEFjRGlhZ25vc3RpY3NSZXNwb25zZRJJCgRMb2NrEhouYmxh'
    'ZGV3YXRjaC52MS5Mb2NrUmVxdWVzdBolLmJsYWRld2F0Y2gudjEuVmVoaWNsZUNvbW1hbmRSZX'
    'Nwb25zZRJNCgZVbmxvY2sSHC5ibGFkZXdhdGNoLnYxLlVubG9ja1JlcXVlc3QaJS5ibGFkZXdh'
    'dGNoLnYxLlZlaGljbGVDb21tYW5kUmVzcG9uc2USSwoFVHJ1bmsSGy5ibGFkZXdhdGNoLnYxLl'
    'RydW5rUmVxdWVzdBolLmJsYWRld2F0Y2gudjEuVmVoaWNsZUNvbW1hbmRSZXNwb25zZRJVCgpN'
    'b3ZlV2luZG93EiAuYmxhZGV3YXRjaC52MS5Nb3ZlV2luZG93UmVxdWVzdBolLmJsYWRld2F0Y2'
    'gudjEuVmVoaWNsZUNvbW1hbmRSZXNwb25zZRJLCgVGbGFzaBIbLmJsYWRld2F0Y2gudjEuRmxh'
    'c2hSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3BvbnNlEk8KB0Zpbm'
    'RDYXISHS5ibGFkZXdhdGNoLnYxLkZpbmRDYXJSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhp'
    'Y2xlQ29tbWFuZFJlc3BvbnNlElUKClNldENsaW1hdGUSIC5ibGFkZXdhdGNoLnYxLlNldENsaW'
    '1hdGVSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3BvbnNlElMKCVNl'
    'dExpZ2h0cxIfLmJsYWRld2F0Y2gudjEuU2V0TGlnaHRzUmVxdWVzdBolLmJsYWRld2F0Y2gudj'
    'EuVmVoaWNsZUNvbW1hbmRSZXNwb25zZRJTCglTZXRTY3JlZW4SHy5ibGFkZXdhdGNoLnYxLlNl'
    'dFNjcmVlblJlcXVlc3QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbGVDb21tYW5kUmVzcG9uc2USXQ'
    'oOU2V0TWVkaWFWb2x1bWUSJC5ibGFkZXdhdGNoLnYxLlNldE1lZGlhVm9sdW1lUmVxdWVzdBol'
    'LmJsYWRld2F0Y2gudjEuVmVoaWNsZUNvbW1hbmRSZXNwb25zZRJPCgdTZXRBZGFzEh0uYmxhZG'
    'V3YXRjaC52MS5TZXRBZGFzUmVxdWVzdBolLmJsYWRld2F0Y2gudjEuVmVoaWNsZUNvbW1hbmRS'
    'ZXNwb25zZRJdCg5TZXRCYXR0ZXJ5SGVhdBIkLmJsYWRld2F0Y2gudjEuU2V0QmF0dGVyeUhlYX'
    'RSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3BvbnNlEmwKE0dldENo'
    'YXJnaW5nU2NoZWR1bGUSKS5ibGFkZXdhdGNoLnYxLkdldENoYXJnaW5nU2NoZWR1bGVSZXF1ZX'
    'N0GiouYmxhZGV3YXRjaC52MS5HZXRDaGFyZ2luZ1NjaGVkdWxlUmVzcG9uc2USZwoTU2V0Q2hh'
    'cmdpbmdTY2hlZHVsZRIpLmJsYWRld2F0Y2gudjEuU2V0Q2hhcmdpbmdTY2hlZHVsZVJlcXVlc3'
    'QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbGVDb21tYW5kUmVzcG9uc2USVwoMR2V0Q2hhcmdlQ2Fw'
    'EiIuYmxhZGV3YXRjaC52MS5HZXRDaGFyZ2VDYXBSZXF1ZXN0GiMuYmxhZGV3YXRjaC52MS5HZX'
    'RDaGFyZ2VDYXBSZXNwb25zZRJZCgxTZXRDaGFyZ2VDYXASIi5ibGFkZXdhdGNoLnYxLlNldENo'
    'YXJnZUNhcFJlcXVlc3QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbGVDb21tYW5kUmVzcG9uc2USXQ'
    'oOR2V0R3BzTG9jYXRpb24SJC5ibGFkZXdhdGNoLnYxLkdldEdwc0xvY2F0aW9uUmVxdWVzdBol'
    'LmJsYWRld2F0Y2gudjEuR2V0R3BzTG9jYXRpb25SZXNwb25zZRJLCghTdGFydEdwcxIeLmJsYW'
    'Rld2F0Y2gudjEuU3RhcnRHcHNSZXF1ZXN0Gh8uYmxhZGV3YXRjaC52MS5TdGFydEdwc1Jlc3Bv'
    'bnNlEkgKB1N0b3BHcHMSHS5ibGFkZXdhdGNoLnYxLlN0b3BHcHNSZXF1ZXN0Gh4uYmxhZGV3YX'
    'RjaC52MS5TdG9wR3BzUmVzcG9uc2USYwoQSXNzdWVBY3Rpb25Ub2tlbhImLmJsYWRld2F0Y2gu'
    'djEuSXNzdWVBY3Rpb25Ub2tlblJlcXVlc3QaJy5ibGFkZXdhdGNoLnYxLklzc3VlQWN0aW9uVG'
    '9rZW5SZXNwb25zZRJjChBHZXRBZGFzSW52ZW50b3J5EiYuYmxhZGV3YXRjaC52MS5HZXRBZGFz'
    'SW52ZW50b3J5UmVxdWVzdBonLmJsYWRld2F0Y2gudjEuR2V0QWRhc0ludmVudG9yeVJlc3Bvbn'
    'Nl');
