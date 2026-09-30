import 'package:bladewatch_theme/dimens_tokens.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import '../i18n.dart';
import '../transport/transport_selector.dart';
import 'car_session.dart';

/// Makes the [CarSession] reachable as `context.session`, rebuilding dependents when its
/// connection state changes.
class SessionScope extends InheritedNotifier<CarSession> {
  const SessionScope({super.key, required CarSession session, required super.child}) : super(notifier: session);
}

extension SessionContext on BuildContext {
  CarSession get session => dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}

/// Every screen that talks to the car sits inside this. It shows the screen only while the car
/// is reachable, and otherwise says which of four different things is going on: still looking
/// (a Pear lookup can take a minute), can't reach the car (it keeps retrying), reached but not
/// answering (its daemon stopped or is restarting; stale data would otherwise pass for live), or
/// the car removed this device (only pairing again helps).
class CarPage extends StatelessWidget {
  const CarPage({super.key, required this.child, this.onPairAgain});

  final Widget child;

  /// Offered when the car refused this device.
  final VoidCallback? onPairAgain;

  @override
  Widget build(BuildContext context) {
    final session = context.session;
    final tr = context.tr;
    if (session.refused) {
      return _State(
        key: const ValueKey('car.refused'),
        dot: HudDotState.bad,
        icon: Icons.link_off,
        title: tr('companion.refused'),
        body: tr('companion.refused_hint'),
        action: onPairAgain == null ? null : FilledButton(onPressed: onPairAgain, child: Text(tr('companion.pair_again'))),
      );
    }
    return switch (session.phase) {
      TransportPhase.lan || TransportPhase.pear when !session.answering => _State(
          key: const ValueKey('car.silent'),
          dot: HudDotState.warning,
          busy: true,
          title: tr('companion.not_answering'),
          body: tr('companion.not_answering_hint'),
        ),
      TransportPhase.lan || TransportPhase.pear => child,
      TransportPhase.discovering => _State(
          key: const ValueKey('car.looking'),
          dot: HudDotState.warning,
          busy: true,
          title: tr(session.everConnected ? 'companion.reconnecting' : 'companion.looking'),
          body: tr('companion.looking_hint'),
        ),
      TransportPhase.failed => _State(
          key: const ValueKey('car.unreachable'),
          dot: HudDotState.bad,
          icon: Icons.cloud_off,
          title: tr('companion.unreachable'),
          body: tr('companion.unreachable_hint'),
          action: OutlinedButton(onPressed: session.retry, child: Text(tr('common.retry'))),
        ),
    };
  }
}

/// One connection state as a HUD panel. The dot is the REAL state of the link: amber while the app is still looking
/// or the car is not answering (both clear by themselves), magenta when it needs the owner (unreachable, refused).
class _State extends StatelessWidget {
  const _State({super.key, required this.dot, this.icon, this.busy = false, required this.title, required this.body, this.action});

  final HudDotState dot;
  final IconData? icon;
  final bool busy;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BwDimens.pagePaddingHorizontal),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: HudPanel(
            gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: hud.summaryGradient),
            borderColor: hud.cardBorder,
            radius: BwHud.radiusPanel,
            shadows: hud.cardShadow,
            padding: const EdgeInsets.all(BwDimens.cardPaddingHero),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: hud.accent,
                      value: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? 0.3 : null,
                    ),
                  )
                else
                  Icon(icon, size: 32, color: hud.magenta),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HudStatusDot(dot),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: hudText(14, hud.accent, lineHeight: 20, weight: FontWeight.w700, em: 0.05, shadows: hudGlow(hud.glowCyan)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(body, textAlign: TextAlign.center, style: hudText(12, hud.textSecondary, lineHeight: 16)),
                if (action != null) ...[const SizedBox(height: 16), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A load that failed while the car was reachable: say so, offer a retry.
class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return HudErrorState(message: message ?? tr('errors.load_failed'), retryLabel: tr('common.retry'), onRetry: onRetry);
  }
}
