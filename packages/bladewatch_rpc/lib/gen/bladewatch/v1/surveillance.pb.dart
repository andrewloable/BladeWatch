// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/surveillance.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pbenum.dart';

/// SurveillanceConfig is the full configuration sent to/from the pipeline.
class SurveillanceConfig extends $pb.GeneratedMessage {
  factory SurveillanceConfig({
    $core.bool? enabled,
    $core.int? sensitivity,
    $core.int? distance,
    $core.double? sadThreshold,
    $core.int? preRecordSeconds,
    $core.int? postRecordSeconds,
    $core.int? totalBlocks,
    $core.int? flashImmunity,
    $core.bool? aiEnabled,
    $core.double? aiConfidence,
    $core.double? minObjectSize,
    $core.bool? detectPerson,
    $core.bool? detectCar,
    $core.bool? detectBike,
    $core.String? distancePreset,
    $core.int? blockSize,
    $core.double? maxDistanceM,
    $core.bool? nightMode,
    $core.double? shadowThreshold,
    $core.double? densityThreshold,
    $core.int? alarmBlockThreshold,
    $core.String? recordingQuality,
    $core.String? recordingCodec,
    $core.bool? cameraFront,
    $core.bool? cameraRight,
    $core.bool? cameraRear,
    $core.bool? cameraLeft,
    $core.String? deterrentAction,
    $core.int? deterrentCooldownSeconds,
  }) {
    final result = SurveillanceConfig._();
    if (enabled != null) result.enabled = enabled;
    if (sensitivity != null) result.sensitivity = sensitivity;
    if (distance != null) result.distance = distance;
    if (sadThreshold != null) result.sadThreshold = sadThreshold;
    if (preRecordSeconds != null) result.preRecordSeconds = preRecordSeconds;
    if (postRecordSeconds != null) result.postRecordSeconds = postRecordSeconds;
    if (totalBlocks != null) result.totalBlocks = totalBlocks;
    if (flashImmunity != null) result.flashImmunity = flashImmunity;
    if (aiEnabled != null) result.aiEnabled = aiEnabled;
    if (aiConfidence != null) result.aiConfidence = aiConfidence;
    if (minObjectSize != null) result.minObjectSize = minObjectSize;
    if (detectPerson != null) result.detectPerson = detectPerson;
    if (detectCar != null) result.detectCar = detectCar;
    if (detectBike != null) result.detectBike = detectBike;
    if (distancePreset != null) result.distancePreset = distancePreset;
    if (blockSize != null) result.blockSize = blockSize;
    if (maxDistanceM != null) result.maxDistanceM = maxDistanceM;
    if (nightMode != null) result.nightMode = nightMode;
    if (shadowThreshold != null) result.shadowThreshold = shadowThreshold;
    if (densityThreshold != null) result.densityThreshold = densityThreshold;
    if (alarmBlockThreshold != null)
      result.alarmBlockThreshold = alarmBlockThreshold;
    if (recordingQuality != null) result.recordingQuality = recordingQuality;
    if (recordingCodec != null) result.recordingCodec = recordingCodec;
    if (cameraFront != null) result.cameraFront = cameraFront;
    if (cameraRight != null) result.cameraRight = cameraRight;
    if (cameraRear != null) result.cameraRear = cameraRear;
    if (cameraLeft != null) result.cameraLeft = cameraLeft;
    if (deterrentAction != null) result.deterrentAction = deterrentAction;
    if (deterrentCooldownSeconds != null)
      result.deterrentCooldownSeconds = deterrentCooldownSeconds;
    return result;
  }

  SurveillanceConfig._();

  factory SurveillanceConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SurveillanceConfig()..mergeFromBuffer(data, registry);
  factory SurveillanceConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SurveillanceConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SurveillanceConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SurveillanceConfig.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aI(2, _omitFieldNames ? '' : 'sensitivity')
    ..aI(3, _omitFieldNames ? '' : 'distance')
    ..aD(4, _omitFieldNames ? '' : 'sadThreshold')
    ..aI(5, _omitFieldNames ? '' : 'preRecordSeconds')
    ..aI(6, _omitFieldNames ? '' : 'postRecordSeconds')
    ..aI(7, _omitFieldNames ? '' : 'totalBlocks')
    ..aI(8, _omitFieldNames ? '' : 'flashImmunity')
    ..aOB(9, _omitFieldNames ? '' : 'aiEnabled')
    ..aD(10, _omitFieldNames ? '' : 'aiConfidence')
    ..aD(11, _omitFieldNames ? '' : 'minObjectSize')
    ..aOB(12, _omitFieldNames ? '' : 'detectPerson')
    ..aOB(13, _omitFieldNames ? '' : 'detectCar')
    ..aOB(14, _omitFieldNames ? '' : 'detectBike')
    ..aOS(15, _omitFieldNames ? '' : 'distancePreset')
    ..aI(16, _omitFieldNames ? '' : 'blockSize')
    ..aD(17, _omitFieldNames ? '' : 'maxDistanceM')
    ..aOB(18, _omitFieldNames ? '' : 'nightMode')
    ..aD(19, _omitFieldNames ? '' : 'shadowThreshold')
    ..aD(20, _omitFieldNames ? '' : 'densityThreshold')
    ..aI(21, _omitFieldNames ? '' : 'alarmBlockThreshold')
    ..aOS(22, _omitFieldNames ? '' : 'recordingQuality')
    ..aOS(23, _omitFieldNames ? '' : 'recordingCodec')
    ..aOB(24, _omitFieldNames ? '' : 'cameraFront')
    ..aOB(25, _omitFieldNames ? '' : 'cameraRight')
    ..aOB(26, _omitFieldNames ? '' : 'cameraRear')
    ..aOB(27, _omitFieldNames ? '' : 'cameraLeft')
    ..aOS(28, _omitFieldNames ? '' : 'deterrentAction')
    ..aI(29, _omitFieldNames ? '' : 'deterrentCooldownSeconds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SurveillanceConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SurveillanceConfig copyWith(void Function(SurveillanceConfig) updates) =>
      super.copyWith((message) => updates(message as SurveillanceConfig))
          as SurveillanceConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SurveillanceConfig() / SurveillanceConfig.new instead')
  static SurveillanceConfig create() => SurveillanceConfig._();
  static $pb.GeneratedMessage $_createMessage() => SurveillanceConfig._();
  @$core.override
  SurveillanceConfig createEmptyInstance() => SurveillanceConfig._();
  @$core.pragma('dart2js:noInline')
  static SurveillanceConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SurveillanceConfig>(
          SurveillanceConfig.$_createMessage);
  static SurveillanceConfig? _defaultInstance;

  /// Whether surveillance is enabled (persisted user preference).
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  /// Motion detection sensitivity level 1-5 (1=strict, 5=aggressive).
  @$pb.TagNumber(2)
  $core.int get sensitivity => $_getIZ(1);
  @$pb.TagNumber(2)
  set sensitivity($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSensitivity() => $_has(1);
  @$pb.TagNumber(2)
  void clearSensitivity() => $_clearField(2);

  /// Detection distance level 1-5 (1=near/3m, 5=far/15m).
  @$pb.TagNumber(3)
  $core.int get distance => $_getIZ(2);
  @$pb.TagNumber(3)
  set distance($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDistance() => $_has(2);
  @$pb.TagNumber(3)
  void clearDistance() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get sadThreshold => $_getN(3);
  @$pb.TagNumber(4)
  set sadThreshold($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSadThreshold() => $_has(3);
  @$pb.TagNumber(4)
  void clearSadThreshold() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get preRecordSeconds => $_getIZ(4);
  @$pb.TagNumber(5)
  set preRecordSeconds($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPreRecordSeconds() => $_has(4);
  @$pb.TagNumber(5)
  void clearPreRecordSeconds() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get postRecordSeconds => $_getIZ(5);
  @$pb.TagNumber(6)
  set postRecordSeconds($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPostRecordSeconds() => $_has(5);
  @$pb.TagNumber(6)
  void clearPostRecordSeconds() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get totalBlocks => $_getIZ(6);
  @$pb.TagNumber(7)
  set totalBlocks($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTotalBlocks() => $_has(6);
  @$pb.TagNumber(7)
  void clearTotalBlocks() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get flashImmunity => $_getIZ(7);
  @$pb.TagNumber(8)
  set flashImmunity($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFlashImmunity() => $_has(7);
  @$pb.TagNumber(8)
  void clearFlashImmunity() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get aiEnabled => $_getBF(8);
  @$pb.TagNumber(9)
  set aiEnabled($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAiEnabled() => $_has(8);
  @$pb.TagNumber(9)
  void clearAiEnabled() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get aiConfidence => $_getN(9);
  @$pb.TagNumber(10)
  set aiConfidence($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAiConfidence() => $_has(9);
  @$pb.TagNumber(10)
  void clearAiConfidence() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get minObjectSize => $_getN(10);
  @$pb.TagNumber(11)
  set minObjectSize($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasMinObjectSize() => $_has(10);
  @$pb.TagNumber(11)
  void clearMinObjectSize() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.bool get detectPerson => $_getBF(11);
  @$pb.TagNumber(12)
  set detectPerson($core.bool value) => $_setBool(11, value);
  @$pb.TagNumber(12)
  $core.bool hasDetectPerson() => $_has(11);
  @$pb.TagNumber(12)
  void clearDetectPerson() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.bool get detectCar => $_getBF(12);
  @$pb.TagNumber(13)
  set detectCar($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasDetectCar() => $_has(12);
  @$pb.TagNumber(13)
  void clearDetectCar() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get detectBike => $_getBF(13);
  @$pb.TagNumber(14)
  set detectBike($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDetectBike() => $_has(13);
  @$pb.TagNumber(14)
  void clearDetectBike() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get distancePreset => $_getSZ(14);
  @$pb.TagNumber(15)
  set distancePreset($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasDistancePreset() => $_has(14);
  @$pb.TagNumber(15)
  void clearDistancePreset() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.int get blockSize => $_getIZ(15);
  @$pb.TagNumber(16)
  set blockSize($core.int value) => $_setSignedInt32(15, value);
  @$pb.TagNumber(16)
  $core.bool hasBlockSize() => $_has(15);
  @$pb.TagNumber(16)
  void clearBlockSize() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.double get maxDistanceM => $_getN(16);
  @$pb.TagNumber(17)
  set maxDistanceM($core.double value) => $_setDouble(16, value);
  @$pb.TagNumber(17)
  $core.bool hasMaxDistanceM() => $_has(16);
  @$pb.TagNumber(17)
  void clearMaxDistanceM() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.bool get nightMode => $_getBF(17);
  @$pb.TagNumber(18)
  set nightMode($core.bool value) => $_setBool(17, value);
  @$pb.TagNumber(18)
  $core.bool hasNightMode() => $_has(17);
  @$pb.TagNumber(18)
  void clearNightMode() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.double get shadowThreshold => $_getN(18);
  @$pb.TagNumber(19)
  set shadowThreshold($core.double value) => $_setDouble(18, value);
  @$pb.TagNumber(19)
  $core.bool hasShadowThreshold() => $_has(18);
  @$pb.TagNumber(19)
  void clearShadowThreshold() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.double get densityThreshold => $_getN(19);
  @$pb.TagNumber(20)
  set densityThreshold($core.double value) => $_setDouble(19, value);
  @$pb.TagNumber(20)
  $core.bool hasDensityThreshold() => $_has(19);
  @$pb.TagNumber(20)
  void clearDensityThreshold() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.int get alarmBlockThreshold => $_getIZ(20);
  @$pb.TagNumber(21)
  set alarmBlockThreshold($core.int value) => $_setSignedInt32(20, value);
  @$pb.TagNumber(21)
  $core.bool hasAlarmBlockThreshold() => $_has(20);
  @$pb.TagNumber(21)
  void clearAlarmBlockThreshold() => $_clearField(21);

  /// Recording quality tier: ECONOMY/STANDARD/HIGH/PREMIUM/MAX.
  @$pb.TagNumber(22)
  $core.String get recordingQuality => $_getSZ(21);
  @$pb.TagNumber(22)
  set recordingQuality($core.String value) => $_setString(21, value);
  @$pb.TagNumber(22)
  $core.bool hasRecordingQuality() => $_has(21);
  @$pb.TagNumber(22)
  void clearRecordingQuality() => $_clearField(22);

  /// Codec: H264 or H265.
  @$pb.TagNumber(23)
  $core.String get recordingCodec => $_getSZ(22);
  @$pb.TagNumber(23)
  set recordingCodec($core.String value) => $_setString(22, value);
  @$pb.TagNumber(23)
  $core.bool hasRecordingCodec() => $_has(22);
  @$pb.TagNumber(23)
  void clearRecordingCodec() => $_clearField(23);

  /// Per-camera enable flags.
  @$pb.TagNumber(24)
  $core.bool get cameraFront => $_getBF(23);
  @$pb.TagNumber(24)
  set cameraFront($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(24)
  $core.bool hasCameraFront() => $_has(23);
  @$pb.TagNumber(24)
  void clearCameraFront() => $_clearField(24);

  @$pb.TagNumber(25)
  $core.bool get cameraRight => $_getBF(24);
  @$pb.TagNumber(25)
  set cameraRight($core.bool value) => $_setBool(24, value);
  @$pb.TagNumber(25)
  $core.bool hasCameraRight() => $_has(24);
  @$pb.TagNumber(25)
  void clearCameraRight() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.bool get cameraRear => $_getBF(25);
  @$pb.TagNumber(26)
  set cameraRear($core.bool value) => $_setBool(25, value);
  @$pb.TagNumber(26)
  $core.bool hasCameraRear() => $_has(25);
  @$pb.TagNumber(26)
  void clearCameraRear() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.bool get cameraLeft => $_getBF(26);
  @$pb.TagNumber(27)
  set cameraLeft($core.bool value) => $_setBool(26, value);
  @$pb.TagNumber(27)
  $core.bool hasCameraLeft() => $_has(26);
  @$pb.TagNumber(27)
  void clearCameraLeft() => $_clearField(27);

  /// Deterrent action: "silent", "flash", "beep", etc.
  @$pb.TagNumber(28)
  $core.String get deterrentAction => $_getSZ(27);
  @$pb.TagNumber(28)
  set deterrentAction($core.String value) => $_setString(27, value);
  @$pb.TagNumber(28)
  $core.bool hasDeterrentAction() => $_has(27);
  @$pb.TagNumber(28)
  void clearDeterrentAction() => $_clearField(28);

  /// Minimum seconds between deterrent triggers.
  @$pb.TagNumber(29)
  $core.int get deterrentCooldownSeconds => $_getIZ(28);
  @$pb.TagNumber(29)
  set deterrentCooldownSeconds($core.int value) => $_setSignedInt32(28, value);
  @$pb.TagNumber(29)
  $core.bool hasDeterrentCooldownSeconds() => $_has(28);
  @$pb.TagNumber(29)
  void clearDeterrentCooldownSeconds() => $_clearField(29);
}

class GetSurveillanceConfigRequest extends $pb.GeneratedMessage {
  factory GetSurveillanceConfigRequest() => GetSurveillanceConfigRequest._();

  GetSurveillanceConfigRequest._();

  factory GetSurveillanceConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceConfigRequest()..mergeFromBuffer(data, registry);
  factory GetSurveillanceConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceConfigRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSurveillanceConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSurveillanceConfigRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceConfigRequest copyWith(
          void Function(GetSurveillanceConfigRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetSurveillanceConfigRequest))
          as GetSurveillanceConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSurveillanceConfigRequest() / GetSurveillanceConfigRequest.new instead')
  static GetSurveillanceConfigRequest create() =>
      GetSurveillanceConfigRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetSurveillanceConfigRequest._();
  @$core.override
  GetSurveillanceConfigRequest createEmptyInstance() =>
      GetSurveillanceConfigRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSurveillanceConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSurveillanceConfigRequest>(
          GetSurveillanceConfigRequest.$_createMessage);
  static GetSurveillanceConfigRequest? _defaultInstance;
}

class GetSurveillanceConfigResponse extends $pb.GeneratedMessage {
  factory GetSurveillanceConfigResponse({
    $core.bool? success,
    SurveillanceConfig? config,
  }) {
    final result = GetSurveillanceConfigResponse._();
    if (success != null) result.success = success;
    if (config != null) result.config = config;
    return result;
  }

  GetSurveillanceConfigResponse._();

  factory GetSurveillanceConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceConfigResponse()..mergeFromBuffer(data, registry);
  factory GetSurveillanceConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceConfigResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSurveillanceConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSurveillanceConfigResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<SurveillanceConfig>(2, _omitFieldNames ? '' : 'config',
        subBuilder: SurveillanceConfig.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceConfigResponse copyWith(
          void Function(GetSurveillanceConfigResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetSurveillanceConfigResponse))
          as GetSurveillanceConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSurveillanceConfigResponse() / GetSurveillanceConfigResponse.new instead')
  static GetSurveillanceConfigResponse create() =>
      GetSurveillanceConfigResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetSurveillanceConfigResponse._();
  @$core.override
  GetSurveillanceConfigResponse createEmptyInstance() =>
      GetSurveillanceConfigResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSurveillanceConfigResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSurveillanceConfigResponse>(
          GetSurveillanceConfigResponse.$_createMessage);
  static GetSurveillanceConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  SurveillanceConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config(SurveillanceConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  SurveillanceConfig ensureConfig() => $_ensure(1);
}

class SetSurveillanceConfigRequest extends $pb.GeneratedMessage {
  factory SetSurveillanceConfigRequest({
    SurveillanceConfig? config,
    $core.int? manualCameraId,
    $core.bool? clearManualCameraId_3,
  }) {
    final result = SetSurveillanceConfigRequest._();
    if (config != null) result.config = config;
    if (manualCameraId != null) result.manualCameraId = manualCameraId;
    if (clearManualCameraId_3 != null)
      result.clearManualCameraId_3 = clearManualCameraId_3;
    return result;
  }

  SetSurveillanceConfigRequest._();

  factory SetSurveillanceConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSurveillanceConfigRequest()..mergeFromBuffer(data, registry);
  factory SetSurveillanceConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSurveillanceConfigRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSurveillanceConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetSurveillanceConfigRequest.$_createMessage)
    ..aOM<SurveillanceConfig>(1, _omitFieldNames ? '' : 'config',
        subBuilder: SurveillanceConfig.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'manualCameraId')
    ..aOB(3, _omitFieldNames ? '' : 'clearManualCameraId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSurveillanceConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSurveillanceConfigRequest copyWith(
          void Function(SetSurveillanceConfigRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetSurveillanceConfigRequest))
          as SetSurveillanceConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSurveillanceConfigRequest() / SetSurveillanceConfigRequest.new instead')
  static SetSurveillanceConfigRequest create() =>
      SetSurveillanceConfigRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetSurveillanceConfigRequest._();
  @$core.override
  SetSurveillanceConfigRequest createEmptyInstance() =>
      SetSurveillanceConfigRequest._();
  @$core.pragma('dart2js:noInline')
  static SetSurveillanceConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSurveillanceConfigRequest>(
          SetSurveillanceConfigRequest.$_createMessage);
  static SetSurveillanceConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  SurveillanceConfig get config => $_getN(0);
  @$pb.TagNumber(1)
  set config(SurveillanceConfig value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => $_clearField(1);
  @$pb.TagNumber(1)
  SurveillanceConfig ensureConfig() => $_ensure(0);

  /// Camera probe override fields. Write to the "camera" config section, not the
  /// surveillance config. Set manual_camera_id (0-5) to pin the probe to that
  /// index. Set clear_manual_camera_id=true to clear the pin and force re-discovery.
  @$pb.TagNumber(2)
  $core.int get manualCameraId => $_getIZ(1);
  @$pb.TagNumber(2)
  set manualCameraId($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasManualCameraId() => $_has(1);
  @$pb.TagNumber(2)
  void clearManualCameraId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get clearManualCameraId_3 => $_getBF(2);
  @$pb.TagNumber(3)
  set clearManualCameraId_3($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasClearManualCameraId_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearClearManualCameraId_3() => $_clearField(3);
}

class SetSurveillanceConfigResponse extends $pb.GeneratedMessage {
  factory SetSurveillanceConfigResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = SetSurveillanceConfigResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  SetSurveillanceConfigResponse._();

  factory SetSurveillanceConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSurveillanceConfigResponse()..mergeFromBuffer(data, registry);
  factory SetSurveillanceConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSurveillanceConfigResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSurveillanceConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetSurveillanceConfigResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSurveillanceConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSurveillanceConfigResponse copyWith(
          void Function(SetSurveillanceConfigResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SetSurveillanceConfigResponse))
          as SetSurveillanceConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSurveillanceConfigResponse() / SetSurveillanceConfigResponse.new instead')
  static SetSurveillanceConfigResponse create() =>
      SetSurveillanceConfigResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetSurveillanceConfigResponse._();
  @$core.override
  SetSurveillanceConfigResponse createEmptyInstance() =>
      SetSurveillanceConfigResponse._();
  @$core.pragma('dart2js:noInline')
  static SetSurveillanceConfigResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSurveillanceConfigResponse>(
          SetSurveillanceConfigResponse.$_createMessage);
  static SetSurveillanceConfigResponse? _defaultInstance;

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

class GetSurveillanceStatusRequest extends $pb.GeneratedMessage {
  factory GetSurveillanceStatusRequest() => GetSurveillanceStatusRequest._();

  GetSurveillanceStatusRequest._();

  factory GetSurveillanceStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceStatusRequest()..mergeFromBuffer(data, registry);
  factory GetSurveillanceStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSurveillanceStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSurveillanceStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceStatusRequest copyWith(
          void Function(GetSurveillanceStatusRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetSurveillanceStatusRequest))
          as GetSurveillanceStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSurveillanceStatusRequest() / GetSurveillanceStatusRequest.new instead')
  static GetSurveillanceStatusRequest create() =>
      GetSurveillanceStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetSurveillanceStatusRequest._();
  @$core.override
  GetSurveillanceStatusRequest createEmptyInstance() =>
      GetSurveillanceStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSurveillanceStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSurveillanceStatusRequest>(
          GetSurveillanceStatusRequest.$_createMessage);
  static GetSurveillanceStatusRequest? _defaultInstance;
}

class GetSurveillanceStatusResponse extends $pb.GeneratedMessage {
  factory GetSurveillanceStatusResponse({
    $core.bool? pipelineRunning,
    $core.bool? surveillanceActive,
    $core.String? error,
    $core.bool? cameraYielded,
    $core.bool? nativeAppActive,
  }) {
    final result = GetSurveillanceStatusResponse._();
    if (pipelineRunning != null) result.pipelineRunning = pipelineRunning;
    if (surveillanceActive != null)
      result.surveillanceActive = surveillanceActive;
    if (error != null) result.error = error;
    if (cameraYielded != null) result.cameraYielded = cameraYielded;
    if (nativeAppActive != null) result.nativeAppActive = nativeAppActive;
    return result;
  }

  GetSurveillanceStatusResponse._();

  factory GetSurveillanceStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceStatusResponse()..mergeFromBuffer(data, registry);
  factory GetSurveillanceStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSurveillanceStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSurveillanceStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSurveillanceStatusResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'pipelineRunning')
    ..aOB(2, _omitFieldNames ? '' : 'surveillanceActive')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..aOB(5, _omitFieldNames ? '' : 'cameraYielded')
    ..aOB(6, _omitFieldNames ? '' : 'nativeAppActive')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSurveillanceStatusResponse copyWith(
          void Function(GetSurveillanceStatusResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetSurveillanceStatusResponse))
          as GetSurveillanceStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSurveillanceStatusResponse() / GetSurveillanceStatusResponse.new instead')
  static GetSurveillanceStatusResponse create() =>
      GetSurveillanceStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetSurveillanceStatusResponse._();
  @$core.override
  GetSurveillanceStatusResponse createEmptyInstance() =>
      GetSurveillanceStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSurveillanceStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSurveillanceStatusResponse>(
          GetSurveillanceStatusResponse.$_createMessage);
  static GetSurveillanceStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get pipelineRunning => $_getBF(0);
  @$pb.TagNumber(1)
  set pipelineRunning($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPipelineRunning() => $_has(0);
  @$pb.TagNumber(1)
  void clearPipelineRunning() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get surveillanceActive => $_getBF(1);
  @$pb.TagNumber(2)
  set surveillanceActive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSurveillanceActive() => $_has(1);
  @$pb.TagNumber(2)
  void clearSurveillanceActive() => $_clearField(2);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);

  /// True while another app (typically the car's own DVR) holds the camera and
  /// BydCameraCoordinator has yielded to it (BladeWatch-gyg1.2). Surface this only while
  /// true -- a permanent "another app might be using the camera" caption is noise.
  @$pb.TagNumber(5)
  $core.bool get cameraYielded => $_getBF(3);
  @$pb.TagNumber(5)
  set cameraYielded($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(5)
  $core.bool hasCameraYielded() => $_has(3);
  @$pb.TagNumber(5)
  void clearCameraYielded() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get nativeAppActive => $_getBF(4);
  @$pb.TagNumber(6)
  set nativeAppActive($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(6)
  $core.bool hasNativeAppActive() => $_has(4);
  @$pb.TagNumber(6)
  void clearNativeAppActive() => $_clearField(6);
}

class EnableSurveillanceRequest extends $pb.GeneratedMessage {
  factory EnableSurveillanceRequest() => EnableSurveillanceRequest._();

  EnableSurveillanceRequest._();

  factory EnableSurveillanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableSurveillanceRequest()..mergeFromBuffer(data, registry);
  factory EnableSurveillanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableSurveillanceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnableSurveillanceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: EnableSurveillanceRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableSurveillanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableSurveillanceRequest copyWith(
          void Function(EnableSurveillanceRequest) updates) =>
      super.copyWith((message) => updates(message as EnableSurveillanceRequest))
          as EnableSurveillanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EnableSurveillanceRequest() / EnableSurveillanceRequest.new instead')
  static EnableSurveillanceRequest create() => EnableSurveillanceRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      EnableSurveillanceRequest._();
  @$core.override
  EnableSurveillanceRequest createEmptyInstance() =>
      EnableSurveillanceRequest._();
  @$core.pragma('dart2js:noInline')
  static EnableSurveillanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnableSurveillanceRequest>(
          EnableSurveillanceRequest.$_createMessage);
  static EnableSurveillanceRequest? _defaultInstance;
}

class EnableSurveillanceResponse extends $pb.GeneratedMessage {
  factory EnableSurveillanceResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? error,
  }) {
    final result = EnableSurveillanceResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (error != null) result.error = error;
    return result;
  }

  EnableSurveillanceResponse._();

  factory EnableSurveillanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableSurveillanceResponse()..mergeFromBuffer(data, registry);
  factory EnableSurveillanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableSurveillanceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnableSurveillanceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: EnableSurveillanceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableSurveillanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableSurveillanceResponse copyWith(
          void Function(EnableSurveillanceResponse) updates) =>
      super.copyWith(
              (message) => updates(message as EnableSurveillanceResponse))
          as EnableSurveillanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EnableSurveillanceResponse() / EnableSurveillanceResponse.new instead')
  static EnableSurveillanceResponse create() => EnableSurveillanceResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      EnableSurveillanceResponse._();
  @$core.override
  EnableSurveillanceResponse createEmptyInstance() =>
      EnableSurveillanceResponse._();
  @$core.pragma('dart2js:noInline')
  static EnableSurveillanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnableSurveillanceResponse>(
          EnableSurveillanceResponse.$_createMessage);
  static EnableSurveillanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class DisableSurveillanceRequest extends $pb.GeneratedMessage {
  factory DisableSurveillanceRequest() => DisableSurveillanceRequest._();

  DisableSurveillanceRequest._();

  factory DisableSurveillanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableSurveillanceRequest()..mergeFromBuffer(data, registry);
  factory DisableSurveillanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableSurveillanceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableSurveillanceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DisableSurveillanceRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableSurveillanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableSurveillanceRequest copyWith(
          void Function(DisableSurveillanceRequest) updates) =>
      super.copyWith(
              (message) => updates(message as DisableSurveillanceRequest))
          as DisableSurveillanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DisableSurveillanceRequest() / DisableSurveillanceRequest.new instead')
  static DisableSurveillanceRequest create() => DisableSurveillanceRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      DisableSurveillanceRequest._();
  @$core.override
  DisableSurveillanceRequest createEmptyInstance() =>
      DisableSurveillanceRequest._();
  @$core.pragma('dart2js:noInline')
  static DisableSurveillanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableSurveillanceRequest>(
          DisableSurveillanceRequest.$_createMessage);
  static DisableSurveillanceRequest? _defaultInstance;
}

class DisableSurveillanceResponse extends $pb.GeneratedMessage {
  factory DisableSurveillanceResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = DisableSurveillanceResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  DisableSurveillanceResponse._();

  factory DisableSurveillanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableSurveillanceResponse()..mergeFromBuffer(data, registry);
  factory DisableSurveillanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableSurveillanceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableSurveillanceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DisableSurveillanceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableSurveillanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableSurveillanceResponse copyWith(
          void Function(DisableSurveillanceResponse) updates) =>
      super.copyWith(
              (message) => updates(message as DisableSurveillanceResponse))
          as DisableSurveillanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DisableSurveillanceResponse() / DisableSurveillanceResponse.new instead')
  static DisableSurveillanceResponse create() =>
      DisableSurveillanceResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      DisableSurveillanceResponse._();
  @$core.override
  DisableSurveillanceResponse createEmptyInstance() =>
      DisableSurveillanceResponse._();
  @$core.pragma('dart2js:noInline')
  static DisableSurveillanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableSurveillanceResponse>(
          DisableSurveillanceResponse.$_createMessage);
  static DisableSurveillanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => $_clearField(2);
}

class GetHeatmapRequest extends $pb.GeneratedMessage {
  factory GetHeatmapRequest() => GetHeatmapRequest._();

  GetHeatmapRequest._();

  factory GetHeatmapRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHeatmapRequest()..mergeFromBuffer(data, registry);
  factory GetHeatmapRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHeatmapRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHeatmapRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetHeatmapRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHeatmapRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHeatmapRequest copyWith(void Function(GetHeatmapRequest) updates) =>
      super.copyWith((message) => updates(message as GetHeatmapRequest))
          as GetHeatmapRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetHeatmapRequest() / GetHeatmapRequest.new instead')
  static GetHeatmapRequest create() => GetHeatmapRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetHeatmapRequest._();
  @$core.override
  GetHeatmapRequest createEmptyInstance() => GetHeatmapRequest._();
  @$core.pragma('dart2js:noInline')
  static GetHeatmapRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetHeatmapRequest>(
          GetHeatmapRequest.$_createMessage);
  static GetHeatmapRequest? _defaultInstance;
}

/// HeatmapQuadrant is one of the four quadrants in the motion heatmap grid.
/// Field JSON names already match the REST handler's camelCase keys (no json_name needed).
class HeatmapQuadrant extends $pb.GeneratedMessage {
  factory HeatmapQuadrant({
    $core.int? id,
    $core.String? name,
    $core.bool? enabled,
    $core.bool? suppressed,
    $core.double? meanLuma,
    $core.int? activeBlocks,
    $core.int? confirmedBlocks,
    $core.int? threatLevel,
    $core.int? componentSize,
    $core.Iterable<$core.double>? confidence,
  }) {
    final result = HeatmapQuadrant._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (enabled != null) result.enabled = enabled;
    if (suppressed != null) result.suppressed = suppressed;
    if (meanLuma != null) result.meanLuma = meanLuma;
    if (activeBlocks != null) result.activeBlocks = activeBlocks;
    if (confirmedBlocks != null) result.confirmedBlocks = confirmedBlocks;
    if (threatLevel != null) result.threatLevel = threatLevel;
    if (componentSize != null) result.componentSize = componentSize;
    if (confidence != null) result.confidence.addAll(confidence);
    return result;
  }

  HeatmapQuadrant._();

  factory HeatmapQuadrant.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeatmapQuadrant()..mergeFromBuffer(data, registry);
  factory HeatmapQuadrant.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HeatmapQuadrant()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HeatmapQuadrant',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: HeatmapQuadrant.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..aOB(4, _omitFieldNames ? '' : 'suppressed')
    ..aD(5, _omitFieldNames ? '' : 'meanLuma')
    ..aI(6, _omitFieldNames ? '' : 'activeBlocks')
    ..aI(7, _omitFieldNames ? '' : 'confirmedBlocks')
    ..aI(8, _omitFieldNames ? '' : 'threatLevel')
    ..aI(9, _omitFieldNames ? '' : 'componentSize')
    ..p<$core.double>(
        10, _omitFieldNames ? '' : 'confidence', $pb.PbFieldType.KD)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeatmapQuadrant clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HeatmapQuadrant copyWith(void Function(HeatmapQuadrant) updates) =>
      super.copyWith((message) => updates(message as HeatmapQuadrant))
          as HeatmapQuadrant;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HeatmapQuadrant() / HeatmapQuadrant.new instead')
  static HeatmapQuadrant create() => HeatmapQuadrant._();
  static $pb.GeneratedMessage $_createMessage() => HeatmapQuadrant._();
  @$core.override
  HeatmapQuadrant createEmptyInstance() => HeatmapQuadrant._();
  @$core.pragma('dart2js:noInline')
  static HeatmapQuadrant getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HeatmapQuadrant>(
          HeatmapQuadrant.$_createMessage);
  static HeatmapQuadrant? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setSignedInt32(0, value);
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
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get suppressed => $_getBF(3);
  @$pb.TagNumber(4)
  set suppressed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSuppressed() => $_has(3);
  @$pb.TagNumber(4)
  void clearSuppressed() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get meanLuma => $_getN(4);
  @$pb.TagNumber(5)
  set meanLuma($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMeanLuma() => $_has(4);
  @$pb.TagNumber(5)
  void clearMeanLuma() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get activeBlocks => $_getIZ(5);
  @$pb.TagNumber(6)
  set activeBlocks($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasActiveBlocks() => $_has(5);
  @$pb.TagNumber(6)
  void clearActiveBlocks() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get confirmedBlocks => $_getIZ(6);
  @$pb.TagNumber(7)
  set confirmedBlocks($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasConfirmedBlocks() => $_has(6);
  @$pb.TagNumber(7)
  void clearConfirmedBlocks() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get threatLevel => $_getIZ(7);
  @$pb.TagNumber(8)
  set threatLevel($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasThreatLevel() => $_has(7);
  @$pb.TagNumber(8)
  void clearThreatLevel() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get componentSize => $_getIZ(8);
  @$pb.TagNumber(9)
  set componentSize($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasComponentSize() => $_has(8);
  @$pb.TagNumber(9)
  void clearComponentSize() => $_clearField(9);

  /// Per-block motion confidence (only present for enabled quadrants).
  @$pb.TagNumber(10)
  $pb.PbList<$core.double> get confidence => $_getList(9);
}

/// GetHeatmapResponse matches SurveillanceApiHandler.sendHeatmap: a motion grid descriptor, NOT a
/// JPEG. (was: bytes image_jpeg = 1.)
class GetHeatmapResponse extends $pb.GeneratedMessage {
  factory GetHeatmapResponse({
    $core.int? gridCols,
    $core.int? gridRows,
    $core.int? viewMode,
    $core.Iterable<HeatmapQuadrant>? quadrants,
  }) {
    final result = GetHeatmapResponse._();
    if (gridCols != null) result.gridCols = gridCols;
    if (gridRows != null) result.gridRows = gridRows;
    if (viewMode != null) result.viewMode = viewMode;
    if (quadrants != null) result.quadrants.addAll(quadrants);
    return result;
  }

  GetHeatmapResponse._();

  factory GetHeatmapResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHeatmapResponse()..mergeFromBuffer(data, registry);
  factory GetHeatmapResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetHeatmapResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHeatmapResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetHeatmapResponse.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'gridCols')
    ..aI(3, _omitFieldNames ? '' : 'gridRows')
    ..aI(4, _omitFieldNames ? '' : 'viewMode')
    ..pPM<HeatmapQuadrant>(5, _omitFieldNames ? '' : 'quadrants',
        subBuilder: HeatmapQuadrant.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHeatmapResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHeatmapResponse copyWith(void Function(GetHeatmapResponse) updates) =>
      super.copyWith((message) => updates(message as GetHeatmapResponse))
          as GetHeatmapResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetHeatmapResponse() / GetHeatmapResponse.new instead')
  static GetHeatmapResponse create() => GetHeatmapResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetHeatmapResponse._();
  @$core.override
  GetHeatmapResponse createEmptyInstance() => GetHeatmapResponse._();
  @$core.pragma('dart2js:noInline')
  static GetHeatmapResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHeatmapResponse>(
          GetHeatmapResponse.$_createMessage);
  static GetHeatmapResponse? _defaultInstance;

  @$pb.TagNumber(2)
  $core.int get gridCols => $_getIZ(0);
  @$pb.TagNumber(2)
  set gridCols($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(2)
  $core.bool hasGridCols() => $_has(0);
  @$pb.TagNumber(2)
  void clearGridCols() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get gridRows => $_getIZ(1);
  @$pb.TagNumber(3)
  set gridRows($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(3)
  $core.bool hasGridRows() => $_has(1);
  @$pb.TagNumber(3)
  void clearGridRows() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get viewMode => $_getIZ(2);
  @$pb.TagNumber(4)
  set viewMode($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(4)
  $core.bool hasViewMode() => $_has(2);
  @$pb.TagNumber(4)
  void clearViewMode() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<HeatmapQuadrant> get quadrants => $_getList(3);
}

class GetSnapshotRequest extends $pb.GeneratedMessage {
  factory GetSnapshotRequest({
    $core.int? quadrant,
  }) {
    final result = GetSnapshotRequest._();
    if (quadrant != null) result.quadrant = quadrant;
    return result;
  }

  GetSnapshotRequest._();

  factory GetSnapshotRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSnapshotRequest()..mergeFromBuffer(data, registry);
  factory GetSnapshotRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSnapshotRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSnapshotRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSnapshotRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'quadrant')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSnapshotRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSnapshotRequest copyWith(void Function(GetSnapshotRequest) updates) =>
      super.copyWith((message) => updates(message as GetSnapshotRequest))
          as GetSnapshotRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetSnapshotRequest() / GetSnapshotRequest.new instead')
  static GetSnapshotRequest create() => GetSnapshotRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSnapshotRequest._();
  @$core.override
  GetSnapshotRequest createEmptyInstance() => GetSnapshotRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSnapshotRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSnapshotRequest>(
          GetSnapshotRequest.$_createMessage);
  static GetSnapshotRequest? _defaultInstance;

  /// Quadrant index 0-3.
  @$pb.TagNumber(1)
  $core.int get quadrant => $_getIZ(0);
  @$pb.TagNumber(1)
  set quadrant($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuadrant() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuadrant() => $_clearField(1);
}

class GetSnapshotResponse extends $pb.GeneratedMessage {
  factory GetSnapshotResponse({
    $core.List<$core.int>? imageJpeg,
    $core.String? error,
  }) {
    final result = GetSnapshotResponse._();
    if (imageJpeg != null) result.imageJpeg = imageJpeg;
    if (error != null) result.error = error;
    return result;
  }

  GetSnapshotResponse._();

  factory GetSnapshotResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSnapshotResponse()..mergeFromBuffer(data, registry);
  factory GetSnapshotResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSnapshotResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSnapshotResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSnapshotResponse.$_createMessage)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'imageJpeg', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSnapshotResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSnapshotResponse copyWith(void Function(GetSnapshotResponse) updates) =>
      super.copyWith((message) => updates(message as GetSnapshotResponse))
          as GetSnapshotResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetSnapshotResponse() / GetSnapshotResponse.new instead')
  static GetSnapshotResponse create() => GetSnapshotResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSnapshotResponse._();
  @$core.override
  GetSnapshotResponse createEmptyInstance() => GetSnapshotResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSnapshotResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSnapshotResponse>(
          GetSnapshotResponse.$_createMessage);
  static GetSnapshotResponse? _defaultInstance;

  /// JPEG-encoded snapshot bytes.
  @$pb.TagNumber(1)
  $core.List<$core.int> get imageJpeg => $_getN(0);
  @$pb.TagNumber(1)
  set imageJpeg($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasImageJpeg() => $_has(0);
  @$pb.TagNumber(1)
  void clearImageJpeg() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class GetFilterLogRequest extends $pb.GeneratedMessage {
  factory GetFilterLogRequest() => GetFilterLogRequest._();

  GetFilterLogRequest._();

  factory GetFilterLogRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetFilterLogRequest()..mergeFromBuffer(data, registry);
  factory GetFilterLogRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetFilterLogRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetFilterLogRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetFilterLogRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetFilterLogRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetFilterLogRequest copyWith(void Function(GetFilterLogRequest) updates) =>
      super.copyWith((message) => updates(message as GetFilterLogRequest))
          as GetFilterLogRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetFilterLogRequest() / GetFilterLogRequest.new instead')
  static GetFilterLogRequest create() => GetFilterLogRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetFilterLogRequest._();
  @$core.override
  GetFilterLogRequest createEmptyInstance() => GetFilterLogRequest._();
  @$core.pragma('dart2js:noInline')
  static GetFilterLogRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetFilterLogRequest>(
          GetFilterLogRequest.$_createMessage);
  static GetFilterLogRequest? _defaultInstance;
}

/// GetFilterLogResponse matches SurveillanceApiHandler.sendFilterLog: the handler emits plain string
/// log lines plus a count (was: repeated FilterLogEntry structs, which the handler never produced).
class GetFilterLogResponse extends $pb.GeneratedMessage {
  factory GetFilterLogResponse({
    $core.Iterable<$core.String>? entries,
    $core.int? count,
  }) {
    final result = GetFilterLogResponse._();
    if (entries != null) result.entries.addAll(entries);
    if (count != null) result.count = count;
    return result;
  }

  GetFilterLogResponse._();

  factory GetFilterLogResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetFilterLogResponse()..mergeFromBuffer(data, registry);
  factory GetFilterLogResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetFilterLogResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetFilterLogResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetFilterLogResponse.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'entries')
    ..aI(3, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetFilterLogResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetFilterLogResponse copyWith(void Function(GetFilterLogResponse) updates) =>
      super.copyWith((message) => updates(message as GetFilterLogResponse))
          as GetFilterLogResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetFilterLogResponse() / GetFilterLogResponse.new instead')
  static GetFilterLogResponse create() => GetFilterLogResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetFilterLogResponse._();
  @$core.override
  GetFilterLogResponse createEmptyInstance() => GetFilterLogResponse._();
  @$core.pragma('dart2js:noInline')
  static GetFilterLogResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetFilterLogResponse>(
          GetFilterLogResponse.$_createMessage);
  static GetFilterLogResponse? _defaultInstance;

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get entries => $_getList(0);

  @$pb.TagNumber(3)
  $core.int get count => $_getIZ(1);
  @$pb.TagNumber(3)
  set count($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(3)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(3)
  void clearCount() => $_clearField(3);
}

class SyncSurveillanceCatalogRequest extends $pb.GeneratedMessage {
  factory SyncSurveillanceCatalogRequest() =>
      SyncSurveillanceCatalogRequest._();

  SyncSurveillanceCatalogRequest._();

  factory SyncSurveillanceCatalogRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncSurveillanceCatalogRequest()..mergeFromBuffer(data, registry);
  factory SyncSurveillanceCatalogRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncSurveillanceCatalogRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncSurveillanceCatalogRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SyncSurveillanceCatalogRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncSurveillanceCatalogRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncSurveillanceCatalogRequest copyWith(
          void Function(SyncSurveillanceCatalogRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SyncSurveillanceCatalogRequest))
          as SyncSurveillanceCatalogRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SyncSurveillanceCatalogRequest() / SyncSurveillanceCatalogRequest.new instead')
  static SyncSurveillanceCatalogRequest create() =>
      SyncSurveillanceCatalogRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SyncSurveillanceCatalogRequest._();
  @$core.override
  SyncSurveillanceCatalogRequest createEmptyInstance() =>
      SyncSurveillanceCatalogRequest._();
  @$core.pragma('dart2js:noInline')
  static SyncSurveillanceCatalogRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncSurveillanceCatalogRequest>(
          SyncSurveillanceCatalogRequest.$_createMessage);
  static SyncSurveillanceCatalogRequest? _defaultInstance;
}

class SyncSurveillanceCatalogResponse extends $pb.GeneratedMessage {
  factory SyncSurveillanceCatalogResponse({
    $core.bool? success,
    $core.String? error,
    $core.int? added,
    $core.int? removed,
  }) {
    final result = SyncSurveillanceCatalogResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    if (added != null) result.added = added;
    if (removed != null) result.removed = removed;
    return result;
  }

  SyncSurveillanceCatalogResponse._();

  factory SyncSurveillanceCatalogResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncSurveillanceCatalogResponse()..mergeFromBuffer(data, registry);
  factory SyncSurveillanceCatalogResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncSurveillanceCatalogResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncSurveillanceCatalogResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SyncSurveillanceCatalogResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aI(3, _omitFieldNames ? '' : 'added')
    ..aI(4, _omitFieldNames ? '' : 'removed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncSurveillanceCatalogResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncSurveillanceCatalogResponse copyWith(
          void Function(SyncSurveillanceCatalogResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SyncSurveillanceCatalogResponse))
          as SyncSurveillanceCatalogResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SyncSurveillanceCatalogResponse() / SyncSurveillanceCatalogResponse.new instead')
  static SyncSurveillanceCatalogResponse create() =>
      SyncSurveillanceCatalogResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SyncSurveillanceCatalogResponse._();
  @$core.override
  SyncSurveillanceCatalogResponse createEmptyInstance() =>
      SyncSurveillanceCatalogResponse._();
  @$core.pragma('dart2js:noInline')
  static SyncSurveillanceCatalogResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncSurveillanceCatalogResponse>(
          SyncSurveillanceCatalogResponse.$_createMessage);
  static SyncSurveillanceCatalogResponse? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.int get added => $_getIZ(2);
  @$pb.TagNumber(3)
  set added($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAdded() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdded() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get removed => $_getIZ(3);
  @$pb.TagNumber(4)
  set removed($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRemoved() => $_has(3);
  @$pb.TagNumber(4)
  void clearRemoved() => $_clearField(4);
}

/// SurveillanceService manages the GPU-accelerated sentry/motion-detection pipeline.
///
/// HTTP mapping:
///   GetConfig    GET  /api/surveillance/config
///   SetConfig    POST /api/surveillance/config
///   GetStatus    GET  /api/surveillance/status  (any method)
///   Enable       POST /api/surveillance/enable
///   Disable      POST /api/surveillance/disable
///   GetHeatmap   GET  /api/surveillance/heatmap
///   GetSnapshot  GET  /api/surveillance/snapshot/{quadrant}
///   GetFilterLog GET  /api/surveillance/filterlog
///   SyncCatalog  POST /api/surveillance/sync
class SurveillanceServiceApi {
  final $pb.RpcClient _client;

  SurveillanceServiceApi(this._client);

  $async.Future<GetSurveillanceConfigResponse> getConfig(
          $pb.ClientContext? ctx, GetSurveillanceConfigRequest request) =>
      _client.invoke<GetSurveillanceConfigResponse>(ctx, 'SurveillanceService',
          'GetConfig', request, GetSurveillanceConfigResponse());
  $async.Future<SetSurveillanceConfigResponse> setConfig(
          $pb.ClientContext? ctx, SetSurveillanceConfigRequest request) =>
      _client.invoke<SetSurveillanceConfigResponse>(ctx, 'SurveillanceService',
          'SetConfig', request, SetSurveillanceConfigResponse());
  $async.Future<GetSurveillanceStatusResponse> getStatus(
          $pb.ClientContext? ctx, GetSurveillanceStatusRequest request) =>
      _client.invoke<GetSurveillanceStatusResponse>(ctx, 'SurveillanceService',
          'GetStatus', request, GetSurveillanceStatusResponse());
  $async.Future<EnableSurveillanceResponse> enable(
          $pb.ClientContext? ctx, EnableSurveillanceRequest request) =>
      _client.invoke<EnableSurveillanceResponse>(ctx, 'SurveillanceService',
          'Enable', request, EnableSurveillanceResponse());
  $async.Future<DisableSurveillanceResponse> disable(
          $pb.ClientContext? ctx, DisableSurveillanceRequest request) =>
      _client.invoke<DisableSurveillanceResponse>(ctx, 'SurveillanceService',
          'Disable', request, DisableSurveillanceResponse());
  $async.Future<GetHeatmapResponse> getHeatmap(
          $pb.ClientContext? ctx, GetHeatmapRequest request) =>
      _client.invoke<GetHeatmapResponse>(ctx, 'SurveillanceService',
          'GetHeatmap', request, GetHeatmapResponse());
  $async.Future<GetSnapshotResponse> getSnapshot(
          $pb.ClientContext? ctx, GetSnapshotRequest request) =>
      _client.invoke<GetSnapshotResponse>(ctx, 'SurveillanceService',
          'GetSnapshot', request, GetSnapshotResponse());
  $async.Future<GetFilterLogResponse> getFilterLog(
          $pb.ClientContext? ctx, GetFilterLogRequest request) =>
      _client.invoke<GetFilterLogResponse>(ctx, 'SurveillanceService',
          'GetFilterLog', request, GetFilterLogResponse());
  $async.Future<SyncSurveillanceCatalogResponse> syncCatalog(
          $pb.ClientContext? ctx, SyncSurveillanceCatalogRequest request) =>
      _client.invoke<SyncSurveillanceCatalogResponse>(
          ctx,
          'SurveillanceService',
          'SyncCatalog',
          request,
          SyncSurveillanceCatalogResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
