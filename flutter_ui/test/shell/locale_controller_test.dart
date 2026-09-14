import 'dart:ui' show Locale;

import 'package:bladewatch_ui/shell/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocaleStore implements LocaleStore {
  String? stored;
  final writes = <String>[];

  /// Set false to model a store that cannot persist (BladeWatch-vcur).
  bool writable = true;

  @override
  Future<String?> readRaw() async => stored;

  @override
  Future<bool> writeRaw(String tag) async {
    writes.add(tag);
    if (!writable) return false;
    stored = tag;
    return true;
  }
}

void main() {
  group('parseLocaleTag', () {
    test('a bare language tag has no country code', () {
      expect(parseLocaleTag('en'), const Locale('en'));
    });

    test('a region-qualified tag splits into language and country', () {
      expect(parseLocaleTag('zh-CN'), const Locale('zh', 'CN'));
      expect(parseLocaleTag('pt-BR'), const Locale('pt', 'BR'));
    });
  });

  group('LocaleController', () {
    late FakeLocaleStore store;
    late LocaleController controller;

    setUp(() {
      store = FakeLocaleStore();
      controller = LocaleController(store: store);
    });

    test('before load(), locale is null (system default) and isAuto is true', () {
      expect(controller.locale, isNull);
      expect(controller.isAuto, isTrue);
      expect(controller.rawTag, isNull);
    });

    test('load() with nothing persisted stays auto', () async {
      await controller.load();
      expect(controller.isAuto, isTrue);
      expect(controller.locale, isNull);
    });

    test('load() with the auto sentinel persisted stays auto', () async {
      store.stored = 'auto';
      await controller.load();
      expect(controller.isAuto, isTrue);
      expect(controller.rawTag, 'auto');
    });

    test('load() with a supported tag persisted resolves to that Locale', () async {
      store.stored = 'zh-CN';
      await controller.load();
      expect(controller.isAuto, isFalse);
      expect(controller.locale, const Locale('zh', 'CN'));
      expect(controller.rawTag, 'zh-CN');
    });

    test('load() with an unrecognized value falls back to auto rather than trusting it', () async {
      store.stored = 'not-a-real-tag';
      await controller.load();
      expect(controller.isAuto, isTrue);
      expect(controller.rawTag, isNull);
    });

    test('select() applies immediately and persists', () async {
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.select('ja');

      expect(controller.locale, const Locale('ja'));
      expect(store.writes, ['ja']);
      expect(notified, 1);
    });

    test('select() with the auto sentinel clears the Locale override', () async {
      await controller.select('ja');
      await controller.select('auto');

      expect(controller.isAuto, isTrue);
      expect(controller.locale, isNull);
      expect(store.writes, ['ja', 'auto']);
    });

    test('select() with the already-current tag is a no-op (no write, no notify)', () async {
      await controller.select('ja');
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.select('ja');

      expect(store.writes, ['ja']);
      expect(notified, 0);
    });
  });

  // ── BladeWatch-vcur: a write that cannot persist must be visible. ────────
  group('persist failure', () {
    test('select() reports when the choice could not be saved', () async {
      final store = FakeLocaleStore()..writable = false;
      final c = LocaleController(store: store);
      await c.load();

      await c.select('de');

      expect(c.rawTag, 'de', reason: 'still applied for this session');
      expect(c.lastPersistSucceeded, isFalse,
          reason: 'the picker needs this to tell the user it will not survive a restart');
    });

    test('select() reports success on a store that can persist', () async {
      final c = LocaleController(store: FakeLocaleStore());
      await c.load();

      await c.select('de');

      expect(c.lastPersistSucceeded, isTrue);
    });
  });
}
