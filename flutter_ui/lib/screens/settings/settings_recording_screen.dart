import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../widgets/storage_limit.dart';
import 'settings_recording_controller.dart';
import 'settings_recording_models.dart';
import '../../widgets/bw_choice_chip.dart';

/// Ground truth: `RecordingSettingsController.kt` — Status/Capture/Quality/
/// Storage tabs. Tab selection is pure UI state (which pane is visible),
/// kept in this widget rather than the controller, which only holds
/// settings data — matches "no business logic in widgets" in spirit, since
/// nothing here is business logic.
class SettingsRecordingScreen extends StatefulWidget {
  final RecordingSettingsController controller;

  const SettingsRecordingScreen({super.key, required this.controller});

  @override
  State<SettingsRecordingScreen> createState() => _SettingsRecordingScreenState();
}

class _SettingsRecordingScreenState extends State<SettingsRecordingScreen> {
  RecordingSettingsTab _tab = RecordingSettingsTab.status;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
    widget.controller.loadOverlayFields();
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

    // BladeWatch-htel: the tab bar sits BELOW the content, as native's does
    // (RecordingSettingsController.buildView adds the tab bar last) and as this
    // app's own Trips screen already did. Having it on top here was the one
    // structural difference between the two UIs' tab strips; the tabs
    // themselves, their order and their contents already matched.
    return Column(
      children: [
        Expanded(
          child: c.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: switch (_tab) {
                    RecordingSettingsTab.status => _statusTab(l10n, theme, c),
                    RecordingSettingsTab.capture => _captureTab(l10n, theme, c),
                    RecordingSettingsTab.quality => _qualityTab(l10n, theme, c),
                    RecordingSettingsTab.storage => _storageTab(l10n, theme, c),
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (final tab in RecordingSettingsTab.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: BwChoiceChip(
                      key: ValueKey('recording.tab.${tab.name}'),
                      label: Text(_tabLabel(l10n, tab)),
                      selected: _tab == tab,
                      onSelected: (_) => setState(() => _tab = tab),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _tabLabel(AppLocalizations l10n, RecordingSettingsTab tab) => switch (tab) {
        RecordingSettingsTab.status => l10n.settings_recording_tab_status,
        RecordingSettingsTab.capture => l10n.settings_recording_tab_capture,
        RecordingSettingsTab.quality => l10n.settings_recording_tab_quality,
        RecordingSettingsTab.storage => l10n.settings_recording_tab_storage,
      };

  List<Widget> _statusTab(AppLocalizations l10n, ThemeData theme, RecordingSettingsController c) {
    final status = c.status;
    final modeLabel = status != null ? _modeLabel(l10n, RecordingMode.fromValue(status.currentMode)) : l10n.dashboard_metric_value_pending;
    final todayCount = status != null ? '${status.normalTodayCount + status.proximityTodayCount}' : l10n.dashboard_metric_value_pending;
    return [
      Text(l10n.settings_recording_status_title, style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      ListTile(title: Text(l10n.settings_recording_status_current_state), trailing: Text(modeLabel)),
      ListTile(title: Text(l10n.settings_recording_status_today_count), trailing: Text(todayCount)),
    ];
  }

  String _modeLabel(AppLocalizations l10n, RecordingMode mode) => switch (mode) {
        RecordingMode.none => l10n.settings_recording_mode_none_label,
        RecordingMode.continuous => l10n.settings_recording_mode_continuous_label,
        RecordingMode.driveMode => l10n.settings_recording_mode_drive_label,
        RecordingMode.proximityGuard => l10n.settings_recording_mode_proximity_label,
      };

  String _modeDesc(AppLocalizations l10n, RecordingMode mode) => switch (mode) {
        RecordingMode.none => l10n.settings_recording_mode_none_desc,
        RecordingMode.continuous => l10n.settings_recording_mode_continuous_desc,
        RecordingMode.driveMode => l10n.settings_recording_mode_drive_desc,
        RecordingMode.proximityGuard => l10n.settings_recording_mode_proximity_desc,
      };

  List<Widget> _captureTab(AppLocalizations l10n, ThemeData theme, RecordingSettingsController c) => [
        Text(l10n.settings_recording_mode_title, style: theme.textTheme.titleMedium),
        Text(l10n.settings_recording_mode_description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        RadioGroup<RecordingMode>(
          groupValue: c.selectedMode,
          onChanged: (m) => c.selectMode(m!),
          child: Column(
            children: [
              for (final mode in RecordingMode.values)
                RadioListTile<RecordingMode>(
                  key: ValueKey('recording.mode.${mode.name}'),
                  value: mode,
                  title: Text(_modeLabel(l10n, mode)),
                  subtitle: Text(_modeDesc(l10n, mode)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.settings_recording_limit_title, style: theme.textTheme.titleMedium),
        Text(l10n.settings_recording_limit_description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final limit in RecordingLimit.values)
              BwChoiceChip(
                key: ValueKey('recording.limit.${limit.minutes}'),
                label: Text(l10n.settings_recording_limit_minutes(limit.minutes)),
                selected: c.selectedLimit == limit,
                onSelected: (_) => c.selectLimit(limit),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.settings_recording_priority_title, style: theme.textTheme.titleMedium),
        Text(l10n.settings_recording_priority_description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        RadioGroup<RecordingPriority>(
          groupValue: c.selectedPriority,
          onChanged: (p) => c.selectPriority(p!),
          child: Column(
            children: [
              for (final priority in RecordingPriority.values)
                RadioListTile<RecordingPriority>(
                  key: ValueKey('recording.priority.${priority.name}'),
                  value: priority,
                  title: Text(_priorityLabel(l10n, priority)),
                  subtitle: Text(_priorityDesc(l10n, priority)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _overlayFieldsSection(l10n, theme, c),
        const SizedBox(height: 16),
        _applyButton(l10n, c, RecordingSettingsTab.capture),
      ];

  /// BladeWatch-y78o.5: the burned-in telemetry overlay's field checklist for continuous
  /// (drive-mode/proximity) dashcam recording. Deliberately no VIN/location entry — see
  /// OverlayField's own doc comment. Saves each toggle immediately (not part of this tab's
  /// batch Apply flow), matching how the toggle reverts itself on a failed save rather than
  /// leaving a dirty, unsaved checkbox behind.
  Widget _overlayFieldsSection(AppLocalizations l10n, ThemeData theme, RecordingSettingsController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settings_recording_overlay_fields_title, style: theme.textTheme.titleMedium),
        Text(
          l10n.settings_recording_overlay_fields_description,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        for (final field in OverlayField.values)
          CheckboxListTile(
            key: ValueKey('recording.overlayField.${field.name}'),
            value: c.overlayFields.contains(field),
            title: Text(_overlayFieldLabel(l10n, field)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (enabled) => c.setOverlayFieldEnabled(field, enabled ?? false),
          ),
      ],
    );
  }

  String _overlayFieldLabel(AppLocalizations l10n, OverlayField field) => switch (field) {
        OverlayField.speed => l10n.settings_recording_overlay_field_speed,
        OverlayField.gear => l10n.settings_recording_overlay_field_gear,
        OverlayField.turnSignalLeft => l10n.settings_recording_overlay_field_turn_signal_left,
        OverlayField.turnSignalRight => l10n.settings_recording_overlay_field_turn_signal_right,
        OverlayField.brakePedal => l10n.settings_recording_overlay_field_brake_pedal,
        OverlayField.accelPedal => l10n.settings_recording_overlay_field_accel_pedal,
        OverlayField.seatbeltDriver => l10n.settings_recording_overlay_field_seatbelt_driver,
        OverlayField.seatbeltPassenger => l10n.settings_recording_overlay_field_seatbelt_passenger,
        OverlayField.timestamp => l10n.settings_recording_overlay_field_timestamp,
      };

  String _priorityLabel(AppLocalizations l10n, RecordingPriority priority) => switch (priority) {
        RecordingPriority.performance => l10n.settings_recording_priority_performance_label,
        RecordingPriority.reliability => l10n.settings_recording_priority_reliability_label,
      };

  String _priorityDesc(AppLocalizations l10n, RecordingPriority priority) => switch (priority) {
        RecordingPriority.performance => l10n.settings_recording_priority_performance_desc,
        RecordingPriority.reliability => l10n.settings_recording_priority_reliability_desc,
      };

  List<Widget> _qualityTab(AppLocalizations l10n, ThemeData theme, RecordingSettingsController c) => [
        Text(l10n.settings_recording_quality_title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final q in RecordingQuality.values)
              BwChoiceChip(
                key: ValueKey('recording.quality.${q.name}'),
                label: Text(q.value),
                selected: c.selectedQuality == q,
                onSelected: (_) => c.selectQuality(q),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _applyButton(l10n, c, RecordingSettingsTab.quality),
      ];

  List<Widget> _storageTab(AppLocalizations l10n, ThemeData theme, RecordingSettingsController c) {
    final storage = c.storageSettings;
    final sdAvailable = storage?.sdCardAvailable ?? false;
    return [
      Text(l10n.settings_recording_storage_title, style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      Text(l10n.settings_recording_storage_location_label, style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        children: [
          BwChoiceChip(
            key: const ValueKey('recording.storage.internal'),
            label: Text(l10n.settings_recording_storage_internal),
            selected: c.selectedStorageType == 'INTERNAL',
            onSelected: (_) => c.selectStorageType('INTERNAL'),
          ),
          BwChoiceChip(
            key: const ValueKey('recording.storage.sdCard'),
            label: Text(sdAvailable ? l10n.settings_recording_storage_sd_card : l10n.settings_recording_storage_sd_card_na),
            selected: c.selectedStorageType == 'SD_CARD',
            onSelected: sdAvailable ? (_) => c.selectStorageType('SD_CARD') : null,
          ),
        ],
      ),
      if (storage?.sdCardMountFailed ?? false) ...[
        const SizedBox(height: 8),
        Card(
          key: const ValueKey('recording.storage.sdMountFailedBanner'),
          color: theme.colorScheme.errorContainer,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settings_recording_storage_sd_mount_failed_title,
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onErrorContainer)),
                if ((storage?.sdCardMountError ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(storage!.sdCardMountError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer)),
                ],
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      Text(l10n.settings_recording_storage_limit_label, style: theme.textTheme.labelMedium),
      // formatStorageMb, not a raw megabyte count: native shows "16.0 GB"
      // where the port used to show "16384 MB" (BladeWatch-htel).
      Text(formatStorageMb(c.selectedLimitMb), style: theme.textTheme.bodyMedium),
      Slider(
        key: const ValueKey('recording.storage.limitSlider'),
        min: c.storageLimitMinMb.toDouble(),
        max: c.storageLimitMaxMb.toDouble(),
        // Native's SeekBar is one notch per 100 MB; the port's slider was
        // continuous, so dragging it produced values like 3847 MB.
        divisions: storageSliderDivisions(c.storageLimitMinMb, c.storageLimitMaxMb),
        value: c.selectedLimitMb.toDouble().clamp(c.storageLimitMinMb.toDouble(), c.storageLimitMaxMb.toDouble()),
        onChanged: (v) => c.setStorageLimitMb(v.round()),
      ),
      const SizedBox(height: 8),
      if (storage != null) ...[
        // BladeWatch-3118: label + right-aligned value on every row, matching
        // native's infoRow(). Usage and Files used to show a bare value with
        // nothing naming it, and Path put its value on a second line while the
        // two rows below it right-aligned theirs.
        ListTile(
          title: Text(l10n.settings_recording_storage_usage_label),
          trailing: Text(l10n.settings_recording_storage_usage(
              '${(storage.recordingsSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB', '${storage.limitMb} MB')),
        ),
        ListTile(
          title: Text(l10n.settings_recording_storage_files_label),
          trailing: Text(l10n.settings_recording_storage_files(storage.recordingsCount)),
        ),
        if (storage.recordingsPath.isNotEmpty)
          ListTile(
            title: Text(l10n.settings_recording_storage_path_label),
            trailing: bwPathValue(storage.recordingsPath),
          ),
        if (sdAvailable && storage.sdCardFreeFormatted.isNotEmpty)
          ListTile(title: Text(l10n.settings_recording_storage_sd_free_label), trailing: Text(storage.sdCardFreeFormatted)),
        if (storage.internalFreeFormatted.isNotEmpty)
          ListTile(title: Text(l10n.settings_recording_storage_internal_free_label), trailing: Text(storage.internalFreeFormatted)),
      ],
      const SizedBox(height: 16),
      _applyButton(l10n, c, RecordingSettingsTab.storage),
      if (sdAvailable) ...[
        const SizedBox(height: 16),
        _FormatDriveCard(l10n: l10n, theme: theme, controller: c),
      ],
      const SizedBox(height: 16),
      _SyncCatalogCard(l10n: l10n, theme: theme, controller: c),
    ];
  }

  Widget _applyButton(AppLocalizations l10n, RecordingSettingsController c, RecordingSettingsTab tab) => FilledButton(
        key: ValueKey('recording.apply.${tab.name}'),
        onPressed: c.dirty
            ? () async {
                if (tab == RecordingSettingsTab.storage) {
                  await _applyStorage(l10n, c);
                  return;
                }
                final result = await c.applyChanges(tab);
                if (!mounted) return;
                if (!result.ok) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? l10n.toast_failed_to_save_short)));
                }
              }
            : null,
        child: Text(l10n.settings_recording_apply_button),
      );

  /// BladeWatch-gyg1.4: lowering the recordings limit can silently delete existing clips.
  /// Preview the real impact first; only apply once the owner has seen and confirmed it (or
  /// there is nothing to confirm). Cancelling must leave SetStorageSettings uncalled -- this
  /// is why the preview and the apply are two separate controller calls, not one.
  Future<void> _applyStorage(AppLocalizations l10n, RecordingSettingsController c) async {
    final impact = await c.previewStorageLimitImpact();
    // The owner can leave this screen while the preview RPC is in flight, and
    // _confirmStorageLimitChange reads State.context, which throws once unmounted.
    // use_build_context_synchronously does not flag it: the await is here and the context
    // read is in that method, and the lint does not follow across the call.
    if (!mounted) return;
    if (impact != null) {
      final confirmed = await _confirmStorageLimitChange(l10n, impact);
      if (confirmed != true) return;
      if (!mounted) return;
    }
    final result = await c.applyChanges(RecordingSettingsTab.storage);
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? l10n.toast_failed_to_save_short)));
    }
  }

  Future<bool?> _confirmStorageLimitChange(AppLocalizations l10n, StorageLimitImpact impact) {
    final known = impact.status == StorageLimitImpactStatus.known;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('recording.storageConfirm.dialog'),
        title: Text(known ? l10n.settings_recording_storage_confirm_title : l10n.settings_recording_storage_confirm_unknown_title),
        content: Text(known
            ? l10n.settings_recording_storage_confirm_message(
                impact.fileCount, formatStorageMb((impact.totalBytes / (1024 * 1024)).round()))
            : l10n.settings_recording_storage_confirm_unknown_message),
        actions: [
          TextButton(
              key: const ValueKey('recording.storageConfirm.cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.action_cancel)),
          FilledButton(
              key: const ValueKey('recording.storageConfirm.confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.dialog_delete)),
        ],
      ),
    );
  }
}

class _FormatDriveCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final RecordingSettingsController controller;

  const _FormatDriveCard({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.formatState;
    return Card(
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: theme.colorScheme.error), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settings_recording_format_title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.settings_recording_format_warning, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            switch (state.state) {
              FormatDriveState.idle => OutlinedButton(
                  key: const ValueKey('recording.format.start'),
                  onPressed: controller.startFormat,
                  child: Text(l10n.settings_recording_format_button),
                ),
              FormatDriveState.confirming => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: const ValueKey('recording.format.confirm'),
                      style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                      onPressed: controller.confirmFormat,
                      child: Text(l10n.settings_recording_format_confirm),
                    ),
                    TextButton(onPressed: controller.cancelFormat, child: Text(l10n.action_cancel)),
                  ],
                ),
              FormatDriveState.running => Text(l10n.settings_recording_format_running),
              FormatDriveState.succeeded || FormatDriveState.failed => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.message ?? '', key: const ValueKey('recording.format.result')),
                    TextButton(onPressed: controller.dismissFormatResult, child: Text(l10n.settings_recording_dismiss)),
                  ],
                ),
            },
          ],
        ),
      ),
    );
  }
}

class _SyncCatalogCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final RecordingSettingsController controller;

  const _SyncCatalogCard({required this.l10n, required this.theme, required this.controller});

  @override
  Widget build(BuildContext context) {
    final state = controller.syncState;
    return Card(
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settings_recording_sync_title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.settings_recording_sync_description, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            switch (state.state) {
              SyncDriveState.idle =>
                OutlinedButton(key: const ValueKey('recording.sync.start'), onPressed: controller.startSync, child: Text(l10n.settings_recording_sync_button)),
              SyncDriveState.running => Text(l10n.settings_recording_sync_running),
              SyncDriveState.succeeded || SyncDriveState.failed => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.message ?? '', key: const ValueKey('recording.sync.result')),
                    TextButton(onPressed: controller.dismissSyncResult, child: Text(l10n.settings_recording_dismiss)),
                  ],
                ),
            },
          ],
        ),
      ),
    );
  }
}
