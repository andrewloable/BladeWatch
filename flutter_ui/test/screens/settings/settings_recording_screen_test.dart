import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/settings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_models.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';
import 'package:bladewatch_ui/widgets/bw_choice_chip.dart';

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => 'fake.jwt.token';

  @override
  Future<int> stateVersion() async => 0;
}

void main() {
  late FakeRpcClient rpc;

  setUp(() {
    rpc = FakeRpcClient();
  });

  RecordingSettingsController buildController({RawGetSender? getSender, RawHttpSender? postSender}) =>
      RecordingSettingsController(
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        settingsService: SettingsServiceClient(rpc),
        storageService: StorageServiceClient(rpc),
        jwtSource: _FakeJwtSource(),
        // initState() always calls loadOverlayFields(), even on tests that never open the
        // Capture tab — it catches its own errors internally, so a throwing default here is
        // safe for every existing test and makes "no real socket, ever, unless a test opts in"
        // explicit rather than accidental.
        getSender: getSender ?? (uri, headers) async => throw Exception('not stubbed in this test'),
        postSender: postSender ?? (uri, headers, body) async => throw Exception('not stubbed in this test'),
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
    expect(find.byKey(const ValueKey('recording.priority.performance')), findsOneWidget);
    expect(find.byKey(const ValueKey('recording.priority.reliability')), findsOneWidget);
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

    final chip = tester.widget<BwChoiceChip>(find.byKey(const ValueKey('recording.limit.1')));
    expect(chip.selected, isTrue);
  });

  testWidgets('selecting a recording-priority option enables Apply, and applying sends it', (tester) async {
    stubHappyPath();
    rpc.stubJson('SettingsService', 'SetRecordingMode', {'success': true});
    rpc.stubJson('SettingsService', 'SetQuality', {'success': true});
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
    await tester.pumpAndSettle();

    final applyBefore = tester.widget<FilledButton>(find.byKey(const ValueKey('recording.apply.capture')));
    expect(applyBefore.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('recording.priority.performance')));
    await tester.pumpAndSettle();

    final applyAfter = tester.widget<FilledButton>(find.byKey(const ValueKey('recording.apply.capture')));
    expect(applyAfter.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('recording.apply.capture')));
    await tester.pumpAndSettle();

    final call = rpc.calls.firstWhere((c) => c.method == 'SetQuality');
    expect((call.request as dynamic).recordingPriority, 'PERFORMANCE');
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
    expect(tester.widget<BwChoiceChip>(find.byKey(const ValueKey('recording.storage.sdCard'))).selected, isTrue);

    await tester.tap(find.byKey(const ValueKey('recording.storage.internal')));
    await tester.pumpAndSettle();
    expect(tester.widget<BwChoiceChip>(find.byKey(const ValueKey('recording.storage.internal'))).selected, isTrue);
  });

  testWidgets('Storage tab disables the SD card chip when unavailable and hides the format card', (tester) async {
    stubHappyPath(sdCardAvailable: false);
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    final sdChip = tester.widget<BwChoiceChip>(find.byKey(const ValueKey('recording.storage.sdCard')));
    expect(sdChip.onSelected, isNull);
    expect(find.byKey(const ValueKey('recording.format.start')), findsNothing);
  });

  testWidgets('Storage tab shows a restart-device banner when the SD card failed to mount at boot', (tester) async {
    rpc.stubJson('SystemService', 'GetStatus', {
      'recordingStatus': {'configuredMode': 'DRIVE_MODE', 'isRecording': true},
    });
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {'recordingsCount': 3, 'proximityCount': 2},
    });
    rpc.stubJson('SettingsService', 'GetQuality', {'recordingQuality': 'HIGH', 'recordingCodec': 'H264', 'recordingSegmentMinutes': 10});
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'recordingsStorageType': 'SD_CARD',
      'recordingsLimitMb': 800,
      'recordingsSize': 500 * 1024 * 1024,
      'recordingsCount': 12,
      'sdCardAvailable': false,
      'sdCardFreeFormatted': '',
      'internalFreeFormatted': '5.4 GB',
      'recordingsPath': '/storage/emulated/0/BladeWatch/recordings',
      'minLimitMb': 100,
      'maxLimitMb': 100000,
      'maxLimitMbSdCard': 100000,
      'internalTotalSpace': 20000 * 1024 * 1024,
      'sdCardTotalSpace': 0,
      'sdCardMountFailed': true,
      'sdCardMountError': 'SD card is configured for storage but did not mount after 5 attempts at startup. '
          'Restart the device with the SD card seated to restore SD card storage.',
    });
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recording.storage.sdMountFailedBanner')), findsOneWidget);
    expect(find.textContaining('Restart the device'), findsOneWidget);
  });

  testWidgets('Storage tab shows no restart banner on the ordinary happy path', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('recording.storage.sdMountFailedBanner')), findsNothing);
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

  // ── BladeWatch-3118: every storage row is label + value, as native's
  // infoRow() renders them. Usage and Files used to show a bare value.
  testWidgets('the storage rows name what they are showing', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    for (final label in ['Storage Usage', 'Files']) {
      expect(find.text(label), findsOneWidget, reason: '$label row must be labelled');
    }
  });

  testWidgets('the storage values are right-aligned beside their labels', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    // A trailing value, not a title-only row — that is what makes the column
    // of values line up the way native's does.
    final usageRow = tester.widget<ListTile>(
      find.ancestor(of: find.text('Storage Usage'), matching: find.byType(ListTile)),
    );
    expect(usageRow.trailing, isNotNull);
    final filesRow = tester.widget<ListTile>(
      find.ancestor(of: find.text('Files'), matching: find.byType(ListTile)),
    );
    expect(filesRow.trailing, isNotNull);
  });

  // Path was the one row left on a second line. Native right-aligns it too —
  // confirmed on the head unit, where the full path fits without ellipsis —
  // so the earlier note that native would ellipsise it was wrong.
  testWidgets('the storage path is right-aligned like the other rows, not a subtitle', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    final pathRow = tester.widget<ListTile>(
      find.ancestor(of: find.text('Path'), matching: find.byType(ListTile)),
    );
    expect(pathRow.trailing, isNotNull, reason: 'the path belongs beside its label, as native renders it');
    expect(pathRow.subtitle, isNull, reason: 'the second-line form is what BladeWatch-3118 reported');
    expect(find.text('/storage/emulated/0/BladeWatch/recordings'), findsOneWidget);
  });

  // ── BladeWatch-htel: the two ways the Storage tab differed from native ────

  testWidgets('the storage limit is shown in GB above 1024 MB, as native formats it', (tester) async {
    stubHappyPath();
    // Override the happy-path 800 MB with a limit that actually crosses the
    // GB threshold — otherwise this asserts nothing about the formatting.
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'recordingsStorageType': 'INTERNAL',
      'recordingsLimitMb': 16384,
      'recordingsCount': 0,
      'recordingsSizeBytes': '0',
      'recordingsPath': '',
      'minLimitMb': 100,
      'maxLimitMb': 100000,
      'maxLimitMbSdCard': 100000,
    });
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    expect(find.text('16.0 GB'), findsOneWidget);
    expect(find.text('16384 MB'), findsNothing, reason: 'the raw megabyte count is what the port used to print');
  });

  testWidgets('the storage slider is stepped, not continuous', (tester) async {
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    // Native's SeekBar is one notch per 100 MB. Without divisions a drag lands
    // on arbitrary values that cannot be reproduced by touch.
    final slider = tester.widget<Slider>(find.byKey(const ValueKey('recording.storage.limitSlider')));
    expect(slider.divisions, isNotNull);
    expect(slider.divisions, greaterThan(0));
  });

  testWidgets('dragging the slider lands on a whole 100 MB step', (tester) async {
    stubHappyPath();
    final c = buildController();
    await pump(tester, c);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const ValueKey('recording.storage.limitSlider')), const Offset(120, 0));
    await tester.pumpAndSettle();

    expect((c.selectedLimitMb - c.storageLimitMinMb) % 100, 0);
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
  testWidgets('the tab bar sits BELOW the content, as native places it', (tester) async {
    // BladeWatch-htel: native adds its tab bar last (at the bottom of the
    // pane) and this app's own Trips screen already did the same; these two
    // screens were the only ones putting it on top.
    stubHappyPath();
    await pump(tester, buildController());
    await tester.pumpAndSettle();

    final tabBarY = tester.getCenter(find.byKey(const ValueKey('recording.tab.status'))).dy;
    final contentY = tester.getCenter(find.byType(ListView).first).dy;
    expect(tabBarY, greaterThan(contentY));
  });

  group('storage limit confirmation (BladeWatch-gyg1.4)', () {
    Future<RecordingSettingsController> openStorageTabAt(WidgetTester tester, int limitMb) async {
      final controller = buildController();
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.tab.storage')));
      await tester.pumpAndSettle();
      controller.setStorageLimitMb(limitMb);
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('lowering to a value the preview says deletes files shows a confirmation with the count and size',
        (tester) async {
      stubHappyPath(); // loaded limitMb is 800
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        // 12 GiB exactly, so formatStorageMb's binary MB->GB conversion is exact ("12.0 GB")
        // with no rounding ambiguity to reproduce in the assertion below.
        'recordingsImpact': {'fileCount': 48, 'totalBytes': 12884901888},
      });
      await openStorageTabAt(tester, 100);

      await tester.tap(find.byKey(const ValueKey('recording.apply.storage')));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byKey(const ValueKey('recording.storageConfirm.dialog')), findsOneWidget);
      expect(find.text(l10n.settings_recording_storage_confirm_message(48, '12.0 GB')), findsOneWidget);
    });

    testWidgets('cancelling leaves SetStorageSettings uncalled', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'recordingsImpact': {'fileCount': 48, 'totalBytes': 12300000000},
      });
      await openStorageTabAt(tester, 100);
      await tester.tap(find.byKey(const ValueKey('recording.apply.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recording.storageConfirm.cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording.storageConfirm.dialog')), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), isEmpty);
    });

    testWidgets('confirming calls SetStorageSettings exactly once with the new value', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'recordingsImpact': {'fileCount': 48, 'totalBytes': 12300000000},
      });
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await openStorageTabAt(tester, 100);
      await tester.tap(find.byKey(const ValueKey('recording.apply.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('recording.storageConfirm.confirm')));
      await tester.pumpAndSettle();

      final calls = rpc.calls.where((c) => c.method == 'SetStorageSettings').toList();
      expect(calls, hasLength(1));
      expect((calls.single.request as dynamic).recordingsLimitMb.toInt(), 100);
    });

    testWidgets('leaving the screen while the preview is still in flight does not throw', (tester) async {
      // BladeWatch-61ed: _applyStorage awaits previewStorageLimitImpact and then calls
      // showDialog(context: State.context). Reading that context after the widget is
      // unmounted throws "the State no longer has a context (and should be considered
      // defunct)". use_build_context_synchronously does not catch it because the await and
      // the context read are in different methods and the lint is intra-procedural.
      //
      // previewStorageLimitImpact turns an RPC failure into a NON-null unknown() impact, so
      // the dialog is attempted even on the slow/failing-daemon path that widens this window.
      stubHappyPath();
      final pending = rpc.stubPending('StorageService', 'PreviewStorageLimitChange');
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await openStorageTabAt(tester, 100);

      await tester.tap(find.byKey(const ValueKey('recording.apply.storage')));
      await tester.pump(); // the preview is now awaiting and cannot complete yet

      // The owner navigates away before the daemon answers.
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete({
        'recordingsImpact': {'fileCount': 48, 'totalBytes': 12300000000},
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('recording.storageConfirm.dialog')), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), isEmpty,
          reason: 'a screen the owner has left must not go on to write settings');
    });

    testWidgets('raising the limit applies directly with no dialog and no preview call', (tester) async {
      stubHappyPath(); // loaded limitMb is 800
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await openStorageTabAt(tester, 900);

      await tester.tap(find.byKey(const ValueKey('recording.apply.storage')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording.storageConfirm.dialog')), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), hasLength(1));
      expect(rpc.calls.where((c) => c.method == 'PreviewStorageLimitChange'), isEmpty);
    });

    testWidgets('lowering to a value that deletes nothing applies directly with no dialog', (tester) async {
      stubHappyPath();
      rpc.stubJson('StorageService', 'PreviewStorageLimitChange', {
        'recordingsImpact': {'fileCount': 0, 'totalBytes': 0},
      });
      rpc.stubJson('StorageService', 'SetStorageSettings', {'success': true});
      await openStorageTabAt(tester, 100);

      await tester.tap(find.byKey(const ValueKey('recording.apply.storage')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('recording.storageConfirm.dialog')), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), hasLength(1));
    });

    testWidgets('the preview RPC failing shows a distinct impact-unknown confirmation, and cancelling it '
        'also leaves SetStorageSettings uncalled', (tester) async {
      stubHappyPath();
      rpc.stubError('StorageService', 'PreviewStorageLimitChange', const ConnectError('unavailable', 'down'));
      await openStorageTabAt(tester, 100);

      await tester.tap(find.byKey(const ValueKey('recording.apply.storage')));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(find.byKey(const ValueKey('recording.storageConfirm.dialog')), findsOneWidget);
      expect(find.text(l10n.settings_recording_storage_confirm_unknown_title), findsOneWidget);
      expect(find.text(l10n.settings_recording_storage_confirm_unknown_message), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('recording.storageConfirm.cancel')));
      await tester.pumpAndSettle();

      expect(rpc.calls.where((c) => c.method == 'SetStorageSettings'), isEmpty);
    });
  });

  // BladeWatch-y78o.5: the burned-in telemetry overlay's field checklist, in the Capture tab.
  group('overlay field checklist', () {
    testWidgets('shows a checkbox per field, checked according to the loaded selection', (tester) async {
      stubHappyPath();
      final controller = buildController(
        getSender: (uri, headers) async => const RawHttpResponse(
          200,
          '{"success":true,"availableFields":["SPEED","GEAR"],"selections":{"continuous":["SPEED"],"surveillance":[],"proximity":[]}}',
        ),
      );
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
      await tester.pumpAndSettle();

      final speedTile =
          tester.widget<CheckboxListTile>(find.byKey(const ValueKey('recording.overlayField.speed')));
      final gearTile = tester.widget<CheckboxListTile>(find.byKey(const ValueKey('recording.overlayField.gear')));
      expect(speedTile.value, isTrue);
      expect(gearTile.value, isFalse);
    });

    testWidgets('every field has its own checkbox, none of them named for VIN or location', (tester) async {
      stubHappyPath();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
      await tester.pumpAndSettle();

      for (final field in OverlayField.values) {
        expect(find.byKey(ValueKey('recording.overlayField.${field.name}')), findsOneWidget);
      }
      // The forbidden-name guard itself lives in the daemon-side test (CameraProfileResolverTest
      // pattern equivalent: OverlayFieldSelectionTest.kt) which reflects over the actual
      // enumeration; this just confirms the widget tree has exactly the OverlayField.values
      // set and nothing extra.
      expect(find.byType(CheckboxListTile), findsNWidgets(OverlayField.values.length));
    });

    testWidgets('tapping a checkbox toggles it and sends the new selection to the daemon', (tester) async {
      stubHappyPath();
      String? sentBody;
      final controller = buildController(
        postSender: (uri, headers, body) async {
          sentBody = body;
          return const RawHttpResponse(200, '{"success":true}');
        },
      );
      await pump(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('recording.tab.capture')));
      await tester.pumpAndSettle();

      final before =
          tester.widget<CheckboxListTile>(find.byKey(const ValueKey('recording.overlayField.gear')));
      expect(before.value, isTrue); // default-all selection, since getSender throws by default

      await tester.tap(find.byKey(const ValueKey('recording.overlayField.gear')));
      await tester.pumpAndSettle();

      final after = tester.widget<CheckboxListTile>(find.byKey(const ValueKey('recording.overlayField.gear')));
      expect(after.value, isFalse);
      expect(sentBody, isNotNull);
      expect(sentBody, isNot(contains('GEAR')));
    });
  });
}
