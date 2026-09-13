import 'dart:io';

import 'package:bladewatch_ui/theme/dimens_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses `<dimen name="...">Ndp</dimen>` entries from an Android dimens XML.
Map<String, double> _parseAndroidDimens(String path) {
  final text = File(path).readAsStringSync();
  final re = RegExp(r'<dimen name="([a-zA-Z0-9_]+)">(-?\d+(?:\.\d+)?)dp</dimen>');
  return {for (final m in re.allMatches(text)) m.group(1)!: double.parse(m.group(2)!)};
}

void main() {
  final dimensXml = _parseAndroidDimens('../app/src/main/res/values/dimens_bladewatch.xml');

  test('dimens_bladewatch.xml was read and has entries', () {
    expect(dimensXml, isNotEmpty);
    expect(dimensXml['card_radius_standard'], 20);
  });

  test('every BwDimens value matches its dimens_bladewatch.xml entry', () {
    final map = BwDimens.xmlNameMap;
    expect(map, isNotEmpty);
    for (final entry in map.entries) {
      final expected = dimensXml[entry.key];
      expect(expected, isNotNull, reason: '${entry.key} not found in dimens_bladewatch.xml');
      expect(entry.value, expected, reason: '${entry.key} drifted from dimens_bladewatch.xml');
    }
  });

  test('shape appearance corner sizes match themes.xml', () {
    // ShapeAppearance.BladeWatch.SmallComponent / LargeComponent in themes.xml
    // are not <dimen> entries (they're cornerSize items inside a <style>), so
    // this pair is asserted by literal value instead of the same regex scan.
    final themesXml = File('../app/src/main/res/values/themes.xml').readAsStringSync();
    expect(themesXml, contains('<item name="cornerSize">8dp</item>'));
    expect(BwDimens.shapeSmallComponent, 8);
    expect(themesXml, contains('<item name="cornerSize">16dp</item>'));
    expect(BwDimens.shapeLargeComponent, 16);
  });
}
