import 'dart:async';

import 'package:bladewatch_companion/car/speed_test.dart';
import 'package:bladewatch_companion/screens/about/about_screen.dart';
import 'package:bladewatch_companion/screens/diagnostics/diagnostics_screen.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_companion/screens/performance/performance_screen.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/settings/settings_screen.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void stubStatus(TestSession s) => s.rpc.stubJson('SystemService', 'GetStatus', {
      'deviceId': 'dev-1',
      'appVersion': '1.4.0.0',
      'available': [0, 1, 2, 3],
      'recordingStatus': {'configuredMode': 'CONTINUOUS', 'pipelineRunning': true},
      'network': {'type': 'WIFI', 'ssid': 'net', 'ip': '10.0.0.2', 'lanHttpEnabled': true},
    });

void stubStorage(TestSession s, {bool sd = true}) => s.rpc.stubJson('StorageService', 'GetStorageSettings', {
      'recordingsLimitMb': '1000',
      'surveillanceLimitMb': '500',
      'recordingsCount': 3,
      'recordingsSize': '1048576',
      'surveillanceCount': 1,
      'surveillanceSize': '2048',
      'internalFreeFormatted': '10 GB',
      'internalTotalFormatted': '32 GB',
      'sdCardAvailable': sd,
      'sdCardFreeFormatted': '50 GB',
      'sdCardTotalFormatted': '64 GB',
      'sdCardMountFailed': !sd,
      'sdCardMountError': sd ? '' : 'unformatted',
      'recordingsStorageType': 'INTERNAL',
      'surveillanceStorageType': 'INTERNAL',
    });

void main() {
  hudTestEnvironment();

  group('SettingsScreen', () {
    late List<String?> languages;
    late int unpaired;

    Future<TestSession> pump(WidgetTester tester, {bool sd = true, void Function(TestSession s)? more}) async {
      final s = TestSession();
      more?.call(s);
      stubStatus(s);
      stubStorage(s, sd: sd);
      s.rpc.stubJson('SettingsService', 'GetQuality', {
        'recordingQuality': 'HIGH',
        'recordingCodec': 'H264',
        'recordingQualityOptions': {'STANDARD': {}, 'HIGH': {}},
        'codecOptions': {'H264': 'H.264', 'H265': 'H.265'},
      });
      s.rpc.stubJson('SettingsService', 'GetLocale', {'lang': 'en', 'supported': {'en': true, 'de': true}});
      s.rpc.stubJson('SettingsService', 'GetStatusOverlay', {'cameraVisible': true});
      for (final m in ['SetRecordingMode', 'SetQuality', 'SetLocale', 'SetStatusOverlay']) {
        s.rpc.stubJson('SettingsService', m, {'success': true});
      }
      s.rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      s.rpc.stubJson('RecordingsService', 'SyncCatalog', {'success': true});
      languages = [];
      unpaired = 0;
      await pumpScreen(
        tester,
        s,
        SettingsScreen(
          store: testStore(car: testCar()),
          onLanguage: (l) async => languages.add(l),
          onUnpair: () async => unpaired++,
        ),
        size: const Size(1200, 4000),
      );
      return s;
    }

    // BladeWatch-rdtj.67: what the in-car Settings has, here too.
    testWidgets('trips and costs from Settings; overlay fields; library sync', (tester) async {
      final s = await pump(tester, more: (s) {
        s.rpc.stubJson('SettingsService', 'GetTelemetryOverlayFields', {
          'success': true,
          'availableFields': ['SPEED', 'GEAR', 'NEW_THING'],
          'selections': {
            'continuous': {'fields': ['SPEED']},
          },
        });
        s.rpc.stubJson('SettingsService', 'SetTelemetryOverlayFields', {'success': true});
        s.rpc.stubJson('TripsService', 'GetConfig', {'config': {'enabled': true, 'electricityRate': 11.5, 'currency': 'PHP', 'distanceUnit': 'km'}});
        s.rpc.stubJson('TripsService', 'GetStorage', {'storage': {'storageType': 'INTERNAL', 'limitMb': '500'}});
        s.rpc.stubJson('TripsService', 'SetConfig', {'success': true});
        s.rpc.stubJson('TripsService', 'SetStorage', {'success': true});
      });
      bool on(String f) => tester.widget<FilterChip>(find.byKey(ValueKey('settings.overlayField.$f'))).selected;
      expect((on('SPEED'), on('GEAR')), (true, false));
      expect(find.text(t('companion.overlay_field_SPEED')), findsOneWidget);
      expect(find.text('NEW_THING'), findsOneWidget, reason: 'a field this app does not know: its name');
      await tester.tap(find.byKey(const ValueKey('settings.overlayField.GEAR')));
      await tester.pumpAndSettle();
      final set = s.rpc.calls.lastWhere((c) => c.method == 'SetTelemetryOverlayFields').request as SetTelemetryOverlayFieldsRequest;
      expect(set.type, 'continuous');
      expect(set.fields.toSet(), {'SPEED', 'GEAR'});

      s.rpc.stubJson('RecordingsService', 'SyncCatalog', {'success': true, 'added': 2, 'removed': 1});
      await tester.tap(find.byKey(const ValueKey('settings.syncLibrary')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.sync_result', {'added': 2, 'removed': 1})), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings.trips')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(HudTitleBar), matching: find.text(t('companion.trips_costs').toUpperCase())), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('trips.unit.mi')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('trips.apply')));
      await tester.tap(find.byKey(const ValueKey('trips.apply')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetConfigRequest).distanceUnit, 'mi');

      await tester.tap(find.byKey(const ValueKey('trips.storage.SD_CARD')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.trip_storage_confirm', {'place': t('trips.sd_card')})), findsOneWidget);
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      Iterable<SetStorageRequest> moves() =>
          s.rpc.calls.where((c) => c.method == 'SetStorage').map((c) => c.request as SetStorageRequest).where((r) => r.storageType.isNotEmpty);
      expect(moves(), isEmpty, reason: 'cancel moves nothing (Apply sends only the limit)');
      await tester.tap(find.byKey(const ValueKey('trips.storage.SD_CARD')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trips.storage.confirm')));
      await tester.pumpAndSettle();
      expect(moves().single.storageType, 'SD_CARD');
      await unmount(tester);
    });

    testWidgets('a car that does not report overlay fields: no overlay section', (tester) async {
      await pump(tester);
      expect(find.text(t('recording.telemetry_overlay_title')), findsNothing);
      await unmount(tester);
    });

    Future<void> pick(WidgetTester tester, String key, String item) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
    }

    testWidgets('this app: language and unpairing (after confirming)', (tester) async {
      await pump(tester);
      expect(find.text('dev-1'), findsOneWidget);
      await pick(tester, 'settings.appLanguage', 'Deutsch'); // by name, not code (BladeWatch-rdtj.49)
      await pick(tester, 'settings.appLanguage', t('companion.follow_device'));
      expect(languages, ['de', null]);

      await tester.tap(find.byKey(const ValueKey('settings.unpair')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(unpaired, 0);
      await tester.tap(find.byKey(const ValueKey('settings.unpair')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      expect(unpaired, 1);
      await unmount(tester);
    });

    testWidgets('HUD: the configured mode is the accent row, unpair is a magenta confirm, single choices have no check mark', (tester) async {
      await pump(tester);
      bool chosen(String m) => tester.widget<HudListRow>(find.byKey(ValueKey('settings.mode.$m'))).selected;
      expect(chosen('CONTINUOUS'), isTrue, reason: "the car's configured mode");
      expect(chosen('NONE'), isFalse);
      expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('settings.segment.5'))).showCheckmark, isFalse);

      await tester.tap(find.byKey(const ValueKey('settings.unpair')));
      await tester.pumpAndSettle();
      final confirm = tester.widget<FilledButton>(find.byKey(const ValueKey('settings.confirm')));
      expect(confirm.style!.foregroundColor!.resolve({}), BwHud.light.magenta);
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      await unmount(tester);
    });

    // BladeWatch-rdtj.49: the web's clip length and where recordings are saved.
    testWidgets('clip length alone; saving to the SD card after asking, limits kept', (tester) async {
      final s = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('settings.segment.10')));
      await tester.pumpAndSettle();
      final q = s.rpc.calls.lastWhere((c) => c.method == 'SetQuality').request as SetQualityRequest;
      expect((q.recordingSegmentMinutes, q.recordingQuality, q.codec), (10, '', ''), reason: 'quality and codec kept by leaving them out');

      await tester.tap(find.byKey(const ValueKey('settings.saveTo.SD_CARD')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.save_to_confirm', {'place': t('companion.place_sd')})), findsOneWidget);
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'SetStorageSettings'), isEmpty);
      await tester.tap(find.byKey(const ValueKey('settings.saveTo.SD_CARD')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      final r = s.rpc.calls.lastWhere((c) => c.method == 'SetStorageSettings').request as SetStorageSettingsRequest;
      expect((r.recordingsStorageType, r.recordingsLimitMb.toInt(), r.surveillanceLimitMb.toInt(), r.surveillanceStorageType), ('SD_CARD', 1000, 500, 'INTERNAL'));
      await unmount(tester);

      await pump(tester, sd: false);
      expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('settings.saveTo.SD_CARD'))).onSelected, isNull);
      expect(find.text(t('recording.sd_card_not_detected')), findsOneWidget);
      await unmount(tester);
    });

    test('language names: each in its own language; unknown tags as they are', () {
      expect([Tr.nameOf('de'), Tr.nameOf('ja'), Tr.nameOf('zh_TW'), Tr.nameOf('xx')], ['Deutsch', '日本語', '繁體中文', 'xx']);
      expect(Tr.languages.every(Tr.names.containsKey), isTrue);
    });

    testWidgets('the car: mode, quality, codec, language, overlay, storage limits and sync', (tester) async {
      final s = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('settings.mode.CONTINUOUS')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'SetRecordingMode'), isEmpty, reason: 'already the mode');
      await tester.tap(find.byKey(const ValueKey('settings.mode.DRIVE_MODE')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetRecordingMode').request as SetRecordingModeRequest).mode, 'DRIVE_MODE');

      await pick(tester, 'settings.quality', 'STANDARD');
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetQuality').request as SetQualityRequest).recordingQuality, 'STANDARD');
      await pick(tester, 'settings.codec', 'H.265');
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetQuality').request as SetQualityRequest).codec, 'H265');
      await pick(tester, 'settings.carLanguage', 'Deutsch');
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetLocale').request as SetLocaleRequest).lang, 'de');

      await tester.tap(find.byKey(const ValueKey('settings.overlayTrip')));
      await tester.pumpAndSettle();
      final trip = s.rpc.calls.lastWhere((c) => c.method == 'SetStatusOverlay').request as SetStatusOverlayRequest;
      expect((trip.tripVisible, trip.setTripVisible, trip.setCameraVisible), (true, true, false));
      await tester.tap(find.byKey(const ValueKey('settings.overlayCamera')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('settings.recLimit')), '2000');
      await tester.tap(find.byKey(const ValueKey('settings.storageApply')));
      await tester.pumpAndSettle();
      final st = s.rpc.calls.lastWhere((c) => c.method == 'SetStorageSettings').request as SetStorageSettingsRequest;
      expect((st.recordingsLimitMb.toInt(), st.surveillanceLimitMb.toInt(), st.recordingsStorageType), (2000, 500, 'INTERNAL'));

      await tester.enterText(find.byKey(const ValueKey('settings.recLimit')), 'lots');
      await tester.tap(find.byKey(const ValueKey('settings.storageApply')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.save_failed')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('settings.sync')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'SyncCatalog'), hasLength(1));
      await unmount(tester);
    });

    testWidgets('cleanup previews first and frees only after confirming', (tester) async {
      final s = await pump(tester);
      s.rpc.stubJson('StorageService', 'PreviewCleanup', {});
      await tester.tap(find.byKey(const ValueKey('settings.cleanup')));
      await tester.pumpAndSettle();
      expect(find.text(t('recording.cdr_no_cleanup')), findsOneWidget);

      s.rpc.stubJson('StorageService', 'PreviewCleanup', {'fileCount': 4, 'totalSize': '4194304'});
      s.rpc.stubJson('StorageService', 'TriggerCleanup', {'success': true, 'bytesFreed': '4194304', 'filesDeleted': 4});
      await tester.tap(find.byKey(const ValueKey('settings.cleanup')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'TriggerCleanup'), isEmpty);

      await tester.tap(find.byKey(const ValueKey('settings.cleanup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      expect(find.text(t('recording.cdr_freed', {'size': '4.0\u00A0MB', 'files': 4})), findsOneWidget);

      s.rpc.stubJson('StorageService', 'TriggerCleanup', {'success': false});
      await tester.tap(find.byKey(const ValueKey('settings.cleanup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      expect(find.text(t('recording.cdr_cleanup_failed')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('formatting the SD card needs two confirmations; no card, no button', (tester) async {
      final s = await pump(tester);
      s.rpc.stubJson('StorageService', 'ListFormatVolumes', {'volumes': []});
      await tester.tap(find.byKey(const ValueKey('settings.format')));
      await tester.pumpAndSettle();
      expect(find.text(t('recording.sd_card_not_detected')), findsOneWidget);

      s.rpc.stubJson('StorageService', 'ListFormatVolumes', {'volumes': [{'volumeId': 'public:8,1', 'mountPath': '/mnt/sd'}]});
      s.rpc.stubJson('StorageService', 'FormatVolume', {'success': true});
      await tester.tap(find.byKey(const ValueKey('settings.format')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'FormatVolume'), isEmpty, reason: 'the second confirmation was declined');

      await tester.tap(find.byKey(const ValueKey('settings.format')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'FormatVolume').request as FormatVolumeRequest).volumeId, 'public:8,1');

      s.rpc.stubJson('StorageService', 'FormatVolume', {'success': false, 'error': 'busy'});
      await tester.tap(find.byKey(const ValueKey('settings.format')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings.confirm')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.save_failed')), findsOneWidget);
      await unmount(tester);

      await pump(tester, sd: false);
      expect(find.byKey(const ValueKey('settings.format')), findsNothing);
      await unmount(tester);
    });
  });

  group('PerformanceScreen', () {
    testWidgets('holds a session while open and shows the numbers', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('SystemService', 'PerformanceConnect', {'success': true});
      s.rpc.stubJson('SystemService', 'PerformanceHeartbeat', {'success': true});
      s.rpc.stubJson('SystemService', 'PerformanceDisconnect', {'success': true});
      s.rpc.stubJson('SystemService', 'PlayAudioTest', {'success': true});
      s.rpc.stubJson('SystemService', 'GetPerformance', {
        'performanceJson': '{"cpu":{"system":42.5,"tempC":55},"memory":{"usedMb":900,"totalMb":2000},"gpu":{"usage":10},'
            '"app":{"threads":141,"openFds":388,"gcCount":27}}',
      });
      await pumpScreen(tester, s, const PerformanceScreen(), size: const Size(420, 1400));
      expect(find.text('42.5%'), findsOneWidget);
      expect(find.text('900\n/ 2000 MB'), findsOneWidget);
      // BladeWatch-rdtj.57: the web's app-process card.
      for (final v in ['141', '388', '27']) {
        expect(find.text(v), findsOneWidget);
      }
      expect(find.text('—'), findsWidgets, reason: 'what the car did not report');

      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.byKey(const ValueKey('perf.audio')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.audio_test_sent')), findsOneWidget);

      final connect = s.rpc.calls.firstWhere((c) => c.method == 'PerformanceConnect').request as PerformanceConnectRequest;
      await unmount(tester);
      final methods = s.rpc.calls.map((c) => c.method).toList();
      expect(methods, containsAll(['PerformanceConnect', 'PerformanceHeartbeat', 'PerformanceDisconnect']));
      final bye = s.rpc.calls.lastWhere((c) => c.method == 'PerformanceDisconnect').request as PerformanceDisconnectRequest;
      expect(bye.clientId, connect.clientId);
    });

    testWidgets('a session the car refuses, and unreadable numbers, still show the page', (tester) async {
      final s = TestSession();
      for (final m in ['PerformanceConnect', 'PerformanceHeartbeat', 'PerformanceDisconnect']) {
        s.rpc.stubError('SystemService', m, const ConnectError('unavailable', 'x'));
      }
      s.rpc.stubJson('SystemService', 'GetPerformance', {'performanceJson': 'garbage'});
      await pumpScreen(tester, s, const PerformanceScreen(), size: const Size(420, 1400));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('—'), findsWidgets);
      await unmount(tester);
    });
  });

  group('DiagnosticsScreen', () {
    testWidgets('HUD: the health dots are the state itself, and the SOH reset confirm is magenta', (tester) async {
      final s = TestSession();
      stubStatus(s);
      stubStorage(s, sd: false);
      s.rpc.stubJson('SystemService', 'GetSohStatus', {'displaySoh': 97.0});
      await pumpScreen(tester, s, const DiagnosticsScreen(), size: const Size(1200, 2400));
      final dots = tester.widgetList<HudStatusDot>(find.byType(HudStatusDot)).map((d) => d.state).toList();
      // LAN access on and the pipeline running are cyan; the SD card that failed to mount is magenta.
      expect(dots, [HudDotState.ok, HudDotState.bad, HudDotState.ok]);

      await tester.ensureVisible(find.byKey(const ValueKey('diag.resetSoh')));
      await tester.tap(find.byKey(const ValueKey('diag.resetSoh')));
      await tester.pumpAndSettle();
      final confirm = tester.widget<FilledButton>(find.byKey(const ValueKey('diag.resetConfirm')));
      expect(confirm.style!.foregroundColor!.resolve({}), BwHud.light.magenta);
      await unmount(tester);
    });

    testWidgets('health, the camera probe, and a confirmed SOH reset', (tester) async {
      final s = TestSession();
      stubStatus(s);
      stubStorage(s, sd: false);
      s.rpc.stubJson('SystemService', 'GetSohStatus', {'displaySoh': 97.0, 'displaySource': 'bms', 'nominalCapacityKwh': 82.5});
      s.rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      s.rpc.stubJson('SystemService', 'ResetSoh', {'success': true});
      await pumpScreen(tester, s, const DiagnosticsScreen(), size: const Size(1200, 2400));
      expect(find.text('10.0.0.2'), findsOneWidget);
      expect(find.text('unformatted'), findsOneWidget);
      expect(find.text('0, 1, 2, 3'), findsOneWidget);
      expect(find.text('97.0%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('diag.probe.auto')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetSurveillanceConfigRequest).clearManualCameraId_3, isTrue);
      await tester.tap(find.byKey(const ValueKey('diag.probe.4')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetSurveillanceConfigRequest).manualCameraId, 4);
      expect(find.text(t('companion.probe_saved')), findsOneWidget);

      s.rpc.stubJson('SurveillanceService', 'SetConfig', {'success': false, 'error': 'no'});
      await tester.tap(find.byKey(const ValueKey('diag.probe.1')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.save_failed')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('diag.resetSoh')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'ResetSoh'), isEmpty);
      await tester.tap(find.byKey(const ValueKey('diag.resetSoh')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('diag.resetConfirm')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'ResetSoh'), hasLength(1));

      s.rpc.stubJson('SystemService', 'ResetSoh', {'success': false});
      await tester.tap(find.byKey(const ValueKey('diag.resetSoh')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('diag.resetConfirm')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.generic')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('an empty status shows dashes, not blanks', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('SystemService', 'GetStatus', {});
      stubStorage(s);
      s.rpc.stubJson('SystemService', 'GetSohStatus', {});
      await pumpScreen(tester, s, const DiagnosticsScreen(), size: const Size(1200, 2400));
      expect(find.text('—'), findsWidgets);
      await unmount(tester);
    });

    // BladeWatch-j6ra.2: the speed test. The runner is injected: its own tests (test/car) own the
    // sockets, so nothing here opens one.
    group('speed test', () {
      TestSession diagSession({TransportPhase phase = TransportPhase.lan}) {
        final s = TestSession(phase: phase);
        stubStatus(s);
        stubStorage(s, sd: false);
        s.rpc.stubJson('SystemService', 'GetSohStatus', {});
        return s;
      }

      const lan = SpeedTestResult(pingMs: 42.4, bytes: 5000000, elapsed: Duration(seconds: 8), phase: TransportPhase.lan);
      final run = find.byKey(const ValueKey('diag.speedtest.run'));

      testWidgets('is idle until asked: a hint and a button, no numbers and no test started', (tester) async {
        var started = 0;
        final s = diagSession();
        await pumpScreen(tester, s, DiagnosticsScreen(speedTest: (_) async {
          started++;
          return lan;
        }), size: const Size(1200, 2400));

        expect(find.text(t('companion.speedtest').toUpperCase()), findsOneWidget, reason: 'a Section upper-cases its title');
        expect(find.text(t('companion.speedtest_hint')), findsOneWidget);
        expect(find.descendant(of: run, matching: find.text(t('companion.speedtest_run'))), findsOneWidget);
        expect(find.text(t('companion.speedtest_download')), findsNothing);
        expect(started, 0, reason: 'a speed test moves tens of MB, possibly on mobile data: never automatic');
        await unmount(tester);
      });

      testWidgets('runs on tap: busy and unrepeatable meanwhile, then latency, speed and the path', (tester) async {
        final done = Completer<SpeedTestResult>();
        var calls = 0;
        final s = diagSession();
        await pumpScreen(tester, s, DiagnosticsScreen(speedTest: (session) {
          calls++;
          expect(session, same(s.session));
          return done.future;
        }), size: const Size(1200, 2400));

        await tester.ensureVisible(run);
        await tester.tap(run);
        await tester.pump();
        expect(calls, 1);
        expect(find.text(t('companion.speedtest_running')), findsOneWidget);
        expect(tester.widget<OutlinedButton>(run).onPressed, isNull);

        done.complete(lan);
        await tester.pumpAndSettle();
        expect(find.text(t('companion.speedtest_running')), findsNothing);
        expect(find.text('42 ms'), findsOneWidget);
        expect(find.text('5.0 Mbit/s'), findsOneWidget);
        expect(find.text(t('companion.route_lan')), findsOneWidget);
        expect(find.descendant(of: run, matching: find.text(t('companion.speedtest_again'))), findsOneWidget);
        expect(tester.widget<OutlinedButton>(run).onPressed, isNotNull);
        await unmount(tester);
      });

      testWidgets('names the internet path when the test went over Pear', (tester) async {
        final s = diagSession(phase: TransportPhase.pear);
        await pumpScreen(
          tester,
          s,
          DiagnosticsScreen(speedTest: (_) async => const SpeedTestResult(pingMs: 180, bytes: 1000000, elapsed: Duration(seconds: 8), phase: TransportPhase.pear)),
          size: const Size(1200, 2400),
        );

        await tester.ensureVisible(run);
        await tester.tap(run);
        await tester.pumpAndSettle();
        expect(find.text(t('companion.route_pear')), findsOneWidget);
        expect(find.text('180 ms'), findsOneWidget);
        expect(find.text('1.0 Mbit/s'), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('a failed test says so, shows no stale numbers, and can be run again', (tester) async {
        var fail = true;
        final s = diagSession();
        await pumpScreen(tester, s, DiagnosticsScreen(speedTest: (_) async => fail ? throw StateError('dropped') : lan), size: const Size(1200, 2400));

        await tester.ensureVisible(run);
        await tester.tap(run);
        await tester.pumpAndSettle();
        expect(find.text(t('companion.speedtest_failed')), findsOneWidget);
        expect(find.text(t('companion.speedtest_download')), findsNothing);
        expect(find.text(t('companion.speedtest_running')), findsNothing);
        expect(tester.widget<OutlinedButton>(run).onPressed, isNotNull);

        fail = false;
        await tester.tap(run);
        await tester.pumpAndSettle();
        expect(find.text('5.0 Mbit/s'), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('a failure after a good run clears the old numbers', (tester) async {
        var fail = false;
        final s = diagSession();
        await pumpScreen(tester, s, DiagnosticsScreen(speedTest: (_) async => fail ? throw StateError('dropped') : lan), size: const Size(1200, 2400));

        await tester.ensureVisible(run);
        await tester.tap(run);
        await tester.pumpAndSettle();
        expect(find.text('5.0 Mbit/s'), findsOneWidget);

        fail = true;
        await tester.tap(run);
        await tester.pumpAndSettle();
        expect(find.text('5.0 Mbit/s'), findsNothing);
        expect(find.text(t('companion.speedtest_failed')), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('cannot be started while there is no route to the car', (tester) async {
        final s = diagSession(phase: TransportPhase.discovering);
        await pumpScreen(tester, s, DiagnosticsScreen(speedTest: (_) async => lan), size: const Size(1200, 2400));

        await tester.ensureVisible(run);
        expect(tester.widget<OutlinedButton>(run).onPressed, isNull);
        await unmount(tester);
      });
    });
  });

  testWidgets('About shows both versions and the licences', (tester) async {
    final s = TestSession();
    stubStatus(s);
    await pumpScreen(tester, s, AboutScreen(appVersion: () async => '1.4.0', buildNumber: () async => '17'));
    expect(find.text('1.4.0'), findsOneWidget);
    expect(find.text('1.4.0.0'), findsOneWidget);
    // BladeWatch-rdtj.57: the web About's build, platform and privacy note.
    expect(find.text('17'), findsOneWidget);
    expect(find.text(t('companion.platform')), findsOneWidget);
    expect(find.byKey(const ValueKey('about.privacy')), findsOneWidget);
    expect([AboutScreen.platformName('ios'), AboutScreen.platformName('macos'), AboutScreen.platformName('fuchsia')], ['iOS', 'macOS', 'fuchsia']);
    await tester.tap(find.byKey(const ValueKey('about.licenses')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}

