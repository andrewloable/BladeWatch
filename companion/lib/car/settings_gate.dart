import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_theme/pin_pad.dart';
import 'package:flutter/material.dart';

import '../i18n.dart';
import 'biometrics.dart';
import 'car_store.dart';

/// The Settings PIN lock (BladeWatch-hr6r): one 6-digit PIN, held by the car, shared with the
/// in-car app and every paired companion -- see the epic for the threat model and the lockout
/// policy. Gates the companion's `settings`, `surveillance` and `notifications` destinations.
///
/// Biometric unlock (BladeWatch-hr6r.6) is local to this device and only tried automatically
/// when [CarStore.biometricUnlockEnabled] is true -- an explicit per-device opt-in the owner
/// turns on from Settings by proving they know the car's PIN (see settings_screen.dart), not
/// just because the OS happens to report a sensor. [admit] is the one place that decides "how
/// does this device unlock right now".
class SettingsGate {
  SettingsGate({required SettingsServiceClient settingsService, required CarStore store, Biometrics? biometrics})
      : _settingsService = settingsService, // ignore: prefer_initializing_formals
        _store = store, // ignore: prefer_initializing_formals
        _biometrics = biometrics ?? LocalAuthBiometrics();

  final SettingsServiceClient _settingsService;
  final CarStore _store;
  final Biometrics _biometrics;

  bool _enabled = false;
  bool get enabled => _enabled;

  /// True once a PIN has been accepted this "session" (until [relock]).
  bool _unlocked = false;
  bool get unlocked => _unlocked;

  /// Refreshes [enabled] from the car and updates the cache in [CarStore] so a later launch can
  /// fail closed even before the first RPC lands. On failure, keeps whatever the cache last said.
  Future<void> refresh() async {
    try {
      final r = await _settingsService.getSettingsLock(GetSettingsLockRequest());
      _enabled = r.enabled;
      _store.settingsLockKnown = _enabled;
      // Fire-and-forget: a slow or failed disk write must never hold up admit().
      unawaited(_store.save());
    } catch (_) {
      _enabled = _store.settingsLockKnown;
    }
  }

  /// Admits the caller to a gated destination: true at once if the lock is off (after a fresh
  /// [refresh]) or this session is already unlocked; otherwise tries biometrics (only when the
  /// owner opted this device in -- see [CarStore.biometricUnlockEnabled]) and falls back to the
  /// PIN dialog, returning whether entry succeeded (false on Cancel).
  ///
  /// Fails closed: when [refresh] cannot reach the car, [enabled] falls back to the cached
  /// value, so a lock the owner turned on is never silently bypassed just because the car is
  /// briefly unreachable. Biometrics work the same whether or not the car is reachable -- they
  /// are local to this device -- so they are tried before any car round-trip is needed.
  Future<bool> admit(BuildContext context) async {
    await refresh();
    if (!_enabled || _unlocked) return true;
    // Opted in AND currently available -- not just opted in: if the owner disabled biometrics in
    // the OS after opting in here, this is false and the PIN dialog shows no retry button either,
    // rather than offering a retry that could only ever fail.
    final triedBiometrics = _store.biometricUnlockEnabled && await _biometrics.available();
    if (triedBiometrics) {
      if (!context.mounted) return false;
      if (await _biometrics.authenticate(context.tr('companion.settings_lock_biometric_reason'))) {
        _unlocked = true;
        return true;
      }
    }
    if (!context.mounted) return false;
    final tr = context.tr;
    final ok = await showPinDialog(
      context,
      strings: PinPadStrings(
        title: tr('companion.settings_lock_enter_title'),
        cancel: tr('common.cancel'),
        backspaceTooltip: tr('companion.settings_lock_backspace'),
        newPinTitle: tr('companion.settings_lock_new_pin_title'),
        confirmPinTitle: tr('companion.settings_lock_confirm_pin_title'),
        mismatch: tr('companion.settings_lock_mismatch'),
      ),
      check: (pin) => check(context, pin),
      leading: triedBiometrics ? _biometricRetryButton(context) : null,
    );
    if (ok) _unlocked = true;
    return ok;
  }

  /// The PIN dialog's bottom-left slot: a retry button shown only when biometrics were actually
  /// tried this time (otherwise offering a retry for something never attempted, or that can only
  /// fail again, would be confusing). Wrapped in a [Builder] so its `onPressed` pops the dialog
  /// using a [BuildContext] that is actually INSIDE the dialog's route -- the same one
  /// [showPinDialog] uses for its own Cancel button -- rather than the outer page's context,
  /// which may sit behind a different (if, in this app, coincidental) Navigator ancestor.
  Widget _biometricRetryButton(BuildContext outerContext) => Builder(
        builder: (dialogContext) => IconButton(
          key: const ValueKey('pinPad.biometricRetry'),
          icon: const Icon(Icons.fingerprint),
          tooltip: outerContext.tr('companion.settings_lock_biometric_retry'),
          onPressed: () async {
            final ok = await _biometrics.authenticate(outerContext.tr('companion.settings_lock_biometric_reason'));
            if (!ok) return;
            _unlocked = true;
            if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
          },
        ),
      );

  /// Checks one entered PIN against the car, already mapped to [PinPadStrings]'s localized
  /// texts -- directly testable with any [BuildContext] that has a [TrScope] in scope.
  Future<PinCheck> check(BuildContext context, String pin) => checkSettingsPin(context, _settingsService, pin);

  /// Ends the current unlock -- leaving a gated destination, or the app going to the background.
  /// Idempotent.
  void relock() => _unlocked = false;
}

/// Maps a VerifySettingsPin outcome to a localized [PinCheck] -- shared by [SettingsGate.check]
/// and the Settings screen's own "prove the PIN before turning on biometric unlock" step
/// (BladeWatch-hr6r.6), so the lockout/wrong-PIN/unreachable mapping exists in exactly one place.
Future<PinCheck> checkSettingsPin(BuildContext context, SettingsServiceClient settings, String pin) async {
  final tr = context.tr;
  try {
    final r = await settings.verifySettingsPin(VerifySettingsPinRequest(pin: pin));
    if (r.ok) return (ok: true, error: null, retryAfter: null);
    if (r.retryAfterMs > 0) {
      final retryAfter = Duration(milliseconds: r.retryAfterMs.toInt());
      return (
        ok: false,
        error: tr('companion.settings_lock_locked_out', {'time': _formatRetryAfter(retryAfter)}),
        retryAfter: retryAfter,
      );
    }
    return (ok: false, error: tr('companion.settings_lock_wrong_pin', {'count': r.attemptsLeft}), retryAfter: null);
  } catch (_) {
    return (ok: false, error: tr('companion.settings_lock_unreachable'), retryAfter: null);
  }
}

/// A plain, locale-neutral unit (matching the lockout policy's exact values -- 60s, 120s, 240s,
/// 480s, 960s, 1920s, capped at 3600s -- every one a whole minute or hour).
String _formatRetryAfter(Duration d) {
  if (d.inSeconds <= 0) return '0s';
  if (d.inSeconds % 3600 == 0) return '${d.inHours}h';
  if (d.inSeconds % 60 == 0) return '${d.inMinutes}m';
  return '${d.inSeconds}s';
}
