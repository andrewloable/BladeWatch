// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/storage.proto.

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

export 'storage.pbenum.dart';

/// VolumeInfo describes one removable public volume visible to StorageManager.
class VolumeInfo extends $pb.GeneratedMessage {
  factory VolumeInfo({
    $core.String? volumeId,
    $core.String? uuid,
    $core.bool? mounted,
    $core.String? mountPath,
  }) {
    final result = VolumeInfo._();
    if (volumeId != null) result.volumeId = volumeId;
    if (uuid != null) result.uuid = uuid;
    if (mounted != null) result.mounted = mounted;
    if (mountPath != null) result.mountPath = mountPath;
    return result;
  }

  VolumeInfo._();

  factory VolumeInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeInfo()..mergeFromBuffer(data, registry);
  factory VolumeInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      VolumeInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'VolumeInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: VolumeInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'volumeId')
    ..aOS(2, _omitFieldNames ? '' : 'uuid')
    ..aOB(3, _omitFieldNames ? '' : 'mounted')
    ..aOS(4, _omitFieldNames ? '' : 'mountPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VolumeInfo copyWith(void Function(VolumeInfo) updates) =>
      super.copyWith((message) => updates(message as VolumeInfo)) as VolumeInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use VolumeInfo() / VolumeInfo.new instead')
  static VolumeInfo create() => VolumeInfo._();
  static $pb.GeneratedMessage $_createMessage() => VolumeInfo._();
  @$core.override
  VolumeInfo createEmptyInstance() => VolumeInfo._();
  @$core.pragma('dart2js:noInline')
  static VolumeInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<VolumeInfo>(VolumeInfo.$_createMessage);
  static VolumeInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get volumeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set volumeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVolumeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVolumeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get uuid => $_getSZ(1);
  @$pb.TagNumber(2)
  set uuid($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUuid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUuid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get mounted => $_getBF(2);
  @$pb.TagNumber(3)
  set mounted($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMounted() => $_has(2);
  @$pb.TagNumber(3)
  void clearMounted() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get mountPath => $_getSZ(3);
  @$pb.TagNumber(4)
  set mountPath($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMountPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearMountPath() => $_clearField(4);
}

class GetStorageSettingsRequest extends $pb.GeneratedMessage {
  factory GetStorageSettingsRequest() => GetStorageSettingsRequest._();

  GetStorageSettingsRequest._();

  factory GetStorageSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageSettingsRequest()..mergeFromBuffer(data, registry);
  factory GetStorageSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageSettingsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStorageSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStorageSettingsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageSettingsRequest copyWith(
          void Function(GetStorageSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as GetStorageSettingsRequest))
          as GetStorageSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetStorageSettingsRequest() / GetStorageSettingsRequest.new instead')
  static GetStorageSettingsRequest create() => GetStorageSettingsRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetStorageSettingsRequest._();
  @$core.override
  GetStorageSettingsRequest createEmptyInstance() =>
      GetStorageSettingsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStorageSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStorageSettingsRequest>(
          GetStorageSettingsRequest.$_createMessage);
  static GetStorageSettingsRequest? _defaultInstance;
}

class GetStorageSettingsResponse extends $pb.GeneratedMessage {
  factory GetStorageSettingsResponse({
    $core.bool? success,
    $fixnum.Int64? recordingsLimitMb,
    $fixnum.Int64? surveillanceLimitMb,
    $fixnum.Int64? minLimitMb,
    $fixnum.Int64? maxLimitMb,
    $fixnum.Int64? maxLimitMbSdCard,
    $core.String? recordingsPath,
    $core.String? surveillancePath,
    $fixnum.Int64? recordingsSizeBytes,
    $fixnum.Int64? surveillanceSizeBytes,
    $core.int? recordingsCount,
    $core.int? surveillanceCount,
    $core.String? recordingsStorageType,
    $core.String? surveillanceStorageType,
    $core.bool? sdCardAvailable,
    $core.String? sdCardPath,
    $fixnum.Int64? sdCardFreeBytes,
    $fixnum.Int64? sdCardTotalBytes,
    $core.String? sdCardFreeFormatted,
    $core.String? sdCardTotalFormatted,
    $fixnum.Int64? internalFreeBytes,
    $fixnum.Int64? internalTotalBytes,
    $core.String? internalFreeFormatted,
    $core.String? internalTotalFormatted,
    $core.bool? sdCardMountFailed,
    $core.String? sdCardMountError,
  }) {
    final result = GetStorageSettingsResponse._();
    if (success != null) result.success = success;
    if (recordingsLimitMb != null) result.recordingsLimitMb = recordingsLimitMb;
    if (surveillanceLimitMb != null)
      result.surveillanceLimitMb = surveillanceLimitMb;
    if (minLimitMb != null) result.minLimitMb = minLimitMb;
    if (maxLimitMb != null) result.maxLimitMb = maxLimitMb;
    if (maxLimitMbSdCard != null) result.maxLimitMbSdCard = maxLimitMbSdCard;
    if (recordingsPath != null) result.recordingsPath = recordingsPath;
    if (surveillancePath != null) result.surveillancePath = surveillancePath;
    if (recordingsSizeBytes != null)
      result.recordingsSizeBytes = recordingsSizeBytes;
    if (surveillanceSizeBytes != null)
      result.surveillanceSizeBytes = surveillanceSizeBytes;
    if (recordingsCount != null) result.recordingsCount = recordingsCount;
    if (surveillanceCount != null) result.surveillanceCount = surveillanceCount;
    if (recordingsStorageType != null)
      result.recordingsStorageType = recordingsStorageType;
    if (surveillanceStorageType != null)
      result.surveillanceStorageType = surveillanceStorageType;
    if (sdCardAvailable != null) result.sdCardAvailable = sdCardAvailable;
    if (sdCardPath != null) result.sdCardPath = sdCardPath;
    if (sdCardFreeBytes != null) result.sdCardFreeBytes = sdCardFreeBytes;
    if (sdCardTotalBytes != null) result.sdCardTotalBytes = sdCardTotalBytes;
    if (sdCardFreeFormatted != null)
      result.sdCardFreeFormatted = sdCardFreeFormatted;
    if (sdCardTotalFormatted != null)
      result.sdCardTotalFormatted = sdCardTotalFormatted;
    if (internalFreeBytes != null) result.internalFreeBytes = internalFreeBytes;
    if (internalTotalBytes != null)
      result.internalTotalBytes = internalTotalBytes;
    if (internalFreeFormatted != null)
      result.internalFreeFormatted = internalFreeFormatted;
    if (internalTotalFormatted != null)
      result.internalTotalFormatted = internalTotalFormatted;
    if (sdCardMountFailed != null) result.sdCardMountFailed = sdCardMountFailed;
    if (sdCardMountError != null) result.sdCardMountError = sdCardMountError;
    return result;
  }

  GetStorageSettingsResponse._();

  factory GetStorageSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageSettingsResponse()..mergeFromBuffer(data, registry);
  factory GetStorageSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStorageSettingsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStorageSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStorageSettingsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aInt64(2, _omitFieldNames ? '' : 'recordingsLimitMb')
    ..aInt64(3, _omitFieldNames ? '' : 'surveillanceLimitMb')
    ..aInt64(4, _omitFieldNames ? '' : 'minLimitMb')
    ..aInt64(5, _omitFieldNames ? '' : 'maxLimitMb')
    ..aInt64(6, _omitFieldNames ? '' : 'maxLimitMbSdCard')
    ..aOS(7, _omitFieldNames ? '' : 'recordingsPath')
    ..aOS(8, _omitFieldNames ? '' : 'surveillancePath')
    ..aInt64(9, _omitFieldNames ? '' : 'recordingsSize',
        protoName: 'recordings_size_bytes')
    ..aInt64(10, _omitFieldNames ? '' : 'surveillanceSize',
        protoName: 'surveillance_size_bytes')
    ..aI(11, _omitFieldNames ? '' : 'recordingsCount')
    ..aI(12, _omitFieldNames ? '' : 'surveillanceCount')
    ..aOS(13, _omitFieldNames ? '' : 'recordingsStorageType')
    ..aOS(14, _omitFieldNames ? '' : 'surveillanceStorageType')
    ..aOB(15, _omitFieldNames ? '' : 'sdCardAvailable')
    ..aOS(16, _omitFieldNames ? '' : 'sdCardPath')
    ..aInt64(17, _omitFieldNames ? '' : 'sdCardFreeSpace',
        protoName: 'sd_card_free_bytes')
    ..aInt64(18, _omitFieldNames ? '' : 'sdCardTotalSpace',
        protoName: 'sd_card_total_bytes')
    ..aOS(19, _omitFieldNames ? '' : 'sdCardFreeFormatted')
    ..aOS(20, _omitFieldNames ? '' : 'sdCardTotalFormatted')
    ..aInt64(21, _omitFieldNames ? '' : 'internalFreeSpace',
        protoName: 'internal_free_bytes')
    ..aInt64(22, _omitFieldNames ? '' : 'internalTotalSpace',
        protoName: 'internal_total_bytes')
    ..aOS(23, _omitFieldNames ? '' : 'internalFreeFormatted')
    ..aOS(24, _omitFieldNames ? '' : 'internalTotalFormatted')
    ..aOB(25, _omitFieldNames ? '' : 'sdCardMountFailed')
    ..aOS(26, _omitFieldNames ? '' : 'sdCardMountError')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStorageSettingsResponse copyWith(
          void Function(GetStorageSettingsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetStorageSettingsResponse))
          as GetStorageSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetStorageSettingsResponse() / GetStorageSettingsResponse.new instead')
  static GetStorageSettingsResponse create() => GetStorageSettingsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetStorageSettingsResponse._();
  @$core.override
  GetStorageSettingsResponse createEmptyInstance() =>
      GetStorageSettingsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStorageSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetStorageSettingsResponse>(
          GetStorageSettingsResponse.$_createMessage);
  static GetStorageSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get recordingsLimitMb => $_getI64(1);
  @$pb.TagNumber(2)
  set recordingsLimitMb($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRecordingsLimitMb() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecordingsLimitMb() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get surveillanceLimitMb => $_getI64(2);
  @$pb.TagNumber(3)
  set surveillanceLimitMb($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSurveillanceLimitMb() => $_has(2);
  @$pb.TagNumber(3)
  void clearSurveillanceLimitMb() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get minLimitMb => $_getI64(3);
  @$pb.TagNumber(4)
  set minLimitMb($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMinLimitMb() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinLimitMb() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get maxLimitMb => $_getI64(4);
  @$pb.TagNumber(5)
  set maxLimitMb($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxLimitMb() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxLimitMb() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get maxLimitMbSdCard => $_getI64(5);
  @$pb.TagNumber(6)
  set maxLimitMbSdCard($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMaxLimitMbSdCard() => $_has(5);
  @$pb.TagNumber(6)
  void clearMaxLimitMbSdCard() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get recordingsPath => $_getSZ(6);
  @$pb.TagNumber(7)
  set recordingsPath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasRecordingsPath() => $_has(6);
  @$pb.TagNumber(7)
  void clearRecordingsPath() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get surveillancePath => $_getSZ(7);
  @$pb.TagNumber(8)
  set surveillancePath($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSurveillancePath() => $_has(7);
  @$pb.TagNumber(8)
  void clearSurveillancePath() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get recordingsSizeBytes => $_getI64(8);
  @$pb.TagNumber(9)
  set recordingsSizeBytes($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasRecordingsSizeBytes() => $_has(8);
  @$pb.TagNumber(9)
  void clearRecordingsSizeBytes() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get surveillanceSizeBytes => $_getI64(9);
  @$pb.TagNumber(10)
  set surveillanceSizeBytes($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasSurveillanceSizeBytes() => $_has(9);
  @$pb.TagNumber(10)
  void clearSurveillanceSizeBytes() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.int get recordingsCount => $_getIZ(10);
  @$pb.TagNumber(11)
  set recordingsCount($core.int value) => $_setSignedInt32(10, value);
  @$pb.TagNumber(11)
  $core.bool hasRecordingsCount() => $_has(10);
  @$pb.TagNumber(11)
  void clearRecordingsCount() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get surveillanceCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set surveillanceCount($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasSurveillanceCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearSurveillanceCount() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get recordingsStorageType => $_getSZ(12);
  @$pb.TagNumber(13)
  set recordingsStorageType($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasRecordingsStorageType() => $_has(12);
  @$pb.TagNumber(13)
  void clearRecordingsStorageType() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get surveillanceStorageType => $_getSZ(13);
  @$pb.TagNumber(14)
  set surveillanceStorageType($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasSurveillanceStorageType() => $_has(13);
  @$pb.TagNumber(14)
  void clearSurveillanceStorageType() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.bool get sdCardAvailable => $_getBF(14);
  @$pb.TagNumber(15)
  set sdCardAvailable($core.bool value) => $_setBool(14, value);
  @$pb.TagNumber(15)
  $core.bool hasSdCardAvailable() => $_has(14);
  @$pb.TagNumber(15)
  void clearSdCardAvailable() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get sdCardPath => $_getSZ(15);
  @$pb.TagNumber(16)
  set sdCardPath($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasSdCardPath() => $_has(15);
  @$pb.TagNumber(16)
  void clearSdCardPath() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get sdCardFreeBytes => $_getI64(16);
  @$pb.TagNumber(17)
  set sdCardFreeBytes($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasSdCardFreeBytes() => $_has(16);
  @$pb.TagNumber(17)
  void clearSdCardFreeBytes() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get sdCardTotalBytes => $_getI64(17);
  @$pb.TagNumber(18)
  set sdCardTotalBytes($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasSdCardTotalBytes() => $_has(17);
  @$pb.TagNumber(18)
  void clearSdCardTotalBytes() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.String get sdCardFreeFormatted => $_getSZ(18);
  @$pb.TagNumber(19)
  set sdCardFreeFormatted($core.String value) => $_setString(18, value);
  @$pb.TagNumber(19)
  $core.bool hasSdCardFreeFormatted() => $_has(18);
  @$pb.TagNumber(19)
  void clearSdCardFreeFormatted() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.String get sdCardTotalFormatted => $_getSZ(19);
  @$pb.TagNumber(20)
  set sdCardTotalFormatted($core.String value) => $_setString(19, value);
  @$pb.TagNumber(20)
  $core.bool hasSdCardTotalFormatted() => $_has(19);
  @$pb.TagNumber(20)
  void clearSdCardTotalFormatted() => $_clearField(20);

  @$pb.TagNumber(21)
  $fixnum.Int64 get internalFreeBytes => $_getI64(20);
  @$pb.TagNumber(21)
  set internalFreeBytes($fixnum.Int64 value) => $_setInt64(20, value);
  @$pb.TagNumber(21)
  $core.bool hasInternalFreeBytes() => $_has(20);
  @$pb.TagNumber(21)
  void clearInternalFreeBytes() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get internalTotalBytes => $_getI64(21);
  @$pb.TagNumber(22)
  set internalTotalBytes($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasInternalTotalBytes() => $_has(21);
  @$pb.TagNumber(22)
  void clearInternalTotalBytes() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get internalFreeFormatted => $_getSZ(22);
  @$pb.TagNumber(23)
  set internalFreeFormatted($core.String value) => $_setString(22, value);
  @$pb.TagNumber(23)
  $core.bool hasInternalFreeFormatted() => $_has(22);
  @$pb.TagNumber(23)
  void clearInternalFreeFormatted() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.String get internalTotalFormatted => $_getSZ(23);
  @$pb.TagNumber(24)
  set internalTotalFormatted($core.String value) => $_setString(23, value);
  @$pb.TagNumber(24)
  $core.bool hasInternalTotalFormatted() => $_has(23);
  @$pb.TagNumber(24)
  void clearInternalTotalFormatted() => $_clearField(24);

  /// True when an SD card configured for storage failed to mount after repeated attempts at
  /// daemon startup and the daemon kept the SD_CARD preference (not silently downgraded to
  /// internal). See sd_card_mount_error for a user-facing message.
  @$pb.TagNumber(25)
  $core.bool get sdCardMountFailed => $_getBF(24);
  @$pb.TagNumber(25)
  set sdCardMountFailed($core.bool value) => $_setBool(24, value);
  @$pb.TagNumber(25)
  $core.bool hasSdCardMountFailed() => $_has(24);
  @$pb.TagNumber(25)
  void clearSdCardMountFailed() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.String get sdCardMountError => $_getSZ(25);
  @$pb.TagNumber(26)
  set sdCardMountError($core.String value) => $_setString(25, value);
  @$pb.TagNumber(26)
  $core.bool hasSdCardMountError() => $_has(25);
  @$pb.TagNumber(26)
  void clearSdCardMountError() => $_clearField(26);
}

class SetStorageSettingsRequest extends $pb.GeneratedMessage {
  factory SetStorageSettingsRequest({
    $fixnum.Int64? recordingsLimitMb,
    $fixnum.Int64? surveillanceLimitMb,
    $core.String? recordingsStorageType,
    $core.String? surveillanceStorageType,
  }) {
    final result = SetStorageSettingsRequest._();
    if (recordingsLimitMb != null) result.recordingsLimitMb = recordingsLimitMb;
    if (surveillanceLimitMb != null)
      result.surveillanceLimitMb = surveillanceLimitMb;
    if (recordingsStorageType != null)
      result.recordingsStorageType = recordingsStorageType;
    if (surveillanceStorageType != null)
      result.surveillanceStorageType = surveillanceStorageType;
    return result;
  }

  SetStorageSettingsRequest._();

  factory SetStorageSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageSettingsRequest()..mergeFromBuffer(data, registry);
  factory SetStorageSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageSettingsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetStorageSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetStorageSettingsRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'recordingsLimitMb')
    ..aInt64(2, _omitFieldNames ? '' : 'surveillanceLimitMb')
    ..aOS(3, _omitFieldNames ? '' : 'recordingsStorageType')
    ..aOS(4, _omitFieldNames ? '' : 'surveillanceStorageType')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageSettingsRequest copyWith(
          void Function(SetStorageSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as SetStorageSettingsRequest))
          as SetStorageSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetStorageSettingsRequest() / SetStorageSettingsRequest.new instead')
  static SetStorageSettingsRequest create() => SetStorageSettingsRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetStorageSettingsRequest._();
  @$core.override
  SetStorageSettingsRequest createEmptyInstance() =>
      SetStorageSettingsRequest._();
  @$core.pragma('dart2js:noInline')
  static SetStorageSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetStorageSettingsRequest>(
          SetStorageSettingsRequest.$_createMessage);
  static SetStorageSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get recordingsLimitMb => $_getI64(0);
  @$pb.TagNumber(1)
  set recordingsLimitMb($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecordingsLimitMb() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecordingsLimitMb() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get surveillanceLimitMb => $_getI64(1);
  @$pb.TagNumber(2)
  set surveillanceLimitMb($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSurveillanceLimitMb() => $_has(1);
  @$pb.TagNumber(2)
  void clearSurveillanceLimitMb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get recordingsStorageType => $_getSZ(2);
  @$pb.TagNumber(3)
  set recordingsStorageType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRecordingsStorageType() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecordingsStorageType() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get surveillanceStorageType => $_getSZ(3);
  @$pb.TagNumber(4)
  set surveillanceStorageType($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSurveillanceStorageType() => $_has(3);
  @$pb.TagNumber(4)
  void clearSurveillanceStorageType() => $_clearField(4);
}

/// CleanupImpact reports the real (not estimated) effect of a limit on existing files, from
/// the identical selection algorithm StorageManager.ensureSpace uses.
class CleanupImpact extends $pb.GeneratedMessage {
  factory CleanupImpact({
    $core.int? fileCount,
    $fixnum.Int64? totalBytes,
  }) {
    final result = CleanupImpact._();
    if (fileCount != null) result.fileCount = fileCount;
    if (totalBytes != null) result.totalBytes = totalBytes;
    return result;
  }

  CleanupImpact._();

  factory CleanupImpact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CleanupImpact()..mergeFromBuffer(data, registry);
  factory CleanupImpact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CleanupImpact()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CleanupImpact',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: CleanupImpact.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'fileCount')
    ..aInt64(2, _omitFieldNames ? '' : 'totalBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CleanupImpact clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CleanupImpact copyWith(void Function(CleanupImpact) updates) =>
      super.copyWith((message) => updates(message as CleanupImpact))
          as CleanupImpact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CleanupImpact() / CleanupImpact.new instead')
  static CleanupImpact create() => CleanupImpact._();
  static $pb.GeneratedMessage $_createMessage() => CleanupImpact._();
  @$core.override
  CleanupImpact createEmptyInstance() => CleanupImpact._();
  @$core.pragma('dart2js:noInline')
  static CleanupImpact getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CleanupImpact>(
          CleanupImpact.$_createMessage);
  static CleanupImpact? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get fileCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set fileCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileCount() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get totalBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set totalBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotalBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotalBytes() => $_clearField(2);
}

class SetStorageSettingsResponse extends $pb.GeneratedMessage {
  factory SetStorageSettingsResponse({
    $core.bool? success,
    $core.String? error,
    CleanupImpact? recordingsImpact,
    CleanupImpact? surveillanceImpact,
  }) {
    final result = SetStorageSettingsResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    if (recordingsImpact != null) result.recordingsImpact = recordingsImpact;
    if (surveillanceImpact != null)
      result.surveillanceImpact = surveillanceImpact;
    return result;
  }

  SetStorageSettingsResponse._();

  factory SetStorageSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageSettingsResponse()..mergeFromBuffer(data, registry);
  factory SetStorageSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetStorageSettingsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetStorageSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetStorageSettingsResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aOM<CleanupImpact>(3, _omitFieldNames ? '' : 'recordingsImpact',
        subBuilder: CleanupImpact.$_createMessage)
    ..aOM<CleanupImpact>(4, _omitFieldNames ? '' : 'surveillanceImpact',
        subBuilder: CleanupImpact.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetStorageSettingsResponse copyWith(
          void Function(SetStorageSettingsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as SetStorageSettingsResponse))
          as SetStorageSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetStorageSettingsResponse() / SetStorageSettingsResponse.new instead')
  static SetStorageSettingsResponse create() => SetStorageSettingsResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetStorageSettingsResponse._();
  @$core.override
  SetStorageSettingsResponse createEmptyInstance() =>
      SetStorageSettingsResponse._();
  @$core.pragma('dart2js:noInline')
  static SetStorageSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetStorageSettingsResponse>(
          SetStorageSettingsResponse.$_createMessage);
  static SetStorageSettingsResponse? _defaultInstance;

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

  /// Present only when applying this request actually deleted at least one existing file for
  /// the corresponding category -- informational; PreviewStorageLimitChange is how a caller
  /// finds this out BEFORE applying.
  @$pb.TagNumber(3)
  CleanupImpact get recordingsImpact => $_getN(2);
  @$pb.TagNumber(3)
  set recordingsImpact(CleanupImpact value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRecordingsImpact() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecordingsImpact() => $_clearField(3);
  @$pb.TagNumber(3)
  CleanupImpact ensureRecordingsImpact() => $_ensure(2);

  @$pb.TagNumber(4)
  CleanupImpact get surveillanceImpact => $_getN(3);
  @$pb.TagNumber(4)
  set surveillanceImpact(CleanupImpact value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSurveillanceImpact() => $_has(3);
  @$pb.TagNumber(4)
  void clearSurveillanceImpact() => $_clearField(4);
  @$pb.TagNumber(4)
  CleanupImpact ensureSurveillanceImpact() => $_ensure(3);
}

class PreviewStorageLimitChangeRequest extends $pb.GeneratedMessage {
  factory PreviewStorageLimitChangeRequest({
    $fixnum.Int64? recordingsLimitMb,
    $fixnum.Int64? surveillanceLimitMb,
  }) {
    final result = PreviewStorageLimitChangeRequest._();
    if (recordingsLimitMb != null) result.recordingsLimitMb = recordingsLimitMb;
    if (surveillanceLimitMb != null)
      result.surveillanceLimitMb = surveillanceLimitMb;
    return result;
  }

  PreviewStorageLimitChangeRequest._();

  factory PreviewStorageLimitChangeRequest.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewStorageLimitChangeRequest()..mergeFromBuffer(data, registry);
  factory PreviewStorageLimitChangeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewStorageLimitChangeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewStorageLimitChangeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PreviewStorageLimitChangeRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'recordingsLimitMb')
    ..aInt64(2, _omitFieldNames ? '' : 'surveillanceLimitMb')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewStorageLimitChangeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewStorageLimitChangeRequest copyWith(
          void Function(PreviewStorageLimitChangeRequest) updates) =>
      super.copyWith(
              (message) => updates(message as PreviewStorageLimitChangeRequest))
          as PreviewStorageLimitChangeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewStorageLimitChangeRequest() / PreviewStorageLimitChangeRequest.new instead')
  static PreviewStorageLimitChangeRequest create() =>
      PreviewStorageLimitChangeRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      PreviewStorageLimitChangeRequest._();
  @$core.override
  PreviewStorageLimitChangeRequest createEmptyInstance() =>
      PreviewStorageLimitChangeRequest._();
  @$core.pragma('dart2js:noInline')
  static PreviewStorageLimitChangeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewStorageLimitChangeRequest>(
          PreviewStorageLimitChangeRequest.$_createMessage);
  static PreviewStorageLimitChangeRequest? _defaultInstance;

  /// 0 = do not preview recordings.
  @$pb.TagNumber(1)
  $fixnum.Int64 get recordingsLimitMb => $_getI64(0);
  @$pb.TagNumber(1)
  set recordingsLimitMb($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecordingsLimitMb() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecordingsLimitMb() => $_clearField(1);

  /// 0 = do not preview surveillance.
  @$pb.TagNumber(2)
  $fixnum.Int64 get surveillanceLimitMb => $_getI64(1);
  @$pb.TagNumber(2)
  set surveillanceLimitMb($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSurveillanceLimitMb() => $_has(1);
  @$pb.TagNumber(2)
  void clearSurveillanceLimitMb() => $_clearField(2);
}

class PreviewStorageLimitChangeResponse extends $pb.GeneratedMessage {
  factory PreviewStorageLimitChangeResponse({
    $core.bool? success,
    $core.String? error,
    CleanupImpact? recordingsImpact,
    CleanupImpact? surveillanceImpact,
  }) {
    final result = PreviewStorageLimitChangeResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    if (recordingsImpact != null) result.recordingsImpact = recordingsImpact;
    if (surveillanceImpact != null)
      result.surveillanceImpact = surveillanceImpact;
    return result;
  }

  PreviewStorageLimitChangeResponse._();

  factory PreviewStorageLimitChangeResponse.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewStorageLimitChangeResponse()..mergeFromBuffer(data, registry);
  factory PreviewStorageLimitChangeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewStorageLimitChangeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewStorageLimitChangeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PreviewStorageLimitChangeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..aOM<CleanupImpact>(3, _omitFieldNames ? '' : 'recordingsImpact',
        subBuilder: CleanupImpact.$_createMessage)
    ..aOM<CleanupImpact>(4, _omitFieldNames ? '' : 'surveillanceImpact',
        subBuilder: CleanupImpact.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewStorageLimitChangeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewStorageLimitChangeResponse copyWith(
          void Function(PreviewStorageLimitChangeResponse) updates) =>
      super.copyWith((message) =>
              updates(message as PreviewStorageLimitChangeResponse))
          as PreviewStorageLimitChangeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewStorageLimitChangeResponse() / PreviewStorageLimitChangeResponse.new instead')
  static PreviewStorageLimitChangeResponse create() =>
      PreviewStorageLimitChangeResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      PreviewStorageLimitChangeResponse._();
  @$core.override
  PreviewStorageLimitChangeResponse createEmptyInstance() =>
      PreviewStorageLimitChangeResponse._();
  @$core.pragma('dart2js:noInline')
  static PreviewStorageLimitChangeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewStorageLimitChangeResponse>(
          PreviewStorageLimitChangeResponse.$_createMessage);
  static PreviewStorageLimitChangeResponse? _defaultInstance;

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

  /// Present iff recordings_limit_mb was set in the request.
  @$pb.TagNumber(3)
  CleanupImpact get recordingsImpact => $_getN(2);
  @$pb.TagNumber(3)
  set recordingsImpact(CleanupImpact value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasRecordingsImpact() => $_has(2);
  @$pb.TagNumber(3)
  void clearRecordingsImpact() => $_clearField(3);
  @$pb.TagNumber(3)
  CleanupImpact ensureRecordingsImpact() => $_ensure(2);

  /// Present iff surveillance_limit_mb was set in the request.
  @$pb.TagNumber(4)
  CleanupImpact get surveillanceImpact => $_getN(3);
  @$pb.TagNumber(4)
  set surveillanceImpact(CleanupImpact value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSurveillanceImpact() => $_has(3);
  @$pb.TagNumber(4)
  void clearSurveillanceImpact() => $_clearField(4);
  @$pb.TagNumber(4)
  CleanupImpact ensureSurveillanceImpact() => $_ensure(3);
}

class GetExternalStorageRequest extends $pb.GeneratedMessage {
  factory GetExternalStorageRequest() => GetExternalStorageRequest._();

  GetExternalStorageRequest._();

  factory GetExternalStorageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetExternalStorageRequest()..mergeFromBuffer(data, registry);
  factory GetExternalStorageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetExternalStorageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetExternalStorageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetExternalStorageRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetExternalStorageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetExternalStorageRequest copyWith(
          void Function(GetExternalStorageRequest) updates) =>
      super.copyWith((message) => updates(message as GetExternalStorageRequest))
          as GetExternalStorageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetExternalStorageRequest() / GetExternalStorageRequest.new instead')
  static GetExternalStorageRequest create() => GetExternalStorageRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetExternalStorageRequest._();
  @$core.override
  GetExternalStorageRequest createEmptyInstance() =>
      GetExternalStorageRequest._();
  @$core.pragma('dart2js:noInline')
  static GetExternalStorageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetExternalStorageRequest>(
          GetExternalStorageRequest.$_createMessage);
  static GetExternalStorageRequest? _defaultInstance;
}

class GetExternalStorageResponse extends $pb.GeneratedMessage {
  factory GetExternalStorageResponse({
    $core.bool? success,
    $core.bool? sdCardAvailable,
    $core.String? sdCardPath,
    $fixnum.Int64? sdCardFreeBytes,
    $fixnum.Int64? sdCardTotalBytes,
    $core.String? sdCardFreeFormatted,
    $core.String? sdCardTotalFormatted,
    $core.int? sdCardUsedPercent,
    $core.String? cdrPath,
    $fixnum.Int64? cdrUsageBytes,
    $core.String? cdrUsageFormatted,
    $core.int? cdrFileCount,
    $fixnum.Int64? cdrProtectedBytes,
    $core.String? cdrProtectedFormatted,
    $fixnum.Int64? cdrDeletableBytes,
    $core.String? cdrDeletableFormatted,
    $core.bool? cleanupEnabled,
    $fixnum.Int64? reservedSpaceMb,
    $core.int? protectedHours,
    $core.int? minFilesKeep,
    $core.bool? monitoringActive,
    $fixnum.Int64? totalBytesFreed,
    $core.String? totalBytesFreedFormatted,
    $core.int? totalFilesDeleted,
    $fixnum.Int64? lastCleanupTimeMs,
    $core.bool? bladewatchUsesSdCard,
    $core.bool? recommendAutoCleanup,
  }) {
    final result = GetExternalStorageResponse._();
    if (success != null) result.success = success;
    if (sdCardAvailable != null) result.sdCardAvailable = sdCardAvailable;
    if (sdCardPath != null) result.sdCardPath = sdCardPath;
    if (sdCardFreeBytes != null) result.sdCardFreeBytes = sdCardFreeBytes;
    if (sdCardTotalBytes != null) result.sdCardTotalBytes = sdCardTotalBytes;
    if (sdCardFreeFormatted != null)
      result.sdCardFreeFormatted = sdCardFreeFormatted;
    if (sdCardTotalFormatted != null)
      result.sdCardTotalFormatted = sdCardTotalFormatted;
    if (sdCardUsedPercent != null) result.sdCardUsedPercent = sdCardUsedPercent;
    if (cdrPath != null) result.cdrPath = cdrPath;
    if (cdrUsageBytes != null) result.cdrUsageBytes = cdrUsageBytes;
    if (cdrUsageFormatted != null) result.cdrUsageFormatted = cdrUsageFormatted;
    if (cdrFileCount != null) result.cdrFileCount = cdrFileCount;
    if (cdrProtectedBytes != null) result.cdrProtectedBytes = cdrProtectedBytes;
    if (cdrProtectedFormatted != null)
      result.cdrProtectedFormatted = cdrProtectedFormatted;
    if (cdrDeletableBytes != null) result.cdrDeletableBytes = cdrDeletableBytes;
    if (cdrDeletableFormatted != null)
      result.cdrDeletableFormatted = cdrDeletableFormatted;
    if (cleanupEnabled != null) result.cleanupEnabled = cleanupEnabled;
    if (reservedSpaceMb != null) result.reservedSpaceMb = reservedSpaceMb;
    if (protectedHours != null) result.protectedHours = protectedHours;
    if (minFilesKeep != null) result.minFilesKeep = minFilesKeep;
    if (monitoringActive != null) result.monitoringActive = monitoringActive;
    if (totalBytesFreed != null) result.totalBytesFreed = totalBytesFreed;
    if (totalBytesFreedFormatted != null)
      result.totalBytesFreedFormatted = totalBytesFreedFormatted;
    if (totalFilesDeleted != null) result.totalFilesDeleted = totalFilesDeleted;
    if (lastCleanupTimeMs != null) result.lastCleanupTimeMs = lastCleanupTimeMs;
    if (bladewatchUsesSdCard != null)
      result.bladewatchUsesSdCard = bladewatchUsesSdCard;
    if (recommendAutoCleanup != null)
      result.recommendAutoCleanup = recommendAutoCleanup;
    return result;
  }

  GetExternalStorageResponse._();

  factory GetExternalStorageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetExternalStorageResponse()..mergeFromBuffer(data, registry);
  factory GetExternalStorageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetExternalStorageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetExternalStorageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetExternalStorageResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOB(2, _omitFieldNames ? '' : 'sdCardAvailable')
    ..aOS(3, _omitFieldNames ? '' : 'sdCardPath')
    ..aInt64(4, _omitFieldNames ? '' : 'sdCardFree',
        protoName: 'sd_card_free_bytes')
    ..aInt64(5, _omitFieldNames ? '' : 'sdCardTotal',
        protoName: 'sd_card_total_bytes')
    ..aOS(6, _omitFieldNames ? '' : 'sdCardFreeFormatted')
    ..aOS(7, _omitFieldNames ? '' : 'sdCardTotalFormatted')
    ..aI(8, _omitFieldNames ? '' : 'sdCardUsedPercent')
    ..aOS(9, _omitFieldNames ? '' : 'cdrPath')
    ..aInt64(10, _omitFieldNames ? '' : 'cdrUsage',
        protoName: 'cdr_usage_bytes')
    ..aOS(11, _omitFieldNames ? '' : 'cdrUsageFormatted')
    ..aI(12, _omitFieldNames ? '' : 'cdrFileCount')
    ..aInt64(13, _omitFieldNames ? '' : 'cdrProtectedSize',
        protoName: 'cdr_protected_bytes')
    ..aOS(14, _omitFieldNames ? '' : 'cdrProtectedFormatted')
    ..aInt64(15, _omitFieldNames ? '' : 'cdrDeletableSize',
        protoName: 'cdr_deletable_bytes')
    ..aOS(16, _omitFieldNames ? '' : 'cdrDeletableFormatted')
    ..aOB(17, _omitFieldNames ? '' : 'cleanupEnabled')
    ..aInt64(18, _omitFieldNames ? '' : 'reservedSpaceMb')
    ..aI(19, _omitFieldNames ? '' : 'protectedHours')
    ..aI(20, _omitFieldNames ? '' : 'minFilesKeep')
    ..aOB(21, _omitFieldNames ? '' : 'monitoringActive')
    ..aInt64(22, _omitFieldNames ? '' : 'totalBytesFreed')
    ..aOS(23, _omitFieldNames ? '' : 'totalBytesFreedFormatted')
    ..aI(24, _omitFieldNames ? '' : 'totalFilesDeleted')
    ..aInt64(25, _omitFieldNames ? '' : 'lastCleanupTime',
        protoName: 'last_cleanup_time_ms')
    ..aOB(26, _omitFieldNames ? '' : 'bladewatchUsesSdCard')
    ..aOB(27, _omitFieldNames ? '' : 'recommendAutoCleanup')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetExternalStorageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetExternalStorageResponse copyWith(
          void Function(GetExternalStorageResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetExternalStorageResponse))
          as GetExternalStorageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetExternalStorageResponse() / GetExternalStorageResponse.new instead')
  static GetExternalStorageResponse create() => GetExternalStorageResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetExternalStorageResponse._();
  @$core.override
  GetExternalStorageResponse createEmptyInstance() =>
      GetExternalStorageResponse._();
  @$core.pragma('dart2js:noInline')
  static GetExternalStorageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetExternalStorageResponse>(
          GetExternalStorageResponse.$_createMessage);
  static GetExternalStorageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get sdCardAvailable => $_getBF(1);
  @$pb.TagNumber(2)
  set sdCardAvailable($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSdCardAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearSdCardAvailable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sdCardPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set sdCardPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSdCardPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearSdCardPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get sdCardFreeBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set sdCardFreeBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSdCardFreeBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearSdCardFreeBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sdCardTotalBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sdCardTotalBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSdCardTotalBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSdCardTotalBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get sdCardFreeFormatted => $_getSZ(5);
  @$pb.TagNumber(6)
  set sdCardFreeFormatted($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSdCardFreeFormatted() => $_has(5);
  @$pb.TagNumber(6)
  void clearSdCardFreeFormatted() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get sdCardTotalFormatted => $_getSZ(6);
  @$pb.TagNumber(7)
  set sdCardTotalFormatted($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSdCardTotalFormatted() => $_has(6);
  @$pb.TagNumber(7)
  void clearSdCardTotalFormatted() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get sdCardUsedPercent => $_getIZ(7);
  @$pb.TagNumber(8)
  set sdCardUsedPercent($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSdCardUsedPercent() => $_has(7);
  @$pb.TagNumber(8)
  void clearSdCardUsedPercent() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get cdrPath => $_getSZ(8);
  @$pb.TagNumber(9)
  set cdrPath($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCdrPath() => $_has(8);
  @$pb.TagNumber(9)
  void clearCdrPath() => $_clearField(9);

  @$pb.TagNumber(10)
  $fixnum.Int64 get cdrUsageBytes => $_getI64(9);
  @$pb.TagNumber(10)
  set cdrUsageBytes($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCdrUsageBytes() => $_has(9);
  @$pb.TagNumber(10)
  void clearCdrUsageBytes() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get cdrUsageFormatted => $_getSZ(10);
  @$pb.TagNumber(11)
  set cdrUsageFormatted($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCdrUsageFormatted() => $_has(10);
  @$pb.TagNumber(11)
  void clearCdrUsageFormatted() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get cdrFileCount => $_getIZ(11);
  @$pb.TagNumber(12)
  set cdrFileCount($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasCdrFileCount() => $_has(11);
  @$pb.TagNumber(12)
  void clearCdrFileCount() => $_clearField(12);

  @$pb.TagNumber(13)
  $fixnum.Int64 get cdrProtectedBytes => $_getI64(12);
  @$pb.TagNumber(13)
  set cdrProtectedBytes($fixnum.Int64 value) => $_setInt64(12, value);
  @$pb.TagNumber(13)
  $core.bool hasCdrProtectedBytes() => $_has(12);
  @$pb.TagNumber(13)
  void clearCdrProtectedBytes() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.String get cdrProtectedFormatted => $_getSZ(13);
  @$pb.TagNumber(14)
  set cdrProtectedFormatted($core.String value) => $_setString(13, value);
  @$pb.TagNumber(14)
  $core.bool hasCdrProtectedFormatted() => $_has(13);
  @$pb.TagNumber(14)
  void clearCdrProtectedFormatted() => $_clearField(14);

  @$pb.TagNumber(15)
  $fixnum.Int64 get cdrDeletableBytes => $_getI64(14);
  @$pb.TagNumber(15)
  set cdrDeletableBytes($fixnum.Int64 value) => $_setInt64(14, value);
  @$pb.TagNumber(15)
  $core.bool hasCdrDeletableBytes() => $_has(14);
  @$pb.TagNumber(15)
  void clearCdrDeletableBytes() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get cdrDeletableFormatted => $_getSZ(15);
  @$pb.TagNumber(16)
  set cdrDeletableFormatted($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasCdrDeletableFormatted() => $_has(15);
  @$pb.TagNumber(16)
  void clearCdrDeletableFormatted() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.bool get cleanupEnabled => $_getBF(16);
  @$pb.TagNumber(17)
  set cleanupEnabled($core.bool value) => $_setBool(16, value);
  @$pb.TagNumber(17)
  $core.bool hasCleanupEnabled() => $_has(16);
  @$pb.TagNumber(17)
  void clearCleanupEnabled() => $_clearField(17);

  @$pb.TagNumber(18)
  $fixnum.Int64 get reservedSpaceMb => $_getI64(17);
  @$pb.TagNumber(18)
  set reservedSpaceMb($fixnum.Int64 value) => $_setInt64(17, value);
  @$pb.TagNumber(18)
  $core.bool hasReservedSpaceMb() => $_has(17);
  @$pb.TagNumber(18)
  void clearReservedSpaceMb() => $_clearField(18);

  @$pb.TagNumber(19)
  $core.int get protectedHours => $_getIZ(18);
  @$pb.TagNumber(19)
  set protectedHours($core.int value) => $_setSignedInt32(18, value);
  @$pb.TagNumber(19)
  $core.bool hasProtectedHours() => $_has(18);
  @$pb.TagNumber(19)
  void clearProtectedHours() => $_clearField(19);

  @$pb.TagNumber(20)
  $core.int get minFilesKeep => $_getIZ(19);
  @$pb.TagNumber(20)
  set minFilesKeep($core.int value) => $_setSignedInt32(19, value);
  @$pb.TagNumber(20)
  $core.bool hasMinFilesKeep() => $_has(19);
  @$pb.TagNumber(20)
  void clearMinFilesKeep() => $_clearField(20);

  @$pb.TagNumber(21)
  $core.bool get monitoringActive => $_getBF(20);
  @$pb.TagNumber(21)
  set monitoringActive($core.bool value) => $_setBool(20, value);
  @$pb.TagNumber(21)
  $core.bool hasMonitoringActive() => $_has(20);
  @$pb.TagNumber(21)
  void clearMonitoringActive() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get totalBytesFreed => $_getI64(21);
  @$pb.TagNumber(22)
  set totalBytesFreed($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasTotalBytesFreed() => $_has(21);
  @$pb.TagNumber(22)
  void clearTotalBytesFreed() => $_clearField(22);

  @$pb.TagNumber(23)
  $core.String get totalBytesFreedFormatted => $_getSZ(22);
  @$pb.TagNumber(23)
  set totalBytesFreedFormatted($core.String value) => $_setString(22, value);
  @$pb.TagNumber(23)
  $core.bool hasTotalBytesFreedFormatted() => $_has(22);
  @$pb.TagNumber(23)
  void clearTotalBytesFreedFormatted() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.int get totalFilesDeleted => $_getIZ(23);
  @$pb.TagNumber(24)
  set totalFilesDeleted($core.int value) => $_setSignedInt32(23, value);
  @$pb.TagNumber(24)
  $core.bool hasTotalFilesDeleted() => $_has(23);
  @$pb.TagNumber(24)
  void clearTotalFilesDeleted() => $_clearField(24);

  @$pb.TagNumber(25)
  $fixnum.Int64 get lastCleanupTimeMs => $_getI64(24);
  @$pb.TagNumber(25)
  set lastCleanupTimeMs($fixnum.Int64 value) => $_setInt64(24, value);
  @$pb.TagNumber(25)
  $core.bool hasLastCleanupTimeMs() => $_has(24);
  @$pb.TagNumber(25)
  void clearLastCleanupTimeMs() => $_clearField(25);

  @$pb.TagNumber(26)
  $core.bool get bladewatchUsesSdCard => $_getBF(25);
  @$pb.TagNumber(26)
  set bladewatchUsesSdCard($core.bool value) => $_setBool(25, value);
  @$pb.TagNumber(26)
  $core.bool hasBladewatchUsesSdCard() => $_has(25);
  @$pb.TagNumber(26)
  void clearBladewatchUsesSdCard() => $_clearField(26);

  @$pb.TagNumber(27)
  $core.bool get recommendAutoCleanup => $_getBF(26);
  @$pb.TagNumber(27)
  set recommendAutoCleanup($core.bool value) => $_setBool(26, value);
  @$pb.TagNumber(27)
  $core.bool hasRecommendAutoCleanup() => $_has(26);
  @$pb.TagNumber(27)
  void clearRecommendAutoCleanup() => $_clearField(27);
}

class SetExternalConfigRequest extends $pb.GeneratedMessage {
  factory SetExternalConfigRequest({
    $core.bool? enabled,
    $fixnum.Int64? reservedSpaceMb,
    $core.int? protectedHours,
    $core.int? minFilesKeep,
  }) {
    final result = SetExternalConfigRequest._();
    if (enabled != null) result.enabled = enabled;
    if (reservedSpaceMb != null) result.reservedSpaceMb = reservedSpaceMb;
    if (protectedHours != null) result.protectedHours = protectedHours;
    if (minFilesKeep != null) result.minFilesKeep = minFilesKeep;
    return result;
  }

  SetExternalConfigRequest._();

  factory SetExternalConfigRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetExternalConfigRequest()..mergeFromBuffer(data, registry);
  factory SetExternalConfigRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetExternalConfigRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetExternalConfigRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetExternalConfigRequest.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aInt64(2, _omitFieldNames ? '' : 'reservedSpaceMb')
    ..aI(3, _omitFieldNames ? '' : 'protectedHours')
    ..aI(4, _omitFieldNames ? '' : 'minFilesKeep')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExternalConfigRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExternalConfigRequest copyWith(
          void Function(SetExternalConfigRequest) updates) =>
      super.copyWith((message) => updates(message as SetExternalConfigRequest))
          as SetExternalConfigRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetExternalConfigRequest() / SetExternalConfigRequest.new instead')
  static SetExternalConfigRequest create() => SetExternalConfigRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetExternalConfigRequest._();
  @$core.override
  SetExternalConfigRequest createEmptyInstance() =>
      SetExternalConfigRequest._();
  @$core.pragma('dart2js:noInline')
  static SetExternalConfigRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetExternalConfigRequest>(
          SetExternalConfigRequest.$_createMessage);
  static SetExternalConfigRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get reservedSpaceMb => $_getI64(1);
  @$pb.TagNumber(2)
  set reservedSpaceMb($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReservedSpaceMb() => $_has(1);
  @$pb.TagNumber(2)
  void clearReservedSpaceMb() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get protectedHours => $_getIZ(2);
  @$pb.TagNumber(3)
  set protectedHours($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProtectedHours() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtectedHours() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get minFilesKeep => $_getIZ(3);
  @$pb.TagNumber(4)
  set minFilesKeep($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMinFilesKeep() => $_has(3);
  @$pb.TagNumber(4)
  void clearMinFilesKeep() => $_clearField(4);
}

class SetExternalConfigResponse extends $pb.GeneratedMessage {
  factory SetExternalConfigResponse({
    $core.bool? success,
    $core.bool? cleanupEnabled,
    $fixnum.Int64? reservedSpaceMb,
    $core.int? protectedHours,
    $core.int? minFilesKeep,
    $core.String? error,
  }) {
    final result = SetExternalConfigResponse._();
    if (success != null) result.success = success;
    if (cleanupEnabled != null) result.cleanupEnabled = cleanupEnabled;
    if (reservedSpaceMb != null) result.reservedSpaceMb = reservedSpaceMb;
    if (protectedHours != null) result.protectedHours = protectedHours;
    if (minFilesKeep != null) result.minFilesKeep = minFilesKeep;
    if (error != null) result.error = error;
    return result;
  }

  SetExternalConfigResponse._();

  factory SetExternalConfigResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetExternalConfigResponse()..mergeFromBuffer(data, registry);
  factory SetExternalConfigResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetExternalConfigResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetExternalConfigResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SetExternalConfigResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOB(2, _omitFieldNames ? '' : 'cleanupEnabled')
    ..aInt64(3, _omitFieldNames ? '' : 'reservedSpaceMb')
    ..aI(4, _omitFieldNames ? '' : 'protectedHours')
    ..aI(5, _omitFieldNames ? '' : 'minFilesKeep')
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExternalConfigResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetExternalConfigResponse copyWith(
          void Function(SetExternalConfigResponse) updates) =>
      super.copyWith((message) => updates(message as SetExternalConfigResponse))
          as SetExternalConfigResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use SetExternalConfigResponse() / SetExternalConfigResponse.new instead')
  static SetExternalConfigResponse create() => SetExternalConfigResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      SetExternalConfigResponse._();
  @$core.override
  SetExternalConfigResponse createEmptyInstance() =>
      SetExternalConfigResponse._();
  @$core.pragma('dart2js:noInline')
  static SetExternalConfigResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetExternalConfigResponse>(
          SetExternalConfigResponse.$_createMessage);
  static SetExternalConfigResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get cleanupEnabled => $_getBF(1);
  @$pb.TagNumber(2)
  set cleanupEnabled($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCleanupEnabled() => $_has(1);
  @$pb.TagNumber(2)
  void clearCleanupEnabled() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get reservedSpaceMb => $_getI64(2);
  @$pb.TagNumber(3)
  set reservedSpaceMb($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReservedSpaceMb() => $_has(2);
  @$pb.TagNumber(3)
  void clearReservedSpaceMb() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get protectedHours => $_getIZ(3);
  @$pb.TagNumber(4)
  set protectedHours($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasProtectedHours() => $_has(3);
  @$pb.TagNumber(4)
  void clearProtectedHours() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get minFilesKeep => $_getIZ(4);
  @$pb.TagNumber(5)
  set minFilesKeep($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMinFilesKeep() => $_has(4);
  @$pb.TagNumber(5)
  void clearMinFilesKeep() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);
}

class TriggerCleanupRequest extends $pb.GeneratedMessage {
  factory TriggerCleanupRequest({
    $fixnum.Int64? bytesToFree,
  }) {
    final result = TriggerCleanupRequest._();
    if (bytesToFree != null) result.bytesToFree = bytesToFree;
    return result;
  }

  TriggerCleanupRequest._();

  factory TriggerCleanupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TriggerCleanupRequest()..mergeFromBuffer(data, registry);
  factory TriggerCleanupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TriggerCleanupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TriggerCleanupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TriggerCleanupRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'bytesToFree')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TriggerCleanupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TriggerCleanupRequest copyWith(
          void Function(TriggerCleanupRequest) updates) =>
      super.copyWith((message) => updates(message as TriggerCleanupRequest))
          as TriggerCleanupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use TriggerCleanupRequest() / TriggerCleanupRequest.new instead')
  static TriggerCleanupRequest create() => TriggerCleanupRequest._();
  static $pb.GeneratedMessage $_createMessage() => TriggerCleanupRequest._();
  @$core.override
  TriggerCleanupRequest createEmptyInstance() => TriggerCleanupRequest._();
  @$core.pragma('dart2js:noInline')
  static TriggerCleanupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TriggerCleanupRequest>(
          TriggerCleanupRequest.$_createMessage);
  static TriggerCleanupRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get bytesToFree => $_getI64(0);
  @$pb.TagNumber(1)
  set bytesToFree($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBytesToFree() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytesToFree() => $_clearField(1);
}

class TriggerCleanupResponse extends $pb.GeneratedMessage {
  factory TriggerCleanupResponse({
    $core.bool? success,
    $fixnum.Int64? bytesFreed,
    $core.int? filesDeleted,
    $core.String? message,
    $core.String? error,
  }) {
    final result = TriggerCleanupResponse._();
    if (success != null) result.success = success;
    if (bytesFreed != null) result.bytesFreed = bytesFreed;
    if (filesDeleted != null) result.filesDeleted = filesDeleted;
    if (message != null) result.message = message;
    if (error != null) result.error = error;
    return result;
  }

  TriggerCleanupResponse._();

  factory TriggerCleanupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TriggerCleanupResponse()..mergeFromBuffer(data, registry);
  factory TriggerCleanupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TriggerCleanupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TriggerCleanupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: TriggerCleanupResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aInt64(2, _omitFieldNames ? '' : 'bytesFreed')
    ..aI(3, _omitFieldNames ? '' : 'filesDeleted')
    ..aOS(4, _omitFieldNames ? '' : 'message')
    ..aOS(5, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TriggerCleanupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TriggerCleanupResponse copyWith(
          void Function(TriggerCleanupResponse) updates) =>
      super.copyWith((message) => updates(message as TriggerCleanupResponse))
          as TriggerCleanupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use TriggerCleanupResponse() / TriggerCleanupResponse.new instead')
  static TriggerCleanupResponse create() => TriggerCleanupResponse._();
  static $pb.GeneratedMessage $_createMessage() => TriggerCleanupResponse._();
  @$core.override
  TriggerCleanupResponse createEmptyInstance() => TriggerCleanupResponse._();
  @$core.pragma('dart2js:noInline')
  static TriggerCleanupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TriggerCleanupResponse>(
          TriggerCleanupResponse.$_createMessage);
  static TriggerCleanupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytesFreed => $_getI64(1);
  @$pb.TagNumber(2)
  set bytesFreed($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytesFreed() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytesFreed() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get filesDeleted => $_getIZ(2);
  @$pb.TagNumber(3)
  set filesDeleted($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilesDeleted() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilesDeleted() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get message => $_getSZ(3);
  @$pb.TagNumber(4)
  set message($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMessage() => $_has(3);
  @$pb.TagNumber(4)
  void clearMessage() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get error => $_getSZ(4);
  @$pb.TagNumber(5)
  set error($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(5)
  void clearError() => $_clearField(5);
}

class PreviewCleanupRequest extends $pb.GeneratedMessage {
  factory PreviewCleanupRequest({
    $fixnum.Int64? bytesToFree,
  }) {
    final result = PreviewCleanupRequest._();
    if (bytesToFree != null) result.bytesToFree = bytesToFree;
    return result;
  }

  PreviewCleanupRequest._();

  factory PreviewCleanupRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCleanupRequest()..mergeFromBuffer(data, registry);
  factory PreviewCleanupRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCleanupRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewCleanupRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PreviewCleanupRequest.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'bytesToFree')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCleanupRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCleanupRequest copyWith(
          void Function(PreviewCleanupRequest) updates) =>
      super.copyWith((message) => updates(message as PreviewCleanupRequest))
          as PreviewCleanupRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewCleanupRequest() / PreviewCleanupRequest.new instead')
  static PreviewCleanupRequest create() => PreviewCleanupRequest._();
  static $pb.GeneratedMessage $_createMessage() => PreviewCleanupRequest._();
  @$core.override
  PreviewCleanupRequest createEmptyInstance() => PreviewCleanupRequest._();
  @$core.pragma('dart2js:noInline')
  static PreviewCleanupRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewCleanupRequest>(
          PreviewCleanupRequest.$_createMessage);
  static PreviewCleanupRequest? _defaultInstance;

  /// Optional target bytes to free for the preview. 0 = use the handler default (500 MB).
  /// Passed to the REST handler as the ?bytesToFree= query param.
  @$pb.TagNumber(1)
  $fixnum.Int64 get bytesToFree => $_getI64(0);
  @$pb.TagNumber(1)
  set bytesToFree($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBytesToFree() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytesToFree() => $_clearField(1);
}

class PreviewCleanupFile extends $pb.GeneratedMessage {
  factory PreviewCleanupFile({
    $core.String? path,
    $fixnum.Int64? sizeBytes,
  }) {
    final result = PreviewCleanupFile._();
    if (path != null) result.path = path;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    return result;
  }

  PreviewCleanupFile._();

  factory PreviewCleanupFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCleanupFile()..mergeFromBuffer(data, registry);
  factory PreviewCleanupFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCleanupFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewCleanupFile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PreviewCleanupFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..aInt64(2, _omitFieldNames ? '' : 'size', protoName: 'size_bytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCleanupFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCleanupFile copyWith(void Function(PreviewCleanupFile) updates) =>
      super.copyWith((message) => updates(message as PreviewCleanupFile))
          as PreviewCleanupFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PreviewCleanupFile() / PreviewCleanupFile.new instead')
  static PreviewCleanupFile create() => PreviewCleanupFile._();
  static $pb.GeneratedMessage $_createMessage() => PreviewCleanupFile._();
  @$core.override
  PreviewCleanupFile createEmptyInstance() => PreviewCleanupFile._();
  @$core.pragma('dart2js:noInline')
  static PreviewCleanupFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewCleanupFile>(
          PreviewCleanupFile.$_createMessage);
  static PreviewCleanupFile? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSizeBytes() => $_clearField(2);
}

class PreviewCleanupResponse extends $pb.GeneratedMessage {
  factory PreviewCleanupResponse({
    $core.bool? success,
    $core.Iterable<PreviewCleanupFile>? files,
    $fixnum.Int64? totalDeletableBytes,
    $core.int? totalDeletableCount,
  }) {
    final result = PreviewCleanupResponse._();
    if (success != null) result.success = success;
    if (files != null) result.files.addAll(files);
    if (totalDeletableBytes != null)
      result.totalDeletableBytes = totalDeletableBytes;
    if (totalDeletableCount != null)
      result.totalDeletableCount = totalDeletableCount;
    return result;
  }

  PreviewCleanupResponse._();

  factory PreviewCleanupResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCleanupResponse()..mergeFromBuffer(data, registry);
  factory PreviewCleanupResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PreviewCleanupResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PreviewCleanupResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: PreviewCleanupResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<PreviewCleanupFile>(2, _omitFieldNames ? '' : 'files',
        subBuilder: PreviewCleanupFile.$_createMessage)
    ..aInt64(3, _omitFieldNames ? '' : 'totalSize',
        protoName: 'total_deletable_bytes')
    ..aI(4, _omitFieldNames ? '' : 'fileCount',
        protoName: 'total_deletable_count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCleanupResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PreviewCleanupResponse copyWith(
          void Function(PreviewCleanupResponse) updates) =>
      super.copyWith((message) => updates(message as PreviewCleanupResponse))
          as PreviewCleanupResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use PreviewCleanupResponse() / PreviewCleanupResponse.new instead')
  static PreviewCleanupResponse create() => PreviewCleanupResponse._();
  static $pb.GeneratedMessage $_createMessage() => PreviewCleanupResponse._();
  @$core.override
  PreviewCleanupResponse createEmptyInstance() => PreviewCleanupResponse._();
  @$core.pragma('dart2js:noInline')
  static PreviewCleanupResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PreviewCleanupResponse>(
          PreviewCleanupResponse.$_createMessage);
  static PreviewCleanupResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<PreviewCleanupFile> get files => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get totalDeletableBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set totalDeletableBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotalDeletableBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotalDeletableBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get totalDeletableCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set totalDeletableCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTotalDeletableCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearTotalDeletableCount() => $_clearField(4);
}

class RefreshExternalStorageRequest extends $pb.GeneratedMessage {
  factory RefreshExternalStorageRequest() => RefreshExternalStorageRequest._();

  RefreshExternalStorageRequest._();

  factory RefreshExternalStorageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshExternalStorageRequest()..mergeFromBuffer(data, registry);
  factory RefreshExternalStorageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshExternalStorageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshExternalStorageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: RefreshExternalStorageRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshExternalStorageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshExternalStorageRequest copyWith(
          void Function(RefreshExternalStorageRequest) updates) =>
      super.copyWith(
              (message) => updates(message as RefreshExternalStorageRequest))
          as RefreshExternalStorageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RefreshExternalStorageRequest() / RefreshExternalStorageRequest.new instead')
  static RefreshExternalStorageRequest create() =>
      RefreshExternalStorageRequest._();
  static $pb.GeneratedMessage $_createMessage() =>
      RefreshExternalStorageRequest._();
  @$core.override
  RefreshExternalStorageRequest createEmptyInstance() =>
      RefreshExternalStorageRequest._();
  @$core.pragma('dart2js:noInline')
  static RefreshExternalStorageRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshExternalStorageRequest>(
          RefreshExternalStorageRequest.$_createMessage);
  static RefreshExternalStorageRequest? _defaultInstance;
}

class RefreshExternalStorageResponse extends $pb.GeneratedMessage {
  factory RefreshExternalStorageResponse({
    $core.bool? success,
  }) {
    final result = RefreshExternalStorageResponse._();
    if (success != null) result.success = success;
    return result;
  }

  RefreshExternalStorageResponse._();

  factory RefreshExternalStorageResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshExternalStorageResponse()..mergeFromBuffer(data, registry);
  factory RefreshExternalStorageResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshExternalStorageResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RefreshExternalStorageResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: RefreshExternalStorageResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshExternalStorageResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshExternalStorageResponse copyWith(
          void Function(RefreshExternalStorageResponse) updates) =>
      super.copyWith(
              (message) => updates(message as RefreshExternalStorageResponse))
          as RefreshExternalStorageResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use RefreshExternalStorageResponse() / RefreshExternalStorageResponse.new instead')
  static RefreshExternalStorageResponse create() =>
      RefreshExternalStorageResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      RefreshExternalStorageResponse._();
  @$core.override
  RefreshExternalStorageResponse createEmptyInstance() =>
      RefreshExternalStorageResponse._();
  @$core.pragma('dart2js:noInline')
  static RefreshExternalStorageResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshExternalStorageResponse>(
          RefreshExternalStorageResponse.$_createMessage);
  static RefreshExternalStorageResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);
}

class ListFormatVolumesRequest extends $pb.GeneratedMessage {
  factory ListFormatVolumesRequest() => ListFormatVolumesRequest._();

  ListFormatVolumesRequest._();

  factory ListFormatVolumesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListFormatVolumesRequest()..mergeFromBuffer(data, registry);
  factory ListFormatVolumesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListFormatVolumesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFormatVolumesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListFormatVolumesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatVolumesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatVolumesRequest copyWith(
          void Function(ListFormatVolumesRequest) updates) =>
      super.copyWith((message) => updates(message as ListFormatVolumesRequest))
          as ListFormatVolumesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListFormatVolumesRequest() / ListFormatVolumesRequest.new instead')
  static ListFormatVolumesRequest create() => ListFormatVolumesRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListFormatVolumesRequest._();
  @$core.override
  ListFormatVolumesRequest createEmptyInstance() =>
      ListFormatVolumesRequest._();
  @$core.pragma('dart2js:noInline')
  static ListFormatVolumesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFormatVolumesRequest>(
          ListFormatVolumesRequest.$_createMessage);
  static ListFormatVolumesRequest? _defaultInstance;
}

class ListFormatVolumesResponse extends $pb.GeneratedMessage {
  factory ListFormatVolumesResponse({
    $core.bool? success,
    $core.Iterable<VolumeInfo>? volumes,
  }) {
    final result = ListFormatVolumesResponse._();
    if (success != null) result.success = success;
    if (volumes != null) result.volumes.addAll(volumes);
    return result;
  }

  ListFormatVolumesResponse._();

  factory ListFormatVolumesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListFormatVolumesResponse()..mergeFromBuffer(data, registry);
  factory ListFormatVolumesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListFormatVolumesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListFormatVolumesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListFormatVolumesResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..pPM<VolumeInfo>(2, _omitFieldNames ? '' : 'volumes',
        subBuilder: VolumeInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatVolumesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListFormatVolumesResponse copyWith(
          void Function(ListFormatVolumesResponse) updates) =>
      super.copyWith((message) => updates(message as ListFormatVolumesResponse))
          as ListFormatVolumesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListFormatVolumesResponse() / ListFormatVolumesResponse.new instead')
  static ListFormatVolumesResponse create() => ListFormatVolumesResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      ListFormatVolumesResponse._();
  @$core.override
  ListFormatVolumesResponse createEmptyInstance() =>
      ListFormatVolumesResponse._();
  @$core.pragma('dart2js:noInline')
  static ListFormatVolumesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListFormatVolumesResponse>(
          ListFormatVolumesResponse.$_createMessage);
  static ListFormatVolumesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<VolumeInfo> get volumes => $_getList(1);
}

class FormatVolumeRequest extends $pb.GeneratedMessage {
  factory FormatVolumeRequest({
    $core.String? volumeId,
  }) {
    final result = FormatVolumeRequest._();
    if (volumeId != null) result.volumeId = volumeId;
    return result;
  }

  FormatVolumeRequest._();

  factory FormatVolumeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatVolumeRequest()..mergeFromBuffer(data, registry);
  factory FormatVolumeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatVolumeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormatVolumeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: FormatVolumeRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'volumeId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatVolumeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatVolumeRequest copyWith(void Function(FormatVolumeRequest) updates) =>
      super.copyWith((message) => updates(message as FormatVolumeRequest))
          as FormatVolumeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use FormatVolumeRequest() / FormatVolumeRequest.new instead')
  static FormatVolumeRequest create() => FormatVolumeRequest._();
  static $pb.GeneratedMessage $_createMessage() => FormatVolumeRequest._();
  @$core.override
  FormatVolumeRequest createEmptyInstance() => FormatVolumeRequest._();
  @$core.pragma('dart2js:noInline')
  static FormatVolumeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormatVolumeRequest>(
          FormatVolumeRequest.$_createMessage);
  static FormatVolumeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get volumeId => $_getSZ(0);
  @$pb.TagNumber(1)
  set volumeId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVolumeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVolumeId() => $_clearField(1);
}

class FormatVolumeResponse extends $pb.GeneratedMessage {
  factory FormatVolumeResponse({
    $core.bool? success,
    $core.String? message,
    $core.String? mountPath,
    $core.String? error,
  }) {
    final result = FormatVolumeResponse._();
    if (success != null) result.success = success;
    if (message != null) result.message = message;
    if (mountPath != null) result.mountPath = mountPath;
    if (error != null) result.error = error;
    return result;
  }

  FormatVolumeResponse._();

  factory FormatVolumeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatVolumeResponse()..mergeFromBuffer(data, registry);
  factory FormatVolumeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FormatVolumeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FormatVolumeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: FormatVolumeResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..aOS(3, _omitFieldNames ? '' : 'mountPath')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatVolumeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FormatVolumeResponse copyWith(void Function(FormatVolumeResponse) updates) =>
      super.copyWith((message) => updates(message as FormatVolumeResponse))
          as FormatVolumeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use FormatVolumeResponse() / FormatVolumeResponse.new instead')
  static FormatVolumeResponse create() => FormatVolumeResponse._();
  static $pb.GeneratedMessage $_createMessage() => FormatVolumeResponse._();
  @$core.override
  FormatVolumeResponse createEmptyInstance() => FormatVolumeResponse._();
  @$core.pragma('dart2js:noInline')
  static FormatVolumeResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FormatVolumeResponse>(
          FormatVolumeResponse.$_createMessage);
  static FormatVolumeResponse? _defaultInstance;

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
  $core.String get mountPath => $_getSZ(2);
  @$pb.TagNumber(3)
  set mountPath($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMountPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearMountPath() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
}

/// StorageService manages recording storage limits and external drive cleanup.
///
/// HTTP mapping (QualitySettingsApiHandler + ExternalStorageApiHandler + FormatStorageApiHandler):
///   GetStorageSettings         GET  /api/settings/storage
///   SetStorageSettings         POST /api/settings/storage
///   PreviewStorageLimitChange  POST /api/settings/storage/preview
///   GetExternalStorage         GET  /api/storage/external
///   SetExternalConfig          POST /api/storage/external/config
///   TriggerCleanup             POST /api/storage/external/cleanup
///   PreviewCleanup             GET  /api/storage/external/preview
///   RefreshExternalStorage     POST /api/storage/external/refresh
///   ListFormatVolumes          GET  /api/storage/format
///   FormatVolume               POST /api/storage/format
class StorageServiceApi {
  final $pb.RpcClient _client;

  StorageServiceApi(this._client);

  $async.Future<GetStorageSettingsResponse> getStorageSettings(
          $pb.ClientContext? ctx, GetStorageSettingsRequest request) =>
      _client.invoke<GetStorageSettingsResponse>(ctx, 'StorageService',
          'GetStorageSettings', request, GetStorageSettingsResponse());
  $async.Future<SetStorageSettingsResponse> setStorageSettings(
          $pb.ClientContext? ctx, SetStorageSettingsRequest request) =>
      _client.invoke<SetStorageSettingsResponse>(ctx, 'StorageService',
          'SetStorageSettings', request, SetStorageSettingsResponse());

  /// BladeWatch-gyg1.4: a separate, read-only RPC -- deliberately not a "dry run" flag on
  /// SetStorageSettings -- so a client can preview a lowered limit's real impact with a
  /// guarantee that SetStorageSettings itself was never called, and therefore nothing was
  /// written and no cleanup ran.
  $async.Future<PreviewStorageLimitChangeResponse> previewStorageLimitChange(
          $pb.ClientContext? ctx, PreviewStorageLimitChangeRequest request) =>
      _client.invoke<PreviewStorageLimitChangeResponse>(
          ctx,
          'StorageService',
          'PreviewStorageLimitChange',
          request,
          PreviewStorageLimitChangeResponse());
  $async.Future<GetExternalStorageResponse> getExternalStorage(
          $pb.ClientContext? ctx, GetExternalStorageRequest request) =>
      _client.invoke<GetExternalStorageResponse>(ctx, 'StorageService',
          'GetExternalStorage', request, GetExternalStorageResponse());
  $async.Future<SetExternalConfigResponse> setExternalConfig(
          $pb.ClientContext? ctx, SetExternalConfigRequest request) =>
      _client.invoke<SetExternalConfigResponse>(ctx, 'StorageService',
          'SetExternalConfig', request, SetExternalConfigResponse());
  $async.Future<TriggerCleanupResponse> triggerCleanup(
          $pb.ClientContext? ctx, TriggerCleanupRequest request) =>
      _client.invoke<TriggerCleanupResponse>(ctx, 'StorageService',
          'TriggerCleanup', request, TriggerCleanupResponse());
  $async.Future<PreviewCleanupResponse> previewCleanup(
          $pb.ClientContext? ctx, PreviewCleanupRequest request) =>
      _client.invoke<PreviewCleanupResponse>(ctx, 'StorageService',
          'PreviewCleanup', request, PreviewCleanupResponse());
  $async.Future<RefreshExternalStorageResponse> refreshExternalStorage(
          $pb.ClientContext? ctx, RefreshExternalStorageRequest request) =>
      _client.invoke<RefreshExternalStorageResponse>(ctx, 'StorageService',
          'RefreshExternalStorage', request, RefreshExternalStorageResponse());
  $async.Future<ListFormatVolumesResponse> listFormatVolumes(
          $pb.ClientContext? ctx, ListFormatVolumesRequest request) =>
      _client.invoke<ListFormatVolumesResponse>(ctx, 'StorageService',
          'ListFormatVolumes', request, ListFormatVolumesResponse());
  $async.Future<FormatVolumeResponse> formatVolume(
          $pb.ClientContext? ctx, FormatVolumeRequest request) =>
      _client.invoke<FormatVolumeResponse>(ctx, 'StorageService',
          'FormatVolume', request, FormatVolumeResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
