import 'package:bladewatch_ui/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_privacy_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_privacy_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;

  setUp(() {
    rpc = FakeRpcClient();
  });

  Widget wrap(SettingsPrivacyController controller) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsPrivacyScreen(controller: controller, systemService: SystemServiceClient(rpc))),
      );

  SettingsPrivacyController buildController() => SettingsPrivacyController(storageService: StorageServiceClient(rpc));

  Future<void> pumpTall(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(widget);
  }

  Future<void> openStorage(WidgetTester tester) async {
    rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 0, 'recordingsSize': 0});
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();
  }

  testWidgets('renders storage totals once loaded', (tester) async {
    rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 7, 'recordingsSize': 1048576});
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();

    expect(find.text('7'), findsOneWidget);
    expect(find.text('1.0 MB'), findsOneWidget);
  });

  testWidgets('shows the pending placeholder when storage is unavailable', (tester) async {
    rpc.stubError('StorageService', 'GetStorageSettings', const ConnectError('unavailable', 'down'));
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsWidgets);
  });

  testWidgets('toggling the debug logs switch updates its state', (tester) async {
    await openStorage(tester);

    await tester.tap(find.byKey(const ValueKey('privacy.debugLogs')));
    await tester.pump();

    final sw = tester.widget<SwitchListTile>(find.byKey(const ValueKey('privacy.debugLogs')));
    expect(sw.value, isTrue);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 0, 'recordingsSize': 0});
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsPrivacyScreen(controller: buildController(), systemService: SystemServiceClient(rpc))),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  group('Reset Data dialog', () {
    testWidgets('opens with every category unchecked and Reset Selected disabled', (tester) async {
      await openStorage(tester);

      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();

      expect(find.text('Reset Data'), findsOneWidget);
      // BladeWatch-uuo6: 'soh' is deliberately absent — state-of-health estimation
      // was removed from the daemon in BladeWatch-p7vi, so offering to recalibrate
      // it promised a repair the product cannot perform.
      for (final id in ['trips', 'socHistory', 'mediaRecordings', 'mediaSurveillance', 'mediaProximity', 'mediaTrips']) {
        final tile = tester.widget<CheckboxListTile>(find.byKey(ValueKey('reset.cat.$id')));
        expect(tile.value, isFalse);
      }
      expect(find.byKey(const ValueKey('reset.cat.soh')), findsNothing,
          reason: 'SoH calibration was removed with the feature itself');
      final confirmButton = tester.widget<TextButton>(find.byKey(const ValueKey('reset.confirmSelection')));
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('Cancel closes the dialog without calling the RPC', (tester) async {
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(find.text('Reset Data'), findsNothing);
      expect(rpc.calls.where((c) => c.method == 'ResetPerformance'), isEmpty);
    });

    testWidgets('Select all then Clear resets every checkbox', (tester) async {
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reset.selectAll')));
      await tester.pump();
      expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('reset.cat.trips'))).value, isTrue);

      await tester.tap(find.byKey(const ValueKey('reset.clearAll')));
      await tester.pump();
      expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('reset.cat.trips'))).value, isFalse);
    });

    testWidgets('selecting one category then confirming shows the "reset the following?" prompt naming it', (tester) async {
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reset.cat.trips')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();

      expect(find.text('Reset the following?'), findsOneWidget);
      expect(find.textContaining('• Trips'), findsOneWidget);
    });

    testWidgets('confirming the final prompt calls ResetPerformance with exactly the selected categories', (tester) async {
      rpc.stubJson('SystemService', 'ResetPerformance', {
        'success': true,
        'resultsJson': '{"trips":{"success":true,"rowsDeleted":12},"socHistory":{"success":true}}',
      });
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.cat.trips')));
      await tester.tap(find.byKey(const ValueKey('reset.cat.socHistory')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reset.confirmFinal')));
      await tester.pumpAndSettle();

      final call = rpc.calls.singleWhere((c) => c.method == 'ResetPerformance');
      expect((call.request as ResetPerformanceRequest).categories.toList(), ['trips', 'socHistory']);
      expect(find.text('Reset complete'), findsOneWidget);
      expect(find.textContaining('Trips (12 rows)'), findsOneWidget);
    });

    testWidgets('a file-based category shows a "files" detail suffix instead of "rows"', (tester) async {
      rpc.stubJson('SystemService', 'ResetPerformance', {
        'success': true,
        'resultsJson': '{"mediaRecordings":{"success":true,"filesDeleted":3}}',
      });
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.cat.mediaRecordings')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.confirmFinal')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Recordings (3 files)'), findsOneWidget);
    });

    testWidgets('a per-category failure in resultsJson is reported in the summary', (tester) async {
      rpc.stubJson('SystemService', 'ResetPerformance', {
        'success': true,
        'resultsJson': '{"trips":{"success":false,"error":"disk error"}}',
      });
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.cat.trips')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.confirmFinal')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Trips — disk error'), findsOneWidget);
    });

    testWidgets('shows a failure snackbar when the RPC reports success: false', (tester) async {
      rpc.stubJson('SystemService', 'ResetPerformance', {'success': false, 'error': 'no daemon'});
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.cat.trips')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.confirmFinal')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Reset failed: no daemon'), findsOneWidget);
    });

    testWidgets('shows a failure snackbar when the RPC throws', (tester) async {
      rpc.stubError('SystemService', 'ResetPerformance', const ConnectError('unavailable', 'down'));
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.cat.trips')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.confirmFinal')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Reset failed:'), findsOneWidget);
    });

    testWidgets('Cancel on the final confirmation does not call the RPC', (tester) async {
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.cat.trips')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      expect(rpc.calls.where((c) => c.method == 'ResetPerformance'), isEmpty);
    });

    testWidgets('a malformed resultsJson still shows the completion dialog with a failed line per category', (tester) async {
      rpc.stubJson('SystemService', 'ResetPerformance', {'success': true, 'resultsJson': 'not json'});
      await openStorage(tester);
      await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.cat.trips')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('reset.confirmSelection')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reset.confirmFinal')));
      await tester.pumpAndSettle();

      expect(find.text('Reset complete'), findsOneWidget);
      expect(find.textContaining('Trips — failed'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('reset.resultOk')));
      await tester.pumpAndSettle();
      expect(find.text('Reset complete'), findsNothing);
    });
  });
}
