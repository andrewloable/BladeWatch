import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-mtnk: every icon-only control must carry a label.
///
/// An `IconButton` with no `tooltip` and no `semanticLabel` is announced by a
/// screen reader as just "button" — the icon means nothing to it. Nine of the
/// eighteen in this app were in that state, while twenty-nine `cd_*` content
/// descriptions sat translated in all 19 catalogs and referenced by nothing. The
/// strings were ported during the Flutter migration; the labels were never
/// applied.
///
/// This is a source scan rather than a widget test on purpose: the failure is
/// "somebody added a new IconButton and forgot", which no screen's own test would
/// notice, and a widget test would only cover the screens somebody remembered to
/// write one for.
void main() {
  test('no IconButton is left without a tooltip or semanticLabel', () {
    var lib = Directory('lib');
    if (!lib.existsSync()) lib = Directory('flutter_ui/lib');
    expect(lib.existsSync(), isTrue, reason: 'could not locate lib/');

    final offenders = <String>[];
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      final path = f.path;
      if (!path.endsWith('.dart')) continue;
      if (path.contains('/gen/') || path.contains('/l10n/')) continue;

      final src = f.readAsStringSync();
      // Each IconButton( ... ) up to the matching close at the same indent.
      for (final m in RegExp(r'IconButton\((.*?)\n\s*\)', dotAll: true).allMatches(src)) {
        final body = m.group(1)!;
        if (body.contains('tooltip:') || body.contains('semanticLabel')) continue;
        final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
        offenders.add('${f.uri.pathSegments.last}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These icon-only buttons have no accessible label, so a screen '
          'reader announces only "button". Add `tooltip:` with one of the '
          'cd_* strings — 29 of them already exist, translated in all 19 '
          'catalogs, and most are still unused. Offenders: $offenders',
    );
  });
}
