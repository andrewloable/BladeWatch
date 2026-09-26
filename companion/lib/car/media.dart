import 'dart:async';
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

/// Waits until [session] has a route to the car again (LAN or Pear); false if it does not within
/// [timeout]. True at once if it already has one.
Future<bool> untilConnected(CarSession session, Duration timeout) async {
  if (session.connected) return true;
  final back = Completer<bool>();
  void check() {
    if (session.connected && !back.isCompleted) back.complete(true);
  }

  session.addListener(check);
  try {
    return await back.future.timeout(timeout, onTimeout: () => false);
  } finally {
    session.removeListener(check);
  }
}

/// Streams a file from the car to [dest] without holding it in memory (clips run to hundreds of
/// MB). A connection that drops mid-way -- routine over Pear from a phone -- resumes where it
/// stopped, with a Range request for the rest (BladeWatch-tayl).
///
/// A drop while the session has no route costs no attempt: the download waits for the route to
/// come back instead. Measured from mobile data, a reconnect took 5 s to 90+ s, and a budget of
/// [attempts] quick tries lost 3 of 5 downloads to drops it could have ridden out. Only failures
/// while the route is up count against [attempts], with a growing pause, and the whole download
/// gives up after [patience]. Returns false on a refusal (never retried) or when it gives up,
/// leaving no partial file behind.
Future<bool> downloadMedia(
  CarSession session,
  String pathAndQuery,
  File dest, {
  int attempts = 5,
  Duration backoff = const Duration(seconds: 2),
  Duration patience = const Duration(minutes: 10),
}) async {
  final part = File('${dest.path}.part');
  final deadline = DateTime.now().add(patience);
  // Sync metadata calls on purpose: cheap, and they keep a caller's fake-async test zone working.
  if (part.existsSync()) part.deleteSync(); // a new download never appends to an old part
  var attempt = 1;
  while (attempt <= attempts) {
    final left = deadline.difference(DateTime.now());
    if (left <= Duration.zero || !await untilConnected(session, left)) break;
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
      // Refused outright while the route is up: the phone's own gateway is not there, so no retry
      // reaches the car. With the route down the gateway refuses too -- that one is a drop.
      if (!connected && session.connected) break;
    } on IOException catch (_) {
      // Dropped mid-way (HttpException and the like): keep the part and resume.
    } catch (_) {
      break; // anything else is not a transient network failure
    } finally {
      client.close(force: true);
    }
    // A drop the session already sees costs nothing: the loop top waits for the route.
    if (session.connected) {
      await Future<void>.delayed(backoff * attempt);
      attempt++;
    }
  }
  if (part.existsSync()) part.deleteSync();
  return false;
}
