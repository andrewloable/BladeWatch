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

import 'package:protobuf/protobuf.dart' as $pb;

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart' as $0;
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pbjson.dart';

export 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';

abstract class RecordingsServiceBase extends $pb.GeneratedService {
  $async.Future<$0.ListRecordingsResponse> listRecordings(
      $pb.ServerContext ctx, $0.ListRecordingsRequest request);
  $async.Future<$0.GetDatesResponse> getDates(
      $pb.ServerContext ctx, $0.GetDatesRequest request);
  $async.Future<$0.GetStatsResponse> getStats(
      $pb.ServerContext ctx, $0.GetStatsRequest request);
  $async.Future<$0.DeleteRecordingResponse> deleteRecording(
      $pb.ServerContext ctx, $0.DeleteRecordingRequest request);
  $async.Future<$0.BatchDeleteResponse> batchDelete(
      $pb.ServerContext ctx, $0.BatchDeleteRequest request);
  $async.Future<$0.SyncCatalogResponse> syncCatalog(
      $pb.ServerContext ctx, $0.SyncCatalogRequest request);
  $async.Future<$0.GetInflightStatusResponse> getInflightStatus(
      $pb.ServerContext ctx, $0.GetInflightStatusRequest request);
  $async.Future<$0.GetEventTimelineResponse> getEventTimeline(
      $pb.ServerContext ctx, $0.GetEventTimelineRequest request);
  $async.Future<$0.MarkRecordingResponse> markRecording(
      $pb.ServerContext ctx, $0.MarkRecordingRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'ListRecordings':
        return $0.ListRecordingsRequest();
      case 'GetDates':
        return $0.GetDatesRequest();
      case 'GetStats':
        return $0.GetStatsRequest();
      case 'DeleteRecording':
        return $0.DeleteRecordingRequest();
      case 'BatchDelete':
        return $0.BatchDeleteRequest();
      case 'SyncCatalog':
        return $0.SyncCatalogRequest();
      case 'GetInflightStatus':
        return $0.GetInflightStatusRequest();
      case 'GetEventTimeline':
        return $0.GetEventTimelineRequest();
      case 'MarkRecording':
        return $0.MarkRecordingRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'ListRecordings':
        return listRecordings(ctx, request as $0.ListRecordingsRequest);
      case 'GetDates':
        return getDates(ctx, request as $0.GetDatesRequest);
      case 'GetStats':
        return getStats(ctx, request as $0.GetStatsRequest);
      case 'DeleteRecording':
        return deleteRecording(ctx, request as $0.DeleteRecordingRequest);
      case 'BatchDelete':
        return batchDelete(ctx, request as $0.BatchDeleteRequest);
      case 'SyncCatalog':
        return syncCatalog(ctx, request as $0.SyncCatalogRequest);
      case 'GetInflightStatus':
        return getInflightStatus(ctx, request as $0.GetInflightStatusRequest);
      case 'GetEventTimeline':
        return getEventTimeline(ctx, request as $0.GetEventTimelineRequest);
      case 'MarkRecording':
        return markRecording(ctx, request as $0.MarkRecordingRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json =>
      RecordingsServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => RecordingsServiceBase$messageJson;
}
