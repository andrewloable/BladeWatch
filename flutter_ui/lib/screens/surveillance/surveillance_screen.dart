import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../gen/l10n/app_localizations.dart';
import 'surveillance_controller.dart';
import 'surveillance_models.dart';

/// Ground truth: `SurveillanceSettingsController.kt` — General/Detection/
/// Recording/Storage/Advanced tabs. Tab selection is pure UI state (kept in
/// this widget, not the controller), matching `SettingsRecordingScreen`'s
/// identical split.
///
/// Mounted from BOTH of this screen's native entry points (standalone
/// `BwRoutes.surveillance` and the Settings sub-rail's Surveillance row) —
/// each site constructs its own controller instance, matching how native's
/// two fragments each construct their own `SurveillanceSettingsController`.
class SurveillanceSettingsScreen extends StatefulWidget {
  final SurveillanceSettingsController controller;

  const SurveillanceSettingsScreen({super.key, required this.controller});

  @override
  State<SurveillanceSettingsScreen> createState() => _SurveillanceSettingsScreenState();
}

class _SurveillanceSettingsScreenState extends State<SurveillanceSettingsScreen> {
  SurveillanceSettingsTab _tab = SurveillanceSettingsTab.general;

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (final tab in SurveillanceSettingsTab.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      key: ValueKey('surveillance.tab.${tab.name}'),
                      label: Text(_tabLabel(l10n, tab)),
                      selected: _tab == tab,
                      onSelected: (_) => setState(() => _tab = tab),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: c.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: switch (_tab) {
                    SurveillanceSettingsTab.general => _generalTab(l10n, theme, c),
                    SurveillanceSettingsTab.detection => _detectionTab(l10n, theme, c),
                    SurveillanceSettingsTab.recording => _recordingTab(l10n, theme, c),
                    SurveillanceSettingsTab.storage => _storageTab(l10n, theme, c),
                    SurveillanceSettingsTab.advanced => _advancedTab(l10n, theme, c),
                  },
                ),
        ),
      ],
    );
  }

  String _tabLabel(AppLocalizations l10n, SurveillanceSettingsTab tab) => switch (tab) {
        SurveillanceSettingsTab.general => l10n.surveillance_tab_general,
        SurveillanceSettingsTab.detection => l10n.surveillance_tab_detection,
        SurveillanceSettingsTab.recording => l10n.surveillance_tab_recording,
        SurveillanceSettingsTab.storage => l10n.surveillance_tab_storage,
        SurveillanceSettingsTab.advanced => l10n.surveillance_tab_advanced,
      };

  // ─────────────────────────── GENERAL ─────────────────────────────────

  List<Widget> _generalTab(AppLocalizations l10n, ThemeData theme, SurveillanceSettingsController c) {
    final status = c.status;
    return [
      Text(l10n.surveillance_general_title, style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      SwitchListTile(
        key: const ValueKey('surveillance.enable'),
        title: Text(l10n.surveillance_general_enable),
        value: c.editEnabled,
        onChanged: (v) => c.toggleSurveillance(v),
      ),
      ListTile(
        title: Text(l10n.surveillance_general_status),
        trailing: Text(status?.isRunning == true ? l10n.surveillance_general_status_running : l10n.surveillance_general_status_idle),
      ),
      ListTile(title: Text(l10n.surveillance_general_events_today), trailing: Text('${status?.eventsToday ?? 0}')),
    ];
  }

  // ─────────────────────────── DETECTION ───────────────────────────────

  List<Widget> _detectionTab(AppLocalizations l10n, ThemeData theme, SurveillanceSettingsController c) => [
        ..._safeLocationsSection(l10n, theme, c),
        const SizedBox(height: 16),
        Text(l10n.surveillance_detection_title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(l10n.surveillance_detection_preset_label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final preset in kEnvironmentPresets)
              ChoiceChip(
                key: ValueKey('surveillance.preset.$preset'),
                label: Text(_presetLabel(l10n, preset)),
                selected: c.editPreset == preset,
                onSelected: (_) => c.selectPreset(preset),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.surveillance_detection_sensitivity_label(c.editSensitivity), style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final level in [1, 2, 3, 4, 5])
              ChoiceChip(
                key: ValueKey('surveillance.sensitivity.$level'),
                label: Text('$level'),
                selected: c.editSensitivity == level,
                onSelected: (_) => c.selectSensitivity(level),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.surveillance_detection_objects_label, style: theme.textTheme.labelMedium),
        SwitchListTile(
          key: const ValueKey('surveillance.detect.person'),
          title: Text(l10n.surveillance_detection_object_person),
          value: c.editDetectPerson,
          onChanged: c.setDetectPerson,
        ),
        SwitchListTile(
          key: const ValueKey('surveillance.detect.car'),
          title: Text(l10n.surveillance_detection_object_car),
          value: c.editDetectCar,
          onChanged: c.setDetectCar,
        ),
        SwitchListTile(
          key: const ValueKey('surveillance.detect.bike'),
          title: Text(l10n.surveillance_detection_object_bike),
          value: c.editDetectBike,
          onChanged: c.setDetectBike,
        ),
        const SizedBox(height: 16),
        _applyButton(l10n, c, SurveillanceSettingsTab.detection),
      ];

  String _presetLabel(AppLocalizations l10n, String preset) => switch (preset) {
        'OUTDOOR' => l10n.surveillance_preset_outdoor,
        'GARAGE' => l10n.surveillance_preset_garage,
        'STREET' => l10n.surveillance_preset_street,
        _ => l10n.surveillance_preset_custom,
      };

  List<Widget> _safeLocationsSection(AppLocalizations l10n, ThemeData theme, SurveillanceSettingsController c) {
    final hasGpsFix = c.currentLat != 0 || c.currentLng != 0;
    final showMap = hasGpsFix || c.safeZones.isNotEmpty;
    return [
      Text(l10n.surveillance_safe_locations_title, style: theme.textTheme.titleMedium),
      Text(l10n.surveillance_safe_locations_subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      SwitchListTile(
        key: const ValueKey('surveillance.safeLocations.enable'),
        title: Text(l10n.surveillance_safe_locations_enable),
        value: c.safeLocFeatureEnabled,
        onChanged: (v) => c.toggleSafeLocations(v),
      ),
      if (showMap) ...[
        SizedBox(
          key: const ValueKey('surveillance.safeLocations.map'),
          height: 200,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(hasGpsFix ? c.currentLat : (c.safeZones.firstOrNull?.lat ?? 0), hasGpsFix ? c.currentLng : (c.safeZones.firstOrNull?.lng ?? 0)),
              initialZoom: 15,
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'net.bladewatch.flutter'),
              MarkerLayer(markers: [
                for (final zone in c.safeZones)
                  Marker(point: LatLng(zone.lat, zone.lng), child: const Icon(Icons.shield, color: Colors.teal)),
                if (hasGpsFix) Marker(point: LatLng(c.currentLat, c.currentLng), child: const Icon(Icons.my_location, color: Colors.blue)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      if (c.safeZones.isNotEmpty)
        for (final zone in c.safeZones)
          ListTile(
            key: ValueKey('surveillance.safeLocations.zone.${zone.id}'),
            title: Text(l10n.surveillance_safe_locations_zone_label(zone.name, zone.radiusM)),
            trailing: IconButton(
              key: ValueKey('surveillance.safeLocations.zone.delete.${zone.id}'),
              icon: const Icon(Icons.close),
              onPressed: () => c.deleteSafeZone(zone.id),
            ),
          )
      else
        Text(l10n.surveillance_safe_locations_empty, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      if (hasGpsFix)
        OutlinedButton(
          key: const ValueKey('surveillance.safeLocations.addCurrent'),
          onPressed: c.addSafeZoneAtCurrentLocation,
          child: Text(l10n.surveillance_safe_locations_add_current),
        )
      else
        Text(l10n.surveillance_safe_locations_no_gps, style: theme.textTheme.bodySmall),
    ];
  }

  // ─────────────────────────── RECORDING ────────────────────────────────

  List<Widget> _recordingTab(AppLocalizations l10n, ThemeData theme, SurveillanceSettingsController c) => [
        Text(l10n.surveillance_recording_title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(l10n.surveillance_recording_pre_label(c.editPreRecord), style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final seconds in kPreRecordOptionsSeconds)
              ChoiceChip(
                key: ValueKey('surveillance.preRecord.$seconds'),
                label: Text(l10n.surveillance_seconds_value(seconds)),
                selected: c.editPreRecord == seconds,
                onSelected: (_) => c.selectPreRecord(seconds),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.surveillance_recording_post_label(c.editPostRecord), style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final seconds in kPostRecordOptionsSeconds)
              ChoiceChip(
                key: ValueKey('surveillance.postRecord.$seconds'),
                label: Text(l10n.surveillance_seconds_value(seconds)),
                selected: c.editPostRecord == seconds,
                onSelected: (_) => c.selectPostRecord(seconds),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _applyButton(l10n, c, SurveillanceSettingsTab.recording),
      ];

  // ─────────────────────────── STORAGE ─────────────────────────────────

  List<Widget> _storageTab(AppLocalizations l10n, ThemeData theme, SurveillanceSettingsController c) {
    final storage = c.storageSettings;
    final sdAvailable = storage?.sdCardAvailable ?? false;
    return [
      Text(l10n.surveillance_storage_title, style: theme.textTheme.titleMedium),
      const SizedBox(height: 12),
      Text(l10n.surveillance_storage_location_label, style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            key: const ValueKey('surveillance.storage.internal'),
            label: Text(l10n.surveillance_storage_internal),
            selected: c.editStorageType == 'INTERNAL',
            onSelected: (_) => c.selectStorageType('INTERNAL'),
          ),
          ChoiceChip(
            key: const ValueKey('surveillance.storage.sdCard'),
            label: Text(sdAvailable ? l10n.surveillance_storage_sd_card : l10n.surveillance_storage_sd_card_na),
            selected: c.editStorageType == 'SD_CARD',
            onSelected: sdAvailable ? (_) => c.selectStorageType('SD_CARD') : null,
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(l10n.surveillance_storage_limit_label, style: theme.textTheme.labelMedium),
      Text('${c.editStorageLimitMb} MB', style: theme.textTheme.bodyMedium),
      Slider(
        key: const ValueKey('surveillance.storage.limitSlider'),
        min: c.storageLimitMinMb.toDouble(),
        max: c.storageLimitMaxMb.toDouble(),
        value: c.editStorageLimitMb.toDouble().clamp(c.storageLimitMinMb.toDouble(), c.storageLimitMaxMb.toDouble()),
        onChanged: (v) => c.setStorageLimitMb(v.round()),
      ),
      const SizedBox(height: 8),
      if (storage != null) ...[
        ListTile(
          title: Text(l10n.surveillance_storage_usage('${(storage.surveillanceSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB', '${storage.limitMb} MB')),
        ),
        ListTile(title: Text(l10n.surveillance_storage_files(storage.surveillanceCount))),
        if (storage.path.isNotEmpty) ListTile(title: Text(l10n.surveillance_storage_path_label), subtitle: Text(storage.path)),
      ],
      const SizedBox(height: 16),
      _applyButton(l10n, c, SurveillanceSettingsTab.storage),
      if (sdAvailable) ...[
        const SizedBox(height: 16),
        _FormatDriveCard(l10n: l10n, theme: theme, controller: c),
      ],
      const SizedBox(height: 16),
      _SyncCatalogCard(l10n: l10n, theme: theme, controller: c),
    ];
  }

  // ─────────────────────────── ADVANCED ─────────────────────────────────

  List<Widget> _advancedTab(AppLocalizations l10n, ThemeData theme, SurveillanceSettingsController c) => [
        Text(l10n.surveillance_advanced_camera_title, style: theme.textTheme.titleMedium),
        SwitchListTile(
          key: const ValueKey('surveillance.camera.front'),
          title: Text(l10n.surveillance_advanced_camera_front),
          value: c.editCameraFront,
          onChanged: c.setCameraFront,
        ),
        SwitchListTile(
          key: const ValueKey('surveillance.camera.right'),
          title: Text(l10n.surveillance_advanced_camera_right),
          value: c.editCameraRight,
          onChanged: c.setCameraRight,
        ),
        SwitchListTile(
          key: const ValueKey('surveillance.camera.rear'),
          title: Text(l10n.surveillance_advanced_camera_rear),
          value: c.editCameraRear,
          onChanged: c.setCameraRear,
        ),
        SwitchListTile(
          key: const ValueKey('surveillance.camera.left'),
          title: Text(l10n.surveillance_advanced_camera_left),
          value: c.editCameraLeft,
          onChanged: c.setCameraLeft,
        ),
        const SizedBox(height: 16),
        Text(l10n.surveillance_advanced_ai_title, style: theme.textTheme.titleMedium),
        SwitchListTile(
          key: const ValueKey('surveillance.ai.enabled'),
          title: Text(l10n.surveillance_advanced_ai_detection),
          value: c.editAiEnabled,
          onChanged: c.setAiEnabled,
        ),
        SwitchListTile(
          key: const ValueKey('surveillance.night.enabled'),
          title: Text(l10n.surveillance_advanced_night_mode),
          value: c.editNightMode,
          onChanged: c.setNightMode,
        ),
        const SizedBox(height: 8),
        Text(l10n.surveillance_advanced_deterrent_label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final action in kDeterrentActions)
              ChoiceChip(
                key: ValueKey('surveillance.deterrent.$action'),
                label: Text(_deterrentLabel(l10n, action)),
                selected: c.editDeterrent == action,
                onSelected: (_) => c.selectDeterrent(action),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _applyButton(l10n, c, SurveillanceSettingsTab.advanced),
      ];

  String _deterrentLabel(AppLocalizations l10n, String action) => switch (action) {
        'horn' => l10n.surveillance_deterrent_horn,
        'flash' => l10n.surveillance_deterrent_flash,
        _ => l10n.surveillance_deterrent_silent,
      };

  Widget _applyButton(AppLocalizations l10n, SurveillanceSettingsController c, SurveillanceSettingsTab tab) => FilledButton(
        key: ValueKey('surveillance.apply.${tab.name}'),
        onPressed: () async {
          final result = await c.applyChanges(tab);
          if (!mounted) return;
          if (!result.ok) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? l10n.surveillance_apply_failed)));
          }
        },
        child: Text(l10n.surveillance_apply_button),
      );
}

class _FormatDriveCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final SurveillanceSettingsController controller;

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
            Text(l10n.surveillance_format_title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.surveillance_format_warning, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            switch (state.state) {
              FormatDriveState.idle => OutlinedButton(
                  key: const ValueKey('surveillance.format.start'),
                  onPressed: controller.startFormat,
                  child: Text(l10n.surveillance_format_button),
                ),
              FormatDriveState.confirming => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: const ValueKey('surveillance.format.confirm'),
                      style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                      onPressed: controller.confirmFormat,
                      child: Text(l10n.surveillance_format_confirm),
                    ),
                    TextButton(
                        key: const ValueKey('surveillance.format.cancel'), onPressed: controller.cancelFormat, child: Text(l10n.action_cancel)),
                  ],
                ),
              FormatDriveState.running => Text(l10n.surveillance_format_running),
              FormatDriveState.succeeded || FormatDriveState.failed => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.message ?? '', key: const ValueKey('surveillance.format.result')),
                    TextButton(
                        key: const ValueKey('surveillance.format.dismiss'),
                        onPressed: controller.dismissFormatResult,
                        child: Text(l10n.surveillance_dismiss)),
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
  final SurveillanceSettingsController controller;

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
            Text(l10n.surveillance_sync_title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.surveillance_sync_description, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            switch (state.state) {
              SyncDriveState.idle => OutlinedButton(
                  key: const ValueKey('surveillance.sync.start'), onPressed: controller.startSync, child: Text(l10n.surveillance_sync_button)),
              SyncDriveState.running => Text(l10n.surveillance_sync_running),
              SyncDriveState.succeeded || SyncDriveState.failed => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.message ?? '', key: const ValueKey('surveillance.sync.result')),
                    TextButton(
                        key: const ValueKey('surveillance.sync.dismiss'),
                        onPressed: controller.dismissSyncResult,
                        child: Text(l10n.surveillance_dismiss)),
                  ],
                ),
            },
          ],
        ),
      ),
    );
  }
}
