// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/system.proto.

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

/// BatteryInfo carries the Android battery level and charge state.
class BatteryInfo extends $pb.GeneratedMessage {
  factory BatteryInfo({
    $core.String? level,
  }) {
    final result = BatteryInfo._();
    if (level != null) result.level = level;
    return result;
  }

  BatteryInfo._();

  factory BatteryInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatteryInfo()..mergeFromBuffer(data, registry);
  factory BatteryInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatteryInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatteryInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: BatteryInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'level')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatteryInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatteryInfo copyWith(void Function(BatteryInfo) updates) =>
      super.copyWith((message) => updates(message as BatteryInfo))
          as BatteryInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BatteryInfo() / BatteryInfo.new instead')
  static BatteryInfo create() => BatteryInfo._();
  static $pb.GeneratedMessage $_createMessage() => BatteryInfo._();
  @$core.override
  BatteryInfo createEmptyInstance() => BatteryInfo._();
  @$core.pragma('dart2js:noInline')
  static BatteryInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BatteryInfo>(
          BatteryInfo.$_createMessage);
  static BatteryInfo? _defaultInstance;

  /// BatteryMonitor.getBatteryInfo() emits a STATUS STRING here (e.g. "NORMAL"),
  /// not a numeric percentage (the percentage is carried by SocInfo.percent).
  /// This was modeled as int32, which made strict JSON clients (connect-web)
  /// reject the entire GetStatus response with a type error. No client reads
  /// battery.level. The daemon also emits voltage/soc/lastUpdate alongside it,
  /// which clients tolerate via jsonOptions.ignoreUnknownFields.
  @$pb.TagNumber(1)
  $core.String get level => $_getSZ(0);
  @$pb.TagNumber(1)
  set level($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => $_clearField(1);
}

/// ChargingInfo carries BYD BMS charging power and state.
class ChargingInfo extends $pb.GeneratedMessage {
  factory ChargingInfo({
    $core.String? stateName,
    $core.String? status,
    $core.double? chargingPowerKW,
    $core.bool? isDischarging,
    $core.bool? isError,
    $core.bool? isEstimated,
  }) {
    final result = ChargingInfo._();
    if (stateName != null) result.stateName = stateName;
    if (status != null) result.status = status;
    if (chargingPowerKW != null) result.chargingPowerKW = chargingPowerKW;
    if (isDischarging != null) result.isDischarging = isDischarging;
    if (isError != null) result.isError = isError;
    if (isEstimated != null) result.isEstimated = isEstimated;
    return result;
  }

  ChargingInfo._();

  factory ChargingInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChargingInfo()..mergeFromBuffer(data, registry);
  factory ChargingInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ChargingInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChargingInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ChargingInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'stateName')
    ..aOS(2, _omitFieldNames ? '' : 'status')
    ..aD(3, _omitFieldNames ? '' : 'chargingPowerKW')
    ..aOB(4, _omitFieldNames ? '' : 'isDischarging')
    ..aOB(5, _omitFieldNames ? '' : 'isError')
    ..aOB(6, _omitFieldNames ? '' : 'isEstimated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChargingInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChargingInfo copyWith(void Function(ChargingInfo) updates) =>
      super.copyWith((message) => updates(message as ChargingInfo))
          as ChargingInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ChargingInfo() / ChargingInfo.new instead')
  static ChargingInfo create() => ChargingInfo._();
  static $pb.GeneratedMessage $_createMessage() => ChargingInfo._();
  @$core.override
  ChargingInfo createEmptyInstance() => ChargingInfo._();
  @$core.pragma('dart2js:noInline')
  static ChargingInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ChargingInfo>(
          ChargingInfo.$_createMessage);
  static ChargingInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get stateName => $_getSZ(0);
  @$pb.TagNumber(1)
  set stateName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStateName() => $_has(0);
  @$pb.TagNumber(1)
  void clearStateName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get status => $_getSZ(1);
  @$pb.TagNumber(2)
  set status($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get chargingPowerKW => $_getN(2);
  @$pb.TagNumber(3)
  set chargingPowerKW($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChargingPowerKW() => $_has(2);
  @$pb.TagNumber(3)
  void clearChargingPowerKW() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isDischarging => $_getBF(3);
  @$pb.TagNumber(4)
  set isDischarging($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsDischarging() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsDischarging() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isError => $_getBF(4);
  @$pb.TagNumber(5)
  set isError($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsError() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsError() => $_clearField(5);

  /// True when kW is estimated from SoC rate rather than direct BMS reading.
  @$pb.TagNumber(6)
  $core.bool get isEstimated => $_getBF(5);
  @$pb.TagNumber(6)
  set isEstimated($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsEstimated() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsEstimated() => $_clearField(6);
}

/// SocInfo carries the high-voltage battery State of Charge.
class SocInfo extends $pb.GeneratedMessage {
  factory SocInfo({
    $core.double? percent,
    $core.bool? isLow,
    $core.bool? isCritical,
    $core.String? status,
  }) {
    final result = SocInfo._();
    if (percent != null) result.percent = percent;
    if (isLow != null) result.isLow = isLow;
    if (isCritical != null) result.isCritical = isCritical;
    if (status != null) result.status = status;
    return result;
  }

  SocInfo._();

  factory SocInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SocInfo()..mergeFromBuffer(data, registry);
  factory SocInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SocInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SocInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SocInfo.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'percent')
    ..aOB(2, _omitFieldNames ? '' : 'isLow')
    ..aOB(3, _omitFieldNames ? '' : 'isCritical')
    ..aOS(4, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SocInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SocInfo copyWith(void Function(SocInfo) updates) =>
      super.copyWith((message) => updates(message as SocInfo)) as SocInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SocInfo() / SocInfo.new instead')
  static SocInfo create() => SocInfo._();
  static $pb.GeneratedMessage $_createMessage() => SocInfo._();
  @$core.override
  SocInfo createEmptyInstance() => SocInfo._();
  @$core.pragma('dart2js:noInline')
  static SocInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SocInfo>(SocInfo.$_createMessage);
  static SocInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get percent => $_getN(0);
  @$pb.TagNumber(1)
  set percent($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPercent() => $_has(0);
  @$pb.TagNumber(1)
  void clearPercent() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isLow => $_getBF(1);
  @$pb.TagNumber(2)
  set isLow($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsLow() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsLow() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isCritical => $_getBF(2);
  @$pb.TagNumber(3)
  set isCritical($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsCritical() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsCritical() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get status => $_getSZ(3);
  @$pb.TagNumber(4)
  set status($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => $_clearField(4);
}

/// RangeInfo carries the vehicle's estimated driving range.
class RangeInfo extends $pb.GeneratedMessage {
  factory RangeInfo({
    $core.double? elecRangeKm,
    $core.double? fuelRangeKm,
    $core.double? totalRangeKm,
    $core.bool? isLow,
    $core.bool? isCritical,
    $core.String? status,
    $core.double? fuelPercent,
  }) {
    final result = RangeInfo._();
    if (elecRangeKm != null) result.elecRangeKm = elecRangeKm;
    if (fuelRangeKm != null) result.fuelRangeKm = fuelRangeKm;
    if (totalRangeKm != null) result.totalRangeKm = totalRangeKm;
    if (isLow != null) result.isLow = isLow;
    if (isCritical != null) result.isCritical = isCritical;
    if (status != null) result.status = status;
    if (fuelPercent != null) result.fuelPercent = fuelPercent;
    return result;
  }

  RangeInfo._();

  factory RangeInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RangeInfo()..mergeFromBuffer(data, registry);
  factory RangeInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RangeInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RangeInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: RangeInfo.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'elecRangeKm')
    ..aD(2, _omitFieldNames ? '' : 'fuelRangeKm')
    ..aD(3, _omitFieldNames ? '' : 'totalRangeKm')
    ..aOB(4, _omitFieldNames ? '' : 'isLow')
    ..aOB(5, _omitFieldNames ? '' : 'isCritical')
    ..aOS(6, _omitFieldNames ? '' : 'status')
    ..aD(7, _omitFieldNames ? '' : 'fuelPercent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RangeInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RangeInfo copyWith(void Function(RangeInfo) updates) =>
      super.copyWith((message) => updates(message as RangeInfo)) as RangeInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RangeInfo() / RangeInfo.new instead')
  static RangeInfo create() => RangeInfo._();
  static $pb.GeneratedMessage $_createMessage() => RangeInfo._();
  @$core.override
  RangeInfo createEmptyInstance() => RangeInfo._();
  @$core.pragma('dart2js:noInline')
  static RangeInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RangeInfo>(RangeInfo.$_createMessage);
  static RangeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get elecRangeKm => $_getN(0);
  @$pb.TagNumber(1)
  set elecRangeKm($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasElecRangeKm() => $_has(0);
  @$pb.TagNumber(1)
  void clearElecRangeKm() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get fuelRangeKm => $_getN(1);
  @$pb.TagNumber(2)
  set fuelRangeKm($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFuelRangeKm() => $_has(1);
  @$pb.TagNumber(2)
  void clearFuelRangeKm() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get totalRangeKm => $_getN(2);
  @$pb.TagNumber(3)
  set totalRangeKm($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalRangeKm() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalRangeKm() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isLow => $_getBF(3);
  @$pb.TagNumber(4)
  set isLow($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasIsLow() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsLow() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isCritical => $_getBF(4);
  @$pb.TagNumber(5)
  set isCritical($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsCritical() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsCritical() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get status => $_getSZ(5);
  @$pb.TagNumber(6)
  set status($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(5);
  @$pb.TagNumber(6)
  void clearStatus() => $_clearField(6);

  /// Only present on PHEVs.
  @$pb.TagNumber(7)
  $core.double get fuelPercent => $_getN(6);
  @$pb.TagNumber(7)
  set fuelPercent($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFuelPercent() => $_has(6);
  @$pb.TagNumber(7)
  void clearFuelPercent() => $_clearField(7);
}

/// SohInfo carries the battery State of Health estimate.
class SohInfo extends $pb.GeneratedMessage {
  factory SohInfo({
    $core.double? percent,
  }) {
    final result = SohInfo._();
    if (percent != null) result.percent = percent;
    return result;
  }

  SohInfo._();

  factory SohInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SohInfo()..mergeFromBuffer(data, registry);
  factory SohInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SohInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SohInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SohInfo.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'percent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SohInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SohInfo copyWith(void Function(SohInfo) updates) =>
      super.copyWith((message) => updates(message as SohInfo)) as SohInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SohInfo() / SohInfo.new instead')
  static SohInfo create() => SohInfo._();
  static $pb.GeneratedMessage $_createMessage() => SohInfo._();
  @$core.override
  SohInfo createEmptyInstance() => SohInfo._();
  @$core.pragma('dart2js:noInline')
  static SohInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SohInfo>(SohInfo.$_createMessage);
  static SohInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get percent => $_getN(0);
  @$pb.TagNumber(1)
  set percent($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPercent() => $_has(0);
  @$pb.TagNumber(1)
  void clearPercent() => $_clearField(1);
}

/// RecordingStatus carries the current recording mode pipeline state.
class RecordingStatus extends $pb.GeneratedMessage {
  factory RecordingStatus({
    $core.String? configuredMode,
    $core.bool? isRecording,
    $core.bool? pipelineRunning,
    $core.String? gear,
    $core.bool? accOn,
  }) {
    final result = RecordingStatus._();
    if (configuredMode != null) result.configuredMode = configuredMode;
    if (isRecording != null) result.isRecording = isRecording;
    if (pipelineRunning != null) result.pipelineRunning = pipelineRunning;
    if (gear != null) result.gear = gear;
    if (accOn != null) result.accOn = accOn;
    return result;
  }

  RecordingStatus._();

  factory RecordingStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecordingStatus()..mergeFromBuffer(data, registry);
  factory RecordingStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecordingStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecordingStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: RecordingStatus.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'configuredMode')
    ..aOB(2, _omitFieldNames ? '' : 'isRecording')
    ..aOB(3, _omitFieldNames ? '' : 'pipelineRunning')
    ..aOS(4, _omitFieldNames ? '' : 'gear')
    ..aOB(5, _omitFieldNames ? '' : 'accOn')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecordingStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecordingStatus copyWith(void Function(RecordingStatus) updates) =>
      super.copyWith((message) => updates(message as RecordingStatus))
          as RecordingStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RecordingStatus() / RecordingStatus.new instead')
  static RecordingStatus create() => RecordingStatus._();
  static $pb.GeneratedMessage $_createMessage() => RecordingStatus._();
  @$core.override
  RecordingStatus createEmptyInstance() => RecordingStatus._();
  @$core.pragma('dart2js:noInline')
  static RecordingStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingStatus>(
          RecordingStatus.$_createMessage);
  static RecordingStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get configuredMode => $_getSZ(0);
  @$pb.TagNumber(1)
  set configuredMode($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasConfiguredMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfiguredMode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isRecording => $_getBF(1);
  @$pb.TagNumber(2)
  set isRecording($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsRecording() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsRecording() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get pipelineRunning => $_getBF(2);
  @$pb.TagNumber(3)
  set pipelineRunning($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPipelineRunning() => $_has(2);
  @$pb.TagNumber(3)
  void clearPipelineRunning() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get gear => $_getSZ(3);
  @$pb.TagNumber(4)
  set gear($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGear() => $_has(3);
  @$pb.TagNumber(4)
  void clearGear() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get accOn => $_getBF(4);
  @$pb.TagNumber(5)
  set accOn($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAccOn() => $_has(4);
  @$pb.TagNumber(5)
  void clearAccOn() => $_clearField(5);
}

/// TripStatus summarises the active trip analytics state.
class TripStatus extends $pb.GeneratedMessage {
  factory TripStatus({
    $core.bool? enabled,
    $core.bool? tripActive,
    $fixnum.Int64? tripStartTime,
    $fixnum.Int64? tripDurationSec,
  }) {
    final result = TripStatus._();
    if (enabled != null) result.enabled = enabled;
    if (tripActive != null) result.tripActive = tripActive;
    if (tripStartTime != null) result.tripStartTime = tripStartTime;
    if (tripDurationSec != null) result.tripDurationSec = tripDurationSec;
    return result;
  }

  TripStatus._();

  factory TripStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripStatus()..mergeFromBuffer(data, registry);
  factory TripStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TripStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TripStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'tripActive')
    ..aInt64(3, _omitFieldNames ? '' : 'tripStartTime')
    ..aInt64(4, _omitFieldNames ? '' : 'tripDurationSec')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripStatus copyWith(void Function(TripStatus) updates) =>
      super.copyWith((message) => updates(message as TripStatus)) as TripStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TripStatus() / TripStatus.new instead')
  static TripStatus create() => TripStatus._();
  static $pb.GeneratedMessage $_createMessage() => TripStatus._();
  @$core.override
  TripStatus createEmptyInstance() => TripStatus._();
  @$core.pragma('dart2js:noInline')
  static TripStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TripStatus>(TripStatus.$_createMessage);
  static TripStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get tripActive => $_getBF(1);
  @$pb.TagNumber(2)
  set tripActive($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTripActive() => $_has(1);
  @$pb.TagNumber(2)
  void clearTripActive() => $_clearField(2);

  /// Epoch ms when the current trip started (0 when no trip active).
  @$pb.TagNumber(3)
  $fixnum.Int64 get tripStartTime => $_getI64(2);
  @$pb.TagNumber(3)
  set tripStartTime($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTripStartTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearTripStartTime() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get tripDurationSec => $_getI64(3);
  @$pb.TagNumber(4)
  set tripDurationSec($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTripDurationSec() => $_has(3);
  @$pb.TagNumber(4)
  void clearTripDurationSec() => $_clearField(4);
}

/// NetworkInfo carries the current network connection details.
class NetworkInfo extends $pb.GeneratedMessage {
  factory NetworkInfo({
    $core.String? type,
    $core.String? ssid,
    $core.String? ip,
    $core.bool? lanHttpEnabled,
    $core.String? httpBind,
    $core.String? httpModeWarning,
  }) {
    final result = NetworkInfo._();
    if (type != null) result.type = type;
    if (ssid != null) result.ssid = ssid;
    if (ip != null) result.ip = ip;
    if (lanHttpEnabled != null) result.lanHttpEnabled = lanHttpEnabled;
    if (httpBind != null) result.httpBind = httpBind;
    if (httpModeWarning != null) result.httpModeWarning = httpModeWarning;
    return result;
  }

  NetworkInfo._();

  factory NetworkInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NetworkInfo()..mergeFromBuffer(data, registry);
  factory NetworkInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NetworkInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NetworkInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: NetworkInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'ssid')
    ..aOS(3, _omitFieldNames ? '' : 'ip')
    ..aOB(4, _omitFieldNames ? '' : 'lanHttpEnabled')
    ..aOS(5, _omitFieldNames ? '' : 'httpBind')
    ..aOS(6, _omitFieldNames ? '' : 'httpModeWarning')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetworkInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NetworkInfo copyWith(void Function(NetworkInfo) updates) =>
      super.copyWith((message) => updates(message as NetworkInfo))
          as NetworkInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NetworkInfo() / NetworkInfo.new instead')
  static NetworkInfo create() => NetworkInfo._();
  static $pb.GeneratedMessage $_createMessage() => NetworkInfo._();
  @$core.override
  NetworkInfo createEmptyInstance() => NetworkInfo._();
  @$core.pragma('dart2js:noInline')
  static NetworkInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NetworkInfo>(
          NetworkInfo.$_createMessage);
  static NetworkInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get ssid => $_getSZ(1);
  @$pb.TagNumber(2)
  set ssid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSsid() => $_has(1);
  @$pb.TagNumber(2)
  void clearSsid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get ip => $_getSZ(2);
  @$pb.TagNumber(3)
  set ip($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIp() => $_has(2);
  @$pb.TagNumber(3)
  void clearIp() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get lanHttpEnabled => $_getBF(3);
  @$pb.TagNumber(4)
  set lanHttpEnabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLanHttpEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearLanHttpEnabled() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get httpBind => $_getSZ(4);
  @$pb.TagNumber(5)
  set httpBind($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHttpBind() => $_has(4);
  @$pb.TagNumber(5)
  void clearHttpBind() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get httpModeWarning => $_getSZ(5);
  @$pb.TagNumber(6)
  set httpModeWarning($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHttpModeWarning() => $_has(5);
  @$pb.TagNumber(6)
  void clearHttpModeWarning() => $_clearField(6);
}

/// GpsStatusInfo is a lightweight location snapshot embedded in SystemStatus.
/// Full GpsLocation is in common.proto and is also used by VehicleService.
class GpsStatusInfo extends $pb.GeneratedMessage {
  factory GpsStatusInfo({
    $core.double? lat,
    $core.double? lng,
    $core.double? speedKmh,
    $core.bool? hasLocation,
  }) {
    final result = GpsStatusInfo._();
    if (lat != null) result.lat = lat;
    if (lng != null) result.lng = lng;
    if (speedKmh != null) result.speedKmh = speedKmh;
    if (hasLocation != null) result.hasLocation = hasLocation;
    return result;
  }

  GpsStatusInfo._();

  factory GpsStatusInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpsStatusInfo()..mergeFromBuffer(data, registry);
  factory GpsStatusInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpsStatusInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GpsStatusInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GpsStatusInfo.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'lat')
    ..aD(2, _omitFieldNames ? '' : 'lng')
    ..aD(3, _omitFieldNames ? '' : 'speedKmh')
    ..aOB(4, _omitFieldNames ? '' : 'hasLocation')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpsStatusInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpsStatusInfo copyWith(void Function(GpsStatusInfo) updates) =>
      super.copyWith((message) => updates(message as GpsStatusInfo))
          as GpsStatusInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GpsStatusInfo() / GpsStatusInfo.new instead')
  static GpsStatusInfo create() => GpsStatusInfo._();
  static $pb.GeneratedMessage $_createMessage() => GpsStatusInfo._();
  @$core.override
  GpsStatusInfo createEmptyInstance() => GpsStatusInfo._();
  @$core.pragma('dart2js:noInline')
  static GpsStatusInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GpsStatusInfo>(
          GpsStatusInfo.$_createMessage);
  static GpsStatusInfo? _defaultInstance;

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
  $core.double get speedKmh => $_getN(2);
  @$pb.TagNumber(3)
  set speedKmh($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSpeedKmh() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpeedKmh() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get hasLocation => $_getBF(3);
  @$pb.TagNumber(4)
  set hasLocation($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHasLocation() => $_has(3);
  @$pb.TagNumber(4)
  void clearHasLocation() => $_clearField(4);
}

class GetStatusRequest extends $pb.GeneratedMessage {
  factory GetStatusRequest() => GetStatusRequest._();

  GetStatusRequest._();

  factory GetStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusRequest()..mergeFromBuffer(data, registry);
  factory GetStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest copyWith(void Function(GetStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatusRequest))
          as GetStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatusRequest() / GetStatusRequest.new instead')
  static GetStatusRequest create() => GetStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStatusRequest._();
  @$core.override
  GetStatusRequest createEmptyInstance() => GetStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStatusRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusRequest>(
          GetStatusRequest.$_createMessage);
  static GetStatusRequest? _defaultInstance;
}

class GetStatusResponse extends $pb.GeneratedMessage {
  factory GetStatusResponse({
    $core.String? deviceId,
    $core.bool? vehicleDataReady,
    $core.String? appVersion,
    $core.Iterable<$core.int>? recording,
    $core.Iterable<$core.int>? viewing,
    $core.Iterable<$core.int>? active,
    $core.Iterable<$core.int>? available,
    BatteryInfo? battery,
    $core.bool? acc,
    ChargingInfo? charging,
    SocInfo? soc,
    RangeInfo? range,
    SohInfo? soh,
    $core.String? distanceUnit,
    $core.String? locale,
    $core.bool? safeZoneSuppressed,
    $core.bool? inSafeZone,
    $core.String? safeZoneName,
    $core.bool? gpuSurveillance,
    RecordingStatus? recordingStatus,
    TripStatus? tripStatus,
    NetworkInfo? network,
    $core.String? vehicleDataError,
  }) {
    final result = GetStatusResponse._();
    if (deviceId != null) result.deviceId = deviceId;
    if (vehicleDataReady != null) result.vehicleDataReady = vehicleDataReady;
    if (appVersion != null) result.appVersion = appVersion;
    if (recording != null) result.recording.addAll(recording);
    if (viewing != null) result.viewing.addAll(viewing);
    if (active != null) result.active.addAll(active);
    if (available != null) result.available.addAll(available);
    if (battery != null) result.battery = battery;
    if (acc != null) result.acc = acc;
    if (charging != null) result.charging = charging;
    if (soc != null) result.soc = soc;
    if (range != null) result.range = range;
    if (soh != null) result.soh = soh;
    if (distanceUnit != null) result.distanceUnit = distanceUnit;
    if (locale != null) result.locale = locale;
    if (safeZoneSuppressed != null)
      result.safeZoneSuppressed = safeZoneSuppressed;
    if (inSafeZone != null) result.inSafeZone = inSafeZone;
    if (safeZoneName != null) result.safeZoneName = safeZoneName;
    if (gpuSurveillance != null) result.gpuSurveillance = gpuSurveillance;
    if (recordingStatus != null) result.recordingStatus = recordingStatus;
    if (tripStatus != null) result.tripStatus = tripStatus;
    if (network != null) result.network = network;
    if (vehicleDataError != null) result.vehicleDataError = vehicleDataError;
    return result;
  }

  GetStatusResponse._();

  factory GetStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusResponse()..mergeFromBuffer(data, registry);
  factory GetStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStatusResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'deviceId')
    ..aOB(2, _omitFieldNames ? '' : 'vehicleDataReady')
    ..aOS(3, _omitFieldNames ? '' : 'appVersion')
    ..p<$core.int>(4, _omitFieldNames ? '' : 'recording', $pb.PbFieldType.K3)
    ..p<$core.int>(5, _omitFieldNames ? '' : 'viewing', $pb.PbFieldType.K3)
    ..p<$core.int>(6, _omitFieldNames ? '' : 'active', $pb.PbFieldType.K3)
    ..p<$core.int>(7, _omitFieldNames ? '' : 'available', $pb.PbFieldType.K3)
    ..aOM<BatteryInfo>(8, _omitFieldNames ? '' : 'battery',
        subBuilder: BatteryInfo.$_createMessage)
    ..aOB(9, _omitFieldNames ? '' : 'acc')
    ..aOM<ChargingInfo>(10, _omitFieldNames ? '' : 'charging',
        subBuilder: ChargingInfo.$_createMessage)
    ..aOM<SocInfo>(11, _omitFieldNames ? '' : 'soc',
        subBuilder: SocInfo.$_createMessage)
    ..aOM<RangeInfo>(12, _omitFieldNames ? '' : 'range',
        subBuilder: RangeInfo.$_createMessage)
    ..aOM<SohInfo>(13, _omitFieldNames ? '' : 'soh',
        subBuilder: SohInfo.$_createMessage)
    ..aOS(14, _omitFieldNames ? '' : 'distanceUnit')
    ..aOS(15, _omitFieldNames ? '' : 'locale')
    ..aOB(16, _omitFieldNames ? '' : 'safeZoneSuppressed')
    ..aOB(17, _omitFieldNames ? '' : 'inSafeZone')
    ..aOS(18, _omitFieldNames ? '' : 'safeZoneName')
    ..aOB(19, _omitFieldNames ? '' : 'gpuSurveillance')
    ..aOM<RecordingStatus>(20, _omitFieldNames ? '' : 'recordingStatus',
        subBuilder: RecordingStatus.$_createMessage)
    ..aOM<TripStatus>(21, _omitFieldNames ? '' : 'tripStatus',
        subBuilder: TripStatus.$_createMessage)
    ..aOM<NetworkInfo>(23, _omitFieldNames ? '' : 'network',
        subBuilder: NetworkInfo.$_createMessage)
    ..aOS(24, _omitFieldNames ? '' : 'vehicleDataError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse copyWith(void Function(GetStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetStatusResponse))
          as GetStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatusResponse() / GetStatusResponse.new instead')
  static GetStatusResponse create() => GetStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetStatusResponse._();
  @$core.override
  GetStatusResponse createEmptyInstance() => GetStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStatusResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusResponse>(
          GetStatusResponse.$_createMessage);
  static GetStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get deviceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set deviceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDeviceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearDeviceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get vehicleDataReady => $_getBF(1);
  @$pb.TagNumber(2)
  set vehicleDataReady($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVehicleDataReady() => $_has(1);
  @$pb.TagNumber(2)
  void clearVehicleDataReady() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get appVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set appVersion($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAppVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearAppVersion() => $_clearField(3);

  /// Camera IDs currently recording.
  @$pb.TagNumber(4)
  $pb.PbList<$core.int> get recording => $_getList(3);

  /// Camera IDs in view-only mode.
  @$pb.TagNumber(5)
  $pb.PbList<$core.int> get viewing => $_getList(4);

  /// Camera IDs active (recording or view).
  @$pb.TagNumber(6)
  $pb.PbList<$core.int> get active => $_getList(5);

  /// Camera IDs available on this device.
  @$pb.TagNumber(7)
  $pb.PbList<$core.int> get available => $_getList(6);

  @$pb.TagNumber(8)
  BatteryInfo get battery => $_getN(7);
  @$pb.TagNumber(8)
  set battery(BatteryInfo value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasBattery() => $_has(7);
  @$pb.TagNumber(8)
  void clearBattery() => $_clearField(8);
  @$pb.TagNumber(8)
  BatteryInfo ensureBattery() => $_ensure(7);

  @$pb.TagNumber(9)
  $core.bool get acc => $_getBF(8);
  @$pb.TagNumber(9)
  set acc($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAcc() => $_has(8);
  @$pb.TagNumber(9)
  void clearAcc() => $_clearField(9);

  @$pb.TagNumber(10)
  ChargingInfo get charging => $_getN(9);
  @$pb.TagNumber(10)
  set charging(ChargingInfo value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasCharging() => $_has(9);
  @$pb.TagNumber(10)
  void clearCharging() => $_clearField(10);
  @$pb.TagNumber(10)
  ChargingInfo ensureCharging() => $_ensure(9);

  @$pb.TagNumber(11)
  SocInfo get soc => $_getN(10);
  @$pb.TagNumber(11)
  set soc(SocInfo value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSoc() => $_has(10);
  @$pb.TagNumber(11)
  void clearSoc() => $_clearField(11);
  @$pb.TagNumber(11)
  SocInfo ensureSoc() => $_ensure(10);

  @$pb.TagNumber(12)
  RangeInfo get range => $_getN(11);
  @$pb.TagNumber(12)
  set range(RangeInfo value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasRange() => $_has(11);
  @$pb.TagNumber(12)
  void clearRange() => $_clearField(12);
  @$pb.TagNumber(12)
  RangeInfo ensureRange() => $_ensure(11);

  @$pb.TagNumber(13)
  SohInfo get soh => $_getN(12);
  @$pb.TagNumber(13)
  set soh(SohInfo value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasSoh() => $_has(12);
  @$pb.TagNumber(13)
  void clearSoh() => $_clearField(13);
  @$pb.TagNumber(13)
  SohInfo ensureSoh() => $_ensure(12);

  @$pb.TagNumber(14)
  $core.String get distanceUnit => $_getSZ(13);
  @$pb.TagNumber(14)
  set distanceUnit($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasDistanceUnit() => $_has(13);
  @$pb.TagNumber(14)
  void clearDistanceUnit() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get locale => $_getSZ(14);
  @$pb.TagNumber(15)
  set locale($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasLocale() => $_has(14);
  @$pb.TagNumber(15)
  void clearLocale() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.bool get safeZoneSuppressed => $_getBF(15);
  @$pb.TagNumber(16)
  set safeZoneSuppressed($core.bool value) => $_setBool(15, value);
  @$pb.TagNumber(16)
  $core.bool hasSafeZoneSuppressed() => $_has(15);
  @$pb.TagNumber(16)
  void clearSafeZoneSuppressed() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get inSafeZone => $_getBF(16);
  @$pb.TagNumber(17)
  set inSafeZone($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasInSafeZone() => $_has(16);
  @$pb.TagNumber(17)
  void clearInSafeZone() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get safeZoneName => $_getSZ(17);
  @$pb.TagNumber(18)
  set safeZoneName($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasSafeZoneName() => $_has(17);
  @$pb.TagNumber(18)
  void clearSafeZoneName() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.bool get gpuSurveillance => $_getBF(18);
  @$pb.TagNumber(19)
  set gpuSurveillance($core.bool value) => $_setBool(18, value);
  @$pb.TagNumber(19)
  $core.bool hasGpuSurveillance() => $_has(18);
  @$pb.TagNumber(19)
  void clearGpuSurveillance() => $_clearField(19);

  @$pb.TagNumber(20)
  RecordingStatus get recordingStatus => $_getN(19);
  @$pb.TagNumber(20)
  set recordingStatus(RecordingStatus value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasRecordingStatus() => $_has(19);
  @$pb.TagNumber(20)
  void clearRecordingStatus() => $_clearField(20);
  @$pb.TagNumber(20)
  RecordingStatus ensureRecordingStatus() => $_ensure(19);

  @$pb.TagNumber(21)
  TripStatus get tripStatus => $_getN(20);
  @$pb.TagNumber(21)
  set tripStatus(TripStatus value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasTripStatus() => $_has(20);
  @$pb.TagNumber(21)
  void clearTripStatus() => $_clearField(21);
  @$pb.TagNumber(21)
  TripStatus ensureTripStatus() => $_ensure(20);

  @$pb.TagNumber(23)
  NetworkInfo get network => $_getN(21);
  @$pb.TagNumber(23)
  set network(NetworkInfo value) => $_setField(23, value);
  @$pb.TagNumber(23)
  $core.bool hasNetwork() => $_has(21);
  @$pb.TagNumber(23)
  void clearNetwork() => $_clearField(23);
  @$pb.TagNumber(23)
  NetworkInfo ensureNetwork() => $_ensure(21);

  /// Populated only when vehicle data block throws.
  @$pb.TagNumber(24)
  $core.String get vehicleDataError => $_getSZ(22);
  @$pb.TagNumber(24)
  set vehicleDataError($core.String value) => $_setString(22, value);
  @$pb.TagNumber(24)
  $core.bool hasVehicleDataError() => $_has(22);
  @$pb.TagNumber(24)
  void clearVehicleDataError() => $_clearField(24);
}

class GetPerformanceRequest extends $pb.GeneratedMessage {
  factory GetPerformanceRequest() => GetPerformanceRequest._();

  GetPerformanceRequest._();

  factory GetPerformanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPerformanceRequest()..mergeFromBuffer(data, registry);
  factory GetPerformanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPerformanceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPerformanceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetPerformanceRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPerformanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPerformanceRequest copyWith(
          void Function(GetPerformanceRequest) updates) =>
      super.copyWith((message) => updates(message as GetPerformanceRequest))
          as GetPerformanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPerformanceRequest() / GetPerformanceRequest.new instead')
  static GetPerformanceRequest create() => GetPerformanceRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetPerformanceRequest._();
  @$core.override
  GetPerformanceRequest createEmptyInstance() => GetPerformanceRequest._();
  @$core.pragma('dart2js:noInline')
  static GetPerformanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPerformanceRequest>(
          GetPerformanceRequest.$_createMessage);
  static GetPerformanceRequest? _defaultInstance;
}

class GetPerformanceResponse extends $pb.GeneratedMessage {
  factory GetPerformanceResponse({
    $core.bool? success,
    $core.String? performanceJson,
  }) {
    final result = GetPerformanceResponse._();
    if (success != null) result.success = success;
    if (performanceJson != null) result.performanceJson = performanceJson;
    return result;
  }

  GetPerformanceResponse._();

  factory GetPerformanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPerformanceResponse()..mergeFromBuffer(data, registry);
  factory GetPerformanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetPerformanceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPerformanceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetPerformanceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'performanceJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPerformanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPerformanceResponse copyWith(
          void Function(GetPerformanceResponse) updates) =>
      super.copyWith((message) => updates(message as GetPerformanceResponse))
          as GetPerformanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetPerformanceResponse() / GetPerformanceResponse.new instead')
  static GetPerformanceResponse create() => GetPerformanceResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetPerformanceResponse._();
  @$core.override
  GetPerformanceResponse createEmptyInstance() => GetPerformanceResponse._();
  @$core.pragma('dart2js:noInline')
  static GetPerformanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPerformanceResponse>(
          GetPerformanceResponse.$_createMessage);
  static GetPerformanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Raw JSON blob from PerformanceApiHandler (format varies).
  @$pb.TagNumber(2)
  $core.String get performanceJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set performanceJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPerformanceJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearPerformanceJson() => $_clearField(2);
}

class PlayAudioTestRequest extends $pb.GeneratedMessage {
  factory PlayAudioTestRequest({
    $core.int? durationMs,
  }) {
    final result = PlayAudioTestRequest._();
    if (durationMs != null) result.durationMs = durationMs;
    return result;
  }

  PlayAudioTestRequest._();

  factory PlayAudioTestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayAudioTestRequest()..mergeFromBuffer(data, registry);
  factory PlayAudioTestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayAudioTestRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayAudioTestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PlayAudioTestRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'durationMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAudioTestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAudioTestRequest copyWith(void Function(PlayAudioTestRequest) updates) =>
      super.copyWith((message) => updates(message as PlayAudioTestRequest))
          as PlayAudioTestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PlayAudioTestRequest() / PlayAudioTestRequest.new instead')
  static PlayAudioTestRequest create() => PlayAudioTestRequest._();
  static $pb.GeneratedMessage $_createMessage() => PlayAudioTestRequest._();
  @$core.override
  PlayAudioTestRequest createEmptyInstance() => PlayAudioTestRequest._();
  @$core.pragma('dart2js:noInline')
  static PlayAudioTestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayAudioTestRequest>(
          PlayAudioTestRequest.$_createMessage);
  static PlayAudioTestRequest? _defaultInstance;

  /// Duration hint in milliseconds. 0 = use server default.
  @$pb.TagNumber(1)
  $core.int get durationMs => $_getIZ(0);
  @$pb.TagNumber(1)
  set durationMs($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDurationMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearDurationMs() => $_clearField(1);
}

class PlayAudioTestResponse extends $pb.GeneratedMessage {
  factory PlayAudioTestResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? error,
  }) {
    final result = PlayAudioTestResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (error != null) result.error = error;
    return result;
  }

  PlayAudioTestResponse._();

  factory PlayAudioTestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayAudioTestResponse()..mergeFromBuffer(data, registry);
  factory PlayAudioTestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlayAudioTestResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlayAudioTestResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PlayAudioTestResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAudioTestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlayAudioTestResponse copyWith(
          void Function(PlayAudioTestResponse) updates) =>
      super.copyWith((message) => updates(message as PlayAudioTestResponse))
          as PlayAudioTestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PlayAudioTestResponse() / PlayAudioTestResponse.new instead')
  static PlayAudioTestResponse create() => PlayAudioTestResponse._();
  static $pb.GeneratedMessage $_createMessage() => PlayAudioTestResponse._();
  @$core.override
  PlayAudioTestResponse createEmptyInstance() => PlayAudioTestResponse._();
  @$core.pragma('dart2js:noInline')
  static PlayAudioTestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlayAudioTestResponse>(
          PlayAudioTestResponse.$_createMessage);
  static PlayAudioTestResponse? _defaultInstance;

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

/// ModelInfo describes one downloadable AI model.
class ModelInfo extends $pb.GeneratedMessage {
  factory ModelInfo({
    $core.String? name,
    $core.bool? downloaded,
    $fixnum.Int64? sizeBytes,
  }) {
    final result = ModelInfo._();
    if (name != null) result.name = name;
    if (downloaded != null) result.downloaded = downloaded;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    return result;
  }

  ModelInfo._();

  factory ModelInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelInfo()..mergeFromBuffer(data, registry);
  factory ModelInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ModelInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ModelInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ModelInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOB(3, _omitFieldNames ? '' : 'downloaded')
    ..aInt64(4, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ModelInfo copyWith(void Function(ModelInfo) updates) =>
      super.copyWith((message) => updates(message as ModelInfo)) as ModelInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ModelInfo() / ModelInfo.new instead')
  static ModelInfo create() => ModelInfo._();
  static $pb.GeneratedMessage $_createMessage() => ModelInfo._();
  @$core.override
  ModelInfo createEmptyInstance() => ModelInfo._();
  @$core.pragma('dart2js:noInline')
  static ModelInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ModelInfo>(ModelInfo.$_createMessage);
  static ModelInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.bool get downloaded => $_getBF(1);
  @$pb.TagNumber(3)
  set downloaded($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(3)
  $core.bool hasDownloaded() => $_has(1);
  @$pb.TagNumber(3)
  void clearDownloaded() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sizeBytes => $_getI64(2);
  @$pb.TagNumber(4)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(4)
  $core.bool hasSizeBytes() => $_has(2);
  @$pb.TagNumber(4)
  void clearSizeBytes() => $_clearField(4);
}

class ListModelsRequest extends $pb.GeneratedMessage {
  factory ListModelsRequest() => ListModelsRequest._();

  ListModelsRequest._();

  factory ListModelsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsRequest()..mergeFromBuffer(data, registry);
  factory ListModelsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModelsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListModelsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsRequest copyWith(void Function(ListModelsRequest) updates) =>
      super.copyWith((message) => updates(message as ListModelsRequest))
          as ListModelsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListModelsRequest() / ListModelsRequest.new instead')
  static ListModelsRequest create() => ListModelsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListModelsRequest._();
  @$core.override
  ListModelsRequest createEmptyInstance() => ListModelsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListModelsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListModelsRequest>(
          ListModelsRequest.$_createMessage);
  static ListModelsRequest? _defaultInstance;
}

class ListModelsResponse extends $pb.GeneratedMessage {
  factory ListModelsResponse({
    $core.Iterable<ModelInfo>? models,
  }) {
    final result = ListModelsResponse._();
    if (models != null) result.models.addAll(models);
    return result;
  }

  ListModelsResponse._();

  factory ListModelsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsResponse()..mergeFromBuffer(data, registry);
  factory ListModelsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListModelsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListModelsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListModelsResponse.$_createMessage)
    ..pPM<ModelInfo>(2, _omitFieldNames ? '' : 'models',
        subBuilder: ModelInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListModelsResponse copyWith(void Function(ListModelsResponse) updates) =>
      super.copyWith((message) => updates(message as ListModelsResponse))
          as ListModelsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListModelsResponse() / ListModelsResponse.new instead')
  static ListModelsResponse create() => ListModelsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListModelsResponse._();
  @$core.override
  ListModelsResponse createEmptyInstance() => ListModelsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListModelsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListModelsResponse>(
          ListModelsResponse.$_createMessage);
  static ListModelsResponse? _defaultInstance;

  @$pb.TagNumber(2)
  $pb.PbList<ModelInfo> get models => $_getList(0);
}

class DownloadModelRequest extends $pb.GeneratedMessage {
  factory DownloadModelRequest({
    $core.String? url,
    $core.String? name,
  }) {
    final result = DownloadModelRequest._();
    if (url != null) result.url = url;
    if (name != null) result.name = name;
    return result;
  }

  DownloadModelRequest._();

  factory DownloadModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadModelRequest()..mergeFromBuffer(data, registry);
  factory DownloadModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadModelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DownloadModelRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadModelRequest copyWith(void Function(DownloadModelRequest) updates) =>
      super.copyWith((message) => updates(message as DownloadModelRequest))
          as DownloadModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DownloadModelRequest() / DownloadModelRequest.new instead')
  static DownloadModelRequest create() => DownloadModelRequest._();
  static $pb.GeneratedMessage $_createMessage() => DownloadModelRequest._();
  @$core.override
  DownloadModelRequest createEmptyInstance() => DownloadModelRequest._();
  @$core.pragma('dart2js:noInline')
  static DownloadModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadModelRequest>(
          DownloadModelRequest.$_createMessage);
  static DownloadModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);
}

class DownloadModelResponse extends $pb.GeneratedMessage {
  factory DownloadModelResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? error,
  }) {
    final result = DownloadModelResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (error != null) result.error = error;
    return result;
  }

  DownloadModelResponse._();

  factory DownloadModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadModelResponse()..mergeFromBuffer(data, registry);
  factory DownloadModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DownloadModelResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DownloadModelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DownloadModelResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DownloadModelResponse copyWith(
          void Function(DownloadModelResponse) updates) =>
      super.copyWith((message) => updates(message as DownloadModelResponse))
          as DownloadModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DownloadModelResponse() / DownloadModelResponse.new instead')
  static DownloadModelResponse create() => DownloadModelResponse._();
  static $pb.GeneratedMessage $_createMessage() => DownloadModelResponse._();
  @$core.override
  DownloadModelResponse createEmptyInstance() => DownloadModelResponse._();
  @$core.pragma('dart2js:noInline')
  static DownloadModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DownloadModelResponse>(
          DownloadModelResponse.$_createMessage);
  static DownloadModelResponse? _defaultInstance;

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

/// SOH nominal capacity endpoints.
class GetSohNominalRequest extends $pb.GeneratedMessage {
  factory GetSohNominalRequest() => GetSohNominalRequest._();

  GetSohNominalRequest._();

  factory GetSohNominalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohNominalRequest()..mergeFromBuffer(data, registry);
  factory GetSohNominalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohNominalRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSohNominalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSohNominalRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohNominalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohNominalRequest copyWith(void Function(GetSohNominalRequest) updates) =>
      super.copyWith((message) => updates(message as GetSohNominalRequest))
          as GetSohNominalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSohNominalRequest() / GetSohNominalRequest.new instead')
  static GetSohNominalRequest create() => GetSohNominalRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSohNominalRequest._();
  @$core.override
  GetSohNominalRequest createEmptyInstance() => GetSohNominalRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSohNominalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSohNominalRequest>(
          GetSohNominalRequest.$_createMessage);
  static GetSohNominalRequest? _defaultInstance;
}

class GetSohNominalResponse extends $pb.GeneratedMessage {
  factory GetSohNominalResponse({
    $core.double? nominalKwh,
    $core.String? nominalSource,
  }) {
    final result = GetSohNominalResponse._();
    if (nominalKwh != null) result.nominalKwh = nominalKwh;
    if (nominalSource != null) result.nominalSource = nominalSource;
    return result;
  }

  GetSohNominalResponse._();

  factory GetSohNominalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohNominalResponse()..mergeFromBuffer(data, registry);
  factory GetSohNominalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohNominalResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSohNominalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSohNominalResponse.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'nominalKwh')
    ..aOS(2, _omitFieldNames ? '' : 'nominalSource')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohNominalResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohNominalResponse copyWith(
          void Function(GetSohNominalResponse) updates) =>
      super.copyWith((message) => updates(message as GetSohNominalResponse))
          as GetSohNominalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSohNominalResponse() / GetSohNominalResponse.new instead')
  static GetSohNominalResponse create() => GetSohNominalResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSohNominalResponse._();
  @$core.override
  GetSohNominalResponse createEmptyInstance() => GetSohNominalResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSohNominalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSohNominalResponse>(
          GetSohNominalResponse.$_createMessage);
  static GetSohNominalResponse? _defaultInstance;

  /// Present only when a nominal kWh has been set; absent means "unset".
  @$pb.TagNumber(1)
  $core.double get nominalKwh => $_getN(0);
  @$pb.TagNumber(1)
  set nominalKwh($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNominalKwh() => $_has(0);
  @$pb.TagNumber(1)
  void clearNominalKwh() => $_clearField(1);

  /// "user", "auto", or "unset".
  @$pb.TagNumber(2)
  $core.String get nominalSource => $_getSZ(1);
  @$pb.TagNumber(2)
  set nominalSource($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNominalSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearNominalSource() => $_clearField(2);
}

class SetSohNominalRequest extends $pb.GeneratedMessage {
  factory SetSohNominalRequest({
    $core.double? nominalKwh,
  }) {
    final result = SetSohNominalRequest._();
    if (nominalKwh != null) result.nominalKwh = nominalKwh;
    return result;
  }

  SetSohNominalRequest._();

  factory SetSohNominalRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSohNominalRequest()..mergeFromBuffer(data, registry);
  factory SetSohNominalRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSohNominalRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSohNominalRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetSohNominalRequest.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'nominalKwh')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSohNominalRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSohNominalRequest copyWith(void Function(SetSohNominalRequest) updates) =>
      super.copyWith((message) => updates(message as SetSohNominalRequest))
          as SetSohNominalRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSohNominalRequest() / SetSohNominalRequest.new instead')
  static SetSohNominalRequest create() => SetSohNominalRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetSohNominalRequest._();
  @$core.override
  SetSohNominalRequest createEmptyInstance() => SetSohNominalRequest._();
  @$core.pragma('dart2js:noInline')
  static SetSohNominalRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSohNominalRequest>(
          SetSohNominalRequest.$_createMessage);
  static SetSohNominalRequest? _defaultInstance;

  /// Omit (not set) to clear the user override.
  @$pb.TagNumber(1)
  $core.double get nominalKwh => $_getN(0);
  @$pb.TagNumber(1)
  set nominalKwh($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNominalKwh() => $_has(0);
  @$pb.TagNumber(1)
  void clearNominalKwh() => $_clearField(1);
}

class SetSohNominalResponse extends $pb.GeneratedMessage {
  factory SetSohNominalResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = SetSohNominalResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  SetSohNominalResponse._();

  factory SetSohNominalResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSohNominalResponse()..mergeFromBuffer(data, registry);
  factory SetSohNominalResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSohNominalResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSohNominalResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetSohNominalResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSohNominalResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSohNominalResponse copyWith(
          void Function(SetSohNominalResponse) updates) =>
      super.copyWith((message) => updates(message as SetSohNominalResponse))
          as SetSohNominalResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSohNominalResponse() / SetSohNominalResponse.new instead')
  static SetSohNominalResponse create() => SetSohNominalResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetSohNominalResponse._();
  @$core.override
  SetSohNominalResponse createEmptyInstance() => SetSohNominalResponse._();
  @$core.pragma('dart2js:noInline')
  static SetSohNominalResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSohNominalResponse>(
          SetSohNominalResponse.$_createMessage);
  static SetSohNominalResponse? _defaultInstance;

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

/// SOH status (stub — estimation has been removed).
class GetSohStatusRequest extends $pb.GeneratedMessage {
  factory GetSohStatusRequest() => GetSohStatusRequest._();

  GetSohStatusRequest._();

  factory GetSohStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohStatusRequest()..mergeFromBuffer(data, registry);
  factory GetSohStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSohStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSohStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohStatusRequest copyWith(void Function(GetSohStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetSohStatusRequest))
          as GetSohStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetSohStatusRequest() / GetSohStatusRequest.new instead')
  static GetSohStatusRequest create() => GetSohStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSohStatusRequest._();
  @$core.override
  GetSohStatusRequest createEmptyInstance() => GetSohStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSohStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSohStatusRequest>(
          GetSohStatusRequest.$_createMessage);
  static GetSohStatusRequest? _defaultInstance;
}

class GetSohStatusResponse extends $pb.GeneratedMessage {
  factory GetSohStatusResponse({
    $core.bool? success,
    $core.double? nominalCapacityKwh,
    $core.String? nominalSource,
    $core.double? displaySoh,
    $core.String? displaySource,
    $core.String? error,
  }) {
    final result = GetSohStatusResponse._();
    if (success != null) result.success = success;
    if (nominalCapacityKwh != null)
      result.nominalCapacityKwh = nominalCapacityKwh;
    if (nominalSource != null) result.nominalSource = nominalSource;
    if (displaySoh != null) result.displaySoh = displaySoh;
    if (displaySource != null) result.displaySource = displaySource;
    if (error != null) result.error = error;
    return result;
  }

  GetSohStatusResponse._();

  factory GetSohStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohStatusResponse()..mergeFromBuffer(data, registry);
  factory GetSohStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSohStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSohStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSohStatusResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aD(2, _omitFieldNames ? '' : 'nominalCapacityKwh')
    ..aOS(3, _omitFieldNames ? '' : 'nominalSource')
    ..aD(4, _omitFieldNames ? '' : 'displaySoh')
    ..aOS(5, _omitFieldNames ? '' : 'displaySource')
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSohStatusResponse copyWith(void Function(GetSohStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetSohStatusResponse))
          as GetSohStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSohStatusResponse() / GetSohStatusResponse.new instead')
  static GetSohStatusResponse create() => GetSohStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSohStatusResponse._();
  @$core.override
  GetSohStatusResponse createEmptyInstance() => GetSohStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSohStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSohStatusResponse>(
          GetSohStatusResponse.$_createMessage);
  static GetSohStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get nominalCapacityKwh => $_getN(1);
  @$pb.TagNumber(2)
  set nominalCapacityKwh($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNominalCapacityKwh() => $_has(1);
  @$pb.TagNumber(2)
  void clearNominalCapacityKwh() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get nominalSource => $_getSZ(2);
  @$pb.TagNumber(3)
  set nominalSource($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasNominalSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearNominalSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get displaySoh => $_getN(3);
  @$pb.TagNumber(4)
  set displaySoh($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDisplaySoh() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplaySoh() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get displaySource => $_getSZ(4);
  @$pb.TagNumber(5)
  set displaySource($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDisplaySource() => $_has(4);
  @$pb.TagNumber(5)
  void clearDisplaySource() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);
}

class ResetSohRequest extends $pb.GeneratedMessage {
  factory ResetSohRequest() => ResetSohRequest._();

  ResetSohRequest._();

  factory ResetSohRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetSohRequest()..mergeFromBuffer(data, registry);
  factory ResetSohRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetSohRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetSohRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ResetSohRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetSohRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetSohRequest copyWith(void Function(ResetSohRequest) updates) =>
      super.copyWith((message) => updates(message as ResetSohRequest))
          as ResetSohRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResetSohRequest() / ResetSohRequest.new instead')
  static ResetSohRequest create() => ResetSohRequest._();
  static $pb.GeneratedMessage $_createMessage() => ResetSohRequest._();
  @$core.override
  ResetSohRequest createEmptyInstance() => ResetSohRequest._();
  @$core.pragma('dart2js:noInline')
  static ResetSohRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResetSohRequest>(
          ResetSohRequest.$_createMessage);
  static ResetSohRequest? _defaultInstance;
}

class ResetSohResponse extends $pb.GeneratedMessage {
  factory ResetSohResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = ResetSohResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  ResetSohResponse._();

  factory ResetSohResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetSohResponse()..mergeFromBuffer(data, registry);
  factory ResetSohResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetSohResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetSohResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ResetSohResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetSohResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetSohResponse copyWith(void Function(ResetSohResponse) updates) =>
      super.copyWith((message) => updates(message as ResetSohResponse))
          as ResetSohResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ResetSohResponse() / ResetSohResponse.new instead')
  static ResetSohResponse create() => ResetSohResponse._();
  static $pb.GeneratedMessage $_createMessage() => ResetSohResponse._();
  @$core.override
  ResetSohResponse createEmptyInstance() => ResetSohResponse._();
  @$core.pragma('dart2js:noInline')
  static ResetSohResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResetSohResponse>(
          ResetSohResponse.$_createMessage);
  static ResetSohResponse? _defaultInstance;

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

/// Bulk performance data reset.
class ResetPerformanceRequest extends $pb.GeneratedMessage {
  factory ResetPerformanceRequest({
    $core.Iterable<$core.String>? categories,
  }) {
    final result = ResetPerformanceRequest._();
    if (categories != null) result.categories.addAll(categories);
    return result;
  }

  ResetPerformanceRequest._();

  factory ResetPerformanceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetPerformanceRequest()..mergeFromBuffer(data, registry);
  factory ResetPerformanceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetPerformanceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetPerformanceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ResetPerformanceRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'categories')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPerformanceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPerformanceRequest copyWith(
          void Function(ResetPerformanceRequest) updates) =>
      super.copyWith((message) => updates(message as ResetPerformanceRequest))
          as ResetPerformanceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResetPerformanceRequest() / ResetPerformanceRequest.new instead')
  static ResetPerformanceRequest create() => ResetPerformanceRequest._();
  static $pb.GeneratedMessage $_createMessage() => ResetPerformanceRequest._();
  @$core.override
  ResetPerformanceRequest createEmptyInstance() => ResetPerformanceRequest._();
  @$core.pragma('dart2js:noInline')
  static ResetPerformanceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetPerformanceRequest>(
          ResetPerformanceRequest.$_createMessage);
  static ResetPerformanceRequest? _defaultInstance;

  /// Categories to reset: "trips", "socHistory", "soh",
  /// "mediaRecordings", "mediaSurveillance", "mediaProximity", "mediaTrips".
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get categories => $_getList(0);
}

class ResetPerformanceResponse extends $pb.GeneratedMessage {
  factory ResetPerformanceResponse({
    $core.bool? success,
    $core.String? resultsJson,
    $core.String? error,
  }) {
    final result = ResetPerformanceResponse._();
    if (success != null) result.success = success;
    if (resultsJson != null) result.resultsJson = resultsJson;
    if (error != null) result.error = error;
    return result;
  }

  ResetPerformanceResponse._();

  factory ResetPerformanceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetPerformanceResponse()..mergeFromBuffer(data, registry);
  factory ResetPerformanceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ResetPerformanceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ResetPerformanceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ResetPerformanceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'resultsJson')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPerformanceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ResetPerformanceResponse copyWith(
          void Function(ResetPerformanceResponse) updates) =>
      super.copyWith((message) => updates(message as ResetPerformanceResponse))
          as ResetPerformanceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ResetPerformanceResponse() / ResetPerformanceResponse.new instead')
  static ResetPerformanceResponse create() => ResetPerformanceResponse._();
  static $pb.GeneratedMessage $_createMessage() => ResetPerformanceResponse._();
  @$core.override
  ResetPerformanceResponse createEmptyInstance() =>
      ResetPerformanceResponse._();
  @$core.pragma('dart2js:noInline')
  static ResetPerformanceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ResetPerformanceResponse>(
          ResetPerformanceResponse.$_createMessage);
  static ResetPerformanceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Per-category result objects encoded as JSON (map serialisation complexity avoided).
  @$pb.TagNumber(2)
  $core.String get resultsJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set resultsJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResultsJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearResultsJson() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

/// Parking energy-delta and last-charge endpoints.
class GetParkingDeltaRequest extends $pb.GeneratedMessage {
  factory GetParkingDeltaRequest({
    $core.int? maxAgeHours,
  }) {
    final result = GetParkingDeltaRequest._();
    if (maxAgeHours != null) result.maxAgeHours = maxAgeHours;
    return result;
  }

  GetParkingDeltaRequest._();

  factory GetParkingDeltaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetParkingDeltaRequest()..mergeFromBuffer(data, registry);
  factory GetParkingDeltaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetParkingDeltaRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetParkingDeltaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetParkingDeltaRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'maxAgeHours')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetParkingDeltaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetParkingDeltaRequest copyWith(
          void Function(GetParkingDeltaRequest) updates) =>
      super.copyWith((message) => updates(message as GetParkingDeltaRequest))
          as GetParkingDeltaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetParkingDeltaRequest() / GetParkingDeltaRequest.new instead')
  static GetParkingDeltaRequest create() => GetParkingDeltaRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetParkingDeltaRequest._();
  @$core.override
  GetParkingDeltaRequest createEmptyInstance() => GetParkingDeltaRequest._();
  @$core.pragma('dart2js:noInline')
  static GetParkingDeltaRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetParkingDeltaRequest>(
          GetParkingDeltaRequest.$_createMessage);
  static GetParkingDeltaRequest? _defaultInstance;

  /// Hours of history to consider (default 72).
  @$pb.TagNumber(1)
  $core.int get maxAgeHours => $_getIZ(0);
  @$pb.TagNumber(1)
  set maxAgeHours($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMaxAgeHours() => $_has(0);
  @$pb.TagNumber(1)
  void clearMaxAgeHours() => $_clearField(1);
}

class GetParkingDeltaResponse extends $pb.GeneratedMessage {
  factory GetParkingDeltaResponse({
    $core.bool? available,
    $core.String? rawJson,
  }) {
    final result = GetParkingDeltaResponse._();
    if (available != null) result.available = available;
    if (rawJson != null) result.rawJson = rawJson;
    return result;
  }

  GetParkingDeltaResponse._();

  factory GetParkingDeltaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetParkingDeltaResponse()..mergeFromBuffer(data, registry);
  factory GetParkingDeltaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetParkingDeltaResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetParkingDeltaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetParkingDeltaResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'available')
    ..aOS(2, _omitFieldNames ? '' : 'rawJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetParkingDeltaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetParkingDeltaResponse copyWith(
          void Function(GetParkingDeltaResponse) updates) =>
      super.copyWith((message) => updates(message as GetParkingDeltaResponse))
          as GetParkingDeltaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetParkingDeltaResponse() / GetParkingDeltaResponse.new instead')
  static GetParkingDeltaResponse create() => GetParkingDeltaResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetParkingDeltaResponse._();
  @$core.override
  GetParkingDeltaResponse createEmptyInstance() => GetParkingDeltaResponse._();
  @$core.pragma('dart2js:noInline')
  static GetParkingDeltaResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetParkingDeltaResponse>(
          GetParkingDeltaResponse.$_createMessage);
  static GetParkingDeltaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get available => $_getBF(0);
  @$pb.TagNumber(1)
  set available($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAvailable() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvailable() => $_clearField(1);

  /// Full JSON object from SocHistoryDatabase.getLastParkingDelta(), present when available=true.
  @$pb.TagNumber(2)
  $core.String get rawJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set rawJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRawJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawJson() => $_clearField(2);
}

class GetLastChargeRequest extends $pb.GeneratedMessage {
  factory GetLastChargeRequest({
    $core.int? hoursBack,
  }) {
    final result = GetLastChargeRequest._();
    if (hoursBack != null) result.hoursBack = hoursBack;
    return result;
  }

  GetLastChargeRequest._();

  factory GetLastChargeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLastChargeRequest()..mergeFromBuffer(data, registry);
  factory GetLastChargeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLastChargeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLastChargeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetLastChargeRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'hoursBack')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLastChargeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLastChargeRequest copyWith(void Function(GetLastChargeRequest) updates) =>
      super.copyWith((message) => updates(message as GetLastChargeRequest))
          as GetLastChargeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetLastChargeRequest() / GetLastChargeRequest.new instead')
  static GetLastChargeRequest create() => GetLastChargeRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetLastChargeRequest._();
  @$core.override
  GetLastChargeRequest createEmptyInstance() => GetLastChargeRequest._();
  @$core.pragma('dart2js:noInline')
  static GetLastChargeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLastChargeRequest>(
          GetLastChargeRequest.$_createMessage);
  static GetLastChargeRequest? _defaultInstance;

  /// How far back to look in hours (default 24).
  @$pb.TagNumber(1)
  $core.int get hoursBack => $_getIZ(0);
  @$pb.TagNumber(1)
  set hoursBack($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHoursBack() => $_has(0);
  @$pb.TagNumber(1)
  void clearHoursBack() => $_clearField(1);
}

class GetLastChargeResponse extends $pb.GeneratedMessage {
  factory GetLastChargeResponse({
    $core.bool? available,
    $core.String? rawJson,
  }) {
    final result = GetLastChargeResponse._();
    if (available != null) result.available = available;
    if (rawJson != null) result.rawJson = rawJson;
    return result;
  }

  GetLastChargeResponse._();

  factory GetLastChargeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLastChargeResponse()..mergeFromBuffer(data, registry);
  factory GetLastChargeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLastChargeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetLastChargeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetLastChargeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'available')
    ..aOS(2, _omitFieldNames ? '' : 'rawJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLastChargeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLastChargeResponse copyWith(
          void Function(GetLastChargeResponse) updates) =>
      super.copyWith((message) => updates(message as GetLastChargeResponse))
          as GetLastChargeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetLastChargeResponse() / GetLastChargeResponse.new instead')
  static GetLastChargeResponse create() => GetLastChargeResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetLastChargeResponse._();
  @$core.override
  GetLastChargeResponse createEmptyInstance() => GetLastChargeResponse._();
  @$core.pragma('dart2js:noInline')
  static GetLastChargeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLastChargeResponse>(
          GetLastChargeResponse.$_createMessage);
  static GetLastChargeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get available => $_getBF(0);
  @$pb.TagNumber(1)
  set available($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAvailable() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvailable() => $_clearField(1);

  /// Full JSON object from SocHistoryDatabase.getMostRecentCompletedChargingSession(), present when available=true.
  @$pb.TagNumber(2)
  $core.String get rawJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set rawJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRawJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawJson() => $_clearField(2);
}

/// Vehicle model selection and manifest.
class GetSelectedModelRequest extends $pb.GeneratedMessage {
  factory GetSelectedModelRequest() => GetSelectedModelRequest._();

  GetSelectedModelRequest._();

  factory GetSelectedModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSelectedModelRequest()..mergeFromBuffer(data, registry);
  factory GetSelectedModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSelectedModelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSelectedModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSelectedModelRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSelectedModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSelectedModelRequest copyWith(
          void Function(GetSelectedModelRequest) updates) =>
      super.copyWith((message) => updates(message as GetSelectedModelRequest))
          as GetSelectedModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSelectedModelRequest() / GetSelectedModelRequest.new instead')
  static GetSelectedModelRequest create() => GetSelectedModelRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSelectedModelRequest._();
  @$core.override
  GetSelectedModelRequest createEmptyInstance() => GetSelectedModelRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSelectedModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSelectedModelRequest>(
          GetSelectedModelRequest.$_createMessage);
  static GetSelectedModelRequest? _defaultInstance;
}

class GetSelectedModelResponse extends $pb.GeneratedMessage {
  factory GetSelectedModelResponse({
    $core.String? modelId,
    $core.String? color,
  }) {
    final result = GetSelectedModelResponse._();
    if (modelId != null) result.modelId = modelId;
    if (color != null) result.color = color;
    return result;
  }

  GetSelectedModelResponse._();

  factory GetSelectedModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSelectedModelResponse()..mergeFromBuffer(data, registry);
  factory GetSelectedModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSelectedModelResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSelectedModelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSelectedModelResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOS(2, _omitFieldNames ? '' : 'color')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSelectedModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSelectedModelResponse copyWith(
          void Function(GetSelectedModelResponse) updates) =>
      super.copyWith((message) => updates(message as GetSelectedModelResponse))
          as GetSelectedModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSelectedModelResponse() / GetSelectedModelResponse.new instead')
  static GetSelectedModelResponse create() => GetSelectedModelResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSelectedModelResponse._();
  @$core.override
  GetSelectedModelResponse createEmptyInstance() =>
      GetSelectedModelResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSelectedModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSelectedModelResponse>(
          GetSelectedModelResponse.$_createMessage);
  static GetSelectedModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get color => $_getSZ(1);
  @$pb.TagNumber(2)
  set color($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearColor() => $_clearField(2);
}

class SetSelectedModelRequest extends $pb.GeneratedMessage {
  factory SetSelectedModelRequest({
    $core.String? modelId,
    $core.String? color,
  }) {
    final result = SetSelectedModelRequest._();
    if (modelId != null) result.modelId = modelId;
    if (color != null) result.color = color;
    return result;
  }

  SetSelectedModelRequest._();

  factory SetSelectedModelRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSelectedModelRequest()..mergeFromBuffer(data, registry);
  factory SetSelectedModelRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSelectedModelRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSelectedModelRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetSelectedModelRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'modelId')
    ..aOS(2, _omitFieldNames ? '' : 'color')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSelectedModelRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSelectedModelRequest copyWith(
          void Function(SetSelectedModelRequest) updates) =>
      super.copyWith((message) => updates(message as SetSelectedModelRequest))
          as SetSelectedModelRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSelectedModelRequest() / SetSelectedModelRequest.new instead')
  static SetSelectedModelRequest create() => SetSelectedModelRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetSelectedModelRequest._();
  @$core.override
  SetSelectedModelRequest createEmptyInstance() => SetSelectedModelRequest._();
  @$core.pragma('dart2js:noInline')
  static SetSelectedModelRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSelectedModelRequest>(
          SetSelectedModelRequest.$_createMessage);
  static SetSelectedModelRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get modelId => $_getSZ(0);
  @$pb.TagNumber(1)
  set modelId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasModelId() => $_has(0);
  @$pb.TagNumber(1)
  void clearModelId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get color => $_getSZ(1);
  @$pb.TagNumber(2)
  set color($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearColor() => $_clearField(2);
}

class SetSelectedModelResponse extends $pb.GeneratedMessage {
  factory SetSelectedModelResponse({
    $core.bool? ok,
    $core.String? error,
  }) {
    final result = SetSelectedModelResponse._();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    return result;
  }

  SetSelectedModelResponse._();

  factory SetSelectedModelResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSelectedModelResponse()..mergeFromBuffer(data, registry);
  factory SetSelectedModelResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSelectedModelResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSelectedModelResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetSelectedModelResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSelectedModelResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSelectedModelResponse copyWith(
          void Function(SetSelectedModelResponse) updates) =>
      super.copyWith((message) => updates(message as SetSelectedModelResponse))
          as SetSelectedModelResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetSelectedModelResponse() / SetSelectedModelResponse.new instead')
  static SetSelectedModelResponse create() => SetSelectedModelResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetSelectedModelResponse._();
  @$core.override
  SetSelectedModelResponse createEmptyInstance() =>
      SetSelectedModelResponse._();
  @$core.pragma('dart2js:noInline')
  static SetSelectedModelResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetSelectedModelResponse>(
          SetSelectedModelResponse.$_createMessage);
  static SetSelectedModelResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get error => $_getSZ(1);
  @$pb.TagNumber(2)
  set error($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

class GetModelsManifestRequest extends $pb.GeneratedMessage {
  factory GetModelsManifestRequest() => GetModelsManifestRequest._();

  GetModelsManifestRequest._();

  factory GetModelsManifestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetModelsManifestRequest()..mergeFromBuffer(data, registry);
  factory GetModelsManifestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetModelsManifestRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModelsManifestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetModelsManifestRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelsManifestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelsManifestRequest copyWith(
          void Function(GetModelsManifestRequest) updates) =>
      super.copyWith((message) => updates(message as GetModelsManifestRequest))
          as GetModelsManifestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetModelsManifestRequest() / GetModelsManifestRequest.new instead')
  static GetModelsManifestRequest create() => GetModelsManifestRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetModelsManifestRequest._();
  @$core.override
  GetModelsManifestRequest createEmptyInstance() =>
      GetModelsManifestRequest._();
  @$core.pragma('dart2js:noInline')
  static GetModelsManifestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModelsManifestRequest>(
          GetModelsManifestRequest.$_createMessage);
  static GetModelsManifestRequest? _defaultInstance;
}

class GetModelsManifestResponse extends $pb.GeneratedMessage {
  factory GetModelsManifestResponse({
    $core.String? manifestJson,
  }) {
    final result = GetModelsManifestResponse._();
    if (manifestJson != null) result.manifestJson = manifestJson;
    return result;
  }

  GetModelsManifestResponse._();

  factory GetModelsManifestResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetModelsManifestResponse()..mergeFromBuffer(data, registry);
  factory GetModelsManifestResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetModelsManifestResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetModelsManifestResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetModelsManifestResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'manifestJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelsManifestResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetModelsManifestResponse copyWith(
          void Function(GetModelsManifestResponse) updates) =>
      super.copyWith((message) => updates(message as GetModelsManifestResponse))
          as GetModelsManifestResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetModelsManifestResponse() / GetModelsManifestResponse.new instead')
  static GetModelsManifestResponse create() => GetModelsManifestResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetModelsManifestResponse._();
  @$core.override
  GetModelsManifestResponse createEmptyInstance() =>
      GetModelsManifestResponse._();
  @$core.pragma('dart2js:noInline')
  static GetModelsManifestResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetModelsManifestResponse>(
          GetModelsManifestResponse.$_createMessage);
  static GetModelsManifestResponse? _defaultInstance;

  /// Full manifest JSON from /data/local/tmp/web/shared/models/manifest.json.
  @$pb.TagNumber(1)
  $core.String get manifestJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set manifestJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasManifestJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearManifestJson() => $_clearField(1);
}

/// SystemService exposes daemon status, performance metrics, AI model management,
/// and audio testing.
///
/// HTTP mapping:
///   GetStatus          GET  /status
///   GetPerformance     GET  /api/performance     (PerformanceApiHandler)
///   PlayAudioTest      POST /api/audio/test-avas
///   ListModels         GET  /api/models/list
///   DownloadModel      POST /api/models/download
///   GetSohNominal      GET  /api/performance/soh/nominal
///   SetSohNominal      POST /api/performance/soh/nominal
///   GetSohStatus       GET  /api/performance/soh
///   ResetSoh           POST /api/performance/soh/reset
///   ResetPerformance   POST /api/performance/reset
///   GetParkingDelta    GET  /api/performance/parking-delta
///   GetLastCharge      GET  /api/performance/last-charge
///   GetSelectedModel   GET  /api/models/selected
///   SetSelectedModel   POST /api/models/selected
///   GetModelsManifest  GET  /api/models/manifest
class SystemServiceApi {
  final $pb.RpcClient _client;

  SystemServiceApi(this._client);

  $async.Future<GetStatusResponse> getStatus(
          $pb.ClientContext? ctx, GetStatusRequest request) =>
      _client.invoke<GetStatusResponse>(
          ctx, 'SystemService', 'GetStatus', request, GetStatusResponse());
  $async.Future<GetPerformanceResponse> getPerformance(
          $pb.ClientContext? ctx, GetPerformanceRequest request) =>
      _client.invoke<GetPerformanceResponse>(ctx, 'SystemService',
          'GetPerformance', request, GetPerformanceResponse());
  $async.Future<PlayAudioTestResponse> playAudioTest(
          $pb.ClientContext? ctx, PlayAudioTestRequest request) =>
      _client.invoke<PlayAudioTestResponse>(ctx, 'SystemService',
          'PlayAudioTest', request, PlayAudioTestResponse());
  $async.Future<ListModelsResponse> listModels(
          $pb.ClientContext? ctx, ListModelsRequest request) =>
      _client.invoke<ListModelsResponse>(
          ctx, 'SystemService', 'ListModels', request, ListModelsResponse());
  $async.Future<DownloadModelResponse> downloadModel(
          $pb.ClientContext? ctx, DownloadModelRequest request) =>
      _client.invoke<DownloadModelResponse>(ctx, 'SystemService',
          'DownloadModel', request, DownloadModelResponse());
  $async.Future<GetSohNominalResponse> getSohNominal(
          $pb.ClientContext? ctx, GetSohNominalRequest request) =>
      _client.invoke<GetSohNominalResponse>(ctx, 'SystemService',
          'GetSohNominal', request, GetSohNominalResponse());
  $async.Future<SetSohNominalResponse> setSohNominal(
          $pb.ClientContext? ctx, SetSohNominalRequest request) =>
      _client.invoke<SetSohNominalResponse>(ctx, 'SystemService',
          'SetSohNominal', request, SetSohNominalResponse());
  $async.Future<GetSohStatusResponse> getSohStatus(
          $pb.ClientContext? ctx, GetSohStatusRequest request) =>
      _client.invoke<GetSohStatusResponse>(ctx, 'SystemService', 'GetSohStatus',
          request, GetSohStatusResponse());
  $async.Future<ResetSohResponse> resetSoh(
          $pb.ClientContext? ctx, ResetSohRequest request) =>
      _client.invoke<ResetSohResponse>(
          ctx, 'SystemService', 'ResetSoh', request, ResetSohResponse());
  $async.Future<ResetPerformanceResponse> resetPerformance(
          $pb.ClientContext? ctx, ResetPerformanceRequest request) =>
      _client.invoke<ResetPerformanceResponse>(ctx, 'SystemService',
          'ResetPerformance', request, ResetPerformanceResponse());
  $async.Future<GetParkingDeltaResponse> getParkingDelta(
          $pb.ClientContext? ctx, GetParkingDeltaRequest request) =>
      _client.invoke<GetParkingDeltaResponse>(ctx, 'SystemService',
          'GetParkingDelta', request, GetParkingDeltaResponse());
  $async.Future<GetLastChargeResponse> getLastCharge(
          $pb.ClientContext? ctx, GetLastChargeRequest request) =>
      _client.invoke<GetLastChargeResponse>(ctx, 'SystemService',
          'GetLastCharge', request, GetLastChargeResponse());
  $async.Future<GetSelectedModelResponse> getSelectedModel(
          $pb.ClientContext? ctx, GetSelectedModelRequest request) =>
      _client.invoke<GetSelectedModelResponse>(ctx, 'SystemService',
          'GetSelectedModel', request, GetSelectedModelResponse());
  $async.Future<SetSelectedModelResponse> setSelectedModel(
          $pb.ClientContext? ctx, SetSelectedModelRequest request) =>
      _client.invoke<SetSelectedModelResponse>(ctx, 'SystemService',
          'SetSelectedModel', request, SetSelectedModelResponse());
  $async.Future<GetModelsManifestResponse> getModelsManifest(
          $pb.ClientContext? ctx, GetModelsManifestRequest request) =>
      _client.invoke<GetModelsManifestResponse>(ctx, 'SystemService',
          'GetModelsManifest', request, GetModelsManifestResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
