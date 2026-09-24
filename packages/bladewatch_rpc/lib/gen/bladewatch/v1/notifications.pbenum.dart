// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/notifications.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// NotificationSeverity mirrors NotificationEvent.Severity.
class NotificationSeverity extends $pb.ProtobufEnum {
  static const NotificationSeverity NOTIFICATION_SEVERITY_UNSPECIFIED =
      NotificationSeverity._(
          0, _omitEnumNames ? '' : 'NOTIFICATION_SEVERITY_UNSPECIFIED');
  static const NotificationSeverity NOTIFICATION_SEVERITY_INFO =
      NotificationSeverity._(
          1, _omitEnumNames ? '' : 'NOTIFICATION_SEVERITY_INFO');
  static const NotificationSeverity NOTIFICATION_SEVERITY_ALERT =
      NotificationSeverity._(
          2, _omitEnumNames ? '' : 'NOTIFICATION_SEVERITY_ALERT');
  static const NotificationSeverity NOTIFICATION_SEVERITY_CRITICAL =
      NotificationSeverity._(
          3, _omitEnumNames ? '' : 'NOTIFICATION_SEVERITY_CRITICAL');

  static const $core.List<NotificationSeverity> values = <NotificationSeverity>[
    NOTIFICATION_SEVERITY_UNSPECIFIED,
    NOTIFICATION_SEVERITY_INFO,
    NOTIFICATION_SEVERITY_ALERT,
    NOTIFICATION_SEVERITY_CRITICAL,
  ];

  static final $core.List<NotificationSeverity?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static NotificationSeverity? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const NotificationSeverity._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
