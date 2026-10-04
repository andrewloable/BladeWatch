import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../car/car_store.dart';
import '../../i18n.dart';
import '../common/format.dart';
import '../common/hud_style.dart';
import '../common/loader.dart';
import '../trips/trips_screen.dart' show TripSettingsForm;

/// Settings: this app's own (language, the paired car) and the car's (capture, quality,
/// storage, language, overlay) -- the web settings page's counterpart. Sentry detection settings
/// live on the Surveillance screen, as on the web.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store, required this.onLanguage, required this.onUnpair});

  final CarStore store;
  final Future<void> Function(String? lang) onLanguage;
  final Future<void> Function() onUnpair;

  static const recordingModes = ['NONE', 'CONTINUOUS', 'DRIVE_MODE', 'PROXIMITY_GUARD'];
  static const qualities = ['ECONOMY', 'STANDARD', 'HIGH', 'PREMIUM', 'MAX'];

  /// The clip lengths the car accepts (it rejects anything else).
  static const segmentMinutes = [1, 5, 10];

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with LoadersState {
  late final _rpc = context.session.rpc;
  late final _settings = SettingsServiceClient(_rpc);
  late final _storage = StorageServiceClient(_rpc);
  late final _data = loader(() async => (
        status: await SystemServiceClient(_rpc).getStatus(GetStatusRequest()),
        quality: await _settings.getQuality(GetQualityRequest()),
        locale: await _settings.getLocale(GetLocaleRequest()),
        overlay: await _settings.getStatusOverlay(GetStatusOverlayRequest()),
        storage: await _storage.getStorageSettings(GetStorageSettingsRequest()),
        fields: await _overlayFields(),
      ));

  /// The recording overlay's fields (BladeWatch-rdtj.67); null when the car does not say, so an
  /// older car still gets the rest of Settings.
  Future<GetTelemetryOverlayFieldsResponse?> _overlayFields() async {
    try {
      final r = await _settings.getTelemetryOverlayFields(GetTelemetryOverlayFieldsRequest());
      return r.availableFields.isEmpty ? null : r;
    } catch (_) {
      return null;
    }
  }

  /// The in-car app's Settings > Trips: costs, currency, distance unit and trip storage.
  void _openTrips() {
    final tr = context.tr;
    final session = context.session;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => TrScope(
        tr: tr,
        child: SessionScope(
          session: session,
          child: Scaffold(
            body: SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: HudTitleBar(
                    title: tr('trips.trip_analytics').toUpperCase(),
                    onBack: () => Navigator.of(context).maybePop(),
                    backTooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                ),
                const Expanded(child: TripSettingsForm()),
              ]),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _syncLibrary() async {
    final tr = context.tr;
    SyncCatalogResponse? r;
    final ok = await act(context, () async {
      r = await RecordingsServiceClient(_rpc).syncCatalog(SyncCatalogRequest());
      if (!r!.success) throw StateError(r!.error);
    }, failed: tr('errors.save_failed'));
    if (ok && mounted && r != null) say(ScaffoldMessenger.of(context), tr('companion.sync_result', {'added': r!.added, 'removed': r!.removed}));
  }
  final _recLimit = TextEditingController();
  final _survLimit = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _recLimit.dispose();
    _survLimit.dispose();
    super.dispose();
  }

  Future<void> _save(Future<void> Function() action) async {
    await act(context, action, done: context.tr('toast.saved'), failed: context.tr('errors.save_failed'));
    await _data.load();
  }

  Future<bool> _confirm(String title, String body, {String? yes, bool destructive = false}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('common.cancel'))),
            FilledButton(
              key: const ValueKey('settings.confirm'),
              style: destructive ? destructiveStyle(context) : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(yes ?? context.tr('common.ok')),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _cleanup() async {
    final tr = context.tr;
    final preview = await _storage.previewCleanup(PreviewCleanupRequest());
    if (!mounted) return;
    if (preview.totalDeletableCount == 0) {
      say(ScaffoldMessenger.of(context), tr('recording.cdr_no_cleanup'));
      return;
    }
    final detail = '${preview.totalDeletableCount} ${tr('settings.files')} · ${Fmt.bytes(preview.totalDeletableBytes.toInt())}';
    if (!await _confirm(tr('companion.cleanup'), detail, destructive: true)) return;
    final r = await _storage.triggerCleanup(TriggerCleanupRequest());
    if (mounted) {
      say(ScaffoldMessenger.of(context), r.success ? tr('recording.cdr_freed', {'size': Fmt.bytes(r.bytesFreed.toInt()), 'files': r.filesDeleted}) : tr('recording.cdr_cleanup_failed'));
    }
  }

  Future<void> _format() async {
    final tr = context.tr;
    final volumes = (await _storage.listFormatVolumes(ListFormatVolumesRequest())).volumes;
    if (!mounted) return;
    if (volumes.isEmpty) {
      say(ScaffoldMessenger.of(context), tr('recording.sd_card_not_detected'));
      return;
    }
    final v = volumes.first;
    // Twice, on purpose: this erases a drive in a car the owner may be nowhere near.
    if (!await _confirm(tr('settings.format_external_drive'), '${tr('settings.format_external_hint')}\n\n${v.mountPath.isEmpty ? v.volumeId : v.mountPath}', destructive: true)) return;
    if (!mounted || !await _confirm(tr('settings.format_external_drive'), tr('settings.tap_again_erase'), yes: tr('settings.format_sd_usb'), destructive: true)) return;
    await _save(() async {
      final r = await _storage.formatVolume(FormatVolumeRequest(volumeId: v.volumeId));
      if (!r.success) throw StateError(r.error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final store = widget.store;
    final app = Section(title: tr('companion.this_app'), children: [
      DropdownButtonFormField<String>(
        isExpanded: true, // long names ellipsize at a large text size (BladeWatch-rdtj.55)
        key: const ValueKey('settings.appLanguage'),
        initialValue: store.language ?? '',
        decoration: InputDecoration(labelText: tr('settings.app_language')),
        items: [
          DropdownMenuItem(value: '', child: Text(tr('companion.follow_device'))),
          for (final l in Tr.languages) DropdownMenuItem(value: l, child: Text(Tr.nameOf(l))),
        ],
        onChanged: (l) => widget.onLanguage(l == null || l.isEmpty ? null : l),
      ),
      if (store.car != null) ...[const SizedBox(height: 8), InfoRow(tr('dashboard.device_id'), store.car!.deviceId)],
      const SizedBox(height: 8),
      OutlinedButton(
        key: const ValueKey('settings.unpair'),
        onPressed: () async {
          if (await _confirm(tr('companion.unpair'), tr('companion.unpair_hint'), destructive: true)) await widget.onUnpair();
        },
        child: Text(tr('companion.unpair')),
      ),
    ]);
    return LoaderView(
      loader: _data,
      builder: (context, v) {
        final st = v.storage;
        if (!_filled) {
          _filled = true;
          _recLimit.text = '${st.recordingsLimitMb}';
          _survLimit.text = '${st.surveillanceLimitMb}';
        }
        final mode = v.status.recordingStatus.configuredMode;
        final qualities = v.quality.recordingQualityOptions.isEmpty
            ? SettingsScreen.qualities
            : v.quality.recordingQualityOptions.keys.toList();
        final codecs = v.quality.codecOptions.isEmpty ? const {'H264': 'H.264', 'H265': 'H.265'} : v.quality.codecOptions;
        final langs = v.locale.supported.keys.toList()..sort();
        return PageList(children: [
          app,
          Section(title: tr('settings.recording_mode_acc'), children: [
            Text(tr('settings.recording_mode_hint')),
            for (final m in SettingsScreen.recordingModes)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                // The chosen mode is the accent-bordered row: its state is real (the car's configured mode).
                child: HudListRow(
                  key: ValueKey('settings.mode.$m'),
                  leading: Icon(m == mode ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20),
                  title: tr('companion.mode_${m.toLowerCase()}'),
                  selected: m == mode,
                  onTap: m == mode ? null : () => _save(() => _settings.setRecordingMode(SetRecordingModeRequest(mode: m))),
                ),
              ),
          ]),
          Section(title: tr('settings.recording_quality'), children: [
            DropdownButtonFormField<String>(
              isExpanded: true, // long names ellipsize at a large text size (BladeWatch-rdtj.55)
              key: const ValueKey('settings.quality'),
              initialValue: qualities.contains(v.quality.recordingQuality) ? v.quality.recordingQuality : null,
              decoration: InputDecoration(labelText: tr('settings.quality_tier')),
              items: [for (final q in qualities) DropdownMenuItem(value: q, child: Text(q))],
              onChanged: (q) => _save(() => _settings.setQuality(SetQualityRequest(recordingQuality: q, codec: v.quality.codec))),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true, // long names ellipsize at a large text size (BladeWatch-rdtj.55)
              key: const ValueKey('settings.codec'),
              initialValue: codecs.containsKey(v.quality.codec) ? v.quality.codec : null,
              decoration: InputDecoration(labelText: tr('settings.video_codec')),
              items: [for (final e in codecs.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (c) => _save(() => _settings.setQuality(SetQualityRequest(recordingQuality: v.quality.recordingQuality, codec: c))),
            ),
            // How long each file runs before the next starts, as the web offers (BladeWatch-rdtj.49).
            // Sent alone: the car changes only the fields a SetQuality carries.
            const SizedBox(height: 12),
            Text(tr('companion.segment_length'), style: Theme.of(context).textTheme.titleSmall),
            Text(tr('companion.segment_hint'), style: Theme.of(context).textTheme.bodySmall),
            Wrap(spacing: 8, children: [
              for (final m in SettingsScreen.segmentMinutes)
                ChoiceChip(
                  showCheckmark: false,
                  key: ValueKey('settings.segment.$m'),
                  label: Text(tr('companion.minutes', {'count': m})),
                  selected: v.quality.recordingSegmentMinutes == m,
                  onSelected: (_) => _save(() => _settings.setQuality(SetQualityRequest(recordingSegmentMinutes: m))),
                ),
            ]),
          ]),
          Section(title: tr('settings.recording_storage'), children: [
            InfoRow(tr('settings.recordings'), '${st.recordingsCount} · ${Fmt.bytes(st.recordingsSizeBytes.toInt())}'),
            InfoRow(tr('companion.surveillance_clips'), '${st.surveillanceCount} · ${Fmt.bytes(st.surveillanceSizeBytes.toInt())}'),
            InfoRow(tr('settings.internal_free'), st.internalFreeFormatted),
            if (st.sdCardAvailable) InfoRow(tr('settings.sd_card_free'), st.sdCardFreeFormatted),
            // Where new recordings go (BladeWatch-rdtj.49). Asked first; the limits go along
            // unchanged, since the car takes them all in one request.
            const SizedBox(height: 8),
            Text(tr('companion.save_to'), style: Theme.of(context).textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              for (final (place, key) in [('INTERNAL', 'companion.place_internal'), ('SD_CARD', 'companion.place_sd')])
                ChoiceChip(
                  showCheckmark: false,
                  key: ValueKey('settings.saveTo.$place'),
                  label: Text(tr(key)),
                  selected: st.recordingsStorageType == place,
                  onSelected: st.recordingsStorageType == place || (place == 'SD_CARD' && !st.sdCardAvailable)
                      ? null
                      : (_) async {
                          if (!await _confirm(tr('companion.save_to'), tr('companion.save_to_confirm', {'place': tr(key)}))) return;
                          await _save(() => _storage.setStorageSettings(SetStorageSettingsRequest(
                                recordingsLimitMb: st.recordingsLimitMb,
                                surveillanceLimitMb: st.surveillanceLimitMb,
                                recordingsStorageType: place,
                                surveillanceStorageType: st.surveillanceStorageType,
                              )));
                        },
                ),
            ]),
            if (!st.sdCardAvailable) Text(tr('recording.sd_card_not_detected'), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('settings.recLimit'),
              controller: _recLimit,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${tr('settings.recordings')} · ${tr('settings.mb_limit')}'),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('settings.survLimit'),
              controller: _survLimit,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${tr('companion.surveillance_clips')} · ${tr('settings.mb_limit')}'),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton(
                key: const ValueKey('settings.storageApply'),
                onPressed: () => _save(() => _storage.setStorageSettings(SetStorageSettingsRequest(
                      recordingsLimitMb: Int64.parseInt(_recLimit.text.trim()),
                      surveillanceLimitMb: Int64.parseInt(_survLimit.text.trim()),
                      recordingsStorageType: st.recordingsStorageType,
                      surveillanceStorageType: st.surveillanceStorageType,
                    ))),
                child: Text(tr('settings.apply_changes')),
              ),
              OutlinedButton(key: const ValueKey('settings.cleanup'), onPressed: _cleanup, child: Text(tr('companion.cleanup'))),
              OutlinedButton(
                key: const ValueKey('settings.sync'),
                onPressed: () => _save(() => RecordingsServiceClient(_rpc).syncCatalog(SyncCatalogRequest())),
                child: Text(tr('settings.sync_database')),
              ),
              if (st.sdCardAvailable)
                OutlinedButton(key: const ValueKey('settings.format'), onPressed: _format, child: Text(tr('settings.format_sd_usb'))),
            ]),
          ]),
          // BladeWatch-rdtj.67: where the owner looks for costs and currency.
          Section(title: tr('companion.trips_costs'), children: [
            HudListRow(
              key: const ValueKey('settings.trips'),
              icon: Icons.route_outlined,
              // Named for what it opens, not its first field: it held fuel costs under "Electricity
              // Rate" and nobody found the currency in it (the owner, 2026-10-04).
              title: tr('trips.trip_analytics'),
              subtitle: [
                tr('trips.currency'),
                tr('trip.settings.elec_rate_label'),
                tr('trips.fuel_cost'),
                tr('trip.settings.distance_unit'),
                tr('trips.storage_location'),
              ].join(' · '),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: _openTrips,
            ),
          ]),
          Section(title: tr('companion.car_language'), children: [
            DropdownButtonFormField<String>(
              isExpanded: true, // long names ellipsize at a large text size (BladeWatch-rdtj.55)
              key: const ValueKey('settings.carLanguage'),
              initialValue: langs.contains(v.locale.lang) ? v.locale.lang : null,
              decoration: InputDecoration(labelText: tr('settings.language')),
              items: [for (final l in langs) DropdownMenuItem(value: l, child: Text(Tr.nameOf(l)))],
              onChanged: (l) => _save(() => _settings.setLocale(SetLocaleRequest(lang: l))),
            ),
          ]),
          Section(title: tr('settings.overlay_indicators'), children: [
            SwitchListTile(
              key: const ValueKey('settings.overlayCamera'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr('settings.camera_recording_indicator')),
              value: v.overlay.cameraVisible,
              onChanged: (on) => _save(() => _settings.setStatusOverlay(SetStatusOverlayRequest(cameraVisible: on, setCameraVisible: true))),
            ),
            SwitchListTile(
              key: const ValueKey('settings.overlayTrip'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr('settings.trip_indicator')),
              value: v.overlay.tripVisible,
              onChanged: (on) => _save(() => _settings.setStatusOverlay(SetStatusOverlayRequest(tripVisible: on, setTripVisible: true))),
            ),
          ]),
          // What the dashcam recording's overlay shows, as the in-car app edits it (continuous clips).
          if (v.fields case final fields?)
            Section(title: tr('recording.telemetry_overlay_title'), children: [
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final f in fields.availableFields)
                  FilterChip(
                    key: ValueKey('settings.overlayField.$f'),
                    label: Text(switch (tr('companion.overlay_field_$f')) {
                      final label when label != 'companion.overlay_field_$f' => label,
                      _ => f, // a field this app does not know yet: its name
                    }),
                    selected: (fields.selections['continuous']?.fields ?? const <String>[]).contains(f),
                    onSelected: (on) {
                      final now = {...?fields.selections['continuous']?.fields};
                      on ? now.add(f) : now.remove(f);
                      _save(() => _settings.setTelemetryOverlayFields(SetTelemetryOverlayFieldsRequest(type: 'continuous', fields: now)));
                    },
                  ),
              ]),
            ]),
          Section(title: tr('settings.sync_database'), children: [
            OutlinedButton(key: const ValueKey('settings.syncLibrary'), onPressed: _syncLibrary, child: Text(tr('settings.sync_database'))),
          ]),
        ]);
      },
    );
  }
}
