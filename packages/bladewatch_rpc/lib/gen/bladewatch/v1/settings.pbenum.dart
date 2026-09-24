// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/settings.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// RecordingQualityTier identifies a named recording quality preset.
class RecordingQualityTier extends $pb.ProtobufEnum {
  static const RecordingQualityTier RECORDING_QUALITY_TIER_UNSPECIFIED =
      RecordingQualityTier._(
          0, _omitEnumNames ? '' : 'RECORDING_QUALITY_TIER_UNSPECIFIED');
  static const RecordingQualityTier RECORDING_QUALITY_TIER_ECONOMY =
      RecordingQualityTier._(
          1, _omitEnumNames ? '' : 'RECORDING_QUALITY_TIER_ECONOMY');
  static const RecordingQualityTier RECORDING_QUALITY_TIER_STANDARD =
      RecordingQualityTier._(
          2, _omitEnumNames ? '' : 'RECORDING_QUALITY_TIER_STANDARD');
  static const RecordingQualityTier RECORDING_QUALITY_TIER_HIGH =
      RecordingQualityTier._(
          3, _omitEnumNames ? '' : 'RECORDING_QUALITY_TIER_HIGH');
  static const RecordingQualityTier RECORDING_QUALITY_TIER_PREMIUM =
      RecordingQualityTier._(
          4, _omitEnumNames ? '' : 'RECORDING_QUALITY_TIER_PREMIUM');
  static const RecordingQualityTier RECORDING_QUALITY_TIER_MAX =
      RecordingQualityTier._(
          5, _omitEnumNames ? '' : 'RECORDING_QUALITY_TIER_MAX');

  static const $core.List<RecordingQualityTier> values = <RecordingQualityTier>[
    RECORDING_QUALITY_TIER_UNSPECIFIED,
    RECORDING_QUALITY_TIER_ECONOMY,
    RECORDING_QUALITY_TIER_STANDARD,
    RECORDING_QUALITY_TIER_HIGH,
    RECORDING_QUALITY_TIER_PREMIUM,
    RECORDING_QUALITY_TIER_MAX,
  ];

  static final $core.List<RecordingQualityTier?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static RecordingQualityTier? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RecordingQualityTier._(super.value, super.name);
}

/// VideoCodec selects the encoding format.
class VideoCodec extends $pb.ProtobufEnum {
  static const VideoCodec VIDEO_CODEC_UNSPECIFIED =
      VideoCodec._(0, _omitEnumNames ? '' : 'VIDEO_CODEC_UNSPECIFIED');
  static const VideoCodec VIDEO_CODEC_H264 =
      VideoCodec._(1, _omitEnumNames ? '' : 'VIDEO_CODEC_H264');
  static const VideoCodec VIDEO_CODEC_H265 =
      VideoCodec._(2, _omitEnumNames ? '' : 'VIDEO_CODEC_H265');

  static const $core.List<VideoCodec> values = <VideoCodec>[
    VIDEO_CODEC_UNSPECIFIED,
    VIDEO_CODEC_H264,
    VIDEO_CODEC_H265,
  ];

  static final $core.List<VideoCodec?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static VideoCodec? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const VideoCodec._(super.value, super.name);
}

/// AppTheme selects the UI colour scheme.
class AppTheme extends $pb.ProtobufEnum {
  static const AppTheme APP_THEME_UNSPECIFIED =
      AppTheme._(0, _omitEnumNames ? '' : 'APP_THEME_UNSPECIFIED');
  static const AppTheme APP_THEME_DARK =
      AppTheme._(1, _omitEnumNames ? '' : 'APP_THEME_DARK');
  static const AppTheme APP_THEME_LIGHT =
      AppTheme._(2, _omitEnumNames ? '' : 'APP_THEME_LIGHT');
  static const AppTheme APP_THEME_AUTO =
      AppTheme._(3, _omitEnumNames ? '' : 'APP_THEME_AUTO');

  static const $core.List<AppTheme> values = <AppTheme>[
    APP_THEME_UNSPECIFIED,
    APP_THEME_DARK,
    APP_THEME_LIGHT,
    APP_THEME_AUTO,
  ];

  static final $core.List<AppTheme?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static AppTheme? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AppTheme._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
