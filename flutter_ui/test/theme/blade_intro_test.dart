import 'package:bladewatch_theme/blade_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-sjz4: the animated launch intro shared by the in-car app and the companion.
void main() {
  // The in-car app's real logo, the same asset main.dart gives the intro.
  const logo = AssetImage('assets/brand/app_icon.png');

  Future<void> pumpIntro(WidgetTester tester, {required VoidCallback onDone, bool reducedMotion = false, Widget? under}) {
    return tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Stack(children: [
        under ?? const SizedBox.expand(),
        BladeIntro(logo: logo, logoSize: 48, onDone: onDone),
      ]),
    ));
  }

  testWidgets('plays for about 1.2 s and then calls onDone exactly once', (tester) async {
    var done = 0;
    await pumpIntro(tester, onDone: () => done++);

    await tester.pump(const Duration(milliseconds: 600));
    expect(done, 0, reason: 'not before the intro has played');
    expect(find.byKey(const ValueKey('bladeIntro.wordmark')), findsOneWidget);
    expect(find.text('BLADEWATCH'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(done, 1);

    await tester.pump(const Duration(seconds: 2));
    expect(done, 1, reason: 'never twice');
  });

  testWidgets('the first frame is the native splash: the logo at its size, centred, nothing else', (tester) async {
    await pumpIntro(tester, onDone: () {});

    final logoRect = tester.getRect(find.byKey(const ValueKey('bladeIntro.logo')));
    final screen = tester.getRect(find.byKey(const ValueKey('bladeIntro')));
    expect(logoRect.size, const Size(48, 48));
    expect(logoRect.center, screen.center);
    final wordmark = tester.widget<Opacity>(
        find.ancestor(of: find.byKey(const ValueKey('bladeIntro.wordmark')), matching: find.byType(Opacity)).first);
    expect(wordmark.opacity, 0.0, reason: 'the wordmark is revealed by the animation, not shown at the start');
    expect(tester.getSize(find.byKey(const ValueKey('bladeIntro.scan'))).width, 0.0);
  });

  testWidgets('ends with the wordmark shown and the scan line swept', (tester) async {
    await pumpIntro(tester, onDone: () {});
    await tester.pump(const Duration(milliseconds: 1120));

    final wordmark = tester.widget<Opacity>(
        find.ancestor(of: find.byKey(const ValueKey('bladeIntro.wordmark')), matching: find.byType(Opacity)).first);
    expect(wordmark.opacity, 1.0);
    expect(tester.getSize(find.byKey(const ValueKey('bladeIntro.scan'))).width, 220.0);
    expect(tester.getRect(find.byKey(const ValueKey('bladeIntro.logo'))).center.dy,
        lessThan(tester.getRect(find.byKey(const ValueKey('bladeIntro'))).center.dy),
        reason: 'the logo has risen to make room for the wordmark');
  });

  testWidgets('reduced motion skips the intro after the first frame', (tester) async {
    var done = 0;
    await pumpIntro(tester, onDone: () => done++, reducedMotion: true);
    await tester.pump();

    expect(done, 1);
  });

  testWidgets('it blocks taps while it shows', (tester) async {
    var taps = 0;
    await pumpIntro(
      tester,
      onDone: () {},
      under: Center(child: ElevatedButton(onPressed: () => taps++, child: const Text('under'))),
    );

    await tester.tap(find.text('under'), warnIfMissed: false);
    expect(taps, 0);
    await tester.pumpAndSettle();
  });
}
