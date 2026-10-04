import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../platform/pairing_channel.dart';
import 'pairing_controller.dart';
import '../../widgets/hud_widgets.dart';

/// Opens the in-car "Pair a device" dialog (BladeWatch-rdtj.7). The QR is minted when the dialog
/// opens -- the explicit action the owner takes -- and is never shown on the dashboard itself.
Future<void> showPairingDialog(BuildContext context, PairingChannel channel) async {
  final controller = PairingController(channel);
  unawaited(controller.start());
  await showHudDialog<void>(context: context, builder: (_) => PairingDialog(controller: controller));
  unawaited(controller.closeWifi());
  controller.dispose();
}

class PairingDialog extends StatefulWidget {
  final PairingController controller;

  const PairingDialog({super.key, required this.controller});

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    // The countdown, and the switch to "expired": a code that has lapsed must stop looking valid.
    // Every other second, Wi-Fi pairing too.
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (t.tick.isEven) widget.controller.pollWifi();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return AlertDialog(
          icon: const Icon(Icons.qr_code_2),
          title: Text(l10n.pairing_title),
          // A fixed width, not styling: QrImageView builds a LayoutBuilder, which cannot answer the
          // intrinsic-width question AlertDialog asks. Scrollable so the actions stay reachable on
          // the head unit's panel in the long languages.
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.wifiRequest case final request?)
                    _wifiRequest(request, c, l10n, theme)
                  else ...[
                    _code(context, c, l10n, theme),
                    const SizedBox(height: 12),
                    Text(l10n.pairing_wifi_hint, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                  ],
                  const Divider(height: 32),
                  SwitchListTile(
                    key: const ValueKey('pairing.lan'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.pairing_lan_title),
                    subtitle: Text(l10n.pairing_lan_body),
                    value: c.lanEnabled,
                    onChanged: c.offer == null ? null : c.setLanAccess,
                  ),
                  const Divider(height: 32),
                  Text(l10n.pairing_devices_title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (c.devices.isEmpty)
                    Text(l10n.pairing_devices_empty, style: theme.textTheme.bodyMedium)
                  else
                    for (final d in c.devices)
                      ListTile(
                        key: ValueKey('pairing.device.${d.id}'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.devices_other),
                        title: Text(d.name),
                        subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(d.pairedAt)),
                        trailing: TextButton(
                          onPressed: () => _confirmRemove(context, d, l10n),
                          child: Text(l10n.pairing_remove),
                        ),
                      ),
                  if (c.actionFailed) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.pairing_error,
                      key: const ValueKey('pairing.actionError'),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.dialog_close)),
          ],
        );
      },
    );
  }

  Widget _code(BuildContext context, PairingController c, AppLocalizations l10n, ThemeData theme) {
    final offer = c.offer;
    if (offer == null) {
      if (!c.mintFailed) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
      return Column(children: [
        Text(l10n.pairing_error, key: const ValueKey('pairing.error')),
        const SizedBox(height: 8),
        FilledButton(onPressed: c.start, child: Text(l10n.action_retry)),
      ]);
    }
    if (c.expired) {
      return Center(
        child: Column(children: [
          Text(l10n.pairing_expired, key: const ValueKey('pairing.expired')),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: c.newCode, icon: const Icon(Icons.refresh), label: Text(l10n.pairing_new_code)),
        ]),
      );
    }
    final left = c.remaining;
    final time = '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    return Center(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: QrImageView(key: const ValueKey('pairing.qr'), data: offer.payload, size: 240),
        ),
        const SizedBox(height: 12),
        Text(l10n.pairing_scan_hint, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(l10n.pairing_expires_in(time), key: const ValueKey('pairing.countdown'), style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(l10n.pairing_remote_note, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      ]),
    );
  }

  /// A device without a camera asking to pair: the owner compares the number with the device's.
  Widget _wifiRequest(WifiPairingRequest r, PairingController c, AppLocalizations l10n, ThemeData theme) {
    final n = r.number;
    return Center(
      key: const ValueKey('pairing.wifi'),
      child: Column(children: [
        Text(l10n.pairing_wifi_title(r.name), style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          n.length == 6 ? '${n.substring(0, 3)} ${n.substring(3)}' : n,
          key: const ValueKey('pairing.wifi.number'),
          style: theme.textTheme.displayMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(height: 12),
        Text(l10n.pairing_wifi_body, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8, children: [
          OutlinedButton(
            key: const ValueKey('pairing.wifi.refuse'),
            onPressed: () => c.decideWifi(false),
            child: Text(l10n.pairing_wifi_refuse),
          ),
          FilledButton(
            key: const ValueKey('pairing.wifi.accept'),
            onPressed: () => c.decideWifi(true),
            child: Text(l10n.pairing_wifi_accept),
          ),
        ]),
      ]),
    );
  }

  Future<void> _confirmRemove(BuildContext context, PairedDevice device, AppLocalizations l10n) async {
    if (await confirmRemovePairedDevice(context, device)) await widget.controller.remove(device.id);
  }
}

/// Asks before un-pairing [device]: it loses access at once. Shared by this dialog and the
/// dashboard's PAIRED DEVICES card.
Future<bool> confirmRemovePairedDevice(BuildContext context, PairedDevice device) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showHudDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.pairing_remove_confirm_title(device.name)),
      content: Text(l10n.pairing_remove_confirm_body),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.action_cancel)),
        FilledButton(
          key: const ValueKey('pairing.removeConfirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.pairing_remove),
        ),
      ],
    ),
  );
  return confirmed == true;
}
