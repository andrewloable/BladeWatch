import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-8w4p.6: the HUD title bar and the summary-card label are built from a localized word plus
/// one of these two, so a locale that still carried the English text showed a mixed-language line
/// ("今週 TELEMETRY"). The two SECURE_LINK strings are deliberately left in English everywhere: they are
/// a status-bar flourish of the HUD design, not prose.
void main() {
  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

  final en = arb('en');
  final locales = [
    for (final f in Directory('lib/l10n').listSync().whereType<File>())
      if (RegExp(r'app_(.+)\.arb$').firstMatch(f.path)!.group(1)! != 'en')
        RegExp(r'app_(.+)\.arb$').firstMatch(f.path)!.group(1)!,
  ]..sort();

  test('there are 18 non-English catalogs', () => expect(locales, hasLength(18)));

  for (final key in ['dashboard_hud_overview', 'dashboard_hud_telemetry']) {
    test('$key is translated in every non-English catalog', () {
      for (final locale in locales) {
        final value = arb(locale)[key] as String?;
        expect(value, isNotNull, reason: '$locale lacks $key');
        expect(value, isNot(en[key]), reason: '$locale still holds the English placeholder for $key');
        expect(value!.trim(), isNotEmpty);
      }
    });
  }

  test('the SECURE_LINK strings stay English on purpose', () {
    for (final locale in locales) {
      expect(arb(locale)['dashboard_hud_link_active'], 'SECURE_LINK: ACTIVE', reason: locale);
      expect(arb(locale)['dashboard_hud_link_offline'], 'SECURE_LINK: OFFLINE', reason: locale);
    }
  });

  test('the title never repeats a word: the overview word differs from the rail Dashboard label', () {
    for (final locale in locales) {
      final a = arb(locale);
      expect(a['dashboard_hud_overview'], isNot(a['rail_dashboard']), reason: '$locale would read "X // X"');
    }
  });
}
