import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every controller the app root owns must be disposed.
///
/// `main.dart` holds fourteen `ChangeNotifier` controllers. Thirteen were listed
/// in `dispose()`; `_appearanceController` was not — and it is one of the two
/// inside the `Listenable.merge` that drives `MaterialApp.themeMode`, so leaking
/// it leaks a listener on the app root.
///
/// It was missed for an understandable reason: it is created as
/// `widget.appearanceController ?? SettingsAppearanceController(...)`, which
/// looks like it might be someone else's to dispose. But `_shellController` and
/// `_startupController` use exactly the same pattern and ARE disposed, so the
/// convention in this file is settled — the omission was an oversight, not a
/// decision.
///
/// A source scan rather than a widget test on purpose: the failure is "somebody
/// adds a fifteenth controller and forgets", which no behavioural test would
/// notice, because a leaked listener does not change what the app renders.
void main() {
  test('every controller field in main.dart is disposed', () {
    var f = File('lib/main.dart');
    if (!f.existsSync()) f = File('flutter_ui/lib/main.dart');
    expect(f.existsSync(), isTrue, reason: 'could not locate main.dart');
    final src = f.readAsStringSync();

    // Fields typed `SomethingController` held on the State.
    final declared = <String>{
      ...RegExp(r'late final \w*Controller\s+(_\w+)').allMatches(src).map((m) => m.group(1)!),
      ...RegExp(r'final \w*Controller\s+(_\w+)\s*=').allMatches(src).map((m) => m.group(1)!),
    };
    expect(declared, isNotEmpty, reason: 'the scan found no controllers — has main.dart moved?');

    final disposed =
        RegExp(r'(_\w+)\.dispose\(\);').allMatches(src).map((m) => m.group(1)!).toSet();

    expect(
      declared.difference(disposed),
      isEmpty,
      reason: 'These controllers are created by the app root but never disposed. '
          'Add them to dispose(), alongside the others — including any created as '
          '`widget.x ?? New()`, which is the pattern _shellController and '
          '_startupController already follow.',
    );
  });
}
