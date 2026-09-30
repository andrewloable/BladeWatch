import 'dart:async';
import 'dart:io';

import 'package:bladewatch_theme/dimens_tokens.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import '../../car/car_store.dart';
import '../../device_name.dart';
import '../../i18n.dart';
import 'pairing_controller.dart';

/// Scans (or takes the pasted text of) the car's "Pair a device" QR and pairs with it.
class PairingScreen extends StatefulWidget {
  const PairingScreen(
      {super.key, required this.controller, required this.onPaired, this.scan, this.defaultName, this.detectName});

  final PairingController controller;
  final ValueChanged<PairedCar> onPaired;

  /// Opens the camera and resolves to the QR's text, or null if cancelled. Null when this
  /// platform has no camera scanner (Windows, Linux): pasting still works everywhere.
  final Future<String?> Function(BuildContext context)? scan;

  /// Pre-filled device name, as the car's "Paired devices" list will show it. Without one, the
  /// screen asks [detectName] -- by default this device's own name ([deviceName]).
  final String? defaultName;

  /// Resolves this device's name, given the generic one to fall back to. Replaceable in tests.
  final Future<String> Function(String fallback)? detectName;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _code = TextEditingController();
  late final _name = TextEditingController(text: widget.defaultName ?? _platformName());

  @override
  void initState() {
    super.initState();
    if (widget.defaultName != null) return;
    // The generic name shows at once; the real one replaces it unless the owner has typed already.
    final generic = _name.text;
    unawaited((widget.detectName ?? deviceName)(generic).then((name) {
      if (mounted && _name.text == generic) _name.text = name;
    }));
  }

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
    final hud = BwHud.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BwDimens.pagePaddingHorizontal),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final c = widget.controller;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The pulsing magenta square is "pairing / attention" (HUD rule 4); the QR mark is the trailing.
                      HudTitleBar(
                        title: tr('companion.pair_title').toUpperCase(),
                        trailing: Icon(Icons.qr_code_2, size: 28, color: hud.accent),
                      ),
                      Text(tr('companion.pair_hint'), style: hudText(12, hud.textSecondary, lineHeight: 16)),
                      const SizedBox(height: 24),
                      HudPanel(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: hud.summaryGradient,
                        ),
                        borderColor: hud.cardBorder,
                        radius: BwHud.radiusPanel,
                        shadows: hud.cardShadow,
                        padding: const EdgeInsets.all(BwDimens.cardPaddingHero),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            if (c.busy || c.error != null) const SizedBox(height: 16),
                            if (c.busy)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      tr(c.step == PairingStep.connecting ? 'companion.pair_finding' : 'companion.pair_redeeming'),
                                      style: hudText(12, hud.textSecondary, lineHeight: 16),
                                    ),
                                  ),
                                ],
                              ),
                            if (c.error != null)
                              Text(
                                tr(c.error!),
                                key: const ValueKey('pair.error'),
                                style: hudText(12, hud.magenta, lineHeight: 16, weight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
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
