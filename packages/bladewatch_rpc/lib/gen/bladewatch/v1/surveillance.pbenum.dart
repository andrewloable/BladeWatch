// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/surveillance.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// DistancePreset maps to the distance slider (1=near, 5=far).
class DistancePreset extends $pb.ProtobufEnum {
  static const DistancePreset DISTANCE_PRESET_UNSPECIFIED =
      DistancePreset._(0, _omitEnumNames ? '' : 'DISTANCE_PRESET_UNSPECIFIED');
  static const DistancePreset DISTANCE_PRESET_NEAR =
      DistancePreset._(1, _omitEnumNames ? '' : 'DISTANCE_PRESET_NEAR');
  static const DistancePreset DISTANCE_PRESET_SHORT =
      DistancePreset._(2, _omitEnumNames ? '' : 'DISTANCE_PRESET_SHORT');
  static const DistancePreset DISTANCE_PRESET_MEDIUM =
      DistancePreset._(3, _omitEnumNames ? '' : 'DISTANCE_PRESET_MEDIUM');
  static const DistancePreset DISTANCE_PRESET_LONG =
      DistancePreset._(4, _omitEnumNames ? '' : 'DISTANCE_PRESET_LONG');
  static const DistancePreset DISTANCE_PRESET_FAR =
      DistancePreset._(5, _omitEnumNames ? '' : 'DISTANCE_PRESET_FAR');

  static const $core.List<DistancePreset> values = <DistancePreset>[
    DISTANCE_PRESET_UNSPECIFIED,
    DISTANCE_PRESET_NEAR,
    DISTANCE_PRESET_SHORT,
    DISTANCE_PRESET_MEDIUM,
    DISTANCE_PRESET_LONG,
    DISTANCE_PRESET_FAR,
  ];

  static final $core.List<DistancePreset?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static DistancePreset? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const DistancePreset._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
