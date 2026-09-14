import 'package:flutter/material.dart';

/// The app icon above the BladeWatch wordmark.
///
/// BladeWatch-ez0z: the native launch drawable
/// (`android/app/src/main/res/drawable/launch_background.xml`) draws this same
/// lockup as the window background, but it stops being visible the moment
/// Flutter's surface attaches — which is long before the app is usable, because
/// Startup waits on the daemons. Drawing the same thing in Dart makes the
/// branding continuous instead of a flash, and unlike the window background it
/// can actually be tested.
///
/// The two must agree. If you change the icon, the wordmark or the spacing here,
/// change `launch_background.xml` to match or the handoff will visibly jump.
class BrandLockup extends StatelessWidget {
  /// Rendered size of the icon. The asset is the xxxhdpi launcher foreground
  /// (192px), so it downscales cleanly at any of these.
  final double iconSize;

  /// Colour of the wordmark. Defaults to the theme's onSurface.
  final Color? color;

  const BrandLockup({super.key, this.iconSize = 96, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = color ?? theme.colorScheme.onSurface;

    return Column(
      key: const ValueKey('brand.lockup'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/app_icon.png',
          key: const ValueKey('brand.icon'),
          width: iconSize,
          height: iconSize,
          // The launcher foreground has no intrinsic semantics; the wordmark
          // below already names the app, so announcing it twice adds nothing.
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 4),
        Text(
          // Deliberately NOT localised: BladeWatch is a brand name, and every
          // catalog that carries it leaves it untranslated.
          'BladeWatch',
          key: const ValueKey('brand.wordmark'),
          style: theme.textTheme.headlineMedium?.copyWith(color: fg),
        ),
      ],
    );
  }
}
