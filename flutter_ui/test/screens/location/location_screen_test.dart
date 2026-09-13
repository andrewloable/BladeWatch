import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/location_channel.dart';
import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/screens/location/location_controller.dart';
import 'package:bladewatch_ui/screens/location/location_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late LocationController controller;

  void stubOnline() => channel.stub('network', 'current', {'type': 'wifi', 'ssid': 'car'});
  void stubOffline() => channel.stub('network', 'current', {'type': 'offline', 'ssid': null});

  void stubBaseline() {
    channel.stub('location', 'stopUpdates', null);
    channel.stub('prefs', 'getLocationUiMode', null);
    channel.stub('prefs', 'getThemeMode', null);
    stubOnline();
  }

  void stubFreshSample({int? ageMs}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch - (ageMs ?? 0);
    channel.stub('location', 'currentSample', {
      'latitude': 37.7749,
      'longitude': -122.4194,
      'bearingDegrees': 45.0,
      'provider': 'gps',
      'timestampMs': timestamp,
    });
  }

  void stubListening() {
    channel.stub('location', 'hasPermission', true);
    channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
    channel.stub('location', 'startUpdates', {'ok': true});
  }

  setUp(() {
    channel = FakePlatformChannel();
    stubBaseline();
    controller = LocationController(
      channel: LocationChannel(channel),
      prefs: PrefsChannel(channel),
      networkChannel: NetworkChannel(channel),
    );
  });

  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  // _start() chains loadUiModePreference -> _refreshAppearance (itself
  // awaiting useNightTiles -> prefs.getThemeMode) -> start() -> poll(), each
  // a separate awaited hop through FakePlatformChannel. A single pump() only
  // flushes one microtask hop, and pumpAndSettle() never returns once the
  // periodic poll Timer is running -- so bounded pump()s, same as
  // performance_screen_test.dart's pattern for its own timer-owning screen.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
  }

  /// Fires the next scheduled poll tick (the screen's 1s `Timer.periodic`)
  /// and flushes the async chain it kicks off. Plain `pump()` never advances
  /// fake time, so anything that only becomes visible on a *later* poll
  /// (not the one `_start()` already awaited) needs this instead.
  Future<void> tick(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
  }

  testWidgets('shows the loading banner on the very first frame', (tester) async {
    channel.stub('location', 'hasPermission', true);
    channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
    channel.stub('location', 'startUpdates', {'ok': true});
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));

    expect(find.text('Loading map'), findsOneWidget);
  });

  testWidgets('permission missing shows the Grant banner, no map; granting-then-denied shows Retry', (tester) async {
    channel.stub('location', 'hasPermission', false);
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.text('Location permission required'), findsOneWidget);
    expect(find.text('Grant'), findsOneWidget);
    expect(find.byKey(const ValueKey('location.map')), findsNothing);

    channel.stub('location', 'requestPermission', false);
    await tester.tap(find.byKey(const ValueKey('location.bannerAction')));
    await settle(tester);

    expect(channel.calls.any((c) => c.method == 'requestPermission'), isTrue);
    expect(find.text('Permission denied'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('no provider enabled shows GPS disabled, Retry restarts via stop()+start()', (tester) async {
    channel.stub('location', 'hasPermission', true);
    channel.stub('location', 'providerEnabled', {'gps': false, 'network': false});
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.text('GPS disabled'), findsOneWidget);

    channel.calls.clear();
    channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
    channel.stub('location', 'startUpdates', {'ok': true});
    stubFreshSample();
    await tester.tap(find.byKey(const ValueKey('location.bannerAction')));
    await settle(tester);

    expect(channel.calls.any((c) => c.method == 'stopUpdates'), isTrue);
    expect(find.text('Waiting for GPS fix'), findsOneWidget, reason: 'retry only restarts listening, the next fix arrives on the following poll tick');

    stubFreshSample();
    await tick(tester);
    expect(find.text('Car location'), findsOneWidget);
  });

  testWidgets('listening with no fix yet shows Waiting for GPS fix, no map', (tester) async {
    stubListening();
    channel.stub('location', 'currentSample', null);
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.text('Waiting for GPS fix'), findsOneWidget);
    expect(find.byKey(const ValueKey('location.map')), findsNothing);
  });

  testWidgets('a fresh fix shows the map, coordinates banner, and mode selector', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.text('Car location'), findsOneWidget);
    expect(find.text('37.77490, -122.41940'), findsOneWidget);
    expect(find.byKey(const ValueKey('location.map')), findsOneWidget);
    expect(find.byKey(const ValueKey('location.modeSelector')), findsOneWidget);
  });

  testWidgets('a stale fix shows the stale banner but keeps the map', (tester) async {
    stubListening();
    stubFreshSample(ageMs: 40000); // older than the 30s threshold
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.text('Location stale'), findsOneWidget);
    expect(find.byKey(const ValueKey('location.map')), findsOneWidget);
  });

  testWidgets('going offline with a fresh fix downgrades to the tile-failure banner, map stays up', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);
    expect(find.text('Car location'), findsOneWidget);

    stubOffline();
    await tick(tester);

    expect(find.text('Map unavailable'), findsOneWidget);
    expect(find.text('Network unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('location.map')), findsOneWidget);
  });

  testWidgets('a startUpdates failure shows the raw reason and a Retry action', (tester) async {
    channel.stub('location', 'hasPermission', true);
    channel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
    channel.stub('location', 'startUpdates', {'ok': false, 'reason': 'permission revoked mid-flight'});
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.text('Location error'), findsOneWidget);
    expect(find.text('permission revoked mid-flight'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping a mode selector segment persists the preference', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    channel.stub('prefs', 'setLocationUiMode', null);
    await tester.tap(find.text('Dark'));
    await settle(tester);

    final call = channel.calls.firstWhere((c) => c.method == 'setLocationUiMode');
    expect((call.args as Map)['value'], 'dark');
    expect(controller.uiModePreference.name, 'dark');
  });

  testWidgets('dragging the map counts as a user pan and shows the recenter button', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);
    expect(controller.viewportState.followCar, isTrue);

    await tester.drag(find.byKey(const ValueKey('location.map')), const Offset(-80, -80));
    await settle(tester);

    expect(controller.viewportState.followCar, isFalse);
    expect(find.byKey(const ValueKey('location.recenter')), findsOneWidget);
  });

  testWidgets('recenter button appears once the car is panned away, and taps re-follow', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);
    expect(find.byKey(const ValueKey('location.recenter')), findsNothing);

    controller.onUserPan();
    await settle(tester);
    expect(find.byKey(const ValueKey('location.recenter')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('location.recenter')));
    await settle(tester);
    expect(controller.viewportState.followCar, isTrue);
    expect(find.byKey(const ValueKey('location.recenter')), findsNothing);
  });

  testWidgets('renders in dark theme without crashing', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller), theme: BladeWatchTheme.dark()));
    await settle(tester);

    expect(find.text('Car location'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an explicit dark app-wide theme preference inverts the tile colors', (tester) async {
    channel.stub('prefs', 'getThemeMode', 'dark');
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.byType(ColorFiltered), findsOneWidget);
  });

  testWidgets('no color inversion for the default (light) appearance', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('disposing the screen stops listening', (tester) async {
    stubListening();
    stubFreshSample();
    await tester.pumpWidget(wrap(LocationScreen(controller: controller)));
    await settle(tester);

    channel.calls.clear();
    await tester.pumpWidget(const SizedBox());
    await settle(tester);

    expect(channel.calls.any((c) => c.method == 'stopUpdates'), isTrue);
  });
}
