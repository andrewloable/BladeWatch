// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/trips.proto.

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

@$core.Deprecated('Use tripSummaryDescriptor instead')
const TripSummary$json = {
  '1': 'TripSummary',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'start_time', '3': 2, '4': 1, '5': 3, '10': 'startTime'},
    {'1': 'end_time', '3': 3, '4': 1, '5': 3, '10': 'endTime'},
    {'1': 'distance_km', '3': 4, '4': 1, '5': 1, '10': 'distanceKm'},
    {'1': 'duration_seconds', '3': 5, '4': 1, '5': 5, '10': 'durationSeconds'},
    {'1': 'avg_speed_kmh', '3': 6, '4': 1, '5': 1, '10': 'avgSpeedKmh'},
    {'1': 'max_speed_kmh', '3': 7, '4': 1, '5': 5, '10': 'maxSpeedKmh'},
    {'1': 'soc_start', '3': 8, '4': 1, '5': 1, '10': 'socStart'},
    {'1': 'soc_end', '3': 9, '4': 1, '5': 1, '10': 'socEnd'},
    {'1': 'energy_per_km', '3': 10, '4': 1, '5': 1, '10': 'energyPerKm'},
    {'1': 'trip_cost', '3': 11, '4': 1, '5': 1, '10': 'tripCost'},
    {'1': 'currency', '3': 12, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'overall_score', '3': 13, '4': 1, '5': 5, '10': 'overallScore'},
    {'1': 'kinematic_state', '3': 14, '4': 1, '5': 9, '10': 'kinematicState'},
    {'1': 'gradient_profile', '3': 15, '4': 1, '5': 9, '10': 'gradientProfile'},
    {'1': 'start_lat', '3': 16, '4': 1, '5': 1, '10': 'startLat'},
    {'1': 'start_lon', '3': 17, '4': 1, '5': 1, '10': 'startLon'},
    {'1': 'end_lat', '3': 18, '4': 1, '5': 1, '10': 'endLat'},
    {'1': 'end_lon', '3': 19, '4': 1, '5': 1, '10': 'endLon'},
    {'1': 'ext_temp_c', '3': 20, '4': 1, '5': 5, '10': 'extTempC'},
  ],
};

/// Descriptor for `TripSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tripSummaryDescriptor = $convert.base64Decode(
    'CgtUcmlwU3VtbWFyeRIOCgJpZBgBIAEoA1ICaWQSHQoKc3RhcnRfdGltZRgCIAEoA1IJc3Rhcn'
    'RUaW1lEhkKCGVuZF90aW1lGAMgASgDUgdlbmRUaW1lEh8KC2Rpc3RhbmNlX2ttGAQgASgBUgpk'
    'aXN0YW5jZUttEikKEGR1cmF0aW9uX3NlY29uZHMYBSABKAVSD2R1cmF0aW9uU2Vjb25kcxIiCg'
    '1hdmdfc3BlZWRfa21oGAYgASgBUgthdmdTcGVlZEttaBIiCg1tYXhfc3BlZWRfa21oGAcgASgF'
    'UgttYXhTcGVlZEttaBIbCglzb2Nfc3RhcnQYCCABKAFSCHNvY1N0YXJ0EhcKB3NvY19lbmQYCS'
    'ABKAFSBnNvY0VuZBIiCg1lbmVyZ3lfcGVyX2ttGAogASgBUgtlbmVyZ3lQZXJLbRIbCgl0cmlw'
    'X2Nvc3QYCyABKAFSCHRyaXBDb3N0EhoKCGN1cnJlbmN5GAwgASgJUghjdXJyZW5jeRIjCg1vdm'
    'VyYWxsX3Njb3JlGA0gASgFUgxvdmVyYWxsU2NvcmUSJwoPa2luZW1hdGljX3N0YXRlGA4gASgJ'
    'Ug5raW5lbWF0aWNTdGF0ZRIpChBncmFkaWVudF9wcm9maWxlGA8gASgJUg9ncmFkaWVudFByb2'
    'ZpbGUSGwoJc3RhcnRfbGF0GBAgASgBUghzdGFydExhdBIbCglzdGFydF9sb24YESABKAFSCHN0'
    'YXJ0TG9uEhcKB2VuZF9sYXQYEiABKAFSBmVuZExhdBIXCgdlbmRfbG9uGBMgASgBUgZlbmRMb2'
    '4SHAoKZXh0X3RlbXBfYxgUIAEoBVIIZXh0VGVtcEM=');

@$core.Deprecated('Use tripDetailDescriptor instead')
const TripDetail$json = {
  '1': 'TripDetail',
  '2': [
    {
      '1': 'summary',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TripSummary',
      '10': 'summary'
    },
    {
      '1': 'anticipation_score',
      '3': 2,
      '4': 1,
      '5': 5,
      '10': 'anticipationScore'
    },
    {'1': 'smoothness_score', '3': 3, '4': 1, '5': 5, '10': 'smoothnessScore'},
    {
      '1': 'speed_discipline_score',
      '3': 4,
      '4': 1,
      '5': 5,
      '10': 'speedDisciplineScore'
    },
    {'1': 'efficiency_score', '3': 5, '4': 1, '5': 5, '10': 'efficiencyScore'},
    {
      '1': 'consistency_score',
      '3': 6,
      '4': 1,
      '5': 5,
      '10': 'consistencyScore'
    },
    {'1': 'elevation_gain_m', '3': 7, '4': 1, '5': 1, '10': 'elevationGainM'},
    {'1': 'elevation_loss_m', '3': 8, '4': 1, '5': 1, '10': 'elevationLossM'},
    {
      '1': 'avg_gradient_percent',
      '3': 9,
      '4': 1,
      '5': 1,
      '10': 'avgGradientPercent'
    },
    {
      '1': 'micro_moments_json',
      '3': 10,
      '4': 1,
      '5': 9,
      '10': 'microMomentsJson'
    },
  ],
};

/// Descriptor for `TripDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tripDetailDescriptor = $convert.base64Decode(
    'CgpUcmlwRGV0YWlsEjQKB3N1bW1hcnkYASABKAsyGi5ibGFkZXdhdGNoLnYxLlRyaXBTdW1tYX'
    'J5UgdzdW1tYXJ5Ei0KEmFudGljaXBhdGlvbl9zY29yZRgCIAEoBVIRYW50aWNpcGF0aW9uU2Nv'
    'cmUSKQoQc21vb3RobmVzc19zY29yZRgDIAEoBVIPc21vb3RobmVzc1Njb3JlEjQKFnNwZWVkX2'
    'Rpc2NpcGxpbmVfc2NvcmUYBCABKAVSFHNwZWVkRGlzY2lwbGluZVNjb3JlEikKEGVmZmljaWVu'
    'Y3lfc2NvcmUYBSABKAVSD2VmZmljaWVuY3lTY29yZRIrChFjb25zaXN0ZW5jeV9zY29yZRgGIA'
    'EoBVIQY29uc2lzdGVuY3lTY29yZRIoChBlbGV2YXRpb25fZ2Fpbl9tGAcgASgBUg5lbGV2YXRp'
    'b25HYWluTRIoChBlbGV2YXRpb25fbG9zc19tGAggASgBUg5lbGV2YXRpb25Mb3NzTRIwChRhdm'
    'dfZ3JhZGllbnRfcGVyY2VudBgJIAEoAVISYXZnR3JhZGllbnRQZXJjZW50EiwKEm1pY3JvX21v'
    'bWVudHNfanNvbhgKIAEoCVIQbWljcm9Nb21lbnRzSnNvbg==');

@$core.Deprecated('Use dnaScoresDescriptor instead')
const DnaScores$json = {
  '1': 'DnaScores',
  '2': [
    {'1': 'anticipation', '3': 1, '4': 1, '5': 5, '10': 'anticipation'},
    {'1': 'smoothness', '3': 2, '4': 1, '5': 5, '10': 'smoothness'},
    {'1': 'speed_discipline', '3': 3, '4': 1, '5': 5, '10': 'speedDiscipline'},
    {'1': 'efficiency', '3': 4, '4': 1, '5': 5, '10': 'efficiency'},
    {'1': 'consistency', '3': 5, '4': 1, '5': 5, '10': 'consistency'},
    {'1': 'overall', '3': 6, '4': 1, '5': 5, '10': 'overall'},
  ],
};

/// Descriptor for `DnaScores`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dnaScoresDescriptor = $convert.base64Decode(
    'CglEbmFTY29yZXMSIgoMYW50aWNpcGF0aW9uGAEgASgFUgxhbnRpY2lwYXRpb24SHgoKc21vb3'
    'RobmVzcxgCIAEoBVIKc21vb3RobmVzcxIpChBzcGVlZF9kaXNjaXBsaW5lGAMgASgFUg9zcGVl'
    'ZERpc2NpcGxpbmUSHgoKZWZmaWNpZW5jeRgEIAEoBVIKZWZmaWNpZW5jeRIgCgtjb25zaXN0ZW'
    '5jeRgFIAEoBVILY29uc2lzdGVuY3kSGAoHb3ZlcmFsbBgGIAEoBVIHb3ZlcmFsbA==');

@$core.Deprecated('Use weeklyRollupEntryDescriptor instead')
const WeeklyRollupEntry$json = {
  '1': 'WeeklyRollupEntry',
  '2': [
    {'1': 'rollup_json', '3': 1, '4': 1, '5': 9, '10': 'rollupJson'},
  ],
};

/// Descriptor for `WeeklyRollupEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List weeklyRollupEntryDescriptor = $convert.base64Decode(
    'ChFXZWVrbHlSb2xsdXBFbnRyeRIfCgtyb2xsdXBfanNvbhgBIAEoCVIKcm9sbHVwSnNvbg==');

@$core.Deprecated('Use telemetrySampleDescriptor instead')
const TelemetrySample$json = {
  '1': 'TelemetrySample',
  '2': [
    {'1': 'sample_json', '3': 1, '4': 1, '5': 9, '10': 'sampleJson'},
  ],
};

/// Descriptor for `TelemetrySample`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List telemetrySampleDescriptor = $convert.base64Decode(
    'Cg9UZWxlbWV0cnlTYW1wbGUSHwoLc2FtcGxlX2pzb24YASABKAlSCnNhbXBsZUpzb24=');

@$core.Deprecated('Use tripConfigDescriptor instead')
const TripConfig$json = {
  '1': 'TripConfig',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'electricity_rate', '3': 2, '4': 1, '5': 1, '10': 'electricityRate'},
    {'1': 'currency', '3': 3, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'distance_unit', '3': 4, '4': 1, '5': 9, '10': 'distanceUnit'},
  ],
};

/// Descriptor for `TripConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tripConfigDescriptor = $convert.base64Decode(
    'CgpUcmlwQ29uZmlnEhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSKQoQZWxlY3RyaWNpdHlfcm'
    'F0ZRgCIAEoAVIPZWxlY3RyaWNpdHlSYXRlEhoKCGN1cnJlbmN5GAMgASgJUghjdXJyZW5jeRIj'
    'Cg1kaXN0YW5jZV91bml0GAQgASgJUgxkaXN0YW5jZVVuaXQ=');

@$core.Deprecated('Use tripStorageInfoDescriptor instead')
const TripStorageInfo$json = {
  '1': 'TripStorageInfo',
  '2': [
    {'1': 'storage_type', '3': 1, '4': 1, '5': 9, '10': 'storageType'},
    {'1': 'limit_mb', '3': 2, '4': 1, '5': 3, '10': 'limitMb'},
    {'1': 'used_mb', '3': 3, '4': 1, '5': 1, '10': 'usedMb'},
    {'1': 'used_unit', '3': 4, '4': 1, '5': 9, '10': 'usedUnit'},
    {'1': 'sd_card_available', '3': 5, '4': 1, '5': 8, '10': 'sdCardAvailable'},
    {'1': 'trips_count', '3': 6, '4': 1, '5': 5, '10': 'tripsCount'},
    {'1': 'storage_path', '3': 7, '4': 1, '5': 9, '10': 'storagePath'},
  ],
};

/// Descriptor for `TripStorageInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List tripStorageInfoDescriptor = $convert.base64Decode(
    'Cg9UcmlwU3RvcmFnZUluZm8SIQoMc3RvcmFnZV90eXBlGAEgASgJUgtzdG9yYWdlVHlwZRIZCg'
    'hsaW1pdF9tYhgCIAEoA1IHbGltaXRNYhIXCgd1c2VkX21iGAMgASgBUgZ1c2VkTWISGwoJdXNl'
    'ZF91bml0GAQgASgJUgh1c2VkVW5pdBIqChFzZF9jYXJkX2F2YWlsYWJsZRgFIAEoCFIPc2RDYX'
    'JkQXZhaWxhYmxlEh8KC3RyaXBzX2NvdW50GAYgASgFUgp0cmlwc0NvdW50EiEKDHN0b3JhZ2Vf'
    'cGF0aBgHIAEoCVILc3RvcmFnZVBhdGg=');

@$core.Deprecated('Use similarTripsStatsDescriptor instead')
const SimilarTripsStats$json = {
  '1': 'SimilarTripsStats',
  '2': [
    {'1': 'avg_efficiency', '3': 1, '4': 1, '5': 1, '10': 'avgEfficiency'},
    {'1': 'avg_score', '3': 2, '4': 1, '5': 1, '10': 'avgScore'},
    {
      '1': 'avg_duration_seconds',
      '3': 3,
      '4': 1,
      '5': 1,
      '10': 'avgDurationSeconds'
    },
    {'1': 'avg_speed_kmh', '3': 4, '4': 1, '5': 1, '10': 'avgSpeedKmh'},
    {'1': 'avg_cost', '3': 5, '4': 1, '5': 1, '10': 'avgCost'},
    {'1': 'best_trip_id', '3': 6, '4': 1, '5': 3, '10': 'bestTripId'},
    {'1': 'best_efficiency', '3': 7, '4': 1, '5': 1, '10': 'bestEfficiency'},
    {'1': 'worst_trip_id', '3': 8, '4': 1, '5': 3, '10': 'worstTripId'},
    {'1': 'worst_efficiency', '3': 9, '4': 1, '5': 1, '10': 'worstEfficiency'},
  ],
};

/// Descriptor for `SimilarTripsStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List similarTripsStatsDescriptor = $convert.base64Decode(
    'ChFTaW1pbGFyVHJpcHNTdGF0cxIlCg5hdmdfZWZmaWNpZW5jeRgBIAEoAVINYXZnRWZmaWNpZW'
    '5jeRIbCglhdmdfc2NvcmUYAiABKAFSCGF2Z1Njb3JlEjAKFGF2Z19kdXJhdGlvbl9zZWNvbmRz'
    'GAMgASgBUhJhdmdEdXJhdGlvblNlY29uZHMSIgoNYXZnX3NwZWVkX2ttaBgEIAEoAVILYXZnU3'
    'BlZWRLbWgSGQoIYXZnX2Nvc3QYBSABKAFSB2F2Z0Nvc3QSIAoMYmVzdF90cmlwX2lkGAYgASgD'
    'UgpiZXN0VHJpcElkEicKD2Jlc3RfZWZmaWNpZW5jeRgHIAEoAVIOYmVzdEVmZmljaWVuY3kSIg'
    'oNd29yc3RfdHJpcF9pZBgIIAEoA1ILd29yc3RUcmlwSWQSKQoQd29yc3RfZWZmaWNpZW5jeRgJ'
    'IAEoAVIPd29yc3RFZmZpY2llbmN5');

@$core.Deprecated('Use gpsPointDescriptor instead')
const GpsPoint$json = {
  '1': 'GpsPoint',
  '2': [
    {'1': 'lat', '3': 1, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lon', '3': 2, '4': 1, '5': 1, '10': 'lon'},
  ],
};

/// Descriptor for `GpsPoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gpsPointDescriptor = $convert.base64Decode(
    'CghHcHNQb2ludBIQCgNsYXQYASABKAFSA2xhdBIQCgNsb24YAiABKAFSA2xvbg==');

@$core.Deprecated('Use listTripsRequestDescriptor instead')
const ListTripsRequest$json = {
  '1': 'ListTripsRequest',
  '2': [
    {'1': 'days', '3': 1, '4': 1, '5': 5, '10': 'days'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
    {'1': 'offset', '3': 3, '4': 1, '5': 5, '10': 'offset'},
  ],
};

/// Descriptor for `ListTripsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTripsRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0VHJpcHNSZXF1ZXN0EhIKBGRheXMYASABKAVSBGRheXMSFAoFbGltaXQYAiABKAVSBW'
    'xpbWl0EhYKBm9mZnNldBgDIAEoBVIGb2Zmc2V0');

@$core.Deprecated('Use listTripsResponseDescriptor instead')
const ListTripsResponse$json = {
  '1': 'ListTripsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'trips',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.TripSummary',
      '10': 'trips'
    },
  ],
};

/// Descriptor for `ListTripsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTripsResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0VHJpcHNSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEjAKBXRyaXBzGA'
    'IgAygLMhouYmxhZGV3YXRjaC52MS5UcmlwU3VtbWFyeVIFdHJpcHM=');

@$core.Deprecated('Use getTripRequestDescriptor instead')
const GetTripRequest$json = {
  '1': 'GetTripRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `GetTripRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTripRequestDescriptor =
    $convert.base64Decode('Cg5HZXRUcmlwUmVxdWVzdBIOCgJpZBgBIAEoA1ICaWQ=');

@$core.Deprecated('Use getTripResponseDescriptor instead')
const GetTripResponse$json = {
  '1': 'GetTripResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'trip',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TripDetail',
      '10': 'trip'
    },
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `GetTripResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTripResponseDescriptor = $convert.base64Decode(
    'Cg9HZXRUcmlwUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxItCgR0cmlwGAIgAS'
    'gLMhkuYmxhZGV3YXRjaC52MS5UcmlwRGV0YWlsUgR0cmlwEhQKBWVycm9yGAMgASgJUgVlcnJv'
    'cg==');

@$core.Deprecated('Use deleteTripRequestDescriptor instead')
const DeleteTripRequest$json = {
  '1': 'DeleteTripRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `DeleteTripRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteTripRequestDescriptor =
    $convert.base64Decode('ChFEZWxldGVUcmlwUmVxdWVzdBIOCgJpZBgBIAEoA1ICaWQ=');

@$core.Deprecated('Use deleteTripResponseDescriptor instead')
const DeleteTripResponse$json = {
  '1': 'DeleteTripResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `DeleteTripResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteTripResponseDescriptor = $convert.base64Decode(
    'ChJEZWxldGVUcmlwUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgVlcnJvch'
    'gCIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use getSummaryRequestDescriptor instead')
const GetSummaryRequest$json = {
  '1': 'GetSummaryRequest',
  '2': [
    {'1': 'days', '3': 1, '4': 1, '5': 5, '10': 'days'},
  ],
};

/// Descriptor for `GetSummaryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSummaryRequestDescriptor = $convert
    .base64Decode('ChFHZXRTdW1tYXJ5UmVxdWVzdBISCgRkYXlzGAEgASgFUgRkYXlz');

@$core.Deprecated('Use getSummaryResponseDescriptor instead')
const GetSummaryResponse$json = {
  '1': 'GetSummaryResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'summary',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.WeeklyRollupEntry',
      '10': 'summary'
    },
  ],
};

/// Descriptor for `GetSummaryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSummaryResponseDescriptor = $convert.base64Decode(
    'ChJHZXRTdW1tYXJ5UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxI6CgdzdW1tYX'
    'J5GAIgAygLMiAuYmxhZGV3YXRjaC52MS5XZWVrbHlSb2xsdXBFbnRyeVIHc3VtbWFyeQ==');

@$core.Deprecated('Use getDnaRequestDescriptor instead')
const GetDnaRequest$json = {
  '1': 'GetDnaRequest',
  '2': [
    {'1': 'days', '3': 1, '4': 1, '5': 5, '10': 'days'},
  ],
};

/// Descriptor for `GetDnaRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDnaRequestDescriptor =
    $convert.base64Decode('Cg1HZXREbmFSZXF1ZXN0EhIKBGRheXMYASABKAVSBGRheXM=');

@$core.Deprecated('Use getDnaResponseDescriptor instead')
const GetDnaResponse$json = {
  '1': 'GetDnaResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'dna',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.DnaScores',
      '10': 'dna'
    },
  ],
};

/// Descriptor for `GetDnaResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDnaResponseDescriptor = $convert.base64Decode(
    'Cg5HZXREbmFSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEioKA2RuYRgCIAEoCz'
    'IYLmJsYWRld2F0Y2gudjEuRG5hU2NvcmVzUgNkbmE=');

@$core.Deprecated('Use getRangeRequestDescriptor instead')
const GetRangeRequest$json = {
  '1': 'GetRangeRequest',
};

/// Descriptor for `GetRangeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRangeRequestDescriptor =
    $convert.base64Decode('Cg9HZXRSYW5nZVJlcXVlc3Q=');

@$core.Deprecated('Use getRangeResponseDescriptor instead')
const GetRangeResponse$json = {
  '1': 'GetRangeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'range_json', '3': 2, '4': 1, '5': 9, '10': 'rangeJson'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `GetRangeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRangeResponseDescriptor = $convert.base64Decode(
    'ChBHZXRSYW5nZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSHQoKcmFuZ2Vfan'
    'NvbhgCIAEoCVIJcmFuZ2VKc29uEhgKB21lc3NhZ2UYAyABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use getConfigRequestDescriptor instead')
const GetConfigRequest$json = {
  '1': 'GetConfigRequest',
};

/// Descriptor for `GetConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConfigRequestDescriptor =
    $convert.base64Decode('ChBHZXRDb25maWdSZXF1ZXN0');

@$core.Deprecated('Use getConfigResponseDescriptor instead')
const GetConfigResponse$json = {
  '1': 'GetConfigResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'config',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TripConfig',
      '10': 'config'
    },
  ],
};

/// Descriptor for `GetConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConfigResponseDescriptor = $convert.base64Decode(
    'ChFHZXRDb25maWdSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEjEKBmNvbmZpZx'
    'gCIAEoCzIZLmJsYWRld2F0Y2gudjEuVHJpcENvbmZpZ1IGY29uZmln');

@$core.Deprecated('Use setConfigRequestDescriptor instead')
const SetConfigRequest$json = {
  '1': 'SetConfigRequest',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'has_enabled', '3': 2, '4': 1, '5': 8, '10': 'hasEnabled'},
    {'1': 'electricity_rate', '3': 3, '4': 1, '5': 1, '10': 'electricityRate'},
    {
      '1': 'has_electricity_rate',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'hasElectricityRate'
    },
    {'1': 'currency', '3': 5, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'distance_unit', '3': 6, '4': 1, '5': 9, '10': 'distanceUnit'},
  ],
};

/// Descriptor for `SetConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setConfigRequestDescriptor = $convert.base64Decode(
    'ChBTZXRDb25maWdSZXF1ZXN0EhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSHwoLaGFzX2VuYW'
    'JsZWQYAiABKAhSCmhhc0VuYWJsZWQSKQoQZWxlY3RyaWNpdHlfcmF0ZRgDIAEoAVIPZWxlY3Ry'
    'aWNpdHlSYXRlEjAKFGhhc19lbGVjdHJpY2l0eV9yYXRlGAQgASgIUhJoYXNFbGVjdHJpY2l0eV'
    'JhdGUSGgoIY3VycmVuY3kYBSABKAlSCGN1cnJlbmN5EiMKDWRpc3RhbmNlX3VuaXQYBiABKAlS'
    'DGRpc3RhbmNlVW5pdA==');

@$core.Deprecated('Use setConfigResponseDescriptor instead')
const SetConfigResponse$json = {
  '1': 'SetConfigResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setConfigResponseDescriptor = $convert.base64Decode(
    'ChFTZXRDb25maWdSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhQKBWVycm9yGA'
    'IgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getStorageRequestDescriptor instead')
const GetStorageRequest$json = {
  '1': 'GetStorageRequest',
};

/// Descriptor for `GetStorageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStorageRequestDescriptor =
    $convert.base64Decode('ChFHZXRTdG9yYWdlUmVxdWVzdA==');

@$core.Deprecated('Use getStorageResponseDescriptor instead')
const GetStorageResponse$json = {
  '1': 'GetStorageResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'storage',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.TripStorageInfo',
      '10': 'storage'
    },
  ],
};

/// Descriptor for `GetStorageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStorageResponseDescriptor = $convert.base64Decode(
    'ChJHZXRTdG9yYWdlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxI4CgdzdG9yYW'
    'dlGAIgASgLMh4uYmxhZGV3YXRjaC52MS5UcmlwU3RvcmFnZUluZm9SB3N0b3JhZ2U=');

@$core.Deprecated('Use setStorageRequestDescriptor instead')
const SetStorageRequest$json = {
  '1': 'SetStorageRequest',
  '2': [
    {'1': 'storage_type', '3': 1, '4': 1, '5': 9, '10': 'storageType'},
    {'1': 'storage_limit_mb', '3': 2, '4': 1, '5': 3, '10': 'storageLimitMb'},
    {
      '1': 'has_storage_limit_mb',
      '3': 3,
      '4': 1,
      '5': 8,
      '10': 'hasStorageLimitMb'
    },
  ],
};

/// Descriptor for `SetStorageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setStorageRequestDescriptor = $convert.base64Decode(
    'ChFTZXRTdG9yYWdlUmVxdWVzdBIhCgxzdG9yYWdlX3R5cGUYASABKAlSC3N0b3JhZ2VUeXBlEi'
    'gKEHN0b3JhZ2VfbGltaXRfbWIYAiABKANSDnN0b3JhZ2VMaW1pdE1iEi8KFGhhc19zdG9yYWdl'
    'X2xpbWl0X21iGAMgASgIUhFoYXNTdG9yYWdlTGltaXRNYg==');

@$core.Deprecated('Use setStorageResponseDescriptor instead')
const SetStorageResponse$json = {
  '1': 'SetStorageResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetStorageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setStorageResponseDescriptor = $convert.base64Decode(
    'ChJTZXRTdG9yYWdlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgVlcnJvch'
    'gCIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use syncTripsRequestDescriptor instead')
const SyncTripsRequest$json = {
  '1': 'SyncTripsRequest',
};

/// Descriptor for `SyncTripsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncTripsRequestDescriptor =
    $convert.base64Decode('ChBTeW5jVHJpcHNSZXF1ZXN0');

@$core.Deprecated('Use syncTripsResponseDescriptor instead')
const SyncTripsResponse$json = {
  '1': 'SyncTripsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
    {'1': 'added', '3': 3, '4': 1, '5': 5, '10': 'added'},
    {'1': 'removed', '3': 4, '4': 1, '5': 5, '10': 'removed'},
    {'1': 'total', '3': 5, '4': 1, '5': 5, '10': 'total'},
  ],
};

/// Descriptor for `SyncTripsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncTripsResponseDescriptor = $convert.base64Decode(
    'ChFTeW5jVHJpcHNSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhQKBWVycm9yGA'
    'IgASgJUgVlcnJvchIUCgVhZGRlZBgDIAEoBVIFYWRkZWQSGAoHcmVtb3ZlZBgEIAEoBVIHcmVt'
    'b3ZlZBIUCgV0b3RhbBgFIAEoBVIFdG90YWw=');

@$core.Deprecated('Use getTelemetryRequestDescriptor instead')
const GetTelemetryRequest$json = {
  '1': 'GetTelemetryRequest',
  '2': [
    {'1': 'trip_id', '3': 1, '4': 1, '5': 3, '10': 'tripId'},
  ],
};

/// Descriptor for `GetTelemetryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTelemetryRequestDescriptor =
    $convert.base64Decode(
        'ChNHZXRUZWxlbWV0cnlSZXF1ZXN0EhcKB3RyaXBfaWQYASABKANSBnRyaXBJZA==');

@$core.Deprecated('Use getTelemetryResponseDescriptor instead')
const GetTelemetryResponse$json = {
  '1': 'GetTelemetryResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'telemetry',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.TelemetrySample',
      '10': 'telemetry'
    },
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `GetTelemetryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTelemetryResponseDescriptor = $convert.base64Decode(
    'ChRHZXRUZWxlbWV0cnlSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEjwKCXRlbG'
    'VtZXRyeRgCIAMoCzIeLmJsYWRld2F0Y2gudjEuVGVsZW1ldHJ5U2FtcGxlUgl0ZWxlbWV0cnkS'
    'FAoFZXJyb3IYAyABKAlSBWVycm9y');

@$core.Deprecated('Use getSimilarTripsRequestDescriptor instead')
const GetSimilarTripsRequest$json = {
  '1': 'GetSimilarTripsRequest',
  '2': [
    {'1': 'trip_id', '3': 1, '4': 1, '5': 3, '10': 'tripId'},
  ],
};

/// Descriptor for `GetSimilarTripsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSimilarTripsRequestDescriptor =
    $convert.base64Decode(
        'ChZHZXRTaW1pbGFyVHJpcHNSZXF1ZXN0EhcKB3RyaXBfaWQYASABKANSBnRyaXBJZA==');

@$core.Deprecated('Use getSimilarTripsResponseDescriptor instead')
const GetSimilarTripsResponse$json = {
  '1': 'GetSimilarTripsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'similar',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.TripSummary',
      '10': 'similar'
    },
    {'1': 'count', '3': 3, '4': 1, '5': 5, '10': 'count'},
    {
      '1': 'stats',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.SimilarTripsStats',
      '10': 'stats'
    },
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `GetSimilarTripsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSimilarTripsResponseDescriptor = $convert.base64Decode(
    'ChdHZXRTaW1pbGFyVHJpcHNSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEjQKB3'
    'NpbWlsYXIYAiADKAsyGi5ibGFkZXdhdGNoLnYxLlRyaXBTdW1tYXJ5UgdzaW1pbGFyEhQKBWNv'
    'dW50GAMgASgFUgVjb3VudBI2CgVzdGF0cxgEIAEoCzIgLmJsYWRld2F0Y2gudjEuU2ltaWxhcl'
    'RyaXBzU3RhdHNSBXN0YXRzEhQKBWVycm9yGAUgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getGpsTraceRequestDescriptor instead')
const GetGpsTraceRequest$json = {
  '1': 'GetGpsTraceRequest',
  '2': [
    {'1': 'trip_id', '3': 1, '4': 1, '5': 3, '10': 'tripId'},
  ],
};

/// Descriptor for `GetGpsTraceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGpsTraceRequestDescriptor =
    $convert.base64Decode(
        'ChJHZXRHcHNUcmFjZVJlcXVlc3QSFwoHdHJpcF9pZBgBIAEoA1IGdHJpcElk');

@$core.Deprecated('Use getGpsTraceResponseDescriptor instead')
const GetGpsTraceResponse$json = {
  '1': 'GetGpsTraceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'gps',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.GpsPoint',
      '10': 'gps'
    },
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `GetGpsTraceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getGpsTraceResponseDescriptor = $convert.base64Decode(
    'ChNHZXRHcHNUcmFjZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSKQoDZ3BzGA'
    'IgAygLMhcuYmxhZGV3YXRjaC52MS5HcHNQb2ludFIDZ3BzEhQKBWVycm9yGAMgASgJUgVlcnJv'
    'cg==');

const $core.Map<$core.String, $core.dynamic> TripsServiceBase$json = {
  '1': 'TripsService',
  '2': [
    {
      '1': 'ListTrips',
      '2': '.bladewatch.v1.ListTripsRequest',
      '3': '.bladewatch.v1.ListTripsResponse'
    },
    {
      '1': 'GetTrip',
      '2': '.bladewatch.v1.GetTripRequest',
      '3': '.bladewatch.v1.GetTripResponse'
    },
    {
      '1': 'DeleteTrip',
      '2': '.bladewatch.v1.DeleteTripRequest',
      '3': '.bladewatch.v1.DeleteTripResponse'
    },
    {
      '1': 'GetSummary',
      '2': '.bladewatch.v1.GetSummaryRequest',
      '3': '.bladewatch.v1.GetSummaryResponse'
    },
    {
      '1': 'GetDna',
      '2': '.bladewatch.v1.GetDnaRequest',
      '3': '.bladewatch.v1.GetDnaResponse'
    },
    {
      '1': 'GetRange',
      '2': '.bladewatch.v1.GetRangeRequest',
      '3': '.bladewatch.v1.GetRangeResponse'
    },
    {
      '1': 'GetConfig',
      '2': '.bladewatch.v1.GetConfigRequest',
      '3': '.bladewatch.v1.GetConfigResponse'
    },
    {
      '1': 'SetConfig',
      '2': '.bladewatch.v1.SetConfigRequest',
      '3': '.bladewatch.v1.SetConfigResponse'
    },
    {
      '1': 'GetStorage',
      '2': '.bladewatch.v1.GetStorageRequest',
      '3': '.bladewatch.v1.GetStorageResponse'
    },
    {
      '1': 'SetStorage',
      '2': '.bladewatch.v1.SetStorageRequest',
      '3': '.bladewatch.v1.SetStorageResponse'
    },
    {
      '1': 'SyncTrips',
      '2': '.bladewatch.v1.SyncTripsRequest',
      '3': '.bladewatch.v1.SyncTripsResponse'
    },
    {
      '1': 'GetTelemetry',
      '2': '.bladewatch.v1.GetTelemetryRequest',
      '3': '.bladewatch.v1.GetTelemetryResponse'
    },
    {
      '1': 'GetSimilarTrips',
      '2': '.bladewatch.v1.GetSimilarTripsRequest',
      '3': '.bladewatch.v1.GetSimilarTripsResponse'
    },
    {
      '1': 'GetGpsTrace',
      '2': '.bladewatch.v1.GetGpsTraceRequest',
      '3': '.bladewatch.v1.GetGpsTraceResponse'
    },
  ],
};

@$core.Deprecated('Use tripsServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    TripsServiceBase$messageJson = {
  '.bladewatch.v1.ListTripsRequest': ListTripsRequest$json,
  '.bladewatch.v1.ListTripsResponse': ListTripsResponse$json,
  '.bladewatch.v1.TripSummary': TripSummary$json,
  '.bladewatch.v1.GetTripRequest': GetTripRequest$json,
  '.bladewatch.v1.GetTripResponse': GetTripResponse$json,
  '.bladewatch.v1.TripDetail': TripDetail$json,
  '.bladewatch.v1.DeleteTripRequest': DeleteTripRequest$json,
  '.bladewatch.v1.DeleteTripResponse': DeleteTripResponse$json,
  '.bladewatch.v1.GetSummaryRequest': GetSummaryRequest$json,
  '.bladewatch.v1.GetSummaryResponse': GetSummaryResponse$json,
  '.bladewatch.v1.WeeklyRollupEntry': WeeklyRollupEntry$json,
  '.bladewatch.v1.GetDnaRequest': GetDnaRequest$json,
  '.bladewatch.v1.GetDnaResponse': GetDnaResponse$json,
  '.bladewatch.v1.DnaScores': DnaScores$json,
  '.bladewatch.v1.GetRangeRequest': GetRangeRequest$json,
  '.bladewatch.v1.GetRangeResponse': GetRangeResponse$json,
  '.bladewatch.v1.GetConfigRequest': GetConfigRequest$json,
  '.bladewatch.v1.GetConfigResponse': GetConfigResponse$json,
  '.bladewatch.v1.TripConfig': TripConfig$json,
  '.bladewatch.v1.SetConfigRequest': SetConfigRequest$json,
  '.bladewatch.v1.SetConfigResponse': SetConfigResponse$json,
  '.bladewatch.v1.GetStorageRequest': GetStorageRequest$json,
  '.bladewatch.v1.GetStorageResponse': GetStorageResponse$json,
  '.bladewatch.v1.TripStorageInfo': TripStorageInfo$json,
  '.bladewatch.v1.SetStorageRequest': SetStorageRequest$json,
  '.bladewatch.v1.SetStorageResponse': SetStorageResponse$json,
  '.bladewatch.v1.SyncTripsRequest': SyncTripsRequest$json,
  '.bladewatch.v1.SyncTripsResponse': SyncTripsResponse$json,
  '.bladewatch.v1.GetTelemetryRequest': GetTelemetryRequest$json,
  '.bladewatch.v1.GetTelemetryResponse': GetTelemetryResponse$json,
  '.bladewatch.v1.TelemetrySample': TelemetrySample$json,
  '.bladewatch.v1.GetSimilarTripsRequest': GetSimilarTripsRequest$json,
  '.bladewatch.v1.GetSimilarTripsResponse': GetSimilarTripsResponse$json,
  '.bladewatch.v1.SimilarTripsStats': SimilarTripsStats$json,
  '.bladewatch.v1.GetGpsTraceRequest': GetGpsTraceRequest$json,
  '.bladewatch.v1.GetGpsTraceResponse': GetGpsTraceResponse$json,
  '.bladewatch.v1.GpsPoint': GpsPoint$json,
};

/// Descriptor for `TripsService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List tripsServiceDescriptor = $convert.base64Decode(
    'CgxUcmlwc1NlcnZpY2USTgoJTGlzdFRyaXBzEh8uYmxhZGV3YXRjaC52MS5MaXN0VHJpcHNSZX'
    'F1ZXN0GiAuYmxhZGV3YXRjaC52MS5MaXN0VHJpcHNSZXNwb25zZRJICgdHZXRUcmlwEh0uYmxh'
    'ZGV3YXRjaC52MS5HZXRUcmlwUmVxdWVzdBoeLmJsYWRld2F0Y2gudjEuR2V0VHJpcFJlc3Bvbn'
    'NlElEKCkRlbGV0ZVRyaXASIC5ibGFkZXdhdGNoLnYxLkRlbGV0ZVRyaXBSZXF1ZXN0GiEuYmxh'
    'ZGV3YXRjaC52MS5EZWxldGVUcmlwUmVzcG9uc2USUQoKR2V0U3VtbWFyeRIgLmJsYWRld2F0Y2'
    'gudjEuR2V0U3VtbWFyeVJlcXVlc3QaIS5ibGFkZXdhdGNoLnYxLkdldFN1bW1hcnlSZXNwb25z'
    'ZRJFCgZHZXREbmESHC5ibGFkZXdhdGNoLnYxLkdldERuYVJlcXVlc3QaHS5ibGFkZXdhdGNoLn'
    'YxLkdldERuYVJlc3BvbnNlEksKCEdldFJhbmdlEh4uYmxhZGV3YXRjaC52MS5HZXRSYW5nZVJl'
    'cXVlc3QaHy5ibGFkZXdhdGNoLnYxLkdldFJhbmdlUmVzcG9uc2USTgoJR2V0Q29uZmlnEh8uYm'
    'xhZGV3YXRjaC52MS5HZXRDb25maWdSZXF1ZXN0GiAuYmxhZGV3YXRjaC52MS5HZXRDb25maWdS'
    'ZXNwb25zZRJOCglTZXRDb25maWcSHy5ibGFkZXdhdGNoLnYxLlNldENvbmZpZ1JlcXVlc3QaIC'
    '5ibGFkZXdhdGNoLnYxLlNldENvbmZpZ1Jlc3BvbnNlElEKCkdldFN0b3JhZ2USIC5ibGFkZXdh'
    'dGNoLnYxLkdldFN0b3JhZ2VSZXF1ZXN0GiEuYmxhZGV3YXRjaC52MS5HZXRTdG9yYWdlUmVzcG'
    '9uc2USUQoKU2V0U3RvcmFnZRIgLmJsYWRld2F0Y2gudjEuU2V0U3RvcmFnZVJlcXVlc3QaIS5i'
    'bGFkZXdhdGNoLnYxLlNldFN0b3JhZ2VSZXNwb25zZRJOCglTeW5jVHJpcHMSHy5ibGFkZXdhdG'
    'NoLnYxLlN5bmNUcmlwc1JlcXVlc3QaIC5ibGFkZXdhdGNoLnYxLlN5bmNUcmlwc1Jlc3BvbnNl'
    'ElcKDEdldFRlbGVtZXRyeRIiLmJsYWRld2F0Y2gudjEuR2V0VGVsZW1ldHJ5UmVxdWVzdBojLm'
    'JsYWRld2F0Y2gudjEuR2V0VGVsZW1ldHJ5UmVzcG9uc2USYAoPR2V0U2ltaWxhclRyaXBzEiUu'
    'YmxhZGV3YXRjaC52MS5HZXRTaW1pbGFyVHJpcHNSZXF1ZXN0GiYuYmxhZGV3YXRjaC52MS5HZX'
    'RTaW1pbGFyVHJpcHNSZXNwb25zZRJUCgtHZXRHcHNUcmFjZRIhLmJsYWRld2F0Y2gudjEuR2V0'
    'R3BzVHJhY2VSZXF1ZXN0GiIuYmxhZGV3YXRjaC52MS5HZXRHcHNUcmFjZVJlc3BvbnNl');
