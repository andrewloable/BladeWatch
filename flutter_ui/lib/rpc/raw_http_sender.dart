import 'dart:convert';
import 'dart:io';

class RawHttpResponse {
  final int statusCode;
  final String body;
  const RawHttpResponse(this.statusCode, this.body);
}

/// The one seam between [ConnectClient] and real network I/O — injectable so
/// tests never open a socket. Throws on anything that stops a response from
/// arriving at all (timeout, connection refused); a non-2xx HTTP status is
/// still a normal return value, not a throw.
typedef RawHttpSender = Future<RawHttpResponse> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

/// The real sender, backed by `dart:io`'s [HttpClient]. Mirrors
/// ConnectClientProvider.kt's OkHttpClient configuration exactly:
///
///  - **No proxy.** A system or VPN proxy on the head unit (this project also
///    ships Tailscale/sing-box) must never intercept loopback calls to the
///    daemon — `findProxy` is forced to `DIRECT`.
///  - 5s connect timeout by default.
///  - 10s read timeout by default; callers needing the long-timeout client
///    (volume format ~30-60s, trips DB sync ~120s) pass `readTimeout:
///    Duration(seconds: 120)`.
RawHttpSender createIoHttpSender({
  Duration connectTimeout = const Duration(seconds: 5),
  Duration readTimeout = const Duration(seconds: 10),
}) {
  final httpClient = HttpClient()
    ..connectionTimeout = connectTimeout
    ..findProxy = (_) => 'DIRECT';

  return (Uri uri, Map<String, String> headers, String body) async {
    final request = await httpClient.postUrl(uri).timeout(connectTimeout);
    headers.forEach(request.headers.set);
    final bodyBytes = utf8.encode(body);
    request.headers.contentLength = bodyBytes.length;
    request.add(bodyBytes);
    final response = await request.close().timeout(readTimeout);
    final responseBody = await response.transform(utf8.decoder).join().timeout(readTimeout);
    return RawHttpResponse(response.statusCode, responseBody);
  };
}
