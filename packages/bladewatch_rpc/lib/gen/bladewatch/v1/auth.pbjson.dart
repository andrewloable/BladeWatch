// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/auth.proto.

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

@$core.Deprecated('Use invalidateAuthCacheRequestDescriptor instead')
const InvalidateAuthCacheRequest$json = {
  '1': 'InvalidateAuthCacheRequest',
};

/// Descriptor for `InvalidateAuthCacheRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invalidateAuthCacheRequestDescriptor =
    $convert.base64Decode('ChpJbnZhbGlkYXRlQXV0aENhY2hlUmVxdWVzdA==');

@$core.Deprecated('Use invalidateAuthCacheResponseDescriptor instead')
const InvalidateAuthCacheResponse$json = {
  '1': 'InvalidateAuthCacheResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `InvalidateAuthCacheResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invalidateAuthCacheResponseDescriptor =
    $convert.base64Decode(
        'ChtJbnZhbGlkYXRlQXV0aENhY2hlUmVzcG9uc2USGAoHc3VjY2VzcxgBIAEoCFIHc3VjY2Vzcw'
        '==');

const $core.Map<$core.String, $core.dynamic> AuthServiceBase$json = {
  '1': 'AuthService',
  '2': [
    {
      '1': 'InvalidateAuthCache',
      '2': '.bladewatch.v1.InvalidateAuthCacheRequest',
      '3': '.bladewatch.v1.InvalidateAuthCacheResponse'
    },
  ],
};

@$core.Deprecated('Use authServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    AuthServiceBase$messageJson = {
  '.bladewatch.v1.InvalidateAuthCacheRequest': InvalidateAuthCacheRequest$json,
  '.bladewatch.v1.InvalidateAuthCacheResponse':
      InvalidateAuthCacheResponse$json,
};

/// Descriptor for `AuthService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List authServiceDescriptor = $convert.base64Decode(
    'CgtBdXRoU2VydmljZRJsChNJbnZhbGlkYXRlQXV0aENhY2hlEikuYmxhZGV3YXRjaC52MS5Jbn'
    'ZhbGlkYXRlQXV0aENhY2hlUmVxdWVzdBoqLmJsYWRld2F0Y2gudjEuSW52YWxpZGF0ZUF1dGhD'
    'YWNoZVJlc3BvbnNl');
