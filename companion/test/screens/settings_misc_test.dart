import 'package:bladewatch_companion/screens/about/about_screen.dart';
import 'package:bladewatch_companion/screens/diagnostics/diagnostics_screen.dart';
import 'package:bladewatch_companion/screens/performance/performance_screen.dart';
import 'package:bladewatch_companion/screens/settings/settings_screen.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
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
  group('SettingsScreen', () {
    late List<String?> languages;
    late int unpaired;

    Future<TestSession> pump(WidgetTester tester, {bool sd = true}) async {
      final s = TestSession();
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

    Future<void> pick(WidgetTester tester, String key, String item) async {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).last);
      await tester.pumpAndSettle();
    }

    testWidgets('this app: language and unpairing (after confirming)', (tester) async {
      await pump(tester);
      expect(find.text('dev-1'), findsOneWidget);
      await pick(tester, 'settings.appLanguage', 'de');
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
      await pick(tester, 'settings.carLanguage', 'de');
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
      expect(find.text(t('recording.cdr_freed', {'size': '4.0 MB', 'files': 4})), findsOneWidget);

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
        'performanceJson': '{"cpu":{"system":42.5,"tempC":55},"memory":{"usedMb":900,"totalMb":2000},"gpu":{"usage":10}}',
      });
      await pumpScreen(tester, s, const PerformanceScreen(), size: const Size(420, 1400));
      expect(find.text('42.5%'), findsOneWidget);
      expect(find.text('900 / 2000 MB'), findsOneWidget);
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
  });

  testWidgets('About shows both versions and the licences', (tester) async {
    final s = TestSession();
    stubStatus(s);
    await pumpScreen(tester, s, AboutScreen(appVersion: () async => '1.4.0'));
    expect(find.text('1.4.0'), findsOneWidget);
    expect(find.text('1.4.0.0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('about.licenses')));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}

