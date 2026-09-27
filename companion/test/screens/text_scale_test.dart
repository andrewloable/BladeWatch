import 'package:bladewatch_companion/app.dart';
import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_test.dart' show MemoryStore, settle;
import '../support.dart';

/// A car with something to say on every page, and an empty answer to anything else.
class _Car implements RpcTransport {
  static final _answers = <String, Object?>{
    'SystemService/GetStatus': {
      'vehicleDataReady': true,
      'acc': true,
      'soc': {'percent': 81.0},
      'range': {'totalRangeKm': 442.0, 'elecRangeKm': 86.0, 'fuelRangeKm': 356.0, 'fuelPercent': 30.0},
      'charging': {'stateName': 'Charging'},
      'soh': {'percent': 97.5},
      'battery': {'level': 'NORMAL'},
      'inSafeZone': true,
      'safeZoneName': 'Home',
      'recordingStatus': {'isRecording': true, 'pipelineRunning': true},
      'network': {'type': 'wifi', 'ssid': 'Garage network', 'ip': '10.0.0.2'},
    },
    'TripsService/ListTrips': {
      'trips': [
        {'id': '7', 'startTime': '1700000000000', 'distanceKm': 12.0, 'durationSeconds': 900, 'overallScore': 88, 'tripCost': 12.5, 'currency': 'PHP'},
      ],
    },
    'TripsService/GetSummary': {
      'summary': [{'rollupJson': '{"tripCount":7,"totalDistanceKm":60.3,"totalDurationSeconds":6240,"totalEnergyKwh":7,"avgEfficiencyScore":83}'}],
    },
    'RecordingsService/GetStats': {'stats': {'totalCount': 1042, 'totalSizeBytes': '114000000000'}},
    'RecordingsService/ListRecordings': {
      'recordings': [
        for (var i = 0; i < 3; i++)
          {
            'filename': 'event_20260927_11120$i.mp4',
            'type': 'RECORDING_TYPE_SENTRY',
            'timestamp': '1700000000000',
            'size': '202100000',
            'durationSeconds': '240',
            'detectedClasses': ['person', 'vehicle', 'bike'],
          },
      ],
      'total': 3,
    },
    'NotificationsService/ListInbox': {
      'entries': [
        {'id': '5', 'title': 'CRITICAL · Person at rear', 'body': 'Very close · 2 people · close-up view', 'severity': 'NOTIFICATION_SEVERITY_CRITICAL'},
      ],
      'latestId': '5',
    },
    'VehicleService/GetState': {
      'success': true,
      'doors': {'overall': 1},
      'battery': {'soc': 81.0, 'rangeKm': 86, 'fuelPercent': 30.0, 'fuelRangeKm': 356},
      'climate': {'acOn': true, 'setpointC': 24.0, 'fanLevel': 3, 'outsideTempC': 34.0},
      'windows': {'lf': 0, 'rf': 10, 'lr': 0, 'rr': 100},
      'tyres': {'fl': {'psi': 36.0, 'temperatureC': 33}, 'fr': {'psi': 35.0, 'airLeakState': 1}, 'rl': {}, 'rr': {}},
    },
    'SurveillanceService/GetStatus': {'surveillanceActive': true, 'pipelineRunning': true},
    'SurveillanceService/GetConfig': {
      'config': {'sensitivity': 3, 'distancePreset': 'BALANCED', 'aiEnabled': true, 'aiConfidence': 0.5, 'preRecordSeconds': 5, 'postRecordSeconds': 10, 'cameraFront': true},
    },
    'SafeLocationsService/ListZones': {
      'zones': [
        {'id': 'z1', 'name': 'Home', 'radiusM': 100, 'enabled': true},
      ],
      'featureEnabled': true,
    },
    'SettingsService/GetQuality': {'recordingQuality': 'HIGH', 'recordingCodec': 'H264', 'recordingSegmentMinutes': 5},
    'SettingsService/GetLocale': {'lang': 'en', 'supported': {'en': true, 'de': true}},
    'StorageService/GetStorageSettings': {
      'recordingsLimitMb': '53923',
      'surveillanceLimitMb': '53923',
      'recordingsCount': 276,
      'recordingsSize': '52500000000',
      'surveillanceCount': 744,
      'surveillanceSize': '52700000000',
      'internalFreeFormatted': '46.2 GB',
      'sdCardAvailable': true,
      'sdCardFreeFormatted': '12.9 GB',
      'recordingsStorageType': 'INTERNAL',
      'surveillanceStorageType': 'INTERNAL',
    },
    'TripsService/GetConfig': {'config': {'enabled': true, 'electricityRate': 11.5, 'currency': 'PHP', 'isPhev': true}},
    'TripsService/GetStorage': {'storage': {'storageType': 'SD_CARD', 'limitMb': '500', 'usedMb': 12.5, 'tripsCount': 40}},
  };

  @override
  Future<T> call<T>(String service, String method, Object? request, T Function(Object? json) decode) async =>
      decode(_answers['$service/$method'] ?? <String, Object?>{});
}

/// BladeWatch-rdtj.55: every place at the phone's largest text size. Nothing may overflow -- a
/// RenderFlex overflow fails the test by itself.
///
/// The test font draws every glyph one em wide, wider than any real Latin font, so this is harsher
/// than a real phone; it proves "no overflow error", not the pixel fit, which still wants one
/// look on a device.
void main() {
  testWidgets('every place, and its main dialogs, at 2x text on a 412 x 915 phone', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final session = CarSession(rpc: _Car(), baseUrl: Uri.parse('http://127.0.0.1:9'), jwt: () async => 'jwt', initialPhase: TransportPhase.pear);
    await tester.pumpWidget(CompanionApp(
      store: MemoryStore(car: testCar()),
      loadTr: (_) async => testTr,
      openSession: (_) async => session,
    ));
    await settle(tester);

    Future<void> open(String key, String more) async {
      if (find.byKey(ValueKey('more.$key')).evaluate().isEmpty && more.isNotEmpty) {
        await tester.tap(find.text(t('nav.more')));
        await settle(tester);
        await tester.scrollUntilVisible(find.byKey(ValueKey('more.$key')), 50, scrollable: find.byType(Scrollable).last);
        await tester.ensureVisible(find.byKey(ValueKey('more.$key')));
        await tester.tap(find.byKey(ValueKey('more.$key')));
      } else {
        await tester.tap(find.text(t('nav.$key')).last);
      }
      await settle(tester);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text(t('nav.$key'))), findsOneWidget, reason: '$key is on screen');
    }

    Future<void> dialog(Finder opener) async {
      await tester.ensureVisible(opener);
      await settle(tester);
      await tester.tap(opener);
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton)).first);
      await settle(tester);
    }

    for (final key in ['dashboard', 'live', 'events', 'recordings']) {
      await open(key, '');
    }
    await open('dashboard', '');
    await dialog(find.text(t('dashboard.battery_capacity')));

    for (final key in ['vehicle', 'location', 'trips', 'surveillance', 'notifications', 'settings', 'performance', 'diagnostics', 'about']) {
      await open(key, 'more');
      if (key == 'vehicle') await dialog(find.byKey(const ValueKey('window.1.50')));
      if (key == 'settings') await dialog(find.byKey(const ValueKey('settings.unpair')));
    }
    await tester.pumpWidget(const SizedBox()); // the app disposes the session it opened
    await tester.pump(const Duration(seconds: 1));
  });
}
