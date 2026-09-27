import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'pear_mux.dart';

/// The companion's half of BladeWatch-rdtj.6's stream pump (BladeWatch-rdtj.8): each local TCP
/// connection handed to it becomes one [PearMux] stream to the car, which the car connects to its
/// Pear TLS listener. Opaque bytes both ways -- here, TLS records the companion's gateway produces;
/// no HTTP, no WebSocket, no H.264 is ever parsed.
///
/// Flow control mirrors the car: each direction of each stream starts with [window] bytes of
/// credit. Toward the car, reading from the local socket pauses when credit runs out. Toward the
/// local client, bytes are handed to the socket one frame at a time with a flush in between --
/// Dart's socket buffers without limit otherwise, and add() during a flush throws -- and credit
/// goes back to the car only once they have left. A car that overruns its credit loses the stream.
///
/// [receiveWindow] (BladeWatch-rdtj.28): how far the car may run ahead toward this side. Every
/// stream starts at the protocol's [window]; a larger [receiveWindow] is granted as extra WINDOW
/// credit right after OPEN, which the car accepts (its grant() is uncapped), so no protocol change.
/// It matters because one stream moves at most window / round-trip: 256 KB over mobile data's
/// ~850 ms round trip is ~2.4 Mbit/s -- measured 2.3-5 Mbit/s -- below a 6 Mbit/s clip, so remote
/// playback could never keep up. [remoteReceiveWindow] lifts that to ~19 Mbit/s at the same RTT.
class MuxBridge {
  MuxBridge(this._link, {this.window = PearMux.initialWindow, int? receiveWindow, this.onClosed})
      : receiveWindow = receiveWindow ?? window {
    assert(this.receiveWindow >= window, 'the receive window can only grow past the protocol window');
    _sub = _link.messages.listen(_onMessage, onDone: shutdown, onError: (Object _) => shutdown());
  }

  /// The car-bound bridge's receive window. ponytail: fixed; make it adaptive (measured RTT x
  /// wanted rate) if memory on the car or the phone ever becomes the limit. Worst case on the car
  /// is its per-peer stream cap (16) x this = 32 MB queued in pear-end.
  static const remoteReceiveWindow = 2 * 1024 * 1024;

  final PeerLink _link;
  final int window;
  final int receiveWindow;

  /// Called once, when the Pear connection goes away (or [shutdown] is called).
  final void Function()? onClosed;
  late final StreamSubscription<Uint8List> _sub;
  final Map<int, _Stream> _streams = {};
  int _nextId = 1;
  bool _closed = false;

  int get openStreams => _streams.length;

  bool get isClosed => _closed;

  /// Carries [local] to the car on a new stream until either end closes.
  void pipe(Socket local) {
    if (_closed) {
      local.destroy();
      return;
    }
    final id = _nextId;
    _nextId = _nextId == 0xFFFFFFFF ? 1 : _nextId + 1;
    final stream = _Stream(this, id, local);
    _streams[id] = stream;
    _send(PearMux.openFrame(id));
    if (receiveWindow > window) _send(PearMux.windowFrame(id, receiveWindow - window));
    stream.start();
  }

  /// The Pear connection is gone: every stream goes with it.
  void shutdown() {
    if (_closed) return;
    _closed = true;
    unawaited(_sub.cancel());
    for (final s in _streams.values.toList()) {
      s.close(notifyCar: false);
    }
    onClosed?.call();
  }

  void _onMessage(Uint8List message) {
    final frame = PearMux.decode(message);
    if (frame == null) return;
    final stream = _streams[frame.stream];
    if (stream == null) return;
    switch (frame.type) {
      case PearMux.data:
        stream.fromCar(frame.payload);
      case PearMux.window:
        stream.grant(frame.credit);
      case PearMux.close:
        stream.close(notifyCar: false);
    }
  }

  void _send(Uint8List frame) {
    // Sends are issued in order and never awaited here: the credit, not this future, is what
    // bounds how much is in flight. A failed write means the connection is gone.
    _link.send(frame).catchError((Object _) => shutdown());
  }
}

class _Stream {
  _Stream(this._bridge, this.id, this._local)
      : _sendCredit = _bridge.window,
        _recvAllowance = _bridge.receiveWindow;

  final MuxBridge _bridge;
  final int id;
  final Socket _local;
  late final StreamSubscription<Uint8List> _fromLocal;
  final Queue<Uint8List> _toCar = Queue();
  final Queue<Uint8List> _toLocal = Queue();
  int _sendCredit;
  int _recvAllowance;
  int _consumed = 0;
  bool _writing = false;
  bool _closed = false;

  void start() {
    _fromLocal = _local.listen(
      (bytes) {
        _toCar.add(bytes);
        _pumpToCar();
      },
      onDone: () => close(notifyCar: true),
      onError: (Object _) => close(notifyCar: true),
      cancelOnError: true,
    );
  }

  void _pumpToCar() {
    while (_toCar.isNotEmpty && _sendCredit > 0) {
      final chunk = _toCar.removeFirst();
      final n = [chunk.length, _sendCredit, PearMux.maxData].reduce((a, b) => a < b ? a : b);
      _bridge._send(PearMux.dataFrame(id, Uint8List.sublistView(chunk, 0, n)));
      _sendCredit -= n;
      if (n < chunk.length) _toCar.addFirst(Uint8List.sublistView(chunk, n));
    }
    // Out of credit with bytes still waiting: stop reading the local socket until the car grants.
    if (_toCar.isNotEmpty && !_fromLocal.isPaused) _fromLocal.pause();
  }

  void grant(int credit) {
    _sendCredit += credit;
    if (_fromLocal.isPaused) _fromLocal.resume();
    _pumpToCar();
  }

  void fromCar(Uint8List bytes) {
    if (bytes.length > _recvAllowance) {
      close(notifyCar: true); // the car overran its credit
      return;
    }
    _recvAllowance -= bytes.length;
    _toLocal.add(bytes);
    unawaited(_pumpToLocal());
  }

  Future<void> _pumpToLocal() async {
    if (_writing) return;
    _writing = true;
    try {
      while (_toLocal.isNotEmpty && !_closed) {
        final chunk = _toLocal.removeFirst();
        _local.add(chunk);
        await _local.flush();
        _consumed += chunk.length;
        if (_consumed >= _bridge.receiveWindow ~/ 4 || _toLocal.isEmpty) {
          _recvAllowance += _consumed;
          _bridge._send(PearMux.windowFrame(id, _consumed));
          _consumed = 0;
        }
      }
    } catch (_) {
      close(notifyCar: true); // the local client went away mid-write
    } finally {
      _writing = false;
    }
  }

  void close({required bool notifyCar}) {
    if (_closed) return;
    _closed = true;
    _bridge._streams.remove(id);
    _toCar.clear();
    _toLocal.clear();
    unawaited(_fromLocal.cancel());
    _local.destroy();
    if (notifyCar && !_bridge._closed) _bridge._send(PearMux.closeFrame(id));
  }
}
