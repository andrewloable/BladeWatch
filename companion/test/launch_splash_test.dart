import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-sjz4: the companion's launch screens are platform resources, not Dart, so nothing in
/// the Flutter build fails if they revert to the white template. They must be black, show the logo
/// at the size the animated intro (BladeIntro) starts from, and leave no white frame anywhere.
void main() {
  File file(String path) {
    var f = File(path);
    if (!f.existsSync()) f = File('companion/$path');
    return f;
  }

  String stripComments(String xml) => xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  const res = 'android/app/src/main/res';

  test('the Android launch drawable is black with the logo, not the white template', () {
    final xml = stripComments(file('$res/drawable/launch_background.xml').readAsStringSync());
    expect(xml, isNot(contains('@android:color/white')));
    expect(xml, contains('@color/splash_background'));
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(file('$res/drawable-v21/launch_background.xml').existsSync(), isFalse,
        reason: 'a drawable-v21 copy would shadow drawable/ on every device');
    expect(file('$res/values/colors.xml').readAsStringSync(), contains('<color name="splash_background">#000000</color>'));
  });

  test('both themes, light and dark, old and Android 12+, paint the black drawable', () {
    for (final dir in ['values', 'values-night', 'values-v31', 'values-night-v31']) {
      final xml = stripComments(file('$res/$dir/styles.xml').readAsStringSync());
      expect(RegExp('@drawable/launch_background').allMatches(xml).length, 2,
          reason: '$dir: LaunchTheme and NormalTheme must both use it (no white frame before Flutter draws)');
      expect(xml, isNot(contains('?android:colorBackground')), reason: dir);
    }
    for (final dir in ['values-v31', 'values-night-v31']) {
      final xml = stripComments(file('$res/$dir/styles.xml').readAsStringSync());
      expect(xml, contains('android:windowSplashScreenBackground">@color/splash_background'), reason: dir);
      expect(xml, contains('android:windowSplashScreenAnimatedIcon">@drawable/splash_icon'), reason: dir);
    }
  });

  test('the Android 12+ splash icon is inset to the same 108 dp as the intro', () {
    final xml = file('$res/drawable/splash_icon.xml').readAsStringSync();
    // The system scales it to 288 dp; 31.25 percent each side leaves 37.5 percent = 108 dp.
    expect(xml, contains('android:inset="31.25%"'));
    expect(xml, contains('@drawable/ic_launcher_foreground'));
  });

  test('the iOS launch screen is black with the logo at 108 points', () {
    final xml = file('ios/Runner/Base.lproj/LaunchScreen.storyboard').readAsStringSync();
    expect(xml, contains('key="backgroundColor" red="0" green="0" blue="0"'));
    expect(xml, contains('<image name="LaunchImage" width="108" height="108"/>'));
    for (final name in ['LaunchImage.png', 'LaunchImage@2x.png', 'LaunchImage@3x.png']) {
      final f = file('ios/Runner/Assets.xcassets/LaunchImage.imageset/$name');
      expect(f.lengthSync(), greaterThan(1000), reason: '$name must be the logo, not the 1x1 placeholder');
    }
  });

  test('the macOS window is black before Flutter draws', () {
    final swift = file('macos/Runner/MainFlutterWindow.swift').readAsStringSync();
    expect(swift, contains('flutterViewController.backgroundColor = .black'));
    expect(swift, contains('self.backgroundColor = .black'));
  });
}
