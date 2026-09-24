import 'dart:typed_data';

/// Stream multiplexing over ONE Pear connection -- the companion's half of BladeWatch-rdtj.6's
/// `PearMux` (app/src/main/java/com/loabletech/bladewatch/daemon/PearMux.kt). Byte for byte the
/// same format; change both together. The class doc there is the spec; in short, one Pear message
/// is one frame:
///
///     byte 0      type:  1 OPEN, 2 DATA, 3 CLOSE, 4 WINDOW
///     bytes 1-4   stream id, u32 big-endian, chosen by the opener (always the companion)
///     bytes 5..   OPEN: version byte; DATA: 1..[maxData] bytes; CLOSE: nothing; WINDOW: u32 > 0
class PearMux {
  static const int version = 1;

  static const int open = 1;
  static const int data = 2;
  static const int close = 3;
  static const int window = 4;

  static const int _header = 5;
  static const int maxData = 32 * 1024;
  static const int initialWindow = 256 * 1024;

  static Uint8List openFrame(int stream) => _encode(open, stream, Uint8List.fromList([version]));

  static Uint8List dataFrame(int stream, List<int> bytes) {
    if (bytes.isEmpty || bytes.length > maxData) {
      throw ArgumentError('DATA payload must be 1..$maxData bytes, was ${bytes.length}');
    }
    return _encode(data, stream, bytes);
  }

  static Uint8List closeFrame(int stream) => _encode(close, stream, const []);

  static Uint8List windowFrame(int stream, int credit) {
    if (credit <= 0) throw ArgumentError('WINDOW credit must be positive');
    return _encode(window, stream, (ByteData(4)..setUint32(0, credit)).buffer.asUint8List());
  }

  /// One message, or null when it is not a well-formed frame. It comes from the far side of the
  /// internet: a value to discard, never an exception to throw.
  static MuxFrame? decode(Uint8List message) {
    if (message.length < _header) return null;
    final type = message[0];
    final stream = ByteData.sublistView(message, 1, 5).getUint32(0);
    final payload = Uint8List.sublistView(message, _header);
    final ok = switch (type) {
      open => payload.length == 1,
      data => payload.isNotEmpty && payload.length <= maxData,
      close => payload.isEmpty,
      window => payload.length == 4 && ByteData.sublistView(payload).getUint32(0) > 0,
      _ => false,
    };
    return ok ? MuxFrame(type, stream, payload) : null;
  }

  static Uint8List _encode(int type, int stream, List<int> payload) {
    final out = Uint8List(_header + payload.length);
    out[0] = type;
    ByteData.sublistView(out, 1, 5).setUint32(0, stream);
    out.setRange(_header, out.length, payload);
    return out;
  }
}

class MuxFrame {
  final int type;
  final int stream;
  final Uint8List payload;

  const MuxFrame(this.type, this.stream, this.payload);

  /// The credit a WINDOW frame carries.
  int get credit => ByteData.sublistView(payload).getUint32(0);
}

/// What the companion needs from a Pear connection to the car, and nothing more: messages in,
/// messages out. The real one wraps flutter_pear's `PearConnection`; tests use an in-memory pair.
abstract class PeerLink {
  /// Each event is one Pear message (Protomux keeps boundaries): exactly one [PearMux] frame.
  Stream<Uint8List> get messages;

  Future<void> send(Uint8List message);
}
