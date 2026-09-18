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

@$core.Deprecated('Use seatCapabilitiesDescriptor instead')
const SeatCapabilities$json = {
  '1': 'SeatCapabilities',
  '2': [
    {'1': 'driver_heat', '3': 1, '4': 1, '5': 8, '10': 'driverHeat'},
    {'1': 'passenger_heat', '3': 2, '4': 1, '5': 8, '10': 'passengerHeat'},
    {'1': 'driver_cool', '3': 3, '4': 1, '5': 8, '10': 'driverCool'},
    {'1': 'passenger_cool', '3': 4, '4': 1, '5': 8, '10': 'passengerCool'},
    {
      '1': 'driver_memory_recall',
      '3': 5,
      '4': 1,
      '5': 8,
      '10': 'driverMemoryRecall'
    },
  ],
};

/// Descriptor for `SeatCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List seatCapabilitiesDescriptor = $convert.base64Decode(
    'ChBTZWF0Q2FwYWJpbGl0aWVzEh8KC2RyaXZlcl9oZWF0GAEgASgIUgpkcml2ZXJIZWF0EiUKDn'
    'Bhc3Nlbmdlcl9oZWF0GAIgASgIUg1wYXNzZW5nZXJIZWF0Eh8KC2RyaXZlcl9jb29sGAMgASgI'
    'Ugpkcml2ZXJDb29sEiUKDnBhc3Nlbmdlcl9jb29sGAQgASgIUg1wYXNzZW5nZXJDb29sEjAKFG'
    'RyaXZlcl9tZW1vcnlfcmVjYWxsGAUgASgIUhJkcml2ZXJNZW1vcnlSZWNhbGw=');

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
    {
      '1': 'seats',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SeatCapabilities',
      '10': 'seats'
    },
  ],
};

/// Descriptor for `VehicleCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleCapabilitiesDescriptor = $convert.base64Decode(
    'ChNWZWhpY2xlQ2FwYWJpbGl0aWVzEjsKB3dpbmRvd3MYASABKAsyIS5ibGFkZXdhdGNoLnYxLl'
    'dpbmRvd0NhcGFiaWxpdGllc1IHd2luZG93cxI1CgVzZWF0cxgCIAEoCzIfLmJsYWRld2F0Y2gu'
    'djEuU2VhdENhcGFiaWxpdGllc1IFc2VhdHM=');

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

@$core.Deprecated('Use seatStatusDescriptor instead')
const SeatStatus$json = {
  '1': 'SeatStatus',
  '2': [
    {'1': 'heat', '3': 1, '4': 3, '5': 5, '10': 'heat'},
    {'1': 'cool', '3': 2, '4': 3, '5': 5, '10': 'cool'},
    {
      '1': 'ventilated_supported',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'ventilatedSupported'
    },
  ],
};

/// Descriptor for `SeatStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List seatStatusDescriptor = $convert.base64Decode(
    'CgpTZWF0U3RhdHVzEhIKBGhlYXQYASADKAVSBGhlYXQSEgoEY29vbBgCIAMoBVIEY29vbBIxCh'
    'R2ZW50aWxhdGVkX3N1cHBvcnRlZBgDIAEoCFITdmVudGlsYXRlZFN1cHBvcnRlZA==');

@$core.Deprecated('Use climateStatusDescriptor instead')
const ClimateStatus$json = {
  '1': 'ClimateStatus',
  '2': [
    {'1': 'ac_on', '3': 1, '4': 1, '5': 8, '10': 'acOn'},
    {'1': 'setpoint_c', '3': 2, '4': 1, '5': 1, '10': 'setpointC'},
    {'1': 'inside_temp_c', '3': 3, '4': 1, '5': 1, '10': 'insideTempC'},
    {'1': 'wind_mode', '3': 4, '4': 1, '5': 5, '10': 'windMode'},
    {'1': 'fan_level', '3': 5, '4': 1, '5': 5, '10': 'fanLevel'},
    {'1': 'max_cooling', '3': 6, '4': 1, '5': 8, '10': 'maxCooling'},
  ],
};

/// Descriptor for `ClimateStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List climateStatusDescriptor = $convert.base64Decode(
    'Cg1DbGltYXRlU3RhdHVzEhMKBWFjX29uGAEgASgIUgRhY09uEh0KCnNldHBvaW50X2MYAiABKA'
    'FSCXNldHBvaW50QxIiCg1pbnNpZGVfdGVtcF9jGAMgASgBUgtpbnNpZGVUZW1wQxIbCgl3aW5k'
    'X21vZGUYBCABKAVSCHdpbmRNb2RlEhsKCWZhbl9sZXZlbBgFIAEoBVIIZmFuTGV2ZWwSHwoLbW'
    'F4X2Nvb2xpbmcYBiABKAhSCm1heENvb2xpbmc=');

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
      '1': 'seats',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SeatStatus',
      '10': 'seats'
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
    'BGFkYXMYCSABKAsyGS5ibGFkZXdhdGNoLnYxLkFkYXNTdGF0dXNSBGFkYXMSLwoFc2VhdHMYCi'
    'ABKAsyGS5ibGFkZXdhdGNoLnYxLlNlYXRTdGF0dXNSBXNlYXRzEjYKB2NsaW1hdGUYCyABKAsy'
    'HC5ibGFkZXdhdGNoLnYxLkNsaW1hdGVTdGF0dXNSB2NsaW1hdGUSLwoFdHlyZXMYDCABKAsyGS'
    '5ibGFkZXdhdGNoLnYxLlR5cmVTdGF0dXNSBXR5cmVzEhQKBWVycm9yGA0gASgJUgVlcnJvchIw'
    'ChRtZWRpYV92b2x1bWVfcGVyY2VudBgOIAEoBVISbWVkaWFWb2x1bWVQZXJjZW50Eh8KC21lZG'
    'lhX211dGVkGA8gASgIUgptZWRpYU11dGVk');

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

@$core.Deprecated('Use getSeatDiagnosticsRequestDescriptor instead')
const GetSeatDiagnosticsRequest$json = {
  '1': 'GetSeatDiagnosticsRequest',
};

/// Descriptor for `GetSeatDiagnosticsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSeatDiagnosticsRequestDescriptor =
    $convert.base64Decode('ChlHZXRTZWF0RGlhZ25vc3RpY3NSZXF1ZXN0');

@$core.Deprecated('Use getSeatDiagnosticsResponseDescriptor instead')
const GetSeatDiagnosticsResponse$json = {
  '1': 'GetSeatDiagnosticsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'raw_json', '3': 2, '4': 1, '5': 9, '10': 'rawJson'},
  ],
};

/// Descriptor for `GetSeatDiagnosticsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSeatDiagnosticsResponseDescriptor =
    $convert.base64Decode(
        'ChpHZXRTZWF0RGlhZ25vc3RpY3NSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'kKCHJhd19qc29uGAIgASgJUgdyYXdKc29u');

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

@$core.Deprecated('Use setSeatRequestDescriptor instead')
const SetSeatRequest$json = {
  '1': 'SetSeatRequest',
  '2': [
    {'1': 'seat_index', '3': 1, '4': 1, '5': 5, '10': 'seatIndex'},
    {'1': 'action', '3': 2, '4': 1, '5': 9, '10': 'action'},
    {'1': 'level', '3': 3, '4': 1, '5': 5, '10': 'level'},
    {'1': 'driver_heat', '3': 4, '4': 1, '5': 5, '10': 'driverHeat'},
    {'1': 'driver_vent', '3': 5, '4': 1, '5': 5, '10': 'driverVent'},
    {'1': 'passenger_heat', '3': 6, '4': 1, '5': 5, '10': 'passengerHeat'},
    {'1': 'passenger_vent', '3': 7, '4': 1, '5': 5, '10': 'passengerVent'},
  ],
};

/// Descriptor for `SetSeatRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setSeatRequestDescriptor = $convert.base64Decode(
    'Cg5TZXRTZWF0UmVxdWVzdBIdCgpzZWF0X2luZGV4GAEgASgFUglzZWF0SW5kZXgSFgoGYWN0aW'
    '9uGAIgASgJUgZhY3Rpb24SFAoFbGV2ZWwYAyABKAVSBWxldmVsEh8KC2RyaXZlcl9oZWF0GAQg'
    'ASgFUgpkcml2ZXJIZWF0Eh8KC2RyaXZlcl92ZW50GAUgASgFUgpkcml2ZXJWZW50EiUKDnBhc3'
    'Nlbmdlcl9oZWF0GAYgASgFUg1wYXNzZW5nZXJIZWF0EiUKDnBhc3Nlbmdlcl92ZW50GAcgASgF'
    'Ug1wYXNzZW5nZXJWZW50');

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
      '1': 'GetSeatDiagnostics',
      '2': '.bladewatch.v1.GetSeatDiagnosticsRequest',
      '3': '.bladewatch.v1.GetSeatDiagnosticsResponse'
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
      '1': 'SetSeat',
      '2': '.bladewatch.v1.SetSeatRequest',
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
  '.bladewatch.v1.SeatCapabilities': SeatCapabilities$json,
  '.bladewatch.v1.TrunkStatus': TrunkStatus$json,
  '.bladewatch.v1.SunroofStatus': SunroofStatus$json,
  '.bladewatch.v1.BatteryStatus': BatteryStatus$json,
  '.bladewatch.v1.LightStatus': LightStatus$json,
  '.bladewatch.v1.AdasStatus': AdasStatus$json,
  '.bladewatch.v1.SeatStatus': SeatStatus$json,
  '.bladewatch.v1.ClimateStatus': ClimateStatus$json,
  '.bladewatch.v1.TyreStatus': TyreStatus$json,
  '.bladewatch.v1.TyrePressure': TyrePressure$json,
  '.bladewatch.v1.GetAcDiagnosticsRequest': GetAcDiagnosticsRequest$json,
  '.bladewatch.v1.GetAcDiagnosticsResponse': GetAcDiagnosticsResponse$json,
  '.bladewatch.v1.GetSeatDiagnosticsRequest': GetSeatDiagnosticsRequest$json,
  '.bladewatch.v1.GetSeatDiagnosticsResponse': GetSeatDiagnosticsResponse$json,
  '.bladewatch.v1.LockRequest': LockRequest$json,
  '.bladewatch.v1.VehicleCommandResponse': VehicleCommandResponse$json,
  '.bladewatch.v1.UnlockRequest': UnlockRequest$json,
  '.bladewatch.v1.TrunkRequest': TrunkRequest$json,
  '.bladewatch.v1.MoveWindowRequest': MoveWindowRequest$json,
  '.bladewatch.v1.FlashRequest': FlashRequest$json,
  '.bladewatch.v1.FindCarRequest': FindCarRequest$json,
  '.bladewatch.v1.SetClimateRequest': SetClimateRequest$json,
  '.bladewatch.v1.SetSeatRequest': SetSeatRequest$json,
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
};

/// Descriptor for `VehicleService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List vehicleServiceDescriptor = $convert.base64Decode(
    'Cg5WZWhpY2xlU2VydmljZRJZCghHZXRTdGF0ZRIlLmJsYWRld2F0Y2gudjEuR2V0VmVoaWNsZV'
    'N0YXRlUmVxdWVzdBomLmJsYWRld2F0Y2gudjEuR2V0VmVoaWNsZVN0YXRlUmVzcG9uc2USYwoQ'
    'R2V0QWNEaWFnbm9zdGljcxImLmJsYWRld2F0Y2gudjEuR2V0QWNEaWFnbm9zdGljc1JlcXVlc3'
    'QaJy5ibGFkZXdhdGNoLnYxLkdldEFjRGlhZ25vc3RpY3NSZXNwb25zZRJpChJHZXRTZWF0RGlh'
    'Z25vc3RpY3MSKC5ibGFkZXdhdGNoLnYxLkdldFNlYXREaWFnbm9zdGljc1JlcXVlc3QaKS5ibG'
    'FkZXdhdGNoLnYxLkdldFNlYXREaWFnbm9zdGljc1Jlc3BvbnNlEkkKBExvY2sSGi5ibGFkZXdh'
    'dGNoLnYxLkxvY2tSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3Bvbn'
    'NlEk0KBlVubG9jaxIcLmJsYWRld2F0Y2gudjEuVW5sb2NrUmVxdWVzdBolLmJsYWRld2F0Y2gu'
    'djEuVmVoaWNsZUNvbW1hbmRSZXNwb25zZRJLCgVUcnVuaxIbLmJsYWRld2F0Y2gudjEuVHJ1bm'
    'tSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3BvbnNlElUKCk1vdmVX'
    'aW5kb3cSIC5ibGFkZXdhdGNoLnYxLk1vdmVXaW5kb3dSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS'
    '5WZWhpY2xlQ29tbWFuZFJlc3BvbnNlEksKBUZsYXNoEhsuYmxhZGV3YXRjaC52MS5GbGFzaFJl'
    'cXVlc3QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbGVDb21tYW5kUmVzcG9uc2USTwoHRmluZENhch'
    'IdLmJsYWRld2F0Y2gudjEuRmluZENhclJlcXVlc3QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbGVD'
    'b21tYW5kUmVzcG9uc2USVQoKU2V0Q2xpbWF0ZRIgLmJsYWRld2F0Y2gudjEuU2V0Q2xpbWF0ZV'
    'JlcXVlc3QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbGVDb21tYW5kUmVzcG9uc2USTwoHU2V0U2Vh'
    'dBIdLmJsYWRld2F0Y2gudjEuU2V0U2VhdFJlcXVlc3QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbG'
    'VDb21tYW5kUmVzcG9uc2USUwoJU2V0TGlnaHRzEh8uYmxhZGV3YXRjaC52MS5TZXRMaWdodHNS'
    'ZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3BvbnNlElMKCVNldFNjcm'
    'VlbhIfLmJsYWRld2F0Y2gudjEuU2V0U2NyZWVuUmVxdWVzdBolLmJsYWRld2F0Y2gudjEuVmVo'
    'aWNsZUNvbW1hbmRSZXNwb25zZRJdCg5TZXRNZWRpYVZvbHVtZRIkLmJsYWRld2F0Y2gudjEuU2'
    'V0TWVkaWFWb2x1bWVSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3Bv'
    'bnNlEk8KB1NldEFkYXMSHS5ibGFkZXdhdGNoLnYxLlNldEFkYXNSZXF1ZXN0GiUuYmxhZGV3YX'
    'RjaC52MS5WZWhpY2xlQ29tbWFuZFJlc3BvbnNlEl0KDlNldEJhdHRlcnlIZWF0EiQuYmxhZGV3'
    'YXRjaC52MS5TZXRCYXR0ZXJ5SGVhdFJlcXVlc3QaJS5ibGFkZXdhdGNoLnYxLlZlaGljbGVDb2'
    '1tYW5kUmVzcG9uc2USbAoTR2V0Q2hhcmdpbmdTY2hlZHVsZRIpLmJsYWRld2F0Y2gudjEuR2V0'
    'Q2hhcmdpbmdTY2hlZHVsZVJlcXVlc3QaKi5ibGFkZXdhdGNoLnYxLkdldENoYXJnaW5nU2NoZW'
    'R1bGVSZXNwb25zZRJnChNTZXRDaGFyZ2luZ1NjaGVkdWxlEikuYmxhZGV3YXRjaC52MS5TZXRD'
    'aGFyZ2luZ1NjaGVkdWxlUmVxdWVzdBolLmJsYWRld2F0Y2gudjEuVmVoaWNsZUNvbW1hbmRSZX'
    'Nwb25zZRJXCgxHZXRDaGFyZ2VDYXASIi5ibGFkZXdhdGNoLnYxLkdldENoYXJnZUNhcFJlcXVl'
    'c3QaIy5ibGFkZXdhdGNoLnYxLkdldENoYXJnZUNhcFJlc3BvbnNlElkKDFNldENoYXJnZUNhcB'
    'IiLmJsYWRld2F0Y2gudjEuU2V0Q2hhcmdlQ2FwUmVxdWVzdBolLmJsYWRld2F0Y2gudjEuVmVo'
    'aWNsZUNvbW1hbmRSZXNwb25zZRJdCg5HZXRHcHNMb2NhdGlvbhIkLmJsYWRld2F0Y2gudjEuR2'
    'V0R3BzTG9jYXRpb25SZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5HZXRHcHNMb2NhdGlvblJlc3Bv'
    'bnNlEksKCFN0YXJ0R3BzEh4uYmxhZGV3YXRjaC52MS5TdGFydEdwc1JlcXVlc3QaHy5ibGFkZX'
    'dhdGNoLnYxLlN0YXJ0R3BzUmVzcG9uc2USSAoHU3RvcEdwcxIdLmJsYWRld2F0Y2gudjEuU3Rv'
    'cEdwc1JlcXVlc3QaHi5ibGFkZXdhdGNoLnYxLlN0b3BHcHNSZXNwb25zZQ==');
