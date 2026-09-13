// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/stream.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// StreamingQuality identifies a named quality preset.
class StreamingQuality extends $pb.ProtobufEnum {
  static const StreamingQuality STREAMING_QUALITY_UNSPECIFIED =
      StreamingQuality._(
          0, _omitEnumNames ? '' : 'STREAMING_QUALITY_UNSPECIFIED');
  static const StreamingQuality STREAMING_QUALITY_ULTRA_LOW =
      StreamingQuality._(
          1, _omitEnumNames ? '' : 'STREAMING_QUALITY_ULTRA_LOW');
  static const StreamingQuality STREAMING_QUALITY_LOW =
      StreamingQuality._(2, _omitEnumNames ? '' : 'STREAMING_QUALITY_LOW');
  static const StreamingQuality STREAMING_QUALITY_MEDIUM =
      StreamingQuality._(3, _omitEnumNames ? '' : 'STREAMING_QUALITY_MEDIUM');
  static const StreamingQuality STREAMING_QUALITY_HIGH =
      StreamingQuality._(4, _omitEnumNames ? '' : 'STREAMING_QUALITY_HIGH');
  static const StreamingQuality STREAMING_QUALITY_ULTRA_HIGH =
      StreamingQuality._(
          5, _omitEnumNames ? '' : 'STREAMING_QUALITY_ULTRA_HIGH');
  static const StreamingQuality STREAMING_QUALITY_SMOOTH =
      StreamingQuality._(6, _omitEnumNames ? '' : 'STREAMING_QUALITY_SMOOTH');
  static const StreamingQuality STREAMING_QUALITY_MAX =
      StreamingQuality._(7, _omitEnumNames ? '' : 'STREAMING_QUALITY_MAX');

  static const $core.List<StreamingQuality> values = <StreamingQuality>[
    STREAMING_QUALITY_UNSPECIFIED,
    STREAMING_QUALITY_ULTRA_LOW,
    STREAMING_QUALITY_LOW,
    STREAMING_QUALITY_MEDIUM,
    STREAMING_QUALITY_HIGH,
    STREAMING_QUALITY_ULTRA_HIGH,
    STREAMING_QUALITY_SMOOTH,
    STREAMING_QUALITY_MAX,
  ];

  static final $core.List<StreamingQuality?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static StreamingQuality? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StreamingQuality._(super.value, super.name);
}

/// ViewMode selects which camera feed to show (0=Mosaic, 1=Front, 2=Right, 3=Rear, 4=Left, 5=Raw).
class ViewMode extends $pb.ProtobufEnum {
  static const ViewMode VIEW_MODE_MOSAIC =
      ViewMode._(0, _omitEnumNames ? '' : 'VIEW_MODE_MOSAIC');
  static const ViewMode VIEW_MODE_FRONT =
      ViewMode._(1, _omitEnumNames ? '' : 'VIEW_MODE_FRONT');
  static const ViewMode VIEW_MODE_RIGHT =
      ViewMode._(2, _omitEnumNames ? '' : 'VIEW_MODE_RIGHT');
  static const ViewMode VIEW_MODE_REAR =
      ViewMode._(3, _omitEnumNames ? '' : 'VIEW_MODE_REAR');
  static const ViewMode VIEW_MODE_LEFT =
      ViewMode._(4, _omitEnumNames ? '' : 'VIEW_MODE_LEFT');
  static const ViewMode VIEW_MODE_RAW =
      ViewMode._(5, _omitEnumNames ? '' : 'VIEW_MODE_RAW');

  static const $core.List<ViewMode> values = <ViewMode>[
    VIEW_MODE_MOSAIC,
    VIEW_MODE_FRONT,
    VIEW_MODE_RIGHT,
    VIEW_MODE_REAR,
    VIEW_MODE_LEFT,
    VIEW_MODE_RAW,
  ];

  static final $core.List<ViewMode?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ViewMode? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ViewMode._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
