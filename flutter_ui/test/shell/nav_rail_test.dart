import 'dart:ui' show Tristate;

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/shell/nav_rail.dart';
import 'package:bladewatch_ui/shell/rail_destination.dart';
import 'package:bladewatch_ui/shell/route_stubs.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders all 9 rail destinations with their localised labels', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));

    expect(find.byType(NavRailItem), findsNWidgets(9));
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Recordings'), findsOneWidget);
    expect(find.text('Vehicle'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('renders every destination icon', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));

    for (final destination in railDestinations) {
      expect(find.byIcon(destination.icon), findsOneWidget);
    }
  });

  testWidgets('exactly one divider, immediately before the About item', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));

    expect(find.byKey(const ValueKey('navRailDivider')), findsOneWidget);

    final column = tester.widget<Column>(find.byKey(const ValueKey('navRailColumn')));
    final children = column.children;
    final dividerIndex = children.indexWhere((w) => w.key == const ValueKey('navRailDivider'));
    final aboutIndex = children.indexWhere((w) => w.key == const ValueKey('navRailItem_$aboutRailIndex'));

    expect(dividerIndex, greaterThan(0));
    expect(aboutIndex, dividerIndex + 1);
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

    await tester.tap(find.text('Trips'));

    expect(tapped, BwRoutes.trips);
  });

  testWidgets('language header is shown only when showLanguageHeader is true', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(
      selectedRoute: BwRoutes.dashboard,
      onSelect: (_) {},
      showLanguageHeader: true,
      onLanguageTap: () {},
    )));
    expect(find.byIcon(Icons.language), findsOneWidget);

    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));
    expect(find.byIcon(Icons.language), findsNothing);
  });

  testWidgets('divider margin is 6dp by default (portrait) and 4dp when compact (landscape)', (tester) async {
    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {})));
    var divider = tester.widget<Container>(find.byKey(const ValueKey('navRailDivider')));
    expect((divider.margin as EdgeInsets).vertical, 12); // 6dp top + 6dp bottom

    await tester.pumpWidget(_wrap(NavRail(selectedRoute: BwRoutes.dashboard, onSelect: (_) {}, compact: true)));
    divider = tester.widget<Container>(find.byKey(const ValueKey('navRailDivider')));
    expect((divider.margin as EdgeInsets).vertical, 8); // 4dp top + 4dp bottom
  });

  testWidgets('tapping the language header calls onLanguageTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(NavRail(
      selectedRoute: BwRoutes.dashboard,
      onSelect: (_) {},
      showLanguageHeader: true,
      onLanguageTap: () => tapped = true,
    )));

    await tester.tap(find.byIcon(Icons.language));

    expect(tapped, isTrue);
  });
}
