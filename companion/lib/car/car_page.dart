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
        icon: Icons.link_off,
        title: tr('companion.refused'),
        body: tr('companion.refused_hint'),
        action: onPairAgain == null ? null : FilledButton(onPressed: onPairAgain, child: Text(tr('companion.pair_again'))),
      );
    }
    return switch (session.phase) {
      TransportPhase.lan || TransportPhase.pear when !session.answering => _State(
          key: const ValueKey('car.silent'),
          busy: true,
          title: tr('companion.not_answering'),
          body: tr('companion.not_answering_hint'),
        ),
      TransportPhase.lan || TransportPhase.pear => child,
      TransportPhase.discovering => _State(
          key: const ValueKey('car.looking'),
          busy: true,
          title: tr(session.everConnected ? 'companion.reconnecting' : 'companion.looking'),
          body: tr('companion.looking_hint'),
        ),
      TransportPhase.failed => _State(
          key: const ValueKey('car.unreachable'),
          icon: Icons.cloud_off,
          title: tr('companion.unreachable'),
          body: tr('companion.unreachable_hint'),
          action: OutlinedButton(onPressed: session.retry, child: Text(tr('common.retry'))),
        ),
    };
  }
}

class _State extends StatelessWidget {
  const _State({super.key, this.icon, this.busy = false, required this.title, required this.body, this.action});

  final IconData? icon;
  final bool busy;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy) const CircularProgressIndicator() else Icon(icon, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(body, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
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
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message ?? tr('errors.load_failed')),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: Text(tr('common.retry'))),
      ]),
    );
  }
}
