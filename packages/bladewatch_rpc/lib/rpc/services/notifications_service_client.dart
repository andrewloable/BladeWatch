// Hand-written Connect RPC wrapper for bladewatch.v1.NotificationsService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/notifications.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class NotificationsServiceClient {
  final RpcTransport _transport;

  const NotificationsServiceClient(this._transport);

  Future<GetCategoriesResponse> getCategories(GetCategoriesRequest request) => _transport.call(
        'NotificationsService',
        'GetCategories',
        request,
        (json) => GetCategoriesResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<SendTestResponse> sendTest(SendTestRequest request) => _transport.call(
        'NotificationsService',
        'SendTest',
        request,
        (json) => SendTestResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<ListInboxResponse> listInbox(ListInboxRequest request) => _transport.call(
        'NotificationsService',
        'ListInbox',
        request,
        (json) => ListInboxResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

}
