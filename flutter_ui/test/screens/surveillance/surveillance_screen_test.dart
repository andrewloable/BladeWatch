import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/safe_locations_service_client.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_ui/screens/surveillance/surveillance_controller.dart';
import 'package:bladewatch_ui/screens/surveillance/surveillance_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:bladewatch_ui/screens/surveillance/roi_editor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;

  setUp(() {
    rpc = FakeRpcClient();
  });

  SurveillanceSettingsController buildController() {
    final surveillanceService = SurveillanceServiceClient(rpc);
    return SurveillanceSettingsController(
      surveillanceService: surveillanceService,
      longSurveillanceService: surveillanceService,
      safeLocationsService: SafeLocationsServiceClient(rpc),
      storageService: StorageServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
    );
  }

  void stubHappyPath({bool sdCardAvailable = true, List<Map<String, Object?>> zones = const [], double lat = 1.5, double lng = 2.5}) {
    rpc.stubJson('SurveillanceService', 'GetConfig', {
      'success': true,
      'config': {
        'enabled': true,
        'distancePreset': 'OUTDOOR',
        'sensitivity': 3,
        'detectPerson': true,
        'detectCar': true,
        'detectBike': false,
        'preRecordSeconds': 5,
        'postRecordSeconds': 10,
        'nightMode': false,
        'aiEnabled': true,
        'aiConfidence': 0.4,
        'cameraFront': true,
        'cameraRight': true,
        'cameraRear': true,
        'cameraLeft': true,
        'deterrentAction': 'silent',
        'deterrentCooldownSeconds': 60,
      },
    });
    rpc.stubJson('SurveillanceService', 'GetStatus', {'pipelineRunning': true, 'surveillanceActive': false});
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {'surveillanceCount': 5},
    });
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'surveillanceStorageType': 'INTERNAL',
      'surveillanceLimitMb': 800,
      'surveillanceSize': 100 * 1024 * 1024,
      'surveillanceCount': 9,
      'sdCardAvailable': sdCardAvailable,
      'surveillancePath': '/storage/emulated/0/BladeWatch/surveillance',
      'minLimitMb': 100,
      'maxLimitMb': 50000,
      'maxLimitMbSdCard': 80000,
      'internalTotalSpace': 20000 * 1024 * 1024,
      'sdCardTotalSpace': 32000 * 1024 * 1024,
    });
    rpc.stubJson('SafeLocationsService', 'ListZones', {'zones': zones, 'featureEnabled': true, 'hasGps': true, 'lat': lat, 'lng': lng});
  }

  Future<void> pump(WidgetTester tester, SurveillanceSettingsController controller, {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SurveillanceSettingsScreen(controller: controller)),
    ));
  }

  testWidgets('shows a loading indicator before data arrives', (tester) async {
    final controller = buildController();
    await pump(tester, controller);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('General tab', () {
    testWidgets('shows running status and events today', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows idle status when not running', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'GetStatus', {'pipelineRunning': false, 'surveillanceActive': false});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Idle'), findsOneWidget);
    });

    testWidgets('toggling Enable Surveillance calls Enable/Disable then reloads', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'Disable', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('surveillance.enable')));
      await tester.pumpAndSettle();

      expect(rpc.calls.any((c) => c.service == 'SurveillanceService' && c.method == 'Disable'), isTrue);
    });
  });

  group('Detection tab', () {
    Future<void> openDetection(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('surveillance.tab.detection')));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the safe-locations empty state and add-current button when no zones exist', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openDetection(tester);

      expect(find.byKey(const ValueKey('surveillance.safeLocations.map')), findsOneWidget);
      expect(find.text('No safe locations added yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('surveillance.safeLocations.addCurrent')), findsOneWidget);
    });

    testWidgets('shows "GPS location not available" and hides add-current without a GPS fix or zones', (tester) async {
      stubHappyPath(lat: 0, lng: 0);
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openDetection(tester);

      expect(find.byKey(const ValueKey('surveillance.safeLocations.map')), findsNothing);
      expect(find.text('GPS location not available'), findsOneWidget);
      expect(find.byKey(const ValueKey('surveillance.safeLocations.addCurrent')), findsNothing);
    });

    testWidgets('lists zones and deleting one calls DeleteZone', (tester) async {
      stubHappyPath(zones: [
        {'id': 'z1', 'name': 'Home', 'lat': 1.1, 'lng': 2.2, 'radiusM': 100},
      ]);
      rpc.stubJson('SafeLocationsService', 'DeleteZone', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openDetection(tester);

      expect(find.textContaining('Home'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('surveillance.safeLocations.zone.delete.z1')));
      await tester.pumpAndSettle();

      expect(rpc.calls.any((c) => c.service == 'SafeLocationsService' && c.method == 'DeleteZone'), isTrue);
    });

    testWidgets('adding a safe zone at the current location calls AddZone', (tester) async {
      stubHappyPath();
      rpc.stubJson('SafeLocationsService', 'AddZone', {
        'success': true,
        'zone': {'id': 'z9', 'name': 'Safe Zone', 'lat': 1.5, 'lng': 2.5, 'radiusM': 150},
      });
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openDetection(tester);

      await tester.tap(find.byKey(const ValueKey('surveillance.safeLocations.addCurrent')));
      await tester.pumpAndSettle();

      final call = rpc.calls.firstWhere((c) => c.method == 'AddZone');
      expect((call.request as dynamic).name, 'Safe Zone');
      expect((call.request as dynamic).radiusM, 150);
    });

    testWidgets('toggling the safe-locations switch calls Toggle', (tester) async {
      stubHappyPath();
      rpc.stubJson('SafeLocationsService', 'Toggle', {'success': true, 'enabled': false});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openDetection(tester);

      await tester.tap(find.byKey(const ValueKey('surveillance.safeLocations.enable')));
      await tester.pumpAndSettle();

      expect(rpc.calls.any((c) => c.service == 'SafeLocationsService' && c.method == 'Toggle'), isTrue);
    });

    testWidgets('selecting a preset, sensitivity, and detect toggles then applying calls SetConfig', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openDetection(tester);

      await tester.tap(find.byKey(const ValueKey('surveillance.preset.GARAGE')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.sensitivity.5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.detect.bike')));
      await tester.pumpAndSettle();
      // The ROI editor (BladeWatch-9b0f) sits between the detect toggles and
      // Apply, so the button is off-screen at test size until we scroll.
      await tester.scrollUntilVisible(find.byKey(const ValueKey('surveillance.apply.detection')), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.apply.detection')));
      await tester.pumpAndSettle();

      final call = rpc.calls.firstWhere((c) => c.method == 'SetConfig');
      final cfg = (call.request as dynamic).config;
      expect(cfg.distancePreset, 'GARAGE');
      expect(cfg.sensitivity, 5);
      expect(cfg.detectBike, isTrue);
    });

    testWidgets('a failed Apply shows a snackbar with the server error', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': false, 'error': 'rejected'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openDetection(tester);

      // The ROI editor (BladeWatch-9b0f) sits between the detect toggles and
      // Apply, so the button is off-screen at test size until we scroll.
      await tester.scrollUntilVisible(find.byKey(const ValueKey('surveillance.apply.detection')), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.apply.detection')));
      await tester.pumpAndSettle();

      expect(find.text('rejected'), findsOneWidget);
    });
  });

  group('Recording tab', () {
    testWidgets('selecting pre/post-record options then applying calls SetConfig', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.tab.recording')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('surveillance.preRecord.15')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.postRecord.30')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.apply.recording')));
      await tester.pumpAndSettle();

      final call = rpc.calls.firstWhere((c) => c.method == 'SetConfig');
      final cfg = (call.request as dynamic).config;
      expect(cfg.preRecordSeconds, 15);
      expect(cfg.postRecordSeconds, 30);
    });
  });

  // BladeWatch-9b0f: the motion-zone editor lives at the bottom of Detection.
  group('ROI editor', () {
    Future<void> openDetection(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('surveillance.tab.detection')));
      await tester.pumpAndSettle();
    }

    /// The section sits below the fold, and revealing one part of it can push
    /// another off-screen — including upwards — so each interaction brings its
    /// own target into view. ensureVisible scrolls whichever way is needed;
    /// scrollUntilVisible only goes one way.
    Future<void> reveal(WidgetTester tester, String key, {double delta = 150}) async {
      final finder = find.byKey(ValueKey(key));
      // ListView(children:) still builds lazily, so a widget far below the fold
      // does not exist yet and ensureVisible alone would find nothing. Scroll
      // down to build it first, then ensureVisible, which unlike
      // scrollUntilVisible will also scroll back UP when the target is above.
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(finder, delta);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    testWidgets("switching quadrant shows that quadrant's own zone", (tester) async {
      stubHappyPath();
      final controller = buildController();
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await openDetection(tester);

      controller.setRoiPolygon('Q0', const [Offset(0, 0), Offset(1, 0), Offset(1, 1)]);
      await tester.pumpAndSettle();
      await reveal(tester, 'surveillance.roi.count');
      expect(find.text('3 / $kRoiMaxPoints'), findsOneWidget);

      // The quadrant chips sit ABOVE the canvas, so revealing the count can
      // scroll them out of the lazily-built range — go back up for them.
      await reveal(tester, 'surveillance.roi.quadrant.Q1', delta: -150);
      await tester.tap(find.byKey(const ValueKey('surveillance.roi.quadrant.Q1')));
      await tester.pumpAndSettle();

      // Q1 has no zone, so the count must follow the selection rather than
      // lingering on Q0's.
      await reveal(tester, 'surveillance.roi.count');
      expect(find.text('0 / $kRoiMaxPoints'), findsOneWidget);
    });

    testWidgets('tapping the canvas records a vertex on the selected quadrant', (tester) async {
      stubHappyPath();
      final controller = buildController();
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await openDetection(tester);
      await reveal(tester, 'roi.canvas');

      await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('roi.canvas'))));
      await tester.pumpAndSettle();

      expect(controller.roiPolygonFor('Q0').length, 1);
      expect(controller.roiPolygonFor('Q1'), isEmpty, reason: 'only the selected quadrant is drawn on');
    });

    testWidgets('the enable switch drives that quadrant only', (tester) async {
      stubHappyPath();
      final controller = buildController();
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await openDetection(tester);
      await reveal(tester, 'surveillance.roi.enable');

      await tester.tap(find.byKey(const ValueKey('surveillance.roi.enable')));
      await tester.pumpAndSettle();

      expect(controller.roiEnabledFor('Q0'), isTrue);
      expect(controller.roiEnabledFor('Q1'), isFalse);
    });

    testWidgets('Undo and Clear are disabled until there is something to remove', (tester) async {
      stubHappyPath();
      final controller = buildController();
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await openDetection(tester);
      await reveal(tester, 'surveillance.roi.undo');

      expect(tester.widget<TextButton>(find.byKey(const ValueKey('surveillance.roi.undo'))).onPressed, isNull);
      expect(tester.widget<TextButton>(find.byKey(const ValueKey('surveillance.roi.clear'))).onPressed, isNull);

      controller.setRoiPolygon('Q0', const [Offset(0, 0), Offset(1, 0), Offset(1, 1)]);
      await tester.pumpAndSettle();
      await reveal(tester, 'surveillance.roi.undo');

      await tester.tap(find.byKey(const ValueKey('surveillance.roi.undo')));
      await tester.pumpAndSettle();
      expect(controller.roiPolygonFor('Q0').length, 2);

      await reveal(tester, 'surveillance.roi.clear');
      await tester.tap(find.byKey(const ValueKey('surveillance.roi.clear')));
      await tester.pumpAndSettle();
      expect(controller.roiPolygonFor('Q0'), isEmpty);
    });
  });

  group('Storage tab', () {
    Future<void> openStorage(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('surveillance.tab.storage')));
      await tester.pumpAndSettle();
    }

    // BladeWatch-3118: same labelling as the Recording tab's storage rows.
    testWidgets('the storage rows name what they are showing', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      for (final label in ['Storage Usage', 'Files']) {
        final row = tester.widget<ListTile>(
          find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
        );
        expect(row.trailing, isNotNull, reason: '$label must be a label + right-aligned value');
      }
    });

    // Path is the same row the Recording tab had on a second line; native
    // right-aligns it in both screens.
    testWidgets('the storage path is right-aligned, not a subtitle', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      final row = tester.widget<ListTile>(
        find.ancestor(of: find.text('Path'), matching: find.byType(ListTile)),
      );
      expect(row.trailing, isNotNull);
      expect(row.subtitle, isNull);
    });

    // BladeWatch-htel: the same two Storage-tab differences the Recording tab
    // had — this tab is meant to behave identically to it.
    testWidgets('the storage limit is shown in GB above 1024 MB, as native formats it', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'GetStorageSettings', {
        'surveillanceStorageType': 'INTERNAL',
        'surveillanceLimitMb': 16384,
        'surveillanceSize': 0,
        'surveillanceCount': 0,
        'sdCardAvailable': false,
        'surveillancePath': '',
        'minLimitMb': 100,
        'maxLimitMb': 100000,
        'maxLimitMbSdCard': 100000,
      });
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      expect(find.text('16.0 GB'), findsOneWidget);
      expect(find.text('16384 MB'), findsNothing);
    });

    testWidgets('the storage slider is stepped, not continuous', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      final slider = tester.widget<Slider>(find.byKey(const ValueKey('surveillance.storage.limitSlider')));
      expect(slider.divisions, isNotNull);
      expect(slider.divisions, greaterThan(0));
    });

    testWidgets('shows usage info and the format card when SD is available', (tester) async {
      stubHappyPath(sdCardAvailable: true);
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      expect(find.byKey(const ValueKey('surveillance.format.start')), findsOneWidget);
      expect(find.textContaining('events'), findsOneWidget);
    });

    testWidgets('hides the format card when SD is unavailable', (tester) async {
      stubHappyPath(sdCardAvailable: false);
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      expect(find.byKey(const ValueKey('surveillance.format.start')), findsNothing);
      expect(find.byKey(const ValueKey('surveillance.storage.sdCard')), findsOneWidget);
    });

    testWidgets('selecting storage type and moving the slider then applying calls SetStorageSettings', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      await tester.tap(find.byKey(const ValueKey('surveillance.storage.sdCard')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.storage.internal')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.storage.sdCard')));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const ValueKey('surveillance.storage.limitSlider')), const Offset(50, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.apply.storage')));
      await tester.pumpAndSettle();

      final call = rpc.calls.firstWhere((c) => c.method == 'SetStorageSettings');
      expect((call.request as dynamic).surveillanceStorageType, 'SD_CARD');
    });

    testWidgets('format flow: start, confirm, success, dismiss', (tester) async {
      stubHappyPath(sdCardAvailable: true);
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': true},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': true, 'mountPath': '/mnt/sdcard'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      await tester.tap(find.byKey(const ValueKey('surveillance.format.start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('surveillance.format.confirm')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('surveillance.format.confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('surveillance.format.result')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('surveillance.format.dismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('surveillance.format.start')), findsOneWidget);
    });

    testWidgets('format flow: cancel returns to idle', (tester) async {
      stubHappyPath(sdCardAvailable: true);
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      await tester.tap(find.byKey(const ValueKey('surveillance.format.start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.format.cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('surveillance.format.start')), findsOneWidget);
    });

    testWidgets('sync flow: start, success, dismiss', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SyncCatalog', {'success': true, 'added': 2, 'removed': 1});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openStorage(tester);

      await tester.tap(find.byKey(const ValueKey('surveillance.sync.start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('surveillance.sync.result')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('surveillance.sync.dismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('surveillance.sync.start')), findsOneWidget);
    });
  });

  group('Advanced tab', () {
    testWidgets('toggling cameras/AI/night and selecting a deterrent then applying calls SetConfig', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.tab.advanced')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('surveillance.camera.rear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.ai.enabled')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.night.enabled')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.deterrent.horn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.apply.advanced')));
      await tester.pumpAndSettle();

      final call = rpc.calls.firstWhere((c) => c.method == 'SetConfig');
      final cfg = (call.request as dynamic).config;
      expect(cfg.cameraRear, isFalse);
      expect(cfg.aiEnabled, isFalse);
      expect(cfg.nightMode, isTrue);
      expect(cfg.deterrentAction, 'horn');
    });
  });

  testWidgets('every RPC failing (daemon not running) still renders sensible defaults, no crash', (tester) async {
    // No stubs registered at all -- FakeRpcClient throws StateError for
    // every call, exercising every try/catch fallback in load() at once.
    await pump(tester, buildController());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    stubHappyPath();
    await pump(tester, buildController(), theme: BladeWatchTheme.dark());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
  testWidgets('the tab bar sits BELOW the content, as native places it', (tester) async {
    // BladeWatch-htel: native adds its tab bar last (at the bottom of the
    // pane) and this app's own Trips screen already did the same; these two
    // screens were the only ones putting it on top.
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();

    final tabBarY = tester.getCenter(find.byKey(const ValueKey('surveillance.tab.general'))).dy;
    final contentY = tester.getCenter(find.byType(ListView).first).dy;
    expect(tabBarY, greaterThan(contentY));
  });

}
