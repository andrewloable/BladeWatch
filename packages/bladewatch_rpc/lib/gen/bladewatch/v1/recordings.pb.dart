// This is a generated file - do not edit.
//
// Generated from bladewatch/v1/recordings.proto.

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

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pbenum.dart';

/// RecordingEntry represents one video clip in the catalog.
class RecordingEntry extends $pb.GeneratedMessage {
  factory RecordingEntry({
    $core.String? filename,
    $core.String? path,
    RecordingType? type,
    $fixnum.Int64? timestampMs,
    $fixnum.Int64? sizeBytes,
    $fixnum.Int64? durationSeconds,
    $core.String? dateLabel,
    $core.String? timeLabel,
    $core.bool? hasEvents,
    $core.Iterable<$core.String>? detectedClasses,
    $core.String? severity,
    $core.String? proximity,
    $core.bool? marked,
    $fixnum.Int64? markedAtMs,
  }) {
    final result = RecordingEntry._();
    if (filename != null) result.filename = filename;
    if (path != null) result.path = path;
    if (type != null) result.type = type;
    if (timestampMs != null) result.timestampMs = timestampMs;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (durationSeconds != null) result.durationSeconds = durationSeconds;
    if (dateLabel != null) result.dateLabel = dateLabel;
    if (timeLabel != null) result.timeLabel = timeLabel;
    if (hasEvents != null) result.hasEvents = hasEvents;
    if (detectedClasses != null) result.detectedClasses.addAll(detectedClasses);
    if (severity != null) result.severity = severity;
    if (proximity != null) result.proximity = proximity;
    if (marked != null) result.marked = marked;
    if (markedAtMs != null) result.markedAtMs = markedAtMs;
    return result;
  }

  RecordingEntry._();

  factory RecordingEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecordingEntry()..mergeFromBuffer(data, registry);
  factory RecordingEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecordingEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecordingEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: RecordingEntry.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aE<RecordingType>(3, _omitFieldNames ? '' : 'type',
        enumValues: RecordingType.values)
    ..aInt64(4, _omitFieldNames ? '' : 'timestamp', protoName: 'timestamp_ms')
    ..aInt64(5, _omitFieldNames ? '' : 'size', protoName: 'size_bytes')
    ..aInt64(6, _omitFieldNames ? '' : 'durationSeconds')
    ..aOS(7, _omitFieldNames ? '' : 'dateFormatted', protoName: 'date_label')
    ..aOS(8, _omitFieldNames ? '' : 'timeFormatted', protoName: 'time_label')
    ..aOB(9, _omitFieldNames ? '' : 'hasEvents')
    ..pPS(10, _omitFieldNames ? '' : 'detectedClasses')
    ..aOS(11, _omitFieldNames ? '' : 'peakSeverity', protoName: 'severity')
    ..aOS(12, _omitFieldNames ? '' : 'peakProximity', protoName: 'proximity')
    ..aOB(13, _omitFieldNames ? '' : 'marked')
    ..aInt64(14, _omitFieldNames ? '' : 'markedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecordingEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecordingEntry copyWith(void Function(RecordingEntry) updates) =>
      super.copyWith((message) => updates(message as RecordingEntry))
          as RecordingEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RecordingEntry() / RecordingEntry.new instead')
  static RecordingEntry create() => RecordingEntry._();
  static $pb.GeneratedMessage $_createMessage() => RecordingEntry._();
  @$core.override
  RecordingEntry createEmptyInstance() => RecordingEntry._();
  @$core.pragma('dart2js:noInline')
  static RecordingEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingEntry>(
          RecordingEntry.$_createMessage);
  static RecordingEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  RecordingType get type => $_getN(2);
  @$pb.TagNumber(3)
  set type(RecordingType value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasType() => $_has(2);
  @$pb.TagNumber(3)
  void clearType() => $_clearField(3);

  /// Epoch ms extracted from the filename timestamp.
  @$pb.TagNumber(4)
  $fixnum.Int64 get timestampMs => $_getI64(3);
  @$pb.TagNumber(4)
  set timestampMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimestampMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestampMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sizeBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSizeBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSizeBytes() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get durationSeconds => $_getI64(5);
  @$pb.TagNumber(6)
  set durationSeconds($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDurationSeconds() => $_has(5);
  @$pb.TagNumber(6)
  void clearDurationSeconds() => $_clearField(6);

  /// Human-readable date string, e.g. "Jun 8, 2026".
  @$pb.TagNumber(7)
  $core.String get dateLabel => $_getSZ(6);
  @$pb.TagNumber(7)
  set dateLabel($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDateLabel() => $_has(6);
  @$pb.TagNumber(7)
  void clearDateLabel() => $_clearField(7);

  /// Human-readable time string, e.g. "03:42 PM".
  @$pb.TagNumber(8)
  $core.String get timeLabel => $_getSZ(7);
  @$pb.TagNumber(8)
  set timeLabel($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTimeLabel() => $_has(7);
  @$pb.TagNumber(8)
  void clearTimeLabel() => $_clearField(8);

  /// Whether a JSON sidecar with event timeline exists for this clip.
  @$pb.TagNumber(9)
  $core.bool get hasEvents => $_getBF(8);
  @$pb.TagNumber(9)
  set hasEvents($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasHasEvents() => $_has(8);
  @$pb.TagNumber(9)
  void clearHasEvents() => $_clearField(9);

  /// AI detection classes present in sidecar (e.g. "person", "vehicle").
  @$pb.TagNumber(10)
  $pb.PbList<$core.String> get detectedClasses => $_getList(9);

  @$pb.TagNumber(11)
  $core.String get severity => $_getSZ(10);
  @$pb.TagNumber(11)
  set severity($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasSeverity() => $_has(10);
  @$pb.TagNumber(11)
  void clearSeverity() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get proximity => $_getSZ(11);
  @$pb.TagNumber(12)
  set proximity($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasProximity() => $_has(11);
  @$pb.TagNumber(12)
  void clearProximity() => $_clearField(12);

  /// Set by MarkRecording while this clip was being written. Excluded from
  /// automatic storage cleanup -- see StorageManager.ensureSpace.
  @$pb.TagNumber(13)
  $core.bool get marked => $_getBF(12);
  @$pb.TagNumber(13)
  set marked($core.bool value) => $_setBool(12, value);
  @$pb.TagNumber(13)
  $core.bool hasMarked() => $_has(12);
  @$pb.TagNumber(13)
  void clearMarked() => $_clearField(13);

  @$pb.TagNumber(14)
  $fixnum.Int64 get markedAtMs => $_getI64(13);
  @$pb.TagNumber(14)
  set markedAtMs($fixnum.Int64 value) => $_setInt64(13, value);
  @$pb.TagNumber(14)
  $core.bool hasMarkedAtMs() => $_has(13);
  @$pb.TagNumber(14)
  void clearMarkedAtMs() => $_clearField(14);
}

class ListRecordingsRequest extends $pb.GeneratedMessage {
  factory ListRecordingsRequest({
    $core.String? type,
    $core.String? date,
    $core.int? page,
    $core.int? pageSize,
    $core.String? classFilter,
    $core.String? severityFilter,
    $core.String? proximityFilter,
  }) {
    final result = ListRecordingsRequest._();
    if (type != null) result.type = type;
    if (date != null) result.date = date;
    if (page != null) result.page = page;
    if (pageSize != null) result.pageSize = pageSize;
    if (classFilter != null) result.classFilter = classFilter;
    if (severityFilter != null) result.severityFilter = severityFilter;
    if (proximityFilter != null) result.proximityFilter = proximityFilter;
    return result;
  }

  ListRecordingsRequest._();

  factory ListRecordingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRecordingsRequest()..mergeFromBuffer(data, registry);
  factory ListRecordingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRecordingsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRecordingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListRecordingsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOS(2, _omitFieldNames ? '' : 'date')
    ..aI(3, _omitFieldNames ? '' : 'page')
    ..aI(4, _omitFieldNames ? '' : 'pageSize')
    ..aOS(5, _omitFieldNames ? '' : 'classFilter')
    ..aOS(6, _omitFieldNames ? '' : 'severityFilter')
    ..aOS(7, _omitFieldNames ? '' : 'proximityFilter')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRecordingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRecordingsRequest copyWith(
          void Function(ListRecordingsRequest) updates) =>
      super.copyWith((message) => updates(message as ListRecordingsRequest))
          as ListRecordingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListRecordingsRequest() / ListRecordingsRequest.new instead')
  static ListRecordingsRequest create() => ListRecordingsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListRecordingsRequest._();
  @$core.override
  ListRecordingsRequest createEmptyInstance() => ListRecordingsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListRecordingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListRecordingsRequest>(
          ListRecordingsRequest.$_createMessage);
  static ListRecordingsRequest? _defaultInstance;

  /// One of: "normal", "sentry", "proximity". Empty = all.
  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// Filter by date string, e.g. "20260608". Empty = all dates.
  @$pb.TagNumber(2)
  $core.String get date => $_getSZ(1);
  @$pb.TagNumber(2)
  set date($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearDate() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get page => $_getIZ(2);
  @$pb.TagNumber(3)
  set page($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPage() => $_has(2);
  @$pb.TagNumber(3)
  void clearPage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get pageSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set pageSize($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPageSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearPageSize() => $_clearField(4);

  /// Comma-separated class groups: "person", "vehicle", "bike".
  @$pb.TagNumber(5)
  $core.String get classFilter => $_getSZ(4);
  @$pb.TagNumber(5)
  set classFilter($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClassFilter() => $_has(4);
  @$pb.TagNumber(5)
  void clearClassFilter() => $_clearField(5);

  /// Comma-separated severity levels: "ALERT", "CRITICAL".
  @$pb.TagNumber(6)
  $core.String get severityFilter => $_getSZ(5);
  @$pb.TagNumber(6)
  set severityFilter($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSeverityFilter() => $_has(5);
  @$pb.TagNumber(6)
  void clearSeverityFilter() => $_clearField(6);

  /// Comma-separated proximity bands: "VERY_CLOSE", "CLOSE".
  @$pb.TagNumber(7)
  $core.String get proximityFilter => $_getSZ(6);
  @$pb.TagNumber(7)
  set proximityFilter($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasProximityFilter() => $_has(6);
  @$pb.TagNumber(7)
  void clearProximityFilter() => $_clearField(7);
}

class ListRecordingsResponse extends $pb.GeneratedMessage {
  factory ListRecordingsResponse({
    $core.Iterable<RecordingEntry>? recordings,
    $core.int? total,
    $core.int? page,
    $core.int? pageSize,
  }) {
    final result = ListRecordingsResponse._();
    if (recordings != null) result.recordings.addAll(recordings);
    if (total != null) result.total = total;
    if (page != null) result.page = page;
    if (pageSize != null) result.pageSize = pageSize;
    return result;
  }

  ListRecordingsResponse._();

  factory ListRecordingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRecordingsResponse()..mergeFromBuffer(data, registry);
  factory ListRecordingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRecordingsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRecordingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: ListRecordingsResponse.$_createMessage)
    ..pPM<RecordingEntry>(1, _omitFieldNames ? '' : 'recordings',
        subBuilder: RecordingEntry.$_createMessage)
    ..aI(2, _omitFieldNames ? '' : 'total')
    ..aI(3, _omitFieldNames ? '' : 'page')
    ..aI(4, _omitFieldNames ? '' : 'pageSize')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRecordingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRecordingsResponse copyWith(
          void Function(ListRecordingsResponse) updates) =>
      super.copyWith((message) => updates(message as ListRecordingsResponse))
          as ListRecordingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use ListRecordingsResponse() / ListRecordingsResponse.new instead')
  static ListRecordingsResponse create() => ListRecordingsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListRecordingsResponse._();
  @$core.override
  ListRecordingsResponse createEmptyInstance() => ListRecordingsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListRecordingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListRecordingsResponse>(
          ListRecordingsResponse.$_createMessage);
  static ListRecordingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<RecordingEntry> get recordings => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get total => $_getIZ(1);
  @$pb.TagNumber(2)
  set total($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTotal() => $_has(1);
  @$pb.TagNumber(2)
  void clearTotal() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get page => $_getIZ(2);
  @$pb.TagNumber(3)
  set page($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPage() => $_has(2);
  @$pb.TagNumber(3)
  void clearPage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get pageSize => $_getIZ(3);
  @$pb.TagNumber(4)
  set pageSize($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPageSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearPageSize() => $_clearField(4);
}

class GetDatesRequest extends $pb.GeneratedMessage {
  factory GetDatesRequest() => GetDatesRequest._();

  GetDatesRequest._();

  factory GetDatesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDatesRequest()..mergeFromBuffer(data, registry);
  factory GetDatesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDatesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDatesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetDatesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDatesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDatesRequest copyWith(void Function(GetDatesRequest) updates) =>
      super.copyWith((message) => updates(message as GetDatesRequest))
          as GetDatesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetDatesRequest() / GetDatesRequest.new instead')
  static GetDatesRequest create() => GetDatesRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetDatesRequest._();
  @$core.override
  GetDatesRequest createEmptyInstance() => GetDatesRequest._();
  @$core.pragma('dart2js:noInline')
  static GetDatesRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetDatesRequest>(
          GetDatesRequest.$_createMessage);
  static GetDatesRequest? _defaultInstance;
}

class GetDatesResponse extends $pb.GeneratedMessage {
  factory GetDatesResponse({
    $core.Iterable<$core.String>? dates,
  }) {
    final result = GetDatesResponse._();
    if (dates != null) result.dates.addAll(dates);
    return result;
  }

  GetDatesResponse._();

  factory GetDatesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDatesResponse()..mergeFromBuffer(data, registry);
  factory GetDatesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetDatesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetDatesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetDatesResponse.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'dates')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDatesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetDatesResponse copyWith(void Function(GetDatesResponse) updates) =>
      super.copyWith((message) => updates(message as GetDatesResponse))
          as GetDatesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetDatesResponse() / GetDatesResponse.new instead')
  static GetDatesResponse create() => GetDatesResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetDatesResponse._();
  @$core.override
  GetDatesResponse createEmptyInstance() => GetDatesResponse._();
  @$core.pragma('dart2js:noInline')
  static GetDatesResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetDatesResponse>(
          GetDatesResponse.$_createMessage);
  static GetDatesResponse? _defaultInstance;

  /// Dates that have at least one recording, formatted as "yyyyMMdd".
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get dates => $_getList(0);
}

class RecordingStats extends $pb.GeneratedMessage {
  factory RecordingStats({
    $fixnum.Int64? recordingsSizeBytes,
    $fixnum.Int64? surveillanceSizeBytes,
    $fixnum.Int64? proximitySizeBytes,
    $core.int? recordingsCount,
    $core.int? surveillanceCount,
    $core.int? proximityCount,
    $fixnum.Int64? totalSizeBytes,
    $core.int? totalCount,
  }) {
    final result = RecordingStats._();
    if (recordingsSizeBytes != null)
      result.recordingsSizeBytes = recordingsSizeBytes;
    if (surveillanceSizeBytes != null)
      result.surveillanceSizeBytes = surveillanceSizeBytes;
    if (proximitySizeBytes != null)
      result.proximitySizeBytes = proximitySizeBytes;
    if (recordingsCount != null) result.recordingsCount = recordingsCount;
    if (surveillanceCount != null) result.surveillanceCount = surveillanceCount;
    if (proximityCount != null) result.proximityCount = proximityCount;
    if (totalSizeBytes != null) result.totalSizeBytes = totalSizeBytes;
    if (totalCount != null) result.totalCount = totalCount;
    return result;
  }

  RecordingStats._();

  factory RecordingStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecordingStats()..mergeFromBuffer(data, registry);
  factory RecordingStats.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RecordingStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecordingStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: RecordingStats.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'recordingsSizeBytes')
    ..aInt64(2, _omitFieldNames ? '' : 'surveillanceSizeBytes')
    ..aInt64(3, _omitFieldNames ? '' : 'proximitySizeBytes')
    ..aI(4, _omitFieldNames ? '' : 'recordingsCount')
    ..aI(5, _omitFieldNames ? '' : 'surveillanceCount')
    ..aI(6, _omitFieldNames ? '' : 'proximityCount')
    ..aInt64(7, _omitFieldNames ? '' : 'totalSizeBytes')
    ..aI(8, _omitFieldNames ? '' : 'totalCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecordingStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecordingStats copyWith(void Function(RecordingStats) updates) =>
      super.copyWith((message) => updates(message as RecordingStats))
          as RecordingStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RecordingStats() / RecordingStats.new instead')
  static RecordingStats create() => RecordingStats._();
  static $pb.GeneratedMessage $_createMessage() => RecordingStats._();
  @$core.override
  RecordingStats createEmptyInstance() => RecordingStats._();
  @$core.pragma('dart2js:noInline')
  static RecordingStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RecordingStats>(
          RecordingStats.$_createMessage);
  static RecordingStats? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get recordingsSizeBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set recordingsSizeBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecordingsSizeBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecordingsSizeBytes() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get surveillanceSizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set surveillanceSizeBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSurveillanceSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSurveillanceSizeBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get proximitySizeBytes => $_getI64(2);
  @$pb.TagNumber(3)
  set proximitySizeBytes($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProximitySizeBytes() => $_has(2);
  @$pb.TagNumber(3)
  void clearProximitySizeBytes() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get recordingsCount => $_getIZ(3);
  @$pb.TagNumber(4)
  set recordingsCount($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRecordingsCount() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecordingsCount() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get surveillanceCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set surveillanceCount($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSurveillanceCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearSurveillanceCount() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get proximityCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set proximityCount($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasProximityCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearProximityCount() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get totalSizeBytes => $_getI64(6);
  @$pb.TagNumber(7)
  set totalSizeBytes($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTotalSizeBytes() => $_has(6);
  @$pb.TagNumber(7)
  void clearTotalSizeBytes() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get totalCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set totalCount($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTotalCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearTotalCount() => $_clearField(8);
}

class GetStatsRequest extends $pb.GeneratedMessage {
  factory GetStatsRequest() => GetStatsRequest._();

  GetStatsRequest._();

  factory GetStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsRequest()..mergeFromBuffer(data, registry);
  factory GetStatsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStatsRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest copyWith(void Function(GetStatsRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatsRequest))
          as GetStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatsRequest() / GetStatsRequest.new instead')
  static GetStatsRequest create() => GetStatsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStatsRequest._();
  @$core.override
  GetStatsRequest createEmptyInstance() => GetStatsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStatsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatsRequest>(
          GetStatsRequest.$_createMessage);
  static GetStatsRequest? _defaultInstance;
}

class GetStatsResponse extends $pb.GeneratedMessage {
  factory GetStatsResponse({
    RecordingStats? stats,
  }) {
    final result = GetStatsResponse._();
    if (stats != null) result.stats = stats;
    return result;
  }

  GetStatsResponse._();

  factory GetStatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsResponse()..mergeFromBuffer(data, registry);
  factory GetStatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetStatsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetStatsResponse.$_createMessage)
    ..aOM<RecordingStats>(1, _omitFieldNames ? '' : 'stats',
        subBuilder: RecordingStats.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse copyWith(void Function(GetStatsResponse) updates) =>
      super.copyWith((message) => updates(message as GetStatsResponse))
          as GetStatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatsResponse() / GetStatsResponse.new instead')
  static GetStatsResponse create() => GetStatsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetStatsResponse._();
  @$core.override
  GetStatsResponse createEmptyInstance() => GetStatsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStatsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatsResponse>(
          GetStatsResponse.$_createMessage);
  static GetStatsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  RecordingStats get stats => $_getN(0);
  @$pb.TagNumber(1)
  set stats(RecordingStats value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStats() => $_has(0);
  @$pb.TagNumber(1)
  void clearStats() => $_clearField(1);
  @$pb.TagNumber(1)
  RecordingStats ensureStats() => $_ensure(0);
}

class DeleteRecordingRequest extends $pb.GeneratedMessage {
  factory DeleteRecordingRequest({
    $core.String? filename,
  }) {
    final result = DeleteRecordingRequest._();
    if (filename != null) result.filename = filename;
    return result;
  }

  DeleteRecordingRequest._();

  factory DeleteRecordingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRecordingRequest()..mergeFromBuffer(data, registry);
  factory DeleteRecordingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRecordingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRecordingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DeleteRecordingRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRecordingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRecordingRequest copyWith(
          void Function(DeleteRecordingRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteRecordingRequest))
          as DeleteRecordingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteRecordingRequest() / DeleteRecordingRequest.new instead')
  static DeleteRecordingRequest create() => DeleteRecordingRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteRecordingRequest._();
  @$core.override
  DeleteRecordingRequest createEmptyInstance() => DeleteRecordingRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteRecordingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteRecordingRequest>(
          DeleteRecordingRequest.$_createMessage);
  static DeleteRecordingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);
}

class DeleteRecordingResponse extends $pb.GeneratedMessage {
  factory DeleteRecordingResponse({
    $core.bool? success,
    $core.String? error,
  }) {
    final result = DeleteRecordingResponse._();
    if (success != null) result.success = success;
    if (error != null) result.error = error;
    return result;
  }

  DeleteRecordingResponse._();

  factory DeleteRecordingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRecordingResponse()..mergeFromBuffer(data, registry);
  factory DeleteRecordingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteRecordingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteRecordingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: DeleteRecordingResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRecordingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteRecordingResponse copyWith(
          void Function(DeleteRecordingResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteRecordingResponse))
          as DeleteRecordingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use DeleteRecordingResponse() / DeleteRecordingResponse.new instead')
  static DeleteRecordingResponse create() => DeleteRecordingResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteRecordingResponse._();
  @$core.override
  DeleteRecordingResponse createEmptyInstance() => DeleteRecordingResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteRecordingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteRecordingResponse>(
          DeleteRecordingResponse.$_createMessage);
  static DeleteRecordingResponse? _defaultInstance;

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

class BatchDeleteRequest extends $pb.GeneratedMessage {
  factory BatchDeleteRequest({
    $core.Iterable<$core.String>? filenames,
  }) {
    final result = BatchDeleteRequest._();
    if (filenames != null) result.filenames.addAll(filenames);
    return result;
  }

  BatchDeleteRequest._();

  factory BatchDeleteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchDeleteRequest()..mergeFromBuffer(data, registry);
  factory BatchDeleteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchDeleteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchDeleteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: BatchDeleteRequest.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'filenames')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchDeleteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchDeleteRequest copyWith(void Function(BatchDeleteRequest) updates) =>
      super.copyWith((message) => updates(message as BatchDeleteRequest))
          as BatchDeleteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BatchDeleteRequest() / BatchDeleteRequest.new instead')
  static BatchDeleteRequest create() => BatchDeleteRequest._();
  static $pb.GeneratedMessage $_createMessage() => BatchDeleteRequest._();
  @$core.override
  BatchDeleteRequest createEmptyInstance() => BatchDeleteRequest._();
  @$core.pragma('dart2js:noInline')
  static BatchDeleteRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchDeleteRequest>(
          BatchDeleteRequest.$_createMessage);
  static BatchDeleteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get filenames => $_getList(0);
}

class BatchDeleteResponse extends $pb.GeneratedMessage {
  factory BatchDeleteResponse({
    $core.bool? success,
    $core.int? deleted,
    $core.int? failed,
    $core.Iterable<$core.String>? errors,
  }) {
    final result = BatchDeleteResponse._();
    if (success != null) result.success = success;
    if (deleted != null) result.deleted = deleted;
    if (failed != null) result.failed = failed;
    if (errors != null) result.errors.addAll(errors);
    return result;
  }

  BatchDeleteResponse._();

  factory BatchDeleteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchDeleteResponse()..mergeFromBuffer(data, registry);
  factory BatchDeleteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BatchDeleteResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchDeleteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: BatchDeleteResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aI(2, _omitFieldNames ? '' : 'deleted')
    ..aI(3, _omitFieldNames ? '' : 'failed')
    ..pPS(4, _omitFieldNames ? '' : 'errors')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchDeleteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BatchDeleteResponse copyWith(void Function(BatchDeleteResponse) updates) =>
      super.copyWith((message) => updates(message as BatchDeleteResponse))
          as BatchDeleteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use BatchDeleteResponse() / BatchDeleteResponse.new instead')
  static BatchDeleteResponse create() => BatchDeleteResponse._();
  static $pb.GeneratedMessage $_createMessage() => BatchDeleteResponse._();
  @$core.override
  BatchDeleteResponse createEmptyInstance() => BatchDeleteResponse._();
  @$core.pragma('dart2js:noInline')
  static BatchDeleteResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchDeleteResponse>(
          BatchDeleteResponse.$_createMessage);
  static BatchDeleteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get deleted => $_getIZ(1);
  @$pb.TagNumber(2)
  set deleted($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeleted() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeleted() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get failed => $_getIZ(2);
  @$pb.TagNumber(3)
  set failed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFailed() => $_has(2);
  @$pb.TagNumber(3)
  void clearFailed() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get errors => $_getList(3);
}

class SyncCatalogRequest extends $pb.GeneratedMessage {
  factory SyncCatalogRequest() => SyncCatalogRequest._();

  SyncCatalogRequest._();

  factory SyncCatalogRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncCatalogRequest()..mergeFromBuffer(data, registry);
  factory SyncCatalogRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncCatalogRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncCatalogRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SyncCatalogRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncCatalogRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncCatalogRequest copyWith(void Function(SyncCatalogRequest) updates) =>
      super.copyWith((message) => updates(message as SyncCatalogRequest))
          as SyncCatalogRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SyncCatalogRequest() / SyncCatalogRequest.new instead')
  static SyncCatalogRequest create() => SyncCatalogRequest._();
  static $pb.GeneratedMessage $_createMessage() => SyncCatalogRequest._();
  @$core.override
  SyncCatalogRequest createEmptyInstance() => SyncCatalogRequest._();
  @$core.pragma('dart2js:noInline')
  static SyncCatalogRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncCatalogRequest>(
          SyncCatalogRequest.$_createMessage);
  static SyncCatalogRequest? _defaultInstance;
}

class SyncCatalogResponse extends $pb.GeneratedMessage {
  factory SyncCatalogResponse({
    $core.bool? success,
    $core.int? added,
    $core.int? removed,
    $core.String? error,
  }) {
    final result = SyncCatalogResponse._();
    if (success != null) result.success = success;
    if (added != null) result.added = added;
    if (removed != null) result.removed = removed;
    if (error != null) result.error = error;
    return result;
  }

  SyncCatalogResponse._();

  factory SyncCatalogResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncCatalogResponse()..mergeFromBuffer(data, registry);
  factory SyncCatalogResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SyncCatalogResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SyncCatalogResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: SyncCatalogResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aI(2, _omitFieldNames ? '' : 'added')
    ..aI(3, _omitFieldNames ? '' : 'removed')
    ..aOS(4, _omitFieldNames ? '' : 'error')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncCatalogResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SyncCatalogResponse copyWith(void Function(SyncCatalogResponse) updates) =>
      super.copyWith((message) => updates(message as SyncCatalogResponse))
          as SyncCatalogResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use SyncCatalogResponse() / SyncCatalogResponse.new instead')
  static SyncCatalogResponse create() => SyncCatalogResponse._();
  static $pb.GeneratedMessage $_createMessage() => SyncCatalogResponse._();
  @$core.override
  SyncCatalogResponse createEmptyInstance() => SyncCatalogResponse._();
  @$core.pragma('dart2js:noInline')
  static SyncCatalogResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SyncCatalogResponse>(
          SyncCatalogResponse.$_createMessage);
  static SyncCatalogResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get added => $_getIZ(1);
  @$pb.TagNumber(2)
  set added($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAdded() => $_has(1);
  @$pb.TagNumber(2)
  void clearAdded() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get removed => $_getIZ(2);
  @$pb.TagNumber(3)
  set removed($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRemoved() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemoved() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get error => $_getSZ(3);
  @$pb.TagNumber(4)
  set error($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
}

class GetInflightStatusRequest extends $pb.GeneratedMessage {
  factory GetInflightStatusRequest({
    $core.String? filename,
  }) {
    final result = GetInflightStatusRequest._();
    if (filename != null) result.filename = filename;
    return result;
  }

  GetInflightStatusRequest._();

  factory GetInflightStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetInflightStatusRequest()..mergeFromBuffer(data, registry);
  factory GetInflightStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetInflightStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInflightStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetInflightStatusRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInflightStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInflightStatusRequest copyWith(
          void Function(GetInflightStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetInflightStatusRequest))
          as GetInflightStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetInflightStatusRequest() / GetInflightStatusRequest.new instead')
  static GetInflightStatusRequest create() => GetInflightStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetInflightStatusRequest._();
  @$core.override
  GetInflightStatusRequest createEmptyInstance() =>
      GetInflightStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetInflightStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInflightStatusRequest>(
          GetInflightStatusRequest.$_createMessage);
  static GetInflightStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);
}

class GetInflightStatusResponse extends $pb.GeneratedMessage {
  factory GetInflightStatusResponse({
    $core.String? status,
  }) {
    final result = GetInflightStatusResponse._();
    if (status != null) result.status = status;
    return result;
  }

  GetInflightStatusResponse._();

  factory GetInflightStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetInflightStatusResponse()..mergeFromBuffer(data, registry);
  factory GetInflightStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetInflightStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInflightStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetInflightStatusResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInflightStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInflightStatusResponse copyWith(
          void Function(GetInflightStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetInflightStatusResponse))
          as GetInflightStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetInflightStatusResponse() / GetInflightStatusResponse.new instead')
  static GetInflightStatusResponse create() => GetInflightStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() =>
      GetInflightStatusResponse._();
  @$core.override
  GetInflightStatusResponse createEmptyInstance() =>
      GetInflightStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetInflightStatusResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInflightStatusResponse>(
          GetInflightStatusResponse.$_createMessage);
  static GetInflightStatusResponse? _defaultInstance;

  /// "recording", "finalizing", or "not_found".
  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

class GetEventTimelineRequest extends $pb.GeneratedMessage {
  factory GetEventTimelineRequest({
    $core.String? filename,
  }) {
    final result = GetEventTimelineRequest._();
    if (filename != null) result.filename = filename;
    return result;
  }

  GetEventTimelineRequest._();

  factory GetEventTimelineRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetEventTimelineRequest()..mergeFromBuffer(data, registry);
  factory GetEventTimelineRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetEventTimelineRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEventTimelineRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetEventTimelineRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'filename')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventTimelineRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventTimelineRequest copyWith(
          void Function(GetEventTimelineRequest) updates) =>
      super.copyWith((message) => updates(message as GetEventTimelineRequest))
          as GetEventTimelineRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetEventTimelineRequest() / GetEventTimelineRequest.new instead')
  static GetEventTimelineRequest create() => GetEventTimelineRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetEventTimelineRequest._();
  @$core.override
  GetEventTimelineRequest createEmptyInstance() => GetEventTimelineRequest._();
  @$core.pragma('dart2js:noInline')
  static GetEventTimelineRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetEventTimelineRequest>(
          GetEventTimelineRequest.$_createMessage);
  static GetEventTimelineRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get filename => $_getSZ(0);
  @$pb.TagNumber(1)
  set filename($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFilename() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilename() => $_clearField(1);
}

class MarkRecordingRequest extends $pb.GeneratedMessage {
  factory MarkRecordingRequest() => MarkRecordingRequest._();

  MarkRecordingRequest._();

  factory MarkRecordingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRecordingRequest()..mergeFromBuffer(data, registry);
  factory MarkRecordingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRecordingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkRecordingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: MarkRecordingRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRecordingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRecordingRequest copyWith(void Function(MarkRecordingRequest) updates) =>
      super.copyWith((message) => updates(message as MarkRecordingRequest))
          as MarkRecordingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MarkRecordingRequest() / MarkRecordingRequest.new instead')
  static MarkRecordingRequest create() => MarkRecordingRequest._();
  static $pb.GeneratedMessage $_createMessage() => MarkRecordingRequest._();
  @$core.override
  MarkRecordingRequest createEmptyInstance() => MarkRecordingRequest._();
  @$core.pragma('dart2js:noInline')
  static MarkRecordingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MarkRecordingRequest>(
          MarkRecordingRequest.$_createMessage);
  static MarkRecordingRequest? _defaultInstance;
}

class MarkRecordingResponse extends $pb.GeneratedMessage {
  factory MarkRecordingResponse({
    $core.bool? success,
    $core.String? reason,
    $core.String? filename,
    $fixnum.Int64? markTimestampMs,
  }) {
    final result = MarkRecordingResponse._();
    if (success != null) result.success = success;
    if (reason != null) result.reason = reason;
    if (filename != null) result.filename = filename;
    if (markTimestampMs != null) result.markTimestampMs = markTimestampMs;
    return result;
  }

  MarkRecordingResponse._();

  factory MarkRecordingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRecordingResponse()..mergeFromBuffer(data, registry);
  factory MarkRecordingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRecordingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkRecordingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: MarkRecordingResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'success')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..aOS(3, _omitFieldNames ? '' : 'filename')
    ..aInt64(4, _omitFieldNames ? '' : 'markTimestampMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRecordingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRecordingResponse copyWith(
          void Function(MarkRecordingResponse) updates) =>
      super.copyWith((message) => updates(message as MarkRecordingResponse))
          as MarkRecordingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use MarkRecordingResponse() / MarkRecordingResponse.new instead')
  static MarkRecordingResponse create() => MarkRecordingResponse._();
  static $pb.GeneratedMessage $_createMessage() => MarkRecordingResponse._();
  @$core.override
  MarkRecordingResponse createEmptyInstance() => MarkRecordingResponse._();
  @$core.pragma('dart2js:noInline')
  static MarkRecordingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MarkRecordingResponse>(
          MarkRecordingResponse.$_createMessage);
  static MarkRecordingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get success => $_getBF(0);
  @$pb.TagNumber(1)
  set success($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSuccess() => $_has(0);
  @$pb.TagNumber(1)
  void clearSuccess() => $_clearField(1);

  /// Populated only when success is false, e.g. "not_recording".
  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get filename => $_getSZ(2);
  @$pb.TagNumber(3)
  set filename($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFilename() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilename() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get markTimestampMs => $_getI64(3);
  @$pb.TagNumber(4)
  set markTimestampMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMarkTimestampMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearMarkTimestampMs() => $_clearField(4);
}

/// GetEventTimelineResponse carries the event-timeline sidecar verbatim as a JSON string blob.
/// The sidecar (EventTimelineCollector v3) is a rich object {version,durationMs,events[],actors[],
/// stats{},heroThumbnail} that does not map to flat fields; clients parse timeline_json themselves.
/// (was: repeated EventEntry events — a flat shape the emitter never produced.)
class GetEventTimelineResponse extends $pb.GeneratedMessage {
  factory GetEventTimelineResponse({
    $core.String? timelineJson,
  }) {
    final result = GetEventTimelineResponse._();
    if (timelineJson != null) result.timelineJson = timelineJson;
    return result;
  }

  GetEventTimelineResponse._();

  factory GetEventTimelineResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetEventTimelineResponse()..mergeFromBuffer(data, registry);
  factory GetEventTimelineResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetEventTimelineResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEventTimelineResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'bladewatch.v1'),
      createEmptyInstance: GetEventTimelineResponse.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'timelineJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventTimelineResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEventTimelineResponse copyWith(
          void Function(GetEventTimelineResponse) updates) =>
      super.copyWith((message) => updates(message as GetEventTimelineResponse))
          as GetEventTimelineResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use GetEventTimelineResponse() / GetEventTimelineResponse.new instead')
  static GetEventTimelineResponse create() => GetEventTimelineResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetEventTimelineResponse._();
  @$core.override
  GetEventTimelineResponse createEmptyInstance() =>
      GetEventTimelineResponse._();
  @$core.pragma('dart2js:noInline')
  static GetEventTimelineResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetEventTimelineResponse>(
          GetEventTimelineResponse.$_createMessage);
  static GetEventTimelineResponse? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get timelineJson => $_getSZ(0);
  @$pb.TagNumber(2)
  set timelineJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasTimelineJson() => $_has(0);
  @$pb.TagNumber(2)
  void clearTimelineJson() => $_clearField(2);
}

/// RecordingsService manages dashcam recordings, events, and storage statistics.
///
/// HTTP mapping:
///   ListRecordings      GET    /api/recordings
///   GetDates            GET    /api/recordings/dates
///   GetStats            GET    /api/recordings/stats
///   DeleteRecording     DELETE /api/recordings/{filename}
///   BatchDelete         POST   /api/recordings/batch-delete
///   SyncCatalog         POST   /api/recordings/sync
///   GetInflightStatus   GET    /api/recordings/inflight/{filename}
///   GetEventTimeline    GET    /api/events/{filename}
///   MarkRecording       POST   /api/recordings/mark
class RecordingsServiceApi {
  final $pb.RpcClient _client;

  RecordingsServiceApi(this._client);

  $async.Future<ListRecordingsResponse> listRecordings(
          $pb.ClientContext? ctx, ListRecordingsRequest request) =>
      _client.invoke<ListRecordingsResponse>(ctx, 'RecordingsService',
          'ListRecordings', request, ListRecordingsResponse());
  $async.Future<GetDatesResponse> getDates(
          $pb.ClientContext? ctx, GetDatesRequest request) =>
      _client.invoke<GetDatesResponse>(
          ctx, 'RecordingsService', 'GetDates', request, GetDatesResponse());
  $async.Future<GetStatsResponse> getStats(
          $pb.ClientContext? ctx, GetStatsRequest request) =>
      _client.invoke<GetStatsResponse>(
          ctx, 'RecordingsService', 'GetStats', request, GetStatsResponse());
  $async.Future<DeleteRecordingResponse> deleteRecording(
          $pb.ClientContext? ctx, DeleteRecordingRequest request) =>
      _client.invoke<DeleteRecordingResponse>(ctx, 'RecordingsService',
          'DeleteRecording', request, DeleteRecordingResponse());
  $async.Future<BatchDeleteResponse> batchDelete(
          $pb.ClientContext? ctx, BatchDeleteRequest request) =>
      _client.invoke<BatchDeleteResponse>(ctx, 'RecordingsService',
          'BatchDelete', request, BatchDeleteResponse());
  $async.Future<SyncCatalogResponse> syncCatalog(
          $pb.ClientContext? ctx, SyncCatalogRequest request) =>
      _client.invoke<SyncCatalogResponse>(ctx, 'RecordingsService',
          'SyncCatalog', request, SyncCatalogResponse());
  $async.Future<GetInflightStatusResponse> getInflightStatus(
          $pb.ClientContext? ctx, GetInflightStatusRequest request) =>
      _client.invoke<GetInflightStatusResponse>(ctx, 'RecordingsService',
          'GetInflightStatus', request, GetInflightStatusResponse());
  $async.Future<GetEventTimelineResponse> getEventTimeline(
          $pb.ClientContext? ctx, GetEventTimelineRequest request) =>
      _client.invoke<GetEventTimelineResponse>(ctx, 'RecordingsService',
          'GetEventTimeline', request, GetEventTimelineResponse());

  /// Bookmarks the recording currently being written (metadata only -- no new
  /// file, no split). No request fields: the server resolves "current" itself,
  /// since the caller (a Live View button) has no filename to give it.
  $async.Future<MarkRecordingResponse> markRecording(
          $pb.ClientContext? ctx, MarkRecordingRequest request) =>
      _client.invoke<MarkRecordingResponse>(ctx, 'RecordingsService',
          'MarkRecording', request, MarkRecordingResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
