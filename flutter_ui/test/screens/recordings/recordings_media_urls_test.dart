import 'package:bladewatch_ui/screens/recordings/recordings_media_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('videoUrl builds /video/<filename> against the given base', () {
    expect(
      videoUrl('cam_20260523_120000.mp4', baseUrl: Uri.parse('http://127.0.0.1:8080')).toString(),
      'http://127.0.0.1:8080/video/cam_20260523_120000.mp4',
    );
  });

  test('thumbUrl builds /thumb/<filename> against the given base', () {
    expect(
      thumbUrl('cam_20260523_120000.mp4', baseUrl: Uri.parse('http://127.0.0.1:8080')).toString(),
      'http://127.0.0.1:8080/thumb/cam_20260523_120000.mp4',
    );
  });

  test('defaults to the daemon loopback base when none is given', () {
    expect(videoUrl('a.mp4').toString(), 'http://127.0.0.1:8080/video/a.mp4');
    expect(thumbUrl('a.mp4').toString(), 'http://127.0.0.1:8080/thumb/a.mp4');
  });
}
