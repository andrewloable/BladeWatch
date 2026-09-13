import 'dart:io';

/// The real health check `StartupController` uses by default — a loopback
/// HTTP GET to the daemon's Connect/HTTP server, ported from
/// `StartupFragment.verifyDaemonHealth()`: "any response means server is up"
/// (even a non-2xx one), only a connection failure or timeout counts as not
/// ready. `StartupController`'s `healthCheck` parameter exists precisely so
/// tests never have to go through real sockets — this function is exercised
/// directly instead, against a real loopback `HttpServer`.
Future<bool> checkDaemonHealth({
  String url = 'http://127.0.0.1:8080/',
  Duration timeout = const Duration(seconds: 2),
}) async {
  final client = HttpClient()
    ..connectionTimeout = timeout
    ..idleTimeout = timeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final response = await request.close().timeout(timeout);
    await response.drain<void>();
    return true;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
