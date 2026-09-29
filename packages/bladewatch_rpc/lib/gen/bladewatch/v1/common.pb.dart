// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// GpsLocation represents a geographic position with optional metadata.
class GpsLocation extends $pb.GeneratedMessage {
  factory GpsLocation({
    $core.double? lat,
    $core.double? lng,
    $core.double? altitudeM,
    $core.double? speedKmh,
    $core.double? accuracyM,
    $core.double? bearingDeg,
    $fixnum.Int64? timestampMs,
    $core.bool? hasLocation,
    $core.String? googleMapsUrl,
  }) {
    final result = GpsLocation._();
    if (lat != null) result.lat = lat;
    if (lng != null) result.lng = lng;
    if (altitudeM != null) result.altitudeM = altitudeM;
    if (speedKmh != null) result.speedKmh = speedKmh;
    if (accuracyM != null) result.accuracyM = accuracyM;
    if (bearingDeg != null) result.bearingDeg = bearingDeg;
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (hasLocation != null) result.hasLocation = hasLocation;
    if (googleMapsUrl != null) result.googleMapsUrl = googleMapsUrl;
    return result;
  }

  GpsLocation._();

  factory GpsLocation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpsLocation()..mergeFromBuffer(data, registry);
  factory GpsLocation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpsLocation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GpsLocation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GpsLocation.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'lat')
    ..aD(2, _omitFieldNames ? '' : 'lng')
    ..aD(3, _omitFieldNames ? '' : 'altitudeM')
    ..aD(4, _omitFieldNames ? '' : 'speedKmh')
    ..aD(5, _omitFieldNames ? '' : 'accuracyM')
    ..aD(6, _omitFieldNames ? '' : 'bearingDeg')
    ..aInt64(7, _omitFieldNames ? '' : 'timestampMs')
    ..aOB(8, _omitFieldNames ? '' : 'hasLocation')
    ..aOS(9, _omitFieldNames ? '' : 'googleMapsUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpsLocation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpsLocation copyWith(void Function(GpsLocation) updates) =>
      super.copyWith((message) => updates(message as GpsLocation))
          as GpsLocation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GpsLocation() / GpsLocation.new instead')
  static GpsLocation create() => GpsLocation._();
  static $pb.GeneratedMessage $_createMessage() => GpsLocation._();
  @$core.override
  GpsLocation createEmptyInstance() => GpsLocation._();
  @$core.pragma('dart2js:noInline')
  static GpsLocation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GpsLocation>(
          GpsLocation.$_createMessage);
  static GpsLocation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get lat => $_getN(0);
  @$pb.TagNumber(1)
  set lat($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLat() => $_has(0);
  @$pb.TagNumber(1)
  void clearLat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lng => $_getN(1);
  @$pb.TagNumber(2)
  set lng($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLng() => $_has(1);
  @$pb.TagNumber(2)
  void clearLng() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get altitudeM => $_getN(2);
  @$pb.TagNumber(3)
  set altitudeM($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAltitudeM() => $_has(2);
  @$pb.TagNumber(3)
  void clearAltitudeM() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get speedKmh => $_getN(3);
  @$pb.TagNumber(4)
  set speedKmh($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSpeedKmh() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpeedKmh() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get accuracyM => $_getN(4);
  @$pb.TagNumber(5)
  set accuracyM($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAccuracyM() => $_has(4);
  @$pb.TagNumber(5)
  void clearAccuracyM() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get bearingDeg => $_getN(5);
  @$pb.TagNumber(6)
  set bearingDeg($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBearingDeg() => $_has(5);
  @$pb.TagNumber(6)
  void clearBearingDeg() => $_clearField(6);

  /// Epoch ms when the fix was obtained.
  @$pb.TagNumber(7)
  $fixnum.Int64 get timestampMs => $_getI64(6);
  @$pb.TagNumber(7)
  set timestampMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTimestampMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearTimestampMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get hasLocation => $_getBF(7);
  @$pb.TagNumber(8)
  set hasLocation($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHasLocation() => $_has(7);
  @$pb.TagNumber(8)
  void clearHasLocation() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get googleMapsUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set googleMapsUrl($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasGoogleMapsUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearGoogleMapsUrl() => $_clearField(9);
}

/// StorageInfo carries free/total bytes for one storage volume.
class StorageInfo extends $pb.GeneratedMessage {
  factory StorageInfo({
    $fixnum.Int64? freeBytes,
    $fixnum.Int64? totalBytes,
    $core.String? freeFormatted,
    $core.String? totalFormatted,
    $core.int? usedPercent,
  }) {
    final result = StorageInfo._();
    if (freeBytes != null) result.freeBytes = freeBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (freeFormatted != null) result.freeFormatted = freeFormatted;
    if (totalFormatted != null) result.totalFormatted = totalFormatted;
    if (usedPercent != null) result.usedPercent = usedPercent;
    return result;
  }

  StorageInfo._();

  factory StorageInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StorageInfo()..mergeFromBuffer(data, registry);
  factory StorageInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StorageInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StorageInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StorageInfo.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'freeBytes')
    ..aInt64(2, _omitFieldNames ? '' : 'totalBytes')
    ..aOS(3, _omitFieldNames ? '' : 'freeFormatted')
    ..aOS(4, _omitFieldNames ? '' : 'totalFormatted')
    ..aI(5, _omitFieldNames ? '' : 'usedPercent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StorageInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StorageInfo copyWith(void Function(StorageInfo) updates) =>
      super.copyWith((message) => updates(message as StorageInfo))
          as StorageInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StorageInfo() / StorageInfo.new instead')
  static StorageInfo create() => StorageInfo._();
  static $pb.GeneratedMessage $_createMessage() => StorageInfo._();
  @$core.override
  StorageInfo createEmptyInstance() => StorageInfo._();
  @$core.pragma('dart2js:noInline')
  static StorageInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StorageInfo>(
          StorageInfo.$_createMessage);
  static StorageInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get freeBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set freeBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFreeBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearFreeBytes() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get totalBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set totalBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get freeFormatted => $_getSZ(2);
  @$pb.TagNumber(3)
  set freeFormatted($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFreeFormatted() => $_has(2);
  @$pb.TagNumber(3)
  void clearFreeFormatted() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get totalFormatted => $_getSZ(3);
  @$pb.TagNumber(4)
  set totalFormatted($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalFormatted() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalFormatted() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get usedPercent => $_getIZ(4);
  @$pb.TagNumber(5)
  set usedPercent($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUsedPercent() => $_has(4);
  @$pb.TagNumber(5)
  void clearUsedPercent() => $_clearField(5);
}

/// QuietHours defines a quiet window for push notifications (minutes since midnight).
class QuietHours extends $pb.GeneratedMessage {
  factory QuietHours({
    $core.int? startMin,
    $core.int? endMin,
    $core.bool? allowCritical,
  }) {
    final result = QuietHours._();
    if (startMin != null) result.startMin = startMin;
    if (endMin != null) result.endMin = endMin;
    if (allowCritical != null) result.allowCritical = allowCritical;
    return result;
  }

  QuietHours._();

  factory QuietHours.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuietHours()..mergeFromBuffer(data, registry);
  factory QuietHours.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QuietHours()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QuietHours',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: QuietHours.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'startMin')
    ..aI(2, _omitFieldNames ? '' : 'endMin')
    ..aOB(3, _omitFieldNames ? '' : 'allowCritical')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuietHours clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QuietHours copyWith(void Function(QuietHours) updates) =>
      super.copyWith((message) => updates(message as QuietHours)) as QuietHours;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QuietHours() / QuietHours.new instead')
  static QuietHours create() => QuietHours._();
  static $pb.GeneratedMessage $_createMessage() => QuietHours._();
  @$core.override
  QuietHours createEmptyInstance() => QuietHours._();
  @$core.pragma('dart2js:noInline')
  static QuietHours getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QuietHours>(QuietHours.$_createMessage);
  static QuietHours? _defaultInstance;

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

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
