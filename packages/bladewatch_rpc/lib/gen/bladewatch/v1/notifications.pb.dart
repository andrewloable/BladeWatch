// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/notifications.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pbenum.dart';

class GetCategoriesRequest extends $pb.GeneratedMessage {
  factory GetCategoriesRequest() => GetCategoriesRequest._();

  GetCategoriesRequest._();

  factory GetCategoriesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCategoriesRequest()..mergeFromBuffer(data, registry);
  factory GetCategoriesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCategoriesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCategoriesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetCategoriesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCategoriesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCategoriesRequest copyWith(void Function(GetCategoriesRequest) updates) =>
      super.copyWith((message) => updates(message as GetCategoriesRequest))
          as GetCategoriesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetCategoriesRequest() / GetCategoriesRequest.new instead')
  static GetCategoriesRequest create() => GetCategoriesRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetCategoriesRequest._();
  @$core.override
  GetCategoriesRequest createEmptyInstance() => GetCategoriesRequest._();
  @$core.pragma('dart2js:noInline')
  static GetCategoriesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCategoriesRequest>(
          GetCategoriesRequest.$_createMessage);
  static GetCategoriesRequest? _defaultInstance;
}

class GetCategoriesResponse extends $pb.GeneratedMessage {
  factory GetCategoriesResponse({
    $core.String? categoriesJson,
  }) {
    final result = GetCategoriesResponse._();
    if (categoriesJson != null) result.categoriesJson = categoriesJson;
    return result;
  }

  GetCategoriesResponse._();

  factory GetCategoriesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCategoriesResponse()..mergeFromBuffer(data, registry);
  factory GetCategoriesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetCategoriesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetCategoriesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetCategoriesResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'categoriesJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCategoriesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetCategoriesResponse copyWith(
          void Function(GetCategoriesResponse) updates) =>
      super.copyWith((message) => updates(message as GetCategoriesResponse))
          as GetCategoriesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetCategoriesResponse() / GetCategoriesResponse.new instead')
  static GetCategoriesResponse create() => GetCategoriesResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetCategoriesResponse._();
  @$core.override
  GetCategoriesResponse createEmptyInstance() => GetCategoriesResponse._();
  @$core.pragma('dart2js:noInline')
  static GetCategoriesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetCategoriesResponse>(
          GetCategoriesResponse.$_createMessage);
  static GetCategoriesResponse? _defaultInstance;

  /// Forwarded registry JSON blob from CategoryRegistry.rawJson().
  @$pb.TagNumber(1)
  $core.String get categoriesJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set categoriesJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategoriesJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategoriesJson() => $_clearField(1);
}

class SendTestRequest extends $pb.GeneratedMessage {
  factory SendTestRequest({
    $core.String? category,
    $core.String? severity,
  }) {
    final result = SendTestRequest._();
    if (category != null) result.category = category;
    if (severity != null) result.severity = severity;
    return result;
  }

  SendTestRequest._();

  factory SendTestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendTestRequest()..mergeFromBuffer(data, registry);
  factory SendTestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendTestRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendTestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SendTestRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'category')
    ..aOS(2, _omitFieldNames ? '' : 'severity')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendTestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendTestRequest copyWith(void Function(SendTestRequest) updates) =>
      super.copyWith((message) => updates(message as SendTestRequest))
          as SendTestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendTestRequest() / SendTestRequest.new instead')
  static SendTestRequest create() => SendTestRequest._();
  static $pb.GeneratedMessage $_createMessage() => SendTestRequest._();
  @$core.override
  SendTestRequest createEmptyInstance() => SendTestRequest._();
  @$core.pragma('dart2js:noInline')
  static SendTestRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendTestRequest>(
          SendTestRequest.$_createMessage);
  static SendTestRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get category => $_getSZ(0);
  @$pb.TagNumber(1)
  set category($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get severity => $_getSZ(1);
  @$pb.TagNumber(2)
  set severity($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeverity() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeverity() => $_clearField(2);
}

class SendTestResponse extends $pb.GeneratedMessage {
  factory SendTestResponse({
    $core.bool? success,
  }) {
    final result = SendTestResponse._();
    if (success != null) result.success = success;
    return result;
  }

  SendTestResponse._();

  factory SendTestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendTestResponse()..mergeFromBuffer(data, registry);
  factory SendTestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendTestResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendTestResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SendTestResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendTestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendTestResponse copyWith(void Function(SendTestResponse) updates) =>
      super.copyWith((message) => updates(message as SendTestResponse))
          as SendTestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendTestResponse() / SendTestResponse.new instead')
  static SendTestResponse create() => SendTestResponse._();
  static $pb.GeneratedMessage $_createMessage() => SendTestResponse._();
  @$core.override
  SendTestResponse createEmptyInstance() => SendTestResponse._();
  @$core.pragma('dart2js:noInline')
  static SendTestResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SendTestResponse>(
          SendTestResponse.$_createMessage);
  static SendTestResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

/// One notification the car raised, kept for companions (BladeWatch-rdtj.14).
class InboxEntry extends $pb.GeneratedMessage {
  factory InboxEntry({
    $fixnum.Int64? id,
    $fixnum.Int64? timestampMs,
    $core.String? category,
    NotificationSeverity? severity,
    $core.String? title,
    $core.String? body,
    $core.String? clickUrl,
    $core.String? tag,
  }) {
    final result = InboxEntry._();
    if (id != null) result.id = id;
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (category != null) result.category = category;
    if (severity != null) result.severity = severity;
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    if (clickUrl != null) result.clickUrl = clickUrl;
    if (tag != null) result.tag = tag;
    return result;
  }

  InboxEntry._();

  factory InboxEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InboxEntry()..mergeFromBuffer(data, registry);
  factory InboxEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      InboxEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'InboxEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: InboxEntry.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'timestampMs')
    ..aOS(3, _omitFieldNames ? '' : 'category')
    ..aE<NotificationSeverity>(4, _omitFieldNames ? '' : 'severity',
        enumValues: NotificationSeverity.values)
    ..aOS(5, _omitFieldNames ? '' : 'title')
    ..aOS(6, _omitFieldNames ? '' : 'body')
    ..aOS(7, _omitFieldNames ? '' : 'clickUrl')
    ..aOS(8, _omitFieldNames ? '' : 'tag')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InboxEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  InboxEntry copyWith(void Function(InboxEntry) updates) =>
      super.copyWith((message) => updates(message as InboxEntry)) as InboxEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use InboxEntry() / InboxEntry.new instead')
  static InboxEntry create() => InboxEntry._();
  static $pb.GeneratedMessage $_createMessage() => InboxEntry._();
  @$core.override
  InboxEntry createEmptyInstance() => InboxEntry._();
  @$core.pragma('dart2js:noInline')
  static InboxEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<InboxEntry>(InboxEntry.$_createMessage);
  static InboxEntry? _defaultInstance;

  /// Strictly increasing, and never reused -- also across daemon restarts.
  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestampMs => $_getI64(1);
  @$pb.TagNumber(2)
  set timestampMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTimestampMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestampMs() => $_clearField(2);

  /// Dotted category, e.g. "surveillance.motion".
  @$pb.TagNumber(3)
  $core.String get category => $_getSZ(2);
  @$pb.TagNumber(3)
  set category($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCategory() => $_has(2);
  @$pb.TagNumber(3)
  void clearCategory() => $_clearField(3);

  @$pb.TagNumber(4)
  NotificationSeverity get severity => $_getN(3);
  @$pb.TagNumber(4)
  set severity(NotificationSeverity value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSeverity() => $_has(3);
  @$pb.TagNumber(4)
  void clearSeverity() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get title => $_getSZ(4);
  @$pb.TagNumber(5)
  set title($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTitle() => $_has(4);
  @$pb.TagNumber(5)
  void clearTitle() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get body => $_getSZ(5);
  @$pb.TagNumber(6)
  set body($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBody() => $_has(5);
  @$pb.TagNumber(6)
  void clearBody() => $_clearField(6);

  /// Deep link the source gave, e.g. to the recording; empty when none.
  @$pb.TagNumber(7)
  $core.String get clickUrl => $_getSZ(6);
  @$pb.TagNumber(7)
  set clickUrl($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasClickUrl() => $_has(6);
  @$pb.TagNumber(7)
  void clearClickUrl() => $_clearField(7);

  /// Events with the same tag supersede each other (e.g. "recording in progress" by the final
  /// alert): the car keeps only the newest, and a companion should show only the newest it has.
  /// Empty when the source gave none.
  @$pb.TagNumber(8)
  $core.String get tag => $_getSZ(7);
  @$pb.TagNumber(8)
  set tag($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTag() => $_has(7);
  @$pb.TagNumber(8)
  void clearTag() => $_clearField(8);
}

class ListInboxRequest extends $pb.GeneratedMessage {
  factory ListInboxRequest({
    $fixnum.Int64? afterId,
    $core.int? limit,
  }) {
    final result = ListInboxRequest._();
    if (afterId != null) result.afterId = afterId;
    if (limit != null) result.limit = limit;
    return result;
  }

  ListInboxRequest._();

  factory ListInboxRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInboxRequest()..mergeFromBuffer(data, registry);
  factory ListInboxRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInboxRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListInboxRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListInboxRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'afterId')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInboxRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInboxRequest copyWith(void Function(ListInboxRequest) updates) =>
      super.copyWith((message) => updates(message as ListInboxRequest))
          as ListInboxRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListInboxRequest() / ListInboxRequest.new instead')
  static ListInboxRequest create() => ListInboxRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListInboxRequest._();
  @$core.override
  ListInboxRequest createEmptyInstance() => ListInboxRequest._();
  @$core.pragma('dart2js:noInline')
  static ListInboxRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListInboxRequest>(
          ListInboxRequest.$_createMessage);
  static ListInboxRequest? _defaultInstance;

  /// Entries with an id greater than this; 0 for everything still held.
  @$pb.TagNumber(1)
  $fixnum.Int64 get afterId => $_getI64(0);
  @$pb.TagNumber(1)
  set afterId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAfterId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAfterId() => $_clearField(1);

  /// At most this many, oldest first; 0 means 100, and it is capped at 500.
  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class ListInboxResponse extends $pb.GeneratedMessage {
  factory ListInboxResponse({
    $core.Iterable<InboxEntry>? entries,
    $fixnum.Int64? latestId,
    $fixnum.Int64? oldestId,
  }) {
    final result = ListInboxResponse._();
    if (entries != null) result.entries.addAll(entries);
    if (latestId != null) result.latestId = latestId;
    if (oldestId != null) result.oldestId = oldestId;
    return result;
  }

  ListInboxResponse._();

  factory ListInboxResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInboxResponse()..mergeFromBuffer(data, registry);
  factory ListInboxResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListInboxResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListInboxResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListInboxResponse.$_createMessage)
    ..pPM<InboxEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: InboxEntry.$_createMessage)
    ..aInt64(2, _omitFieldNames ? '' : 'latestId')
    ..aInt64(3, _omitFieldNames ? '' : 'oldestId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInboxResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListInboxResponse copyWith(void Function(ListInboxResponse) updates) =>
      super.copyWith((message) => updates(message as ListInboxResponse))
          as ListInboxResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListInboxResponse() / ListInboxResponse.new instead')
  static ListInboxResponse create() => ListInboxResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListInboxResponse._();
  @$core.override
  ListInboxResponse createEmptyInstance() => ListInboxResponse._();
  @$core.pragma('dart2js:noInline')
  static ListInboxResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListInboxResponse>(
          ListInboxResponse.$_createMessage);
  static ListInboxResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<InboxEntry> get entries => $_getList(0);

  /// The newest and oldest ids the car still holds (0 when empty). The inbox is bounded: a
  /// companion whose after_id is below oldest_id - 1 missed entries that were dropped.
  @$pb.TagNumber(2)
  $fixnum.Int64 get latestId => $_getI64(1);
  @$pb.TagNumber(2)
  set latestId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLatestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get oldestId => $_getI64(2);
  @$pb.TagNumber(3)
  set oldestId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOldestId() => $_has(2);
  @$pb.TagNumber(3)
  void clearOldestId() => $_clearField(3);
}

/// NotificationsService: the notification categories, a test alert, and the store-and-forward inbox.
/// Web Push (Subscribe / Unsubscribe / ListSubscriptions / UpdatePreferences) was removed with the
/// web app (BladeWatch-rdtj.22); the companion collects alerts from the inbox instead.
class NotificationsServiceApi {
  final $pb.RpcClient _client;

  NotificationsServiceApi(this._client);

  $async.Future<GetCategoriesResponse> getCategories(
          $pb.ClientContext? ctx, GetCategoriesRequest request) =>
      _client.invoke<GetCategoriesResponse>(ctx, 'NotificationsService',
          'GetCategories', request, GetCategoriesResponse());
  $async.Future<SendTestResponse> sendTest(
          $pb.ClientContext? ctx, SendTestRequest request) =>
      _client.invoke<SendTestResponse>(
          ctx, 'NotificationsService', 'SendTest', request, SendTestResponse());

  /// Store and forward (BladeWatch-rdtj.14): the car keeps the notifications it raised, and a
  /// companion fetches the ones it has not seen whenever it connects -- over the LAN or Pear, with
  /// no push service in between. Oldest first.
  $async.Future<ListInboxResponse> listInbox(
          $pb.ClientContext? ctx, ListInboxRequest request) =>
      _client.invoke<ListInboxResponse>(ctx, 'NotificationsService',
          'ListInbox', request, ListInboxResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
