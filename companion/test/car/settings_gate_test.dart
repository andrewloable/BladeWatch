import 'dart:async';
import 'dart:io';

import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/car/settings_gate.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/tv.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

/// BladeWatch-hr6r: the companion's Settings PIN lock gate -- fail-closed caching and PIN
/// checking (wrong PIN, lockout, car unreachable). On top of car_store_test.dart's own coverage
/// of the cache field itself.
void main() {
  late FakeRpcClient rpc;
  late CarStore store;
  late FakeBiometrics biometrics;
  late SettingsGate gate;
  late BuildContext ctx;

  setUp(() {
    rpc = FakeRpcClient();
    store = CarStore(File('${Directory.systemTemp.createTempSync('settings-gate').path}/store.json'));
    biometrics = FakeBiometrics();
    gate = SettingsGate(settingsService: SettingsServiceClient(rpc), store: store, biometrics: biometrics);
  });

  Future<void> pump(WidgetTester tester, {bool tv = false}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TrScope(tr: testTr, child: tv ? DpadFieldExit(child: child!) : child!),
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
  }

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.widgetWithText(OutlinedButton, d));
      await tester.pump();
    }
  }

  group('refresh', () {
    test('success updates enabled and writes the cache', () async {
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      await gate.refresh();
      expect(gate.enabled, isTrue);
      expect(store.settingsLockKnown, isTrue);
    });

    test('failure falls back to the cached value', () async {
      store.settingsLockKnown = true;
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));
      await gate.refresh();
      expect(gate.enabled, isTrue);
    });

    test('failure with no cached value defaults to disabled', () async {
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));
      await gate.refresh();
      expect(gate.enabled, isFalse);
    });
  });

  group('admit', () {
    testWidgets('the lock off admits at once with no dialog', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': false, 'retryAfterMs': '0'});

      expect(await gate.admit(ctx), isTrue);
      expect(gate.unlocked, isFalse);
    });

    testWidgets('already unlocked this session admits at once, even if the lock is on', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});
      final first = gate.admit(ctx);
      await tester.pumpAndSettle();
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();
      expect(await first, isTrue);
      rpc.calls.clear();

      expect(await gate.admit(ctx), isTrue);
      expect(rpc.calls.where((c) => c.method == 'VerifySettingsPin'), isEmpty);
    });

    testWidgets('lock on, correct PIN unlocks', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});

      final future = gate.admit(ctx);
      await tester.pumpAndSettle();
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();

      expect(await future, isTrue);
      expect(gate.unlocked, isTrue);
    });

    testWidgets('Cancel leaves it locked', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});

      final future = gate.admit(ctx);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();

      expect(await future, isFalse);
      expect(gate.unlocked, isFalse);
    });

    testWidgets('car unreachable with a cached-enabled lock still shows the dialog and reports unreachable', (tester) async {
      await pump(tester);
      store.settingsLockKnown = true;
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));
      rpc.stubError('SettingsService', 'VerifySettingsPin', const ConnectError('unavailable', 'boom'));

      final future = gate.admit(ctx);
      await tester.pumpAndSettle();
      expect(find.text(t('companion.settings_lock_enter_title')), findsOneWidget);

      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();
      expect(find.text(t('companion.settings_lock_unreachable')), findsOneWidget);

      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(await future, isFalse);
    });

    testWidgets('car unreachable with a cached-disabled lock admits at once', (tester) async {
      await pump(tester);
      store.settingsLockKnown = false;
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));

      expect(await gate.admit(ctx), isTrue);
    });
  });

  group('check', () {
    testWidgets('maps ok to a successful PinCheck', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});

      final r = await gate.check(ctx, '123456');

      expect(r.ok, isTrue);
      expect(r.error, isNull);
      expect(r.retryAfter, isNull);
    });

    testWidgets('maps a wrong pin to the attempts-left message', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': false, 'retryAfterMs': '0', 'attemptsLeft': 3});

      final r = await gate.check(ctx, '000000');

      expect(r.ok, isFalse);
      expect(r.error, t('companion.settings_lock_wrong_pin', {'count': 3}));
      expect(r.retryAfter, isNull);
    });

    testWidgets('maps a lockout to a formatted retry-after message and a Duration', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': false, 'retryAfterMs': '60000', 'attemptsLeft': 0});

      final r = await gate.check(ctx, '000000');

      expect(r.ok, isFalse);
      expect(r.error, t('companion.settings_lock_locked_out', {'time': '1m'}));
      expect(r.retryAfter, const Duration(minutes: 1));
    });

    testWidgets('an RPC failure maps to the unreachable message', (tester) async {
      await pump(tester);
      rpc.stubError('SettingsService', 'VerifySettingsPin', const ConnectError('unavailable', 'boom'));

      final r = await gate.check(ctx, '123456');

      expect(r.ok, isFalse);
      expect(r.error, t('companion.settings_lock_unreachable'));
    });
  });

  group('biometrics (BladeWatch-hr6r.6)', () {
    testWidgets('opted in, available, and it succeeds: unlocks with no PIN dialog at all', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      store.biometricUnlockEnabled = true;
      biometrics.isAvailable = true;
      biometrics.authResult = true;

      expect(await gate.admit(ctx), isTrue);
      expect(gate.unlocked, isTrue);
      expect(biometrics.authenticateCalls, 1);
      expect(rpc.calls.where((c) => c.method == 'VerifySettingsPin'), isEmpty, reason: 'the PIN was never needed');
    });

    testWidgets('opted in and available, but it fails: falls back to the PIN dialog with a retry button; retry can still succeed',
        (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      store.biometricUnlockEnabled = true;
      biometrics.isAvailable = true;
      biometrics.authResult = false;

      final future = gate.admit(ctx);
      await tester.pumpAndSettle();
      expect(find.text(t('companion.settings_lock_enter_title')), findsOneWidget, reason: 'biometrics failed, PIN dialog comes up');
      expect(biometrics.authenticateCalls, 1);
      final retry = find.byKey(const ValueKey('pinPad.biometricRetry'));
      expect(retry, findsOneWidget);

      biometrics.authResult = true;
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(await future, isTrue);
      expect(gate.unlocked, isTrue);
      expect(biometrics.authenticateCalls, 2);
    });

    testWidgets('not opted in: biometrics are never tried, even though the device has them, and there is no retry button', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});
      biometrics.isAvailable = true; // the device could, but this device was never opted in

      final future = gate.admit(ctx);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pinPad.biometricRetry')), findsNothing);
      expect(biometrics.authenticateCalls, 0);
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();

      expect(await future, isTrue);
      expect(biometrics.authenticateCalls, 0, reason: 'still never tried, not even as a side effect of the PIN succeeding');
    });

    testWidgets('opted in but currently unavailable: straight to the PIN dialog, no retry button, never tried', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});
      store.biometricUnlockEnabled = true;
      biometrics.isAvailable = false;

      final future = gate.admit(ctx);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pinPad.biometricRetry')), findsNothing);
      expect(biometrics.authenticateCalls, 0);
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();

      expect(await future, isTrue);
    });

    testWidgets('the lock off never calls biometrics at all', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': false, 'retryAfterMs': '0'});
      store.biometricUnlockEnabled = true;
      biometrics.isAvailable = true;

      expect(await gate.admit(ctx), isTrue);
      expect(biometrics.authenticateCalls, 0);
    });
  });

  test('relock clears unlocked and is idempotent', () {
    // No need to actually unlock first -- relock() just sets a bool; this proves it never throws.
    gate.relock();
    expect(gate.unlocked, isFalse);
    gate.relock();
    expect(gate.unlocked, isFalse);
  });

  testWidgets('after relock, the next admit shows the PIN dialog again -- it is really relocked, '
      'not just visually switched', (tester) async {
    await pump(tester);
    rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
    rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});

    final first = gate.admit(ctx);
    await tester.pumpAndSettle();
    await tapDigits(tester, '123456');
    await tester.pumpAndSettle();
    expect(await first, isTrue);
    expect(gate.unlocked, isTrue);

    gate.relock();
    expect(gate.unlocked, isFalse);

    final second = gate.admit(ctx);
    await tester.pumpAndSettle();
    expect(find.text(t('companion.settings_lock_enter_title')), findsOneWidget, reason: 'the dialog is asked for again');
    await tapDigits(tester, '123456');
    await tester.pumpAndSettle();
    expect(await second, isTrue);
  });

  // BladeWatch-hr6r: on a TV, DpadFieldExit intercepts up/down everywhere (tv_test.dart) -- prove
  // it does not strand the remote inside the PIN pad's digit grid the way it used to in text fields.
  testWidgets('on a TV, up and down move across the digit grid instead of getting stuck', (tester) async {
    await pump(tester, tv: true);
    rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});

    unawaited(gate.admit(ctx));
    await tester.pumpAndSettle();

    FocusNode digit(String d) =>
        Focus.of(tester.element(find.descendant(of: find.widgetWithText(OutlinedButton, d), matching: find.byType(Text))));
    digit('1').requestFocus();
    await tester.pump();
    expect(digit('1').hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(digit('4').hasPrimaryFocus, isTrue, reason: 'down from the top row reaches the row below it');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(digit('1').hasPrimaryFocus, isTrue, reason: 'and up comes back');
  });
}
