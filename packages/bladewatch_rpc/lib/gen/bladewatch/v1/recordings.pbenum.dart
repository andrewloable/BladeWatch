// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/recordings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// RecordingType filters which recording category to list.
class RecordingType extends $pb.ProtobufEnum {
  static const RecordingType RECORDING_TYPE_UNSPECIFIED =
      RecordingType._(0, _omitEnumNames ? '' : 'RECORDING_TYPE_UNSPECIFIED');
  static const RecordingType RECORDING_TYPE_NORMAL =
      RecordingType._(1, _omitEnumNames ? '' : 'RECORDING_TYPE_NORMAL');
  static const RecordingType RECORDING_TYPE_SENTRY =
      RecordingType._(2, _omitEnumNames ? '' : 'RECORDING_TYPE_SENTRY');
  static const RecordingType RECORDING_TYPE_PROXIMITY =
      RecordingType._(3, _omitEnumNames ? '' : 'RECORDING_TYPE_PROXIMITY');

  static const $core.List<RecordingType> values = <RecordingType>[
    RECORDING_TYPE_UNSPECIFIED,
    RECORDING_TYPE_NORMAL,
    RECORDING_TYPE_SENTRY,
    RECORDING_TYPE_PROXIMITY,
  ];

  static final $core.List<RecordingType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static RecordingType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RecordingType._(super.value, super.name);
}

/// ClassFilter restricts results to specific AI detection classes.
class ClassFilter extends $pb.ProtobufEnum {
  static const ClassFilter CLASS_FILTER_UNSPECIFIED =
      ClassFilter._(0, _omitEnumNames ? '' : 'CLASS_FILTER_UNSPECIFIED');
  static const ClassFilter CLASS_FILTER_PERSON =
      ClassFilter._(1, _omitEnumNames ? '' : 'CLASS_FILTER_PERSON');
  static const ClassFilter CLASS_FILTER_VEHICLE =
      ClassFilter._(2, _omitEnumNames ? '' : 'CLASS_FILTER_VEHICLE');
  static const ClassFilter CLASS_FILTER_BIKE =
      ClassFilter._(3, _omitEnumNames ? '' : 'CLASS_FILTER_BIKE');

  static const $core.List<ClassFilter> values = <ClassFilter>[
    CLASS_FILTER_UNSPECIFIED,
    CLASS_FILTER_PERSON,
    CLASS_FILTER_VEHICLE,
    CLASS_FILTER_BIKE,
  ];

  static final $core.List<ClassFilter?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ClassFilter? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ClassFilter._(super.value, super.name);
}

/// SeverityFilter restricts sentry events by severity level.
class SeverityFilter extends $pb.ProtobufEnum {
  static const SeverityFilter SEVERITY_FILTER_UNSPECIFIED =
      SeverityFilter._(0, _omitEnumNames ? '' : 'SEVERITY_FILTER_UNSPECIFIED');
  static const SeverityFilter SEVERITY_FILTER_INFO =
      SeverityFilter._(1, _omitEnumNames ? '' : 'SEVERITY_FILTER_INFO');
  static const SeverityFilter SEVERITY_FILTER_ALERT =
      SeverityFilter._(2, _omitEnumNames ? '' : 'SEVERITY_FILTER_ALERT');
  static const SeverityFilter SEVERITY_FILTER_CRITICAL =
      SeverityFilter._(3, _omitEnumNames ? '' : 'SEVERITY_FILTER_CRITICAL');

  static const $core.List<SeverityFilter> values = <SeverityFilter>[
    SEVERITY_FILTER_UNSPECIFIED,
    SEVERITY_FILTER_INFO,
    SEVERITY_FILTER_ALERT,
    SEVERITY_FILTER_CRITICAL,
  ];

  static final $core.List<SeverityFilter?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static SeverityFilter? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SeverityFilter._(super.value, super.name);
}

/// ProximityFilter restricts proximity recordings by closeness band.
class ProximityFilter extends $pb.ProtobufEnum {
  static const ProximityFilter PROXIMITY_FILTER_UNSPECIFIED = ProximityFilter._(
      0, _omitEnumNames ? '' : 'PROXIMITY_FILTER_UNSPECIFIED');
  static const ProximityFilter PROXIMITY_FILTER_VERY_CLOSE =
      ProximityFilter._(1, _omitEnumNames ? '' : 'PROXIMITY_FILTER_VERY_CLOSE');
  static const ProximityFilter PROXIMITY_FILTER_CLOSE =
      ProximityFilter._(2, _omitEnumNames ? '' : 'PROXIMITY_FILTER_CLOSE');
  static const ProximityFilter PROXIMITY_FILTER_MEDIUM =
      ProximityFilter._(3, _omitEnumNames ? '' : 'PROXIMITY_FILTER_MEDIUM');

  static const $core.List<ProximityFilter> values = <ProximityFilter>[
    PROXIMITY_FILTER_UNSPECIFIED,
    PROXIMITY_FILTER_VERY_CLOSE,
    PROXIMITY_FILTER_CLOSE,
    PROXIMITY_FILTER_MEDIUM,
  ];

  static final $core.List<ProximityFilter?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static ProximityFilter? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ProximityFilter._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
