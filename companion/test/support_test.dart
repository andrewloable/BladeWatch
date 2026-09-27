import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A broken fixture image fails to decode asynchronously, in whatever test is running then.
  test('the test PNG is a real image', () async {
    final frame = await (await ui.instantiateImageCodec(testPng)).getNextFrame();
    expect(frame.image.width, 1);
    expect(frame.image.height, 1);
  });
}
