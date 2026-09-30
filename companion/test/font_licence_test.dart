import 'package:bladewatch_companion/font_licence.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Space Mono OFL notice is on the licences page', () async {
    registerFontLicence();

    final entries = await LicenseRegistry.licenses.toList();
    final spaceMono = entries.where((e) => e.packages.contains('Space Mono')).toList();
    expect(spaceMono, hasLength(1));
    expect(spaceMono.single.paragraphs.map((p) => p.text).join('\n'), contains('SIL OPEN FONT LICENSE'));
  });
}
