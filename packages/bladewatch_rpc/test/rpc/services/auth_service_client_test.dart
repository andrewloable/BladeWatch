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
