import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-ez0z, BladeWatch-sjz4: the launch splash is Android resources, not Dart, so nothing
/// in the Flutter build fails if it silently reverts. Since BladeWatch-sjz4 it is plain black in
/// both modes with only the icon, the first frame of the animated intro (BladeIntro). These read the actual files,
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
      // Checked on the markup, not the explanatory comment.
      final code = xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
      expect(code, contains('@mipmap/ic_launcher_foreground'), reason: 'the app icon must be shown');
      // The intro reveals the wordmark; drawing it here too would make the handoff jump.
      expect(code, isNot(contains('wordmark')), reason: 'the wordmark is the intro\'s, not the splash\'s');
      // Centred with no insets: exactly where BladeIntro's first frame draws the icon.
      expect(code, isNot(contains('android:top=')), reason: 'the icon must sit dead centre');
      expect(code, isNot(contains('android:bottom=')), reason: 'the icon must sit dead centre');
      expect(xml, contains('@color/splash_background'),
          reason: 'the background must come from the day/night colour, not a literal');
    });

    test('no drawable-v21 copy shadows it', () {
      // minSdk is 29, so a -v21 qualifier matches every device and would win.
      expect(res('drawable-v21/launch_background.xml').existsSync(), isFalse,
          reason: 'drawable-v21/ overrides drawable/ on every device at minSdk 29, '
              'so edits to drawable/ would have no effect');
    });

    test('the splash is black in light and dark mode', () {
      // The owner's decision of 2026-11-19 (BladeWatch-sjz4): black in both modes. It was white
      // in light mode before.
      for (final dir in ['values', 'values-night']) {
        final xml = res('$dir/colors.xml').readAsStringSync();
        expect(RegExp(r'<color name="splash_background">#000000</color>').hasMatch(xml), isTrue,
            reason: '$dir/colors.xml must define splash_background as black');
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
