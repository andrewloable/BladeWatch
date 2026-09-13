import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/rpc/connect_client.dart';
import 'package:bladewatch_ui/rpc/connect_error.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';

class _FakeJwtSource implements JwtSource {
  String? nextJwt;
  int version = 0;
  int mintCount = 0;

  @override
  Future<String?> mintJwt() async {
    mintCount++;
    return nextJwt;
  }

  @override
  Future<int> stateVersion() async => version;
}

void main() {
  group('ConnectClient', () {
    late _FakeJwtSource jwtSource;
    late DateTime now;
    late ConnectClient client;
    late List<(Uri, Map<String, String>, String)> sentRequests;
    late RawHttpResponse Function(Uri uri, Map<String, String> headers, String body) respondWith;

    setUp(() {
      jwtSource = _FakeJwtSource()..nextJwt = 'jwt-1';
      now = DateTime(2026, 1, 1, 12, 0, 0);
      sentRequests = [];
      respondWith = (uri, headers, body) => const RawHttpResponse(200, '{}');
      client = ConnectClient(
        jwtSource: jwtSource,
        baseUrl: Uri.parse('http://127.0.0.1:8080'),
        now: () => now,
        send: (uri, headers, body) async {
          sentRequests.add((uri, headers, body));
          return respondWith(uri, headers, body);
        },
      );
    });

    test('posts to /bladewatch.v1.<Service>/<Method> with the encoded request', () async {
      respondWith = (uri, headers, body) => const RawHttpResponse(200, '{"deviceId":"byd-1"}');

      final result = await client.call<Map<String, dynamic>>(
        'SystemService',
        'GetStatus',
        _FakeMessage({'foo': 'bar'}),
        (json) => Map<String, dynamic>.from(json as Map),
      );

      expect(result, {'deviceId': 'byd-1'});
      expect(sentRequests, hasLength(1));
      final (uri, headers, body) = sentRequests.single;
      expect(uri, Uri.parse('http://127.0.0.1:8080/bladewatch.v1.SystemService/GetStatus'));
      expect(body, '{"foo":"bar"}');
    });

    test('sets Content-Type, Connect-Protocol-Version, and Authorization headers', () async {
      await client.call<void>('AuthService', 'Login', _FakeMessage({}), (_) {});

      final (_, headers, _) = sentRequests.single;
      expect(headers['Content-Type'], 'application/json');
      expect(headers['Connect-Protocol-Version'], '1');
      expect(headers['Authorization'], 'Bearer jwt-1');
    });

    test('omits Authorization when no JWT is available yet', () async {
      jwtSource.nextJwt = null;

      await client.call<void>('AuthService', 'Login', _FakeMessage({}), (_) {});

      final (_, headers, _) = sentRequests.single;
      expect(headers.containsKey('Authorization'), isFalse);
    });

    test('caches the JWT across calls within the TTL and same state version', () async {
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});

      expect(jwtSource.mintCount, 1);
    });

    test('re-mints once the cache TTL (4 minutes) elapses', () async {
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});
      now = now.add(const Duration(minutes: 4, seconds: 1));
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});

      expect(jwtSource.mintCount, 2);
    });

    test('does not yet re-mint just under the cache TTL', () async {
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});
      now = now.add(const Duration(minutes: 3, seconds: 59));
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});

      expect(jwtSource.mintCount, 1);
    });

    test('re-mints immediately when the state version changes, even within the TTL', () async {
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});
      jwtSource.version = 1;
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});

      expect(jwtSource.mintCount, 2);
    });

    test('invalidate() forces the next call to re-mint', () async {
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});
      client.invalidate();
      await client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {});

      expect(jwtSource.mintCount, 2);
    });

    test('a non-2xx response throws a typed ConnectError decoded from the body', () async {
      respondWith = (uri, headers, body) =>
          const RawHttpResponse(404, '{"code":"not_found","message":"Service not registered: X"}');

      await expectLater(
        () => client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {}),
        throwsA(
          isA<ConnectError>()
              .having((e) => e.httpStatus, 'httpStatus', 404)
              .having((e) => e.code, 'code', 'not_found')
              .having((e) => e.message, 'message', 'Service not registered: X'),
        ),
      );
    });

    test('an error response with an unparseable body still throws ConnectError, not a raw string', () async {
      respondWith = (uri, headers, body) => const RawHttpResponse(500, 'not json at all');

      await expectLater(
        () => client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {}),
        throwsA(isA<ConnectError>().having((e) => e.httpStatus, 'httpStatus', 500)),
      );
    });

    test('an empty success body decodes as an empty object, not a crash', () async {
      respondWith = (uri, headers, body) => const RawHttpResponse(200, '');

      final result = await client.call<Map<String, dynamic>>(
        'AuthService',
        'Logout',
        _FakeMessage({}),
        (json) => Map<String, dynamic>.from(json as Map? ?? const {}),
      );

      expect(result, <String, dynamic>{});
    });

    test('a send() that throws TimeoutException surfaces as a deadline_exceeded ConnectError', () async {
      client = ConnectClient(
        jwtSource: jwtSource,
        baseUrl: Uri.parse('http://127.0.0.1:8080'),
        now: () => now,
        send: (uri, headers, body) => Future<RawHttpResponse>.error(
          TimeoutException('timed out', const Duration(seconds: 10)),
        ),
      );

      await expectLater(
        () => client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {}),
        throwsA(
          isA<ConnectError>()
              .having((e) => e.httpStatus, 'httpStatus', 0)
              .having((e) => e.code, 'code', 'deadline_exceeded'),
        ),
      );
    });

    test('defaults baseUrl to 127.0.0.1:8080 and builds a real sender when neither is given', () {
      final defaultClient = ConnectClient(jwtSource: jwtSource);

      expect(defaultClient.baseUrl, Uri.parse('http://127.0.0.1:8080'));
    });

    test('a send() that fails to connect (daemon not running) surfaces as an unavailable ConnectError', () async {
      client = ConnectClient(
        jwtSource: jwtSource,
        baseUrl: Uri.parse('http://127.0.0.1:8080'),
        now: () => now,
        send: (uri, headers, body) => Future<RawHttpResponse>.error(
          const SocketException('Connection refused'),
        ),
      );

      await expectLater(
        () => client.call<void>('SystemService', 'GetStatus', _FakeMessage({}), (_) {}),
        throwsA(
          isA<ConnectError>()
              .having((e) => e.httpStatus, 'httpStatus', 0)
              .having((e) => e.code, 'code', 'unavailable'),
        ),
      );
    });
  });
}

/// Stands in for a real `GeneratedMessage` in these tests — `ConnectClient`
/// only ever needs `.toProto3Json()` from whatever it's handed.
class _FakeMessage {
  final Map<String, dynamic> _json;
  const _FakeMessage(this._json);
  Map<String, dynamic> toProto3Json() => _json;
}
