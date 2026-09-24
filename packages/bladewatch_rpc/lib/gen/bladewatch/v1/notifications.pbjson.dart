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

@$core.Deprecated('Use quietHoursPrefDescriptor instead')
const QuietHoursPref$json = {
  '1': 'QuietHoursPref',
  '2': [
    {'1': 'start_min', '3': 1, '4': 1, '5': 5, '10': 'startMin'},
    {'1': 'end_min', '3': 2, '4': 1, '5': 5, '10': 'endMin'},
    {'1': 'allow_critical', '3': 3, '4': 1, '5': 8, '10': 'allowCritical'},
  ],
};

/// Descriptor for `QuietHoursPref`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List quietHoursPrefDescriptor = $convert.base64Decode(
    'Cg5RdWlldEhvdXJzUHJlZhIbCglzdGFydF9taW4YASABKAVSCHN0YXJ0TWluEhcKB2VuZF9taW'
    '4YAiABKAVSBmVuZE1pbhIlCg5hbGxvd19jcml0aWNhbBgDIAEoCFINYWxsb3dDcml0aWNhbA==');

@$core.Deprecated('Use pushKeysDescriptor instead')
const PushKeys$json = {
  '1': 'PushKeys',
  '2': [
    {'1': 'p256dh', '3': 1, '4': 1, '5': 9, '10': 'p256dh'},
    {'1': 'auth', '3': 2, '4': 1, '5': 9, '10': 'auth'},
  ],
};

/// Descriptor for `PushKeys`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushKeysDescriptor = $convert.base64Decode(
    'CghQdXNoS2V5cxIWCgZwMjU2ZGgYASABKAlSBnAyNTZkaBISCgRhdXRoGAIgASgJUgRhdXRo');

@$core.Deprecated('Use pushSubscriptionRecordDescriptor instead')
const PushSubscriptionRecord$json = {
  '1': 'PushSubscriptionRecord',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'created_at', '3': 3, '4': 1, '5': 3, '10': 'createdAt'},
    {'1': 'last_seen_at', '3': 4, '4': 1, '5': 3, '10': 'lastSeenAt'},
    {'1': 'min_severity', '3': 5, '4': 1, '5': 9, '10': 'minSeverity'},
    {'1': 'muted_categories', '3': 6, '4': 3, '5': 9, '10': 'mutedCategories'},
    {
      '1': 'quiet_hours',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.QuietHoursPref',
      '10': 'quietHours'
    },
  ],
};

/// Descriptor for `PushSubscriptionRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushSubscriptionRecordDescriptor = $convert.base64Decode(
    'ChZQdXNoU3Vic2NyaXB0aW9uUmVjb3JkEg4KAmlkGAEgASgJUgJpZBIUCgVsYWJlbBgCIAEoCV'
    'IFbGFiZWwSHQoKY3JlYXRlZF9hdBgDIAEoA1IJY3JlYXRlZEF0EiAKDGxhc3Rfc2Vlbl9hdBgE'
    'IAEoA1IKbGFzdFNlZW5BdBIhCgxtaW5fc2V2ZXJpdHkYBSABKAlSC21pblNldmVyaXR5EikKEG'
    '11dGVkX2NhdGVnb3JpZXMYBiADKAlSD211dGVkQ2F0ZWdvcmllcxI+CgtxdWlldF9ob3VycxgH'
    'IAEoCzIdLmJsYWRld2F0Y2gudjEuUXVpZXRIb3Vyc1ByZWZSCnF1aWV0SG91cnM=');

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
    {'1': 'vapid_public_key', '3': 2, '4': 1, '5': 9, '10': 'vapidPublicKey'},
  ],
};

/// Descriptor for `GetCategoriesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCategoriesResponseDescriptor = $convert.base64Decode(
    'ChVHZXRDYXRlZ29yaWVzUmVzcG9uc2USJwoPY2F0ZWdvcmllc19qc29uGAEgASgJUg5jYXRlZ2'
    '9yaWVzSnNvbhIoChB2YXBpZF9wdWJsaWNfa2V5GAIgASgJUg52YXBpZFB1YmxpY0tleQ==');

@$core.Deprecated('Use subscribeRequestDescriptor instead')
const SubscribeRequest$json = {
  '1': 'SubscribeRequest',
  '2': [
    {'1': 'endpoint', '3': 1, '4': 1, '5': 9, '10': 'endpoint'},
    {
      '1': 'keys',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.PushKeys',
      '10': 'keys'
    },
    {'1': 'label', '3': 3, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `SubscribeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeRequestDescriptor = $convert.base64Decode(
    'ChBTdWJzY3JpYmVSZXF1ZXN0EhoKCGVuZHBvaW50GAEgASgJUghlbmRwb2ludBIrCgRrZXlzGA'
    'IgASgLMhcuYmxhZGV3YXRjaC52MS5QdXNoS2V5c1IEa2V5cxIUCgVsYWJlbBgDIAEoCVIFbGFi'
    'ZWw=');

@$core.Deprecated('Use subscribeResponseDescriptor instead')
const SubscribeResponse$json = {
  '1': 'SubscribeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
    {'1': 'error', '3': 3, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `SubscribeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscribeResponseDescriptor = $convert.base64Decode(
    'ChFTdWJzY3JpYmVSZXNwb25zZRIYCgdzdWNjZXNzGAEgASgIUgdzdWNjZXNzEg4KAmlkGAIgAS'
    'gJUgJpZBIUCgVlcnJvchgDIAEoCVIFZXJyb3I=');

@$core.Deprecated('Use unsubscribeRequestDescriptor instead')
const UnsubscribeRequest$json = {
  '1': 'UnsubscribeRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'endpoint', '3': 2, '4': 1, '5': 9, '10': 'endpoint'},
  ],
};

/// Descriptor for `UnsubscribeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unsubscribeRequestDescriptor = $convert.base64Decode(
    'ChJVbnN1YnNjcmliZVJlcXVlc3QSDgoCaWQYASABKAlSAmlkEhoKCGVuZHBvaW50GAIgASgJUg'
    'hlbmRwb2ludA==');

@$core.Deprecated('Use unsubscribeResponseDescriptor instead')
const UnsubscribeResponse$json = {
  '1': 'UnsubscribeResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
  ],
};

/// Descriptor for `UnsubscribeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List unsubscribeResponseDescriptor =
    $convert.base64Decode(
        'ChNVbnN1YnNjcmliZVJlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3M=');

@$core.Deprecated('Use listSubscriptionsRequestDescriptor instead')
const ListSubscriptionsRequest$json = {
  '1': 'ListSubscriptionsRequest',
};

/// Descriptor for `ListSubscriptionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSubscriptionsRequestDescriptor =
    $convert.base64Decode('ChhMaXN0U3Vic2NyaXB0aW9uc1JlcXVlc3Q=');

@$core.Deprecated('Use listSubscriptionsResponseDescriptor instead')
const ListSubscriptionsResponse$json = {
  '1': 'ListSubscriptionsResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {
      '1': 'subscriptions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.bladewatch.v1.PushSubscriptionRecord',
      '10': 'subscriptions'
    },
  ],
};

/// Descriptor for `ListSubscriptionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSubscriptionsResponseDescriptor = $convert.base64Decode(
    'ChlMaXN0U3Vic2NyaXB0aW9uc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSSw'
    'oNc3Vic2NyaXB0aW9ucxgCIAMoCzIlLmJsYWRld2F0Y2gudjEuUHVzaFN1YnNjcmlwdGlvblJl'
    'Y29yZFINc3Vic2NyaXB0aW9ucw==');

@$core.Deprecated('Use updatePreferencesRequestDescriptor instead')
const UpdatePreferencesRequest$json = {
  '1': 'UpdatePreferencesRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'muted_categories', '3': 2, '4': 3, '5': 9, '10': 'mutedCategories'},
    {'1': 'min_severity', '3': 3, '4': 1, '5': 9, '10': 'minSeverity'},
    {
      '1': 'quiet_hours',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.bladewatch.v1.QuietHoursPref',
      '10': 'quietHours'
    },
    {'1': 'has_quiet_hours', '3': 5, '4': 1, '5': 8, '10': 'hasQuietHours'},
  ],
};

/// Descriptor for `UpdatePreferencesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePreferencesRequestDescriptor = $convert.base64Decode(
    'ChhVcGRhdGVQcmVmZXJlbmNlc1JlcXVlc3QSDgoCaWQYASABKAlSAmlkEikKEG11dGVkX2NhdG'
    'Vnb3JpZXMYAiADKAlSD211dGVkQ2F0ZWdvcmllcxIhCgxtaW5fc2V2ZXJpdHkYAyABKAlSC21p'
    'blNldmVyaXR5Ej4KC3F1aWV0X2hvdXJzGAQgASgLMh0uYmxhZGV3YXRjaC52MS5RdWlldEhvdX'
    'JzUHJlZlIKcXVpZXRIb3VycxImCg9oYXNfcXVpZXRfaG91cnMYBSABKAhSDWhhc1F1aWV0SG91'
    'cnM=');

@$core.Deprecated('Use updatePreferencesResponseDescriptor instead')
const UpdatePreferencesResponse$json = {
  '1': 'UpdatePreferencesResponse',
  '2': [
    {'1': 'success', '3': 1, '4': 1, '5': 8, '10': 'success'},
    {'1': 'error', '3': 2, '4': 1, '5': 9, '10': 'error'},
  ],
};

/// Descriptor for `UpdatePreferencesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePreferencesResponseDescriptor =
    $convert.base64Decode(
        'ChlVcGRhdGVQcmVmZXJlbmNlc1Jlc3BvbnNlEhgKB3N1Y2Nlc3MYASABKAhSB3N1Y2Nlc3MSFA'
        'oFZXJyb3IYAiABKAlSBWVycm9y');

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
      '1': 'Subscribe',
      '2': '.bladewatch.v1.SubscribeRequest',
      '3': '.bladewatch.v1.SubscribeResponse'
    },
    {
      '1': 'Unsubscribe',
      '2': '.bladewatch.v1.UnsubscribeRequest',
      '3': '.bladewatch.v1.UnsubscribeResponse'
    },
    {
      '1': 'ListSubscriptions',
      '2': '.bladewatch.v1.ListSubscriptionsRequest',
      '3': '.bladewatch.v1.ListSubscriptionsResponse'
    },
    {
      '1': 'UpdatePreferences',
      '2': '.bladewatch.v1.UpdatePreferencesRequest',
      '3': '.bladewatch.v1.UpdatePreferencesResponse'
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
  '.bladewatch.v1.SubscribeRequest': SubscribeRequest$json,
  '.bladewatch.v1.PushKeys': PushKeys$json,
  '.bladewatch.v1.SubscribeResponse': SubscribeResponse$json,
  '.bladewatch.v1.UnsubscribeRequest': UnsubscribeRequest$json,
  '.bladewatch.v1.UnsubscribeResponse': UnsubscribeResponse$json,
  '.bladewatch.v1.ListSubscriptionsRequest': ListSubscriptionsRequest$json,
  '.bladewatch.v1.ListSubscriptionsResponse': ListSubscriptionsResponse$json,
  '.bladewatch.v1.PushSubscriptionRecord': PushSubscriptionRecord$json,
  '.bladewatch.v1.QuietHoursPref': QuietHoursPref$json,
  '.bladewatch.v1.UpdatePreferencesRequest': UpdatePreferencesRequest$json,
  '.bladewatch.v1.UpdatePreferencesResponse': UpdatePreferencesResponse$json,
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
    'bnNlEk4KCVN1YnNjcmliZRIfLmJsYWRld2F0Y2gudjEuU3Vic2NyaWJlUmVxdWVzdBogLmJsYW'
    'Rld2F0Y2gudjEuU3Vic2NyaWJlUmVzcG9uc2USVAoLVW5zdWJzY3JpYmUSIS5ibGFkZXdhdGNo'
    'LnYxLlVuc3Vic2NyaWJlUmVxdWVzdBoiLmJsYWRld2F0Y2gudjEuVW5zdWJzY3JpYmVSZXNwb2'
    '5zZRJmChFMaXN0U3Vic2NyaXB0aW9ucxInLmJsYWRld2F0Y2gudjEuTGlzdFN1YnNjcmlwdGlv'
    'bnNSZXF1ZXN0GiguYmxhZGV3YXRjaC52MS5MaXN0U3Vic2NyaXB0aW9uc1Jlc3BvbnNlEmYKEV'
    'VwZGF0ZVByZWZlcmVuY2VzEicuYmxhZGV3YXRjaC52MS5VcGRhdGVQcmVmZXJlbmNlc1JlcXVl'
    'c3QaKC5ibGFkZXdhdGNoLnYxLlVwZGF0ZVByZWZlcmVuY2VzUmVzcG9uc2USSwoIU2VuZFRlc3'
    'QSHi5ibGFkZXdhdGNoLnYxLlNlbmRUZXN0UmVxdWVzdBofLmJsYWRld2F0Y2gudjEuU2VuZFRl'
    'c3RSZXNwb25zZRJOCglMaXN0SW5ib3gSHy5ibGFkZXdhdGNoLnYxLkxpc3RJbmJveFJlcXVlc3'
    'QaIC5ibGFkZXdhdGNoLnYxLkxpc3RJbmJveFJlc3BvbnNl');
