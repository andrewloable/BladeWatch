import 'dart:io';

import 'package:bladewatch_ui/shell/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real-file integration test for [FileLocaleStore] — mirrors
/// `raw_http_sender_test.dart`/`io_live_socket_test.dart`'s own approach to a
/// thin `dart:io` wrapper: exercise it against a real temp file rather than
/// mock `dart:io`. Uses a temp directory in place of the real
/// `/data/local/tmp/.bladewatch/`, which only exists on-device.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('locale_store_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('readRaw returns null when the file does not exist yet', () async {
    final store = FileLocaleStore('${tempDir.path}/.bladewatch/locale');
    expect(await store.readRaw(), isNull);
  });

  test('writeRaw creates the parent directory and the file, readable back by a fresh store', () async {
    final path = '${tempDir.path}/.bladewatch/locale';
    final store = FileLocaleStore(path);

    await store.writeRaw('zh-CN');

    expect(await FileLocaleStore(path).readRaw(), 'zh-CN');
  });

  test('writeRaw overwrites a previously-written value', () async {
    final path = '${tempDir.path}/.bladewatch/locale';
    final store = FileLocaleStore(path);

    await store.writeRaw('ja');
    await store.writeRaw('auto');

    expect(await store.readRaw(), 'auto');
  });

  test('readRaw trims surrounding whitespace and treats a blank file as unset', () async {
    final path = '${tempDir.path}/.bladewatch/locale';
    await Directory('${tempDir.path}/.bladewatch').create(recursive: true);
    await File(path).writeAsString('  \n');

    expect(await FileLocaleStore(path).readRaw(), isNull);
  });

  test('readRaw swallows a read error (e.g. the path is a directory, not a file)', () async {
    final path = '${tempDir.path}/.bladewatch'; // a directory, not the locale file
    await Directory(path).create(recursive: true);

    expect(await FileLocaleStore(path).readRaw(), isNull);
  });
}
