import 'package:bladewatch_ui/screens/surveillance/roi_editor.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = Size(200, 100);

  group('roiToNormalised', () {
    test('maps local pixels to 0..1 against the widget size', () {
      expect(roiToNormalised(const Offset(100, 50), size), const Offset(0.5, 0.5));
      expect(roiToNormalised(Offset.zero, size), Offset.zero);
      expect(roiToNormalised(const Offset(200, 100), size), const Offset(1, 1));
    });

    test('clamps a touch that leaves the canvas', () {
      // A finger dragged past the edge must pin the vertex to the border, not
      // produce an out-of-range coordinate the engine would rasterise oddly.
      expect(roiToNormalised(const Offset(-40, -10), size), Offset.zero);
      expect(roiToNormalised(const Offset(400, 900), size), const Offset(1, 1));
    });

    test('a zero-sized canvas yields zero instead of dividing by zero', () {
      expect(roiToNormalised(const Offset(10, 10), Size.zero), Offset.zero);
    });
  });

  test('roiToLocal is the inverse of roiToNormalised', () {
    expect(roiToLocal(const Offset(0.5, 0.25), size), const Offset(100, 25));
  });

  group('roiHitTest', () {
    final points = [const Offset(0.5, 0.5)];

    test('grabs a vertex within the touch slop', () {
      expect(roiHitTest(points, const Offset(100, 50), size), 0);
      expect(roiHitTest(points, const Offset(110, 60), size), 0);
    });

    test('returns null for empty canvas beyond the slop', () {
      expect(roiHitTest(points, const Offset(100, 50), size, slop: 4), 0);
      expect(roiHitTest(points, const Offset(180, 90), size, slop: 4), isNull);
    });

    test('the earlier vertex wins when two overlap', () {
      // Keeps a repeated drag stable instead of alternating between them —
      // native's findPointAt returns on first match for the same reason.
      final overlapping = [const Offset(0.5, 0.5), const Offset(0.5, 0.5)];
      expect(roiHitTest(overlapping, const Offset(100, 50), size), 0);
    });

    test('an empty polygon has nothing to hit', () {
      expect(roiHitTest(const [], const Offset(100, 50), size), isNull);
    });
  });

  group('roiIsApplied', () {
    test('needs 3 points, because that is what the engine requires', () {
      // applyQuadrantRoi clears the quadrant below 3 vertices.
      expect(roiIsApplied(const []), isFalse);
      expect(roiIsApplied(const [Offset(0, 0)]), isFalse);
      expect(roiIsApplied(const [Offset(0, 0), Offset(1, 0)]), isFalse);
      expect(roiIsApplied(const [Offset(0, 0), Offset(1, 0), Offset(1, 1)]), isTrue);
    });
  });

  group('RoiPainter', () {
    test('repaints only when something it draws changed', () {
      const a = RoiPainter(normalised: [Offset(0, 0)], color: Colors.red, vertexColor: Colors.red);
      const same = RoiPainter(normalised: [Offset(0, 0)], color: Colors.red, vertexColor: Colors.red);
      const movedPoint = RoiPainter(normalised: [Offset(0, 1)], color: Colors.red, vertexColor: Colors.red);
      const extraPoint =
          RoiPainter(normalised: [Offset(0, 0), Offset(1, 1)], color: Colors.red, vertexColor: Colors.red);
      const recoloured = RoiPainter(normalised: [Offset(0, 0)], color: Colors.blue, vertexColor: Colors.red);

      expect(same.shouldRepaint(a), isFalse);
      expect(movedPoint.shouldRepaint(a), isTrue);
      expect(extraPoint.shouldRepaint(a), isTrue);
      expect(recoloured.shouldRepaint(a), isTrue);
    });
  });

  group('RoiEditor', () {
    Future<List<List<Offset>>> pump(WidgetTester tester, List<Offset> initial) async {
      final emitted = <List<Offset>>[];
      var points = initial;
      await tester.pumpWidget(MaterialApp(
        theme: BladeWatchTheme.light(),
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                width: 200,
                height: 100,
                child: RoiEditor(
                  points: points,
                  onChanged: (p) {
                    emitted.add(p);
                    setState(() => points = p);
                  },
                ),
              ),
            ),
          ),
        ),
      ));
      return emitted;
    }

    testWidgets('tapping empty canvas adds a normalised vertex', (tester) async {
      final emitted = await pump(tester, const []);

      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('roi.canvas'))));
      await tester.pumpAndSettle();

      expect(emitted.single.single, const Offset(0.5, 0.5));
    });

    testWidgets('stops accepting new vertices at the maximum', (tester) async {
      final full = [for (var i = 0; i < kRoiMaxPoints; i++) Offset(i / 10, 0.9)];
      final emitted = await pump(tester, full);

      // Well clear of every existing vertex, so this is an add, not a grab.
      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('roi.canvas'))));
      await tester.pumpAndSettle();

      expect(emitted, isEmpty, reason: 'a tap past the maximum is ignored, not a silent replace');
    });

    testWidgets('dragging a vertex moves that vertex and no other', (tester) async {
      final emitted = await pump(tester, const [Offset(0.5, 0.5), Offset(0.9, 0.9)]);
      final canvas = find.byKey(const ValueKey('roi.canvas'));

      await tester.dragFrom(tester.getCenter(canvas), const Offset(-50, 0));
      await tester.pumpAndSettle();

      expect(emitted, isNotEmpty);
      final last = emitted.last;
      expect(last[0].dx, closeTo(0.25, 0.01), reason: 'the grabbed vertex moved left');
      expect(last[1], const Offset(0.9, 0.9), reason: 'the other vertex is untouched');
    });

    testWidgets('a drag that starts on empty canvas does NOT draw', (tester) async {
      // Regression: the editor used to claim every pan, so a user dragging to
      // SCROLL the settings pane past the editor drew a row of stray points.
      // It now only claims a pan that starts on an existing vertex, leaving
      // everything else to the surrounding scrollable.
      final emitted = await pump(tester, const [Offset(0.05, 0.05)]);
      final canvas = find.byKey(const ValueKey('roi.canvas'));

      await tester.dragFrom(tester.getCenter(canvas), const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(emitted, isEmpty);
    });

    testWidgets('the editor does not block the surrounding list from scrolling', (tester) async {
      // The concrete symptom of the bug above, at the layout level.
      final controller = ScrollController();
      await tester.pumpWidget(MaterialApp(
        theme: BladeWatchTheme.light(),
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 400),
              SizedBox(
                width: 200,
                height: 200,
                child: RoiEditor(points: const [Offset(0.9, 0.9)], onChanged: (_) {}),
              ),
              const SizedBox(height: 800),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Drag starting INSIDE the editor, away from its single vertex.
      await tester.dragFrom(tester.getCenter(find.byKey(const ValueKey('roi.canvas'))), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(controller.offset, greaterThan(0), reason: 'the list scrolled instead of drawing');
    });

    testWidgets('a cancelled drag releases the vertex instead of leaving it stuck', (tester) async {
      // A gesture can be cancelled out from under the editor (a competing
      // recogniser, or the pane being swiped away mid-drag). Leaving _dragging
      // set would make the NEXT touch anywhere silently drag that old vertex.
      final emitted = await pump(tester, const [Offset(0.5, 0.5)]);
      final canvas = find.byKey(const ValueKey('roi.canvas'));

      final gesture = await tester.startGesture(tester.getCenter(canvas));
      // Move first so the pan recogniser actually claims the gesture; a cancel
      // before that is a no-op and would not exercise onPanCancel at all.
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();

      final countAfterCancel = emitted.length;
      // A fresh touch far from the vertex must ADD, proving nothing is latched.
      await tester.tapAt(tester.getTopLeft(canvas) + const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(emitted.length, greaterThan(countAfterCancel));
      expect(emitted.last.length, 2);
    });

    testWidgets('renders a closed zone once there are 3 points, in both themes', (tester) async {
      for (final theme in [BladeWatchTheme.light(), BladeWatchTheme.dark()]) {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100,
              child: RoiEditor(
                points: const [Offset(0.1, 0.1), Offset(0.9, 0.1), Offset(0.5, 0.9)],
                onChanged: (_) {},
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  });
}
