// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/vehicle.proto.

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

/// DoorStatus holds per-door lock state: 1=locked, 2=unlocked, -1=unknown.
class DoorStatus extends $pb.GeneratedMessage {
  factory DoorStatus({
    $core.int? lf,
    $core.int? rf,
    $core.int? lr,
    $core.int? rr,
    $core.int? trunk,
    $core.int? hood,
    $core.int? overall,
  }) {
    final result = DoorStatus._();
    if (lf != null) result.lf = lf;
    if (rf != null) result.rf = rf;
    if (lr != null) result.lr = lr;
    if (rr != null) result.rr = rr;
    if (trunk != null) result.trunk = trunk;
    if (hood != null) result.hood = hood;
    if (overall != null) result.overall = overall;
    return result;
  }

  DoorStatus._();

  factory DoorStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DoorStatus()..mergeFromBuffer(data, registry);
  factory DoorStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DoorStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DoorStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DoorStatus.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'lf')
    ..aI(2, _omitFieldNames ? '' : 'rf')
    ..aI(3, _omitFieldNames ? '' : 'lr')
    ..aI(4, _omitFieldNames ? '' : 'rr')
    ..aI(5, _omitFieldNames ? '' : 'trunk')
    ..aI(6, _omitFieldNames ? '' : 'hood')
    ..aI(7, _omitFieldNames ? '' : 'overall')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DoorStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DoorStatus copyWith(void Function(DoorStatus) updates) =>
      super.copyWith((message) => updates(message as DoorStatus)) as DoorStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DoorStatus() / DoorStatus.new instead')
  static DoorStatus create() => DoorStatus._();
  static $pb.GeneratedMessage $_createMessage() => DoorStatus._();
  @$core.override
  DoorStatus createEmptyInstance() => DoorStatus._();
  @$core.pragma('dart2js:noInline')
  static DoorStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DoorStatus>(DoorStatus.$_createMessage);
  static DoorStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get lf => $_getIZ(0);
  @$pb.TagNumber(1)
  set lf($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLf() => $_has(0);
  @$pb.TagNumber(1)
  void clearLf() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rf => $_getIZ(1);
  @$pb.TagNumber(2)
  set rf($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRf() => $_has(1);
  @$pb.TagNumber(2)
  void clearRf() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get lr => $_getIZ(2);
  @$pb.TagNumber(3)
  set lr($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLr() => $_has(2);
  @$pb.TagNumber(3)
  void clearLr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get rr => $_getIZ(3);
  @$pb.TagNumber(4)
  set rr($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRr() => $_has(3);
  @$pb.TagNumber(4)
  void clearRr() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get trunk => $_getIZ(4);
  @$pb.TagNumber(5)
  set trunk($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTrunk() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrunk() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get hood => $_getIZ(5);
  @$pb.TagNumber(6)
  set hood($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHood() => $_has(5);
  @$pb.TagNumber(6)
  void clearHood() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get overall => $_getIZ(6);
  @$pb.TagNumber(7)
  set overall($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasOverall() => $_has(6);
  @$pb.TagNumber(7)
  void clearOverall() => $_clearField(7);
}

/// WindowStatus holds per-window open percentage: 0=closed, 100=open, -1=unknown.
class WindowStatus extends $pb.GeneratedMessage {
  factory WindowStatus({
    $core.int? lf,
    $core.int? rf,
    $core.int? lr,
    $core.int? rr,
    $core.int? sunroof,
    $core.int? sunshade,
  }) {
    final result = WindowStatus._();
    if (lf != null) result.lf = lf;
    if (rf != null) result.rf = rf;
    if (lr != null) result.lr = lr;
    if (rr != null) result.rr = rr;
    if (sunroof != null) result.sunroof = sunroof;
    if (sunshade != null) result.sunshade = sunshade;
    return result;
  }

  WindowStatus._();

  factory WindowStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WindowStatus()..mergeFromBuffer(data, registry);
  factory WindowStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WindowStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WindowStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: WindowStatus.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'lf')
    ..aI(2, _omitFieldNames ? '' : 'rf')
    ..aI(3, _omitFieldNames ? '' : 'lr')
    ..aI(4, _omitFieldNames ? '' : 'rr')
    ..aI(5, _omitFieldNames ? '' : 'sunroof')
    ..aI(6, _omitFieldNames ? '' : 'sunshade')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WindowStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WindowStatus copyWith(void Function(WindowStatus) updates) =>
      super.copyWith((message) => updates(message as WindowStatus))
          as WindowStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WindowStatus() / WindowStatus.new instead')
  static WindowStatus create() => WindowStatus._();
  static $pb.GeneratedMessage $_createMessage() => WindowStatus._();
  @$core.override
  WindowStatus createEmptyInstance() => WindowStatus._();
  @$core.pragma('dart2js:noInline')
  static WindowStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WindowStatus>(
          WindowStatus.$_createMessage);
  static WindowStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get lf => $_getIZ(0);
  @$pb.TagNumber(1)
  set lf($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLf() => $_has(0);
  @$pb.TagNumber(1)
  void clearLf() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rf => $_getIZ(1);
  @$pb.TagNumber(2)
  set rf($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRf() => $_has(1);
  @$pb.TagNumber(2)
  void clearRf() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get lr => $_getIZ(2);
  @$pb.TagNumber(3)
  set lr($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLr() => $_has(2);
  @$pb.TagNumber(3)
  void clearLr() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get rr => $_getIZ(3);
  @$pb.TagNumber(4)
  set rr($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRr() => $_has(3);
  @$pb.TagNumber(4)
  void clearRr() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get sunroof => $_getIZ(4);
  @$pb.TagNumber(5)
  set sunroof($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSunroof() => $_has(4);
  @$pb.TagNumber(5)
  void clearSunroof() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get sunshade => $_getIZ(5);
  @$pb.TagNumber(6)
  set sunshade($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSunshade() => $_has(5);
  @$pb.TagNumber(6)
  void clearSunshade() => $_clearField(6);
}

class WindowCapabilities extends $pb.GeneratedMessage {
  factory WindowCapabilities({
    $core.bool? sunroof,
    $core.bool? sunshade,
  }) {
    final result = WindowCapabilities._();
    if (sunroof != null) result.sunroof = sunroof;
    if (sunshade != null) result.sunshade = sunshade;
    return result;
  }

  WindowCapabilities._();

  factory WindowCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WindowCapabilities()..mergeFromBuffer(data, registry);
  factory WindowCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WindowCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WindowCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: WindowCapabilities.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'sunroof')
    ..aOB(2, _omitFieldNames ? '' : 'sunshade')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WindowCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WindowCapabilities copyWith(void Function(WindowCapabilities) updates) =>
      super.copyWith((message) => updates(message as WindowCapabilities))
          as WindowCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WindowCapabilities() / WindowCapabilities.new instead')
  static WindowCapabilities create() => WindowCapabilities._();
  static $pb.GeneratedMessage $_createMessage() => WindowCapabilities._();
  @$core.override
  WindowCapabilities createEmptyInstance() => WindowCapabilities._();
  @$core.pragma('dart2js:noInline')
  static WindowCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WindowCapabilities>(
          WindowCapabilities.$_createMessage);
  static WindowCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get sunroof => $_getBF(0);
  @$pb.TagNumber(1)
  set sunroof($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSunroof() => $_has(0);
  @$pb.TagNumber(1)
  void clearSunroof() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get sunshade => $_getBF(1);
  @$pb.TagNumber(2)
  set sunshade($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSunshade() => $_has(1);
  @$pb.TagNumber(2)
  void clearSunshade() => $_clearField(2);
}

class SeatCapabilities extends $pb.GeneratedMessage {
  factory SeatCapabilities({
    $core.bool? driverHeat,
    $core.bool? passengerHeat,
    $core.bool? driverCool,
    $core.bool? passengerCool,
    $core.bool? driverMemoryRecall,
  }) {
    final result = SeatCapabilities._();
    if (driverHeat != null) result.driverHeat = driverHeat;
    if (passengerHeat != null) result.passengerHeat = passengerHeat;
    if (driverCool != null) result.driverCool = driverCool;
    if (passengerCool != null) result.passengerCool = passengerCool;
    if (driverMemoryRecall != null)
      result.driverMemoryRecall = driverMemoryRecall;
    return result;
  }

  SeatCapabilities._();

  factory SeatCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SeatCapabilities()..mergeFromBuffer(data, registry);
  factory SeatCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SeatCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SeatCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SeatCapabilities.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'driverHeat')
    ..aOB(2, _omitFieldNames ? '' : 'passengerHeat')
    ..aOB(3, _omitFieldNames ? '' : 'driverCool')
    ..aOB(4, _omitFieldNames ? '' : 'passengerCool')
    ..aOB(5, _omitFieldNames ? '' : 'driverMemoryRecall')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeatCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeatCapabilities copyWith(void Function(SeatCapabilities) updates) =>
      super.copyWith((message) => updates(message as SeatCapabilities))
          as SeatCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SeatCapabilities() / SeatCapabilities.new instead')
  static SeatCapabilities create() => SeatCapabilities._();
  static $pb.GeneratedMessage $_createMessage() => SeatCapabilities._();
  @$core.override
  SeatCapabilities createEmptyInstance() => SeatCapabilities._();
  @$core.pragma('dart2js:noInline')
  static SeatCapabilities getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SeatCapabilities>(
          SeatCapabilities.$_createMessage);
  static SeatCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get driverHeat => $_getBF(0);
  @$pb.TagNumber(1)
  set driverHeat($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDriverHeat() => $_has(0);
  @$pb.TagNumber(1)
  void clearDriverHeat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get passengerHeat => $_getBF(1);
  @$pb.TagNumber(2)
  set passengerHeat($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassengerHeat() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassengerHeat() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get driverCool => $_getBF(2);
  @$pb.TagNumber(3)
  set driverCool($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDriverCool() => $_has(2);
  @$pb.TagNumber(3)
  void clearDriverCool() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get passengerCool => $_getBF(3);
  @$pb.TagNumber(4)
  set passengerCool($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPassengerCool() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassengerCool() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get driverMemoryRecall => $_getBF(4);
  @$pb.TagNumber(5)
  set driverMemoryRecall($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDriverMemoryRecall() => $_has(4);
  @$pb.TagNumber(5)
  void clearDriverMemoryRecall() => $_clearField(5);
}

class VehicleCapabilities extends $pb.GeneratedMessage {
  factory VehicleCapabilities({
    WindowCapabilities? windows,
    SeatCapabilities? seats,
  }) {
    final result = VehicleCapabilities._();
    if (windows != null) result.windows = windows;
    if (seats != null) result.seats = seats;
    return result;
  }

  VehicleCapabilities._();

  factory VehicleCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VehicleCapabilities()..mergeFromBuffer(data, registry);
  factory VehicleCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VehicleCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VehicleCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: VehicleCapabilities.$_createMessage)
    ..aOM<WindowCapabilities>(1, _omitFieldNames ? '' : 'windows',
        subBuilder: WindowCapabilities.$_createMessage)
    ..aOM<SeatCapabilities>(2, _omitFieldNames ? '' : 'seats',
        subBuilder: SeatCapabilities.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehicleCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehicleCapabilities copyWith(void Function(VehicleCapabilities) updates) =>
      super.copyWith((message) => updates(message as VehicleCapabilities))
          as VehicleCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use VehicleCapabilities() / VehicleCapabilities.new instead')
  static VehicleCapabilities create() => VehicleCapabilities._();
  static $pb.GeneratedMessage $_createMessage() => VehicleCapabilities._();
  @$core.override
  VehicleCapabilities createEmptyInstance() => VehicleCapabilities._();
  @$core.pragma('dart2js:noInline')
  static VehicleCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VehicleCapabilities>(
          VehicleCapabilities.$_createMessage);
  static VehicleCapabilities? _defaultInstance;

  @$pb.TagNumber(1)
  WindowCapabilities get windows => $_getN(0);
  @$pb.TagNumber(1)
  set windows(WindowCapabilities value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasWindows() => $_has(0);
  @$pb.TagNumber(1)
  void clearWindows() => $_clearField(1);
  @$pb.TagNumber(1)
  WindowCapabilities ensureWindows() => $_ensure(0);

  @$pb.TagNumber(2)
  SeatCapabilities get seats => $_getN(1);
  @$pb.TagNumber(2)
  set seats(SeatCapabilities value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSeats() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeats() => $_clearField(2);
  @$pb.TagNumber(2)
  SeatCapabilities ensureSeats() => $_ensure(1);
}

class TrunkStatus extends $pb.GeneratedMessage {
  factory TrunkStatus({
    $core.int? lockStatus,
  }) {
    final result = TrunkStatus._();
    if (lockStatus != null) result.lockStatus = lockStatus;
    return result;
  }

  TrunkStatus._();

  factory TrunkStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrunkStatus()..mergeFromBuffer(data, registry);
  factory TrunkStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrunkStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrunkStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TrunkStatus.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'lockStatus')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrunkStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrunkStatus copyWith(void Function(TrunkStatus) updates) =>
      super.copyWith((message) => updates(message as TrunkStatus))
          as TrunkStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TrunkStatus() / TrunkStatus.new instead')
  static TrunkStatus create() => TrunkStatus._();
  static $pb.GeneratedMessage $_createMessage() => TrunkStatus._();
  @$core.override
  TrunkStatus createEmptyInstance() => TrunkStatus._();
  @$core.pragma('dart2js:noInline')
  static TrunkStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrunkStatus>(
          TrunkStatus.$_createMessage);
  static TrunkStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get lockStatus => $_getIZ(0);
  @$pb.TagNumber(1)
  set lockStatus($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLockStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearLockStatus() => $_clearField(1);
}

class SunroofStatus extends $pb.GeneratedMessage {
  factory SunroofStatus({
    $core.int? state,
    $core.int? position,
  }) {
    final result = SunroofStatus._();
    if (state != null) result.state = state;
    if (position != null) result.position = position;
    return result;
  }

  SunroofStatus._();

  factory SunroofStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SunroofStatus()..mergeFromBuffer(data, registry);
  factory SunroofStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SunroofStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SunroofStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SunroofStatus.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'state')
    ..aI(2, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SunroofStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SunroofStatus copyWith(void Function(SunroofStatus) updates) =>
      super.copyWith((message) => updates(message as SunroofStatus))
          as SunroofStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SunroofStatus() / SunroofStatus.new instead')
  static SunroofStatus create() => SunroofStatus._();
  static $pb.GeneratedMessage $_createMessage() => SunroofStatus._();
  @$core.override
  SunroofStatus createEmptyInstance() => SunroofStatus._();
  @$core.pragma('dart2js:noInline')
  static SunroofStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SunroofStatus>(
          SunroofStatus.$_createMessage);
  static SunroofStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get state => $_getIZ(0);
  @$pb.TagNumber(1)
  set state($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get position => $_getIZ(1);
  @$pb.TagNumber(2)
  set position($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearPosition() => $_clearField(2);
}

class BatteryStatus extends $pb.GeneratedMessage {
  factory BatteryStatus({
    $core.double? soc,
    $core.int? rangeKm,
    $core.int? bodyworkRangeKm,
  }) {
    final result = BatteryStatus._();
    if (soc != null) result.soc = soc;
    if (rangeKm != null) result.rangeKm = rangeKm;
    if (bodyworkRangeKm != null) result.bodyworkRangeKm = bodyworkRangeKm;
    return result;
  }

  BatteryStatus._();

  factory BatteryStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatteryStatus()..mergeFromBuffer(data, registry);
  factory BatteryStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatteryStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatteryStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: BatteryStatus.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'soc')
    ..aI(2, _omitFieldNames ? '' : 'rangeKm')
    ..aI(3, _omitFieldNames ? '' : 'bodyworkRangeKm')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatteryStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatteryStatus copyWith(void Function(BatteryStatus) updates) =>
      super.copyWith((message) => updates(message as BatteryStatus))
          as BatteryStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BatteryStatus() / BatteryStatus.new instead')
  static BatteryStatus create() => BatteryStatus._();
  static $pb.GeneratedMessage $_createMessage() => BatteryStatus._();
  @$core.override
  BatteryStatus createEmptyInstance() => BatteryStatus._();
  @$core.pragma('dart2js:noInline')
  static BatteryStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BatteryStatus>(
          BatteryStatus.$_createMessage);
  static BatteryStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get soc => $_getN(0);
  @$pb.TagNumber(1)
  set soc($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSoc() => $_has(0);
  @$pb.TagNumber(1)
  void clearSoc() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get rangeKm => $_getIZ(1);
  @$pb.TagNumber(2)
  set rangeKm($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRangeKm() => $_has(1);
  @$pb.TagNumber(2)
  void clearRangeKm() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get bodyworkRangeKm => $_getIZ(2);
  @$pb.TagNumber(3)
  set bodyworkRangeKm($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBodyworkRangeKm() => $_has(2);
  @$pb.TagNumber(3)
  void clearBodyworkRangeKm() => $_clearField(3);
}

class LightStatus extends $pb.GeneratedMessage {
  factory LightStatus({
    $core.bool? lowBeam,
    $core.bool? highBeam,
    $core.bool? hazard,
    $core.bool? dayTimeLight,
  }) {
    final result = LightStatus._();
    if (lowBeam != null) result.lowBeam = lowBeam;
    if (highBeam != null) result.highBeam = highBeam;
    if (hazard != null) result.hazard = hazard;
    if (dayTimeLight != null) result.dayTimeLight = dayTimeLight;
    return result;
  }

  LightStatus._();

  factory LightStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LightStatus()..mergeFromBuffer(data, registry);
  factory LightStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LightStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LightStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: LightStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'lowBeam')
    ..aOB(2, _omitFieldNames ? '' : 'highBeam')
    ..aOB(3, _omitFieldNames ? '' : 'hazard')
    ..aOB(4, _omitFieldNames ? '' : 'dayTimeLight')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LightStatus copyWith(void Function(LightStatus) updates) =>
      super.copyWith((message) => updates(message as LightStatus))
          as LightStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LightStatus() / LightStatus.new instead')
  static LightStatus create() => LightStatus._();
  static $pb.GeneratedMessage $_createMessage() => LightStatus._();
  @$core.override
  LightStatus createEmptyInstance() => LightStatus._();
  @$core.pragma('dart2js:noInline')
  static LightStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LightStatus>(
          LightStatus.$_createMessage);
  static LightStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get lowBeam => $_getBF(0);
  @$pb.TagNumber(1)
  set lowBeam($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLowBeam() => $_has(0);
  @$pb.TagNumber(1)
  void clearLowBeam() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get highBeam => $_getBF(1);
  @$pb.TagNumber(2)
  set highBeam($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHighBeam() => $_has(1);
  @$pb.TagNumber(2)
  void clearHighBeam() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get hazard => $_getBF(2);
  @$pb.TagNumber(3)
  set hazard($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHazard() => $_has(2);
  @$pb.TagNumber(3)
  void clearHazard() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get dayTimeLight => $_getBF(3);
  @$pb.TagNumber(4)
  set dayTimeLight($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDayTimeLight() => $_has(3);
  @$pb.TagNumber(4)
  void clearDayTimeLight() => $_clearField(4);
}

class AdasStatus extends $pb.GeneratedMessage {
  factory AdasStatus({
    $core.bool? speedLimitWarning,
  }) {
    final result = AdasStatus._();
    if (speedLimitWarning != null) result.speedLimitWarning = speedLimitWarning;
    return result;
  }

  AdasStatus._();

  factory AdasStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdasStatus()..mergeFromBuffer(data, registry);
  factory AdasStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AdasStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdasStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: AdasStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'speedLimitWarning')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdasStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdasStatus copyWith(void Function(AdasStatus) updates) =>
      super.copyWith((message) => updates(message as AdasStatus)) as AdasStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AdasStatus() / AdasStatus.new instead')
  static AdasStatus create() => AdasStatus._();
  static $pb.GeneratedMessage $_createMessage() => AdasStatus._();
  @$core.override
  AdasStatus createEmptyInstance() => AdasStatus._();
  @$core.pragma('dart2js:noInline')
  static AdasStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdasStatus>(AdasStatus.$_createMessage);
  static AdasStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get speedLimitWarning => $_getBF(0);
  @$pb.TagNumber(1)
  set speedLimitWarning($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSpeedLimitWarning() => $_has(0);
  @$pb.TagNumber(1)
  void clearSpeedLimitWarning() => $_clearField(1);
}

class SeatStatus extends $pb.GeneratedMessage {
  factory SeatStatus({
    $core.Iterable<$core.int>? heat,
    $core.Iterable<$core.int>? cool,
    $core.bool? ventilatedSupported,
  }) {
    final result = SeatStatus._();
    if (heat != null) result.heat.addAll(heat);
    if (cool != null) result.cool.addAll(cool);
    if (ventilatedSupported != null)
      result.ventilatedSupported = ventilatedSupported;
    return result;
  }

  SeatStatus._();

  factory SeatStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SeatStatus()..mergeFromBuffer(data, registry);
  factory SeatStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SeatStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SeatStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SeatStatus.$_createMessage)
    ..p<$core.int>(1, _omitFieldNames ? '' : 'heat', $pb.PbFieldType.K3)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'cool', $pb.PbFieldType.K3)
    ..aOB(3, _omitFieldNames ? '' : 'ventilatedSupported')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeatStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SeatStatus copyWith(void Function(SeatStatus) updates) =>
      super.copyWith((message) => updates(message as SeatStatus)) as SeatStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SeatStatus() / SeatStatus.new instead')
  static SeatStatus create() => SeatStatus._();
  static $pb.GeneratedMessage $_createMessage() => SeatStatus._();
  @$core.override
  SeatStatus createEmptyInstance() => SeatStatus._();
  @$core.pragma('dart2js:noInline')
  static SeatStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SeatStatus>(SeatStatus.$_createMessage);
  static SeatStatus? _defaultInstance;

  /// Heating levels per seat index [0-2], 0=off.
  @$pb.TagNumber(1)
  $pb.PbList<$core.int> get heat => $_getList(0);

  /// Cooling levels per seat index [0-2], 0=off.
  @$pb.TagNumber(2)
  $pb.PbList<$core.int> get cool => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get ventilatedSupported => $_getBF(2);
  @$pb.TagNumber(3)
  set ventilatedSupported($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVentilatedSupported() => $_has(2);
  @$pb.TagNumber(3)
  void clearVentilatedSupported() => $_clearField(3);
}

class ClimateStatus extends $pb.GeneratedMessage {
  factory ClimateStatus({
    $core.bool? acOn,
    $core.double? setpointC,
    $core.double? insideTempC,
    $core.int? windMode,
    $core.int? fanLevel,
    $core.bool? maxCooling,
  }) {
    final result = ClimateStatus._();
    if (acOn != null) result.acOn = acOn;
    if (setpointC != null) result.setpointC = setpointC;
    if (insideTempC != null) result.insideTempC = insideTempC;
    if (windMode != null) result.windMode = windMode;
    if (fanLevel != null) result.fanLevel = fanLevel;
    if (maxCooling != null) result.maxCooling = maxCooling;
    return result;
  }

  ClimateStatus._();

  factory ClimateStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClimateStatus()..mergeFromBuffer(data, registry);
  factory ClimateStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClimateStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClimateStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ClimateStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'acOn')
    ..aD(2, _omitFieldNames ? '' : 'setpointC')
    ..aD(3, _omitFieldNames ? '' : 'insideTempC')
    ..aI(4, _omitFieldNames ? '' : 'windMode')
    ..aI(5, _omitFieldNames ? '' : 'fanLevel')
    ..aOB(6, _omitFieldNames ? '' : 'maxCooling')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClimateStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClimateStatus copyWith(void Function(ClimateStatus) updates) =>
      super.copyWith((message) => updates(message as ClimateStatus))
          as ClimateStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClimateStatus() / ClimateStatus.new instead')
  static ClimateStatus create() => ClimateStatus._();
  static $pb.GeneratedMessage $_createMessage() => ClimateStatus._();
  @$core.override
  ClimateStatus createEmptyInstance() => ClimateStatus._();
  @$core.pragma('dart2js:noInline')
  static ClimateStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClimateStatus>(
          ClimateStatus.$_createMessage);
  static ClimateStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get acOn => $_getBF(0);
  @$pb.TagNumber(1)
  set acOn($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAcOn() => $_has(0);
  @$pb.TagNumber(1)
  void clearAcOn() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get setpointC => $_getN(1);
  @$pb.TagNumber(2)
  set setpointC($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSetpointC() => $_has(1);
  @$pb.TagNumber(2)
  void clearSetpointC() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get insideTempC => $_getN(2);
  @$pb.TagNumber(3)
  set insideTempC($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInsideTempC() => $_has(2);
  @$pb.TagNumber(3)
  void clearInsideTempC() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get windMode => $_getIZ(3);
  @$pb.TagNumber(4)
  set windMode($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWindMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearWindMode() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get fanLevel => $_getIZ(4);
  @$pb.TagNumber(5)
  set fanLevel($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFanLevel() => $_has(4);
  @$pb.TagNumber(5)
  void clearFanLevel() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get maxCooling => $_getBF(5);
  @$pb.TagNumber(6)
  set maxCooling($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMaxCooling() => $_has(5);
  @$pb.TagNumber(6)
  void clearMaxCooling() => $_clearField(6);
}

class TyrePressure extends $pb.GeneratedMessage {
  factory TyrePressure({
    $core.int? kPa,
    $core.double? psi,
    $core.int? tempC,
    $core.int? pressureState,
    $core.int? leakState,
    $core.int? signalState,
  }) {
    final result = TyrePressure._();
    if (kPa != null) result.kPa = kPa;
    if (psi != null) result.psi = psi;
    if (tempC != null) result.tempC = tempC;
    if (pressureState != null) result.pressureState = pressureState;
    if (leakState != null) result.leakState = leakState;
    if (signalState != null) result.signalState = signalState;
    return result;
  }

  TyrePressure._();

  factory TyrePressure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TyrePressure()..mergeFromBuffer(data, registry);
  factory TyrePressure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TyrePressure()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TyrePressure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TyrePressure.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'kPa')
    ..aD(2, _omitFieldNames ? '' : 'psi')
    ..aI(3, _omitFieldNames ? '' : 'temperatureC', protoName: 'temp_c')
    ..aI(4, _omitFieldNames ? '' : 'pressureState')
    ..aI(5, _omitFieldNames ? '' : 'airLeakState', protoName: 'leak_state')
    ..aI(6, _omitFieldNames ? '' : 'signalState')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TyrePressure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TyrePressure copyWith(void Function(TyrePressure) updates) =>
      super.copyWith((message) => updates(message as TyrePressure))
          as TyrePressure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TyrePressure() / TyrePressure.new instead')
  static TyrePressure create() => TyrePressure._();
  static $pb.GeneratedMessage $_createMessage() => TyrePressure._();
  @$core.override
  TyrePressure createEmptyInstance() => TyrePressure._();
  @$core.pragma('dart2js:noInline')
  static TyrePressure getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TyrePressure>(
          TyrePressure.$_createMessage);
  static TyrePressure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get kPa => $_getIZ(0);
  @$pb.TagNumber(1)
  set kPa($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKPa() => $_has(0);
  @$pb.TagNumber(1)
  void clearKPa() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get psi => $_getN(1);
  @$pb.TagNumber(2)
  set psi($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPsi() => $_has(1);
  @$pb.TagNumber(2)
  void clearPsi() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get tempC => $_getIZ(2);
  @$pb.TagNumber(3)
  set tempC($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTempC() => $_has(2);
  @$pb.TagNumber(3)
  void clearTempC() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get pressureState => $_getIZ(3);
  @$pb.TagNumber(4)
  set pressureState($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPressureState() => $_has(3);
  @$pb.TagNumber(4)
  void clearPressureState() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get leakState => $_getIZ(4);
  @$pb.TagNumber(5)
  set leakState($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLeakState() => $_has(4);
  @$pb.TagNumber(5)
  void clearLeakState() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get signalState => $_getIZ(5);
  @$pb.TagNumber(6)
  set signalState($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSignalState() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignalState() => $_clearField(6);
}

class TyreStatus extends $pb.GeneratedMessage {
  factory TyreStatus({
    TyrePressure? fl,
    TyrePressure? fr,
    TyrePressure? rl,
    TyrePressure? rr,
  }) {
    final result = TyreStatus._();
    if (fl != null) result.fl = fl;
    if (fr != null) result.fr = fr;
    if (rl != null) result.rl = rl;
    if (rr != null) result.rr = rr;
    return result;
  }

  TyreStatus._();

  factory TyreStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TyreStatus()..mergeFromBuffer(data, registry);
  factory TyreStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TyreStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TyreStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TyreStatus.$_createMessage)
    ..aOM<TyrePressure>(1, _omitFieldNames ? '' : 'fl',
        subBuilder: TyrePressure.$_createMessage)
    ..aOM<TyrePressure>(2, _omitFieldNames ? '' : 'fr',
        subBuilder: TyrePressure.$_createMessage)
    ..aOM<TyrePressure>(3, _omitFieldNames ? '' : 'rl',
        subBuilder: TyrePressure.$_createMessage)
    ..aOM<TyrePressure>(4, _omitFieldNames ? '' : 'rr',
        subBuilder: TyrePressure.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TyreStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TyreStatus copyWith(void Function(TyreStatus) updates) =>
      super.copyWith((message) => updates(message as TyreStatus)) as TyreStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TyreStatus() / TyreStatus.new instead')
  static TyreStatus create() => TyreStatus._();
  static $pb.GeneratedMessage $_createMessage() => TyreStatus._();
  @$core.override
  TyreStatus createEmptyInstance() => TyreStatus._();
  @$core.pragma('dart2js:noInline')
  static TyreStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TyreStatus>(TyreStatus.$_createMessage);
  static TyreStatus? _defaultInstance;

  @$pb.TagNumber(1)
  TyrePressure get fl => $_getN(0);
  @$pb.TagNumber(1)
  set fl(TyrePressure value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasFl() => $_has(0);
  @$pb.TagNumber(1)
  void clearFl() => $_clearField(1);
  @$pb.TagNumber(1)
  TyrePressure ensureFl() => $_ensure(0);

  @$pb.TagNumber(2)
  TyrePressure get fr => $_getN(1);
  @$pb.TagNumber(2)
  set fr(TyrePressure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFr() => $_has(1);
  @$pb.TagNumber(2)
  void clearFr() => $_clearField(2);
  @$pb.TagNumber(2)
  TyrePressure ensureFr() => $_ensure(1);

  @$pb.TagNumber(3)
  TyrePressure get rl => $_getN(2);
  @$pb.TagNumber(3)
  set rl(TyrePressure value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRl() => $_has(2);
  @$pb.TagNumber(3)
  void clearRl() => $_clearField(3);
  @$pb.TagNumber(3)
  TyrePressure ensureRl() => $_ensure(2);

  @$pb.TagNumber(4)
  TyrePressure get rr => $_getN(3);
  @$pb.TagNumber(4)
  set rr(TyrePressure value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasRr() => $_has(3);
  @$pb.TagNumber(4)
  void clearRr() => $_clearField(4);
  @$pb.TagNumber(4)
  TyrePressure ensureRr() => $_ensure(3);
}

class GetVehicleStateRequest extends $pb.GeneratedMessage {
  factory GetVehicleStateRequest() => GetVehicleStateRequest._();

  GetVehicleStateRequest._();

  factory GetVehicleStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVehicleStateRequest()..mergeFromBuffer(data, registry);
  factory GetVehicleStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVehicleStateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetVehicleStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetVehicleStateRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVehicleStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVehicleStateRequest copyWith(
          void Function(GetVehicleStateRequest) updates) =>
      super.copyWith((message) => updates(message as GetVehicleStateRequest))
          as GetVehicleStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetVehicleStateRequest() / GetVehicleStateRequest.new instead')
  static GetVehicleStateRequest create() => GetVehicleStateRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetVehicleStateRequest._();
  @$core.override
  GetVehicleStateRequest createEmptyInstance() => GetVehicleStateRequest._();
  @$core.pragma('dart2js:noInline')
  static GetVehicleStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetVehicleStateRequest>(
          GetVehicleStateRequest.$_createMessage);
  static GetVehicleStateRequest? _defaultInstance;
}

class GetVehicleStateResponse extends $pb.GeneratedMessage {
  factory GetVehicleStateResponse({
    $core.bool? success,
    DoorStatus? doors,
    WindowStatus? windows,
    VehicleCapabilities? capabilities,
    TrunkStatus? trunk,
    SunroofStatus? sunroof,
    BatteryStatus? battery,
    LightStatus? lights,
    AdasStatus? adas,
    SeatStatus? seats,
    ClimateStatus? climate,
    TyreStatus? tyres,
    $core.String? error,
  }) {
    final result = GetVehicleStateResponse._();
    if (success != null) result.success = success;
    if (doors != null) result.doors = doors;
    if (windows != null) result.windows = windows;
    if (capabilities != null) result.capabilities = capabilities;
    if (trunk != null) result.trunk = trunk;
    if (sunroof != null) result.sunroof = sunroof;
    if (battery != null) result.battery = battery;
    if (lights != null) result.lights = lights;
    if (adas != null) result.adas = adas;
    if (seats != null) result.seats = seats;
    if (climate != null) result.climate = climate;
    if (tyres != null) result.tyres = tyres;
    if (error != null) result.error = error;
    return result;
  }

  GetVehicleStateResponse._();

  factory GetVehicleStateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVehicleStateResponse()..mergeFromBuffer(data, registry);
  factory GetVehicleStateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetVehicleStateResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetVehicleStateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetVehicleStateResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<DoorStatus>(2, _omitFieldNames ? '' : 'doors',
        subBuilder: DoorStatus.$_createMessage)
    ..aOM<WindowStatus>(3, _omitFieldNames ? '' : 'windows',
        subBuilder: WindowStatus.$_createMessage)
    ..aOM<VehicleCapabilities>(4, _omitFieldNames ? '' : 'capabilities',
        subBuilder: VehicleCapabilities.$_createMessage)
    ..aOM<TrunkStatus>(5, _omitFieldNames ? '' : 'trunk',
        subBuilder: TrunkStatus.$_createMessage)
    ..aOM<SunroofStatus>(6, _omitFieldNames ? '' : 'sunroof',
        subBuilder: SunroofStatus.$_createMessage)
    ..aOM<BatteryStatus>(7, _omitFieldNames ? '' : 'battery',
        subBuilder: BatteryStatus.$_createMessage)
    ..aOM<LightStatus>(8, _omitFieldNames ? '' : 'lights',
        subBuilder: LightStatus.$_createMessage)
    ..aOM<AdasStatus>(9, _omitFieldNames ? '' : 'adas',
        subBuilder: AdasStatus.$_createMessage)
    ..aOM<SeatStatus>(10, _omitFieldNames ? '' : 'seats',
        subBuilder: SeatStatus.$_createMessage)
    ..aOM<ClimateStatus>(11, _omitFieldNames ? '' : 'climate',
        subBuilder: ClimateStatus.$_createMessage)
    ..aOM<TyreStatus>(12, _omitFieldNames ? '' : 'tyres',
        subBuilder: TyreStatus.$_createMessage)
    ..aOS(13, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVehicleStateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetVehicleStateResponse copyWith(
          void Function(GetVehicleStateResponse) updates) =>
      super.copyWith((message) => updates(message as GetVehicleStateResponse))
          as GetVehicleStateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetVehicleStateResponse() / GetVehicleStateResponse.new instead')
  static GetVehicleStateResponse create() => GetVehicleStateResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetVehicleStateResponse._();
  @$core.override
  GetVehicleStateResponse createEmptyInstance() => GetVehicleStateResponse._();
  @$core.pragma('dart2js:noInline')
  static GetVehicleStateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetVehicleStateResponse>(
          GetVehicleStateResponse.$_createMessage);
  static GetVehicleStateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  DoorStatus get doors => $_getN(1);
  @$pb.TagNumber(2)
  set doors(DoorStatus value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDoors() => $_has(1);
  @$pb.TagNumber(2)
  void clearDoors() => $_clearField(2);
  @$pb.TagNumber(2)
  DoorStatus ensureDoors() => $_ensure(1);

  @$pb.TagNumber(3)
  WindowStatus get windows => $_getN(2);
  @$pb.TagNumber(3)
  set windows(WindowStatus value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasWindows() => $_has(2);
  @$pb.TagNumber(3)
  void clearWindows() => $_clearField(3);
  @$pb.TagNumber(3)
  WindowStatus ensureWindows() => $_ensure(2);

  @$pb.TagNumber(4)
  VehicleCapabilities get capabilities => $_getN(3);
  @$pb.TagNumber(4)
  set capabilities(VehicleCapabilities value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCapabilities() => $_has(3);
  @$pb.TagNumber(4)
  void clearCapabilities() => $_clearField(4);
  @$pb.TagNumber(4)
  VehicleCapabilities ensureCapabilities() => $_ensure(3);

  @$pb.TagNumber(5)
  TrunkStatus get trunk => $_getN(4);
  @$pb.TagNumber(5)
  set trunk(TrunkStatus value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTrunk() => $_has(4);
  @$pb.TagNumber(5)
  void clearTrunk() => $_clearField(5);
  @$pb.TagNumber(5)
  TrunkStatus ensureTrunk() => $_ensure(4);

  @$pb.TagNumber(6)
  SunroofStatus get sunroof => $_getN(5);
  @$pb.TagNumber(6)
  set sunroof(SunroofStatus value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasSunroof() => $_has(5);
  @$pb.TagNumber(6)
  void clearSunroof() => $_clearField(6);
  @$pb.TagNumber(6)
  SunroofStatus ensureSunroof() => $_ensure(5);

  @$pb.TagNumber(7)
  BatteryStatus get battery => $_getN(6);
  @$pb.TagNumber(7)
  set battery(BatteryStatus value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasBattery() => $_has(6);
  @$pb.TagNumber(7)
  void clearBattery() => $_clearField(7);
  @$pb.TagNumber(7)
  BatteryStatus ensureBattery() => $_ensure(6);

  @$pb.TagNumber(8)
  LightStatus get lights => $_getN(7);
  @$pb.TagNumber(8)
  set lights(LightStatus value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasLights() => $_has(7);
  @$pb.TagNumber(8)
  void clearLights() => $_clearField(8);
  @$pb.TagNumber(8)
  LightStatus ensureLights() => $_ensure(7);

  @$pb.TagNumber(9)
  AdasStatus get adas => $_getN(8);
  @$pb.TagNumber(9)
  set adas(AdasStatus value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasAdas() => $_has(8);
  @$pb.TagNumber(9)
  void clearAdas() => $_clearField(9);
  @$pb.TagNumber(9)
  AdasStatus ensureAdas() => $_ensure(8);

  @$pb.TagNumber(10)
  SeatStatus get seats => $_getN(9);
  @$pb.TagNumber(10)
  set seats(SeatStatus value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSeats() => $_has(9);
  @$pb.TagNumber(10)
  void clearSeats() => $_clearField(10);
  @$pb.TagNumber(10)
  SeatStatus ensureSeats() => $_ensure(9);

  @$pb.TagNumber(11)
  ClimateStatus get climate => $_getN(10);
  @$pb.TagNumber(11)
  set climate(ClimateStatus value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasClimate() => $_has(10);
  @$pb.TagNumber(11)
  void clearClimate() => $_clearField(11);
  @$pb.TagNumber(11)
  ClimateStatus ensureClimate() => $_ensure(10);

  @$pb.TagNumber(12)
  TyreStatus get tyres => $_getN(11);
  @$pb.TagNumber(12)
  set tyres(TyreStatus value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasTyres() => $_has(11);
  @$pb.TagNumber(12)
  void clearTyres() => $_clearField(12);
  @$pb.TagNumber(12)
  TyreStatus ensureTyres() => $_ensure(11);

  @$pb.TagNumber(13)
  $core.String get error => $_getSZ(12);
  @$pb.TagNumber(13)
  set error($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasError() => $_has(12);
  @$pb.TagNumber(13)
  void clearError() => $_clearField(13);
}

class GetAcDiagnosticsRequest extends $pb.GeneratedMessage {
  factory GetAcDiagnosticsRequest() => GetAcDiagnosticsRequest._();

  GetAcDiagnosticsRequest._();

  factory GetAcDiagnosticsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAcDiagnosticsRequest()..mergeFromBuffer(data, registry);
  factory GetAcDiagnosticsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAcDiagnosticsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAcDiagnosticsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetAcDiagnosticsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAcDiagnosticsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAcDiagnosticsRequest copyWith(
          void Function(GetAcDiagnosticsRequest) updates) =>
      super.copyWith((message) => updates(message as GetAcDiagnosticsRequest))
          as GetAcDiagnosticsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAcDiagnosticsRequest() / GetAcDiagnosticsRequest.new instead')
  static GetAcDiagnosticsRequest create() => GetAcDiagnosticsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAcDiagnosticsRequest._();
  @$core.override
  GetAcDiagnosticsRequest createEmptyInstance() => GetAcDiagnosticsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAcDiagnosticsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAcDiagnosticsRequest>(
          GetAcDiagnosticsRequest.$_createMessage);
  static GetAcDiagnosticsRequest? _defaultInstance;
}

class GetAcDiagnosticsResponse extends $pb.GeneratedMessage {
  factory GetAcDiagnosticsResponse({
    $core.bool? success,
    $core.String? rawJson,
  }) {
    final result = GetAcDiagnosticsResponse._();
    if (success != null) result.success = success;
    if (rawJson != null) result.rawJson = rawJson;
    return result;
  }

  GetAcDiagnosticsResponse._();

  factory GetAcDiagnosticsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAcDiagnosticsResponse()..mergeFromBuffer(data, registry);
  factory GetAcDiagnosticsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAcDiagnosticsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetAcDiagnosticsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetAcDiagnosticsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'rawJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAcDiagnosticsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAcDiagnosticsResponse copyWith(
          void Function(GetAcDiagnosticsResponse) updates) =>
      super.copyWith((message) => updates(message as GetAcDiagnosticsResponse))
          as GetAcDiagnosticsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetAcDiagnosticsResponse() / GetAcDiagnosticsResponse.new instead')
  static GetAcDiagnosticsResponse create() => GetAcDiagnosticsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetAcDiagnosticsResponse._();
  @$core.override
  GetAcDiagnosticsResponse createEmptyInstance() =>
      GetAcDiagnosticsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAcDiagnosticsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetAcDiagnosticsResponse>(
          GetAcDiagnosticsResponse.$_createMessage);
  static GetAcDiagnosticsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get rawJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set rawJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRawJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawJson() => $_clearField(2);
}

class GetSeatDiagnosticsRequest extends $pb.GeneratedMessage {
  factory GetSeatDiagnosticsRequest() => GetSeatDiagnosticsRequest._();

  GetSeatDiagnosticsRequest._();

  factory GetSeatDiagnosticsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSeatDiagnosticsRequest()..mergeFromBuffer(data, registry);
  factory GetSeatDiagnosticsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSeatDiagnosticsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSeatDiagnosticsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSeatDiagnosticsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSeatDiagnosticsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSeatDiagnosticsRequest copyWith(
          void Function(GetSeatDiagnosticsRequest) updates) =>
      super.copyWith((message) => updates(message as GetSeatDiagnosticsRequest))
          as GetSeatDiagnosticsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSeatDiagnosticsRequest() / GetSeatDiagnosticsRequest.new instead')
  static GetSeatDiagnosticsRequest create() => GetSeatDiagnosticsRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetSeatDiagnosticsRequest._();
  @$core.override
  GetSeatDiagnosticsRequest createEmptyInstance() =>
      GetSeatDiagnosticsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSeatDiagnosticsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSeatDiagnosticsRequest>(
          GetSeatDiagnosticsRequest.$_createMessage);
  static GetSeatDiagnosticsRequest? _defaultInstance;
}

class GetSeatDiagnosticsResponse extends $pb.GeneratedMessage {
  factory GetSeatDiagnosticsResponse({
    $core.bool? success,
    $core.String? rawJson,
  }) {
    final result = GetSeatDiagnosticsResponse._();
    if (success != null) result.success = success;
    if (rawJson != null) result.rawJson = rawJson;
    return result;
  }

  GetSeatDiagnosticsResponse._();

  factory GetSeatDiagnosticsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSeatDiagnosticsResponse()..mergeFromBuffer(data, registry);
  factory GetSeatDiagnosticsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSeatDiagnosticsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSeatDiagnosticsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSeatDiagnosticsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'rawJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSeatDiagnosticsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSeatDiagnosticsResponse copyWith(
          void Function(GetSeatDiagnosticsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetSeatDiagnosticsResponse))
          as GetSeatDiagnosticsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSeatDiagnosticsResponse() / GetSeatDiagnosticsResponse.new instead')
  static GetSeatDiagnosticsResponse create() => GetSeatDiagnosticsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetSeatDiagnosticsResponse._();
  @$core.override
  GetSeatDiagnosticsResponse createEmptyInstance() =>
      GetSeatDiagnosticsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSeatDiagnosticsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSeatDiagnosticsResponse>(
          GetSeatDiagnosticsResponse.$_createMessage);
  static GetSeatDiagnosticsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get rawJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set rawJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRawJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearRawJson() => $_clearField(2);
}

/// VehicleCommandResponse is a generic response for write commands.
class VehicleCommandResponse extends $pb.GeneratedMessage {
  factory VehicleCommandResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? error,
    $core.String? outcome,
    $core.String? path,
  }) {
    final result = VehicleCommandResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (error != null) result.error = error;
    if (outcome != null) result.outcome = outcome;
    if (path != null) result.path = path;
    return result;
  }

  VehicleCommandResponse._();

  factory VehicleCommandResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VehicleCommandResponse()..mergeFromBuffer(data, registry);
  factory VehicleCommandResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VehicleCommandResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VehicleCommandResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: VehicleCommandResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..aOS(4, _omitFieldNames ? '' : 'outcome')
    ..aOS(5, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehicleCommandResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VehicleCommandResponse copyWith(
          void Function(VehicleCommandResponse) updates) =>
      super.copyWith((message) => updates(message as VehicleCommandResponse))
          as VehicleCommandResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use VehicleCommandResponse() / VehicleCommandResponse.new instead')
  static VehicleCommandResponse create() => VehicleCommandResponse._();
  static $pb.GeneratedMessage $_createMessage() => VehicleCommandResponse._();
  @$core.override
  VehicleCommandResponse createEmptyInstance() => VehicleCommandResponse._();
  @$core.pragma('dart2js:noInline')
  static VehicleCommandResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VehicleCommandResponse>(
          VehicleCommandResponse.$_createMessage);
  static VehicleCommandResponse? _defaultInstance;

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

  /// Routing outcome from the server (e.g. "success", "not_supported", "failed").
  /// The REST handler already emits this key via routedResponse().
  @$pb.TagNumber(4)
  $core.String get outcome => $_getSZ(3);
  @$pb.TagNumber(4)
  set outcome($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasOutcome() => $_has(3);
  @$pb.TagNumber(4)
  void clearOutcome() => $_clearField(4);

  /// The routing path taken (e.g. "sdk_only", "cloud_only"). Emitted by routedResponse().
  @$pb.TagNumber(5)
  $core.String get path => $_getSZ(4);
  @$pb.TagNumber(5)
  set path($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearPath() => $_clearField(5);
}

class LockRequest extends $pb.GeneratedMessage {
  factory LockRequest() => LockRequest._();

  LockRequest._();

  factory LockRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LockRequest()..mergeFromBuffer(data, registry);
  factory LockRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LockRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LockRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: LockRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LockRequest copyWith(void Function(LockRequest) updates) =>
      super.copyWith((message) => updates(message as LockRequest))
          as LockRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LockRequest() / LockRequest.new instead')
  static LockRequest create() => LockRequest._();
  static $pb.GeneratedMessage $_createMessage() => LockRequest._();
  @$core.override
  LockRequest createEmptyInstance() => LockRequest._();
  @$core.pragma('dart2js:noInline')
  static LockRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LockRequest>(
          LockRequest.$_createMessage);
  static LockRequest? _defaultInstance;
}

class UnlockRequest extends $pb.GeneratedMessage {
  factory UnlockRequest() => UnlockRequest._();

  UnlockRequest._();

  factory UnlockRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockRequest()..mergeFromBuffer(data, registry);
  factory UnlockRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UnlockRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UnlockRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: UnlockRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UnlockRequest copyWith(void Function(UnlockRequest) updates) =>
      super.copyWith((message) => updates(message as UnlockRequest))
          as UnlockRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UnlockRequest() / UnlockRequest.new instead')
  static UnlockRequest create() => UnlockRequest._();
  static $pb.GeneratedMessage $_createMessage() => UnlockRequest._();
  @$core.override
  UnlockRequest createEmptyInstance() => UnlockRequest._();
  @$core.pragma('dart2js:noInline')
  static UnlockRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UnlockRequest>(
          UnlockRequest.$_createMessage);
  static UnlockRequest? _defaultInstance;
}

class FlashRequest extends $pb.GeneratedMessage {
  factory FlashRequest() => FlashRequest._();

  FlashRequest._();

  factory FlashRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FlashRequest()..mergeFromBuffer(data, registry);
  factory FlashRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FlashRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FlashRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: FlashRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlashRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FlashRequest copyWith(void Function(FlashRequest) updates) =>
      super.copyWith((message) => updates(message as FlashRequest))
          as FlashRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FlashRequest() / FlashRequest.new instead')
  static FlashRequest create() => FlashRequest._();
  static $pb.GeneratedMessage $_createMessage() => FlashRequest._();
  @$core.override
  FlashRequest createEmptyInstance() => FlashRequest._();
  @$core.pragma('dart2js:noInline')
  static FlashRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FlashRequest>(
          FlashRequest.$_createMessage);
  static FlashRequest? _defaultInstance;
}

class FindCarRequest extends $pb.GeneratedMessage {
  factory FindCarRequest() => FindCarRequest._();

  FindCarRequest._();

  factory FindCarRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FindCarRequest()..mergeFromBuffer(data, registry);
  factory FindCarRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FindCarRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FindCarRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: FindCarRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FindCarRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FindCarRequest copyWith(void Function(FindCarRequest) updates) =>
      super.copyWith((message) => updates(message as FindCarRequest))
          as FindCarRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FindCarRequest() / FindCarRequest.new instead')
  static FindCarRequest create() => FindCarRequest._();
  static $pb.GeneratedMessage $_createMessage() => FindCarRequest._();
  @$core.override
  FindCarRequest createEmptyInstance() => FindCarRequest._();
  @$core.pragma('dart2js:noInline')
  static FindCarRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FindCarRequest>(
          FindCarRequest.$_createMessage);
  static FindCarRequest? _defaultInstance;
}

class TrunkRequest extends $pb.GeneratedMessage {
  factory TrunkRequest({
    $core.String? action,
  }) {
    final result = TrunkRequest._();
    if (action != null) result.action = action;
    return result;
  }

  TrunkRequest._();

  factory TrunkRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrunkRequest()..mergeFromBuffer(data, registry);
  factory TrunkRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TrunkRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrunkRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TrunkRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrunkRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrunkRequest copyWith(void Function(TrunkRequest) updates) =>
      super.copyWith((message) => updates(message as TrunkRequest))
          as TrunkRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TrunkRequest() / TrunkRequest.new instead')
  static TrunkRequest create() => TrunkRequest._();
  static $pb.GeneratedMessage $_createMessage() => TrunkRequest._();
  @$core.override
  TrunkRequest createEmptyInstance() => TrunkRequest._();
  @$core.pragma('dart2js:noInline')
  static TrunkRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TrunkRequest>(
          TrunkRequest.$_createMessage);
  static TrunkRequest? _defaultInstance;

  /// "open", "close", or "stop".
  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);
}

class MoveWindowRequest extends $pb.GeneratedMessage {
  factory MoveWindowRequest({
    $core.int? windowIndex,
    $core.String? direction,
    $core.int? targetPercent,
  }) {
    final result = MoveWindowRequest._();
    if (windowIndex != null) result.windowIndex = windowIndex;
    if (direction != null) result.direction = direction;
    if (targetPercent != null) result.targetPercent = targetPercent;
    return result;
  }

  MoveWindowRequest._();

  factory MoveWindowRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MoveWindowRequest()..mergeFromBuffer(data, registry);
  factory MoveWindowRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MoveWindowRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MoveWindowRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: MoveWindowRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'windowIndex')
    ..aOS(2, _omitFieldNames ? '' : 'direction')
    ..aI(3, _omitFieldNames ? '' : 'targetPercent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveWindowRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MoveWindowRequest copyWith(void Function(MoveWindowRequest) updates) =>
      super.copyWith((message) => updates(message as MoveWindowRequest))
          as MoveWindowRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MoveWindowRequest() / MoveWindowRequest.new instead')
  static MoveWindowRequest create() => MoveWindowRequest._();
  static $pb.GeneratedMessage $_createMessage() => MoveWindowRequest._();
  @$core.override
  MoveWindowRequest createEmptyInstance() => MoveWindowRequest._();
  @$core.pragma('dart2js:noInline')
  static MoveWindowRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MoveWindowRequest>(
          MoveWindowRequest.$_createMessage);
  static MoveWindowRequest? _defaultInstance;

  /// Window index: 0=all, 1=LF, 2=RF, 3=LR, 4=RR, 5=sunroof, 6=sunshade.
  @$pb.TagNumber(1)
  $core.int get windowIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set windowIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWindowIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearWindowIndex() => $_clearField(1);

  /// Direction: "open" or "close".
  @$pb.TagNumber(2)
  $core.String get direction => $_getSZ(1);
  @$pb.TagNumber(2)
  set direction($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDirection() => $_has(1);
  @$pb.TagNumber(2)
  void clearDirection() => $_clearField(2);

  /// Explicit presence: 0% (fully closed preset) is a default scalar and would
  /// be omitted from JSON without optional, routing the request to the direction
  /// path instead of the closed-loop positioning path.
  @$pb.TagNumber(3)
  $core.int get targetPercent => $_getIZ(2);
  @$pb.TagNumber(3)
  set targetPercent($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTargetPercent() => $_has(2);
  @$pb.TagNumber(3)
  void clearTargetPercent() => $_clearField(3);
}

class SetClimateRequest extends $pb.GeneratedMessage {
  factory SetClimateRequest({
    $core.String? action,
    $core.bool? on,
    $core.double? setpointC,
    $core.int? fanLevel,
    $core.int? windMode,
    $core.bool? maxCooling,
    $core.bool? restoreAcOn,
    $core.double? restoreTempC,
    $core.int? restoreFanLevel,
  }) {
    final result = SetClimateRequest._();
    if (action != null) result.action = action;
    if (on != null) result.on = on;
    if (setpointC != null) result.setpointC = setpointC;
    if (fanLevel != null) result.fanLevel = fanLevel;
    if (windMode != null) result.windMode = windMode;
    if (maxCooling != null) result.maxCooling = maxCooling;
    if (restoreAcOn != null) result.restoreAcOn = restoreAcOn;
    if (restoreTempC != null) result.restoreTempC = restoreTempC;
    if (restoreFanLevel != null) result.restoreFanLevel = restoreFanLevel;
    return result;
  }

  SetClimateRequest._();

  factory SetClimateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetClimateRequest()..mergeFromBuffer(data, registry);
  factory SetClimateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetClimateRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetClimateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetClimateRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..aOB(2, _omitFieldNames ? '' : 'on')
    ..aD(3, _omitFieldNames ? '' : 'setpointC')
    ..aI(4, _omitFieldNames ? '' : 'fanLevel')
    ..aI(5, _omitFieldNames ? '' : 'windMode')
    ..aOB(6, _omitFieldNames ? '' : 'maxCooling')
    ..aOB(7, _omitFieldNames ? '' : 'restoreAcOn')
    ..aD(8, _omitFieldNames ? '' : 'restoreTempC')
    ..aI(9, _omitFieldNames ? '' : 'restoreFanLevel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetClimateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetClimateRequest copyWith(void Function(SetClimateRequest) updates) =>
      super.copyWith((message) => updates(message as SetClimateRequest))
          as SetClimateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetClimateRequest() / SetClimateRequest.new instead')
  static SetClimateRequest create() => SetClimateRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetClimateRequest._();
  @$core.override
  SetClimateRequest createEmptyInstance() => SetClimateRequest._();
  @$core.pragma('dart2js:noInline')
  static SetClimateRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetClimateRequest>(
          SetClimateRequest.$_createMessage);
  static SetClimateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get on => $_getBF(1);
  @$pb.TagNumber(2)
  set on($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOn() => $_has(1);
  @$pb.TagNumber(2)
  void clearOn() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get setpointC => $_getN(2);
  @$pb.TagNumber(3)
  set setpointC($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSetpointC() => $_has(2);
  @$pb.TagNumber(3)
  void clearSetpointC() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get fanLevel => $_getIZ(3);
  @$pb.TagNumber(4)
  set fanLevel($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFanLevel() => $_has(3);
  @$pb.TagNumber(4)
  void clearFanLevel() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get windMode => $_getIZ(4);
  @$pb.TagNumber(5)
  set windMode($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasWindMode() => $_has(4);
  @$pb.TagNumber(5)
  void clearWindMode() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get maxCooling => $_getBF(5);
  @$pb.TagNumber(6)
  set maxCooling($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMaxCooling() => $_has(5);
  @$pb.TagNumber(6)
  void clearMaxCooling() => $_clearField(6);

  /// Restore params: used when disabling max_cooling to re-apply prior AC state.
  @$pb.TagNumber(7)
  $core.bool get restoreAcOn => $_getBF(6);
  @$pb.TagNumber(7)
  set restoreAcOn($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRestoreAcOn() => $_has(6);
  @$pb.TagNumber(7)
  void clearRestoreAcOn() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get restoreTempC => $_getN(7);
  @$pb.TagNumber(8)
  set restoreTempC($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRestoreTempC() => $_has(7);
  @$pb.TagNumber(8)
  void clearRestoreTempC() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get restoreFanLevel => $_getIZ(8);
  @$pb.TagNumber(9)
  set restoreFanLevel($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasRestoreFanLevel() => $_has(8);
  @$pb.TagNumber(9)
  void clearRestoreFanLevel() => $_clearField(9);
}

class SetSeatRequest extends $pb.GeneratedMessage {
  factory SetSeatRequest({
    $core.int? seatIndex,
    $core.String? action,
    $core.int? level,
    $core.int? driverHeat,
    $core.int? driverVent,
    $core.int? passengerHeat,
    $core.int? passengerVent,
  }) {
    final result = SetSeatRequest._();
    if (seatIndex != null) result.seatIndex = seatIndex;
    if (action != null) result.action = action;
    if (level != null) result.level = level;
    if (driverHeat != null) result.driverHeat = driverHeat;
    if (driverVent != null) result.driverVent = driverVent;
    if (passengerHeat != null) result.passengerHeat = passengerHeat;
    if (passengerVent != null) result.passengerVent = passengerVent;
    return result;
  }

  SetSeatRequest._();

  factory SetSeatRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSeatRequest()..mergeFromBuffer(data, registry);
  factory SetSeatRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetSeatRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetSeatRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetSeatRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'seatIndex')
    ..aOS(2, _omitFieldNames ? '' : 'action')
    ..aI(3, _omitFieldNames ? '' : 'level')
    ..aI(4, _omitFieldNames ? '' : 'driverHeat')
    ..aI(5, _omitFieldNames ? '' : 'driverVent')
    ..aI(6, _omitFieldNames ? '' : 'passengerHeat')
    ..aI(7, _omitFieldNames ? '' : 'passengerVent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSeatRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetSeatRequest copyWith(void Function(SetSeatRequest) updates) =>
      super.copyWith((message) => updates(message as SetSeatRequest))
          as SetSeatRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetSeatRequest() / SetSeatRequest.new instead')
  static SetSeatRequest create() => SetSeatRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetSeatRequest._();
  @$core.override
  SetSeatRequest createEmptyInstance() => SetSeatRequest._();
  @$core.pragma('dart2js:noInline')
  static SetSeatRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetSeatRequest>(
          SetSeatRequest.$_createMessage);
  static SetSeatRequest? _defaultInstance;

  /// Seat index: 1=driver, 2=passenger.
  @$pb.TagNumber(1)
  $core.int get seatIndex => $_getIZ(0);
  @$pb.TagNumber(1)
  set seatIndex($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeatIndex() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeatIndex() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get action => $_getSZ(1);
  @$pb.TagNumber(2)
  set action($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAction() => $_has(1);
  @$pb.TagNumber(2)
  void clearAction() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get level => $_getIZ(2);
  @$pb.TagNumber(3)
  set level($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLevel() => $_clearField(3);

  /// Full current seat state: cloud API is stateful and requires these on every call.
  @$pb.TagNumber(4)
  $core.int get driverHeat => $_getIZ(3);
  @$pb.TagNumber(4)
  set driverHeat($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDriverHeat() => $_has(3);
  @$pb.TagNumber(4)
  void clearDriverHeat() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get driverVent => $_getIZ(4);
  @$pb.TagNumber(5)
  set driverVent($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDriverVent() => $_has(4);
  @$pb.TagNumber(5)
  void clearDriverVent() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get passengerHeat => $_getIZ(5);
  @$pb.TagNumber(6)
  set passengerHeat($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPassengerHeat() => $_has(5);
  @$pb.TagNumber(6)
  void clearPassengerHeat() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get passengerVent => $_getIZ(6);
  @$pb.TagNumber(7)
  set passengerVent($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPassengerVent() => $_has(6);
  @$pb.TagNumber(7)
  void clearPassengerVent() => $_clearField(7);
}

class SetLightsRequest extends $pb.GeneratedMessage {
  factory SetLightsRequest({
    $core.String? action,
    $core.bool? on,
  }) {
    final result = SetLightsRequest._();
    if (action != null) result.action = action;
    if (on != null) result.on = on;
    return result;
  }

  SetLightsRequest._();

  factory SetLightsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLightsRequest()..mergeFromBuffer(data, registry);
  factory SetLightsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLightsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetLightsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetLightsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..aOB(2, _omitFieldNames ? '' : 'on')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLightsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLightsRequest copyWith(void Function(SetLightsRequest) updates) =>
      super.copyWith((message) => updates(message as SetLightsRequest))
          as SetLightsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetLightsRequest() / SetLightsRequest.new instead')
  static SetLightsRequest create() => SetLightsRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetLightsRequest._();
  @$core.override
  SetLightsRequest createEmptyInstance() => SetLightsRequest._();
  @$core.pragma('dart2js:noInline')
  static SetLightsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetLightsRequest>(
          SetLightsRequest.$_createMessage);
  static SetLightsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  /// Explicit presence: a pure disable request sets on=false, which a plain
  /// proto3 bool would omit from the JSON wire (default-scalar omission), so
  /// the handler would never see the boolean. optional forces it onto the wire.
  @$pb.TagNumber(2)
  $core.bool get on => $_getBF(1);
  @$pb.TagNumber(2)
  set on($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOn() => $_has(1);
  @$pb.TagNumber(2)
  void clearOn() => $_clearField(2);
}

class SetAdasRequest extends $pb.GeneratedMessage {
  factory SetAdasRequest({
    $core.String? action,
    $core.bool? on,
  }) {
    final result = SetAdasRequest._();
    if (action != null) result.action = action;
    if (on != null) result.on = on;
    return result;
  }

  SetAdasRequest._();

  factory SetAdasRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetAdasRequest()..mergeFromBuffer(data, registry);
  factory SetAdasRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetAdasRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetAdasRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetAdasRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'action')
    ..aOB(2, _omitFieldNames ? '' : 'on')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAdasRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetAdasRequest copyWith(void Function(SetAdasRequest) updates) =>
      super.copyWith((message) => updates(message as SetAdasRequest))
          as SetAdasRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetAdasRequest() / SetAdasRequest.new instead')
  static SetAdasRequest create() => SetAdasRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetAdasRequest._();
  @$core.override
  SetAdasRequest createEmptyInstance() => SetAdasRequest._();
  @$core.pragma('dart2js:noInline')
  static SetAdasRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetAdasRequest>(
          SetAdasRequest.$_createMessage);
  static SetAdasRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get action => $_getSZ(0);
  @$pb.TagNumber(1)
  set action($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAction() => $_has(0);
  @$pb.TagNumber(1)
  void clearAction() => $_clearField(1);

  /// Explicit presence: a pure disable request sets on=false, which a plain
  /// proto3 bool would omit from the JSON wire (default-scalar omission), so
  /// the handler would never see the boolean. optional forces it onto the wire.
  @$pb.TagNumber(2)
  $core.bool get on => $_getBF(1);
  @$pb.TagNumber(2)
  set on($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOn() => $_has(1);
  @$pb.TagNumber(2)
  void clearOn() => $_clearField(2);
}

class SetBatteryHeatRequest extends $pb.GeneratedMessage {
  factory SetBatteryHeatRequest({
    $core.bool? on,
  }) {
    final result = SetBatteryHeatRequest._();
    if (on != null) result.on = on;
    return result;
  }

  SetBatteryHeatRequest._();

  factory SetBatteryHeatRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetBatteryHeatRequest()..mergeFromBuffer(data, registry);
  factory SetBatteryHeatRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetBatteryHeatRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetBatteryHeatRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetBatteryHeatRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'on')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetBatteryHeatRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetBatteryHeatRequest copyWith(
          void Function(SetBatteryHeatRequest) updates) =>
      super.copyWith((message) => updates(message as SetBatteryHeatRequest))
          as SetBatteryHeatRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetBatteryHeatRequest() / SetBatteryHeatRequest.new instead')
  static SetBatteryHeatRequest create() => SetBatteryHeatRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetBatteryHeatRequest._();
  @$core.override
  SetBatteryHeatRequest createEmptyInstance() => SetBatteryHeatRequest._();
  @$core.pragma('dart2js:noInline')
  static SetBatteryHeatRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetBatteryHeatRequest>(
          SetBatteryHeatRequest.$_createMessage);
  static SetBatteryHeatRequest? _defaultInstance;

  /// Explicit presence: a pure disable request sets on=false, which a plain
  /// proto3 bool would omit from the JSON wire (default-scalar omission), so
  /// the handler would never see the boolean. optional forces it onto the wire.
  @$pb.TagNumber(1)
  $core.bool get on => $_getBF(0);
  @$pb.TagNumber(1)
  set on($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOn() => $_has(0);
  @$pb.TagNumber(1)
  void clearOn() => $_clearField(1);
}

class GetChargingScheduleRequest extends $pb.GeneratedMessage {
  factory GetChargingScheduleRequest() => GetChargingScheduleRequest._();

  GetChargingScheduleRequest._();

  factory GetChargingScheduleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargingScheduleRequest()..mergeFromBuffer(data, registry);
  factory GetChargingScheduleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargingScheduleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetChargingScheduleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetChargingScheduleRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargingScheduleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargingScheduleRequest copyWith(
          void Function(GetChargingScheduleRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetChargingScheduleRequest))
          as GetChargingScheduleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetChargingScheduleRequest() / GetChargingScheduleRequest.new instead')
  static GetChargingScheduleRequest create() => GetChargingScheduleRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetChargingScheduleRequest._();
  @$core.override
  GetChargingScheduleRequest createEmptyInstance() =>
      GetChargingScheduleRequest._();
  @$core.pragma('dart2js:noInline')
  static GetChargingScheduleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetChargingScheduleRequest>(
          GetChargingScheduleRequest.$_createMessage);
  static GetChargingScheduleRequest? _defaultInstance;
}

class GetChargingScheduleResponse extends $pb.GeneratedMessage {
  factory GetChargingScheduleResponse({
    $core.bool? success,
    $core.bool? enabled,
    $core.String? startChargeTime,
    $core.String? endChargeTime,
    $core.int? chargeWay,
    $core.String? error,
    $core.bool? supported,
    $core.String? reason,
  }) {
    final result = GetChargingScheduleResponse._();
    if (success != null) result.success = success;
    if (enabled != null) result.enabled = enabled;
    if (startChargeTime != null) result.startChargeTime = startChargeTime;
    if (endChargeTime != null) result.endChargeTime = endChargeTime;
    if (chargeWay != null) result.chargeWay = chargeWay;
    if (error != null) result.error = error;
    if (supported != null) result.supported = supported;
    if (reason != null) result.reason = reason;
    return result;
  }

  GetChargingScheduleResponse._();

  factory GetChargingScheduleResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargingScheduleResponse()..mergeFromBuffer(data, registry);
  factory GetChargingScheduleResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargingScheduleResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetChargingScheduleResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetChargingScheduleResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..aOS(3, _omitFieldNames ? '' : 'startChargeTime')
    ..aOS(4, _omitFieldNames ? '' : 'endChargeTime')
    ..aI(5, _omitFieldNames ? '' : 'chargeWay')
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..aOB(7, _omitFieldNames ? '' : 'supported')
    ..aOS(8, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargingScheduleResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargingScheduleResponse copyWith(
          void Function(GetChargingScheduleResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetChargingScheduleResponse))
          as GetChargingScheduleResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetChargingScheduleResponse() / GetChargingScheduleResponse.new instead')
  static GetChargingScheduleResponse create() =>
      GetChargingScheduleResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetChargingScheduleResponse._();
  @$core.override
  GetChargingScheduleResponse createEmptyInstance() =>
      GetChargingScheduleResponse._();
  @$core.pragma('dart2js:noInline')
  static GetChargingScheduleResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetChargingScheduleResponse>(
          GetChargingScheduleResponse.$_createMessage);
  static GetChargingScheduleResponse? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.String get startChargeTime => $_getSZ(2);
  @$pb.TagNumber(3)
  set startChargeTime($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStartChargeTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartChargeTime() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get endChargeTime => $_getSZ(3);
  @$pb.TagNumber(4)
  set endChargeTime($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEndChargeTime() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndChargeTime() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get chargeWay => $_getIZ(4);
  @$pb.TagNumber(5)
  set chargeWay($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasChargeWay() => $_has(4);
  @$pb.TagNumber(5)
  void clearChargeWay() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);

  /// Whether charging-schedule readback is available. The BYD cloud source was
  /// removed, so this currently reports false with reason "cloud_not_configured"
  /// so the UI can hide the section instead of showing an empty schedule.
  @$pb.TagNumber(7)
  $core.bool get supported => $_getBF(6);
  @$pb.TagNumber(7)
  set supported($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSupported() => $_has(6);
  @$pb.TagNumber(7)
  void clearSupported() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get reason => $_getSZ(7);
  @$pb.TagNumber(8)
  set reason($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReason() => $_has(7);
  @$pb.TagNumber(8)
  void clearReason() => $_clearField(8);
}

class SetChargingScheduleRequest extends $pb.GeneratedMessage {
  factory SetChargingScheduleRequest({
    $core.String? startChargeTime,
    $core.String? endChargeTime,
    $core.int? chargeWay,
    $core.bool? enabled,
  }) {
    final result = SetChargingScheduleRequest._();
    if (startChargeTime != null) result.startChargeTime = startChargeTime;
    if (endChargeTime != null) result.endChargeTime = endChargeTime;
    if (chargeWay != null) result.chargeWay = chargeWay;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetChargingScheduleRequest._();

  factory SetChargingScheduleRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetChargingScheduleRequest()..mergeFromBuffer(data, registry);
  factory SetChargingScheduleRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetChargingScheduleRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetChargingScheduleRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetChargingScheduleRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'startChargeTime')
    ..aOS(2, _omitFieldNames ? '' : 'endChargeTime')
    ..aI(3, _omitFieldNames ? '' : 'chargeWay')
    ..aOB(4, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetChargingScheduleRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetChargingScheduleRequest copyWith(
          void Function(SetChargingScheduleRequest) updates) =>
      super.copyWith(
              (message) => updates(message as SetChargingScheduleRequest))
          as SetChargingScheduleRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetChargingScheduleRequest() / SetChargingScheduleRequest.new instead')
  static SetChargingScheduleRequest create() => SetChargingScheduleRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetChargingScheduleRequest._();
  @$core.override
  SetChargingScheduleRequest createEmptyInstance() =>
      SetChargingScheduleRequest._();
  @$core.pragma('dart2js:noInline')
  static SetChargingScheduleRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetChargingScheduleRequest>(
          SetChargingScheduleRequest.$_createMessage);
  static SetChargingScheduleRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get startChargeTime => $_getSZ(0);
  @$pb.TagNumber(1)
  set startChargeTime($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStartChargeTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartChargeTime() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get endChargeTime => $_getSZ(1);
  @$pb.TagNumber(2)
  set endChargeTime($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEndChargeTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndChargeTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get chargeWay => $_getIZ(2);
  @$pb.TagNumber(3)
  set chargeWay($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChargeWay() => $_has(2);
  @$pb.TagNumber(3)
  void clearChargeWay() => $_clearField(3);

  /// Explicit presence: a pure "disable only" request sets enabled=false,
  /// which a plain proto3 bool would omit from the JSON wire (default-scalar
  /// omission), causing the handler's has("enabled") check to fail. optional
  /// forces it onto the wire.
  @$pb.TagNumber(4)
  $core.bool get enabled => $_getBF(3);
  @$pb.TagNumber(4)
  set enabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => $_clearField(4);
}

class GetChargeCapRequest extends $pb.GeneratedMessage {
  factory GetChargeCapRequest() => GetChargeCapRequest._();

  GetChargeCapRequest._();

  factory GetChargeCapRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargeCapRequest()..mergeFromBuffer(data, registry);
  factory GetChargeCapRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargeCapRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetChargeCapRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetChargeCapRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargeCapRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargeCapRequest copyWith(void Function(GetChargeCapRequest) updates) =>
      super.copyWith((message) => updates(message as GetChargeCapRequest))
          as GetChargeCapRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetChargeCapRequest() / GetChargeCapRequest.new instead')
  static GetChargeCapRequest create() => GetChargeCapRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetChargeCapRequest._();
  @$core.override
  GetChargeCapRequest createEmptyInstance() => GetChargeCapRequest._();
  @$core.pragma('dart2js:noInline')
  static GetChargeCapRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetChargeCapRequest>(
          GetChargeCapRequest.$_createMessage);
  static GetChargeCapRequest? _defaultInstance;
}

class GetChargeCapResponse extends $pb.GeneratedMessage {
  factory GetChargeCapResponse({
    $core.bool? success,
    $core.int? percent,
    $core.bool? enabled,
    $core.bool? supported,
    $core.String? error,
  }) {
    final result = GetChargeCapResponse._();
    if (success != null) result.success = success;
    if (percent != null) result.percent = percent;
    if (enabled != null) result.enabled = enabled;
    if (supported != null) result.supported = supported;
    if (error != null) result.error = error;
    return result;
  }

  GetChargeCapResponse._();

  factory GetChargeCapResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargeCapResponse()..mergeFromBuffer(data, registry);
  factory GetChargeCapResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetChargeCapResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetChargeCapResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetChargeCapResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aI(2, _omitFieldNames ? '' : 'percent')
    ..aOB(3, _omitFieldNames ? '' : 'enabled')
    ..aOB(4, _omitFieldNames ? '' : 'supported')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargeCapResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetChargeCapResponse copyWith(void Function(GetChargeCapResponse) updates) =>
      super.copyWith((message) => updates(message as GetChargeCapResponse))
          as GetChargeCapResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetChargeCapResponse() / GetChargeCapResponse.new instead')
  static GetChargeCapResponse create() => GetChargeCapResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetChargeCapResponse._();
  @$core.override
  GetChargeCapResponse createEmptyInstance() => GetChargeCapResponse._();
  @$core.pragma('dart2js:noInline')
  static GetChargeCapResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetChargeCapResponse>(
          GetChargeCapResponse.$_createMessage);
  static GetChargeCapResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Tri-state: the REST handler emits JSON null for "not yet probed". Marking
  /// these optional lets a parsed null stay unset (has()=false) so the client
  /// can distinguish "not probed" from a real 0/false.
  @$pb.TagNumber(2)
  $core.int get percent => $_getIZ(1);
  @$pb.TagNumber(2)
  set percent($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPercent() => $_has(1);
  @$pb.TagNumber(2)
  void clearPercent() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get enabled => $_getBF(2);
  @$pb.TagNumber(3)
  set enabled($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEnabled() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnabled() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get supported => $_getBF(3);
  @$pb.TagNumber(4)
  set supported($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSupported() => $_has(3);
  @$pb.TagNumber(4)
  void clearSupported() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
}

class SetChargeCapRequest extends $pb.GeneratedMessage {
  factory SetChargeCapRequest({
    $core.int? percent,
    $core.bool? enabled,
  }) {
    final result = SetChargeCapRequest._();
    if (percent != null) result.percent = percent;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetChargeCapRequest._();

  factory SetChargeCapRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetChargeCapRequest()..mergeFromBuffer(data, registry);
  factory SetChargeCapRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetChargeCapRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetChargeCapRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetChargeCapRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'percent')
    ..aOB(2, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetChargeCapRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetChargeCapRequest copyWith(void Function(SetChargeCapRequest) updates) =>
      super.copyWith((message) => updates(message as SetChargeCapRequest))
          as SetChargeCapRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SetChargeCapRequest() / SetChargeCapRequest.new instead')
  static SetChargeCapRequest create() => SetChargeCapRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetChargeCapRequest._();
  @$core.override
  SetChargeCapRequest createEmptyInstance() => SetChargeCapRequest._();
  @$core.pragma('dart2js:noInline')
  static SetChargeCapRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetChargeCapRequest>(
          SetChargeCapRequest.$_createMessage);
  static SetChargeCapRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get percent => $_getIZ(0);
  @$pb.TagNumber(1)
  set percent($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPercent() => $_has(0);
  @$pb.TagNumber(1)
  void clearPercent() => $_clearField(1);

  /// Explicit presence: a pure disable request sets enabled=false, which a plain
  /// proto3 bool would omit from the JSON wire (default-scalar omission), making
  /// the handler's has("enabled") check fail. optional forces it onto the wire.
  @$pb.TagNumber(2)
  $core.bool get enabled => $_getBF(1);
  @$pb.TagNumber(2)
  set enabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnabled() => $_clearField(2);
}

class GetGpsLocationRequest extends $pb.GeneratedMessage {
  factory GetGpsLocationRequest() => GetGpsLocationRequest._();

  GetGpsLocationRequest._();

  factory GetGpsLocationRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsLocationRequest()..mergeFromBuffer(data, registry);
  factory GetGpsLocationRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsLocationRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGpsLocationRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetGpsLocationRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsLocationRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsLocationRequest copyWith(
          void Function(GetGpsLocationRequest) updates) =>
      super.copyWith((message) => updates(message as GetGpsLocationRequest))
          as GetGpsLocationRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGpsLocationRequest() / GetGpsLocationRequest.new instead')
  static GetGpsLocationRequest create() => GetGpsLocationRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetGpsLocationRequest._();
  @$core.override
  GetGpsLocationRequest createEmptyInstance() => GetGpsLocationRequest._();
  @$core.pragma('dart2js:noInline')
  static GetGpsLocationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGpsLocationRequest>(
          GetGpsLocationRequest.$_createMessage);
  static GetGpsLocationRequest? _defaultInstance;
}

class GetGpsLocationResponse extends $pb.GeneratedMessage {
  factory GetGpsLocationResponse({
    $core.bool? success,
    $core.String? locationJson,
    $core.String? googleMapsUrl,
  }) {
    final result = GetGpsLocationResponse._();
    if (success != null) result.success = success;
    if (locationJson != null) result.locationJson = locationJson;
    if (googleMapsUrl != null) result.googleMapsUrl = googleMapsUrl;
    return result;
  }

  GetGpsLocationResponse._();

  factory GetGpsLocationResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsLocationResponse()..mergeFromBuffer(data, registry);
  factory GetGpsLocationResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsLocationResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGpsLocationResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetGpsLocationResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'locationJson')
    ..aOS(3, _omitFieldNames ? '' : 'googleMapsUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsLocationResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsLocationResponse copyWith(
          void Function(GetGpsLocationResponse) updates) =>
      super.copyWith((message) => updates(message as GetGpsLocationResponse))
          as GetGpsLocationResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetGpsLocationResponse() / GetGpsLocationResponse.new instead')
  static GetGpsLocationResponse create() => GetGpsLocationResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetGpsLocationResponse._();
  @$core.override
  GetGpsLocationResponse createEmptyInstance() => GetGpsLocationResponse._();
  @$core.pragma('dart2js:noInline')
  static GetGpsLocationResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGpsLocationResponse>(
          GetGpsLocationResponse.$_createMessage);
  static GetGpsLocationResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Nested location object from GpsMonitor.getLocationJson().
  @$pb.TagNumber(2)
  $core.String get locationJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set locationJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLocationJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearLocationJson() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get googleMapsUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set googleMapsUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGoogleMapsUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearGoogleMapsUrl() => $_clearField(3);
}

class StartGpsRequest extends $pb.GeneratedMessage {
  factory StartGpsRequest() => StartGpsRequest._();

  StartGpsRequest._();

  factory StartGpsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartGpsRequest()..mergeFromBuffer(data, registry);
  factory StartGpsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartGpsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartGpsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StartGpsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartGpsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartGpsRequest copyWith(void Function(StartGpsRequest) updates) =>
      super.copyWith((message) => updates(message as StartGpsRequest))
          as StartGpsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StartGpsRequest() / StartGpsRequest.new instead')
  static StartGpsRequest create() => StartGpsRequest._();
  static $pb.GeneratedMessage $_createMessage() => StartGpsRequest._();
  @$core.override
  StartGpsRequest createEmptyInstance() => StartGpsRequest._();
  @$core.pragma('dart2js:noInline')
  static StartGpsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartGpsRequest>(
          StartGpsRequest.$_createMessage);
  static StartGpsRequest? _defaultInstance;
}

class StartGpsResponse extends $pb.GeneratedMessage {
  factory StartGpsResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? locationJson,
  }) {
    final result = StartGpsResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (locationJson != null) result.locationJson = locationJson;
    return result;
  }

  StartGpsResponse._();

  factory StartGpsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartGpsResponse()..mergeFromBuffer(data, registry);
  factory StartGpsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartGpsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartGpsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StartGpsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'locationJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartGpsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartGpsResponse copyWith(void Function(StartGpsResponse) updates) =>
      super.copyWith((message) => updates(message as StartGpsResponse))
          as StartGpsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StartGpsResponse() / StartGpsResponse.new instead')
  static StartGpsResponse create() => StartGpsResponse._();
  static $pb.GeneratedMessage $_createMessage() => StartGpsResponse._();
  @$core.override
  StartGpsResponse createEmptyInstance() => StartGpsResponse._();
  @$core.pragma('dart2js:noInline')
  static StartGpsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartGpsResponse>(
          StartGpsResponse.$_createMessage);
  static StartGpsResponse? _defaultInstance;

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
  $core.String get locationJson => $_getSZ(2);
  @$pb.TagNumber(3)
  set locationJson($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLocationJson() => $_has(2);
  @$pb.TagNumber(3)
  void clearLocationJson() => $_clearField(3);
}

class StopGpsRequest extends $pb.GeneratedMessage {
  factory StopGpsRequest() => StopGpsRequest._();

  StopGpsRequest._();

  factory StopGpsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopGpsRequest()..mergeFromBuffer(data, registry);
  factory StopGpsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopGpsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopGpsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StopGpsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopGpsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopGpsRequest copyWith(void Function(StopGpsRequest) updates) =>
      super.copyWith((message) => updates(message as StopGpsRequest))
          as StopGpsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StopGpsRequest() / StopGpsRequest.new instead')
  static StopGpsRequest create() => StopGpsRequest._();
  static $pb.GeneratedMessage $_createMessage() => StopGpsRequest._();
  @$core.override
  StopGpsRequest createEmptyInstance() => StopGpsRequest._();
  @$core.pragma('dart2js:noInline')
  static StopGpsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StopGpsRequest>(
          StopGpsRequest.$_createMessage);
  static StopGpsRequest? _defaultInstance;
}

class StopGpsResponse extends $pb.GeneratedMessage {
  factory StopGpsResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = StopGpsResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  StopGpsResponse._();

  factory StopGpsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopGpsResponse()..mergeFromBuffer(data, registry);
  factory StopGpsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopGpsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopGpsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StopGpsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopGpsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopGpsResponse copyWith(void Function(StopGpsResponse) updates) =>
      super.copyWith((message) => updates(message as StopGpsResponse))
          as StopGpsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StopGpsResponse() / StopGpsResponse.new instead')
  static StopGpsResponse create() => StopGpsResponse._();
  static $pb.GeneratedMessage $_createMessage() => StopGpsResponse._();
  @$core.override
  StopGpsResponse createEmptyInstance() => StopGpsResponse._();
  @$core.pragma('dart2js:noInline')
  static StopGpsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StopGpsResponse>(
          StopGpsResponse.$_createMessage);
  static StopGpsResponse? _defaultInstance;

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

/// VehicleService exposes BYD vehicle state reads and control commands.
///
/// HTTP mapping:
///   GetState             GET  /api/vehicle/state
///   GetAcDiagnostics     GET  /api/vehicle/ac-diagnostics
///   GetSeatDiagnostics   GET  /api/vehicle/seat-diagnostics
///   Lock                 POST /api/vehicle/lock
///   Unlock               POST /api/vehicle/unlock
///   Trunk                POST /api/vehicle/trunk
///   MoveWindow           POST /api/vehicle/window
///   Flash                POST /api/vehicle/flash
///   FindCar              POST /api/vehicle/find-car
///   SetClimate           POST /api/vehicle/climate
///   SetSeat              POST /api/vehicle/seat
///   SetLights            POST /api/vehicle/lights
///   SetAdas              POST /api/vehicle/adas
///   SetBatteryHeat       POST /api/vehicle/battery-heat
///   GetChargingSchedule  GET  /api/vehicle/charging-schedule
///   SetChargingSchedule  POST /api/vehicle/charging-schedule
///   GetChargeCap         GET  /api/vehicle/charge-cap
///   SetChargeCap         POST /api/vehicle/charge-cap
///   GetGpsLocation       GET  /api/gps
///   StartGps             POST /api/gps/start
///   StopGps              POST /api/gps/stop
class VehicleServiceApi {
  final $pb.RpcClient _client;

  VehicleServiceApi(this._client);

  $async.Future<GetVehicleStateResponse> getState(
          $pb.ClientContext? ctx, GetVehicleStateRequest request) =>
      _client.invoke<GetVehicleStateResponse>(ctx, 'VehicleService', 'GetState',
          request, GetVehicleStateResponse());
  $async.Future<GetAcDiagnosticsResponse> getAcDiagnostics(
          $pb.ClientContext? ctx, GetAcDiagnosticsRequest request) =>
      _client.invoke<GetAcDiagnosticsResponse>(ctx, 'VehicleService',
          'GetAcDiagnostics', request, GetAcDiagnosticsResponse());
  $async.Future<GetSeatDiagnosticsResponse> getSeatDiagnostics(
          $pb.ClientContext? ctx, GetSeatDiagnosticsRequest request) =>
      _client.invoke<GetSeatDiagnosticsResponse>(ctx, 'VehicleService',
          'GetSeatDiagnostics', request, GetSeatDiagnosticsResponse());
  $async.Future<VehicleCommandResponse> lock(
          $pb.ClientContext? ctx, LockRequest request) =>
      _client.invoke<VehicleCommandResponse>(
          ctx, 'VehicleService', 'Lock', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> unlock(
          $pb.ClientContext? ctx, UnlockRequest request) =>
      _client.invoke<VehicleCommandResponse>(
          ctx, 'VehicleService', 'Unlock', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> trunk(
          $pb.ClientContext? ctx, TrunkRequest request) =>
      _client.invoke<VehicleCommandResponse>(
          ctx, 'VehicleService', 'Trunk', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> moveWindow(
          $pb.ClientContext? ctx, MoveWindowRequest request) =>
      _client.invoke<VehicleCommandResponse>(ctx, 'VehicleService',
          'MoveWindow', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> flash(
          $pb.ClientContext? ctx, FlashRequest request) =>
      _client.invoke<VehicleCommandResponse>(
          ctx, 'VehicleService', 'Flash', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> findCar(
          $pb.ClientContext? ctx, FindCarRequest request) =>
      _client.invoke<VehicleCommandResponse>(
          ctx, 'VehicleService', 'FindCar', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> setClimate(
          $pb.ClientContext? ctx, SetClimateRequest request) =>
      _client.invoke<VehicleCommandResponse>(ctx, 'VehicleService',
          'SetClimate', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> setSeat(
          $pb.ClientContext? ctx, SetSeatRequest request) =>
      _client.invoke<VehicleCommandResponse>(
          ctx, 'VehicleService', 'SetSeat', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> setLights(
          $pb.ClientContext? ctx, SetLightsRequest request) =>
      _client.invoke<VehicleCommandResponse>(ctx, 'VehicleService', 'SetLights',
          request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> setAdas(
          $pb.ClientContext? ctx, SetAdasRequest request) =>
      _client.invoke<VehicleCommandResponse>(
          ctx, 'VehicleService', 'SetAdas', request, VehicleCommandResponse());
  $async.Future<VehicleCommandResponse> setBatteryHeat(
          $pb.ClientContext? ctx, SetBatteryHeatRequest request) =>
      _client.invoke<VehicleCommandResponse>(ctx, 'VehicleService',
          'SetBatteryHeat', request, VehicleCommandResponse());
  $async.Future<GetChargingScheduleResponse> getChargingSchedule(
          $pb.ClientContext? ctx, GetChargingScheduleRequest request) =>
      _client.invoke<GetChargingScheduleResponse>(ctx, 'VehicleService',
          'GetChargingSchedule', request, GetChargingScheduleResponse());
  $async.Future<VehicleCommandResponse> setChargingSchedule(
          $pb.ClientContext? ctx, SetChargingScheduleRequest request) =>
      _client.invoke<VehicleCommandResponse>(ctx, 'VehicleService',
          'SetChargingSchedule', request, VehicleCommandResponse());
  $async.Future<GetChargeCapResponse> getChargeCap(
          $pb.ClientContext? ctx, GetChargeCapRequest request) =>
      _client.invoke<GetChargeCapResponse>(ctx, 'VehicleService',
          'GetChargeCap', request, GetChargeCapResponse());
  $async.Future<VehicleCommandResponse> setChargeCap(
          $pb.ClientContext? ctx, SetChargeCapRequest request) =>
      _client.invoke<VehicleCommandResponse>(ctx, 'VehicleService',
          'SetChargeCap', request, VehicleCommandResponse());
  $async.Future<GetGpsLocationResponse> getGpsLocation(
          $pb.ClientContext? ctx, GetGpsLocationRequest request) =>
      _client.invoke<GetGpsLocationResponse>(ctx, 'VehicleService',
          'GetGpsLocation', request, GetGpsLocationResponse());
  $async.Future<StartGpsResponse> startGps(
          $pb.ClientContext? ctx, StartGpsRequest request) =>
      _client.invoke<StartGpsResponse>(
          ctx, 'VehicleService', 'StartGps', request, StartGpsResponse());
  $async.Future<StopGpsResponse> stopGps(
          $pb.ClientContext? ctx, StopGpsRequest request) =>
      _client.invoke<StopGpsResponse>(
          ctx, 'VehicleService', 'StopGps', request, StopGpsResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
