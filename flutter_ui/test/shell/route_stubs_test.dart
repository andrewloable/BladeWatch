import 'package:bladewatch_ui/shell/route_stubs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all lists exactly the 11 screen groups Epic 2 (yz1e) ports', () {
    expect(BwRoutes.all, hasLength(11));
    expect(BwRoutes.all.toSet().length, 11, reason: 'route names must be unique');
  });

  testWidgets('StubScreen renders for every one of the 11 routes', (tester) async {
    for (final route in BwRoutes.all) {
      await tester.pumpWidget(MaterialApp(home: StubScreen(routeName: route)));
      expect(find.textContaining(route), findsOneWidget);
    }
  });

  testWidgets('StubScreen renders for the extra settingsAbout route', (tester) async {
    await tester.pumpWidget(MaterialApp(home: StubScreen(routeName: BwRoutes.settingsAbout)));
    expect(find.textContaining(BwRoutes.settingsAbout), findsOneWidget);
  });
}
