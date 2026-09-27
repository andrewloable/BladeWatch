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
/// credit right after OPEN. It matters because one stream moves at most window / round-trip: 256 KB
/// over mobile data's ~850 ms round trip is ~2.4 Mbit/s -- below a 6 Mbit/s clip.
/// [remoteReceiveWindow] lifts that to ~19 Mbit/s at the same RTT.
///
/// ## Surviving a reconnect (BladeWatch-bbvx)
///
/// When the Pear connection drops, the bridge DETACHES instead of closing: local sockets stay
/// open, and each stream keeps what it sent until the car acknowledged it. [onClosed] fires so the
/// transport looks for the car again; a bridge on the new connection then [adopt]s these streams,
/// sending REATTACH with the token the car issued in OPENED, and both sides resend from where the
/// other stopped receiving. The app on top -- RPC, stills, clip playback -- never notices. Local
/// connections made while detached wait too, and open once adopted. After [grace] without an
/// adoption, everything closes as before. Stream ids come from one counter shared by every bridge,
/// so adopted streams never collide with the new bridge's own.
class MuxBridge {
  MuxBridge(PeerLink link,
      {this.window = PearMux.initialWindow, int? receiveWindow, this.onClosed, this.grace = defaultGrace})
      : receiveWindow = receiveWindow ?? window,
        _link = link {
    assert(this.receiveWindow >= window, 'the receive window can only grow past the protocol window');
    _sub = link.messages.listen(_onMessage, onDone: _onLinkLost, onError: (Object _) => _onLinkLost());
  }

  /// The car-bound bridge's receive window. ponytail: fixed; make it adaptive (measured RTT x
  /// wanted rate) if memory on the car or the phone ever becomes the limit. The car caps what it
  /// keeps for resending per stream and in total (PearStreamPump.Limits).
  static const remoteReceiveWindow = 2 * 1024 * 1024;

  /// How long streams wait for the car to come back. The car keeps its side as long
  /// (PearStreamPump.Limits.graceMs); from mobile data a reconnect took 5 s to minutes.
  static const defaultGrace = Duration(seconds: 60);

  /// Shared by every bridge: see the class doc.
  static int _nextId = 1;

  final int window;
  final int receiveWindow;
  final Duration grace;

  /// Called once, when the Pear connection goes away (or [shutdown] is called first).
  final void Function()? onClosed;
  PeerLink? _link;
  StreamSubscription<Uint8List>? _sub;
  Timer? _graceTimer;
  final Map<int, _Stream> _streams = {};
  bool _closed = false;
  bool _told = false;

  int get openStreams => _streams.length;

  bool get isClosed => _closed;

  /// Lost its connection and waiting, within [grace], to be adopted.
  bool get isDetached => !_closed && _link == null;

  bool get _attached => !_closed && _link != null;

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
    if (_attached) _open(stream);
    stream.start();
  }

  void _open(_Stream s) {
    s.openSent = true;
    _send(PearMux.openFrame(s.id));
    if (receiveWindow > window) _send(PearMux.windowFrame(s.id, receiveWindow - window, 0));
  }

  /// Takes over [previous]'s streams, which carry on over this bridge's connection: REATTACH for
  /// those the car had opened, OPEN for local connections that were still waiting, and a close for
  /// any that were half-open when the connection went. [previous] is closed, without its streams.
  void adopt(MuxBridge previous) {
    if (identical(previous, this) || previous._closed || _closed) return;
    previous._closed = true;
    previous._told = true; // its connection loss was already reported, or is moot now
    previous._graceTimer?.cancel();
    unawaited(previous._sub?.cancel());
    previous._link = null;
    final moving = previous._streams.values.toList();
    previous._streams.clear();
    for (final s in moving) {
      s._bridge = this;
      _streams[s.id] = s;
      if (s.token != null) {
        s.reattach();
      } else if (!s.openSent) {
        _open(s);
        s.pumpToCar();
      } else {
        s.abort(notifyCar: false); // OPEN went out, OPENED never came: nothing to resume
      }
    }
  }

  /// Everything closes: after [grace] detached, on dispose, or when the car is found elsewhere.
  void shutdown() {
    if (_closed) return;
    _closed = true;
    _graceTimer?.cancel();
    unawaited(_sub?.cancel());
    _link = null;
    for (final s in _streams.values.toList()) {
      s.abort(notifyCar: false);
    }
    _tell();
  }

  void _tell() {
    if (_told) return;
    _told = true;
    onClosed?.call();
  }

  void _onLinkLost() {
    if (_closed || _link == null) return;
    unawaited(_sub?.cancel());
    _link = null;
    for (final s in _streams.values.toList()) {
      if (s.token == null) s.abort(notifyCar: false); // the car never confirmed it: nothing to resume
    }
    if (_streams.isEmpty) return shutdown();
    _graceTimer = Timer(grace, shutdown);
    _tell();
  }

  void _onMessage(Uint8List message) {
    final frame = PearMux.decode(message);
    if (frame == null) return;
    final stream = _streams[frame.stream];
    if (stream == null) return;
    switch (frame.type) {
      case PearMux.opened:
        stream.token ??= frame.token;
      case PearMux.data:
        stream.fromCar(frame.payload);
      case PearMux.window:
        stream.grant(frame.credit, frame.received);
      case PearMux.close:
        stream.onCarClose();
      case PearMux.reattached:
        stream.onReattached(frame.received, frame.limit);
    }
  }

  /// Sends unless detached: a frame lost that way is covered by the resend after a reattach.
  void _send(Uint8List frame) {
    final link = _link;
    if (_closed || link == null) return;
    // Sends are issued in order and never awaited here: the credit, not this future, is what
    // bounds how much is in flight. A failed write means the connection is gone.
    link.send(frame).catchError((Object _) => _onLinkLost());
  }
}

class _Stream {
  _Stream(this._bridge, this.id, this._local)
      : _limit = _bridge.window,
        _recvLimit = _bridge.receiveWindow;

  MuxBridge _bridge;
  final int id;
  final Socket _local;
  late final StreamSubscription<Uint8List> _fromLocal;

  /// From the car's OPENED; what proves this stream is ours in a REATTACH.
  Uint8List? token;
  bool openSent = false;
  bool _reattaching = false;

  // Toward the car. Offsets count bytes from the start of the stream.
  final Queue<Uint8List> _toCar = Queue();
  int _sent = 0;
  int _limit;
  final Queue<Uint8List> _unacked = Queue(); // bytes [_unackedStart, _sent)
  int _unackedStart = 0;

  // From the car.
  final Queue<Uint8List> _toLocal = Queue();
  int _received = 0;
  int _recvLimit;
  int _consumed = 0; // since the last WINDOW
  bool _writing = false;

  bool _localDone = false;
  bool _closeSent = false;
  bool _closeReceived = false;
  bool _closed = false;

  void start() {
    _fromLocal = _local.listen(
      (bytes) {
        _toCar.add(bytes);
        pumpToCar();
      },
      onDone: () {
        _localDone = true;
        pumpToCar(); // sends CLOSE once everything before it is out
      },
      onError: (Object _) => abort(notifyCar: true),
      cancelOnError: true,
    );
  }

  bool get _canSend => _bridge._attached && openSent && !_reattaching && !_closed;

  void pumpToCar() {
    if (!_canSend || _closeSent) {
      if (_toCar.isNotEmpty && !_fromLocal.isPaused) _fromLocal.pause();
      return;
    }
    while (_toCar.isNotEmpty && _limit - _sent > 0) {
      final chunk = _toCar.removeFirst();
      final n = [chunk.length, _limit - _sent, PearMux.maxData].reduce((a, b) => a < b ? a : b);
      final piece = Uint8List.sublistView(chunk, 0, n);
      _unacked.add(piece);
      _sent += n;
      _bridge._send(PearMux.dataFrame(id, piece));
      if (n < chunk.length) _toCar.addFirst(Uint8List.sublistView(chunk, n));
    }
    if (_toCar.isNotEmpty) {
      // Out of credit with bytes still waiting: stop reading the local socket until the car grants.
      if (!_fromLocal.isPaused) _fromLocal.pause();
    } else if (_localDone) {
      _closeSent = true;
      _bridge._send(PearMux.closeFrame(id));
      if (_closeReceived) _forget();
    }
  }

  void grant(int credit, int carReceived) {
    if (_reattaching || _closed) return; // stale: REATTACHED carries the truth
    _limit += credit;
    _trim(carReceived);
    if (_fromLocal.isPaused) _fromLocal.resume();
    pumpToCar();
  }

  void _trim(int carReceived) {
    final upTo = carReceived < _sent ? carReceived : _sent;
    while (_unacked.isNotEmpty && _unackedStart + _unacked.first.length <= upTo) {
      _unackedStart += _unacked.removeFirst().length;
    }
  }

  void fromCar(Uint8List bytes) {
    // While reattaching, the car may still be sending into the old connection's gap: ignore it,
    // the car resends from our offset once it has our REATTACH.
    if (_reattaching || _closeReceived || _closed) return;
    if (_received + bytes.length > _recvLimit) {
      abort(notifyCar: true); // the car overran its credit
      return;
    }
    _received += bytes.length;
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
        // Not while reattaching: the REATTACH already told the car our limit, so this credit waits
        // for REATTACHED (onReattached sends it) instead of being lost with a stale frame.
        if (!_reattaching && (_consumed >= _bridge.receiveWindow ~/ 4 || _toLocal.isEmpty)) _grantConsumed();
      }
    } catch (_) {
      abort(notifyCar: true); // the local client went away mid-write
    } finally {
      _writing = false;
    }
    if (_closeReceived && _toLocal.isEmpty && !_closed) _forget();
  }

  void _grantConsumed() {
    _recvLimit += _consumed;
    _bridge._send(PearMux.windowFrame(id, _consumed, _received));
    _consumed = 0;
  }

  /// The car finished (or answers ours): what it sent is delivered first, then the local socket.
  void onCarClose() {
    if (_closeReceived || _closed) return;
    _closeReceived = true;
    _reattaching = false; // a refused REATTACH is answered with CLOSE
    if (!_closeSent) {
      _closeSent = true;
      _toCar.clear();
      _bridge._send(PearMux.closeFrame(id));
    }
    if (!_writing && _toLocal.isEmpty) _forget();
  }

  /// On the new connection: tell the car where this side stands.
  void reattach() {
    _reattaching = true;
    _bridge._send(PearMux.reattachFrame(id, token!, _received, _recvLimit));
  }

  /// The car is back: resend from what it received, and send only as far as it now allows.
  void onReattached(int carReceived, int carLimit) {
    if (!_reattaching || _closed) return;
    if (carReceived < _unackedStart || carReceived > _sent || carLimit < _sent) {
      abort(notifyCar: true);
      return;
    }
    _reattaching = false;
    _trim(carReceived);
    var offset = _unackedStart;
    for (final chunk in _unacked) {
      final skip = (carReceived - offset).clamp(0, chunk.length);
      if (skip < chunk.length) _bridge._send(PearMux.dataFrame(id, Uint8List.sublistView(chunk, skip)));
      offset += chunk.length;
    }
    _limit = carLimit;
    if (_consumed > 0) _grantConsumed(); // freed while the REATTACH was in flight
    if (_closeSent) {
      _bridge._send(PearMux.closeFrame(id));
    } else {
      if (_fromLocal.isPaused) _fromLocal.resume();
      pumpToCar();
    }
  }

  /// Both CLOSEs have crossed and everything is delivered.
  void _forget() {
    if (_closed) return;
    _closed = true;
    _bridge._streams.remove(id);
    unawaited(_fromLocal.cancel());
    _local.destroy();
  }

  /// Ends the stream now, with no handshake.
  void abort({required bool notifyCar}) {
    if (_closed) return;
    final tell = notifyCar && !_closeSent && _bridge._attached && openSent;
    _closed = true;
    _bridge._streams.remove(id);
    _toCar.clear();
    _toLocal.clear();
    _unacked.clear();
    unawaited(_fromLocal.cancel());
    _local.destroy();
    if (tell) _bridge._send(PearMux.closeFrame(id));
  }
}
