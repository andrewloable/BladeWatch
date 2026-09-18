import 'dart:convert';

import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/settings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => 'fake.jwt.token';

  @override
  Future<int> stateVersion() async => 0;
}

void main() {
  late FakeRpcClient rpc;

  RecordingSettingsController build({RawGetSender? getSender, RawHttpSender? postSender}) => RecordingSettingsController(
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        settingsService: SettingsServiceClient(rpc),
        storageService: StorageServiceClient(rpc),
        jwtSource: _FakeJwtSource(),
        getSender: getSender,
        postSender: postSender,
      );

  void stubHappyPath() {
    rpc.stubJson('SystemService', 'GetStatus', {
      'recordingStatus': {'configuredMode': 'DRIVE_MODE', 'isRecording': true},
    });
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {'recordingsCount': 3, 'proximityCount': 2},
    });
    rpc.stubJson('SettingsService', 'GetQuality',
        {'recordingQuality': 'HIGH', 'recordingCodec': 'H264', 'recordingSegmentMinutes': 10, 'recordingPriority': 'PERFORMANCE'});
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'recordingsStorageType': 'INTERNAL',
      'recordingsLimitMb': 800,
      'recordingsSize': 500000000,
      'recordingsCount': 12,
      'sdCardAvailable': true,
      'sdCardFreeSpace': 0,
      'sdCardFreeFormatted': '2.1 GB',
      'internalFreeFormatted': '5.4 GB',
      'recordingsPath': '/storage/emulated/0/BladeWatch/recordings',
      'minLimitMb': 100,
      'maxLimitMb': 100000,
      'maxLimitMbSdCard': 100000,
      'internalTotalSpace': 20000 * 1024 * 1024,
      'sdCardTotalSpace': 32000 * 1024 * 1024,
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
  });

  group('load()', () {
    test('populates status, quality, and storage from their respective RPCs', () async {
      stubHappyPath();
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.status?.currentMode, 'DRIVE_MODE');
      expect(c.status?.isRecording, isTrue);
      expect(c.status?.normalTodayCount, 3);
      expect(c.status?.proximityTodayCount, 2);
      expect(c.selectedMode, RecordingMode.driveMode);
      expect(c.selectedQuality, RecordingQuality.high);
      expect(c.selectedLimit, RecordingLimit.ten);
      expect(c.selectedPriority, RecordingPriority.performance);
      expect(c.selectedStorageType, 'INTERNAL');
      expect(c.selectedLimitMb, 800);
      expect(c.dirty, isFalse);
      expect(c.storageSettings?.recordingsCount, 12);
      expect(c.storageSettings?.recordingsPath, '/storage/emulated/0/BladeWatch/recordings');
    });

    test('a total RPC failure leaves defaults without crashing', () async {
      rpc.stubError('SystemService', 'GetStatus', const ConnectError('unavailable', 'down'));
      rpc.stubError('RecordingsService', 'GetStats', const ConnectError('unavailable', 'down'));
      rpc.stubError('SettingsService', 'GetQuality', const ConnectError('unavailable', 'down'));
      rpc.stubError('StorageService', 'GetStorageSettings', const ConnectError('unavailable', 'down'));
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.status, isNull);
      expect(c.selectedMode, RecordingMode.none);
      expect(c.selectedQuality, RecordingQuality.standard);
      expect(c.selectedPriority, RecordingPriority.reliability);
    });
  });

  group('editable selections', () {
    test('selectMode marks dirty and notifies', () async {
      stubHappyPath();
      final c = build();
      await c.load();
      var notified = 0;
      c.addListener(() => notified++);

      c.selectMode(RecordingMode.continuous);

      expect(c.selectedMode, RecordingMode.continuous);
      expect(c.dirty, isTrue);
      expect(notified, 1);
    });

    test('selectLimit marks dirty', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.selectLimit(RecordingLimit.one);

      expect(c.selectedLimit, RecordingLimit.one);
      expect(c.dirty, isTrue);
    });

    test('selectPriority marks dirty', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.selectPriority(RecordingPriority.reliability);

      expect(c.selectedPriority, RecordingPriority.reliability);
      expect(c.dirty, isTrue);
    });

    test('selectQuality marks dirty', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.selectQuality(RecordingQuality.max);

      expect(c.selectedQuality, RecordingQuality.max);
      expect(c.dirty, isTrue);
    });

    test('selectStorageType to SD_CARD is a no-op when the SD card is unavailable', () async {
      rpc.stubJson('SystemService', 'GetStatus', {'recordingStatus': {}});
      rpc.stubJson('RecordingsService', 'GetStats', {'stats': {}});
      rpc.stubJson('SettingsService', 'GetQuality', {});
      rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsStorageType': 'INTERNAL', 'sdCardAvailable': false});
      final c = build();
      await c.load();

      c.selectStorageType('SD_CARD');

      expect(c.selectedStorageType, 'INTERNAL');
      expect(c.dirty, isFalse);
    });

    test('setStorageLimitMb clamps to the current bounds', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.setStorageLimitMb(50); // below minLimitMb of 100

      expect(c.selectedLimitMb, greaterThanOrEqualTo(100));
      expect(c.dirty, isTrue);
    });
  });

  group('applyChanges()', () {
    test('CAPTURE tab saves mode and recording limit', () async {
      stubHappyPath();
      rpc.stubJson('SettingsService', 'SetRecordingMode', {'success': true});
      rpc.stubJson('SettingsService', 'SetQuality', {'success': true});
      final c = build();
      await c.load();
      c.selectMode(RecordingMode.continuous);
      c.selectLimit(RecordingLimit.one);
      c.selectPriority(RecordingPriority.reliability);

      final result = await c.applyChanges(RecordingSettingsTab.capture);

      expect(result.ok, isTrue);
      expect(c.dirty, isFalse);
      final modeCall = rpc.calls.firstWhere((c) => c.method == 'SetRecordingMode');
      expect((modeCall.request as dynamic).mode, 'CONTINUOUS');
      final limitCall = rpc.calls.firstWhere((c) => c.method == 'SetQuality');
      expect((limitCall.request as dynamic).recordingSegmentMinutes, 1);
      expect((limitCall.request as dynamic).recordingPriority, 'RELIABILITY');
    });

    test('CAPTURE tab surfaces a mode-save failure without attempting the limit save result', () async {
      stubHappyPath();
      rpc.stubJson('SettingsService', 'SetRecordingMode', {'success': false, 'error': 'daemon busy'});
      rpc.stubJson('SettingsService', 'SetQuality', {'success': true});
      final c = build();
      await c.load();

      final result = await c.applyChanges(RecordingSettingsTab.capture);

      expect(result.ok, isFalse);
      expect(result.error, 'daemon busy');
    });

    test('QUALITY tab saves quality and codec', () async {
      stubHappyPath();
      rpc.stubJson('SettingsService', 'SetQuality', {'success': true});
      final c = build();
      await c.load();
      c.selectQuality(RecordingQuality.max);

      final result = await c.applyChanges(RecordingSettingsTab.quality);

      expect(result.ok, isTrue);
      final call = rpc.calls.firstWhere((c) => c.method == 'SetQuality');
      expect((call.request as dynamic).recordingQuality, 'MAX');
      expect((call.request as dynamic).codec, 'H264');
    });

    test('STORAGE tab saves storage type and limit', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      final c = build();
      await c.load();
      c.setStorageLimitMb(1000);

      final result = await c.applyChanges(RecordingSettingsTab.storage);

      expect(result.ok, isTrue);
      final call = rpc.calls.firstWhere((c) => c.method == 'SetStorageSettings');
      expect((call.request as dynamic).recordingsLimitMb.toInt(), 1000);
    });

    test('STATUS tab is a no-op that still clears dirty', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      final result = await c.applyChanges(RecordingSettingsTab.status);

      expect(result.ok, isTrue);
    });

    test('an RPC failure during apply is reported, not thrown', () async {
      stubHappyPath();
      rpc.stubError('SettingsService', 'SetQuality', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final result = await c.applyChanges(RecordingSettingsTab.quality);

      expect(result.ok, isFalse);
    });

    test('CAPTURE tab reports failure when the mode save itself throws', () async {
      stubHappyPath();
      rpc.stubError('SettingsService', 'SetRecordingMode', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final result = await c.applyChanges(RecordingSettingsTab.capture);

      expect(result.ok, isFalse);
    });

    test('CAPTURE tab reports failure when the limit save throws after the mode save succeeds', () async {
      stubHappyPath();
      rpc.stubJson('SettingsService', 'SetRecordingMode', {'success': true});
      rpc.stubError('SettingsService', 'SetQuality', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final result = await c.applyChanges(RecordingSettingsTab.capture);

      expect(result.ok, isFalse);
    });

    test('STORAGE tab reports failure when the storage save throws', () async {
      stubHappyPath();
      rpc.stubError('StorageService', 'SetStorageSettings', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final result = await c.applyChanges(RecordingSettingsTab.storage);

      expect(result.ok, isFalse);
    });
  });

  group('previewStorageLimitImpact()', () {
    test('raising the limit returns null without calling the preview RPC', () async {
      stubHappyPath(); // loaded limitMb is 800
      final c = build();
      await c.load();
      c.setStorageLimitMb(900);

      final impact = await c.previewStorageLimitImpact();

      expect(impact, isNull);
      expect(rpc.calls.where((call) => call.method == 'PreviewStorageLimitChange'), isEmpty);
    });

    test('lowering to a value the preview says deletes files returns the real count and size', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'recordingsImpact': {'fileCount': 48, 'totalBytes': 12300000000},
      });
      final c = build();
      await c.load();
      c.setStorageLimitMb(100);

      final impact = await c.previewStorageLimitImpact();

      expect(impact, isNotNull);
      expect(impact!.status, StorageLimitImpactStatus.known);
      expect(impact.fileCount, 48);
      expect(impact.totalBytes, 12300000000);
      final call = rpc.calls.firstWhere((c) => c.method == 'PreviewStorageLimitChange');
      expect((call.request as dynamic).recordingsLimitMb.toInt(), 100);
    });

    test('lowering to a value that deletes nothing returns null', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'recordingsImpact': {'fileCount': 0, 'totalBytes': 0},
      });
      final c = build();
      await c.load();
      c.setStorageLimitMb(100);

      final impact = await c.previewStorageLimitImpact();

      expect(impact, isNull);
    });

    test('the preview RPC failing returns an unknown-impact result', () async {
      stubHappyPath();
      rpc.stubError('StorageService', 'PreviewStorageLimitChange', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();
      c.setStorageLimitMb(100);

      final impact = await c.previewStorageLimitImpact();

      expect(impact, isNotNull);
      expect(impact!.status, StorageLimitImpactStatus.unknown);
    });
  });

  group('format drive flow', () {
    test('startFormat moves to confirming', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.startFormat();

      expect(c.formatState.state, FormatDriveState.confirming);
    });

    test('cancelFormat returns to idle', () async {
      stubHappyPath();
      final c = build();
      await c.load();
      c.startFormat();

      c.cancelFormat();

      expect(c.formatState.state, FormatDriveState.idle);
    });

    test('confirmFormat with no removable drive reports failure', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {'volumes': []});
      final c = build();
      await c.load();
      c.startFormat();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.failed);
    });

    test('confirmFormat formats the first mounted volume and reports success', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'sd1', 'mounted': true, 'mountPath': '/storage/sd1'},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': true, 'mountPath': '/storage/sd1'});
      final c = build();
      await c.load();
      c.startFormat();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.succeeded);
      final call = rpc.calls.firstWhere((c) => c.method == 'FormatVolume');
      expect((call.request as dynamic).volumeId, 'sd1');
    });

    test('confirmFormat reports failure when the format RPC fails', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'sd1', 'mounted': true},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': false, 'error': 'I/O error'});
      final c = build();
      await c.load();
      c.startFormat();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.failed);
      expect(c.formatState.message, 'I/O error');
    });

    test('confirmFormat reports failure when listing volumes throws', () async {
      stubHappyPath();
      rpc.stubError('StorageService', 'ListFormatVolumes', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();
      c.startFormat();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.failed);
    });

    test('dismissFormatResult returns to idle', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {'volumes': []});
      final c = build();
      await c.load();
      c.startFormat();
      await c.confirmFormat();

      c.dismissFormatResult();

      expect(c.formatState.state, FormatDriveState.idle);
    });
  });

  group('sync catalog flow', () {
    test('startSync succeeds and reports added/removed counts', () async {
      stubHappyPath();
      rpc.stubJson('RecordingsService', 'SyncCatalog', {'success': true, 'added': 3, 'removed': 1});
      final c = build();
      await c.load();

      await c.startSync();

      expect(c.syncState.state, SyncDriveState.succeeded);
    });

    test('a sync-in-progress error is reported distinctly', () async {
      stubHappyPath();
      rpc.stubJson('RecordingsService', 'SyncCatalog', {'success': false, 'error': 'sync_in_progress'});
      final c = build();
      await c.load();

      await c.startSync();

      expect(c.syncState.state, SyncDriveState.failed);
    });

    test('an RPC failure during sync is reported, not thrown', () async {
      stubHappyPath();
      rpc.stubError('RecordingsService', 'SyncCatalog', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.startSync();

      expect(c.syncState.state, SyncDriveState.failed);
    });

    test('dismissSyncResult returns to idle', () async {
      stubHappyPath();
      rpc.stubJson('RecordingsService', 'SyncCatalog', {'success': true, 'added': 0, 'removed': 0});
      final c = build();
      await c.load();
      await c.startSync();

      c.dismissSyncResult();

      expect(c.syncState.state, SyncDriveState.idle);
    });
  });

  group('storage limit bounds', () {
    test('storageLimitMaxMb uses the internal volume total when known', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      expect(c.storageLimitMaxMb, 20000);
    });

    test('storageLimitMaxMb switches to the SD card total after selecting SD_CARD', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.selectStorageType('SD_CARD');

      expect(c.storageLimitMaxMb, 32000);
    });

    test('storageLimitMaxMb falls back to the daemon max when the volume total is unknown', () async {
      rpc.stubJson('SystemService', 'GetStatus', {'recordingStatus': {}});
      rpc.stubJson('RecordingsService', 'GetStats', {'stats': {}});
      rpc.stubJson('SettingsService', 'GetQuality', {});
      rpc.stubJson('StorageService', 'GetStorageSettings', {
        'recordingsStorageType': 'INTERNAL',
        'sdCardAvailable': false,
        'maxLimitMb': 5000,
        'minLimitMb': 100,
      });
      final c = build();
      await c.load();

      expect(c.storageLimitMaxMb, 5000);
    });
  });

  // BladeWatch-y78o.5: the telemetry overlay field checklist. A plain REST endpoint (see
  // QualitySettingsApiHandler.java), not a Connect RPC — these use the injected raw GET/POST
  // senders directly rather than FakeRpcClient.
  group('overlay fields', () {
    test('loadOverlayFields() populates the selection from the daemon response', () async {
      final c = build(
        getSender: (uri, headers) async => RawHttpResponse(
          200,
          jsonEncode({
            'success': true,
            'availableFields': ['SPEED', 'GEAR'],
            'selections': {
              'continuous': ['SPEED'],
              'surveillance': [],
              'proximity': [],
            },
          }),
        ),
      );

      await c.loadOverlayFields();

      expect(c.overlayFields, {OverlayField.speed});
    });

    test('loadOverlayFields() leaves the default (all fields) selection on a failure', () async {
      final c = build(getSender: (uri, headers) async => throw Exception('connection refused'));

      await c.loadOverlayFields();

      expect(c.overlayFields, OverlayField.values.toSet());
    });

    test('setOverlayFieldEnabled() removes a field optimistically and keeps it removed on success', () async {
      String? sentBody;
      final c = build(
        postSender: (uri, headers, body) async {
          sentBody = body;
          return const RawHttpResponse(200, '{"success":true}');
        },
      );

      await c.setOverlayFieldEnabled(OverlayField.brakePedal, false);

      expect(c.overlayFields.contains(OverlayField.brakePedal), isFalse);
      final sent = jsonDecode(sentBody!) as Map<String, dynamic>;
      expect(sent['type'], 'continuous');
      expect((sent['fields'] as List).contains('BRAKE_PEDAL'), isFalse);
    });

    test('setOverlayFieldEnabled() reverts the optimistic change when the daemon write fails', () async {
      final c = build(postSender: (uri, headers, body) async => const RawHttpResponse(500, '{"success":false}'));
      final before = c.overlayFields;

      await c.setOverlayFieldEnabled(OverlayField.timestamp, false);

      expect(c.overlayFields, before);
      expect(c.overlayFields.contains(OverlayField.timestamp), isTrue);
    });

    test('setOverlayFieldEnabled() reverts on a thrown exception, not just a bad status', () async {
      final c = build(postSender: (uri, headers, body) async => throw Exception('connection refused'));
      final before = c.overlayFields;

      await c.setOverlayFieldEnabled(OverlayField.gear, false);

      expect(c.overlayFields, before);
    });
  });
}
