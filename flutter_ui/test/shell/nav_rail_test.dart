import 'dart:ui' show SemanticsAction, Tristate;

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/shell/nav_rail.dart';
import 'package:bladewatch_ui/shell/rail_destination.dart';
import 'package:bladewatch_ui/shell/route_stubs.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? BladeWatchTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('renders all 9 rail destinations with their localised labels, uppercased', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));

    expect(find.byType(NavRailItem), findsNWidgets(9));
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('LOCATION'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('RECORDINGS'), findsOneWidget);
    expect(find.text('VEHICLE'), findsOneWidget);
    expect(find.text('TRIPS'), findsOneWidget);
    expect(find.text('DIAGNOSTICS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('ABOUT'), findsOneWidget);
  });

  // BladeWatch-5l5o: on the head unit (landscape, ~604 logical px between the car's bars) About sat
  // below the fold of a rail that had to be scrolled.
  testWidgets('the landscape rail, globe and all, fits the head unit without scrolling', (tester) async {
    await tester.pumpWidget(
      _wrap(
        NavRail(
          selectedRoute: BwRoutes.dashboard,
          onSelect: (_) {},
          showLanguageHeader: true,
          onLanguageTap: () {},
          compact: true,
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('navRailColumn'))).height, lessThanOrEqualTo(604));
    // ...and the rail's panel still runs the full height, items at the top.
    final screen = tester.getSize(find.byType(Scaffold));
    expect(tester.getSize(find.byType(NavRail)).height, screen.height);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('navRailColumn'))).dy,
      tester.getTopLeft(find.byType(NavRail)).dy,
    );
    for (var i = 0; i < railDestinations.length; i++) {
      expect(
        tester.getSize(find.byKey(ValueKey('navRailItem_$i'))).height,
        greaterThanOrEqualTo(48),
        reason: 'still a full touch target',
      );
    }
  });

  testWidgets('renders every destination icon', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));

    for (final destination in railDestinations) {
      expect(find.byIcon(destination.icon), findsOneWidget);
    }
  });

  // The reference design has no hairline before About (the owner's screenshots show uniform spacing).
  testWidgets('no divider: the nine items are one uniformly spaced stack', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));

    expect(find.byKey(const ValueKey('navRailDivider')), findsNothing);
    final tops = [
      for (var i = 0; i < railDestinations.length; i++) tester.getTopLeft(find.byKey(ValueKey('navRailItem_$i'))).dy,
    ];
    final pitches = [for (var i = 1; i < tops.length; i++) tops[i] - tops[i - 1]];
    expect(pitches.toSet(), {pitches.first}, reason: 'every gap the same, About included');
  });

  testWidgets('marks only the selected destination as selected', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.vehicle, onSelect: (_) {})));

    for (var i = 0; i < railDestinations.length; i++) {
      final semantics = tester.getSemantics(find.byKey(ValueKey('navRailItem_$i')));
      final expectedSelected = railDestinations[i].routeName == BwRoutes.vehicle;
      expect(
        semantics.flagsCollection.isSelected,
        expectedSelected ? Tristate.isTrue : Tristate.isFalse,
        reason: 'index $i (${railDestinations[i].routeName})',
      );
    }
  });

  testWidgets('tapping a destination reports its route name', (tester) async {
    String? tapped;
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (r) => tapped = r)));

    await tester.tap(find.text('TRIPS'));

    expect(tapped, BwRoutes.trips);
  });

  testWidgets('language header is shown only when showLanguageHeader is true', (tester) async {
    await tester.pumpWidget(
      _wrap(
        NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {}, showLanguageHeader: true, onLanguageTap: () {}),
      ),
    );
    expect(find.byIcon(Icons.translate), findsOneWidget);

    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));
    expect(find.byIcon(Icons.translate), findsNothing);
  });

  testWidgets('tapping the language header calls onLanguageTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        NavRail(
          selectedRoute: BwRoutes.dashboard,
          onSelect: (_) {},
          showLanguageHeader: true,
          onLanguageTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.translate));

    expect(tapped, isTrue);
  });

  group('HUD look (BladeWatch-8w4p)', () {
    Finder item(int i) => find.byKey(ValueKey('navRailItem_$i'));
    BoxDecoration decoration(WidgetTester tester, int i) =>
        tester.widget<Container>(find.descendant(of: item(i), matching: find.byType(Container)).first).decoration!
            as BoxDecoration;
    Icon iconOf(WidgetTester tester, int i) =>
        tester.widget<Icon>(find.descendant(of: item(i), matching: find.byType(Icon)));
    Text labelOf(WidgetTester tester, int i) =>
        tester.widget<Text>(find.descendant(of: item(i), matching: find.byType(Text)));

    Future<void> pumpRail(WidgetTester tester, ThemeData theme, {bool compact = false, bool onRight = false}) async {
      await tester.pumpWidget(
        _wrap(
          NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {}, compact: compact, onRight: onRight),
          theme: theme,
        ),
      );
      // MaterialApp animates between themes; let the new one land.
      await tester.pumpAndSettle();
    }

    testWidgets('dark: the active item has the gradient, accent border, glow and bold tight label', (tester) async {
      await pumpRail(tester, BladeWatchTheme.dark());
      const hud = BwHud.dark;

      final active = decoration(tester, 0);
      expect(
        active.gradient,
        LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: hud.navActiveGradient),
      );
      expect(active.border, Border.all(color: hud.navActiveBorder));
      expect(active.boxShadow, hud.navActiveShadow);
      expect(active.borderRadius, BorderRadius.circular(4));
      expect(iconOf(tester, 0).size, 20);
      expect(iconOf(tester, 0).color, hud.navActiveIcon);
      expect(iconOf(tester, 0).shadows, [hud.glowCyan]);
      final label = labelOf(tester, 0).style!;
      expect(label.fontFamily, BwHud.fontFamily);
      expect(label.fontSize, 10);
      expect(label.fontWeight, FontWeight.w700);
      expect(label.letterSpacing, -0.5);
      expect(label.color, hud.navActiveLabel);
    });

    testWidgets('dark: an inactive item is bare, 18 dp, normal weight, slate', (tester) async {
      await pumpRail(tester, BladeWatchTheme.dark());
      const hud = BwHud.dark;

      final inactive = decoration(tester, 1);
      expect(inactive.gradient, isNull);
      expect(inactive.boxShadow, isEmpty);
      expect(inactive.border, Border.all(color: Colors.transparent), reason: 'same box as active: no layout jump');
      expect(iconOf(tester, 1).size, 18);
      expect(iconOf(tester, 1).color, hud.navInactive);
      expect(iconOf(tester, 1).shadows, isNull);
      final label = labelOf(tester, 1).style!;
      expect(label.fontWeight, FontWeight.w400);
      expect(label.letterSpacing, 0);
      expect(label.color, hud.navInactive);
    });

    testWidgets('light: cyan-50 to white, no glow, cyan-700 label over a cyan-600 icon', (tester) async {
      await pumpRail(tester, BladeWatchTheme.light());
      const hud = BwHud.light;

      final active = decoration(tester, 0);
      expect((active.gradient! as LinearGradient).colors, hud.navActiveGradient);
      expect(active.border, Border.all(color: hud.navActiveBorder));
      expect(active.boxShadow, hud.navActiveShadow);
      expect(iconOf(tester, 0).shadows, isNull, reason: 'the light design has no glow');
      expect(iconOf(tester, 0).color, hud.navActiveIcon);
      expect(labelOf(tester, 0).style!.color, hud.navActiveLabel);
      expect(iconOf(tester, 1).color, hud.navInactive);
    });

    testWidgets('the rail frame: background, edge on the content side, full 80 dp', (tester) async {
      await pumpRail(tester, BladeWatchTheme.dark());
      var frame = tester.widget<Container>(
        find.descendant(of: find.byType(NavRail), matching: find.byType(Container)).first,
      );
      var deco = frame.decoration! as BoxDecoration;
      expect(deco.color, BwHud.dark.railBackground);
      expect(deco.border, Border(right: BorderSide(color: BwHud.dark.railBorder)));
      expect(deco.boxShadow, BwHud.dark.railShadow);
      expect(tester.getSize(find.byType(NavRail)).width, 80);

      await pumpRail(tester, BladeWatchTheme.light(), onRight: true);
      frame = tester.widget<Container>(
        find.descendant(of: find.byType(NavRail), matching: find.byType(Container)).first,
      );
      deco = frame.decoration! as BoxDecoration;
      expect(deco.color, BwHud.light.railBackground);
      expect(
        deco.border,
        Border(left: BorderSide(color: BwHud.light.railBorder)),
        reason: 'rail on the right: edge on its left',
      );
    });

    testWidgets(
      'item height: 52 landscape (nine fit 604 dp), 64 portrait; 4 dp margin either side of the 79 dp inside the edge line',
      (tester) async {
        Size box(WidgetTester t) => t.getSize(find.descendant(of: item(0), matching: find.byType(Container)).first);
        await pumpRail(tester, BladeWatchTheme.dark(), compact: true);
        expect(box(tester), const Size(71, 52));
        await pumpRail(tester, BladeWatchTheme.dark());
        expect(box(tester), const Size(71, 64));
      },
    );

    testWidgets('the icons are the Material stand-ins for the reference glyphs, in rail order', (tester) async {
      expect(
        [for (final d in railDestinations) d.icon],
        [
          Icons.public,
          Icons.navigation,
          Icons.play_arrow,
          Icons.videocam,
          Icons.directions_car,
          Icons.show_chart,
          Icons.monitor_heart,
          Icons.settings,
          Icons.info,
        ],
      );
    });

    testWidgets('the label is uppercased for display but announced as the localized string, and taps', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRail(tester, BladeWatchTheme.dark());
      final data = tester.getSemantics(item(5)).getSemanticsData();
      expect(data.label, 'Trips');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('a long localized label is scaled down, never overflows', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 80,
            child: NavRailItem(
              icon: Icons.info,
              label: 'Diagnoseübersichtsanzeige',
              selected: true,
              onTap: () {},
              dense: true,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
