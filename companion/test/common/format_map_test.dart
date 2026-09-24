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
    expect(Fmt.distance(16.09344, unit: 'mi'), '10.0 mi');
    expect(Fmt.distance(3), '3.0 km');
    expect(Fmt.bytes(512), '512 B');
    expect(Fmt.bytes(1536), '1.5 KB');
    expect(Fmt.bytes(5 * 1024 * 1024 * 1024 * 1024 * 3), '15.0 TB');
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
