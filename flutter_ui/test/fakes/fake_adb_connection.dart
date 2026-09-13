/// Fake [AdbConnection] shared across ADB Console controller/screen tests —
/// no real socket, no fake TCP server. The wire protocol itself is
/// exhaustively tested against a real loopback socket in
/// test/adb/adb_client_test.dart; this fake only needs to stand in for
/// [AdbConsoleController]'s 3 dependency points.
library;

import 'package:bladewatch_ui/adb/adb_client.dart';

class FakeAdbConnection implements AdbConnection {
  AdbConnectResult nextConnectResult = const AdbConnectResult(AdbConnectionStatus.unavailable);
  Object? connectError;
  int connectCallCount = 0;

  /// Maps a command to the output [runCommand] returns for it. A command
  /// with no entry throws [Exception] (mirroring a real command that never
  /// completes/errors), unless [runCommandError] is set instead.
  final Map<String, String> commandOutputs = {};
  Object? runCommandError;
  final List<String> runCommandCalls = [];

  bool closed = false;

  @override
  Future<AdbConnectResult> connect() async {
    connectCallCount++;
    if (connectError != null) throw connectError!;
    return nextConnectResult;
  }

  @override
  Future<String> runCommand(String command, {Duration timeout = const Duration(seconds: 15)}) async {
    runCommandCalls.add(command);
    if (runCommandError != null) throw runCommandError!;
    final output = commandOutputs[command];
    if (output == null) {
      throw StateError('FakeAdbConnection: no output stubbed for command "$command"');
    }
    return output;
  }

  @override
  Future<void> close() async {
    closed = true;
  }
}
