// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/notifications.proto.

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

@$core.Deprecated('Use notificationSeverityDescriptor instead')
const NotificationSeverity$json = {
  '1': 'NotificationSeverity',
  '2': [
    {'1': 'NOTIFICATION_SEVERITY_UNSPECIFIED', '2': 0},
    {'1': 'NOTIFICATION_SEVERITY_INFO', '2': 1},
    {'1': 'NOTIFICATION_SEVERITY_ALERT', '2': 2},
    {'1': 'NOTIFICATION_SEVERITY_CRITICAL', '2': 3},
  ],
};

/// Descriptor for `NotificationSeverity`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List notificationSeverityDescriptor = $convert.base64Decode(
    'ChROb3RpZmljYXRpb25TZXZlcml0eRIlCiFOT1RJRklDQVRJT05fU0VWRVJJVFlfVU5TUEVDSU'
    'ZJRUQQABIeChpOT1RJRklDQVRJT05fU0VWRVJJVFlfSU5GTxABEh8KG05PVElGSUNBVElPTl9T'
    'RVZFUklUWV9BTEVSVBACEiIKHk5PVElGSUNBVElPTl9TRVZFUklUWV9DUklUSUNBTBAD');

@$core.Deprecated('Use getCategoriesRequestDescriptor instead')
const GetCategoriesRequest$json = {
  '1': 'GetCategoriesRequest',
};

/// Descriptor for `GetCategoriesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCategoriesRequestDescriptor =
    $convert.base64Decode('ChRHZXRDYXRlZ29yaWVzUmVxdWVzdA==');

@$core.Deprecated('Use getCategoriesResponseDescriptor instead')
const GetCategoriesResponse$json = {
  '1': 'GetCategoriesResponse',
  '2': [
    {'1': 'categories_json', '3': 1, '4': 1, '5': 9, '10': 'categoriesJson'},
  ],
  '9': [
    {'1': 2, '2': 3},
  ],
  '10': ['vapid_public_key'],
};

/// Descriptor for `GetCategoriesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCategoriesResponseDescriptor = $convert.base64Decode(
    'ChVHZXRDYXRlZ29yaWVzUmVzcG9uc2USJwoPY2F0ZWdvcmllc19qc29uGAEgASgJUg5jYXRlZ2'
    '9yaWVzSnNvbkoECAIQA1IQdmFwaWRfcHVibGljX2tleQ==');

@$core.Deprecated('Use sendTestRequestDescriptor instead')
const SendTestRequest$json = {
  '1': 'SendTestRequest',
  '2': [
    {'1': 'category', '3': 1, '4': 1, '5': 9, '10': 'category'},
    {'1': 'severity', '3': 2, '4': 1, '5': 9, '10': 'severity'},
  ],
};

/// Descriptor for `SendTestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendTestRequestDescriptor = $convert.base64Decode(
    'Cg9TZW5kVGVzdFJlcXVlc3QSGgoIY2F0ZWdvcnkYASABKAlSCGNhdGVnb3J5EhoKCHNldmVyaX'
    'R5GAIgASgJUghzZXZlcml0eQ==');

@$core.Deprecated('Use sendTestResponseDescriptor instead')
const SendTestResponse$json = {
  '1': 'SendTestResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `SendTestResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendTestResponseDescriptor = $convert.base64Decode(
    'ChBTZW5kVGVzdFJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3M=');

@$core.Deprecated('Use inboxEntryDescriptor instead')
const InboxEntry$json = {
  '1': 'InboxEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'timestamp_ms', '3': 2, '4': 1, '5': 3, '10': 'timestampMs'},
    {'1': 'category', '3': 3, '4': 1, '5': 9, '10': 'category'},
    {
      '1': 'severity',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.bladewatch.v1.NotificationSeverity',
      '10': 'severity'
    },
    {'1': 'title', '3': 5, '4': 1, '5': 9, '10': 'title'},
    {'1': 'body', '3': 6, '4': 1, '5': 9, '10': 'body'},
    {'1': 'click_url', '3': 7, '4': 1, '5': 9, '10': 'clickUrl'},
    {'1': 'tag', '3': 8, '4': 1, '5': 9, '10': 'tag'},
  ],
};

/// Descriptor for `InboxEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inboxEntryDescriptor = $convert.base64Decode(
    'CgpJbmJveEVudHJ5Eg4KAmlkGAEgASgDUgJpZBIhCgx0aW1lc3RhbXBfbXMYAiABKANSC3RpbW'
    'VzdGFtcE1zEhoKCGNhdGVnb3J5GAMgASgJUghjYXRlZ29yeRI/CghzZXZlcml0eRgEIAEoDjIj'
    'LmJsYWRld2F0Y2gudjEuTm90aWZpY2F0aW9uU2V2ZXJpdHlSCHNldmVyaXR5EhQKBXRpdGxlGA'
    'UgASgJUgV0aXRsZRISCgRib2R5GAYgASgJUgRib2R5EhsKCWNsaWNrX3VybBgHIAEoCVIIY2xp'
    'Y2tVcmwSEAoDdGFnGAggASgJUgN0YWc=');

@$core.Deprecated('Use listInboxRequestDescriptor instead')
const ListInboxRequest$json = {
  '1': 'ListInboxRequest',
  '2': [
    {'1': 'after_id', '3': 1, '4': 1, '5': 3, '10': 'afterId'},
    {'1': 'limit', '3': 2, '4': 1, '5': 5, '10': 'limit'},
  ],
};

/// Descriptor for `ListInboxRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listInboxRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0SW5ib3hSZXF1ZXN0EhkKCGFmdGVyX2lkGAEgASgDUgdhZnRlcklkEhQKBWxpbWl0GA'
    'IgASgFUgVsaW1pdA==');

@$core.Deprecated('Use listInboxResponseDescriptor instead')
const ListInboxResponse$json = {
  '1': 'ListInboxResponse',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.InboxEntry',
      '10': 'entries'
    },
    {'1': 'latest_id', '3': 2, '4': 1, '5': 3, '10': 'latestId'},
    {'1': 'oldest_id', '3': 3, '4': 1, '5': 3, '10': 'oldestId'},
  ],
};

/// Descriptor for `ListInboxResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listInboxResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0SW5ib3hSZXNwb25zZRIzCgdlbnRyaWVzGAEgAygLMhkuYmxhZGV3YXRjaC52MS5Jbm'
    'JveEVudHJ5UgdlbnRyaWVzEhsKCWxhdGVzdF9pZBgCIAEoA1IIbGF0ZXN0SWQSGwoJb2xkZXN0'
    'X2lkGAMgASgDUghvbGRlc3RJZA==');

const $core.Map<$core.String, $core.dynamic> NotificationsServiceBase$json = {
  '1': 'NotificationsService',
  '2': [
    {
      '1': 'GetCategories',
      '2': '.bladewatch.v1.GetCategoriesRequest',
      '3': '.bladewatch.v1.GetCategoriesResponse'
    },
    {
      '1': 'SendTest',
      '2': '.bladewatch.v1.SendTestRequest',
      '3': '.bladewatch.v1.SendTestResponse'
    },
    {
      '1': 'ListInbox',
      '2': '.bladewatch.v1.ListInboxRequest',
      '3': '.bladewatch.v1.ListInboxResponse'
    },
  ],
};

@$core.Deprecated('Use notificationsServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    NotificationsServiceBase$messageJson = {
  '.bladewatch.v1.GetCategoriesRequest': GetCategoriesRequest$json,
  '.bladewatch.v1.GetCategoriesResponse': GetCategoriesResponse$json,
  '.bladewatch.v1.SendTestRequest': SendTestRequest$json,
  '.bladewatch.v1.SendTestResponse': SendTestResponse$json,
  '.bladewatch.v1.ListInboxRequest': ListInboxRequest$json,
  '.bladewatch.v1.ListInboxResponse': ListInboxResponse$json,
  '.bladewatch.v1.InboxEntry': InboxEntry$json,
};

/// Descriptor for `NotificationsService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List notificationsServiceDescriptor = $convert.base64Decode(
    'ChROb3RpZmljYXRpb25zU2VydmljZRJaCg1HZXRDYXRlZ29yaWVzEiMuYmxhZGV3YXRjaC52MS'
    '5HZXRDYXRlZ29yaWVzUmVxdWVzdBokLmJsYWRld2F0Y2gudjEuR2V0Q2F0ZWdvcmllc1Jlc3Bv'
    'bnNlEksKCFNlbmRUZXN0Eh4uYmxhZGV3YXRjaC52MS5TZW5kVGVzdFJlcXVlc3QaHy5ibGFkZX'
    'dhdGNoLnYxLlNlbmRUZXN0UmVzcG9uc2USTgoJTGlzdEluYm94Eh8uYmxhZGV3YXRjaC52MS5M'
    'aXN0SW5ib3hSZXF1ZXN0GiAuYmxhZGV3YXRjaC52MS5MaXN0SW5ib3hSZXNwb25zZQ==');
