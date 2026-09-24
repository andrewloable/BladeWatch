import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/auth.pb.dart';
import 'package:bladewatch_rpc/rpc/services/auth_service_client.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('AuthServiceClient', () {
    late FakeRpcClient fake;
    late AuthServiceClient client;

    setUp(() {
      fake = FakeRpcClient();
      client = AuthServiceClient(fake);
    });

    test('login sends AuthService/Login and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => LoginResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('AuthService', 'Login', <String, dynamic>{});

      final result = await client.login(LoginRequest());

      expect(result, isA<LoginResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'AuthService');
      expect(fake.calls.single.method, 'Login');
      expect(fake.calls.single.request, isA<LoginRequest>());
    });

    test('logout sends AuthService/Logout and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => LogoutResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('AuthService', 'Logout', <String, dynamic>{});

      final result = await client.logout(LogoutRequest());

      expect(result, isA<LogoutResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'AuthService');
      expect(fake.calls.single.method, 'Logout');
      expect(fake.calls.single.request, isA<LogoutRequest>());
    });

    test('getAuthStatus sends AuthService/GetAuthStatus and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => GetAuthStatusResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('AuthService', 'GetAuthStatus', <String, dynamic>{});

      final result = await client.getAuthStatus(GetAuthStatusRequest());

      expect(result, isA<GetAuthStatusResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'AuthService');
      expect(fake.calls.single.method, 'GetAuthStatus');
      expect(fake.calls.single.request, isA<GetAuthStatusRequest>());
    });

    test('invalidateAuthCache sends AuthService/InvalidateAuthCache and decodes a real proto3Json response', () async {
      // stubJson (not stub) so the wrapper's own decode closure — 
      // '(json) => InvalidateAuthCacheResponse()..mergeFromProto3Json(json)' — actually runs.
      fake.stubJson('AuthService', 'InvalidateAuthCache', <String, dynamic>{});

      final result = await client.invalidateAuthCache(InvalidateAuthCacheRequest());

      expect(result, isA<InvalidateAuthCacheResponse>());
      expect(fake.calls, hasLength(1));
      expect(fake.calls.single.service, 'AuthService');
      expect(fake.calls.single.method, 'InvalidateAuthCache');
      expect(fake.calls.single.request, isA<InvalidateAuthCacheRequest>());
    });

  });
}
