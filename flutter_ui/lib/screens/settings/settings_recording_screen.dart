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
        _applyButton(l10n, c, RecordingSettingsTab.capture),
      ];

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
                final result = await c.applyChanges(tab);
                if (!mounted) return;
                if (!result.ok) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Save failed')));
                }
              }
            : null,
        child: Text(l10n.settings_recording_apply_button),
      );
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
