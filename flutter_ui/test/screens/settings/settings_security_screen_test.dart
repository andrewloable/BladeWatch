import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/pairing_channel.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/screens/pairing/pairing_dialog.dart';
import 'package:bladewatch_ui/screens/settings/settings_lock_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_security_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

/// BladeWatch-hr6r: Settings > Security -- turning the lock on (new + confirm), changing the
/// PIN, and turning it off after a confirm. BladeWatch-xfb5: pairing a device and managing
/// paired devices, moved here from the Dashboard.
void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel platform;
  late SettingsLockController controller;

  setUp(() {
    rpc = FakeRpcClient();
    platform = FakePlatformChannel();
    platform.stub('prefs', 'setSettingsLockKnown', null);
    controller = SettingsLockController(settingsService: SettingsServiceClient(rpc), prefs: PrefsChannel(platform));
  });

  Future<void> pump(WidgetTester tester, {bool enabled = false, PairingChannel? pairing}) async {
    rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': enabled, 'retryAfterMs': '0'});
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsSecurityScreen(controller: controller, pairingChannel: pairing)),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.widgetWithText(OutlinedButton, d));
      await tester.pump();
    }
  }

  testWidgets('starts off: the switch is unchecked and there is no Change PIN row', (tester) async {
    await pump(tester);

    final switchTile = tester.widget<SwitchListTile>(find.byKey(const ValueKey('security.enabled')));
    expect(switchTile.value, isFalse);
    expect(find.byKey(const ValueKey('security.changePin')), findsNothing);
  });

  testWidgets('turning the switch on asks for a new PIN, twice, then enables it', (tester) async {
    await pump(tester);
    rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': true, 'error': ''});

    await tester.tap(find.byKey(const ValueKey('security.enabled')));
    await tester.pumpAndSettle();
    await tapDigits(tester, '123456'); // new PIN
    await tester.pumpAndSettle();
    await tapDigits(tester, '123456'); // confirm
    await tester.pumpAndSettle();

    expect(rpc.calls.where((c) => c.method == 'SetSettingsLock').single.request, isA<SetSettingsLockRequest>());
    final sent = rpc.calls.where((c) => c.method == 'SetSettingsLock').single.request as SetSettingsLockRequest;
    expect(sent.enabled, isTrue);
    expect(sent.pin, '123456');
    expect(controller.enabled, isTrue);
    final switchTile = tester.widget<SwitchListTile>(find.byKey(const ValueKey('security.enabled')));
    expect(switchTile.value, isTrue);
    expect(find.byKey(const ValueKey('security.changePin')), findsOneWidget);
  });

  testWidgets('cancelling the new-PIN dialog leaves the lock off', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('security.enabled')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(rpc.calls.where((c) => c.method == 'SetSettingsLock'), isEmpty);
    expect(controller.enabled, isFalse);
  });

  testWidgets('a mismatched confirmation does not save, and starting over succeeds', (tester) async {
    await pump(tester);
    rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': true, 'error': ''});

    await tester.tap(find.byKey(const ValueKey('security.enabled')));
    await tester.pumpAndSettle();
    await tapDigits(tester, '111111');
    await tester.pumpAndSettle();
    await tapDigits(tester, '222222'); // does not match
    await tester.pumpAndSettle();

    expect(rpc.calls.where((c) => c.method == 'SetSettingsLock'), isEmpty);

    await tapDigits(tester, '999999');
    await tester.pumpAndSettle();
    await tapDigits(tester, '999999');
    await tester.pumpAndSettle();

    expect((rpc.calls.where((c) => c.method == 'SetSettingsLock').single.request as SetSettingsLockRequest).pin, '999999');
  });

  testWidgets('Change PIN sets a new one while the lock stays on', (tester) async {
    await pump(tester, enabled: true);
    rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': true, 'error': ''});

    await tester.tap(find.byKey(const ValueKey('security.changePin')));
    await tester.pumpAndSettle();
    await tapDigits(tester, '654321');
    await tester.pumpAndSettle();
    await tapDigits(tester, '654321');
    await tester.pumpAndSettle();

    expect((rpc.calls.where((c) => c.method == 'SetSettingsLock').single.request as SetSettingsLockRequest).pin, '654321');
    expect(controller.enabled, isTrue);
  });

  testWidgets('turning the switch off asks for confirmation before disabling', (tester) async {
    await pump(tester, enabled: true);
    rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': true, 'error': ''});

    await tester.tap(find.byKey(const ValueKey('security.enabled')));
    await tester.pumpAndSettle();
    expect(rpc.calls.where((c) => c.method == 'SetSettingsLock'), isEmpty, reason: 'not yet -- the confirm dialog is up');

    await tester.tap(find.byKey(const ValueKey('security.disableConfirm')));
    await tester.pumpAndSettle();

    final sent = rpc.calls.where((c) => c.method == 'SetSettingsLock').single.request as SetSettingsLockRequest;
    expect(sent.enabled, isFalse);
    expect(controller.enabled, isFalse);
  });

  testWidgets('cancelling the turn-off confirmation leaves the lock on', (tester) async {
    await pump(tester, enabled: true);

    await tester.tap(find.byKey(const ValueKey('security.enabled')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(rpc.calls.where((c) => c.method == 'SetSettingsLock'), isEmpty);
    expect(controller.enabled, isTrue);
  });

  testWidgets('a failed save shows the inline error', (tester) async {
    await pump(tester);
    rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': false, 'error': 'nope'});

    await tester.tap(find.byKey(const ValueKey('security.enabled')));
    await tester.pumpAndSettle();
    await tapDigits(tester, '123456');
    await tester.pumpAndSettle();
    await tapDigits(tester, '123456');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('security.error')), findsOneWidget);
    expect(controller.enabled, isFalse);
  });

  group('paired devices (BladeWatch-xfb5, moved from the Dashboard)', () {
    testWidgets('without a pairing channel there is no pairing section at all', (tester) async {
      await pump(tester);
      expect(find.byKey(const ValueKey('dashboard.pair')), findsNothing);
      expect(find.text('Paired devices'), findsNothing);
    });

    testWidgets('lock off: Pair a device opens the pairing dialog with no PIN prompt', (tester) async {
      final pairing = FakePlatformChannel()
        ..stub('pairing', 'mint', {'payload': 'qr-text', 'expiresAt': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch})
        ..stub('pairing', 'list', {'companions': []});
      await pump(tester, pairing: PairingChannel(pairing));

      await tester.tap(find.byKey(const ValueKey('dashboard.pair')));
      await tester.pumpAndSettle();

      expect(find.byType(PairingDialog), findsOneWidget);
      expect(pairing.calls.map((c) => c.method), containsAll(['mint', 'list']));
    });

    // BladeWatch-hr6r: without this gate, anyone in the car could pair their own phone and unlock
    // the companion with their own fingerprint -- the whole point of the Settings PIN lock. This
    // is the SAME SettingsLockController the switch above uses, not an injected fake.
    testWidgets('lock on: Pair a device asks for the PIN first; a correct PIN opens it', (tester) async {
      final pairing = FakePlatformChannel()
        ..stub('pairing', 'mint', {'payload': 'qr-text', 'expiresAt': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch})
        ..stub('pairing', 'list', {'companions': []});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});
      await pump(tester, enabled: true, pairing: PairingChannel(pairing));

      await tester.tap(find.byKey(const ValueKey('dashboard.pair')));
      await tester.pumpAndSettle();
      expect(find.byType(PairingDialog), findsNothing, reason: 'the PIN dialog is up first');
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();

      expect(find.byType(PairingDialog), findsOneWidget);
    });

    testWidgets('lock on: cancelling the PIN leaves the pairing dialog closed', (tester) async {
      final pairing = FakePlatformChannel()..stub('pairing', 'list', {'companions': []});
      await pump(tester, enabled: true, pairing: PairingChannel(pairing));

      await tester.tap(find.byKey(const ValueKey('dashboard.pair')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(PairingDialog), findsNothing);
      expect(pairing.calls.map((c) => c.method), isNot(contains('mint')));
    });

    testWidgets('lists what can reach the car, and removing one asks for confirmation first', (tester) async {
      final pairing = FakePlatformChannel()
        ..stub('pairing', 'list', {
          'companions': [
            <Object?, Object?>{'id': 'a1', 'name': 'Owner phone', 'pairedAt': DateTime(2026, 9, 24).millisecondsSinceEpoch},
            <Object?, Object?>{'id': 'b2', 'name': 'Living room TV', 'pairedAt': DateTime(2026, 10, 4).millisecondsSinceEpoch},
          ],
        })
        ..stub('pairing', 'revoke', {'status': 'ok'});
      await pump(tester, pairing: PairingChannel(pairing));

      expect(find.text('Owner phone'), findsOneWidget);
      expect(find.text('Living room TV'), findsOneWidget);
      expect(find.textContaining('Oct 4'), findsOneWidget);

      final remove = find.descendant(of: find.byKey(const ValueKey('dashboard.device.b2')), matching: find.byType(TextButton));
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(pairing.calls.map((c) => c.method), isNot(contains('revoke')), reason: 'nothing is removed before the owner confirms');
      await tester.tap(find.byKey(const ValueKey('pairing.removeConfirm')));
      await tester.pumpAndSettle();
      expect(pairing.calls.where((c) => c.method == 'revoke').single.args, {'id': 'b2'});
    });

    // BladeWatch-hr6r: removing a paired device needs the PIN too, same as pairing a new one.
    testWidgets('lock on: removing a device asks for the PIN first', (tester) async {
      final pairing = FakePlatformChannel()
        ..stub('pairing', 'list', {
          'companions': [
            <Object?, Object?>{'id': 'a1', 'name': 'Owner phone', 'pairedAt': DateTime(2026, 9, 24).millisecondsSinceEpoch},
          ],
        })
        ..stub('pairing', 'revoke', {'status': 'ok'});
      await pump(tester, enabled: true, pairing: PairingChannel(pairing));

      final remove = find.descendant(of: find.byKey(const ValueKey('dashboard.device.a1')), matching: find.byType(TextButton));
      await tester.tap(remove);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pairing.removeConfirm')), findsNothing, reason: 'the PIN dialog is up first, not the confirm');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(pairing.calls.map((c) => c.method), isNot(contains('revoke')));
    });

    testWidgets('says when there are none paired yet', (tester) async {
      final empty = FakePlatformChannel()..stub('pairing', 'list', {'companions': []});
      await pump(tester, pairing: PairingChannel(empty));
      expect(find.text('No devices paired yet.'), findsOneWidget);
    });

    testWidgets('says when the car does not answer', (tester) async {
      final unreachable = FakePlatformChannel()
        ..stubError('pairing', 'list', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
      await pump(tester, pairing: PairingChannel(unreachable));
      expect(find.byKey(const ValueKey('dashboard.devicesError')), findsOneWidget);
    });
  });
}
