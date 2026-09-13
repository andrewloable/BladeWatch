// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/storage.proto.

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

@$core.Deprecated('Use storageTypeDescriptor instead')
const StorageType$json = {
  '1': 'StorageType',
  '2': [
    {'1': 'STORAGE_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'STORAGE_TYPE_INTERNAL', '2': 1},
    {'1': 'STORAGE_TYPE_SD_CARD', '2': 2},
  ],
};

/// Descriptor for `StorageType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List storageTypeDescriptor = $convert.base64Decode(
    'CgtTdG9yYWdlVHlwZRIcChhTVE9SQUdFX1RZUEVfVU5TUEVDSUZJRUQQABIZChVTVE9SQUdFX1'
    'RZUEVfSU5URVJOQUwQARIYChRTVE9SQUdFX1RZUEVfU0RfQ0FSRBAC');

@$core.Deprecated('Use volumeInfoDescriptor instead')
const VolumeInfo$json = {
  '1': 'VolumeInfo',
  '2': [
    {'1': 'volume_id', '3': 1, '4': 1, '5': 9, '10': 'volumeId'},
    {'1': 'uuid', '3': 2, '4': 1, '5': 9, '10': 'uuid'},
    {'1': 'mounted', '3': 3, '4': 1, '5': 8, '10': 'mounted'},
    {'1': 'mount_path', '3': 4, '4': 1, '5': 9, '10': 'mountPath'},
  ],
};

/// Descriptor for `VolumeInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List volumeInfoDescriptor = $convert.base64Decode(
    'CgpWb2x1bWVJbmZvEhsKCXZvbHVtZV9pZBgBIAEoCVIIdm9sdW1lSWQSEgoEdXVpZBgCIAEoCV'
    'IEdXVpZBIYCgdtb3VudGVkGAMgASgIUgdtb3VudGVkEh0KCm1vdW50X3BhdGgYBCABKAlSCW1v'
    'dW50UGF0aA==');

@$core.Deprecated('Use getStorageSettingsRequestDescriptor instead')
const GetStorageSettingsRequest$json = {
  '1': 'GetStorageSettingsRequest',
};

/// Descriptor for `GetStorageSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStorageSettingsRequestDescriptor =
    $convert.base64Decode('ChlHZXRTdG9yYWdlU2V0dGluZ3NSZXF1ZXN0');

@$core.Deprecated('Use getStorageSettingsResponseDescriptor instead')
const GetStorageSettingsResponse$json = {
  '1': 'GetStorageSettingsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'recordings_limit_mb',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'recordingsLimitMb'
    },
    {
      '1': 'surveillance_limit_mb',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'surveillanceLimitMb'
    },
    {'1': 'min_limit_mb', '3': 4, '4': 1, '5': 3, '10': 'minLimitMb'},
    {'1': 'max_limit_mb', '3': 5, '4': 1, '5': 3, '10': 'maxLimitMb'},
    {
      '1': 'max_limit_mb_sd_card',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'maxLimitMbSdCard'
    },
    {'1': 'recordings_path', '3': 7, '4': 1, '5': 9, '10': 'recordingsPath'},
    {
      '1': 'surveillance_path',
      '3': 8,
      '4': 1,
      '5': 9,
      '10': 'surveillancePath'
    },
    {
      '1': 'recordings_size_bytes',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'recordingsSize'
    },
    {
      '1': 'surveillance_size_bytes',
      '3': 10,
      '4': 1,
      '5': 3,
      '10': 'surveillanceSize'
    },
    {'1': 'recordings_count', '3': 11, '4': 1, '5': 5, '10': 'recordingsCount'},
    {
      '1': 'surveillance_count',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'surveillanceCount'
    },
    {
      '1': 'recordings_storage_type',
      '3': 13,
      '4': 1,
      '5': 9,
      '10': 'recordingsStorageType'
    },
    {
      '1': 'surveillance_storage_type',
      '3': 14,
      '4': 1,
      '5': 9,
      '10': 'surveillanceStorageType'
    },
    {
      '1': 'sd_card_available',
      '3': 15,
      '4': 1,
      '5': 8,
      '10': 'sdCardAvailable'
    },
    {'1': 'sd_card_path', '3': 16, '4': 1, '5': 9, '10': 'sdCardPath'},
    {
      '1': 'sd_card_free_bytes',
      '3': 17,
      '4': 1,
      '5': 3,
      '10': 'sdCardFreeSpace'
    },
    {
      '1': 'sd_card_total_bytes',
      '3': 18,
      '4': 1,
      '5': 3,
      '10': 'sdCardTotalSpace'
    },
    {
      '1': 'sd_card_free_formatted',
      '3': 19,
      '4': 1,
      '5': 9,
      '10': 'sdCardFreeFormatted'
    },
    {
      '1': 'sd_card_total_formatted',
      '3': 20,
      '4': 1,
      '5': 9,
      '10': 'sdCardTotalFormatted'
    },
    {
      '1': 'internal_free_bytes',
      '3': 21,
      '4': 1,
      '5': 3,
      '10': 'internalFreeSpace'
    },
    {
      '1': 'internal_total_bytes',
      '3': 22,
      '4': 1,
      '5': 3,
      '10': 'internalTotalSpace'
    },
    {
      '1': 'internal_free_formatted',
      '3': 23,
      '4': 1,
      '5': 9,
      '10': 'internalFreeFormatted'
    },
    {
      '1': 'internal_total_formatted',
      '3': 24,
      '4': 1,
      '5': 9,
      '10': 'internalTotalFormatted'
    },
  ],
};

/// Descriptor for `GetStorageSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStorageSettingsResponseDescriptor = $convert.base64Decode(
    'ChpHZXRTdG9yYWdlU2V0dGluZ3NSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEi'
    '4KE3JlY29yZGluZ3NfbGltaXRfbWIYAiABKANSEXJlY29yZGluZ3NMaW1pdE1iEjIKFXN1cnZl'
    'aWxsYW5jZV9saW1pdF9tYhgDIAEoA1ITc3VydmVpbGxhbmNlTGltaXRNYhIgCgxtaW5fbGltaX'
    'RfbWIYBCABKANSCm1pbkxpbWl0TWISIAoMbWF4X2xpbWl0X21iGAUgASgDUgptYXhMaW1pdE1i'
    'Ei4KFG1heF9saW1pdF9tYl9zZF9jYXJkGAYgASgDUhBtYXhMaW1pdE1iU2RDYXJkEicKD3JlY2'
    '9yZGluZ3NfcGF0aBgHIAEoCVIOcmVjb3JkaW5nc1BhdGgSKwoRc3VydmVpbGxhbmNlX3BhdGgY'
    'CCABKAlSEHN1cnZlaWxsYW5jZVBhdGgSLQoVcmVjb3JkaW5nc19zaXplX2J5dGVzGAkgASgDUg'
    '5yZWNvcmRpbmdzU2l6ZRIxChdzdXJ2ZWlsbGFuY2Vfc2l6ZV9ieXRlcxgKIAEoA1IQc3VydmVp'
    'bGxhbmNlU2l6ZRIpChByZWNvcmRpbmdzX2NvdW50GAsgASgFUg9yZWNvcmRpbmdzQ291bnQSLQ'
    'oSc3VydmVpbGxhbmNlX2NvdW50GAwgASgFUhFzdXJ2ZWlsbGFuY2VDb3VudBI2ChdyZWNvcmRp'
    'bmdzX3N0b3JhZ2VfdHlwZRgNIAEoCVIVcmVjb3JkaW5nc1N0b3JhZ2VUeXBlEjoKGXN1cnZlaW'
    'xsYW5jZV9zdG9yYWdlX3R5cGUYDiABKAlSF3N1cnZlaWxsYW5jZVN0b3JhZ2VUeXBlEioKEXNk'
    'X2NhcmRfYXZhaWxhYmxlGA8gASgIUg9zZENhcmRBdmFpbGFibGUSIAoMc2RfY2FyZF9wYXRoGB'
    'AgASgJUgpzZENhcmRQYXRoEisKEnNkX2NhcmRfZnJlZV9ieXRlcxgRIAEoA1IPc2RDYXJkRnJl'
    'ZVNwYWNlEi0KE3NkX2NhcmRfdG90YWxfYnl0ZXMYEiABKANSEHNkQ2FyZFRvdGFsU3BhY2USMw'
    'oWc2RfY2FyZF9mcmVlX2Zvcm1hdHRlZBgTIAEoCVITc2RDYXJkRnJlZUZvcm1hdHRlZBI1Chdz'
    'ZF9jYXJkX3RvdGFsX2Zvcm1hdHRlZBgUIAEoCVIUc2RDYXJkVG90YWxGb3JtYXR0ZWQSLgoTaW'
    '50ZXJuYWxfZnJlZV9ieXRlcxgVIAEoA1IRaW50ZXJuYWxGcmVlU3BhY2USMAoUaW50ZXJuYWxf'
    'dG90YWxfYnl0ZXMYFiABKANSEmludGVybmFsVG90YWxTcGFjZRI2ChdpbnRlcm5hbF9mcmVlX2'
    'Zvcm1hdHRlZBgXIAEoCVIVaW50ZXJuYWxGcmVlRm9ybWF0dGVkEjgKGGludGVybmFsX3RvdGFs'
    'X2Zvcm1hdHRlZBgYIAEoCVIWaW50ZXJuYWxUb3RhbEZvcm1hdHRlZA==');

@$core.Deprecated('Use setStorageSettingsRequestDescriptor instead')
const SetStorageSettingsRequest$json = {
  '1': 'SetStorageSettingsRequest',
  '2': [
    {
      '1': 'recordings_limit_mb',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'recordingsLimitMb'
    },
    {
      '1': 'surveillance_limit_mb',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'surveillanceLimitMb'
    },
    {
      '1': 'recordings_storage_type',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'recordingsStorageType'
    },
    {
      '1': 'surveillance_storage_type',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'surveillanceStorageType'
    },
  ],
};

/// Descriptor for `SetStorageSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setStorageSettingsRequestDescriptor = $convert.base64Decode(
    'ChlTZXRTdG9yYWdlU2V0dGluZ3NSZXF1ZXN0Ei4KE3JlY29yZGluZ3NfbGltaXRfbWIYASABKA'
    'NSEXJlY29yZGluZ3NMaW1pdE1iEjIKFXN1cnZlaWxsYW5jZV9saW1pdF9tYhgCIAEoA1ITc3Vy'
    'dmVpbGxhbmNlTGltaXRNYhI2ChdyZWNvcmRpbmdzX3N0b3JhZ2VfdHlwZRgDIAEoCVIVcmVjb3'
    'JkaW5nc1N0b3JhZ2VUeXBlEjoKGXN1cnZlaWxsYW5jZV9zdG9yYWdlX3R5cGUYBCABKAlSF3N1'
    'cnZlaWxsYW5jZVN0b3JhZ2VUeXBl');

@$core.Deprecated('Use setStorageSettingsResponseDescriptor instead')
const SetStorageSettingsResponse$json = {
  '1': 'SetStorageSettingsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetStorageSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setStorageSettingsResponseDescriptor =
    $convert.base64Decode(
        'ChpTZXRTdG9yYWdlU2V0dGluZ3NSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEh'
        'QKBWVycm9yGAIgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getExternalStorageRequestDescriptor instead')
const GetExternalStorageRequest$json = {
  '1': 'GetExternalStorageRequest',
};

/// Descriptor for `GetExternalStorageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getExternalStorageRequestDescriptor =
    $convert.base64Decode('ChlHZXRFeHRlcm5hbFN0b3JhZ2VSZXF1ZXN0');

@$core.Deprecated('Use getExternalStorageResponseDescriptor instead')
const GetExternalStorageResponse$json = {
  '1': 'GetExternalStorageResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'sd_card_available', '3': 2, '4': 1, '5': 8, '10': 'sdCardAvailable'},
    {'1': 'sd_card_path', '3': 3, '4': 1, '5': 9, '10': 'sdCardPath'},
    {'1': 'sd_card_free_bytes', '3': 4, '4': 1, '5': 3, '10': 'sdCardFree'},
    {'1': 'sd_card_total_bytes', '3': 5, '4': 1, '5': 3, '10': 'sdCardTotal'},
    {
      '1': 'sd_card_free_formatted',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'sdCardFreeFormatted'
    },
    {
      '1': 'sd_card_total_formatted',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'sdCardTotalFormatted'
    },
    {
      '1': 'sd_card_used_percent',
      '3': 8,
      '4': 1,
      '5': 5,
      '10': 'sdCardUsedPercent'
    },
    {'1': 'cdr_path', '3': 9, '4': 1, '5': 9, '10': 'cdrPath'},
    {'1': 'cdr_usage_bytes', '3': 10, '4': 1, '5': 3, '10': 'cdrUsage'},
    {
      '1': 'cdr_usage_formatted',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'cdrUsageFormatted'
    },
    {'1': 'cdr_file_count', '3': 12, '4': 1, '5': 5, '10': 'cdrFileCount'},
    {
      '1': 'cdr_protected_bytes',
      '3': 13,
      '4': 1,
      '5': 3,
      '10': 'cdrProtectedSize'
    },
    {
      '1': 'cdr_protected_formatted',
      '3': 14,
      '4': 1,
      '5': 9,
      '10': 'cdrProtectedFormatted'
    },
    {
      '1': 'cdr_deletable_bytes',
      '3': 15,
      '4': 1,
      '5': 3,
      '10': 'cdrDeletableSize'
    },
    {
      '1': 'cdr_deletable_formatted',
      '3': 16,
      '4': 1,
      '5': 9,
      '10': 'cdrDeletableFormatted'
    },
    {'1': 'cleanup_enabled', '3': 17, '4': 1, '5': 8, '10': 'cleanupEnabled'},
    {
      '1': 'reserved_space_mb',
      '3': 18,
      '4': 1,
      '5': 3,
      '10': 'reservedSpaceMb'
    },
    {'1': 'protected_hours', '3': 19, '4': 1, '5': 5, '10': 'protectedHours'},
    {'1': 'min_files_keep', '3': 20, '4': 1, '5': 5, '10': 'minFilesKeep'},
    {
      '1': 'monitoring_active',
      '3': 21,
      '4': 1,
      '5': 8,
      '10': 'monitoringActive'
    },
    {
      '1': 'total_bytes_freed',
      '3': 22,
      '4': 1,
      '5': 3,
      '10': 'totalBytesFreed'
    },
    {
      '1': 'total_bytes_freed_formatted',
      '3': 23,
      '4': 1,
      '5': 9,
      '10': 'totalBytesFreedFormatted'
    },
    {
      '1': 'total_files_deleted',
      '3': 24,
      '4': 1,
      '5': 5,
      '10': 'totalFilesDeleted'
    },
    {
      '1': 'last_cleanup_time_ms',
      '3': 25,
      '4': 1,
      '5': 3,
      '10': 'lastCleanupTime'
    },
    {
      '1': 'bladewatch_uses_sd_card',
      '3': 26,
      '4': 1,
      '5': 8,
      '10': 'bladewatchUsesSdCard'
    },
    {
      '1': 'recommend_auto_cleanup',
      '3': 27,
      '4': 1,
      '5': 8,
      '10': 'recommendAutoCleanup'
    },
  ],
};

/// Descriptor for `GetExternalStorageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getExternalStorageResponseDescriptor = $convert.base64Decode(
    'ChpHZXRFeHRlcm5hbFN0b3JhZ2VSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEi'
    'oKEXNkX2NhcmRfYXZhaWxhYmxlGAIgASgIUg9zZENhcmRBdmFpbGFibGUSIAoMc2RfY2FyZF9w'
    'YXRoGAMgASgJUgpzZENhcmRQYXRoEiYKEnNkX2NhcmRfZnJlZV9ieXRlcxgEIAEoA1IKc2RDYX'
    'JkRnJlZRIoChNzZF9jYXJkX3RvdGFsX2J5dGVzGAUgASgDUgtzZENhcmRUb3RhbBIzChZzZF9j'
    'YXJkX2ZyZWVfZm9ybWF0dGVkGAYgASgJUhNzZENhcmRGcmVlRm9ybWF0dGVkEjUKF3NkX2Nhcm'
    'RfdG90YWxfZm9ybWF0dGVkGAcgASgJUhRzZENhcmRUb3RhbEZvcm1hdHRlZBIvChRzZF9jYXJk'
    'X3VzZWRfcGVyY2VudBgIIAEoBVIRc2RDYXJkVXNlZFBlcmNlbnQSGQoIY2RyX3BhdGgYCSABKA'
    'lSB2NkclBhdGgSIQoPY2RyX3VzYWdlX2J5dGVzGAogASgDUghjZHJVc2FnZRIuChNjZHJfdXNh'
    'Z2VfZm9ybWF0dGVkGAsgASgJUhFjZHJVc2FnZUZvcm1hdHRlZBIkCg5jZHJfZmlsZV9jb3VudB'
    'gMIAEoBVIMY2RyRmlsZUNvdW50Ei0KE2Nkcl9wcm90ZWN0ZWRfYnl0ZXMYDSABKANSEGNkclBy'
    'b3RlY3RlZFNpemUSNgoXY2RyX3Byb3RlY3RlZF9mb3JtYXR0ZWQYDiABKAlSFWNkclByb3RlY3'
    'RlZEZvcm1hdHRlZBItChNjZHJfZGVsZXRhYmxlX2J5dGVzGA8gASgDUhBjZHJEZWxldGFibGVT'
    'aXplEjYKF2Nkcl9kZWxldGFibGVfZm9ybWF0dGVkGBAgASgJUhVjZHJEZWxldGFibGVGb3JtYX'
    'R0ZWQSJwoPY2xlYW51cF9lbmFibGVkGBEgASgIUg5jbGVhbnVwRW5hYmxlZBIqChFyZXNlcnZl'
    'ZF9zcGFjZV9tYhgSIAEoA1IPcmVzZXJ2ZWRTcGFjZU1iEicKD3Byb3RlY3RlZF9ob3VycxgTIA'
    'EoBVIOcHJvdGVjdGVkSG91cnMSJAoObWluX2ZpbGVzX2tlZXAYFCABKAVSDG1pbkZpbGVzS2Vl'
    'cBIrChFtb25pdG9yaW5nX2FjdGl2ZRgVIAEoCFIQbW9uaXRvcmluZ0FjdGl2ZRIqChF0b3RhbF'
    '9ieXRlc19mcmVlZBgWIAEoA1IPdG90YWxCeXRlc0ZyZWVkEj0KG3RvdGFsX2J5dGVzX2ZyZWVk'
    'X2Zvcm1hdHRlZBgXIAEoCVIYdG90YWxCeXRlc0ZyZWVkRm9ybWF0dGVkEi4KE3RvdGFsX2ZpbG'
    'VzX2RlbGV0ZWQYGCABKAVSEXRvdGFsRmlsZXNEZWxldGVkEi0KFGxhc3RfY2xlYW51cF90aW1l'
    'X21zGBkgASgDUg9sYXN0Q2xlYW51cFRpbWUSNQoXYmxhZGV3YXRjaF91c2VzX3NkX2NhcmQYGi'
    'ABKAhSFGJsYWRld2F0Y2hVc2VzU2RDYXJkEjQKFnJlY29tbWVuZF9hdXRvX2NsZWFudXAYGyAB'
    'KAhSFHJlY29tbWVuZEF1dG9DbGVhbnVw');

@$core.Deprecated('Use setExternalConfigRequestDescriptor instead')
const SetExternalConfigRequest$json = {
  '1': 'SetExternalConfigRequest',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'reserved_space_mb', '3': 2, '4': 1, '5': 3, '10': 'reservedSpaceMb'},
    {'1': 'protected_hours', '3': 3, '4': 1, '5': 5, '10': 'protectedHours'},
    {'1': 'min_files_keep', '3': 4, '4': 1, '5': 5, '10': 'minFilesKeep'},
  ],
};

/// Descriptor for `SetExternalConfigRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setExternalConfigRequestDescriptor = $convert.base64Decode(
    'ChhTZXRFeHRlcm5hbENvbmZpZ1JlcXVlc3QSGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBIqCh'
    'FyZXNlcnZlZF9zcGFjZV9tYhgCIAEoA1IPcmVzZXJ2ZWRTcGFjZU1iEicKD3Byb3RlY3RlZF9o'
    'b3VycxgDIAEoBVIOcHJvdGVjdGVkSG91cnMSJAoObWluX2ZpbGVzX2tlZXAYBCABKAVSDG1pbk'
    'ZpbGVzS2VlcA==');

@$core.Deprecated('Use setExternalConfigResponseDescriptor instead')
const SetExternalConfigResponse$json = {
  '1': 'SetExternalConfigResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'cleanup_enabled', '3': 2, '4': 1, '5': 8, '10': 'cleanupEnabled'},
    {'1': 'reserved_space_mb', '3': 3, '4': 1, '5': 3, '10': 'reservedSpaceMb'},
    {'1': 'protected_hours', '3': 4, '4': 1, '5': 5, '10': 'protectedHours'},
    {'1': 'min_files_keep', '3': 5, '4': 1, '5': 5, '10': 'minFilesKeep'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetExternalConfigResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setExternalConfigResponseDescriptor = $convert.base64Decode(
    'ChlTZXRFeHRlcm5hbENvbmZpZ1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSJw'
    'oPY2xlYW51cF9lbmFibGVkGAIgASgIUg5jbGVhbnVwRW5hYmxlZBIqChFyZXNlcnZlZF9zcGFj'
    'ZV9tYhgDIAEoA1IPcmVzZXJ2ZWRTcGFjZU1iEicKD3Byb3RlY3RlZF9ob3VycxgEIAEoBVIOcH'
    'JvdGVjdGVkSG91cnMSJAoObWluX2ZpbGVzX2tlZXAYBSABKAVSDG1pbkZpbGVzS2VlcBIUCgVl'
    'cnJvchgGIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use triggerCleanupRequestDescriptor instead')
const TriggerCleanupRequest$json = {
  '1': 'TriggerCleanupRequest',
  '2': [
    {'1': 'bytes_to_free', '3': 1, '4': 1, '5': 3, '10': 'bytesToFree'},
  ],
};

/// Descriptor for `TriggerCleanupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List triggerCleanupRequestDescriptor = $convert.base64Decode(
    'ChVUcmlnZ2VyQ2xlYW51cFJlcXVlc3QSIgoNYnl0ZXNfdG9fZnJlZRgBIAEoA1ILYnl0ZXNUb0'
    'ZyZWU=');

@$core.Deprecated('Use triggerCleanupResponseDescriptor instead')
const TriggerCleanupResponse$json = {
  '1': 'TriggerCleanupResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'bytes_freed', '3': 2, '4': 1, '5': 3, '10': 'bytesFreed'},
    {'1': 'files_deleted', '3': 3, '4': 1, '5': 5, '10': 'filesDeleted'},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `TriggerCleanupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List triggerCleanupResponseDescriptor = $convert.base64Decode(
    'ChZUcmlnZ2VyQ2xlYW51cFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSHwoLYn'
    'l0ZXNfZnJlZWQYAiABKANSCmJ5dGVzRnJlZWQSIwoNZmlsZXNfZGVsZXRlZBgDIAEoBVIMZmls'
    'ZXNEZWxldGVkEhgKB21lc3NhZ2UYBCABKAlSB21lc3NhZ2USFAoFZXJyb3IYBSABKAlSBWVycm'
    '9y');

@$core.Deprecated('Use previewCleanupRequestDescriptor instead')
const PreviewCleanupRequest$json = {
  '1': 'PreviewCleanupRequest',
  '2': [
    {'1': 'bytes_to_free', '3': 1, '4': 1, '5': 3, '10': 'bytesToFree'},
  ],
};

/// Descriptor for `PreviewCleanupRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCleanupRequestDescriptor = $convert.base64Decode(
    'ChVQcmV2aWV3Q2xlYW51cFJlcXVlc3QSIgoNYnl0ZXNfdG9fZnJlZRgBIAEoA1ILYnl0ZXNUb0'
    'ZyZWU=');

@$core.Deprecated('Use previewCleanupFileDescriptor instead')
const PreviewCleanupFile$json = {
  '1': 'PreviewCleanupFile',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'size_bytes', '3': 2, '4': 1, '5': 3, '10': 'size'},
  ],
  '9': [
    {'1': 3, '2': 4},
  ],
  '10': ['age_hours'],
};

/// Descriptor for `PreviewCleanupFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCleanupFileDescriptor = $convert.base64Decode(
    'ChJQcmV2aWV3Q2xlYW51cEZpbGUSEgoEcGF0aBgBIAEoCVIEcGF0aBIYCgpzaXplX2J5dGVzGA'
    'IgASgDUgRzaXplSgQIAxAEUglhZ2VfaG91cnM=');

@$core.Deprecated('Use previewCleanupResponseDescriptor instead')
const PreviewCleanupResponse$json = {
  '1': 'PreviewCleanupResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'files',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.PreviewCleanupFile',
      '10': 'files'
    },
    {'1': 'total_deletable_bytes', '3': 3, '4': 1, '5': 3, '10': 'totalSize'},
    {'1': 'total_deletable_count', '3': 4, '4': 1, '5': 5, '10': 'fileCount'},
  ],
};

/// Descriptor for `PreviewCleanupResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCleanupResponseDescriptor = $convert.base64Decode(
    'ChZQcmV2aWV3Q2xlYW51cFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSNwoFZm'
    'lsZXMYAiADKAsyIS5ibGFkZXdhdGNoLnYxLlByZXZpZXdDbGVhbnVwRmlsZVIFZmlsZXMSKAoV'
    'dG90YWxfZGVsZXRhYmxlX2J5dGVzGAMgASgDUgl0b3RhbFNpemUSKAoVdG90YWxfZGVsZXRhYm'
    'xlX2NvdW50GAQgASgFUglmaWxlQ291bnQ=');

@$core.Deprecated('Use refreshExternalStorageRequestDescriptor instead')
const RefreshExternalStorageRequest$json = {
  '1': 'RefreshExternalStorageRequest',
};

/// Descriptor for `RefreshExternalStorageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshExternalStorageRequestDescriptor =
    $convert.base64Decode('Ch1SZWZyZXNoRXh0ZXJuYWxTdG9yYWdlUmVxdWVzdA==');

@$core.Deprecated('Use refreshExternalStorageResponseDescriptor instead')
const RefreshExternalStorageResponse$json = {
  '1': 'RefreshExternalStorageResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `RefreshExternalStorageResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshExternalStorageResponseDescriptor =
    $convert.base64Decode(
        'Ch5SZWZyZXNoRXh0ZXJuYWxTdG9yYWdlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2'
        'Vzcw==');

@$core.Deprecated('Use listFormatVolumesRequestDescriptor instead')
const ListFormatVolumesRequest$json = {
  '1': 'ListFormatVolumesRequest',
};

/// Descriptor for `ListFormatVolumesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFormatVolumesRequestDescriptor =
    $convert.base64Decode('ChhMaXN0Rm9ybWF0Vm9sdW1lc1JlcXVlc3Q=');

@$core.Deprecated('Use listFormatVolumesResponseDescriptor instead')
const ListFormatVolumesResponse$json = {
  '1': 'ListFormatVolumesResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'volumes',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.VolumeInfo',
      '10': 'volumes'
    },
  ],
};

/// Descriptor for `ListFormatVolumesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listFormatVolumesResponseDescriptor =
    $convert.base64Decode(
        'ChlMaXN0Rm9ybWF0Vm9sdW1lc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSMw'
        'oHdm9sdW1lcxgCIAMoCzIZLmJsYWRld2F0Y2gudjEuVm9sdW1lSW5mb1IHdm9sdW1lcw==');

@$core.Deprecated('Use formatVolumeRequestDescriptor instead')
const FormatVolumeRequest$json = {
  '1': 'FormatVolumeRequest',
  '2': [
    {'1': 'volume_id', '3': 1, '4': 1, '5': 9, '10': 'volumeId'},
  ],
};

/// Descriptor for `FormatVolumeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formatVolumeRequestDescriptor =
    $convert.base64Decode(
        'ChNGb3JtYXRWb2x1bWVSZXF1ZXN0EhsKCXZvbHVtZV9pZBgBIAEoCVIIdm9sdW1lSWQ=');

@$core.Deprecated('Use formatVolumeResponseDescriptor instead')
const FormatVolumeResponse$json = {
  '1': 'FormatVolumeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'mount_path', '3': 3, '4': 1, '5': 9, '10': 'mountPath'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `FormatVolumeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List formatVolumeResponseDescriptor = $convert.base64Decode(
    'ChRGb3JtYXRWb2x1bWVSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2USHQoKbW91bnRfcGF0aBgDIAEoCVIJbW91bnRQYXRoEhQKBWVy'
    'cm9yGAQgASgJUgVlcnJvcg==');

const $core.Map<$core.String, $core.dynamic> StorageServiceBase$json = {
  '1': 'StorageService',
  '2': [
    {
      '1': 'GetStorageSettings',
      '2': '.bladewatch.v1.GetStorageSettingsRequest',
      '3': '.bladewatch.v1.GetStorageSettingsResponse'
    },
    {
      '1': 'SetStorageSettings',
      '2': '.bladewatch.v1.SetStorageSettingsRequest',
      '3': '.bladewatch.v1.SetStorageSettingsResponse'
    },
    {
      '1': 'GetExternalStorage',
      '2': '.bladewatch.v1.GetExternalStorageRequest',
      '3': '.bladewatch.v1.GetExternalStorageResponse'
    },
    {
      '1': 'SetExternalConfig',
      '2': '.bladewatch.v1.SetExternalConfigRequest',
      '3': '.bladewatch.v1.SetExternalConfigResponse'
    },
    {
      '1': 'TriggerCleanup',
      '2': '.bladewatch.v1.TriggerCleanupRequest',
      '3': '.bladewatch.v1.TriggerCleanupResponse'
    },
    {
      '1': 'PreviewCleanup',
      '2': '.bladewatch.v1.PreviewCleanupRequest',
      '3': '.bladewatch.v1.PreviewCleanupResponse'
    },
    {
      '1': 'RefreshExternalStorage',
      '2': '.bladewatch.v1.RefreshExternalStorageRequest',
      '3': '.bladewatch.v1.RefreshExternalStorageResponse'
    },
    {
      '1': 'ListFormatVolumes',
      '2': '.bladewatch.v1.ListFormatVolumesRequest',
      '3': '.bladewatch.v1.ListFormatVolumesResponse'
    },
    {
      '1': 'FormatVolume',
      '2': '.bladewatch.v1.FormatVolumeRequest',
      '3': '.bladewatch.v1.FormatVolumeResponse'
    },
  ],
};

@$core.Deprecated('Use storageServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    StorageServiceBase$messageJson = {
  '.bladewatch.v1.GetStorageSettingsRequest': GetStorageSettingsRequest$json,
  '.bladewatch.v1.GetStorageSettingsResponse': GetStorageSettingsResponse$json,
  '.bladewatch.v1.SetStorageSettingsRequest': SetStorageSettingsRequest$json,
  '.bladewatch.v1.SetStorageSettingsResponse': SetStorageSettingsResponse$json,
  '.bladewatch.v1.GetExternalStorageRequest': GetExternalStorageRequest$json,
  '.bladewatch.v1.GetExternalStorageResponse': GetExternalStorageResponse$json,
  '.bladewatch.v1.SetExternalConfigRequest': SetExternalConfigRequest$json,
  '.bladewatch.v1.SetExternalConfigResponse': SetExternalConfigResponse$json,
  '.bladewatch.v1.TriggerCleanupRequest': TriggerCleanupRequest$json,
  '.bladewatch.v1.TriggerCleanupResponse': TriggerCleanupResponse$json,
  '.bladewatch.v1.PreviewCleanupRequest': PreviewCleanupRequest$json,
  '.bladewatch.v1.PreviewCleanupResponse': PreviewCleanupResponse$json,
  '.bladewatch.v1.PreviewCleanupFile': PreviewCleanupFile$json,
  '.bladewatch.v1.RefreshExternalStorageRequest':
      RefreshExternalStorageRequest$json,
  '.bladewatch.v1.RefreshExternalStorageResponse':
      RefreshExternalStorageResponse$json,
  '.bladewatch.v1.ListFormatVolumesRequest': ListFormatVolumesRequest$json,
  '.bladewatch.v1.ListFormatVolumesResponse': ListFormatVolumesResponse$json,
  '.bladewatch.v1.VolumeInfo': VolumeInfo$json,
  '.bladewatch.v1.FormatVolumeRequest': FormatVolumeRequest$json,
  '.bladewatch.v1.FormatVolumeResponse': FormatVolumeResponse$json,
};

/// Descriptor for `StorageService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List storageServiceDescriptor = $convert.base64Decode(
    'Cg5TdG9yYWdlU2VydmljZRJpChJHZXRTdG9yYWdlU2V0dGluZ3MSKC5ibGFkZXdhdGNoLnYxLk'
    'dldFN0b3JhZ2VTZXR0aW5nc1JlcXVlc3QaKS5ibGFkZXdhdGNoLnYxLkdldFN0b3JhZ2VTZXR0'
    'aW5nc1Jlc3BvbnNlEmkKElNldFN0b3JhZ2VTZXR0aW5ncxIoLmJsYWRld2F0Y2gudjEuU2V0U3'
    'RvcmFnZVNldHRpbmdzUmVxdWVzdBopLmJsYWRld2F0Y2gudjEuU2V0U3RvcmFnZVNldHRpbmdz'
    'UmVzcG9uc2USaQoSR2V0RXh0ZXJuYWxTdG9yYWdlEiguYmxhZGV3YXRjaC52MS5HZXRFeHRlcm'
    '5hbFN0b3JhZ2VSZXF1ZXN0GikuYmxhZGV3YXRjaC52MS5HZXRFeHRlcm5hbFN0b3JhZ2VSZXNw'
    'b25zZRJmChFTZXRFeHRlcm5hbENvbmZpZxInLmJsYWRld2F0Y2gudjEuU2V0RXh0ZXJuYWxDb2'
    '5maWdSZXF1ZXN0GiguYmxhZGV3YXRjaC52MS5TZXRFeHRlcm5hbENvbmZpZ1Jlc3BvbnNlEl0K'
    'DlRyaWdnZXJDbGVhbnVwEiQuYmxhZGV3YXRjaC52MS5UcmlnZ2VyQ2xlYW51cFJlcXVlc3QaJS'
    '5ibGFkZXdhdGNoLnYxLlRyaWdnZXJDbGVhbnVwUmVzcG9uc2USXQoOUHJldmlld0NsZWFudXAS'
    'JC5ibGFkZXdhdGNoLnYxLlByZXZpZXdDbGVhbnVwUmVxdWVzdBolLmJsYWRld2F0Y2gudjEuUH'
    'Jldmlld0NsZWFudXBSZXNwb25zZRJ1ChZSZWZyZXNoRXh0ZXJuYWxTdG9yYWdlEiwuYmxhZGV3'
    'YXRjaC52MS5SZWZyZXNoRXh0ZXJuYWxTdG9yYWdlUmVxdWVzdBotLmJsYWRld2F0Y2gudjEuUm'
    'VmcmVzaEV4dGVybmFsU3RvcmFnZVJlc3BvbnNlEmYKEUxpc3RGb3JtYXRWb2x1bWVzEicuYmxh'
    'ZGV3YXRjaC52MS5MaXN0Rm9ybWF0Vm9sdW1lc1JlcXVlc3QaKC5ibGFkZXdhdGNoLnYxLkxpc3'
    'RGb3JtYXRWb2x1bWVzUmVzcG9uc2USVwoMRm9ybWF0Vm9sdW1lEiIuYmxhZGV3YXRjaC52MS5G'
    'b3JtYXRWb2x1bWVSZXF1ZXN0GiMuYmxhZGV3YXRjaC52MS5Gb3JtYXRWb2x1bWVSZXNwb25zZQ'
    '==');
