// Hand-written Connect RPC wrapper for bladewatch.v1.SafeLocationsService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/safe_locations.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class SafeLocationsServiceClient {
  final RpcTransport _transport;

  const SafeLocationsServiceClient(this._transport);

  Future<ListZonesResponse> listZones(ListZonesRequest request) => _transport.call(
        'SafeLocationsService',
        'ListZones',
        request,
        (json) => ListZonesResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<AddZoneResponse> addZone(AddZoneRequest request) => _transport.call(
        'SafeLocationsService',
        'AddZone',
        request,
        (json) => AddZoneResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<UpdateZoneResponse> updateZone(UpdateZoneRequest request) => _transport.call(
        'SafeLocationsService',
        'UpdateZone',
        request,
        (json) => UpdateZoneResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<DeleteZoneResponse> deleteZone(DeleteZoneRequest request) => _transport.call(
        'SafeLocationsService',
        'DeleteZone',
        request,
        (json) => DeleteZoneResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<ToggleSafeLocationsResponse> toggle(ToggleSafeLocationsRequest request) => _transport.call(
        'SafeLocationsService',
        'Toggle',
        request,
        (json) => ToggleSafeLocationsResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

}
