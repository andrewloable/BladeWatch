// Hand-written Connect RPC wrapper for bladewatch.v1.RecordingsService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_ui/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_ui/rpc/rpc_transport.dart';

class RecordingsServiceClient {
  final RpcTransport _transport;

  const RecordingsServiceClient(this._transport);

  Future<ListRecordingsResponse> listRecordings(ListRecordingsRequest request) => _transport.call(
        'RecordingsService',
        'ListRecordings',
        request,
        (json) => ListRecordingsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetDatesResponse> getDates(GetDatesRequest request) => _transport.call(
        'RecordingsService',
        'GetDates',
        request,
        (json) => GetDatesResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetStatsResponse> getStats(GetStatsRequest request) => _transport.call(
        'RecordingsService',
        'GetStats',
        request,
        (json) => GetStatsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<DeleteRecordingResponse> deleteRecording(DeleteRecordingRequest request) => _transport.call(
        'RecordingsService',
        'DeleteRecording',
        request,
        (json) => DeleteRecordingResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<BatchDeleteResponse> batchDelete(BatchDeleteRequest request) => _transport.call(
        'RecordingsService',
        'BatchDelete',
        request,
        (json) => BatchDeleteResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SyncCatalogResponse> syncCatalog(SyncCatalogRequest request) => _transport.call(
        'RecordingsService',
        'SyncCatalog',
        request,
        (json) => SyncCatalogResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetInflightStatusResponse> getInflightStatus(GetInflightStatusRequest request) => _transport.call(
        'RecordingsService',
        'GetInflightStatus',
        request,
        (json) => GetInflightStatusResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetEventTimelineResponse> getEventTimeline(GetEventTimelineRequest request) => _transport.call(
        'RecordingsService',
        'GetEventTimeline',
        request,
        (json) => GetEventTimelineResponse()..mergeFromProto3Json(json ?? const {}),
      );

}
