// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/settings.proto.

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

export 'settings.pbenum.dart';

/// QualityTierInfo describes one recording quality tier.
class QualityTierInfo extends $pb.GeneratedMessage {
  factory QualityTierInfo({
    $core.String? displayName,
    $fixnum.Int64? bitrateBps,
    $core.double? bitrateMbps,
    $core.double? mbPerMinute,
    $core.double? gbPerHour,
    $core.String? qualityEquivalent,
  }) {
    final result = QualityTierInfo._();
    if (displayName != null) result.displayName = displayName;
    if (bitrateBps != null) result.bitrateBps = bitrateBps;
    if (bitrateMbps != null) result.bitrateMbps = bitrateMbps;
    if (mbPerMinute != null) result.mbPerMinute = mbPerMinute;
    if (gbPerHour != null) result.gbPerHour = gbPerHour;
    if (qualityEquivalent != null) result.qualityEquivalent = qualityEquivalent;
    return result;
  }

  QualityTierInfo._();

  factory QualityTierInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QualityTierInfo()..mergeFromBuffer(data, registry);
  factory QualityTierInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QualityTierInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QualityTierInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: QualityTierInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'displayName')
    ..aInt64(2, _omitFieldNames ? '' : 'bitrateBps')
    ..aD(3, _omitFieldNames ? '' : 'bitrateMbps')
    ..aD(4, _omitFieldNames ? '' : 'mbPerMinute')
    ..aD(5, _omitFieldNames ? '' : 'gbPerHour')
    ..aOS(6, _omitFieldNames ? '' : 'qualityEquivalent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QualityTierInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QualityTierInfo copyWith(void Function(QualityTierInfo) updates) =>
      super.copyWith((message) => updates(message as QualityTierInfo))
          as QualityTierInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QualityTierInfo() / QualityTierInfo.new instead')
  static QualityTierInfo create() => QualityTierInfo._();
  static $pb.GeneratedMessage $_createMessage() => QualityTierInfo._();
  @$core.override
  QualityTierInfo createEmptyInstance() => QualityTierInfo._();
  @$core.pragma('dart2js:noInline')
  static QualityTierInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QualityTierInfo>(
          QualityTierInfo.$_createMessage);
  static QualityTierInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get displayName => $_getSZ(0);
  @$pb.TagNumber(1)
  set displayName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDisplayName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDisplayName() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bitrateBps => $_getI64(1);
  @$pb.TagNumber(2)
  set bitrateBps($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBitrateBps() => $_has(1);
  @$pb.TagNumber(2)
  void clearBitrateBps() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get bitrateMbps => $_getN(2);
  @$pb.TagNumber(3)
  set bitrateMbps($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBitrateMbps() => $_has(2);
  @$pb.TagNumber(3)
  void clearBitrateMbps() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get mbPerMinute => $_getN(3);
  @$pb.TagNumber(4)
  set mbPerMinute($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMbPerMinute() => $_has(3);
  @$pb.TagNumber(4)
  void clearMbPerMinute() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get gbPerHour => $_getN(4);
  @$pb.TagNumber(5)
  set gbPerHour($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasGbPerHour() => $_has(4);
  @$pb.TagNumber(5)
  void clearGbPerHour() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get qualityEquivalent => $_getSZ(5);
  @$pb.TagNumber(6)
  set qualityEquivalent($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasQualityEquivalent() => $_has(5);
  @$pb.TagNumber(6)
  void clearQualityEquivalent() => $_clearField(6);
}

/// ActiveRecordingEstimate gives real-time size estimates for the current settings.
class ActiveRecordingEstimate extends $pb.GeneratedMessage {
  factory ActiveRecordingEstimate({
    $core.double? bitrateMbps,
    $core.double? mbPerMinute,
    $core.double? mbPer2Min,
    $core.double? gbPerHour,
    $core.int? minutesPerGb,
    $core.String? qualityEquivalent,
  }) {
    final result = ActiveRecordingEstimate._();
    if (bitrateMbps != null) result.bitrateMbps = bitrateMbps;
    if (mbPerMinute != null) result.mbPerMinute = mbPerMinute;
    if (mbPer2Min != null) result.mbPer2Min = mbPer2Min;
    if (gbPerHour != null) result.gbPerHour = gbPerHour;
    if (minutesPerGb != null) result.minutesPerGb = minutesPerGb;
    if (qualityEquivalent != null) result.qualityEquivalent = qualityEquivalent;
    return result;
  }

  ActiveRecordingEstimate._();

  factory ActiveRecordingEstimate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActiveRecordingEstimate()..mergeFromBuffer(data, registry);
  factory ActiveRecordingEstimate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActiveRecordingEstimate()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveRecordingEstimate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ActiveRecordingEstimate.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'bitrateMbps')
    ..aD(2, _omitFieldNames ? '' : 'mbPerMinute')
    ..aD(3, _omitFieldNames ? '' : 'mbPer2Min', protoName: 'mb_per_2_min')
    ..aD(4, _omitFieldNames ? '' : 'gbPerHour')
    ..aI(5, _omitFieldNames ? '' : 'minutesPerGb')
    ..aOS(6, _omitFieldNames ? '' : 'qualityEquivalent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveRecordingEstimate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveRecordingEstimate copyWith(
          void Function(ActiveRecordingEstimate) updates) =>
      super.copyWith((message) => updates(message as ActiveRecordingEstimate))
          as ActiveRecordingEstimate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ActiveRecordingEstimate() / ActiveRecordingEstimate.new instead')
  static ActiveRecordingEstimate create() => ActiveRecordingEstimate._();
  static $pb.GeneratedMessage $_createMessage() => ActiveRecordingEstimate._();
  @$core.override
  ActiveRecordingEstimate createEmptyInstance() => ActiveRecordingEstimate._();
  @$core.pragma('dart2js:noInline')
  static ActiveRecordingEstimate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ActiveRecordingEstimate>(
          ActiveRecordingEstimate.$_createMessage);
  static ActiveRecordingEstimate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get bitrateMbps => $_getN(0);
  @$pb.TagNumber(1)
  set bitrateMbps($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBitrateMbps() => $_has(0);
  @$pb.TagNumber(1)
  void clearBitrateMbps() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get mbPerMinute => $_getN(1);
  @$pb.TagNumber(2)
  set mbPerMinute($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMbPerMinute() => $_has(1);
  @$pb.TagNumber(2)
  void clearMbPerMinute() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get mbPer2Min => $_getN(2);
  @$pb.TagNumber(3)
  set mbPer2Min($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMbPer2Min() => $_has(2);
  @$pb.TagNumber(3)
  void clearMbPer2Min() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get gbPerHour => $_getN(3);
  @$pb.TagNumber(4)
  set gbPerHour($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGbPerHour() => $_has(3);
  @$pb.TagNumber(4)
  void clearGbPerHour() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get minutesPerGb => $_getIZ(4);
  @$pb.TagNumber(5)
  set minutesPerGb($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMinutesPerGb() => $_has(4);
  @$pb.TagNumber(5)
  void clearMinutesPerGb() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get qualityEquivalent => $_getSZ(5);
  @$pb.TagNumber(6)
  set qualityEquivalent($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasQualityEquivalent() => $_has(5);
  @$pb.TagNumber(6)
  void clearQualityEquivalent() => $_clearField(6);
}

class GetQualityRequest extends $pb.GeneratedMessage {
  factory GetQualityRequest() => GetQualityRequest._();

  GetQualityRequest._();

  factory GetQualityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetQualityRequest()..mergeFromBuffer(data, registry);
  factory GetQualityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetQualityRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetQualityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetQualityRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQualityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQualityRequest copyWith(void Function(GetQualityRequest) updates) =>
      super.copyWith((message) => updates(message as GetQualityRequest))
          as GetQualityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetQualityRequest() / GetQualityRequest.new instead')
  static GetQualityRequest create() => GetQualityRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetQualityRequest._();
  @$core.override
  GetQualityRequest createEmptyInstance() => GetQualityRequest._();
  @$core.pragma('dart2js:noInline')
  static GetQualityRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetQualityRequest>(
          GetQualityRequest.$_createMessage);
  static GetQualityRequest? _defaultInstance;
}

class GetQualityResponse extends $pb.GeneratedMessage {
  factory GetQualityResponse({
    $core.bool? success,
    $core.String? recordingQuality,
    $core.String? codec,
    $core.int? fps,
    $core.Iterable<$core.MapEntry<$core.String, QualityTierInfo>>?
        recordingQualityOptions,
    ActiveRecordingEstimate? activeRecordingEstimate,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? codecOptions,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? fpsOptions,
    $core.String? nativeResolution,
    $core.int? recordingSegmentMinutes,
    $core.String? recordingPriority,
  }) {
    final result = GetQualityResponse._();
    if (success != null) result.success = success;
    if (recordingQuality != null) result.recordingQuality = recordingQuality;
    if (codec != null) result.codec = codec;
    if (fps != null) result.fps = fps;
    if (recordingQualityOptions != null)
      result.recordingQualityOptions.addEntries(recordingQualityOptions);
    if (activeRecordingEstimate != null)
      result.activeRecordingEstimate = activeRecordingEstimate;
    if (codecOptions != null) result.codecOptions.addEntries(codecOptions);
    if (fpsOptions != null) result.fpsOptions.addEntries(fpsOptions);
    if (nativeResolution != null) result.nativeResolution = nativeResolution;
    if (recordingSegmentMinutes != null)
      result.recordingSegmentMinutes = recordingSegmentMinutes;
    if (recordingPriority != null) result.recordingPriority = recordingPriority;
    return result;
  }

  GetQualityResponse._();

  factory GetQualityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetQualityResponse()..mergeFromBuffer(data, registry);
  factory GetQualityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetQualityResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetQualityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetQualityResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'recordingQuality')
    ..aOS(3, _omitFieldNames ? '' : 'recordingCodec', protoName: 'codec')
    ..aI(4, _omitFieldNames ? '' : 'cameraFps', protoName: 'fps')
    ..m<$core.String, QualityTierInfo>(
        5, _omitFieldNames ? '' : 'recordingQualityOptions',
        entryClassName: 'GetQualityResponse.RecordingQualityOptionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: QualityTierInfo.$_createMessage,
        valueDefaultOrMaker: QualityTierInfo.getDefault,
        packageName: const $pb.PackageName('bladewatch.v1'))
    ..aOM<ActiveRecordingEstimate>(
        6, _omitFieldNames ? '' : 'activeRecordingEstimate',
        subBuilder: ActiveRecordingEstimate.$_createMessage)
    ..m<$core.String, $core.String>(7, _omitFieldNames ? '' : 'codecOptions',
        entryClassName: 'GetQualityResponse.CodecOptionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('bladewatch.v1'))
    ..m<$core.String, $core.String>(8, _omitFieldNames ? '' : 'fpsOptions',
        entryClassName: 'GetQualityResponse.FpsOptionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('bladewatch.v1'))
    ..aOS(9, _omitFieldNames ? '' : 'nativeResolution')
    ..aI(10, _omitFieldNames ? '' : 'recordingSegmentMinutes')
    ..aOS(11, _omitFieldNames ? '' : 'recordingPriority')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQualityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetQualityResponse copyWith(void Function(GetQualityResponse) updates) =>
      super.copyWith((message) => updates(message as GetQualityResponse))
          as GetQualityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetQualityResponse() / GetQualityResponse.new instead')
  static GetQualityResponse create() => GetQualityResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetQualityResponse._();
  @$core.override
  GetQualityResponse createEmptyInstance() => GetQualityResponse._();
  @$core.pragma('dart2js:noInline')
  static GetQualityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetQualityResponse>(
          GetQualityResponse.$_createMessage);
  static GetQualityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Current recording quality tier name (e.g. "STANDARD").
  @$pb.TagNumber(2)
  $core.String get recordingQuality => $_getSZ(1);
  @$pb.TagNumber(2)
  set recordingQuality($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRecordingQuality() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecordingQuality() => $_clearField(2);

  /// Current codec name ("H264" or "H265").
  @$pb.TagNumber(3)
  $core.String get codec => $_getSZ(2);
  @$pb.TagNumber(3)
  set codec($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCodec() => $_has(2);
  @$pb.TagNumber(3)
  void clearCodec() => $_clearField(3);

  /// Current FPS setting.
  @$pb.TagNumber(4)
  $core.int get fps => $_getIZ(3);
  @$pb.TagNumber(4)
  set fps($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFps() => $_has(3);
  @$pb.TagNumber(4)
  void clearFps() => $_clearField(4);

  /// Per-tier options keyed by tier name (e.g. "ECONOMY", "STANDARD", etc.).
  @$pb.TagNumber(5)
  $pb.PbMap<$core.String, QualityTierInfo> get recordingQualityOptions =>
      $_getMap(4);

  @$pb.TagNumber(6)
  ActiveRecordingEstimate get activeRecordingEstimate => $_getN(5);
  @$pb.TagNumber(6)
  set activeRecordingEstimate(ActiveRecordingEstimate value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasActiveRecordingEstimate() => $_has(5);
  @$pb.TagNumber(6)
  void clearActiveRecordingEstimate() => $_clearField(6);
  @$pb.TagNumber(6)
  ActiveRecordingEstimate ensureActiveRecordingEstimate() => $_ensure(5);

  /// Codec display options keyed by codec name.
  @$pb.TagNumber(7)
  $pb.PbMap<$core.String, $core.String> get codecOptions => $_getMap(6);

  /// FPS options keyed by numeric string (e.g. "15").
  @$pb.TagNumber(8)
  $pb.PbMap<$core.String, $core.String> get fpsOptions => $_getMap(7);

  @$pb.TagNumber(9)
  $core.String get nativeResolution => $_getSZ(8);
  @$pb.TagNumber(9)
  set nativeResolution($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasNativeResolution() => $_has(8);
  @$pb.TagNumber(9)
  void clearNativeResolution() => $_clearField(9);

  /// Recording segment length in minutes (e.g. 5, 10, 15).
  @$pb.TagNumber(10)
  $core.int get recordingSegmentMinutes => $_getIZ(9);
  @$pb.TagNumber(10)
  set recordingSegmentMinutes($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRecordingSegmentMinutes() => $_has(9);
  @$pb.TagNumber(10)
  void clearRecordingSegmentMinutes() => $_clearField(10);

  /// One of: PERFORMANCE, RELIABILITY. See RecordingPriority.
  @$pb.TagNumber(11)
  $core.String get recordingPriority => $_getSZ(10);
  @$pb.TagNumber(11)
  set recordingPriority($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasRecordingPriority() => $_has(10);
  @$pb.TagNumber(11)
  void clearRecordingPriority() => $_clearField(11);
}

class SetQualityRequest extends $pb.GeneratedMessage {
  factory SetQualityRequest({
    $core.String? recordingQuality,
    $core.String? codec,
    $core.String? streamingQuality,
    $core.int? fps,
    $core.int? recordingSegmentMinutes,
    $core.String? recordingPriority,
  }) {
    final result = SetQualityRequest._();
    if (recordingQuality != null) result.recordingQuality = recordingQuality;
    if (codec != null) result.codec = codec;
    if (streamingQuality != null) result.streamingQuality = streamingQuality;
    if (fps != null) result.fps = fps;
    if (recordingSegmentMinutes != null)
      result.recordingSegmentMinutes = recordingSegmentMinutes;
    if (recordingPriority != null) result.recordingPriority = recordingPriority;
    return result;
  }

  SetQualityRequest._();

  factory SetQualityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetQualityRequest()..mergeFromBuffer(data, registry);
  factory SetQualityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetQualityRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetQualityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetQualityRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'recordingQuality')
    ..aOS(2, _omitFieldNames ? '' : 'codec')
    ..aOS(3, _omitFieldNames ? '' : 'streamingQuality')
    ..aI(4, _omitFieldNames ? '' : 'fps')
    ..aI(5, _omitFieldNames ? '' : 'recordingSegmentMinutes')
    ..aOS(6, _omitFieldNames ? '' : 'recordingPriority')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetQualityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetQualityRequest copyWith(void Function(SetQualityRequest) updates) =>
      super.copyWith((message) => updates(message as SetQualityRequest))
          as SetQualityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetQualityRequest() / SetQualityRequest.new instead')
  static SetQualityRequest create() => SetQualityRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetQualityRequest._();
  @$core.override
  SetQualityRequest createEmptyInstance() => SetQualityRequest._();
  @$core.pragma('dart2js:noInline')
  static SetQualityRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetQualityRequest>(
          SetQualityRequest.$_createMessage);
  static SetQualityRequest? _defaultInstance;

  /// One of: ECONOMY, STANDARD, HIGH, PREMIUM, MAX. Leave empty to keep current.
  @$pb.TagNumber(1)
  $core.String get recordingQuality => $_getSZ(0);
  @$pb.TagNumber(1)
  set recordingQuality($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecordingQuality() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecordingQuality() => $_clearField(1);

  /// H264 only. Leave empty to keep current.
  @$pb.TagNumber(2)
  $core.String get codec => $_getSZ(1);
  @$pb.TagNumber(2)
  set codec($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCodec() => $_has(1);
  @$pb.TagNumber(2)
  void clearCodec() => $_clearField(2);

  /// Streaming quality preset. Leave empty to keep current.
  @$pb.TagNumber(3)
  $core.String get streamingQuality => $_getSZ(2);
  @$pb.TagNumber(3)
  set streamingQuality($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStreamingQuality() => $_has(2);
  @$pb.TagNumber(3)
  void clearStreamingQuality() => $_clearField(3);

  /// FPS (10-30). 0 = keep current.
  @$pb.TagNumber(4)
  $core.int get fps => $_getIZ(3);
  @$pb.TagNumber(4)
  set fps($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFps() => $_has(3);
  @$pb.TagNumber(4)
  void clearFps() => $_clearField(4);

  /// Recording segment length in minutes. 0 = keep current.
  @$pb.TagNumber(5)
  $core.int get recordingSegmentMinutes => $_getIZ(4);
  @$pb.TagNumber(5)
  set recordingSegmentMinutes($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRecordingSegmentMinutes() => $_has(4);
  @$pb.TagNumber(5)
  void clearRecordingSegmentMinutes() => $_clearField(5);

  /// One of: PERFORMANCE, RELIABILITY. Leave empty to keep current.
  @$pb.TagNumber(6)
  $core.String get recordingPriority => $_getSZ(5);
  @$pb.TagNumber(6)
  set recordingPriority($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRecordingPriority() => $_has(5);
  @$pb.TagNumber(6)
  void clearRecordingPriority() => $_clearField(6);
}

class SetQualityResponse extends $pb.GeneratedMessage {
  factory SetQualityResponse({
    $core.bool? success,
    $core.String? recordingQuality,
    $core.String? codec,
    $core.String? message,
    $core.String? error,
  }) {
    final result = SetQualityResponse._();
    if (success != null) result.success = success;
    if (recordingQuality != null) result.recordingQuality = recordingQuality;
    if (codec != null) result.codec = codec;
    if (message != null) result.message = message;
    if (error != null) result.error = error;
    return result;
  }

  SetQualityResponse._();

  factory SetQualityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetQualityResponse()..mergeFromBuffer(data, registry);
  factory SetQualityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetQualityResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetQualityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetQualityResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'recordingQuality')
    ..aOS(3, _omitFieldNames ? '' : 'recordingCodec', protoName: 'codec')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetQualityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetQualityResponse copyWith(void Function(SetQualityResponse) updates) =>
      super.copyWith((message) => updates(message as SetQualityResponse))
          as SetQualityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetQualityResponse() / SetQualityResponse.new instead')
  static SetQualityResponse create() => SetQualityResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetQualityResponse._();
  @$core.override
  SetQualityResponse createEmptyInstance() => SetQualityResponse._();
  @$core.pragma('dart2js:noInline')
  static SetQualityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetQualityResponse>(
          SetQualityResponse.$_createMessage);
  static SetQualityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get recordingQuality => $_getSZ(1);
  @$pb.TagNumber(2)
  set recordingQuality($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRecordingQuality() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecordingQuality() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get codec => $_getSZ(2);
  @$pb.TagNumber(3)
  set codec($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCodec() => $_has(2);
  @$pb.TagNumber(3)
  void clearCodec() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
}

class GetAppearanceRequest extends $pb.GeneratedMessage {
  factory GetAppearanceRequest() => GetAppearanceRequest._();

  GetAppearanceRequest._();

  factory GetAppearanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAppearanceRequest()..mergeFromBuffer(data, registry);
  factory GetAppearanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAppearanceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAppearanceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetAppearanceRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAppearanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAppearanceRequest copyWith(void Function(GetAppearanceRequest) updates) =>
      super.copyWith((message) => updates(message as GetAppearanceRequest))
          as GetAppearanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAppearanceRequest() / GetAppearanceRequest.new instead')
  static GetAppearanceRequest create() => GetAppearanceRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAppearanceRequest._();
  @$core.override
  GetAppearanceRequest createEmptyInstance() => GetAppearanceRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAppearanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAppearanceRequest>(
          GetAppearanceRequest.$_createMessage);
  static GetAppearanceRequest? _defaultInstance;
}

class GetAppearanceResponse extends $pb.GeneratedMessage {
  factory GetAppearanceResponse({
    $core.bool? success,
    $core.String? theme,
    $core.String? locale,
  }) {
    final result = GetAppearanceResponse._();
    if (success != null) result.success = success;
    if (theme != null) result.theme = theme;
    if (locale != null) result.locale = locale;
    return result;
  }

  GetAppearanceResponse._();

  factory GetAppearanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAppearanceResponse()..mergeFromBuffer(data, registry);
  factory GetAppearanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAppearanceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAppearanceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetAppearanceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'theme')
    ..aOS(3, _omitFieldNames ? '' : 'locale')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAppearanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAppearanceResponse copyWith(
          void Function(GetAppearanceResponse) updates) =>
      super.copyWith((message) => updates(message as GetAppearanceResponse))
          as GetAppearanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAppearanceResponse() / GetAppearanceResponse.new instead')
  static GetAppearanceResponse create() => GetAppearanceResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetAppearanceResponse._();
  @$core.override
  GetAppearanceResponse createEmptyInstance() => GetAppearanceResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAppearanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAppearanceResponse>(
          GetAppearanceResponse.$_createMessage);
  static GetAppearanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get theme => $_getSZ(1);
  @$pb.TagNumber(2)
  set theme($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTheme() => $_has(1);
  @$pb.TagNumber(2)
  void clearTheme() => $_clearField(2);

  /// BCP-47 locale tag or "auto".
  @$pb.TagNumber(3)
  $core.String get locale => $_getSZ(2);
  @$pb.TagNumber(3)
  set locale($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocale() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocale() => $_clearField(3);
}

class SetAppearanceRequest extends $pb.GeneratedMessage {
  factory SetAppearanceRequest({
    $core.String? theme,
    $core.String? locale,
  }) {
    final result = SetAppearanceRequest._();
    if (theme != null) result.theme = theme;
    if (locale != null) result.locale = locale;
    return result;
  }

  SetAppearanceRequest._();

  factory SetAppearanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetAppearanceRequest()..mergeFromBuffer(data, registry);
  factory SetAppearanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetAppearanceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetAppearanceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetAppearanceRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'theme')
    ..aOS(2, _omitFieldNames ? '' : 'locale')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAppearanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAppearanceRequest copyWith(void Function(SetAppearanceRequest) updates) =>
      super.copyWith((message) => updates(message as SetAppearanceRequest))
          as SetAppearanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetAppearanceRequest() / SetAppearanceRequest.new instead')
  static SetAppearanceRequest create() => SetAppearanceRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetAppearanceRequest._();
  @$core.override
  SetAppearanceRequest createEmptyInstance() => SetAppearanceRequest._();
  @$core.pragma('dart2js:noInline')
  static SetAppearanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetAppearanceRequest>(
          SetAppearanceRequest.$_createMessage);
  static SetAppearanceRequest? _defaultInstance;

  /// One of: dark, light, auto. Leave empty to keep current.
  @$pb.TagNumber(1)
  $core.String get theme => $_getSZ(0);
  @$pb.TagNumber(1)
  set theme($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTheme() => $_has(0);
  @$pb.TagNumber(1)
  void clearTheme() => $_clearField(1);

  /// BCP-47 locale tag or "auto". Leave empty to keep current.
  @$pb.TagNumber(2)
  $core.String get locale => $_getSZ(1);
  @$pb.TagNumber(2)
  set locale($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocale() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocale() => $_clearField(2);
}

class SetAppearanceResponse extends $pb.GeneratedMessage {
  factory SetAppearanceResponse({
    $core.bool? success,
    $core.String? theme,
    $core.String? locale,
    $core.String? error,
  }) {
    final result = SetAppearanceResponse._();
    if (success != null) result.success = success;
    if (theme != null) result.theme = theme;
    if (locale != null) result.locale = locale;
    if (error != null) result.error = error;
    return result;
  }

  SetAppearanceResponse._();

  factory SetAppearanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetAppearanceResponse()..mergeFromBuffer(data, registry);
  factory SetAppearanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetAppearanceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetAppearanceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetAppearanceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'theme')
    ..aOS(3, _omitFieldNames ? '' : 'locale')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAppearanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAppearanceResponse copyWith(
          void Function(SetAppearanceResponse) updates) =>
      super.copyWith((message) => updates(message as SetAppearanceResponse))
          as SetAppearanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetAppearanceResponse() / SetAppearanceResponse.new instead')
  static SetAppearanceResponse create() => SetAppearanceResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetAppearanceResponse._();
  @$core.override
  SetAppearanceResponse createEmptyInstance() => SetAppearanceResponse._();
  @$core.pragma('dart2js:noInline')
  static SetAppearanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetAppearanceResponse>(
          SetAppearanceResponse.$_createMessage);
  static SetAppearanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get theme => $_getSZ(1);
  @$pb.TagNumber(2)
  set theme($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTheme() => $_has(1);
  @$pb.TagNumber(2)
  void clearTheme() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get locale => $_getSZ(2);
  @$pb.TagNumber(3)
  set locale($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocale() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocale() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
}

class GetLocaleRequest extends $pb.GeneratedMessage {
  factory GetLocaleRequest() => GetLocaleRequest._();

  GetLocaleRequest._();

  factory GetLocaleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLocaleRequest()..mergeFromBuffer(data, registry);
  factory GetLocaleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLocaleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLocaleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetLocaleRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLocaleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLocaleRequest copyWith(void Function(GetLocaleRequest) updates) =>
      super.copyWith((message) => updates(message as GetLocaleRequest))
          as GetLocaleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetLocaleRequest() / GetLocaleRequest.new instead')
  static GetLocaleRequest create() => GetLocaleRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetLocaleRequest._();
  @$core.override
  GetLocaleRequest createEmptyInstance() => GetLocaleRequest._();
  @$core.pragma('dart2js:noInline')
  static GetLocaleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetLocaleRequest>(
          GetLocaleRequest.$_createMessage);
  static GetLocaleRequest? _defaultInstance;
}

class GetLocaleResponse extends $pb.GeneratedMessage {
  factory GetLocaleResponse({
    $core.String? lang,
    $core.Iterable<$core.MapEntry<$core.String, $core.bool>>? supported,
  }) {
    final result = GetLocaleResponse._();
    if (lang != null) result.lang = lang;
    if (supported != null) result.supported.addEntries(supported);
    return result;
  }

  GetLocaleResponse._();

  factory GetLocaleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLocaleResponse()..mergeFromBuffer(data, registry);
  factory GetLocaleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLocaleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLocaleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetLocaleResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'lang')
    ..m<$core.String, $core.bool>(2, _omitFieldNames ? '' : 'supported',
        entryClassName: 'GetLocaleResponse.SupportedEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('bladewatch.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLocaleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLocaleResponse copyWith(void Function(GetLocaleResponse) updates) =>
      super.copyWith((message) => updates(message as GetLocaleResponse))
          as GetLocaleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetLocaleResponse() / GetLocaleResponse.new instead')
  static GetLocaleResponse create() => GetLocaleResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetLocaleResponse._();
  @$core.override
  GetLocaleResponse createEmptyInstance() => GetLocaleResponse._();
  @$core.pragma('dart2js:noInline')
  static GetLocaleResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetLocaleResponse>(
          GetLocaleResponse.$_createMessage);
  static GetLocaleResponse? _defaultInstance;

  /// Active BCP-47 locale tag.
  @$pb.TagNumber(1)
  $core.String get lang => $_getSZ(0);
  @$pb.TagNumber(1)
  set lang($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLang() => $_has(0);
  @$pb.TagNumber(1)
  void clearLang() => $_clearField(1);

  /// All supported tags mapped to true.
  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.bool> get supported => $_getMap(1);
}

class SetLocaleRequest extends $pb.GeneratedMessage {
  factory SetLocaleRequest({
    $core.String? lang,
  }) {
    final result = SetLocaleRequest._();
    if (lang != null) result.lang = lang;
    return result;
  }

  SetLocaleRequest._();

  factory SetLocaleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLocaleRequest()..mergeFromBuffer(data, registry);
  factory SetLocaleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLocaleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetLocaleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetLocaleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'lang')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLocaleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLocaleRequest copyWith(void Function(SetLocaleRequest) updates) =>
      super.copyWith((message) => updates(message as SetLocaleRequest))
          as SetLocaleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetLocaleRequest() / SetLocaleRequest.new instead')
  static SetLocaleRequest create() => SetLocaleRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetLocaleRequest._();
  @$core.override
  SetLocaleRequest createEmptyInstance() => SetLocaleRequest._();
  @$core.pragma('dart2js:noInline')
  static SetLocaleRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetLocaleRequest>(
          SetLocaleRequest.$_createMessage);
  static SetLocaleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get lang => $_getSZ(0);
  @$pb.TagNumber(1)
  set lang($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLang() => $_has(0);
  @$pb.TagNumber(1)
  void clearLang() => $_clearField(1);
}

class SetLocaleResponse extends $pb.GeneratedMessage {
  factory SetLocaleResponse({
    $core.String? lang,
  }) {
    final result = SetLocaleResponse._();
    if (lang != null) result.lang = lang;
    return result;
  }

  SetLocaleResponse._();

  factory SetLocaleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLocaleResponse()..mergeFromBuffer(data, registry);
  factory SetLocaleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLocaleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetLocaleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetLocaleResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'lang')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLocaleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLocaleResponse copyWith(void Function(SetLocaleResponse) updates) =>
      super.copyWith((message) => updates(message as SetLocaleResponse))
          as SetLocaleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetLocaleResponse() / SetLocaleResponse.new instead')
  static SetLocaleResponse create() => SetLocaleResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetLocaleResponse._();
  @$core.override
  SetLocaleResponse createEmptyInstance() => SetLocaleResponse._();
  @$core.pragma('dart2js:noInline')
  static SetLocaleResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetLocaleResponse>(
          SetLocaleResponse.$_createMessage);
  static SetLocaleResponse? _defaultInstance;

  /// Resolved locale tag that was applied.
  @$pb.TagNumber(1)
  $core.String get lang => $_getSZ(0);
  @$pb.TagNumber(1)
  set lang($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLang() => $_has(0);
  @$pb.TagNumber(1)
  void clearLang() => $_clearField(1);
}

class SetRecordingModeRequest extends $pb.GeneratedMessage {
  factory SetRecordingModeRequest({
    $core.String? mode,
  }) {
    final result = SetRecordingModeRequest._();
    if (mode != null) result.mode = mode;
    return result;
  }

  SetRecordingModeRequest._();

  factory SetRecordingModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRecordingModeRequest()..mergeFromBuffer(data, registry);
  factory SetRecordingModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRecordingModeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRecordingModeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetRecordingModeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'mode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRecordingModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRecordingModeRequest copyWith(
          void Function(SetRecordingModeRequest) updates) =>
      super.copyWith((message) => updates(message as SetRecordingModeRequest))
          as SetRecordingModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetRecordingModeRequest() / SetRecordingModeRequest.new instead')
  static SetRecordingModeRequest create() => SetRecordingModeRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetRecordingModeRequest._();
  @$core.override
  SetRecordingModeRequest createEmptyInstance() => SetRecordingModeRequest._();
  @$core.pragma('dart2js:noInline')
  static SetRecordingModeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRecordingModeRequest>(
          SetRecordingModeRequest.$_createMessage);
  static SetRecordingModeRequest? _defaultInstance;

  /// Recording mode, e.g. "CONTINUOUS", "EVENTS", "OFF".
  @$pb.TagNumber(1)
  $core.String get mode => $_getSZ(0);
  @$pb.TagNumber(1)
  set mode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearMode() => $_clearField(1);
}

class SetRecordingModeResponse extends $pb.GeneratedMessage {
  factory SetRecordingModeResponse({
    $core.bool? success,
    $core.String? mode,
    $core.String? error,
  }) {
    final result = SetRecordingModeResponse._();
    if (success != null) result.success = success;
    if (mode != null) result.mode = mode;
    if (error != null) result.error = error;
    return result;
  }

  SetRecordingModeResponse._();

  factory SetRecordingModeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRecordingModeResponse()..mergeFromBuffer(data, registry);
  factory SetRecordingModeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetRecordingModeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetRecordingModeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetRecordingModeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'mode')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRecordingModeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetRecordingModeResponse copyWith(
          void Function(SetRecordingModeResponse) updates) =>
      super.copyWith((message) => updates(message as SetRecordingModeResponse))
          as SetRecordingModeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetRecordingModeResponse() / SetRecordingModeResponse.new instead')
  static SetRecordingModeResponse create() => SetRecordingModeResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetRecordingModeResponse._();
  @$core.override
  SetRecordingModeResponse createEmptyInstance() =>
      SetRecordingModeResponse._();
  @$core.pragma('dart2js:noInline')
  static SetRecordingModeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetRecordingModeResponse>(
          SetRecordingModeResponse.$_createMessage);
  static SetRecordingModeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// The mode that was applied.
  @$pb.TagNumber(2)
  $core.String get mode => $_getSZ(1);
  @$pb.TagNumber(2)
  set mode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearMode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

/// SettingsService manages recording quality, appearance, and locale settings.
///
/// HTTP mapping:
///   GetQuality       GET  /api/settings/quality
///   SetQuality       POST /api/settings/quality
///   GetAppearance    GET  /api/settings/appearance
///   SetAppearance    POST /api/settings/appearance
///   GetLocale        GET  /api/i18n/lang
///   SetLocale        POST /api/i18n/lang
///   SetRecordingMode POST /api/recording/mode
class SettingsServiceApi {
  final $pb.RpcClient _client;

  SettingsServiceApi(this._client);

  $async.Future<GetQualityResponse> getQuality(
          $pb.ClientContext? ctx, GetQualityRequest request) =>
      _client.invoke<GetQualityResponse>(
          ctx, 'SettingsService', 'GetQuality', request, GetQualityResponse());
  $async.Future<SetQualityResponse> setQuality(
          $pb.ClientContext? ctx, SetQualityRequest request) =>
      _client.invoke<SetQualityResponse>(
          ctx, 'SettingsService', 'SetQuality', request, SetQualityResponse());
  $async.Future<GetAppearanceResponse> getAppearance(
          $pb.ClientContext? ctx, GetAppearanceRequest request) =>
      _client.invoke<GetAppearanceResponse>(ctx, 'SettingsService',
          'GetAppearance', request, GetAppearanceResponse());
  $async.Future<SetAppearanceResponse> setAppearance(
          $pb.ClientContext? ctx, SetAppearanceRequest request) =>
      _client.invoke<SetAppearanceResponse>(ctx, 'SettingsService',
          'SetAppearance', request, SetAppearanceResponse());
  $async.Future<GetLocaleResponse> getLocale(
          $pb.ClientContext? ctx, GetLocaleRequest request) =>
      _client.invoke<GetLocaleResponse>(
          ctx, 'SettingsService', 'GetLocale', request, GetLocaleResponse());
  $async.Future<SetLocaleResponse> setLocale(
          $pb.ClientContext? ctx, SetLocaleRequest request) =>
      _client.invoke<SetLocaleResponse>(
          ctx, 'SettingsService', 'SetLocale', request, SetLocaleResponse());
  $async.Future<SetRecordingModeResponse> setRecordingMode(
          $pb.ClientContext? ctx, SetRecordingModeRequest request) =>
      _client.invoke<SetRecordingModeResponse>(ctx, 'SettingsService',
          'SetRecordingMode', request, SetRecordingModeResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
