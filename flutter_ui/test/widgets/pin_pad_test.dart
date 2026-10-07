import 'dart:async';

import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_theme/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-hr6r: the 6-digit PIN pad shared by the in-car UI and the companion.
const _strings = PinPadStrings(
  title: 'Enter PIN',
  subtitle: 'Enter your 6-digit PIN',
  cancel: 'Cancel',
  backspaceTooltip: 'Backspace',
  newPinTitle: 'Set a new PIN',
  confirmPinTitle: 'Confirm your new PIN',
  mismatch: "PINs didn't match",
);

Widget _app(Widget child) => MaterialApp(
      theme: BladeWatchTheme.dark(),
      builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: c!),
      home: Scaffold(body: Center(child: child)),
    );

Future<void> _tapDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.widgetWithText(OutlinedButton, d));
    await tester.pump();
  }
}

void main() {
  group('PinPad', () {
    testWidgets('tapping six digits fires onCompleted with the entered PIN', (tester) async {
      String? completed;
      await tester.pumpWidget(_app(PinPad(backspaceTooltip: 'Backspace', onCompleted: (p) => completed = p)));

      await _tapDigits(tester, '135792');

      expect(completed, '135792');
    });

    testWidgets('backspace removes the last digit before completion', (tester) async {
      String? completed;
      await tester.pumpWidget(_app(PinPad(backspaceTooltip: 'Backspace', onCompleted: (p) => completed = p)));

      await _tapDigits(tester, '1234'); // 4 digits in
      await tester.tap(find.byTooltip('Backspace')); // -> 3 digits (123)
      await tester.pump();
      await _tapDigits(tester, '9999'); // 123 + 9999 = 1239999, but completes at the 6th digit

      expect(completed, '123999');
    });

    testWidgets('hardware digit keys and backspace work while the pad has focus', (tester) async {
      String? completed;
      await tester.pumpWidget(_app(PinPad(backspaceTooltip: 'Backspace', onCompleted: (p) => completed = p)));
      await tester.pump(); // let autofocus land

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace); // -> 12
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad3);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad4);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad5);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad6);
      await tester.pump();

      expect(completed, '123456');
    });

    // A real BRAVIA Android TV, 2026-10-07: the first D-pad press after opening the dialog
    // jumped clean past every digit key to Cancel -- autofocus had landed on the grid's own
    // wrapping Focus (skipTraversal: true, so directional focus had no real target inside it to
    // move from), not on a digit. No widget test had caught this because every one of them that
    // checked D-pad movement called requestFocus() on a digit itself first, which skips straight
    // past the real bug. This one does not: it only pumps, the way a freshly opened dialog does.
    testWidgets('fresh autofocus lands on digit 1, not the grid itself, so a D-pad has somewhere real to move from', (tester) async {
      await tester.pumpWidget(_app(PinPad(backspaceTooltip: 'Backspace', onCompleted: (_) {})));
      await tester.pump(); // let autofocus land, same as the hardware-keys test above

      FocusNode digit(String d) => Focus.of(tester.element(find.descendant(of: find.widgetWithText(OutlinedButton, d), matching: find.byType(Text))));
      expect(digit('1').hasPrimaryFocus, isTrue, reason: 'a concrete digit key, not the wrapping Focus, holds focus on open');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(digit('4').hasPrimaryFocus, isTrue, reason: 'down from the top row reaches the row below it, not Cancel');
    });

    testWidgets('showError sets the error text and clears the entered digits', (tester) async {
      final key = GlobalKey<PinPadState>();
      await tester.pumpWidget(_app(PinPad(key: key, backspaceTooltip: 'Backspace', onCompleted: (_) {})));

      await _tapDigits(tester, '123');
      key.currentState!.showError('Wrong PIN. 4 attempts left.');
      await tester.pump();

      expect(find.text('Wrong PIN. 4 attempts left.'), findsOneWidget);
      // The digits were cleared: completing now needs a fresh 6, not 3 more.
      String? completed;
      await tester.pumpWidget(_app(PinPad(key: key, backspaceTooltip: 'Backspace', onCompleted: (p) => completed = p)));
      await _tapDigits(tester, '000');
      expect(completed, isNull);
      await _tapDigits(tester, '000');
      expect(completed, '000000');
    });

    testWidgets('clear empties the digits without touching the error', (tester) async {
      final key = GlobalKey<PinPadState>();
      await tester.pumpWidget(_app(PinPad(key: key, backspaceTooltip: 'Backspace', onCompleted: (_) {})));
      key.currentState!.showError('Wrong PIN');
      await tester.pump();
      key.currentState!.clear();
      await tester.pump();

      expect(find.text('Wrong PIN'), findsOneWidget);
    });

    testWidgets('disableFor blocks every key until the duration elapses', (tester) async {
      var completions = 0;
      final key = GlobalKey<PinPadState>();
      await tester.pumpWidget(_app(PinPad(key: key, backspaceTooltip: 'Backspace', onCompleted: (_) => completions++)));
      key.currentState!.disableFor(const Duration(seconds: 60));
      await tester.pump();

      await _tapDigits(tester, '123456'); // every tap is a no-op while disabled
      expect(completions, 0);

      await tester.pump(const Duration(seconds: 60)); // the lockout ends
      await _tapDigits(tester, '123456');
      expect(completions, 1);
    });

    testWidgets('leading is rendered in the bottom-left key slot', (tester) async {
      await tester.pumpWidget(_app(PinPad(
        backspaceTooltip: 'Backspace',
        onCompleted: (_) {},
        leading: const Icon(Icons.fingerprint, key: ValueKey('bio')),
      )));

      expect(find.byKey(const ValueKey('bio')), findsOneWidget);
    });

    testWidgets('a subtitle is shown above the dots when given', (tester) async {
      await tester.pumpWidget(_app(PinPad(
        subtitle: 'Enter your PIN',
        backspaceTooltip: 'Backspace',
        onCompleted: (_) {},
      )));

      expect(find.text('Enter your PIN'), findsOneWidget);
    });
  });

  group('showPinDialog', () {
    testWidgets('a correct PIN pops true', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      bool? result;
      unawaited(showPinDialog(
        ctx,
        strings: _strings,
        check: (pin) async => (ok: pin == '123456', error: pin == '123456' ? null : 'Wrong PIN', retryAfter: null),
      ).then((r) => result = r));
      await tester.pumpAndSettle();

      await _tapDigits(tester, '123456');
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('a wrong pin shows the error, clears the digits, and the dialog stays open', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      unawaited(showPinDialog(
        ctx,
        strings: _strings,
        check: (pin) async => (ok: false, error: 'Wrong PIN. 4 attempts left.', retryAfter: null),
      ));
      await tester.pumpAndSettle();

      await _tapDigits(tester, '000000');
      await tester.pumpAndSettle();

      expect(find.text('Wrong PIN. 4 attempts left.'), findsOneWidget);
      expect(find.text(_strings.title), findsOneWidget); // still open
    });

    testWidgets('a lockout disables the pad for retryAfter', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      var checks = 0;
      unawaited(showPinDialog(
        ctx,
        strings: _strings,
        check: (pin) async {
          checks++;
          return (ok: false, error: 'Locked out for 60s', retryAfter: const Duration(seconds: 60));
        },
      ));
      await tester.pumpAndSettle();

      await _tapDigits(tester, '000000');
      await tester.pumpAndSettle();
      expect(checks, 1);

      await _tapDigits(tester, '123456'); // disabled: no second check while locked out
      await tester.pump();
      expect(checks, 1);

      await tester.pump(const Duration(seconds: 60));
      await _tapDigits(tester, '123456');
      await tester.pump();
      expect(checks, 2);
    });

    testWidgets('Cancel pops false', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      bool? result;
      unawaited(showPinDialog(ctx, strings: _strings, check: (_) async => (ok: true, error: null, retryAfter: null))
          .then((r) => result = r));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });

  group('showNewPinDialog', () {
    testWidgets('matching entries return the pin', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      String? result;
      unawaited(showNewPinDialog(ctx, strings: _strings).then((r) => result = r));
      await tester.pumpAndSettle();
      expect(find.text(_strings.newPinTitle), findsOneWidget);

      await _tapDigits(tester, '246810');
      await tester.pumpAndSettle();
      expect(find.text(_strings.confirmPinTitle), findsOneWidget);

      await _tapDigits(tester, '246810');
      await tester.pumpAndSettle();

      expect(result, '246810');
    });

    testWidgets('a mismatch shows the mismatch error and starts over at the first entry', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      String? result;
      unawaited(showNewPinDialog(ctx, strings: _strings).then((r) => result = r));
      await tester.pumpAndSettle();

      await _tapDigits(tester, '111111');
      await tester.pumpAndSettle();
      expect(find.text(_strings.confirmPinTitle), findsOneWidget);

      await _tapDigits(tester, '222222'); // does not match
      await tester.pumpAndSettle();

      expect(find.text(_strings.mismatch), findsOneWidget);
      expect(find.text(_strings.newPinTitle), findsOneWidget); // back to the first entry
      expect(result, isNull);

      // A fresh matching pair now succeeds.
      await _tapDigits(tester, '999999');
      await tester.pumpAndSettle();
      await _tapDigits(tester, '999999');
      await tester.pumpAndSettle();
      expect(result, '999999');
    });

    testWidgets('Cancel returns null', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      String? result = 'not yet';
      unawaited(showNewPinDialog(ctx, strings: _strings).then((r) => result = r));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
