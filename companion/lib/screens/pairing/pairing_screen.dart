import 'dart:io';

import 'package:flutter/material.dart';

import '../../car/car_store.dart';
import '../../i18n.dart';
import 'pairing_controller.dart';

/// Scans (or takes the pasted text of) the car's "Pair a device" QR and pairs with it.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, required this.controller, required this.onPaired, this.scan, this.defaultName});

  final PairingController controller;
  final ValueChanged<PairedCar> onPaired;

  /// Opens the camera and resolves to the QR's text, or null if cancelled. Null when this
  /// platform has no camera scanner (Windows, Linux): pasting still works everywhere.
  final Future<String?> Function(BuildContext context)? scan;

  /// Pre-filled device name, as the car's "Paired devices" list will show it.
  final String? defaultName;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _code = TextEditingController();
  late final _name = TextEditingController(text: widget.defaultName ?? _platformName());

  static String _platformName() => switch (Platform.operatingSystem) {
        'android' => 'Android',
        'ios' => 'iPhone',
        'macos' => 'Mac',
        'windows' => 'Windows PC',
        'linux' => 'Linux PC',
        final other => other,
      };

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit(String text) async {
    final car = await widget.controller.pair(text, _name.text);
    if (car != null) widget.onPaired(car);
  }

  Future<void> _scan() async {
    final text = await widget.scan!(context);
    if (text != null && mounted) {
      _code.text = text;
      await _submit(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final c = widget.controller;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.qr_code_2, size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(tr('companion.pair_title'), style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text(tr('companion.pair_hint'), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      TextField(
                        key: const ValueKey('pair.name'),
                        controller: _name,
                        enabled: !c.busy,
                        decoration: InputDecoration(labelText: tr('companion.pair_device_name')),
                      ),
                      const SizedBox(height: 16),
                      if (widget.scan != null) ...[
                        FilledButton.icon(
                          key: const ValueKey('pair.scan'),
                          onPressed: c.busy ? null : _scan,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(tr('companion.pair_scan')),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        key: const ValueKey('pair.code'),
                        controller: _code,
                        enabled: !c.busy,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(labelText: tr('companion.pair_paste')),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        key: const ValueKey('pair.submit'),
                        onPressed: c.busy ? null : () => _submit(_code.text),
                        child: Text(tr('companion.pair_button')),
                      ),
                      const SizedBox(height: 16),
                      if (c.busy)
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(tr(c.step == PairingStep.connecting ? 'companion.pair_finding' : 'companion.pair_redeeming')),
                          ),
                        ]),
                      if (c.error != null)
                        Text(tr(c.error!), key: const ValueKey('pair.error'), style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
