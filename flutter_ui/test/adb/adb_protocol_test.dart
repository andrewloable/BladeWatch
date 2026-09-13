import 'dart:typed_data';

import 'package:bladewatch_ui/adb/adb_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdbConnectionClosedException.toString() is descriptive', () {
    expect(const AdbConnectionClosedException('boom').toString(), contains('boom'));
  });

  group('AdbCommand', () {
    test('four-character codes match the well-known ADB protocol values', () {
      // Independently computed (not via AdbCommand._fourCc) so a bug in the
      // production helper can't hide from this test.
      expect(AdbCommand.cnxn, 0x4e584e43);
      expect(AdbCommand.auth, 0x48545541);
      expect(AdbCommand.open, 0x4e45504f);
      expect(AdbCommand.okay, 0x59414b4f);
      expect(AdbCommand.wrte, 0x45545257);
      expect(AdbCommand.clse, 0x45534c43);
    });

    test('name returns the 4-character command name for every known command', () {
      expect(AdbCommand.name(AdbCommand.cnxn), 'CNXN');
      expect(AdbCommand.name(AdbCommand.auth), 'AUTH');
      expect(AdbCommand.name(AdbCommand.open), 'OPEN');
      expect(AdbCommand.name(AdbCommand.okay), 'OKAY');
      expect(AdbCommand.name(AdbCommand.wrte), 'WRTE');
      expect(AdbCommand.name(AdbCommand.clse), 'CLSE');
    });

    test('name returns a hex fallback for an unrecognized command', () {
      expect(AdbCommand.name(0x1), 'UNKNOWN(0x1)');
    });
  });

  group('AdbPacket.encode', () {
    test('lays out a header-only packet as 24 little-endian bytes with no payload', () {
      final packet = AdbPacket(AdbCommand.cnxn, 0x01000000, 0x00040000, Uint8List(0));

      final bytes = packet.encode();

      expect(bytes.length, 24);
      final view = ByteData.sublistView(bytes);
      expect(view.getUint32(0, Endian.little), AdbCommand.cnxn);
      expect(view.getUint32(4, Endian.little), 0x01000000);
      expect(view.getUint32(8, Endian.little), 0x00040000);
      expect(view.getUint32(12, Endian.little), 0); // dataLength
      expect(view.getUint32(16, Endian.little), 0); // checksum of empty data
      expect(view.getUint32(20, Endian.little), AdbCommand.cnxn ^ 0xFFFFFFFF); // magic
    });

    test('appends the payload after the header and records its length', () {
      final data = Uint8List.fromList('host::\u0000'.codeUnits);
      final packet = AdbPacket(AdbCommand.cnxn, 1, 2, data);

      final bytes = packet.encode();

      expect(bytes.length, 24 + data.length);
      final view = ByteData.sublistView(bytes);
      expect(view.getUint32(12, Endian.little), data.length);
      expect(bytes.sublist(24), data);
    });

    test('the checksum is the unsigned sum of the data bytes', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]); // sum = 15
      final packet = AdbPacket(AdbCommand.wrte, 0, 0, data);

      final bytes = packet.encode();

      final view = ByteData.sublistView(bytes);
      expect(view.getUint32(16, Endian.little), 15);
    });

    test('the magic field is the bitwise complement of the command', () {
      final packet = AdbPacket(AdbCommand.auth, 0, 0, Uint8List(0));

      final bytes = packet.encode();

      final view = ByteData.sublistView(bytes);
      expect(view.getUint32(20, Endian.little), AdbCommand.auth ^ 0xFFFFFFFF);
    });
  });

  group('AdbPacket.decodeHeader', () {
    test('round-trips command/arg0/arg1/dataLength through encode', () {
      final data = Uint8List.fromList([9, 8, 7]);
      final original = AdbPacket(AdbCommand.wrte, 42, 99, data);

      final (command, arg0, arg1, dataLength) = AdbPacket.decodeHeader(
        original.encode().sublist(0, AdbPacket.headerLength),
      );

      expect(command, AdbCommand.wrte);
      expect(arg0, 42);
      expect(arg1, 99);
      expect(dataLength, data.length);
    });

    test('throws a FormatException when given the wrong number of bytes', () {
      expect(
        () => AdbPacket.decodeHeader(Uint8List(10)),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws a FormatException when the magic does not match the command', () {
      final bytes = AdbPacket(AdbCommand.cnxn, 0, 0, Uint8List(0)).encode();
      // Corrupt the magic field (bytes 20..24) without touching the command.
      final corrupted = Uint8List.fromList(bytes);
      corrupted[20] = corrupted[20] ^ 0xFF;

      expect(
        () => AdbPacket.decodeHeader(corrupted),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AdbAuthType', () {
    test('has the 3 ADB AUTH sub-types at their protocol values', () {
      expect(AdbAuthType.token, 1);
      expect(AdbAuthType.signature, 2);
      expect(AdbAuthType.rsaPublicKey, 3);
    });
  });

  group('AdbPacketReader', () {
    test('reads a whole packet delivered as a single chunk', () async {
      final packet = AdbPacket(AdbCommand.cnxn, 1, 2, Uint8List.fromList('hi'.codeUnits));
      final reader = AdbPacketReader(Stream.fromIterable([packet.encode()]));

      final decoded = await reader.readPacket();

      expect(decoded.command, AdbCommand.cnxn);
      expect(decoded.arg0, 1);
      expect(decoded.arg1, 2);
      expect(decoded.data, packet.data);
    });

    test('reassembles a packet split across many small chunks, including mid-header and mid-payload splits', () async {
      final packet = AdbPacket(AdbCommand.wrte, 5, 6, Uint8List.fromList([10, 20, 30, 40, 50]));
      final bytes = packet.encode();
      // One byte at a time — the least forgiving possible chunking.
      final chunks = [for (final b in bytes) Uint8List.fromList([b])];
      final reader = AdbPacketReader(Stream.fromIterable(chunks));

      final decoded = await reader.readPacket();

      expect(decoded.command, AdbCommand.wrte);
      expect(decoded.data, packet.data);
    });

    test('reads consecutive packets off the same stream in order', () async {
      final first = AdbPacket(AdbCommand.okay, 1, 1, Uint8List(0));
      final second = AdbPacket(AdbCommand.clse, 2, 2, Uint8List(0));
      final reader = AdbPacketReader(Stream.fromIterable([first.encode(), second.encode()]));

      expect((await reader.readPacket()).command, AdbCommand.okay);
      expect((await reader.readPacket()).command, AdbCommand.clse);
    });

    test('handles a zero-length payload without waiting for data bytes', () async {
      final packet = AdbPacket(AdbCommand.clse, 1, 2, Uint8List(0));
      final reader = AdbPacketReader(Stream.fromIterable([packet.encode()]));

      final decoded = await reader.readPacket();

      expect(decoded.data, isEmpty);
    });

    test('throws AdbConnectionClosedException when the stream ends mid-header', () async {
      final reader = AdbPacketReader(Stream.fromIterable([Uint8List(10)]));

      expect(() => reader.readPacket(), throwsA(isA<AdbConnectionClosedException>()));
    });

    test('throws AdbConnectionClosedException when the stream ends mid-payload', () async {
      final packet = AdbPacket(AdbCommand.wrte, 0, 0, Uint8List.fromList([1, 2, 3, 4, 5]));
      final fullBytes = packet.encode();
      // Header plus only part of the declared payload, then the stream ends.
      final truncated = fullBytes.sublist(0, AdbPacket.headerLength + 2);
      final reader = AdbPacketReader(Stream.fromIterable([truncated]));

      expect(() => reader.readPacket(), throwsA(isA<AdbConnectionClosedException>()));
    });
  });

  group('payload length bounds', () {
    Uint8List headerWith(int dataLength) {
      final h = Uint8List(AdbPacket.headerLength);
      final v = ByteData.sublistView(h);
      v.setUint32(0, AdbCommand.wrte, Endian.little);
      v.setUint32(12, dataLength, Endian.little);
      v.setUint32(20, AdbCommand.wrte ^ 0xFFFFFFFF, Endian.little);
      return h;
    }

    test('rejects a header claiming more than the payload limit', () {
      // dataLength is an attacker-controlled uint32 read before any payload
      // arrives. Without this bound, AdbPacketReader buffers until OOM.
      expect(
        () => AdbPacket.decodeHeader(headerWith(AdbPacket.maxPayloadLength + 1)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects the largest possible uint32 length', () {
      expect(() => AdbPacket.decodeHeader(headerWith(0xFFFFFFFF)), throwsA(isA<FormatException>()));
    });

    test('accepts a header exactly at the limit', () {
      final (_, _, _, len) = AdbPacket.decodeHeader(headerWith(AdbPacket.maxPayloadLength));
      expect(len, AdbPacket.maxPayloadLength);
    });

    test('a reader never buffers a payload larger than the limit', () async {
      final reader = AdbPacketReader(Stream.value(headerWith(0xFFFFFFFF)));
      await expectLater(reader.readPacket(), throwsA(isA<FormatException>()));
    });
  });
}
