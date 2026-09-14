import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/brand_lockup.dart';

import '../../gen/l10n/app_localizations.dart';
import 'startup_controller.dart';
import 'startup_models.dart';

/// Ported from `app/src/main/res/layout/fragment_startup.xml` +
/// `StartupFragment.kt`. Renders [StartupController] state; forwards the one
/// user intent (tapping the continue button) to it. No business logic here —
/// see the controller for the actual behaviour and why it looks the way it
/// does.
class StartupScreen extends StatefulWidget {
  final StartupController controller;
  final VoidCallback onReadyToNavigate;

  const StartupScreen({super.key, required this.controller, required this.onReadyToNavigate});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => widget.controller.tick());
    widget.controller.tick();
  }

  void _onControllerChanged() {
    if (widget.controller.navigateToDashboard) {
      widget.onReadyToNavigate();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Column(
                children: [
                  // BladeWatch-ez0z: icon + wordmark, matching the native launch
                  // drawable so the handoff from the window background to
                  // Flutter's first frame does not drop the branding. This
                  // screen is what the user actually stares at while the daemons
                  // come up, so it is where the brand needs to be.
                  BrandLockup(iconSize: 88, color: theme.colorScheme.primary),
                  const SizedBox(height: 4),
                  Text(l10n.startup_subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24).copyWith(top: 32),
                    child: Card(
                      color: theme.colorScheme.surfaceContainer,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.channelErrorMessage ?? _headerText(l10n, c.phase),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: c.channelErrorMessage != null ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Text('${_overallElapsed(c).inSeconds}s',
                                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: theme.colorScheme.outlineVariant),
                          _DaemonRow(
                            name: l10n.startup_daemon_camera,
                            desc: l10n.startup_daemon_camera_desc,
                            state: c.rows[CoreDaemon.camera]!,
                            l10n: l10n,
                          ),
                          Divider(height: 1, color: theme.colorScheme.outlineVariant),
                          _DaemonRow(
                            name: l10n.startup_daemon_sentry,
                            desc: l10n.startup_daemon_sentry_desc,
                            state: c.rows[CoreDaemon.sentry]!,
                            l10n: l10n,
                          ),
                          Divider(height: 1, color: theme.colorScheme.outlineVariant),
                          _DaemonRow(
                            name: l10n.startup_daemon_parking,
                            desc: l10n.startup_daemon_parking_desc,
                            state: c.rows[CoreDaemon.accSentry]!,
                            l10n: l10n,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (c.phase != StartupPhase.ready)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32).copyWith(top: 24),
                      child: LinearProgressIndicator(
                        color: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  if (c.showContinueButton || c.phase == StartupPhase.ready)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                        onPressed: c.continueAnyway,
                        child: Text(c.phase == StartupPhase.ready ? l10n.startup_continue : l10n.startup_continue_anyway),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _headerText(AppLocalizations l10n, StartupPhase phase) => switch (phase) {
        StartupPhase.preparing => l10n.startup_header_preparing,
        StartupPhase.starting => l10n.startup_header_starting,
        StartupPhase.verifying => l10n.startup_header_verifying,
        StartupPhase.ready => l10n.startup_header_ready,
      };

  Duration _overallElapsed(StartupController c) {
    final elapsedValues = c.rows.values.map((r) => r.elapsed);
    return elapsedValues.isEmpty ? Duration.zero : elapsedValues.reduce((a, b) => a > b ? a : b);
  }
}

class _DaemonRow extends StatelessWidget {
  final String name;
  final String desc;
  final DaemonRowState state;
  final AppLocalizations l10n;

  const _DaemonRow({required this.name, required this.desc, required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = state.status == DaemonRowStatus.ready;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ready ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface)),
                Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            ready ? l10n.startup_status_ready : l10n.startup_status_waiting,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(width: 8),
          Text('${state.elapsed.inSeconds}s', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}
