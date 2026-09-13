import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/settings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;

  setUp(() {
    rpc = FakeRpcClient();
  });

  RecordingSettingsController buildController() => RecordingSettingsController(
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        settingsService: SettingsServiceClient(rpc),
        storageService: StorageServiceClient(rpc),
      );

  void stubHappyPath({bool sdCardAvailable = true}) {
    rpc.stubJson('SystemService', 'GetStatus', {
      'recordingStatus': {'configuredMode': 'DRIVE_MODE', 'isRecording': true},
    });
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {'recordingsCount': 3, 'proximityCount': 2},
    });
    rpc.stubJson('SettingsService', 'GetQuality', {'recordingQuality': 'HIGH', 'recordingCodec': 'H264', 'recordingSegmentMinutes': 10});
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'recordingsStorageType': 'INTERNAL',
      'recordingsLimitMb': 800,
      'recordingsSize': 500 * 1024 * 1024,
      'recordingsCount': 12,
      'sdCardAvailable': sdCardAvailable,
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

  Future<void> pump(WidgetTester tester, RecordingSettingsController controller) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsRecordingScreen(controller: controller)),
    ));
  }

  testWidgets('shows a loading indicator before data arrives', (tester) async {
    final controller = buildController();
    await pump(tester, controller);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Status tab shows the current mode and today count', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.text('Drive Mode'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('switching to the Capture tab shows the mode options and limit chips', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recording.mode.driveMode')), findsOneWidget);
    expect(find.byKey(const ValueKey('recording.limit.10')), findsOneWidget);
  });

  testWidgets('selecting a different mode enables Apply, and applying calls SetRecordingMode', (tester) async {
    stubHappyPath();
    rpc.stubJson('SettingsService', 'SetRecordingMode', {'success': true});
    rpc.stubJson('SettingsService', 'SetQuality', {'success': true});
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
    await tester.pumpAndSettle();

    final applyBefore = tester.widget<FilledButton>(find.byKey(const ValueKey('recording.apply.capture')));
    expect(applyBefore.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('recording.mode.continuous')));
    await tester.pumpAndSettle();

    final applyAfter = tester.widget<FilledButton>(find.byKey(const ValueKey('recording.apply.capture')));
    expect(applyAfter.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('recording.apply.capture')));
    await tester.pumpAndSettle();

    final call = rpc.calls.firstWhere((c) => c.method == 'SetRecordingMode');
    expect((call.request as dynamic).mode, 'CONTINUOUS');
  });

  testWidgets('an apply failure shows a snack bar with the error', (tester) async {
    stubHappyPath();
    rpc.stubJson('SettingsService', 'SetRecordingMode', {'success': false, 'error': 'daemon busy'});
    rpc.stubJson('SettingsService', 'SetQuality', {'success': true});
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.mode.none')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recording.apply.capture')));
    await tester.pumpAndSettle();

    expect(find.text('daemon busy'), findsOneWidget);
  });

  testWidgets('tapping a recording-limit chip selects it', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recording.limit.1')));
    await tester.pumpAndSettle();

    final chip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('recording.limit.1')));
    expect(chip.selected, isTrue);
  });

  testWidgets('Quality tab lets the user pick a tier', (tester) async {
    stubHappyPath();
    rpc.stubJson('SettingsService', 'SetQuality', {'success': true});
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.quality')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recording.quality.max')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.apply.quality')));
    await tester.pumpAndSettle();

    final call = rpc.calls.firstWhere((c) => c.method == 'SetQuality' && (c.request as dynamic).recordingQuality == 'MAX');
    expect(call, isNotNull);
  });

  testWidgets('Storage tab shows usage info and the SD card option when available', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recording.storage.sdCard')), findsOneWidget);
    expect(find.text('12 recordings'), findsOneWidget);
    expect(find.byKey(const ValueKey('recording.format.start')), findsOneWidget);
  });

  testWidgets('tapping the SD card chip then Internal chip switches storage type both ways', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recording.storage.sdCard')));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('recording.storage.sdCard'))).selected, isTrue);

    await tester.tap(find.byKey(const ValueKey('recording.storage.internal')));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('recording.storage.internal'))).selected, isTrue);
  });

  testWidgets('Storage tab disables the SD card chip when unavailable and hides the format card', (tester) async {
    stubHappyPath(sdCardAvailable: false);
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    final sdChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('recording.storage.sdCard')));
    expect(sdChip.onSelected, isNull);
    expect(find.byKey(const ValueKey('recording.format.start')), findsNothing);
  });

  testWidgets('moving the storage limit slider marks the tab dirty', (tester) async {
    stubHappyPath();
    rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const ValueKey('recording.storage.limitSlider')), const Offset(50, 0));
    await tester.pumpAndSettle();

    final applyButton = tester.widget<FilledButton>(find.byKey(const ValueKey('recording.apply.storage')));
    expect(applyButton.onPressed, isNotNull);
  });

  group('format drive flow', () {
    testWidgets('confirm -> format -> success shows the result', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'ListFormatVolumes', {
        'volumes': [
          {'volumeId': 'sd1', 'mounted': true, 'mountPath': '/storage/sd1'},
        ],
      });
      rpc.stubJson('StorageService', 'FormatVolume', {'success': true, 'mountPath': '/storage/sd1'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recording.format.start')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('recording.format.confirm')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recording.format.confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording.format.result')), findsOneWidget);
    });

    testWidgets('cancel returns to the start button without formatting', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.format.start')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording.format.start')), findsOneWidget);
      expect(rpc.calls.where((c) => c.method == 'FormatVolume'), isEmpty);
    });
  });

  group('sync catalog flow', () {
    testWidgets('start -> success shows the result and can be dismissed', (tester) async {
      stubHappyPath();
      rpc.stubJson('RecordingsService', 'SyncCatalog', {'success': true, 'added': 2, 'removed': 1});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recording.sync.start')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording.sync.result')), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording.sync.start')), findsOneWidget);
    });
  });

  testWidgets('renders without error in dark theme', (tester) async {
    stubHappyPath();
    final controller = buildController();
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsRecordingScreen(controller: controller)),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
