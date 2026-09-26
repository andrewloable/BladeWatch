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
/// MB). A connection that drops mid-way -- routine over Pear from a phone -- resumes where it
/// stopped, with a Range request for the rest (BladeWatch-tayl), up to [attempts] tries with a
/// growing pause. Returns false on a refusal (never retried) or when every try fails, leaving no
/// partial file behind.
Future<bool> downloadMedia(
  CarSession session,
  String pathAndQuery,
  File dest, {
  int attempts = 5,
  Duration backoff = const Duration(seconds: 2),
}) async {
  final part = File('${dest.path}.part');
  // Sync metadata calls on purpose: cheap, and they keep a caller's fake-async test zone working.
  if (part.existsSync()) part.deleteSync(); // a new download never appends to an old part
  for (var attempt = 1; attempt <= attempts; attempt++) {
    final client = HttpClient();
    var connected = false;
    try {
      final have = part.existsSync() ? part.lengthSync() : 0;
      final request = await client.getUrl(session.baseUrl.resolve(pathAndQuery));
      connected = true;
      (await session.authHeaders()).forEach(request.headers.set);
      if (have > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final response = await request.close();
      final resumed = have > 0 && response.statusCode == 206;
      if (response.statusCode != 200 && !resumed) {
        await response.drain<void>();
        break;
      }
      // A 200 to a Range request means the whole file again: start the part over.
      await response.pipe(part.openWrite(mode: resumed ? FileMode.append : FileMode.write));
      await part.rename(dest.path);
      return true;
    } on FileSystemException catch (_) {
      break; // the phone's disk, not the network: retrying will not help
    } on SocketException catch (_) {
      // Refused outright: the phone's own gateway is not there, so no retry will reach the car.
      // A route that drops shows up differently -- the gateway accepts, then closes.
      if (!connected) break;
      if (attempt < attempts) await Future<void>.delayed(backoff * attempt);
    } on IOException catch (_) {
      // Dropped mid-way (HttpException and the like): keep the part, resume after a pause.
      if (attempt < attempts) await Future<void>.delayed(backoff * attempt);
    } catch (_) {
      break; // anything else is not a transient network failure
    } finally {
      client.close(force: true);
    }
  }
  if (part.existsSync()) part.deleteSync();
  return false;
}
