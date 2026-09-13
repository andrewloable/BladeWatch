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

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'notifications.pbenum.dart';

/// QuietHoursPref defines a window (minutes since midnight) during which
/// non-critical push notifications are suppressed.
class QuietHoursPref extends $pb.GeneratedMessage {
  factory QuietHoursPref({
    $core.int? startMin,
    $core.int? endMin,
    $core.bool? allowCritical,
  }) {
    final result = QuietHoursPref._();
    if (startMin != null) result.startMin = startMin;
    if (endMin != null) result.endMin = endMin;
    if (allowCritical != null) result.allowCritical = allowCritical;
    return result;
  }

  QuietHoursPref._();

  factory QuietHoursPref.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuietHoursPref()..mergeFromBuffer(data, registry);
  factory QuietHoursPref.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuietHoursPref()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuietHoursPref',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: QuietHoursPref.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'startMin')
    ..aI(2, _omitFieldNames ? '' : 'endMin')
    ..aOB(3, _omitFieldNames ? '' : 'allowCritical')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuietHoursPref clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuietHoursPref copyWith(void Function(QuietHoursPref) updates) =>
      super.copyWith((message) => updates(message as QuietHoursPref))
          as QuietHoursPref;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QuietHoursPref() / QuietHoursPref.new instead')
  static QuietHoursPref create() => QuietHoursPref._();
  static $pb.GeneratedMessage $_createMessage() => QuietHoursPref._();
  @$core.override
  QuietHoursPref createEmptyInstance() => QuietHoursPref._();
  @$core.pragma('dart2js:noInline')
  static QuietHoursPref getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QuietHoursPref>(
          QuietHoursPref.$_createMessage);
  static QuietHoursPref? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get startMin => $_getIZ(0);
  @$pb.TagNumber(1)
  set startMin($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStartMin() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartMin() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get endMin => $_getIZ(1);
  @$pb.TagNumber(2)
  set endMin($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEndMin() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndMin() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get allowCritical => $_getBF(2);
  @$pb.TagNumber(3)
  set allowCritical($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAllowCritical() => $_has(2);
  @$pb.TagNumber(3)
  void clearAllowCritical() => $_clearField(3);
}

/// PushKeys carries the ECDH/auth keys from the browser PushSubscription.
class PushKeys extends $pb.GeneratedMessage {
  factory PushKeys({
    $core.String? p256dh,
    $core.String? auth,
  }) {
    final result = PushKeys._();
    if (p256dh != null) result.p256dh = p256dh;
    if (auth != null) result.auth = auth;
    return result;
  }

  PushKeys._();

  factory PushKeys.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PushKeys()..mergeFromBuffer(data, registry);
  factory PushKeys.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PushKeys()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushKeys',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PushKeys.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'p256dh')
    ..aOS(2, _omitFieldNames ? '' : 'auth')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushKeys clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushKeys copyWith(void Function(PushKeys) updates) =>
      super.copyWith((message) => updates(message as PushKeys)) as PushKeys;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PushKeys() / PushKeys.new instead')
  static PushKeys create() => PushKeys._();
  static $pb.GeneratedMessage $_createMessage() => PushKeys._();
  @$core.override
  PushKeys createEmptyInstance() => PushKeys._();
  @$core.pragma('dart2js:noInline')
  static PushKeys getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushKeys>(PushKeys.$_createMessage);
  static PushKeys? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get p256dh => $_getSZ(0);
  @$pb.TagNumber(1)
  set p256dh($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasP256dh() => $_has(0);
  @$pb.TagNumber(1)
  void clearP256dh() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get auth => $_getSZ(1);
  @$pb.TagNumber(2)
  set auth($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuth() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuth() => $_clearField(2);
}

/// PushSubscriptionRecord is one registered device for the settings UI.
class PushSubscriptionRecord extends $pb.GeneratedMessage {
  factory PushSubscriptionRecord({
    $core.String? id,
    $core.String? label,
    $fixnum.Int64? createdAt,
    $fixnum.Int64? lastSeenAt,
    $core.String? minSeverity,
    $core.Iterable<$core.String>? mutedCategories,
    QuietHoursPref? quietHours,
  }) {
    final result = PushSubscriptionRecord._();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (createdAt != null) result.createdAt = createdAt;
    if (lastSeenAt != null) result.lastSeenAt = lastSeenAt;
    if (minSeverity != null) result.minSeverity = minSeverity;
    if (mutedCategories != null) result.mutedCategories.addAll(mutedCategories);
    if (quietHours != null) result.quietHours = quietHours;
    return result;
  }

  PushSubscriptionRecord._();

  factory PushSubscriptionRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PushSubscriptionRecord()..mergeFromBuffer(data, registry);
  factory PushSubscriptionRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PushSubscriptionRecord()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushSubscriptionRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PushSubscriptionRecord.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aInt64(3, _omitFieldNames ? '' : 'createdAt')
    ..aInt64(4, _omitFieldNames ? '' : 'lastSeenAt')
    ..aOS(5, _omitFieldNames ? '' : 'minSeverity')
    ..pPS(6, _omitFieldNames ? '' : 'mutedCategories')
    ..aOM<QuietHoursPref>(7, _omitFieldNames ? '' : 'quietHours',
        subBuilder: QuietHoursPref.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushSubscriptionRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushSubscriptionRecord copyWith(
          void Function(PushSubscriptionRecord) updates) =>
      super.copyWith((message) => updates(message as PushSubscriptionRecord))
          as PushSubscriptionRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PushSubscriptionRecord() / PushSubscriptionRecord.new instead')
  static PushSubscriptionRecord create() => PushSubscriptionRecord._();
  static $pb.GeneratedMessage $_createMessage() => PushSubscriptionRecord._();
  @$core.override
  PushSubscriptionRecord createEmptyInstance() => PushSubscriptionRecord._();
  @$core.pragma('dart2js:noInline')
  static PushSubscriptionRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushSubscriptionRecord>(
          PushSubscriptionRecord.$_createMessage);
  static PushSubscriptionRecord? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createdAt => $_getI64(2);
  @$pb.TagNumber(3)
  set createdAt($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAt() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastSeenAt => $_getI64(3);
  @$pb.TagNumber(4)
  set lastSeenAt($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastSeenAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastSeenAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get minSeverity => $_getSZ(4);
  @$pb.TagNumber(5)
  set minSeverity($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMinSeverity() => $_has(4);
  @$pb.TagNumber(5)
  void clearMinSeverity() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<$core.String> get mutedCategories => $_getList(5);

  @$pb.TagNumber(7)
  QuietHoursPref get quietHours => $_getN(6);
  @$pb.TagNumber(7)
  set quietHours(QuietHoursPref value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasQuietHours() => $_has(6);
  @$pb.TagNumber(7)
  void clearQuietHours() => $_clearField(7);
  @$pb.TagNumber(7)
  QuietHoursPref ensureQuietHours() => $_ensure(6);
}

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
    $core.String? vapidPublicKey,
  }) {
    final result = GetCategoriesResponse._();
    if (categoriesJson != null) result.categoriesJson = categoriesJson;
    if (vapidPublicKey != null) result.vapidPublicKey = vapidPublicKey;
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
    ..aOS(2, _omitFieldNames ? '' : 'vapidPublicKey')
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

  @$pb.TagNumber(2)
  $core.String get vapidPublicKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set vapidPublicKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVapidPublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearVapidPublicKey() => $_clearField(2);
}

class SubscribeRequest extends $pb.GeneratedMessage {
  factory SubscribeRequest({
    $core.String? endpoint,
    PushKeys? keys,
    $core.String? label,
  }) {
    final result = SubscribeRequest._();
    if (endpoint != null) result.endpoint = endpoint;
    if (keys != null) result.keys = keys;
    if (label != null) result.label = label;
    return result;
  }

  SubscribeRequest._();

  factory SubscribeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscribeRequest()..mergeFromBuffer(data, registry);
  factory SubscribeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscribeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SubscribeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'endpoint')
    ..aOM<PushKeys>(2, _omitFieldNames ? '' : 'keys',
        subBuilder: PushKeys.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeRequest copyWith(void Function(SubscribeRequest) updates) =>
      super.copyWith((message) => updates(message as SubscribeRequest))
          as SubscribeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SubscribeRequest() / SubscribeRequest.new instead')
  static SubscribeRequest create() => SubscribeRequest._();
  static $pb.GeneratedMessage $_createMessage() => SubscribeRequest._();
  @$core.override
  SubscribeRequest createEmptyInstance() => SubscribeRequest._();
  @$core.pragma('dart2js:noInline')
  static SubscribeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscribeRequest>(
          SubscribeRequest.$_createMessage);
  static SubscribeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get endpoint => $_getSZ(0);
  @$pb.TagNumber(1)
  set endpoint($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEndpoint() => $_has(0);
  @$pb.TagNumber(1)
  void clearEndpoint() => $_clearField(1);

  @$pb.TagNumber(2)
  PushKeys get keys => $_getN(1);
  @$pb.TagNumber(2)
  set keys(PushKeys value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKeys() => $_has(1);
  @$pb.TagNumber(2)
  void clearKeys() => $_clearField(2);
  @$pb.TagNumber(2)
  PushKeys ensureKeys() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get label => $_getSZ(2);
  @$pb.TagNumber(3)
  set label($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLabel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLabel() => $_clearField(3);
}

class SubscribeResponse extends $pb.GeneratedMessage {
  factory SubscribeResponse({
    $core.bool? success,
    $core.String? id,
    $core.String? error,
  }) {
    final result = SubscribeResponse._();
    if (success != null) result.success = success;
    if (id != null) result.id = id;
    if (error != null) result.error = error;
    return result;
  }

  SubscribeResponse._();

  factory SubscribeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscribeResponse()..mergeFromBuffer(data, registry);
  factory SubscribeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscribeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SubscribeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SubscribeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscribeResponse copyWith(void Function(SubscribeResponse) updates) =>
      super.copyWith((message) => updates(message as SubscribeResponse))
          as SubscribeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SubscribeResponse() / SubscribeResponse.new instead')
  static SubscribeResponse create() => SubscribeResponse._();
  static $pb.GeneratedMessage $_createMessage() => SubscribeResponse._();
  @$core.override
  SubscribeResponse createEmptyInstance() => SubscribeResponse._();
  @$core.pragma('dart2js:noInline')
  static SubscribeResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscribeResponse>(
          SubscribeResponse.$_createMessage);
  static SubscribeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class UnsubscribeRequest extends $pb.GeneratedMessage {
  factory UnsubscribeRequest({
    $core.String? id,
    $core.String? endpoint,
  }) {
    final result = UnsubscribeRequest._();
    if (id != null) result.id = id;
    if (endpoint != null) result.endpoint = endpoint;
    return result;
  }

  UnsubscribeRequest._();

  factory UnsubscribeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnsubscribeRequest()..mergeFromBuffer(data, registry);
  factory UnsubscribeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnsubscribeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnsubscribeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: UnsubscribeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'endpoint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnsubscribeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnsubscribeRequest copyWith(void Function(UnsubscribeRequest) updates) =>
      super.copyWith((message) => updates(message as UnsubscribeRequest))
          as UnsubscribeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UnsubscribeRequest() / UnsubscribeRequest.new instead')
  static UnsubscribeRequest create() => UnsubscribeRequest._();
  static $pb.GeneratedMessage $_createMessage() => UnsubscribeRequest._();
  @$core.override
  UnsubscribeRequest createEmptyInstance() => UnsubscribeRequest._();
  @$core.pragma('dart2js:noInline')
  static UnsubscribeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnsubscribeRequest>(
          UnsubscribeRequest.$_createMessage);
  static UnsubscribeRequest? _defaultInstance;

  /// Either id or endpoint must be set.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get endpoint => $_getSZ(1);
  @$pb.TagNumber(2)
  set endpoint($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEndpoint() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndpoint() => $_clearField(2);
}

class UnsubscribeResponse extends $pb.GeneratedMessage {
  factory UnsubscribeResponse({
    $core.bool? success,
  }) {
    final result = UnsubscribeResponse._();
    if (success != null) result.success = success;
    return result;
  }

  UnsubscribeResponse._();

  factory UnsubscribeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnsubscribeResponse()..mergeFromBuffer(data, registry);
  factory UnsubscribeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnsubscribeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnsubscribeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: UnsubscribeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnsubscribeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnsubscribeResponse copyWith(void Function(UnsubscribeResponse) updates) =>
      super.copyWith((message) => updates(message as UnsubscribeResponse))
          as UnsubscribeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use UnsubscribeResponse() / UnsubscribeResponse.new instead')
  static UnsubscribeResponse create() => UnsubscribeResponse._();
  static $pb.GeneratedMessage $_createMessage() => UnsubscribeResponse._();
  @$core.override
  UnsubscribeResponse createEmptyInstance() => UnsubscribeResponse._();
  @$core.pragma('dart2js:noInline')
  static UnsubscribeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UnsubscribeResponse>(
          UnsubscribeResponse.$_createMessage);
  static UnsubscribeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class ListSubscriptionsRequest extends $pb.GeneratedMessage {
  factory ListSubscriptionsRequest() => ListSubscriptionsRequest._();

  ListSubscriptionsRequest._();

  factory ListSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsRequest()..mergeFromBuffer(data, registry);
  factory ListSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSubscriptionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListSubscriptionsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsRequest copyWith(
          void Function(ListSubscriptionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSubscriptionsRequest))
          as ListSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListSubscriptionsRequest() / ListSubscriptionsRequest.new instead')
  static ListSubscriptionsRequest create() => ListSubscriptionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListSubscriptionsRequest._();
  @$core.override
  ListSubscriptionsRequest createEmptyInstance() =>
      ListSubscriptionsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsRequest>(
          ListSubscriptionsRequest.$_createMessage);
  static ListSubscriptionsRequest? _defaultInstance;
}

class ListSubscriptionsResponse extends $pb.GeneratedMessage {
  factory ListSubscriptionsResponse({
    $core.bool? success,
    $core.Iterable<PushSubscriptionRecord>? subscriptions,
  }) {
    final result = ListSubscriptionsResponse._();
    if (success != null) result.success = success;
    if (subscriptions != null) result.subscriptions.addAll(subscriptions);
    return result;
  }

  ListSubscriptionsResponse._();

  factory ListSubscriptionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsResponse()..mergeFromBuffer(data, registry);
  factory ListSubscriptionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListSubscriptionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListSubscriptionsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<PushSubscriptionRecord>(2, _omitFieldNames ? '' : 'subscriptions',
        subBuilder: PushSubscriptionRecord.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsResponse copyWith(
          void Function(ListSubscriptionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSubscriptionsResponse))
          as ListSubscriptionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListSubscriptionsResponse() / ListSubscriptionsResponse.new instead')
  static ListSubscriptionsResponse create() => ListSubscriptionsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListSubscriptionsResponse._();
  @$core.override
  ListSubscriptionsResponse createEmptyInstance() =>
      ListSubscriptionsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsResponse>(
          ListSubscriptionsResponse.$_createMessage);
  static ListSubscriptionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<PushSubscriptionRecord> get subscriptions => $_getList(1);
}

class UpdatePreferencesRequest extends $pb.GeneratedMessage {
  factory UpdatePreferencesRequest({
    $core.String? id,
    $core.Iterable<$core.String>? mutedCategories,
    $core.String? minSeverity,
    QuietHoursPref? quietHours,
    $core.bool? hasQuietHours_5,
  }) {
    final result = UpdatePreferencesRequest._();
    if (id != null) result.id = id;
    if (mutedCategories != null) result.mutedCategories.addAll(mutedCategories);
    if (minSeverity != null) result.minSeverity = minSeverity;
    if (quietHours != null) result.quietHours = quietHours;
    if (hasQuietHours_5 != null) result.hasQuietHours_5 = hasQuietHours_5;
    return result;
  }

  UpdatePreferencesRequest._();

  factory UpdatePreferencesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdatePreferencesRequest()..mergeFromBuffer(data, registry);
  factory UpdatePreferencesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdatePreferencesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdatePreferencesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: UpdatePreferencesRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..pPS(2, _omitFieldNames ? '' : 'mutedCategories')
    ..aOS(3, _omitFieldNames ? '' : 'minSeverity')
    ..aOM<QuietHoursPref>(4, _omitFieldNames ? '' : 'quietHours',
        subBuilder: QuietHoursPref.$_createMessage)
    ..aOB(5, _omitFieldNames ? '' : 'hasQuietHours')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePreferencesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePreferencesRequest copyWith(
          void Function(UpdatePreferencesRequest) updates) =>
      super.copyWith((message) => updates(message as UpdatePreferencesRequest))
          as UpdatePreferencesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdatePreferencesRequest() / UpdatePreferencesRequest.new instead')
  static UpdatePreferencesRequest create() => UpdatePreferencesRequest._();
  static $pb.GeneratedMessage $_createMessage() => UpdatePreferencesRequest._();
  @$core.override
  UpdatePreferencesRequest createEmptyInstance() =>
      UpdatePreferencesRequest._();
  @$core.pragma('dart2js:noInline')
  static UpdatePreferencesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdatePreferencesRequest>(
          UpdatePreferencesRequest.$_createMessage);
  static UpdatePreferencesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get mutedCategories => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get minSeverity => $_getSZ(2);
  @$pb.TagNumber(3)
  set minSeverity($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMinSeverity() => $_has(2);
  @$pb.TagNumber(3)
  void clearMinSeverity() => $_clearField(3);

  /// Set to null-equivalent (has_quiet_hours=false) to clear.
  @$pb.TagNumber(4)
  QuietHoursPref get quietHours => $_getN(3);
  @$pb.TagNumber(4)
  set quietHours(QuietHoursPref value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasQuietHours() => $_has(3);
  @$pb.TagNumber(4)
  void clearQuietHours() => $_clearField(4);
  @$pb.TagNumber(4)
  QuietHoursPref ensureQuietHours() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.bool get hasQuietHours_5 => $_getBF(4);
  @$pb.TagNumber(5)
  set hasQuietHours_5($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHasQuietHours_5() => $_has(4);
  @$pb.TagNumber(5)
  void clearHasQuietHours_5() => $_clearField(5);
}

class UpdatePreferencesResponse extends $pb.GeneratedMessage {
  factory UpdatePreferencesResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = UpdatePreferencesResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  UpdatePreferencesResponse._();

  factory UpdatePreferencesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdatePreferencesResponse()..mergeFromBuffer(data, registry);
  factory UpdatePreferencesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdatePreferencesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdatePreferencesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: UpdatePreferencesResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePreferencesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePreferencesResponse copyWith(
          void Function(UpdatePreferencesResponse) updates) =>
      super.copyWith((message) => updates(message as UpdatePreferencesResponse))
          as UpdatePreferencesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use UpdatePreferencesResponse() / UpdatePreferencesResponse.new instead')
  static UpdatePreferencesResponse create() => UpdatePreferencesResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      UpdatePreferencesResponse._();
  @$core.override
  UpdatePreferencesResponse createEmptyInstance() =>
      UpdatePreferencesResponse._();
  @$core.pragma('dart2js:noInline')
  static UpdatePreferencesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdatePreferencesResponse>(
          UpdatePreferencesResponse.$_createMessage);
  static UpdatePreferencesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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

/// NotificationsService manages Web Push subscriptions and notification preferences.
///
/// HTTP mapping:
///   GetCategories        GET  /api/notifications/categories
///   Subscribe            POST /api/push/subscribe
///   Unsubscribe          POST /api/push/unsubscribe
///   ListSubscriptions    GET  /api/push/subscriptions
///   UpdatePreferences    POST /api/push/preferences
///   SendTest             POST /api/push/test
class NotificationsServiceApi {
  final $pb.RpcClient _client;

  NotificationsServiceApi(this._client);

  $async.Future<GetCategoriesResponse> getCategories(
          $pb.ClientContext? ctx, GetCategoriesRequest request) =>
      _client.invoke<GetCategoriesResponse>(ctx, 'NotificationsService',
          'GetCategories', request, GetCategoriesResponse());
  $async.Future<SubscribeResponse> subscribe(
          $pb.ClientContext? ctx, SubscribeRequest request) =>
      _client.invoke<SubscribeResponse>(ctx, 'NotificationsService',
          'Subscribe', request, SubscribeResponse());
  $async.Future<UnsubscribeResponse> unsubscribe(
          $pb.ClientContext? ctx, UnsubscribeRequest request) =>
      _client.invoke<UnsubscribeResponse>(ctx, 'NotificationsService',
          'Unsubscribe', request, UnsubscribeResponse());
  $async.Future<ListSubscriptionsResponse> listSubscriptions(
          $pb.ClientContext? ctx, ListSubscriptionsRequest request) =>
      _client.invoke<ListSubscriptionsResponse>(ctx, 'NotificationsService',
          'ListSubscriptions', request, ListSubscriptionsResponse());
  $async.Future<UpdatePreferencesResponse> updatePreferences(
          $pb.ClientContext? ctx, UpdatePreferencesRequest request) =>
      _client.invoke<UpdatePreferencesResponse>(ctx, 'NotificationsService',
          'UpdatePreferences', request, UpdatePreferencesResponse());
  $async.Future<SendTestResponse> sendTest(
          $pb.ClientContext? ctx, SendTestRequest request) =>
      _client.invoke<SendTestResponse>(
          ctx, 'NotificationsService', 'SendTest', request, SendTestResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
