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

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor =
    $convert.base64Decode('CgxMb2dpblJlcXVlc3QSFAoFdG9rZW4YASABKAlSBXRva2Vu');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'expires_in', '3': 3, '4': 1, '5': 3, '10': 'expiresIn'},
    {'1': 'error', '3': 4, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert.base64Decode(
    'Cg1Mb2dpblJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSGwoJZGV2aWNlX2lkGA'
    'IgASgJUghkZXZpY2VJZBIdCgpleHBpcmVzX2luGAMgASgDUglleHBpcmVzSW4SFAoFZXJyb3IY'
    'BCABKAlSBWVycm9y');

@$core.Deprecated('Use logoutRequestDescriptor instead')
const LogoutRequest$json = {
  '1': 'LogoutRequest',
};

/// Descriptor for `LogoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutRequestDescriptor =
    $convert.base64Decode('Cg1Mb2dvdXRSZXF1ZXN0');

@$core.Deprecated('Use logoutResponseDescriptor instead')
const LogoutResponse$json = {
  '1': 'LogoutResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `LogoutResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutResponseDescriptor = $convert.base64Decode(
    'Cg5Mb2dvdXRSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEhgKB21lc3NhZ2UYAi'
    'ABKAlSB21lc3NhZ2U=');

@$core.Deprecated('Use getAuthStatusRequestDescriptor instead')
const GetAuthStatusRequest$json = {
  '1': 'GetAuthStatusRequest',
};

/// Descriptor for `GetAuthStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAuthStatusRequestDescriptor =
    $convert.base64Decode('ChRHZXRBdXRoU3RhdHVzUmVxdWVzdA==');

@$core.Deprecated('Use getAuthStatusResponseDescriptor instead')
const GetAuthStatusResponse$json = {
  '1': 'GetAuthStatusResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
  ],
};

/// Descriptor for `GetAuthStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAuthStatusResponseDescriptor = $convert.base64Decode(
    'ChVHZXRBdXRoU3RhdHVzUmVzcG9uc2USFgoGc3RhdHVzGAEgASgJUgZzdGF0dXMSGwoJZGV2aW'
    'NlX2lkGAIgASgJUghkZXZpY2VJZA==');

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
      '1': 'Login',
      '2': '.bladewatch.v1.LoginRequest',
      '3': '.bladewatch.v1.LoginResponse'
    },
    {
      '1': 'Logout',
      '2': '.bladewatch.v1.LogoutRequest',
      '3': '.bladewatch.v1.LogoutResponse'
    },
    {
      '1': 'GetAuthStatus',
      '2': '.bladewatch.v1.GetAuthStatusRequest',
      '3': '.bladewatch.v1.GetAuthStatusResponse'
    },
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
  '.bladewatch.v1.LoginRequest': LoginRequest$json,
  '.bladewatch.v1.LoginResponse': LoginResponse$json,
  '.bladewatch.v1.LogoutRequest': LogoutRequest$json,
  '.bladewatch.v1.LogoutResponse': LogoutResponse$json,
  '.bladewatch.v1.GetAuthStatusRequest': GetAuthStatusRequest$json,
  '.bladewatch.v1.GetAuthStatusResponse': GetAuthStatusResponse$json,
  '.bladewatch.v1.InvalidateAuthCacheRequest': InvalidateAuthCacheRequest$json,
  '.bladewatch.v1.InvalidateAuthCacheResponse':
      InvalidateAuthCacheResponse$json,
};

/// Descriptor for `AuthService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List authServiceDescriptor = $convert.base64Decode(
    'CgtBdXRoU2VydmljZRJCCgVMb2dpbhIbLmJsYWRld2F0Y2gudjEuTG9naW5SZXF1ZXN0GhwuYm'
    'xhZGV3YXRjaC52MS5Mb2dpblJlc3BvbnNlEkUKBkxvZ291dBIcLmJsYWRld2F0Y2gudjEuTG9n'
    'b3V0UmVxdWVzdBodLmJsYWRld2F0Y2gudjEuTG9nb3V0UmVzcG9uc2USWgoNR2V0QXV0aFN0YX'
    'R1cxIjLmJsYWRld2F0Y2gudjEuR2V0QXV0aFN0YXR1c1JlcXVlc3QaJC5ibGFkZXdhdGNoLnYx'
    'LkdldEF1dGhTdGF0dXNSZXNwb25zZRJsChNJbnZhbGlkYXRlQXV0aENhY2hlEikuYmxhZGV3YX'
    'RjaC52MS5JbnZhbGlkYXRlQXV0aENhY2hlUmVxdWVzdBoqLmJsYWRld2F0Y2gudjEuSW52YWxp'
    'ZGF0ZUF1dGhDYWNoZVJlc3BvbnNl');
