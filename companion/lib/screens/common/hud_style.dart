import 'package:bladewatch_theme/hud_theme.dart';
import 'package:flutter/material.dart';

/// A destructive action's button: magenta text and border on the soft magenta fill (the HUD's attention colour), not
/// the accent every other action wears. For a `FilledButton` (or `.tonal`) that deletes, resets or unpairs.
ButtonStyle destructiveStyle(BuildContext context) {
  final hud = BwHud.of(context);
  return FilledButton.styleFrom(
    foregroundColor: hud.magenta,
    backgroundColor: Color.alphaBlend(hud.magenta.withValues(alpha: 0.15), hud.panel),
    side: BorderSide(color: hud.magentaBorder),
  );
}
