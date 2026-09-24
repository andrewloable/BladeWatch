import 'dart:io';
import 'dart:typed_data';

import 'car_session.dart';

/// A binary fetch from the car through the gateway, authenticated like an RPC -- for what the
/// car serves as plain HTTP because a browser once fetched it directly (stills, thumbnails).
class MediaResponse {
  const MediaResponse(this.status, this.bytes);

  final int status;
  final Uint8List bytes;

  bool get ok => status == 200 && bytes.isNotEmpty;
}

Future<MediaResponse> fetchMedia(CarSession session, String pathAndQuery, {Duration timeout = const Duration(seconds: 20)}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(session.baseUrl.resolve(pathAndQuery)).timeout(timeout);
    (await session.authHeaders()).forEach(request.headers.set);
    final response = await request.close().timeout(timeout);
    final builder = BytesBuilder(copy: false);
    await response.timeout(timeout).forEach(builder.add);
    return MediaResponse(response.statusCode, builder.takeBytes());
  } finally {
    client.close(force: true);
  }
}

/// Streams a file from the car to [dest] without holding it in memory (clips run to hundreds of
/// MB). Returns false on any non-200 answer, leaving no partial file behind.
Future<bool> downloadMedia(CarSession session, String pathAndQuery, File dest) async {
  final client = HttpClient();
  final part = File('${dest.path}.part');
  try {
    final request = await client.getUrl(session.baseUrl.resolve(pathAndQuery));
    (await session.authHeaders()).forEach(request.headers.set);
    final response = await request.close();
    if (response.statusCode != 200) {
      await response.drain<void>();
      return false;
    }
    await response.pipe(part.openWrite());
    await part.rename(dest.path);
    return true;
  } catch (_) {
    if (await part.exists()) await part.delete();
    return false;
  } finally {
    client.close(force: true);
  }
}
