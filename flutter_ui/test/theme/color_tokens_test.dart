import 'dart:io';

import 'package:bladewatch_ui/theme/color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses `<color name="...">#RRGGBB</color>` entries out of an Android
/// colors XML file. Regex, not an XML parser: the file shape is fixed and a
/// dependency isn't worth it for one test file.
Map<String, String> _parseAndroidColors(String path) {
  final text = File(path).readAsStringSync();
  final re = RegExp(r'<color name="([a-zA-Z0-9_]+)">#([0-9A-Fa-f]{6,8})</color>');
  return {for (final m in re.allMatches(text)) m.group(1)!: m.group(2)!.toUpperCase()};
}

String _hex(Color c) => c.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0').substring(2);

void main() {
  final lightXml = _parseAndroidColors('../app/src/main/res/values/colors_m3.xml');
  final darkXml = _parseAndroidColors('../app/src/main/res/values-night/colors_m3.xml');

  test('colors_m3.xml (light) was read and has entries', () {
    expect(lightXml, isNotEmpty);
    expect(lightXml['md_sys_color_primary_light'], '00677E');
  });

  test('every BwColorTokens.light value matches its colors_m3.xml entry', () {
    final map = BwColorTokens.light.xmlNameMap('light');
    expect(map, isNotEmpty);
    for (final entry in map.entries) {
      final expected = lightXml[entry.key];
      expect(expected, isNotNull, reason: '${entry.key} not found in values/colors_m3.xml');
      expect(_hex(entry.value), expected, reason: '${entry.key} drifted from values/colors_m3.xml');
    }
  });

  test('every BwColorTokens.dark value matches its values-night/colors_m3.xml entry', () {
    final map = BwColorTokens.dark.xmlNameMap('dark');
    expect(map, isNotEmpty);
    for (final entry in map.entries) {
      final expected = darkXml[entry.key];
      expect(expected, isNotNull, reason: '${entry.key} not found in values-night/colors_m3.xml');
      expect(_hex(entry.value), expected, reason: '${entry.key} drifted from values-night/colors_m3.xml');
    }
  });

  test('light and dark xmlNameMap cover the same set of role keys', () {
    final lightKeys = BwColorTokens.light.xmlNameMap('light').keys.map((k) => k.replaceAll('_light', ''));
    final darkKeys = BwColorTokens.dark.xmlNameMap('dark').keys.map((k) => k.replaceAll('_dark', ''));
    expect(lightKeys.toSet(), darkKeys.toSet());
  });
}
