// Hand-written Connect RPC wrapper for bladewatch.v1.TripsService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_ui/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_ui/rpc/rpc_transport.dart';

class TripsServiceClient {
  final RpcTransport _transport;

  const TripsServiceClient(this._transport);

  Future<ListTripsResponse> listTrips(ListTripsRequest request) => _transport.call(
        'TripsService',
        'ListTrips',
        request,
        (json) => ListTripsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetTripResponse> getTrip(GetTripRequest request) => _transport.call(
        'TripsService',
        'GetTrip',
        request,
        (json) => GetTripResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<DeleteTripResponse> deleteTrip(DeleteTripRequest request) => _transport.call(
        'TripsService',
        'DeleteTrip',
        request,
        (json) => DeleteTripResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetSummaryResponse> getSummary(GetSummaryRequest request) => _transport.call(
        'TripsService',
        'GetSummary',
        request,
        (json) => GetSummaryResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetDnaResponse> getDna(GetDnaRequest request) => _transport.call(
        'TripsService',
        'GetDna',
        request,
        (json) => GetDnaResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetRangeResponse> getRange(GetRangeRequest request) => _transport.call(
        'TripsService',
        'GetRange',
        request,
        (json) => GetRangeResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetConfigResponse> getConfig(GetConfigRequest request) => _transport.call(
        'TripsService',
        'GetConfig',
        request,
        (json) => GetConfigResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetConfigResponse> setConfig(SetConfigRequest request) => _transport.call(
        'TripsService',
        'SetConfig',
        request,
        (json) => SetConfigResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetStorageResponse> getStorage(GetStorageRequest request) => _transport.call(
        'TripsService',
        'GetStorage',
        request,
        (json) => GetStorageResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SetStorageResponse> setStorage(SetStorageRequest request) => _transport.call(
        'TripsService',
        'SetStorage',
        request,
        (json) => SetStorageResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<SyncTripsResponse> syncTrips(SyncTripsRequest request) => _transport.call(
        'TripsService',
        'SyncTrips',
        request,
        (json) => SyncTripsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetTelemetryResponse> getTelemetry(GetTelemetryRequest request) => _transport.call(
        'TripsService',
        'GetTelemetry',
        request,
        (json) => GetTelemetryResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetSimilarTripsResponse> getSimilarTrips(GetSimilarTripsRequest request) => _transport.call(
        'TripsService',
        'GetSimilarTrips',
        request,
        (json) => GetSimilarTripsResponse()..mergeFromProto3Json(json ?? const {}),
      );

  Future<GetGpsTraceResponse> getGpsTrace(GetGpsTraceRequest request) => _transport.call(
        'TripsService',
        'GetGpsTrace',
        request,
        (json) => GetGpsTraceResponse()..mergeFromProto3Json(json ?? const {}),
      );

}
