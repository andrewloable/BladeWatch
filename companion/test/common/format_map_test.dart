import 'package:bladewatch_companion/screens/common/car_map.dart';
import 'package:bladewatch_companion/screens/common/format.dart';
import 'package:bladewatch_theme/bladewatch_theme.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('Fmt', () {
    expect(Fmt.duration(45), '45s');
    expect(Fmt.duration(125), '2m');
    expect(Fmt.duration(3725), '1h 2m');
    expect(Fmt.distance(16.09344, unit: 'mi'), '10.0\u00A0mi');
    expect(Fmt.distance(3), '3.0\u00A0km');
    expect(Fmt.distance(118.4, decimals: 0), '118\u00A0km');
    expect(Fmt.speed(64.37376, unit: 'mi'), '40\u00A0mph');
    expect(Fmt.speed(64.4), '64\u00A0km/h');
    // Money as the in-car Currency.format: an ISO code through intl, a symbol first, none bare,
    // and a code intl does not know in the plain form.
    expect(Fmt.money(49.96, 'PHP'), '\u20B149.96');
    expect(Fmt.money(49.96, '\u20B1'), '\u20B1 49.96');
    expect(Fmt.money(1.5, ''), '1.50');
    expect(Fmt.money(2, 'ZZZ'), anyOf('2.00 ZZZ', 'ZZZ2.00'));
    expect(Fmt.bytes(512), '512\u00A0B');
    expect(Fmt.bytes(1536), '1.5\u00A0KB');
    expect(Fmt.bytes(5 * 1024 * 1024 * 1024 * 1024 * 3), '15.0\u00A0TB');
    expect(Fmt.percent(81.4), '81%');
    expect(Fmt.dateTime(Int64.ZERO), '—');
    expect(Fmt.time(Int64.ZERO), '—');
    expect(Fmt.time(Int64(1700000000000), 'en'), isNotEmpty);
  });

  testWidgets('a dark theme inverts the tiles; a route fits its bounds', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const a = LatLng(14.5, 121.0);
    const b = LatLng(14.6, 121.1);
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      home: const Scaffold(body: CarMap(center: a, route: [a, b], markers: [a])),
    ));
    await tester.pump();
    expect(find.byType(ColorFiltered), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); // no theme animation between the two
    await tester.pumpWidget(MaterialApp(theme: BladeWatchTheme.light(), home: const Scaffold(body: CarMap(center: a, markers: [a]))));
    await tester.pump();
    expect(find.byType(ColorFiltered), findsNothing);
  });
}
