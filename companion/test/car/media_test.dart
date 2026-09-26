import 'dart:async';
import 'dart:io';

import 'package:bladewatch_companion/car/media.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  late HttpServer car;
  final auth = <String?>[];
  final ranges = <String?>[];
  // 0..255 repeating, so a resumed download that stitched the wrong bytes would not compare equal.
  final full = List<int>.generate(100000, (i) => i % 256);
  var cutAfter = 0; // /video/flaky.mp4: bytes sent before the connection is cut (0 = never)
  void Function()? onCut; // runs just before the cut: e.g. the session losing its route

  setUp(() async {
    onCut = null;
    auth.clear();
    ranges.clear();
    car = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    car.listen((r) async {
      auth.add(r.headers.value('authorization'));
      if (r.uri.path == '/api/stream/still') {
        r.response.add([1, 2, 3]);
      } else if (r.uri.path == '/video/clip.mp4') {
        r.response.add(List.filled(100000, 7));
      } else if (r.uri.path == '/video/flaky.mp4') {
        final range = r.headers.value(HttpHeaders.rangeHeader);
        ranges.add(range);
        final from = range == null ? 0 : int.parse(range.substring('bytes='.length, range.length - 1));
        if (range != null) {
          r.response.statusCode = 206;
          r.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $from-${full.length - 1}/${full.length}');
        }
        r.response.contentLength = full.length - from;
        if (cutAfter > 0) {
          // Promise the whole body, deliver part of it, drop the connection: what a Pear
          // reconnect does to a transfer in flight.
          final socket = await r.response.detachSocket();
          socket.add(full.sublist(from, from + cutAfter));
          await socket.flush();
          onCut?.call();
          socket.destroy();
          cutAfter = 0;
          return;
        }
        r.response.add(full.sublist(from));
      } else {
        r.response.statusCode = 503;
      }
      await r.response.close();
    });
  });

  tearDown(() => car.close(force: true));

  TestSession session() => TestSession(baseUrl: Uri.parse('http://127.0.0.1:${car.port}'));

  test('fetchMedia carries the session JWT and returns status and bytes', () async {
    final s = session();
    final ok = await fetchMedia(s.session, '/api/stream/still');
    expect(ok.ok, isTrue);
    expect(ok.bytes, [1, 2, 3]);
    final missing = await fetchMedia(s.session, '/nope');
    expect(missing.status, 503);
    expect(missing.ok, isFalse);
    expect(auth, ['Bearer jwt', 'Bearer jwt']);
  });

  test('downloadMedia streams to the file, and leaves nothing behind on a refusal', () async {
    final s = session();
    final dir = Directory.systemTemp.createTempSync('dl');
    final dest = File('${dir.path}/clip.mp4');
    expect(await downloadMedia(s.session, '/video/clip.mp4', dest), isTrue);
    expect(dest.lengthSync(), 100000);

    final bad = File('${dir.path}/bad.mp4');
    expect(await downloadMedia(s.session, '/video/other.mp4', bad), isFalse);
    expect(bad.existsSync(), isFalse);
    expect(File('${bad.path}.part').existsSync(), isFalse);

    await car.close(force: true);
    final down = File('${dir.path}/down.mp4');
    expect(await downloadMedia(s.session, '/video/clip.mp4', down, backoff: Duration.zero), isFalse);
    expect(File('${down.path}.part').existsSync(), isFalse, reason: 'every try failed: nothing left behind');
  });

  // BladeWatch-tayl: a transfer the connection drops is finished from where it stopped.
  test('downloadMedia resumes a dropped transfer with a Range request, byte for byte', () async {
    final s = session();
    final dest = File('${Directory.systemTemp.createTempSync('dl').path}/flaky.mp4');
    cutAfter = 40000;
    expect(await downloadMedia(s.session, '/video/flaky.mp4', dest, backoff: Duration.zero), isTrue);
    expect(ranges, [null, 'bytes=40000-'], reason: 'the retry asks only for what is missing');
    expect(dest.readAsBytesSync(), full);
    expect(File('${dest.path}.part').existsSync(), isFalse);
  });

  // BladeWatch-tayl, measured from mobile data: reconnects took 5 s to 90+ s, and a download that
  // spent its few quick attempts during the outage was lost. A drop the session sees must wait for
  // the route, not use up tries -- with ONE attempt this passes only if the drop costs none.
  test('a drop while the route is down costs no attempt: it waits for the session, then resumes', () async {
    final s = session();
    final dest = File('${Directory.systemTemp.createTempSync('dl').path}/flaky.mp4');
    cutAfter = 40000;
    onCut = () {
      s.phases.add(TransportPhase.discovering);
      Timer(const Duration(milliseconds: 300), () => s.phases.add(TransportPhase.pear));
    };
    expect(await downloadMedia(s.session, '/video/flaky.mp4', dest, attempts: 1, backoff: Duration.zero), isTrue);
    expect(ranges, [null, 'bytes=40000-']);
    expect(dest.readAsBytesSync(), full);
  });

  test('a route that never comes back gives up after its patience, leaving nothing behind', () async {
    final s = session();
    final dest = File('${Directory.systemTemp.createTempSync('dl').path}/flaky.mp4');
    cutAfter = 40000;
    onCut = () => s.phases.add(TransportPhase.discovering);
    final watch = Stopwatch()..start();
    expect(
      await downloadMedia(s.session, '/video/flaky.mp4', dest, backoff: Duration.zero, patience: const Duration(milliseconds: 400)),
      isFalse,
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)), reason: 'bounded by patience, not by a hang');
    expect(File('${dest.path}.part').existsSync(), isFalse);
    expect(dest.existsSync(), isFalse);
  });
}
