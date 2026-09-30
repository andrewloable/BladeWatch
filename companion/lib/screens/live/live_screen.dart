import 'dart:async';
import 'dart:typed_data';

import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_rpc/rpc/services/stream_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../car/car_page.dart';
import '../../car/car_session.dart';
import '../../car/media.dart';
import '../../i18n.dart';
import '../common/format.dart';
import '../common/shell_nav.dart';
import '../location/location_screen.dart' show parseFix;

/// Live view as refreshed stills (the owner's choice for v1.4.0.0): the car's four-camera
/// mosaic JPEG from `/api/stream/still`, polled. Works on every platform with no video decoder,
/// and degrades at low bandwidth instead of stalling. Smooth H.264 -- and with it the per-camera
/// view, since SetViewMode only switches the H.264 stream -- is a follow-up.
///
/// The car renders a new still every 100ms, 10fps (BladeWatch-hmk0), and this polls at the same
/// rate on every transport. A frame replaces the one shown only when its bytes differ, and it
/// keeps the time it first arrived; a failed or empty fetch leaves the last frame up. Each request
/// also keeps the car's streaming from idling out (WebSocketStreamServer.noteStillViewer).
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key, this.fetch, this.enable, this.gps});

  /// Test seams: the still fetch, StreamService.Enable, and the car's GPS fix.
  final Future<MediaResponse> Function(CarSession session, String path)? fetch;
  final Future<void> Function(CarSession session)? enable;
  final Future<GetGpsLocationResponse> Function(CarSession session)? gps;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  // One camera. Since BladeWatch-rdtj.68 the car sends that camera alone at its native 1280x960
  // (`?camera=q`; the response's X-Still-View says what it holds). Until it does -- the first second
  // after a pick, or a car without rdtj.68 -- the quarter is cut from the four-camera still here, as
  // rdtj.45 did. The pick changes only the car's still capture, never its shared H.264 stream,
  // so the in-car Live View is untouched. Order is the car's (MotionPipelineV2.QUADRANT_NAMES):
  // front, right, rear, left; null is all four.
  int? _camera;
  static const _cameraKeys = ['companion.cam_front', 'companion.cam_right', 'companion.cam_rear', 'companion.cam_left'];
  static const _quarters = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];

  Timer? _timer;
  Timer? _gpsTimer;
  ({LatLng at, bool stale, double? accuracy})? _fix;
  bool _gpsAsked = false;
  Uint8List? _frame;
  String _frameView = '';
  DateTime? _frameAt;
  bool _starting = true;
  bool _busy = false;
  DateTime _lastEnable = DateTime.fromMillisecondsSinceEpoch(0);
  CarSession? _session;
  bool _wasConnected = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.session;
    if (identical(session, _session)) {
      // BladeWatch-tayl: the moment the route is back, fetch. Waiting for the next tick costs up
      // to its period, and a fetch the drop left hanging would block every tick until
      // fetchMedia's 20 s timeout -- so it is disowned instead.
      final connected = session.connected;
      if (connected && !_wasConnected) {
        _generation++;
        _busy = false;
        unawaited(_tick());
      }
      _wasConnected = connected;
      return;
    }
    _session = session;
    _wasConnected = session.connected;
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => unawaited(_tick()));
    _gpsTimer?.cancel();
    unawaited(_gpsTick());
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(_gpsTick()));
  }

  Future<void> _enable(CarSession session) async {
    _lastEnable = DateTime.now();
    try {
      await (widget.enable ?? (s) => StreamServiceClient(s.rpc).enable(EnableStreamRequest()))(session);
    } catch (_) {
      // The next 503 tries again.
    }
  }

  Future<void> _tick() async {
    final session = _session;
    if (session == null || _busy) return;
    _busy = true;
    final generation = _generation;
    try {
      final path = '/api/stream/still${_camera == null ? '' : '?camera=$_camera'}';
      final r = await (widget.fetch ?? fetchMedia)(session, path);
      if (!mounted || generation != _generation) return; // from before a reconnect
      if (r.ok) {
        // The same still again (the car has no newer frame): keep it and the time it came.
        if (listEquals(_frame, r.bytes)) return;
        setState(() {
          _frame = r.bytes;
          _frameView = r.headers['x-still-view'] ?? '';
          _frameAt = DateTime.now();
          _starting = false;
        });
      } else if (r.status == 503 && DateTime.now().difference(_lastEnable) > const Duration(seconds: 10)) {
        // Streaming is off (never started, or idled out): turn it on. It takes a few seconds.
        setState(() => _starting = true);
        await _enable(session);
      }
    } catch (_) {
      // A dropped fetch: the next tick retries. The frame shown keeps its timestamp.
    } finally {
      if (generation == _generation) _busy = false;
    }
  }

  /// Where the car is, as in the in-car Live View's chip: the daemon's GPS fix, every 5 s.
  Future<void> _gpsTick() async {
    final session = _session;
    if (session == null) return;
    try {
      final r = await (widget.gps ?? (s) => VehicleServiceClient(s.rpc).getGpsLocation(GetGpsLocationRequest()))(session);
      final fix = parseFix(r.locationJson);
      if (!mounted) return;
      if (!_gpsAsked || fix?.at != _fix?.at || fix?.stale != _fix?.stale) setState(() => _fix = fix);
    } catch (_) {
      // The next tick asks again; the chip keeps the last fix.
    } finally {
      _gpsAsked = true;
    }
  }

  /// The in-car Live View's location chip: where the car is, or that it has no fix yet. Tapping
  /// it opens Location.
  Widget _gpsChip(BuildContext context) {
    final tr = context.tr;
    final fix = _fix;
    final title = fix == null
        ? tr('safe_loc.waiting_gps')
        : [tr('vehicle.gps_location'), if (fix.stale) tr('status.stale')].join(' · ');
    // An overlay chip on the video: dark and translucent in both modes (it sits on the picture, not the page), with the
    // HUD's 4 dp corners and border.
    final hud = BwHud.of(context);
    const radius = BorderRadius.all(Radius.circular(BwHud.radiusSmall));
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: hud.panelBorderStrong)),
      child: InkWell(
        key: const ValueKey('live.gps'),
        borderRadius: radius,
        onTap: () => ShellNav.of(context)?.go('location'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
                if (fix != null)
                  Text('${fix.at.latitude.toStringAsFixed(4)}, ${fix.at.longitude.toStringAsFixed(4)}',
                      overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final frame = _frame;
    final at = _frameAt;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Wrap(spacing: 8, runSpacing: 4, alignment: WrapAlignment.center, children: [
          for (final (i, key) in [(null, 'events.all'), for (var q = 0; q < 4; q++) (q, _cameraKeys[q])])
            ChoiceChip(
              showCheckmark: false,
              key: ValueKey('live.camera.${i ?? 'all'}'),
              label: Text(tr(key)),
              selected: _camera == i,
              onSelected: (_) {
                setState(() => _camera = i);
                unawaited(_tick()); // ask for the new view now, not at the next tick
              },
            ),
        ]),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          // The picture is untouched (black letterbox); the frame around it is the HUD's 4 dp bordered panel.
          child: HudPanel(
            color: Colors.black,
            borderColor: BwHud.of(context).panelBorder,
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
          Positioned.fill(
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: frame == null
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(tr(_starting ? 'companion.live_starting' : 'common.loading'), style: const TextStyle(color: Colors.white70)),
                ])
              // Tight constraints, so BoxFit.contain scales the still UP to the area: with the loose
              // ones Container(alignment) hands down, a 640x480 still sat at its own size in the
              // middle of a desktop window (BladeWatch-rdtj.45).
              : SizedBox.expand(
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: _camera == null || _frameView == '$_camera'
                        ? Image.memory(frame, key: const ValueKey('live.frame'), gaplessPlayback: true, fit: BoxFit.contain)
                        : FittedBox(
                            child: ClipRect(
                              child: Align(
                                key: const ValueKey('live.quarter'),
                                alignment: _quarters[_camera!],
                                widthFactor: 0.5,
                                heightFactor: 0.5,
                                child: Image.memory(frame, key: const ValueKey('live.frame'), gaplessPlayback: true),
                              ),
                            ),
                          ),
                  ),
                ),
        ),
          ),
          if (_gpsAsked)
            Positioned(top: 8, right: 8, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 280), child: _gpsChip(context))),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          [
            _camera == null ? tr('companion.live_note') : tr('companion.live_note_one', {'camera': tr(_cameraKeys[_camera!])}),
            if (at != null) Fmt.clock(at, tr.lang),
          ].join(' · '),
          key: const ValueKey('live.note'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ]);
  }
}
