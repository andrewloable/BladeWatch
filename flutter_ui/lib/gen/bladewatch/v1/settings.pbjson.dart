// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/settings.proto.

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

@$core.Deprecated('Use recordingQualityTierDescriptor instead')
const RecordingQualityTier$json = {
  '1': 'RecordingQualityTier',
  '2': [
    {'1': 'RECORDING_QUALITY_TIER_UNSPECIFIED', '2': 0},
    {'1': 'RECORDING_QUALITY_TIER_ECONOMY', '2': 1},
    {'1': 'RECORDING_QUALITY_TIER_STANDARD', '2': 2},
    {'1': 'RECORDING_QUALITY_TIER_HIGH', '2': 3},
    {'1': 'RECORDING_QUALITY_TIER_PREMIUM', '2': 4},
    {'1': 'RECORDING_QUALITY_TIER_MAX', '2': 5},
  ],
};

/// Descriptor for `RecordingQualityTier`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List recordingQualityTierDescriptor = $convert.base64Decode(
    'ChRSZWNvcmRpbmdRdWFsaXR5VGllchImCiJSRUNPUkRJTkdfUVVBTElUWV9USUVSX1VOU1BFQ0'
    'lGSUVEEAASIgoeUkVDT1JESU5HX1FVQUxJVFlfVElFUl9FQ09OT01ZEAESIwofUkVDT1JESU5H'
    'X1FVQUxJVFlfVElFUl9TVEFOREFSRBACEh8KG1JFQ09SRElOR19RVUFMSVRZX1RJRVJfSElHSB'
    'ADEiIKHlJFQ09SRElOR19RVUFMSVRZX1RJRVJfUFJFTUlVTRAEEh4KGlJFQ09SRElOR19RVUFM'
    'SVRZX1RJRVJfTUFYEAU=');

@$core.Deprecated('Use videoCodecDescriptor instead')
const VideoCodec$json = {
  '1': 'VideoCodec',
  '2': [
    {'1': 'VIDEO_CODEC_UNSPECIFIED', '2': 0},
    {'1': 'VIDEO_CODEC_H264', '2': 1},
    {'1': 'VIDEO_CODEC_H265', '2': 2},
  ],
};

/// Descriptor for `VideoCodec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List videoCodecDescriptor = $convert.base64Decode(
    'CgpWaWRlb0NvZGVjEhsKF1ZJREVPX0NPREVDX1VOU1BFQ0lGSUVEEAASFAoQVklERU9fQ09ERU'
    'NfSDI2NBABEhQKEFZJREVPX0NPREVDX0gyNjUQAg==');

@$core.Deprecated('Use appThemeDescriptor instead')
const AppTheme$json = {
  '1': 'AppTheme',
  '2': [
    {'1': 'APP_THEME_UNSPECIFIED', '2': 0},
    {'1': 'APP_THEME_DARK', '2': 1},
    {'1': 'APP_THEME_LIGHT', '2': 2},
    {'1': 'APP_THEME_AUTO', '2': 3},
  ],
};

/// Descriptor for `AppTheme`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List appThemeDescriptor = $convert.base64Decode(
    'CghBcHBUaGVtZRIZChVBUFBfVEhFTUVfVU5TUEVDSUZJRUQQABISCg5BUFBfVEhFTUVfREFSSx'
    'ABEhMKD0FQUF9USEVNRV9MSUdIVBACEhIKDkFQUF9USEVNRV9BVVRPEAM=');

@$core.Deprecated('Use qualityTierInfoDescriptor instead')
const QualityTierInfo$json = {
  '1': 'QualityTierInfo',
  '2': [
    {'1': 'display_name', '3': 1, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'bitrate_bps', '3': 2, '4': 1, '5': 3, '10': 'bitrateBps'},
    {'1': 'bitrate_mbps', '3': 3, '4': 1, '5': 1, '10': 'bitrateMbps'},
    {'1': 'mb_per_minute', '3': 4, '4': 1, '5': 1, '10': 'mbPerMinute'},
    {'1': 'gb_per_hour', '3': 5, '4': 1, '5': 1, '10': 'gbPerHour'},
    {
      '1': 'quality_equivalent',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'qualityEquivalent'
    },
  ],
};

/// Descriptor for `QualityTierInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List qualityTierInfoDescriptor = $convert.base64Decode(
    'Cg9RdWFsaXR5VGllckluZm8SIQoMZGlzcGxheV9uYW1lGAEgASgJUgtkaXNwbGF5TmFtZRIfCg'
    'tiaXRyYXRlX2JwcxgCIAEoA1IKYml0cmF0ZUJwcxIhCgxiaXRyYXRlX21icHMYAyABKAFSC2Jp'
    'dHJhdGVNYnBzEiIKDW1iX3Blcl9taW51dGUYBCABKAFSC21iUGVyTWludXRlEh4KC2diX3Blcl'
    '9ob3VyGAUgASgBUglnYlBlckhvdXISLQoScXVhbGl0eV9lcXVpdmFsZW50GAYgASgJUhFxdWFs'
    'aXR5RXF1aXZhbGVudA==');

@$core.Deprecated('Use activeRecordingEstimateDescriptor instead')
const ActiveRecordingEstimate$json = {
  '1': 'ActiveRecordingEstimate',
  '2': [
    {'1': 'bitrate_mbps', '3': 1, '4': 1, '5': 1, '10': 'bitrateMbps'},
    {'1': 'mb_per_minute', '3': 2, '4': 1, '5': 1, '10': 'mbPerMinute'},
    {'1': 'mb_per_2_min', '3': 3, '4': 1, '5': 1, '10': 'mbPer2Min'},
    {'1': 'gb_per_hour', '3': 4, '4': 1, '5': 1, '10': 'gbPerHour'},
    {'1': 'minutes_per_gb', '3': 5, '4': 1, '5': 5, '10': 'minutesPerGb'},
    {
      '1': 'quality_equivalent',
      '3': 6,
      '4': 1,
      '5': 9,
      '10': 'qualityEquivalent'
    },
  ],
};

/// Descriptor for `ActiveRecordingEstimate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeRecordingEstimateDescriptor = $convert.base64Decode(
    'ChdBY3RpdmVSZWNvcmRpbmdFc3RpbWF0ZRIhCgxiaXRyYXRlX21icHMYASABKAFSC2JpdHJhdG'
    'VNYnBzEiIKDW1iX3Blcl9taW51dGUYAiABKAFSC21iUGVyTWludXRlEh8KDG1iX3Blcl8yX21p'
    'bhgDIAEoAVIJbWJQZXIyTWluEh4KC2diX3Blcl9ob3VyGAQgASgBUglnYlBlckhvdXISJAoObW'
    'ludXRlc19wZXJfZ2IYBSABKAVSDG1pbnV0ZXNQZXJHYhItChJxdWFsaXR5X2VxdWl2YWxlbnQY'
    'BiABKAlSEXF1YWxpdHlFcXVpdmFsZW50');

@$core.Deprecated('Use getQualityRequestDescriptor instead')
const GetQualityRequest$json = {
  '1': 'GetQualityRequest',
};

/// Descriptor for `GetQualityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getQualityRequestDescriptor =
    $convert.base64Decode('ChFHZXRRdWFsaXR5UmVxdWVzdA==');

@$core.Deprecated('Use getQualityResponseDescriptor instead')
const GetQualityResponse$json = {
  '1': 'GetQualityResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'recording_quality',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'recordingQuality'
    },
    {'1': 'codec', '3': 3, '4': 1, '5': 9, '10': 'recordingCodec'},
    {'1': 'fps', '3': 4, '4': 1, '5': 5, '10': 'cameraFps'},
    {
      '1': 'recording_quality_options',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.GetQualityResponse.RecordingQualityOptionsEntry',
      '10': 'recordingQualityOptions'
    },
    {
      '1': 'active_recording_estimate',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.ActiveRecordingEstimate',
      '10': 'activeRecordingEstimate'
    },
    {
      '1': 'codec_options',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.GetQualityResponse.CodecOptionsEntry',
      '10': 'codecOptions'
    },
    {
      '1': 'fps_options',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.GetQualityResponse.FpsOptionsEntry',
      '10': 'fpsOptions'
    },
    {
      '1': 'native_resolution',
      '3': 9,
      '4': 1,
      '5': 9,
      '10': 'nativeResolution'
    },
    {
      '1': 'recording_segment_minutes',
      '3': 10,
      '4': 1,
      '5': 5,
      '10': 'recordingSegmentMinutes'
    },
  ],
  '3': [
    GetQualityResponse_RecordingQualityOptionsEntry$json,
    GetQualityResponse_CodecOptionsEntry$json,
    GetQualityResponse_FpsOptionsEntry$json
  ],
};

@$core.Deprecated('Use getQualityResponseDescriptor instead')
const GetQualityResponse_RecordingQualityOptionsEntry$json = {
  '1': 'RecordingQualityOptionsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.QualityTierInfo',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use getQualityResponseDescriptor instead')
const GetQualityResponse_CodecOptionsEntry$json = {
  '1': 'CodecOptionsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use getQualityResponseDescriptor instead')
const GetQualityResponse_FpsOptionsEntry$json = {
  '1': 'FpsOptionsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `GetQualityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getQualityResponseDescriptor = $convert.base64Decode(
    'ChJHZXRRdWFsaXR5UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIrChFyZWNvcm'
    'RpbmdfcXVhbGl0eRgCIAEoCVIQcmVjb3JkaW5nUXVhbGl0eRIdCgVjb2RlYxgDIAEoCVIOcmVj'
    'b3JkaW5nQ29kZWMSFgoDZnBzGAQgASgFUgljYW1lcmFGcHMSegoZcmVjb3JkaW5nX3F1YWxpdH'
    'lfb3B0aW9ucxgFIAMoCzI+LmJsYWRld2F0Y2gudjEuR2V0UXVhbGl0eVJlc3BvbnNlLlJlY29y'
    'ZGluZ1F1YWxpdHlPcHRpb25zRW50cnlSF3JlY29yZGluZ1F1YWxpdHlPcHRpb25zEmIKGWFjdG'
    'l2ZV9yZWNvcmRpbmdfZXN0aW1hdGUYBiABKAsyJi5ibGFkZXdhdGNoLnYxLkFjdGl2ZVJlY29y'
    'ZGluZ0VzdGltYXRlUhdhY3RpdmVSZWNvcmRpbmdFc3RpbWF0ZRJYCg1jb2RlY19vcHRpb25zGA'
    'cgAygLMjMuYmxhZGV3YXRjaC52MS5HZXRRdWFsaXR5UmVzcG9uc2UuQ29kZWNPcHRpb25zRW50'
    'cnlSDGNvZGVjT3B0aW9ucxJSCgtmcHNfb3B0aW9ucxgIIAMoCzIxLmJsYWRld2F0Y2gudjEuR2'
    'V0UXVhbGl0eVJlc3BvbnNlLkZwc09wdGlvbnNFbnRyeVIKZnBzT3B0aW9ucxIrChFuYXRpdmVf'
    'cmVzb2x1dGlvbhgJIAEoCVIQbmF0aXZlUmVzb2x1dGlvbhI6ChlyZWNvcmRpbmdfc2VnbWVudF'
    '9taW51dGVzGAogASgFUhdyZWNvcmRpbmdTZWdtZW50TWludXRlcxpqChxSZWNvcmRpbmdRdWFs'
    'aXR5T3B0aW9uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjQKBXZhbHVlGAIgASgLMh4uYmxhZG'
    'V3YXRjaC52MS5RdWFsaXR5VGllckluZm9SBXZhbHVlOgI4ARo/ChFDb2RlY09wdGlvbnNFbnRy'
    'eRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj0KD0Zwc09wdG'
    'lvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use setQualityRequestDescriptor instead')
const SetQualityRequest$json = {
  '1': 'SetQualityRequest',
  '2': [
    {
      '1': 'recording_quality',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'recordingQuality'
    },
    {'1': 'codec', '3': 2, '4': 1, '5': 9, '10': 'codec'},
    {
      '1': 'streaming_quality',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'streamingQuality'
    },
    {'1': 'fps', '3': 4, '4': 1, '5': 5, '10': 'fps'},
    {
      '1': 'recording_segment_minutes',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'recordingSegmentMinutes'
    },
  ],
};

/// Descriptor for `SetQualityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setQualityRequestDescriptor = $convert.base64Decode(
    'ChFTZXRRdWFsaXR5UmVxdWVzdBIrChFyZWNvcmRpbmdfcXVhbGl0eRgBIAEoCVIQcmVjb3JkaW'
    '5nUXVhbGl0eRIUCgVjb2RlYxgCIAEoCVIFY29kZWMSKwoRc3RyZWFtaW5nX3F1YWxpdHkYAyAB'
    'KAlSEHN0cmVhbWluZ1F1YWxpdHkSEAoDZnBzGAQgASgFUgNmcHMSOgoZcmVjb3JkaW5nX3NlZ2'
    '1lbnRfbWludXRlcxgFIAEoBVIXcmVjb3JkaW5nU2VnbWVudE1pbnV0ZXM=');

@$core.Deprecated('Use setQualityResponseDescriptor instead')
const SetQualityResponse$json = {
  '1': 'SetQualityResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'recording_quality',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'recordingQuality'
    },
    {'1': 'codec', '3': 3, '4': 1, '5': 9, '10': 'recordingCodec'},
    {'1': 'message', '3': 4, '4': 1, '5': 9, '10': 'message'},
    {'1': 'error', '3': 5, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetQualityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setQualityResponseDescriptor = $convert.base64Decode(
    'ChJTZXRRdWFsaXR5UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIrChFyZWNvcm'
    'RpbmdfcXVhbGl0eRgCIAEoCVIQcmVjb3JkaW5nUXVhbGl0eRIdCgVjb2RlYxgDIAEoCVIOcmVj'
    'b3JkaW5nQ29kZWMSGAoHbWVzc2FnZRgEIAEoCVIHbWVzc2FnZRIUCgVlcnJvchgFIAEoCVIFZX'
    'Jyb3I=');

@$core.Deprecated('Use getAppearanceRequestDescriptor instead')
const GetAppearanceRequest$json = {
  '1': 'GetAppearanceRequest',
};

/// Descriptor for `GetAppearanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAppearanceRequestDescriptor =
    $convert.base64Decode('ChRHZXRBcHBlYXJhbmNlUmVxdWVzdA==');

@$core.Deprecated('Use getAppearanceResponseDescriptor instead')
const GetAppearanceResponse$json = {
  '1': 'GetAppearanceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'theme', '3': 2, '4': 1, '5': 9, '10': 'theme'},
    {'1': 'locale', '3': 3, '4': 1, '5': 9, '10': 'locale'},
  ],
};

/// Descriptor for `GetAppearanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAppearanceResponseDescriptor = $convert.base64Decode(
    'ChVHZXRBcHBlYXJhbmNlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgV0aG'
    'VtZRgCIAEoCVIFdGhlbWUSFgoGbG9jYWxlGAMgASgJUgZsb2NhbGU=');

@$core.Deprecated('Use setAppearanceRequestDescriptor instead')
const SetAppearanceRequest$json = {
  '1': 'SetAppearanceRequest',
  '2': [
    {'1': 'theme', '3': 1, '4': 1, '5': 9, '10': 'theme'},
    {'1': 'locale', '3': 2, '4': 1, '5': 9, '10': 'locale'},
  ],
};

/// Descriptor for `SetAppearanceRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setAppearanceRequestDescriptor = $convert.base64Decode(
    'ChRTZXRBcHBlYXJhbmNlUmVxdWVzdBIUCgV0aGVtZRgBIAEoCVIFdGhlbWUSFgoGbG9jYWxlGA'
    'IgASgJUgZsb2NhbGU=');

@$core.Deprecated('Use setAppearanceResponseDescriptor instead')
const SetAppearanceResponse$json = {
  '1': 'SetAppearanceResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'theme', '3': 2, '4': 1, '5': 9, '10': 'theme'},
    {'1': 'locale', '3': 3, '4': 1, '5': 9, '10': 'locale'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetAppearanceResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setAppearanceResponseDescriptor = $convert.base64Decode(
    'ChVTZXRBcHBlYXJhbmNlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIUCgV0aG'
    'VtZRgCIAEoCVIFdGhlbWUSFgoGbG9jYWxlGAMgASgJUgZsb2NhbGUSFAoFZXJyb3IYBCABKAlS'
    'BWVycm9y');

@$core.Deprecated('Use getLocaleRequestDescriptor instead')
const GetLocaleRequest$json = {
  '1': 'GetLocaleRequest',
};

/// Descriptor for `GetLocaleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLocaleRequestDescriptor =
    $convert.base64Decode('ChBHZXRMb2NhbGVSZXF1ZXN0');

@$core.Deprecated('Use getLocaleResponseDescriptor instead')
const GetLocaleResponse$json = {
  '1': 'GetLocaleResponse',
  '2': [
    {'1': 'lang', '3': 1, '4': 1, '5': 9, '10': 'lang'},
    {
      '1': 'supported',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.GetLocaleResponse.SupportedEntry',
      '10': 'supported'
    },
  ],
  '3': [GetLocaleResponse_SupportedEntry$json],
};

@$core.Deprecated('Use getLocaleResponseDescriptor instead')
const GetLocaleResponse_SupportedEntry$json = {
  '1': 'SupportedEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `GetLocaleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLocaleResponseDescriptor = $convert.base64Decode(
    'ChFHZXRMb2NhbGVSZXNwb25zZRISCgRsYW5nGAEgASgJUgRsYW5nEk0KCXN1cHBvcnRlZBgCIA'
    'MoCzIvLmJsYWRld2F0Y2gudjEuR2V0TG9jYWxlUmVzcG9uc2UuU3VwcG9ydGVkRW50cnlSCXN1'
    'cHBvcnRlZBo8Cg5TdXBwb3J0ZWRFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIA'
    'EoCFIFdmFsdWU6AjgB');

@$core.Deprecated('Use setLocaleRequestDescriptor instead')
const SetLocaleRequest$json = {
  '1': 'SetLocaleRequest',
  '2': [
    {'1': 'lang', '3': 1, '4': 1, '5': 9, '10': 'lang'},
  ],
};

/// Descriptor for `SetLocaleRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLocaleRequestDescriptor = $convert
    .base64Decode('ChBTZXRMb2NhbGVSZXF1ZXN0EhIKBGxhbmcYASABKAlSBGxhbmc=');

@$core.Deprecated('Use setLocaleResponseDescriptor instead')
const SetLocaleResponse$json = {
  '1': 'SetLocaleResponse',
  '2': [
    {'1': 'lang', '3': 1, '4': 1, '5': 9, '10': 'lang'},
  ],
};

/// Descriptor for `SetLocaleResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLocaleResponseDescriptor = $convert
    .base64Decode('ChFTZXRMb2NhbGVSZXNwb25zZRISCgRsYW5nGAEgASgJUgRsYW5n');

@$core.Deprecated('Use setRecordingModeRequestDescriptor instead')
const SetRecordingModeRequest$json = {
  '1': 'SetRecordingModeRequest',
  '2': [
    {'1': 'mode', '3': 1, '4': 1, '5': 9, '10': 'mode'},
  ],
};

/// Descriptor for `SetRecordingModeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRecordingModeRequestDescriptor =
    $convert.base64Decode(
        'ChdTZXRSZWNvcmRpbmdNb2RlUmVxdWVzdBISCgRtb2RlGAEgASgJUgRtb2Rl');

@$core.Deprecated('Use setRecordingModeResponseDescriptor instead')
const SetRecordingModeResponse$json = {
  '1': 'SetRecordingModeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'mode', '3': 2, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetRecordingModeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRecordingModeResponseDescriptor =
    $convert.base64Decode(
        'ChhTZXRSZWNvcmRpbmdNb2RlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxISCg'
        'Rtb2RlGAIgASgJUgRtb2RlEhQKBWVycm9yGAMgASgJUgVlcnJvcg==');

const $core.Map<$core.String, $core.dynamic> SettingsServiceBase$json = {
  '1': 'SettingsService',
  '2': [
    {
      '1': 'GetQuality',
      '2': '.bladewatch.v1.GetQualityRequest',
      '3': '.bladewatch.v1.GetQualityResponse'
    },
    {
      '1': 'SetQuality',
      '2': '.bladewatch.v1.SetQualityRequest',
      '3': '.bladewatch.v1.SetQualityResponse'
    },
    {
      '1': 'GetAppearance',
      '2': '.bladewatch.v1.GetAppearanceRequest',
      '3': '.bladewatch.v1.GetAppearanceResponse'
    },
    {
      '1': 'SetAppearance',
      '2': '.bladewatch.v1.SetAppearanceRequest',
      '3': '.bladewatch.v1.SetAppearanceResponse'
    },
    {
      '1': 'GetLocale',
      '2': '.bladewatch.v1.GetLocaleRequest',
      '3': '.bladewatch.v1.GetLocaleResponse'
    },
    {
      '1': 'SetLocale',
      '2': '.bladewatch.v1.SetLocaleRequest',
      '3': '.bladewatch.v1.SetLocaleResponse'
    },
    {
      '1': 'SetRecordingMode',
      '2': '.bladewatch.v1.SetRecordingModeRequest',
      '3': '.bladewatch.v1.SetRecordingModeResponse'
    },
  ],
};

@$core.Deprecated('Use settingsServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    SettingsServiceBase$messageJson = {
  '.bladewatch.v1.GetQualityRequest': GetQualityRequest$json,
  '.bladewatch.v1.GetQualityResponse': GetQualityResponse$json,
  '.bladewatch.v1.GetQualityResponse.RecordingQualityOptionsEntry':
      GetQualityResponse_RecordingQualityOptionsEntry$json,
  '.bladewatch.v1.QualityTierInfo': QualityTierInfo$json,
  '.bladewatch.v1.ActiveRecordingEstimate': ActiveRecordingEstimate$json,
  '.bladewatch.v1.GetQualityResponse.CodecOptionsEntry':
      GetQualityResponse_CodecOptionsEntry$json,
  '.bladewatch.v1.GetQualityResponse.FpsOptionsEntry':
      GetQualityResponse_FpsOptionsEntry$json,
  '.bladewatch.v1.SetQualityRequest': SetQualityRequest$json,
  '.bladewatch.v1.SetQualityResponse': SetQualityResponse$json,
  '.bladewatch.v1.GetAppearanceRequest': GetAppearanceRequest$json,
  '.bladewatch.v1.GetAppearanceResponse': GetAppearanceResponse$json,
  '.bladewatch.v1.SetAppearanceRequest': SetAppearanceRequest$json,
  '.bladewatch.v1.SetAppearanceResponse': SetAppearanceResponse$json,
  '.bladewatch.v1.GetLocaleRequest': GetLocaleRequest$json,
  '.bladewatch.v1.GetLocaleResponse': GetLocaleResponse$json,
  '.bladewatch.v1.GetLocaleResponse.SupportedEntry':
      GetLocaleResponse_SupportedEntry$json,
  '.bladewatch.v1.SetLocaleRequest': SetLocaleRequest$json,
  '.bladewatch.v1.SetLocaleResponse': SetLocaleResponse$json,
  '.bladewatch.v1.SetRecordingModeRequest': SetRecordingModeRequest$json,
  '.bladewatch.v1.SetRecordingModeResponse': SetRecordingModeResponse$json,
};

/// Descriptor for `SettingsService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List settingsServiceDescriptor = $convert.base64Decode(
    'Cg9TZXR0aW5nc1NlcnZpY2USUQoKR2V0UXVhbGl0eRIgLmJsYWRld2F0Y2gudjEuR2V0UXVhbG'
    'l0eVJlcXVlc3QaIS5ibGFkZXdhdGNoLnYxLkdldFF1YWxpdHlSZXNwb25zZRJRCgpTZXRRdWFs'
    'aXR5EiAuYmxhZGV3YXRjaC52MS5TZXRRdWFsaXR5UmVxdWVzdBohLmJsYWRld2F0Y2gudjEuU2'
    'V0UXVhbGl0eVJlc3BvbnNlEloKDUdldEFwcGVhcmFuY2USIy5ibGFkZXdhdGNoLnYxLkdldEFw'
    'cGVhcmFuY2VSZXF1ZXN0GiQuYmxhZGV3YXRjaC52MS5HZXRBcHBlYXJhbmNlUmVzcG9uc2USWg'
    'oNU2V0QXBwZWFyYW5jZRIjLmJsYWRld2F0Y2gudjEuU2V0QXBwZWFyYW5jZVJlcXVlc3QaJC5i'
    'bGFkZXdhdGNoLnYxLlNldEFwcGVhcmFuY2VSZXNwb25zZRJOCglHZXRMb2NhbGUSHy5ibGFkZX'
    'dhdGNoLnYxLkdldExvY2FsZVJlcXVlc3QaIC5ibGFkZXdhdGNoLnYxLkdldExvY2FsZVJlc3Bv'
    'bnNlEk4KCVNldExvY2FsZRIfLmJsYWRld2F0Y2gudjEuU2V0TG9jYWxlUmVxdWVzdBogLmJsYW'
    'Rld2F0Y2gudjEuU2V0TG9jYWxlUmVzcG9uc2USYwoQU2V0UmVjb3JkaW5nTW9kZRImLmJsYWRl'
    'd2F0Y2gudjEuU2V0UmVjb3JkaW5nTW9kZVJlcXVlc3QaJy5ibGFkZXdhdGNoLnYxLlNldFJlY2'
    '9yZGluZ01vZGVSZXNwb25zZQ==');
