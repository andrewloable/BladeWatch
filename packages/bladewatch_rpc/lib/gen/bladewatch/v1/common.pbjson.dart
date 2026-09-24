// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/common.proto.

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

@$core.Deprecated('Use gpsLocationDescriptor instead')
const GpsLocation$json = {
  '1': 'GpsLocation',
  '2': [
    {'1': 'lat', '3': 1, '4': 1, '5': 1, '10': 'lat'},
    {'1': 'lng', '3': 2, '4': 1, '5': 1, '10': 'lng'},
    {'1': 'altitude_m', '3': 3, '4': 1, '5': 1, '10': 'altitudeM'},
    {'1': 'speed_kmh', '3': 4, '4': 1, '5': 1, '10': 'speedKmh'},
    {'1': 'accuracy_m', '3': 5, '4': 1, '5': 1, '10': 'accuracyM'},
    {'1': 'bearing_deg', '3': 6, '4': 1, '5': 1, '10': 'bearingDeg'},
    {'1': 'timestamp_ms', '3': 7, '4': 1, '5': 3, '10': 'timestampMs'},
    {'1': 'has_location', '3': 8, '4': 1, '5': 8, '10': 'hasLocation'},
    {'1': 'google_maps_url', '3': 9, '4': 1, '5': 9, '10': 'googleMapsUrl'},
  ],
};

/// Descriptor for `GpsLocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gpsLocationDescriptor = $convert.base64Decode(
    'CgtHcHNMb2NhdGlvbhIQCgNsYXQYASABKAFSA2xhdBIQCgNsbmcYAiABKAFSA2xuZxIdCgphbH'
    'RpdHVkZV9tGAMgASgBUglhbHRpdHVkZU0SGwoJc3BlZWRfa21oGAQgASgBUghzcGVlZEttaBId'
    'CgphY2N1cmFjeV9tGAUgASgBUglhY2N1cmFjeU0SHwoLYmVhcmluZ19kZWcYBiABKAFSCmJlYX'
    'JpbmdEZWcSIQoMdGltZXN0YW1wX21zGAcgASgDUgt0aW1lc3RhbXBNcxIhCgxoYXNfbG9jYXRp'
    'b24YCCABKAhSC2hhc0xvY2F0aW9uEiYKD2dvb2dsZV9tYXBzX3VybBgJIAEoCVINZ29vZ2xlTW'
    'Fwc1VybA==');

@$core.Deprecated('Use storageInfoDescriptor instead')
const StorageInfo$json = {
  '1': 'StorageInfo',
  '2': [
    {'1': 'free_bytes', '3': 1, '4': 1, '5': 3, '10': 'freeBytes'},
    {'1': 'total_bytes', '3': 2, '4': 1, '5': 3, '10': 'totalBytes'},
    {'1': 'free_formatted', '3': 3, '4': 1, '5': 9, '10': 'freeFormatted'},
    {'1': 'total_formatted', '3': 4, '4': 1, '5': 9, '10': 'totalFormatted'},
    {'1': 'used_percent', '3': 5, '4': 1, '5': 5, '10': 'usedPercent'},
  ],
};

/// Descriptor for `StorageInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List storageInfoDescriptor = $convert.base64Decode(
    'CgtTdG9yYWdlSW5mbxIdCgpmcmVlX2J5dGVzGAEgASgDUglmcmVlQnl0ZXMSHwoLdG90YWxfYn'
    'l0ZXMYAiABKANSCnRvdGFsQnl0ZXMSJQoOZnJlZV9mb3JtYXR0ZWQYAyABKAlSDWZyZWVGb3Jt'
    'YXR0ZWQSJwoPdG90YWxfZm9ybWF0dGVkGAQgASgJUg50b3RhbEZvcm1hdHRlZBIhCgx1c2VkX3'
    'BlcmNlbnQYBSABKAVSC3VzZWRQZXJjZW50');

@$core.Deprecated('Use quietHoursDescriptor instead')
const QuietHours$json = {
  '1': 'QuietHours',
  '2': [
    {'1': 'start_min', '3': 1, '4': 1, '5': 5, '10': 'startMin'},
    {'1': 'end_min', '3': 2, '4': 1, '5': 5, '10': 'endMin'},
    {'1': 'allow_critical', '3': 3, '4': 1, '5': 8, '10': 'allowCritical'},
  ],
};

/// Descriptor for `QuietHours`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quietHoursDescriptor = $convert.base64Decode(
    'CgpRdWlldEhvdXJzEhsKCXN0YXJ0X21pbhgBIAEoBVIIc3RhcnRNaW4SFwoHZW5kX21pbhgCIA'
    'EoBVIGZW5kTWluEiUKDmFsbG93X2NyaXRpY2FsGAMgASgIUg1hbGxvd0NyaXRpY2Fs');
