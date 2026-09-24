import 'dart:typed_data';

import 'package:bladewatch_rpc/gen/bladewatch/v1/safe_locations.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/rpc/services/safe_locations_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/surveillance_service_client.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/loader.dart';

/// The web surveillance page's counterpart: sentry on or off, detection settings, a snapshot of
/// each camera, and the safe zones where sentry stands down.
///
/// Settings are saved as the WHOLE loaded config with the edits applied: proto3 JSON cannot send
/// `false`, so the car resets every omitted flag to false -- a partial save switched all four
/// cameras off on the web (BladeWatch-q0p4).
class SurveillanceScreen extends StatefulWidget {
  const SurveillanceScreen({super.key});

  static const presets = ['NEAR', 'SHORT', 'MEDIUM', 'BALANCED', 'LONG', 'FAR'];

  @override
  State<SurveillanceScreen> createState() => _SurveillanceScreenState();
}

class _SurveillanceScreenState extends State<SurveillanceScreen> with LoadersState {
  late final _client = SurveillanceServiceClient(context.session.rpc);
  late final _zones = SafeLocationsServiceClient(context.session.rpc);
  late final _data = loader(() async => (
        status: await _client.getStatus(GetSurveillanceStatusRequest()),
        config: (await _client.getConfig(GetSurveillanceConfigRequest())).config,
        zones: await _zones.listZones(ListZonesRequest()),
      ));
  SurveillanceConfig? _edit;
  final _snapshots = <int, Uint8List>{};
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _busy = true);
    await act(context, action, done: done, failed: context.tr('errors.save_failed'));
    await _data.load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _snapshot(int quadrant) async {
    try {
      final r = await _client.getSnapshot(GetSnapshotRequest(quadrant: quadrant));
      if (r.imageJpeg.isNotEmpty && mounted) setState(() => _snapshots[quadrant] = Uint8List.fromList(r.imageJpeg));
    } catch (_) {
      // Left as "tap to load".
    }
  }

  void _change(void Function(SurveillanceConfig c) edit) => setState(() => edit(_edit!));

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _data,
      builder: (context, v) {
        final c = _edit ??= v.config.deepCopy();
        final cameras = [tr('companion.cam_front'), tr('companion.cam_right'), tr('companion.cam_rear'), tr('companion.cam_left')];
        Widget flag(String label, String key, bool value, void Function(SurveillanceConfig c, bool on) set) => SwitchListTile(
              key: ValueKey('surv.$key'),
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              value: value,
              onChanged: (on) => _change((c) => set(c, on)),
            );
        return PageList(children: [
          Section(title: tr('surveillance.surveillance_mode'), children: [
            SwitchListTile(
              key: const ValueKey('surv.active'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr(v.status.surveillanceActive ? 'surveillance.active' : 'surveillance.inactive')),
              subtitle: Text(tr(v.status.pipelineRunning ? 'surveillance.pipeline_running' : 'surveillance.pipeline_stopped')),
              value: v.status.surveillanceActive,
              onChanged: _busy
                  ? null
                  : (on) => _run(() async {
                        if (on) {
                          await _client.enable(EnableSurveillanceRequest());
                        } else {
                          await _client.disable(DisableSurveillanceRequest());
                        }
                      }),
            ),
          ]),
          Section(title: tr('surveillance.detection_config'), children: [
            Text('${tr('surveillance.sensitivity')} (${c.sensitivity})'),
            Slider(
              key: const ValueKey('surv.sensitivity'),
              min: 1,
              max: 5,
              divisions: 4,
              value: c.sensitivity.clamp(1, 5).toDouble(),
              onChanged: (x) => _change((c) => c.sensitivity = x.round()),
            ),
            DropdownButtonFormField<String>(
              key: const ValueKey('surv.preset'),
              initialValue: SurveillanceScreen.presets.contains(c.distancePreset) ? c.distancePreset : 'BALANCED',
              decoration: InputDecoration(labelText: tr('surveillance.distance_preset')),
              items: [
                for (final p in SurveillanceScreen.presets)
                  DropdownMenuItem(value: p, child: Text(tr('surveillance.preset_${p.toLowerCase()}'))),
              ],
              onChanged: (p) => _change((c) => c.distancePreset = p!),
            ),
            flag(tr('surveillance.ai_detection'), 'ai', c.aiEnabled, (c, on) => c.aiEnabled = on),
            flag(tr('surveillance.person'), 'person', c.detectPerson, (c, on) => c.detectPerson = on),
            flag(tr('surveillance.car'), 'car', c.detectCar, (c, on) => c.detectCar = on),
            flag(tr('surveillance.bike'), 'bike', c.detectBike, (c, on) => c.detectBike = on),
            flag(tr('surveillance.night_mode'), 'night', c.nightMode, (c, on) => c.nightMode = on),
            flag(cameras[0], 'front', c.cameraFront, (c, on) => c.cameraFront = on),
            flag(cameras[1], 'right', c.cameraRight, (c, on) => c.cameraRight = on),
            flag(cameras[2], 'rear', c.cameraRear, (c, on) => c.cameraRear = on),
            flag(cameras[3], 'left', c.cameraLeft, (c, on) => c.cameraLeft = on),
            const SizedBox(height: 8),
            FilledButton(
              key: const ValueKey('surv.save'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final r = await _client.setConfig(SetSurveillanceConfigRequest(config: c));
                        if (!r.success) throw StateError(r.error);
                        _edit = null; // re-read what the car applied
                      }, done: tr('toast.saved')),
              child: Text(tr('surveillance.save_config')),
            ),
          ]),
          Section(title: tr('surveillance.live_snapshots'), children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 4 / 3,
              children: [
                for (var q = 0; q < 4; q++)
                  InkWell(
                    key: ValueKey('surv.snapshot.$q'),
                    onTap: () => _snapshot(q),
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: _snapshots[q] != null
                          ? Image.memory(_snapshots[q]!, fit: BoxFit.cover, gaplessPlayback: true)
                          : Center(child: Text('${cameras[q]}\n${tr('surveillance.tap_to_load')}', textAlign: TextAlign.center)),
                    ),
                  ),
              ],
            ),
          ]),
          Section(title: tr('surveillance.safe_locations'), children: [
            SwitchListTile(
              key: const ValueKey('surv.zones'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr('surveillance.safe_locations')),
              subtitle: v.zones.currentlyInSafeZone ? Text(tr('status.safe')) : null,
              value: v.zones.featureEnabled,
              onChanged: _busy ? null : (on) => _run(() => _zones.toggle(ToggleSafeLocationsRequest(enabled: on, enabledSet: true))),
            ),
            if (v.zones.zones.isEmpty) Text(tr('surveillance.no_safe_zones')),
            for (final z in v.zones.zones)
              ListTile(
                key: ValueKey('zone.${z.id}'),
                contentPadding: EdgeInsets.zero,
                title: Text(z.name),
                subtitle: Text('${z.radiusM} m${z.active ? '' : ' · ${tr('status.off')}'}'),
                trailing: IconButton(
                  key: ValueKey('zone.delete.${z.id}'),
                  tooltip: tr('surveillance.remove'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _busy ? null : () => _run(() => _zones.deleteZone(DeleteZoneRequest(id: z.id))),
                ),
              ),
          ]),
        ]);
      },
    );
  }
}
