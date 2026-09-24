// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/safe_locations.proto.

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

/// SafeZone is a named geofence circle.
class SafeZone extends $pb.GeneratedMessage {
  factory SafeZone({
    $core.String? id,
    $core.String? name,
    $core.double? lat,
    $core.double? lng,
    $core.int? radiusM,
    $core.bool? active,
    $fixnum.Int64? createdAtMs,
  }) {
    final result = SafeZone._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (lat != null) result.lat = lat;
    if (lng != null) result.lng = lng;
    if (radiusM != null) result.radiusM = radiusM;
    if (active != null) result.active = active;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    return result;
  }

  SafeZone._();

  factory SafeZone.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SafeZone()..mergeFromBuffer(data, registry);
  factory SafeZone.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SafeZone()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SafeZone',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SafeZone.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aD(3, _omitFieldNames ? '' : 'lat')
    ..aD(4, _omitFieldNames ? '' : 'lng')
    ..aI(5, _omitFieldNames ? '' : 'radiusM')
    ..aOB(6, _omitFieldNames ? '' : 'enabled', protoName: 'active')
    ..aInt64(7, _omitFieldNames ? '' : 'createdAt', protoName: 'created_at_ms')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SafeZone clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SafeZone copyWith(void Function(SafeZone) updates) =>
      super.copyWith((message) => updates(message as SafeZone)) as SafeZone;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SafeZone() / SafeZone.new instead')
  static SafeZone create() => SafeZone._();
  static $pb.GeneratedMessage $_createMessage() => SafeZone._();
  @$core.override
  SafeZone createEmptyInstance() => SafeZone._();
  @$core.pragma('dart2js:noInline')
  static SafeZone getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SafeZone>(SafeZone.$_createMessage);
  static SafeZone? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lat => $_getN(2);
  @$pb.TagNumber(3)
  set lat($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLat() => $_has(2);
  @$pb.TagNumber(3)
  void clearLat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get lng => $_getN(3);
  @$pb.TagNumber(4)
  set lng($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLng() => $_has(3);
  @$pb.TagNumber(4)
  void clearLng() => $_clearField(4);

  /// Radius in metres.
  @$pb.TagNumber(5)
  $core.int get radiusM => $_getIZ(4);
  @$pb.TagNumber(5)
  set radiusM($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRadiusM() => $_has(4);
  @$pb.TagNumber(5)
  void clearRadiusM() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get active => $_getBF(5);
  @$pb.TagNumber(6)
  set active($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasActive() => $_has(5);
  @$pb.TagNumber(6)
  void clearActive() => $_clearField(6);

  /// Epoch ms when the zone was created.
  @$pb.TagNumber(7)
  $fixnum.Int64 get createdAtMs => $_getI64(6);
  @$pb.TagNumber(7)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAtMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAtMs() => $_clearField(7);
}

class ListZonesRequest extends $pb.GeneratedMessage {
  factory ListZonesRequest() => ListZonesRequest._();

  ListZonesRequest._();

  factory ListZonesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListZonesRequest()..mergeFromBuffer(data, registry);
  factory ListZonesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListZonesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListZonesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListZonesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListZonesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListZonesRequest copyWith(void Function(ListZonesRequest) updates) =>
      super.copyWith((message) => updates(message as ListZonesRequest))
          as ListZonesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListZonesRequest() / ListZonesRequest.new instead')
  static ListZonesRequest create() => ListZonesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListZonesRequest._();
  @$core.override
  ListZonesRequest createEmptyInstance() => ListZonesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListZonesRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListZonesRequest>(
          ListZonesRequest.$_createMessage);
  static ListZonesRequest? _defaultInstance;
}

class ListZonesResponse extends $pb.GeneratedMessage {
  factory ListZonesResponse({
    $core.Iterable<SafeZone>? zones,
    $core.bool? featureEnabled,
    $core.bool? currentlyInSafeZone,
    $core.bool? hasGps,
    $core.double? currentLat,
    $core.double? currentLng,
  }) {
    final result = ListZonesResponse._();
    if (zones != null) result.zones.addAll(zones);
    if (featureEnabled != null) result.featureEnabled = featureEnabled;
    if (currentlyInSafeZone != null)
      result.currentlyInSafeZone = currentlyInSafeZone;
    if (hasGps != null) result.hasGps = hasGps;
    if (currentLat != null) result.currentLat = currentLat;
    if (currentLng != null) result.currentLng = currentLng;
    return result;
  }

  ListZonesResponse._();

  factory ListZonesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListZonesResponse()..mergeFromBuffer(data, registry);
  factory ListZonesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListZonesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListZonesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListZonesResponse.$_createMessage)
    ..pPM<SafeZone>(1, _omitFieldNames ? '' : 'zones',
        subBuilder: SafeZone.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'featureEnabled')
    ..aOB(3, _omitFieldNames ? '' : 'inSafeZone',
        protoName: 'currently_in_safe_zone')
    ..aOB(4, _omitFieldNames ? '' : 'hasGps')
    ..aD(5, _omitFieldNames ? '' : 'lat', protoName: 'current_lat')
    ..aD(6, _omitFieldNames ? '' : 'lng', protoName: 'current_lng')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListZonesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListZonesResponse copyWith(void Function(ListZonesResponse) updates) =>
      super.copyWith((message) => updates(message as ListZonesResponse))
          as ListZonesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListZonesResponse() / ListZonesResponse.new instead')
  static ListZonesResponse create() => ListZonesResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListZonesResponse._();
  @$core.override
  ListZonesResponse createEmptyInstance() => ListZonesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListZonesResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListZonesResponse>(
          ListZonesResponse.$_createMessage);
  static ListZonesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SafeZone> get zones => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get featureEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set featureEnabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFeatureEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearFeatureEnabled() => $_clearField(2);

  /// Whether the vehicle is currently inside any zone.
  @$pb.TagNumber(3)
  $core.bool get currentlyInSafeZone => $_getBF(2);
  @$pb.TagNumber(3)
  set currentlyInSafeZone($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrentlyInSafeZone() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrentlyInSafeZone() => $_clearField(3);

  /// Current GPS fix from the daemon, for map centering and add-zone-at-location.
  @$pb.TagNumber(4)
  $core.bool get hasGps => $_getBF(3);
  @$pb.TagNumber(4)
  set hasGps($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHasGps() => $_has(3);
  @$pb.TagNumber(4)
  void clearHasGps() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get currentLat => $_getN(4);
  @$pb.TagNumber(5)
  set currentLat($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrentLat() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrentLat() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get currentLng => $_getN(5);
  @$pb.TagNumber(6)
  set currentLng($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCurrentLng() => $_has(5);
  @$pb.TagNumber(6)
  void clearCurrentLng() => $_clearField(6);
}

class AddZoneRequest extends $pb.GeneratedMessage {
  factory AddZoneRequest({
    $core.String? name,
    $core.double? lat,
    $core.double? lng,
    $core.int? radiusM,
  }) {
    final result = AddZoneRequest._();
    if (name != null) result.name = name;
    if (lat != null) result.lat = lat;
    if (lng != null) result.lng = lng;
    if (radiusM != null) result.radiusM = radiusM;
    return result;
  }

  AddZoneRequest._();

  factory AddZoneRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddZoneRequest()..mergeFromBuffer(data, registry);
  factory AddZoneRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddZoneRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddZoneRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: AddZoneRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aD(2, _omitFieldNames ? '' : 'lat')
    ..aD(3, _omitFieldNames ? '' : 'lng')
    ..aI(4, _omitFieldNames ? '' : 'radiusM')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddZoneRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddZoneRequest copyWith(void Function(AddZoneRequest) updates) =>
      super.copyWith((message) => updates(message as AddZoneRequest))
          as AddZoneRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddZoneRequest() / AddZoneRequest.new instead')
  static AddZoneRequest create() => AddZoneRequest._();
  static $pb.GeneratedMessage $_createMessage() => AddZoneRequest._();
  @$core.override
  AddZoneRequest createEmptyInstance() => AddZoneRequest._();
  @$core.pragma('dart2js:noInline')
  static AddZoneRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddZoneRequest>(
          AddZoneRequest.$_createMessage);
  static AddZoneRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lat => $_getN(1);
  @$pb.TagNumber(2)
  set lat($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLat() => $_has(1);
  @$pb.TagNumber(2)
  void clearLat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lng => $_getN(2);
  @$pb.TagNumber(3)
  set lng($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLng() => $_has(2);
  @$pb.TagNumber(3)
  void clearLng() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get radiusM => $_getIZ(3);
  @$pb.TagNumber(4)
  set radiusM($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRadiusM() => $_has(3);
  @$pb.TagNumber(4)
  void clearRadiusM() => $_clearField(4);
}

class AddZoneResponse extends $pb.GeneratedMessage {
  factory AddZoneResponse({
    $core.bool? success,
    SafeZone? zone,
    $core.String? error,
  }) {
    final result = AddZoneResponse._();
    if (success != null) result.success = success;
    if (zone != null) result.zone = zone;
    if (error != null) result.error = error;
    return result;
  }

  AddZoneResponse._();

  factory AddZoneResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddZoneResponse()..mergeFromBuffer(data, registry);
  factory AddZoneResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AddZoneResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddZoneResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: AddZoneResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<SafeZone>(2, _omitFieldNames ? '' : 'zone',
        subBuilder: SafeZone.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddZoneResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddZoneResponse copyWith(void Function(AddZoneResponse) updates) =>
      super.copyWith((message) => updates(message as AddZoneResponse))
          as AddZoneResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AddZoneResponse() / AddZoneResponse.new instead')
  static AddZoneResponse create() => AddZoneResponse._();
  static $pb.GeneratedMessage $_createMessage() => AddZoneResponse._();
  @$core.override
  AddZoneResponse createEmptyInstance() => AddZoneResponse._();
  @$core.pragma('dart2js:noInline')
  static AddZoneResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddZoneResponse>(
          AddZoneResponse.$_createMessage);
  static AddZoneResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  SafeZone get zone => $_getN(1);
  @$pb.TagNumber(2)
  set zone(SafeZone value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasZone() => $_has(1);
  @$pb.TagNumber(2)
  void clearZone() => $_clearField(2);
  @$pb.TagNumber(2)
  SafeZone ensureZone() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class UpdateZoneRequest extends $pb.GeneratedMessage {
  factory UpdateZoneRequest({
    $core.String? id,
    $core.String? name,
    $core.double? lat,
    $core.double? lng,
    $core.int? radiusM,
  }) {
    final result = UpdateZoneRequest._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (lat != null) result.lat = lat;
    if (lng != null) result.lng = lng;
    if (radiusM != null) result.radiusM = radiusM;
    return result;
  }

  UpdateZoneRequest._();

  factory UpdateZoneRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateZoneRequest()..mergeFromBuffer(data, registry);
  factory UpdateZoneRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateZoneRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateZoneRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: UpdateZoneRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aD(3, _omitFieldNames ? '' : 'lat')
    ..aD(4, _omitFieldNames ? '' : 'lng')
    ..aI(5, _omitFieldNames ? '' : 'radiusM')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateZoneRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateZoneRequest copyWith(void Function(UpdateZoneRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateZoneRequest))
          as UpdateZoneRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateZoneRequest() / UpdateZoneRequest.new instead')
  static UpdateZoneRequest create() => UpdateZoneRequest._();
  static $pb.GeneratedMessage $_createMessage() => UpdateZoneRequest._();
  @$core.override
  UpdateZoneRequest createEmptyInstance() => UpdateZoneRequest._();
  @$core.pragma('dart2js:noInline')
  static UpdateZoneRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateZoneRequest>(
          UpdateZoneRequest.$_createMessage);
  static UpdateZoneRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get lat => $_getN(2);
  @$pb.TagNumber(3)
  set lat($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLat() => $_has(2);
  @$pb.TagNumber(3)
  void clearLat() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get lng => $_getN(3);
  @$pb.TagNumber(4)
  set lng($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLng() => $_has(3);
  @$pb.TagNumber(4)
  void clearLng() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get radiusM => $_getIZ(4);
  @$pb.TagNumber(5)
  set radiusM($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRadiusM() => $_has(4);
  @$pb.TagNumber(5)
  void clearRadiusM() => $_clearField(5);
}

class UpdateZoneResponse extends $pb.GeneratedMessage {
  factory UpdateZoneResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = UpdateZoneResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  UpdateZoneResponse._();

  factory UpdateZoneResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateZoneResponse()..mergeFromBuffer(data, registry);
  factory UpdateZoneResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateZoneResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateZoneResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: UpdateZoneResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateZoneResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateZoneResponse copyWith(void Function(UpdateZoneResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateZoneResponse))
          as UpdateZoneResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateZoneResponse() / UpdateZoneResponse.new instead')
  static UpdateZoneResponse create() => UpdateZoneResponse._();
  static $pb.GeneratedMessage $_createMessage() => UpdateZoneResponse._();
  @$core.override
  UpdateZoneResponse createEmptyInstance() => UpdateZoneResponse._();
  @$core.pragma('dart2js:noInline')
  static UpdateZoneResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateZoneResponse>(
          UpdateZoneResponse.$_createMessage);
  static UpdateZoneResponse? _defaultInstance;

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

class DeleteZoneRequest extends $pb.GeneratedMessage {
  factory DeleteZoneRequest({
    $core.String? id,
  }) {
    final result = DeleteZoneRequest._();
    if (id != null) result.id = id;
    return result;
  }

  DeleteZoneRequest._();

  factory DeleteZoneRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteZoneRequest()..mergeFromBuffer(data, registry);
  factory DeleteZoneRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteZoneRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteZoneRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DeleteZoneRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteZoneRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteZoneRequest copyWith(void Function(DeleteZoneRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteZoneRequest))
          as DeleteZoneRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteZoneRequest() / DeleteZoneRequest.new instead')
  static DeleteZoneRequest create() => DeleteZoneRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteZoneRequest._();
  @$core.override
  DeleteZoneRequest createEmptyInstance() => DeleteZoneRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteZoneRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteZoneRequest>(
          DeleteZoneRequest.$_createMessage);
  static DeleteZoneRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeleteZoneResponse extends $pb.GeneratedMessage {
  factory DeleteZoneResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = DeleteZoneResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeleteZoneResponse._();

  factory DeleteZoneResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteZoneResponse()..mergeFromBuffer(data, registry);
  factory DeleteZoneResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteZoneResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteZoneResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DeleteZoneResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteZoneResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteZoneResponse copyWith(void Function(DeleteZoneResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteZoneResponse))
          as DeleteZoneResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteZoneResponse() / DeleteZoneResponse.new instead')
  static DeleteZoneResponse create() => DeleteZoneResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteZoneResponse._();
  @$core.override
  DeleteZoneResponse createEmptyInstance() => DeleteZoneResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteZoneResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteZoneResponse>(
          DeleteZoneResponse.$_createMessage);
  static DeleteZoneResponse? _defaultInstance;

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

class ToggleSafeLocationsRequest extends $pb.GeneratedMessage {
  factory ToggleSafeLocationsRequest({
    $core.bool? enabled,
    $core.bool? enabledSet,
  }) {
    final result = ToggleSafeLocationsRequest._();
    if (enabled != null) result.enabled = enabled;
    if (enabledSet != null) result.enabledSet = enabledSet;
    return result;
  }

  ToggleSafeLocationsRequest._();

  factory ToggleSafeLocationsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToggleSafeLocationsRequest()..mergeFromBuffer(data, registry);
  factory ToggleSafeLocationsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToggleSafeLocationsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToggleSafeLocationsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ToggleSafeLocationsRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'enabledSet')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToggleSafeLocationsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToggleSafeLocationsRequest copyWith(
          void Function(ToggleSafeLocationsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ToggleSafeLocationsRequest))
          as ToggleSafeLocationsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ToggleSafeLocationsRequest() / ToggleSafeLocationsRequest.new instead')
  static ToggleSafeLocationsRequest create() => ToggleSafeLocationsRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      ToggleSafeLocationsRequest._();
  @$core.override
  ToggleSafeLocationsRequest createEmptyInstance() =>
      ToggleSafeLocationsRequest._();
  @$core.pragma('dart2js:noInline')
  static ToggleSafeLocationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ToggleSafeLocationsRequest>(
          ToggleSafeLocationsRequest.$_createMessage);
  static ToggleSafeLocationsRequest? _defaultInstance;

  /// If not set the server will invert the current state.
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabledSet => $_getBF(1);
  @$pb.TagNumber(2)
  set enabledSet($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabledSet() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabledSet() => $_clearField(2);
}

class ToggleSafeLocationsResponse extends $pb.GeneratedMessage {
  factory ToggleSafeLocationsResponse({
    $core.bool? success,
    $core.bool? enabled,
  }) {
    final result = ToggleSafeLocationsResponse._();
    if (success != null) result.success = success;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  ToggleSafeLocationsResponse._();

  factory ToggleSafeLocationsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToggleSafeLocationsResponse()..mergeFromBuffer(data, registry);
  factory ToggleSafeLocationsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ToggleSafeLocationsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ToggleSafeLocationsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ToggleSafeLocationsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToggleSafeLocationsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ToggleSafeLocationsResponse copyWith(
          void Function(ToggleSafeLocationsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ToggleSafeLocationsResponse))
          as ToggleSafeLocationsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ToggleSafeLocationsResponse() / ToggleSafeLocationsResponse.new instead')
  static ToggleSafeLocationsResponse create() =>
      ToggleSafeLocationsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ToggleSafeLocationsResponse._();
  @$core.override
  ToggleSafeLocationsResponse createEmptyInstance() =>
      ToggleSafeLocationsResponse._();
  @$core.pragma('dart2js:noInline')
  static ToggleSafeLocationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ToggleSafeLocationsResponse>(
          ToggleSafeLocationsResponse.$_createMessage);
  static ToggleSafeLocationsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

/// SafeLocationsService manages geofence zones that suppress surveillance alerts.
///
/// HTTP mapping:
///   ListZones    GET    /api/surveillance/safe-locations
///   AddZone      POST   /api/surveillance/safe-locations
///   UpdateZone   PUT    /api/surveillance/safe-locations  (id via ?id=xxx or request body)
///   DeleteZone   DELETE /api/surveillance/safe-locations  (id via ?id=xxx or request body)
///   Over Connect the id travels in the request body (UpdateZoneRequest.id / DeleteZoneRequest.id);
///   the REST handler accepts either the ?id= query param or the body id.
///   Toggle       POST   /api/surveillance/safe-locations/toggle
class SafeLocationsServiceApi {
  final $pb.RpcClient _client;

  SafeLocationsServiceApi(this._client);

  $async.Future<ListZonesResponse> listZones(
          $pb.ClientContext? ctx, ListZonesRequest request) =>
      _client.invoke<ListZonesResponse>(ctx, 'SafeLocationsService',
          'ListZones', request, ListZonesResponse());
  $async.Future<AddZoneResponse> addZone(
          $pb.ClientContext? ctx, AddZoneRequest request) =>
      _client.invoke<AddZoneResponse>(
          ctx, 'SafeLocationsService', 'AddZone', request, AddZoneResponse());
  $async.Future<UpdateZoneResponse> updateZone(
          $pb.ClientContext? ctx, UpdateZoneRequest request) =>
      _client.invoke<UpdateZoneResponse>(ctx, 'SafeLocationsService',
          'UpdateZone', request, UpdateZoneResponse());
  $async.Future<DeleteZoneResponse> deleteZone(
          $pb.ClientContext? ctx, DeleteZoneRequest request) =>
      _client.invoke<DeleteZoneResponse>(ctx, 'SafeLocationsService',
          'DeleteZone', request, DeleteZoneResponse());
  $async.Future<ToggleSafeLocationsResponse> toggle(
          $pb.ClientContext? ctx, ToggleSafeLocationsRequest request) =>
      _client.invoke<ToggleSafeLocationsResponse>(ctx, 'SafeLocationsService',
          'Toggle', request, ToggleSafeLocationsResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
