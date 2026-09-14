import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/shell/app_shell.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-0kru: the toolbar status pill used to be hardcoded — always
/// "Connecting…", always a grey dot, copy button always `onPressed: null` — on
/// every screen in the app.
///
/// Native's `MainActivity.updateUrlDisplay()` hides the bar entirely when there
/// is no tunnel (`View.GONE`) because the Dashboard connect card already reports
/// that state. These pin both halves of that rule.
void main() {
  Widget wrap({Future<String?> Function()? source}) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppShell(
          controller: ShellController(),
          onLanguageTap: () {},
          tunnelUrlSource: source,
        ),
      );

  testWidgets('no tunnel means NO pill, not a placeholder', (tester) async {
    await tester.pumpWidget(wrap(source: () async => null));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shell.statusPill.url')), findsNothing);
    expect(find.byKey(const ValueKey('shell.statusPill.dot')), findsNothing);
    expect(find.byKey(const ValueKey('shell.statusPill.copy')), findsNothing);
    // The exact regression: a placeholder string standing in for the real state.
    expect(find.text('Connecting…'), findsNothing);
  });

  testWidgets('an absent source is treated the same as no tunnel', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('shell.statusPill.url')), findsNothing);
    expect(find.text('Connecting…'), findsNothing);
  });

  testWidgets('a live tunnel shows the real URL, not a placeholder', (tester) async {
    await tester.pumpWidget(wrap(source: () async => 'https://abc123.share.zrok.io'));
    await tester.pumpAndSettle();

    expect(find.text('https://abc123.share.zrok.io'), findsOneWidget);
    expect(find.byKey(const ValueKey('shell.statusPill.dot')), findsOneWidget);
  });

  testWidgets('the copy button actually copies the URL', (tester) async {
    const url = 'https://abc123.share.zrok.io';
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(wrap(source: () async => url));
    await tester.pumpAndSettle();

    // It was `onPressed: null` before, so this tap did nothing at all.
    await tester.tap(find.byKey(const ValueKey('shell.statusPill.copy')));
    await tester.pumpAndSettle();

    expect(copied, url);
  });

  // A tunnel can drop while the app is open. The pill must go away again rather
  // than keep showing a dead address someone might try to hand out.
  testWidgets('the pill disappears when a tunnel drops', (tester) async {
    String? current = 'https://abc123.share.zrok.io';
    await tester.pumpWidget(wrap(source: () async => current));
    await tester.pumpAndSettle();
    expect(find.text('https://abc123.share.zrok.io'), findsOneWidget);

    current = null;
    // Past the poll interval.
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shell.statusPill.url')), findsNothing);
  });

  // A failing IPC call is indistinguishable from "no tunnel" for this pill, and
  // native hides the bar in both cases. It must not throw into the widget tree.
  testWidgets('a throwing source hides the pill instead of crashing', (tester) async {
    await tester.pumpWidget(wrap(source: () async => throw StateError('ipc down')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('shell.statusPill.url')), findsNothing);
  });
}
