// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/storage.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// StorageType selects the physical storage medium.
class StorageType extends $pb.ProtobufEnum {
  static const StorageType STORAGE_TYPE_UNSPECIFIED =
      StorageType._(0, _omitEnumNames ? '' : 'STORAGE_TYPE_UNSPECIFIED');
  static const StorageType STORAGE_TYPE_INTERNAL =
      StorageType._(1, _omitEnumNames ? '' : 'STORAGE_TYPE_INTERNAL');
  static const StorageType STORAGE_TYPE_SD_CARD =
      StorageType._(2, _omitEnumNames ? '' : 'STORAGE_TYPE_SD_CARD');

  static const $core.List<StorageType> values = <StorageType>[
    STORAGE_TYPE_UNSPECIFIED,
    STORAGE_TYPE_INTERNAL,
    STORAGE_TYPE_SD_CARD,
  ];

  static final $core.List<StorageType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static StorageType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const StorageType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
