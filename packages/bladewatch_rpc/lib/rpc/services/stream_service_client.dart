// Hand-written Connect RPC wrapper for bladewatch.v1.StreamService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class StreamServiceClient {
  final RpcTransport _transport;

  const StreamServiceClient(this._transport);

  Future<EnableStreamResponse> enable(EnableStreamRequest request) => _transport.call(
        'StreamService',
        'Enable',
        request,
        (json) => EnableStreamResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<DisableStreamResponse> disable(DisableStreamRequest request) => _transport.call(
        'StreamService',
        'Disable',
        request,
        (json) => DisableStreamResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetStreamStatusResponse> getStatus(GetStreamStatusRequest request) => _transport.call(
        'StreamService',
        'GetStatus',
        request,
        (json) => GetStreamStatusResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetStreamQualityResponse> getQuality(GetStreamQualityRequest request) => _transport.call(
        'StreamService',
        'GetQuality',
        request,
        (json) => GetStreamQualityResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetStreamQualityResponse> setQuality(SetStreamQualityRequest request) => _transport.call(
        'StreamService',
        'SetQuality',
        request,
        (json) => SetStreamQualityResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SetViewModeResponse> setViewMode(SetViewModeRequest request) => _transport.call(
        'StreamService',
        'SetViewMode',
        request,
        (json) => SetViewModeResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetViewModeResponse> getViewMode(GetViewModeRequest request) => _transport.call(
        'StreamService',
        'GetViewMode',
        request,
        (json) => GetViewModeResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

}
