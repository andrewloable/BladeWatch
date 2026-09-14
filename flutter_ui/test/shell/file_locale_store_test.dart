import 'dart:io';

import 'package:bladewatch_ui/shell/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real-file integration test for [FileLocaleStore] — mirrors
/// `raw_http_sender_test.dart`/`io_live_socket_test.dart`'s own approach to a
/// thin `dart:io` wrapper: exercise it against a real temp file rather than
/// mock `dart:io`. Uses a temp directory in place of the real
/// the real device paths, which only exist on-device.
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

  // ── BladeWatch-vcur: the store moved off /data/local/tmp/.bladewatch/, which
  // the app UID cannot create, so the legacy file still has to be read. ─────

  test('the default path is one the app UID can actually write, not /data/local/tmp', () {
    const store = FileLocaleStore();
    expect(store.path, '/storage/emulated/0/BladeWatch/data/locale');
    expect(store.legacyPath, '/data/local/tmp/.bladewatch/locale',
        reason: 'a device whose web UI already persisted a language reads from here');
  });

  test('readRaw falls back to the legacy file when the current one is absent', () async {
    final legacy = File('${tempDir.path}/legacy/locale')..createSync(recursive: true);
    legacy.writeAsStringSync('de');
    final store = FileLocaleStore('${tempDir.path}/new/locale', legacy.path);

    expect(await store.readRaw(), 'de', reason: 'an upgraded device must keep its language');
  });

  test('the current file wins over the legacy one', () async {
    final legacy = File('${tempDir.path}/legacy/locale')..createSync(recursive: true);
    legacy.writeAsStringSync('de');
    final current = File('${tempDir.path}/new/locale')..createSync(recursive: true);
    current.writeAsStringSync('ja');
    final store = FileLocaleStore(current.path, legacy.path);

    expect(await store.readRaw(), 'ja');
  });

  test('writeRaw reports success, and failure instead of throwing', () async {
    final ok = FileLocaleStore('${tempDir.path}/fresh/locale');
    expect(await ok.writeRaw('fr'), isTrue);

    // A path whose parent is a FILE cannot be created — the closest a unit test
    // gets to /data/local/tmp's 0771 shell:shell, which is what actually bit us.
    final blocker = File('${tempDir.path}/blocker')..writeAsStringSync('x');
    final bad = FileLocaleStore('${blocker.path}/locale');
    expect(await bad.writeRaw('fr'), isFalse, reason: 'a failed write must be reported, not swallowed');
  });
}
