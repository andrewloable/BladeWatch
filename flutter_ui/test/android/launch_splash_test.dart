import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-ez0z: the launch splash is Android resources, not Dart, so nothing
/// in the Flutter build fails if it silently reverts. These read the actual files,
/// the same way `test/theme/color_tokens_test.dart` reads the Android colour XML.
///
/// Three separate regressions are pinned here, and every one of them already
/// happened:
///
/// 1. The drawable was the untouched `flutter create` template — a plain white
///    rectangle with the image slot commented out — which is why launching the app
///    showed a blank white screen for the whole of engine startup.
/// 2. A `drawable-v21/launch_background.xml` sat alongside it. At `minSdk 29`
///    EVERY device is v21+, so that copy always won and the file in `drawable/`
///    was dead. Editing `drawable/` alone changed nothing on the device.
/// 3. A literal `--` inside an XML comment makes the whole file invalid. aapt then
///    drops the drawable and the build fails with the unhelpful
///    "resource drawable/launch_background not found". Easy to write, silent until
///    the build breaks, and not flagged by any editor.
void main() {
  File res(String path) {
    // Tests run with flutter_ui/ as CWD; fall back to the repo root.
    var f = File('android/app/src/main/res/$path');
    if (!f.existsSync()) f = File('flutter_ui/android/app/src/main/res/$path');
    return f;
  }

  group('launch splash resources', () {
    test('the launch drawable is not the flutter create template', () {
      final f = res('drawable/launch_background.xml');
      expect(f.existsSync(), isTrue, reason: 'drawable/launch_background.xml is missing');
      final xml = f.readAsStringSync();

      expect(xml, isNot(contains('You can insert your own image assets here')),
          reason: 'still the stock template — this is the blank white screen bug');
      expect(xml, contains('@mipmap/ic_launcher'), reason: 'the app icon must be shown');
      expect(xml, contains('@drawable/wordmark_bladewatch'),
          reason: 'the BladeWatch wordmark must be shown');
      expect(xml, contains('@color/splash_background'),
          reason: 'the background must come from the day/night colour, not a literal');
    });

    test('no drawable-v21 copy shadows it', () {
      // minSdk is 29, so a -v21 qualifier matches every device and would win.
      expect(res('drawable-v21/launch_background.xml').existsSync(), isFalse,
          reason: 'drawable-v21/ overrides drawable/ on every device at minSdk 29, '
              'so edits to drawable/ would have no effect');
    });

    test('splash colours are defined for both light and dark', () {
      final day = res('values/colors.xml').readAsStringSync();
      final night = res('values-night/colors.xml').readAsStringSync();

      // The owner's requirement: plain white in light mode, plain black in dark.
      expect(day, contains('#FFFFFF'), reason: 'light mode splash must be white');
      expect(night, contains('#000000'), reason: 'dark mode splash must be black');

      for (final name in ['splash_background', 'splash_foreground']) {
        expect(day, contains(name), reason: '$name missing from values/colors.xml');
        expect(night, contains(name), reason: '$name missing from values-night/colors.xml');
      }
    });

    test('both themes paint the branded drawable, not a theme attribute', () {
      // ?android:colorBackground is what let a white frame through between the
      // launch drawable and Flutter's first paint. Comments are stripped first so
      // the note explaining that trap does not trip the check documenting it.
      String stripComments(String xml) =>
          xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

      for (final dir in ['values', 'values-night']) {
        final xml = stripComments(res('$dir/styles.xml').readAsStringSync());
        // BOTH themes, not just LaunchTheme. LaunchTheme paints only the brief
        // "starting window"; NormalTheme replaces it as soon as the process
        // starts and holds until Flutter's first frame. A plain colour there
        // meant the icon and wordmark vanished almost immediately.
        expect(
          RegExp(r'@drawable/launch_background').allMatches(xml).length,
          2,
          reason: '$dir must use the branded drawable for BOTH LaunchTheme and NormalTheme',
        );
        expect(xml, isNot(contains('?android:colorBackground')), reason: dir);
      }
    });

    test('the wordmark ships at every density it claims', () {
      for (final d in ['hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        final f = res('drawable-$d/wordmark_bladewatch.png');
        expect(f.existsSync(), isTrue, reason: 'missing wordmark for $d');
        expect(f.lengthSync(), greaterThan(0), reason: 'empty wordmark for $d');
      }
    });

    /// A literal `--` inside an XML comment is invalid and makes aapt drop the
    /// whole file. It cost a build here already.
    test('no splash XML contains a double hyphen inside a comment', () {
      const files = [
        'drawable/launch_background.xml',
        'values/colors.xml',
        'values-night/colors.xml',
        'values/styles.xml',
        'values-night/styles.xml',
      ];
      for (final path in files) {
        final xml = res(path).readAsStringSync();
        for (final match in RegExp(r'<!--(.*?)-->', dotAll: true).allMatches(xml)) {
          expect(match.group(1), isNot(contains('--')),
              reason: '$path has "--" inside an XML comment, which is invalid XML');
        }
      }
    });
  });
}
