import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_theme/pin_pad.dart';
import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../platform/prefs_channel.dart';
import '../../shell/disposed_safe_notifier.dart';

/// The Settings PIN lock (BladeWatch-hr6r): one 6-digit PIN, held by the car, shared with
/// every paired companion -- see the epic for the threat model and the lockout policy.
///
/// Root-owned, like [SettingsAppearanceController] (see its own doc comment for why): both
/// `ShellController`'s route guard and the Dashboard's pairing gate need it, not only the
/// Settings > Security pane, and [unlocked] must survive switching sections inside Settings.
class SettingsLockController extends ChangeNotifier with DisposedSafeNotifier {
  SettingsLockController({required SettingsServiceClient settingsService, required PrefsChannel prefs})
      : _settingsService = settingsService, // ignore: prefer_initializing_formals
        _prefs = prefs; // ignore: prefer_initializing_formals

  final SettingsServiceClient _settingsService;
  final PrefsChannel _prefs;

  bool _enabled = false;
  bool get enabled => _enabled;

  /// True once a PIN has been accepted this "session" (until [relock]). Deliberately not
  /// persisted: every app launch, and every return from the background, starts locked again.
  bool _unlocked = false;
  bool get unlocked => _unlocked;

  /// Refreshes [enabled] from the car and updates the local cache so a later launch can fail
  /// closed even before the first RPC lands. On failure, keeps whatever the cache last said.
  Future<void> refresh() async {
    try {
      final r = await _settingsService.getSettingsLock(GetSettingsLockRequest());
      _enabled = r.enabled;
      unawaited(_prefs.setSettingsLockKnown(_enabled));
    } catch (_) {
      // The cache read itself can fail too (e.g. the platform channel is unavailable) -- that
      // must not escape as an uncaught error out of a fire-and-forget refresh() call. Falling
      // back to disabled here is the same fail-closed-by-construction default isEnabled() has
      // before anything is ever cached.
      try {
        _enabled = await _prefs.getSettingsLockKnown() ?? false;
      } catch (_) {
        _enabled = false;
      }
    }
    notifyListeners();
  }

  /// Admits the caller to a guarded screen or action: true at once if the lock is off (after
  /// a fresh [refresh]) or this session is already unlocked; otherwise shows the PIN dialog
  /// and returns whether it was entered correctly (false on Cancel).
  ///
  /// Fails closed: when [refresh] cannot reach the car, [enabled] falls back to the cached
  /// value, so a lock the owner turned on is never silently bypassed just because the daemon
  /// is briefly unreachable -- the dialog still shows, and [check] reports the service is
  /// unreachable for every PIN tried while it stays that way.
  Future<bool> admit(BuildContext context) async {
    await refresh();
    if (!_enabled || _unlocked) return true;
    if (!context.mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final ok = await showPinDialog(
      context,
      strings: PinPadStrings(
        title: l10n.settings_lock_enter_title,
        subtitle: l10n.settings_lock_enter_subtitle,
        cancel: l10n.action_cancel,
        backspaceTooltip: l10n.settings_lock_backspace,
        newPinTitle: l10n.settings_lock_new_pin_title,
        confirmPinTitle: l10n.settings_lock_confirm_pin_title,
        mismatch: l10n.settings_lock_mismatch,
      ),
      check: (pin) => check(context, pin),
    );
    if (ok) {
      _unlocked = true;
      notifyListeners();
    }
    return ok;
  }

  /// Checks one entered PIN against the car, already mapped to [PinPadStrings]'s localized
  /// texts -- directly unit-testable with a widget-test [BuildContext] that has
  /// [AppLocalizations] in scope.
  Future<PinCheck> check(BuildContext context, String pin) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final r = await _settingsService.verifySettingsPin(VerifySettingsPinRequest(pin: pin));
      if (r.ok) return (ok: true, error: null, retryAfter: null);
      if (r.retryAfterMs > 0) {
        final retryAfter = Duration(milliseconds: r.retryAfterMs.toInt());
        return (ok: false, error: l10n.settings_lock_locked_out(_formatRetryAfter(retryAfter)), retryAfter: retryAfter);
      }
      return (ok: false, error: l10n.settings_lock_wrong_pin(r.attemptsLeft), retryAfter: null);
    } catch (_) {
      return (ok: false, error: l10n.settings_lock_unreachable, retryAfter: null);
    }
  }

  /// A plain, locale-neutral unit (matching the lockout policy's exact values -- 60s, 120s,
  /// 240s, 480s, 960s, 1920s, capped at 3600s -- every one a whole minute or hour), the same
  /// spirit as the pairing dialog's own pre-formatted countdown rather than a fully
  /// locale-aware duration formatter this one line does not need.
  static String _formatRetryAfter(Duration d) {
    if (d.inSeconds <= 0) return '0s';
    if (d.inSeconds % 3600 == 0) return '${d.inHours}h';
    if (d.inSeconds % 60 == 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }

  /// Sets a new PIN and turns the lock on. Returns whether the car accepted it.
  Future<bool> setPin(String pin) async {
    try {
      final r = await _settingsService.setSettingsLock(SetSettingsLockRequest(enabled: true, pin: pin));
      if (r.success) {
        _enabled = true;
        _unlocked = true; // the owner just proved they know the new PIN
        unawaited(_prefs.setSettingsLockKnown(true));
        notifyListeners();
      }
      return r.success;
    } catch (_) {
      return false;
    }
  }

  /// Turns the lock off. Returns whether the car accepted it.
  Future<bool> disable() async {
    try {
      final r = await _settingsService.setSettingsLock(SetSettingsLockRequest(enabled: false));
      if (r.success) {
        _enabled = false;
        unawaited(_prefs.setSettingsLockKnown(false));
        notifyListeners();
      }
      return r.success;
    } catch (_) {
      return false;
    }
  }

  /// Ends the current unlock -- leaving Settings, or the app going to the background.
  /// Idempotent.
  void relock() {
    if (!_unlocked) return;
    _unlocked = false;
    notifyListeners();
  }
}
