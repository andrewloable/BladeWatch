import 'package:bladewatch_ui/adb/adb_client.dart';
import 'package:bladewatch_ui/screens/diagnostics/adb_console_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_adb_connection.dart';

void main() {
  late FakeAdbConnection connection;
  late AdbConsoleController controller;

  setUp(() {
    connection = FakeAdbConnection();
    controller = AdbConsoleController(connection: connection);
  });

  test('starts in the connecting state with empty output', () {
    expect(controller.connectionState, AdbConsoleConnectionState.connecting);
    expect(controller.output, isEmpty);
    expect(controller.isExecuting, isFalse);
  });

  group('connect', () {
    test('transitions to connected on success', () async {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);

      await controller.connect();

      expect(controller.connectionState, AdbConsoleConnectionState.connected);
    });

    test('transitions to authPending when the device has not authorized this key yet', () async {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.authPending);

      await controller.connect();

      expect(controller.connectionState, AdbConsoleConnectionState.authPending);
    });

    test('transitions to unavailable when adbd is not reachable', () async {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.unavailable);

      await controller.connect();

      expect(controller.connectionState, AdbConsoleConnectionState.unavailable);
    });

    test('notifies listeners', () async {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.connect();

      expect(notifications, greaterThan(0));
    });

    test('can be retried after a failed attempt', () async {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.unavailable);
      await controller.connect();
      expect(controller.connectionState, AdbConsoleConnectionState.unavailable);

      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      await controller.connect();

      expect(controller.connectionState, AdbConsoleConnectionState.connected);
      expect(connection.connectCallCount, 2);
    });
  });

  group('execute', () {
    setUp(() async {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      await controller.connect();
    });

    test('appends the command line and its output to the transcript', () async {
      connection.commandOutputs['df -h'] = 'Filesystem  Size  Used';

      await controller.execute('df -h');

      expect(controller.output, r'$ df -h' '\nFilesystem  Size  Used');
    });

    test('appends only the command line when the command produces no output', () async {
      connection.commandOutputs['echo -n'] = '';

      await controller.execute('echo -n');

      expect(controller.output, r'$ echo -n');
    });

    test('appends an Error line instead of throwing when the command fails', () async {
      connection.runCommandError = const AdbCommandTimeoutException();

      await controller.execute('sleep 999');

      expect(controller.output, contains(r'$ sleep 999'));
      expect(controller.output, contains('Error:'));
    });

    test('trims surrounding whitespace and ignores a blank command', () async {
      await controller.execute('   ');

      expect(controller.output, isEmpty);
      expect(connection.runCommandCalls, isEmpty);
    });

    test('sets isExecuting while the command is in flight and clears it afterward', () async {
      connection.commandOutputs['ls'] = 'a.txt';
      final states = <bool>[];
      controller.addListener(() => states.add(controller.isExecuting));

      await controller.execute('ls');

      expect(states, contains(true));
      expect(controller.isExecuting, isFalse);
    });

    test('ignores a re-entrant execute call while one is already in flight', () async {
      connection.commandOutputs['first'] = 'ok';
      final firstFuture = controller.execute('first');

      await controller.execute('second'); // should be a no-op — first is still running

      await firstFuture;
      expect(connection.runCommandCalls, ['first']);
    });

    test('accumulates multiple commands across calls', () async {
      connection.commandOutputs['one'] = 'A';
      connection.commandOutputs['two'] = 'B';

      await controller.execute('one');
      await controller.execute('two');

      expect(controller.output, r'$ one' '\nA\n' r'$ two' '\nB');
    });
  });

  group('clearOutput', () {
    test('empties the transcript', () async {
      connection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      await controller.connect();
      connection.commandOutputs['ls'] = 'a.txt';
      await controller.execute('ls');
      expect(controller.output, isNotEmpty);

      controller.clearOutput();

      expect(controller.output, isEmpty);
    });

    test('notifies listeners', () {
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.clearOutput();

      expect(notifications, 1);
    });
  });

  group('dispose', () {
    test('closes the underlying connection', () {
      controller.dispose();

      expect(connection.closed, isTrue);
    });
  });
}
