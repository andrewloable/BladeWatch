// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/stream.proto.

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

export 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pbenum.dart';

/// QualityOption describes one quality preset.
class QualityOption extends $pb.GeneratedMessage {
  factory QualityOption({
    $core.String? id,
    $core.String? name,
    $core.int? width,
    $core.int? height,
    $core.int? fps,
    $core.int? bitrate,
    $core.int? bitrateKbps,
  }) {
    final result = QualityOption._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (fps != null) result.fps = fps;
    if (bitrate != null) result.bitrate = bitrate;
    if (bitrateKbps != null) result.bitrateKbps = bitrateKbps;
    return result;
  }

  QualityOption._();

  factory QualityOption.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QualityOption()..mergeFromBuffer(data, registry);
  factory QualityOption.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QualityOption()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QualityOption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: QualityOption.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aI(3, _omitFieldNames ? '' : 'width')
    ..aI(4, _omitFieldNames ? '' : 'height')
    ..aI(5, _omitFieldNames ? '' : 'fps')
    ..aI(6, _omitFieldNames ? '' : 'bitrate')
    ..aI(7, _omitFieldNames ? '' : 'bitrateKbps')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QualityOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QualityOption copyWith(void Function(QualityOption) updates) =>
      super.copyWith((message) => updates(message as QualityOption))
          as QualityOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QualityOption() / QualityOption.new instead')
  static QualityOption create() => QualityOption._();
  static $pb.GeneratedMessage $_createMessage() => QualityOption._();
  @$core.override
  QualityOption createEmptyInstance() => QualityOption._();
  @$core.pragma('dart2js:noInline')
  static QualityOption getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QualityOption>(
          QualityOption.$_createMessage);
  static QualityOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
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
  $core.int get width => $_getIZ(2);
  @$pb.TagNumber(3)
  set width($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWidth() => $_has(2);
  @$pb.TagNumber(3)
  void clearWidth() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get height => $_getIZ(3);
  @$pb.TagNumber(4)
  set height($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHeight() => $_has(3);
  @$pb.TagNumber(4)
  void clearHeight() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get fps => $_getIZ(4);
  @$pb.TagNumber(5)
  set fps($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFps() => $_has(4);
  @$pb.TagNumber(5)
  void clearFps() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get bitrate => $_getIZ(5);
  @$pb.TagNumber(6)
  set bitrate($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBitrate() => $_has(5);
  @$pb.TagNumber(6)
  void clearBitrate() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get bitrateKbps => $_getIZ(6);
  @$pb.TagNumber(7)
  set bitrateKbps($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBitrateKbps() => $_has(6);
  @$pb.TagNumber(7)
  void clearBitrateKbps() => $_clearField(7);
}

class EnableStreamRequest extends $pb.GeneratedMessage {
  factory EnableStreamRequest() => EnableStreamRequest._();

  EnableStreamRequest._();

  factory EnableStreamRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableStreamRequest()..mergeFromBuffer(data, registry);
  factory EnableStreamRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableStreamRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnableStreamRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: EnableStreamRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableStreamRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableStreamRequest copyWith(void Function(EnableStreamRequest) updates) =>
      super.copyWith((message) => updates(message as EnableStreamRequest))
          as EnableStreamRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use EnableStreamRequest() / EnableStreamRequest.new instead')
  static EnableStreamRequest create() => EnableStreamRequest._();
  static $pb.GeneratedMessage $_createMessage() => EnableStreamRequest._();
  @$core.override
  EnableStreamRequest createEmptyInstance() => EnableStreamRequest._();
  @$core.pragma('dart2js:noInline')
  static EnableStreamRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnableStreamRequest>(
          EnableStreamRequest.$_createMessage);
  static EnableStreamRequest? _defaultInstance;
}

class EnableStreamResponse extends $pb.GeneratedMessage {
  factory EnableStreamResponse({
    $core.bool? success,
    $core.String? message,
    $core.int? wsPort,
    $core.String? quality,
    $core.String? resolution,
    $core.int? fps,
    $core.int? bitrate,
    $core.String? error,
  }) {
    final result = EnableStreamResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (wsPort != null) result.wsPort = wsPort;
    if (quality != null) result.quality = quality;
    if (resolution != null) result.resolution = resolution;
    if (fps != null) result.fps = fps;
    if (bitrate != null) result.bitrate = bitrate;
    if (error != null) result.error = error;
    return result;
  }

  EnableStreamResponse._();

  factory EnableStreamResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableStreamResponse()..mergeFromBuffer(data, registry);
  factory EnableStreamResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EnableStreamResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EnableStreamResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: EnableStreamResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aI(3, _omitFieldNames ? '' : 'wsPort')
    ..aOS(4, _omitFieldNames ? '' : 'quality')
    ..aOS(5, _omitFieldNames ? '' : 'resolution')
    ..aI(6, _omitFieldNames ? '' : 'fps')
    ..aI(7, _omitFieldNames ? '' : 'bitrate')
    ..aOS(8, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableStreamResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EnableStreamResponse copyWith(void Function(EnableStreamResponse) updates) =>
      super.copyWith((message) => updates(message as EnableStreamResponse))
          as EnableStreamResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use EnableStreamResponse() / EnableStreamResponse.new instead')
  static EnableStreamResponse create() => EnableStreamResponse._();
  static $pb.GeneratedMessage $_createMessage() => EnableStreamResponse._();
  @$core.override
  EnableStreamResponse createEmptyInstance() => EnableStreamResponse._();
  @$core.pragma('dart2js:noInline')
  static EnableStreamResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EnableStreamResponse>(
          EnableStreamResponse.$_createMessage);
  static EnableStreamResponse? _defaultInstance;

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
  $core.int get wsPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set wsPort($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWsPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearWsPort() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get quality => $_getSZ(3);
  @$pb.TagNumber(4)
  set quality($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasQuality() => $_has(3);
  @$pb.TagNumber(4)
  void clearQuality() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get resolution => $_getSZ(4);
  @$pb.TagNumber(5)
  set resolution($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasResolution() => $_has(4);
  @$pb.TagNumber(5)
  void clearResolution() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get fps => $_getIZ(5);
  @$pb.TagNumber(6)
  set fps($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFps() => $_has(5);
  @$pb.TagNumber(6)
  void clearFps() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get bitrate => $_getIZ(6);
  @$pb.TagNumber(7)
  set bitrate($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBitrate() => $_has(6);
  @$pb.TagNumber(7)
  void clearBitrate() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get error => $_getSZ(7);
  @$pb.TagNumber(8)
  set error($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasError() => $_has(7);
  @$pb.TagNumber(8)
  void clearError() => $_clearField(8);
}

class DisableStreamRequest extends $pb.GeneratedMessage {
  factory DisableStreamRequest() => DisableStreamRequest._();

  DisableStreamRequest._();

  factory DisableStreamRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableStreamRequest()..mergeFromBuffer(data, registry);
  factory DisableStreamRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableStreamRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableStreamRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DisableStreamRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableStreamRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableStreamRequest copyWith(void Function(DisableStreamRequest) updates) =>
      super.copyWith((message) => updates(message as DisableStreamRequest))
          as DisableStreamRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DisableStreamRequest() / DisableStreamRequest.new instead')
  static DisableStreamRequest create() => DisableStreamRequest._();
  static $pb.GeneratedMessage $_createMessage() => DisableStreamRequest._();
  @$core.override
  DisableStreamRequest createEmptyInstance() => DisableStreamRequest._();
  @$core.pragma('dart2js:noInline')
  static DisableStreamRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableStreamRequest>(
          DisableStreamRequest.$_createMessage);
  static DisableStreamRequest? _defaultInstance;
}

class DisableStreamResponse extends $pb.GeneratedMessage {
  factory DisableStreamResponse({
    $core.bool? success,
    $core.String? message,
  }) {
    final result = DisableStreamResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    return result;
  }

  DisableStreamResponse._();

  factory DisableStreamResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableStreamResponse()..mergeFromBuffer(data, registry);
  factory DisableStreamResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisableStreamResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisableStreamResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DisableStreamResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableStreamResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisableStreamResponse copyWith(
          void Function(DisableStreamResponse) updates) =>
      super.copyWith((message) => updates(message as DisableStreamResponse))
          as DisableStreamResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DisableStreamResponse() / DisableStreamResponse.new instead')
  static DisableStreamResponse create() => DisableStreamResponse._();
  static $pb.GeneratedMessage $_createMessage() => DisableStreamResponse._();
  @$core.override
  DisableStreamResponse createEmptyInstance() => DisableStreamResponse._();
  @$core.pragma('dart2js:noInline')
  static DisableStreamResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisableStreamResponse>(
          DisableStreamResponse.$_createMessage);
  static DisableStreamResponse? _defaultInstance;

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

class GetStreamStatusRequest extends $pb.GeneratedMessage {
  factory GetStreamStatusRequest() => GetStreamStatusRequest._();

  GetStreamStatusRequest._();

  factory GetStreamStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamStatusRequest()..mergeFromBuffer(data, registry);
  factory GetStreamStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStreamStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStreamStatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamStatusRequest copyWith(
          void Function(GetStreamStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetStreamStatusRequest))
          as GetStreamStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetStreamStatusRequest() / GetStreamStatusRequest.new instead')
  static GetStreamStatusRequest create() => GetStreamStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStreamStatusRequest._();
  @$core.override
  GetStreamStatusRequest createEmptyInstance() => GetStreamStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStreamStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStreamStatusRequest>(
          GetStreamStatusRequest.$_createMessage);
  static GetStreamStatusRequest? _defaultInstance;
}

class GetStreamStatusResponse extends $pb.GeneratedMessage {
  factory GetStreamStatusResponse({
    $core.bool? pipelineRunning,
    $core.bool? streamingEnabled,
    $core.int? wsPort,
    $core.int? viewMode,
    $core.String? viewName,
  }) {
    final result = GetStreamStatusResponse._();
    if (pipelineRunning != null) result.pipelineRunning = pipelineRunning;
    if (streamingEnabled != null) result.streamingEnabled = streamingEnabled;
    if (wsPort != null) result.wsPort = wsPort;
    if (viewMode != null) result.viewMode = viewMode;
    if (viewName != null) result.viewName = viewName;
    return result;
  }

  GetStreamStatusResponse._();

  factory GetStreamStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamStatusResponse()..mergeFromBuffer(data, registry);
  factory GetStreamStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStreamStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStreamStatusResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'pipelineRunning')
    ..aOB(2, _omitFieldNames ? '' : 'streamingEnabled')
    ..aI(3, _omitFieldNames ? '' : 'wsPort')
    ..aI(4, _omitFieldNames ? '' : 'viewMode')
    ..aOS(5, _omitFieldNames ? '' : 'viewName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamStatusResponse copyWith(
          void Function(GetStreamStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetStreamStatusResponse))
          as GetStreamStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetStreamStatusResponse() / GetStreamStatusResponse.new instead')
  static GetStreamStatusResponse create() => GetStreamStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetStreamStatusResponse._();
  @$core.override
  GetStreamStatusResponse createEmptyInstance() => GetStreamStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStreamStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStreamStatusResponse>(
          GetStreamStatusResponse.$_createMessage);
  static GetStreamStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get pipelineRunning => $_getBF(0);
  @$pb.TagNumber(1)
  set pipelineRunning($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPipelineRunning() => $_has(0);
  @$pb.TagNumber(1)
  void clearPipelineRunning() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get streamingEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set streamingEnabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStreamingEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearStreamingEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get wsPort => $_getIZ(2);
  @$pb.TagNumber(3)
  set wsPort($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasWsPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearWsPort() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get viewMode => $_getIZ(3);
  @$pb.TagNumber(4)
  set viewMode($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasViewMode() => $_has(3);
  @$pb.TagNumber(4)
  void clearViewMode() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get viewName => $_getSZ(4);
  @$pb.TagNumber(5)
  set viewName($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasViewName() => $_has(4);
  @$pb.TagNumber(5)
  void clearViewName() => $_clearField(5);
}

class GetStreamQualityRequest extends $pb.GeneratedMessage {
  factory GetStreamQualityRequest() => GetStreamQualityRequest._();

  GetStreamQualityRequest._();

  factory GetStreamQualityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamQualityRequest()..mergeFromBuffer(data, registry);
  factory GetStreamQualityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamQualityRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStreamQualityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStreamQualityRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamQualityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamQualityRequest copyWith(
          void Function(GetStreamQualityRequest) updates) =>
      super.copyWith((message) => updates(message as GetStreamQualityRequest))
          as GetStreamQualityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetStreamQualityRequest() / GetStreamQualityRequest.new instead')
  static GetStreamQualityRequest create() => GetStreamQualityRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStreamQualityRequest._();
  @$core.override
  GetStreamQualityRequest createEmptyInstance() => GetStreamQualityRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStreamQualityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStreamQualityRequest>(
          GetStreamQualityRequest.$_createMessage);
  static GetStreamQualityRequest? _defaultInstance;
}

class GetStreamQualityResponse extends $pb.GeneratedMessage {
  factory GetStreamQualityResponse({
    $core.bool? success,
    $core.String? current,
    $core.Iterable<QualityOption>? options,
  }) {
    final result = GetStreamQualityResponse._();
    if (success != null) result.success = success;
    if (current != null) result.current = current;
    if (options != null) result.options.addAll(options);
    return result;
  }

  GetStreamQualityResponse._();

  factory GetStreamQualityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamQualityResponse()..mergeFromBuffer(data, registry);
  factory GetStreamQualityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStreamQualityResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStreamQualityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStreamQualityResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'current')
    ..pPM<QualityOption>(3, _omitFieldNames ? '' : 'options',
        subBuilder: QualityOption.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamQualityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStreamQualityResponse copyWith(
          void Function(GetStreamQualityResponse) updates) =>
      super.copyWith((message) => updates(message as GetStreamQualityResponse))
          as GetStreamQualityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetStreamQualityResponse() / GetStreamQualityResponse.new instead')
  static GetStreamQualityResponse create() => GetStreamQualityResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetStreamQualityResponse._();
  @$core.override
  GetStreamQualityResponse createEmptyInstance() =>
      GetStreamQualityResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStreamQualityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStreamQualityResponse>(
          GetStreamQualityResponse.$_createMessage);
  static GetStreamQualityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get current => $_getSZ(1);
  @$pb.TagNumber(2)
  set current($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrent() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrent() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<QualityOption> get options => $_getList(2);
}

class SetStreamQualityRequest extends $pb.GeneratedMessage {
  factory SetStreamQualityRequest({
    $core.String? quality,
  }) {
    final result = SetStreamQualityRequest._();
    if (quality != null) result.quality = quality;
    return result;
  }

  SetStreamQualityRequest._();

  factory SetStreamQualityRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStreamQualityRequest()..mergeFromBuffer(data, registry);
  factory SetStreamQualityRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStreamQualityRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetStreamQualityRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetStreamQualityRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'quality')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStreamQualityRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStreamQualityRequest copyWith(
          void Function(SetStreamQualityRequest) updates) =>
      super.copyWith((message) => updates(message as SetStreamQualityRequest))
          as SetStreamQualityRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetStreamQualityRequest() / SetStreamQualityRequest.new instead')
  static SetStreamQualityRequest create() => SetStreamQualityRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetStreamQualityRequest._();
  @$core.override
  SetStreamQualityRequest createEmptyInstance() => SetStreamQualityRequest._();
  @$core.pragma('dart2js:noInline')
  static SetStreamQualityRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetStreamQualityRequest>(
          SetStreamQualityRequest.$_createMessage);
  static SetStreamQualityRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get quality => $_getSZ(0);
  @$pb.TagNumber(1)
  set quality($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuality() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuality() => $_clearField(1);
}

class SetStreamQualityResponse extends $pb.GeneratedMessage {
  factory SetStreamQualityResponse({
    $core.bool? success,
    $core.String? quality,
    $core.String? displayName,
    $core.int? width,
    $core.int? height,
    $core.int? fps,
    $core.int? bitrate,
  }) {
    final result = SetStreamQualityResponse._();
    if (success != null) result.success = success;
    if (quality != null) result.quality = quality;
    if (displayName != null) result.displayName = displayName;
    if (width != null) result.width = width;
    if (height != null) result.height = height;
    if (fps != null) result.fps = fps;
    if (bitrate != null) result.bitrate = bitrate;
    return result;
  }

  SetStreamQualityResponse._();

  factory SetStreamQualityResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStreamQualityResponse()..mergeFromBuffer(data, registry);
  factory SetStreamQualityResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStreamQualityResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetStreamQualityResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetStreamQualityResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'quality')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aI(4, _omitFieldNames ? '' : 'width')
    ..aI(5, _omitFieldNames ? '' : 'height')
    ..aI(6, _omitFieldNames ? '' : 'fps')
    ..aI(7, _omitFieldNames ? '' : 'bitrate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStreamQualityResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStreamQualityResponse copyWith(
          void Function(SetStreamQualityResponse) updates) =>
      super.copyWith((message) => updates(message as SetStreamQualityResponse))
          as SetStreamQualityResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetStreamQualityResponse() / SetStreamQualityResponse.new instead')
  static SetStreamQualityResponse create() => SetStreamQualityResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetStreamQualityResponse._();
  @$core.override
  SetStreamQualityResponse createEmptyInstance() =>
      SetStreamQualityResponse._();
  @$core.pragma('dart2js:noInline')
  static SetStreamQualityResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetStreamQualityResponse>(
          SetStreamQualityResponse.$_createMessage);
  static SetStreamQualityResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get quality => $_getSZ(1);
  @$pb.TagNumber(2)
  set quality($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasQuality() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuality() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get width => $_getIZ(3);
  @$pb.TagNumber(4)
  set width($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWidth() => $_has(3);
  @$pb.TagNumber(4)
  void clearWidth() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get height => $_getIZ(4);
  @$pb.TagNumber(5)
  set height($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHeight() => $_has(4);
  @$pb.TagNumber(5)
  void clearHeight() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get fps => $_getIZ(5);
  @$pb.TagNumber(6)
  set fps($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFps() => $_has(5);
  @$pb.TagNumber(6)
  void clearFps() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get bitrate => $_getIZ(6);
  @$pb.TagNumber(7)
  set bitrate($core.int value) => $_setSignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasBitrate() => $_has(6);
  @$pb.TagNumber(7)
  void clearBitrate() => $_clearField(7);
}

class SetViewModeRequest extends $pb.GeneratedMessage {
  factory SetViewModeRequest({
    $core.int? viewMode,
  }) {
    final result = SetViewModeRequest._();
    if (viewMode != null) result.viewMode = viewMode;
    return result;
  }

  SetViewModeRequest._();

  factory SetViewModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetViewModeRequest()..mergeFromBuffer(data, registry);
  factory SetViewModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetViewModeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetViewModeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetViewModeRequest.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'viewMode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetViewModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetViewModeRequest copyWith(void Function(SetViewModeRequest) updates) =>
      super.copyWith((message) => updates(message as SetViewModeRequest))
          as SetViewModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetViewModeRequest() / SetViewModeRequest.new instead')
  static SetViewModeRequest create() => SetViewModeRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetViewModeRequest._();
  @$core.override
  SetViewModeRequest createEmptyInstance() => SetViewModeRequest._();
  @$core.pragma('dart2js:noInline')
  static SetViewModeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetViewModeRequest>(
          SetViewModeRequest.$_createMessage);
  static SetViewModeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get viewMode => $_getIZ(0);
  @$pb.TagNumber(1)
  set viewMode($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasViewMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearViewMode() => $_clearField(1);
}

class SetViewModeResponse extends $pb.GeneratedMessage {
  factory SetViewModeResponse({
    $core.bool? success,
    $core.int? viewMode,
    $core.String? viewName,
    $core.String? error,
  }) {
    final result = SetViewModeResponse._();
    if (success != null) result.success = success;
    if (viewMode != null) result.viewMode = viewMode;
    if (viewName != null) result.viewName = viewName;
    if (error != null) result.error = error;
    return result;
  }

  SetViewModeResponse._();

  factory SetViewModeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetViewModeResponse()..mergeFromBuffer(data, registry);
  factory SetViewModeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetViewModeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetViewModeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetViewModeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aI(2, _omitFieldNames ? '' : 'viewMode')
    ..aOS(3, _omitFieldNames ? '' : 'viewName')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetViewModeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetViewModeResponse copyWith(void Function(SetViewModeResponse) updates) =>
      super.copyWith((message) => updates(message as SetViewModeResponse))
          as SetViewModeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SetViewModeResponse() / SetViewModeResponse.new instead')
  static SetViewModeResponse create() => SetViewModeResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetViewModeResponse._();
  @$core.override
  SetViewModeResponse createEmptyInstance() => SetViewModeResponse._();
  @$core.pragma('dart2js:noInline')
  static SetViewModeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetViewModeResponse>(
          SetViewModeResponse.$_createMessage);
  static SetViewModeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get viewMode => $_getIZ(1);
  @$pb.TagNumber(2)
  set viewMode($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasViewMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearViewMode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get viewName => $_getSZ(2);
  @$pb.TagNumber(3)
  set viewName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasViewName() => $_has(2);
  @$pb.TagNumber(3)
  void clearViewName() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
}

class GetViewModeRequest extends $pb.GeneratedMessage {
  factory GetViewModeRequest() => GetViewModeRequest._();

  GetViewModeRequest._();

  factory GetViewModeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetViewModeRequest()..mergeFromBuffer(data, registry);
  factory GetViewModeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetViewModeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetViewModeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetViewModeRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetViewModeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetViewModeRequest copyWith(void Function(GetViewModeRequest) updates) =>
      super.copyWith((message) => updates(message as GetViewModeRequest))
          as GetViewModeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetViewModeRequest() / GetViewModeRequest.new instead')
  static GetViewModeRequest create() => GetViewModeRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetViewModeRequest._();
  @$core.override
  GetViewModeRequest createEmptyInstance() => GetViewModeRequest._();
  @$core.pragma('dart2js:noInline')
  static GetViewModeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetViewModeRequest>(
          GetViewModeRequest.$_createMessage);
  static GetViewModeRequest? _defaultInstance;
}

class GetViewModeResponse extends $pb.GeneratedMessage {
  factory GetViewModeResponse({
    $core.bool? success,
    $core.int? viewMode,
    $core.String? viewName,
  }) {
    final result = GetViewModeResponse._();
    if (success != null) result.success = success;
    if (viewMode != null) result.viewMode = viewMode;
    if (viewName != null) result.viewName = viewName;
    return result;
  }

  GetViewModeResponse._();

  factory GetViewModeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetViewModeResponse()..mergeFromBuffer(data, registry);
  factory GetViewModeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetViewModeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetViewModeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetViewModeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aI(2, _omitFieldNames ? '' : 'viewMode')
    ..aOS(3, _omitFieldNames ? '' : 'viewName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetViewModeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetViewModeResponse copyWith(void Function(GetViewModeResponse) updates) =>
      super.copyWith((message) => updates(message as GetViewModeResponse))
          as GetViewModeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use GetViewModeResponse() / GetViewModeResponse.new instead')
  static GetViewModeResponse create() => GetViewModeResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetViewModeResponse._();
  @$core.override
  GetViewModeResponse createEmptyInstance() => GetViewModeResponse._();
  @$core.pragma('dart2js:noInline')
  static GetViewModeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetViewModeResponse>(
          GetViewModeResponse.$_createMessage);
  static GetViewModeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get viewMode => $_getIZ(1);
  @$pb.TagNumber(2)
  set viewMode($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasViewMode() => $_has(1);
  @$pb.TagNumber(2)
  void clearViewMode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get viewName => $_getSZ(2);
  @$pb.TagNumber(3)
  set viewName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasViewName() => $_has(2);
  @$pb.TagNumber(3)
  void clearViewName() => $_clearField(3);
}

/// StreamService controls the WebSocket live-view stream on port 8887.
///
/// HTTP mapping:
///   Enable           POST /api/stream/enable
///   Disable          POST /api/stream/disable
///   GetStatus        GET  /api/stream/status
///   GetQuality       GET  /api/stream/quality
///   SetQuality       POST /api/stream/quality/{preset}
///   SetViewMode      POST /api/stream/view/{mode}
///   GetViewMode      GET  /api/stream/view
class StreamServiceApi {
  final $pb.RpcClient _client;

  StreamServiceApi(this._client);

  $async.Future<EnableStreamResponse> enable(
          $pb.ClientContext? ctx, EnableStreamRequest request) =>
      _client.invoke<EnableStreamResponse>(
          ctx, 'StreamService', 'Enable', request, EnableStreamResponse());
  $async.Future<DisableStreamResponse> disable(
          $pb.ClientContext? ctx, DisableStreamRequest request) =>
      _client.invoke<DisableStreamResponse>(
          ctx, 'StreamService', 'Disable', request, DisableStreamResponse());
  $async.Future<GetStreamStatusResponse> getStatus(
          $pb.ClientContext? ctx, GetStreamStatusRequest request) =>
      _client.invoke<GetStreamStatusResponse>(ctx, 'StreamService', 'GetStatus',
          request, GetStreamStatusResponse());
  $async.Future<GetStreamQualityResponse> getQuality(
          $pb.ClientContext? ctx, GetStreamQualityRequest request) =>
      _client.invoke<GetStreamQualityResponse>(ctx, 'StreamService',
          'GetQuality', request, GetStreamQualityResponse());
  $async.Future<SetStreamQualityResponse> setQuality(
          $pb.ClientContext? ctx, SetStreamQualityRequest request) =>
      _client.invoke<SetStreamQualityResponse>(ctx, 'StreamService',
          'SetQuality', request, SetStreamQualityResponse());
  $async.Future<SetViewModeResponse> setViewMode(
          $pb.ClientContext? ctx, SetViewModeRequest request) =>
      _client.invoke<SetViewModeResponse>(
          ctx, 'StreamService', 'SetViewMode', request, SetViewModeResponse());
  $async.Future<GetViewModeResponse> getViewMode(
          $pb.ClientContext? ctx, GetViewModeRequest request) =>
      _client.invoke<GetViewModeResponse>(
          ctx, 'StreamService', 'GetViewMode', request, GetViewModeResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
