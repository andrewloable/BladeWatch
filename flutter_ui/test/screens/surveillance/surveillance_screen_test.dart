import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/safe_locations_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_ui/screens/surveillance/surveillance_controller.dart';
import 'package:bladewatch_ui/screens/surveillance/surveillance_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

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

    // BladeWatch-gyg1.2: honest-warning tests. stubHappyPath()'s GetConfig has
    // enabled: true, so armed is the default fixture; the disarmed test overrides it.
    testWidgets('battery cost note is shown next to the arming control when armed', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // Asserts on the resolved l10n VALUE, not an English literal written in this
      // test -- if the widget hardcoded different text, or the key were renamed,
      // this and the widget's own lookup would diverge and the test would fail.
      expect(find.text(l10n.surveillance_general_battery_warning), findsOneWidget);
    });

    testWidgets('battery cost note is absent when disarmed', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'GetConfig', {
        'success': true,
        'config': {
          'enabled': false,
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
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.surveillance_general_battery_warning), findsNothing);
    });

    testWidgets('camera contention note is shown only while another app holds the camera', (tester) async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'GetStatus',
          {'pipelineRunning': true, 'surveillanceActive': false, 'cameraYielded': true, 'nativeAppActive': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      expect(find.text(l10n.surveillance_general_camera_contention_warning), findsOneWidget);
    });

    testWidgets('camera contention note is absent when nothing is contending', (tester) async {
      stubHappyPath(); // GetStatus defaults cameraYielded to false (unset in the fixture)
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // This is the assertion that matters most: a permanent caption here is exactly
      // the failure mode step 2 of the issue exists to prevent.
      expect(find.text(l10n.surveillance_general_camera_contention_warning), findsNothing);
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
      // Apply can sit below the fold at test size, so scroll it into view.
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

      // Apply can sit below the fold at test size, so scroll it into view.
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

  group('storage limit confirmation (BladeWatch-gyg1.6)', () {
    Future<SurveillanceSettingsController> openStorageTabAt(WidgetTester tester, int limitMb) async {
      final controller = buildController();
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('surveillance.tab.storage')));
      await tester.pumpAndSettle();
      controller.setStorageLimitMb(limitMb);
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('lowering to a value the preview says deletes files shows a confirmation with the count and size',
        (tester) async {
      stubHappyPath(); // loaded limitMb is 800
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'surveillanceImpact': {'fileCount': 6, 'totalBytes': 12884901888},
      });
      await openStorageTabAt(tester, 100);

      await tester.tap(find.byKey(const ValueKey('surveillance.apply.storage')));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byKey(const ValueKey('surveillance.storageConfirm.dialog')), findsOneWidget);
      expect(find.text(l10n.settings_recording_storage_confirm_message(6, '12.0 GB')), findsOneWidget);
    });

    testWidgets('cancelling leaves SetStorageSettings uncalled', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'surveillanceImpact': {'fileCount': 6, 'totalBytes': 12884901888},
      });
      await openStorageTabAt(tester, 100);
      await tester.tap(find.byKey(const ValueKey('surveillance.apply.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('surveillance.storageConfirm.cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('surveillance.storageConfirm.dialog')), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), isEmpty);
    });

    testWidgets('confirming calls SetStorageSettings exactly once with the new value', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'surveillanceImpact': {'fileCount': 6, 'totalBytes': 12884901888},
      });
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await openStorageTabAt(tester, 100);
      await tester.tap(find.byKey(const ValueKey('surveillance.apply.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('surveillance.storageConfirm.confirm')));
      await tester.pumpAndSettle();

      final calls = rpc.calls.where((c) => c.method == 'SetStorageSettings').toList();
      expect(calls, hasLength(1));
      expect((calls.single.request as dynamic).surveillanceLimitMb.toInt(), 100);
    });

    testWidgets('raising the limit applies directly with no dialog and no preview call', (tester) async {
      stubHappyPath(); // loaded limitMb is 800
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await openStorageTabAt(tester, 900);

      await tester.tap(find.byKey(const ValueKey('surveillance.apply.storage')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('surveillance.storageConfirm.dialog')), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), hasLength(1));
      expect(rpc.calls.where((c) => c.method == 'PreviewStorageLimitChange'), isEmpty);
    });

    testWidgets('lowering to a value that deletes nothing applies directly with no dialog', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'surveillanceImpact': {'fileCount': 0, 'totalBytes': 0},
      });
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await openStorageTabAt(tester, 100);

      await tester.tap(find.byKey(const ValueKey('surveillance.apply.storage')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('surveillance.storageConfirm.dialog')), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), hasLength(1));
    });

    testWidgets('the preview RPC failing shows a distinct impact-unknown confirmation, and cancelling it '
        'also leaves SetStorageSettings uncalled', (tester) async {
      stubHappyPath();
      rpc.stubError('StorageService', 'PreviewStorageLimitChange', const ConnectError('unavailable', 'down'));
      await openStorageTabAt(tester, 100);

      await tester.tap(find.byKey(const ValueKey('surveillance.apply.storage')));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byKey(const ValueKey('surveillance.storageConfirm.dialog')), findsOneWidget);
      expect(find.text(l10n.settings_recording_storage_confirm_unknown_title), findsOneWidget);
      expect(find.text(l10n.settings_recording_storage_confirm_unknown_message), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('surveillance.storageConfirm.cancel')));
      await tester.pumpAndSettle();

      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), isEmpty);
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
