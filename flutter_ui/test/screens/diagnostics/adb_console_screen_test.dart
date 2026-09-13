import 'package:bladewatch_ui/adb/adb_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/diagnostics/adb_console_controller.dart';
import 'package:bladewatch_ui/screens/diagnostics/adb_console_models.dart';
import 'package:bladewatch_ui/screens/diagnostics/adb_console_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_adb_connection.dart';

void main() {
  late FakeAdbConnection connection;
  late AdbConsoleController controller;

  setUp(() {
    connection = FakeAdbConnection();
    controller = AdbConsoleController(connection: connection);
  });

  Future<void> pumpScreen(WidgetTester tester, {Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AdbConsoleScreen(controller: controller)),
    ));
  }

  testWidgets('shows a connecting indicator before connect() resolves', (tester) async {
    connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('adb.connecting')), findsOneWidget);
  });

  testWidgets('shows the unavailable explanation and a working retry button', (tester) async {
    connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.unavailable);
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('adb.unavailable')), findsOneWidget);
    expect(find.text('ADB is not connected'), findsOneWidget);

    connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
    await tester.tap(find.byKey(const ValueKey('adb.retryButton')));
    await tester.pumpAndSettle();

    expect(connection.connectCallCount, 2);
    expect(find.byKey(const ValueKey('adb.commandField')), findsOneWidget);
  });

  testWidgets('shows the auth-pending explanation and a working retry button', (tester) async {
    connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.authPending);
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('adb.authPending')), findsOneWidget);
    expect(find.text('Waiting for approval'), findsOneWidget);

    connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
    await tester.tap(find.byKey(const ValueKey('adb.retryButton')));
    await tester.pumpAndSettle();

    expect(connection.connectCallCount, 2);
  });

  group('connected', () {
    setUp(() {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
    });

    testWidgets('shows the console: command field, execute button, presets, and an empty-output placeholder', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adb.commandField')), findsOneWidget);
      expect(find.byKey(const ValueKey('adb.executeButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('adb.clearButton')), findsOneWidget);
      expect(find.byKey(ValueKey('adb.preset.0')), findsOneWidget);
      expect(find.text(adbPresetCommands.first.label), findsOneWidget);
      expect(find.text('\$ Ready for commands…'), findsOneWidget);
    });

    testWidgets('typing a command and tapping execute runs it and clears the field', (tester) async {
      connection.commandOutputs['df -h'] = 'Filesystem  Size';
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('adb.commandField')), 'df -h');
      await tester.tap(find.byKey(const ValueKey('adb.executeButton')));
      await tester.pumpAndSettle();

      expect(connection.runCommandCalls, ['df -h']);
      expect(find.text(r'$ df -h' '\nFilesystem  Size'), findsOneWidget);
      final field = tester.widget<TextField>(find.byKey(const ValueKey('adb.commandField')));
      expect(field.controller!.text, isEmpty);
    });

    testWidgets('submitting via the keyboard action also runs the command', (tester) async {
      connection.commandOutputs['ls'] = 'a.txt';
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('adb.commandField')), 'ls');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(connection.runCommandCalls, ['ls']);
    });

    testWidgets('tapping a preset chip populates the command field without executing it', (tester) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('adb.preset.0')));
      await tester.pump();

      final field = tester.widget<TextField>(find.byKey(const ValueKey('adb.commandField')));
      expect(field.controller!.text, adbPresetCommands.first.command);
      expect(connection.runCommandCalls, isEmpty);
    });

    testWidgets('tapping clear empties the output transcript', (tester) async {
      connection.commandOutputs['ls'] = 'a.txt';
      await pumpScreen(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('adb.commandField')), 'ls');
      await tester.tap(find.byKey(const ValueKey('adb.executeButton')));
      await tester.pumpAndSettle();
      expect(find.text('\$ Ready for commands…'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('adb.clearButton')));
      await tester.pump();

      expect(find.text('\$ Ready for commands…'), findsOneWidget);
    });

    testWidgets('shows an Error line instead of crashing when a command fails', (tester) async {
      connection.runCommandError = const AdbCommandTimeoutException();
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('adb.commandField')), 'sleep 999');
      await tester.tap(find.byKey(const ValueKey('adb.executeButton')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in dark theme', (tester) async {
      await pumpScreen(tester, brightness: Brightness.dark);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('adb.commandField')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
