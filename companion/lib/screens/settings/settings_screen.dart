import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../car/car_store.dart';
import '../../i18n.dart';
import '../common/format.dart';
import '../common/loader.dart';

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
      ));
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

  Future<bool> _confirm(String title, String body, {String? yes}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('common.cancel'))),
            FilledButton(key: const ValueKey('settings.confirm'), onPressed: () => Navigator.pop(context, true), child: Text(yes ?? context.tr('common.ok'))),
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
    if (!await _confirm(tr('companion.cleanup'), detail)) return;
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
    if (!await _confirm(tr('settings.format_external_drive'), '${tr('settings.format_external_hint')}\n\n${v.mountPath.isEmpty ? v.volumeId : v.mountPath}')) return;
    if (!mounted || !await _confirm(tr('settings.format_external_drive'), tr('settings.tap_again_erase'), yes: tr('settings.format_sd_usb'))) return;
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
        key: const ValueKey('settings.appLanguage'),
        initialValue: store.language ?? '',
        decoration: InputDecoration(labelText: tr('settings.app_language')),
        items: [
          DropdownMenuItem(value: '', child: Text(tr('companion.follow_device'))),
          for (final l in Tr.languages) DropdownMenuItem(value: l, child: Text(l)),
        ],
        onChanged: (l) => widget.onLanguage(l == null || l.isEmpty ? null : l),
      ),
      if (store.car != null) InfoRow(tr('dashboard.device_id'), store.car!.deviceId),
      const SizedBox(height: 8),
      OutlinedButton(
        key: const ValueKey('settings.unpair'),
        onPressed: () async {
          if (await _confirm(tr('companion.unpair'), tr('companion.unpair_hint'))) await widget.onUnpair();
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
              ListTile(
                key: ValueKey('settings.mode.$m'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(m == mode ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(tr('companion.mode_${m.toLowerCase()}')),
                onTap: m == mode ? null : () => _save(() => _settings.setRecordingMode(SetRecordingModeRequest(mode: m))),
              ),
          ]),
          Section(title: tr('settings.recording_quality'), children: [
            DropdownButtonFormField<String>(
              key: const ValueKey('settings.quality'),
              initialValue: qualities.contains(v.quality.recordingQuality) ? v.quality.recordingQuality : null,
              decoration: InputDecoration(labelText: tr('settings.quality_tier')),
              items: [for (final q in qualities) DropdownMenuItem(value: q, child: Text(q))],
              onChanged: (q) => _save(() => _settings.setQuality(SetQualityRequest(recordingQuality: q, codec: v.quality.codec))),
            ),
            DropdownButtonFormField<String>(
              key: const ValueKey('settings.codec'),
              initialValue: codecs.containsKey(v.quality.codec) ? v.quality.codec : null,
              decoration: InputDecoration(labelText: tr('settings.video_codec')),
              items: [for (final e in codecs.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (c) => _save(() => _settings.setQuality(SetQualityRequest(recordingQuality: v.quality.recordingQuality, codec: c))),
            ),
          ]),
          Section(title: tr('settings.recording_storage'), children: [
            InfoRow(tr('settings.recordings'), '${st.recordingsCount} · ${Fmt.bytes(st.recordingsSizeBytes.toInt())}'),
            InfoRow(tr('companion.surveillance_clips'), '${st.surveillanceCount} · ${Fmt.bytes(st.surveillanceSizeBytes.toInt())}'),
            InfoRow(tr('settings.internal_free'), st.internalFreeFormatted),
            if (st.sdCardAvailable) InfoRow(tr('settings.sd_card_free'), st.sdCardFreeFormatted),
            TextField(
              key: const ValueKey('settings.recLimit'),
              controller: _recLimit,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '${tr('settings.recordings')} · ${tr('settings.mb_limit')}'),
            ),
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
          Section(title: tr('companion.car_language'), children: [
            DropdownButtonFormField<String>(
              key: const ValueKey('settings.carLanguage'),
              initialValue: langs.contains(v.locale.lang) ? v.locale.lang : null,
              decoration: InputDecoration(labelText: tr('settings.language')),
              items: [for (final l in langs) DropdownMenuItem(value: l, child: Text(l))],
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
        ]);
      },
    );
  }
}
