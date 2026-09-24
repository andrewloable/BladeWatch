import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/pairing_channel.dart';
import 'package:bladewatch_ui/screens/pairing/pairing_controller.dart';
import 'package:bladewatch_ui/screens/pairing/pairing_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

/// BladeWatch-rdtj.7: the in-car "Pair a device" dialog.
void main() {
  late FakePlatformChannel fake;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 9, 24, 12);
    fake = FakePlatformChannel()
      ..stub('pairing', 'mint', {'payload': 'qr-text', 'expiresAt': now.add(const Duration(minutes: 5)).millisecondsSinceEpoch, 'lanEnabled': false})
      ..stub('pairing', 'list', {
        'companions': [<Object?, Object?>{'id': 'a1', 'name': 'Owner phone', 'pairedAt': 1700000000000}],
      });
  });

  Future<PairingController> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final controller = PairingController(PairingChannel(fake), now: () => now);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PairingDialog(controller: controller)),
    ));
    await controller.start();
    await tester.pump();
    return controller;
  }

  testWidgets('shows the single-use QR with its countdown and what pairing switches on', (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('pairing.qr')), findsOneWidget);
    expect(find.text('Expires in 5:00'), findsOneWidget);
    expect(find.text('Pairing turns on remote access for this car.'), findsOneWidget);
    expect(find.text('Owner phone'), findsOneWidget);
  });

  testWidgets('an expired code stops looking valid and can be replaced', (tester) async {
    final controller = await open(tester);
    now = now.add(const Duration(minutes: 6));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('pairing.qr')), findsNothing);
    expect(find.byKey(const ValueKey('pairing.expired')), findsOneWidget);

    fake.stub('pairing', 'mint', {'payload': 'fresh', 'expiresAt': now.add(const Duration(minutes: 5)).millisecondsSinceEpoch});
    await tester.tap(find.text('New code'));
    await tester.pump();
    expect(controller.offer?.payload, 'fresh');
    expect(find.byKey(const ValueKey('pairing.qr')), findsOneWidget);
  });

  testWidgets('a daemon that does not answer shows an error with a retry', (tester) async {
    fake.stubError('pairing', 'mint', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
    await open(tester);
    expect(find.byKey(const ValueKey('pairing.error')), findsOneWidget);
    fake.stub('pairing', 'mint', {'payload': 'qr-text', 'expiresAt': now.add(const Duration(minutes: 5)).millisecondsSinceEpoch});
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byKey(const ValueKey('pairing.qr')), findsOneWidget);
  });

  testWidgets('shows a spinner while the first code is being minted', (tester) async {
    final controller = PairingController(PairingChannel(fake), now: () => now);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PairingDialog(controller: controller)),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the LAN switch is explained and sends the owner\'s choice', (tester) async {
    await open(tester);
    expect(find.text('Direct connection on this Wi-Fi'), findsOneWidget);
    fake.stub('pairing', 'setLanAccess', {'enabled': true});
    await tester.tap(find.byKey(const ValueKey('pairing.lan')));
    await tester.pump();
    expect(fake.calls.last.method, 'setLanAccess');
    expect(fake.calls.last.args, {'enabled': true});
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('pairing.lan'))).value, isTrue);
  });

  testWidgets('removing a device asks first, and only a confirmed remove revokes it', (tester) async {
    await open(tester);
    fake.stub('pairing', 'revoke', {'status': 'ok'});

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove Owner phone?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fake.calls.where((c) => c.method == 'revoke'), isEmpty);

    fake.stub('pairing', 'list', {'companions': []});
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pairing.removeConfirm')));
    await tester.pumpAndSettle();
    expect(fake.calls.where((c) => c.method == 'revoke').single.args, {'id': 'a1'});
    expect(find.text('No devices paired yet.'), findsOneWidget);
  });

  testWidgets('a removal the daemon refuses says so instead of doing nothing', (tester) async {
    await open(tester);
    fake.stubError('pairing', 'revoke', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pairing.removeConfirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pairing.actionError')), findsOneWidget);
    expect(find.text('Owner phone'), findsOneWidget);
  });

  testWidgets('Close dismisses the dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(onPressed: () => showPairingDialog(context, PairingChannel(fake)), child: const Text('open')),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(PairingDialog), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PairingDialog), findsNothing);
  });
}
