/// Shared shape between the real [ConnectClient] (connect_client.dart) and
/// the shared test double `FakeRpcClient`
/// (lib/testing/fake_rpc_client.dart, from BladeWatch-ncbb.5) —
/// every typed service client under lib/rpc/services/ is written against
/// this interface so a controller test can inject the fake with no other
/// change.
///
/// [request] is always a `GeneratedMessage` in practice (every real caller is
/// a generated service-client wrapper method); it is typed `Object?` here,
/// not `GeneratedMessage`, purely so the interface matches
/// `FakeRpcClient.call`, which pre-dates this file and stubs plain Dart
/// values directly. [decode] turns the raw proto3Json response into the
/// typed message — the real client calls it, the fake ignores it (it already
/// knows what to return from its stub table).
abstract class RpcTransport {
  Future<T> call<T>(
    String service,
    String method,
    Object? request,
    T Function(Object? json) decode,
  );
}
