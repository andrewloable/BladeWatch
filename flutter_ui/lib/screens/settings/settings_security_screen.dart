import 'dart:async' show unawaited;

import 'package:bladewatch_theme/pin_pad.dart';
import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../platform/pairing_channel.dart';
import '../../widgets/hud_widgets.dart';
import '../pairing/pairing_controller.dart';
import '../pairing/pairing_dialog.dart';
import 'settings_lock_controller.dart';

/// Settings > Security (BladeWatch-hr6r): turns the Settings PIN lock on and off, changes the
/// PIN, and (BladeWatch-xfb5) manages paired devices -- pairing a new one and removing an
/// existing one, moved here from the Dashboard because device pairing is configuration, not
/// status, and because both actions are already gated by the same PIN lock this pane manages.
/// The lock itself -- the PIN dialog, `ShellController`'s route guard, the pairing gate -- is
/// [SettingsLockController], shared with the rest of the app; this pane only manages it, the
/// same shape as [SettingsRelayScreen] manages its own secret-backed switch.
class SettingsSecurityScreen extends StatefulWidget {
  final SettingsLockController controller;

  /// BladeWatch-xfb5: null hides the Paired devices section (tests that do not exercise it, and
  /// the same "no channel, no pairing UI" default the Dashboard version had).
  final PairingChannel? pairingChannel;

  const SettingsSecurityScreen({super.key, required this.controller, this.pairingChannel});

  @override
  State<SettingsSecurityScreen> createState() => _SettingsSecurityScreenState();
}

class _SettingsSecurityScreenState extends State<SettingsSecurityScreen> {
  bool _saving = false;
  String? _error;

  /// The paired-devices list (moved from dashboard_screen.dart, BladeWatch-xfb5): the pairing
  /// dialog's own controller, used for its device list only -- nothing here mints a code.
  late final PairingController? _pairing = widget.pairingChannel == null ? null : PairingController(widget.pairingChannel!);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.refresh();
    _pairing?.addListener(_onChanged);
    _pairing?.refreshDevices();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _pairing?.dispose();
    super.dispose();
  }

  /// BladeWatch-hr6r: the Settings PIN lock's gate on pairing a new device or removing a paired
  /// one -- without it, anyone in the car could pair their own phone and unlock the companion
  /// with their own fingerprint, bypassing the whole point of the lock. Reaching this pane at
  /// all already passed the same gate when the lock is on (the route guard admits once per
  /// session), so this second check is normally instant -- it stays here anyway for the case a
  /// future entry point reaches this pane without going through that guard.
  Future<void> _pair() async {
    if (!await widget.controller.admit(context)) return;
    if (!mounted) return;
    await showPairingDialog(context, widget.pairingChannel!);
    unawaited(_pairing?.refreshDevices());
  }

  Future<void> _removeDevice(PairedDevice device) async {
    if (!await widget.controller.admit(context)) return;
    if (!mounted) return;
    if (await confirmRemovePairedDevice(context, device)) await _pairing!.remove(device.id);
  }

  PinPadStrings _newPinStrings(AppLocalizations l10n) => PinPadStrings(
        // Unused by showNewPinDialog (it shows newPinTitle/confirmPinTitle instead), but
        // PinPadStrings.title is required -- see pin_pad.dart's doc comment for the two flows.
        title: l10n.settings_lock_enter_title,
        cancel: l10n.action_cancel,
        backspaceTooltip: l10n.settings_lock_backspace,
        newPinTitle: l10n.settings_lock_new_pin_title,
        confirmPinTitle: l10n.settings_lock_confirm_pin_title,
        mismatch: l10n.settings_lock_mismatch,
      );

  Future<void> _setNewPin() async {
    final l10n = AppLocalizations.of(context)!;
    final pin = await showNewPinDialog(context, strings: _newPinStrings(l10n));
    if (pin == null || !mounted) return;
    await _save(widget.controller.setPin(pin));
  }

  Future<void> _turnOff() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showHudDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settings_lock_disable_confirm_title),
        content: Text(l10n.settings_lock_disable_confirm_body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.action_cancel)),
          TextButton(
            key: const ValueKey('security.disableConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settings_lock_turn_off),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _save(widget.controller.disable());
  }

  Future<void> _save(Future<bool> future) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await future;
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = ok ? null : AppLocalizations.of(context)!.settings_lock_save_failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                key: const ValueKey('security.enabled'),
                secondary: const Icon(Icons.lock),
                title: Text(l10n.settings_lock_switch_label),
                value: c.enabled,
                onChanged: _saving ? null : (on) => on ? _setNewPin() : _turnOff(),
              ),
              if (c.enabled) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  key: const ValueKey('security.changePin'),
                  leading: const Icon(Icons.password),
                  title: Text(l10n.settings_lock_change_pin),
                  onTap: _saving ? null : _setNewPin,
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    _error!,
                    key: const ValueKey('security.error'),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: Text(l10n.settings_lock_explainer, style: theme.textTheme.bodySmall),
        ),
        if (_pairing case final pairing?) ...[
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surfaceContainer,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.pairing_devices_title, style: theme.textTheme.titleMedium),
                      OutlinedButton.icon(
                        key: const ValueKey('dashboard.pair'),
                        onPressed: _pair,
                        icon: const Icon(Icons.qr_code_2, size: 16),
                        label: Text(l10n.pairing_title.toUpperCase()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (pairing.devices.isEmpty)
                    Text(l10n.pairing_devices_empty, style: theme.textTheme.bodyMedium)
                  else
                    for (final d in pairing.devices)
                      ListTile(
                        key: ValueKey('dashboard.device.${d.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(d.name),
                        subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(d.pairedAt)),
                        trailing: TextButton(onPressed: () => _removeDevice(d), child: Text(l10n.pairing_remove)),
                      ),
                  if (pairing.actionFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.pairing_error,
                        key: const ValueKey('dashboard.devicesError'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
