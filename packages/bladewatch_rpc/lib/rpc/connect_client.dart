import 'dart:async';
import 'dart:convert';

import 'package:bladewatch_rpc/rpc/connect_error.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';

/// The Flutter side of the Connect protocol transport every typed service
/// client (lib/rpc/services/) is built on. Mirrors
/// app/src/main/java/com/loabletech/bladewatch/client/ConnectClientProvider.kt:
/// same base URL, same headers, the same 4-minute JWT cache keyed to a state
/// version so a rotated device secret forces an immediate re-mint.
///
/// [request] must expose a `toProto3Json()` method — in practice always a
/// generated `GeneratedMessage` — called dynamically so this file has no
/// direct dependency on `package:protobuf`. [decode] turns the raw,
/// already-`jsonDecode`d proto3Json response (or `null` for an empty body)
/// into the typed response message.
class ConnectClient implements RpcTransport {
  static const _jwtCacheTtl = Duration(minutes: 4);

  final Uri baseUrl;
  final JwtSource _jwtSource;
  final RawHttpSender _send;
  final DateTime Function() _now;

  String? _cachedJwt;
  DateTime? _cachedAt;
  int? _cachedStateVersion;

  ConnectClient({
    required JwtSource jwtSource,
    Uri? baseUrl,
    RawHttpSender? send,
    DateTime Function()? now,
    // Not an initializing formal on purpose: the public parameter above is
    // named `jwtSource`, stored privately as `_jwtSource` below —
    // `this._jwtSource` would force callers to write the leading-underscore
    // name instead.
    // ignore: prefer_initializing_formals
  })  : _jwtSource = jwtSource,
        baseUrl = baseUrl ?? Uri.parse('http://127.0.0.1:8080'),
        _send = send ?? createIoHttpSender(),
        _now = now ?? DateTime.now;

  @override
  Future<T> call<T>(
    String service,
    String method,
    Object? request,
    T Function(Object? json) decode,
  ) async {
    final jwt = await _currentJwt();
    final uri = baseUrl.replace(path: '/bladewatch.v1.$service/$method');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Connect-Protocol-Version': '1',
      if (jwt != null) 'Authorization': 'Bearer $jwt',
    };
    // ignore: avoid_dynamic_calls — every real caller passes a GeneratedMessage.
    final requestJson = (request as dynamic).toProto3Json();
    final body = jsonEncode(requestJson);

    final RawHttpResponse response;
    try {
      response = await _send(uri, headers, body);
    } on TimeoutException {
      throw ConnectError(
        httpStatus: 0,
        code: 'deadline_exceeded',
        message: '$service/$method timed out',
      );
    } catch (e) {
      // Anything else that stops a response from arriving at all — most
      // commonly "connection refused" because the daemon isn't up yet.
      throw ConnectError(
        httpStatus: 0,
        code: 'unavailable',
        message: '$service/$method: $e',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      return decode(decoded);
    }

    throw _decodeError(response);
  }

  ConnectError _decodeError(RawHttpResponse response) {
    String code = 'unknown';
    String message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        code = decoded['code'] as String? ?? 'unknown';
        message = decoded['message'] as String? ?? '';
      }
    } catch (_) {
      // Body wasn't JSON (e.g. a proxy/gateway error page) — keep the raw
      // body as the message and 'unknown' as the code rather than throwing
      // a second, unrelated exception out of an error path.
    }
    return ConnectError(httpStatus: response.statusCode, code: code, message: message);
  }

  Future<String?> _currentJwt() async {
    final now = _now();
    final version = await _jwtSource.stateVersion();
    final cachedAt = _cachedAt;
    if (_cachedJwt != null &&
        cachedAt != null &&
        now.difference(cachedAt) < _jwtCacheTtl &&
        _cachedStateVersion == version) {
      return _cachedJwt;
    }

    final fresh = await _jwtSource.mintJwt();
    if (fresh != null) {
      _cachedJwt = fresh;
      _cachedAt = now;
      _cachedStateVersion = version;
    }
    return fresh;
  }

  /// Clears the cached JWT — call when the device token is regenerated.
  void invalidate() {
    _cachedJwt = null;
    _cachedAt = null;
    _cachedStateVersion = null;
  }
}
