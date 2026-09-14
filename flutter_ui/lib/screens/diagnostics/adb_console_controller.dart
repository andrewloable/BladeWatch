import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import 'package:bladewatch_ui/adb/adb_client.dart';
import '../../shell/disposed_safe_notifier.dart';

enum AdbConsoleConnectionState { connecting, unavailable, authPending, connected }

/// Controller behind the ADB Console screen — BladeWatch-yz1e.4. Ported from
/// `app/src/main/java/com/loabletech/bladewatch/ui/fragment/AdbConsoleFragment.kt`,
/// but the connection handshake itself lives in [AdbConnection]
/// (`flutter_ui/lib/adb/adb_client.dart`), not here: this class only owns the
/// screen's visible state (connection state, the output transcript, whether
/// a command is currently running).
///
/// [output] is a plain transcript string, not native's `outputBuilder` text
/// verbatim — in particular the "$ Ready for commands…" placeholder native
/// shows on an empty transcript is an ARB-resolved string the screen renders
/// when [output] is empty, not something this (Flutter-import-free) class
/// can produce itself.
class AdbConsoleController extends ChangeNotifier with DisposedSafeNotifier {
  final AdbConnection _connection;

  AdbConsoleController({required AdbConnection connection}) : _connection = connection; // ignore: prefer_initializing_formals

  AdbConsoleConnectionState _connectionState = AdbConsoleConnectionState.connecting;
  AdbConsoleConnectionState get connectionState => _connectionState;

  final List<String> _lines = [];
  String get output => _lines.join('\n');

  bool _isExecuting = false;
  bool get isExecuting => _isExecuting;

  Future<void> connect() async {
    final result = await _connection.connect();
    _connectionState = switch (result.status) {
      AdbConnectionStatus.connected => AdbConsoleConnectionState.connected,
      AdbConnectionStatus.authPending => AdbConsoleConnectionState.authPending,
      AdbConnectionStatus.unavailable => AdbConsoleConnectionState.unavailable,
    };
    notifyListeners();
  }

  Future<void> execute(String command) async {
    if (_isExecuting) return;
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    _lines.add('\$ $trimmed');
    _isExecuting = true;
    notifyListeners();

    try {
      final result = await _connection.runCommand(trimmed);
      if (result.isNotEmpty) _lines.add(result);
    } catch (e) {
      _lines.add('Error: $e');
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }

  void clearOutput() {
    _lines.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_connection.close());
    super.dispose();
  }
}
