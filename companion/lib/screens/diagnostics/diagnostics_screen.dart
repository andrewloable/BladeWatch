import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../car/car_session.dart';
import '../../car/speed_test.dart';
import '../../i18n.dart';
import '../../transport/transport_selector.dart';
import '../common/format.dart';
import '../common/hud_style.dart';
import '../common/loader.dart';

/// The web diagnostics page's counterpart: network, storage, camera and battery health, and the
/// tools behind them -- the link speed test, pinning the camera probe and resetting the learned
/// State of Health.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, this.speedTest = runSpeedTest});

  /// The speed test, injected so a widget test opens no socket (its own tests own those).
  final Future<SpeedTestResult> Function(CarSession session) speedTest;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> with LoadersState {
  late final _system = SystemServiceClient(context.session.rpc);
  late final _storage = StorageServiceClient(context.session.rpc);
  late final _data = loader(() async => (
        status: await _system.getStatus(GetStatusRequest()),
        storage: await _storage.getStorageSettings(GetStorageSettingsRequest()),
        soh: await _system.getSohStatus(GetSohStatusRequest()),
      ));

  SpeedTestResult? _speed;
  var _speedRunning = false;

  /// Never automatic: it downloads tens of MB, which may be mobile data. A failed run shows no
  /// numbers, not the last good ones.
  Future<void> _runSpeedTest() async {
    final session = context.session;
    setState(() {
      _speedRunning = true;
      _speed = null;
    });
    SpeedTestResult? result;
    await act(context, () async => result = await widget.speedTest(session), failed: context.tr('companion.speedtest_failed'));
    if (mounted) {
      setState(() {
        _speed = result;
        _speedRunning = false;
      });
    }
  }

  Future<void> _probe(int? cameraId) async {
    final tr = context.tr;
    final client = SurveillanceServiceClient(context.session.rpc);
    await act(context, () async {
      final r = await client.setConfig(
        cameraId == null ? SetSurveillanceConfigRequest(clearManualCameraId_3: true) : SetSurveillanceConfigRequest(manualCameraId: cameraId),
      );
      if (!r.success) throw StateError(r.error);
    }, done: tr('companion.probe_saved'), failed: tr('errors.save_failed'));
  }

  Future<void> _resetSoh() async {
    final tr = context.tr;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('diagnostics.reset_soh')),
        content: Text(tr('companion.reset_soh_hint')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('common.cancel'))),
          FilledButton(
            key: const ValueKey('diag.resetConfirm'),
            style: destructiveStyle(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('diagnostics.reset_soh')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await act(context, () async {
      final r = await _system.resetSoh(ResetSohRequest());
      if (!r.success) throw StateError(r.error);
    }, done: tr('toast.applied'), failed: tr('errors.generic'));
    await _data.load();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _data,
      builder: (context, v) {
        final n = v.status.network;
        final st = v.storage;
        final rec = v.status.recordingStatus;
        return PageList(children: [
          Section(title: tr('diagnostics.network'), children: [
            InfoRow(tr('companion.net_type'), n.type.isEmpty ? '—' : n.type),
            if (n.ssid.isNotEmpty) InfoRow('Wi-Fi', n.ssid),
            if (n.ip.isNotEmpty) InfoRow('IP', n.ip),
            // A dot is the state itself: on is cyan, off is a grey one, never a coloured claim.
            InfoRow(tr('companion.lan_access'), tr(n.lanHttpEnabled ? 'status.on' : 'status.off'),
                leading: HudStatusDot(n.lanHttpEnabled ? HudDotState.ok : HudDotState.idle)),
          ]),
          Section(title: tr('companion.speedtest'), children: [
            Text(tr('companion.speedtest_hint')),
            if (_speed case final r?) ...[
              const SizedBox(height: 8),
              InfoRow(tr('companion.speedtest_latency'), '${r.pingMs.round()} ms'),
              InfoRow(tr('companion.speedtest_download'), '${r.mbps.toStringAsFixed(1)} Mbit/s'),
              InfoRow(tr('companion.speedtest_path'), tr(r.phase == TransportPhase.lan ? 'companion.route_lan' : 'companion.route_pear')),
            ],
            if (_speedRunning) ...[
              const SizedBox(height: 8),
              Text(tr('companion.speedtest_running')),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('diag.speedtest.run'),
              onPressed: _speedRunning || !context.session.connected ? null : _runSpeedTest,
              child: Text(tr(_speed == null ? 'companion.speedtest_run' : 'companion.speedtest_again')),
            ),
          ]),
          Section(title: tr('diagnostics.storage'), children: [
            // A forced break before the "/ total" half, not the greedy wrap InfoRow's own Text
            // would otherwise pick on a narrow phone -- that left "GB" alone on its own line
            // (BladeWatch-rdtj.72.3). Both formatted strings already carry their own unit.
            InfoRow(tr('settings.internal_free'), '${st.internalFreeFormatted}\n/ ${st.internalTotalFormatted}'),
            if (st.sdCardAvailable) InfoRow(tr('settings.sd_card_free'), '${st.sdCardFreeFormatted}\n/ ${st.sdCardTotalFormatted}'),
            if (st.sdCardMountFailed) InfoRow(tr('settings.sd_card'), st.sdCardMountError, leading: const HudStatusDot(HudDotState.bad)),
            InfoRow(tr('settings.recordings'), Fmt.bytes((st.recordingsSizeBytes + st.surveillanceSizeBytes).toInt())),
          ]),
          Section(title: tr('diagnostics.camera'), children: [
            InfoRow(tr('companion.pipeline'), tr(rec.pipelineRunning ? 'status.on' : 'status.off'),
                leading: HudStatusDot(rec.pipelineRunning ? HudDotState.ok : HudDotState.idle)),
            InfoRow(tr('companion.cameras_available'), v.status.available.isEmpty ? '—' : v.status.available.join(', ')),
            const SizedBox(height: 8),
            Text(tr('diagnostics.camera_probe_desc')),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(key: const ValueKey('diag.probe.auto'), label: Text(tr('diagnostics.auto')), onPressed: () => _probe(null)),
              for (var id = 0; id <= 5; id++)
                ActionChip(key: ValueKey('diag.probe.$id'), label: Text('$id'), onPressed: () => _probe(id)),
            ]),
          ]),
          Section(title: tr('diagnostics.battery_health'), children: [
            InfoRow(tr('diagnostics.state_of_health'), v.soh.displaySoh > 0 ? '${v.soh.displaySoh.toStringAsFixed(1)}%' : '—'),
            InfoRow(tr('diagnostics.source'), v.soh.displaySource.isEmpty ? '—' : v.soh.displaySource),
            InfoRow(tr('diagnostics.nominal_capacity'),
                v.soh.nominalCapacityKwh > 0 ? '${v.soh.nominalCapacityKwh.toStringAsFixed(1)} kWh' : '—'),
            const SizedBox(height: 8),
            OutlinedButton(key: const ValueKey('diag.resetSoh'), onPressed: _resetSoh, child: Text(tr('diagnostics.reset_soh'))),
          ]),
        ]);
      },
    );
  }
}
