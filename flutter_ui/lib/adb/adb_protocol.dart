import 'dart:async';
import 'dart:typed_data';

/// Thrown by [AdbPacketReader] when the underlying stream ends before a full
/// packet has arrived — the peer closed the connection mid-read.
class AdbConnectionClosedException implements Exception {
  final String message;
  const AdbConnectionClosedException(this.message);

  @override
  String toString() => 'AdbConnectionClosedException: $message';
}

/// The ADB wire protocol's 6 packet commands, as their little-endian uint32
/// encoding of the 4-character ASCII name (e.g. "CNXN" → the bytes C,N,X,N
/// read back as a little-endian uint32) — computed rather than hardcoded as
/// hex so the value is self-evidently correct from the name next to it.
/// Reference: AOSP `system/core/adb/protocol.txt` (long-stable, unversioned
/// wire format — this is the same protocol
/// `app/src/main/java/com/loabletech/bladewatch/launcher/AdbShellExecutor.kt`
/// talks over the `dadb` library).
class AdbCommand {
  static final int cnxn = _fourCc('CNXN');
  static final int auth = _fourCc('AUTH');
  static final int open = _fourCc('OPEN');
  static final int okay = _fourCc('OKAY');
  static final int wrte = _fourCc('WRTE');
  static final int clse = _fourCc('CLSE');

  static int _fourCc(String s) =>
      s.codeUnitAt(0) | (s.codeUnitAt(1) << 8) | (s.codeUnitAt(2) << 16) | (s.codeUnitAt(3) << 24);

  static String name(int command) {
    if (command == cnxn) return 'CNXN';
    if (command == auth) return 'AUTH';
    if (command == open) return 'OPEN';
    if (command == okay) return 'OKAY';
    if (command == wrte) return 'WRTE';
    if (command == clse) return 'CLSE';
    return 'UNKNOWN(0x${command.toRadixString(16)})';
  }
}

/// AUTH packet sub-types (the `arg0` field of an AUTH packet).
class AdbAuthType {
  static const int token = 1;
  static const int signature = 2;
  static const int rsaPublicKey = 3;
}

/// The fixed 24-byte-header ADB packet: command, two 32-bit args, a payload,
/// and the two trailing integrity fields adbd expects (data checksum, and
/// the command's bitwise complement as a sanity magic number).
class AdbPacket {
  static const int headerLength = 24;

  /// Largest payload a peer is allowed to announce in a packet header.
  ///
  /// `dataLength` is an attacker-controlled uint32 read off the wire before a
  /// single payload byte arrives, so without this a peer can claim a 4 GB
  /// payload and [AdbPacketReader] will sit there growing a buffer until the
  /// head unit runs out of memory. ADB's own MAX_PAYLOAD is 256 KB on older
  /// adbd and 1 MB on newer; we advertise 256 KB in our CNXN but accept up to
  /// 1 MB so a newer adbd that ignores our advertised size still works.
  static const int maxPayloadLength = 1024 * 1024;

  final int command;
  final int arg0;
  final int arg1;
  final Uint8List data;

  const AdbPacket(this.command, this.arg0, this.arg1, this.data);

  /// The additive checksum ADB calls "crc32" but isn't: the unsigned sum of
  /// every data byte, wrapped to 32 bits. Modern adbd doesn't verify it, but
  /// computing it correctly costs nothing and matches every adbd version.
  int get _dataChecksum {
    var sum = 0;
    for (final byte in data) {
      sum = (sum + byte) & 0xFFFFFFFF;
    }
    return sum;
  }

  Uint8List encode() {
    final bytes = Uint8List(headerLength + data.length);
    final view = ByteData.sublistView(bytes);
    view.setUint32(0, command, Endian.little);
    view.setUint32(4, arg0, Endian.little);
    view.setUint32(8, arg1, Endian.little);
    view.setUint32(12, data.length, Endian.little);
    view.setUint32(16, _dataChecksum, Endian.little);
    view.setUint32(20, command ^ 0xFFFFFFFF, Endian.little);
    bytes.setRange(headerLength, headerLength + data.length, data);
    return bytes;
  }

  /// Parses a 24-byte header (only — the caller reads `dataLength` more
  /// bytes separately once known) into `(command, arg0, arg1, dataLength)`.
  /// Throws a [FormatException] if the header's magic doesn't match its
  /// command — the one structural check possible before the payload
  /// arrives.
  static (int command, int arg0, int arg1, int dataLength) decodeHeader(Uint8List header) {
    if (header.length != headerLength) {
      throw FormatException('ADB header must be $headerLength bytes, got ${header.length}');
    }
    final view = ByteData.sublistView(header);
    final command = view.getUint32(0, Endian.little);
    final arg0 = view.getUint32(4, Endian.little);
    final arg1 = view.getUint32(8, Endian.little);
    final dataLength = view.getUint32(12, Endian.little);
    final magic = view.getUint32(20, Endian.little);
    if (magic != (command ^ 0xFFFFFFFF)) {
      throw FormatException('ADB header magic mismatch for command ${AdbCommand.name(command)}');
    }
    if (dataLength > maxPayloadLength) {
      throw FormatException(
        'ADB payload length $dataLength exceeds the $maxPayloadLength-byte limit '
        'for command ${AdbCommand.name(command)}',
      );
    }
    return (command, arg0, arg1, dataLength);
  }
}

/// Reassembles whole [AdbPacket]s from a raw byte stream (a [Socket], or a
/// fake connection in tests) — TCP makes no promise that one `add()` on the
/// sender arrives as one chunk on the receiver, so this buffers until it has
/// a full header, then a full payload, before yielding a packet.
class AdbPacketReader {
  final StreamIterator<List<int>> _iterator;
  final List<int> _buffer = [];

  AdbPacketReader(Stream<List<int>> stream) : _iterator = StreamIterator(stream);

  Future<Uint8List> _readExactly(int n) async {
    while (_buffer.length < n) {
      if (!await _iterator.moveNext()) {
        throw const AdbConnectionClosedException('connection closed while reading an ADB packet');
      }
      _buffer.addAll(_iterator.current);
    }
    final result = Uint8List.fromList(_buffer.sublist(0, n));
    _buffer.removeRange(0, n);
    return result;
  }

  Future<AdbPacket> readPacket() async {
    final header = await _readExactly(AdbPacket.headerLength);
    final (command, arg0, arg1, dataLength) = AdbPacket.decodeHeader(header);
    final data = dataLength > 0 ? await _readExactly(dataLength) : Uint8List(0);
    return AdbPacket(command, arg0, arg1, data);
  }
}
