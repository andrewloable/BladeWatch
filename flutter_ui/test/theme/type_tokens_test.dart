import 'dart:io';

import 'package:bladewatch_ui/theme/type_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses each `TextAppearance.BladeWatch.<Role>` style block in
/// themes_bladewatch.xml and pulls out its `android:letterSpacing` value (in
/// em, same unit Android uses).
Map<String, double> _parseAndroidLetterSpacing(String path) {
  final text = File(path).readAsStringSync();
  final re = RegExp(
    r'<style name="TextAppearance\.BladeWatch\.(\w+)"[^>]*>(.*?)</style>',
    dotAll: true,
  );
  final result = <String, double>{};
  for (final m in re.allMatches(text)) {
    final body = m.group(2)!;
    final spacing = RegExp(r'<item name="android:letterSpacing">(-?[\d.]+)</item>').firstMatch(body);
    if (spacing != null) {
      result[m.group(1)!] = double.parse(spacing.group(1)!);
    }
  }
  return result;
}

void main() {
  final xml = _parseAndroidLetterSpacing('../app/src/main/res/values/themes_bladewatch.xml');

  test('themes_bladewatch.xml TextAppearance.BladeWatch.* styles were found', () {
    expect(xml, isNotEmpty);
    expect(xml['TitleLarge'], -0.005);
  });

  test('every BwTypeTracking em value matches its TextAppearance.BladeWatch.* style', () {
    expect(BwTypeTracking.xmlEmValues, isNotEmpty);
    for (final entry in BwTypeTracking.xmlEmValues.entries) {
      final expected = xml[entry.key];
      expect(expected, isNotNull, reason: 'TextAppearance.BladeWatch.${entry.key} not found');
      expect(entry.value, expected, reason: '${entry.key} tracking drifted from themes_bladewatch.xml');
    }
  });

  test('xmlEmValues has all 8 roles the design doc table lists', () {
    expect(BwTypeTracking.xmlEmValues.keys.toSet(), {
      'DisplaySmall',
      'HeadlineLarge',
      'HeadlineMedium',
      'HeadlineSmall',
      'TitleLarge',
      'TitleMedium',
      'LabelLarge',
      'LabelMedium',
    });
  });
}
