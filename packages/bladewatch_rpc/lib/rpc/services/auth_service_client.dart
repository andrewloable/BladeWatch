// Hand-written Connect RPC wrapper for bladewatch.v1.AuthService
// (BladeWatch-ncbb.1). One thin method per RPC: encode the request via
// toProto3Json(), POST through RpcTransport, decode the response the same
// way — no logic of its own beyond that, by design (see ConnectClient).
import 'package:bladewatch_rpc/gen/bladewatch/v1/auth.pb.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

class AuthServiceClient {
  final RpcTransport _transport;

  const AuthServiceClient(this._transport);

  Future<LoginResponse> login(LoginRequest request) => _transport.call(
        'AuthService',
        'Login',
        request,
        (json) => LoginResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<LogoutResponse> logout(LogoutRequest request) => _transport.call(
        'AuthService',
        'Logout',
        request,
        (json) => LogoutResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<GetAuthStatusResponse> getAuthStatus(GetAuthStatusRequest request) => _transport.call(
        'AuthService',
        'GetAuthStatus',
        request,
        (json) => GetAuthStatusResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

  Future<InvalidateAuthCacheResponse> invalidateAuthCache(InvalidateAuthCacheRequest request) => _transport.call(
        'AuthService',
        'InvalidateAuthCache',
        request,
        (json) => InvalidateAuthCacheResponse()..mergeFromProto3Json(json ?? const {}, ignoreUnknownFields: true),
      );

}
