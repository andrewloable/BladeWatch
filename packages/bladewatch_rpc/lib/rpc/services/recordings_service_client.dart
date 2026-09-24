// Hand-written Connect RPC wrapper for bladewatch.v1.RecordingsService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class RecordingsServiceClient {
  final RpcTransport _transport;

  const RecordingsServiceClient(this._transport);

  Future<ListRecordingsResponse> listRecordings(ListRecordingsRequest request) => _transport.call(
        'RecordingsService',
        'ListRecordings',
        request,
        (json) => ListRecordingsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetDatesResponse> getDates(GetDatesRequest request) => _transport.call(
        'RecordingsService',
        'GetDates',
        request,
        (json) => GetDatesResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetStatsResponse> getStats(GetStatsRequest request) => _transport.call(
        'RecordingsService',
        'GetStats',
        request,
        (json) => GetStatsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<DeleteRecordingResponse> deleteRecording(DeleteRecordingRequest request) => _transport.call(
        'RecordingsService',
        'DeleteRecording',
        request,
        (json) => DeleteRecordingResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<BatchDeleteResponse> batchDelete(BatchDeleteRequest request) => _transport.call(
        'RecordingsService',
        'BatchDelete',
        request,
        (json) => BatchDeleteResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SyncCatalogResponse> syncCatalog(SyncCatalogRequest request) => _transport.call(
        'RecordingsService',
        'SyncCatalog',
        request,
        (json) => SyncCatalogResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetInflightStatusResponse> getInflightStatus(GetInflightStatusRequest request) => _transport.call(
        'RecordingsService',
        'GetInflightStatus',
        request,
        (json) => GetInflightStatusResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetEventTimelineResponse> getEventTimeline(GetEventTimelineRequest request) => _transport.call(
        'RecordingsService',
        'GetEventTimeline',
        request,
        (json) => GetEventTimelineResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<MarkRecordingResponse> markRecording(MarkRecordingRequest request) => _transport.call(
        'RecordingsService',
        'MarkRecording',
        request,
        (json) => MarkRecordingResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

}
