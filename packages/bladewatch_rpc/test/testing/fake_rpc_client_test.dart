import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  group('FakeRpcClient', () {
    test('returns the stubbed response and records the call', () async {
      final client = FakeRpcClient();
      client.stub('SystemService', 'GetStatus', {'ok': true});

      final response = await client.call<Map<String, dynamic>>(
        'SystemService',
        'GetStatus',
        {'deviceId': 'byd-test'},
      );

      expect(response, {'ok': true});
      expect(client.calls, hasLength(1));
      expect(client.calls.single.service, 'SystemService');
      expect(client.calls.single.method, 'GetStatus');
      expect(client.calls.single.request, {'deviceId': 'byd-test'});
    });

    test('throws the stubbed ConnectError', () async {
      final client = FakeRpcClient();
      client.stubError('AuthService', 'Login', const ConnectError('unauthenticated', 'bad code'));

      await expectLater(
        () => client.call<void>('AuthService', 'Login', null),
        throwsA(isA<ConnectError>().having((e) => e.code, 'code', 'unauthenticated')),
      );
      // The call is still recorded even though it failed — controllers need
      // to be able to assert "it tried," not just "it succeeded."
      expect(client.calls, hasLength(1));
    });

    test('throws a timeout when stubbed', () async {
      final client = FakeRpcClient();
      client.stubTimeout('VehicleService', 'GetTyrePressure');

      await expectLater(
        () => client.call<void>('VehicleService', 'GetTyrePressure', null),
        throwsA(isA<RpcTimeoutException>()),
      );
    });

    test('throws StateError when nothing was stubbed for that call', () async {
      final client = FakeRpcClient();

      await expectLater(
        () => client.call<void>('TripsService', 'ListTrips', null),
        throwsA(isA<StateError>()),
      );
    });

    test('re-stubbing the same service/method replaces the previous stub', () async {
      final client = FakeRpcClient();
      client.stubError('UpdateService', 'CheckForUpdate', const ConnectError('unavailable', 'x'));
      client.stub('UpdateService', 'CheckForUpdate', {'hasUpdate': false});

      final response = await client.call<Map<String, dynamic>>(
        'UpdateService',
        'CheckForUpdate',
        null,
      );

      expect(response, {'hasUpdate': false});
    });

    test('different methods on the same service are stubbed independently', () async {
      final client = FakeRpcClient();
      client.stub('StorageService', 'ListRecordings', ['a.mp4']);
      client.stubError('StorageService', 'DeleteRecording', const ConnectError('not_found', 'x'));

      expect(await client.call<List>('StorageService', 'ListRecordings', null), ['a.mp4']);
      await expectLater(
        () => client.call<void>('StorageService', 'DeleteRecording', 'a.mp4'),
        throwsA(isA<ConnectError>()),
      );
    });

    group('stubJson', () {
      test('runs the raw value through the caller-supplied decode function', () async {
        final client = FakeRpcClient();
        client.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-9'});

        final response = await client.call<String>(
          'SystemService',
          'GetStatus',
          null,
          (json) => (json as Map)['deviceId'] as String,
        );

        expect(response, 'byd-9');
      });

      test('passes null through when the stubbed value is null (an empty response body)', () async {
        final client = FakeRpcClient();
        client.stubJson('AuthService', 'Logout', null);
        var decodeSawNull = false;

        await client.call<void>('AuthService', 'Logout', null, (json) {
          decodeSawNull = json == null;
        });

        expect(decodeSawNull, isTrue);
      });

      test('throws StateError if call() is given no decode function to run the stub through', () async {
        final client = FakeRpcClient();
        client.stubJson('SystemService', 'GetStatus', {});

        await expectLater(
          () => client.call<void>('SystemService', 'GetStatus', null),
          throwsA(isA<StateError>()),
        );
      });

      test('stubJson overrides a previous typed stub() for the same key, and vice versa', () async {
        final client = FakeRpcClient();
        client.stub('SystemService', 'GetStatus', 'typed-value');
        client.stubJson('SystemService', 'GetStatus', 'raw');
        expect(
          await client.call<String>('SystemService', 'GetStatus', null, (json) => '$json-decoded'),
          'raw-decoded',
        );

        client.stub('SystemService', 'GetStatus', 'typed-value-2');
        expect(await client.call<String>('SystemService', 'GetStatus', null), 'typed-value-2');
      });
    });

    group('stubError and stubTimeout also clear a previous stubJson', () {
      test('stubError', () async {
        final client = FakeRpcClient();
        client.stubJson('AuthService', 'Login', {});
        client.stubError('AuthService', 'Login', const ConnectError('unauthenticated', 'x'));

        await expectLater(
          () => client.call<void>('AuthService', 'Login', null, (_) {}),
          throwsA(isA<ConnectError>()),
        );
      });

      test('stubTimeout', () async {
        final client = FakeRpcClient();
        client.stubJson('AuthService', 'Login', {});
        client.stubTimeout('AuthService', 'Login');

        await expectLater(
          () => client.call<void>('AuthService', 'Login', null, (_) {}),
          throwsA(isA<RpcTimeoutException>()),
        );
      });
    });
  });

  // Pinned directly since the fake moved into this package's lib/ (BladeWatch-rdtj.10): before,
  // only flutter_ui's screen tests reached these paths.
  group('FakeRpcClient in-flight and diagnostics', () {
    test('stubPending holds the call open until completed, then decodes', () async {
      final fake = FakeRpcClient();
      final pending = fake.stubPending('S', 'M');

      var done = false;
      final future = fake.call<String>('S', 'M', 'req', (json) => 'decoded:$json')
          .then((v) {
        done = true;
        return v;
      });
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse, reason: 'must stay in flight until the test completes it');
      expect(fake.calls.single.method, 'M');

      pending.complete('raw');
      expect(await future, 'decoded:raw');
    });

    test('stubPending without a decode function fails loudly, not silently', () async {
      final fake = FakeRpcClient();
      fake.stubPending('S', 'M').complete('raw');
      await expectLater(fake.call<Object?>('S', 'M', null), throwsStateError);
    });

    test('a later stub replaces a pending one', () async {
      final fake = FakeRpcClient();
      fake.stubPending('S', 'M');
      fake.stubTimeout('S', 'M');
      await expectLater(fake.call<Object?>('S', 'M', null), throwsA(isA<RpcTimeoutException>()));
    });

    test('diagnostics name the call, so a failing test says which RPC', () {
      expect(const RpcCall('S', 'M', 'r').toString(), 'S/M(r)');
      expect(const ConnectError('unavailable', 'down').toString(), 'ConnectError(unavailable): down');
      expect(const RpcTimeoutException('S', 'M').toString(), 'S/M timed out');
    });
  });
}
