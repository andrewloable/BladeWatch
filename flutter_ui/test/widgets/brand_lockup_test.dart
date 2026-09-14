import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/widgets/brand_lockup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-ez0z: the app showed a blank screen for the whole of startup.
///
/// The native launch drawable draws an icon + wordmark as the window background,
/// but it stops being visible the moment Flutter's surface attaches — which is
/// long before the app is usable, because Startup waits on the daemons. It is
/// also unobservable from adb: five `screencap` attempts, including back-to-back
/// bursts from `am start`, caught only the launcher (too early) or Flutter's own
/// background (too late), because a screencap round trip is slower than the
/// handoff.
///
/// Drawing the same lockup in Dart is what makes the branding continuous — and,
/// unlike a window background, testable.
void main() {
  Widget wrap(Widget child, {Brightness brightness = Brightness.dark}) => MaterialApp(
        theme: brightness == Brightness.dark ? BladeWatchTheme.dark() : BladeWatchTheme.light(),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('shows the icon and the wordmark', (tester) async {
    await tester.pumpWidget(wrap(const BrandLockup()));

    expect(find.byKey(const ValueKey('brand.icon')), findsOneWidget);
    expect(find.byKey(const ValueKey('brand.wordmark')), findsOneWidget);
    expect(find.text('BladeWatch'), findsOneWidget);
  });

  testWidgets('the icon honours the requested size', (tester) async {
    await tester.pumpWidget(wrap(const BrandLockup(iconSize: 120)));

    final img = tester.widget<Image>(find.byKey(const ValueKey('brand.icon')));
    expect(img.width, 120);
    expect(img.height, 120);
  });

  /// The asset must be declared in pubspec.yaml. If it is not, Image.asset
  /// throws when it resolves — and it would do so on the device, on the very
  /// first screen, which is the worst place to find out.
  testWidgets('the icon asset actually resolves', (tester) async {
    await tester.pumpWidget(wrap(const BrandLockup()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in both themes without overflowing', (tester) async {
    for (final b in [Brightness.light, Brightness.dark]) {
      await tester.pumpWidget(wrap(const BrandLockup(), brightness: b));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$b');
      expect(find.text('BladeWatch'), findsOneWidget, reason: '$b');
    }
  });

  /// The icon carries no meaning a screen reader needs — the wordmark beside it
  /// already names the app. Announcing both would just be noise.
  testWidgets('the icon is excluded from semantics', (tester) async {
    await tester.pumpWidget(wrap(const BrandLockup()));
    final img = tester.widget<Image>(find.byKey(const ValueKey('brand.icon')));
    expect(img.excludeFromSemantics, isTrue);
  });
}
