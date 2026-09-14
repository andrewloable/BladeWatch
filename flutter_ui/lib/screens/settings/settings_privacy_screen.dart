import 'dart:convert';

import 'package:flutter/material.dart';

import '../../gen/bladewatch/v1/system.pb.dart';
import '../../gen/l10n/app_localizations.dart';
import '../../rpc/services/system_service_client.dart';
import 'settings_privacy_controller.dart';

/// One reset category: its API id (must match the server exactly — ground
/// truth: `MainActivity.kt`'s `resetCategoryMapping`), checkbox title,
/// description, and the shorter label used in the "reset the following?"
/// confirmation list.
typedef _ResetCategory = (String id, String title, String desc, String label);

/// BladeWatch-uuo6: there is deliberately NO `soh` category here. BladeWatch-p7vi
/// removed state-of-health estimation from the daemon, so offering to "re-detect
/// nominal capacity, re-seed estimate from BMS" promised a repair for a capability
/// the product no longer has. Do not re-add it without reinstating SoH first.
///
/// `socHistory` below is a DIFFERENT thing — state of CHARGE, which is live and
/// which BladeWatch-1ovy's battery tile reads.
List<_ResetCategory> _resetCategories(AppLocalizations l10n) => [
      ('trips', l10n.reset_cat_trips, l10n.reset_cat_trips_desc, l10n.reset_label_trips),
      ('socHistory', l10n.reset_cat_soc_history, l10n.reset_cat_soc_history_desc, l10n.reset_label_soc_history),
      ('mediaRecordings', l10n.reset_cat_recordings, l10n.reset_cat_recordings_desc, l10n.reset_label_recordings),
      ('mediaSurveillance', l10n.reset_cat_sentry_events, l10n.reset_cat_sentry_events_desc, l10n.reset_label_sentry_events),
      ('mediaProximity', l10n.reset_cat_proximity, l10n.reset_cat_proximity_desc, l10n.reset_label_proximity),
      ('mediaTrips', l10n.reset_cat_trip_files, l10n.reset_cat_trip_files_desc, l10n.reset_label_trip_files),
    ];

/// Ground truth: `SettingsPrivacyFragment.kt` for storage/logging, and
/// `MainActivity.kt`'s `showResetDataDialog()` / `confirmAndPerformReset()` /
/// `performReset()` for the reset-data flow (BladeWatch-yz1e.11) — a category
/// checklist, then a "reset the following?" confirmation naming the selected
/// categories, then `SystemService.ResetPerformance`, matching native's
/// `resetCategoryMapping` id → API category strings exactly.
class SettingsPrivacyScreen extends StatefulWidget {
  final SettingsPrivacyController controller;
  final SystemServiceClient systemService;

  const SettingsPrivacyScreen({super.key, required this.controller, required this.systemService});

  @override
  State<SettingsPrivacyScreen> createState() => _SettingsPrivacyScreenState();
}

class _SettingsPrivacyScreenState extends State<SettingsPrivacyScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;
    final pending = l10n.dashboard_metric_value_pending;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.settings_privacy_stance_title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.settings_privacy_stance_body, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Text(l10n.settings_privacy_overline_storage, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        ListTile(
          title: Text(l10n.settings_privacy_storage_clips_label),
          trailing: Text(c.storageAvailable ? '${c.clipCount}' : pending),
        ),
        ListTile(
          title: Text(l10n.settings_privacy_storage_size_label),
          trailing: Text(c.storageAvailable ? (c.formattedSize ?? pending) : pending),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const ValueKey('privacy.timingLogs'),
          title: Text(l10n.settings_developer_timing_logs_title),
          subtitle: Text(l10n.settings_developer_timing_logs_subtitle),
          value: c.timingLogsEnabled,
          onChanged: c.loading ? null : c.setTimingLogsEnabled,
        ),
        SwitchListTile(
          key: const ValueKey('privacy.debugLogs'),
          title: Text(l10n.settings_developer_debug_logs_title),
          subtitle: Text(l10n.settings_developer_debug_logs_subtitle),
          value: c.debugLogsEnabled,
          onChanged: c.loading ? null : c.setDebugLogsEnabled,
        ),
        const SizedBox(height: 24),
        Text(l10n.settings_privacy_overline_reset, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.error)),
        const SizedBox(height: 4),
        Text(l10n.settings_privacy_body, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const ValueKey('privacy.resetData'),
          style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
          onPressed: () => _showResetDataDialog(context, l10n),
          child: Text(l10n.settings_reset_row_subtitle),
        ),
      ],
    );
  }

  Future<void> _showResetDataDialog(BuildContext context, AppLocalizations l10n) async {
    final categories = _resetCategories(l10n);
    final selected = <String>{};

    final toReset = await showDialog<List<_ResetCategory>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          icon: Icon(Icons.delete_outline, color: Theme.of(dialogContext).colorScheme.error),
          title: Text(l10n.reset_title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.reset_subtitle, style: Theme.of(dialogContext).textTheme.bodySmall),
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(dialogContext).colorScheme.errorContainer,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(l10n.reset_warning, style: TextStyle(color: Theme.of(dialogContext).colorScheme.onErrorContainer)),
                  ),
                ),
                for (final cat in categories)
                  CheckboxListTile(
                    key: ValueKey('reset.cat.${cat.$1}'),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(cat.$2),
                    subtitle: Text(cat.$3),
                    value: selected.contains(cat.$1),
                    onChanged: (v) => setDialogState(() => v == true ? selected.add(cat.$1) : selected.remove(cat.$1)),
                  ),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('reset.selectAll'),
                      onPressed: () => setDialogState(() => selected.addAll(categories.map((c) => c.$1))),
                      child: Text(l10n.action_select_all),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('reset.clearAll'),
                      onPressed: () => setDialogState(selected.clear),
                      child: Text(l10n.action_clear_plain),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.action_cancel)),
            TextButton(
              key: const ValueKey('reset.confirmSelection'),
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(categories.where((c) => selected.contains(c.$1)).toList()),
              child: Text(l10n.dialog_reset_selected),
            ),
          ],
        ),
      ),
    );

    if (toReset == null || !context.mounted) return;
    await _confirmAndPerformReset(context, l10n, toReset);
  }

  Future<void> _confirmAndPerformReset(BuildContext context, AppLocalizations l10n, List<_ResetCategory> categories) async {
    final list = categories.map((c) => '• ${c.$4}').join('\n');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber),
        title: Text(l10n.dialog_reset_following_title),
        content: SingleChildScrollView(child: Text(l10n.dialog_reset_following_message(list))),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.action_cancel)),
          TextButton(
            key: const ValueKey('reset.confirmFinal'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dialog_reset),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final resp = await widget.systemService.resetPerformance(ResetPerformanceRequest(categories: categories.map((c) => c.$1)));
      if (!context.mounted) return;
      if (resp.success) {
        await _showResetResult(context, l10n, categories, resp.resultsJson);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toast_reset_failed_with_error(resp.error))));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toast_reset_failed_with_error(e.toString()))));
    }
  }

  Future<void> _showResetResult(
      BuildContext context, AppLocalizations l10n, List<_ResetCategory> categories, String resultsJson) async {
    Map<String, dynamic>? results;
    try {
      results = jsonDecode(resultsJson) as Map<String, dynamic>;
    } catch (_) {
      results = null;
    }

    final lines = <String>[];
    for (final cat in categories) {
      final r = results?[cat.$1] as Map<String, dynamic>?;
      if (r != null && r['success'] == true) {
        final detail = r.containsKey('rowsDeleted')
            ? ' (${r['rowsDeleted']} rows)'
            : r.containsKey('filesDeleted')
                ? ' (${r['filesDeleted']} files)'
                : '';
        lines.add('• ${cat.$4}$detail');
      } else {
        lines.add('• ${cat.$4} — ${r?['error'] ?? 'failed'}');
      }
    }

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline),
        title: Text(l10n.dialog_reset_complete_title),
        content: SingleChildScrollView(child: Text(lines.join('\n'))),
        actions: [
          TextButton(key: const ValueKey('reset.resultOk'), onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.dialog_ok)),
        ],
      ),
    );
  }
}
