import 'dart:convert';

import 'package:flutter/widgets.dart';

/// The companion's strings (BladeWatch-rdtj.11): the web app's own catalogs, bundled as
/// `assets/i18n/<lang>.json` with the same dotted keys, so every web page this app replaces is
/// already translated into the same 17 languages. A key missing from a language falls back to
/// English, and one missing from English shows the key itself -- test/i18n_test.dart fails on
/// any key the code uses that en.json lacks.
///
/// ponytail: a runtime lookup, not generated accessors -- 1600 keys already exist in this shape,
/// and the guard test above gives back the compile-time check.
class Tr {
  Tr(this.lang, this._strings, this._fallback);

  /// The languages shipped in assets/i18n, as the web names them.
  static const languages = [
    'en', 'de', 'es', 'fr', 'hi', 'it', 'ja', 'ko', 'nb', 'nl', 'pt-BR', 'ru', 'th', 'tr', 'vi', 'zh-CN', 'zh-TW', //
  ];

  final String lang;
  final Map<String, Object?> _strings;
  final Map<String, Object?> _fallback;

  /// English only, for tests and as the last resort.
  factory Tr.english(Map<String, Object?> en) => Tr('en', en, en);

  static Future<Tr> load(AssetBundle bundle, String lang) async {
    Future<Map<String, Object?>> read(String l) async =>
        jsonDecode(await bundle.loadString('assets/i18n/$l.json')) as Map<String, Object?>;
    final en = await read('en');
    return Tr(lang, lang == 'en' || !languages.contains(lang) ? en : await read(lang), en);
  }

  /// The best shipped language for [locale]: an exact region match (pt-BR, zh-TW), else the
  /// language alone (zh -> zh-CN), else English.
  static String pick(Locale locale) {
    final tagged = '${locale.languageCode}-${locale.countryCode}';
    if (languages.contains(tagged)) return tagged;
    return languages.firstWhere((l) => l == locale.languageCode || l.startsWith('${locale.languageCode}-'),
        orElse: () => 'en');
  }

  /// [key] in this language, placeholders filled from [params]. The catalogs use both
  /// ngx-translate's `{{name}}` and a plain `{name}`.
  String call(String key, [Map<String, Object?> params = const {}]) {
    final s = _lookup(_strings, key) ?? _lookup(_fallback, key) ?? key;
    if (params.isEmpty) return s;
    return s.replaceAllMapped(_placeholder, (m) => '${params[m[1] ?? m[2]] ?? m[0]}');
  }

  static final _placeholder = RegExp(r'\{\{\s*(\w+)\s*\}\}|\{(\w+)\}');

  /// A plural entry (`{"one": ..., "other": ...}`), `{count}` filled in.
  /// ponytail: one/other only -- all the web catalogs use; add CLDR categories if a language needs them.
  String plural(String key, int count, [Map<String, Object?> params = const {}]) =>
      call('$key.${count == 1 ? 'one' : 'other'}', {'count': count, ...params});

  bool has(String key) => _lookup(_fallback, key) != null || _lookup(_fallback, '$key.other') != null;

  static String? _lookup(Map<String, Object?> map, String key) {
    Object? node = map;
    for (final part in key.split('.')) {
      if (node is! Map<String, Object?>) return null;
      node = node[part];
    }
    return node is String ? node : null;
  }
}

/// Makes the current [Tr] reachable as `context.tr`.
class TrScope extends InheritedWidget {
  const TrScope({super.key, required this.tr, required super.child});

  final Tr tr;

  @override
  bool updateShouldNotify(TrScope oldWidget) => oldWidget.tr != tr;
}

extension TrContext on BuildContext {
  Tr get tr => dependOnInheritedWidgetOfExactType<TrScope>()!.tr;
}
