// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/stream.proto.

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

@$core.Deprecated('Use streamingQualityDescriptor instead')
const StreamingQuality$json = {
  '1': 'StreamingQuality',
  '2': [
    {'1': 'STREAMING_QUALITY_UNSPECIFIED', '2': 0},
    {'1': 'STREAMING_QUALITY_ULTRA_LOW', '2': 1},
    {'1': 'STREAMING_QUALITY_LOW', '2': 2},
    {'1': 'STREAMING_QUALITY_MEDIUM', '2': 3},
    {'1': 'STREAMING_QUALITY_HIGH', '2': 4},
    {'1': 'STREAMING_QUALITY_ULTRA_HIGH', '2': 5},
    {'1': 'STREAMING_QUALITY_SMOOTH', '2': 6},
    {'1': 'STREAMING_QUALITY_MAX', '2': 7},
  ],
};

/// Descriptor for `StreamingQuality`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List streamingQualityDescriptor = $convert.base64Decode(
    'ChBTdHJlYW1pbmdRdWFsaXR5EiEKHVNUUkVBTUlOR19RVUFMSVRZX1VOU1BFQ0lGSUVEEAASHw'
    'obU1RSRUFNSU5HX1FVQUxJVFlfVUxUUkFfTE9XEAESGQoVU1RSRUFNSU5HX1FVQUxJVFlfTE9X'
    'EAISHAoYU1RSRUFNSU5HX1FVQUxJVFlfTUVESVVNEAMSGgoWU1RSRUFNSU5HX1FVQUxJVFlfSE'
    'lHSBAEEiAKHFNUUkVBTUlOR19RVUFMSVRZX1VMVFJBX0hJR0gQBRIcChhTVFJFQU1JTkdfUVVB'
    'TElUWV9TTU9PVEgQBhIZChVTVFJFQU1JTkdfUVVBTElUWV9NQVgQBw==');

@$core.Deprecated('Use viewModeDescriptor instead')
const ViewMode$json = {
  '1': 'ViewMode',
  '2': [
    {'1': 'VIEW_MODE_MOSAIC', '2': 0},
    {'1': 'VIEW_MODE_FRONT', '2': 1},
    {'1': 'VIEW_MODE_RIGHT', '2': 2},
    {'1': 'VIEW_MODE_REAR', '2': 3},
    {'1': 'VIEW_MODE_LEFT', '2': 4},
    {'1': 'VIEW_MODE_RAW', '2': 5},
  ],
};

/// Descriptor for `ViewMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List viewModeDescriptor = $convert.base64Decode(
    'CghWaWV3TW9kZRIUChBWSUVXX01PREVfTU9TQUlDEAASEwoPVklFV19NT0RFX0ZST05UEAESEw'
    'oPVklFV19NT0RFX1JJR0hUEAISEgoOVklFV19NT0RFX1JFQVIQAxISCg5WSUVXX01PREVfTEVG'
    'VBAEEhEKDVZJRVdfTU9ERV9SQVcQBQ==');

@$core.Deprecated('Use qualityOptionDescriptor instead')
const QualityOption$json = {
  '1': 'QualityOption',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'width', '3': 3, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 5, '10': 'height'},
    {'1': 'fps', '3': 5, '4': 1, '5': 5, '10': 'fps'},
    {'1': 'bitrate', '3': 6, '4': 1, '5': 5, '10': 'bitrate'},
    {'1': 'bitrate_kbps', '3': 7, '4': 1, '5': 5, '10': 'bitrateKbps'},
  ],
};

/// Descriptor for `QualityOption`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List qualityOptionDescriptor = $convert.base64Decode(
    'Cg1RdWFsaXR5T3B0aW9uEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEhQKBX'
    'dpZHRoGAMgASgFUgV3aWR0aBIWCgZoZWlnaHQYBCABKAVSBmhlaWdodBIQCgNmcHMYBSABKAVS'
    'A2ZwcxIYCgdiaXRyYXRlGAYgASgFUgdiaXRyYXRlEiEKDGJpdHJhdGVfa2JwcxgHIAEoBVILYm'
    'l0cmF0ZUticHM=');

@$core.Deprecated('Use enableStreamRequestDescriptor instead')
const EnableStreamRequest$json = {
  '1': 'EnableStreamRequest',
};

/// Descriptor for `EnableStreamRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enableStreamRequestDescriptor =
    $convert.base64Decode('ChNFbmFibGVTdHJlYW1SZXF1ZXN0');

@$core.Deprecated('Use enableStreamResponseDescriptor instead')
const EnableStreamResponse$json = {
  '1': 'EnableStreamResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
    {'1': 'ws_port', '3': 3, '4': 1, '5': 5, '10': 'wsPort'},
    {'1': 'quality', '3': 4, '4': 1, '5': 9, '10': 'quality'},
    {'1': 'resolution', '3': 5, '4': 1, '5': 9, '10': 'resolution'},
    {'1': 'fps', '3': 6, '4': 1, '5': 5, '10': 'fps'},
    {'1': 'bitrate', '3': 7, '4': 1, '5': 5, '10': 'bitrate'},
    {'1': 'error', '3': 8, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `EnableStreamResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enableStreamResponseDescriptor = $convert.base64Decode(
    'ChRFbmFibGVTdHJlYW1SZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3'
    'NhZ2UYAiABKAlSB21lc3NhZ2USFwoHd3NfcG9ydBgDIAEoBVIGd3NQb3J0EhgKB3F1YWxpdHkY'
    'BCABKAlSB3F1YWxpdHkSHgoKcmVzb2x1dGlvbhgFIAEoCVIKcmVzb2x1dGlvbhIQCgNmcHMYBi'
    'ABKAVSA2ZwcxIYCgdiaXRyYXRlGAcgASgFUgdiaXRyYXRlEhQKBWVycm9yGAggASgJUgVlcnJv'
    'cg==');

@$core.Deprecated('Use disableStreamRequestDescriptor instead')
const DisableStreamRequest$json = {
  '1': 'DisableStreamRequest',
};

/// Descriptor for `DisableStreamRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disableStreamRequestDescriptor =
    $convert.base64Decode('ChREaXNhYmxlU3RyZWFtUmVxdWVzdA==');

@$core.Deprecated('Use disableStreamResponseDescriptor instead')
const DisableStreamResponse$json = {
  '1': 'DisableStreamResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `DisableStreamResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disableStreamResponseDescriptor = $convert.base64Decode(
    'ChVEaXNhYmxlU3RyZWFtUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCgdtZX'
    'NzYWdlGAIgASgJUgdtZXNzYWdl');

@$core.Deprecated('Use getStreamStatusRequestDescriptor instead')
const GetStreamStatusRequest$json = {
  '1': 'GetStreamStatusRequest',
};

/// Descriptor for `GetStreamStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStreamStatusRequestDescriptor =
    $convert.base64Decode('ChZHZXRTdHJlYW1TdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use getStreamStatusResponseDescriptor instead')
const GetStreamStatusResponse$json = {
  '1': 'GetStreamStatusResponse',
  '2': [
    {'1': 'pipeline_running', '3': 1, '4': 1, '5': 8, '10': 'pipelineRunning'},
    {
      '1': 'streaming_enabled',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'streamingEnabled'
    },
    {'1': 'ws_port', '3': 3, '4': 1, '5': 5, '10': 'wsPort'},
    {'1': 'view_mode', '3': 4, '4': 1, '5': 5, '10': 'viewMode'},
    {'1': 'view_name', '3': 5, '4': 1, '5': 9, '10': 'viewName'},
  ],
};

/// Descriptor for `GetStreamStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStreamStatusResponseDescriptor = $convert.base64Decode(
    'ChdHZXRTdHJlYW1TdGF0dXNSZXNwb25zZRIpChBwaXBlbGluZV9ydW5uaW5nGAEgASgIUg9waX'
    'BlbGluZVJ1bm5pbmcSKwoRc3RyZWFtaW5nX2VuYWJsZWQYAiABKAhSEHN0cmVhbWluZ0VuYWJs'
    'ZWQSFwoHd3NfcG9ydBgDIAEoBVIGd3NQb3J0EhsKCXZpZXdfbW9kZRgEIAEoBVIIdmlld01vZG'
    'USGwoJdmlld19uYW1lGAUgASgJUgh2aWV3TmFtZQ==');

@$core.Deprecated('Use getStreamQualityRequestDescriptor instead')
const GetStreamQualityRequest$json = {
  '1': 'GetStreamQualityRequest',
};

/// Descriptor for `GetStreamQualityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStreamQualityRequestDescriptor =
    $convert.base64Decode('ChdHZXRTdHJlYW1RdWFsaXR5UmVxdWVzdA==');

@$core.Deprecated('Use getStreamQualityResponseDescriptor instead')
const GetStreamQualityResponse$json = {
  '1': 'GetStreamQualityResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'current', '3': 2, '4': 1, '5': 9, '10': 'current'},
    {
      '1': 'options',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.QualityOption',
      '10': 'options'
    },
  ],
};

/// Descriptor for `GetStreamQualityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStreamQualityResponseDescriptor = $convert.base64Decode(
    'ChhHZXRTdHJlYW1RdWFsaXR5UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCg'
    'djdXJyZW50GAIgASgJUgdjdXJyZW50EjYKB29wdGlvbnMYAyADKAsyHC5ibGFkZXdhdGNoLnYx'
    'LlF1YWxpdHlPcHRpb25SB29wdGlvbnM=');

@$core.Deprecated('Use setStreamQualityRequestDescriptor instead')
const SetStreamQualityRequest$json = {
  '1': 'SetStreamQualityRequest',
  '2': [
    {'1': 'quality', '3': 1, '4': 1, '5': 9, '10': 'quality'},
  ],
};

/// Descriptor for `SetStreamQualityRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setStreamQualityRequestDescriptor =
    $convert.base64Decode(
        'ChdTZXRTdHJlYW1RdWFsaXR5UmVxdWVzdBIYCgdxdWFsaXR5GAEgASgJUgdxdWFsaXR5');

@$core.Deprecated('Use setStreamQualityResponseDescriptor instead')
const SetStreamQualityResponse$json = {
  '1': 'SetStreamQualityResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'quality', '3': 2, '4': 1, '5': 9, '10': 'quality'},
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'width', '3': 4, '4': 1, '5': 5, '10': 'width'},
    {'1': 'height', '3': 5, '4': 1, '5': 5, '10': 'height'},
    {'1': 'fps', '3': 6, '4': 1, '5': 5, '10': 'fps'},
    {'1': 'bitrate', '3': 7, '4': 1, '5': 5, '10': 'bitrate'},
  ],
};

/// Descriptor for `SetStreamQualityResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setStreamQualityResponseDescriptor = $convert.base64Decode(
    'ChhTZXRTdHJlYW1RdWFsaXR5UmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2VzcxIYCg'
    'dxdWFsaXR5GAIgASgJUgdxdWFsaXR5EiEKDGRpc3BsYXlfbmFtZRgDIAEoCVILZGlzcGxheU5h'
    'bWUSFAoFd2lkdGgYBCABKAVSBXdpZHRoEhYKBmhlaWdodBgFIAEoBVIGaGVpZ2h0EhAKA2Zwcx'
    'gGIAEoBVIDZnBzEhgKB2JpdHJhdGUYByABKAVSB2JpdHJhdGU=');

@$core.Deprecated('Use setViewModeRequestDescriptor instead')
const SetViewModeRequest$json = {
  '1': 'SetViewModeRequest',
  '2': [
    {'1': 'view_mode', '3': 1, '4': 1, '5': 5, '10': 'viewMode'},
  ],
};

/// Descriptor for `SetViewModeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setViewModeRequestDescriptor =
    $convert.base64Decode(
        'ChJTZXRWaWV3TW9kZVJlcXVlc3QSGwoJdmlld19tb2RlGAEgASgFUgh2aWV3TW9kZQ==');

@$core.Deprecated('Use setViewModeResponseDescriptor instead')
const SetViewModeResponse$json = {
  '1': 'SetViewModeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'view_mode', '3': 2, '4': 1, '5': 5, '10': 'viewMode'},
    {'1': 'view_name', '3': 3, '4': 1, '5': 9, '10': 'viewName'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SetViewModeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setViewModeResponseDescriptor = $convert.base64Decode(
    'ChNTZXRWaWV3TW9kZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGwoJdmlld1'
    '9tb2RlGAIgASgFUgh2aWV3TW9kZRIbCgl2aWV3X25hbWUYAyABKAlSCHZpZXdOYW1lEhQKBWVy'
    'cm9yGAQgASgJUgVlcnJvcg==');

@$core.Deprecated('Use getViewModeRequestDescriptor instead')
const GetViewModeRequest$json = {
  '1': 'GetViewModeRequest',
};

/// Descriptor for `GetViewModeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getViewModeRequestDescriptor =
    $convert.base64Decode('ChJHZXRWaWV3TW9kZVJlcXVlc3Q=');

@$core.Deprecated('Use getViewModeResponseDescriptor instead')
const GetViewModeResponse$json = {
  '1': 'GetViewModeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'view_mode', '3': 2, '4': 1, '5': 5, '10': 'viewMode'},
    {'1': 'view_name', '3': 3, '4': 1, '5': 9, '10': 'viewName'},
  ],
};

/// Descriptor for `GetViewModeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getViewModeResponseDescriptor = $convert.base64Decode(
    'ChNHZXRWaWV3TW9kZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGwoJdmlld1'
    '9tb2RlGAIgASgFUgh2aWV3TW9kZRIbCgl2aWV3X25hbWUYAyABKAlSCHZpZXdOYW1l');

const $core.Map<$core.String, $core.dynamic> StreamServiceBase$json = {
  '1': 'StreamService',
  '2': [
    {
      '1': 'Enable',
      '2': '.bladewatch.v1.EnableStreamRequest',
      '3': '.bladewatch.v1.EnableStreamResponse'
    },
    {
      '1': 'Disable',
      '2': '.bladewatch.v1.DisableStreamRequest',
      '3': '.bladewatch.v1.DisableStreamResponse'
    },
    {
      '1': 'GetStatus',
      '2': '.bladewatch.v1.GetStreamStatusRequest',
      '3': '.bladewatch.v1.GetStreamStatusResponse'
    },
    {
      '1': 'GetQuality',
      '2': '.bladewatch.v1.GetStreamQualityRequest',
      '3': '.bladewatch.v1.GetStreamQualityResponse'
    },
    {
      '1': 'SetQuality',
      '2': '.bladewatch.v1.SetStreamQualityRequest',
      '3': '.bladewatch.v1.SetStreamQualityResponse'
    },
    {
      '1': 'SetViewMode',
      '2': '.bladewatch.v1.SetViewModeRequest',
      '3': '.bladewatch.v1.SetViewModeResponse'
    },
    {
      '1': 'GetViewMode',
      '2': '.bladewatch.v1.GetViewModeRequest',
      '3': '.bladewatch.v1.GetViewModeResponse'
    },
  ],
};

@$core.Deprecated('Use streamServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    StreamServiceBase$messageJson = {
  '.bladewatch.v1.EnableStreamRequest': EnableStreamRequest$json,
  '.bladewatch.v1.EnableStreamResponse': EnableStreamResponse$json,
  '.bladewatch.v1.DisableStreamRequest': DisableStreamRequest$json,
  '.bladewatch.v1.DisableStreamResponse': DisableStreamResponse$json,
  '.bladewatch.v1.GetStreamStatusRequest': GetStreamStatusRequest$json,
  '.bladewatch.v1.GetStreamStatusResponse': GetStreamStatusResponse$json,
  '.bladewatch.v1.GetStreamQualityRequest': GetStreamQualityRequest$json,
  '.bladewatch.v1.GetStreamQualityResponse': GetStreamQualityResponse$json,
  '.bladewatch.v1.QualityOption': QualityOption$json,
  '.bladewatch.v1.SetStreamQualityRequest': SetStreamQualityRequest$json,
  '.bladewatch.v1.SetStreamQualityResponse': SetStreamQualityResponse$json,
  '.bladewatch.v1.SetViewModeRequest': SetViewModeRequest$json,
  '.bladewatch.v1.SetViewModeResponse': SetViewModeResponse$json,
  '.bladewatch.v1.GetViewModeRequest': GetViewModeRequest$json,
  '.bladewatch.v1.GetViewModeResponse': GetViewModeResponse$json,
};

/// Descriptor for `StreamService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List streamServiceDescriptor = $convert.base64Decode(
    'Cg1TdHJlYW1TZXJ2aWNlElEKBkVuYWJsZRIiLmJsYWRld2F0Y2gudjEuRW5hYmxlU3RyZWFtUm'
    'VxdWVzdBojLmJsYWRld2F0Y2gudjEuRW5hYmxlU3RyZWFtUmVzcG9uc2USVAoHRGlzYWJsZRIj'
    'LmJsYWRld2F0Y2gudjEuRGlzYWJsZVN0cmVhbVJlcXVlc3QaJC5ibGFkZXdhdGNoLnYxLkRpc2'
    'FibGVTdHJlYW1SZXNwb25zZRJaCglHZXRTdGF0dXMSJS5ibGFkZXdhdGNoLnYxLkdldFN0cmVh'
    'bVN0YXR1c1JlcXVlc3QaJi5ibGFkZXdhdGNoLnYxLkdldFN0cmVhbVN0YXR1c1Jlc3BvbnNlEl'
    '0KCkdldFF1YWxpdHkSJi5ibGFkZXdhdGNoLnYxLkdldFN0cmVhbVF1YWxpdHlSZXF1ZXN0Gicu'
    'YmxhZGV3YXRjaC52MS5HZXRTdHJlYW1RdWFsaXR5UmVzcG9uc2USXQoKU2V0UXVhbGl0eRImLm'
    'JsYWRld2F0Y2gudjEuU2V0U3RyZWFtUXVhbGl0eVJlcXVlc3QaJy5ibGFkZXdhdGNoLnYxLlNl'
    'dFN0cmVhbVF1YWxpdHlSZXNwb25zZRJUCgtTZXRWaWV3TW9kZRIhLmJsYWRld2F0Y2gudjEuU2'
    'V0Vmlld01vZGVSZXF1ZXN0GiIuYmxhZGV3YXRjaC52MS5TZXRWaWV3TW9kZVJlc3BvbnNlElQK'
    'C0dldFZpZXdNb2RlEiEuYmxhZGV3YXRjaC52MS5HZXRWaWV3TW9kZVJlcXVlc3QaIi5ibGFkZX'
    'dhdGNoLnYxLkdldFZpZXdNb2RlUmVzcG9uc2U=');
