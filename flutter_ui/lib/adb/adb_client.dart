import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_ui/platform/adb_key_channel.dart';

import 'adb_protocol.dart';

enum AdbConnectionStatus {
  /// Nothing is listening on the ADB port at all — e.g. the head unit's
  /// wireless ADB was reset by a firmware update (see BladeWatch-ofzb).
  unavailable,

  /// adbd is reachable but has not (yet) authorized this key — the console
  /// should explain that the device needs a tap on its own "Allow USB
  /// debugging?" prompt, and let the caller retry.
  authPending,

  /// The connection completed the ADB handshake and is ready for commands.
  connected,
}

class AdbConnectResult {
  final AdbConnectionStatus status;
  const AdbConnectResult(this.status);
}

/// Thrown by [AdbClient.runCommand] when called before [AdbClient.connect]
/// has completed successfully (or after [AdbClient.close]).
class AdbNotConnectedException implements Exception {
  const AdbNotConnectedException();

  @override
  String toString() => 'AdbNotConnectedException: not connected — call connect() first';
}

/// Thrown by [AdbClient.runCommand] when the peer doesn't finish the command
/// within its timeout, or the connection drops while it's in flight. Either
/// way the connection is closed — a fresh [AdbClient.connect] is required.
class AdbCommandTimeoutException implements Exception {
  const AdbCommandTimeoutException();

  @override
  String toString() => 'AdbCommandTimeoutException: command timed out or the connection dropped';
}

/// The 3 operations [AdbConsoleController] needs — [AdbClient] implements
/// this against a real socket; tests inject `FakeAdbConnection`
/// (flutter_ui/test/fakes/fake_adb_connection.dart) instead, the same shape
/// [RpcTransport]/[PlatformChannel] are split from their real
/// implementations for the same reason.
abstract class AdbConnection {
  Future<AdbConnectResult> connect();
  Future<String> runCommand(String command, {Duration timeout});
  Future<void> close();
}

/// A hand-rolled, pure-Dart ADB protocol client — BladeWatch-yz1e.4's ADB
/// Console talks to adbd on 127.0.0.1:5555 this way instead of through a
/// pub.dev ADB package or the privileged-operations IPC channel (there is no
/// `shell` IPC command; it was removed as an RCE fix, see
/// `app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java`).
/// Mirrors the protocol
/// `app/src/main/java/com/loabletech/bladewatch/launcher/AdbShellExecutor.kt`
/// talks over the `dadb` JVM library: CNXN connect, AUTH(TOKEN) →
/// AUTH(SIGNATURE) → (CNXN, or AUTH(TOKEN) again meaning not-yet-authorized →
/// AUTH(RSAPUBLICKEY)), then OPEN/WRTE/OKAY/CLSE to run one `shell:` command
/// per stream.
///
/// Unlike [AdbShellExecutor]'s own internal 60×3s auth-polling loop, [connect]
/// makes exactly ONE bounded attempt and returns which of the 3 states it
/// reached — the caller (the screen, via its controller) owns any retry
/// timer, matching this port's convention of screens owning timers rather
/// than a client blocking for minutes (see the Performance screen).
class AdbClient implements AdbConnection {
  static const int _protocolVersion = 0x01000000;
  static const int _maxData = 256 * 1024;

  /// Cap on the combined output [runCommand] will accumulate for one command.
  ///
  /// The timeout bounds how *long* a command runs but not how much it emits,
  /// and the ADB Console hands the user a free-text prompt: `logcat` without
  /// `-d`, or `cat /dev/urandom`, streams until the deadline. At localhost
  /// speeds that is hundreds of megabytes into a growing buffer on a head unit
  /// with limited RAM. Past this, the stream is closed and what was collected
  /// is returned with a truncation marker — a truncated answer beats an OOM.
  static const int maxCommandOutputBytes = 2 * 1024 * 1024;

  final AdbKeyChannel keys;
  final String host;
  final int port;
  final Duration connectTimeout;

  Socket? _socket;
  AdbPacketReader? _reader;
  bool _connected = false;
  bool _busy = false;
  int _nextLocalId = 1;

  AdbClient({
    required this.keys,
    this.host = '127.0.0.1',
    this.port = 5555,
    this.connectTimeout = const Duration(seconds: 2),
  });

  bool get isConnected => _connected;

  @override
  Future<AdbConnectResult> connect() async {
    final Socket socket;
    try {
      socket = await Socket.connect(host, port, timeout: connectTimeout);
    } catch (_) {
      return const AdbConnectResult(AdbConnectionStatus.unavailable);
    }

    final reader = AdbPacketReader(socket);
    try {
      _send(socket, AdbCommand.cnxn, _protocolVersion, _maxData, utf8.encode('host::\u0000'));
      var packet = await reader.readPacket().timeout(connectTimeout);

      if (packet.command == AdbCommand.auth && packet.arg0 == AdbAuthType.token) {
        final signature = await keys.sign(packet.data);
        _send(socket, AdbCommand.auth, AdbAuthType.signature, 0, signature);
        packet = await reader.readPacket().timeout(connectTimeout);

        if (packet.command == AdbCommand.auth && packet.arg0 == AdbAuthType.token) {
          final publicKey = await keys.getPublicKey();
          _send(socket, AdbCommand.auth, AdbAuthType.rsaPublicKey, 0, utf8.encode('$publicKey\u0000'));
          packet = await reader.readPacket().timeout(connectTimeout);
        }
      }

      if (packet.command == AdbCommand.cnxn) {
        _socket = socket;
        _reader = reader;
        _connected = true;
        return const AdbConnectResult(AdbConnectionStatus.connected);
      }

      await socket.close();
      return const AdbConnectResult(AdbConnectionStatus.authPending);
    } catch (_) {
      await socket.close();
      return const AdbConnectResult(AdbConnectionStatus.authPending);
    }
  }

  /// Runs one command over a `shell:` stream on the existing connection,
  /// returning its combined stdout/stderr once adbd closes the stream. Only
  /// one command may be in flight at a time.
  @override
  Future<String> runCommand(String command, {Duration timeout = const Duration(seconds: 15)}) async {
    final socket = _socket;
    final reader = _reader;
    if (!_connected || socket == null || reader == null) {
      throw const AdbNotConnectedException();
    }
    if (_busy) {
      throw StateError('AdbClient.runCommand: a command is already in flight');
    }

    _busy = true;
    try {
      final localId = _nextLocalId++;
      _send(socket, AdbCommand.open, localId, 0, utf8.encode('shell:$command\u0000'));

      final output = BytesBuilder(copy: false);
      var truncated = false;
      try {
        while (true) {
          final packet = await reader.readPacket().timeout(timeout);
          if (packet.command == AdbCommand.okay) {
            continue;
          }
          if (packet.command == AdbCommand.wrte) {
            output.add(packet.data);
            _send(socket, AdbCommand.okay, localId, packet.arg0);
            if (output.length >= maxCommandOutputBytes) {
              // Stop draining rather than keep growing. The connection is torn
              // down because the stream is left mid-flight; the caller gets what
              // arrived so far and must reconnect, same as after a timeout.
              truncated = true;
              break;
            }
            continue;
          }
          if (packet.command == AdbCommand.clse) {
            _send(socket, AdbCommand.clse, localId, packet.arg0);
            break;
          }
          // Any other packet type isn't meaningful for a single-stream shell
          // command — ignore it and keep waiting for WRTE/CLSE.
        }
      } on TimeoutException {
        await _disconnect();
        throw const AdbCommandTimeoutException();
      } on AdbConnectionClosedException {
        await _disconnect();
        throw const AdbCommandTimeoutException();
      }

      final text = utf8.decode(output.toBytes(), allowMalformed: true);
      if (truncated) {
        await _disconnect();
        return '$text\n[output truncated at $maxCommandOutputBytes bytes — connection closed]';
      }
      return text;
    } finally {
      _busy = false;
    }
  }

  @override
  Future<void> close() => _disconnect();

  void _send(Socket socket, int command, int arg0, int arg1, [List<int>? data]) {
    socket.add(AdbPacket(command, arg0, arg1, data == null ? Uint8List(0) : Uint8List.fromList(data)).encode());
  }

  Future<void> _disconnect() async {
    _connected = false;
    final socket = _socket;
    _socket = null;
    _reader = null;
    if (socket != null) {
      await socket.close();
    }
  }
}
