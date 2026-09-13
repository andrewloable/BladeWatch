import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_ui/adb/adb_client.dart';
import 'package:bladewatch_ui/adb/adb_protocol.dart';
import 'package:bladewatch_ui/platform/adb_key_channel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_platform_channel.dart';

const _fakePublicKey = 'QAAAAAtestkeyblob== user@bladewatch';
final _fakeSignature = Uint8List.fromList(List.generate(256, (i) => i % 256));

AdbKeyChannel _fakeKeys() => AdbKeyChannel(
      FakePlatformChannel()
        ..stub('adb', 'getPublicKey', _fakePublicKey)
        ..stub('adb', 'sign', _fakeSignature),
    );

/// A minimal, independently-written fake adbd endpoint — deliberately does
/// NOT import adb_client.dart's own packet handling, only adb_protocol.dart's
/// wire-format primitives, so a bug in AdbClient's use of those primitives
/// can't hide behind the test using the exact same broken logic.
class _FakeAdbdConnection {
  final Socket socket;
  late final AdbPacketReader _reader;

  _FakeAdbdConnection(this.socket) {
    _reader = AdbPacketReader(socket);
  }

  Future<AdbPacket> read() => _reader.readPacket();

  void write(int command, int arg0, int arg1, [Uint8List? data]) {
    socket.add(AdbPacket(command, arg0, arg1, data ?? Uint8List(0)).encode());
  }

  Future<void> close() => socket.close();
}

Future<(ServerSocket, Future<_FakeAdbdConnection>)> _bindFakeAdbd() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final connectionFuture = server.first.then((socket) => _FakeAdbdConnection(socket));
  return (server, connectionFuture);
}

void main() {
  group('AdbClient.connect', () {
    test('returns unavailable when nothing is listening on the port', () async {
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: 1);

      final result = await client.connect();

      expect(result.status, AdbConnectionStatus.unavailable);
    });

    test('sends a host:: connect banner as the opening CNXN packet', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      final cnxn = await fakeAdbd.read();
      fakeAdbd.write(AdbCommand.cnxn, 0x01000000, 256 * 1024);
      await resultFuture;

      expect(cnxn.command, AdbCommand.cnxn);
      expect(utf8.decode(cnxn.data), 'host::\u0000');

      await client.close();
      await server.close();
    });

    test('returns connected when the peer accepts the connection without requiring auth', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read(); // CNXN
      fakeAdbd.write(AdbCommand.cnxn, 0x01000000, 256 * 1024);

      expect((await resultFuture).status, AdbConnectionStatus.connected);

      await client.close();
      await server.close();
    });

    test('signs the auth token and returns connected when the peer accepts the signature', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read(); // CNXN
      final token = Uint8List.fromList(List.generate(20, (i) => i));
      fakeAdbd.write(AdbCommand.auth, AdbAuthType.token, 0, token);

      final signaturePacket = await fakeAdbd.read();
      expect(signaturePacket.command, AdbCommand.auth);
      expect(signaturePacket.arg0, AdbAuthType.signature);
      expect(signaturePacket.data, _fakeSignature);

      fakeAdbd.write(AdbCommand.cnxn, 0x01000000, 256 * 1024);

      expect((await resultFuture).status, AdbConnectionStatus.connected);

      await client.close();
      await server.close();
    });

    test('sends its ADB public key when the first signature is rejected, and connects if then accepted', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read(); // CNXN
      final token = Uint8List.fromList(List.generate(20, (i) => i));
      fakeAdbd.write(AdbCommand.auth, AdbAuthType.token, 0, token);
      await fakeAdbd.read(); // AUTH(signature) — rejected below
      fakeAdbd.write(AdbCommand.auth, AdbAuthType.token, 0, token); // still not authorized

      final pubkeyPacket = await fakeAdbd.read();
      expect(pubkeyPacket.command, AdbCommand.auth);
      expect(pubkeyPacket.arg0, AdbAuthType.rsaPublicKey);
      expect(utf8.decode(pubkeyPacket.data), '$_fakePublicKey\u0000');

      fakeAdbd.write(AdbCommand.cnxn, 0x01000000, 256 * 1024);

      expect((await resultFuture).status, AdbConnectionStatus.connected);

      await client.close();
      await server.close();
    });

    test('returns authPending when the peer never accepts within one connection attempt', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(
        keys: _fakeKeys(),
        host: '127.0.0.1',
        port: server.port,
        connectTimeout: const Duration(milliseconds: 200),
      );

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read(); // CNXN
      final token = Uint8List.fromList(List.generate(20, (i) => i));
      fakeAdbd.write(AdbCommand.auth, AdbAuthType.token, 0, token);
      await fakeAdbd.read(); // AUTH(signature)
      fakeAdbd.write(AdbCommand.auth, AdbAuthType.token, 0, token); // rejected again
      await fakeAdbd.read(); // AUTH(rsaPublicKey)
      // Peer never replies again within this attempt's timeout.

      expect((await resultFuture).status, AdbConnectionStatus.authPending);

      await client.close();
      await server.close();
    });

    test('returns authPending if the peer\'s final reply is neither CNXN nor AUTH(token) again', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read(); // CNXN
      // No auth challenge at all — an unexpected reply straight away.
      fakeAdbd.write(AdbCommand.clse, 0, 0);

      expect((await resultFuture).status, AdbConnectionStatus.authPending);

      await client.close();
      await server.close();
    });

    test('returns authPending (not unavailable) if the connection drops mid-handshake', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(
        keys: _fakeKeys(),
        host: '127.0.0.1',
        port: server.port,
        connectTimeout: const Duration(milliseconds: 500),
      );

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read(); // CNXN
      await fakeAdbd.close(); // adbd hangs up instead of replying

      expect((await resultFuture).status, AdbConnectionStatus.authPending);

      await client.close();
      await server.close();
    });
  });

  group('AdbClient.runCommand', () {
    Future<(AdbClient, _FakeAdbdConnection, ServerSocket)> connectedFixture() async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);
      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read(); // CNXN
      fakeAdbd.write(AdbCommand.cnxn, 0x01000000, 256 * 1024);
      await resultFuture;
      return (client, fakeAdbd, server);
    }

    test('truncates and disconnects rather than buffering unbounded output', () async {
      // The ADB Console gives the user a free-text prompt, so `logcat` (no -d)
      // or `cat /dev/urandom` streams until the deadline. The timeout bounds
      // how long that runs but not how much it emits — without a size cap this
      // grows until the head unit runs out of memory.
      final (client, fakeAdbd, server) = await connectedFixture();

      final runFuture = client.runCommand('logcat');
      final open = await fakeAdbd.read();
      final localId = open.arg0;
      const remoteId = 7;
      fakeAdbd.write(AdbCommand.okay, remoteId, localId);

      // Flood past the cap without ever sending CLSE.
      final chunk = Uint8List(64 * 1024);
      var sent = 0;
      while (sent <= AdbClient.maxCommandOutputBytes) {
        fakeAdbd.write(AdbCommand.wrte, remoteId, localId, chunk);
        sent += chunk.length;
      }

      final out = await runFuture;
      expect(out, contains('output truncated'));
      expect(out.length, lessThan(AdbClient.maxCommandOutputBytes + 4096));
      // The stream was abandoned mid-flight, so the connection is closed.
      expect(client.isConnected, isFalse);

      await client.close();
      await server.close();
    });

    test('opens a shell: stream for the given command', () async {
      final (client, fakeAdbd, server) = await connectedFixture();

      final runFuture = client.runCommand('echo hi');
      final open = await fakeAdbd.read();
      expect(open.command, AdbCommand.open);
      expect(utf8.decode(open.data), 'shell:echo hi\u0000');

      fakeAdbd.write(AdbCommand.okay, 100, open.arg0);
      fakeAdbd.write(AdbCommand.clse, 100, open.arg0);
      await fakeAdbd.read(); // client's CLSE ack

      expect(await runFuture, '');

      await client.close();
      await server.close();
    });

    test('accumulates output across multiple WRTE chunks and acknowledges each with OKAY', () async {
      final (client, fakeAdbd, server) = await connectedFixture();

      final runFuture = client.runCommand('cat /proc/version');
      final open = await fakeAdbd.read();
      final localId = open.arg0;
      const remoteId = 42;
      fakeAdbd.write(AdbCommand.okay, remoteId, localId);

      fakeAdbd.write(AdbCommand.wrte, remoteId, localId, Uint8List.fromList(utf8.encode('hello ')));
      final ack1 = await fakeAdbd.read();
      expect(ack1.command, AdbCommand.okay);
      expect(ack1.arg0, localId);
      expect(ack1.arg1, remoteId);

      fakeAdbd.write(AdbCommand.wrte, remoteId, localId, Uint8List.fromList(utf8.encode('world')));
      final ack2 = await fakeAdbd.read();
      expect(ack2.command, AdbCommand.okay);

      fakeAdbd.write(AdbCommand.clse, remoteId, localId);
      final clseAck = await fakeAdbd.read();
      expect(clseAck.command, AdbCommand.clse);
      expect(clseAck.arg0, localId);
      expect(clseAck.arg1, remoteId);

      expect(await runFuture, 'hello world');

      await client.close();
      await server.close();
    });

    test('throws AdbNotConnectedException when called before connect() succeeds', () async {
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: 1);

      expect(() => client.runCommand('ls'), throwsA(isA<AdbNotConnectedException>()));
    });

    test('throws AdbCommandTimeoutException and disconnects if the peer never responds', () async {
      final (client, fakeAdbd, server) = await connectedFixture();

      final runFuture = client.runCommand('sleep 999', timeout: const Duration(milliseconds: 200));
      await fakeAdbd.read(); // OPEN — never acknowledged

      await expectLater(runFuture, throwsA(isA<AdbCommandTimeoutException>()));
      expect(() => client.runCommand('ls'), throwsA(isA<AdbNotConnectedException>()));

      await fakeAdbd.close();
      await server.close();
    });

    test('throws AdbCommandTimeoutException and disconnects if the peer closes mid-command', () async {
      final (client, fakeAdbd, server) = await connectedFixture();

      final runFuture = client.runCommand('sleep 999');
      await fakeAdbd.read(); // OPEN
      await fakeAdbd.close(); // adbd hangs up instead of ever acknowledging

      await expectLater(runFuture, throwsA(isA<AdbCommandTimeoutException>()));
      expect(() => client.runCommand('ls'), throwsA(isA<AdbNotConnectedException>()));

      await server.close();
    });

    test('rejects a second runCommand while one is still in flight', () async {
      final (client, fakeAdbd, server) = await connectedFixture();

      final firstRun = client.runCommand('sleep 5');
      final open = await fakeAdbd.read(); // OPEN for the first command

      expect(() => client.runCommand('ls'), throwsA(isA<StateError>()));

      fakeAdbd.write(AdbCommand.okay, 7, open.arg0);
      fakeAdbd.write(AdbCommand.clse, 7, open.arg0);
      await fakeAdbd.read(); // first command's CLSE ack
      await firstRun;

      await client.close();
      await server.close();
    });
  });

  group('AdbClient.isConnected', () {
    test('is false before connect() and true after a successful connect()', () async {
      final (server, connectionFuture) = await _bindFakeAdbd();
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);
      expect(client.isConnected, isFalse);

      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read();
      fakeAdbd.write(AdbCommand.cnxn, 0x01000000, 256 * 1024);
      await resultFuture;

      expect(client.isConnected, isTrue);

      await client.close();
      await server.close();
    });
  });

  group('exception messages', () {
    test('AdbNotConnectedException.toString() is descriptive', () {
      expect(const AdbNotConnectedException().toString(), contains('not connected'));
    });

    test('AdbCommandTimeoutException.toString() is descriptive', () {
      expect(const AdbCommandTimeoutException().toString(), contains('timed out'));
    });
  });

  group('AdbClient.close', () {
    test('closing before connecting is a harmless no-op', () async {
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: 1);

      await client.close();
    });

    test('closes the underlying socket so a subsequent runCommand throws AdbNotConnectedException', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final connectionFuture = server.first.then((socket) => _FakeAdbdConnection(socket));
      final client = AdbClient(keys: _fakeKeys(), host: '127.0.0.1', port: server.port);
      final resultFuture = client.connect();
      final fakeAdbd = await connectionFuture;
      await fakeAdbd.read();
      fakeAdbd.write(AdbCommand.cnxn, 0x01000000, 256 * 1024);
      await resultFuture;

      await client.close();

      expect(() => client.runCommand('ls'), throwsA(isA<AdbNotConnectedException>()));

      await server.close();
    });
  });
}
