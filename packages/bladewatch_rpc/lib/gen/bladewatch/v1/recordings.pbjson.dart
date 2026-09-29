// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/recordings.proto.

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

@$core.Deprecated('Use recordingTypeDescriptor instead')
const RecordingType$json = {
  '1': 'RecordingType',
  '2': [
    {'1': 'RECORDING_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'RECORDING_TYPE_NORMAL', '2': 1},
    {'1': 'RECORDING_TYPE_SENTRY', '2': 2},
    {'1': 'RECORDING_TYPE_PROXIMITY', '2': 3},
  ],
};

/// Descriptor for `RecordingType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List recordingTypeDescriptor = $convert.base64Decode(
    'Cg1SZWNvcmRpbmdUeXBlEh4KGlJFQ09SRElOR19UWVBFX1VOU1BFQ0lGSUVEEAASGQoVUkVDT1'
    'JESU5HX1RZUEVfTk9STUFMEAESGQoVUkVDT1JESU5HX1RZUEVfU0VOVFJZEAISHAoYUkVDT1JE'
    'SU5HX1RZUEVfUFJPWElNSVRZEAM=');

@$core.Deprecated('Use classFilterDescriptor instead')
const ClassFilter$json = {
  '1': 'ClassFilter',
  '2': [
    {'1': 'CLASS_FILTER_UNSPECIFIED', '2': 0},
    {'1': 'CLASS_FILTER_PERSON', '2': 1},
    {'1': 'CLASS_FILTER_VEHICLE', '2': 2},
    {'1': 'CLASS_FILTER_BIKE', '2': 3},
  ],
};

/// Descriptor for `ClassFilter`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List classFilterDescriptor = $convert.base64Decode(
    'CgtDbGFzc0ZpbHRlchIcChhDTEFTU19GSUxURVJfVU5TUEVDSUZJRUQQABIXChNDTEFTU19GSU'
    'xURVJfUEVSU09OEAESGAoUQ0xBU1NfRklMVEVSX1ZFSElDTEUQAhIVChFDTEFTU19GSUxURVJf'
    'QklLRRAD');

@$core.Deprecated('Use severityFilterDescriptor instead')
const SeverityFilter$json = {
  '1': 'SeverityFilter',
  '2': [
    {'1': 'SEVERITY_FILTER_UNSPECIFIED', '2': 0},
    {'1': 'SEVERITY_FILTER_INFO', '2': 1},
    {'1': 'SEVERITY_FILTER_ALERT', '2': 2},
    {'1': 'SEVERITY_FILTER_CRITICAL', '2': 3},
  ],
};

/// Descriptor for `SeverityFilter`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List severityFilterDescriptor = $convert.base64Decode(
    'Cg5TZXZlcml0eUZpbHRlchIfChtTRVZFUklUWV9GSUxURVJfVU5TUEVDSUZJRUQQABIYChRTRV'
    'ZFUklUWV9GSUxURVJfSU5GTxABEhkKFVNFVkVSSVRZX0ZJTFRFUl9BTEVSVBACEhwKGFNFVkVS'
    'SVRZX0ZJTFRFUl9DUklUSUNBTBAD');

@$core.Deprecated('Use proximityFilterDescriptor instead')
const ProximityFilter$json = {
  '1': 'ProximityFilter',
  '2': [
    {'1': 'PROXIMITY_FILTER_UNSPECIFIED', '2': 0},
    {'1': 'PROXIMITY_FILTER_VERY_CLOSE', '2': 1},
    {'1': 'PROXIMITY_FILTER_CLOSE', '2': 2},
    {'1': 'PROXIMITY_FILTER_MEDIUM', '2': 3},
  ],
};

/// Descriptor for `ProximityFilter`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List proximityFilterDescriptor = $convert.base64Decode(
    'Cg9Qcm94aW1pdHlGaWx0ZXISIAocUFJPWElNSVRZX0ZJTFRFUl9VTlNQRUNJRklFRBAAEh8KG1'
    'BST1hJTUlUWV9GSUxURVJfVkVSWV9DTE9TRRABEhoKFlBST1hJTUlUWV9GSUxURVJfQ0xPU0UQ'
    'AhIbChdQUk9YSU1JVFlfRklMVEVSX01FRElVTRAD');

@$core.Deprecated('Use recordingEntryDescriptor instead')
const RecordingEntry$json = {
  '1': 'RecordingEntry',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.bladewatch.v1.RecordingType',
      '10': 'type'
    },
    {'1': 'timestamp_ms', '3': 4, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'size_bytes', '3': 5, '4': 1, '5': 3, '10': 'size'},
    {'1': 'duration_seconds', '3': 6, '4': 1, '5': 3, '10': 'durationSeconds'},
    {'1': 'date_label', '3': 7, '4': 1, '5': 9, '10': 'dateFormatted'},
    {'1': 'time_label', '3': 8, '4': 1, '5': 9, '10': 'timeFormatted'},
    {'1': 'has_events', '3': 9, '4': 1, '5': 8, '10': 'hasEvents'},
    {'1': 'detected_classes', '3': 10, '4': 3, '5': 9, '10': 'detectedClasses'},
    {'1': 'severity', '3': 11, '4': 1, '5': 9, '10': 'peakSeverity'},
    {'1': 'proximity', '3': 12, '4': 1, '5': 9, '10': 'peakProximity'},
    {'1': 'marked', '3': 13, '4': 1, '5': 8, '10': 'marked'},
    {'1': 'marked_at_ms', '3': 14, '4': 1, '5': 3, '10': 'markedAtMs'},
  ],
};

/// Descriptor for `RecordingEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingEntryDescriptor = $convert.base64Decode(
    'Cg5SZWNvcmRpbmdFbnRyeRIaCghmaWxlbmFtZRgBIAEoCVIIZmlsZW5hbWUSEgoEcGF0aBgCIA'
    'EoCVIEcGF0aBIwCgR0eXBlGAMgASgOMhwuYmxhZGV3YXRjaC52MS5SZWNvcmRpbmdUeXBlUgR0'
    'eXBlEh8KDHRpbWVzdGFtcF9tcxgEIAEoA1IJdGltZXN0YW1wEhgKCnNpemVfYnl0ZXMYBSABKA'
    'NSBHNpemUSKQoQZHVyYXRpb25fc2Vjb25kcxgGIAEoA1IPZHVyYXRpb25TZWNvbmRzEiEKCmRh'
    'dGVfbGFiZWwYByABKAlSDWRhdGVGb3JtYXR0ZWQSIQoKdGltZV9sYWJlbBgIIAEoCVINdGltZU'
    'Zvcm1hdHRlZBIdCgpoYXNfZXZlbnRzGAkgASgIUgloYXNFdmVudHMSKQoQZGV0ZWN0ZWRfY2xh'
    'c3NlcxgKIAMoCVIPZGV0ZWN0ZWRDbGFzc2VzEh4KCHNldmVyaXR5GAsgASgJUgxwZWFrU2V2ZX'
    'JpdHkSIAoJcHJveGltaXR5GAwgASgJUg1wZWFrUHJveGltaXR5EhYKBm1hcmtlZBgNIAEoCFIG'
    'bWFya2VkEiAKDG1hcmtlZF9hdF9tcxgOIAEoA1IKbWFya2VkQXRNcw==');

@$core.Deprecated('Use listRecordingsRequestDescriptor instead')
const ListRecordingsRequest$json = {
  '1': 'ListRecordingsRequest',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'date', '3': 2, '4': 1, '5': 9, '10': 'date'},
    {'1': 'page', '3': 3, '4': 1, '5': 5, '10': 'page'},
    {'1': 'page_size', '3': 4, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'class_filter', '3': 5, '4': 1, '5': 9, '10': 'classFilter'},
    {'1': 'severity_filter', '3': 6, '4': 1, '5': 9, '10': 'severityFilter'},
    {'1': 'proximity_filter', '3': 7, '4': 1, '5': 9, '10': 'proximityFilter'},
  ],
};

/// Descriptor for `ListRecordingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRecordingsRequestDescriptor = $convert.base64Decode(
    'ChVMaXN0UmVjb3JkaW5nc1JlcXVlc3QSEgoEdHlwZRgBIAEoCVIEdHlwZRISCgRkYXRlGAIgAS'
    'gJUgRkYXRlEhIKBHBhZ2UYAyABKAVSBHBhZ2USGwoJcGFnZV9zaXplGAQgASgFUghwYWdlU2l6'
    'ZRIhCgxjbGFzc19maWx0ZXIYBSABKAlSC2NsYXNzRmlsdGVyEicKD3NldmVyaXR5X2ZpbHRlch'
    'gGIAEoCVIOc2V2ZXJpdHlGaWx0ZXISKQoQcHJveGltaXR5X2ZpbHRlchgHIAEoCVIPcHJveGlt'
    'aXR5RmlsdGVy');

@$core.Deprecated('Use listRecordingsResponseDescriptor instead')
const ListRecordingsResponse$json = {
  '1': 'ListRecordingsResponse',
  '2': [
    {
      '1': 'recordings',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.RecordingEntry',
      '10': 'recordings'
    },
    {'1': 'total', '3': 2, '4': 1, '5': 5, '10': 'total'},
    {'1': 'page', '3': 3, '4': 1, '5': 5, '10': 'page'},
    {'1': 'page_size', '3': 4, '4': 1, '5': 5, '10': 'pageSize'},
  ],
};

/// Descriptor for `ListRecordingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRecordingsResponseDescriptor = $convert.base64Decode(
    'ChZMaXN0UmVjb3JkaW5nc1Jlc3BvbnNlEj0KCnJlY29yZGluZ3MYASADKAsyHS5ibGFkZXdhdG'
    'NoLnYxLlJlY29yZGluZ0VudHJ5UgpyZWNvcmRpbmdzEhQKBXRvdGFsGAIgASgFUgV0b3RhbBIS'
    'CgRwYWdlGAMgASgFUgRwYWdlEhsKCXBhZ2Vfc2l6ZRgEIAEoBVIIcGFnZVNpemU=');

@$core.Deprecated('Use getDatesRequestDescriptor instead')
const GetDatesRequest$json = {
  '1': 'GetDatesRequest',
};

/// Descriptor for `GetDatesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDatesRequestDescriptor =
    $convert.base64Decode('Cg9HZXREYXRlc1JlcXVlc3Q=');

@$core.Deprecated('Use getDatesResponseDescriptor instead')
const GetDatesResponse$json = {
  '1': 'GetDatesResponse',
  '2': [
    {'1': 'dates', '3': 1, '4': 3, '5': 9, '10': 'dates'},
  ],
};

/// Descriptor for `GetDatesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDatesResponseDescriptor = $convert
    .base64Decode('ChBHZXREYXRlc1Jlc3BvbnNlEhQKBWRhdGVzGAEgAygJUgVkYXRlcw==');

@$core.Deprecated('Use recordingStatsDescriptor instead')
const RecordingStats$json = {
  '1': 'RecordingStats',
  '2': [
    {
      '1': 'recordings_size_bytes',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'recordingsSizeBytes'
    },
    {
      '1': 'surveillance_size_bytes',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'surveillanceSizeBytes'
    },
    {
      '1': 'proximity_size_bytes',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'proximitySizeBytes'
    },
    {'1': 'recordings_count', '3': 4, '4': 1, '5': 5, '10': 'recordingsCount'},
    {
      '1': 'surveillance_count',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'surveillanceCount'
    },
    {'1': 'proximity_count', '3': 6, '4': 1, '5': 5, '10': 'proximityCount'},
    {'1': 'total_size_bytes', '3': 7, '4': 1, '5': 3, '10': 'totalSizeBytes'},
    {'1': 'total_count', '3': 8, '4': 1, '5': 5, '10': 'totalCount'},
  ],
};

/// Descriptor for `RecordingStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordingStatsDescriptor = $convert.base64Decode(
    'Cg5SZWNvcmRpbmdTdGF0cxIyChVyZWNvcmRpbmdzX3NpemVfYnl0ZXMYASABKANSE3JlY29yZG'
    'luZ3NTaXplQnl0ZXMSNgoXc3VydmVpbGxhbmNlX3NpemVfYnl0ZXMYAiABKANSFXN1cnZlaWxs'
    'YW5jZVNpemVCeXRlcxIwChRwcm94aW1pdHlfc2l6ZV9ieXRlcxgDIAEoA1IScHJveGltaXR5U2'
    'l6ZUJ5dGVzEikKEHJlY29yZGluZ3NfY291bnQYBCABKAVSD3JlY29yZGluZ3NDb3VudBItChJz'
    'dXJ2ZWlsbGFuY2VfY291bnQYBSABKAVSEXN1cnZlaWxsYW5jZUNvdW50EicKD3Byb3hpbWl0eV'
    '9jb3VudBgGIAEoBVIOcHJveGltaXR5Q291bnQSKAoQdG90YWxfc2l6ZV9ieXRlcxgHIAEoA1IO'
    'dG90YWxTaXplQnl0ZXMSHwoLdG90YWxfY291bnQYCCABKAVSCnRvdGFsQ291bnQ=');

@$core.Deprecated('Use getStatsRequestDescriptor instead')
const GetStatsRequest$json = {
  '1': 'GetStatsRequest',
};

/// Descriptor for `GetStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsRequestDescriptor =
    $convert.base64Decode('Cg9HZXRTdGF0c1JlcXVlc3Q=');

@$core.Deprecated('Use getStatsResponseDescriptor instead')
const GetStatsResponse$json = {
  '1': 'GetStatsResponse',
  '2': [
    {
      '1': 'stats',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.RecordingStats',
      '10': 'stats'
    },
  ],
};

/// Descriptor for `GetStatsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsResponseDescriptor = $convert.base64Decode(
    'ChBHZXRTdGF0c1Jlc3BvbnNlEjMKBXN0YXRzGAEgASgLMh0uYmxhZGV3YXRjaC52MS5SZWNvcm'
    'RpbmdTdGF0c1IFc3RhdHM=');

@$core.Deprecated('Use deleteRecordingRequestDescriptor instead')
const DeleteRecordingRequest$json = {
  '1': 'DeleteRecordingRequest',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
  ],
};

/// Descriptor for `DeleteRecordingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteRecordingRequestDescriptor =
    $convert.base64Decode(
        'ChZEZWxldGVSZWNvcmRpbmdSZXF1ZXN0EhoKCGZpbGVuYW1lGAEgASgJUghmaWxlbmFtZQ==');

@$core.Deprecated('Use deleteRecordingResponseDescriptor instead')
const DeleteRecordingResponse$json = {
  '1': 'DeleteRecordingResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `DeleteRecordingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteRecordingResponseDescriptor =
    $convert.base64Decode(
        'ChdEZWxldGVSZWNvcmRpbmdSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhQKBW'
        'Vycm9yGAIgASgJUgVlcnJvcg==');

@$core.Deprecated('Use batchDeleteRequestDescriptor instead')
const BatchDeleteRequest$json = {
  '1': 'BatchDeleteRequest',
  '2': [
    {'1': 'filenames', '3': 1, '4': 3, '5': 9, '10': 'filenames'},
  ],
};

/// Descriptor for `BatchDeleteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchDeleteRequestDescriptor =
    $convert.base64Decode(
        'ChJCYXRjaERlbGV0ZVJlcXVlc3QSHAoJZmlsZW5hbWVzGAEgAygJUglmaWxlbmFtZXM=');

@$core.Deprecated('Use batchDeleteResponseDescriptor instead')
const BatchDeleteResponse$json = {
  '1': 'BatchDeleteResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'deleted', '3': 2, '4': 1, '5': 5, '10': 'deleted'},
    {'1': 'failed', '3': 3, '4': 1, '5': 5, '10': 'failed'},
    {'1': 'errors', '3': 4, '4': 3, '5': 9, '10': 'errors'},
  ],
};

/// Descriptor for `BatchDeleteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchDeleteResponseDescriptor = $convert.base64Decode(
    'ChNCYXRjaERlbGV0ZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGAoHZGVsZX'
    'RlZBgCIAEoBVIHZGVsZXRlZBIWCgZmYWlsZWQYAyABKAVSBmZhaWxlZBIWCgZlcnJvcnMYBCAD'
    'KAlSBmVycm9ycw==');

@$core.Deprecated('Use syncCatalogRequestDescriptor instead')
const SyncCatalogRequest$json = {
  '1': 'SyncCatalogRequest',
};

/// Descriptor for `SyncCatalogRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncCatalogRequestDescriptor =
    $convert.base64Decode('ChJTeW5jQ2F0YWxvZ1JlcXVlc3Q=');

@$core.Deprecated('Use syncCatalogResponseDescriptor instead')
const SyncCatalogResponse$json = {
  '1': 'SyncCatalogResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'added', '3': 2, '4': 1, '5': 5, '10': 'added'},
    {'1': 'removed', '3': 3, '4': 1, '5': 5, '10': 'removed'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SyncCatalogResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List syncCatalogResponseDescriptor = $convert.base64Decode(
    'ChNTeW5jQ2F0YWxvZ1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSFAoFYWRkZW'
    'QYAiABKAVSBWFkZGVkEhgKB3JlbW92ZWQYAyABKAVSB3JlbW92ZWQSFAoFZXJyb3IYBCABKAlS'
    'BWVycm9y');

@$core.Deprecated('Use getInflightStatusRequestDescriptor instead')
const GetInflightStatusRequest$json = {
  '1': 'GetInflightStatusRequest',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
  ],
};

/// Descriptor for `GetInflightStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInflightStatusRequestDescriptor =
    $convert.base64Decode(
        'ChhHZXRJbmZsaWdodFN0YXR1c1JlcXVlc3QSGgoIZmlsZW5hbWUYASABKAlSCGZpbGVuYW1l');

@$core.Deprecated('Use getInflightStatusResponseDescriptor instead')
const GetInflightStatusResponse$json = {
  '1': 'GetInflightStatusResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `GetInflightStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInflightStatusResponseDescriptor =
    $convert.base64Decode(
        'ChlHZXRJbmZsaWdodFN0YXR1c1Jlc3BvbnNlEhYKBnN0YXR1cxgBIAEoCVIGc3RhdHVz');

@$core.Deprecated('Use getEventTimelineRequestDescriptor instead')
const GetEventTimelineRequest$json = {
  '1': 'GetEventTimelineRequest',
  '2': [
    {'1': 'filename', '3': 1, '4': 1, '5': 9, '10': 'filename'},
  ],
};

/// Descriptor for `GetEventTimelineRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventTimelineRequestDescriptor =
    $convert.base64Decode(
        'ChdHZXRFdmVudFRpbWVsaW5lUmVxdWVzdBIaCghmaWxlbmFtZRgBIAEoCVIIZmlsZW5hbWU=');

@$core.Deprecated('Use markRecordingRequestDescriptor instead')
const MarkRecordingRequest$json = {
  '1': 'MarkRecordingRequest',
};

/// Descriptor for `MarkRecordingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markRecordingRequestDescriptor =
    $convert.base64Decode('ChRNYXJrUmVjb3JkaW5nUmVxdWVzdA==');

@$core.Deprecated('Use markRecordingResponseDescriptor instead')
const MarkRecordingResponse$json = {
  '1': 'MarkRecordingResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'filename', '3': 3, '4': 1, '5': 9, '10': 'filename'},
    {'1': 'mark_timestamp_ms', '3': 4, '4': 1, '5': 3, '10': 'markTimestampMs'},
  ],
};

/// Descriptor for `MarkRecordingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markRecordingResponseDescriptor = $convert.base64Decode(
    'ChVNYXJrUmVjb3JkaW5nUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIWCgZyZW'
    'Fzb24YAiABKAlSBnJlYXNvbhIaCghmaWxlbmFtZRgDIAEoCVIIZmlsZW5hbWUSKgoRbWFya190'
    'aW1lc3RhbXBfbXMYBCABKANSD21hcmtUaW1lc3RhbXBNcw==');

@$core.Deprecated('Use getEventTimelineResponseDescriptor instead')
const GetEventTimelineResponse$json = {
  '1': 'GetEventTimelineResponse',
  '2': [
    {'1': 'timeline_json', '3': 2, '4': 1, '5': 9, '10': 'timelineJson'},
  ],
  '9': [
    {'1': 1, '2': 2},
  ],
};

/// Descriptor for `GetEventTimelineResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEventTimelineResponseDescriptor =
    $convert.base64Decode(
        'ChhHZXRFdmVudFRpbWVsaW5lUmVzcG9uc2USIwoNdGltZWxpbmVfanNvbhgCIAEoCVIMdGltZW'
        'xpbmVKc29uSgQIARAC');

const $core.Map<$core.String, $core.dynamic> RecordingsServiceBase$json = {
  '1': 'RecordingsService',
  '2': [
    {
      '1': 'ListRecordings',
      '2': '.bladewatch.v1.ListRecordingsRequest',
      '3': '.bladewatch.v1.ListRecordingsResponse'
    },
    {
      '1': 'GetDates',
      '2': '.bladewatch.v1.GetDatesRequest',
      '3': '.bladewatch.v1.GetDatesResponse'
    },
    {
      '1': 'GetStats',
      '2': '.bladewatch.v1.GetStatsRequest',
      '3': '.bladewatch.v1.GetStatsResponse'
    },
    {
      '1': 'DeleteRecording',
      '2': '.bladewatch.v1.DeleteRecordingRequest',
      '3': '.bladewatch.v1.DeleteRecordingResponse'
    },
    {
      '1': 'BatchDelete',
      '2': '.bladewatch.v1.BatchDeleteRequest',
      '3': '.bladewatch.v1.BatchDeleteResponse'
    },
    {
      '1': 'SyncCatalog',
      '2': '.bladewatch.v1.SyncCatalogRequest',
      '3': '.bladewatch.v1.SyncCatalogResponse'
    },
    {
      '1': 'GetInflightStatus',
      '2': '.bladewatch.v1.GetInflightStatusRequest',
      '3': '.bladewatch.v1.GetInflightStatusResponse'
    },
    {
      '1': 'GetEventTimeline',
      '2': '.bladewatch.v1.GetEventTimelineRequest',
      '3': '.bladewatch.v1.GetEventTimelineResponse'
    },
    {
      '1': 'MarkRecording',
      '2': '.bladewatch.v1.MarkRecordingRequest',
      '3': '.bladewatch.v1.MarkRecordingResponse'
    },
  ],
};

@$core.Deprecated('Use recordingsServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    RecordingsServiceBase$messageJson = {
  '.bladewatch.v1.ListRecordingsRequest': ListRecordingsRequest$json,
  '.bladewatch.v1.ListRecordingsResponse': ListRecordingsResponse$json,
  '.bladewatch.v1.RecordingEntry': RecordingEntry$json,
  '.bladewatch.v1.GetDatesRequest': GetDatesRequest$json,
  '.bladewatch.v1.GetDatesResponse': GetDatesResponse$json,
  '.bladewatch.v1.GetStatsRequest': GetStatsRequest$json,
  '.bladewatch.v1.GetStatsResponse': GetStatsResponse$json,
  '.bladewatch.v1.RecordingStats': RecordingStats$json,
  '.bladewatch.v1.DeleteRecordingRequest': DeleteRecordingRequest$json,
  '.bladewatch.v1.DeleteRecordingResponse': DeleteRecordingResponse$json,
  '.bladewatch.v1.BatchDeleteRequest': BatchDeleteRequest$json,
  '.bladewatch.v1.BatchDeleteResponse': BatchDeleteResponse$json,
  '.bladewatch.v1.SyncCatalogRequest': SyncCatalogRequest$json,
  '.bladewatch.v1.SyncCatalogResponse': SyncCatalogResponse$json,
  '.bladewatch.v1.GetInflightStatusRequest': GetInflightStatusRequest$json,
  '.bladewatch.v1.GetInflightStatusResponse': GetInflightStatusResponse$json,
  '.bladewatch.v1.GetEventTimelineRequest': GetEventTimelineRequest$json,
  '.bladewatch.v1.GetEventTimelineResponse': GetEventTimelineResponse$json,
  '.bladewatch.v1.MarkRecordingRequest': MarkRecordingRequest$json,
  '.bladewatch.v1.MarkRecordingResponse': MarkRecordingResponse$json,
};

/// Descriptor for `RecordingsService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List recordingsServiceDescriptor = $convert.base64Decode(
    'ChFSZWNvcmRpbmdzU2VydmljZRJdCg5MaXN0UmVjb3JkaW5ncxIkLmJsYWRld2F0Y2gudjEuTG'
    'lzdFJlY29yZGluZ3NSZXF1ZXN0GiUuYmxhZGV3YXRjaC52MS5MaXN0UmVjb3JkaW5nc1Jlc3Bv'
    'bnNlEksKCEdldERhdGVzEh4uYmxhZGV3YXRjaC52MS5HZXREYXRlc1JlcXVlc3QaHy5ibGFkZX'
    'dhdGNoLnYxLkdldERhdGVzUmVzcG9uc2USSwoIR2V0U3RhdHMSHi5ibGFkZXdhdGNoLnYxLkdl'
    'dFN0YXRzUmVxdWVzdBofLmJsYWRld2F0Y2gudjEuR2V0U3RhdHNSZXNwb25zZRJgCg9EZWxldG'
    'VSZWNvcmRpbmcSJS5ibGFkZXdhdGNoLnYxLkRlbGV0ZVJlY29yZGluZ1JlcXVlc3QaJi5ibGFk'
    'ZXdhdGNoLnYxLkRlbGV0ZVJlY29yZGluZ1Jlc3BvbnNlElQKC0JhdGNoRGVsZXRlEiEuYmxhZG'
    'V3YXRjaC52MS5CYXRjaERlbGV0ZVJlcXVlc3QaIi5ibGFkZXdhdGNoLnYxLkJhdGNoRGVsZXRl'
    'UmVzcG9uc2USVAoLU3luY0NhdGFsb2cSIS5ibGFkZXdhdGNoLnYxLlN5bmNDYXRhbG9nUmVxdW'
    'VzdBoiLmJsYWRld2F0Y2gudjEuU3luY0NhdGFsb2dSZXNwb25zZRJmChFHZXRJbmZsaWdodFN0'
    'YXR1cxInLmJsYWRld2F0Y2gudjEuR2V0SW5mbGlnaHRTdGF0dXNSZXF1ZXN0GiguYmxhZGV3YX'
    'RjaC52MS5HZXRJbmZsaWdodFN0YXR1c1Jlc3BvbnNlEmMKEEdldEV2ZW50VGltZWxpbmUSJi5i'
    'bGFkZXdhdGNoLnYxLkdldEV2ZW50VGltZWxpbmVSZXF1ZXN0GicuYmxhZGV3YXRjaC52MS5HZX'
    'RFdmVudFRpbWVsaW5lUmVzcG9uc2USWgoNTWFya1JlY29yZGluZxIjLmJsYWRld2F0Y2gudjEu'
    'TWFya1JlY29yZGluZ1JlcXVlc3QaJC5ibGFkZXdhdGNoLnYxLk1hcmtSZWNvcmRpbmdSZXNwb2'
    '5zZQ==');
