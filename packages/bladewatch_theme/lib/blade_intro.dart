import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hud_theme.dart';
import 'hud_widgets.dart';

/// The animated launch intro of both apps (BladeWatch-sjz4): about 1.2 s on every launch.
///
/// The native splash (Android launch drawable, the Android 12+ system splash, the iOS launch
/// screen) is black with ONLY the app's logo in the centre. This widget's first frame is the same
/// picture, the same logo at the same [logoSize], so the handoff from native to Flutter cannot be
/// seen. From there the logo grows and rises with a cyan glow pulse, "BladeWatch" slides up under
/// it, a thin scan line sweeps beneath the name, and the whole layer fades out onto the app.
///
/// It is an OVERLAY: the app is built and starting underneath it the whole time (the in-car startup
/// checks run during the intro, not after it). It absorbs taps while it shows, so a touch cannot
/// land on a screen nobody can see yet, and it calls [onDone] when it is finished so the caller
/// can remove it.
///
/// It skips itself (calls [onDone] after the first frame) when the platform asks for reduced
/// motion: [MediaQuery.disableAnimations].
class BladeIntro extends StatefulWidget {
  const BladeIntro({
    super.key,
    required this.logo,
    required this.logoSize,
    required this.onDone,
    this.duration = defaultDuration,
  });

  /// The same image the native splash shows.
  final ImageProvider logo;

  /// The logo's size on the native splash, in logical pixels: where the intro starts.
  final double logoSize;

  final VoidCallback onDone;
  final Duration duration;

  static const defaultDuration = Duration(milliseconds: 1200);

  /// The brand name. Deliberately not localised, like every catalog that carries it.
  static const wordmark = 'BladeWatch';

  @override
  State<BladeIntro> createState() => _BladeIntroState();
}

class _BladeIntroState extends State<BladeIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _c.forward().whenComplete(_finish);
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// [t] mapped onto [begin]..[end] and clamped, then eased.
  static double _phase(double t, double begin, double end, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    const hud = BwHud.dark;
    final size = widget.logoSize;
    return AbsorbPointer(
      key: const ValueKey('bladeIntro'),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // Logo: grows to 1.6x and rises; the glow swells, then settles into a softer pulse.
          final grow = _phase(t, 0.0, 0.5);
          final scale = 1.0 + 0.6 * grow;
          final rise = -size * 0.55 * _phase(t, 0.2, 0.6);
          final glow = _phase(t, 0.1, 0.45) * (0.75 - 0.3 * _phase(t, 0.45, 0.8)) +
              0.08 * math.sin(math.pi * 2 * _phase(t, 0.45, 1.0, Curves.linear));
          // Wordmark: fades in while sliding up into place under the logo.
          final word = _phase(t, 0.35, 0.7);
          final wordY = size * 0.95 + 14 * (1 - word);
          // Scan line: sweeps left to right under the wordmark.
          final sweep = _phase(t, 0.6, 0.92, Curves.easeInOutCubic);
          // The whole layer fades out onto the app at the end.
          final out = 1.0 - _phase(t, 0.86, 1.0, Curves.easeIn);
          final glowSize = size * scale * 2.4;

          return Opacity(
            opacity: out,
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(0, rise),
                    child: Container(
                      key: const ValueKey('bladeIntro.glow'),
                      width: glowSize,
                      height: glowSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          hud.accent.withValues(alpha: glow.clamp(0.0, 1.0) * 0.55),
                          hud.accent.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, rise),
                    child: Transform.scale(
                      scale: scale,
                      child: Image(
                        key: const ValueKey('bladeIntro.logo'),
                        image: widget.logo,
                        width: size,
                        height: size,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, rise + wordY),
                    child: Opacity(
                      opacity: word,
                      child: Text(
                        BladeIntro.wordmark.toUpperCase(),
                        key: const ValueKey('bladeIntro.wordmark'),
                        style: hudText(22, hud.textPrimary, lineHeight: 28, weight: FontWeight.w700, em: 0.3)
                            .copyWith(shadows: hudGlow(hud.glowCyan)),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, rise + wordY + 24),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 220,
                        height: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            key: const ValueKey('bladeIntro.scan'),
                            width: 220 * sweep,
                            height: 2,
                            decoration: BoxDecoration(
                              color: hud.accent,
                              boxShadow: [BoxShadow(color: hud.accent.withValues(alpha: 0.8), blurRadius: 8)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
