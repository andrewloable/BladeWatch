import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/screens/settings/settings_lock_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

/// BladeWatch-hr6r: the Settings PIN lock controller -- fail-closed caching, PIN checking
/// (including the lockout mapping), and the set/disable/relock lifecycle.
void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel platform;
  late SettingsLockController controller;
  late BuildContext ctx;

  setUp(() {
    rpc = FakeRpcClient();
    platform = FakePlatformChannel();
    platform.stub('prefs', 'setSettingsLockKnown', null); // written on every refresh()/setPin()/disable()
    controller = SettingsLockController(settingsService: SettingsServiceClient(rpc), prefs: PrefsChannel(platform));
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
      await controller.refresh();
      expect(controller.enabled, isTrue);
      expect(platform.calls.where((c) => c.group == 'prefs' && c.method == 'setSettingsLockKnown').last.args, {'value': true});
    });

    test('failure falls back to the cached value', () async {
      platform.stub('prefs', 'getSettingsLockKnown', true);
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));
      await controller.refresh();
      expect(controller.enabled, isTrue);
    });

    test('failure with no cached value defaults to disabled', () async {
      platform.stub('prefs', 'getSettingsLockKnown', null);
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));
      await controller.refresh();
      expect(controller.enabled, isFalse);
    });
  });

  group('admit', () {
    testWidgets('the lock off admits at once with no dialog', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': false, 'retryAfterMs': '0'});

      final ok = await controller.admit(ctx);

      expect(ok, isTrue);
      expect(controller.unlocked, isFalse); // never needed to unlock
    });

    testWidgets('already unlocked this session admits at once, even if the lock is on', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});
      final first = controller.admit(ctx); // shows the dialog -- its Future resolves once the PIN is entered below
      await tester.pumpAndSettle();
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();
      expect(await first, isTrue); // unlocked
      rpc.calls.clear();

      final ok = await controller.admit(ctx);

      expect(ok, isTrue);
      expect(rpc.calls.where((c) => c.method == 'VerifySettingsPin'), isEmpty, reason: 'no second PIN check needed');
    });

    testWidgets('lock on, correct PIN unlocks', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});

      final future = controller.admit(ctx);
      await tester.pumpAndSettle();
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();

      expect(await future, isTrue);
      expect(controller.unlocked, isTrue);
    });

    testWidgets('Cancel leaves it locked', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});

      final future = controller.admit(ctx);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await future, isFalse);
      expect(controller.unlocked, isFalse);
    });

    testWidgets('daemon unreachable with a cached-enabled lock still shows the dialog and reports unreachable', (tester) async {
      await pump(tester);
      platform.stub('prefs', 'getSettingsLockKnown', true);
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));
      rpc.stubError('SettingsService', 'VerifySettingsPin', const ConnectError('unavailable', 'boom'));

      final future = controller.admit(ctx);
      await tester.pumpAndSettle();
      expect(find.text(AppLocalizations.of(ctx)!.settings_lock_enter_title), findsOneWidget);

      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();

      expect(find.text(AppLocalizations.of(ctx)!.settings_lock_unreachable), findsOneWidget);
      // Settings must not have opened.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await future, isFalse);
    });

    testWidgets('daemon unreachable with a cached-disabled lock admits at once', (tester) async {
      await pump(tester);
      platform.stub('prefs', 'getSettingsLockKnown', false);
      rpc.stubError('SettingsService', 'GetSettingsLock', const ConnectError('unavailable', 'boom'));

      final ok = await controller.admit(ctx);

      expect(ok, isTrue);
    });
  });

  group('check', () {
    testWidgets('maps ok to a successful PinCheck', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});

      final r = await controller.check(ctx, '123456');

      expect(r.ok, isTrue);
      expect(r.error, isNull);
      expect(r.retryAfter, isNull);
    });

    testWidgets('maps a wrong pin to the attempts-left plural message', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': false, 'retryAfterMs': '0', 'attemptsLeft': 3});

      final r = await controller.check(ctx, '000000');

      expect(r.ok, isFalse);
      expect(r.error, AppLocalizations.of(ctx)!.settings_lock_wrong_pin(3));
      expect(r.retryAfter, isNull);
    });

    testWidgets('maps a lockout to a formatted retry-after message and a Duration', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': false, 'retryAfterMs': '60000', 'attemptsLeft': 0});

      final r = await controller.check(ctx, '000000');

      expect(r.ok, isFalse);
      expect(r.error, AppLocalizations.of(ctx)!.settings_lock_locked_out('1m'));
      expect(r.retryAfter, const Duration(minutes: 1));
    });

    testWidgets('formats an hour-long lockout as 1h', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': false, 'retryAfterMs': '3600000', 'attemptsLeft': 0});

      final r = await controller.check(ctx, '000000');

      expect(r.error, AppLocalizations.of(ctx)!.settings_lock_locked_out('1h'));
    });

    testWidgets('an RPC failure maps to the unreachable message', (tester) async {
      await pump(tester);
      rpc.stubError('SettingsService', 'VerifySettingsPin', const ConnectError('unavailable', 'boom'));

      final r = await controller.check(ctx, '123456');

      expect(r.ok, isFalse);
      expect(r.error, AppLocalizations.of(ctx)!.settings_lock_unreachable);
    });
  });

  group('setPin / disable / relock', () {
    test('setPin success enables the lock, unlocks, and caches true', () async {
      rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': true, 'error': ''});
      final ok = await controller.setPin('123456');
      expect(ok, isTrue);
      expect(controller.enabled, isTrue);
      expect(controller.unlocked, isTrue);
      expect(platform.calls.last.args, {'value': true});
    });

    test('setPin failure leaves state unchanged', () async {
      rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': false, 'error': 'bad'});
      final ok = await controller.setPin('123456');
      expect(ok, isFalse);
      expect(controller.enabled, isFalse);
    });

    test('setPin exception returns false', () async {
      rpc.stubError('SettingsService', 'SetSettingsLock', const ConnectError('unavailable', 'boom'));
      expect(await controller.setPin('123456'), isFalse);
    });

    test('disable success turns the lock off and caches false', () async {
      rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': true, 'error': ''});
      await controller.setPin('123456');
      final ok = await controller.disable();
      expect(ok, isTrue);
      expect(controller.enabled, isFalse);
      expect(platform.calls.last.args, {'value': false});
    });

    test('disable failure leaves enabled unchanged', () async {
      rpc.stubJson('SettingsService', 'SetSettingsLock', {'success': false, 'error': 'bad'});
      final ok = await controller.disable();
      expect(ok, isFalse);
    });

    testWidgets('relock clears unlocked and is idempotent', (tester) async {
      await pump(tester);
      rpc.stubJson('SettingsService', 'GetSettingsLock', {'enabled': true, 'retryAfterMs': '0'});
      rpc.stubJson('SettingsService', 'VerifySettingsPin', {'ok': true, 'retryAfterMs': '0', 'attemptsLeft': 5});
      final future = controller.admit(ctx);
      await tester.pumpAndSettle();
      await tapDigits(tester, '123456');
      await tester.pumpAndSettle();
      await future;
      expect(controller.unlocked, isTrue);

      controller.relock();
      expect(controller.unlocked, isFalse);
      controller.relock(); // idempotent -- no error, nothing to assert beyond "didn't throw"
      expect(controller.unlocked, isFalse);
    });
  });
}
