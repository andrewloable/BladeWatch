// Hand-written Connect RPC wrapper for bladewatch.v1.SurveillanceService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class SurveillanceServiceClient {
  final RpcTransport _transport;

  const SurveillanceServiceClient(this._transport);

  Future<GetSurveillanceConfigResponse> getConfig(GetSurveillanceConfigRequest request) => _transport.call(
        'SurveillanceService',
        'GetConfig',
        request,
        (json) => GetSurveillanceConfigResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetSurveillanceConfigResponse> setConfig(SetSurveillanceConfigRequest request) => _transport.call(
        'SurveillanceService',
        'SetConfig',
        request,
        (json) => SetSurveillanceConfigResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetSurveillanceStatusResponse> getStatus(GetSurveillanceStatusRequest request) => _transport.call(
        'SurveillanceService',
        'GetStatus',
        request,
        (json) => GetSurveillanceStatusResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<EnableSurveillanceResponse> enable(EnableSurveillanceRequest request) => _transport.call(
        'SurveillanceService',
        'Enable',
        request,
        (json) => EnableSurveillanceResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<DisableSurveillanceResponse> disable(DisableSurveillanceRequest request) => _transport.call(
        'SurveillanceService',
        'Disable',
        request,
        (json) => DisableSurveillanceResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetHeatmapResponse> getHeatmap(GetHeatmapRequest request) => _transport.call(
        'SurveillanceService',
        'GetHeatmap',
        request,
        (json) => GetHeatmapResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetSnapshotResponse> getSnapshot(GetSnapshotRequest request) => _transport.call(
        'SurveillanceService',
        'GetSnapshot',
        request,
        (json) => GetSnapshotResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetFilterLogResponse> getFilterLog(GetFilterLogRequest request) => _transport.call(
        'SurveillanceService',
        'GetFilterLog',
        request,
        (json) => GetFilterLogResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SyncSurveillanceCatalogResponse> syncCatalog(SyncSurveillanceCatalogRequest request) => _transport.call(
        'SurveillanceService',
        'SyncCatalog',
        request,
        (json) => SyncSurveillanceCatalogResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

}
