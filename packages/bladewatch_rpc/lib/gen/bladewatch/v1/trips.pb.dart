// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/trips.proto.

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

/// TripSummary is a compact trip row for list views.
class TripSummary extends $pb.GeneratedMessage {
  factory TripSummary({
    $fixnum.Int64? id,
    $fixnum.Int64? startTime,
    $fixnum.Int64? endTime,
    $core.double? distanceKm,
    $core.int? durationSeconds,
    $core.double? avgSpeedKmh,
    $core.int? maxSpeedKmh,
    $core.double? socStart,
    $core.double? socEnd,
    $core.double? energyPerKm,
    $core.double? tripCost,
    $core.String? currency,
    $core.int? overallScore,
    $core.String? kinematicState,
    $core.String? gradientProfile,
    $core.double? startLat,
    $core.double? startLon,
    $core.double? endLat,
    $core.double? endLon,
    $core.int? extTempC,
    $core.double? litresUsed,
    $core.double? fuelCost,
    $core.double? electricCost,
    $core.bool? hasFuelData,
    $core.bool? manual,
    $core.double? evKm,
    $core.double? evKwh,
    $core.double? hevKm,
    $core.double? hevLitres,
    $core.bool? hasEnergySplit,
  }) {
    final result = TripSummary._();
    if (id != null) result.id = id;
    if (startTime != null) result.startTime = startTime;
    if (endTime != null) result.endTime = endTime;
    if (distanceKm != null) result.distanceKm = distanceKm;
    if (durationSeconds != null) result.durationSeconds = durationSeconds;
    if (avgSpeedKmh != null) result.avgSpeedKmh = avgSpeedKmh;
    if (maxSpeedKmh != null) result.maxSpeedKmh = maxSpeedKmh;
    if (socStart != null) result.socStart = socStart;
    if (socEnd != null) result.socEnd = socEnd;
    if (energyPerKm != null) result.energyPerKm = energyPerKm;
    if (tripCost != null) result.tripCost = tripCost;
    if (currency != null) result.currency = currency;
    if (overallScore != null) result.overallScore = overallScore;
    if (kinematicState != null) result.kinematicState = kinematicState;
    if (gradientProfile != null) result.gradientProfile = gradientProfile;
    if (startLat != null) result.startLat = startLat;
    if (startLon != null) result.startLon = startLon;
    if (endLat != null) result.endLat = endLat;
    if (endLon != null) result.endLon = endLon;
    if (extTempC != null) result.extTempC = extTempC;
    if (litresUsed != null) result.litresUsed = litresUsed;
    if (fuelCost != null) result.fuelCost = fuelCost;
    if (electricCost != null) result.electricCost = electricCost;
    if (hasFuelData != null) result.hasFuelData = hasFuelData;
    if (manual != null) result.manual = manual;
    if (evKm != null) result.evKm = evKm;
    if (evKwh != null) result.evKwh = evKwh;
    if (hevKm != null) result.hevKm = hevKm;
    if (hevLitres != null) result.hevLitres = hevLitres;
    if (hasEnergySplit != null) result.hasEnergySplit = hasEnergySplit;
    return result;
  }

  TripSummary._();

  factory TripSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripSummary()..mergeFromBuffer(data, registry);
  factory TripSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripSummary()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TripSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TripSummary.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'startTime')
    ..aInt64(3, _omitFieldNames ? '' : 'endTime')
    ..aD(4, _omitFieldNames ? '' : 'distanceKm')
    ..aI(5, _omitFieldNames ? '' : 'durationSeconds')
    ..aD(6, _omitFieldNames ? '' : 'avgSpeedKmh')
    ..aI(7, _omitFieldNames ? '' : 'maxSpeedKmh')
    ..aD(8, _omitFieldNames ? '' : 'socStart')
    ..aD(9, _omitFieldNames ? '' : 'socEnd')
    ..aD(10, _omitFieldNames ? '' : 'energyPerKm')
    ..aD(11, _omitFieldNames ? '' : 'tripCost')
    ..aOS(12, _omitFieldNames ? '' : 'currency')
    ..aI(13, _omitFieldNames ? '' : 'overallScore')
    ..aOS(14, _omitFieldNames ? '' : 'kinematicState')
    ..aOS(15, _omitFieldNames ? '' : 'gradientProfile')
    ..aD(16, _omitFieldNames ? '' : 'startLat')
    ..aD(17, _omitFieldNames ? '' : 'startLon')
    ..aD(18, _omitFieldNames ? '' : 'endLat')
    ..aD(19, _omitFieldNames ? '' : 'endLon')
    ..aI(20, _omitFieldNames ? '' : 'extTempC')
    ..aD(21, _omitFieldNames ? '' : 'litresUsed')
    ..aD(22, _omitFieldNames ? '' : 'fuelCost')
    ..aD(23, _omitFieldNames ? '' : 'electricCost')
    ..aOB(24, _omitFieldNames ? '' : 'hasFuelData')
    ..aOB(25, _omitFieldNames ? '' : 'manual')
    ..aD(26, _omitFieldNames ? '' : 'evKm')
    ..aD(27, _omitFieldNames ? '' : 'evKwh')
    ..aD(28, _omitFieldNames ? '' : 'hevKm')
    ..aD(29, _omitFieldNames ? '' : 'hevLitres')
    ..aOB(30, _omitFieldNames ? '' : 'hasEnergySplit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripSummary copyWith(void Function(TripSummary) updates) =>
      super.copyWith((message) => updates(message as TripSummary))
          as TripSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TripSummary() / TripSummary.new instead')
  static TripSummary create() => TripSummary._();
  static $pb.GeneratedMessage $_createMessage() => TripSummary._();
  @$core.override
  TripSummary createEmptyInstance() => TripSummary._();
  @$core.pragma('dart2js:noInline')
  static TripSummary getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TripSummary>(
          TripSummary.$_createMessage);
  static TripSummary? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get startTime => $_getI64(1);
  @$pb.TagNumber(2)
  set startTime($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartTime() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get endTime => $_getI64(2);
  @$pb.TagNumber(3)
  set endTime($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEndTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndTime() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get distanceKm => $_getN(3);
  @$pb.TagNumber(4)
  set distanceKm($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDistanceKm() => $_has(3);
  @$pb.TagNumber(4)
  void clearDistanceKm() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get durationSeconds => $_getIZ(4);
  @$pb.TagNumber(5)
  set durationSeconds($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDurationSeconds() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationSeconds() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get avgSpeedKmh => $_getN(5);
  @$pb.TagNumber(6)
  set avgSpeedKmh($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAvgSpeedKmh() => $_has(5);
  @$pb.TagNumber(6)
  void clearAvgSpeedKmh() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get maxSpeedKmh => $_getIZ(6);
  @$pb.TagNumber(7)
  set maxSpeedKmh($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMaxSpeedKmh() => $_has(6);
  @$pb.TagNumber(7)
  void clearMaxSpeedKmh() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get socStart => $_getN(7);
  @$pb.TagNumber(8)
  set socStart($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSocStart() => $_has(7);
  @$pb.TagNumber(8)
  void clearSocStart() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get socEnd => $_getN(8);
  @$pb.TagNumber(9)
  set socEnd($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSocEnd() => $_has(8);
  @$pb.TagNumber(9)
  void clearSocEnd() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.double get energyPerKm => $_getN(9);
  @$pb.TagNumber(10)
  set energyPerKm($core.double value) => $_setDouble(9, value);
  @$pb.TagNumber(10)
  $core.bool hasEnergyPerKm() => $_has(9);
  @$pb.TagNumber(10)
  void clearEnergyPerKm() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get tripCost => $_getN(10);
  @$pb.TagNumber(11)
  set tripCost($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasTripCost() => $_has(10);
  @$pb.TagNumber(11)
  void clearTripCost() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get currency => $_getSZ(11);
  @$pb.TagNumber(12)
  set currency($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCurrency() => $_has(11);
  @$pb.TagNumber(12)
  void clearCurrency() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.int get overallScore => $_getIZ(12);
  @$pb.TagNumber(13)
  set overallScore($core.int value) => $_setSignedInt32(12, value);
  @$pb.TagNumber(13)
  $core.bool hasOverallScore() => $_has(12);
  @$pb.TagNumber(13)
  void clearOverallScore() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get kinematicState => $_getSZ(13);
  @$pb.TagNumber(14)
  set kinematicState($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasKinematicState() => $_has(13);
  @$pb.TagNumber(14)
  void clearKinematicState() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get gradientProfile => $_getSZ(14);
  @$pb.TagNumber(15)
  set gradientProfile($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasGradientProfile() => $_has(14);
  @$pb.TagNumber(15)
  void clearGradientProfile() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.double get startLat => $_getN(15);
  @$pb.TagNumber(16)
  set startLat($core.double value) => $_setDouble(15, value);
  @$pb.TagNumber(16)
  $core.bool hasStartLat() => $_has(15);
  @$pb.TagNumber(16)
  void clearStartLat() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.double get startLon => $_getN(16);
  @$pb.TagNumber(17)
  set startLon($core.double value) => $_setDouble(16, value);
  @$pb.TagNumber(17)
  $core.bool hasStartLon() => $_has(16);
  @$pb.TagNumber(17)
  void clearStartLon() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.double get endLat => $_getN(17);
  @$pb.TagNumber(18)
  set endLat($core.double value) => $_setDouble(17, value);
  @$pb.TagNumber(18)
  $core.bool hasEndLat() => $_has(17);
  @$pb.TagNumber(18)
  void clearEndLat() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.double get endLon => $_getN(18);
  @$pb.TagNumber(19)
  set endLon($core.double value) => $_setDouble(18, value);
  @$pb.TagNumber(19)
  $core.bool hasEndLon() => $_has(18);
  @$pb.TagNumber(19)
  void clearEndLon() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.int get extTempC => $_getIZ(19);
  @$pb.TagNumber(20)
  set extTempC($core.int value) => $_setSignedInt32(19, value);
  @$pb.TagNumber(20)
  $core.bool hasExtTempC() => $_has(19);
  @$pb.TagNumber(20)
  void clearExtTempC() => $_clearField(20);

  /// PHEV fuel leg (BladeWatch-fpdz). New field numbers only -- 1-20 keep their meaning, so
  /// an older client parses this message unchanged.
  ///
  /// Derived values only: a list row shows what the fuel leg COST, never the lifetime
  /// counters it was derived from. Handing a client raw counters invites it to compute its
  /// own delta, which then disagrees with the daemon the moment a counter resets.
  ///
  /// On a BEV these are all 0, which is also proto3's default -- there is no "absent" here,
  /// and has_fuel_data below is what distinguishes a BEV from a PHEV that burned nothing.
  @$pb.TagNumber(21)
  $core.double get litresUsed => $_getN(20);
  @$pb.TagNumber(21)
  set litresUsed($core.double value) => $_setDouble(20, value);
  @$pb.TagNumber(21)
  $core.bool hasLitresUsed() => $_has(20);
  @$pb.TagNumber(21)
  void clearLitresUsed() => $_clearField(21);

  @$pb.TagNumber(22)
  $core.double get fuelCost => $_getN(21);
  @$pb.TagNumber(22)
  set fuelCost($core.double value) => $_setDouble(21, value);
  @$pb.TagNumber(22)
  $core.bool hasFuelCost() => $_has(21);
  @$pb.TagNumber(22)
  void clearFuelCost() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.double get electricCost => $_getN(22);
  @$pb.TagNumber(23)
  set electricCost($core.double value) => $_setDouble(22, value);
  @$pb.TagNumber(23)
  $core.bool hasElectricCost() => $_has(22);
  @$pb.TagNumber(23)
  void clearElectricCost() => $_clearField(23);

  /// True when this trip recorded both ends of the fuel counter. Derived from the STORED
  /// trip, not a live drivetrain probe, so a historical trip renders the same way on a car
  /// whose drivetrain reads differently today.
  @$pb.TagNumber(24)
  $core.bool get hasFuelData => $_getBF(23);
  @$pb.TagNumber(24)
  set hasFuelData($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(24)
  $core.bool hasHasFuelData() => $_has(23);
  @$pb.TagNumber(24)
  void clearHasFuelData() => $_clearField(24);

  /// True when the driver started this trip with the Start Trip button (BladeWatch-gklt).
  @$pb.TagNumber(25)
  $core.bool get manual => $_getBF(24);
  @$pb.TagNumber(25)
  set manual($core.bool value) => $_setBool(24, value);
  @$pb.TagNumber(25)
  $core.bool hasManual() => $_has(24);
  @$pb.TagNumber(25)
  void clearManual() => $_clearField(25);

  /// EV/HEV split (BladeWatch-reml). A BYD plug-in hybrid drives in EV or HEV energy mode and a trip
  /// can switch; each stretch is measured on its own. EV driving carries kWh and no litres; HEV
  /// driving carries litres and NO kWh (not even as information). All 0 on a trip recorded before
  /// the split existed, which has_energy_split tells apart from a trip that really drove 0 km in a
  /// mode. With HEV driving present, energy_per_km is kWh over the EV kilometres only.
  @$pb.TagNumber(26)
  $core.double get evKm => $_getN(25);
  @$pb.TagNumber(26)
  set evKm($core.double value) => $_setDouble(25, value);
  @$pb.TagNumber(26)
  $core.bool hasEvKm() => $_has(25);
  @$pb.TagNumber(26)
  void clearEvKm() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.double get evKwh => $_getN(26);
  @$pb.TagNumber(27)
  set evKwh($core.double value) => $_setDouble(26, value);
  @$pb.TagNumber(27)
  $core.bool hasEvKwh() => $_has(26);
  @$pb.TagNumber(27)
  void clearEvKwh() => $_clearField(27);

  @$pb.TagNumber(28)
  $core.double get hevKm => $_getN(27);
  @$pb.TagNumber(28)
  set hevKm($core.double value) => $_setDouble(27, value);
  @$pb.TagNumber(28)
  $core.bool hasHevKm() => $_has(27);
  @$pb.TagNumber(28)
  void clearHevKm() => $_clearField(28);

  @$pb.TagNumber(29)
  $core.double get hevLitres => $_getN(28);
  @$pb.TagNumber(29)
  set hevLitres($core.double value) => $_setDouble(28, value);
  @$pb.TagNumber(29)
  $core.bool hasHevLitres() => $_has(28);
  @$pb.TagNumber(29)
  void clearHevLitres() => $_clearField(29);

  @$pb.TagNumber(30)
  $core.bool get hasEnergySplit => $_getBF(29);
  @$pb.TagNumber(30)
  set hasEnergySplit($core.bool value) => $_setBool(29, value);
  @$pb.TagNumber(30)
  $core.bool hasHasEnergySplit() => $_has(29);
  @$pb.TagNumber(30)
  void clearHasEnergySplit() => $_clearField(30);
}

/// TripDetail extends TripSummary with Driving DNA scores and micro-moments.
class TripDetail extends $pb.GeneratedMessage {
  factory TripDetail({
    TripSummary? summary,
    $core.int? anticipationScore,
    $core.int? smoothnessScore,
    $core.int? speedDisciplineScore,
    $core.int? efficiencyScore,
    $core.int? consistencyScore,
    $core.double? elevationGainM,
    $core.double? elevationLossM,
    $core.double? avgGradientPercent,
    $core.String? microMomentsJson,
    $core.double? fuelPctStart,
    $core.double? fuelPctEnd,
    $core.double? fuelConStart,
    $core.double? fuelConEnd,
    $core.double? fuelPricePerL,
    $core.double? elecConStart,
    $core.double? elecConEnd,
  }) {
    final result = TripDetail._();
    if (summary != null) result.summary = summary;
    if (anticipationScore != null) result.anticipationScore = anticipationScore;
    if (smoothnessScore != null) result.smoothnessScore = smoothnessScore;
    if (speedDisciplineScore != null)
      result.speedDisciplineScore = speedDisciplineScore;
    if (efficiencyScore != null) result.efficiencyScore = efficiencyScore;
    if (consistencyScore != null) result.consistencyScore = consistencyScore;
    if (elevationGainM != null) result.elevationGainM = elevationGainM;
    if (elevationLossM != null) result.elevationLossM = elevationLossM;
    if (avgGradientPercent != null)
      result.avgGradientPercent = avgGradientPercent;
    if (microMomentsJson != null) result.microMomentsJson = microMomentsJson;
    if (fuelPctStart != null) result.fuelPctStart = fuelPctStart;
    if (fuelPctEnd != null) result.fuelPctEnd = fuelPctEnd;
    if (fuelConStart != null) result.fuelConStart = fuelConStart;
    if (fuelConEnd != null) result.fuelConEnd = fuelConEnd;
    if (fuelPricePerL != null) result.fuelPricePerL = fuelPricePerL;
    if (elecConStart != null) result.elecConStart = elecConStart;
    if (elecConEnd != null) result.elecConEnd = elecConEnd;
    return result;
  }

  TripDetail._();

  factory TripDetail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripDetail()..mergeFromBuffer(data, registry);
  factory TripDetail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripDetail()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TripDetail',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TripDetail.$_createMessage)
    ..aOM<TripSummary>(1, _omitFieldNames ? '' : 'summary',
        subBuilder: TripSummary.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'anticipationScore')
    ..aI(3, _omitFieldNames ? '' : 'smoothnessScore')
    ..aI(4, _omitFieldNames ? '' : 'speedDisciplineScore')
    ..aI(5, _omitFieldNames ? '' : 'efficiencyScore')
    ..aI(6, _omitFieldNames ? '' : 'consistencyScore')
    ..aD(7, _omitFieldNames ? '' : 'elevationGainM')
    ..aD(8, _omitFieldNames ? '' : 'elevationLossM')
    ..aD(9, _omitFieldNames ? '' : 'avgGradientPercent')
    ..aOS(10, _omitFieldNames ? '' : 'microMomentsJson')
    ..aD(11, _omitFieldNames ? '' : 'fuelPctStart')
    ..aD(12, _omitFieldNames ? '' : 'fuelPctEnd')
    ..aD(13, _omitFieldNames ? '' : 'fuelConStart')
    ..aD(14, _omitFieldNames ? '' : 'fuelConEnd')
    ..aD(15, _omitFieldNames ? '' : 'fuelPricePerL')
    ..aD(16, _omitFieldNames ? '' : 'elecConStart')
    ..aD(17, _omitFieldNames ? '' : 'elecConEnd')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripDetail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripDetail copyWith(void Function(TripDetail) updates) =>
      super.copyWith((message) => updates(message as TripDetail)) as TripDetail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TripDetail() / TripDetail.new instead')
  static TripDetail create() => TripDetail._();
  static $pb.GeneratedMessage $_createMessage() => TripDetail._();
  @$core.override
  TripDetail createEmptyInstance() => TripDetail._();
  @$core.pragma('dart2js:noInline')
  static TripDetail getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TripDetail>(TripDetail.$_createMessage);
  static TripDetail? _defaultInstance;

  @$pb.TagNumber(1)
  TripSummary get summary => $_getN(0);
  @$pb.TagNumber(1)
  set summary(TripSummary value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSummary() => $_has(0);
  @$pb.TagNumber(1)
  void clearSummary() => $_clearField(1);
  @$pb.TagNumber(1)
  TripSummary ensureSummary() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get anticipationScore => $_getIZ(1);
  @$pb.TagNumber(2)
  set anticipationScore($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAnticipationScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearAnticipationScore() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get smoothnessScore => $_getIZ(2);
  @$pb.TagNumber(3)
  set smoothnessScore($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSmoothnessScore() => $_has(2);
  @$pb.TagNumber(3)
  void clearSmoothnessScore() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get speedDisciplineScore => $_getIZ(3);
  @$pb.TagNumber(4)
  set speedDisciplineScore($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSpeedDisciplineScore() => $_has(3);
  @$pb.TagNumber(4)
  void clearSpeedDisciplineScore() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get efficiencyScore => $_getIZ(4);
  @$pb.TagNumber(5)
  set efficiencyScore($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEfficiencyScore() => $_has(4);
  @$pb.TagNumber(5)
  void clearEfficiencyScore() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get consistencyScore => $_getIZ(5);
  @$pb.TagNumber(6)
  set consistencyScore($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasConsistencyScore() => $_has(5);
  @$pb.TagNumber(6)
  void clearConsistencyScore() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get elevationGainM => $_getN(6);
  @$pb.TagNumber(7)
  set elevationGainM($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasElevationGainM() => $_has(6);
  @$pb.TagNumber(7)
  void clearElevationGainM() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get elevationLossM => $_getN(7);
  @$pb.TagNumber(8)
  set elevationLossM($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasElevationLossM() => $_has(7);
  @$pb.TagNumber(8)
  void clearElevationLossM() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get avgGradientPercent => $_getN(8);
  @$pb.TagNumber(9)
  set avgGradientPercent($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAvgGradientPercent() => $_has(8);
  @$pb.TagNumber(9)
  void clearAvgGradientPercent() => $_clearField(9);

  /// Raw micro-moments JSON blob.
  @$pb.TagNumber(10)
  $core.String get microMomentsJson => $_getSZ(9);
  @$pb.TagNumber(10)
  set microMomentsJson($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasMicroMomentsJson() => $_has(9);
  @$pb.TagNumber(10)
  void clearMicroMomentsJson() => $_clearField(10);

  /// PHEV fuel leg detail (BladeWatch-fpdz). The raw lifetime counters live here, in the
  /// detail view only. -1 means the reading was never taken; 0 is a real measurement.
  @$pb.TagNumber(11)
  $core.double get fuelPctStart => $_getN(10);
  @$pb.TagNumber(11)
  set fuelPctStart($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasFuelPctStart() => $_has(10);
  @$pb.TagNumber(11)
  void clearFuelPctStart() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get fuelPctEnd => $_getN(11);
  @$pb.TagNumber(12)
  set fuelPctEnd($core.double value) => $_setDouble(11, value);
  @$pb.TagNumber(12)
  $core.bool hasFuelPctEnd() => $_has(11);
  @$pb.TagNumber(12)
  void clearFuelPctEnd() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.double get fuelConStart => $_getN(12);
  @$pb.TagNumber(13)
  set fuelConStart($core.double value) => $_setDouble(12, value);
  @$pb.TagNumber(13)
  $core.bool hasFuelConStart() => $_has(12);
  @$pb.TagNumber(13)
  void clearFuelConStart() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.double get fuelConEnd => $_getN(13);
  @$pb.TagNumber(14)
  set fuelConEnd($core.double value) => $_setDouble(13, value);
  @$pb.TagNumber(14)
  $core.bool hasFuelConEnd() => $_has(13);
  @$pb.TagNumber(14)
  void clearFuelConEnd() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.double get fuelPricePerL => $_getN(14);
  @$pb.TagNumber(15)
  set fuelPricePerL($core.double value) => $_setDouble(14, value);
  @$pb.TagNumber(15)
  $core.bool hasFuelPricePerL() => $_has(14);
  @$pb.TagNumber(15)
  void clearFuelPricePerL() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.double get elecConStart => $_getN(15);
  @$pb.TagNumber(16)
  set elecConStart($core.double value) => $_setDouble(15, value);
  @$pb.TagNumber(16)
  $core.bool hasElecConStart() => $_has(15);
  @$pb.TagNumber(16)
  void clearElecConStart() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.double get elecConEnd => $_getN(16);
  @$pb.TagNumber(17)
  set elecConEnd($core.double value) => $_setDouble(16, value);
  @$pb.TagNumber(17)
  $core.bool hasElecConEnd() => $_has(16);
  @$pb.TagNumber(17)
  void clearElecConEnd() => $_clearField(17);
}

/// DnaScores holds the five Driving DNA axes.
class DnaScores extends $pb.GeneratedMessage {
  factory DnaScores({
    $core.int? anticipation,
    $core.int? smoothness,
    $core.int? speedDiscipline,
    $core.int? efficiency,
    $core.int? consistency,
    $core.int? overall,
  }) {
    final result = DnaScores._();
    if (anticipation != null) result.anticipation = anticipation;
    if (smoothness != null) result.smoothness = smoothness;
    if (speedDiscipline != null) result.speedDiscipline = speedDiscipline;
    if (efficiency != null) result.efficiency = efficiency;
    if (consistency != null) result.consistency = consistency;
    if (overall != null) result.overall = overall;
    return result;
  }

  DnaScores._();

  factory DnaScores.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DnaScores()..mergeFromBuffer(data, registry);
  factory DnaScores.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DnaScores()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DnaScores',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DnaScores.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'anticipation')
    ..aI(2, _omitFieldNames ? '' : 'smoothness')
    ..aI(3, _omitFieldNames ? '' : 'speedDiscipline')
    ..aI(4, _omitFieldNames ? '' : 'efficiency')
    ..aI(5, _omitFieldNames ? '' : 'consistency')
    ..aI(6, _omitFieldNames ? '' : 'overall')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DnaScores clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DnaScores copyWith(void Function(DnaScores) updates) =>
      super.copyWith((message) => updates(message as DnaScores)) as DnaScores;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DnaScores() / DnaScores.new instead')
  static DnaScores create() => DnaScores._();
  static $pb.GeneratedMessage $_createMessage() => DnaScores._();
  @$core.override
  DnaScores createEmptyInstance() => DnaScores._();
  @$core.pragma('dart2js:noInline')
  static DnaScores getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DnaScores>(DnaScores.$_createMessage);
  static DnaScores? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get anticipation => $_getIZ(0);
  @$pb.TagNumber(1)
  set anticipation($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAnticipation() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnticipation() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get smoothness => $_getIZ(1);
  @$pb.TagNumber(2)
  set smoothness($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSmoothness() => $_has(1);
  @$pb.TagNumber(2)
  void clearSmoothness() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get speedDiscipline => $_getIZ(2);
  @$pb.TagNumber(3)
  set speedDiscipline($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSpeedDiscipline() => $_has(2);
  @$pb.TagNumber(3)
  void clearSpeedDiscipline() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get efficiency => $_getIZ(3);
  @$pb.TagNumber(4)
  set efficiency($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEfficiency() => $_has(3);
  @$pb.TagNumber(4)
  void clearEfficiency() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get consistency => $_getIZ(4);
  @$pb.TagNumber(5)
  set consistency($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasConsistency() => $_has(4);
  @$pb.TagNumber(5)
  void clearConsistency() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get overall => $_getIZ(5);
  @$pb.TagNumber(6)
  set overall($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOverall() => $_has(5);
  @$pb.TagNumber(6)
  void clearOverall() => $_clearField(6);
}

/// WeeklyRollupEntry is one week-level trip summary row.
class WeeklyRollupEntry extends $pb.GeneratedMessage {
  factory WeeklyRollupEntry({
    $core.String? rollupJson,
  }) {
    final result = WeeklyRollupEntry._();
    if (rollupJson != null) result.rollupJson = rollupJson;
    return result;
  }

  WeeklyRollupEntry._();

  factory WeeklyRollupEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WeeklyRollupEntry()..mergeFromBuffer(data, registry);
  factory WeeklyRollupEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WeeklyRollupEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WeeklyRollupEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: WeeklyRollupEntry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'rollupJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WeeklyRollupEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WeeklyRollupEntry copyWith(void Function(WeeklyRollupEntry) updates) =>
      super.copyWith((message) => updates(message as WeeklyRollupEntry))
          as WeeklyRollupEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WeeklyRollupEntry() / WeeklyRollupEntry.new instead')
  static WeeklyRollupEntry create() => WeeklyRollupEntry._();
  static $pb.GeneratedMessage $_createMessage() => WeeklyRollupEntry._();
  @$core.override
  WeeklyRollupEntry createEmptyInstance() => WeeklyRollupEntry._();
  @$core.pragma('dart2js:noInline')
  static WeeklyRollupEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WeeklyRollupEntry>(
          WeeklyRollupEntry.$_createMessage);
  static WeeklyRollupEntry? _defaultInstance;

  /// Raw JSON blob from WeeklyRollup.toJson().
  @$pb.TagNumber(1)
  $core.String get rollupJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set rollupJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRollupJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearRollupJson() => $_clearField(1);
}

/// TelemetrySample is one recorded data point during a trip.
class TelemetrySample extends $pb.GeneratedMessage {
  factory TelemetrySample({
    $core.String? sampleJson,
  }) {
    final result = TelemetrySample._();
    if (sampleJson != null) result.sampleJson = sampleJson;
    return result;
  }

  TelemetrySample._();

  factory TelemetrySample.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TelemetrySample()..mergeFromBuffer(data, registry);
  factory TelemetrySample.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TelemetrySample()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TelemetrySample',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TelemetrySample.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'sampleJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetrySample clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetrySample copyWith(void Function(TelemetrySample) updates) =>
      super.copyWith((message) => updates(message as TelemetrySample))
          as TelemetrySample;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TelemetrySample() / TelemetrySample.new instead')
  static TelemetrySample create() => TelemetrySample._();
  static $pb.GeneratedMessage $_createMessage() => TelemetrySample._();
  @$core.override
  TelemetrySample createEmptyInstance() => TelemetrySample._();
  @$core.pragma('dart2js:noInline')
  static TelemetrySample getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TelemetrySample>(
          TelemetrySample.$_createMessage);
  static TelemetrySample? _defaultInstance;

  /// Raw JSON blob from TelemetrySample.toJson().
  @$pb.TagNumber(1)
  $core.String get sampleJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set sampleJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSampleJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearSampleJson() => $_clearField(1);
}

/// TripConfig controls trip recording behaviour.
class TripConfig extends $pb.GeneratedMessage {
  factory TripConfig({
    $core.bool? enabled,
    $core.double? electricityRate,
    $core.String? currency,
    $core.String? distanceUnit,
    $core.double? fuelPricePerL,
    $core.double? fuelTankCapacityL,
    $core.bool? isPhev,
  }) {
    final result = TripConfig._();
    if (enabled != null) result.enabled = enabled;
    if (electricityRate != null) result.electricityRate = electricityRate;
    if (currency != null) result.currency = currency;
    if (distanceUnit != null) result.distanceUnit = distanceUnit;
    if (fuelPricePerL != null) result.fuelPricePerL = fuelPricePerL;
    if (fuelTankCapacityL != null) result.fuelTankCapacityL = fuelTankCapacityL;
    if (isPhev != null) result.isPhev = isPhev;
    return result;
  }

  TripConfig._();

  factory TripConfig.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripConfig()..mergeFromBuffer(data, registry);
  factory TripConfig.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripConfig()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TripConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TripConfig.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aD(2, _omitFieldNames ? '' : 'electricityRate')
    ..aOS(3, _omitFieldNames ? '' : 'currency')
    ..aOS(4, _omitFieldNames ? '' : 'distanceUnit')
    ..aD(5, _omitFieldNames ? '' : 'fuelPricePerL')
    ..aD(6, _omitFieldNames ? '' : 'fuelTankCapacityL')
    ..aOB(7, _omitFieldNames ? '' : 'isPhev')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripConfig clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripConfig copyWith(void Function(TripConfig) updates) =>
      super.copyWith((message) => updates(message as TripConfig)) as TripConfig;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TripConfig() / TripConfig.new instead')
  static TripConfig create() => TripConfig._();
  static $pb.GeneratedMessage $_createMessage() => TripConfig._();
  @$core.override
  TripConfig createEmptyInstance() => TripConfig._();
  @$core.pragma('dart2js:noInline')
  static TripConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TripConfig>(TripConfig.$_createMessage);
  static TripConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get electricityRate => $_getN(1);
  @$pb.TagNumber(2)
  set electricityRate($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasElectricityRate() => $_has(1);
  @$pb.TagNumber(2)
  void clearElectricityRate() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get currency => $_getSZ(2);
  @$pb.TagNumber(3)
  set currency($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCurrency() => $_has(2);
  @$pb.TagNumber(3)
  void clearCurrency() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get distanceUnit => $_getSZ(3);
  @$pb.TagNumber(4)
  set distanceUnit($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDistanceUnit() => $_has(3);
  @$pb.TagNumber(4)
  void clearDistanceUnit() => $_clearField(4);

  /// Cost per litre for the PHEV fuel leg. 0 means not configured, so the leg is recorded
  /// but not costed. The currency above is shared with the electricity rate.
  @$pb.TagNumber(5)
  $core.double get fuelPricePerL => $_getN(4);
  @$pb.TagNumber(5)
  set fuelPricePerL($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFuelPricePerL() => $_has(4);
  @$pb.TagNumber(5)
  void clearFuelPricePerL() => $_clearField(5);

  /// Fuel tank capacity in litres. 0 means not configured, and there is no default: BYD
  /// local data exposes no tank size, so without this the fuel RANGE simply cannot be
  /// computed. A guessed capacity would put a wrong range on the dashboard, which is worse
  /// than a blank one because the driver acts on it.
  @$pb.TagNumber(6)
  $core.double get fuelTankCapacityL => $_getN(5);
  @$pb.TagNumber(6)
  set fuelTankCapacityL($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFuelTankCapacityL() => $_has(5);
  @$pb.TagNumber(6)
  void clearFuelTankCapacityL() => $_clearField(6);

  /// Whether this vehicle has a fuel system at all.
  ///
  /// NOT a stored setting — a live read of the drivetrain, carried on the config message
  /// because the config screen is the one place that needs it. The two fuel settings above are
  /// meaningless on a BEV, and a UI that shows "Fuel Price (per litre)" to an owner whose car
  /// has no tank reads as a bug in the app.
  ///
  /// Clients must NOT treat false as "hide unconditionally": a value already configured has to
  /// stay visible so it can be cleared, and the drivetrain probe can read false while the HAL
  /// is warming up. See the gating rule in the web and Flutter trips settings.
  @$pb.TagNumber(7)
  $core.bool get isPhev => $_getBF(6);
  @$pb.TagNumber(7)
  set isPhev($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsPhev() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsPhev() => $_clearField(7);
}

/// TripStorageInfo reports trips storage usage and limits.
class TripStorageInfo extends $pb.GeneratedMessage {
  factory TripStorageInfo({
    $core.String? storageType,
    $fixnum.Int64? limitMb,
    $core.double? usedMb,
    $core.String? usedUnit,
    $core.bool? sdCardAvailable,
    $core.int? tripsCount,
    $core.String? storagePath,
  }) {
    final result = TripStorageInfo._();
    if (storageType != null) result.storageType = storageType;
    if (limitMb != null) result.limitMb = limitMb;
    if (usedMb != null) result.usedMb = usedMb;
    if (usedUnit != null) result.usedUnit = usedUnit;
    if (sdCardAvailable != null) result.sdCardAvailable = sdCardAvailable;
    if (tripsCount != null) result.tripsCount = tripsCount;
    if (storagePath != null) result.storagePath = storagePath;
    return result;
  }

  TripStorageInfo._();

  factory TripStorageInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripStorageInfo()..mergeFromBuffer(data, registry);
  factory TripStorageInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TripStorageInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TripStorageInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TripStorageInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'storageType')
    ..aInt64(2, _omitFieldNames ? '' : 'limitMb')
    ..aD(3, _omitFieldNames ? '' : 'usedMb')
    ..aOS(4, _omitFieldNames ? '' : 'usedUnit')
    ..aOB(5, _omitFieldNames ? '' : 'sdCardAvailable')
    ..aI(6, _omitFieldNames ? '' : 'tripsCount')
    ..aOS(7, _omitFieldNames ? '' : 'storagePath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripStorageInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TripStorageInfo copyWith(void Function(TripStorageInfo) updates) =>
      super.copyWith((message) => updates(message as TripStorageInfo))
          as TripStorageInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TripStorageInfo() / TripStorageInfo.new instead')
  static TripStorageInfo create() => TripStorageInfo._();
  static $pb.GeneratedMessage $_createMessage() => TripStorageInfo._();
  @$core.override
  TripStorageInfo createEmptyInstance() => TripStorageInfo._();
  @$core.pragma('dart2js:noInline')
  static TripStorageInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TripStorageInfo>(
          TripStorageInfo.$_createMessage);
  static TripStorageInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get storageType => $_getSZ(0);
  @$pb.TagNumber(1)
  set storageType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStorageType() => $_has(0);
  @$pb.TagNumber(1)
  void clearStorageType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get limitMb => $_getI64(1);
  @$pb.TagNumber(2)
  set limitMb($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimitMb() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimitMb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get usedMb => $_getN(2);
  @$pb.TagNumber(3)
  set usedMb($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUsedMb() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsedMb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get usedUnit => $_getSZ(3);
  @$pb.TagNumber(4)
  set usedUnit($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUsedUnit() => $_has(3);
  @$pb.TagNumber(4)
  void clearUsedUnit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get sdCardAvailable => $_getBF(4);
  @$pb.TagNumber(5)
  set sdCardAvailable($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSdCardAvailable() => $_has(4);
  @$pb.TagNumber(5)
  void clearSdCardAvailable() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get tripsCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set tripsCount($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTripsCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearTripsCount() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get storagePath => $_getSZ(6);
  @$pb.TagNumber(7)
  set storagePath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasStoragePath() => $_has(6);
  @$pb.TagNumber(7)
  void clearStoragePath() => $_clearField(7);
}

/// SimilarTripsStats carries aggregate statistics over similar-route trips.
class SimilarTripsStats extends $pb.GeneratedMessage {
  factory SimilarTripsStats({
    $core.double? avgEfficiency,
    $core.double? avgScore,
    $core.double? avgDurationSeconds,
    $core.double? avgSpeedKmh,
    $core.double? avgCost,
    $fixnum.Int64? bestTripId,
    $core.double? bestEfficiency,
    $fixnum.Int64? worstTripId,
    $core.double? worstEfficiency,
  }) {
    final result = SimilarTripsStats._();
    if (avgEfficiency != null) result.avgEfficiency = avgEfficiency;
    if (avgScore != null) result.avgScore = avgScore;
    if (avgDurationSeconds != null)
      result.avgDurationSeconds = avgDurationSeconds;
    if (avgSpeedKmh != null) result.avgSpeedKmh = avgSpeedKmh;
    if (avgCost != null) result.avgCost = avgCost;
    if (bestTripId != null) result.bestTripId = bestTripId;
    if (bestEfficiency != null) result.bestEfficiency = bestEfficiency;
    if (worstTripId != null) result.worstTripId = worstTripId;
    if (worstEfficiency != null) result.worstEfficiency = worstEfficiency;
    return result;
  }

  SimilarTripsStats._();

  factory SimilarTripsStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SimilarTripsStats()..mergeFromBuffer(data, registry);
  factory SimilarTripsStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SimilarTripsStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SimilarTripsStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SimilarTripsStats.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'avgEfficiency')
    ..aD(2, _omitFieldNames ? '' : 'avgScore')
    ..aD(3, _omitFieldNames ? '' : 'avgDurationSeconds')
    ..aD(4, _omitFieldNames ? '' : 'avgSpeedKmh')
    ..aD(5, _omitFieldNames ? '' : 'avgCost')
    ..aInt64(6, _omitFieldNames ? '' : 'bestTripId')
    ..aD(7, _omitFieldNames ? '' : 'bestEfficiency')
    ..aInt64(8, _omitFieldNames ? '' : 'worstTripId')
    ..aD(9, _omitFieldNames ? '' : 'worstEfficiency')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimilarTripsStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SimilarTripsStats copyWith(void Function(SimilarTripsStats) updates) =>
      super.copyWith((message) => updates(message as SimilarTripsStats))
          as SimilarTripsStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SimilarTripsStats() / SimilarTripsStats.new instead')
  static SimilarTripsStats create() => SimilarTripsStats._();
  static $pb.GeneratedMessage $_createMessage() => SimilarTripsStats._();
  @$core.override
  SimilarTripsStats createEmptyInstance() => SimilarTripsStats._();
  @$core.pragma('dart2js:noInline')
  static SimilarTripsStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SimilarTripsStats>(
          SimilarTripsStats.$_createMessage);
  static SimilarTripsStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get avgEfficiency => $_getN(0);
  @$pb.TagNumber(1)
  set avgEfficiency($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAvgEfficiency() => $_has(0);
  @$pb.TagNumber(1)
  void clearAvgEfficiency() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get avgScore => $_getN(1);
  @$pb.TagNumber(2)
  set avgScore($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvgScore() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvgScore() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get avgDurationSeconds => $_getN(2);
  @$pb.TagNumber(3)
  set avgDurationSeconds($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvgDurationSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvgDurationSeconds() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get avgSpeedKmh => $_getN(3);
  @$pb.TagNumber(4)
  set avgSpeedKmh($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAvgSpeedKmh() => $_has(3);
  @$pb.TagNumber(4)
  void clearAvgSpeedKmh() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get avgCost => $_getN(4);
  @$pb.TagNumber(5)
  set avgCost($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAvgCost() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvgCost() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get bestTripId => $_getI64(5);
  @$pb.TagNumber(6)
  set bestTripId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBestTripId() => $_has(5);
  @$pb.TagNumber(6)
  void clearBestTripId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.double get bestEfficiency => $_getN(6);
  @$pb.TagNumber(7)
  set bestEfficiency($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBestEfficiency() => $_has(6);
  @$pb.TagNumber(7)
  void clearBestEfficiency() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get worstTripId => $_getI64(7);
  @$pb.TagNumber(8)
  set worstTripId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWorstTripId() => $_has(7);
  @$pb.TagNumber(8)
  void clearWorstTripId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get worstEfficiency => $_getN(8);
  @$pb.TagNumber(9)
  set worstEfficiency($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasWorstEfficiency() => $_has(8);
  @$pb.TagNumber(9)
  void clearWorstEfficiency() => $_clearField(9);
}

/// GpsPoint is a [lat, lon] pair for lightweight GPS trace responses.
class GpsPoint extends $pb.GeneratedMessage {
  factory GpsPoint({
    $core.double? lat,
    $core.double? lon,
  }) {
    final result = GpsPoint._();
    if (lat != null) result.lat = lat;
    if (lon != null) result.lon = lon;
    return result;
  }

  GpsPoint._();

  factory GpsPoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpsPoint()..mergeFromBuffer(data, registry);
  factory GpsPoint.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GpsPoint()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GpsPoint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GpsPoint.$_createMessage)
    ..aD(1, _omitFieldNames ? '' : 'lat')
    ..aD(2, _omitFieldNames ? '' : 'lon')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpsPoint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GpsPoint copyWith(void Function(GpsPoint) updates) =>
      super.copyWith((message) => updates(message as GpsPoint)) as GpsPoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GpsPoint() / GpsPoint.new instead')
  static GpsPoint create() => GpsPoint._();
  static $pb.GeneratedMessage $_createMessage() => GpsPoint._();
  @$core.override
  GpsPoint createEmptyInstance() => GpsPoint._();
  @$core.pragma('dart2js:noInline')
  static GpsPoint getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GpsPoint>(GpsPoint.$_createMessage);
  static GpsPoint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.double get lat => $_getN(0);
  @$pb.TagNumber(1)
  set lat($core.double value) => $_setDouble(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLat() => $_has(0);
  @$pb.TagNumber(1)
  void clearLat() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get lon => $_getN(1);
  @$pb.TagNumber(2)
  set lon($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLon() => $_has(1);
  @$pb.TagNumber(2)
  void clearLon() => $_clearField(2);
}

class ListTripsRequest extends $pb.GeneratedMessage {
  factory ListTripsRequest({
    $core.int? days,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = ListTripsRequest._();
    if (days != null) result.days = days;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListTripsRequest._();

  factory ListTripsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListTripsRequest()..mergeFromBuffer(data, registry);
  factory ListTripsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListTripsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTripsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListTripsRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'days')
    ..aI(2, _omitFieldNames ? '' : 'limit')
    ..aI(3, _omitFieldNames ? '' : 'offset')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTripsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTripsRequest copyWith(void Function(ListTripsRequest) updates) =>
      super.copyWith((message) => updates(message as ListTripsRequest))
          as ListTripsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListTripsRequest() / ListTripsRequest.new instead')
  static ListTripsRequest create() => ListTripsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListTripsRequest._();
  @$core.override
  ListTripsRequest createEmptyInstance() => ListTripsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListTripsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListTripsRequest>(
          ListTripsRequest.$_createMessage);
  static ListTripsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get days => $_getIZ(0);
  @$pb.TagNumber(1)
  set days($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearDays() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get offset => $_getIZ(2);
  @$pb.TagNumber(3)
  set offset($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);
}

class ListTripsResponse extends $pb.GeneratedMessage {
  factory ListTripsResponse({
    $core.bool? success,
    $core.Iterable<TripSummary>? trips,
  }) {
    final result = ListTripsResponse._();
    if (success != null) result.success = success;
    if (trips != null) result.trips.addAll(trips);
    return result;
  }

  ListTripsResponse._();

  factory ListTripsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListTripsResponse()..mergeFromBuffer(data, registry);
  factory ListTripsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListTripsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTripsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListTripsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<TripSummary>(2, _omitFieldNames ? '' : 'trips',
        subBuilder: TripSummary.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTripsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListTripsResponse copyWith(void Function(ListTripsResponse) updates) =>
      super.copyWith((message) => updates(message as ListTripsResponse))
          as ListTripsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListTripsResponse() / ListTripsResponse.new instead')
  static ListTripsResponse create() => ListTripsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListTripsResponse._();
  @$core.override
  ListTripsResponse createEmptyInstance() => ListTripsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListTripsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListTripsResponse>(
          ListTripsResponse.$_createMessage);
  static ListTripsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<TripSummary> get trips => $_getList(1);
}

class GetTripRequest extends $pb.GeneratedMessage {
  factory GetTripRequest({
    $fixnum.Int64? id,
  }) {
    final result = GetTripRequest._();
    if (id != null) result.id = id;
    return result;
  }

  GetTripRequest._();

  factory GetTripRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTripRequest()..mergeFromBuffer(data, registry);
  factory GetTripRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTripRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTripRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetTripRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTripRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTripRequest copyWith(void Function(GetTripRequest) updates) =>
      super.copyWith((message) => updates(message as GetTripRequest))
          as GetTripRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetTripRequest() / GetTripRequest.new instead')
  static GetTripRequest create() => GetTripRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetTripRequest._();
  @$core.override
  GetTripRequest createEmptyInstance() => GetTripRequest._();
  @$core.pragma('dart2js:noInline')
  static GetTripRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTripRequest>(
          GetTripRequest.$_createMessage);
  static GetTripRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class GetTripResponse extends $pb.GeneratedMessage {
  factory GetTripResponse({
    $core.bool? success,
    TripDetail? trip,
    $core.String? error,
  }) {
    final result = GetTripResponse._();
    if (success != null) result.success = success;
    if (trip != null) result.trip = trip;
    if (error != null) result.error = error;
    return result;
  }

  GetTripResponse._();

  factory GetTripResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTripResponse()..mergeFromBuffer(data, registry);
  factory GetTripResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTripResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTripResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetTripResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<TripDetail>(2, _omitFieldNames ? '' : 'trip',
        subBuilder: TripDetail.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTripResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTripResponse copyWith(void Function(GetTripResponse) updates) =>
      super.copyWith((message) => updates(message as GetTripResponse))
          as GetTripResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetTripResponse() / GetTripResponse.new instead')
  static GetTripResponse create() => GetTripResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetTripResponse._();
  @$core.override
  GetTripResponse createEmptyInstance() => GetTripResponse._();
  @$core.pragma('dart2js:noInline')
  static GetTripResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTripResponse>(
          GetTripResponse.$_createMessage);
  static GetTripResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  TripDetail get trip => $_getN(1);
  @$pb.TagNumber(2)
  set trip(TripDetail value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTrip() => $_has(1);
  @$pb.TagNumber(2)
  void clearTrip() => $_clearField(2);
  @$pb.TagNumber(2)
  TripDetail ensureTrip() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class DeleteTripRequest extends $pb.GeneratedMessage {
  factory DeleteTripRequest({
    $fixnum.Int64? id,
  }) {
    final result = DeleteTripRequest._();
    if (id != null) result.id = id;
    return result;
  }

  DeleteTripRequest._();

  factory DeleteTripRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteTripRequest()..mergeFromBuffer(data, registry);
  factory DeleteTripRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteTripRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteTripRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DeleteTripRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTripRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTripRequest copyWith(void Function(DeleteTripRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteTripRequest))
          as DeleteTripRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteTripRequest() / DeleteTripRequest.new instead')
  static DeleteTripRequest create() => DeleteTripRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteTripRequest._();
  @$core.override
  DeleteTripRequest createEmptyInstance() => DeleteTripRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteTripRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteTripRequest>(
          DeleteTripRequest.$_createMessage);
  static DeleteTripRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeleteTripResponse extends $pb.GeneratedMessage {
  factory DeleteTripResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = DeleteTripResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeleteTripResponse._();

  factory DeleteTripResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteTripResponse()..mergeFromBuffer(data, registry);
  factory DeleteTripResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteTripResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteTripResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DeleteTripResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTripResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteTripResponse copyWith(void Function(DeleteTripResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteTripResponse))
          as DeleteTripResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteTripResponse() / DeleteTripResponse.new instead')
  static DeleteTripResponse create() => DeleteTripResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteTripResponse._();
  @$core.override
  DeleteTripResponse createEmptyInstance() => DeleteTripResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteTripResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteTripResponse>(
          DeleteTripResponse.$_createMessage);
  static DeleteTripResponse? _defaultInstance;

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

class GetSummaryRequest extends $pb.GeneratedMessage {
  factory GetSummaryRequest({
    $core.int? days,
  }) {
    final result = GetSummaryRequest._();
    if (days != null) result.days = days;
    return result;
  }

  GetSummaryRequest._();

  factory GetSummaryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSummaryRequest()..mergeFromBuffer(data, registry);
  factory GetSummaryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSummaryRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSummaryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSummaryRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'days')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSummaryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSummaryRequest copyWith(void Function(GetSummaryRequest) updates) =>
      super.copyWith((message) => updates(message as GetSummaryRequest))
          as GetSummaryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetSummaryRequest() / GetSummaryRequest.new instead')
  static GetSummaryRequest create() => GetSummaryRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSummaryRequest._();
  @$core.override
  GetSummaryRequest createEmptyInstance() => GetSummaryRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSummaryRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetSummaryRequest>(
          GetSummaryRequest.$_createMessage);
  static GetSummaryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get days => $_getIZ(0);
  @$pb.TagNumber(1)
  set days($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearDays() => $_clearField(1);
}

class GetSummaryResponse extends $pb.GeneratedMessage {
  factory GetSummaryResponse({
    $core.bool? success,
    $core.Iterable<WeeklyRollupEntry>? summary,
  }) {
    final result = GetSummaryResponse._();
    if (success != null) result.success = success;
    if (summary != null) result.summary.addAll(summary);
    return result;
  }

  GetSummaryResponse._();

  factory GetSummaryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSummaryResponse()..mergeFromBuffer(data, registry);
  factory GetSummaryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSummaryResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSummaryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSummaryResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<WeeklyRollupEntry>(2, _omitFieldNames ? '' : 'summary',
        subBuilder: WeeklyRollupEntry.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSummaryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSummaryResponse copyWith(void Function(GetSummaryResponse) updates) =>
      super.copyWith((message) => updates(message as GetSummaryResponse))
          as GetSummaryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetSummaryResponse() / GetSummaryResponse.new instead')
  static GetSummaryResponse create() => GetSummaryResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSummaryResponse._();
  @$core.override
  GetSummaryResponse createEmptyInstance() => GetSummaryResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSummaryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSummaryResponse>(
          GetSummaryResponse.$_createMessage);
  static GetSummaryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<WeeklyRollupEntry> get summary => $_getList(1);
}

class GetDnaRequest extends $pb.GeneratedMessage {
  factory GetDnaRequest({
    $core.int? days,
  }) {
    final result = GetDnaRequest._();
    if (days != null) result.days = days;
    return result;
  }

  GetDnaRequest._();

  factory GetDnaRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDnaRequest()..mergeFromBuffer(data, registry);
  factory GetDnaRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDnaRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDnaRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetDnaRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'days')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDnaRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDnaRequest copyWith(void Function(GetDnaRequest) updates) =>
      super.copyWith((message) => updates(message as GetDnaRequest))
          as GetDnaRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetDnaRequest() / GetDnaRequest.new instead')
  static GetDnaRequest create() => GetDnaRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetDnaRequest._();
  @$core.override
  GetDnaRequest createEmptyInstance() => GetDnaRequest._();
  @$core.pragma('dart2js:noInline')
  static GetDnaRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetDnaRequest>(
          GetDnaRequest.$_createMessage);
  static GetDnaRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get days => $_getIZ(0);
  @$pb.TagNumber(1)
  set days($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDays() => $_has(0);
  @$pb.TagNumber(1)
  void clearDays() => $_clearField(1);
}

class GetDnaResponse extends $pb.GeneratedMessage {
  factory GetDnaResponse({
    $core.bool? success,
    DnaScores? dna,
  }) {
    final result = GetDnaResponse._();
    if (success != null) result.success = success;
    if (dna != null) result.dna = dna;
    return result;
  }

  GetDnaResponse._();

  factory GetDnaResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDnaResponse()..mergeFromBuffer(data, registry);
  factory GetDnaResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDnaResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDnaResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetDnaResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<DnaScores>(2, _omitFieldNames ? '' : 'dna',
        subBuilder: DnaScores.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDnaResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDnaResponse copyWith(void Function(GetDnaResponse) updates) =>
      super.copyWith((message) => updates(message as GetDnaResponse))
          as GetDnaResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetDnaResponse() / GetDnaResponse.new instead')
  static GetDnaResponse create() => GetDnaResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetDnaResponse._();
  @$core.override
  GetDnaResponse createEmptyInstance() => GetDnaResponse._();
  @$core.pragma('dart2js:noInline')
  static GetDnaResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetDnaResponse>(
          GetDnaResponse.$_createMessage);
  static GetDnaResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  DnaScores get dna => $_getN(1);
  @$pb.TagNumber(2)
  set dna(DnaScores value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasDna() => $_has(1);
  @$pb.TagNumber(2)
  void clearDna() => $_clearField(2);
  @$pb.TagNumber(2)
  DnaScores ensureDna() => $_ensure(1);
}

class GetRangeRequest extends $pb.GeneratedMessage {
  factory GetRangeRequest() => GetRangeRequest._();

  GetRangeRequest._();

  factory GetRangeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRangeRequest()..mergeFromBuffer(data, registry);
  factory GetRangeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRangeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRangeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetRangeRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRangeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRangeRequest copyWith(void Function(GetRangeRequest) updates) =>
      super.copyWith((message) => updates(message as GetRangeRequest))
          as GetRangeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetRangeRequest() / GetRangeRequest.new instead')
  static GetRangeRequest create() => GetRangeRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetRangeRequest._();
  @$core.override
  GetRangeRequest createEmptyInstance() => GetRangeRequest._();
  @$core.pragma('dart2js:noInline')
  static GetRangeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRangeRequest>(
          GetRangeRequest.$_createMessage);
  static GetRangeRequest? _defaultInstance;
}

class GetRangeResponse extends $pb.GeneratedMessage {
  factory GetRangeResponse({
    $core.bool? success,
    $core.String? rangeJson,
    $core.String? message,
  }) {
    final result = GetRangeResponse._();
    if (success != null) result.success = success;
    if (rangeJson != null) result.rangeJson = rangeJson;
    if (message != null) result.message = message;
    return result;
  }

  GetRangeResponse._();

  factory GetRangeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRangeResponse()..mergeFromBuffer(data, registry);
  factory GetRangeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRangeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetRangeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetRangeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'rangeJson')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRangeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRangeResponse copyWith(void Function(GetRangeResponse) updates) =>
      super.copyWith((message) => updates(message as GetRangeResponse))
          as GetRangeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetRangeResponse() / GetRangeResponse.new instead')
  static GetRangeResponse create() => GetRangeResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetRangeResponse._();
  @$core.override
  GetRangeResponse createEmptyInstance() => GetRangeResponse._();
  @$core.pragma('dart2js:noInline')
  static GetRangeResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRangeResponse>(
          GetRangeResponse.$_createMessage);
  static GetRangeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Raw JSON from RangeEstimate.toJson(), or empty when not enough data.
  @$pb.TagNumber(2)
  $core.String get rangeJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set rangeJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRangeJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearRangeJson() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class GetConfigRequest extends $pb.GeneratedMessage {
  factory GetConfigRequest() => GetConfigRequest._();

  GetConfigRequest._();

  factory GetConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConfigRequest()..mergeFromBuffer(data, registry);
  factory GetConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConfigRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetConfigRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConfigRequest copyWith(void Function(GetConfigRequest) updates) =>
      super.copyWith((message) => updates(message as GetConfigRequest))
          as GetConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetConfigRequest() / GetConfigRequest.new instead')
  static GetConfigRequest create() => GetConfigRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetConfigRequest._();
  @$core.override
  GetConfigRequest createEmptyInstance() => GetConfigRequest._();
  @$core.pragma('dart2js:noInline')
  static GetConfigRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConfigRequest>(
          GetConfigRequest.$_createMessage);
  static GetConfigRequest? _defaultInstance;
}

class GetConfigResponse extends $pb.GeneratedMessage {
  factory GetConfigResponse({
    $core.bool? success,
    TripConfig? config,
  }) {
    final result = GetConfigResponse._();
    if (success != null) result.success = success;
    if (config != null) result.config = config;
    return result;
  }

  GetConfigResponse._();

  factory GetConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConfigResponse()..mergeFromBuffer(data, registry);
  factory GetConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConfigResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetConfigResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<TripConfig>(2, _omitFieldNames ? '' : 'config',
        subBuilder: TripConfig.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConfigResponse copyWith(void Function(GetConfigResponse) updates) =>
      super.copyWith((message) => updates(message as GetConfigResponse))
          as GetConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetConfigResponse() / GetConfigResponse.new instead')
  static GetConfigResponse create() => GetConfigResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetConfigResponse._();
  @$core.override
  GetConfigResponse createEmptyInstance() => GetConfigResponse._();
  @$core.pragma('dart2js:noInline')
  static GetConfigResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetConfigResponse>(
          GetConfigResponse.$_createMessage);
  static GetConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  TripConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config(TripConfig value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => $_clearField(2);
  @$pb.TagNumber(2)
  TripConfig ensureConfig() => $_ensure(1);
}

class SetConfigRequest extends $pb.GeneratedMessage {
  factory SetConfigRequest({
    $core.bool? enabled,
    $core.bool? hasEnabled_2,
    $core.double? electricityRate,
    $core.bool? hasElectricityRate_4,
    $core.String? currency,
    $core.String? distanceUnit,
    $core.double? fuelPricePerL,
    $core.bool? hasFuelPricePerL_8,
    $core.double? fuelTankCapacityL,
    $core.bool? hasFuelTankCapacityL_10,
  }) {
    final result = SetConfigRequest._();
    if (enabled != null) result.enabled = enabled;
    if (hasEnabled_2 != null) result.hasEnabled_2 = hasEnabled_2;
    if (electricityRate != null) result.electricityRate = electricityRate;
    if (hasElectricityRate_4 != null)
      result.hasElectricityRate_4 = hasElectricityRate_4;
    if (currency != null) result.currency = currency;
    if (distanceUnit != null) result.distanceUnit = distanceUnit;
    if (fuelPricePerL != null) result.fuelPricePerL = fuelPricePerL;
    if (hasFuelPricePerL_8 != null)
      result.hasFuelPricePerL_8 = hasFuelPricePerL_8;
    if (fuelTankCapacityL != null) result.fuelTankCapacityL = fuelTankCapacityL;
    if (hasFuelTankCapacityL_10 != null)
      result.hasFuelTankCapacityL_10 = hasFuelTankCapacityL_10;
    return result;
  }

  SetConfigRequest._();

  factory SetConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetConfigRequest()..mergeFromBuffer(data, registry);
  factory SetConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetConfigRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetConfigRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'hasEnabled')
    ..aD(3, _omitFieldNames ? '' : 'electricityRate')
    ..aOB(4, _omitFieldNames ? '' : 'hasElectricityRate')
    ..aOS(5, _omitFieldNames ? '' : 'currency')
    ..aOS(6, _omitFieldNames ? '' : 'distanceUnit')
    ..aD(7, _omitFieldNames ? '' : 'fuelPricePerL')
    ..aOB(8, _omitFieldNames ? '' : 'hasFuelPricePerL')
    ..aD(9, _omitFieldNames ? '' : 'fuelTankCapacityL')
    ..aOB(10, _omitFieldNames ? '' : 'hasFuelTankCapacityL')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetConfigRequest copyWith(void Function(SetConfigRequest) updates) =>
      super.copyWith((message) => updates(message as SetConfigRequest))
          as SetConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetConfigRequest() / SetConfigRequest.new instead')
  static SetConfigRequest create() => SetConfigRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetConfigRequest._();
  @$core.override
  SetConfigRequest createEmptyInstance() => SetConfigRequest._();
  @$core.pragma('dart2js:noInline')
  static SetConfigRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetConfigRequest>(
          SetConfigRequest.$_createMessage);
  static SetConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get hasEnabled_2 => $_getBF(1);
  @$pb.TagNumber(2)
  set hasEnabled_2($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasEnabled_2() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasEnabled_2() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get electricityRate => $_getN(2);
  @$pb.TagNumber(3)
  set electricityRate($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasElectricityRate() => $_has(2);
  @$pb.TagNumber(3)
  void clearElectricityRate() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get hasElectricityRate_4 => $_getBF(3);
  @$pb.TagNumber(4)
  set hasElectricityRate_4($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHasElectricityRate_4() => $_has(3);
  @$pb.TagNumber(4)
  void clearHasElectricityRate_4() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get currency => $_getSZ(4);
  @$pb.TagNumber(5)
  set currency($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrency() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrency() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get distanceUnit => $_getSZ(5);
  @$pb.TagNumber(6)
  set distanceUnit($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDistanceUnit() => $_has(5);
  @$pb.TagNumber(6)
  void clearDistanceUnit() => $_clearField(6);

  /// PHEV pricing (BladeWatch-9uu6). New field numbers only, so a client built against the
  /// old schema still parses this message.
  ///
  /// Each value carries an explicit has_* companion, matching the pattern above. proto3 omits
  /// default scalars on the wire, so without the companion a deliberate 0 — which means "not
  /// configured" for both of these — would be indistinguishable from "field not sent", and the
  /// daemon would keep the previous value instead of clearing it.
  @$pb.TagNumber(7)
  $core.double get fuelPricePerL => $_getN(6);
  @$pb.TagNumber(7)
  set fuelPricePerL($core.double value) => $_setDouble(6, value);
  @$pb.TagNumber(7)
  $core.bool hasFuelPricePerL() => $_has(6);
  @$pb.TagNumber(7)
  void clearFuelPricePerL() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get hasFuelPricePerL_8 => $_getBF(7);
  @$pb.TagNumber(8)
  set hasFuelPricePerL_8($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasHasFuelPricePerL_8() => $_has(7);
  @$pb.TagNumber(8)
  void clearHasFuelPricePerL_8() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.double get fuelTankCapacityL => $_getN(8);
  @$pb.TagNumber(9)
  set fuelTankCapacityL($core.double value) => $_setDouble(8, value);
  @$pb.TagNumber(9)
  $core.bool hasFuelTankCapacityL() => $_has(8);
  @$pb.TagNumber(9)
  void clearFuelTankCapacityL() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get hasFuelTankCapacityL_10 => $_getBF(9);
  @$pb.TagNumber(10)
  set hasFuelTankCapacityL_10($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasHasFuelTankCapacityL_10() => $_has(9);
  @$pb.TagNumber(10)
  void clearHasFuelTankCapacityL_10() => $_clearField(10);
}

class SetConfigResponse extends $pb.GeneratedMessage {
  factory SetConfigResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = SetConfigResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  SetConfigResponse._();

  factory SetConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetConfigResponse()..mergeFromBuffer(data, registry);
  factory SetConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetConfigResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetConfigResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetConfigResponse copyWith(void Function(SetConfigResponse) updates) =>
      super.copyWith((message) => updates(message as SetConfigResponse))
          as SetConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetConfigResponse() / SetConfigResponse.new instead')
  static SetConfigResponse create() => SetConfigResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetConfigResponse._();
  @$core.override
  SetConfigResponse createEmptyInstance() => SetConfigResponse._();
  @$core.pragma('dart2js:noInline')
  static SetConfigResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetConfigResponse>(
          SetConfigResponse.$_createMessage);
  static SetConfigResponse? _defaultInstance;

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

class GetStorageRequest extends $pb.GeneratedMessage {
  factory GetStorageRequest() => GetStorageRequest._();

  GetStorageRequest._();

  factory GetStorageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageRequest()..mergeFromBuffer(data, registry);
  factory GetStorageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStorageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStorageRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageRequest copyWith(void Function(GetStorageRequest) updates) =>
      super.copyWith((message) => updates(message as GetStorageRequest))
          as GetStorageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStorageRequest() / GetStorageRequest.new instead')
  static GetStorageRequest create() => GetStorageRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStorageRequest._();
  @$core.override
  GetStorageRequest createEmptyInstance() => GetStorageRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStorageRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStorageRequest>(
          GetStorageRequest.$_createMessage);
  static GetStorageRequest? _defaultInstance;
}

class GetStorageResponse extends $pb.GeneratedMessage {
  factory GetStorageResponse({
    $core.bool? success,
    TripStorageInfo? storage,
  }) {
    final result = GetStorageResponse._();
    if (success != null) result.success = success;
    if (storage != null) result.storage = storage;
    return result;
  }

  GetStorageResponse._();

  factory GetStorageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageResponse()..mergeFromBuffer(data, registry);
  factory GetStorageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStorageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStorageResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOM<TripStorageInfo>(2, _omitFieldNames ? '' : 'storage',
        subBuilder: TripStorageInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageResponse copyWith(void Function(GetStorageResponse) updates) =>
      super.copyWith((message) => updates(message as GetStorageResponse))
          as GetStorageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStorageResponse() / GetStorageResponse.new instead')
  static GetStorageResponse create() => GetStorageResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetStorageResponse._();
  @$core.override
  GetStorageResponse createEmptyInstance() => GetStorageResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStorageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStorageResponse>(
          GetStorageResponse.$_createMessage);
  static GetStorageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  TripStorageInfo get storage => $_getN(1);
  @$pb.TagNumber(2)
  set storage(TripStorageInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStorage() => $_has(1);
  @$pb.TagNumber(2)
  void clearStorage() => $_clearField(2);
  @$pb.TagNumber(2)
  TripStorageInfo ensureStorage() => $_ensure(1);
}

class SetStorageRequest extends $pb.GeneratedMessage {
  factory SetStorageRequest({
    $core.String? storageType,
    $fixnum.Int64? storageLimitMb,
    $core.bool? hasStorageLimitMb_3,
  }) {
    final result = SetStorageRequest._();
    if (storageType != null) result.storageType = storageType;
    if (storageLimitMb != null) result.storageLimitMb = storageLimitMb;
    if (hasStorageLimitMb_3 != null)
      result.hasStorageLimitMb_3 = hasStorageLimitMb_3;
    return result;
  }

  SetStorageRequest._();

  factory SetStorageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageRequest()..mergeFromBuffer(data, registry);
  factory SetStorageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetStorageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetStorageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'storageType')
    ..aInt64(2, _omitFieldNames ? '' : 'storageLimitMb')
    ..aOB(3, _omitFieldNames ? '' : 'hasStorageLimitMb')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageRequest copyWith(void Function(SetStorageRequest) updates) =>
      super.copyWith((message) => updates(message as SetStorageRequest))
          as SetStorageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetStorageRequest() / SetStorageRequest.new instead')
  static SetStorageRequest create() => SetStorageRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetStorageRequest._();
  @$core.override
  SetStorageRequest createEmptyInstance() => SetStorageRequest._();
  @$core.pragma('dart2js:noInline')
  static SetStorageRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetStorageRequest>(
          SetStorageRequest.$_createMessage);
  static SetStorageRequest? _defaultInstance;

  /// "INTERNAL" or "SD_CARD". Leave empty to keep current.
  @$pb.TagNumber(1)
  $core.String get storageType => $_getSZ(0);
  @$pb.TagNumber(1)
  set storageType($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStorageType() => $_has(0);
  @$pb.TagNumber(1)
  void clearStorageType() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get storageLimitMb => $_getI64(1);
  @$pb.TagNumber(2)
  set storageLimitMb($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStorageLimitMb() => $_has(1);
  @$pb.TagNumber(2)
  void clearStorageLimitMb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get hasStorageLimitMb_3 => $_getBF(2);
  @$pb.TagNumber(3)
  set hasStorageLimitMb_3($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasStorageLimitMb_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasStorageLimitMb_3() => $_clearField(3);
}

class SetStorageResponse extends $pb.GeneratedMessage {
  factory SetStorageResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = SetStorageResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  SetStorageResponse._();

  factory SetStorageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageResponse()..mergeFromBuffer(data, registry);
  factory SetStorageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetStorageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetStorageResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageResponse copyWith(void Function(SetStorageResponse) updates) =>
      super.copyWith((message) => updates(message as SetStorageResponse))
          as SetStorageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetStorageResponse() / SetStorageResponse.new instead')
  static SetStorageResponse create() => SetStorageResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetStorageResponse._();
  @$core.override
  SetStorageResponse createEmptyInstance() => SetStorageResponse._();
  @$core.pragma('dart2js:noInline')
  static SetStorageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetStorageResponse>(
          SetStorageResponse.$_createMessage);
  static SetStorageResponse? _defaultInstance;

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

class SyncTripsRequest extends $pb.GeneratedMessage {
  factory SyncTripsRequest() => SyncTripsRequest._();

  SyncTripsRequest._();

  factory SyncTripsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncTripsRequest()..mergeFromBuffer(data, registry);
  factory SyncTripsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncTripsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncTripsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SyncTripsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncTripsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncTripsRequest copyWith(void Function(SyncTripsRequest) updates) =>
      super.copyWith((message) => updates(message as SyncTripsRequest))
          as SyncTripsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncTripsRequest() / SyncTripsRequest.new instead')
  static SyncTripsRequest create() => SyncTripsRequest._();
  static $pb.GeneratedMessage $_createMessage() => SyncTripsRequest._();
  @$core.override
  SyncTripsRequest createEmptyInstance() => SyncTripsRequest._();
  @$core.pragma('dart2js:noInline')
  static SyncTripsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncTripsRequest>(
          SyncTripsRequest.$_createMessage);
  static SyncTripsRequest? _defaultInstance;
}

class SyncTripsResponse extends $pb.GeneratedMessage {
  factory SyncTripsResponse({
    $core.bool? success,
    $core.String? error,
    $core.int? added,
    $core.int? removed,
    $core.int? total,
  }) {
    final result = SyncTripsResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    if (added != null) result.added = added;
    if (removed != null) result.removed = removed;
    if (total != null) result.total = total;
    return result;
  }

  SyncTripsResponse._();

  factory SyncTripsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncTripsResponse()..mergeFromBuffer(data, registry);
  factory SyncTripsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncTripsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncTripsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SyncTripsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aI(3, _omitFieldNames ? '' : 'added')
    ..aI(4, _omitFieldNames ? '' : 'removed')
    ..aI(5, _omitFieldNames ? '' : 'total')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncTripsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncTripsResponse copyWith(void Function(SyncTripsResponse) updates) =>
      super.copyWith((message) => updates(message as SyncTripsResponse))
          as SyncTripsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncTripsResponse() / SyncTripsResponse.new instead')
  static SyncTripsResponse create() => SyncTripsResponse._();
  static $pb.GeneratedMessage $_createMessage() => SyncTripsResponse._();
  @$core.override
  SyncTripsResponse createEmptyInstance() => SyncTripsResponse._();
  @$core.pragma('dart2js:noInline')
  static SyncTripsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SyncTripsResponse>(
          SyncTripsResponse.$_createMessage);
  static SyncTripsResponse? _defaultInstance;

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

  @$pb.TagNumber(5)
  $core.int get total => $_getIZ(4);
  @$pb.TagNumber(5)
  set total($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTotal() => $_has(4);
  @$pb.TagNumber(5)
  void clearTotal() => $_clearField(5);
}

class GetTelemetryRequest extends $pb.GeneratedMessage {
  factory GetTelemetryRequest({
    $fixnum.Int64? tripId,
  }) {
    final result = GetTelemetryRequest._();
    if (tripId != null) result.tripId = tripId;
    return result;
  }

  GetTelemetryRequest._();

  factory GetTelemetryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTelemetryRequest()..mergeFromBuffer(data, registry);
  factory GetTelemetryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTelemetryRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTelemetryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetTelemetryRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'tripId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTelemetryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTelemetryRequest copyWith(void Function(GetTelemetryRequest) updates) =>
      super.copyWith((message) => updates(message as GetTelemetryRequest))
          as GetTelemetryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetTelemetryRequest() / GetTelemetryRequest.new instead')
  static GetTelemetryRequest create() => GetTelemetryRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetTelemetryRequest._();
  @$core.override
  GetTelemetryRequest createEmptyInstance() => GetTelemetryRequest._();
  @$core.pragma('dart2js:noInline')
  static GetTelemetryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTelemetryRequest>(
          GetTelemetryRequest.$_createMessage);
  static GetTelemetryRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get tripId => $_getI64(0);
  @$pb.TagNumber(1)
  set tripId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTripId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTripId() => $_clearField(1);
}

class GetTelemetryResponse extends $pb.GeneratedMessage {
  factory GetTelemetryResponse({
    $core.bool? success,
    $core.Iterable<TelemetrySample>? telemetry,
    $core.String? error,
  }) {
    final result = GetTelemetryResponse._();
    if (success != null) result.success = success;
    if (telemetry != null) result.telemetry.addAll(telemetry);
    if (error != null) result.error = error;
    return result;
  }

  GetTelemetryResponse._();

  factory GetTelemetryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTelemetryResponse()..mergeFromBuffer(data, registry);
  factory GetTelemetryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetTelemetryResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTelemetryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetTelemetryResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<TelemetrySample>(2, _omitFieldNames ? '' : 'telemetry',
        subBuilder: TelemetrySample.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTelemetryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetTelemetryResponse copyWith(void Function(GetTelemetryResponse) updates) =>
      super.copyWith((message) => updates(message as GetTelemetryResponse))
          as GetTelemetryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetTelemetryResponse() / GetTelemetryResponse.new instead')
  static GetTelemetryResponse create() => GetTelemetryResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetTelemetryResponse._();
  @$core.override
  GetTelemetryResponse createEmptyInstance() => GetTelemetryResponse._();
  @$core.pragma('dart2js:noInline')
  static GetTelemetryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTelemetryResponse>(
          GetTelemetryResponse.$_createMessage);
  static GetTelemetryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<TelemetrySample> get telemetry => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

class GetSimilarTripsRequest extends $pb.GeneratedMessage {
  factory GetSimilarTripsRequest({
    $fixnum.Int64? tripId,
  }) {
    final result = GetSimilarTripsRequest._();
    if (tripId != null) result.tripId = tripId;
    return result;
  }

  GetSimilarTripsRequest._();

  factory GetSimilarTripsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSimilarTripsRequest()..mergeFromBuffer(data, registry);
  factory GetSimilarTripsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSimilarTripsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSimilarTripsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSimilarTripsRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'tripId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSimilarTripsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSimilarTripsRequest copyWith(
          void Function(GetSimilarTripsRequest) updates) =>
      super.copyWith((message) => updates(message as GetSimilarTripsRequest))
          as GetSimilarTripsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSimilarTripsRequest() / GetSimilarTripsRequest.new instead')
  static GetSimilarTripsRequest create() => GetSimilarTripsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetSimilarTripsRequest._();
  @$core.override
  GetSimilarTripsRequest createEmptyInstance() => GetSimilarTripsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetSimilarTripsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSimilarTripsRequest>(
          GetSimilarTripsRequest.$_createMessage);
  static GetSimilarTripsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get tripId => $_getI64(0);
  @$pb.TagNumber(1)
  set tripId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTripId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTripId() => $_clearField(1);
}

class GetSimilarTripsResponse extends $pb.GeneratedMessage {
  factory GetSimilarTripsResponse({
    $core.bool? success,
    $core.Iterable<TripSummary>? similar,
    $core.int? count,
    SimilarTripsStats? stats,
    $core.String? error,
  }) {
    final result = GetSimilarTripsResponse._();
    if (success != null) result.success = success;
    if (similar != null) result.similar.addAll(similar);
    if (count != null) result.count = count;
    if (stats != null) result.stats = stats;
    if (error != null) result.error = error;
    return result;
  }

  GetSimilarTripsResponse._();

  factory GetSimilarTripsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSimilarTripsResponse()..mergeFromBuffer(data, registry);
  factory GetSimilarTripsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetSimilarTripsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSimilarTripsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetSimilarTripsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<TripSummary>(2, _omitFieldNames ? '' : 'similar',
        subBuilder: TripSummary.$_createMessage)
    ..aI(3, _omitFieldNames ? '' : 'count')
    ..aOM<SimilarTripsStats>(4, _omitFieldNames ? '' : 'stats',
        subBuilder: SimilarTripsStats.$_createMessage)
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSimilarTripsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSimilarTripsResponse copyWith(
          void Function(GetSimilarTripsResponse) updates) =>
      super.copyWith((message) => updates(message as GetSimilarTripsResponse))
          as GetSimilarTripsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetSimilarTripsResponse() / GetSimilarTripsResponse.new instead')
  static GetSimilarTripsResponse create() => GetSimilarTripsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetSimilarTripsResponse._();
  @$core.override
  GetSimilarTripsResponse createEmptyInstance() => GetSimilarTripsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetSimilarTripsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSimilarTripsResponse>(
          GetSimilarTripsResponse.$_createMessage);
  static GetSimilarTripsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<TripSummary> get similar => $_getList(1);

  @$pb.TagNumber(3)
  $core.int get count => $_getIZ(2);
  @$pb.TagNumber(3)
  set count($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearCount() => $_clearField(3);

  @$pb.TagNumber(4)
  SimilarTripsStats get stats => $_getN(3);
  @$pb.TagNumber(4)
  set stats(SimilarTripsStats value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStats() => $_has(3);
  @$pb.TagNumber(4)
  void clearStats() => $_clearField(4);
  @$pb.TagNumber(4)
  SimilarTripsStats ensureStats() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
}

class GetGpsTraceRequest extends $pb.GeneratedMessage {
  factory GetGpsTraceRequest({
    $fixnum.Int64? tripId,
  }) {
    final result = GetGpsTraceRequest._();
    if (tripId != null) result.tripId = tripId;
    return result;
  }

  GetGpsTraceRequest._();

  factory GetGpsTraceRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsTraceRequest()..mergeFromBuffer(data, registry);
  factory GetGpsTraceRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsTraceRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGpsTraceRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetGpsTraceRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'tripId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsTraceRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsTraceRequest copyWith(void Function(GetGpsTraceRequest) updates) =>
      super.copyWith((message) => updates(message as GetGpsTraceRequest))
          as GetGpsTraceRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetGpsTraceRequest() / GetGpsTraceRequest.new instead')
  static GetGpsTraceRequest create() => GetGpsTraceRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetGpsTraceRequest._();
  @$core.override
  GetGpsTraceRequest createEmptyInstance() => GetGpsTraceRequest._();
  @$core.pragma('dart2js:noInline')
  static GetGpsTraceRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGpsTraceRequest>(
          GetGpsTraceRequest.$_createMessage);
  static GetGpsTraceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get tripId => $_getI64(0);
  @$pb.TagNumber(1)
  set tripId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTripId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTripId() => $_clearField(1);
}

class GetGpsTraceResponse extends $pb.GeneratedMessage {
  factory GetGpsTraceResponse({
    $core.bool? success,
    $core.Iterable<GpsPoint>? gps,
    $core.String? error,
  }) {
    final result = GetGpsTraceResponse._();
    if (success != null) result.success = success;
    if (gps != null) result.gps.addAll(gps);
    if (error != null) result.error = error;
    return result;
  }

  GetGpsTraceResponse._();

  factory GetGpsTraceResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsTraceResponse()..mergeFromBuffer(data, registry);
  factory GetGpsTraceResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetGpsTraceResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetGpsTraceResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetGpsTraceResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<GpsPoint>(2, _omitFieldNames ? '' : 'gps',
        subBuilder: GpsPoint.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsTraceResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetGpsTraceResponse copyWith(void Function(GetGpsTraceResponse) updates) =>
      super.copyWith((message) => updates(message as GetGpsTraceResponse))
          as GetGpsTraceResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetGpsTraceResponse() / GetGpsTraceResponse.new instead')
  static GetGpsTraceResponse create() => GetGpsTraceResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetGpsTraceResponse._();
  @$core.override
  GetGpsTraceResponse createEmptyInstance() => GetGpsTraceResponse._();
  @$core.pragma('dart2js:noInline')
  static GetGpsTraceResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetGpsTraceResponse>(
          GetGpsTraceResponse.$_createMessage);
  static GetGpsTraceResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<GpsPoint> get gps => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get error => $_getSZ(2);
  @$pb.TagNumber(3)
  set error($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
}

/// ActiveTripStatus describes the trip in progress, if any.
class ActiveTripStatus extends $pb.GeneratedMessage {
  factory ActiveTripStatus({
    $core.bool? active,
    $core.bool? manual,
    $fixnum.Int64? startTimeMs,
    $core.double? distanceKm,
    $fixnum.Int64? autoStopAtMs,
    $fixnum.Int64? reminderSeq,
    $core.String? reminderReason,
    $fixnum.Int64? reminderAckedSeq,
    $core.bool? telemetryPaused,
    $core.bool? liveCostAvailable,
    $core.double? liveElectricCost,
    $core.double? liveFuelCost,
    $core.String? liveCurrency,
    $core.bool? liveHasFuel,
  }) {
    final result = ActiveTripStatus._();
    if (active != null) result.active = active;
    if (manual != null) result.manual = manual;
    if (startTimeMs != null) result.startTimeMs = startTimeMs;
    if (distanceKm != null) result.distanceKm = distanceKm;
    if (autoStopAtMs != null) result.autoStopAtMs = autoStopAtMs;
    if (reminderSeq != null) result.reminderSeq = reminderSeq;
    if (reminderReason != null) result.reminderReason = reminderReason;
    if (reminderAckedSeq != null) result.reminderAckedSeq = reminderAckedSeq;
    if (telemetryPaused != null) result.telemetryPaused = telemetryPaused;
    if (liveCostAvailable != null) result.liveCostAvailable = liveCostAvailable;
    if (liveElectricCost != null) result.liveElectricCost = liveElectricCost;
    if (liveFuelCost != null) result.liveFuelCost = liveFuelCost;
    if (liveCurrency != null) result.liveCurrency = liveCurrency;
    if (liveHasFuel != null) result.liveHasFuel = liveHasFuel;
    return result;
  }

  ActiveTripStatus._();

  factory ActiveTripStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActiveTripStatus()..mergeFromBuffer(data, registry);
  factory ActiveTripStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActiveTripStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActiveTripStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ActiveTripStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'active')
    ..aOB(2, _omitFieldNames ? '' : 'manual')
    ..aInt64(3, _omitFieldNames ? '' : 'startTimeMs')
    ..aD(4, _omitFieldNames ? '' : 'distanceKm')
    ..aInt64(5, _omitFieldNames ? '' : 'autoStopAtMs')
    ..aInt64(6, _omitFieldNames ? '' : 'reminderSeq')
    ..aOS(7, _omitFieldNames ? '' : 'reminderReason')
    ..aInt64(8, _omitFieldNames ? '' : 'reminderAckedSeq')
    ..aOB(9, _omitFieldNames ? '' : 'telemetryPaused')
    ..aOB(10, _omitFieldNames ? '' : 'liveCostAvailable')
    ..aD(11, _omitFieldNames ? '' : 'liveElectricCost')
    ..aD(12, _omitFieldNames ? '' : 'liveFuelCost')
    ..aOS(13, _omitFieldNames ? '' : 'liveCurrency')
    ..aOB(14, _omitFieldNames ? '' : 'liveHasFuel')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveTripStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActiveTripStatus copyWith(void Function(ActiveTripStatus) updates) =>
      super.copyWith((message) => updates(message as ActiveTripStatus))
          as ActiveTripStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ActiveTripStatus() / ActiveTripStatus.new instead')
  static ActiveTripStatus create() => ActiveTripStatus._();
  static $pb.GeneratedMessage $_createMessage() => ActiveTripStatus._();
  @$core.override
  ActiveTripStatus createEmptyInstance() => ActiveTripStatus._();
  @$core.pragma('dart2js:noInline')
  static ActiveTripStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ActiveTripStatus>(
          ActiveTripStatus.$_createMessage);
  static ActiveTripStatus? _defaultInstance;

  /// True while any trip (auto-detected or manual) is open.
  @$pb.TagNumber(1)
  $core.bool get active => $_getBF(0);
  @$pb.TagNumber(1)
  set active($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasActive() => $_has(0);
  @$pb.TagNumber(1)
  void clearActive() => $_clearField(1);

  /// True when the open trip was started with the Start Trip button.
  @$pb.TagNumber(2)
  $core.bool get manual => $_getBF(1);
  @$pb.TagNumber(2)
  set manual($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasManual() => $_has(1);
  @$pb.TagNumber(2)
  void clearManual() => $_clearField(2);

  /// Epoch ms the open trip started; 0 when no trip is open.
  @$pb.TagNumber(3)
  $fixnum.Int64 get startTimeMs => $_getI64(2);
  @$pb.TagNumber(3)
  set startTimeMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasStartTimeMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartTimeMs() => $_clearField(3);

  /// GPS distance recorded so far, in km.
  @$pb.TagNumber(4)
  $core.double get distanceKm => $_getN(3);
  @$pb.TagNumber(4)
  set distanceKm($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDistanceKm() => $_has(3);
  @$pb.TagNumber(4)
  void clearDistanceKm() => $_clearField(4);

  /// Epoch ms at which a manual trip is ended automatically (start + 7 days); 0 otherwise.
  @$pb.TagNumber(5)
  $fixnum.Int64 get autoStopAtMs => $_getI64(4);
  @$pb.TagNumber(5)
  set autoStopAtMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAutoStopAtMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearAutoStopAtMs() => $_clearField(5);

  /// Reminder to stop an open manual trip. reminder_seq counts reminders raised for this trip
  /// and is 0 until the first one; reminder_reason is "acc_off" or "parked_30m" (empty before the
  /// first). The in-car app shows a dialog while reminder_seq > reminder_acked_seq and then calls
  /// AcknowledgeTripReminder, so each reminder is shown once even across app restarts.
  @$pb.TagNumber(6)
  $fixnum.Int64 get reminderSeq => $_getI64(5);
  @$pb.TagNumber(6)
  set reminderSeq($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReminderSeq() => $_has(5);
  @$pb.TagNumber(6)
  void clearReminderSeq() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get reminderReason => $_getSZ(6);
  @$pb.TagNumber(7)
  set reminderReason($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasReminderReason() => $_has(6);
  @$pb.TagNumber(7)
  void clearReminderReason() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get reminderAckedSeq => $_getI64(7);
  @$pb.TagNumber(8)
  set reminderAckedSeq($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasReminderAckedSeq() => $_has(7);
  @$pb.TagNumber(8)
  void clearReminderAckedSeq() => $_clearField(8);

  /// True while telemetry sampling is suspended because ACC is OFF (the trip stays open).
  @$pb.TagNumber(9)
  $core.bool get telemetryPaused => $_getBF(8);
  @$pb.TagNumber(9)
  set telemetryPaused($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasTelemetryPaused() => $_has(8);
  @$pb.TagNumber(9)
  void clearTelemetryPaused() => $_clearField(9);

  /// What the open trip has cost SO FAR (BladeWatch-reml): EV driving so far x the electricity rate,
  /// HEV driving so far x the fuel price. live_cost_available is false with no trip open or with
  /// neither rate configured (not a cost of zero). live_has_fuel is true when a fuel price is set, so
  /// a client can leave the fuel part out for an electricity-only owner.
  @$pb.TagNumber(10)
  $core.bool get liveCostAvailable => $_getBF(9);
  @$pb.TagNumber(10)
  set liveCostAvailable($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLiveCostAvailable() => $_has(9);
  @$pb.TagNumber(10)
  void clearLiveCostAvailable() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.double get liveElectricCost => $_getN(10);
  @$pb.TagNumber(11)
  set liveElectricCost($core.double value) => $_setDouble(10, value);
  @$pb.TagNumber(11)
  $core.bool hasLiveElectricCost() => $_has(10);
  @$pb.TagNumber(11)
  void clearLiveElectricCost() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.double get liveFuelCost => $_getN(11);
  @$pb.TagNumber(12)
  set liveFuelCost($core.double value) => $_setDouble(11, value);
  @$pb.TagNumber(12)
  $core.bool hasLiveFuelCost() => $_has(11);
  @$pb.TagNumber(12)
  void clearLiveFuelCost() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get liveCurrency => $_getSZ(12);
  @$pb.TagNumber(13)
  set liveCurrency($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasLiveCurrency() => $_has(12);
  @$pb.TagNumber(13)
  void clearLiveCurrency() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get liveHasFuel => $_getBF(13);
  @$pb.TagNumber(14)
  set liveHasFuel($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasLiveHasFuel() => $_has(13);
  @$pb.TagNumber(14)
  void clearLiveHasFuel() => $_clearField(14);
}

class StartManualTripRequest extends $pb.GeneratedMessage {
  factory StartManualTripRequest() => StartManualTripRequest._();

  StartManualTripRequest._();

  factory StartManualTripRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartManualTripRequest()..mergeFromBuffer(data, registry);
  factory StartManualTripRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartManualTripRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartManualTripRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StartManualTripRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartManualTripRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartManualTripRequest copyWith(
          void Function(StartManualTripRequest) updates) =>
      super.copyWith((message) => updates(message as StartManualTripRequest))
          as StartManualTripRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StartManualTripRequest() / StartManualTripRequest.new instead')
  static StartManualTripRequest create() => StartManualTripRequest._();
  static $pb.GeneratedMessage $_createMessage() => StartManualTripRequest._();
  @$core.override
  StartManualTripRequest createEmptyInstance() => StartManualTripRequest._();
  @$core.pragma('dart2js:noInline')
  static StartManualTripRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartManualTripRequest>(
          StartManualTripRequest.$_createMessage);
  static StartManualTripRequest? _defaultInstance;
}

class StartManualTripResponse extends $pb.GeneratedMessage {
  factory StartManualTripResponse({
    ActiveTripStatus? status,
  }) {
    final result = StartManualTripResponse._();
    if (status != null) result.status = status;
    return result;
  }

  StartManualTripResponse._();

  factory StartManualTripResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartManualTripResponse()..mergeFromBuffer(data, registry);
  factory StartManualTripResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StartManualTripResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartManualTripResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StartManualTripResponse.$_createMessage)
    ..aOM<ActiveTripStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: ActiveTripStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartManualTripResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartManualTripResponse copyWith(
          void Function(StartManualTripResponse) updates) =>
      super.copyWith((message) => updates(message as StartManualTripResponse))
          as StartManualTripResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StartManualTripResponse() / StartManualTripResponse.new instead')
  static StartManualTripResponse create() => StartManualTripResponse._();
  static $pb.GeneratedMessage $_createMessage() => StartManualTripResponse._();
  @$core.override
  StartManualTripResponse createEmptyInstance() => StartManualTripResponse._();
  @$core.pragma('dart2js:noInline')
  static StartManualTripResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartManualTripResponse>(
          StartManualTripResponse.$_createMessage);
  static StartManualTripResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ActiveTripStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ActiveTripStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  ActiveTripStatus ensureStatus() => $_ensure(0);
}

class StopManualTripRequest extends $pb.GeneratedMessage {
  factory StopManualTripRequest() => StopManualTripRequest._();

  StopManualTripRequest._();

  factory StopManualTripRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopManualTripRequest()..mergeFromBuffer(data, registry);
  factory StopManualTripRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopManualTripRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopManualTripRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StopManualTripRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopManualTripRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopManualTripRequest copyWith(
          void Function(StopManualTripRequest) updates) =>
      super.copyWith((message) => updates(message as StopManualTripRequest))
          as StopManualTripRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StopManualTripRequest() / StopManualTripRequest.new instead')
  static StopManualTripRequest create() => StopManualTripRequest._();
  static $pb.GeneratedMessage $_createMessage() => StopManualTripRequest._();
  @$core.override
  StopManualTripRequest createEmptyInstance() => StopManualTripRequest._();
  @$core.pragma('dart2js:noInline')
  static StopManualTripRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopManualTripRequest>(
          StopManualTripRequest.$_createMessage);
  static StopManualTripRequest? _defaultInstance;
}

class StopManualTripResponse extends $pb.GeneratedMessage {
  factory StopManualTripResponse({
    $core.bool? stopped,
  }) {
    final result = StopManualTripResponse._();
    if (stopped != null) result.stopped = stopped;
    return result;
  }

  StopManualTripResponse._();

  factory StopManualTripResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopManualTripResponse()..mergeFromBuffer(data, registry);
  factory StopManualTripResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StopManualTripResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StopManualTripResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: StopManualTripResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'stopped')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopManualTripResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StopManualTripResponse copyWith(
          void Function(StopManualTripResponse) updates) =>
      super.copyWith((message) => updates(message as StopManualTripResponse))
          as StopManualTripResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use StopManualTripResponse() / StopManualTripResponse.new instead')
  static StopManualTripResponse create() => StopManualTripResponse._();
  static $pb.GeneratedMessage $_createMessage() => StopManualTripResponse._();
  @$core.override
  StopManualTripResponse createEmptyInstance() => StopManualTripResponse._();
  @$core.pragma('dart2js:noInline')
  static StopManualTripResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StopManualTripResponse>(
          StopManualTripResponse.$_createMessage);
  static StopManualTripResponse? _defaultInstance;

  /// False when no manual trip was open (an auto trip in progress is left alone).
  @$pb.TagNumber(1)
  $core.bool get stopped => $_getBF(0);
  @$pb.TagNumber(1)
  set stopped($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStopped() => $_has(0);
  @$pb.TagNumber(1)
  void clearStopped() => $_clearField(1);
}

class GetActiveTripRequest extends $pb.GeneratedMessage {
  factory GetActiveTripRequest() => GetActiveTripRequest._();

  GetActiveTripRequest._();

  factory GetActiveTripRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetActiveTripRequest()..mergeFromBuffer(data, registry);
  factory GetActiveTripRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetActiveTripRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetActiveTripRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetActiveTripRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetActiveTripRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetActiveTripRequest copyWith(void Function(GetActiveTripRequest) updates) =>
      super.copyWith((message) => updates(message as GetActiveTripRequest))
          as GetActiveTripRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetActiveTripRequest() / GetActiveTripRequest.new instead')
  static GetActiveTripRequest create() => GetActiveTripRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetActiveTripRequest._();
  @$core.override
  GetActiveTripRequest createEmptyInstance() => GetActiveTripRequest._();
  @$core.pragma('dart2js:noInline')
  static GetActiveTripRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetActiveTripRequest>(
          GetActiveTripRequest.$_createMessage);
  static GetActiveTripRequest? _defaultInstance;
}

class GetActiveTripResponse extends $pb.GeneratedMessage {
  factory GetActiveTripResponse({
    ActiveTripStatus? status,
  }) {
    final result = GetActiveTripResponse._();
    if (status != null) result.status = status;
    return result;
  }

  GetActiveTripResponse._();

  factory GetActiveTripResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetActiveTripResponse()..mergeFromBuffer(data, registry);
  factory GetActiveTripResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetActiveTripResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetActiveTripResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetActiveTripResponse.$_createMessage)
    ..aOM<ActiveTripStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: ActiveTripStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetActiveTripResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetActiveTripResponse copyWith(
          void Function(GetActiveTripResponse) updates) =>
      super.copyWith((message) => updates(message as GetActiveTripResponse))
          as GetActiveTripResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetActiveTripResponse() / GetActiveTripResponse.new instead')
  static GetActiveTripResponse create() => GetActiveTripResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetActiveTripResponse._();
  @$core.override
  GetActiveTripResponse createEmptyInstance() => GetActiveTripResponse._();
  @$core.pragma('dart2js:noInline')
  static GetActiveTripResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetActiveTripResponse>(
          GetActiveTripResponse.$_createMessage);
  static GetActiveTripResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ActiveTripStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ActiveTripStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  ActiveTripStatus ensureStatus() => $_ensure(0);
}

class AcknowledgeTripReminderRequest extends $pb.GeneratedMessage {
  factory AcknowledgeTripReminderRequest({
    $fixnum.Int64? reminderSeq,
  }) {
    final result = AcknowledgeTripReminderRequest._();
    if (reminderSeq != null) result.reminderSeq = reminderSeq;
    return result;
  }

  AcknowledgeTripReminderRequest._();

  factory AcknowledgeTripReminderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcknowledgeTripReminderRequest()..mergeFromBuffer(data, registry);
  factory AcknowledgeTripReminderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcknowledgeTripReminderRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcknowledgeTripReminderRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: AcknowledgeTripReminderRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'reminderSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcknowledgeTripReminderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcknowledgeTripReminderRequest copyWith(
          void Function(AcknowledgeTripReminderRequest) updates) =>
      super.copyWith(
              (message) => updates(message as AcknowledgeTripReminderRequest))
          as AcknowledgeTripReminderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AcknowledgeTripReminderRequest() / AcknowledgeTripReminderRequest.new instead')
  static AcknowledgeTripReminderRequest create() =>
      AcknowledgeTripReminderRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      AcknowledgeTripReminderRequest._();
  @$core.override
  AcknowledgeTripReminderRequest createEmptyInstance() =>
      AcknowledgeTripReminderRequest._();
  @$core.pragma('dart2js:noInline')
  static AcknowledgeTripReminderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcknowledgeTripReminderRequest>(
          AcknowledgeTripReminderRequest.$_createMessage);
  static AcknowledgeTripReminderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get reminderSeq => $_getI64(0);
  @$pb.TagNumber(1)
  set reminderSeq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReminderSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearReminderSeq() => $_clearField(1);
}

class AcknowledgeTripReminderResponse extends $pb.GeneratedMessage {
  factory AcknowledgeTripReminderResponse({
    ActiveTripStatus? status,
  }) {
    final result = AcknowledgeTripReminderResponse._();
    if (status != null) result.status = status;
    return result;
  }

  AcknowledgeTripReminderResponse._();

  factory AcknowledgeTripReminderResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcknowledgeTripReminderResponse()..mergeFromBuffer(data, registry);
  factory AcknowledgeTripReminderResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AcknowledgeTripReminderResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AcknowledgeTripReminderResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: AcknowledgeTripReminderResponse.$_createMessage)
    ..aOM<ActiveTripStatus>(1, _omitFieldNames ? '' : 'status',
        subBuilder: ActiveTripStatus.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcknowledgeTripReminderResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AcknowledgeTripReminderResponse copyWith(
          void Function(AcknowledgeTripReminderResponse) updates) =>
      super.copyWith(
              (message) => updates(message as AcknowledgeTripReminderResponse))
          as AcknowledgeTripReminderResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use AcknowledgeTripReminderResponse() / AcknowledgeTripReminderResponse.new instead')
  static AcknowledgeTripReminderResponse create() =>
      AcknowledgeTripReminderResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      AcknowledgeTripReminderResponse._();
  @$core.override
  AcknowledgeTripReminderResponse createEmptyInstance() =>
      AcknowledgeTripReminderResponse._();
  @$core.pragma('dart2js:noInline')
  static AcknowledgeTripReminderResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AcknowledgeTripReminderResponse>(
          AcknowledgeTripReminderResponse.$_createMessage);
  static AcknowledgeTripReminderResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ActiveTripStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(ActiveTripStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  ActiveTripStatus ensureStatus() => $_ensure(0);
}

/// TripsService manages trip analytics records, Driving DNA scores, and
/// personalised range estimation.
///
/// HTTP mapping:
///   ListTrips        GET    /api/trips
///   GetTrip          GET    /api/trips/{id}
///   DeleteTrip       DELETE /api/trips/{id}
///   GetSummary       GET    /api/trips/summary
///   GetDna           GET    /api/trips/dna
///   GetRange         GET    /api/trips/range
///   GetConfig        GET    /api/trips/config
///   SetConfig        POST   /api/trips/config
///   GetStorage       GET    /api/trips/storage
///   SetStorage       POST   /api/trips/storage
///   SyncTrips        POST   /api/trips/sync
///   GetTelemetry     GET    /api/trips/{id}/telemetry
///   GetSimilarTrips  GET    /api/trips/{id}/similar
///   GetGpsTrace      GET    /api/trips/{id}/gps
///   StartManualTrip  POST   /api/trips/manual/start
///   StopManualTrip   POST   /api/trips/manual/stop
///   GetActiveTrip    GET    /api/trips/active
///   AcknowledgeTripReminder POST /api/trips/manual/ack
class TripsServiceApi {
  final $pb.RpcClient _client;

  TripsServiceApi(this._client);

  $async.Future<ListTripsResponse> listTrips(
          $pb.ClientContext? ctx, ListTripsRequest request) =>
      _client.invoke<ListTripsResponse>(
          ctx, 'TripsService', 'ListTrips', request, ListTripsResponse());
  $async.Future<GetTripResponse> getTrip(
          $pb.ClientContext? ctx, GetTripRequest request) =>
      _client.invoke<GetTripResponse>(
          ctx, 'TripsService', 'GetTrip', request, GetTripResponse());
  $async.Future<DeleteTripResponse> deleteTrip(
          $pb.ClientContext? ctx, DeleteTripRequest request) =>
      _client.invoke<DeleteTripResponse>(
          ctx, 'TripsService', 'DeleteTrip', request, DeleteTripResponse());
  $async.Future<GetSummaryResponse> getSummary(
          $pb.ClientContext? ctx, GetSummaryRequest request) =>
      _client.invoke<GetSummaryResponse>(
          ctx, 'TripsService', 'GetSummary', request, GetSummaryResponse());
  $async.Future<GetDnaResponse> getDna(
          $pb.ClientContext? ctx, GetDnaRequest request) =>
      _client.invoke<GetDnaResponse>(
          ctx, 'TripsService', 'GetDna', request, GetDnaResponse());
  $async.Future<GetRangeResponse> getRange(
          $pb.ClientContext? ctx, GetRangeRequest request) =>
      _client.invoke<GetRangeResponse>(
          ctx, 'TripsService', 'GetRange', request, GetRangeResponse());
  $async.Future<GetConfigResponse> getConfig(
          $pb.ClientContext? ctx, GetConfigRequest request) =>
      _client.invoke<GetConfigResponse>(
          ctx, 'TripsService', 'GetConfig', request, GetConfigResponse());
  $async.Future<SetConfigResponse> setConfig(
          $pb.ClientContext? ctx, SetConfigRequest request) =>
      _client.invoke<SetConfigResponse>(
          ctx, 'TripsService', 'SetConfig', request, SetConfigResponse());
  $async.Future<GetStorageResponse> getStorage(
          $pb.ClientContext? ctx, GetStorageRequest request) =>
      _client.invoke<GetStorageResponse>(
          ctx, 'TripsService', 'GetStorage', request, GetStorageResponse());
  $async.Future<SetStorageResponse> setStorage(
          $pb.ClientContext? ctx, SetStorageRequest request) =>
      _client.invoke<SetStorageResponse>(
          ctx, 'TripsService', 'SetStorage', request, SetStorageResponse());
  $async.Future<SyncTripsResponse> syncTrips(
          $pb.ClientContext? ctx, SyncTripsRequest request) =>
      _client.invoke<SyncTripsResponse>(
          ctx, 'TripsService', 'SyncTrips', request, SyncTripsResponse());
  $async.Future<GetTelemetryResponse> getTelemetry(
          $pb.ClientContext? ctx, GetTelemetryRequest request) =>
      _client.invoke<GetTelemetryResponse>(
          ctx, 'TripsService', 'GetTelemetry', request, GetTelemetryResponse());
  $async.Future<GetSimilarTripsResponse> getSimilarTrips(
          $pb.ClientContext? ctx, GetSimilarTripsRequest request) =>
      _client.invoke<GetSimilarTripsResponse>(ctx, 'TripsService',
          'GetSimilarTrips', request, GetSimilarTripsResponse());
  $async.Future<GetGpsTraceResponse> getGpsTrace(
          $pb.ClientContext? ctx, GetGpsTraceRequest request) =>
      _client.invoke<GetGpsTraceResponse>(
          ctx, 'TripsService', 'GetGpsTrace', request, GetGpsTraceResponse());

  /// Manual trips (BladeWatch-gklt): the driver starts a trip with the Start Trip button; it ends
  /// only via StopManualTrip (or a 7-day safety auto-stop), never on Park or ACC OFF.
  $async.Future<StartManualTripResponse> startManualTrip(
          $pb.ClientContext? ctx, StartManualTripRequest request) =>
      _client.invoke<StartManualTripResponse>(ctx, 'TripsService',
          'StartManualTrip', request, StartManualTripResponse());
  $async.Future<StopManualTripResponse> stopManualTrip(
          $pb.ClientContext? ctx, StopManualTripRequest request) =>
      _client.invoke<StopManualTripResponse>(ctx, 'TripsService',
          'StopManualTrip', request, StopManualTripResponse());
  $async.Future<GetActiveTripResponse> getActiveTrip(
          $pb.ClientContext? ctx, GetActiveTripRequest request) =>
      _client.invoke<GetActiveTripResponse>(ctx, 'TripsService',
          'GetActiveTrip', request, GetActiveTripResponse());
  $async.Future<AcknowledgeTripReminderResponse> acknowledgeTripReminder(
          $pb.ClientContext? ctx, AcknowledgeTripReminderRequest request) =>
      _client.invoke<AcknowledgeTripReminderResponse>(
          ctx,
          'TripsService',
          'AcknowledgeTripReminder',
          request,
          AcknowledgeTripReminderResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
