import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'hud_theme.dart';
import 'hud_widgets.dart';

/// What a PIN check answered. [ok] true unlocks; otherwise [error] (already localized by the
/// caller) is shown and, when the car reports a lockout, [retryAfter] disables the pad for that
/// long. A plain record, not a class, so this package never needs an RPC type of its own.
typedef PinCheck = ({bool ok, String? error, Duration? retryAfter});

/// Every user-visible string [PinPad] and its dialogs need. Both apps load strings differently
/// (in-car: gen-l10n ARB; companion: JSON catalogs), so this package holds no literal text —
/// every string the pad shows comes from here.
class PinPadStrings {
  final String title;
  final String? subtitle;
  final String cancel;
  final String backspaceTooltip;

  // The "set a new PIN" flow: enter, then confirm.
  final String newPinTitle;
  final String confirmPinTitle;
  final String mismatch;

  const PinPadStrings({
    required this.title,
    this.subtitle,
    required this.cancel,
    required this.backspaceTooltip,
    required this.newPinTitle,
    required this.confirmPinTitle,
    required this.mismatch,
  });
}

const double _keySize = 56;
const double _keyGap = 10;
const List<List<int?>> _digitRows = [
  [1, 2, 3],
  [4, 5, 6],
  [7, 8, 9],
];
const int _pinLength = 6;

final Map<LogicalKeyboardKey, int> _keyToDigit = {
  LogicalKeyboardKey.digit0: 0,
  LogicalKeyboardKey.digit1: 1,
  LogicalKeyboardKey.digit2: 2,
  LogicalKeyboardKey.digit3: 3,
  LogicalKeyboardKey.digit4: 4,
  LogicalKeyboardKey.digit5: 5,
  LogicalKeyboardKey.digit6: 6,
  LogicalKeyboardKey.digit7: 7,
  LogicalKeyboardKey.digit8: 8,
  LogicalKeyboardKey.digit9: 9,
  LogicalKeyboardKey.numpad0: 0,
  LogicalKeyboardKey.numpad1: 1,
  LogicalKeyboardKey.numpad2: 2,
  LogicalKeyboardKey.numpad3: 3,
  LogicalKeyboardKey.numpad4: 4,
  LogicalKeyboardKey.numpad5: 5,
  LogicalKeyboardKey.numpad6: 6,
  LogicalKeyboardKey.numpad7: 7,
  LogicalKeyboardKey.numpad8: 8,
  LogicalKeyboardKey.numpad9: 9,
};

/// Six dots, a 3x4 keypad (1-9, an optional [leading] slot, 0, backspace) and an error line — the
/// PIN entry both apps share. Owns no RPC and no navigation: [onCompleted] fires with the 6-digit
/// string once entered, and the caller (usually [showPinDialog]/[showNewPinDialog]) decides what
/// that means. [clear], [showError] and [disableFor] on the state (reach it with a
/// `GlobalKey<PinPadState>`) are how a caller reports the result of checking a PIN.
class PinPad extends StatefulWidget {
  final String? subtitle;
  final String backspaceTooltip;
  final ValueChanged<String> onCompleted;

  /// Rendered in the otherwise-empty bottom-left key, e.g. the companion's biometric retry button.
  final Widget? leading;

  const PinPad({
    super.key,
    this.subtitle,
    required this.backspaceTooltip,
    required this.onCompleted,
    this.leading,
  });

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  final List<int> _digits = [];
  String? _error;
  bool _disabled = false;
  Timer? _disableTimer;

  /// Empties the entered digits without touching the error line.
  void clear() => setState(() => _digits.clear());

  /// Shows [message] and clears the entered digits — the normal reaction to a wrong PIN.
  void showError(String message) => setState(() {
        _error = message;
        _digits.clear();
      });

  /// Disables every key for [duration]; the error already on screen stays visible throughout.
  /// Driven entirely by the [Timer] firing, not a wall-clock comparison: `DateTime.now()` is real
  /// time even inside a widget test's faked `Timer`s, so comparing against it would never flip
  /// back in a test that advances time with `tester.pump(duration)`.
  void disableFor(Duration duration) {
    _disableTimer?.cancel();
    setState(() => _disabled = true);
    _disableTimer = Timer(duration, () {
      if (mounted) setState(() => _disabled = false);
    });
  }

  @override
  void dispose() {
    _disableTimer?.cancel();
    super.dispose();
  }

  void _tapDigit(int digit) {
    if (_disabled || _digits.length >= _pinLength) return;
    setState(() {
      _error = null;
      _digits.add(digit);
    });
    if (_digits.length == _pinLength) {
      final pin = _digits.join();
      widget.onCompleted(pin);
    }
  }

  void _backspace() {
    if (_disabled || _digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final digit = _keyToDigit[event.logicalKey];
    if (digit != null) {
      _tapDigit(digit);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Focus(
      // Not autofocus: see digit 1's own autofocus below, and its doc comment, for why focusing
      // THIS node (skipTraversal: true, so it is never itself a D-pad target) left Android TV
      // with no real focus to move away from.
      skipTraversal: true,
      onKeyEvent: _handleKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.subtitle != null) ...[
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: hudText(12, hud.textSecondary, lineHeight: 16),
            ),
            const SizedBox(height: 16),
          ],
          Semantics(
            container: true,
            value: '${_digits.length}/$_pinLength',
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _pinLength; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    _Dot(filled: i < _digits.length, hud: hud),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: _error == null
                ? null
                : Center(
                    child: Text(
                      _error!,
                      key: const ValueKey('pinPad.error'),
                      textAlign: TextAlign.center,
                      style: hudText(12, hud.magenta, lineHeight: 16, weight: FontWeight.w700),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          for (final row in _digitRows) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: _keyGap),
                  _DigitKey(
                    digit: row[i]!,
                    disabled: _disabled,
                    hud: hud,
                    onTap: () => _tapDigit(row[i]!),
                    autofocus: row[i] == 1,
                  ),
                ],
              ],
            ),
            const SizedBox(height: _keyGap),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: _keySize, height: _keySize, child: Center(child: widget.leading)),
              const SizedBox(width: _keyGap),
              _DigitKey(digit: 0, disabled: _disabled, hud: hud, onTap: () => _tapDigit(0)),
              const SizedBox(width: _keyGap),
              _BackspaceKey(
                disabled: _disabled || _digits.isEmpty,
                hud: hud,
                tooltip: widget.backspaceTooltip,
                onTap: _backspace,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool filled;
  final BwHud hud;

  const _Dot({required this.filled, required this.hud});

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? hud.accent : Colors.transparent,
          border: Border.all(color: filled ? hud.accent : hud.panelBorder),
        ),
      );
}

ButtonStyle _keyStyle(BwHud hud, {required bool disabled}) => OutlinedButton.styleFrom(
      backgroundColor: hud.panel,
      foregroundColor: disabled ? hud.textSecondary : hud.textPrimary,
      side: BorderSide(color: disabled ? hud.panelBorder.withValues(alpha: 0.4) : hud.panelBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BwHud.radiusPanel)),
      padding: EdgeInsets.zero,
      minimumSize: const Size(_keySize, _keySize),
      fixedSize: const Size(_keySize, _keySize),
    );

class _DigitKey extends StatelessWidget {
  final int digit;
  final bool disabled;
  final BwHud hud;
  final VoidCallback onTap;

  /// True only for digit 1 (see [PinPad.build]): a real focus target a D-pad can land on and
  /// move away from. Autofocusing the grid's own wrapping `Focus` instead -- which has
  /// `skipTraversal: true` -- left Android TV's directional focus with nowhere sensible to go:
  /// one press of any arrow jumped clean over every digit key to Cancel, on the actual hardware
  /// (a Sony BRAVIA; no widget test had caught it, because every test that checked D-pad movement
  /// called `requestFocus()` on a digit itself first instead of starting from a fresh dialog).
  final bool autofocus;

  const _DigitKey({required this.digit, required this.disabled, required this.hud, required this.onTap, this.autofocus = false});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$digit',
        button: true,
        excludeSemantics: true,
        child: OutlinedButton(
          autofocus: autofocus,
          onPressed: disabled ? null : onTap,
          style: _keyStyle(hud, disabled: disabled),
          child: Text('$digit', style: hudText(20, disabled ? hud.textSecondary : hud.textPrimary, lineHeight: 24, weight: FontWeight.w700)),
        ),
      );
}

class _BackspaceKey extends StatelessWidget {
  final bool disabled;
  final BwHud hud;
  final String tooltip;
  final VoidCallback onTap;

  const _BackspaceKey({required this.disabled, required this.hud, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          label: tooltip,
          button: true,
          excludeSemantics: true,
          child: OutlinedButton(
            onPressed: disabled ? null : onTap,
            style: _keyStyle(hud, disabled: disabled),
            child: Icon(Icons.backspace_outlined, size: 20, color: disabled ? hud.textSecondary : hud.textPrimary),
          ),
        ),
      );
}

/// Shows the PIN pad to unlock something already protected by a PIN. Awaits [check] on every
/// 6-digit entry; a correct PIN pops `true`, Cancel pops `false`. [leading] is passed straight
/// through to [PinPad] (the companion's biometric retry button).
///
/// Uses the root navigator (the default for [showHudDialog]) rather than whichever Navigator is
/// nearest the call site — the in-car shell scopes its own Navigator to the content stage
/// (`AppShell`), and a PIN dialog must cover the whole window, rail included.
Future<bool> showPinDialog(
  BuildContext context, {
  required PinPadStrings strings,
  required Future<PinCheck> Function(String pin) check,
  Widget? leading,
}) async {
  final padKey = GlobalKey<PinPadState>();
  var checking = false;

  final result = await showHudDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.title),
      content: PinPad(
        key: padKey,
        subtitle: strings.subtitle,
        backspaceTooltip: strings.backspaceTooltip,
        leading: leading,
        onCompleted: (pin) async {
          if (checking) return;
          checking = true;
          final outcome = await check(pin);
          checking = false;
          if (outcome.ok) {
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            return;
          }
          padKey.currentState?.showError(outcome.error ?? '');
          final retryAfter = outcome.retryAfter;
          if (retryAfter != null) padKey.currentState?.disableFor(retryAfter);
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(strings.cancel)),
      ],
    ),
  );
  return result ?? false;
}

/// Shows the "set a new PIN" flow: enter, then confirm. Returns the PIN once both entries match,
/// or null on Cancel. Makes no RPC call of its own — the caller saves the returned PIN.
Future<String?> showNewPinDialog(BuildContext context, {required PinPadStrings strings}) async {
  final padKey = GlobalKey<PinPadState>();
  String? firstPin;
  var title = strings.newPinTitle;

  return showHudDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: PinPad(
          key: padKey,
          backspaceTooltip: strings.backspaceTooltip,
          onCompleted: (pin) {
            if (firstPin == null) {
              firstPin = pin;
              padKey.currentState?.clear();
              setState(() => title = strings.confirmPinTitle);
              return;
            }
            if (pin == firstPin) {
              Navigator.of(dialogContext).pop(pin);
              return;
            }
            firstPin = null;
            setState(() => title = strings.newPinTitle);
            padKey.currentState?.showError(strings.mismatch);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(strings.cancel)),
        ],
      ),
    ),
  );
}
