import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart' show SetStorageSettingsRequest;
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart' show SetSurveillanceConfigRequest;
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/safe_locations_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_models.dart' show StorageLimitImpactStatus;
import 'package:bladewatch_ui/screens/surveillance/surveillance_controller.dart';
import 'package:bladewatch_ui/screens/surveillance/surveillance_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;

  SurveillanceSettingsController build() {
    final surveillanceService = SurveillanceServiceClient(rpc);
    return SurveillanceSettingsController(
      surveillanceService: surveillanceService,
      longSurveillanceService: surveillanceService,
      safeLocationsService: SafeLocationsServiceClient(rpc),
      storageService: StorageServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
    );
  }

  void stubConfig({
    bool success = true,
    bool enabled = true,
    String distancePreset = 'GARAGE',
    int sensitivity = 4,
    bool detectPerson = true,
    bool detectCar = false,
    bool detectBike = true,
    int preRecord = 15,
    int postRecord = 30,
    bool nightMode = true,
    bool aiEnabled = false,
    double aiConfidence = 0.6,
    bool cameraFront = false,
    bool cameraRight = true,
    bool cameraRear = false,
    bool cameraLeft = true,
    String deterrentAction = 'horn',
    int deterrentCooldown = 90,
  }) {
    rpc.stubJson('SurveillanceService', 'GetConfig', {
      'success': success,
      'config': {
        'enabled': enabled,
        'distancePreset': distancePreset,
        'sensitivity': sensitivity,
        'detectPerson': detectPerson,
        'detectCar': detectCar,
        'detectBike': detectBike,
        'preRecordSeconds': preRecord,
        'postRecordSeconds': postRecord,
        'nightMode': nightMode,
        'aiEnabled': aiEnabled,
        'aiConfidence': aiConfidence,
        'cameraFront': cameraFront,
        'cameraRight': cameraRight,
        'cameraRear': cameraRear,
        'cameraLeft': cameraLeft,
        'deterrentAction': deterrentAction,
        'deterrentCooldownSeconds': deterrentCooldown,
      },
    });
  }

  void stubStatusAndStats({bool pipelineRunning = true, bool surveillanceActive = false, int surveillanceCount = 7}) {
    rpc.stubJson('SurveillanceService', 'GetStatus', {'pipelineRunning': pipelineRunning, 'surveillanceActive': surveillanceActive});
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {'surveillanceCount': surveillanceCount},
    });
  }

  void stubStorage({
    String storageType = 'SD_CARD',
    int limitMb = 800,
    int sizeBytes = 123456,
    int count = 9,
    bool sdCardAvailable = true,
    String path = '/storage/emulated/0/BladeWatch/surveillance',
    int minLimitMb = 100,
    int maxLimitMb = 50000,
    int maxLimitMbSdCard = 80000,
    int internalTotalMb = 20000,
    int sdCardTotalMb = 32000,
  }) {
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'surveillanceStorageType': storageType,
      'surveillanceLimitMb': limitMb,
      'surveillanceSize': sizeBytes,
      'surveillanceCount': count,
      'sdCardAvailable': sdCardAvailable,
      'surveillancePath': path,
      'minLimitMb': minLimitMb,
      'maxLimitMb': maxLimitMb,
      'maxLimitMbSdCard': maxLimitMbSdCard,
      'internalTotalSpace': internalTotalMb * 1024 * 1024,
      'sdCardTotalSpace': sdCardTotalMb * 1024 * 1024,
    });
  }

  void stubSafeLocations({bool featureEnabled = true, List<Map<String, Object?>> zones = const [], bool hasGps = true, double lat = 1.5, double lng = 2.5}) {
    rpc.stubJson('SafeLocationsService', 'ListZones', {
      'zones': zones,
      'featureEnabled': featureEnabled,
      'hasGps': hasGps,
      'lat': lat,
      'lng': lng,
    });
  }

  void stubHappyPath() {
    stubConfig();
    stubStatusAndStats();
    stubStorage();
    stubSafeLocations(zones: [
      {'id': 'z1', 'name': 'Home', 'lat': 1.1, 'lng': 2.2, 'radiusM': 100},
    ]);
  }

  setUp(() {
    rpc = FakeRpcClient();
  });

  group('load()', () {
    test('happy path populates config, status, storage, and safe locations', () async {
      stubHappyPath();
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.editEnabled, isTrue);
      expect(c.editPreset, 'GARAGE');
      expect(c.editSensitivity, 4);
      expect(c.editDetectPerson, isTrue);
      expect(c.editDetectCar, isFalse);
      expect(c.editDetectBike, isTrue);
      expect(c.editPreRecord, 15);
      expect(c.editPostRecord, 30);
      expect(c.editNightMode, isTrue);
      expect(c.editAiEnabled, isFalse);
      expect(c.editCameraFront, isFalse);
      expect(c.editCameraRight, isTrue);
      expect(c.editCameraRear, isFalse);
      expect(c.editCameraLeft, isTrue);
      expect(c.editDeterrent, 'horn');

      expect(c.status?.isRunning, isTrue);
      expect(c.status?.eventsToday, 7);

      expect(c.storageSettings?.storageType, 'SD_CARD');
      expect(c.editStorageType, 'SD_CARD');
      expect(c.editStorageLimitMb, 800);
      expect(c.storageSettings?.path, '/storage/emulated/0/BladeWatch/surveillance');
      expect(c.storageSettings?.surveillanceCount, 9);

      expect(c.safeLocFeatureEnabled, isTrue);
      expect(c.safeZones, hasLength(1));
      expect(c.safeZones.single.name, 'Home');
      expect(c.currentLat, 1.5);
      expect(c.currentLng, 2.5);
    });

    test('config fetch throwing leaves edit fields at class defaults', () async {
      rpc.stubError('SurveillanceService', 'GetConfig', const ConnectError('unavailable', 'down'));
      stubStatusAndStats();
      stubStorage();
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.editEnabled, isFalse);
      expect(c.editPreset, 'OUTDOOR');
      expect(c.editSensitivity, 3);
      expect(c.editPreRecord, 5);
      expect(c.editPostRecord, 10);
      expect(c.editDeterrent, 'silent');
    });

    test('config success:false leaves edit fields at class defaults', () async {
      stubConfig(success: false);
      stubStatusAndStats();
      stubStorage();
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.editEnabled, isFalse);
      expect(c.editPreset, 'OUTDOOR');
    });

    test('config with zero/empty fields falls back to per-field defaults', () async {
      rpc.stubJson('SurveillanceService', 'GetConfig', {
        'success': true,
        'config': {
          'enabled': false,
          'distancePreset': '',
          'sensitivity': 0,
          'detectPerson': false,
          'detectCar': false,
          'detectBike': false,
          'preRecordSeconds': 0,
          'postRecordSeconds': 0,
          'nightMode': false,
          'aiEnabled': false,
          'aiConfidence': 0.0,
          'cameraFront': false,
          'cameraRight': false,
          'cameraRear': false,
          'cameraLeft': false,
          'deterrentAction': '',
          'deterrentCooldownSeconds': 0,
        },
      });
      stubStatusAndStats();
      stubStorage();
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.editPreset, 'OUTDOOR');
      expect(c.editSensitivity, 3);
      expect(c.editPreRecord, 5);
      expect(c.editPostRecord, 10);
      expect(c.editDeterrent, 'silent');
    });

    test('status isRunning true via surveillanceActive alone (pipelineRunning false)', () async {
      stubConfig();
      rpc.stubJson('SurveillanceService', 'GetStatus', {'pipelineRunning': false, 'surveillanceActive': true});
      rpc.stubJson('RecordingsService', 'GetStats', {
        'stats': {'surveillanceCount': 0},
      });
      stubStorage();
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.status?.isRunning, isTrue);
    });

    test('getStatus throwing still lets eventsToday populate from GetStats', () async {
      stubConfig();
      rpc.stubError('SurveillanceService', 'GetStatus', const ConnectError('unavailable', 'down'));
      rpc.stubJson('RecordingsService', 'GetStats', {
        'stats': {'surveillanceCount': 4},
      });
      stubStorage();
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.status?.isRunning, isFalse);
      expect(c.status?.eventsToday, 4);
    });

    test('GetStats throwing still lets isRunning populate from GetStatus', () async {
      stubConfig();
      rpc.stubJson('SurveillanceService', 'GetStatus', {'pipelineRunning': true, 'surveillanceActive': false});
      rpc.stubError('RecordingsService', 'GetStats', const ConnectError('unavailable', 'down'));
      stubStorage();
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.status?.isRunning, isTrue);
      expect(c.status?.eventsToday, 0);
    });

    test('storage fetch throwing leaves storageSettings null and edit fields at defaults', () async {
      stubConfig();
      stubStatusAndStats();
      rpc.stubError('StorageService', 'GetStorageSettings', const ConnectError('unavailable', 'down'));
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.storageSettings, isNull);
      expect(c.editStorageType, 'INTERNAL');
      expect(c.editStorageLimitMb, 500);
    });

    test('storage with zero fields falls back to per-field defaults', () async {
      stubConfig();
      stubStatusAndStats();
      rpc.stubJson('StorageService', 'GetStorageSettings', {
        'surveillanceStorageType': '',
        'surveillanceLimitMb': 0,
        'surveillanceSize': 0,
        'surveillanceCount': 0,
        'sdCardAvailable': false,
        'surveillancePath': '',
        'minLimitMb': 0,
        'maxLimitMb': 0,
        'maxLimitMbSdCard': 0,
        'internalTotalSpace': 0,
        'sdCardTotalSpace': 0,
      });
      stubSafeLocations();
      final c = build();

      await c.load();

      expect(c.storageSettings?.storageType, 'INTERNAL');
      expect(c.storageSettings?.limitMb, 500);
      expect(c.storageSettings?.minLimitMb, 100);
      expect(c.storageSettings?.maxLimitMb, 100000);
      expect(c.storageSettings?.maxLimitMbSdCard, 100000);
    });

    test('safe locations fetch throwing resets to defaults', () async {
      stubConfig();
      stubStatusAndStats();
      stubStorage();
      rpc.stubError('SafeLocationsService', 'ListZones', const ConnectError('unavailable', 'down'));
      final c = build();

      await c.load();

      expect(c.safeLocFeatureEnabled, isFalse);
      expect(c.safeZones, isEmpty);
      expect(c.currentLat, 0);
      expect(c.currentLng, 0);
    });
  });

  group('toggleSurveillance', () {
    test('true calls Enable then reloads', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'Enable', {'success': true});
      final c = build();
      await c.load();

      await c.toggleSurveillance(true);

      expect(rpc.calls.any((call) => call.service == 'SurveillanceService' && call.method == 'Enable'), isTrue);
      expect(c.loading, isFalse);
    });

    test('false calls Disable then reloads', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'Disable', {'success': true});
      final c = build();
      await c.load();

      await c.toggleSurveillance(false);

      expect(rpc.calls.any((call) => call.service == 'SurveillanceService' && call.method == 'Disable'), isTrue);
    });

    test('Enable throwing does not prevent the reload', () async {
      stubHappyPath();
      rpc.stubError('SurveillanceService', 'Enable', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.toggleSurveillance(true);

      expect(c.loading, isFalse);
    });
  });

  group('toggleSafeLocations', () {
    test('true calls Toggle then reloads', () async {
      stubHappyPath();
      rpc.stubJson('SafeLocationsService', 'Toggle', {'success': true, 'enabled': true});
      final c = build();
      await c.load();

      await c.toggleSafeLocations(true);

      final call = rpc.calls.lastWhere((c) => c.service == 'SafeLocationsService' && c.method == 'Toggle');
      expect(call, isNotNull);
    });

    test('Toggle throwing does not prevent the reload', () async {
      stubHappyPath();
      rpc.stubError('SafeLocationsService', 'Toggle', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.toggleSafeLocations(false);

      expect(c.loading, isFalse);
    });
  });

  group('addSafeZoneAtCurrentLocation', () {
    test('adds the fixed-name/radius zone at the current GPS fix then reloads', () async {
      stubHappyPath();
      rpc.stubJson('SafeLocationsService', 'AddZone', {
        'success': true,
        'zone': {'id': 'z2', 'name': kDefaultSafeZoneName, 'lat': 1.5, 'lng': 2.5, 'radiusM': kDefaultSafeZoneRadiusM},
      });
      final c = build();
      await c.load();

      await c.addSafeZoneAtCurrentLocation();

      final call = rpc.calls.lastWhere((c) => c.service == 'SafeLocationsService' && c.method == 'AddZone');
      expect(call, isNotNull);
    });

    test('AddZone throwing does not prevent the reload', () async {
      stubHappyPath();
      rpc.stubError('SafeLocationsService', 'AddZone', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.addSafeZoneAtCurrentLocation();

      expect(c.loading, isFalse);
    });
  });

  group('deleteSafeZone', () {
    test('deletes then reloads', () async {
      stubHappyPath();
      rpc.stubJson('SafeLocationsService', 'DeleteZone', {'success': true});
      final c = build();
      await c.load();

      await c.deleteSafeZone('z1');

      final call = rpc.calls.lastWhere((c) => c.service == 'SafeLocationsService' && c.method == 'DeleteZone');
      expect(call, isNotNull);
    });

    test('DeleteZone throwing does not prevent the reload', () async {
      stubHappyPath();
      rpc.stubError('SafeLocationsService', 'DeleteZone', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.deleteSafeZone('z1');

      expect(c.loading, isFalse);
    });
  });

  group('local edit setters', () {
    test('each setter updates its field and notifies listeners', () async {
      stubHappyPath();
      final c = build();
      await c.load();
      var notifications = 0;
      c.addListener(() => notifications++);

      c.selectPreset('STREET');
      expect(c.editPreset, 'STREET');
      c.selectSensitivity(1);
      expect(c.editSensitivity, 1);
      c.setDetectPerson(false);
      expect(c.editDetectPerson, isFalse);
      c.setDetectCar(true);
      expect(c.editDetectCar, isTrue);
      c.setDetectBike(false);
      expect(c.editDetectBike, isFalse);
      c.selectPreRecord(2);
      expect(c.editPreRecord, 2);
      c.selectPostRecord(20);
      expect(c.editPostRecord, 20);
      c.setCameraFront(true);
      expect(c.editCameraFront, isTrue);
      c.setCameraRight(false);
      expect(c.editCameraRight, isFalse);
      c.setCameraRear(true);
      expect(c.editCameraRear, isTrue);
      c.setCameraLeft(false);
      expect(c.editCameraLeft, isFalse);
      c.setAiEnabled(true);
      expect(c.editAiEnabled, isTrue);
      c.setNightMode(false);
      expect(c.editNightMode, isFalse);
      c.selectDeterrent('flash');
      expect(c.editDeterrent, 'flash');

      expect(notifications, 14);
    });
  });

  group('selectStorageType', () {
    test('SD_CARD is ignored when not available', () async {
      stubConfig();
      stubStatusAndStats();
      stubStorage(sdCardAvailable: false, storageType: 'INTERNAL');
      stubSafeLocations();
      final c = build();
      await c.load();

      c.selectStorageType('SD_CARD');

      expect(c.editStorageType, 'INTERNAL');
    });

    test('SD_CARD is applied and clamps the limit when available', () async {
      stubHappyPath();
      final c = build();
      await c.load();
      c.setStorageLimitMb(999999);

      c.selectStorageType('SD_CARD');

      expect(c.editStorageType, 'SD_CARD');
      expect(c.editStorageLimitMb, lessThanOrEqualTo(c.storageLimitMaxMb));
    });

    test('INTERNAL is always applied', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.selectStorageType('INTERNAL');

      expect(c.editStorageType, 'INTERNAL');
    });
  });

  group('setStorageLimitMb', () {
    test('clamps below the minimum', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.setStorageLimitMb(0);

      expect(c.editStorageLimitMb, c.storageLimitMinMb);
    });

    test('clamps above the maximum', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.setStorageLimitMb(999999999);

      expect(c.editStorageLimitMb, c.storageLimitMaxMb);
    });

    test('keeps an in-range value as-is', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.setStorageLimitMb(1000);

      expect(c.editStorageLimitMb, 1000);
    });
  });

  group('previewStorageLimitImpact() (BladeWatch-gyg1.6)', () {
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
        'surveillanceImpact': {'fileCount': 12, 'totalBytes': 12884901888},
      });
      final c = build();
      await c.load();
      c.setStorageLimitMb(100);

      final impact = await c.previewStorageLimitImpact();

      expect(impact, isNotNull);
      expect(impact!.status, StorageLimitImpactStatus.known);
      expect(impact.fileCount, 12);
      expect(impact.totalBytes, 12884901888);
      final call = rpc.calls.firstWhere((c) => c.method == 'PreviewStorageLimitChange');
      expect((call.request as dynamic).surveillanceLimitMb.toInt(), 100);
    });

    test('lowering to a value that deletes nothing returns null', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'surveillanceImpact': {'fileCount': 0, 'totalBytes': 0},
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

  group('storage limit bounds', () {
    test('fall back to fixed defaults when no storage was ever loaded', () {
      final c = build();

      expect(c.storageLimitMinMb, 100);
      expect(c.storageLimitMaxMb, 100000);
    });

    test('min below 100 is floored to 100', () async {
      stubConfig();
      stubStatusAndStats();
      stubStorage(minLimitMb: 0);
      stubSafeLocations();
      final c = build();
      await c.load();

      expect(c.storageLimitMinMb, 100);
    });

    test('max falls back to the daemon max when the volume total is unknown', () async {
      stubConfig();
      stubStatusAndStats();
      stubStorage(storageType: 'INTERNAL', internalTotalMb: 0, maxLimitMb: 42000);
      stubSafeLocations();
      final c = build();
      await c.load();

      expect(c.storageLimitMaxMb, 42000);
    });

    test('max is floored to min+100 when the daemon max is smaller than that', () async {
      stubConfig();
      stubStatusAndStats();
      stubStorage(storageType: 'INTERNAL', internalTotalMb: 0, maxLimitMb: 50, minLimitMb: 100);
      stubSafeLocations();
      final c = build();
      await c.load();

      expect(c.storageLimitMaxMb, 200);
    });
  });

  group('format drive', () {
    test('startFormat/cancelFormat/dismissFormatResult transition state', () async {
      stubHappyPath();
      final c = build();
      await c.load();

      c.startFormat();
      expect(c.formatState.state, FormatDriveState.confirming);
      c.cancelFormat();
      expect(c.formatState.state, FormatDriveState.idle);

      c.startFormat();
      c.dismissFormatResult();
      expect(c.formatState.state, FormatDriveState.idle);
    });

    test('no mounted volume produces the "no removable drive" failure', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {'volumes': []});
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.failed);
      expect(c.formatState.message, 'Error: No removable drive found');
    });

    test('a volume that is not mounted is filtered out, same as no volumes', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': false},
        ],
      });
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.failed);
      expect(c.formatState.message, 'Error: No removable drive found');
    });

    test('success reports the new mount path and reloads', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': true},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': true, 'mountPath': '/mnt/sdcard'});
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.succeeded);
      expect(c.formatState.message, 'Formatted successfully. New path: /mnt/sdcard');
    });

    test('success with an empty mount path falls back to "unknown"', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': true},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': true, 'mountPath': ''});
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.message, 'Formatted successfully. New path: unknown');
    });

    test('failure prefers the message field over error', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': true},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': false, 'message': 'busy', 'error': 'ignored'});
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.message, 'Error: busy');
    });

    test('failure falls back to error when message is empty', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': true},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': false, 'message': '', 'error': 'mount failed'});
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.message, 'Error: mount failed');
    });

    test('failure falls back to "Unknown result" when both are empty', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': true},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': false, 'message': '', 'error': ''});
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.message, 'Error: Unknown result');
    });

    test('ListFormatVolumes throwing surfaces the exception as the failure message', () async {
      stubHappyPath();
      rpc.stubError('StorageService', 'ListFormatVolumes', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.failed);
      expect(c.formatState.message, contains('Error:'));
    });

    test('FormatVolume throwing surfaces the exception as the failure message', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'v1', 'mounted': true},
        ],
      });
      rpc.stubError('StorageService', 'FormatVolume', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.confirmFormat();

      expect(c.formatState.state, FormatDriveState.failed);
    });
  });

  group('sync catalog', () {
    test('dismissSyncResult resets to idle', () async {
      stubHappyPath();
      final c = build();
      await c.load();
      rpc.stubJson('SurveillanceService', 'SyncCatalog', {'success': true, 'added': 1, 'removed': 0});
      await c.startSync();

      c.dismissSyncResult();

      expect(c.syncState.state, SyncDriveState.idle);
    });

    test('success reports added/removed counts', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SyncCatalog', {'success': true, 'added': 3, 'removed': 2});
      final c = build();
      await c.load();

      await c.startSync();

      expect(c.syncState.state, SyncDriveState.succeeded);
      expect(c.syncState.message, 'Synced: +3 -2');
    });

    test('sync_in_progress error maps to a friendly message', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SyncCatalog', {'success': false, 'error': 'sync_in_progress'});
      final c = build();
      await c.load();

      await c.startSync();

      expect(c.syncState.state, SyncDriveState.failed);
      expect(c.syncState.message, 'Sync already in progress');
    });

    test('other errors are reported as "Sync failed: ..."', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SyncCatalog', {'success': false, 'error': 'disk full'});
      final c = build();
      await c.load();

      await c.startSync();

      expect(c.syncState.message, 'Sync failed: disk full');
    });

    test('SyncCatalog throwing surfaces the exception', () async {
      stubHappyPath();
      rpc.stubError('SurveillanceService', 'SyncCatalog', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      await c.startSync();

      expect(c.syncState.state, SyncDriveState.failed);
    });
  });

  group('applyChanges', () {
    test('storage tab calls SetStorageSettings, not SetConfig', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      final c = build();
      await c.load();

      final result = await c.applyChanges(SurveillanceSettingsTab.storage);

      expect(result.ok, isTrue);
      expect(rpc.calls.any((call) => call.service == 'StorageService' && call.method == 'SetStorageSettings'), isTrue);
      expect(rpc.calls.any((call) => call.service == 'SurveillanceService' && call.method == 'SetConfig'), isFalse);
      final req = rpc.calls.firstWhere((call) => call.method == 'SetStorageSettings').request as SetStorageSettingsRequest;
      expect(req.surveillanceStorageType, c.editStorageType);
    });

    test('a non-storage tab calls SetConfig, not SetStorageSettings', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      final c = build();
      await c.load();

      final result = await c.applyChanges(SurveillanceSettingsTab.detection);

      expect(result.ok, isTrue);
      expect(rpc.calls.any((call) => call.service == 'SurveillanceService' && call.method == 'SetConfig'), isTrue);
      expect(rpc.calls.any((call) => call.method == 'SetStorageSettings'), isFalse);
    });

    test('SetConfig sends the loaded aiConfidence and deterrentCooldownSeconds unchanged', () async {
      stubConfig(aiConfidence: 0.73, deterrentCooldown: 45);
      stubStatusAndStats();
      stubStorage();
      stubSafeLocations();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      final c = build();
      await c.load();

      await c.applyChanges(SurveillanceSettingsTab.advanced);

      final req = rpc.calls.firstWhere((call) => call.method == 'SetConfig').request as SetSurveillanceConfigRequest;
      expect(req.config.aiConfidence, closeTo(0.73, 0.0001));
      expect(req.config.deterrentCooldownSeconds, 45);
    });

    test('SetConfig falls back to 0.4 aiConfidence when no config ever loaded', () async {
      rpc.stubError('SurveillanceService', 'GetConfig', const ConnectError('unavailable', 'down'));
      stubStatusAndStats();
      stubStorage();
      stubSafeLocations();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      final c = build();
      await c.load();

      await c.applyChanges(SurveillanceSettingsTab.general);

      final req = rpc.calls.firstWhere((call) => call.method == 'SetConfig').request as SetSurveillanceConfigRequest;
      expect(req.config.aiConfidence, closeTo(0.4, 0.0001));
    });

    test('SetConfig failure surfaces the server error', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': false, 'error': 'rejected'});
      final c = build();
      await c.load();

      final result = await c.applyChanges(SurveillanceSettingsTab.detection);

      expect(result.ok, isFalse);
      expect(result.error, 'rejected');
    });

    test('SetConfig failure with an empty error yields a null error', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': false, 'error': ''});
      final c = build();
      await c.load();

      final result = await c.applyChanges(SurveillanceSettingsTab.detection);

      expect(result.ok, isFalse);
      expect(result.error, isNull);
    });

    test('SetConfig throwing is reported as a failed ApplyResult', () async {
      stubHappyPath();
      rpc.stubError('SurveillanceService', 'SetConfig', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final result = await c.applyChanges(SurveillanceSettingsTab.recording);

      expect(result.ok, isFalse);
      expect(result.error, isNotNull);
    });

    test('SetStorageSettings failure surfaces the server error', () async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': false, 'error': 'no space'});
      final c = build();
      await c.load();

      final result = await c.applyChanges(SurveillanceSettingsTab.storage);

      expect(result.ok, isFalse);
      expect(result.error, 'no space');
    });

    test('SetStorageSettings throwing is reported as a failed ApplyResult', () async {
      stubHappyPath();
      rpc.stubError('StorageService', 'SetStorageSettings', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final result = await c.applyChanges(SurveillanceSettingsTab.storage);

      expect(result.ok, isFalse);
      expect(result.error, isNotNull);
    });

    test('always reloads afterward, discarding any pending unrelated edits', () async {
      stubHappyPath();
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      final c = build();
      await c.load();
      c.selectPreset('CUSTOM');

      await c.applyChanges(SurveillanceSettingsTab.detection);

      // load() re-fetched, so editPreset reflects the server's GARAGE again.
      expect(c.editPreset, 'GARAGE');
    });
  });
}
