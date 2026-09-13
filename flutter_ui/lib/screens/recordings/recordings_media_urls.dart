final _defaultBaseUrl = Uri.parse('http://127.0.0.1:8080');

/// `/video/<filename>` -- ground truth: `HttpServer.java`'s route table
/// (`path.startsWith("/video/")` → `RecordingsApiHandler.handleWithRange`,
/// which supports Range headers for seeking). Requires the same Bearer JWT
/// auth as every RPC call (`/video/`/`/thumb/` are not in
/// `AuthMiddleware.PUBLIC_PATHS`).
Uri videoUrl(String filename, {Uri? baseUrl}) => (baseUrl ?? _defaultBaseUrl).replace(path: '/video/$filename');

/// `/thumb/<filename>` -- same route table, same auth requirement.
Uri thumbUrl(String filename, {Uri? baseUrl}) => (baseUrl ?? _defaultBaseUrl).replace(path: '/thumb/$filename');
