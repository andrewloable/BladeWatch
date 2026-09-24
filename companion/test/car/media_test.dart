import 'dart:io';

import 'package:bladewatch_companion/car/media.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  late HttpServer car;
  final auth = <String?>[];

  setUp(() async {
    auth.clear();
    car = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    car.listen((r) {
      auth.add(r.headers.value('authorization'));
      if (r.uri.path == '/api/stream/still') {
        r.response.add([1, 2, 3]);
      } else if (r.uri.path == '/video/clip.mp4') {
        r.response.add(List.filled(100000, 7));
      } else {
        r.response.statusCode = 503;
      }
      r.response.close();
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
    expect(await downloadMedia(s.session, '/video/clip.mp4', File('${dir.path}/down.mp4')), isFalse);
  });
}
