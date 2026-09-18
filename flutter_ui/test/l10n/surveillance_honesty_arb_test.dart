import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-gyg1.2: asserts directly against the template ARB source file, not the
/// generated Dart getters -- this is what catches a key present in English and missing
/// from the generated catalog before it ever reaches `flutter gen-l10n`.
void main() {
  test('the two new honesty-warning keys exist in the template ARB file', () {
    final file = File('lib/l10n/app_en.arb');
    expect(file.existsSync(), isTrue, reason: 'expected ${file.path} relative to flutter_ui/');

    final Map<String, dynamic> arb = jsonDecode(file.readAsStringSync());

    expect(arb.containsKey('surveillance_general_battery_warning'), isTrue);
    expect(arb['surveillance_general_battery_warning'], isNotEmpty);
    expect(arb.containsKey('surveillance_general_camera_contention_warning'), isTrue);
    expect(arb['surveillance_general_camera_contention_warning'], isNotEmpty);
  });
}
