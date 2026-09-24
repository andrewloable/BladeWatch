import 'dart:convert';
import 'dart:io';

import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/settings/settings_screen.dart';
import 'package:bladewatch_companion/screens/surveillance/surveillance_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _catalog(String lang) =>
    jsonDecode(File('assets/i18n/$lang.json').readAsStringSync()) as Map<String, Object?>;

void main() {
  final en = Tr.english(_catalog('en'));

  test('every shipped language parses, and nothing ships that Tr does not list', () {
    final files = Directory('assets/i18n').listSync().map((f) => f.uri.pathSegments.last.replaceAll('.json', '')).toSet();
    expect(files, Tr.languages.toSet());
    for (final l in Tr.languages) {
      expect(_catalog(l), isA<Map<String, Object?>>(), reason: l);
    }
  });

  test('every language translates the companion\'s own strings, placeholders intact', () {
    final en = (_catalog('en')['companion'] as Map).cast<String, String>();
    final placeholder = RegExp(r'\{\w+\}');
    for (final l in Tr.languages.where((l) => l != 'en')) {
      final c = (_catalog(l)['companion'] as Map?)?.cast<String, String>() ?? const {};
      expect(c.keys.toSet(), en.keys.toSet(), reason: '$l: a new key needs translating in every catalog');
      for (final k in en.keys) {
        expect(placeholder.allMatches(c[k]!).map((m) => m[0]).toSet(), placeholder.allMatches(en[k]!).map((m) => m[0]).toSet(),
            reason: '$l.$k');
      }
    }
  });

  // The runtime lookup gives up generated accessors; this gives back their compile-time check.
  test('every catalog key the code uses exists in en.json', () {
    final keyLiteral = RegExp(r"(?<!ValueKey\()'([a-z_]+\.[a-z0-9_]+(?:\.[a-z0-9_]+)*)'");
    final sections = _catalog('en').keys.toSet();
    final used = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      for (final m in keyLiteral.allMatches(f.readAsStringSync())) {
        final k = m[1]!;
        if (sections.contains(k.split('.').first) && !k.endsWith('.dart')) used.add(k); // not an import
      }
    }
    // Built at runtime from a value, so no literal names them.
    used.addAll([
      for (var i = 1; i <= 4; i++) 'companion.window_$i',
      for (final m in SettingsScreen.recordingModes) 'companion.mode_${m.toLowerCase()}',
      for (final p in SurveillanceScreen.presets) 'surveillance.preset_${p.toLowerCase()}',
    ]);
    // Not catalog keys: the category id a test alert is raised with.
    used.remove('surveillance.motion');
    expect(used.where((k) => !en.has(k)).toList(), isEmpty);
    expect(used.length, greaterThan(200), reason: 'the scan must actually find the screens\' keys');
  });

  test('placeholders in both syntaxes, plurals, fallbacks and language choice', () {
    final tr = Tr('de', {'a': {'b': 'Hallo {{name}}'}}, {
      'a': {'b': 'Hello {{name}}', 'c': 'Only English {n}'},
      'p': {'one': '{count} clip', 'other': '{count} clips'},
    });
    expect(tr('a.b', {'name': 'X'}), 'Hallo X');
    expect(tr('a.c', {'n': 3}), 'Only English 3');
    expect(tr('a.c'), 'Only English {n}');
    expect(tr('missing.key'), 'missing.key');
    expect(tr.plural('p', 1), '1 clip');
    expect(tr.plural('p', 2), '2 clips');
    expect(tr.has('p'), isTrue);
    expect(tr.has('a'), isFalse);

    expect(Tr.pick(const Locale('pt', 'BR')), 'pt-BR');
    expect(Tr.pick(const Locale('zh')), 'zh-CN');
    expect(Tr.pick(const Locale('de', 'AT')), 'de');
    expect(Tr.pick(const Locale('xx')), 'en');
  });

  test('load reads the language and English from the bundled assets', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tr = await Tr.load(rootBundle, 'de');
    expect(tr.lang, 'de');
    expect(tr('common.cancel'), isNot('common.cancel'));
    expect(tr('companion.pair_button'), isNot('companion.pair_button'), reason: 'falls back to English');
    expect((await Tr.load(rootBundle, 'xx'))('common.cancel'), en('common.cancel'));
  });
}
