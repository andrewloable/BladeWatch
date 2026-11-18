import 'package:flutter/material.dart';

import '../gen/l10n/app_localizations.dart';
import '../widgets/hud_widgets.dart';
import 'trip_reminder_controller.dart';

/// Shows the "trip still recording" dialog over whatever screen is up (BladeWatch-gklt.6).
///
/// Mounted once, below the app's navigator and above the shell, so the dialog covers any page. It
/// starts the controller's poll, re-reads when the app comes back to the foreground (a head unit
/// that slept with the app alive), and shows at most one dialog at a time.
class TripReminderHost extends StatefulWidget {
  final TripReminderController controller;
  final Widget child;

  const TripReminderHost({super.key, required this.controller, required this.child});

  @override
  State<TripReminderHost> createState() => _TripReminderHostState();
}

class _TripReminderHostState extends State<TripReminderHost> with WidgetsBindingObserver {
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onChanged);
    widget.controller.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.refresh();
  }

  void _onChanged() {
    if (!mounted || _dialogOpen || widget.controller.pending == null) return;
    _dialogOpen = true;
    // After this frame: the controller can notify during a build. A post-frame callback does NOT
    // ask for a frame, so on a screen that is not animating (nothing repaints) the dialog would
    // wait for some unrelated repaint: ask for one.
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _show() async {
    if (!mounted) {
      _dialogOpen = false;
      return;
    }
    await showHudDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TripReminderDialog(controller: widget.controller),
    );
    _dialogOpen = false;
    // A newer reminder may have arrived while this one was up.
    _onChanged();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TripReminderDialog extends StatefulWidget {
  final TripReminderController controller;

  const _TripReminderDialog({required this.controller});

  @override
  State<_TripReminderDialog> createState() => _TripReminderDialogState();
}

class _TripReminderDialogState extends State<_TripReminderDialog> {
  bool _busy = false;
  bool _stopFailed = false;

  /// The reminder this dialog was opened for, read ONCE in [initState]: a later status read (a newer
  /// reminder, a stopped trip) must not change what this dialog acknowledges.
  late final int _seq;
  late final String _reason;
  late final int _startMs;

  @override
  void initState() {
    super.initState();
    final p = widget.controller.pending;
    _seq = p?.reminderSeq.toInt() ?? 0;
    _reason = p?.reminderReason ?? '';
    _startMs = p?.startTimeMs.toInt() ?? 0;
  }

  static String _elapsed(int startMs) {
    final seconds = (DateTime.now().millisecondsSinceEpoch - startMs).clamp(0, 1 << 40) ~/ 1000;
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    return '${seconds ~/ 3600}:$m';
  }

  Future<void> _keep() async {
    setState(() => _busy = true);
    await widget.controller.acknowledge(_seq);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _stop() async {
    setState(() {
      _busy = true;
      _stopFailed = false;
    });
    final stopped = await widget.controller.stopTrip();
    if (!mounted) return;
    if (stopped) {
      await widget.controller.acknowledge(_seq);
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _stopFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elapsed = _elapsed(_startMs);
    final body = _reason == 'parked_30m'
        ? l10n.trip_reminder_body_parked(elapsed)
        : l10n.trip_reminder_body_acc_off(elapsed);
    return AlertDialog(
      key: const ValueKey('tripReminder.dialog'),
      title: Text(l10n.trip_reminder_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(body, key: const ValueKey('tripReminder.body')),
          if (_stopFailed) ...[
            const SizedBox(height: 12),
            Text(
              l10n.dashboard_trip_error,
              key: const ValueKey('tripReminder.error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('tripReminder.keep'),
          onPressed: _busy ? null : _keep,
          child: Text(l10n.trip_reminder_keep),
        ),
        FilledButton(
          key: const ValueKey('tripReminder.stop'),
          onPressed: _busy ? null : _stop,
          child: Text(l10n.trip_reminder_stop),
        ),
      ],
    );
  }
}
