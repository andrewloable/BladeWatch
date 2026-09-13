import 'package:bladewatch_ui/screens/settings/settings_about_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SettingsAboutController build({Future<AppVersionInfo> Function()? versionSource}) => SettingsAboutController(
    versionSource:
        versionSource ??
        () async => const AppVersionInfo(version: '1.2.3', buildNumber: '4', packageName: 'net.bladewatch.flutter'),
  );

  group('load()', () {
    test('populates version info from the injected source', () async {
      final c = build();

      await c.load();

      expect(c.versionInfo?.version, '1.2.3');
      expect(c.versionInfo?.buildNumber, '4');
      expect(c.versionInfo?.packageName, 'net.bladewatch.flutter');
    });

    test('a version source that throws leaves versionInfo null rather than crashing', () async {
      final c = build(versionSource: () async => throw StateError('boom'));

      await c.load();

      expect(c.versionInfo, isNull);
    });
  });
}
