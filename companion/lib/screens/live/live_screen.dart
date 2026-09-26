import 'dart:async';
import 'dart:typed_data';

import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/rpc/services/stream_service_client.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../car/car_session.dart';
import '../../car/media.dart';
import '../../i18n.dart';
import '../../transport/transport_selector.dart';

/// Live view as refreshed stills (the owner's choice for v1.4.0.0): the car's four-camera
/// mosaic JPEG from `/api/stream/still`, polled. Works on every platform with no video decoder,
/// and degrades at low bandwidth instead of stalling. Smooth H.264 -- and with it the per-camera
/// view, since SetViewMode only switches the H.264 stream -- is a follow-up.
///
/// The car renders a new still every 5 s; polling faster only shortens the wait for it. Each
/// request also keeps the car's streaming from idling out (WebSocketStreamServer.noteStillViewer).
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key, this.fetch, this.enable});

  /// Test seams: the still fetch and StreamService.Enable.
  final Future<MediaResponse> Function(CarSession session)? fetch;
  final Future<void> Function(CarSession session)? enable;

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  Timer? _timer;
  Uint8List? _frame;
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
    final every = session.phase == TransportPhase.lan ? const Duration(seconds: 1) : const Duration(seconds: 2);
    unawaited(_tick());
    _timer = Timer.periodic(every, (_) => unawaited(_tick()));
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
      final r = await (widget.fetch ?? (s) => fetchMedia(s, '/api/stream/still'))(session);
      if (!mounted || generation != _generation) return; // from before a reconnect
      if (r.ok) {
        setState(() {
          _frame = r.bytes;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final frame = _frame;
    final at = _frameAt;
    return Column(children: [
      Expanded(
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: frame == null
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(tr(_starting ? 'companion.live_starting' : 'common.loading'), style: const TextStyle(color: Colors.white70)),
                ])
              : InteractiveViewer(
                  maxScale: 4,
                  child: Image.memory(frame, key: const ValueKey('live.frame'), gaplessPlayback: true, fit: BoxFit.contain),
                ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          at == null ? tr('companion.live_note') : '${tr('companion.live_note')} · ${TimeOfDay.fromDateTime(at).format(context)}',
          key: const ValueKey('live.note'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ]);
  }
}
