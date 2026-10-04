import 'package:bladewatch_companion/tv.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a TV is a device that declares Android\'s TV feature', () async {
    expect(await isAndroidTv(features: () async => ['android.hardware.wifi', 'android.software.leanback']), isTrue);
    expect(await isAndroidTv(features: () async => ['android.hardware.touchscreen']), isFalse);
    expect(await isAndroidTv(features: () async => throw StateError('no plugin')), isFalse, reason: 'unknown is not a TV');
  });

  Future<List<FocusNode>> pumpForm(WidgetTester tester, {required bool tv}) async {
    final nodes = [FocusNode(), FocusNode(), FocusNode()];
    addTearDown(() {
      for (final n in nodes) {
        n.dispose();
      }
    });
    final form = Column(children: [
      TextField(focusNode: nodes[0]),
      TextField(focusNode: nodes[1]),
      ElevatedButton(focusNode: nodes[2], onPressed: () {}, child: const Text('Pair')),
    ]);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: tv ? DpadFieldExit(child: form) : form)));
    nodes[0].requestFocus();
    await tester.pump();
    return nodes;
  }

  // Seen on a Sony BRAVIA (2026-10-04): the remote could not get out of the first field.
  testWidgets('on a TV, up and down leave a text field for the next control', (tester) async {
    final nodes = await pumpForm(tester, tv: true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue, reason: 'down from the last field reaches the button');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);
  });

  testWidgets('elsewhere, a text field keeps up and down for its caret, as before', (tester) async {
    final nodes = await pumpForm(tester, tv: false);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue);
  });

  // The owner, 2026-10-04: up from Diagnostics' "Run speed test" could not bring the text above it
  // back, because only controls take focus. Up now scrolls the page while it can.
  testWidgets('on a TV, up and down scroll a page to its text before focus leaves it', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    final button = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(button.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DpadFieldExit(
          child: ListView(controller: controller, children: [
            const SizedBox(height: 1500, child: Text('Measures the link between this device and your car...')),
            ElevatedButton(focusNode: button, onPressed: () {}, child: const Text('Run speed test')),
          ]),
        ),
      ),
    ));
    controller.jumpTo(controller.position.maxScrollExtent);
    button.requestFocus();
    await tester.pumpAndSettle();
    final bottom = controller.offset;

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(controller.offset, lessThan(bottom), reason: 'the text above came back into view');
    expect(button.hasFocus, isTrue, reason: 'focus stays put while the page scrolls');

    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(controller.offset, 0, reason: 'up scrolls all the way to the top');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0), reason: 'and down scrolls back');
  });

  /// A side panel beside a page, as on a TV: [rail] items down the left, the page on the right.
  Future<(ScrollController, FocusNode, List<FocusNode>)> pumpShell(WidgetTester tester, {required double pageHeight}) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final page = ScrollController();
    final button = FocusNode(debugLabel: 'Run speed test');
    final rail = [for (var i = 0; i < 12; i++) FocusNode(debugLabel: 'rail $i')];
    addTearDown(() {
      page.dispose();
      button.dispose();
      for (final n in rail) {
        n.dispose();
      }
    });
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => DpadFieldExit(child: child!),
      home: Scaffold(
        body: Row(children: [
          TvPane(
            child: SizedBox(
              width: 480,
              child: ListView(children: [
                for (final n in rail) SizedBox(height: 90, child: InkWell(focusNode: n, onTap: () {}, child: Text('${n.debugLabel}'))),
              ]),
            ),
          ),
          Expanded(
            child: TvPane(
              child: ListView(controller: page, children: [
                const SizedBox(height: 500, child: Text('NETWORK')),
                OutlinedButton(focusNode: button, onPressed: () {}, child: const Text('Run speed test')),
                SizedBox(height: pageHeight, child: const Text('STORAGE')),
              ]),
            ),
          ),
        ]),
      ),
    ));
    return (page, button, rail);
  }

  // The owner, 2026-10-04: in Diagnostics, down and then up never brought the top labels back --
  // up jumped into the side panel. Focus moves at the end of the event, so the action read where
  // focus WAS and took the jump for a move within the page.
  testWidgets('on a TV, up from a page control scrolls the page back rather than jump into the side panel', (tester) async {
    final (page, button, rail) = await pumpShell(tester, pageHeight: 1500);
    page.jumpTo(200); // the button sits mid-screen, with panel items above it
    button.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(button.hasFocus, isTrue);
    expect(rail.any((n) => n.hasFocus), isFalse);
    expect(page.offset, 0, reason: 'the labels above came back into view');
  });

  testWidgets('on a TV, down from the last control of a page stays on the page', (tester) async {
    final (page, button, rail) = await pumpShell(tester, pageHeight: 100);
    button.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(button.hasFocus, isTrue, reason: 'nothing below it on the page, and the panel is another column');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(rail.any((n) => n.hasFocus), isTrue, reason: 'left still crosses into the panel');
  });

  testWidgets('on a TV, a ring marks the focused control, and nothing else', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: BwHud.themeData(Brightness.dark),
      builder: (context, child) => TvFocusRing(child: child!),
      home: Scaffold(body: Center(child: ElevatedButton(focusNode: node, onPressed: () {}, child: const Text('Pair')))),
    ));
    final ring = find.descendant(of: find.byType(TvFocusRing), matching: find.byType(CustomPaint)).last;
    expect(ring, paintsNothing);
    node.requestFocus();
    await tester.pump();
    expect(ring, paints..rrect()..rrect(color: BwHud.of(tester.element(find.text('Pair'))).accent));

    await tester.drag(find.byType(Scaffold), const Offset(0, -10)); // a scroll repaints, harmlessly
    node.unfocus();
    await tester.pump();
    expect(ring, paintsNothing);
  });

  // The owner, 2026-10-04: a trip's summary has its buttons in the title bar and nothing to focus
  // below, so down did nothing and the scores further down could not be reached.
  testWidgets('on a TV, up and down from a title bar button scroll the page under it', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final page = ScrollController();
    final delete = FocusNode(debugLabel: 'delete');
    addTearDown(page.dispose);
    addTearDown(delete.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => DpadFieldExit(child: child!),
      home: Scaffold(
        body: Column(children: [
          Row(children: [const Text('TRIP SUMMARY'), IconButton(focusNode: delete, onPressed: () {}, icon: const Icon(Icons.delete))]),
          Expanded(child: ListView(controller: page, children: const [SizedBox(height: 3000, child: Text('scores'))])),
        ]),
      ),
    ));
    delete.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(page.offset, greaterThan(0), reason: 'the page scrolled down');
    expect(delete.hasFocus, isTrue, reason: 'focus stays on the only control');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(page.offset, 0, reason: 'and back up');
  });
}
