/// Fake ConnectRPC client shared across screen/controller tests so they run
/// with no daemon attached. Covers all 12 bladewatch.v1 services generically —
/// `service`/`method` are plain strings (e.g. "SystemService", "GetStatus").
///
/// Usage: in a test, create one `FakeRpcClient`, call [stub] (or [stubError] /
/// [stubTimeout]) for every RPC the code under test will make, inject the fake
/// wherever the real client would go, exercise the code, then assert against
/// [calls] to confirm the right RPC was sent with the right request.
///
/// Implements [RpcTransport] (BladeWatch-ncbb.1) so it drops in wherever the
/// real `ConnectClient` goes — the typed service clients under
/// lib/rpc/services/ don't need to know which one they're talking to. [stub]
/// hands back a typed value directly, bypassing the caller's `decode`
/// callback entirely — convenient for most tests, but it means a wrapper
/// method's own response-decoding logic (`(json) =>
/// SomeResponse()..mergeFromProto3Json(json)`) never actually runs. Use
/// [stubJson] instead when a test needs to prove that logic for real: it
/// stores a raw proto3Json value and runs it through the real `decode`
/// callback, exactly like the real `ConnectClient` would.
library;

import 'dart:async';

import 'package:bladewatch_ui/rpc/rpc_transport.dart';

class RpcCall {
  final String service;
  final String method;
  final Object? request;

  const RpcCall(this.service, this.method, this.request);

  @override
  String toString() => '$service/$method($request)';
}

/// Mirrors a Connect protocol error (code + message) without depending on the
/// not-yet-generated real Connect-Dart error type.
class ConnectError implements Exception {
  final String code;
  final String message;

  const ConnectError(this.code, this.message);

  @override
  String toString() => 'ConnectError($code): $message';
}

class RpcTimeoutException implements Exception {
  final String service;
  final String method;

  const RpcTimeoutException(this.service, this.method);

  @override
  String toString() => '$service/$method timed out';
}

/// Sentinel wrapper so `null` is a valid stubbed raw-JSON value (an empty
/// Connect response body decodes as `null`), distinguishable from "nothing
/// registered for this key" in the underlying map.
class _JsonStub {
  final Object? value;
  const _JsonStub(this.value);
}

class FakeRpcClient implements RpcTransport {
  final List<RpcCall> calls = [];
  final Map<String, Object?> _responses = {};
  final Map<String, _JsonStub> _jsonResponses = {};
  final Map<String, ConnectError> _errors = {};
  final Set<String> _timeouts = {};
  final Map<String, Completer<Object?>> _pending = {};

  static String _key(String service, String method) => '$service/$method';

  /// Registers a canned typed success response for [service]/[method],
  /// returned as-is without going through the caller's `decode` callback.
  void stub(String service, String method, Object? response) {
    final key = _key(service, method);
    _responses[key] = response;
    _jsonResponses.remove(key);
    _errors.remove(key);
    _timeouts.remove(key);
  }

  /// Registers a raw proto3Json value for [service]/[method] — [call] runs
  /// it through the real `decode` callback the caller passes in, exercising
  /// the same response-decoding path the real `ConnectClient` uses. Prefer
  /// this over [stub] when a test needs to prove a wrapper method's decoding
  /// logic actually works for a given shape (including a partial/empty one),
  /// not just that the RPC was invoked.
  void stubJson(String service, String method, Object? rawJson) {
    final key = _key(service, method);
    _jsonResponses[key] = _JsonStub(rawJson);
    _responses.remove(key);
    _errors.remove(key);
    _timeouts.remove(key);
  }

  /// Registers a Connect error for [service]/[method].
  void stubError(String service, String method, ConnectError error) {
    final key = _key(service, method);
    _errors[key] = error;
    _responses.remove(key);
    _jsonResponses.remove(key);
    _timeouts.remove(key);
  }

  /// Registers [service]/[method] to hang until the returned completer is
  /// completed with the raw JSON to decode.
  ///
  /// The other stubs all resolve on the next microtask, which is too fast to
  /// reproduce "the screen was disposed while this call was still in flight" —
  /// the case where a widget awaits an RPC and then touches `State.context`.
  /// Holding the future open explicitly is the only deterministic way to land a
  /// test in that window.
  Completer<Object?> stubPending(String service, String method) {
    final key = _key(service, method);
    final completer = Completer<Object?>();
    _pending[key] = completer;
    _responses.remove(key);
    _jsonResponses.remove(key);
    _errors.remove(key);
    _timeouts.remove(key);
    return completer;
  }

  /// Registers [service]/[method] to simulate a timeout.
  void stubTimeout(String service, String method) {
    final key = _key(service, method);
    _timeouts.add(key);
    _responses.remove(key);
    _jsonResponses.remove(key);
    _errors.remove(key);
  }

  /// Invokes [service]/[method] with [request]. Records the call, then
  /// returns/throws whatever was stubbed. Throws [StateError] if nothing was
  /// stubbed — a test hitting this means it needs a `stub(...)`/`stubJson(...)`
  /// call added, not a silently-null response.
  @override
  Future<T> call<T>(
    String service,
    String method,
    Object? request, [
    T Function(Object? json)? decode,
  ]) async {
    final key = _key(service, method);
    calls.add(RpcCall(service, method, request));

    final pending = _pending[key];
    if (pending != null) {
      final raw = await pending.future;
      if (decode == null) {
        throw StateError(
          'FakeRpcClient: stubPending($key) was used but call() got no decode function to run it through',
        );
      }
      return decode(raw);
    }
    if (_timeouts.contains(key)) {
      throw RpcTimeoutException(service, method);
    }
    final error = _errors[key];
    if (error != null) {
      throw error;
    }
    final jsonStub = _jsonResponses[key];
    if (jsonStub != null) {
      if (decode == null) {
        throw StateError(
          'FakeRpcClient: stubJson($key) was used but call() got no decode function to run it through',
        );
      }
      return decode(jsonStub.value);
    }
    if (!_responses.containsKey(key)) {
      throw StateError(
        'FakeRpcClient: no stub registered for $key — call stub()/stubJson()/stubError()/stubTimeout() first',
      );
    }
    return _responses[key] as T;
  }
}
